const { ethers, upgrades } = require('hardhat');

async function main() {
  try {
    const IterableMapping = await ethers.getContractFactory('IterableMapping');
    console.log('Deploying IterableMapping...');
    const iterableMapping = await IterableMapping.deploy(); 
    const Token3DividendTracker = await ethers.getContractFactory('Token3DividendTracker', {
      libraries: {
        IterableMapping: iterableMapping.address
      }});
    console.log('Deploying Token3DividendTracker');
    const token3DividendTracker = await upgrades.deployProxy(Token3DividendTracker, [
      "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3", //reward token - BUSD address
      "10000000000000000" //minimumTokenBalanceForDividends_
    ], 
    { initializer: 'initialize', unsafeAllow:["external-library-linking"] });
    await token3DividendTracker.deployed();
    console.log('Token3DividendTracker deployed to:', token3DividendTracker.address);
  } catch (err) {
    console.log(err);
  }
}

main();