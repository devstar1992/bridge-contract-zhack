const { ethers, upgrades } = require('hardhat');

async function main () {
  try{    
    const Token = await ethers.getContractFactory('Token');
    console.log('Deploying Token...');
    const token = await upgrades.deployProxy(Token, ["0x4984aefC02674b60D40ef57FAA158140AE69c0a8", 
    "Test Token", 
    "TTK", 
    "1000000000000",
    "0xEC261AaA4A88Ce37671fEa5027b9d3f2f3C3a445",
    "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3",
    [20,
    20,
    20],
    [20,
    20,
    20],
    [20,
    20,
    20],
    0,
    "10000000000"
  ], { initializer: 'initialize' });
    await token.deployed();
    console.log('Token deployed to:', token.address);
  }catch(err){
    console.log(err);
  }
}

main();