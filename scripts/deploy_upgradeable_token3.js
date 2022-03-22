const { ethers, upgrades } = require('hardhat');

async function main() {
  try {
    const Token3 = await ethers.getContractFactory('Token3');
    console.log('Deploying Token3');
    const token3 = await upgrades.deployProxy(Token3, [
      "token name",
      "tokensymbol",
      "100000000000000000000000000", //total supply
      [
        "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3",// reward
        "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3",// router
        "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3",// marketing wallet
        "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3"// dividendTracker
      ],
      [    
        10,  // rewards
        2, // liquidity
        5,// marketing
        "100000000000000000000000" // max limit to sell
      ],
      "100000000000000",//minimumTokenBalanceForDividends_
      "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3", // serviceFeeReceiver_
      "100000000000000",//serviceFee_
      9 //decimals
    ], { initializer: 'initialize' });
    await token3.deployed();
    console.log('Token3 deployed to:', token3.address);
  } catch (err) {
    console.log(err);
  }
}

main();