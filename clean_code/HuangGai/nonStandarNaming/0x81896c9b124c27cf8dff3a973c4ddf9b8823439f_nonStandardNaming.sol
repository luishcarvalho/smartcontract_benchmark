



pragma solidity ^0.5.7;


library SafeMath {

    int256 constant private int256_min606 = -2**255;


    function MUL578(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }


    function MUL578(int256 a, int256 b) internal pure returns (int256) {



        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == int256_min606));

        int256 c = a * b;
        require(c / a == b);

        return c;
    }


    function DIV266(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }


    function DIV266(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);
        require(!(b == -1 && a == int256_min606));

        int256 c = a / b;

        return c;
    }


    function SUB55(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }


    function SUB55(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }


    function ADD666(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }


    function ADD666(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }


    function MOD120(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



interface IERC20 {
    function TOTALSUPPLY304() external view returns (uint256);

    function BALANCEOF735(address who) external view returns (uint256);

    function ALLOWANCE123(address owner, address spender) external view returns (uint256);

    function TRANSFER854(address to, uint256 value) external returns (bool);

    function APPROVE531(address spender, uint256 value) external returns (bool);

    function TRANSFERFROM522(address from, address to, uint256 value) external returns (bool);

    event TRANSFER418(address indexed from, address indexed to, uint256 value);

    event APPROVAL780(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Pistachio is IERC20 {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;




    string public symbol;


    string public  name;


    uint8 public decimals;


    constructor (address initialAccount, string memory _tokenSymbol, string memory _tokenName, uint256 initialBalance) public {


        symbol = _tokenSymbol;
        name = _tokenName;
        decimals = 18;

        _MINT600(initialAccount, initialBalance);

    }


    function TOTALSUPPLY304() public view returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF735(address owner) public view returns (uint256) {
        return _balances[owner];
    }


    function ALLOWANCE123(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }


    function TRANSFER854(address to, uint256 value) public returns (bool) {
        _TRANSFER481(msg.sender, to, value);
        return true;
    }


    function APPROVE531(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit APPROVAL780(msg.sender, spender, value);
        return true;
    }


    function TRANSFERFROM522(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].SUB55(value);
        _TRANSFER481(from, to, value);
        emit APPROVAL780(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }


    function INCREASEALLOWANCE330(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].ADD666(addedValue);
        emit APPROVAL780(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }


    function DECREASEALLOWANCE446(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].SUB55(subtractedValue);
        emit APPROVAL780(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }


    function _TRANSFER481(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].SUB55(value);
        _balances[to] = _balances[to].ADD666(value);
        emit TRANSFER418(from, to, value);
    }


    function _MINT600(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.ADD666(value);
        _balances[account] = _balances[account].ADD666(value);
        emit TRANSFER418(address(0), account, value);
    }


    function _BURN785(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.SUB55(value);
        _balances[account] = _balances[account].SUB55(value);
        emit TRANSFER418(account, address(0), value);
    }


    function _BURNFROM615(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].SUB55(value);
        _BURN785(account, value);
        emit APPROVAL780(account, msg.sender, _allowed[account][msg.sender]);
    }

}


contract ERC20Burnable is ERC20Pistachio {

    bool private _burnableActive;


    function BURN665(uint256 value) public WHENBURNABLEACTIVE644 {
        _BURN785(msg.sender, value);
    }


    function BURNFROM948(address from, uint256 value) public WHENBURNABLEACTIVE644 {
        _BURNFROM615(from, value);
    }



    function _SETBURNABLEACTIVE519(bool _active) internal {
        _burnableActive = _active;
    }

    modifier WHENBURNABLEACTIVE644() {
        require(_burnableActive);
        _;
    }

}


library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }


    function ADD666(Role storage role, address account) internal {
        require(account != address(0));
        require(!HAS322(role, account));

        role.bearer[account] = true;
    }


    function REMOVE231(Role storage role, address account) internal {
        require(account != address(0));
        require(HAS322(role, account));

        role.bearer[account] = false;
    }


    function HAS322(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MINTERADDED605(address indexed account);
    event MINTERREMOVED905(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _ADDMINTER929(msg.sender);
    }

    modifier ONLYMINTER785() {
        require(ISMINTER455(msg.sender));
        _;
    }

    function ISMINTER455(address account) public view returns (bool) {
        return _minters.HAS322(account);
    }

    function ADDMINTER562(address account) public ONLYMINTER785 {
        _ADDMINTER929(account);
    }

    function RENOUNCEMINTER297() public {
        _REMOVEMINTER917(msg.sender);
    }

    function _ADDMINTER929(address account) internal {
        _minters.ADD666(account);
        emit MINTERADDED605(account);
    }

    function _REMOVEMINTER917(address account) internal {
        _minters.REMOVE231(account);
        emit MINTERREMOVED905(account);
    }
}


