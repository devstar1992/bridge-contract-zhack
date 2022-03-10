const { ethers, upgrades } = require('hardhat');

async function main () {
  try{    
    const Token1 = await ethers.getContractFactory('Token1');
    console.log('Deploying Token (removed community)...');
    const token1 = await upgrades.deployProxy(Token1, ["0x4984aefC02674b60D40ef57FAA158140AE69c0a8", 
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
    20]   
  ], { initializer: 'initialize' });
    await token1.deployed();
    console.log('Token (removed community) deployed to:', token1.address);
  }catch(err){
    console.log(err);
  }
}

main();