



pragma solidity ^0.7.1;


library SafeMath {

    function ADD792(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB330(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB330(a, b, "SafeMath: subtraction overflow");
    }


    function SUB330(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL940(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV558(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV558(a, b, "SafeMath: division by zero");
    }


    function DIV558(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD235(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD235(a, b, "SafeMath: modulo by zero");
    }


    function MOD235(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



library Address {

    function ISCONTRACT625(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }


    function SENDVALUE454(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function FUNCTIONCALL480(address target, bytes memory data) internal returns (bytes memory) {
      return FUNCTIONCALL480(target, data, "Address: low-level call failed");
    }


    function FUNCTIONCALL480(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _FUNCTIONCALLWITHVALUE85(target, data, 0, errorMessage);
    }


    function FUNCTIONCALLWITHVALUE305(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return FUNCTIONCALLWITHVALUE305(target, data, value, "Address: low-level call with value failed");
    }


    function FUNCTIONCALLWITHVALUE305(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _FUNCTIONCALLWITHVALUE85(target, data, value, errorMessage);
    }

    function _FUNCTIONCALLWITHVALUE85(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(ISCONTRACT625(target), "Address: call to non-contract");


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



interface IERC20 {

    function TOTALSUPPLY794() external view returns (uint256);


    function BALANCEOF985(address account) external view returns (uint256);


    function TRANSFER289(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE73(address owner, address spender) external view returns (uint256);


    function APPROVE424(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM238(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER11(address indexed from, address indexed to, uint256 value);


    event APPROVAL313(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _MSGSENDER817() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA892() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED181(address indexed previousOwner, address indexed newOwner);


    constructor () {
        address msgSender = _MSGSENDER817();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED181(address(0), msgSender);
    }


    function OWNER943() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER755() {
        require(_owner == _MSGSENDER817(), "Ownable: caller is not the owner");
        _;
    }


    function TRANSFEROWNERSHIP364(address newOwner) public virtual ONLYOWNER755 {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED181(_owner, newOwner);
        _owner = newOwner;
    }
}


contract YearnSquaredFinance is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor () {
        _name = "YearnSquared.Finance";
        _symbol = "Y2F";
        _decimals = 18;
        uint256 _maxSupply = 30000;
        _MINTONCE54(msg.sender, _maxSupply.MUL940(10 ** _decimals));
    }

    receive() external payable {
        revert();
    }


    function NAME162() public view returns (string memory) {
        return _name;
    }


    function SYMBOL732() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS776() public view returns (uint8) {
        return _decimals;
    }


    function TOTALSUPPLY794() public view override returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF985(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function TRANSFER289(address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER282(_MSGSENDER817(), recipient, amount);
        return true;
    }


    function ALLOWANCE73(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function APPROVE424(address spender, uint256 amount) public virtual override returns (bool) {
        _APPROVE612(_MSGSENDER817(), spender, amount);
        return true;
    }


    function TRANSFERFROM238(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER282(sender, recipient, amount);
        _APPROVE612(sender, _MSGSENDER817(), _allowances[sender][_MSGSENDER817()].SUB330(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function INCREASEALLOWANCE269(address spender, uint256 addedValue) public virtual returns (bool) {
        _APPROVE612(_MSGSENDER817(), spender, _allowances[_MSGSENDER817()][spender].ADD792(addedValue));
        return true;
    }


    function DECREASEALLOWANCE793(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _APPROVE612(_MSGSENDER817(), spender, _allowances[_MSGSENDER817()][spender].SUB330(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _TRANSFER282(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _BEFORETOKENTRANSFER594(sender, recipient, amount);

        _balances[sender] = _balances[sender].SUB330(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD792(amount);
        emit TRANSFER11(sender, recipient, amount);
    }


    function _MINTONCE54(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _BEFORETOKENTRANSFER594(address(0), account, amount);

        _totalSupply = _totalSupply.ADD792(amount);
        _balances[account] = _balances[account].ADD792(amount);
        emit TRANSFER11(address(0), account, amount);
    }


    function _BURN126(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _BEFORETOKENTRANSFER594(account, address(0), amount);

        _balances[account] = _balances[account].SUB330(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB330(amount);
        emit TRANSFER11(account, address(0), amount);
    }


    function _APPROVE612(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL313(owner, spender, amount);
    }


    function _SETUPDECIMALS44(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _BEFORETOKENTRANSFER594(address from, address to, uint256 amount) internal virtual { }
}
