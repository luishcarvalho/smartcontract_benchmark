





pragma solidity 0.6.11;
















library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }













    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }













    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }













    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


























library EnumerableSet {









    struct Set {

        bytes32[] _values;



        mapping (bytes32 => uint256) _indexes;
    }







    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);


            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }







    function _remove(Set storage set, bytes32 value) private returns (bool) {

        uint256 valueIndex = set._indexes[value];

        if (block.number != 0) {




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




    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }




    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }











    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }



    struct AddressSet {
        Set _inner;
    }







    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }







    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }




    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }




    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }




    struct UintSet {
        Set _inner;
    }







    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }







    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }




    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }




    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}





library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (block.number > 0) {



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












abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}





































abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;









    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);







    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);








    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);




    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }





    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }













    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }







    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }











    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }










    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }















    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

















    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }






    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


















contract ReentrancyGuard {











    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }








    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");


        _status = _ENTERED;

        _;



        _status = _NOT_ENTERED;
    }
}


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}





interface IXFIToken is IERC20 {
    event VestingStartChanged(uint256 newVestingStart, uint256 newVestingEnd, uint256 newReserveFrozenUntil);
    event TransfersStarted();
    event TransfersStopped();
    event MigrationsAllowed();
    event ReserveWithdrawal(address indexed to, uint256 amount);
    event VestingBalanceMigrated(address indexed from, bytes32 to, uint256 vestingDaysLeft, uint256 vestingBalance);

    function isTransferringStopped() external view returns (bool);
    function isMigratingAllowed() external view returns (bool);
    function VESTING_DURATION() external view returns (uint256);
    function VESTING_DURATION_DAYS() external view returns (uint256);
    function RESERVE_FREEZE_DURATION() external view returns (uint256);
    function RESERVE_FREEZE_DURATION_DAYS() external view returns (uint256);
    function MAX_VESTING_TOTAL_SUPPLY() external view returns (uint256);
    function vestingStart() external view returns (uint256);
    function vestingEnd() external view returns (uint256);
    function reserveFrozenUntil() external view returns (uint256);
    function reserveAmount() external view returns (uint256);
    function vestingDaysSinceStart() external view returns (uint256);
    function vestingDaysLeft() external view returns (uint256);
    function convertAmountUsingRatio(uint256 amount) external view returns (uint256);
    function convertAmountUsingReverseRatio(uint256 amount) external view returns (uint256);
    function totalVestedBalanceOf(address account) external view returns (uint256);
    function unspentVestedBalanceOf(address account) external view returns (uint256);
    function spentVestedBalanceOf(address account) external view returns (uint256);

    function mint(address account, uint256 amount) external returns (bool);
    function mintWithoutVesting(address account, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function startTransfers() external returns (bool);
    function stopTransfers() external returns (bool);
    function allowMigrations() external returns (bool);
    function changeVestingStart(uint256 newVestingStart) external returns (bool);
    function withdrawReserve(address to) external returns (bool);
    function migrateVestingBalance(bytes32 to) external returns (bool);
}


















contract XFIToken is AccessControl, ReentrancyGuard, IXFIToken {
    using SafeMath for uint256;
    using Address for address;

    string private constant _name = 'dfinance';

    string private constant _symbol = 'XFI';

    uint8 private constant _decimals = 18;

    bytes32 public constant MINTER_ROLE = keccak256('minter');

    uint256 public constant override MAX_VESTING_TOTAL_SUPPLY = 1e26;

    uint256 public constant override VESTING_DURATION_DAYS = 182;
    uint256 public constant override VESTING_DURATION = 182 days;





    uint256 public constant override RESERVE_FREEZE_DURATION_DAYS = 730;
    uint256 public constant override RESERVE_FREEZE_DURATION = 730 days;

    mapping (address => uint256) private _vestingBalances;

    mapping (address => uint256) private _balances;

    mapping (address => uint256) private _spentVestedBalances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _vestingTotalSupply;

    uint256 private _totalSupply;

    uint256 private _spentVestedTotalSupply;

    uint256 private _vestingStart;

    uint256 private _vestingEnd;

    uint256 private _reserveFrozenUntil;

    bool private _stopped = false;

    bool private _migratingAllowed = false;

    uint256 private _reserveAmount;





    constructor (uint256 vestingStart_) public {
        require(vestingStart_ > block.timestamp, 'XFIToken: vesting start must be greater than current timestamp');
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _vestingStart = vestingStart_;
        _vestingEnd = vestingStart_.add(VESTING_DURATION);
        _reserveFrozenUntil = vestingStart_.add(RESERVE_FREEZE_DURATION);
        _reserveAmount = MAX_VESTING_TOTAL_SUPPLY;
    }










    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);

