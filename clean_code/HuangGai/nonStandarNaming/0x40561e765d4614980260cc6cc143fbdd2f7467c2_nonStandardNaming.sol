

pragma solidity ^0.6.6;



abstract contract Context {
    function _MSGSENDER800() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA819() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}



interface IERC20 {

    function TOTALSUPPLY18() external view returns (uint256);


    function BALANCEOF19(address account) external view returns (uint256);


    function TRANSFER188(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE990(address owner, address spender) external view returns (uint256);


    function APPROVE569(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM677(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER36(address indexed from, address indexed to, uint256 value);


    event APPROVAL777(address indexed owner, address indexed spender, uint256 value);
}



library SafeMath {

    function ADD452(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB908(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB908(a, b, "SafeMath: subtraction overflow");
    }


    function SUB908(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL764(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV702(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV702(a, b, "SafeMath: division by zero");
    }


    function DIV702(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD170(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD170(a, b, "SafeMath: modulo by zero");
    }


    function MOD170(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



library Address {

    function ISCONTRACT666(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function SENDVALUE670(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function FUNCTIONCALL237(address target, bytes memory data) internal returns (bytes memory) {
      return FUNCTIONCALL237(target, data, "Address: low-level call failed");
    }


    function FUNCTIONCALL237(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _FUNCTIONCALLWITHVALUE645(target, data, 0, errorMessage);
    }


    function FUNCTIONCALLWITHVALUE846(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return FUNCTIONCALLWITHVALUE846(target, data, value, "Address: low-level call with value failed");
    }


    function FUNCTIONCALLWITHVALUE846(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _FUNCTIONCALLWITHVALUE645(target, data, value, errorMessage);
    }

    function _FUNCTIONCALLWITHVALUE645(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(ISCONTRACT666(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }


    function NAME463() public view returns (string memory) {
        return _name;
    }


    function SYMBOL625() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS746() public view returns (uint8) {
        return _decimals;
    }


    function TOTALSUPPLY18() public view override returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF19(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function TRANSFER188(address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER546(_MSGSENDER800(), recipient, amount);
        return true;
    }


    function ALLOWANCE990(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function APPROVE569(address spender, uint256 amount) public virtual override returns (bool) {
        _APPROVE756(_MSGSENDER800(), spender, amount);
        return true;
    }


    function TRANSFERFROM677(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER546(sender, recipient, amount);
        _APPROVE756(sender, _MSGSENDER800(), _allowances[sender][_MSGSENDER800()].SUB908(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function INCREASEALLOWANCE156(address spender, uint256 addedValue) public virtual returns (bool) {
        _APPROVE756(_MSGSENDER800(), spender, _allowances[_MSGSENDER800()][spender].ADD452(addedValue));
        return true;
    }


    function DECREASEALLOWANCE599(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _APPROVE756(_MSGSENDER800(), spender, _allowances[_MSGSENDER800()][spender].SUB908(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _TRANSFER546(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _BEFORETOKENTRANSFER598(sender, recipient, amount);

        _balances[sender] = _balances[sender].SUB908(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD452(amount);
        emit TRANSFER36(sender, recipient, amount);
    }


    function _MINT47(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _BEFORETOKENTRANSFER598(address(0), account, amount);

        _totalSupply = _totalSupply.ADD452(amount);
        _balances[account] = _balances[account].ADD452(amount);
        emit TRANSFER36(address(0), account, amount);
    }


    function _BURN695(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _BEFORETOKENTRANSFER598(account, address(0), amount);

        _balances[account] = _balances[account].SUB908(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB908(amount);
        emit TRANSFER36(account, address(0), amount);
    }


    function _APPROVE756(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL777(owner, spender, amount);
    }


    function _SETUPDECIMALS343(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _BEFORETOKENTRANSFER598(address from, address to, uint256 amount) internal virtual { }
}


contract ERAF is ERC20 {
    constructor ()
        ERC20('ERAF Finance', 'ERAF')
        public
    {
        _MINT47(0x5a77bD42971B3399d5f2eaE6505bb36EA6a359F3, 12000 * 10 ** uint(DECIMALS746()));
    }
}
