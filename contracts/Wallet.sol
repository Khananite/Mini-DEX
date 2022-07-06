pragma solidity >=0.4.22 <0.9.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/Math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Wallet is Ownable {
 
    using SafeMath for uint256;
    
    //Store information about tokens.
    //In order for this DEX to trade tokens it needs to have support for the token,
    //so we save the address of the token.
    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }
    
    //Id points to the spcific token.
    mapping(bytes32 => Token) public tokenMapping;

    //Ids of the tokens.
    bytes32[] public tokenList;

    modifier tokenExist(bytes32 ticker)
    {
        //Check if token exists.
        require(tokenMapping[ticker].tokenAddress != address(0), "token does not exist");
        _;
    }

    //Keep track of multiple balanaces.
    mapping(address => mapping(bytes32 => uint256)) public balances;

    //Take information about our token and add it to the storage (ticker).
    function addToken(bytes32 ticker, address tokenAddress) onlyOwner external
    {
        tokenMapping[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }

    function deposit(uint amount, bytes32 ticker) tokenExist(ticker) external 
    {   
        balances[msg.sender][ticker] += amount;   
        IERC20(tokenMapping[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
    }

    function depositETH() payable external
    {
        balances[msg.sender][bytes32("ETH")] += msg.value;
    }
  
    function withdrawal(uint amount, bytes32 ticker) tokenExist(ticker) external 
    {      
        require(balances[msg.sender][ticker] >= amount, "Balance not sufficient");       

        balances[msg.sender][ticker] -= balances[msg.sender][ticker].sub(amount);
        IERC20(tokenMapping[ticker].tokenAddress).transfer(msg.sender, amount);
    }
}