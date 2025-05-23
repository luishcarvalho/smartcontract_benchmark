



pragma solidity ^0.6.2;

abstract contract Context {
    function _MSGSENDER792() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA319() internal virtual view returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {

    function TOTALSUPPLY627() external view returns (uint256);


    function BALANCEOF214(address account) external view returns (uint256);


    function TRANSFER284(address recipient, uint256 amount)
        external
        returns (bool);


    function ALLOWANCE87(address owner, address spender)
        external
        view
        returns (uint256);


    function APPROVE270(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM704(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    event TRANSFER280(address indexed from, address indexed to, uint256 value);


    event APPROVAL290(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {

    function ADD392(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB701(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB701(a, b, "SafeMath: subtraction overflow");
    }


    function SUB701(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL933(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV610(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV610(a, b, "SafeMath: division by zero");
    }


    function DIV610(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD161(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD161(a, b, "SafeMath: modulo by zero");
    }


    function MOD161(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function ISCONTRACT415(address account) internal view returns (bool) {




        uint256 size;

        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    function SENDVALUE405(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );


        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }


    function FUNCTIONCALL165(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return FUNCTIONCALL165(target, data, "Address: low-level call failed");
    }


    function FUNCTIONCALL165(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _FUNCTIONCALLWITHVALUE741(target, data, 0, errorMessage);
    }


    function FUNCTIONCALLWITHVALUE297(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            FUNCTIONCALLWITHVALUE297(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }


    function FUNCTIONCALLWITHVALUE297(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _FUNCTIONCALLWITHVALUE741(target, data, value, errorMessage);
    }

    function _FUNCTIONCALLWITHVALUE741(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(ISCONTRACT415(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED644(
        address indexed previousOwner,
        address indexed newOwner
    );


    constructor() internal {
        address msgSender = _MSGSENDER792();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED644(address(0), msgSender);
    }


    function OWNER788() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER946() {
        require(_owner == _MSGSENDER792(), "Ownable: caller is not the owner");
        _;
    }


    function RENOUNCEOWNERSHIP657() public virtual ONLYOWNER946 {
        emit OWNERSHIPTRANSFERRED644(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP245(address newOwner) public virtual ONLYOWNER946 {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OWNERSHIPTRANSFERRED644(_owner, newOwner);
        _owner = newOwner;
    }
}


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }


    function NAME278() public view returns (string memory) {
        return _name;
    }


    function SYMBOL52() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS613() public view returns (uint8) {
        return _decimals;
    }


    function TOTALSUPPLY627() public override view returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF214(address account) public override view returns (uint256) {
        return _balances[account];
    }


    function TRANSFER284(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _TRANSFER770(_MSGSENDER792(), recipient, amount);
        return true;
    }


    function ALLOWANCE87(address owner, address spender)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }


    function APPROVE270(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _APPROVE295(_MSGSENDER792(), spender, amount);
        return true;
    }


    function TRANSFERFROM704(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _TRANSFER770(sender, recipient, amount);
        _APPROVE295(
            sender,
            _MSGSENDER792(),
            _allowances[sender][_MSGSENDER792()].SUB701(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }


    function INCREASEALLOWANCE237(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _APPROVE295(
            _MSGSENDER792(),
            spender,
            _allowances[_MSGSENDER792()][spender].ADD392(addedValue)
        );
        return true;
    }


    function DECREASEALLOWANCE219(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _APPROVE295(
            _MSGSENDER792(),
            spender,
            _allowances[_MSGSENDER792()][spender].SUB701(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }


    function _TRANSFER770(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _BEFORETOKENTRANSFER837(sender, recipient, amount);

        _balances[sender] = _balances[sender].SUB701(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].ADD392(amount);
        emit TRANSFER280(sender, recipient, amount);
    }


    function _MINT54(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _BEFORETOKENTRANSFER837(address(0), account, amount);

        _totalSupply = _totalSupply.ADD392(amount);
        _balances[account] = _balances[account].ADD392(amount);
        emit TRANSFER280(address(0), account, amount);
    }


    function _BURN901(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _BEFORETOKENTRANSFER837(account, address(0), amount);

        _balances[account] = _balances[account].SUB701(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.SUB701(amount);
        emit TRANSFER280(account, address(0), amount);
    }


    function _APPROVE295(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL290(owner, spender, amount);
    }


    function _SETUPDECIMALS815(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _BEFORETOKENTRANSFER837(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract TCharizardFarm is ERC20("t.me/charizardfarm", "TCRZF"), Ownable {

    function MINT23(address _to, uint256 _amount) public ONLYOWNER946 {
        _MINT54(_to, _amount);
    }
}


