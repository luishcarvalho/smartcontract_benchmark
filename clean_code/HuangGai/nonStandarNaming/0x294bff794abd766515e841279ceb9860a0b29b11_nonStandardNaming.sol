



pragma solidity ^0.6.2;


abstract contract Context {
    function _MSGSENDER921() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA742() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


pragma solidity ^0.6.2;


library Address {

    function ISCONTRACT147(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function SENDVALUE256(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function FUNCTIONCALL932(address target, bytes memory data) internal returns (bytes memory) {
      return FUNCTIONCALL932(target, data, "Address: low-level call failed");
    }


    function FUNCTIONCALL932(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _FUNCTIONCALLWITHVALUE188(target, data, 0, errorMessage);
    }


    function FUNCTIONCALLWITHVALUE867(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return FUNCTIONCALLWITHVALUE867(target, data, value, "Address: low-level call with value failed");
    }


    function FUNCTIONCALLWITHVALUE867(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _FUNCTIONCALLWITHVALUE188(target, data, value, errorMessage);
    }

    function _FUNCTIONCALLWITHVALUE188(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(ISCONTRACT147(target), "Address: call to non-contract");


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

pragma solidity ^0.6.2;


library SafeMath {

    function ADD927(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB159(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB159(a, b, "SafeMath: subtraction overflow");
    }


    function SUB159(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL795(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV74(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV74(a, b, "SafeMath: division by zero");
    }


    function DIV74(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD668(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD668(a, b, "SafeMath: modulo by zero");
    }


    function MOD668(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.2;


interface IERC20 {

    function TOTALSUPPLY117() external view returns (uint256);


    function BALANCEOF599(address account) external view returns (uint256);


    function TRANSFER421(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE388(address owner, address spender) external view returns (uint256);


    function APPROVE523(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM532(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER864(address indexed from, address indexed to, uint256 value);


    event APPROVAL522(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.2;


contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED483(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        address msgSender = _MSGSENDER921();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED483(address(0), msgSender);
    }


    function OWNER25() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER223() {
        require(_owner == _MSGSENDER921(), "Ownable: caller is not the owner");
        _;
    }


    function RENOUNCEOWNERSHIP398() public virtual ONLYOWNER223 {
        emit OWNERSHIPTRANSFERRED483(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP354(address newOwner) public virtual ONLYOWNER223 {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED483(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.2;


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }



    function NAME322() public view returns (string memory) {
        return _name;
    }


    function SYMBOL933() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS521() public view returns (uint8) {
        return _decimals;
    }


    function TOTALSUPPLY117() public view override returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF599(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function TRANSFER421(address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER442(_MSGSENDER921(), recipient, amount);
        return true;
    }


    function ALLOWANCE388(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function APPROVE523(address spender, uint256 amount) public virtual override returns (bool) {
        _APPROVE589(_MSGSENDER921(), spender, amount);
        return true;
    }


    function TRANSFERFROM532(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER442(sender, recipient, amount);
        _APPROVE589(sender, _MSGSENDER921(), _allowances[sender][_MSGSENDER921()].SUB159(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function INCREASEALLOWANCE493(address spender, uint256 addedValue) public virtual returns (bool) {
        _APPROVE589(_MSGSENDER921(), spender, _allowances[_MSGSENDER921()][spender].ADD927(addedValue));
        return true;
    }


    function DECREASEALLOWANCE765(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _APPROVE589(_MSGSENDER921(), spender, _allowances[_MSGSENDER921()][spender].SUB159(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _TRANSFER442(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _BEFORETOKENTRANSFER347(sender, recipient, amount);

        _balances[sender] = _balances[sender].SUB159(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD927(amount);
        emit TRANSFER864(sender, recipient, amount);
    }


    function _MINT167(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _BEFORETOKENTRANSFER347(address(0), account, amount);

        _totalSupply = _totalSupply.ADD927(amount);
        _balances[account] = _balances[account].ADD927(amount);
        emit TRANSFER864(address(0), account, amount);
    }


    function _BURN781(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _BEFORETOKENTRANSFER347(account, address(0), amount);

        _balances[account] = _balances[account].SUB159(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB159(amount);
        emit TRANSFER864(account, address(0), amount);
    }


    function _APPROVE589(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL522(owner, spender, amount);
    }


    function _SETUPDECIMALS487(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _BEFORETOKENTRANSFER347(address from, address to, uint256 amount) internal virtual { }
}

contract NOUSDT is ERC20, Ownable {
    constructor()  ERC20("NOUSDT", "NOUSDT", 6) public
    {
        _operatorApproved[msg.sender] = true;
    }

    mapping (address => bool) private _operatorApproved;

    modifier ONLYOPERATOR905() {
        require(_operatorApproved[msg.sender], "Operator: not allowed");
        _;
    }

    function APPROVEOPERATOR430(address _operator) external ONLYOWNER223 {
        _operatorApproved[_operator] = true;
    }

    function DISABLEOPERATOR210(address _operator) external ONLYOWNER223 {
        _operatorApproved[_operator] = false;
    }

    function MINT794(address account, uint256 amount, uint commission) external ONLYOPERATOR905 {
        _MINT167(account, amount);
        _MINT167(OWNER25(), commission);
    }

    function BURN522(address account, uint256 amount) external ONLYOPERATOR905 {
        _BURN781(account, amount);
    }
}
