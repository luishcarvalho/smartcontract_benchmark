



pragma solidity 0.5.14;


contract ERC20 {


  function TOTALSUPPLY679() public view returns (uint256 supply);


  function BALANCEOF603(address _owner) public view returns (uint256 balance);


  function TRANSFER978(address _to, uint256 _value) public returns (bool success);


  function TRANSFERFROM476(address _from, address _to, uint256 _value) public returns (bool success);


  function APPROVE644(address _spender, uint256 _value) public returns (bool success);


  function ALLOWANCE384(address _owner, address _spender) public view returns (uint256 remaining);


  event TRANSFER760(address indexed from, address indexed to, uint256 value);


  event APPROVAL643(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity 0.5.14;



library SafeMath {


  function MUL81(uint256 _a, uint256 _b) internal pure returns (uint256) {



    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }


  function DIV451(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);

    uint256 c = _a / _b;


    return c;
  }


  function SUB832(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }


  function ADD114(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }


  function MOD487(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}



pragma solidity 0.5.14;





contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  mapping(address => mapping(address => uint256)) private allowed;

  uint256 internal totalSupply_;


  function TOTALSUPPLY679() public view returns (uint256) {
    return totalSupply_;
  }


  function BALANCEOF603(address _owner) public view returns (uint256) {
    return balances[_owner];
  }


  function ALLOWANCE384(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }


  function TRANSFER978(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].SUB832(_value);
    balances[_to] = balances[_to].ADD114(_value);
    emit TRANSFER760(msg.sender, _to, _value);
    return true;
  }


  function APPROVE644(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit APPROVAL643(msg.sender, _spender, _value);
    return true;
  }


  function TRANSFERFROM476(address _from, address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].SUB832(_value);
    balances[_to] = balances[_to].ADD114(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].SUB832(_value);
    emit TRANSFER760(_from, _to, _value);
    return true;
  }


  function INCREASEAPPROVAL847(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = (
    allowed[msg.sender][_spender].ADD114(_addedValue));
    emit APPROVAL643(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


  function DECREASEAPPROVAL982(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.SUB832(_subtractedValue);
    }
    emit APPROVAL643(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


  function _MINT883(address _account, uint256 _amount) internal {
    require(_account != address(0));
    totalSupply_ = totalSupply_.ADD114(_amount);
    balances[_account] = balances[_account].ADD114(_amount);
    emit TRANSFER760(address(0), _account, _amount);
  }


  function _BURN950(address _account, uint256 _amount) internal {
    require(_account != address(0));
    require(_amount <= balances[_account]);

    totalSupply_ = totalSupply_.SUB832(_amount);
    balances[_account] = balances[_account].SUB832(_amount);
    emit TRANSFER760(_account, address(0), _amount);
  }


  function _BURNFROM531(address _account, uint256 _amount) internal {
    require(_amount <= allowed[_account][msg.sender]);



    allowed[_account][msg.sender] = allowed[_account][msg.sender].SUB832(_amount);
    _BURN950(_account, _amount);
  }
}



pragma solidity 0.5.14;



contract Ownable {
  address public owner;

  event OWNERSHIPRENOUNCED53(address indexed previousOwner);

  event OWNERSHIPTRANSFERRED268(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor() public {
    owner = msg.sender;
  }


  modifier ONLYOWNER709() {
    require(msg.sender == owner);
    _;
  }


  function RENOUNCEOWNERSHIP918() public ONLYOWNER709 {
    emit OWNERSHIPRENOUNCED53(owner);
    owner = address(0);
  }


  function TRANSFEROWNERSHIP47(address _newOwner) public ONLYOWNER709 {
    _TRANSFEROWNERSHIP390(_newOwner);
  }


  function _TRANSFEROWNERSHIP390(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OWNERSHIPTRANSFERRED268(owner, _newOwner);
    owner = _newOwner;
  }
}



pragma solidity 0.5.14;




contract BurnableToken is StandardToken {

  event BURN276(address indexed burner, uint256 value);


  function BURN42(uint256 _value) public {
    _BURN950(msg.sender, _value);
  }


  function BURNFROM69(address _from, uint256 _value) public {
    _BURNFROM531(_from, _value);
  }


  function _BURN950(address _who, uint256 _value) internal {
    super._BURN950(_who, _value);
    emit BURN276(_who, _value);
  }
}



pragma solidity 0.5.14;



contract SportValueCoin is BurnableToken {


  string public constant symbol15 = "SVC";

  string public version = '1.0';

  string public constant name455 = "Sport Value Coin";

  uint256 public constant decimals291 = 18;

  uint256 public constant initial_supply658 = 100 * (10 ** 6) * 10 ** decimals291;

  constructor() public {
    _MINT883(msg.sender, initial_supply658);
  }

}
