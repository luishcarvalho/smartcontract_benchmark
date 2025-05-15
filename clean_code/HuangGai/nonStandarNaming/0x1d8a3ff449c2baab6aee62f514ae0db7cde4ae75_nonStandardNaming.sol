

pragma solidity ^0.5.15;

interface IERC20 {
    function TOTALSUPPLY265() external view returns (uint256);
    function BALANCEOF676(address account) external view returns (uint256);
    function TRANSFER585(address recipient, uint256 amount) external returns (bool);
    function ALLOWANCE478(address owner, address spender) external view returns (uint256);
    function APPROVE401(address spender, uint256 amount) external returns (bool);
    function TRANSFERFROM799(address sender, address recipient, uint256 amount) external returns (bool);
    event TRANSFER297(address indexed from, address indexed to, uint256 value);
    event APPROVAL288(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    constructor () internal { }


    function _MSGSENDER981() internal view returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA870() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED51(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _MSGSENDER981();
        emit OWNERSHIPTRANSFERRED51(address(0), _owner);
    }

    function OWNER52() public view returns (address) {
        return _owner;
    }

    modifier ONLYOWNER947() {
        require(ISOWNER855(), "Ownable: caller is not the owner");
        _;
    }

    function ISOWNER855() public view returns (bool) {
        return _MSGSENDER981() == _owner;
    }

    function RENOUNCEOWNERSHIP936() public ONLYOWNER947 {
        emit OWNERSHIPTRANSFERRED51(_owner, address(0));
        _owner = address(0);
    }

    function TRANSFEROWNERSHIP177(address newOwner) public ONLYOWNER947 {
        _TRANSFEROWNERSHIP636(newOwner);
    }

    function _TRANSFEROWNERSHIP636(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED51(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function TOTALSUPPLY265() public view returns (uint256) {
        return _totalSupply;
    }

    function BALANCEOF676(address account) public view returns (uint256) {
        return _balances[account];
    }

    function TRANSFER585(address recipient, uint256 amount) public returns (bool) {
        _TRANSFER399(_MSGSENDER981(), recipient, amount);
        return true;
    }

    function ALLOWANCE478(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function APPROVE401(address spender, uint256 amount) public returns (bool) {
        _APPROVE768(_MSGSENDER981(), spender, amount);
        return true;
    }

    function TRANSFERFROM799(address sender, address recipient, uint256 amount) public returns (bool) {
        _TRANSFER399(sender, recipient, amount);
        _APPROVE768(sender, _MSGSENDER981(), _allowances[sender][_MSGSENDER981()].SUB171(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function INCREASEALLOWANCE254(address spender, uint256 addedValue) public returns (bool) {
        _APPROVE768(_MSGSENDER981(), spender, _allowances[_MSGSENDER981()][spender].ADD125(addedValue));
        return true;
    }

    function DECREASEALLOWANCE775(address spender, uint256 subtractedValue) public returns (bool) {
        _APPROVE768(_MSGSENDER981(), spender, _allowances[_MSGSENDER981()][spender].SUB171(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _TRANSFER399(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].SUB171(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD125(amount);
        emit TRANSFER297(sender, recipient, amount);
    }

    function _MINT552(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.ADD125(amount);
        _balances[account] = _balances[account].ADD125(amount);
        emit TRANSFER297(address(0), account, amount);
    }

    function _BURN908(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].SUB171(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB171(amount);
        emit TRANSFER297(account, address(0), amount);
    }

    function _APPROVE768(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL288(owner, spender, amount);
    }

    function _BURNFROM359(address account, uint256 amount) internal {
        _BURN908(account, amount);
        _APPROVE768(account, _MSGSENDER981(), _allowances[account][_MSGSENDER981()].SUB171(amount, "ERC20: burn amount exceeds allowance"));
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

    function NAME677() public view returns (string memory) {
        return _name;
    }

    function SYMBOL955() public view returns (string memory) {
        return _symbol;
    }

    function DECIMALS596() public view returns (uint8) {
        return _decimals;
    }
}

library SafeMath {
    function ADD125(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function SUB171(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB171(a, b, "SafeMath: subtraction overflow");
    }

    function SUB171(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function MUL207(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function DIV619(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV619(a, b, "SafeMath: division by zero");
    }

    function DIV619(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function MOD550(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD550(a, b, "SafeMath: modulo by zero");
    }

    function MOD550(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function ISCONTRACT651(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function TOPAYABLE339(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function SENDVALUE156(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER644(IERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN428(token, abi.encodeWithSelector(token.TRANSFER585.selector, to, value));
    }

    function SAFETRANSFERFROM18(IERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN428(token, abi.encodeWithSelector(token.TRANSFERFROM799.selector, from, to, value));
    }

    function SAFEAPPROVE229(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.ALLOWANCE478(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN428(token, abi.encodeWithSelector(token.APPROVE401.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE497(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE478(address(this), spender).ADD125(value);
        CALLOPTIONALRETURN428(token, abi.encodeWithSelector(token.APPROVE401.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE975(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE478(address(this), spender).SUB171(value, "SafeERC20: decreased allowance below zero");
        CALLOPTIONALRETURN428(token, abi.encodeWithSelector(token.APPROVE401.selector, spender, newAllowance));
    }

    function CALLOPTIONALRETURN428(IERC20 token, bytes memory data) private {
        require(address(token).ISCONTRACT651(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface Controller {
    function WITHDRAW158(address, uint) external;
    function BALANCEOF676(address) external view returns (uint);
    function EARN532(address, uint) external;
    function REWARDS630() external view returns (address);
}



contract Vault  {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  IERC20 public token;
  IERC20 public YFToken;

  uint public min = 9500;
  uint public constant max986 = 10000;

  uint public earnLowerlimit;

  address public governance;
  address public controller;

  struct Player {
        uint256 stake;
        uint256 payout;
        uint256 total_out;
  }
  mapping(address => Player) public player_;

  struct Global {
        uint256 total_stake;
        uint256 total_out;
        uint256 earnings_per_share;
  }
  mapping(uint256 => Global) public global_;
  mapping (address => uint256) public deposittime;
  uint256 constant internal magnitude720 = 10**40;

  address constant public yf82 = address(0x96F9632b25f874769969ff91219fCCb6ceDf26D2);

  string public getName;

  constructor (address _token, uint256 _earnLowerlimit) public {
      token = IERC20(_token);
      getName = string(abi.encodePacked("yf:Vault:", ERC20Detailed(_token).NAME677()));

      earnLowerlimit = _earnLowerlimit*1e18;
      YFToken = IERC20(yf82);
      governance = tx.origin;
      controller = 0xcC8d36211374a08fC61d74ed2E48e22b922C9D7C;
  }

  function BALANCE265() public view returns (uint) {
      return token.BALANCEOF676(address(this))
             .ADD125(Controller(controller).BALANCEOF676(address(token)));
  }

  function SETMIN245(uint _min) external {
      require(msg.sender == governance, "!governance");
      min = _min;
  }


  function SETGOVERNANCE992(address _governance) public {
      require(msg.sender == governance, "!governance");
      governance = _governance;
  }


  function SETTOKEN102(address _token) public {
      require(msg.sender == governance, "!governance");
      token = IERC20(_token);
  }


  function SETCONTROLLER604(address _controller) public {
      require(msg.sender == governance, "!governance");
      controller = _controller;
  }

  function SETEARNLOWERLIMIT476(uint256 _earnLowerlimit) public{
      require(msg.sender == governance, "!governance");
      earnLowerlimit = _earnLowerlimit;
  }





  function AVAILABLE23() public view returns (uint) {
      return token.BALANCEOF676(address(this)).MUL207(min).DIV619(max986);
  }


  function EARN532() public {
      uint _bal = AVAILABLE23();
      token.SAFETRANSFER644(controller, _bal);
      Controller(controller).EARN532(address(token), _bal);
  }


  function DEPOSIT245(uint amount) external {

      token.SAFETRANSFERFROM18(msg.sender, address(this), amount);

      player_[msg.sender].stake = player_[msg.sender].stake.ADD125(amount);

      if (global_[0].earnings_per_share != 0) {
          player_[msg.sender].payout = player_[msg.sender].payout.ADD125(
              global_[0].earnings_per_share.MUL207(amount).SUB171(1).DIV619(magnitude720).ADD125(1)
          );
      }

      global_[0].total_stake = global_[0].total_stake.ADD125(amount);

      if (token.BALANCEOF676(address(this)) > earnLowerlimit){
          EARN532();
      }

      deposittime[msg.sender] = now;
  }



  function WITHDRAW158(uint amount) external {
      CLAIM365();
      require(amount <= player_[msg.sender].stake, "!balance");
      uint r = amount;


      uint b = token.BALANCEOF676(address(this));
      if (b < r) {
          uint _withdraw = r.SUB171(b);
          Controller(controller).WITHDRAW158(address(token), _withdraw);
          uint _after = token.BALANCEOF676(address(this));
          uint _diff = _after.SUB171(b);
          if (_diff < _withdraw) {
              r = b.ADD125(_diff);
          }
      }

      player_[msg.sender].payout = player_[msg.sender].payout.SUB171(
            global_[0].earnings_per_share.MUL207(amount).DIV619(magnitude720)
      );

      player_[msg.sender].stake = player_[msg.sender].stake.SUB171(amount);
      global_[0].total_stake = global_[0].total_stake.SUB171(amount);

      token.SAFETRANSFER644(msg.sender, r);
  }


  function MAKE_PROFIT788(uint256 amount) public {
      require(amount > 0, "not 0");
      YFToken.SAFETRANSFERFROM18(msg.sender, address(this), amount);
      global_[0].earnings_per_share = global_[0].earnings_per_share.ADD125(
          amount.MUL207(magnitude720).DIV619(global_[0].total_stake)
      );
      global_[0].total_out = global_[0].total_out.ADD125(amount);
  }


  function CAL_OUT246(address user) public view returns (uint256) {
      uint256 _cal = global_[0].earnings_per_share.MUL207(player_[user].stake).DIV619(magnitude720);
      if (_cal < player_[user].payout) {
          return 0;
      } else {
          return _cal.SUB171(player_[user].payout);
      }
  }


  function CAL_OUT_PENDING918(uint256 _pendingBalance,address user) public view returns (uint256) {
      uint256 _earnings_per_share = global_[0].earnings_per_share.ADD125(
          _pendingBalance.MUL207(magnitude720).DIV619(global_[0].total_stake)
      );
      uint256 _cal = _earnings_per_share.MUL207(player_[user].stake).DIV619(magnitude720);
      _cal = _cal.SUB171(CAL_OUT246(user));
      if (_cal < player_[user].payout) {
          return 0;
      } else {
          return _cal.SUB171(player_[user].payout);
      }
  }


  function CLAIM365() public {
      uint256 out = CAL_OUT246(msg.sender);
      player_[msg.sender].payout = global_[0].earnings_per_share.MUL207(player_[msg.sender].stake).DIV619(magnitude720);
      player_[msg.sender].total_out = player_[msg.sender].total_out.ADD125(out);

      if (out > 0) {
          uint256 _depositTime = now - deposittime[msg.sender];
          if (_depositTime < 1 days){
              uint256 actually_out = _depositTime.MUL207(out).MUL207(1e18).DIV619(1 days).DIV619(1e18);
              uint256 to_team = out.SUB171(actually_out);
              YFToken.SAFETRANSFER644(Controller(controller).REWARDS630(), to_team);
              out = actually_out;
          }
          YFToken.SAFETRANSFER644(msg.sender, out);
      }
  }
}
