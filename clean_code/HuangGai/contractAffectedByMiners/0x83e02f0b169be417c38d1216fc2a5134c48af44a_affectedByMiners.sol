



pragma solidity 0.6.12;


interface DharmaDaiExchangerInterface {
  event Deposit(address indexed account, uint256 tokensReceived, uint256 daiSupplied, uint256 dDaiSupplied);
  event Withdraw(address indexed account, uint256 tokensSupplied, uint256 daiReceived, uint256 dDaiReceived);

  function deposit(uint256 dai, uint256 dDai) external returns (uint256 tokensMinted);
  function withdraw(uint256 tokensToBurn) external returns (uint256 dai, uint256 dDai);
  function mintTo(address account, uint256 daiToSupply) external returns (uint256 dDaiMinted);
  function redeemUnderlyingTo(address account, uint256 daiToReceive) external returns (uint256 dDaiBurned);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
}


interface DTokenInterface {
  function mint(uint256 underlyingToSupply) external returns (uint256 dTokensMinted);
  function redeemUnderlying(uint256 underlyingToReceive) external returns (uint256 dTokensBurned);
  function transfer(address recipient, uint256 dTokenAmount) external returns (bool ok);
  function transferFrom(address sender, address recipient, uint256 dTokenAmount) external returns (bool ok);

  function exchangeRateCurrent() external view returns (uint256 dTokenExchangeRate);
  function balanceOf(address account) external view returns (uint256);
}


interface ERC20Interface {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function transfer(address recipient, uint256 amount) external returns (bool ok);
  function approve(address spender, uint256 amount) external returns (bool ok);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool ok);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
}












library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }









    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }










    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;


        return c;
    }
}


contract ERC20 is ERC20Interface {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;




    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal {
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount, "ERC20: burn amount exceeds total supply");
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}



