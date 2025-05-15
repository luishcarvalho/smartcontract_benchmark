

pragma solidity 0.6.10;

library SafeMath {

  function MUL346(uint256 a, uint256 b) internal pure returns (uint256) {



    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }


  function DIV110(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b > 0);
    uint256 c = a / b;


    return c;
  }


  function SUB809(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }


  function ADD413(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }


  function MOD443(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Lazarus {
  using SafeMath for uint256;


  string public name;
  string public symbol;
  uint256 public constant decimals374 = 18;

  uint256 public supply;
  address public owner;


  event TRANSFER545(address indexed from, address indexed to, uint256 value);
  event APPROVAL511(address indexed owner, address indexed spender, uint256 value);


  mapping(address => uint256) public _balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor(address _owner, string memory _name, string memory _symbol, uint256 _supply) public {
    owner = _owner;
    name = _name;
    symbol = _symbol;
    supply = _supply * 10 ** decimals374;
    _balanceOf[owner] = supply;
    emit TRANSFER545(address(0x0), owner, supply);
  }

  function BALANCEOF391 (address who) public view returns (uint256) {
    return _balanceOf[who];
  }

  function TOTALSUPPLY367 () public view returns (uint256) {
    return supply;
  }


  function _TRANSFER160(address _from, address _to, uint256 _value) internal {
    _balanceOf[_from] = _balanceOf[_from].SUB809(_value);
    _balanceOf[_to] = _balanceOf[_to].ADD413(_value);
    emit TRANSFER545(_from, _to, _value);
  }


  function TRANSFER298(address _to, uint256 _value) public returns (bool success) {
    require(_balanceOf[msg.sender] >= _value);
    _TRANSFER160(msg.sender, _to, _value);
    return true;
  }


  function APPROVE998(address _spender, uint256 _value) public returns (bool success) {
    require(_spender != address(0));
    allowance[msg.sender][_spender] = _value;
    emit APPROVAL511(msg.sender, _spender, _value);
    return true;
  }


  function TRANSFERFROM682(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _balanceOf[_from]);
    require(_value <= allowance[_from][msg.sender]);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].SUB809(_value);
    _TRANSFER160(_from, _to, _value);
    return true;
  }

  function INCREASEALLOWANCE316(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));
    require(allowance[msg.sender][_spender] > 0);
    allowance[msg.sender][_spender] = allowance[msg.sender][_spender].ADD413(_value);
    emit APPROVAL511(msg.sender, _spender, _value);
    return true;
  }

  function DECREASEALLOWANCE575(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));
    require(allowance[msg.sender][_spender].SUB809(_value) >= 0);
    allowance[msg.sender][_spender] = allowance[msg.sender][_spender].SUB809(_value);
    emit APPROVAL511(msg.sender, _spender, _value);
    return true;
  }


  function BURN795 (uint256 amount) public {
    require(msg.sender == owner);
    require(_balanceOf[msg.sender] >= amount);
    supply = supply.SUB809(amount);
    _TRANSFER160(msg.sender, address(0), amount);

  }


  function TRANSFEROWNERSHIP7 (address newOwner) public {
    require(msg.sender == owner);
    owner = newOwner;
  }
}
