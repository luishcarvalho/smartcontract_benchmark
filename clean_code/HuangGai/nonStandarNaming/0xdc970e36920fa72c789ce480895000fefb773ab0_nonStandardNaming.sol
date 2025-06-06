pragma solidity ^0.5.2;


contract Ownable {
    address private _owner;

    event OWNERSHIPTRANSFERRED275(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = msg.sender;
        emit OWNERSHIPTRANSFERRED275(address(0), _owner);
    }


    function OWNER625() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER263() {
        require(ISOWNER221());
        _;
    }


    function ISOWNER221() public view returns (bool) {
        return msg.sender == _owner;
    }


    function RENOUNCEOWNERSHIP563() public ONLYOWNER263 {
        emit OWNERSHIPTRANSFERRED275(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP811(address newOwner) public ONLYOWNER263 {
        _TRANSFEROWNERSHIP827(newOwner);
    }


    function _TRANSFEROWNERSHIP827(address newOwner) internal {
        require(newOwner != address(0));
        emit OWNERSHIPTRANSFERRED275(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Secondary {
    address private _primary;

    event PRIMARYTRANSFERRED466(
        address recipient
    );


    constructor () internal {
        _primary = msg.sender;
        emit PRIMARYTRANSFERRED466(_primary);
    }


    modifier ONLYPRIMARY116() {
        require(msg.sender == _primary);
        _;
    }


    function PRIMARY581() public view returns (address) {
        return _primary;
    }


    function TRANSFERPRIMARY630(address recipient) public ONLYPRIMARY116 {
        require(recipient != address(0));
        _primary = recipient;
        emit PRIMARYTRANSFERRED466(_primary);
    }
}




interface IERC20 {
    function TRANSFER568(address to, uint256 value) external returns (bool);

    function APPROVE366(address spender, uint256 value) external returns (bool);

    function TRANSFERFROM855(address from, address to, uint256 value) external returns (bool);

    function TOTALSUPPLY96() external view returns (uint256);

    function BALANCEOF58(address who) external view returns (uint256);

    function ALLOWANCE511(address owner, address spender) external view returns (uint256);

    event TRANSFER836(address indexed from, address indexed to, uint256 value);

    event APPROVAL290(address indexed owner, address indexed spender, uint256 value);
}





library SafeMath {

    function MUL97(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }


    function DIV803(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }


    function SUB631(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }


    function ADD445(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }


    function MOD309(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}





contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;


    function TOTALSUPPLY96() public view returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF58(address owner) public view returns (uint256) {
        return _balances[owner];
    }


    function ALLOWANCE511(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }


    function TRANSFER568(address to, uint256 value) public returns (bool) {
        _TRANSFER261(msg.sender, to, value);
        return true;
    }


    function APPROVE366(address spender, uint256 value) public returns (bool) {
        _APPROVE283(msg.sender, spender, value);
        return true;
    }


    function TRANSFERFROM855(address from, address to, uint256 value) public returns (bool) {
        _TRANSFER261(from, to, value);
        _APPROVE283(from, msg.sender, _allowed[from][msg.sender].SUB631(value));
        return true;
    }


    function INCREASEALLOWANCE464(address spender, uint256 addedValue) public returns (bool) {
        _APPROVE283(msg.sender, spender, _allowed[msg.sender][spender].ADD445(addedValue));
        return true;
    }


    function DECREASEALLOWANCE302(address spender, uint256 subtractedValue) public returns (bool) {
        _APPROVE283(msg.sender, spender, _allowed[msg.sender][spender].SUB631(subtractedValue));
        return true;
    }


    function _TRANSFER261(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].SUB631(value);
        _balances[to] = _balances[to].ADD445(value);
        emit TRANSFER836(from, to, value);
    }


    function _MINT945(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.ADD445(value);
        _balances[account] = _balances[account].ADD445(value);
        emit TRANSFER836(address(0), account, value);
    }


    function _BURN542(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.SUB631(value);
        _balances[account] = _balances[account].SUB631(value);
        emit TRANSFER836(account, address(0), value);
    }


    function _APPROVE283(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit APPROVAL290(owner, spender, value);
    }


    function _BURNFROM236(address account, uint256 value) internal {
        _BURN542(account, value);
        _APPROVE283(account, msg.sender, _allowed[account][msg.sender].SUB631(value));
    }
}




contract ERC20Burnable is ERC20 {

    function BURN435(uint256 value) public {
        _BURN542(msg.sender, value);
    }


    function BURNFROM369(address from, uint256 value) public {
        _BURNFROM236(from, value);
    }
}


library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }


    function ADD445(Role storage role, address account) internal {
        require(account != address(0));
        require(!HAS23(role, account));

        role.bearer[account] = true;
    }


    function REMOVE600(Role storage role, address account) internal {
        require(account != address(0));
        require(HAS23(role, account));

        role.bearer[account] = false;
    }


    function HAS23(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


contract MinterRole {
    using Roles for Roles.Role;

    event MINTERADDED570(address indexed account);
    event MINTERREMOVED239(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _ADDMINTER827(msg.sender);
    }

    modifier ONLYMINTER291() {
        require(ISMINTER698(msg.sender));
        _;
    }

    function ISMINTER698(address account) public view returns (bool) {
        return _minters.HAS23(account);
    }

    function ADDMINTER239(address account) public ONLYMINTER291 {
        _ADDMINTER827(account);
    }

    function RENOUNCEMINTER237() public {
        _REMOVEMINTER650(msg.sender);
    }

    function _ADDMINTER827(address account) internal {
        _minters.ADD445(account);
        emit MINTERADDED570(account);
    }

    function _REMOVEMINTER650(address account) internal {
        _minters.REMOVE600(account);
        emit MINTERREMOVED239(account);
    }
}




contract ERC20Mintable is ERC20, MinterRole {

    function MINT610(address to, uint256 value) public ONLYMINTER291 returns (bool) {
        _MINT945(to, value);
        return true;
    }
}





contract ERC20Frozenable is ERC20Burnable, ERC20Mintable, Ownable {
    mapping (address => bool) private _frozenAccount;
    event FROZENFUNDS807(address target, bool frozen);


    function FROZENACCOUNT782(address _address) public view returns(bool isFrozen) {
        return _frozenAccount[_address];
    }

    function FREEZEACCOUNT250(address target, bool freeze)  public ONLYOWNER263 {
        require(_frozenAccount[target] != freeze, "Same as current");
        _frozenAccount[target] = freeze;
        emit FROZENFUNDS807(target, freeze);
    }

    function _TRANSFER261(address from, address to, uint256 value) internal {
        require(!_frozenAccount[from], "error - frozen");
        require(!_frozenAccount[to], "error - frozen");
        super._TRANSFER261(from, to, value);
    }

}




contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }


    function NAME858() public view returns (string memory) {
        return _name;
    }


    function SYMBOL418() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS361() public view returns (uint8) {
        return _decimals;
    }
}


contract Escrow is Secondary {
    using SafeMath for uint256;

    event DEPOSITED6(address indexed payee, uint256 weiAmount);
    event WITHDRAWN702(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function DEPOSITSOF491(address payee) public view returns (uint256) {
        return _deposits[payee];
    }


    function DEPOSIT494(address payee) public ONLYPRIMARY116 payable {
        uint256 amount = msg.value;
        _deposits[payee] = _deposits[payee].ADD445(amount);

        emit DEPOSITED6(payee, amount);
    }


    function WITHDRAW275(address payable payee) public ONLYPRIMARY116 {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.transfer(payment);

        emit WITHDRAWN702(payee, payment);
    }
}


contract PullPayment {
    Escrow private _escrow;

    constructor () internal {
        _escrow = new Escrow();
    }


    function WITHDRAWPAYMENTS729(address payable payee) public {
        _escrow.WITHDRAW275(payee);
    }


    function PAYMENTS838(address dest) public view returns (uint256) {
        return _escrow.DEPOSITSOF491(dest);
    }


    function _ASYNCTRANSFER275(address dest, uint256 amount) internal {
        _escrow.DEPOSIT494.value(amount)(dest);
    }
}

contract PaymentSplitter {
    using SafeMath for uint256;

    event PAYEEADDED416(address account, uint256 shares);
    event PAYMENTRELEASED38(address to, uint256 amount);
    event PAYMENTRECEIVED491(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;


    constructor (address[] memory payees, uint256[] memory shares) public payable {
        require(payees.length == shares.length);
        require(payees.length > 0);

        for (uint256 i = 0; i < payees.length; i++) {
            _ADDPAYEE628(payees[i], shares[i]);
        }
    }


    function () external payable {
        emit PAYMENTRECEIVED491(msg.sender, msg.value);
    }


    function TOTALSHARES81() public view returns (uint256) {
        return _totalShares;
    }


    function TOTALRELEASED129() public view returns (uint256) {
        return _totalReleased;
    }


    function SHARES670(address account) public view returns (uint256) {
        return _shares[account];
    }


    function RELEASED874(address account) public view returns (uint256) {
        return _released[account];
    }


    function PAYEE185(uint256 index) public view returns (address) {
        return _payees[index];
    }


    function RELEASE471(address payable account) public {
        require(_shares[account] > 0);

        uint256 totalReceived = address(this).balance.ADD445(_totalReleased);
        uint256 payment = totalReceived.MUL97(_shares[account]).DIV803(_totalShares).SUB631(_released[account]);

        require(payment != 0);

        _released[account] = _released[account].ADD445(payment);
        _totalReleased = _totalReleased.ADD445(payment);

        account.transfer(payment);
        emit PAYMENTRELEASED38(account, payment);
    }


    function _ADDPAYEE628(address account, uint256 shares_) private {
        require(account != address(0));
        require(shares_ > 0);
        require(_shares[account] == 0);

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares.ADD445(shares_);
        emit PAYEEADDED416(account, shares_);
    }
}

contract ConditionalEscrow is Escrow {

    function WITHDRAWALALLOWED82(address payee) public view returns (bool);

    function WITHDRAW275(address payable payee) public {
        require(WITHDRAWALALLOWED82(payee));
        super.WITHDRAW275(payee);
    }
}


contract RefundEscrow is ConditionalEscrow {
    enum State { Active, Refunding, Closed }

    event REFUNDSCLOSED652();
    event REFUNDSENABLED266();

    State private _state;
    address payable private _beneficiary;


    constructor (address payable beneficiary) public {
        require(beneficiary != address(0));
        _beneficiary = beneficiary;
        _state = State.Active;
    }


    function STATE442() public view returns (State) {
        return _state;
    }


    function BENEFICIARY91() public view returns (address) {
        return _beneficiary;
    }


    function DEPOSIT494(address refundee) public payable {
        require(_state == State.Active);
        super.DEPOSIT494(refundee);
    }


    function CLOSE124() public ONLYPRIMARY116 {
        require(_state == State.Active);
        _state = State.Closed;
        emit REFUNDSCLOSED652();
    }


    function ENABLEREFUNDS102() public ONLYPRIMARY116 {
        require(_state == State.Active);
        _state = State.Refunding;
        emit REFUNDSENABLED266();
    }


    function BENEFICIARYWITHDRAW365() public {
        require(_state == State.Closed);
        _beneficiary.transfer(address(this).balance);
    }


    function WITHDRAWALALLOWED82(address) public view returns (bool) {
        return _state == State.Refunding;
    }
}


contract DeltaBlocks is ERC20Frozenable, ERC20Detailed {

    constructor()
    ERC20Detailed("Delta Blocks", "DTB", 18)
    public {
        uint256 supply = 10000000000;
        uint256 initialSupply = supply * uint(10) ** DECIMALS361();
        _MINT945(msg.sender, initialSupply);
    }
}
