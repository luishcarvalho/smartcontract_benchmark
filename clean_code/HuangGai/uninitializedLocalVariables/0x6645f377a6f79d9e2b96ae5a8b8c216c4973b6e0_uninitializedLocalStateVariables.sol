







pragma solidity ^0.5.16;


















contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }


    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract Athena is owned {
  using SafeMath for uint256;

  bool public safeGuard;


  mapping (address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowed;
  string public constant name  = "ATHENA";
  string public constant symbol = "ATH";
  uint8 public constant decimals = 18;
  address payable coldWallet ;


  uint256 public _totalSupply;
  uint256 public tokenPrice;
  uint256 public soldTokens;

  mapping(address=>uint256) public Pool;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event TransferPoolamount(address _from, address _to, uint256 _ether);
  event Approval(address _from, address _spender, uint256 _tokenAmt);

  constructor(uint256 _supply,uint256 _price) public {
     _totalSupply= _supply * (10 ** 18);
     tokenPrice=_price;


  }


  function buyToken() payable public returns(bool)
  {
      require(msg.value!=0,"Invalid Amount");

      uint256 one;


      uint256 tknAmount;


      require(soldTokens.add(tknAmount)<=_totalSupply,"Token Not Available");

      balances[msg.sender]+=tknAmount;
      Pool[owner]+=msg.value;
      coldWallet.transfer(msg.value);
      Pool[owner]=0;
      soldTokens+=tknAmount;

      emit Transfer(address(this),msg.sender,tknAmount);
  }

  function withDraw() public onlyOwner{

      require(Pool[owner]!=0,"No Ether Available");
      owner.transfer(Pool[owner]);

      emit TransferPoolamount(address(this),owner,Pool[owner]);
      Pool[owner]=0;
  }

  function tokenSold() public view returns(uint256)
  {
      return soldTokens;
  }

  function totalEther() public view returns(uint256)
  {
      return Pool[owner];
  }

  function availableToken() public view returns(uint256)
  {
      return _totalSupply.sub(soldTokens);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address player) public view returns (uint256) {
    return balances[player];
  }

  function allowance(address player, address spender) public view returns (uint256) {
    return allowed[player][spender];
  }


  function transfer(address to, uint256 value) public returns (bool) {
    require(safeGuard==true,'Transfer Is Not Available');
    require(value <= balances[msg.sender]);
    require(to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);

    emit Transfer(msg.sender, to, value);
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i ; i < receivers.length; i++) {

      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }








  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= balances[from]);
    require(value <= allowed[from][msg.sender]);
    require(to != address(0));

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);

    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, value);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function burn(uint256 amount) external {
    require(amount != 0);
    require(amount <= balances[msg.sender]);
    _totalSupply = _totalSupply.sub(amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    emit Transfer(msg.sender, address(0), amount);
  }

  function changeSafeGuard() public onlyOwner{
      safeGuard=true;
  }

}




library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c ;

    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c ;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c ;

    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c ;

    uint256 d ;

    return mul(div(d,m),m);
  }
}
