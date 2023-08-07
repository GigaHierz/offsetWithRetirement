// deploy/00_deploy_my_contract.js

// const { ethers } = require("hardhat");

// const sleep = (ms) =>
//   new Promise((r) =>
//     setTimeout(() => {
//       console.log(`waited for ${(ms / 1000).toFixed(3)} seconds`);
//       r();
//     }, ms)
//   );

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;

  // Named Accounts are for improving developer experience, can be configured in hardhat.config.js
  const { deployer } = await getNamedAccounts();

  await deploy("SimpleSwapper", {
    from: deployer,
    // Uniswap V3 router address
    args: [0x1f98431c8ad98523631ae4a59f267346ea31f984],
    log: true,
  });

  // Getting a previously deployed contract
  // const SimpleSwapper = new ethers.Contract("SimpleSwapper", deployer);

  // await SimpleSwapper.setGreeting("Hello Celo!");

  /*
  // If you want to send value to an address from the deployer
  
  const deployerWallet = ethers.provider.getSigner()
  await deployerWallet.sendTransaction({
    to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
    value: ethers.utils.parseEther("0.001")
  })
  */

  /*
  //If you want to send some CELO to a contract on deploy (make your constructor payable!)
  const yourContract = await deploy("YourContract", [], {
    value: ethers.utils.parseEther("0.05")
  });
  */

  /*
  //If you want to link a library into your contract:
  // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
  const yourContract = await deploy("YourContract", [], {}, {
    LibraryName: **LibraryAddress**
  });
  */
};

/**
 * Use tags to run specific deploy scripts
 * For example:- npx hardhat deploy --tags SimpleSwapper will run only this script
 */
module.exports.tags = ["SimpleSwapper"];
