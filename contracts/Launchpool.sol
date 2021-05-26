pragma solidity ^0.6.0;
//SPDX-License-Identifier: UNLICENSED

import "./Core.sol";






//RUDY LAUNCHPOOL


contract RudyLaunchpool is Ownable {

    // index of created launches

    Crowdsale[] public launches;


    // useful to know the row count in launches index

    function getLaunchesCount() public view returns(uint launchesCount) {
   
    return launches.length;
    
    }

    // deploy a new launch

    function newLaunch(IERC20 _Token, uint256 _ROUND_MAX_CAP, uint256 _MIN_CONTRIBUTION, uint256 _HARDCAP, uint256 _CROWDSALE_START_TIME,uint256 _CROWDSALE_END_TIME, uint256 _TOKEN_PER_ETH, IUniswapV2Router02 _uniswapRouter, uint256 _TOKEN_PER_ETH_LIST, uint256 _MAX_CONTRIBUTION, uint256 _LIQPERC) public returns(Crowdsale newContract) {
    
    Crowdsale c = new Crowdsale(_Token, _ROUND_MAX_CAP, _MIN_CONTRIBUTION, _HARDCAP, _CROWDSALE_START_TIME, _CROWDSALE_END_TIME, _TOKEN_PER_ETH, _uniswapRouter, _TOKEN_PER_ETH_LIST, _MAX_CONTRIBUTION, _LIQPERC);

    launches.push(c);
    return c;
  }

}


//YOUR TOKEN NEED UNPAUSE AND BURNIT FUNCTION SO IT CAN PREVENT THE CREATION OF THE PAIR WHILE IN LAUNCH
//AND BURN LEFT OVER TOKEN TO 0X0

//THIS IS BUILT IN RUDY TOKENS ANYWAY 
interface Pauseable {
    function unpause() external; 

    function burnIt(uint256 amounts) external;
}




contract Crowdsale is Ownable {
    using SafeMath for uint256;


    // Caps
    uint256 public ROUND_MAX_CAP;
    uint256 public MAX_CONTRIBUTION;
    uint256 public MIN_CONTRIBUTION;
    uint256 public HARDCAP; 

    // Start time 
    uint256 public CROWDSALE_START_TIME;

    // End time
    uint256 public CROWDSALE_END_TIME;

    
    uint256 public TOKEN_PER_ETH;


    uint256 public TOKEN_PER_ETH_LIST;

    uint256 public LIQPERC;



  
    // Contributions state
    mapping(address => uint256) public contributions;

    uint256 public weiRaised;

    bool public liquidityLocked = false;

    IERC20 public Token;

    IUniswapV2Router02 internal uniswapRouter;

    event TokenPurchase(address indexed beneficiary, uint256 weiAmount, uint256 tokenAmount);

    constructor(IERC20 _Token, uint256 _ROUND_MAX_CAP, uint256 _MIN_CONTRIBUTION, uint256 _HARDCAP, uint256 _CROWDSALE_START_TIME,uint256 _CROWDSALE_END_TIME, uint256 _TOKEN_PER_ETH, IUniswapV2Router02 _uniswapRouter, uint256 _TOKEN_PER_ETH_LIST, uint256 _MAX_CONTRIBUTION, uint256 _LIQPERC) Ownable() public {

        Token = _Token;


        ROUND_MAX_CAP =_ROUND_MAX_CAP;
        MIN_CONTRIBUTION =_MIN_CONTRIBUTION;
        MAX_CONTRIBUTION = _MAX_CONTRIBUTION;
        HARDCAP =_HARDCAP;
        CROWDSALE_START_TIME =_CROWDSALE_START_TIME;
        CROWDSALE_END_TIME =_CROWDSALE_END_TIME;
        TOKEN_PER_ETH =_TOKEN_PER_ETH;
        uniswapRouter =_uniswapRouter;
        TOKEN_PER_ETH_LIST = _TOKEN_PER_ETH_LIST;
        LIQPERC = _LIQPERC;
    }



    receive() payable external {
        // Prevent owner from buying tokens, but allow them to add pre-sale ETH to the contract for Pancakeswap liquidity
        if (owner() != msg.sender) {
            _buyTokens(msg.sender);
        }
    }

    function _buyTokens(address beneficiary) internal {
        uint256 weiToHardcap = HARDCAP.sub(weiRaised);
        uint256 weiAmount = weiToHardcap < msg.value ? weiToHardcap : msg.value;

        _buyTokens(beneficiary, weiAmount);

        uint256 refund = msg.value.sub(weiAmount);
        if (refund > 0) {
            payable(beneficiary).transfer(refund);
        }
    }

    function _buyTokens(address beneficiary, uint256 weiAmount) internal {
        _validatePurchase(beneficiary, weiAmount);

        // Update internal state
        weiRaised = weiRaised.add(weiAmount);
        contributions[beneficiary] = contributions[beneficiary].add(weiAmount);

        // Transfer tokens
        uint256 tokenAmount = _getTokenAmount(weiAmount);
        Token.transfer(beneficiary, tokenAmount);

        emit TokenPurchase(beneficiary, weiAmount, tokenAmount);
    }

    function _validatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(isOpen(), "Crowdsale: sale did not start yet.");
        require(!hasEnded(), "Crowdsale: sale is over.");
        require(weiAmount >= MIN_CONTRIBUTION, "Crowdsale: weiAmount is smaller than min contribution.");
        require(weiAmount >= MAX_CONTRIBUTION, "Crowdsale: weiAmount is smaller than min contribution.");

        require(isWithinCappedSaleWindow(weiAmount,beneficiary) , "Crowdsale: weiAmount is bigger than max contribution.");
        this; 
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(TOKEN_PER_ETH);
    }

    function _getTokenAmountForDexRate(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(TOKEN_PER_ETH_LIST);
    }

    function isOpen() public view returns (bool) {
        return now >= CROWDSALE_START_TIME;
    }

    function isWithinCappedSaleWindow(uint256 weiAmount, address _who) public view returns (bool) {
        return contributions[_who].add(weiAmount) <= ROUND_MAX_CAP;
    }

    function hasEnded() public view returns (bool) {
        return now >= CROWDSALE_END_TIME || weiRaised >= HARDCAP;
    }



    // Pancakeswap

    function addAndLockLiquidity() external {
        require(hasEnded(), "Crowdsale: can only send liquidity once hardcap is reached");

        uint256 amountEthForUniswap = address(this).balance;

        uint256 amountotlp = (amountEthForUniswap.mul(LIQPERC)).div(100);
        
       

        uint256 tokenAmount = _getTokenAmountForDexRate(amountotlp);
        
      
        
        // Unpause transfers forever
        Pauseable(address(Token)).unpause();
        
        // Send the entire balance and all tokens in the contract to Pancakeswap LP
        Token.approve(address(uniswapRouter), tokenAmount);
        uniswapRouter.addLiquidityETH
        { value: amountotlp }
        (
            address(Token),
            tokenAmount,
            tokenAmount,
            amountotlp,
            address(0), // burn address
            now
        );
        
        
      
        uint256 actualBalance = Token.balanceOf(address(this));

        uint256 amountEthForUniswapNow = address(this).balance;

        
         if (actualBalance > 0 ){
            Pauseable(address(Token)).burnIt(actualBalance);
        }        

        if(amountEthForUniswapNow > 0){

            payable(owner()).transfer(amountEthForUniswapNow);
        }
        
        liquidityLocked = true;
       
    }


     


    
}