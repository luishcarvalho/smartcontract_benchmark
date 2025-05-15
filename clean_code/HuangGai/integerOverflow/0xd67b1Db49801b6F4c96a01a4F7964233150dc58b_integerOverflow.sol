



pragma solidity >=0.5.13 <0.6.0;





library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {

    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;

    return c;
  }
}






contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}





contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}





contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;






  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);


    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
    return true;
  }






  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}








contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;







  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);

    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }











  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }







  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }







  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}







contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





  constructor() public {
    owner = msg.sender;
  }




  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }





  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract InvestorsFeature is Ownable, StandardToken {
    using SafeMath for uint;

    address[] public investors;

    mapping(address => bool) isInvestor;

    function deposit(address investor, uint) internal {
        if(isInvestor[investor] == false) {
            investors.push(investor);
            isInvestor[investor] = true;
        }
    }

    function sendp(address addr, uint amount) internal {
        require(addr != address(0));
        require(amount > 0);
        deposit(addr, amount);


        balances[address(this)] = balances[address(this)].sub(amount);
        balances[addr] = balances[addr].add(amount);
        emit Transfer(address(this), addr, amount);
    }
}

contract KaratBankCoin is Ownable, StandardToken, InvestorsFeature  {

  string public constant name = "KaratBank Coin";
  string public constant symbol = "KBC";
  uint8 public constant decimals = 7;

  uint256 public constant INITIAL_SUPPLY = (12000 * (10**6)) * (10 ** uint256(decimals));

  constructor() public {
    totalSupply = INITIAL_SUPPLY;
    balances[address(this)] = INITIAL_SUPPLY;
    emit Transfer(address(0), address(this), INITIAL_SUPPLY);
  }

  function send(address addr, uint amount) public onlyOwner {
      sendp(addr, amount);
  }

  function safe(address addr) public onlyOwner {
      require(addr != address(0));
      uint256 amount = balances[addr];
      balances[address(this)] = balances[address(this)].add(amount);
      balances[addr] = 0;
      emit Transfer(addr, address(this), amount);
  }

  function burnRemainder(uint) public onlyOwner {
      uint value = balances[address(this)];
      totalSupply = totalSupply.sub(value);
      balances[address(this)] = 0;
  }

  function burnFrom(address addr, uint256 amount) public onlyOwner {
      require(addr != address(0) && balances[addr] >= amount);

      totalSupply = totalSupply.sub(amount);

      balances[addr] = balances[addr].sub(amount);
  }

  function burnAllFrom(address addr) public onlyOwner {
      require(addr != address(0) && balances[addr] > 0);
      totalSupply = totalSupply.sub(balances[addr]);
      balances[addr] = 0;
  }
}
