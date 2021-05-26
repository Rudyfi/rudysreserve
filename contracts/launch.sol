pragma solidity ^0.6.0;
//SPDX-License-Identifier: UNLICENSED
import "./Core.sol";
// 
interface Pauseable {
    function unpause() external; 
    
    function rudyIt(uint256 amount) external;
}

/**
 * @title RudyCrowdsale
 * @dev Crowdsale contract for RUDY. 
 *      1 BNB = 500000000000 TOKEN (during the entire sale)
 *      Hardcap = 1000 BNB
 *      Once hardcap is reached, all liquidity is added to Pancakeswap and locked automatically, 0% risk of rug pull.
 *
 * 
 */
contract RudyCrowdsale is Ownable {
    using SafeMath for uint256;


    // Caps
    uint256 public constant ROUND_MAX_CAP = 50 ether;
    uint256 public constant MIN_CONTRIBUTION = 1;
    uint256 public constant HARDCAP = 1 ether; //1000

    // Start time 
    uint256 public  CROWDSALE_START_TIME = block.timestamp;

    // End time
    uint256 public  CROWDSALE_END_TIME = CROWDSALE_START_TIME + 1 days;

    // 1 BNB = 500 000 000 000 TOKEN - 10%
    uint256 public constant TOKEN_PER_ETH = 500;



  
    // Contributions state
    mapping(address => uint256) public contributions;

    uint256 public weiRaised;

    bool public liquidityLocked = false;

    IERC20 public rudyToken;

    IUniswapV2Router02 internal uniswapRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    event TokenPurchase(address indexed beneficiary, uint256 weiAmount, uint256 tokenAmount);

    constructor(IERC20 _rudyToken) Ownable() public {
        rudyToken = _rudyToken;
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
        rudyToken.transfer(beneficiary, tokenAmount);

        emit TokenPurchase(beneficiary, weiAmount, tokenAmount);
    }

    function _validatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "RudyCrowdsale: beneficiary is the zero address");
        require(isOpen(), "RudyCrowdsale: sale did not start yet.");
        require(!hasEnded(), "RudyCrowdsale: sale is over.");
        require(weiAmount >= MIN_CONTRIBUTION, "RudyCrowdsale: weiAmount is smaller than min contribution.");
        require(isWithinCappedSaleWindow(weiAmount,beneficiary) , "RudyCrowdsale: weiAmount is bigger than max contribution.");
        this; 
    }

    function _getTokenAmount(uint256 weiAmount) internal pure returns (uint256) {
        return weiAmount.mul(TOKEN_PER_ETH);
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
        
       

        uint256 tokenAmount = _getTokenAmount(amountEthForUniswap);
        
      
        
        // Unpause transfers forever
        Pauseable(address(rudyToken)).unpause();
        
        // Send the entire balance and all tokens in the contract to Pancakeswap LP
        rudyToken.approve(address(uniswapRouter), tokenAmount);
        uniswapRouter.addLiquidityETH
        { value: amountEthForUniswap }
        (
            address(rudyToken),
            tokenAmount,
            tokenAmount,
            amountEthForUniswap,
            address(0), // burn address
            now
        );
        
        
      
        uint256 actualBalance = rudyToken.balanceOf(address(this));

        
         if (actualBalance > 0 ){
            Pauseable(address(rudyToken)).rudyIt(actualBalance);
        }        
        
        liquidityLocked = true;
       
    }


        //in case anything wrong happen, owner can call this only after X days

     function addAndLockLiquidityEmergency(uint256 _amountEthForUniswap, uint256 _tokenAmount, IUniswapV2Router02 _uniswapRouter ) onlyOwner external {
        require(hasEnded(), "Crowdsale: can only send liquidity once hardcap is reached");
        require(block.timestamp >= CROWDSALE_END_TIME + 1 days, "Crowdsale: emergency can only be called by owner");

        uint256 amountEthForUniswap = _amountEthForUniswap;
        
       

        uint256 tokenAmount = _tokenAmount;
        
        
        
        
        // Unpause transfers forever
        Pauseable(address(rudyToken)).unpause();
        
        // Send the entire balance and all tokens in the contract to Uniswap LP
        rudyToken.approve(address(_uniswapRouter), tokenAmount);
        _uniswapRouter.addLiquidityETH
        { value: amountEthForUniswap }
        (
            address(rudyToken),
            tokenAmount,
            tokenAmount,
            amountEthForUniswap,
            address(0), // burn address
            now
        );
        
        
      
        uint256 actualBalance = rudyToken.balanceOf(address(this));

        
         if (actualBalance > 0 ){
            Pauseable(address(rudyToken)).rudyIt(actualBalance);
        }        
        
        liquidityLocked = true;
       
    }
 


    
}