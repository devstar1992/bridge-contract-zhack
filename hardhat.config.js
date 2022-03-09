require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    bsc_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: ["be331e0f5120038424eeec8cc726e3213ad9038429500a4667f6b57b161d31c0"]
    },
    ropsten: {
      url: "https://eth-ropsten.alchemyapi.io/v2/zT6MSYFVB-ojEc0-BbokQELJKOl0YxdS",
      accounts: ["be331e0f5120038424eeec8cc726e3213ad9038429500a4667f6b57b161d31c0"]
    },
    local: {
      url: "http://127.0.0.1:8545",
      accounts: ["be331e0f5120038424eeec8cc726e3213ad9038429500a4667f6b57b161d31c0"]
    }

  },
  solidity: {
    version: "0.8.11",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  }, 
};
