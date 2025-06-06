

pragma solidity ^0.5.16;

interface IERC20 {
    function TOTALSUPPLY171() external view returns (uint);
    function BALANCEOF784(address account) external view returns (uint);
    function TRANSFER754(address recipient, uint amount) external returns (bool);
    function ALLOWANCE384(address owner, address spender) external view returns (uint);
    function APPROVE522(address spender, uint amount) external returns (bool);
    function TRANSFERFROM156(address sender, address recipient, uint amount) external returns (bool);
    event TRANSFER68(address indexed from, address indexed to, uint value);
    event APPROVAL81(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal { }


    function _MSGSENDER324() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    function TOTALSUPPLY171() public view returns (uint) {
        return _totalSupply;
    }
    function BALANCEOF784(address account) public view returns (uint) {
        return _balances[account];
    }
    function TRANSFER754(address recipient, uint amount) public returns (bool) {
        _TRANSFER587(_MSGSENDER324(), recipient, amount);
        return true;
    }
    function ALLOWANCE384(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function APPROVE522(address spender, uint amount) public returns (bool) {
        _APPROVE274(_MSGSENDER324(), spender, amount);
        return true;
    }
    function TRANSFERFROM156(address sender, address recipient, uint amount) public returns (bool) {
        _TRANSFER587(sender, recipient, amount);
        _APPROVE274(sender, _MSGSENDER324(), _allowances[sender][_MSGSENDER324()].SUB131(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function INCREASEALLOWANCE835(address spender, uint addedValue) public returns (bool) {
        _APPROVE274(_MSGSENDER324(), spender, _allowances[_MSGSENDER324()][spender].ADD951(addedValue));
        return true;
    }
    function DECREASEALLOWANCE568(address spender, uint subtractedValue) public returns (bool) {
        _APPROVE274(_MSGSENDER324(), spender, _allowances[_MSGSENDER324()][spender].SUB131(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _TRANSFER587(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].SUB131(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD951(amount);
        emit TRANSFER68(sender, recipient, amount);
    }
    function _MINT189(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.ADD951(amount);
        _balances[account] = _balances[account].ADD951(amount);
        emit TRANSFER68(address(0), account, amount);
    }
    function _BURN372(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].SUB131(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB131(amount);
        emit TRANSFER68(account, address(0), amount);
    }
    function _APPROVE274(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL81(owner, spender, amount);
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
    function NAME128() public view returns (string memory) {
        return _name;
    }
    function SYMBOL200() public view returns (string memory) {
        return _symbol;
    }
    function DECIMALS712() public view returns (uint8) {
        return _decimals;
    }
}

library SafeMath {
    function ADD951(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function SUB131(uint a, uint b) internal pure returns (uint) {
        return SUB131(a, b, "SafeMath: subtraction overflow");
    }
    function SUB131(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function MUL231(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function DIV400(uint a, uint b) internal pure returns (uint) {
        return DIV400(a, b, "SafeMath: division by zero");
    }
    function DIV400(uint a, uint b, string memory errorMessage) internal pure returns (uint) {

        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function ISCONTRACT647(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function SAFETRANSFER747(IERC20 token, address to, uint value) internal {
        CALLOPTIONALRETURN719(token, abi.encodeWithSelector(token.TRANSFER754.selector, to, value));
    }

    function SAFETRANSFERFROM172(IERC20 token, address from, address to, uint value) internal {
        CALLOPTIONALRETURN719(token, abi.encodeWithSelector(token.TRANSFERFROM156.selector, from, to, value));
    }

    function SAFEAPPROVE759(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.ALLOWANCE384(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN719(token, abi.encodeWithSelector(token.APPROVE522.selector, spender, value));
    }
    function CALLOPTIONALRETURN719(IERC20 token, bytes memory data) private {
        require(address(token).ISCONTRACT647(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract YFiG is ERC20, ERC20Detailed {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint;


  address public governance;
  mapping (address => bool) public minters;

  constructor () public ERC20Detailed("YFiGlobal.Finance", "YFiG", 18) {
      governance = msg.sender;
  }

  function MINT296(address account, uint amount) public {
      require(minters[msg.sender], "!minter");
      _MINT189(account, amount);
  }

  function SETGOVERNANCE402(address _governance) public {
      require(msg.sender == governance, "!governance");
      governance = _governance;
  }

  function ADDMINTER585(address _minter) public {
      require(msg.sender == governance, "!governance");
      minters[_minter] = true;
  }

  function REMOVEMINTER114(address _minter) public {
      require(msg.sender == governance, "!governance");
      minters[_minter] = false;
  }
}