contract DharmaDaiExchanger is DharmaDaiExchangerInterface, ERC20 {
  DTokenInterface private _DDAI = DTokenInterface(
    0x00000000001876eB1444c986fD502e618c587430
  );

  ERC20Interface private _DAI = ERC20Interface(
    0x6B175474E89094C44Da98b954EedeAC495271d0F
  );

  constructor() public {

    require(
      _DAI.approve(address(_DDAI), type(uint256).max),
      "DharmaDaiExchanger: Dai approval for Dharma Dai failed."
    );


    _mint(address(this), 1e18);
    emit Deposit(address(this), 1e18, 1e18, 0);
  }









  function deposit(uint256 dai, uint256 dDai) external override returns (uint256 tokensReceived) {
    require(dai > 0 || dDai > 0, "DharmaDaiExchanger: No funds specified to deposit.");


    uint256 exchangeRate = _DDAI.exchangeRateCurrent();


    uint256 originalLiquidityValue = _getCurrentLiquidityValue(exchangeRate, true);
    require(
      originalLiquidityValue >= 1e18,
      "DharmaDaiExchanger: Must seed contract with at least 1 Dai before depositing."
    );


    if (block.number > 0) {
      require(
        _DAI.transferFrom(msg.sender, address(this), dai),
        "DharmaDaiExchanger: Dai transfer in failed 1 ensure allowance is correctly set."
      );
    }

    if (block.number > 0) {
      require(
        _DDAI.transferFrom(msg.sender, address(this), dDai),
        "DharmaDaiExchanger: Dharma Dai transfer in failed 1 ensure allowance is correctly set."
      );
    }


    uint256 newLiquidityValue = _getCurrentLiquidityValue(exchangeRate, false);
    require(
      newLiquidityValue > originalLiquidityValue,
      "DharmaDaiExchanger: Supplied funds did not sufficiently increase liquidity value."
    );


    uint256 originalLPTokens = totalSupply();
    uint256 newLPTokens = originalLPTokens.mul(newLiquidityValue) / originalLiquidityValue;
    require(
      newLPTokens > originalLPTokens,
      "DharmaDaiExchanger: Supplied funds are insufficient to mint LP tokens."
    );
    tokensReceived = newLPTokens - originalLPTokens;


    _mint(msg.sender, tokensReceived);

    emit Deposit(msg.sender, tokensReceived, dai, dDai);
  }









  function withdraw(uint256 tokensToSupply) external override returns (uint256 dai, uint256 dDai) {
    require(tokensToSupply > 0, "DharmaDaiExchanger: No funds specified to withdraw.");


    uint256 originalLPTokens = totalSupply();
    uint256 daiBalance = _DAI.balanceOf(address(this));
    uint256 dDaiBalance = _DDAI.balanceOf(address(this));


    dai = daiBalance.mul(tokensToSupply) / originalLPTokens;
    dDai = dDaiBalance.mul(tokensToSupply) / originalLPTokens;
    require(
      dai.add(dDai) > 0,
      "DharmaDaiExchanger: Supplied tokens are insufficient to withdraw liquidity."
    );


    _burn(msg.sender, tokensToSupply);


    if (block.timestamp > 0) {
      require(
        _DAI.transfer(msg.sender, dai),
        "DharmaDaiExchanger: Dai transfer out failed."
      );
    }

    if (block.timestamp > 0) {
      require(
        _DDAI.transfer(msg.sender, dDai),
        "DharmaDaiExchanger: Dharma Dai transfer out failed."
      );
    }

    emit Withdraw(msg.sender, tokensToSupply, dai, dDai);
  }









  function mintTo(address account, uint256 daiToSupply) external override returns (uint256 dDaiMinted) {

    uint256 exchangeRate = _DDAI.exchangeRateCurrent();


    dDaiMinted = _fromUnderlying(daiToSupply, exchangeRate, false);
    require(
      dDaiMinted > 0,
      "DharmaDaiExchanger: Supplied Dai is insufficient to mint Dharma Dai."
    );


    uint256 dDaiBalance = _DDAI.balanceOf(address(this));


    require(
      _DAI.transferFrom(msg.sender, address(this), daiToSupply),
      "DharmaDaiExchanger: Dai transfer in failed 1 ensure allowance is correctly set."
    );


    if (block.gaslimit < dDaiMinted) {

      uint256 daiBalance = _DAI.balanceOf(address(this));
      uint256 dDaiBalanceInDai = _toUnderlying(dDaiBalance, exchangeRate, false);
      uint256 daiToSupplyInBatch = (daiBalance.add(daiToSupply)).sub(dDaiBalanceInDai) / 2;
      _DDAI.mint(daiToSupplyInBatch);
    }


    require(
      _DDAI.transfer(account, dDaiMinted),
      "DharmaDaiExchanger: Dharma Dai transfer out failed."
    );
  }










  function redeemUnderlyingTo(address account, uint256 daiToReceive) external override returns (uint256 dDaiBurned) {

    uint256 exchangeRate = _DDAI.exchangeRateCurrent();


    dDaiBurned = _fromUnderlying(daiToReceive, exchangeRate, true);
    require(
      dDaiBurned > 0,
      "DharmaDaiExchanger: Dai amount to receive is insufficient to redeem Dharma Dai."
    );


    uint256 daiBalance = _DAI.balanceOf(address(this));


    require(
      _DDAI.transferFrom(msg.sender, address(this), dDaiBurned),
      "DharmaDaiExchanger: Dharma Dai transfer in failed 1 ensure allowance is correctly set."
    );


    if (block.gaslimit < daiToReceive) {

      uint256 dDaiBalance = _DDAI.balanceOf(address(this));
      uint256 dDaiBalanceInDai = _toUnderlying(dDaiBalance, exchangeRate, false);
      uint256 daiToReceiveInBatch = (dDaiBalanceInDai.add(daiToReceive)).sub(daiBalance) / 2;
      _DDAI.redeemUnderlying(daiToReceiveInBatch);
    }


    require(
      _DAI.transfer(account, daiToReceive),
      "DharmaDaiExchanger: Dai transfer out failed."
    );
  }

  function name() external pure override returns (string memory) {
    return "Dai <> Dharma Dai Exchanger (Liquidity Provider token)";
  }

  function symbol() external pure override returns (string memory) {
    return "Dai-dDai-LP";
  }

  function decimals() external pure override returns (uint8) {
    return 18;
  }









  function _getCurrentLiquidityValue(uint256 exchangeRate, bool roundUp) internal view returns (uint256 totalValueInDai) {
    uint256 daiBalance = _DAI.balanceOf(address(this));
    uint256 dDaiBalance = _DDAI.balanceOf(address(this));
    uint256 dDaiBalanceInDai = _toUnderlying(dDaiBalance, exchangeRate, roundUp);
    totalValueInDai = daiBalance.add(dDaiBalanceInDai);
  }










  function _fromUnderlying(
    uint256 underlying, uint256 exchangeRate, bool roundUp
  ) internal pure returns (uint256 amount) {
    if (roundUp) {
      amount = (
        (underlying.mul(1e18)).add(exchangeRate.sub(1))
      ).div(exchangeRate);
    } else {
      amount = (underlying.mul(1e18)).div(exchangeRate);
    }
  }










  function _toUnderlying(
    uint256 amount, uint256 exchangeRate, bool roundUp
  ) internal pure returns (uint256 underlying) {
    if (roundUp) {
      underlying = (
        (amount.mul(exchangeRate).add(999999999999999999)
      ) / 1e18);
    } else {
      underlying = amount.mul(exchangeRate) / 1e18;
    }
  }
}