contract ERC20Mintable is ERC20Pistachio, MinterRole {

    bool private _mintableActive;

    function MINT525(address to, uint256 value) public ONLYMINTER785 WHENMINTABLEACTIVE702 returns (bool) {
        _MINT600(to, value);
        return true;
    }



    function _SETMINTABLEACTIVE686(bool _active) internal {
        _mintableActive = _active;
    }

    modifier WHENMINTABLEACTIVE702() {
        require(_mintableActive);
        _;
    }

}

contract PauserRole {
    using Roles for Roles.Role;

    event PAUSERADDED252(address indexed account);
    event PAUSERREMOVED538(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _ADDPAUSER941(msg.sender);
    }

    modifier ONLYPAUSER672() {
        require(ISPAUSER604(msg.sender));
        _;
    }

    function ISPAUSER604(address account) public view returns (bool) {
        return _pausers.HAS322(account);
    }

    function ADDPAUSER65(address account) public ONLYPAUSER672 {
        _ADDPAUSER941(account);
    }

    function RENOUNCEPAUSER647() public {
        _REMOVEPAUSER706(msg.sender);
    }

    function _ADDPAUSER941(address account) internal {
        _pausers.ADD666(account);
        emit PAUSERADDED252(account);
    }

    function _REMOVEPAUSER706(address account) internal {
        _pausers.REMOVE231(account);
        emit PAUSERREMOVED538(account);
    }
}


contract Pausable is PauserRole {
    event PAUSED114(address account);
    event UNPAUSED110(address account);

    bool private _pausableActive;
    bool private _paused;

    constructor () internal {
        _paused = false;
    }


    function PAUSED723() public view returns (bool) {
        return _paused;
    }


    modifier WHENNOTPAUSED424() {
        require(!_paused);
        _;
    }


    modifier WHENPAUSED745() {
        require(_paused);
        _;
    }


    function PAUSE827() public ONLYPAUSER672 WHENNOTPAUSED424 WHENPAUSABLEACTIVE658 {
        _paused = true;
        emit PAUSED114(msg.sender);
    }


    function UNPAUSE942() public ONLYPAUSER672 WHENPAUSED745 WHENPAUSABLEACTIVE658 {
        _paused = false;
        emit UNPAUSED110(msg.sender);
    }



    function _SETPAUSABLEACTIVE337(bool _active) internal {
        _pausableActive = _active;
    }

    modifier WHENPAUSABLEACTIVE658() {
        require(_pausableActive);
        _;
    }

}


contract ERC20Chocolate is ERC20Pistachio, ERC20Burnable, ERC20Mintable, Pausable {


    uint256 private _cap;

    constructor (
        address initialAccount, string memory _tokenSymbol, string memory _tokenName, uint256 initialBalance, uint256 cap,
        bool _burnableOption, bool _mintableOption, bool _pausableOption
    ) public
        ERC20Pistachio(initialAccount, _tokenSymbol, _tokenName, initialBalance) {


        ADDMINTER562(initialAccount);


        ADDPAUSER65(initialAccount);

        if (cap > 0) {
            _cap = cap;
        } else {
            _cap = 0;
        }


        _SETBURNABLEACTIVE519(_burnableOption);
        _SETMINTABLEACTIVE686(_mintableOption);
        _SETPAUSABLEACTIVE337(_pausableOption);

    }


    function CAP794() public view returns (uint256) {
        return _cap;
    }


    function _MINT600(address account, uint256 value) internal {
        if (_cap > 0) {
            require(TOTALSUPPLY304().ADD666(value) <= _cap);
        }
        super._MINT600(account, value);
    }


    function TRANSFER854(address to, uint256 value) public WHENNOTPAUSED424 returns (bool) {
        return super.TRANSFER854(to, value);
    }

    function TRANSFERFROM522(address from,address to, uint256 value) public WHENNOTPAUSED424 returns (bool) {
        return super.TRANSFERFROM522(from, to, value);
    }

    function APPROVE531(address spender, uint256 value) public WHENNOTPAUSED424 returns (bool) {
        return super.APPROVE531(spender, value);
    }

    function INCREASEALLOWANCE330(address spender, uint addedValue) public WHENNOTPAUSED424 returns (bool success) {
        return super.INCREASEALLOWANCE330(spender, addedValue);
    }

    function DECREASEALLOWANCE446(address spender, uint subtractedValue) public WHENNOTPAUSED424 returns (bool success) {
        return super.DECREASEALLOWANCE446(spender, subtractedValue);
    }

}


