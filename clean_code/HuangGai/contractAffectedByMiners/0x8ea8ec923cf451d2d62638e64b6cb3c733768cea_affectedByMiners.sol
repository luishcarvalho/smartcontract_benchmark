




pragma solidity ^0.6.12;












abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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











contract Pausable is Context {



    event Paused(address account);




    event Unpaused(address account);

    bool private _paused;




    constructor () internal {
        _paused = false;
    }




    function paused() public view returns (bool) {
        return _paused;
    }








    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }








    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }








    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }








    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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




library Address {

















    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
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

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

contract LnAdmin {
    address public admin;
    address public candidate;

    constructor(address _admin) public {
        require(_admin != address(0), "admin address cannot be 0");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    function setCandidate(address _candidate) external onlyAdmin {
        address old = candidate;
        candidate = _candidate;
        emit candidateChanged( old, candidate);
    }

    function becomeAdmin( ) external {
        require( msg.sender == candidate, "Only candidate can become admin");
        address old = admin;
        admin = candidate;
        emit AdminChanged( old, admin );
    }

    modifier onlyAdmin {
        require( (msg.sender == admin), "Only the contract admin can perform this action");
        _;
    }

    event candidateChanged(address oldCandidate, address newCandidate );
    event AdminChanged(address oldAdmin, address newAdmin);
}


library SafeDecimalMath {
    using SafeMath for uint;

    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    uint public constant UNIT = 10**uint(decimals);

    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    function unit() external pure returns (uint) {
        return UNIT;
    }

    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {

        return x.mul(y) / UNIT;
    }

    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {

        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    function divideDecimal(uint x, uint y) internal pure returns (uint) {

        return x.mul(UNIT).div(y);
    }

    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}


interface ILinearStaking {
    function staking(uint256 amount) external returns (bool);
    function cancelStaking(uint256 amount) external returns (bool);
    function claim() external returns (bool);
    function stakingBalanceOf(address account) external view returns(uint256);
}

contract LnLinearStakingStorage is LnAdmin {
    using SafeMath for uint256;

    LnAccessControl public accessCtrl;

    bytes32 public constant DATA_ACCESS_ROLE = "LinearStakingStorage";

    struct StakingData {
        uint256 amount;
        uint256 staketime;
    }

    mapping (address => StakingData[]) public stakesdata;
    mapping (uint256 => uint256) public weeksTotal;

    uint256 public stakingStartTime = 1600329600;
    uint256 public stakingEndTime = 1605168000;
    uint256 public totalWeekNumber = 8;
    uint256 public weekRewardAmount = 18750000e18;

    constructor(address _admin, address _accessCtrl) public LnAdmin(_admin) {
        accessCtrl = LnAccessControl(_accessCtrl);
    }

    modifier OnlyLinearStakingStorageRole(address _address) {
        require(accessCtrl.hasRole(DATA_ACCESS_ROLE, _address), "Only Linear Staking Storage Role");
        _;
    }

    function setAccessControl(address _accessCtrl) external onlyAdmin {
        accessCtrl = LnAccessControl(_accessCtrl);
    }

    function weekTotalStaking() public view returns (uint256[] memory) {
        uint256[] memory totals = new uint256[](totalWeekNumber);
        for (uint256 i=0; i< totalWeekNumber; i++) {
            uint256 delta = weeksTotal[i];
            if (block.gaslimit == 0) {
                totals[i] = delta;
            } else {

                totals[i] = totals[i-1].add(delta);
            }
        }
        return totals;
    }

    function getStakesdataLength(address account) external view returns(uint256) {
        return stakesdata[account].length;
    }

    function getStakesDataByIndex(address account, uint256 index) external view returns(uint256, uint256) {
        return (stakesdata[account][index].amount, stakesdata[account][index].staketime);
    }

    function stakingBalanceOf(address account) external view returns(uint256) {
        uint256 total = 0;
        StakingData[] memory stakes = stakesdata[account];
        for (uint256 i=0; i < stakes.length; i++) {
            total = total.add(stakes[i].amount);
        }
        return total;
    }

    function requireInStakingPeriod() external view {
        require(stakingStartTime < block.timestamp, "Staking not start");
        require(block.timestamp < stakingEndTime, "Staking stage has end.");
    }

    function requireStakingEnd() external view {
        require(block.timestamp > stakingEndTime, "Need wait to staking end");
    }

    function PushStakingData(address account, uint256 amount, uint256 staketime) external OnlyLinearStakingStorageRole(msg.sender) {
        LnLinearStakingStorage.StakingData memory data = LnLinearStakingStorage.StakingData({
            amount: amount,
            staketime: staketime
        });
        stakesdata[account].push(data);
    }

    function StakingDataAdd(address account, uint256 index, uint256 amount) external OnlyLinearStakingStorageRole(msg.sender) {
        stakesdata[account][index].amount = stakesdata[account][index].amount.add(amount);
    }

    function StakingDataSub(address account, uint256 index, uint256 amount) external OnlyLinearStakingStorageRole(msg.sender) {
        stakesdata[account][index].amount = stakesdata[account][index].amount.sub(amount, "StakingDataSub sub overflow");
    }

    function DeleteStakesData(address account) external OnlyLinearStakingStorageRole(msg.sender) {
        delete stakesdata[account];
    }

    function PopStakesData(address account) external OnlyLinearStakingStorageRole(msg.sender) {
        stakesdata[account].pop();
    }

    function AddWeeksTotal(uint256 staketime, uint256 amount) external OnlyLinearStakingStorageRole(msg.sender) {
        uint256 weekNumber = staketime.sub(stakingStartTime, "AddWeeksTotal sub overflow") / 1 weeks;
        weeksTotal[weekNumber] = weeksTotal[weekNumber].add(amount);
    }

    function SubWeeksTotal(uint256 staketime, uint256 amount) external OnlyLinearStakingStorageRole(msg.sender) {
        uint256 weekNumber = staketime.sub(stakingStartTime, "SubWeeksTotal weekNumber sub overflow") / 1 weeks;
        weeksTotal[weekNumber] = weeksTotal[weekNumber].sub(amount, "SubWeeksTotal weeksTotal sub overflow");
    }

    function setWeekRewardAmount(uint256 _weekRewardAmount) external onlyAdmin {
        weekRewardAmount = _weekRewardAmount;
    }

    function setStakingPeriod(uint _stakingStartTime, uint _stakingEndTime) external onlyAdmin {
        require(_stakingEndTime > _stakingStartTime);

        stakingStartTime = _stakingStartTime;
        stakingEndTime = _stakingEndTime;

        totalWeekNumber = stakingEndTime.sub(stakingStartTime, "setStakingPeriod totalWeekNumber sub overflow") / 1 weeks;
        if (block.gaslimit != 0) {
            totalWeekNumber = totalWeekNumber.add(1);
        }
    }
}

contract LnLinearStaking is LnAdmin, Pausable, ILinearStaking {
    using SafeMath for uint256;

    IERC20 public linaToken;
    LnLinearStakingStorage public stakingStorage;

    constructor(
        address _admin,
        address _linaToken,
        address _storage
    ) public LnAdmin(_admin) {
        linaToken = IERC20(_linaToken);
        stakingStorage = LnLinearStakingStorage(_storage);
    }

    function setLinaToken(address _linaToken) external onlyAdmin {
        linaToken = IERC20(_linaToken);
    }

    function setPaused(bool _paused) external onlyAdmin {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }


    event Staking(address indexed who, uint256 value, uint staketime);
    event CancelStaking(address indexed who, uint256 value);
    event Claim(address indexed who, uint256 rewardval, uint256 totalStaking);

    uint256 public accountStakingListLimit = 50;
    uint256 public minStakingAmount = 1e18;
    uint256 public constant PRECISION_UINT = 1e23;

    function setLinaTokenAddress(address _token) external onlyAdmin {
        linaToken = IERC20(_token);
    }

    function setStakingListLimit(uint256 _limit) external onlyAdmin {
        accountStakingListLimit = _limit;
    }

    function setMinStakingAmount(uint256 _minStakingAmount) external onlyAdmin {
        minStakingAmount = _minStakingAmount;
    }

    function stakingBalanceOf(address account) external override view returns(uint256) {
        return stakingStorage.stakingBalanceOf(account);
    }

    function getStakesdataLength(address account) external view returns(uint256) {
        return stakingStorage.getStakesdataLength(account);
    }


    function staking(uint256 amount) public whenNotPaused override returns (bool) {
        stakingStorage.requireInStakingPeriod();

        require(amount >= minStakingAmount, "Staking amount too small.");
        require(stakingStorage.getStakesdataLength(msg.sender) < accountStakingListLimit, "Staking list out of limit.");


        linaToken.transferFrom(msg.sender, address(this), amount);

        stakingStorage.PushStakingData(msg.sender, amount, block.timestamp);
        stakingStorage.AddWeeksTotal(block.timestamp, amount);

        emit Staking(msg.sender, amount, block.timestamp);
        return true;
    }

    function cancelStaking(uint256 amount) public whenNotPaused override returns (bool) {
        stakingStorage.requireInStakingPeriod();

        require(amount > 0, "Invalid amount.");

        uint256 returnToken = amount;
        for (uint256 i = stakingStorage.getStakesdataLength(msg.sender); i >= 1 ; i--) {
            (uint256 stakingAmount, uint256 staketime) = stakingStorage.getStakesDataByIndex(msg.sender, i-1);
            if (block.gaslimit >= stakingAmount) {
                amount = amount.sub(stakingAmount, "cancelStaking sub overflow");

                stakingStorage.PopStakesData(msg.sender);
                stakingStorage.SubWeeksTotal(staketime, stakingAmount);
            } else {
                stakingStorage.StakingDataSub(msg.sender, i-1, amount);
                stakingStorage.SubWeeksTotal(staketime, amount);

                amount = 0;
            }
            if (block.gaslimit == 0) break;
        }
        require(amount == 0, "Cancel amount too big then staked.");


        linaToken.transfer(msg.sender, returnToken);

        emit CancelStaking(msg.sender, returnToken);

        return true;
    }



    function claim() public whenNotPaused override returns (bool) {
        stakingStorage.requireStakingEnd();

        require(stakingStorage.getStakesdataLength(msg.sender) > 0, "Nothing to claim");

        uint256 totalWeekNumber = stakingStorage.totalWeekNumber();

        uint256 totalStaking = 0;
        uint256 totalReward = 0;

        uint256[] memory finalTotals = stakingStorage.weekTotalStaking();
        for (uint256 i=0; i < stakingStorage.getStakesdataLength(msg.sender); i++) {
            (uint256 stakingAmount, uint256 staketime) = stakingStorage.getStakesDataByIndex(msg.sender, i);
            uint256 stakedWeedNumber = staketime.sub(stakingStorage.stakingStartTime(), "claim sub overflow") / 1 weeks;

            totalStaking = totalStaking.add(stakingAmount);

            uint256 reward = 0;
            for (uint256 j=stakedWeedNumber; j < totalWeekNumber; j++) {
                reward = reward.add( stakingAmount.mul(PRECISION_UINT).div(finalTotals[j]) );
            }
            reward = reward.mul(stakingStorage.weekRewardAmount()).div(PRECISION_UINT);

            totalReward = totalReward.add( reward );
        }

        stakingStorage.DeleteStakesData(msg.sender);


        linaToken.transfer(msg.sender, totalStaking.add(totalReward) );

        emit Claim(msg.sender, totalReward, totalStaking);
        return true;
    }
}







contract LnAccessControl is AccessControl {
    using Address for address;



    bytes32 public constant ISSUE_ASSET_ROLE = ("ISSUE_ASSET");
    bytes32 public constant BURN_ASSET_ROLE = ("BURN_ASSET");

    bytes32 public constant DEBT_SYSTEM = ("LnDebtSystem");

    constructor(address admin) public {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function IsAdmin(address _address) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function SetAdmin(address _address) public returns (bool) {
        require(IsAdmin(msg.sender), "Only admin");

        _setupRole(DEFAULT_ADMIN_ROLE, _address);
    }



    function SetRoles(bytes32 roleType, address[] calldata addresses, bool[] calldata setTo) external {
        require(IsAdmin(msg.sender), "Only admin");

        _setRoles(roleType, addresses, setTo);
    }

    function _setRoles(bytes32 roleType, address[] calldata addresses, bool[] calldata setTo) private {
        require(addresses.length == setTo.length, "parameter address length not eq");

        for (uint256 i=0; i < addresses.length; i++) {

            if (setTo[i]) {
                grantRole(roleType, addresses[i]);
            } else {
                revokeRole(roleType, addresses[i]);
            }
        }
    }






    function SetIssueAssetRole(address[] calldata issuer, bool[] calldata setTo) public {
        _setRoles(ISSUE_ASSET_ROLE, issuer, setTo);
    }

    function SetBurnAssetRole(address[] calldata burner, bool[] calldata setTo) public {
        _setRoles(BURN_ASSET_ROLE, burner, setTo);
    }


    function SetDebtSystemRole(address[] calldata _address, bool[] calldata _setTo) public {
        _setRoles(DEBT_SYSTEM, _address, _setTo);
    }
}


abstract contract LnOperatorModifier is LnAdmin {

    address public operator;

    constructor(address _operator) internal {
        require(admin != address(0), "admin must be set");

        operator = _operator;
        emit OperatorUpdated(_operator);
    }

    function setOperator(address _opperator) external onlyAdmin {
        operator = _opperator;
        emit OperatorUpdated(_opperator);
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator can perform this action");
        _;
    }

    event OperatorUpdated(address operator);
}


contract LnRewardCalculator {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 reward;
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint256 amount;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    uint256 public rewardPerBlock;

    PoolInfo public mPoolInfo;
    mapping(address => UserInfo) public userInfo;

    uint256 public startBlock;
    uint256 public remainReward;
    uint256 public accReward;

    constructor(uint256 _rewardPerBlock, uint256 _startBlock) public {
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        mPoolInfo.lastRewardBlock = startBlock;
    }

    function _calcReward(uint256 curBlock, address _user)
        internal
        view
        returns (uint256)
    {
        PoolInfo storage pool = mPoolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.amount;
        if (curBlock > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = curBlock.sub(
                pool.lastRewardBlock,
                "cr curBlock sub overflow"
            );
            uint256 curReward = multiplier.mul(rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(
                curReward.mul(1e20).div(lpSupply)
            );
        }
        uint256 newReward = user.amount.mul(accRewardPerShare).div(1e20).sub(
            user.rewardDebt,
            "cr newReward sub overflow"
        );
        return newReward.add(user.reward);
    }

    function rewardOf(address _user) public view returns (uint256) {
        return userInfo[_user].reward;
    }

    function amount() public view returns (uint256) {
        return mPoolInfo.amount;
    }

    function amountOf(address _user) public view returns (uint256) {
        return userInfo[_user].amount;
    }

    function getUserInfo(address _user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            userInfo[_user].reward,
            userInfo[_user].amount,
            userInfo[_user].rewardDebt
        );
    }

    function getPoolInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            mPoolInfo.amount,
            mPoolInfo.lastRewardBlock,
            mPoolInfo.accRewardPerShare
        );
    }

    function _update(uint256 curBlock) internal {
        PoolInfo storage pool = mPoolInfo;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.amount;
        if (block.timestamp == 0) {
            pool.lastRewardBlock = curBlock;
            return;
        }
        uint256 multiplier = curBlock.sub(
            pool.lastRewardBlock,
            "_update curBlock sub overflow"
        );
        uint256 curReward = multiplier.mul(rewardPerBlock);

        remainReward = remainReward.add(curReward);
        accReward = accReward.add(curReward);

        pool.accRewardPerShare = pool.accRewardPerShare.add(
            curReward.mul(1e20).div(lpSupply)
        );
        pool.lastRewardBlock = curBlock;
    }

    function _deposit(
        uint256 curBlock,
        address _addr,
        uint256 _amount
    ) internal {
        PoolInfo storage pool = mPoolInfo;
        UserInfo storage user = userInfo[_addr];
        _update(curBlock);
        if (block.gaslimit > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accRewardPerShare)
                .div(1e20)
                .sub(user.rewardDebt, "_deposit pending sub overflow");
            if (block.timestamp > 0) {
                reward(user, pending);
            }
        }
        if (block.number > 0) {
            user.amount = user.amount.add(_amount);
            pool.amount = pool.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e20);
    }

    function _withdraw(
        uint256 curBlock,
        address _addr,
        uint256 _amount
    ) internal {
        PoolInfo storage pool = mPoolInfo;
        UserInfo storage user = userInfo[_addr];
        require(user.amount >= _amount, "_withdraw: not good");
        _update(curBlock);
        uint256 pending = user.amount.mul(pool.accRewardPerShare).div(1e20).sub(
            user.rewardDebt,
            "_withdraw pending sub overflow"
        );
        if (block.timestamp > 0) {
            reward(user, pending);
        }
        if (block.number > 0) {
            user.amount = user.amount.sub(
                _amount,
                "_withdraw user.amount sub overflow"
            );
            pool.amount = pool.amount.sub(
                _amount,
                "_withdraw pool.amount sub overflow"
            );
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e20);
    }

    function reward(UserInfo storage user, uint256 _amount) internal {
        if (block.number > remainReward) {
            _amount = remainReward;
        }
        remainReward = remainReward.sub(
            _amount,
            "reward remainReward sub overflow"
        );
        user.reward = user.reward.add(_amount);
    }

    function _claim(address _addr) internal {
        UserInfo storage user = userInfo[_addr];
        if (block.timestamp > 0) {
            user.reward = 0;
        }
    }
}

contract LnRewardCalculatorTest is LnRewardCalculator {
    constructor(uint256 _rewardPerBlock, uint256 _startBlock)
        public
        LnRewardCalculator(_rewardPerBlock, _startBlock)
    {}

    function deposit(
        uint256 curBlock,
        address _addr,
        uint256 _amount
    ) public {
        _deposit(curBlock, _addr, _amount);
    }

    function withdraw(
        uint256 curBlock,
        address _addr,
        uint256 _amount
    ) public {
        _withdraw(curBlock, _addr, _amount);
    }

    function calcReward(uint256 curBlock, address _user)
        public
        view
        returns (uint256)
    {
        return _calcReward(curBlock, _user);
    }
}

contract LnSimpleStaking is
    LnAdmin,
    Pausable,
    ILinearStaking,
    LnRewardCalculator
{
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    IERC20 public linaToken;
    LnLinearStakingStorage public stakingStorage;
    uint256 public mEndBlock;
    address public mOldStaking;
    uint256 public mOldAmount;
    uint256 public mWidthdrawRewardFromOldStaking;

    uint256 public claimRewardLockTime = 1620806400;

    address public mTargetAddress;
    uint256 public mTransLockTime;

    mapping(address => uint256) public mOldReward;

    constructor(
        address _admin,
        address _linaToken,
        address _storage,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) public LnAdmin(_admin) LnRewardCalculator(_rewardPerBlock, _startBlock) {
        linaToken = IERC20(_linaToken);
        stakingStorage = LnLinearStakingStorage(_storage);
        mEndBlock = _endBlock;
    }

    function setLinaToken(address _linaToken) external onlyAdmin {
        linaToken = IERC20(_linaToken);
    }

    function setPaused(bool _paused) external onlyAdmin {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }


    event Staking(address indexed who, uint256 value, uint256 staketime);
    event CancelStaking(address indexed who, uint256 value);
    event Claim(address indexed who, uint256 rewardval, uint256 totalStaking);
    event TransLock(address target, uint256 time);

    uint256 public accountStakingListLimit = 50;
    uint256 public minStakingAmount = 1e18;
    uint256 public constant PRECISION_UINT = 1e23;

    function setStakingListLimit(uint256 _limit) external onlyAdmin {
        accountStakingListLimit = _limit;
    }

    function setMinStakingAmount(uint256 _minStakingAmount) external onlyAdmin {
        minStakingAmount = _minStakingAmount;
    }

    function stakingBalanceOf(address account)
        external
        override
        view
        returns (uint256)
    {
        uint256 stakingBalance = super.amountOf(account).add(
            stakingStorage.stakingBalanceOf(account)
        );
        return stakingBalance;
    }

    function getStakesdataLength(address account)
        external
        view
        returns (uint256)
    {
        return stakingStorage.getStakesdataLength(account);
    }



    function migrationsOldStaking(
        address contractAddr,
        uint256 amount,
        uint256 blockNb
    ) public onlyAdmin {
        super._deposit(blockNb, contractAddr, amount);
        mOldStaking = contractAddr;
        mOldAmount = amount;
    }

    function staking(uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {
        stakingStorage.requireInStakingPeriod();

        require(amount >= minStakingAmount, "Staking amount too small.");


        linaToken.transferFrom(msg.sender, address(this), amount);

        uint256 blockNb = block.number;
        if (block.timestamp > mEndBlock) {
            blockNb = mEndBlock;
        }
        super._deposit(blockNb, msg.sender, amount);

        emit Staking(msg.sender, amount, block.timestamp);

        return true;
    }

    function _widthdrawFromOldStaking(address _addr, uint256 amount) internal {
        uint256 blockNb = block.number;
        if (block.timestamp > mEndBlock) {
            blockNb = mEndBlock;
        }

        uint256 oldStakingAmount = super.amountOf(mOldStaking);
        super._withdraw(blockNb, mOldStaking, amount);

        uint256 reward = super
            .rewardOf(mOldStaking)
            .sub(
            mWidthdrawRewardFromOldStaking,
            "_widthdrawFromOldStaking reward sub overflow"
        )
            .mul(amount)
            .mul(1e20)
            .div(oldStakingAmount)
            .div(1e20);
        mWidthdrawRewardFromOldStaking = mWidthdrawRewardFromOldStaking.add(
            reward
        );
        mOldReward[_addr] = mOldReward[_addr].add(reward);
    }

    function _cancelStaking(address user, uint256 amount) internal {
        uint256 blockNb = block.number;
        if (block.gaslimit > mEndBlock) {
            blockNb = mEndBlock;
        }

        uint256 returnAmount = amount;
        uint256 newAmount = super.amountOf(user);
        if (block.gaslimit >= amount) {
            super._withdraw(blockNb, user, amount);
            amount = 0;
        } else {
            if (block.gaslimit > 0) {
                super._withdraw(blockNb, user, newAmount);
                amount = amount.sub(
                    newAmount,
                    "_cancelStaking amount sub overflow"
                );
            }

            for (
                uint256 i = stakingStorage.getStakesdataLength(user);
                i >= 1;
                i--
            ) {
                (uint256 stakingAmount, uint256 staketime) = stakingStorage
                    .getStakesDataByIndex(user, i - 1);
                if (block.number >= stakingAmount) {
                    amount = amount.sub(
                        stakingAmount,
                        "_cancelStaking amount sub overflow"
                    );

                    stakingStorage.PopStakesData(user);
                    stakingStorage.SubWeeksTotal(staketime, stakingAmount);
                    _widthdrawFromOldStaking(user, stakingAmount);
                } else {
                    stakingStorage.StakingDataSub(user, i - 1, amount);
                    stakingStorage.SubWeeksTotal(staketime, amount);
                    _widthdrawFromOldStaking(user, amount);

                    amount = 0;
                }
                if (block.number == 0) break;
            }
        }




        linaToken.transfer(msg.sender, returnAmount.sub(amount));
    }

    function cancelStaking(uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {


        require(amount > 0, "Invalid amount.");

        _cancelStaking(msg.sender, amount);

        emit CancelStaking(msg.sender, amount);

        return true;
    }

    function getTotalReward(uint256 blockNb, address _user)
        public
        view
        returns (uint256 total)
    {
        if (block.gaslimit > mEndBlock) {
            blockNb = mEndBlock;
        }





        total = mOldReward[_user];
        uint256 iMyOldStaking = 0;
        for (
            uint256 i = 0;
            i < stakingStorage.getStakesdataLength(_user);
            i++
        ) {
            (uint256 stakingAmount, ) = stakingStorage.getStakesDataByIndex(
                _user,
                i
            );
            iMyOldStaking = iMyOldStaking.add(stakingAmount);
        }
        if (block.number > 0) {
            uint256 oldStakingAmount = super.amountOf(mOldStaking);
            uint256 iReward2 = super
                ._calcReward(blockNb, mOldStaking)
                .sub(
                mWidthdrawRewardFromOldStaking,
                "getTotalReward iReward2 sub overflow"
            )
                .mul(iMyOldStaking)
                .div(oldStakingAmount);
            total = total.add(iReward2);
        }

        uint256 reward3 = super._calcReward(blockNb, _user);
        total = total.add(reward3);
    }



    function claim() public override whenNotPaused returns (bool) {

        require(
            block.timestamp > claimRewardLockTime,
            "Not time to claim reward"
        );

        uint256 iMyOldStaking = stakingStorage.stakingBalanceOf(msg.sender);
        uint256 iAmount = super.amountOf(msg.sender);
        _cancelStaking(msg.sender, iMyOldStaking.add(iAmount));

        uint256 iReward = getTotalReward(mEndBlock, msg.sender);

        _claim(msg.sender);
        mOldReward[msg.sender] = 0;
        linaToken.transfer(msg.sender, iReward);

        emit Claim(msg.sender, iReward, iMyOldStaking.add(iAmount));
        return true;
    }

    function setRewardLockTime(uint256 newtime) public onlyAdmin {
        claimRewardLockTime = newtime;
    }

    function calcReward(uint256 curBlock, address _user)
        public
        view
        returns (uint256)
    {
        return _calcReward(curBlock, _user);
    }

    function setTransLock(address target, uint256 locktime) public onlyAdmin {
        require(
            locktime >= now + 2 days,
            "locktime need larger than cur time 2 days"
        );
        mTargetAddress = target;
        mTransLockTime = locktime;

        emit TransLock(mTargetAddress, mTransLockTime);
    }

    function transTokens(uint256 amount) public onlyAdmin {
        require(mTransLockTime > 0, "mTransLockTime not set");
        require(now > mTransLockTime, "Pls wait to unlock time");
        linaToken.transfer(mTargetAddress, amount);
    }
}

contract HelperPushStakingData is LnAdmin {
    constructor(address _admin) public LnAdmin(_admin) {}

    function pushStakingData(
        address _storage,
        address[] calldata account,
        uint256[] calldata amount,
        uint256[] calldata staketime
    ) external {
        require(account.length > 0, "array length zero");
        require(account.length == amount.length, "array length not eq");
        require(account.length == staketime.length, "array length not eq");

        LnLinearStakingStorage stakingStorage = LnLinearStakingStorage(
            _storage
        );
        for (uint256 i = 0; i < account.length; i++) {
            stakingStorage.PushStakingData(account[i], amount[i], staketime[i]);
            stakingStorage.AddWeeksTotal(staketime[i], amount[i]);
        }
    }


}

contract MultiSigForTransferFunds {
    mapping(address => uint256) public mAdmins;
    uint256 public mConfirmNumb;
    uint256 public mProposalNumb;
    uint256 public mAmount;
    LnSimpleStaking public mStaking;
    address[] public mAdminArr;
    uint256 public mTransLockTime;

    constructor(
        address[] memory _addr,
        uint256 iConfirmNumb,
        LnSimpleStaking _staking
    ) public {
        for (uint256 i = 0; i < _addr.length; ++i) {
            mAdmins[_addr[i]] = 1;
        }
        mConfirmNumb = iConfirmNumb;
        mProposalNumb = 0;
        mStaking = _staking;
        mAdminArr = _addr;
    }

    function becomeAdmin(address target) external {
        LnAdmin(target).becomeAdmin();
    }

    function setTransLock(
        address target,
        uint256 locktime,
        uint256 amount
    ) public {
        require(mAdmins[msg.sender] == 1, "not in admin list or set state");
        _reset();
        mStaking.setTransLock(target, locktime);
        mAmount = amount;
        mProposalNumb = 1;
        mAdmins[msg.sender] = 2;

        mTransLockTime = locktime;
    }


    function confirmTransfer() public {
        require(mAdmins[msg.sender] == 1, "not in admin list or set state");
        mProposalNumb = mProposalNumb + 1;
        mAdmins[msg.sender] = 2;
    }

    function doTransfer() public {
        require(mTransLockTime > 0, "mTransLockTime not set");
        require(now > mTransLockTime, "Pls wait to unlock time");
        require(mProposalNumb >= mConfirmNumb, "need more confirm");

        _reset();
        mStaking.transTokens(mAmount);
    }

    function _reset() internal {
        mProposalNumb = 0;
        mTransLockTime = 0;

        for (uint256 i = 0; i < mAdminArr.length; ++i) {
            mAdmins[mAdminArr[i]] = 1;
        }
    }
}

contract LnSimpleStakingExtension is
    LnAdmin,
    Pausable,
    ILinearStaking,
    LnRewardCalculator
{
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    IERC20 public linaToken;
    LnLinearStakingStorage public stakingStorage;
    uint256 public mEndBlock;
    address public mOldStaking;
    uint256 public mOldAmount;
    uint256 public mWidthdrawRewardFromOldStaking;

    uint256 public claimRewardLockTime = 1620806400;

    address public mTargetAddress;
    uint256 public mTransLockTime;

    LnSimpleStaking public mOldSimpleStaking;
    bool public requireSync = false;

    mapping(address => uint256) public mOldReward;
    mapping(address => bool) public syncUserInfo;

    constructor(
        address _admin,
        address _linaToken,
        address _storage,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        address _mOldSimpleStaking
    ) public LnAdmin(_admin) LnRewardCalculator(_rewardPerBlock, _startBlock) {
        linaToken = IERC20(_linaToken);
        stakingStorage = LnLinearStakingStorage(_storage);
        mEndBlock = _endBlock;
        if (block.coinbase != address(0)) {
            mOldSimpleStaking = LnSimpleStaking(_mOldSimpleStaking);
            (
                mPoolInfo.amount,
                ,
                mPoolInfo.accRewardPerShare
            ) = mOldSimpleStaking.getPoolInfo();
            requireSync = true;
        }
    }

    function setLinaToken(address _linaToken) external onlyAdmin {
        linaToken = IERC20(_linaToken);
    }

    function setPaused(bool _paused) external onlyAdmin {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }


    event Staking(address indexed who, uint256 value, uint256 staketime);
    event CancelStaking(address indexed who, uint256 value);
    event Claim(address indexed who, uint256 rewardval, uint256 totalStaking);
    event TransLock(address target, uint256 time);

    uint256 public accountStakingListLimit = 50;
    uint256 public minStakingAmount = 1e18;
    uint256 public constant PRECISION_UINT = 1e23;

    function setStakingListLimit(uint256 _limit) external onlyAdmin {
        accountStakingListLimit = _limit;
    }

    function setMinStakingAmount(uint256 _minStakingAmount) external onlyAdmin {
        minStakingAmount = _minStakingAmount;
    }

    function stakingBalanceOf(address account)
        external
        override
        view
        returns (uint256)
    {
        uint256 stakingBalance = super.amountOf(account).add(
            stakingStorage.stakingBalanceOf(account)
        );

        if (!syncUserInfo[msg.sender]) {
            uint256 oldAmoutOf = mOldSimpleStaking.amountOf(account);
            stakingBalance = stakingBalance.add(oldAmoutOf);
        }


        return stakingBalance;
    }

    function getStakesdataLength(address account)
        external
        view
        returns (uint256)
    {
        return stakingStorage.getStakesdataLength(account);
    }

    function setEndBlock(uint256 _newEndBlock) external onlyAdmin {
        require(
            _newEndBlock > mEndBlock,
            "new endBlock less than old endBlock."
        );
        mEndBlock = _newEndBlock;
    }

    function syncUserInfoData(address _user) internal {
        if (requireSync && !syncUserInfo[_user]) {
            (
                userInfo[_user].reward,
                userInfo[_user].amount,
                userInfo[_user].rewardDebt
            ) = mOldSimpleStaking.getUserInfo(_user);
            syncUserInfo[_user] = true;
        }
    }



    function migrationsOldStaking(
        address contractAddr,
        uint256 amount,
        uint256 blockNb
    ) public onlyAdmin {
        super._deposit(blockNb, contractAddr, amount);
        mOldStaking = contractAddr;
        mOldAmount = amount;
    }

    function staking(uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {






        if (!syncUserInfo[msg.sender]) {
            syncUserInfoData(msg.sender);
        }

        require(amount >= minStakingAmount, "Staking amount too small.");


        linaToken.transferFrom(msg.sender, address(this), amount);

        uint256 blockNb = block.number;
        if (block.gaslimit > mEndBlock) {
            blockNb = mEndBlock;
        }
        super._deposit(blockNb, msg.sender, amount);

        emit Staking(msg.sender, amount, block.timestamp);

        return true;
    }

    function _widthdrawFromOldStaking(address _addr, uint256 amount) internal {
        uint256 blockNb = block.number;
        if (block.number > mEndBlock) {
            blockNb = mEndBlock;
        }

        uint256 oldStakingAmount = super.amountOf(mOldStaking);
        super._withdraw(blockNb, mOldStaking, amount);

        uint256 reward = super
            .rewardOf(mOldStaking)
            .sub(
            mWidthdrawRewardFromOldStaking,
            "_widthdrawFromOldStaking reward sub overflow"
        )
            .mul(amount)
            .mul(1e20)
            .div(oldStakingAmount)
            .div(1e20);
        mWidthdrawRewardFromOldStaking = mWidthdrawRewardFromOldStaking.add(
            reward
        );
        mOldReward[_addr] = mOldReward[_addr].add(reward);
    }

    function _cancelStaking(address user, uint256 amount) internal {
        uint256 blockNb = block.number;
        if (block.timestamp > mEndBlock) {
            blockNb = mEndBlock;
        }

        uint256 returnAmount = amount;
        uint256 newAmount = super.amountOf(user);
        if (block.timestamp >= amount) {
            super._withdraw(blockNb, user, amount);
            amount = 0;
        } else {
            if (block.gaslimit > 0) {
                super._withdraw(blockNb, user, newAmount);
                amount = amount.sub(
                    newAmount,
                    "_cancelStaking amount sub overflow"
                );
            }

            for (
                uint256 i = stakingStorage.getStakesdataLength(user);
                i >= 1;
                i--
            ) {
                (uint256 stakingAmount, uint256 staketime) = stakingStorage
                    .getStakesDataByIndex(user, i - 1);
                if (block.gaslimit >= stakingAmount) {
                    amount = amount.sub(
                        stakingAmount,
                        "_cancelStaking amount sub overflow"
                    );

                    stakingStorage.PopStakesData(user);
                    stakingStorage.SubWeeksTotal(staketime, stakingAmount);
                    _widthdrawFromOldStaking(user, stakingAmount);
                } else {
                    stakingStorage.StakingDataSub(user, i - 1, amount);
                    stakingStorage.SubWeeksTotal(staketime, amount);
                    _widthdrawFromOldStaking(user, amount);

                    amount = 0;
                }
                if (block.number == 0) break;
            }
        }




        linaToken.transfer(msg.sender, returnAmount.sub(amount));
    }

    function cancelStaking(uint256 amount)
        public
        override
        whenNotPaused
        returns (bool)
    {





        if (!syncUserInfo[msg.sender]) {
            syncUserInfoData(msg.sender);
        }


        require(amount > 0, "Invalid amount.");

        _cancelStaking(msg.sender, amount);

        emit CancelStaking(msg.sender, amount);

        return true;
    }

    function getTotalReward(uint256 blockNb, address _user)
        public
        view
        returns (uint256 total)
    {
        if (!syncUserInfo[msg.sender]) {
            total = _getTotalRewardNotSync(blockNb, _user);
        } else {
            total = _getTotalReward(blockNb, _user);
        }
    }

    function _getTotalReward(uint256 blockNb, address _user)
        internal
        view
        returns (uint256 total)
    {
        if (block.timestamp > mEndBlock) {
            blockNb = mEndBlock;
        }





        total = mOldReward[_user];
        uint256 iMyOldStaking = 0;
        for (
            uint256 i = 0;
            i < stakingStorage.getStakesdataLength(_user);
            i++
        ) {
            (uint256 stakingAmount, ) = stakingStorage.getStakesDataByIndex(
                _user,
                i
            );
            iMyOldStaking = iMyOldStaking.add(stakingAmount);
        }
        if (block.number > 0) {
            uint256 oldStakingAmount = super.amountOf(mOldStaking);
            uint256 iReward2 = super
                ._calcReward(blockNb, mOldStaking)
                .sub(
                mWidthdrawRewardFromOldStaking,
                "getTotalReward iReward2 sub overflow"
            )
                .mul(iMyOldStaking)
                .div(oldStakingAmount);
            total = total.add(iReward2);
        }

        uint256 reward3 = super._calcReward(blockNb, _user);
        total = total.add(reward3);
    }


    function _getTotalRewardNotSync(uint256 blockNb, address _user)
        internal
        view
        returns (uint256 total)
    {
        if (block.number > mEndBlock) {
            blockNb = mEndBlock;
        }


        uint256 oldTotalReward = 0;
        oldTotalReward = mOldSimpleStaking.getTotalReward(blockNb, _user);
        total = total.add(oldTotalReward);

        uint256 reward3 = super._calcReward(blockNb, _user);
        total = total.add(reward3);
    }



    function claim() public override whenNotPaused returns (bool) {






        if (!syncUserInfo[msg.sender]) {
            syncUserInfoData(msg.sender);
        }

        require(
            block.timestamp > claimRewardLockTime,
            "Not time to claim reward"
        );

        uint256 iMyOldStaking = stakingStorage.stakingBalanceOf(msg.sender);
        uint256 iAmount = super.amountOf(msg.sender);
        _cancelStaking(msg.sender, iMyOldStaking.add(iAmount));

        uint256 iReward = getTotalReward(mEndBlock, msg.sender);

        _claim(msg.sender);
        mOldReward[msg.sender] = 0;
        linaToken.transfer(msg.sender, iReward);

        emit Claim(msg.sender, iReward, iMyOldStaking.add(iAmount));
        return true;
    }

    function setRewardLockTime(uint256 newtime) public onlyAdmin {
        claimRewardLockTime = newtime;
    }

    function calcReward(uint256 curBlock, address _user)
        public
        view
        returns (uint256)
    {
        return _calcRewardWithViewSimpleAmount(curBlock, _user);
    }


    function _calcRewardWithViewSimpleAmount(uint256 curBlock, address _user)
        internal
        view
        returns (uint256)
    {
        PoolInfo storage pool = mPoolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.amount;
        if (curBlock > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = curBlock.sub(
                pool.lastRewardBlock,
                "cr curBlock sub overflow"
            );
            uint256 curReward = multiplier.mul(rewardPerBlock);
            accRewardPerShare = accRewardPerShare.add(
                curReward.mul(1e20).div(lpSupply)
            );
        }


        uint256 ssReward;
        uint256 ssAmount;
        uint256 ssRewardDebt;
        (ssReward, ssAmount, ssRewardDebt) = mOldSimpleStaking.getUserInfo(
            _user
        );
        ssAmount = ssAmount.add(user.amount);
        ssRewardDebt = ssRewardDebt.add(user.rewardDebt);
        ssReward = ssReward.add(user.reward);


        uint256 newReward = ssAmount.mul(accRewardPerShare).div(1e20).sub(
            ssRewardDebt,
            "cr newReward sub overflow"
        );
        return newReward.add(ssReward);
    }

    function setTransLock(address target, uint256 locktime) public onlyAdmin {
        require(
            locktime >= now + 2 days,
            "locktime need larger than cur time 2 days"
        );
        mTargetAddress = target;
        mTransLockTime = locktime;

        emit TransLock(mTargetAddress, mTransLockTime);
    }

    function transTokens(uint256 amount) public onlyAdmin {
        require(mTransLockTime > 0, "mTransLockTime not set");
        require(now > mTransLockTime, "Pls wait to unlock time");
        linaToken.transfer(mTargetAddress, amount);
    }
}
