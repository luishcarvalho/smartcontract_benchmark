pragma solidity ^0.5.1;

interface tokenRecipient {
    function RECEIVEAPPROVAL508(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}


library SafeMath {


  function MUL771(uint256 a, uint256 b) internal pure returns (uint256 c) {



    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }


  function DIV887(uint256 a, uint256 b) internal pure returns (uint256) {



    return a / b;
  }


  function SUB554(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }


  function ADD386(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract SOContract {

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public totalSupply;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;


    event TRANSFER728(address indexed from, address indexed to, uint256 value);
    event APPROVAL102(address indexed _owner, address indexed _spender, uint256 _value);


    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }


    function _TRANSFER248(address _from, address _to, uint256 _value) internal {

        require(_to != address(0x0));

        require(balanceOf[_from] >= _value);

        require(balanceOf[_to] + _value >= balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;

        balanceOf[_to] += _value;
        emit TRANSFER728(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }


    function TRANSFER116(address _to, uint256 _value) public returns (bool success) {
        _TRANSFER248(msg.sender, _to, _value);
        return true;
    }


    function TRANSFERFROM758(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        _TRANSFER248(_from, _to, _value);
        return true;
    }


    function APPROVE102(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit APPROVAL102(msg.sender, _spender, _value);
        return true;
    }


    function INCREASEAPPROVAL679(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = SafeMath.ADD386(allowed[msg.sender][_spender],_addedValue);
        emit APPROVAL102(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function DECREASEAPPROVAL481(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = SafeMath.SUB554(oldValue, _subtractedValue);
        }
        emit APPROVAL102(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function ALLOWANCE225(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function APPROVEANDCALL291(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (APPROVE102(_spender, _value)) {
            spender.RECEIVEAPPROVAL508(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }
}