contract ReentrancyGuard {

    uint256 private _guardCounter;

    constructor () internal {


        _guardCounter = 1;
    }


    modifier NONREENTRANT377() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER714(IERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN667(token, abi.encodeWithSelector(token.TRANSFER854.selector, to, value));
    }

    function SAFETRANSFERFROM672(IERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN667(token, abi.encodeWithSelector(token.TRANSFERFROM522.selector, from, to, value));
    }

    function SAFEAPPROVE372(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.ALLOWANCE123(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN667(token, abi.encodeWithSelector(token.APPROVE531.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE265(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE123(address(this), spender).ADD666(value);
        CALLOPTIONALRETURN667(token, abi.encodeWithSelector(token.APPROVE531.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE998(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE123(address(this), spender).SUB55(value);
        CALLOPTIONALRETURN667(token, abi.encodeWithSelector(token.APPROVE531.selector, spender, newAllowance));
    }


    function CALLOPTIONALRETURN667(IERC20 token, bytes memory data) private {








        require(address(token).ISCONTRACT761(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


library Address {

    function ISCONTRACT761(address account) internal view returns (bool) {







        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }


    function TOPAYABLE851(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}


contract Crowdsale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Chocolate;


    ERC20Chocolate private _token;


    address payable private _wallet;





    uint256 private _rate;


    uint256 private _weiRaised;


    event TOKENSPURCHASED287(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    constructor (uint256 rate, address payable wallet, ERC20Chocolate token) public {
        require(rate > 0, "Crowdsale: rate is 0");
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }


    function () external payable {
        BUYTOKENS434(msg.sender);
    }


    function TOKEN293() public view returns (IERC20) {
        return _token;
    }


    function WALLET108() public view returns (address payable) {
        return _wallet;
    }


    function RATE426() public view returns (uint256) {
        return _rate;
    }


    function WEIRAISED13() public view returns (uint256) {
        return _weiRaised;
    }


    function BUYTOKENS434(address beneficiary) public NONREENTRANT377 payable {
        uint256 weiAmount = msg.value;
        _PREVALIDATEPURCHASE289(beneficiary, weiAmount);


        uint256 tokens = _GETTOKENAMOUNT276(weiAmount);


        _weiRaised = _weiRaised.ADD666(weiAmount);

        _PROCESSPURCHASE887(beneficiary, tokens);
        emit TOKENSPURCHASED287(msg.sender, beneficiary, weiAmount, tokens);

        _UPDATEPURCHASINGSTATE322(beneficiary, weiAmount);

        _FORWARDFUNDS963();
        _POSTVALIDATEPURCHASE368(beneficiary, weiAmount);
    }


    function _PREVALIDATEPURCHASE289(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
    }


    function _POSTVALIDATEPURCHASE368(address beneficiary, uint256 weiAmount) internal view {

    }


    function _DELIVERTOKENS47(address beneficiary, uint256 tokenAmount) internal {
        _token.SAFETRANSFER714(beneficiary, tokenAmount);
    }


    function _PROCESSPURCHASE887(address beneficiary, uint256 tokenAmount) internal {
        _DELIVERTOKENS47(beneficiary, tokenAmount);
    }


    function _UPDATEPURCHASINGSTATE322(address beneficiary, uint256 weiAmount) internal {

    }


    function _GETTOKENAMOUNT276(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.MUL578(_rate);
    }


    function _FORWARDFUNDS963() internal {
        _wallet.transfer(msg.value);
    }
}


contract MintedCrowdsale is Crowdsale {

    function _DELIVERTOKENS47(address beneficiary, uint256 tokenAmount) internal {

        require(
            ERC20Mintable(address(TOKEN293())).MINT525(beneficiary, tokenAmount),
                "MintedCrowdsale: minting failed"
        );
    }
}


contract PausableCrowdsale is Crowdsale, Pausable {

    function _PREVALIDATEPURCHASE289(address _beneficiary, uint256 _weiAmount) internal view WHENNOTPAUSED424 {
        return super._PREVALIDATEPURCHASE289(_beneficiary, _weiAmount);
    }
}


contract CrowdsaleRaspberry is MintedCrowdsale, PausableCrowdsale {
    constructor (uint256 rate, address payable wallet, ERC20Chocolate token, bool _isPausable) public
    Crowdsale(rate, wallet, token) {

        _SETPAUSABLEACTIVE337(_isPausable);
    }
}
