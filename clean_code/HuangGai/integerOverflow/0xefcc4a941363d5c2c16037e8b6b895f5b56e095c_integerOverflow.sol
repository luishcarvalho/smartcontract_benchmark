



pragma solidity ^0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;

        return c;
    }
}

contract Ownable {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	constructor() internal {
		owner = msg.sender;
		newOwner = address(0);
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "msg.sender == owner");
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(address(0) != _newOwner, "address(0) != _newOwner");
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner, "msg.sender == newOwner");
		emit OwnershipTransferred(owner, msg.sender);
		owner = msg.sender;
		newOwner = address(0);
	}
}

contract Adminable is Ownable {
    mapping(address => bool) public admin;

    event AdminSet(address indexed adminAddress, bool indexed status);

    constructor() internal {
        admin[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admin[msg.sender], "admin[msg.sender]");
        _;
    }

    function setAdmin(address adminAddress, bool status) public onlyOwner {
        emit AdminSet(adminAddress, status);
        admin[adminAddress] = status;
    }
}

contract Authorizable is Adminable {
    mapping(address => bool) public authorized;

    event AuthorizationSet(address indexed addressAuthorized, bool indexed authorization);

    constructor() internal {
        authorized[msg.sender] = true;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "authorized[msg.sender]");
        _;
    }

    function setAuthorized(address addressAuthorized, bool authorization) public onlyAdmin {
        emit AuthorizationSet(addressAuthorized, authorization);
        authorized[addressAuthorized] = authorization;
    }
}

contract ERC20Basic {
    string public name;
    string public symbol;
    uint8 public decimals;
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

    function transferFunction(address _sender, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0), "_to != address(0)");
        require(_to != address(this), "_to != address(this)");
        require(_value <= balances[_sender], "_value <= balances[_sender]");

        balances[_sender] = balances[_sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
	    transferFunction(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}

contract ERC223TokenCompatible is BasicToken {
  using SafeMath for uint256;

  event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);

	function transfer(address _to, uint256 _value, bytes memory _data, string memory _custom_fallback) public returns (bool success) {
		transferFunction(msg.sender, _to, _value);

		if( isContract(_to) ) {
		    (bool txOk, ) = _to.call.value(0)( abi.encodePacked(bytes4( keccak256( abi.encodePacked( _custom_fallback ) ) ), msg.sender, _value, _data) );
			require( txOk, "_to.call.value(0)( abi.encodePacked(bytes4( keccak256( abi.encodePacked( _custom_fallback ) ) ), msg.sender, _value, _data) )" );

		}
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}

	function transfer(address _to, uint256 _value, bytes memory _data) public returns (bool success) {
		return transfer(_to, _value, _data, "tokenFallback(address,uint256,bytes)");
	}


	function isContract(address _addr) private view returns (bool is_contract) {
		uint256 length;
		assembly {

            length := extcodesize(_addr)
		}
		return (length>0);
    }
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(_value <= allowed[_from][msg.sender], "_value <= allowed[_from][msg.sender]");

        transferFunction(_from, _to, _value);

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

contract HumanStandardToken is StandardToken {

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        approve(_spender, _value);
        (bool txOk, ) = _spender.call(abi.encodePacked(bytes4(keccak256("receiveApproval(address,uint256,bytes)")), msg.sender, _value, _extraData));
        require(txOk, 'error on approveAndCall()');
        return true;
    }
    function approveAndCustomCall(address _spender, uint256 _value, bytes memory _extraData, bytes4 _customFunction) public returns (bool success) {
        approve(_spender, _value);
        (bool txOk, ) = _spender.call(abi.encodePacked(_customFunction, msg.sender, _value, _extraData));
        require(txOk, "error on approveAndCustomCall()");
        return true;
    }
}

contract BurnToken is StandardToken {
    uint256 public initialSupply;

    event Burn(address indexed burner, uint256 value);

    constructor(uint256 _totalSupply) internal {
        initialSupply = _totalSupply;
    }

    function burnFunction(address _burner, uint256 _value) internal returns (bool) {
        require(_value > 0, "_value > 0");
		require(_value <= balances[_burner], "_value <= balances[_burner]");

        balances[_burner] = balances[_burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_burner, _value);
		emit Transfer(_burner, address(0), _value);
		return true;
    }

	function burn(uint256 _value) public returns(bool) {
        return burnFunction(msg.sender, _value);
    }

	function burnFrom(address _from, uint256 _value) public returns (bool) {
		require(_value <= allowed[_from][msg.sender], "_value <= allowed[_from][msg.sender]");
		burnFunction(_from, _value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		return true;
	}
}

contract Mintable is Ownable, Adminable, StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished, 'Is not more possible minting new token.');
    _;
  }

  function mint(address _to, uint256 _amount) public onlyAdmin canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);

    balances[_to] = balances[_to].add(_amount);

    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract Changable is Adminable, ERC20Basic {
    function changeName(string memory _newName) public onlyAdmin {
        name = _newName;
    }
    function changeSymbol(string memory _newSymbol) public onlyAdmin {
        symbol = _newSymbol;
    }
}

contract Token is
    ERC20Basic,
    ERC223TokenCompatible,
    StandardToken,
    HumanStandardToken,
    Mintable,
    BurnToken,
    Changable
    {
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) public BurnToken(_totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = totalSupply;
		emit Transfer(address(0), msg.sender, totalSupply);
    }
}
