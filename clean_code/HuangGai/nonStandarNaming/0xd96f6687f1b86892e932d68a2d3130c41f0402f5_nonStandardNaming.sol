


pragma solidity 0.5.16;


contract Ownable {
    address public owner;
    address public newOwner;

    event OWNERSHIPTRANSFERRED255(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
        newOwner = address(0);
    }

    modifier ONLYOWNER801() {
        require(msg.sender == owner);
        _;
    }

    modifier ONLYNEWOWNER910() {
        require(msg.sender != address(0));
        require(msg.sender == newOwner);
        _;
    }

    function ISOWNER322(address account) public view returns (bool) {
        if( account == owner ){
            return true;
        }
        else {
            return false;
        }
    }

    function TRANSFEROWNERSHIP66(address _newOwner) public ONLYOWNER801 {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }

    function ACCEPTOWNERSHIP649() public ONLYNEWOWNER910 {
        emit OWNERSHIPTRANSFERRED255(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract Pausable is Ownable {
    event PAUSED648(address account);
    event UNPAUSED784(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }


    function PAUSED429() public view returns (bool) {
        return _paused;
    }


    modifier WHENNOTPAUSED792() {
        require(!_paused);
        _;
    }


    modifier WHENPAUSED835() {
        require(_paused);
        _;
    }


    function PAUSE539() public ONLYOWNER801 WHENNOTPAUSED792 {
        _paused = true;
        emit PAUSED648(msg.sender);
    }


    function UNPAUSE742() public ONLYOWNER801 WHENPAUSED835 {
        _paused = false;
        emit UNPAUSED784(msg.sender);
    }
}


contract Mintable {

    function MINTTOKEN168(address to, uint256 amount) public returns (bool success);


    function SETUPMINTABLEADDRESS676(address _mintable) public returns (bool success);
}


contract OffchainIssuable {

    uint256 public MIN_WITHDRAW_AMOUNT = 100;


    function SETMINWITHDRAWAMOUNT929(uint256 amount) public returns (bool success);


    function GETMINWITHDRAWAMOUNT682() public view returns (uint256 amount);


    function AMOUNTREDEEMOF405(address _owner) public view returns (uint256 amount);


    function AMOUNTWITHDRAWOF128(address _owner) public view returns (uint256 amount);


    function REDEEM734(address to, uint256 amount) external returns (bool success);


    function WITHDRAW552(uint256 amount) public returns (bool success);
}


contract Token {

    uint256 public totalSupply;


    function BALANCEOF407(address _owner) public view returns (uint256 balance);


    function TRANSFER676(address _to, uint256 _value) public returns (bool success);


    function TRANSFERFROM24(address _from, address _to, uint256 _value) public returns (bool success);


    function APPROVE688(address _spender, uint256 _value) public returns (bool success);


    function ALLOWANCE78(address _owner, address _spender) public view returns (uint256 remaining);

    event TRANSFER664(address indexed _from, address indexed _to, uint256 _value);
    event APPROVAL898(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {
    uint256 constant private max_uint256778 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function TRANSFER676(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);


        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit TRANSFER664(msg.sender, _to, _value);
        return true;
    }

    function TRANSFERFROM24(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);


        require(balances[_to] + _value >= balances[_to]);

        balances[_from] -= _value;
        balances[_to] += _value;

        if (allowance < max_uint256778) {
            allowed[_from][msg.sender] -= _value;
        }

        emit TRANSFER664(_from, _to, _value);
        return true;
    }

    function BALANCEOF407(address account) public view returns (uint256) {
        return balances[account];
    }

    function APPROVE688(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit APPROVAL898(msg.sender, _spender, _value);
        return true;
    }

    function ALLOWANCE78(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}



contract FlowchainToken is StandardToken, Mintable, OffchainIssuable, Ownable, Pausable {


    string public name = "Flowchain";
    string public symbol = "FLC";
    uint8 public decimals = 18;
    string public version = "2.0";
    address public mintableAddress;
    address public multiSigWallet;

    bool internal _isIssuable;

    event FREEZE881(address indexed account);
    event UNFREEZE906(address indexed account);

    mapping (address => uint256) private _amountMinted;
    mapping (address => uint256) private _amountRedeem;
    mapping (address => bool) public frozenAccount;

    modifier NOTFROZEN65(address _account) {
        require(!frozenAccount[_account]);
        _;
    }

    constructor(address _multiSigWallet) public {

        totalSupply = 10**27;


        multiSigWallet = _multiSigWallet;


        balances[multiSigWallet] = totalSupply;

        emit TRANSFER664(address(0), multiSigWallet, totalSupply);
    }

    function TRANSFER676(address to, uint256 value) public NOTFROZEN65(msg.sender) WHENNOTPAUSED792 returns (bool) {
        return super.TRANSFER676(to, value);
    }

    function TRANSFERFROM24(address from, address to, uint256 value) public NOTFROZEN65(from) WHENNOTPAUSED792 returns (bool) {
        return super.TRANSFERFROM24(from, to, value);
    }


    function SUSPENDISSUANCE45() external ONLYOWNER801 {
        _isIssuable = false;
    }


    function RESUMEISSUANCE530() external ONLYOWNER801 {
        _isIssuable = true;
    }


    function ISISSUABLE383() public view returns (bool success) {
        return _isIssuable;
    }


    function AMOUNTREDEEMOF405(address _owner) public view returns (uint256 amount) {
        return _amountRedeem[_owner];
    }


    function AMOUNTWITHDRAWOF128(address _owner) public view returns (uint256 amount) {
        return _amountRedeem[_owner];
    }


    function REDEEM734(address to, uint256 amount) external returns (bool success) {
        require(msg.sender == mintableAddress);
        require(_isIssuable == true);
        require(amount > 0);


        _amountRedeem[to] += amount;



        MINTTOKEN168(mintableAddress, amount);

        return true;
    }


    function WITHDRAW552(uint256 amount) public returns (bool success) {
        require(_isIssuable == true);


        require(amount > 0);
        require(amount <= _amountRedeem[msg.sender]);
        require(amount >= MIN_WITHDRAW_AMOUNT);


        require(balances[mintableAddress] >= amount);


        _amountRedeem[msg.sender] -= amount;


        _amountMinted[msg.sender] += amount;

        balances[mintableAddress] -= amount;
        balances[msg.sender] += amount;

        emit TRANSFER664(mintableAddress, msg.sender, amount);
        return true;
    }


    function SETUPMINTABLEADDRESS676(address _mintable) public ONLYOWNER801 returns (bool success) {
        mintableAddress = _mintable;
        return true;
    }


    function MINTTOKEN168(address to, uint256 amount) public returns (bool success) {
        require(msg.sender == mintableAddress);
        require(balances[multiSigWallet] >= amount);

        balances[multiSigWallet] -= amount;
        balances[to] += amount;

        emit TRANSFER664(multiSigWallet, to, amount);
        return true;
    }


    function SETMINWITHDRAWAMOUNT929(uint256 amount) public ONLYOWNER801 returns (bool success) {
        require(amount > 0);
        MIN_WITHDRAW_AMOUNT = amount;
        return true;
    }


    function GETMINWITHDRAWAMOUNT682() public view returns (uint256 amount) {
        return MIN_WITHDRAW_AMOUNT;
    }


    function FREEZEACCOUNT522(address account) public ONLYOWNER801 returns (bool) {
        require(!frozenAccount[account]);
        frozenAccount[account] = true;
        emit FREEZE881(account);
        return true;
    }


    function UNFREEZEACCOUNT409(address account) public ONLYOWNER801 returns (bool) {
        require(frozenAccount[account]);
        frozenAccount[account] = false;
        emit UNFREEZE906(account);
        return true;
    }


    function GETCREATOR217() external view returns (address) {
        return owner;
    }


    function GETMINTABLEADDRESS583() external view returns (address) {
        return mintableAddress;
    }
}
