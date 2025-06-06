



pragma solidity 0.5.17;






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






  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}






contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}






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





contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}









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







  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public
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


interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, bytes calldata _extraData) external;
}





contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);





    function burn(address burner, uint256 _value) internal {
        require(_value > 0);
        require(_value <= balances[burner]);



        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(burner, address(0), _value);
        emit Burn(burner, _value);
    }
}

contract DKING is BurnableToken, Ownable {

    address public stakingAddress;

    string public constant name = "Deflationary King";
    string public constant symbol = "DKING";
    uint public constant decimals = 18;

    uint256 public constant initialSupply = 1000000 * (10 ** uint256(decimals));

    function setStakingAddress(address _addr) public onlyOwner {
        stakingAddress = _addr;
    }

    function transfer(address to, uint amount) public returns (bool) {
        uint _amountToBurn = amount.mul(400).div(10000);
        uint _amountToDisburse = amount.mul(400).div(10000);
        uint _amountAfterFee = amount.sub(_amountToBurn).sub(_amountToDisburse);

        burn(msg.sender, _amountToBurn);
        require(super.transfer(stakingAddress, _amountToDisburse), "Cannot disburse rewards.");
        if (stakingAddress != address(0)) {
            tokenRecipient(stakingAddress).receiveApproval(msg.sender, _amountToDisburse, "");
        }
        require(super.transfer(to, _amountAfterFee), "Cannot transfer tokens.");
        return true;
    }

    function transferFrom(address from, address to, uint amount) public returns (bool) {
        require(to != address(0) && to != address(this));
        uint _amountToBurn = amount.mul(400).div(10000);
        uint _amountToDisburse = amount.mul(400).div(10000);
        uint _amountAfterFee = amount.sub(_amountToBurn).sub(_amountToDisburse);

        uint256 _allowance = allowed[from][msg.sender];




        balances[from] = balances[from].sub(_amountAfterFee);
        balances[to] = balances[to].add(_amountAfterFee);
        balances[from] = balances[from].sub(_amountToDisburse);
        balances[stakingAddress] = balances[stakingAddress].add(_amountToDisburse);
        allowed[from][msg.sender] = _allowance.sub(amount);


        burn(from, _amountToBurn);

        emit Transfer(from, stakingAddress, _amountToDisburse);
        emit Transfer(from, to, _amountAfterFee);

        if (stakingAddress != address(0)) {
            tokenRecipient(stakingAddress).receiveApproval(msg.sender, _amountToDisburse, "");
        }
        return true;
    }


    constructor () public {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }


    function transferAnyERC20Token(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        ERC20(_tokenAddress).transfer(_to, _amount);
    }

}
