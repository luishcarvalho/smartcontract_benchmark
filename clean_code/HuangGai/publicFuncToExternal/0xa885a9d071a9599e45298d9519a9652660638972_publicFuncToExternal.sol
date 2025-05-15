





pragma solidity 0.6.11;



























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



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IStaking {

    event Connection(bytes32 indexed account);
    event Stake(bytes32 indexed account, uint256 amount, string stakeType);
    event Unstake(bytes32 indexed account);
    event UnstakingDisabled(string stakeType);
    event Migration(uint256 amount, string stakeType);


    function token() external view returns (address);
    function XFIETHPair() external view returns (address);


    function staker(address account) external view returns (bytes32, uint256, uint256, uint256);
    function isStaker(bytes32 account) external view returns (bool);


    function isXFIUnstakingDisabled() external view returns (bool);


    function isLPTStakingEnabled() external view returns (bool);
    function LPTToXFIRatio() external view returns (uint256 lptTotalSupply, uint256 xfiReserve);


    function connect(bytes32 account) external returns (bool);
    function addXFI(uint256 amount) external returns (bool);
    function addLPT(uint256 amount) external returns (bool);
    function unstake() external returns (bool);


    function disableXFIUnstaking() external returns (bool);
    function migrateXFI(address pegZone) external returns (bool);
    function setXFIETHPair(address xfiEthPairAddress) external returns (bool);
    function enableLPTStaking() external returns (bool);
}


interface IUniswapV2Pair {
    function totalSupply() external view returns (uint256);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}






