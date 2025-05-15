










pragma solidity 0.5.12;


contract Ownable {
  address public owner;
  address public pendingOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);






  constructor () public {
    owner = msg.sender;
  }





  modifier onlyOwner() {
    require(tx.origin == owner);

    _;
  }




  modifier onlyPendingOwner() {
    assert(msg.sender != address(0));
    require(msg.sender == pendingOwner);
    _;
  }






  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    pendingOwner = newOwner;
  }




  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}








pragma solidity 0.5.12;


contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}







pragma solidity 0.5.12;



contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}







pragma solidity 0.5.12;


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
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}







 pragma solidity 0.5.12;




contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;






  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0) && _to != address(this));


    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }






  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}









pragma solidity 0.5.12;




contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;








  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0) && _to != address(this));

    uint256 _allowance = allowed[_from][msg.sender];




    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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






  function increaseApproval (address _spender, uint _addedValue)
    public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    public
    returns (bool success) {
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



pragma solidity >=0.4.24 <0.7.0;














contract Initializable {




  bool private initialized;




  bool private initializing;




  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }


  function isConstructor() private view returns (bool) {





    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }


  uint256[50] private ______gap;
}



pragma solidity 0.5.12;




interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, bytes calldata _extraData) external;
}

contract WOMToken is StandardToken, Ownable, Initializable {

    string public name = "WOM Token";
    string public symbol = "WOM";
    uint public decimals = 18;

    uint256 public initialSupply = 1000000000 * (10 ** uint256(decimals));


    function initialize() public initializer {
        name = "WOM Token";
        symbol = "WOM";
        decimals = 18;
        initialSupply = 1000000000 * (10 ** uint256(decimals));
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }


    function approveAndCall(address _spender, uint256 _value, bytes calldata _extraData)
        external
        returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, _extraData);
            return true;
        }
    }




    function transferAnyERC20Token(address _tokenAddr, address _toAddr, uint _tokenAmount) public onlyOwner {
      ERC20(_tokenAddr).transfer(_toAddr, _tokenAmount);
    }
}
