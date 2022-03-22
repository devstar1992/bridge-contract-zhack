const { ethers, upgrades } = require('hardhat');

async function main() {
  try {
    const Token2 = await ethers.getContractFactory('Token2');
    console.log('Deploying Token2');
    const token2 = await upgrades.deployProxy(Token2, [
      "token name",
      "tokensymbol",
      9,//decimals
      "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3", // pancake router address
      [
        true,//limitsInEffect - for token launch
        true, //transferDelayEnabled
        true, //_gasLimitActive
        false, //tradingActive
        false//swapAndLiquifyEnabled
      ],
      [
        "100000000000000000000000000", //total supply
        5, //buyLiquidityFee
        6, //buyMarketingFee
        5, //sellLiquidityFee
        6, //sellMarketingFee
        "1000000000000000000000", //minimumToken amount BeforeSwap
        "10000000000000000000000", //maxTransactionAmount
        "100000000000000000000000", //maxWallet
        20, //maxBuyFee
        30, //maxSellFee
        "500000000000" //_gasPriceLimit
      ]
    ], { initializer: 'initialize' });
    await token2.deployed();
    console.log('Token2 deployed to:', token2.address);
  } catch (err) {
    console.log(err);
  }
}

main();