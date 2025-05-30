




pragma solidity ^0.5.3;





library SafeMath {



    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}





interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}







library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {



        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

contract MoneyMarketInterface {
  function getSupplyBalance(address account, address asset) public view returns (uint);
  function supply(address asset, uint amount) public returns (uint);
  function withdraw(address asset, uint requestedAmount) public returns (uint);
}

contract LoanEscrow {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public constant DAI_ADDRESS = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
  IERC20 public dai = IERC20(DAI_ADDRESS);

  address public constant MONEY_MARKET_ADDRESS = 0x3FDA67f7583380E67ef93072294a7fAc882FD7E7;
  MoneyMarketInterface public moneyMarket = MoneyMarketInterface(MONEY_MARKET_ADDRESS);

  event Deposited(address indexed from, uint256 daiAmount);
  event Pulled(address indexed to, uint256 daiAmount);
  event InterestWithdrawn(address indexed to, uint256 daiAmount);

  mapping(address => uint256) public deposits;
  mapping(address => uint256) public pulls;
  uint256 public deposited;
  uint256 public pulled;

  modifier onlyBlockimmo() {
    require(msg.sender == blockimmo());
    _;
  }

  function blockimmo() public returns (address);

  function withdrawInterest() public onlyBlockimmo {
    uint256 amountInterest = moneyMarket.getSupplyBalance(address(this), DAI_ADDRESS).add(pulled).sub(deposited);
    require(amountInterest > 0, "no interest");

    uint256 errorCode = moneyMarket.withdraw(DAI_ADDRESS, amountInterest);
    require(errorCode == 0, "withdraw failed");

    dai.safeTransfer(msg.sender, amountInterest);
    emit InterestWithdrawn(msg.sender, amountInterest);
  }

  function deposit(address _from, uint256 _amountDai) internal {
    require(_from != address(0) && _amountDai > 0, "invalid parameter(s)");
    dai.safeTransferFrom(msg.sender, address(this), _amountDai);

    require(dai.allowance(address(this), MONEY_MARKET_ADDRESS) == 0, "non-zero initial moneyMarket allowance");
    require(dai.approve(MONEY_MARKET_ADDRESS, _amountDai), "approving moneyMarket failed");

    uint256 errorCode = moneyMarket.supply(DAI_ADDRESS, _amountDai);
    require(errorCode == 0, "supply failed");
    require(dai.allowance(address(this), MONEY_MARKET_ADDRESS) == 0, "allowance not fully consumed by moneyMarket");

    deposits[_from] = deposits[_from].add(_amountDai);
    deposited = deposited.add(_amountDai);
    emit Deposited(_from, _amountDai);
  }

  function pull(address _to, uint256 _amountDai, bool refund) internal {
    uint256 errorCode = moneyMarket.withdraw(DAI_ADDRESS, _amountDai);
    require(errorCode == 0, "withdraw failed");

    if (refund) {
      deposits[_to] = deposits[_to].sub(_amountDai);
      deposited = deposited.sub(_amountDai);
    } else {
      pulls[_to] = pulls[_to].add(_amountDai);
      pulled = pulled.add(_amountDai);
    }

    dai.safeTransfer(_to, _amountDai);
    emit Pulled(_to, _amountDai);
  }
}







contract ReentrancyGuard {

    uint256 private _guardCounter;

    constructor () internal {


        _guardCounter = 1;
    }








    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}













contract Crowdsale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    IERC20 private _token;


    address payable private _wallet;





    uint256 private _rate;


    uint256 private _weiRaised;








    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);









    constructor (uint256 rate, address payable wallet, IERC20 token) public {
        require(rate > 0);
        require(wallet != address(0));
        require(address(token) != address(0));

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }







    function () external payable {
        buyTokens(msg.sender);
    }




    function token() public view returns (IERC20) {
        return _token;
    }




    function wallet() public view returns (address payable) {
        return _wallet;
    }




    function rate() public view returns (uint256) {
        return _rate;
    }




    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }







    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = _weiAmount();
        _preValidatePurchase(beneficiary, weiAmount);


        uint256 tokens = _getTokenAmount(weiAmount);


        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }










    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0));
        require(weiAmount != 0);
    }







    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {

    }







    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }







    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }







    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {

    }






    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }




    function _forwardFunds() internal {
        _wallet.transfer(0);
    }




    function _weiAmount() internal view returns (uint256) {
        return msg.value;
    }
}





contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _cap;





    constructor (uint256 cap) public {
        require(cap > 0);
        _cap = cap;
    }




    function cap() public view returns (uint256) {
        return _cap;
    }





    function capReached() public view returns (bool) {
        return weiRaised() >= _cap;
    }






    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiRaised().add(weiAmount) <= _cap);
    }
}





contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;




    modifier onlyWhileOpen {
        require(isOpen());
        _;
    }






    constructor (uint256 openingTime, uint256 closingTime) public {

        require(openingTime >= block.timestamp);
        require(closingTime > openingTime);

        _openingTime = openingTime;
        _closingTime = closingTime;
    }




    function openingTime() public view returns (uint256) {
        return _openingTime;
    }




    function closingTime() public view returns (uint256) {
        return _closingTime;
    }




    function isOpen() public view returns (bool) {

        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }





    function hasClosed() public view returns (bool) {

        return block.timestamp > _closingTime;
    }






    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        super._preValidatePurchase(beneficiary, weiAmount);
    }
}






contract FinalizableCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    bool private _finalized;

    event CrowdsaleFinalized();

    constructor () internal {
        _finalized = false;
    }




    function finalized() public view returns (bool) {
        return _finalized;
    }





    function finalize() public {
        require(!_finalized);
        require(hasClosed());

        _finalized = true;

        _finalization();
        emit CrowdsaleFinalized();
    }






    function _finalization() internal {

    }
}





contract PostDeliveryCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;





    function withdrawTokens(address beneficiary) public {
        require(hasClosed());
        uint256 amount = _balances[beneficiary];
        require(amount > 0);
        _balances[beneficiary] = 0;
        _deliverTokens(beneficiary, amount);
    }




    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }






    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
    }

}

contract LandRegistryProxyInterface {
  function owner() public view returns (address);
}

contract WhitelistInterface {
  function checkRole(address _operator, string memory _role) public view;
  function hasRole(address _operator, string memory _role) public view returns (bool);
}

contract WhitelistProxyInterface {
  function whitelist() public view returns (WhitelistInterface);
}


























contract TokenSale is CappedCrowdsale, FinalizableCrowdsale, LoanEscrow, PostDeliveryCrowdsale {
  address public constant LAND_REGISTRY_PROXY_ADDRESS = 0xe72AD2A335AE18e6C7cdb6dAEB64b0330883CD56;
  address public constant WHITELIST_PROXY_ADDRESS = 0x7223b032180CDb06Be7a3D634B1E10032111F367;

  LandRegistryProxyInterface public registryProxy = LandRegistryProxyInterface(LAND_REGISTRY_PROXY_ADDRESS);
  WhitelistProxyInterface public whitelistProxy = WhitelistProxyInterface(WHITELIST_PROXY_ADDRESS);

  mapping(address => bool) public claimedRefund;
  uint256 public goal;
  mapping(address => bool) public reversed;
  uint256 public totalTokens;

  constructor (
    uint256 _cap,
    uint256 _closingTime,
    uint256 _goal,
    uint256 _openingTime,
    uint256 _rate,
    IERC20 _token,
    address payable _wallet
  )
  public
    Crowdsale(_rate, _wallet, _token)
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    TimedCrowdsale(_openingTime, _closingTime)
    PostDeliveryCrowdsale()
  {
    goal = _goal;
  }

  function blockimmo() public returns (address) {
    return registryProxy.owner();
  }

  function claimRefund(address _refundee) public {
    require(finalized() && !goalReached());
    require(!claimedRefund[_refundee]);

    claimedRefund[_refundee] = true;
    pull(_refundee, deposits[_refundee], true);
  }

  function goalReached() public view returns (bool) {
    return weiRaised() >= goal;
  }

  function reverse(address _account) public onlyBlockimmo {
    require(!finalized());
    require(!reversed[_account]);
    WhitelistInterface whitelist = whitelistProxy.whitelist();
    require(!whitelist.hasRole(_account, "authorized"));

    reversed[_account] = true;
    pull(_account, deposits[_account], true);
  }

  function totalTokensSold() public view returns (uint256) {
    return _getTokenAmount(weiRaised());
  }

  function withdrawTokens(address beneficiary) public {
    require(finalized() && goalReached(), "withdrawTokens requires the TokenSale to be successfully finalized");
    require(!reversed[beneficiary]);

    uint256 extra = totalTokens.sub(totalTokensSold()).mul(balanceOf(beneficiary)) / totalTokensSold();
    _deliverTokens(beneficiary, extra);

    super.withdrawTokens(beneficiary);
  }

  function weiRaised() public view returns (uint256) {
    return deposited;
  }

  function _finalization() internal {
    require(msg.sender == blockimmo() || msg.sender == wallet());

    totalTokens = token().balanceOf(address(this));

    if (goalReached()) {
      uint256 fee = weiRaised().div(100);

      pull(blockimmo(), fee, false);
      pull(wallet(), weiRaised().sub(fee), false);
    } else {
      token().safeTransfer(wallet(), totalTokens);
    }

    super._finalization();
  }

  function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
    deposit(beneficiary, weiAmount);
  }

  function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
    super._preValidatePurchase(beneficiary, weiAmount);

    require(!reversed[beneficiary]);

    WhitelistInterface whitelist = whitelistProxy.whitelist();
    whitelist.checkRole(beneficiary, "authorized");
    require(deposits[beneficiary].add(weiAmount) <= 100000e18 || whitelist.hasRole(beneficiary, "uncapped"));
  }

  function _weiAmount() internal view returns (uint256) {
    return dai.allowance(msg.sender, address(this));
  }
}
