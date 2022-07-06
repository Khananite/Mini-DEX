// The user must have ETH deposited such that deposited eth >= buy order value
// The user must have enough tokens deposited such that token balance >= sell order amount
// The BUY order book should be ordered on price from highest to lowest starting at index 0
// The SELL order book should be ordered on price from lowest to highest starting at index 0
// The User should not be able to create for not supported tokens

const Dex = artifacts.require("Dex");
const ChainLink = artifacts.require("ChainLink");
const truffleAssert = require('truffle-assertions');

contract("Dex", accounts => {

    it("should only be possible to create a BUY limit order that the user can afford", async () => {
        let dex = await Dex.deployed()

        await truffleAssert.reverts(
            dex.createLimitOrder(0, web3.utils.fromUtf8("LINK"), 10, 1)
        )

        await dex.depositETH({value: 10});

        await truffleAssert.passes(
            dex.createLimitOrder(0, web3.utils.fromUtf8("LINK"), 10, 1)
        )
    })

    it("should only be possible to create a SELL limit order that the user can afford", async () => {
        let dex = await Dex.deployed()
        let link = await ChainLink.deployed()

        await truffleAssert.reverts(
            dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 5, 1)
        );

        await dex.addToken(web3.utils.fromUtf8("LINK"), link.address, {from: accounts[0]})
        await link.approve(dex.address, 5)
        await dex.deposit(5, web3.utils.fromUtf8("LINK"));

        await truffleAssert.passes(
            dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), 5,1)
        );
    })
    it("should order the BUY order book in decending order", async () => {
        let dex = await Dex.deployed()
        let link = await ChainLink.deployed()

        const invalidOrder = [12,2,5,9,45,3];
        await link.approve(dex.address, 1000);
        await dex.depositETH({value: 1000});
        await dex.deposit(100, web3.utils.fromUtf8("LINK"));

        for (let i = 0; i< invalidOrder.length; i++){
            await dex.createLimitOrder(0, web3.utils.fromUtf8("LINK"), invalidOrder[i], 1);
        }

        let orderBook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"), 0);
        assert(orderBook.length > 0);
        for (let i = 0; i < orderBook.length -1; i++){
            assert(orderBook[i].price >= orderBook[i+1].price, "Invalid price order")
        }
    })

    it("should order the SELL order book in ascending order", async () => {
        let dex = await Dex.deployed()
        let link = await ChainLink.deployed()

        const invalidOrder = [12, 2, 5, 9, 45, 3];
        await link.approve(dex.address, 1000);

        for (let i = 0; i< invalidOrder.length; i++){
            await dex.createLimitOrder(1, web3.utils.fromUtf8("LINK"), invalidOrder[i], 1);
        }

        let orderBook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"), 1);
        assert(orderBook.length > 0);
        for (let i = 0; i< orderBook.length -1; i++){
            assert(orderBook[i].price <= orderBook[i+1].price, "Invalid price order")
        }
    })
})