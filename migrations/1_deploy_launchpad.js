// const { deployProxy, upgradeProxy} = require('@openzeppelin/truffle-upgrades');

// const NFTLaunchPad = artifacts.require('NFTLaunchPad');

// module.exports = async function (deployer, network, accounts) {
//   const instance =  await deployProxy(NFTLaunchPad, { deployer, initializer: 'initialize' });
//   console.log('Deployed', instance.address);
// };

var NFTCollection = artifacts.require("NFTCollection");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(NFTCollection,[10000, 250], 
    "0x678fee76722fcDB047543fB7Fb92821e6E19F8db",
    ["Name", "COLLECTION", "baseURI", "contractURI"],
    [[["0x4B4743a09E5542F0E59770DF4Dd578098A24BDb1"], ["10"], ["0x4B4743a09E5542F0E59770DF4Dd578098A24BDb1"], ["5"], true, "1671189013", "1671192613", "10", "10"]]
);
};
