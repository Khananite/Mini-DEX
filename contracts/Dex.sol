pragma solidity >=0.4.22 <0.9.0;

import "./Wallet.sol";

contract Dex is Wallet
{
    enum buyOrSell
    {
        BUY,
        SELL
    }

    //Order struct for the order book.
    struct Order
    {
        uint256 id;
        address trader;
        buyOrSell buyOrSell;
        bytes32 ticker;
        uint amount;
        uint price;
        uint filled;
    }

    //Order book split into 2:
    //1. We have the bids and the asks.
    //2. One order book for each asset.
    //The below mapping points from an asset to another mapping of uint, which represets
    //the enum (BUY/SELL), this points to a list of orders.
    //Now we have one order book for buy and one order book for sell for each asset.
    mapping(bytes32 => mapping(uint => Order[])) orderBook;

    uint public nextOrderId = 0;

    function getOrderBook(bytes32 ticker, buyOrSell buySell) view public returns(Order[] memory)
    {
        return orderBook[ticker][uint(buySell)];
    }

    //Adding orders into order book.
    function createLimitOrder(buyOrSell buySell, bytes32 ticker, uint amount, uint price) public
    {
        if(buySell == buyOrSell.BUY)
        {
            require(balances[msg.sender]["ETH"] >= amount * price);

        }
        else if(buySell == buyOrSell.SELL)
        {
            require(balances[msg.sender][ticker] >= amount);
        }

        Order[] storage orders = orderBook[ticker][uint(buySell)];
        orders.push(Order(nextOrderId, msg.sender, buySell, ticker, amount, price, 0));

        if(orders.length > 0)
        {
            //Bubble sort.
            //Sort BUY side.
            if(buySell == buyOrSell.BUY)
            {
                for(uint i = orders.length - 1; i > 0; i--)
                {
                    if(orders[i].price > orders[i-1].price)
                    {
                        Order storage temp = orders[i];
                        orders[i] = orders[i-1];
                        orders[i-1] = temp;
                    }
                    else
                        break;
                }
            }
            //Sort SELL side.
            else if(buySell == buyOrSell.SELL)
            {
                for(uint i = 0; i < orders.length-1; i++)
                {
                    if(orders[i].price > orders[i+1].price)
                    {
                        Order storage temp = orders[i];
                        orders[i] = orders[i+1];
                        orders[i+1] = temp;
                    }
                    else
                        break;
                }
            }
        }
        nextOrderId++;
    }

    function createMarketOrder(buyOrSell buySell, bytes32 ticker, uint amount) public
    {
        if(buySell == buyOrSell.SELL)
            require(balances[msg.sender][ticker] >= amount, "Insufficient balance");
        uint orderBookBuySell;

        if(buySell == buyOrSell.BUY)
        {
            orderBookBuySell = 1;
        }
        else
        {
            orderBookBuySell = 0;
        }

        Order[] storage orders = orderBook[ticker][orderBookBuySell];
        

        ///////////////////How much we can fill from order[i]
        ///////////////////Update totalFilled.

        //How much have we filled of the market order.
        uint totalFilled = 0;

        //totalFilled < amount, means if we've filled the order book.
        for(uint256 i = 0; i < orders.length && totalFilled < amount; i++)
        {
            uint leftToFill = amount - totalFilled;
            uint availableToFill = orders[i].amount - orders[i].filled;
            uint filled = 0;
            if(availableToFill > leftToFill)
            {
                //Fill the entire market order.
                filled = leftToFill;
            }
            else
            {
                //Fill as much as is available in order[i]
                filled = availableToFill;
            }

            totalFilled = totalFilled + filled;
            orders[i].filled = orders[i].filled + filled;
            uint cost = filled * orders[i].price;

            //Execute the trade and shift balances between buyer/seller.
            if(buySell == buyOrSell.BUY)
            {
                //Verify that the market order trader has enough ETH to cover.
                require(balances[msg.sender]["ETH"] >= cost);
                
                //msg.sender is the buyer.
                //Transfer ETH from buyer to seller.
                //Transfer tokens from seller to buyer.
                balances[msg.sender][ticker] = (balances[msg.sender][ticker] + filled);	
                balances[msg.sender]["ETH"] = (balances[msg.sender]["ETH"] - cost);	
                	
                balances[orders[i].trader][ticker] = (balances[orders[i].trader][ticker] - filled);	
                balances[orders[i].trader]["ETH"] = (balances[orders[i].trader]["ETH"] + cost);
            }
            else if(buySell == buyOrSell.SELL)
            {
                //msg.sender is the seller.
                balances[msg.sender][ticker] = (balances[msg.sender][ticker] - filled);
                balances[msg.sender]["ETH"] = (balances[msg.sender]["ETH"] + cost);

                balances[orders[i].trader][ticker] = (balances[orders[i].trader][ticker] + filled);
                balances[orders[i].trader]["ETH"] = (balances[orders[i].trader]["ETH"] - cost);
            }
        }

        //Loop through the orderbook and remove 100% filled orders from the order book.
        while(orders.length > 0 && orders[0].filled == orders[0].amount)
        {
            //Remove top element in the top orders array by overwritting every
            //element with the next element in the order list.
            for(uint256 i = 0; i < orders.length - 1; i++)
            {
                orders[i] = orders[i + 1];
            }
            orders.pop();
        }
    }
}
