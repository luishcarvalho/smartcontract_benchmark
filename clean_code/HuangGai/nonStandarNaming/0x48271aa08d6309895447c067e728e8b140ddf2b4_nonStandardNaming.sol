pragma solidity ^0.5.8;

library SafeMath {

    function MUL38(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV634(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;


        return c;
    }


    function SUB406(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }


    function ADD700(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

contract Ownable {
    address private _owner;

    event OWNERSHIPTRANSFERRED30(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = 0xfc0281163cFeDA9FbB3B18A72A27310B1725fD65;
        emit OWNERSHIPTRANSFERRED30(address(0), _owner);
    }


    function OWNER975() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER510() {
        require(ISOWNER350(), "Ownable: caller is not the owner");
        _;
    }


    function ISOWNER350() public view returns (bool) {
        return msg.sender == _owner;
    }


    function RENOUNCEOWNERSHIP332() public ONLYOWNER510 {
        emit OWNERSHIPTRANSFERRED30(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP193(address newOwner) public ONLYOWNER510 {
        _TRANSFEROWNERSHIP229(newOwner);
    }


    function _TRANSFEROWNERSHIP229(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED30(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function TRANSFER697(address to, uint256 value) external returns (bool);
    function APPROVE20(address spender, uint256 value) external returns (bool);
    function TRANSFERFROM431(address from, address to, uint256 value) external returns (bool);
    function TOTALSUPPLY947() external view returns (uint256);
    function BALANCEOF859(address who) external view returns (uint256);
    function ALLOWANCE181(address owner, address spender) external view returns (uint256);
    event TRANSFER948(address indexed from, address indexed to, uint256 value);
    event APPROVAL469(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;


    function TOTALSUPPLY947() public view returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF859(address owner) public view returns (uint256) {
        return _balances[owner];
    }


    function ALLOWANCE181(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    function TRANSFER697(address to, uint256 value) public returns (bool) {
        _TRANSFER167(msg.sender, to, value);
        return true;
    }


    function APPROVE20(address spender, uint256 value) public returns (bool) {
        _APPROVE409(msg.sender, spender, value);
        return true;
    }


    function TRANSFERFROM431(address from, address to, uint256 value) public returns (bool) {
        _TRANSFER167(from, to, value);
        _APPROVE409(from, msg.sender, _allowances[from][msg.sender].SUB406(value));
        return true;
    }


    function INCREASEALLOWANCE260(address spender, uint256 addedValue) public returns (bool) {
        _APPROVE409(msg.sender, spender, _allowances[msg.sender][spender].ADD700(addedValue));
        return true;
    }


    function DECREASEALLOWANCE155(address spender, uint256 subtractedValue) public returns (bool) {
        _APPROVE409(msg.sender, spender, _allowances[msg.sender][spender].SUB406(subtractedValue));
        return true;
    }


    function _TRANSFER167(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _balances[from] = _balances[from].SUB406(value);
        _balances[to] = _balances[to].ADD700(value);
        emit TRANSFER948(from, to, value);
    }


    function _MINT833(address account, uint256 value) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.ADD700(value);
        _balances[account] = _balances[account].ADD700(value);
        emit TRANSFER948(address(0), account, value);
    }


    function _APPROVE409(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit APPROVAL469(owner, spender, value);
    }
}

contract CSCToken is ERC20, Ownable {
    using SafeMath for uint256;

    string public constant name863     = "Crypto Service Capital Token";
    string public constant symbol721   = "CSCT";
    uint8  public constant decimals85 = 18;

    bool public mintingFinished = false;
    mapping (address => bool) private _minters;
    event MINT126(address indexed to, uint256 amount);
    event MINTFINISHED370();

    modifier CANMINT211() {
        require(!mintingFinished);
        _;
    }

    function ISMINTER256(address minter) public view returns (bool) {
        if (OWNER975() == minter) {
            return true;
        }
        return _minters[minter];
    }

    modifier ONLYMINTER211() {
        require(ISMINTER256(msg.sender), "Minter: caller is not the minter");
        _;
    }

    function ADDMINTER63(address _minter) external ONLYOWNER510 returns (bool) {
        require(_minter != address(0));
        _minters[_minter] = true;
        return true;
    }

    function REMOVEMINTER886(address _minter) external ONLYOWNER510 returns (bool) {
        require(_minter != address(0));
        _minters[_minter] = false;
        return true;
    }

    function MINT259(address to, uint256 value) public ONLYMINTER211 returns (bool) {
        _MINT833(to, value);
        emit MINT126(to, value);
        return true;
    }

    function FINISHMINTING196() ONLYOWNER510 CANMINT211 external returns (bool) {
        mintingFinished = true;
        emit MINTFINISHED370();
        return true;
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;

    uint256 public constant rate431 = 1000;
    uint256 public constant cap376 = 10000 ether;

    bool public isFinalized = false;
    uint256 public startTime = 1559347199;
    uint256 public endTime = 1577836799;

    CSCToken public token;
    address payable public wallet = 0x1524Aa69ef4BA327576FcF548f7dD14aEaC8CA18;
    uint256 public weiRaised;

    uint256 public firstBonus = 30;
    uint256 public secondBonus = 50;

    event TOKENPURCHASE96(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event FINALIZED531();

    constructor (CSCToken _CSCT) public {
        assert(address(_CSCT) != address(0));
        token = _CSCT;
    }

    function () external payable {
        BUYTOKENS779(msg.sender);
    }


    function VALIDPURCHASE868() internal view returns (bool) {
        require(!token.mintingFinished());
        require(weiRaised <= cap376);
        require(now >= startTime);
        require(now <= endTime);
        require(msg.value >= 0.001 ether);

        return true;
    }

    function TOKENSFORWEI360(uint weiAmount) public view returns (uint tokens) {
        tokens = weiAmount.MUL38(rate431);
        tokens = tokens.ADD700(GETBONUS366(tokens, weiAmount));
    }

    function GETBONUS366(uint256 _tokens, uint256 _weiAmount) public view returns (uint256) {
        if (_weiAmount >= 30 ether) {
            return _tokens.MUL38(secondBonus).DIV634(100);
        }
        return _tokens.MUL38(firstBonus).DIV634(100);
    }

    function BUYTOKENS779(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(VALIDPURCHASE868());

        uint256 weiAmount = msg.value;
        uint256 tokens = TOKENSFORWEI360(weiAmount);
        weiRaised = weiRaised.ADD700(weiAmount);

        token.MINT259(beneficiary, tokens);
        emit TOKENPURCHASE96(msg.sender, beneficiary, weiAmount, tokens);

        wallet.transfer(msg.value);
    }

    function SETFIRSTBONUS839(uint256 _newBonus) ONLYOWNER510 external {
        firstBonus = _newBonus;
    }

    function SETSECONDBONUS714(uint256 _newBonus) ONLYOWNER510 external {
        secondBonus = _newBonus;
    }

    function CHANGEENDTIME347(uint256 _newTime) ONLYOWNER510 external {
        require(endTime >= now);
        endTime = _newTime;
    }


    function FINALIZE617() ONLYOWNER510 external {
        require(!isFinalized);

        endTime = now;
        isFinalized = true;
        emit FINALIZED531();
    }


    function HASENDED686() external view returns (bool) {
        return now > endTime;
    }
}
