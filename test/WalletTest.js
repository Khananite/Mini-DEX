const Dex = artifacts.require("Dex");
const ChainLink = artifacts.require("ChainLink");
const truffleAssert = require('truffle-assertions');

contract("Dex", accounts => {
    it("should only be possible for owner to add tokens", async () => {
        let dex = await Dex.deployed()
        let link = await ChainLink.deployed()
        await truffleAssert.passes(
            dex.addToken(web3.utils.fromUtf8("LINK"), link.address, {from: accounts[0]})
        )
        await truffleAssert.reverts(
            dex.addToken(web3.utils.fromUtf8("AAVE"), link.address, {from: accounts[1]})
        )
    })

    it("should handle deposits correctly", async () => {
        let dex = await Dex.deployed()
        let link = await ChainLink.deployed()
        await link.approve(dex.address, 500);
        await dex.deposit(100, web3.utils.fromUtf8("LINK"));
        let balance = await dex.balances(accounts[0], web3.utils.fromUtf8("LINK"));
        assert.equal(balance.toNumber(), 100);
    })

    it("should handle faulty withdrawals correctly", async () => {
        let dex = await Dex.deployed()
        let link = await ChainLink.deployed()
        //I should not be able to withdraw 500 because I only have 100 in my account.
        await truffleAssert.reverts(dex.withdrawal(500, web3.utils.fromUtf8("LINK")));
    })

    it("should handle correct withdrawals", async () => {
        let dex = await Dex.deployed()
        let link = await ChainLink.deployed()
        //I should not be able to withdraw 500 because I don't have that in my account.
        await truffleAssert.passes(dex.withdrawal(100, web3.utils.fromUtf8("LINK")));
    })
})