        return true;
    }
















    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);

        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, 'XFIToken: transfer amount exceeds allowance'));

        return true;
    }












    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));

        return true;
    }














    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, 'XFIToken: decreased allowance below zero'));

        return true;
    }











    function mint(address account, uint256 amount) external override returns (bool) {
        require(hasRole(MINTER_ROLE, msg.sender), 'XFIToken: sender is not minter');

        _mint(account, amount);

        return true;
    }











    function mintWithoutVesting(address account, uint256 amount) external override returns (bool) {
        require(hasRole(MINTER_ROLE, msg.sender), 'XFIToken: sender is not minter');

        _mintWithoutVesting(account, amount);

        return true;
    }










    function burnFrom(address account, uint256 amount) external override returns (bool) {
        require(hasRole(MINTER_ROLE, msg.sender), 'XFIToken: sender is not minter');

        _burn(account, amount);

        return true;
    }







    function burn(uint256 amount) external override returns (bool) {
        _burn(msg.sender, amount);

        return true;
    }











    function changeVestingStart(uint256 vestingStart_) external override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'XFIToken: sender is not owner');
        require(_vestingStart > block.timestamp, 'XFIToken: vesting has started');
        require(vestingStart_ > block.timestamp, 'XFIToken: vesting start must be greater than current timestamp');

        _vestingStart = vestingStart_;
        _vestingEnd = vestingStart_.add(VESTING_DURATION);
        _reserveFrozenUntil = vestingStart_.add(RESERVE_FREEZE_DURATION);

        emit VestingStartChanged(vestingStart_, _vestingEnd, _reserveFrozenUntil);

        return true;
    }










    function startTransfers() external override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'XFIToken: sender is not owner');
        require(_stopped, 'XFIToken: transferring is not stopped');

        _stopped = false;

        emit TransfersStarted();

        return true;
    }










    function stopTransfers() external override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'XFIToken: sender is not owner');
        require(!_stopped, 'XFIToken: transferring is stopped');

        _stopped = true;

        emit TransfersStopped();

        return true;
    }










    function allowMigrations() external override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'XFIToken: sender is not owner');
        require(!_migratingAllowed, 'XFIToken: migrating is allowed');

        _migratingAllowed = true;

        emit MigrationsAllowed();

        return true;
    }











    function withdrawReserve(address to) external override nonReentrant returns (bool) {
        require(to != address(0), 'XFIToken: withdraw to the zero address');
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'XFIToken: sender is not owner');
        require(block.timestamp > _reserveFrozenUntil, 'XFIToken: reserve is frozen');

        uint256 amount = reserveAmount();

        _mintWithoutVesting(to, amount);

        _reserveAmount = 0;

        emit ReserveWithdrawal(to, amount);

        return true;
    }











    function migrateVestingBalance(bytes32 to) external override nonReentrant returns (bool) {
        require(to != bytes32(0), 'XFIToken: migrate to the zero bytes');
        require(_migratingAllowed, 'XFIToken: migrating is disallowed');
        require(block.timestamp < _vestingEnd, 'XFIToken: vesting has ended');

        uint256 vestingBalance = _vestingBalances[msg.sender];

        require(vestingBalance > 0, 'XFIToken: vesting balance is zero');

        uint256 spentVestedBalance = spentVestedBalanceOf(msg.sender);
        uint256 unspentVestedBalance = unspentVestedBalanceOf(msg.sender);


        _vestingTotalSupply = _vestingTotalSupply.sub(vestingBalance);


        _totalSupply = _totalSupply.add(unspentVestedBalance);


        _spentVestedTotalSupply = _spentVestedTotalSupply.sub(spentVestedBalance);


        _balances[msg.sender] = _balances[msg.sender].add(unspentVestedBalance);


        _vestingBalances[msg.sender] = 0;
        _spentVestedBalances[msg.sender] = 0;

        emit VestingBalanceMigrated(msg.sender, to, vestingDaysLeft(), vestingBalance);

        return true;
    }




    function name() external view override returns (string memory) {
        return _name;
    }




    function symbol() external view override returns (string memory) {
        return _symbol;
    }




    function decimals() external view override returns (uint8) {
        return _decimals;
    }




    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }




    function vestingStart() external view override returns (uint256) {
        return _vestingStart;
    }




    function vestingEnd() external view override returns (uint256) {
        return _vestingEnd;
    }




    function reserveFrozenUntil() external view override returns (uint256) {
        return _reserveFrozenUntil;
    }




    function isTransferringStopped() external view override returns (bool) {
        return _stopped;
    }




    function isMigratingAllowed() external view override returns (bool) {
        return _migratingAllowed;
    }





    function convertAmountUsingRatio(uint256 amount) public view override returns (uint256) {
        uint256 convertedAmount = amount
            .mul(vestingDaysSinceStart())
            .div(VESTING_DURATION_DAYS);

        return (convertedAmount < amount)
            ? convertedAmount
            : amount;
    }





    function convertAmountUsingReverseRatio(uint256 amount) public view override returns (uint256) {
        if (block.timestamp > 0) {
            return amount
                .mul(vestingDaysLeft().add(1))
                .div(VESTING_DURATION_DAYS);
        } else {
            return amount;
        }
    }




    function vestingDaysSinceStart() public view override returns (uint256) {
        if (block.number > _vestingStart) {
            return block.timestamp
                .sub(_vestingStart)
                .div(1 days)
                .add(1);
        } else {
            return 0;
        }
    }




    function vestingDaysLeft() public view override returns (uint256) {
        if (block.number < _vestingEnd) {
            return VESTING_DURATION_DAYS
                .sub(vestingDaysSinceStart());
        } else {
            return 0;
        }
    }




    function totalSupply() public view override returns (uint256) {
        return convertAmountUsingRatio(_vestingTotalSupply)
            .add(_totalSupply)
            .sub(_spentVestedTotalSupply);
    }




    function totalVestedBalanceOf(address account) public view override returns (uint256) {
        return convertAmountUsingRatio(_vestingBalances[account]);
    }




    function unspentVestedBalanceOf(address account) public view override returns (uint256) {
        return totalVestedBalanceOf(account)
            .sub(_spentVestedBalances[account]);
    }




    function spentVestedBalanceOf(address account) public view override returns (uint256) {
        return _spentVestedBalances[account];
    }




    function balanceOf(address account) public view override returns (uint256) {
        return unspentVestedBalanceOf(account)
            .add(_balances[account]);
    }




    function reserveAmount() public view override returns (uint256) {
        return _reserveAmount;
    }












    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'XFIToken: transfer from the zero address');
        require(recipient != address(0), 'XFIToken: transfer to the zero address');
        require(!_stopped, 'XFIToken: transferring is stopped');

        _decreaseAccountBalance(sender, amount);

        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }












    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'XFIToken: mint to the zero address');
        require(!_stopped, 'XFIToken: transferring is stopped');
        require(_reserveAmount >= amount, 'XFIToken: mint amount exceeds reserve amount');

        _vestingTotalSupply = _vestingTotalSupply.add(amount);

        _vestingBalances[account] = _vestingBalances[account].add(amount);

        _reserveAmount = _reserveAmount.sub(amount);

        emit Transfer(address(0), account, amount);
    }











    function _mintWithoutVesting(address account, uint256 amount) internal {
        require(account != address(0), 'XFIToken: mint to the zero address');
        require(!_stopped, 'XFIToken: transferring is stopped');

        _totalSupply = _totalSupply.add(amount);

        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'XFIToken: burn from the zero address');
        require(!_stopped, 'XFIToken: transferring is stopped');
        require(balanceOf(account) >= amount, 'XFIToken: burn amount exceeds balance');

        _decreaseAccountBalance(account, amount);

        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }










    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'XFIToken: approve from the zero address');
        require(spender != address(0), 'XFIToken: approve to the zero address');

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }







    function _decreaseAccountBalance(address account, uint256 amount) internal {
        uint256 accountBalance = balanceOf(account);

        require(accountBalance >= amount, 'XFIToken: transfer amount exceeds balance');

        uint256 accountVestedBalance = unspentVestedBalanceOf(account);
        uint256 usedVestedBalance = 0;
        uint256 usedBalance = 0;

        if (block.timestamp >= amount) {
            usedVestedBalance = amount;
        } else {
            usedVestedBalance = accountVestedBalance;
            usedBalance = amount.sub(usedVestedBalance);
        }

        _balances[account] = _balances[account].sub(usedBalance);
        _spentVestedBalances[account] = _spentVestedBalances[account].add(usedVestedBalance);

        _totalSupply = _totalSupply.add(usedVestedBalance);
        _spentVestedTotalSupply = _spentVestedTotalSupply.add(usedVestedBalance);
    }
}
