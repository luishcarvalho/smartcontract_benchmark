

pragma solidity 0.5.1;




interface IERC20 {
  function TOTALSUPPLY936() external view returns (uint256);

  function BALANCEOF371(address who) external view returns (uint256);

  function ALLOWANCE214(address owner, address spender)
    external view returns (uint256);

  function TRANSFER168(address to, uint256 value) external returns (bool);

  function APPROVE80(address spender, uint256 value)
    external returns (bool);

  function TRANSFERFROM234(address from, address to, uint256 value)
    external returns (bool);

  event TRANSFER30(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event APPROVAL61(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}




library SafeMath {


  function MUL733(uint256 a, uint256 b) internal pure returns (uint256) {



    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }


  function DIV828(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;


    return c;
  }


  function SUB889(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }


  function ADD39(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }


  function MOD393(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}




contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;


  function TOTALSUPPLY936() public view returns (uint256) {
    return _totalSupply;
  }


  function BALANCEOF371(address owner) public view returns (uint256) {
    return _balances[owner];
  }


  function ALLOWANCE214(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }


  function TRANSFER168(address to, uint256 value) public returns (bool) {
    _TRANSFER798(msg.sender, to, value);
    return true;
  }


  function APPROVE80(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit APPROVAL61(msg.sender, spender, value);
    return true;
  }


  function TRANSFERFROM234(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].SUB889(value);
    _TRANSFER798(from, to, value);
    return true;
  }


  function INCREASEALLOWANCE418(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].ADD39(addedValue));
    emit APPROVAL61(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }


  function DECREASEALLOWANCE265(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].SUB889(subtractedValue));
    emit APPROVAL61(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }


  function _TRANSFER798(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].SUB889(value);
    _balances[to] = _balances[to].ADD39(value);
    emit TRANSFER30(from, to, value);
  }


  function _MINT17(address account, uint256 value) internal {
    require(account != address(0));
    _totalSupply = _totalSupply.ADD39(value);
    _balances[account] = _balances[account].ADD39(value);
    emit TRANSFER30(address(0), account, value);
  }


  function _BURN632(address account, uint256 value) internal {
    require(account != address(0));
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.SUB889(value);
    _balances[account] = _balances[account].SUB889(value);
    emit TRANSFER30(account, address(0), value);
  }


  function _BURNFROM339(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);



    _allowed[account][msg.sender] = _allowed[account][msg.sender].SUB889(
      value);
    _BURN632(account, value);
  }
}




library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }


  function ADD39(Role storage role, address account) internal {
    require(account != address(0));
    require(!HAS536(role, account));

    role.bearer[account] = true;
  }


  function REMOVE855(Role storage role, address account) internal {
    require(account != address(0));
    require(HAS536(role, account));

    role.bearer[account] = false;
  }


  function HAS536(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}



contract MinterRole {
  using Roles for Roles.Role;

  event MINTERADDED705(address indexed account);
  event MINTERREMOVED101(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _ADDMINTER752(msg.sender);
  }

  modifier ONLYMINTER554() {
    require(ISMINTER485(msg.sender));
    _;
  }

  function ISMINTER485(address account) public view returns (bool) {
    return minters.HAS536(account);
  }

  function ADDMINTER992(address account) public ONLYMINTER554 {
    _ADDMINTER752(account);
  }

  function RENOUNCEMINTER120() public {
    _REMOVEMINTER694(msg.sender);
  }

  function _ADDMINTER752(address account) internal {
    minters.ADD39(account);
    emit MINTERADDED705(account);
  }

  function _REMOVEMINTER694(address account) internal {
    minters.REMOVE855(account);
    emit MINTERREMOVED101(account);
  }
}




contract ERC20Mintable is ERC20, MinterRole {

  function MINT763(
    address to,
    uint256 value
  )
    public
    ONLYMINTER554
    returns (bool)
  {
    _MINT17(to, value);
    return true;
  }
}




contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }


  function NAME131() public view returns(string memory) {
    return _name;
  }


  function SYMBOL158() public view returns(string memory) {
    return _symbol;
  }


  function DECIMALS779() public view returns(uint8) {
    return _decimals;
  }
}



