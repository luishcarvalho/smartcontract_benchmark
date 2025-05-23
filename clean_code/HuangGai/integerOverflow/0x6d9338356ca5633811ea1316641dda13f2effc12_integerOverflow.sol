



pragma solidity ^0.5.10;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

library SafeMath {




  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;





  modifier whenNotPaused() {
    require(!paused);
    _;
  }




  modifier whenPaused() {
    require(paused);
    _;
  }




  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }




  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;




  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }






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
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }







  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);

    balances[_to] = balances[_to].add(_amount);

    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }





  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }







  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

contract KittiefightToken is PausableToken, CappedToken {


    string public constant symbol = "KTY";


    string public constant name = "Kittiefight";


    uint8 public constant decimals = 18;


    uint256 public constant amountOfTokenToMint = 10**8 * 10**uint256(decimals);


    bool public isTransferWhitelistOnly = false;


    mapping (address => bool) transfersWhitelist;

    event UserTransferWhitelistStatusChange(address user, bool whitelisted);

    event TransferWhitelistOnly(bool flag);


    constructor() CappedToken(amountOfTokenToMint) public {

    }





    function isUserAllowedToTransfer(address _user) public view returns (bool) {
        require(_user != address(0));
        return transfersWhitelist[_user];
    }




    function setWhitelistedOnly(bool _isWhitelistOnly) onlyOwner public {
        if (isTransferWhitelistOnly != _isWhitelistOnly) {
            isTransferWhitelistOnly = _isWhitelistOnly;
            emit TransferWhitelistOnly(_isWhitelistOnly);
        }
    }




    function whitelistUserForTransfers(address _user) onlyOwner public {
        require(!isUserAllowedToTransfer(_user));
        transfersWhitelist[_user] = true;
        emit UserTransferWhitelistStatusChange(_user, true);
    }




    function blacklistUserForTransfers(address _user) onlyOwner public {
        require(isUserAllowedToTransfer(_user));
        transfersWhitelist[_user] = false;
        emit UserTransferWhitelistStatusChange(_user, false);
    }






    function transfer(address _to, uint256 _value) public returns (bool) {
      if (isTransferWhitelistOnly) {
        require(isUserAllowedToTransfer(msg.sender));
      }
      return super.transfer(_to, _value);
    }







    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (isTransferWhitelistOnly) {
            require(isUserAllowedToTransfer(_from));
        }
        return super.transferFrom(_from, _to, _value);
    }

}
