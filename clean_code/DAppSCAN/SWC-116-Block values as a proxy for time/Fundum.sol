

pragma solidity ^0.8.4;

import "./Address.sol";
import "./IBEP20.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Uniswap.sol";

contract Fundum is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => bool) private _isExcludedFromFee;

  uint256 private _totalSupply = 250 * 10**6 * 10**9;

  string private _name = "FUNDUM";
  string private _symbol = "FUNDUM";
  uint8 private _decimals = 9;

  address public deployerWallet = 0x38Af5Fb037ecD3F0589682b32cE30A9Db183c887;
  address public release2Wallet = 0xb8BFE1537003Ec28886E7815825aDb728f763D95;
  address public teamWallet = 0xaDe9a25c271a9d804968f1a843591a3C8Ff42a5D;
  address public marketingWallet = 0x9D0F1e9C087cEA08fFEF6afdACdFa2A07c001F8c;
  address public buybackWallet = 0xCCB24e0bb00064e465b916533950870CeD737476;
  address public lp2Wallet = 0xf46F57debA545b281c515D064ECD9Da598EF7cf0;

  uint8 public taxFee = 10;
  uint256 public totalTax = 0;

  uint256 public remainTax = 0;
  uint256 public minSwapBalance = 1000 * 10**9;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = false;
  bool public openTrading = false;


  address public busdAddress = 0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47;
  address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

  IUniswapV2Router02 public immutable uniswapV2Router;
  address public uniswapV2Pair;


  uint256 public lp1Tokens = 666666666667;
  uint256 public lp2Tokens = 199333333333333;
  uint256 public reserveTokens;
  uint256 public tradeTokens;

  event OpenTradingEnabledUpdated(bool enabled);
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );
  event SwapTokensForBUSD(
      uint256 amountIn,
      address[] path
  );

  modifier lockTheSwap {
      inSwapAndLiquify = true;
      _;
      inSwapAndLiquify = false;
  }

  constructor() {
    reserveTokens = _totalSupply.mul(40).div(100);
    tradeTokens = _totalSupply.sub(lp1Tokens).sub(lp2Tokens).sub(reserveTokens);


    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), busdAddress);
    uniswapV2Router = _uniswapV2Router;

    _isExcludedFromFee[deployerWallet] = true;
    _isExcludedFromFee[release2Wallet] = true;
    _isExcludedFromFee[teamWallet] = true;
    _isExcludedFromFee[marketingWallet] = true;
    _isExcludedFromFee[buybackWallet] = true;
    _isExcludedFromFee[lp2Wallet] = true;
    _isExcludedFromFee[address(this)] = true;

    _balances[deployerWallet] = lp1Tokens;

    _balances[lp2Wallet] = lp2Tokens;

    _balances[release2Wallet] = reserveTokens;

    _balances[address(this)] = tradeTokens;

    emit Transfer(address(0), deployerWallet, lp1Tokens);
    emit Transfer(address(0), lp2Wallet, lp2Tokens);
    emit Transfer(address(0), release2Wallet, reserveTokens);
    emit Transfer(address(0), address(this), tradeTokens);
  }




  function getOwner() external override view returns (address) {
    return owner();
  }




  function decimals() external override view returns (uint8) {
    return _decimals;
  }




  function symbol() external override view returns (string memory) {
    return _symbol;
  }




  function name() external override view returns (string memory) {
    return _name;
  }




  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }




  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }









  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }




  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }








  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }













  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }













  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }















  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }
















  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    if(!openTrading){
        require(_msgSender() != address(uniswapV2Router) && _msgSender() != uniswapV2Pair, "ERR: disable adding liquidity");
    }

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");

    bool takeFee = true;


    if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
        takeFee = false;
    }

    if (!inSwapAndLiquify && swapAndLiquifyEnabled && recipient == uniswapV2Pair) {
      remainTax = _balances[address(this)].sub(tradeTokens);
      if(remainTax >= minSwapBalance)
        _distributeTaxFees(remainTax);
    }

    if(takeFee){
      uint256 fee = amount.mul(taxFee).div(100);
      uint256 transAmount = amount.sub(fee);

      totalTax = totalTax.add(fee);

      _balances[recipient] = _balances[recipient].add(transAmount);
      _balances[address(this)] = _balances[address(this)].add(fee);

      emit Transfer(sender, recipient, transAmount);
      emit Transfer(sender, address(this), fee);
    }else{
        if(recipient == buybackWallet){
          _balances[deadAddress] = _balances[deadAddress].add(amount);

          emit Transfer(sender, deadAddress, amount);
        }else{
          _balances[recipient] = _balances[recipient].add(amount);

          emit Transfer(sender, recipient, amount);
        }
    }
  }















  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }


  function swapAndLiquify(uint256 contractTokenBalance) private {

    uint256 half = contractTokenBalance.div(2);
    uint256 otherHalf = contractTokenBalance.sub(half);





    uint256 initialBalance = address(this).balance;


    swapTokensForETH(half);


    uint256 newBalance = address(this).balance.sub(initialBalance);


    addLiquidity(otherHalf, newBalance);

    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

      _approve(address(this), address(uniswapV2Router), tokenAmount);


      uniswapV2Router.addLiquidityETH{value: ethAmount}(
          address(this),
          tokenAmount,
          0,
          0,
          owner(),
          block.timestamp
      );
  }

  function swapTokensForETH(uint256 tokenAmount) private lockTheSwap {

      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = uniswapV2Router.WETH();

      _approve(address(this), address(uniswapV2Router), tokenAmount);


      uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
          tokenAmount,
          0,
          path,
          address(this),
          block.timestamp
      );
  }

  function swapTokensForBUSD(address toAddress, uint256 tokenAmount) private {

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = busdAddress;

        _approve(address(this), address(uniswapV2Router), tokenAmount);


        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            toAddress,
            block.timestamp.add(120)
        );

        emit SwapTokensForBUSD(tokenAmount, path);
  }

  function _distributeTaxFees(uint256 taxBalance) private {
    swapAndLiquify(taxBalance.mul(5).div(10));

    swapTokensForBUSD(teamWallet, taxBalance.mul(1).div(10));

    swapTokensForBUSD(marketingWallet, taxBalance.mul(2).div(10));

    swapTokensForBUSD(buybackWallet, taxBalance.mul(2).div(10));

    if(1000 * 10**9 < _balances[uniswapV2Pair] && _balances[uniswapV2Pair] < 2 * 10**5 * 10**9){
      uint256 lessAmount = 2 * 10**5 * 10**9 - _balances[uniswapV2Pair];

      tradeTokens = tradeTokens.sub(lessAmount);
      _balances[address(this)] = _balances[address(this)].sub(lessAmount);
      _balances[uniswapV2Pair] = _balances[uniswapV2Pair].add(lessAmount);
      emit Transfer(address(this), uniswapV2Pair, lessAmount);
    }
  }

  function updateMinSwapBalance(uint256 _minBalance) public onlyOwner {
    minSwapBalance = _minBalance * 10**9;
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  function setOpenTrading(bool _enabled) public onlyOwner {
    openTrading = _enabled;
    emit OpenTradingEnabledUpdated(_enabled);
  }

  function prepareForPreSale() public onlyOwner {
    setSwapAndLiquifyEnabled(false);
    setOpenTrading(false);
    taxFee = 0;
  }

  function afterPreSale() public onlyOwner {
    setSwapAndLiquifyEnabled(true);
    setOpenTrading(true);
    taxFee = 10;
  }


  receive() external payable {}
}
