



pragma solidity ^0.5.10;






contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);






    constructor() public {
        owner = msg.sender;
    }





    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized operation");
        _;
    }






    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Address shouldn't be zero");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

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












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}





contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);


}




library Address {










    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }
}






contract MintableToken is ERC20, Ownable {
  using Address for address;
  using SafeMath for uint256;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  address public tokenOwner;
  address private crowdsale;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) internal allowed;

  event SetCrowdsale(address indexed _crowdsale);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event UnlockToken();
  event LockToken();
  event Burn();

  bool public mintingFinished = false;
  bool public locked = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier canTransfer() {
    require(!locked || msg.sender == owner);
    _;
  }

  modifier onlyCrowdsale() {
    require(msg.sender == crowdsale);
    _;
  }

  modifier onlyAuthorized() {
    require(msg.sender == owner || msg.sender == crowdsale);
    _;
  }

  constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = 0;
    balances[msg.sender] = totalSupply;
    emit Transfer(address(0), msg.sender, totalSupply);
  }






  function mint(address _to, uint256 _amount) public onlyAuthorized canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }





  function finishMinting() onlyOwner public canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

  function burn(uint256 _value) public onlyAuthorized returns (bool) {
    totalSupply = totalSupply.sub(_value);
    balances[address(this)] = balances[address(this)].sub(_value);
    emit Burn();
    emit Transfer(address(this), address(0), _value);
    return true;
  }






  function transfer(address _to, uint256 _value) public canTransfer returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);


    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFromContract(address _to, uint256 _value) public onlyOwner returns (bool) {
    require(_to != address(0));
    require(_value <= balances[address(this)]);
    balances[address(this)] = balances[address(this)].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(address(this), _to, _value);
    return true;
  }






  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }







  function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool) {
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







  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }











  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }











  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];

    if (block.number > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function unlockToken() public onlyCrowdsale returns (bool) {
    locked = false;
    emit UnlockToken();
    return true;
  }

  function lockToken() public onlyCrowdsale returns (bool) {
    locked = true;
    emit LockToken();
    return true;
  }

  function setCrowdsale(address _crowdsale) public onlyOwner returns (bool) {
    require(_crowdsale.isContract());
    crowdsale = _crowdsale;

    emit SetCrowdsale(_crowdsale);
    return true;
  }
}
