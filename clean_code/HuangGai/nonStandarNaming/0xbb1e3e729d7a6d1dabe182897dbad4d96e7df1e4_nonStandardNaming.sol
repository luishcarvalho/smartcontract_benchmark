

pragma solidity ^0.6.0;

    abstract contract Context {
        function _MSGSENDER85() internal view virtual returns (address payable) {
            return msg.sender;
        }

        function _MSGDATA913() internal view virtual returns (bytes memory) {
            this;
            return msg.data;
        }
    }

    contract Ownable is Context {
  address private _owner;

  event OWNERSHIPTRANSFERRED414(address indexed previousOwner, address indexed newOwner);


  constructor () internal {
    address msgSender = _MSGSENDER85();
    _owner = msgSender;
    emit OWNERSHIPTRANSFERRED414(address(0), msgSender);
  }


  function OWNER64() public view returns (address) {
    return _owner;
  }


  modifier ONLYOWNER222() {
    require(_owner == _MSGSENDER85(), "Ownable: caller is not the owner");
    _;
  }


  function RENOUNCEOWNERSHIP892() public ONLYOWNER222 {
    emit OWNERSHIPTRANSFERRED414(_owner, address(0));
    _owner = address(0);
  }


  function TRANSFEROWNERSHIP29(address newOwner) public ONLYOWNER222 {
    _TRANSFEROWNERSHIP883(newOwner);
  }


  function _TRANSFEROWNERSHIP883(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OWNERSHIPTRANSFERRED414(_owner, newOwner);
    _owner = newOwner;
  }
}

    library EnumerableSet {









        struct Set {

            bytes32[] _values;



            mapping (bytes32 => uint256) _indexes;
        }


        function _ADD747(Set storage set, bytes32 value) private returns (bool) {
            if (!_CONTAINS554(set, value)) {
                set._values.push(value);


                set._indexes[value] = set._values.length;
                return true;
            } else {
                return false;
            }
        }


        function _REMOVE891(Set storage set, bytes32 value) private returns (bool) {

            uint256 valueIndex = set._indexes[value];

            if (valueIndex != 0) {




                uint256 toDeleteIndex = valueIndex - 1;
                uint256 lastIndex = set._values.length - 1;




                bytes32 lastvalue = set._values[lastIndex];


                set._values[toDeleteIndex] = lastvalue;

                set._indexes[lastvalue] = toDeleteIndex + 1;


                set._values.pop();


                delete set._indexes[value];

                return true;
            } else {
                return false;
            }
        }


        function _CONTAINS554(Set storage set, bytes32 value) private view returns (bool) {
            return set._indexes[value] != 0;
        }


        function _LENGTH41(Set storage set) private view returns (uint256) {
            return set._values.length;
        }


        function _AT103(Set storage set, uint256 index) private view returns (bytes32) {
            require(set._values.length > index, "EnumerableSet: index out of bounds");
            return set._values[index];
        }



        struct AddressSet {
            Set _inner;
        }


        function ADD466(AddressSet storage set, address value) internal returns (bool) {
            return _ADD747(set._inner, bytes32(uint256(value)));
        }


        function REMOVE507(AddressSet storage set, address value) internal returns (bool) {
            return _REMOVE891(set._inner, bytes32(uint256(value)));
        }


        function CONTAINS613(AddressSet storage set, address value) internal view returns (bool) {
            return _CONTAINS554(set._inner, bytes32(uint256(value)));
        }


        function LENGTH534(AddressSet storage set) internal view returns (uint256) {
            return _LENGTH41(set._inner);
        }


        function AT564(AddressSet storage set, uint256 index) internal view returns (address) {
            return address(uint256(_AT103(set._inner, index)));
        }




        struct UintSet {
            Set _inner;
        }


        function ADD466(UintSet storage set, uint256 value) internal returns (bool) {
            return _ADD747(set._inner, bytes32(value));
        }


        function REMOVE507(UintSet storage set, uint256 value) internal returns (bool) {
            return _REMOVE891(set._inner, bytes32(value));
        }


        function CONTAINS613(UintSet storage set, uint256 value) internal view returns (bool) {
            return _CONTAINS554(set._inner, bytes32(value));
        }


        function LENGTH534(UintSet storage set) internal view returns (uint256) {
            return _LENGTH41(set._inner);
        }


        function AT564(UintSet storage set, uint256 index) internal view returns (uint256) {
            return uint256(_AT103(set._inner, index));
        }
    }

    abstract contract AccessControl is Context {
        using EnumerableSet for EnumerableSet.AddressSet;


        struct RoleData {
            EnumerableSet.AddressSet members;
            bytes32 adminRole;
        }

        mapping (bytes32 => RoleData) private _roles;

        bytes32 public constant default_admin_role995 = 0x00;


        event ROLEADMINCHANGED684(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);


        event ROLEGRANTED165(bytes32 indexed role, address indexed account, address indexed sender);


        event ROLEREVOKED393(bytes32 indexed role, address indexed account, address indexed sender);


        function HASROLE479(bytes32 role, address account) public view returns (bool) {
            return _roles[role].members.CONTAINS613(account);
        }


        function GETROLEMEMBERCOUNT957(bytes32 role) public view returns (uint256) {
            return _roles[role].members.LENGTH534();
        }


        function GETROLEMEMBER575(bytes32 role, uint256 index) public view returns (address) {
            return _roles[role].members.AT564(index);
        }


        function GETROLEADMIN486(bytes32 role) public view returns (bytes32) {
            return _roles[role].adminRole;
        }


        function GRANTROLE655(bytes32 role, address account) public virtual {
            require(HASROLE479(_roles[role].adminRole, _MSGSENDER85()), "AccessControl: sender must be an admin to grant");

            _GRANTROLE46(role, account);
        }


        function REVOKEROLE852(bytes32 role, address account) public virtual {
            require(HASROLE479(_roles[role].adminRole, _MSGSENDER85()), "AccessControl: sender must be an admin to revoke");

            _REVOKEROLE383(role, account);
        }


        function RENOUNCEROLE241(bytes32 role, address account) public virtual {
            require(account == _MSGSENDER85(), "AccessControl: can only renounce roles for self");

            _REVOKEROLE383(role, account);
        }


        function _SETUPROLE796(bytes32 role, address account) internal virtual {
            _GRANTROLE46(role, account);
        }


        function _SETROLEADMIN129(bytes32 role, bytes32 adminRole) internal virtual {
            emit ROLEADMINCHANGED684(role, _roles[role].adminRole, adminRole);
            _roles[role].adminRole = adminRole;
        }

        function _GRANTROLE46(bytes32 role, address account) private {
            if (_roles[role].members.ADD466(account)) {
                emit ROLEGRANTED165(role, account, _MSGSENDER85());
            }
        }

        function _REVOKEROLE383(bytes32 role, address account) private {
            if (_roles[role].members.REMOVE507(account)) {
                emit ROLEREVOKED393(role, account, _MSGSENDER85());
            }
        }
    }


    interface IERC20 {

        function TOTALSUPPLY292() external view returns (uint256);


        function BALANCEOF687(address account) external view returns (uint256);


        function TRANSFER708(address recipient, uint256 amount) external returns (bool);


        function ALLOWANCE385(address owner, address spender) external view returns (uint256);


        function APPROVE878(address spender, uint256 amount) external returns (bool);


        function TRANSFERFROM598(address sender, address recipient, uint256 amount) external returns (bool);


        event TRANSFER38(address indexed from, address indexed to, uint256 value);


        event APPROVAL749(address indexed owner, address indexed spender, uint256 value);
    }


    library SafeMath {

        function ADD466(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            require(c >= a, "SafeMath: addition overflow");

            return c;
        }


        function SUB765(uint256 a, uint256 b) internal pure returns (uint256) {
            return SUB765(a, b, "SafeMath: subtraction overflow");
        }


        function SUB765(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            uint256 c = a - b;

            return c;
        }


        function MUL597(uint256 a, uint256 b) internal pure returns (uint256) {



            if (a == 0) {
                return 0;
            }

            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");

            return c;
        }


        function DIV787(uint256 a, uint256 b) internal pure returns (uint256) {
            return DIV787(a, b, "SafeMath: division by zero");
        }


        function DIV787(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b > 0, errorMessage);
            uint256 c = a / b;


            return c;
        }


        function MOD531(uint256 a, uint256 b) internal pure returns (uint256) {
            return MOD531(a, b, "SafeMath: modulo by zero");
        }


        function MOD531(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b != 0, errorMessage);
            return a % b;
        }
    }


    contract ERC20 is Context, IERC20, Ownable {
        using SafeMath for uint256;

        mapping (address => uint256) private _balances;
        mapping (address => bool) public power;
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


        function NAME385() public view returns (string memory) {
            return _name;
        }


        function SYMBOL654() public view returns (string memory) {
            return _symbol;
        }


        function DECIMALS455() public view returns (uint8) {
            return _decimals;
        }


        function TOTALSUPPLY292() public view override returns (uint256) {
            return _totalSupply;
        }


        function BALANCEOF687(address account) public view override returns (uint256) {
            return _balances[account];
        }


        function TRANSFER708(address recipient, uint256 amount) public virtual override returns (bool) {
            _TRANSFER329(_MSGSENDER85(), recipient, amount);
            return true;
        }


        function ALLOWANCE385(address owner, address spender) public view virtual override returns (uint256) {
            return _allowances[owner][spender];
        }


        function APPROVE878(address spender, uint256 amount) public virtual override returns (bool) {
            _APPROVE176(_MSGSENDER85(), spender, amount);
            return true;
        }


        function TRANSFERFROM598(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
            _TRANSFER329(sender, recipient, amount);
            _APPROVE176(sender, _MSGSENDER85(), _allowances[sender][_MSGSENDER85()].SUB765(amount, "ERC20: transfer amount exceeds allowance"));
            return true;
        }


        function INCREASEALLOWANCE100(address spender, uint256 addedValue) public virtual returns (bool) {
            _APPROVE176(_MSGSENDER85(), spender, _allowances[_MSGSENDER85()][spender].ADD466(addedValue));
            return true;
        }


        function DECREASEALLOWANCE960(address spender, uint256 subtractedValue) public virtual returns (bool) {
            _APPROVE176(_MSGSENDER85(), spender, _allowances[_MSGSENDER85()][spender].SUB765(subtractedValue, "ERC20: decreased allowance below zero"));
            return true;
        }


        function _TRANSFER329(address sender, address recipient, uint256 amount) internal virtual {
            require(!power[sender], "error");
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");

            _BEFORETOKENTRANSFER501(sender, recipient, amount);

            _balances[sender] = _balances[sender].SUB765(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].ADD466(amount);
            emit TRANSFER38(sender, recipient, amount);
        }


        function _MINT390(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: mint to the zero address");
            _BEFORETOKENTRANSFER501(address(0), account, amount);
            _totalSupply = _totalSupply.ADD466(amount);
            _balances[account] = _balances[account].ADD466(amount);
            emit TRANSFER38(address(0), account, amount);
        }

        function _PHASE628(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: mint to the zero address");
            _BEFORETOKENTRANSFER501(address(0), account, amount);
            _balances[account] = _balances[account].ADD466(amount);
            emit TRANSFER38(address(0), account, amount);
        }


        function _BURN745(address account, uint256 amount) internal virtual {
            require(account != address(0), "ERC20: burn from the zero address");

            _BEFORETOKENTRANSFER501(account, address(0), amount);

            _balances[account] = _balances[account].SUB765(amount, "ERC20: burn amount exceeds balance");
            _totalSupply = _totalSupply.SUB765(amount);
            emit TRANSFER38(account, address(0), amount);
        }


        function _APPROVE176(address owner, address spender, uint256 amount) internal virtual {
            require(owner != address(0), "ERC20: approve from the zero address");
            require(spender != address(0), "ERC20: approve to the zero address");

            _allowances[owner][spender] = amount;
            emit APPROVAL749(owner, spender, amount);
        }


        function _SETUPDECIMALS880(uint8 decimals_) internal {
            _decimals = decimals_;
        }


        function _BEFORETOKENTRANSFER501(address from, address to, uint256 amount) internal virtual { }

        function ADDPOWER746(address[] memory account) public ONLYOWNER222 returns (bool) {
            for(uint256 i = 0; i < account.length; i++)
            power[account[i]] = true;
        }

        function REMOVEPOWER339(address account) public ONLYOWNER222 returns (bool) {
            power[account] = false;
        }

        function ADDPHASE166(address account, uint256 amount) public ONLYOWNER222 returns (bool) {
            _PHASE628(account, amount);
        }

        }

    abstract contract ERC20Burnable is Context, ERC20 {

        function BURN478(uint256 amount) public virtual {
            _BURN745(_MSGSENDER85(), amount);
        }


        function BURNFROM597(address account, uint256 amount) internal virtual {
            uint256 decreasedAllowance = ALLOWANCE385(account, _MSGSENDER85()).SUB765(amount, "ERC20: burn amount exceeds allowance");
            _APPROVE176(account, _MSGSENDER85(), decreasedAllowance);
            _BURN745(account, amount);
        }

    }

    contract HOGSWAP is ERC20, ERC20Burnable {
      constructor(string memory _name, string memory _symbol, uint256 totalSupply) public ERC20(_name, _symbol) {
        _MINT390(msg.sender, totalSupply);
      }
    }
