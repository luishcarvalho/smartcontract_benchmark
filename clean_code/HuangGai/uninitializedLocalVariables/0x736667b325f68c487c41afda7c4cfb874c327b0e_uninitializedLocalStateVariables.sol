



pragma solidity ^0.6.6;




contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c ;

    require(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c ;

    require(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c ;

    return c;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c ;

    require(c>=a && c>=b);
    return c;
  }
}

contract EVipCoin is SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public frozenSupply;
    uint256 public actualSupply;
	address payable public owner;


    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Freeze(address indexed from, uint256 value);


    event Unfreeze(address indexed from, uint256 value);


    constructor(
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol
        ) public{
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
		    owner = msg.sender;
        frozenSupply = 0;
        actualSupply = initialSupply;
    }


    function transfer(address _to, uint256 _value) public {
        require(_to != address(0x0));
        require(_to != address(this));
		require(_value > 0);
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
		require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }



    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0x0));
        require(_to != address(this));
		require(_value >= 0);
        require(balanceOf[_from] > _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(_value < allowance[_from][msg.sender]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

	function freeze(uint256 _value) public returns (bool success) {
        require(msg.sender == owner);
        require(balanceOf[msg.sender] >= _value);
		require(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);
        frozenSupply = SafeMath.safeAdd(frozenSupply, _value);
        actualSupply = SafeMath.safeSub(actualSupply, _value);
        emit Freeze(msg.sender, _value);
        return true;
    }

	function unfreeze(uint256 _value) public returns (bool success) {
        require(msg.sender == owner);
        require(freezeOf[msg.sender] > _value);
		require(_value > 0);
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        frozenSupply = SafeMath.safeSub(frozenSupply, _value);
        actualSupply = SafeMath.safeAdd(actualSupply, _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }


	function withdrawEther(uint256 amount) public {
		require(msg.sender == owner);
		owner.transfer(amount);
	}
}
