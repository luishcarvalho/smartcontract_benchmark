



pragma solidity ^0.6.12;

abstract contract Context {
    function _MSGSENDER157() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA592() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


interface IERC20 {

    function TOTALSUPPLY223() external view returns (uint256);


    function BALANCEOF306(address account) external view returns (uint256);


    function TRANSFER463(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE696(address owner, address spender) external view returns (uint256);


    function APPROVE561(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM21(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER851(address indexed from, address indexed to, uint256 value);


    event APPROVAL370(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

    function ADD799(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB732(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB732(a, b, "SafeMath: subtraction overflow");
    }


    function SUB732(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL950(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV680(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV680(a, b, "SafeMath: division by zero");
    }


    function DIV680(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD792(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD792(a, b, "SafeMath: modulo by zero");
    }


    function MOD792(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



library Address {

    function ISCONTRACT333(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function SENDVALUE497(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function FUNCTIONCALL661(address target, bytes memory data) internal returns (bytes memory) {
      return FUNCTIONCALL661(target, data, "Address: low-level call failed");
    }


    function FUNCTIONCALL661(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _FUNCTIONCALLWITHVALUE995(target, data, 0, errorMessage);
    }


    function FUNCTIONCALLWITHVALUE621(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return FUNCTIONCALLWITHVALUE621(target, data, value, "Address: low-level call with value failed");
    }


    function FUNCTIONCALLWITHVALUE621(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _FUNCTIONCALLWITHVALUE995(target, data, value, errorMessage);
    }

    function _FUNCTIONCALLWITHVALUE995(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(ISCONTRACT333(target), "Address: call to non-contract");


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


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER597(IERC20 token, address to, uint256 value) internal {
        _CALLOPTIONALRETURN182(token, abi.encodeWithSelector(token.TRANSFER463.selector, to, value));
    }

    function SAFETRANSFERFROM780(IERC20 token, address from, address to, uint256 value) internal {
        _CALLOPTIONALRETURN182(token, abi.encodeWithSelector(token.TRANSFERFROM21.selector, from, to, value));
    }


    function SAFEAPPROVE352(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.ALLOWANCE696(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _CALLOPTIONALRETURN182(token, abi.encodeWithSelector(token.APPROVE561.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE57(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE696(address(this), spender).ADD799(value);
        _CALLOPTIONALRETURN182(token, abi.encodeWithSelector(token.APPROVE561.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE5(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE696(address(this), spender).SUB732(value, "SafeERC20: decreased allowance below zero");
        _CALLOPTIONALRETURN182(token, abi.encodeWithSelector(token.APPROVE561.selector, spender, newAllowance));
    }


    function _CALLOPTIONALRETURN182(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).FUNCTIONCALL661(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}




contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED950(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        address msgSender = _MSGSENDER157();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED950(address(0), msgSender);
    }


    function OWNER835() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER465() {
        require(_owner == _MSGSENDER157(), "Ownable: caller is not the owner");
        _;
    }


    function RENOUNCEOWNERSHIP697() public virtual ONLYOWNER465 {
        emit OWNERSHIPTRANSFERRED950(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP738(address newOwner) public virtual ONLYOWNER465 {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED950(_owner, newOwner);
        _owner = newOwner;
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


    function NAME734() public view returns (string memory) {
        return _name;
    }


    function SYMBOL830() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS862() public view returns (uint8) {
        return _decimals;
    }


    function TOTALSUPPLY223() public view override returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF306(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function TRANSFER463(address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER846(_MSGSENDER157(), recipient, amount);
        return true;
    }


    function ALLOWANCE696(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function APPROVE561(address spender, uint256 amount) public virtual override returns (bool) {
        _APPROVE805(_MSGSENDER157(), spender, amount);
        return true;
    }


    function TRANSFERFROM21(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER846(sender, recipient, amount);
        _APPROVE805(sender, _MSGSENDER157(), _allowances[sender][_MSGSENDER157()].SUB732(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function INCREASEALLOWANCE200(address spender, uint256 addedValue) public virtual returns (bool) {
        _APPROVE805(_MSGSENDER157(), spender, _allowances[_MSGSENDER157()][spender].ADD799(addedValue));
        return true;
    }


    function DECREASEALLOWANCE585(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _APPROVE805(_MSGSENDER157(), spender, _allowances[_MSGSENDER157()][spender].SUB732(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _TRANSFER846(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _BEFORETOKENTRANSFER151(sender, recipient, amount);

        _balances[sender] = _balances[sender].SUB732(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD799(amount);
        emit TRANSFER851(sender, recipient, amount);
    }


    function _MINT127(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _BEFORETOKENTRANSFER151(address(0), account, amount);

        _totalSupply = _totalSupply.ADD799(amount);
        _balances[account] = _balances[account].ADD799(amount);
        emit TRANSFER851(address(0), account, amount);
    }


    function _BURN291(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _BEFORETOKENTRANSFER151(account, address(0), amount);

        _balances[account] = _balances[account].SUB732(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB732(amount);
        emit TRANSFER851(account, address(0), amount);
    }


    function _APPROVE805(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL370(owner, spender, amount);
    }


    function _SETUPDECIMALS256(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _BEFORETOKENTRANSFER151(address from, address to, uint256 amount) internal virtual { }
}

contract nGASToken is ERC20("pumpgasplatform.com", "nGAS"), Ownable {

    function MINT597(address _to, uint256 _amount) public ONLYOWNER465 {
        _MINT127(_to, _amount);
    }
    function TRANSFER463(address to, uint256 amount) public override returns (bool) {
        return super.TRANSFER463(to, _PARTIALBURN883(msg.sender, amount));
    }
    function TRANSFERFROM21(address from, address to, uint256 amount) public override returns (bool) {
        return super.TRANSFERFROM21(from, to, _PARTIALBURN883(from, amount));
    }
    function _PARTIALBURN883(address sender, uint256 amount) internal returns (uint256) {
        uint256 burnAmount = (amount.MUL950(30)).DIV680(1000);
        if (burnAmount > 0) {
            _BURN291(sender, burnAmount);
        }
        return amount.SUB732(burnAmount);
    }
}
