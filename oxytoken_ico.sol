// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import './oxytoken.sol';
// import './oxytoken_oracle.sol';
interface OxyTokenSale_Oracle {
    function setTokenPrice(uint256 _price) external;
    function getTokenPrice() external view returns(uint256);
}

contract OxyTokenCrowdSale {
    using SafeMath for uint256;
    
    address public admin;               // owner of the crowd sale 
    OxyToken public tokenContract;
    // uint256 public tokenPrice;          // price of token in wei; 1 token = 10000000000000000 wei; 1 token = 0.01 ether
    uint256 public tokensSold;          // no. of tokens sold in crowd sale
    // uint256 public fundingGoal;         // funds need to be received through this sale, in wei 
    
    bool isICORunning;
    
    OxyTokenSale_Oracle public oracleContract;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor(OxyToken _tokenContract, OxyTokenSale_Oracle _oracleContractAddress) {
        require(OxyToken(_tokenContract) != OxyToken(address(0)), 'Invalid token contract address given');
        
        admin = msg.sender;
        tokenContract = _tokenContract;
        
        oracleContract = OxyTokenSale_Oracle(_oracleContractAddress);
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    modifier whenICOEnded() {
        require(isICORunning == false);
        _;
    }
    
    function setPrice(uint256 _tokenPrice) public onlyAdmin {
        require(_tokenPrice > 0, 'Token Price should be greater than 0');
        
        // tokenPrice = _tokenPrice;
        oracleContract.setTokenPrice(_tokenPrice);
    }
    
    function startICO() public onlyAdmin {
        isICORunning = true;
    }
    
    function endICO() public onlyAdmin {
        isICORunning = false;
    }
    
    // function is payable here because ethers will be sent with this function
    function buyToken() public payable {
        
        require(isICORunning == true, 'Cannot buy tokens, ICO not running');
        
        require(msg.value > 0, 'Invalid amount given');
        
        // uint256 _tokensToTransfer = msg.value.div(tokenPrice);
        
        uint256 _tokensToTransfer = msg.value.div(oracleContract.getTokenPrice());
        
        // Check if Crowd Sale contract has enough tokens
        require(OxyToken(tokenContract).balanceOf(address(this)) >= _tokensToTransfer, "Insufficient tokens");
        
        // Give tokens to the user
        OxyToken(tokenContract).transfer(msg.sender, _tokensToTransfer);
        
        tokensSold = tokensSold.add(_tokensToTransfer);
        
        emit Transfer(address(this), msg.sender, _tokensToTransfer);
    }
    
    function returnTokensToICO(uint256 _tokenAmountToReturn) public {
        // uint256 balanceToReturn = _tokenAmountToReturn.mul(tokenPrice);
        uint256 balanceToReturn = _tokenAmountToReturn.mul(oracleContract.getTokenPrice());
        OxyToken(tokenContract).transfer(msg.sender, balanceToReturn);
        
        // Approve the token so that it can transfer tokens from msg.sender to ico contract
        
        OxyToken(tokenContract).transferFrom(msg.sender, address(this), _tokenAmountToReturn);
        emit Transfer(msg.sender, address(this), _tokenAmountToReturn);
        
        OxyToken(tokenContract).transfer(msg.sender, balanceToReturn);
        emit Transfer(address(this), msg.sender, _tokenAmountToReturn);
    }
    
    function withdrawRaisedFunds() public onlyAdmin whenICOEnded {
        uint256 raisedFunds = OxyToken(tokenContract).balanceOf(address(this));
        OxyToken(tokenContract).transfer(admin, raisedFunds);
    }
    
    // function transferTokenToSaleContractAdmin() public onlyAdmin {
    //     uint256 _totalTokens = tokenContract.totalSupply();
    //     OxyToken(tokenContract).transfer(admin, _totalTokens);
    // }
}
