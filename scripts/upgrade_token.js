// scripts/upgrade_Token.js
const { ethers, upgrades } = require('hardhat');

async function main () {
  const TokenV2 = await ethers.getContractFactory('Token');
  console.log('Upgrading Token...');
  await upgrades.upgradeProxy('0x42Fb6819a6C7b4824B26D47B09CF2C6D338E00e8', TokenV2);
  console.log('Token upgraded');
}

main();