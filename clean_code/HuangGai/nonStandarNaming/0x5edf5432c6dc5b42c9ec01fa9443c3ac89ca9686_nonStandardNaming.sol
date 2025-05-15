pragma solidity ^0.5.1;

library SafeMath {


  function MUL493(uint256 _a, uint256 _b) internal pure returns (uint256 c) {



    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }


  function DIV994(uint256 _a, uint256 _b) internal pure returns (uint256) {



    return _a / _b;
  }


  function SUB747(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }


  function ADD196(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OWNERSHIPRENOUNCED804(address indexed previousOwner);
  event OWNERSHIPTRANSFERRED780(
    address indexed previousOwner,
    address indexed newOwner
  );



  constructor() public {
    owner = msg.sender;
  }


  modifier ONLYOWNER146() {
    require(msg.sender == owner);
    _;
  }


  function RENOUNCEOWNERSHIP303() public ONLYOWNER146 {
    emit OWNERSHIPRENOUNCED804(owner);
    owner = address(0);
  }


  function TRANSFEROWNERSHIP59(address _newOwner) public ONLYOWNER146 {
    _TRANSFEROWNERSHIP932(_newOwner);
  }


  function _TRANSFEROWNERSHIP932(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OWNERSHIPTRANSFERRED780(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Pausable is Ownable {
  event PAUSE575();
  event UNPAUSE64();

  bool public paused = false;



  modifier WHENNOTPAUSED282() {
    require(!paused);
    _;
  }


  modifier WHENPAUSED855() {
    require(paused);
    _;
  }


  function PAUSE602() public ONLYOWNER146 WHENNOTPAUSED282 {
    paused = true;
    emit PAUSE575();
  }


  function UNPAUSE899() public ONLYOWNER146 WHENPAUSED855 {
    paused = false;
    emit UNPAUSE64();
  }
}

contract ERC20Basic {
    function TOTALSUPPLY769() public view returns (uint256);
    function BALANCEOF878(address _who) public view returns (uint256);
    function TRANSFER201(address _to, uint256 _value) public returns (bool);

    event TRANSFER93(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;

    uint256 internal totalSupply_;


    function TOTALSUPPLY769() public view returns (uint256) {
        return totalSupply_;
    }


    function TRANSFER201(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].SUB747(_value);
        balances[_to] = balances[_to].ADD196(_value);
        emit TRANSFER93(msg.sender, _to, _value);
        return true;
    }


    function BALANCEOF878(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {
    function ALLOWANCE103(address _owner, address _spender) public view returns (uint256);
    function TRANSFERFROM299(address _from, address _to, uint256 _value) public returns (bool);
    function APPROVE456(address _spender, uint256 _value) public returns (bool);

    event APPROVAL162(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;



    function TRANSFERFROM299(address _from, address _to, uint256 _value)
        public returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].SUB747(_value);
        balances[_to] = balances[_to].ADD196(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].SUB747(_value);
        emit TRANSFER93(_from, _to, _value);
        return true;
    }



    function APPROVE456(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit APPROVAL162(msg.sender, _spender, _value);
        return true;
    }



    function ALLOWANCE103(address _owner, address _spender)
        public view returns (uint256) {
        return allowed[_owner][_spender];
    }



    function INCREASEAPPROVAL281(address _spender, uint256 _addedValue)
        public returns (bool) {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].ADD196(_addedValue));
        emit APPROVAL162(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }



    function DECREASEAPPROVAL320(address _spender, uint256 _subtractedValue)
        public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];

        if (_subtractedValue >= oldValue) allowed[msg.sender][_spender] = 0;
        else allowed[msg.sender][_spender] = oldValue.SUB747(_subtractedValue);

        emit APPROVAL162(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract BurnableToken is StandardToken, Ownable {
    event BURN461(address indexed burner, uint256 value);



    function BURN801(address _who, uint256 _value) ONLYOWNER146 public {
        require(_value <= balances[_who]);



        balances[_who] = balances[_who].SUB747(_value);
        totalSupply_ = totalSupply_.SUB747(_value);
        emit BURN461(_who, _value);
        emit TRANSFER93(_who, address(0), _value);
    }
}

contract MintableToken is StandardToken, Ownable {
    event MINT447(address indexed to, uint256 amount);
    event MINTFINISHED751();

    bool public mintingFinished = false;


    modifier CANMINT819() {
        require(!mintingFinished);
        _;
    }


    modifier HASMINTPERMISSION565() {
        require(msg.sender == owner);
        _;
    }



    function MINT802(address _to, uint256 _amount)
        public HASMINTPERMISSION565 CANMINT819 returns (bool) {
        totalSupply_ = totalSupply_.ADD196(_amount);
        balances[_to] = balances[_to].ADD196(_amount);
        emit MINT447(_to, _amount);
        emit TRANSFER93(address(0), _to, _amount);
        return true;
    }



    function FINISHMINTING937() public ONLYOWNER146 CANMINT819 returns (bool) {
        mintingFinished = true;
        emit MINTFINISHED751();
        return true;
    }
}

contract CappedToken is MintableToken {
    uint256 public cap;


    constructor(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }



    function MINT802(address _to, uint256 _amount) public returns (bool) {
        require(totalSupply_.ADD196(_amount) <= cap);
        return super.MINT802(_to, _amount);
    }
}

contract PausableToken is StandardToken, Pausable {
    function TRANSFER201(address _to, uint256 _value)
        public WHENNOTPAUSED282 returns (bool) {
        return super.TRANSFER201(_to, _value);
    }


    function TRANSFERFROM299(address _from, address _to, uint256 _value)
        public WHENNOTPAUSED282 returns (bool) {
        return super.TRANSFERFROM299(_from, _to, _value);
    }


    function APPROVE456(address _spender, uint256 _value)
        public WHENNOTPAUSED282 returns (bool) {
        return super.APPROVE456(_spender, _value);
    }


    function INCREASEAPPROVAL281(address _spender, uint _addedValue)
        public WHENNOTPAUSED282 returns (bool success) {
        return super.INCREASEAPPROVAL281(_spender, _addedValue);
    }


    function DECREASEAPPROVAL320(address _spender, uint _subtractedValue)
        public WHENNOTPAUSED282 returns (bool success) {
        return super.DECREASEAPPROVAL320(_spender, _subtractedValue);
    }
}

contract CryptoPolitanToken is BurnableToken, PausableToken, CappedToken {
    address public upgradedAddress;
    bool public deprecated;
    string public contactInformation = "contact@cryptopolitan.com";
    string public name = "CryptoPolitan";
    string public reason;
    string public symbol = "CPOL";
    uint8 public decimals = 8;

    constructor () CappedToken(100000000000000000000) public {}


    modifier ONLYPAYLOADSIZE635(uint size) {
        require(!(msg.data.length < size + 4), "payload too big");
        _;
    }


    function TRANSFER201(address _to, uint _value) public WHENNOTPAUSED282 returns (bool) {
        if (deprecated) return UpgradedStandardToken(upgradedAddress).TRANSFERBYLEGACY691(msg.sender, _to, _value);
        else return super.TRANSFER201(_to, _value);
    }


    function TRANSFERFROM299(address _from, address _to, uint _value) public WHENNOTPAUSED282 returns (bool) {
        if (deprecated) return UpgradedStandardToken(upgradedAddress).TRANSFERFROMBYLEGACY906(msg.sender, _from, _to, _value);
        else return super.TRANSFERFROM299(_from, _to, _value);
    }


    function BALANCEOF878(address who) public view returns (uint256) {
        if (deprecated) return UpgradedStandardToken(upgradedAddress).BALANCEOF878(who);
        else return super.BALANCEOF878(who);
    }


    function APPROVE456(address _spender, uint _value) public ONLYPAYLOADSIZE635(2 * 32) returns (bool) {
        if (deprecated) return UpgradedStandardToken(upgradedAddress).APPROVEBYLEGACY941(msg.sender, _spender, _value);
        else return super.APPROVE456(_spender, _value);
    }


    function ALLOWANCE103(address _owner, address _spender) public view returns (uint remaining) {
        if (deprecated) return StandardToken(upgradedAddress).ALLOWANCE103(_owner, _spender);
        else return super.ALLOWANCE103(_owner, _spender);
    }


    function DEPRECATE994(address _upgradedAddress, string memory _reason) public ONLYOWNER146 {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        reason = _reason;
        emit DEPRECATE691(_upgradedAddress, _reason);
    }


    event DEPRECATE691(address newAddress, string reason);
}

contract UpgradedStandardToken is PausableToken {


    function TRANSFERBYLEGACY691(address from, address to, uint value) public returns (bool);
    function TRANSFERFROMBYLEGACY906(address sender, address from, address spender, uint value) public returns (bool);
    function APPROVEBYLEGACY941(address from, address spender, uint value) public returns (bool);
}
