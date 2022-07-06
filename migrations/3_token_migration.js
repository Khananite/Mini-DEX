const ChainLink = artifacts.require("ChainLink");
const Dex = artifacts.require("Dex");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(ChainLink);
  
  //We moved this code below to the wallettest.js for unit testing.
  /*let dex = await Dex.deployed()
  let link = await ChainLink.deployed()

  dex.addToken(web3.utils.fromUtf8("LINK"), link.address, {from: accounts[0]})
  await link.approve(dex.address, 500)
  await dex.deposit(300, web3.utils.fromUtf8("LINK"))
  let balanceOfLink = await dex.balances(accounts[0], web3.utils.fromUtf8("LINK"))
  console.log("This is the balance: " + balanceOfLink)*/
};
