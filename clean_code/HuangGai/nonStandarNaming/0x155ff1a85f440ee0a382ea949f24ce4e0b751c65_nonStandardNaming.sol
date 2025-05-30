


pragma solidity ^0.7.0;





library SafeMath {
    function ADD20(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function SUB525(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB525(a, b, "SafeMath: subtraction overflow");
    }

    function SUB525(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}

interface IERC20 {
    function TOTALSUPPLY48() external view returns (uint256);

    function BALANCEOF781(address account) external view returns (uint256);

    function TRANSFER338(address recipient, uint256 amount)
        external
        returns (bool);

    function ALLOWANCE551(address owner, address spender)
        external
        view
        returns (uint256);

    function APPROVE593(address spender, uint256 amount) external returns (bool);

    function TRANSFERFROM175(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event TRANSFER2(address indexed from, address indexed to, uint256 value);
    event APPROVAL598(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _MSGSENDER294() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA312() internal virtual view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED463(address indexed previousOwner, address indexed newOwner);


    constructor () {
        address msgSender = _MSGSENDER294();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED463(address(0), msgSender);
    }


    function OWNER738() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER109() {
        require(_owner == _MSGSENDER294(), "Ownable: caller is not the owner");
        _;
    }


    function RENOUNCEOWNERSHIP577() public virtual ONLYOWNER109 {
        emit OWNERSHIPTRANSFERRED463(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP444(address newOwner) public virtual ONLYOWNER109 {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED463(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Eye is Context, Ownable, IERC20 {
    uint256 public constant one557 = 1e18;
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply = 10e6 * one557;
    bool private burnEnabled = false;

    constructor() {
        _balances[msg.sender] = _totalSupply;
    }

    function NAME872() public pure returns (string memory) {
        return "Behodler.io";
    }

    function SYMBOL284() public pure returns (string memory) {
        return "EYE";
    }

    function DECIMALS495() public pure returns (uint8) {
        return 18;
    }

    function TOTALSUPPLY48() public view override returns (uint256) {
        return _totalSupply;
    }

    function BALANCEOF781(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function TRANSFER338(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _TRANSFER64(_MSGSENDER294(), recipient, amount);
        return true;
    }

    function ALLOWANCE551(address owner, address spender)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function APPROVE593(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _APPROVE384(_MSGSENDER294(), spender, amount);
        return true;
    }

    function TRANSFERFROM175(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _TRANSFER64(sender, recipient, amount);
        _APPROVE384(
            sender,
            _MSGSENDER294(),
            _allowances[sender][_MSGSENDER294()].SUB525(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function INCREASEALLOWANCE658(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _APPROVE384(
            _MSGSENDER294(),
            spender,
            _allowances[_MSGSENDER294()][spender].ADD20(addedValue)
        );
        return true;
    }

    function DECREASEALLOWANCE822(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _APPROVE384(
            _MSGSENDER294(),
            spender,
            _allowances[_MSGSENDER294()][spender].SUB525(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _TRANSFER64(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].SUB525(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].ADD20(amount);
        emit TRANSFER2(sender, recipient, amount);
    }

    function _APPROVE384(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL598(owner, spender, amount);
    }

    function ENABLEBURNING537(bool enabled) public ONLYOWNER109 {
        burnEnabled = enabled;
    }

    function BURN926 (uint value) public {
        require(burnEnabled,"burn feature not yet active.");
        _BURN884(_MSGSENDER294(),value);
    }

     function _BURN884(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.SUB525(value);
        _balances[account] = _balances[account].SUB525(value);
        emit TRANSFER2(account, address(0), value);
    }
}
