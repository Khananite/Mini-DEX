//We are creating this mock ERC20 token contract as a test, to test our wallet.

pragma solidity >=0.4.22 <0.9.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";


//Creating a chain link type ERC20 token as a test.
contract ChainLink is ERC20
{
    constructor() ERC20("Chainlink", "LINK")
    {
        _mint(msg.sender, 1000);
    }
}