// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "./SimpleSwapper.sol";
import "https://github.com/ToucanProtocol/contracts/blob/main/contracts/RetirementCertificates.sol";

contract OffsetWithCertificate is SimpleSwapper, RetirementCertificates {
    // For the scope of these swap examples,
    // we will detail the design considerations when using
    // `autoOffsetWithCertificate`.

    constructor() {}

    /**
     * @notice Retire carbon credits using the lowest quality (oldest) TCO2
     * tokens available from the specified Toucan token pool by sending ERC20
     * tokens (cUSD, USDC, WETH, WMATIC). All provided token is consumed for
     * offsetting.
     *
     * This function:
     * 1. Swaps the ERC20 token sent to the contract for the specified pool token.
     * 2. Redeems the pool token for the poorest quality TCO2 tokens available.
     * 3. Retires the TCO2 tokens.
     *
     * Note: The client must approve the ERC20 token that is sent to the contract.
     *
     * @dev When automatically redeeming pool tokens for the lowest quality
     * TCO2s there are no fees and you receive exactly 1 TCO2 token for 1 pool
     * token.
    * @param beneficiary The beneficiary address for whom the TCO2 amount was retired.
     *
     * @param _fromToken The address of the ERC20 token that the user sends
     * (e.g., cUSD, cUSD, USDC, WETH, WMATIC)
     * @param _poolToken The address of the Toucan pool token that the
     * user wants to use,  e.g., NCT or BCT
     * @param _amountToSwap The amount of ERC20 token to swap into Toucan pool
     * token. Full amount will be used for offsetting.
     * @param retiringEntityString The amount of ERC20 token to swap into Toucan pool
     * token. Full amount will be used for offsetting.
     * @param retiringEntityString An identifiable string for the retiring entity, eg. their name.
     * @param beneficiaryString An identifiable string for the beneficiary, eg. their name.
     * @param retirementMessage A message to accompany the retirement.
     *
     * @return tco2s An array of the TCO2 addresses that were redeemed
     * @return amounts An array of the amounts of each TCO2 that were redeemed
     */
    function autoOffsetWithCertificate(
        address _beneficiary,
        address _fromToken,
        address _poolToken,
        uint256 _amountToSwap,
        string calldata retiringEntityString,
        string calldata beneficiaryString,
        string calldata retirementMessage,
    ) public returns (address[] memory tco2s, uint256[] memory amounts) {
        // swap input token for BCT / NCT
        uint256 amountToOffset = simpleSwapper.swapExactInputSingle(
            _fromToken,
            _poolToken,
            _amountToSwap
        );

        // redeem BCT / NCT for TCO2s
        (tco2s, amounts) = autoRedeem(_poolToken, amountToOffset);

        // retire the TCO2s to achieve offset
        uint256 retirementEventId = autoRetireFrom(_beneficiary, tco2s, amounts);

        // create Certificate
        uint256[] memory retirementEventIds = new uint256[](1);
        retirementEventIds[0] = retirementEventId;
        RetirementCertificates.mintCertificate(_beneficiary, retiringEntityString, _beneficiary, retiringEntityString, beneficiaryString, retirementMessage, retirementEventIds)
    }

    /**
     * @notice Redeems the specified amount of NCT / BCT for TCO2.
     * @dev Needs to be approved on the client side
     * @param _fromToken Could be the address of NCT or BCT
     * @param _amount Amount to redeem
     * @return tco2s An array of the TCO2 addresses that were redeemed
     * @return amounts An array of the amounts of each TCO2 that were redeemed
     */
    function autoRedeem(
        address _fromToken,
        uint256 _amount
    )
        public
        onlyRedeemable(_fromToken)
        returns (address[] memory tco2s, uint256[] memory amounts)
    {
        require(
            balances[msg.sender][_fromToken] >= _amount,
            "Insufficient NCT/BCT balance"
        );

        // instantiate pool token (NCT or BCT)
        IToucanPoolToken PoolTokenImplementation = IToucanPoolToken(_fromToken);

        // auto redeem pool token for TCO2; will transfer automatically picked TCO2 to this contract
        (tco2s, amounts) = PoolTokenImplementation.redeemAuto2(_amount);

        // update balances
        balances[msg.sender][_fromToken] -= _amount;
        uint256 tco2sLen = tco2s.length;
        for (uint256 index = 0; index < tco2sLen; index++) {
            balances[msg.sender][tco2s[index]] += amounts[index];
        }

        emit Redeemed(msg.sender, _fromToken, tco2s, amounts);
    }

    /**
     * @notice Retire the specified TCO2 tokens.
     * @param beneficiary The addresses of the person to retire for
     * @param _tco2s The addresses of the TCO2s to retire
     * @param _amounts The amounts to retire from each of the corresponding
     * TCO2 addresses
     */
    function autoRetireFrom(
        address beneficiary,
        address[] memory _tco2s,
        uint256[] memory _amounts
    ) public returns (uint256 retirementEventId) {
        uint256 tco2sLen = _tco2s.length;
        require(tco2sLen != 0, "Array empty");

        require(tco2sLen == _amounts.length, "Arrays unequal");

        uint256 i = 0;
        while (i < tco2sLen) {
            if (_amounts[i] == 0) {
                unchecked {
                    i++;
                }
                continue;
            }
            require(
                balances[msg.sender][_tco2s[i]] >= _amounts[i],
                "Insufficient TCO2 balance"
            );

            balances[msg.sender][_tco2s[i]] -= _amounts[i];

            uint256 retirementEventId = IToucanCarbonOffsets(_tco2s[i])
                .retireFrom(beneficiary, _amounts[i]);

            unchecked {
                ++i;
            }
        }
    }


}
