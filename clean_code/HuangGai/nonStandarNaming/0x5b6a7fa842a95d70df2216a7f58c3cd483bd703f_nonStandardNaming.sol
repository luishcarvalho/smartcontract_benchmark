pragma solidity ^0.5.2;


contract Ownable {
    address public owner;

    event OWNERSHIPRENOUNCED348(address indexed previousOwner);
    event OWNERSHIPTRANSFERRED910(
        address indexed previousOwner,
        address indexed newOwner
    );


    constructor() public {
        owner = msg.sender;
    }


    modifier ONLYOWNER133() {
        require(msg.sender == owner);
        _;
    }


    function TRANSFEROWNERSHIP800(address newOwner) public ONLYOWNER133 {
        require(newOwner != address(0));
        emit OWNERSHIPTRANSFERRED910(owner, newOwner);
        owner = newOwner;
    }


    function RENOUNCEOWNERSHIP965() public ONLYOWNER133 {
        emit OWNERSHIPRENOUNCED348(owner);
        owner = address(0);
    }
}


library SafeMath {


    function MUL451(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }


    function DIV968(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }


    function SUB978(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }


    function ADD466(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}


contract ERC20Basic {
    function TOTALSUPPLY948() public view returns (uint256);
    function BALANCEOF975(address who) public view returns (uint256);
    function TRANSFER954(address to, uint256 value) public returns (bool);
    event TRANSFER596(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function ALLOWANCE236(address owner, address spender) public view returns (uint256);
    function TRANSFERFROM818(address from, address to, uint256 value) public returns (bool);
    function APPROVE732(address spender, uint256 value) public returns (bool);
    event APPROVAL122(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;


    function TOTALSUPPLY948() public view returns (uint256) {
        return totalSupply_;
    }


    function TRANSFER954(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].SUB978(_value);
        balances[_to] = balances[_to].ADD466(_value);
        emit TRANSFER596(msg.sender, _to, _value);
        return true;
    }


    function BALANCEOF975(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;



    function TRANSFERFROM818(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].SUB978(_value);
        balances[_to] = balances[_to].ADD466(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].SUB978(_value);
        emit TRANSFER596(_from, _to, _value);
        return true;
    }


    function APPROVE732(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit APPROVAL122(msg.sender, _spender, _value);
        return true;
    }


    function ALLOWANCE236(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }


    function INCREASEAPPROVAL411(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].ADD466(_addedValue);
        emit APPROVAL122(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function DECREASEAPPROVAL474(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.SUB978(_subtractedValue);
        }
        emit APPROVAL122(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract Pausable is Ownable {
    event PAUSE560();
    event UNPAUSE665();

    bool public paused = false;



    modifier WHENNOTPAUSED770() {
        require(!paused);
        _;
    }


    modifier WHENPAUSED528() {
        require(paused);
        _;
    }


    function PAUSE825() ONLYOWNER133 WHENNOTPAUSED770 public {
        paused = true;
        emit PAUSE560();
    }


    function UNPAUSE769() ONLYOWNER133 WHENPAUSED528 public {
        paused = false;
        emit UNPAUSE665();
    }
}

contract PausableToken is StandardToken, Pausable {

    function TRANSFER954(address _to, uint256 _value) public WHENNOTPAUSED770 returns (bool) {
        return super.TRANSFER954(_to, _value);
    }

    function TRANSFERFROM818(address _from, address _to, uint256 _value) public WHENNOTPAUSED770 returns (bool) {
        return super.TRANSFERFROM818(_from, _to, _value);
    }

    function APPROVE732(address _spender, uint256 _value) public WHENNOTPAUSED770 returns (bool) {
        return super.APPROVE732(_spender, _value);
    }

    function INCREASEAPPROVAL411(address _spender, uint256 _addedValue) public WHENNOTPAUSED770 returns (bool) {
        return super.INCREASEAPPROVAL411(_spender, _addedValue);
    }

    function DECREASEAPPROVAL474(address _spender, uint256 _subtractedValue) public WHENNOTPAUSED770 returns (bool) {
        return super.DECREASEAPPROVAL474(_spender, _subtractedValue);
    }
}

contract FFToken is PausableToken {
    string public constant name264 = "Fifty Five Token";
    string public constant symbol755 = "FF";
    uint256 public constant decimals786 = 18;

    mapping (address => uint256) freezes;


    event BURN80(address indexed from, uint256 value);


    event FREEZE181(address indexed from, uint256 value);


    event UNFREEZE267(address indexed from, uint256 value);

    constructor() public {
        totalSupply_ = 10000000000 * (10 ** uint256(decimals786));
        balances[msg.sender] = totalSupply_;
    }

    function FREEZEOF457(address _owner) public view returns (uint256) {
        return freezes[_owner];
    }

    function BURN929(uint256 _value) WHENNOTPAUSED770 public returns (bool) {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].SUB978(_value);
        totalSupply_ = totalSupply_.SUB978(_value);
        emit BURN80(msg.sender, _value);
        return true;
    }

	function FREEZE250(uint256 _value) WHENNOTPAUSED770 public returns (bool) {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].SUB978(_value);
        freezes[msg.sender] = freezes[msg.sender].ADD466(_value);
        emit FREEZE181(msg.sender, _value);
        return true;
    }

	function UNFREEZE512(uint256 _value) WHENNOTPAUSED770 public returns (bool) {
        require(_value <= freezes[msg.sender]);

        freezes[msg.sender] = freezes[msg.sender].SUB978(_value);
		balances[msg.sender] = balances[msg.sender].ADD466(_value);
        emit UNFREEZE267(msg.sender, _value);
        return true;
    }


    function TRANSFEROWNERSHIP800(address newOwner) ONLYOWNER133 WHENNOTPAUSED770 public {
        super.TRANSFEROWNERSHIP800(newOwner);
    }


    function() payable external {
        revert();
    }
}