contract Staking is IStaking, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    IERC20 private immutable _token;
    IUniswapV2Pair private _xfiEthPair;

    bool private _isXfiUnstakingDisabled;
    bool private _isLptStakingEnabled;

    struct Account {
        bytes32 account;
        uint256 xfiBalance;
        uint256 lptBalance;
        uint256 unstakedAt;
    }

    mapping(address => Account) private _stakers;
    mapping(bytes32 => bool) private _accounts;





    constructor(address xfiToken_, address xfiEthPair_) public {
        if (xfiEthPair_ != address(0)) {
            _checkXFIETHPair(xfiToken_, xfiEthPair_);
        }

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _token = IERC20(xfiToken_);
        _xfiEthPair = IUniswapV2Pair(xfiEthPair_);
    }











    function connect(bytes32 account) public override returns (bool) {
        require(account != bytes32(0), 'Staking: Dfinance account can not be the zero bytes');
        require(_stakers[msg.sender].account == bytes32(0), 'Staking: Ethereum account already connected');
        require(!_accounts[account], 'Staking: Dfinance account already connected');

        _accounts[account] = true;
        _stakers[msg.sender] = Account(account, 0, 0, 0);

        emit Connection(account);

        return true;
    }












    function addXFI(uint256 amount) public override nonReentrant returns (bool) {
        require(amount > 0, 'Staking: amount must be greater than zero');
        require(!_isXfiUnstakingDisabled, 'Staking: staking is disabled');
        require(_stakers[msg.sender].account != bytes32(0), 'Staking: Dfinance account is not connected');
        require(_stakers[msg.sender].unstakedAt == 0, 'Staking: unstaked account');

        _stakers[msg.sender].xfiBalance = _stakers[msg.sender].xfiBalance.add(amount);

        require(_token.transferFrom(msg.sender, address(this), amount), 'Staking: XFI transferFrom failed');

        emit Stake(_stakers[msg.sender].account, amount, 'XFI');

        return true;
    }














    function addLPT(uint256 amount) public override nonReentrant returns (bool) {
        require(amount > 0, 'Staking: amount must be greater than zero');
        require(address(_xfiEthPair) != address(0), 'Staking: XFI-ETH pair is not set');
        require(_isLptStakingEnabled, 'Staking: LPT staking is not enabled');
        require(!_isXfiUnstakingDisabled, 'Staking: staking is disabled');
        require(_stakers[msg.sender].account != bytes32(0), 'Staking: Dfinance account is not connected');
        require(_stakers[msg.sender].unstakedAt == 0, 'Staking: unstaked account');

        _stakers[msg.sender].lptBalance = _stakers[msg.sender].lptBalance.add(amount);

        require(_xfiEthPair.transferFrom(msg.sender, address(this), amount), 'Staking: LPT transferFrom failed');

        emit Stake(_stakers[msg.sender].account, amount, 'LPT');

        return true;
    }










    function unstake() public override returns (bool) {
        require(_stakers[msg.sender].account != bytes32(0), 'Staking: Dfinance account is not connected');
        require(_stakers[msg.sender].unstakedAt == 0, 'Staking: unstaked account');

        _stakers[msg.sender].unstakedAt = block.timestamp;

        if (!_isXfiUnstakingDisabled) {
            uint256 unstakedXfiAmount = _stakers[msg.sender].xfiBalance;

            if (unstakedXfiAmount > 0) {
                _stakers[msg.sender].xfiBalance = 0;
                require(_token.transfer(msg.sender, unstakedXfiAmount), 'Staking: XFI transfer failed');
            }
        }

        uint256 unstakedLptAmount = _stakers[msg.sender].lptBalance;

        if (unstakedLptAmount > 0) {
            _stakers[msg.sender].lptBalance = 0;
            require(_xfiEthPair.transfer(msg.sender, unstakedLptAmount), 'Staking: LPT transfer failed');
        }

        emit Unstake(_stakers[msg.sender].account);

        return true;
    }










    function disableXFIUnstaking() public override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Staking: sender is not owner');
        require(!_isXfiUnstakingDisabled, 'Staking: XFI unstaking is already disabled');

        _isXfiUnstakingDisabled = true;

        emit UnstakingDisabled('XFI');

        return true;
    }










    function migrateXFI(address pegZone) public override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Staking: sender is not owner');
        require(pegZone != address(0), 'Staking: pegZone is the zero address');
        require(_isXfiUnstakingDisabled, 'Staking: XFI unstaking is not disabled');

        uint256 xfiBalance = _token.balanceOf(address(this));

        require(xfiBalance > 0, 'Staking: XFI balance is zero');

        require(_token.transfer(pegZone, xfiBalance), 'Staking: XFI transfer failed');

        emit Migration(xfiBalance, 'XFI');

        return true;
    }








    function setXFIETHPair(address xfiEthPairAddress) public override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Staking: sender is not owner');
        _checkXFIETHPair(address(_token), xfiEthPairAddress);

        _xfiEthPair = IUniswapV2Pair(xfiEthPairAddress);

        return true;
    }









    function enableLPTStaking() public override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Staking: sender is not owner');
        require(address(_xfiEthPair) != address(0), 'Staking: XFI-ETH pair is not set');
        require(!_isLptStakingEnabled, 'Staking: LPT staking enabled');

        _isLptStakingEnabled = true;

        return true;
    }




    function token() public override view returns (address) {
        return address(_token);
    }




    function XFIETHPair() public view override returns (address) {
        return address(_xfiEthPair);
    }




    function isStaker(bytes32 account) public override view returns (bool) {
        return _accounts[account];
    }










    function staker(address account) public view override returns (bytes32, uint256, uint256, uint256) {
        Account memory accountObject = _stakers[account];

        return (
            accountObject.account,
            accountObject.xfiBalance,
            accountObject.lptBalance,
            accountObject.unstakedAt
        );
    }




    function isXFIUnstakingDisabled() public view override returns (bool) {
        return _isXfiUnstakingDisabled;
    }








    function LPTToXFIRatio() public view override returns (uint256 lptTotalSupply, uint256 xfiReserve) {
        lptTotalSupply = _xfiEthPair.totalSupply();

        uint112 xfiReserve_;

        if (_xfiEthPair.token0() == address(_token)) {
            (xfiReserve_, , ) = _xfiEthPair.getReserves();
        } else {
            (, xfiReserve_, ) = _xfiEthPair.getReserves();
        }

        xfiReserve = uint256(xfiReserve_);
    }




    function isLPTStakingEnabled() public view override returns (bool) {
        return _isLptStakingEnabled;
    }




    function _checkXFIETHPair(address xfiToken_, address xfiEthPairAddress) internal view {
        IUniswapV2Pair pair = IUniswapV2Pair(xfiEthPairAddress);

        require(
            (
                (pair.token0() == xfiToken_) || (pair.token1() == xfiToken_)
            ),
            'Staking: invalid XFI-ETH pair address'
            );
    }
}
