pragma solidity ^0.6.0;
//SPDX-License-Identifier: UNLICENSED

import "./Core.sol";


// 
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


    // Pause for allowing tokens to only become transferable at the end of sale

      address public pauser;

      address public realowner;

      bool public paused;


     modifier onlyPauser() {
        require(pauser == _msgSender(), "Token: caller is not the pauser.");
        _;
    }


    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint256 totalSupply, uint8 decimals, address _owner) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;

        realowner = _owner;
       
        _mint(_owner, totalSupply);
        paused = true;
    }


     function setPauser(address newPauser) public {

        
        require(msg.sender == realowner, "Token: owner .");
        require(newPauser != address(0), "Token: pauser is the zero address.");
        pauser = newPauser;
    }

    function unpause() external onlyPauser {
        paused = false;

        
    }



    //only pauser can burn from himself to 0x0
    function burnIt(uint256 amount) public onlyPauser {

        _burn(pauser, amount);
        

    }



    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { 

    require(!paused || msg.sender == pauser || msg.sender == realowner, "Token: token transfer while paused and not pauser role.");

    }


    
}





//RUDY LAUNCHPOOL


contract RudyLaunchpool is Ownable {

    //rudy token

    IERC20 public rudyToken;

    IUniswapV2Router02 public _uniswapRouter;

    uint256 public triggerAm;

    // index of created launches

    Crowdsale[] public launches;


    constructor (IERC20 _rudyToken, IUniswapV2Router02 uniswapRouter  , uint256 _triggerAm) public {

        rudyToken = _rudyToken;

        triggerAm = _triggerAm;

        _uniswapRouter = uniswapRouter;

    }


    

    function changeTriggerAm(uint256 _newtriggerAm) external onlyOwner {


        triggerAm = _newtriggerAm;

    }

    function changeRouter(IUniswapV2Router02 _newRouter) external onlyOwner {


        _uniswapRouter = _newRouter;

    }

    // useful to know the row count in launches index

    function getLaunchesCount() public view returns(uint launchesCount) {
   
    return launches.length;
    
    }

    // deploy a new launch

    function newLaunch(IERC20 _Token, bool customToken, string memory name, string memory symbol, uint256 totalSupply, uint256 _ROUND_MAX_CAP, uint256 _MIN_CONTRIBUTION, uint256 _HARDCAP, uint256 _CROWDSALE_START_TIME,uint256 _CROWDSALE_END_TIME, uint256 _TOKEN_PER_ETH, uint256 _TOKEN_PER_ETH_LIST, uint256 _MAX_CONTRIBUTION, uint256 _LIQPERC) public returns(Crowdsale newContract) {


        

        if (!customToken){

            _Token = new ERC20(name, symbol,totalSupply,18,msg.sender);

            }else{

                //require rudy holding

                require(rudyToken.balanceOf(msg.sender) >= triggerAm);
                _Token = _Token;
            }


            return createLaunch(_Token, _ROUND_MAX_CAP, _MIN_CONTRIBUTION, _HARDCAP, _CROWDSALE_START_TIME, _CROWDSALE_END_TIME, _TOKEN_PER_ETH, _TOKEN_PER_ETH_LIST, _MAX_CONTRIBUTION, _LIQPERC);
    
    
  }

  function createLaunch(IERC20 _Token, uint256 _ROUND_MAX_CAP, uint256 _MIN_CONTRIBUTION, uint256 _HARDCAP, uint256 _CROWDSALE_START_TIME,uint256 _CROWDSALE_END_TIME, uint256 _TOKEN_PER_ETH, uint256 _TOKEN_PER_ETH_LIST, uint256 _MAX_CONTRIBUTION, uint256 _LIQPERC) internal returns(Crowdsale newContract) {

    Crowdsale c = new Crowdsale(_Token, _ROUND_MAX_CAP, _MIN_CONTRIBUTION, _HARDCAP, _CROWDSALE_START_TIME, _CROWDSALE_END_TIME, _TOKEN_PER_ETH, _uniswapRouter, _TOKEN_PER_ETH_LIST, _MAX_CONTRIBUTION, _LIQPERC);

    launches.push(c);
    return c;


  }



}


//YOUR TOKEN NEED UNPAUSE AND BURNIT FUNCTION SO IT CAN PREVENT THE CREATION OF THE PAIR WHILE IN LAUNCH
//AND BURN LEFT OVER TOKEN TO 0X0




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