contract TXCast is ERC20Mintable, ERC20Detailed {
  constructor () public ERC20Detailed("TXCast", "TXC", 0) {}
}




library SafeERC20 {

  using SafeMath for uint256;

  function SAFETRANSFER87(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.TRANSFER168(to, value));
  }

  function SAFETRANSFERFROM776(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.TRANSFERFROM234(from, to, value));
  }

  function SAFEAPPROVE794(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {



    require((value == 0) || (token.ALLOWANCE214(msg.sender, spender) == 0));
    require(token.APPROVE80(spender, value));
  }

  function SAFEINCREASEALLOWANCE532(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.ALLOWANCE214(address(this), spender).ADD39(value);
    require(token.APPROVE80(spender, newAllowance));
  }

  function SAFEDECREASEALLOWANCE74(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.ALLOWANCE214(address(this), spender).SUB889(value);
    require(token.APPROVE80(spender, newAllowance));
  }
}




contract ReentrancyGuard {


  uint256 private _guardCounter;

  constructor() internal {


    _guardCounter = 1;
  }


  modifier NONREENTRANT633() {
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


  event TOKENSPURCHASED409(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );


  constructor(uint256 rate, address payable wallet                  ) internal {
    require(rate > 0);
    require(wallet != address(0));


    _rate = rate;
    _wallet = wallet;
    _token = new TXCast();
  }






  function () external payable {
    BUYTOKENS23(msg.sender);
  }


  function TOKEN725() public view returns(IERC20) {
    return _token;
  }


  function WALLET658() public view returns(address) {
    return _wallet;
  }


  function RATE552() public view returns(uint256) {
    return _rate;
  }


  function WEIRAISED883() public view returns (uint256) {
    return _weiRaised;
  }


  function BUYTOKENS23(address beneficiary) public NONREENTRANT633 payable {

    uint256 weiAmount = msg.value;
    _PREVALIDATEPURCHASE107(beneficiary, weiAmount);


    uint256 tokens = _GETTOKENAMOUNT819(weiAmount);


    _weiRaised = _weiRaised.ADD39(weiAmount);

    _PROCESSPURCHASE612(beneficiary, tokens);
    emit TOKENSPURCHASED409(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    _UPDATEPURCHASINGSTATE169(beneficiary, weiAmount);

    _FORWARDFUNDS314();
    _POSTVALIDATEPURCHASE48(beneficiary, weiAmount);
  }






  function _PREVALIDATEPURCHASE107(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    view
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
    require(uint(weiAmount >> 18) << 18 == weiAmount);
  }


  function _POSTVALIDATEPURCHASE48(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    view
  {

  }


  function _DELIVERTOKENS659(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _token.SAFETRANSFER87(beneficiary, tokenAmount);
  }


  function _PROCESSPURCHASE612(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _DELIVERTOKENS659(beneficiary, tokenAmount);
  }


  function _UPDATEPURCHASINGSTATE169(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {

  }


  function _GETTOKENAMOUNT819(uint256 weiAmount)
    internal view returns (uint256)
  {
    return weiAmount.DIV828(1 ether);
  }


  function _FORWARDFUNDS314() internal {
    _wallet.transfer(msg.value);
  }
}




contract MintedCrowdsale is Crowdsale {
  constructor() internal {}


  function _DELIVERTOKENS659(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {

    require(
      ERC20Mintable(address(TOKEN725())).MINT763(beneficiary, tokenAmount));
  }
}




contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 private _cap;


  constructor(uint256 cap) internal {
    require(cap > 0);
    _cap = cap;
  }


  function CAP835() public view returns(uint256) {
    return _cap;
  }


  function CAPREACHED150() public view returns (bool) {
    return WEIRAISED883() >= _cap;
  }


  function _PREVALIDATEPURCHASE107(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    view
  {
    super._PREVALIDATEPURCHASE107(beneficiary, weiAmount);
    require(WEIRAISED883().ADD39(weiAmount) <= _cap);
  }

}



contract TXCSale is CappedCrowdsale, MintedCrowdsale {
  constructor
  (
    uint256 _cap,
    address payable _wallet
  )
  public
  Crowdsale(1 ether, _wallet)
  CappedCrowdsale(_cap * 1 ether) {

  }
}
