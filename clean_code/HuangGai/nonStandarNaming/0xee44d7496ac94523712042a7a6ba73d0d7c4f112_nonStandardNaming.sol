


pragma solidity ^0.6.12;



abstract contract Context {
    function _MSGSENDER442() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA841() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}


library EnumerableSet {









    struct Set {

        bytes32[] _values;



        mapping (bytes32 => uint256) _indexes;
    }


    function _ADD793(Set storage set, bytes32 value) private returns (bool) {
        if (!_CONTAINS602(set, value)) {
            set._values.push(value);


            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }


    function _REMOVE671(Set storage set, bytes32 value) private returns (bool) {

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


    function _CONTAINS602(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }


    function _LENGTH966(Set storage set) private view returns (uint256) {
        return set._values.length;
    }


    function _AT186(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }



    struct AddressSet {
        Set _inner;
    }


    function ADD955(AddressSet storage set, address value) internal returns (bool) {
        return _ADD793(set._inner, bytes32(uint256(value)));
    }


    function REMOVE612(AddressSet storage set, address value) internal returns (bool) {
        return _REMOVE671(set._inner, bytes32(uint256(value)));
    }


    function CONTAINS582(AddressSet storage set, address value) internal view returns (bool) {
        return _CONTAINS602(set._inner, bytes32(uint256(value)));
    }


    function LENGTH322(AddressSet storage set) internal view returns (uint256) {
        return _LENGTH966(set._inner);
    }


    function AT372(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_AT186(set._inner, index)));
    }




    struct UintSet {
        Set _inner;
    }


    function ADD955(UintSet storage set, uint256 value) internal returns (bool) {
        return _ADD793(set._inner, bytes32(value));
    }


    function REMOVE612(UintSet storage set, uint256 value) internal returns (bool) {
        return _REMOVE671(set._inner, bytes32(value));
    }


    function CONTAINS582(UintSet storage set, uint256 value) internal view returns (bool) {
        return _CONTAINS602(set._inner, bytes32(value));
    }


    function LENGTH322(UintSet storage set) internal view returns (uint256) {
        return _LENGTH966(set._inner);
    }


    function AT372(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_AT186(set._inner, index));
    }
}


library SafeMath {

    function ADD955(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB444(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB444(a, b, "SafeMath: subtraction overflow");
    }


    function SUB444(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL509(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV140(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV140(a, b, "SafeMath: division by zero");
    }


    function DIV140(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD127(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD127(a, b, "SafeMath: modulo by zero");
    }


    function MOD127(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



contract Pausable is Context {

    event PAUSED925(address account);


    event UNPAUSED624(address account);

    bool private _paused;


    constructor () internal {
        _paused = false;
    }


    function PAUSED303() public view returns (bool) {
        return _paused;
    }


    modifier WHENNOTPAUSED156() {
        require(!_paused, "Pausable: paused");
        _;
    }


    modifier WHENPAUSED81() {
        require(_paused, "Pausable: not paused");
        _;
    }


    function _PAUSE21() internal virtual WHENNOTPAUSED156 {
        _paused = true;
        emit PAUSED925(_MSGSENDER442());
    }


    function _UNPAUSE943() internal virtual WHENPAUSED81 {
        _paused = false;
        emit UNPAUSED624(_MSGSENDER442());
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

    bytes32 public constant default_admin_role643 = 0x00;


    event ROLEADMINCHANGED358(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);


    event ROLEGRANTED844(bytes32 indexed role, address indexed account, address indexed sender);


    event ROLEREVOKED840(bytes32 indexed role, address indexed account, address indexed sender);


    function HASROLE566(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.CONTAINS582(account);
    }


    function GETROLEMEMBERCOUNT266(bytes32 role) public view returns (uint256) {
        return _roles[role].members.LENGTH322();
    }


    function GETROLEMEMBER390(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.AT372(index);
    }


    function GETROLEADMIN142(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }


    function GRANTROLE448(bytes32 role, address account) public virtual {
        require(HASROLE566(_roles[role].adminRole, _MSGSENDER442()), "AccessControl: sender must be an admin to grant");

        _GRANTROLE994(role, account);
    }


    function REVOKEROLE161(bytes32 role, address account) public virtual {
        require(HASROLE566(_roles[role].adminRole, _MSGSENDER442()), "AccessControl: sender must be an admin to revoke");

        _REVOKEROLE858(role, account);
    }


    function RENOUNCEROLE414(bytes32 role, address account) public virtual {
        require(account == _MSGSENDER442(), "AccessControl: can only renounce roles for self");

        _REVOKEROLE858(role, account);
    }


    function _SETUPROLE604(bytes32 role, address account) internal virtual {
        _GRANTROLE994(role, account);
    }


    function _SETROLEADMIN339(bytes32 role, bytes32 adminRole) internal virtual {
        emit ROLEADMINCHANGED358(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _GRANTROLE994(bytes32 role, address account) private {
        if (_roles[role].members.ADD955(account)) {
            emit ROLEGRANTED844(role, account, _MSGSENDER442());
        }
    }

    function _REVOKEROLE858(bytes32 role, address account) private {
        if (_roles[role].members.REMOVE612(account)) {
            emit ROLEREVOKED840(role, account, _MSGSENDER442());
        }
    }
}


library Address {

    function ISCONTRACT149(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }


    function SENDVALUE745(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function FUNCTIONCALL287(address target, bytes memory data) internal returns (bytes memory) {
      return FUNCTIONCALL287(target, data, "Address: low-level call failed");
    }


    function FUNCTIONCALL287(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _FUNCTIONCALLWITHVALUE197(target, data, 0, errorMessage);
    }


    function FUNCTIONCALLWITHVALUE757(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return FUNCTIONCALLWITHVALUE757(target, data, value, "Address: low-level call with value failed");
    }


    function FUNCTIONCALLWITHVALUE757(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _FUNCTIONCALLWITHVALUE197(target, data, value, errorMessage);
    }

    function _FUNCTIONCALLWITHVALUE197(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(ISCONTRACT149(target), "Address: call to non-contract");


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

    function NAME653() external view returns (string memory);

    function SYMBOL206() external view returns (string memory);

    function DECIMALS526() external view returns (uint8);

    function TOTALSUPPLY875() external view returns (uint);

    function BALANCEOF638(address owner) external view returns (uint);

    function ALLOWANCE195(address owner, address spender) external view returns (uint);

    function TRANSFER72(address to, uint value) external returns (bool);

    function APPROVE120(address spender, uint value) external returns (bool);

    function TRANSFERFROM500(
        address from,
        address to,
        uint value
    ) external returns (bool);

    event TRANSFER974(address indexed from, address indexed to, uint value);

    event APPROVAL68(address indexed owner, address indexed spender, uint value);
}

contract LnAdmin {
    address public admin;
    address public candidate;

    constructor(address _admin) public {
        require(_admin != address(0), "admin address cannot be 0");
        admin = _admin;
        emit ADMINCHANGED70(address(0), _admin);
    }

    function SETCANDIDATE399(address _candidate) external ONLYADMIN30 {
        address old = candidate;
        candidate = _candidate;
        emit CANDIDATECHANGED218( old, candidate);
    }

    function BECOMEADMIN406( ) external {
        require( msg.sender == candidate, "Only candidate can become admin");
        address old = admin;
        admin = candidate;
        emit ADMINCHANGED70( old, admin );
    }

    modifier ONLYADMIN30 {
        require( (msg.sender == admin), "Only the contract admin can perform this action");
        _;
    }

    event CANDIDATECHANGED218(address oldCandidate, address newCandidate );
    event ADMINCHANGED70(address oldAdmin, address newAdmin);
}


library SafeDecimalMath {
    using SafeMath for uint;

    uint8 public constant decimals39 = 18;
    uint8 public constant highprecisiondecimals272 = 27;

    uint public constant unit739 = 10**uint(decimals39);

    uint public constant precise_unit766 = 10**uint(highprecisiondecimals272);
    uint private constant unit_to_high_precision_conversion_factor241 = 10**uint(highprecisiondecimals272 - decimals39);

    function UNIT5() external pure returns (uint) {
        return unit739;
    }

    function PRECISEUNIT401() external pure returns (uint) {
        return precise_unit766;
    }

    function MULTIPLYDECIMAL731(uint x, uint y) internal pure returns (uint) {

        return x.MUL509(y) / unit739;
    }

    function _MULTIPLYDECIMALROUND367(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {

        uint quotientTimesTen = x.MUL509(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    function MULTIPLYDECIMALROUNDPRECISE456(uint x, uint y) internal pure returns (uint) {
        return _MULTIPLYDECIMALROUND367(x, y, precise_unit766);
    }

    function MULTIPLYDECIMALROUND81(uint x, uint y) internal pure returns (uint) {
        return _MULTIPLYDECIMALROUND367(x, y, unit739);
    }

    function DIVIDEDECIMAL852(uint x, uint y) internal pure returns (uint) {

        return x.MUL509(unit739).DIV140(y);
    }

    function _DIVIDEDECIMALROUND630(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.MUL509(precisionUnit * 10).DIV140(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    function DIVIDEDECIMALROUND74(uint x, uint y) internal pure returns (uint) {
        return _DIVIDEDECIMALROUND630(x, y, unit739);
    }

    function DIVIDEDECIMALROUNDPRECISE587(uint x, uint y) internal pure returns (uint) {
        return _DIVIDEDECIMALROUND630(x, y, precise_unit766);
    }

    function DECIMALTOPRECISEDECIMAL237(uint i) internal pure returns (uint) {
        return i.MUL509(unit_to_high_precision_conversion_factor241);
    }

    function PRECISEDECIMALTODECIMAL159(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (unit_to_high_precision_conversion_factor241 / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}


interface ILinearStaking {
    function STAKING189(uint256 amount) external returns (bool);
    function CANCELSTAKING166(uint256 amount) external returns (bool);
    function CLAIM668() external returns (bool);
    function STAKINGBALANCEOF960(address account) external view returns(uint256);
}

contract LnLinearStakingStorage is LnAdmin {
    using SafeMath for uint256;

    LnAccessControl public accessCtrl;

    bytes32 public constant data_access_role516 = "LinearStakingStorage";

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

    modifier ONLYLINEARSTAKINGSTORAGEROLE421(address _address) {
        require(accessCtrl.HASROLE566(data_access_role516, _address), "Only Linear Staking Storage Role");
        _;
    }

    function SETACCESSCONTROL240(address _accessCtrl) external ONLYADMIN30 {
        accessCtrl = LnAccessControl(_accessCtrl);
    }

    function WEEKTOTALSTAKING870() public view returns (uint256[] memory) {
        uint256[] memory totals = new uint256[](totalWeekNumber);
        for (uint256 i=0; i< totalWeekNumber; i++) {
            uint256 delta = weeksTotal[i];
            if (i == 0) {
                totals[i] = delta;
            } else {

                totals[i] = totals[i-1].ADD955(delta);
            }
        }
        return totals;
    }

    function GETSTAKESDATALENGTH308(address account) external view returns(uint256) {
        return stakesdata[account].length;
    }

    function GETSTAKESDATABYINDEX845(address account, uint256 index) external view returns(uint256, uint256) {
        return (stakesdata[account][index].amount, stakesdata[account][index].staketime);
    }

    function STAKINGBALANCEOF960(address account) external view returns(uint256) {
        uint256 total = 0;
        StakingData[] memory stakes = stakesdata[account];
        for (uint256 i=0; i < stakes.length; i++) {
            total = total.ADD955(stakes[i].amount);
        }
        return total;
    }

    function REQUIREINSTAKINGPERIOD293() external view {
        require(stakingStartTime < block.timestamp, "Staking not start");
        require(block.timestamp < stakingEndTime, "Staking stage has end.");
    }

    function REQUIRESTAKINGEND294() external view {
        require(block.timestamp > stakingEndTime, "Need wait to staking end");
    }

    function PUSHSTAKINGDATA192(address account, uint256 amount, uint256 staketime) external ONLYLINEARSTAKINGSTORAGEROLE421(msg.sender) {
        LnLinearStakingStorage.StakingData memory data = LnLinearStakingStorage.StakingData({
            amount: amount,
            staketime: staketime
        });
        stakesdata[account].push(data);
    }

    function STAKINGDATAADD553(address account, uint256 index, uint256 amount) external ONLYLINEARSTAKINGSTORAGEROLE421(msg.sender) {
        stakesdata[account][index].amount = stakesdata[account][index].amount.ADD955(amount);
    }

    function STAKINGDATASUB735(address account, uint256 index, uint256 amount) external ONLYLINEARSTAKINGSTORAGEROLE421(msg.sender) {
        stakesdata[account][index].amount = stakesdata[account][index].amount.SUB444(amount, "StakingDataSub sub overflow");
    }

    function DELETESTAKESDATA62(address account) external ONLYLINEARSTAKINGSTORAGEROLE421(msg.sender) {
        delete stakesdata[account];
    }

    function POPSTAKESDATA423(address account) external ONLYLINEARSTAKINGSTORAGEROLE421(msg.sender) {
        stakesdata[account].pop();
    }

    function ADDWEEKSTOTAL472(uint256 staketime, uint256 amount) external ONLYLINEARSTAKINGSTORAGEROLE421(msg.sender) {
        uint256 weekNumber = staketime.SUB444(stakingStartTime, "AddWeeksTotal sub overflow") / 1 weeks;
        weeksTotal[weekNumber] = weeksTotal[weekNumber].ADD955(amount);
    }

    function SUBWEEKSTOTAL597(uint256 staketime, uint256 amount) external ONLYLINEARSTAKINGSTORAGEROLE421(msg.sender) {
        uint256 weekNumber = staketime.SUB444(stakingStartTime, "SubWeeksTotal weekNumber sub overflow") / 1 weeks;
        weeksTotal[weekNumber] = weeksTotal[weekNumber].SUB444(amount, "SubWeeksTotal weeksTotal sub overflow");
    }

    function SETWEEKREWARDAMOUNT481(uint256 _weekRewardAmount) external ONLYADMIN30 {
        weekRewardAmount = _weekRewardAmount;
    }

    function SETSTAKINGPERIOD256(uint _stakingStartTime, uint _stakingEndTime) external ONLYADMIN30 {
        require(_stakingEndTime > _stakingStartTime);

        stakingStartTime = _stakingStartTime;
        stakingEndTime = _stakingEndTime;

        totalWeekNumber = stakingEndTime.SUB444(stakingStartTime, "setStakingPeriod totalWeekNumber sub overflow") / 1 weeks;
        if (stakingEndTime.SUB444(stakingStartTime, "setStakingPeriod stakingEndTime sub overflow") % 1 weeks != 0) {
            totalWeekNumber = totalWeekNumber.ADD955(1);
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

    function SETLINATOKEN908(address _linaToken) external ONLYADMIN30 {
        linaToken = IERC20(_linaToken);
    }

    function SETPAUSED644(bool _paused) external ONLYADMIN30 {
        if (_paused) {
            _PAUSE21();
        } else {
            _UNPAUSE943();
        }
    }


    event STAKING625(address indexed who, uint256 value, uint staketime);
    event CANCELSTAKING945(address indexed who, uint256 value);
    event CLAIM827(address indexed who, uint256 rewardval, uint256 totalStaking);

    uint256 public accountStakingListLimit = 50;
    uint256 public minStakingAmount = 1e18;
    uint256 public constant precision_uint99 = 1e23;

    function SETLINATOKENADDRESS568(address _token) external ONLYADMIN30 {
        linaToken = IERC20(_token);
    }

    function SETSTAKINGLISTLIMIT246(uint256 _limit) external ONLYADMIN30 {
        accountStakingListLimit = _limit;
    }

    function SETMINSTAKINGAMOUNT66(uint256 _minStakingAmount) external ONLYADMIN30 {
        minStakingAmount = _minStakingAmount;
    }

    function STAKINGBALANCEOF960(address account) external override view returns(uint256) {
        return stakingStorage.STAKINGBALANCEOF960(account);
    }

    function GETSTAKESDATALENGTH308(address account) external view returns(uint256) {
        return stakingStorage.GETSTAKESDATALENGTH308(account);
    }


    function STAKING189(uint256 amount) public WHENNOTPAUSED156 override returns (bool) {
        stakingStorage.REQUIREINSTAKINGPERIOD293();

        require(amount >= minStakingAmount, "Staking amount too small.");
        require(stakingStorage.GETSTAKESDATALENGTH308(msg.sender) < accountStakingListLimit, "Staking list out of limit.");


        linaToken.TRANSFERFROM500(msg.sender, address(this), amount);

        stakingStorage.PUSHSTAKINGDATA192(msg.sender, amount, block.timestamp);
        stakingStorage.ADDWEEKSTOTAL472(block.timestamp, amount);

        emit STAKING625(msg.sender, amount, block.timestamp);
        return true;
    }

    function CANCELSTAKING166(uint256 amount) public WHENNOTPAUSED156 override returns (bool) {
        stakingStorage.REQUIREINSTAKINGPERIOD293();

        require(amount > 0, "Invalid amount.");

        uint256 returnToken = amount;
        for (uint256 i = stakingStorage.GETSTAKESDATALENGTH308(msg.sender); i >= 1 ; i--) {
            (uint256 stakingAmount, uint256 staketime) = stakingStorage.GETSTAKESDATABYINDEX845(msg.sender, i-1);
            if (amount >= stakingAmount) {
                amount = amount.SUB444(stakingAmount, "cancelStaking sub overflow");

                stakingStorage.POPSTAKESDATA423(msg.sender);
                stakingStorage.SUBWEEKSTOTAL597(staketime, stakingAmount);
            } else {
                stakingStorage.STAKINGDATASUB735(msg.sender, i-1, amount);
                stakingStorage.SUBWEEKSTOTAL597(staketime, amount);

                amount = 0;
            }
            if (amount == 0) break;
        }
        require(amount == 0, "Cancel amount too big then staked.");


        linaToken.TRANSFER72(msg.sender, returnToken);

        emit CANCELSTAKING945(msg.sender, returnToken);

        return true;
    }



    function CLAIM668() public WHENNOTPAUSED156 override returns (bool) {
        stakingStorage.REQUIRESTAKINGEND294();

        require(stakingStorage.GETSTAKESDATALENGTH308(msg.sender) > 0, "Nothing to claim");

        uint256 totalWeekNumber = stakingStorage.totalWeekNumber();

        uint256 totalStaking = 0;
        uint256 totalReward = 0;

        uint256[] memory finalTotals = stakingStorage.WEEKTOTALSTAKING870();
        for (uint256 i=0; i < stakingStorage.GETSTAKESDATALENGTH308(msg.sender); i++) {
            (uint256 stakingAmount, uint256 staketime) = stakingStorage.GETSTAKESDATABYINDEX845(msg.sender, i);
            uint256 stakedWeedNumber = staketime.SUB444(stakingStorage.stakingStartTime(), "claim sub overflow") / 1 weeks;

            totalStaking = totalStaking.ADD955(stakingAmount);

            uint256 reward = 0;
            for (uint256 j=stakedWeedNumber; j < totalWeekNumber; j++) {
                reward = reward.ADD955( stakingAmount.MUL509(precision_uint99).DIV140(finalTotals[j]) );
            }
            reward = reward.MUL509(stakingStorage.weekRewardAmount()).DIV140(precision_uint99);

            totalReward = totalReward.ADD955( reward );
        }

        stakingStorage.DELETESTAKESDATA62(msg.sender);


        linaToken.TRANSFER72(msg.sender, totalStaking.ADD955(totalReward) );

        emit CLAIM827(msg.sender, totalReward, totalStaking);
        return true;
    }
}







contract LnAccessControl is AccessControl {
    using Address for address;



    bytes32 public constant issue_asset_role354 = ("ISSUE_ASSET");
    bytes32 public constant burn_asset_role864 = ("BURN_ASSET");

    bytes32 public constant debt_system916 = ("LnDebtSystem");

    constructor(address admin) public {
        _SETUPROLE604(default_admin_role643, admin);
    }

    function ISADMIN537(address _address) public view returns (bool) {
        return HASROLE566(default_admin_role643, _address);
    }

    function SETADMIN420(address _address) public returns (bool) {
        require(ISADMIN537(msg.sender), "Only admin");

        _SETUPROLE604(default_admin_role643, _address);
    }



    function SETROLES11(bytes32 roleType, address[] calldata addresses, bool[] calldata setTo) external {
        require(ISADMIN537(msg.sender), "Only admin");

        _SETROLES348(roleType, addresses, setTo);
    }

    function _SETROLES348(bytes32 roleType, address[] calldata addresses, bool[] calldata setTo) private {
        require(addresses.length == setTo.length, "parameter address length not eq");

        for (uint256 i=0; i < addresses.length; i++) {

            if (setTo[i]) {
                GRANTROLE448(roleType, addresses[i]);
            } else {
                REVOKEROLE161(roleType, addresses[i]);
            }
        }
    }






    function SETISSUEASSETROLE734(address[] calldata issuer, bool[] calldata setTo) public {
        _SETROLES348(issue_asset_role354, issuer, setTo);
    }

    function SETBURNASSETROLE582(address[] calldata burner, bool[] calldata setTo) public {
        _SETROLES348(burn_asset_role864, burner, setTo);
    }


    function SETDEBTSYSTEMROLE518(address[] calldata _address, bool[] calldata _setTo) public {
        _SETROLES348(debt_system916, _address, _setTo);
    }
}


abstract contract LnOperatorModifier is LnAdmin {

    address public operator;

    constructor(address _operator) internal {
        require(admin != address(0), "admin must be set");

        operator = _operator;
        emit OPERATORUPDATED731(_operator);
    }

    function SETOPERATOR821(address _opperator) external ONLYADMIN30 {
        operator = _opperator;
        emit OPERATORUPDATED731(_opperator);
    }

    modifier ONLYOPERATOR997() {
        require(msg.sender == operator, "Only operator can perform this action");
        _;
    }

    event OPERATORUPDATED731(address operator);
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

    function _CALCREWARD319(uint256 curBlock, address _user)
        internal
        view
        returns (uint256)
    {
        PoolInfo storage pool = mPoolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.amount;
        if (curBlock > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = curBlock.SUB444(
                pool.lastRewardBlock,
                "cr curBlock sub overflow"
            );
            uint256 curReward = multiplier.MUL509(rewardPerBlock);
            accRewardPerShare = accRewardPerShare.ADD955(
                curReward.MUL509(1e20).DIV140(lpSupply)
            );
        }
        uint256 newReward = user.amount.MUL509(accRewardPerShare).DIV140(1e20).SUB444(
            user.rewardDebt,
            "cr newReward sub overflow"
        );
        return newReward.ADD955(user.reward);
    }

    function REWARDOF391(address _user) public view returns (uint256) {
        return userInfo[_user].reward;
    }

    function AMOUNT622() public view returns (uint256) {
        return mPoolInfo.amount;
    }

    function AMOUNTOF525(address _user) public view returns (uint256) {
        return userInfo[_user].amount;
    }

    function GETUSERINFO565(address _user)
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

    function GETPOOLINFO789()
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

    function _UPDATE589(uint256 curBlock) internal {
        PoolInfo storage pool = mPoolInfo;
        if (curBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.amount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = curBlock;
            return;
        }
        uint256 multiplier = curBlock.SUB444(
            pool.lastRewardBlock,
            "_update curBlock sub overflow"
        );
        uint256 curReward = multiplier.MUL509(rewardPerBlock);

        remainReward = remainReward.ADD955(curReward);
        accReward = accReward.ADD955(curReward);

        pool.accRewardPerShare = pool.accRewardPerShare.ADD955(
            curReward.MUL509(1e20).DIV140(lpSupply)
        );
        pool.lastRewardBlock = curBlock;
    }

    function _DEPOSIT6(
        uint256 curBlock,
        address _addr,
        uint256 _amount
    ) internal {
        PoolInfo storage pool = mPoolInfo;
        UserInfo storage user = userInfo[_addr];
        _UPDATE589(curBlock);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .MUL509(pool.accRewardPerShare)
                .DIV140(1e20)
                .SUB444(user.rewardDebt, "_deposit pending sub overflow");
            if (pending > 0) {
                REWARD327(user, pending);
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.ADD955(_amount);
            pool.amount = pool.amount.ADD955(_amount);
        }
        user.rewardDebt = user.amount.MUL509(pool.accRewardPerShare).DIV140(1e20);
    }

    function _WITHDRAW71(
        uint256 curBlock,
        address _addr,
        uint256 _amount
    ) internal {
        PoolInfo storage pool = mPoolInfo;
        UserInfo storage user = userInfo[_addr];
        require(user.amount >= _amount, "_withdraw: not good");
        _UPDATE589(curBlock);
        uint256 pending = user.amount.MUL509(pool.accRewardPerShare).DIV140(1e20).SUB444(
            user.rewardDebt,
            "_withdraw pending sub overflow"
        );
        if (pending > 0) {
            REWARD327(user, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.SUB444(
                _amount,
                "_withdraw user.amount sub overflow"
            );
            pool.amount = pool.amount.SUB444(
                _amount,
                "_withdraw pool.amount sub overflow"
            );
        }
        user.rewardDebt = user.amount.MUL509(pool.accRewardPerShare).DIV140(1e20);
    }

    function REWARD327(UserInfo storage user, uint256 _amount) internal {
        if (_amount > remainReward) {
            _amount = remainReward;
        }
        remainReward = remainReward.SUB444(
            _amount,
            "reward remainReward sub overflow"
        );
        user.reward = user.reward.ADD955(_amount);
    }

    function _CLAIM850(address _addr) internal {
        UserInfo storage user = userInfo[_addr];
        if (user.reward > 0) {
            user.reward = 0;
        }
    }
}

contract LnRewardCalculatorTest is LnRewardCalculator {
    constructor(uint256 _rewardPerBlock, uint256 _startBlock)
        public
        LnRewardCalculator(_rewardPerBlock, _startBlock)
    {}

    function DEPOSIT888(
        uint256 curBlock,
        address _addr,
        uint256 _amount
    ) public {
        _DEPOSIT6(curBlock, _addr, _amount);
    }

    function WITHDRAW713(
        uint256 curBlock,
        address _addr,
        uint256 _amount
    ) public {
        _WITHDRAW71(curBlock, _addr, _amount);
    }

    function CALCREWARD808(uint256 curBlock, address _user)
        public
        view
        returns (uint256)
    {
        return _CALCREWARD319(curBlock, _user);
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

    function SETLINATOKEN908(address _linaToken) external ONLYADMIN30 {
        linaToken = IERC20(_linaToken);
    }

    function SETPAUSED644(bool _paused) external ONLYADMIN30 {
        if (_paused) {
            _PAUSE21();
        } else {
            _UNPAUSE943();
        }
    }


    event STAKING625(address indexed who, uint256 value, uint256 staketime);
    event CANCELSTAKING945(address indexed who, uint256 value);
    event CLAIM827(address indexed who, uint256 rewardval, uint256 totalStaking);
    event TRANSLOCK726(address target, uint256 time);

    uint256 public accountStakingListLimit = 50;
    uint256 public minStakingAmount = 1e18;
    uint256 public constant precision_uint99 = 1e23;

    function SETSTAKINGLISTLIMIT246(uint256 _limit) external ONLYADMIN30 {
        accountStakingListLimit = _limit;
    }

    function SETMINSTAKINGAMOUNT66(uint256 _minStakingAmount) external ONLYADMIN30 {
        minStakingAmount = _minStakingAmount;
    }

    function STAKINGBALANCEOF960(address account)
        external
        override
        view
        returns (uint256)
    {
        uint256 stakingBalance = super.AMOUNTOF525(account).ADD955(
            stakingStorage.STAKINGBALANCEOF960(account)
        );
        return stakingBalance;
    }

    function GETSTAKESDATALENGTH308(address account)
        external
        view
        returns (uint256)
    {
        return stakingStorage.GETSTAKESDATALENGTH308(account);
    }



    function MIGRATIONSOLDSTAKING766(
        address contractAddr,
        uint256 amount,
        uint256 blockNb
    ) public ONLYADMIN30 {
        super._DEPOSIT6(blockNb, contractAddr, amount);
        mOldStaking = contractAddr;
        mOldAmount = amount;
    }

    function STAKING189(uint256 amount)
        public
        override
        WHENNOTPAUSED156
        returns (bool)
    {
        stakingStorage.REQUIREINSTAKINGPERIOD293();

        require(amount >= minStakingAmount, "Staking amount too small.");


        linaToken.TRANSFERFROM500(msg.sender, address(this), amount);

        uint256 blockNb = block.number;
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }
        super._DEPOSIT6(blockNb, msg.sender, amount);

        emit STAKING625(msg.sender, amount, block.timestamp);

        return true;
    }

    function _WIDTHDRAWFROMOLDSTAKING790(address _addr, uint256 amount) internal {
        uint256 blockNb = block.number;
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }

        uint256 oldStakingAmount = super.AMOUNTOF525(mOldStaking);
        super._WITHDRAW71(blockNb, mOldStaking, amount);

        uint256 reward = super
            .REWARDOF391(mOldStaking)
            .SUB444(
            mWidthdrawRewardFromOldStaking,
            "_widthdrawFromOldStaking reward sub overflow"
        )
            .MUL509(amount)
            .MUL509(1e20)
            .DIV140(oldStakingAmount)
            .DIV140(1e20);
        mWidthdrawRewardFromOldStaking = mWidthdrawRewardFromOldStaking.ADD955(
            reward
        );
        mOldReward[_addr] = mOldReward[_addr].ADD955(reward);
    }

    function _CANCELSTAKING147(address user, uint256 amount) internal {
        uint256 blockNb = block.number;
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }

        uint256 returnAmount = amount;
        uint256 newAmount = super.AMOUNTOF525(user);
        if (newAmount >= amount) {
            super._WITHDRAW71(blockNb, user, amount);
            amount = 0;
        } else {
            if (newAmount > 0) {
                super._WITHDRAW71(blockNb, user, newAmount);
                amount = amount.SUB444(
                    newAmount,
                    "_cancelStaking amount sub overflow"
                );
            }

            for (
                uint256 i = stakingStorage.GETSTAKESDATALENGTH308(user);
                i >= 1;
                i--
            ) {
                (uint256 stakingAmount, uint256 staketime) = stakingStorage
                    .GETSTAKESDATABYINDEX845(user, i - 1);
                if (amount >= stakingAmount) {
                    amount = amount.SUB444(
                        stakingAmount,
                        "_cancelStaking amount sub overflow"
                    );

                    stakingStorage.POPSTAKESDATA423(user);
                    stakingStorage.SUBWEEKSTOTAL597(staketime, stakingAmount);
                    _WIDTHDRAWFROMOLDSTAKING790(user, stakingAmount);
                } else {
                    stakingStorage.STAKINGDATASUB735(user, i - 1, amount);
                    stakingStorage.SUBWEEKSTOTAL597(staketime, amount);
                    _WIDTHDRAWFROMOLDSTAKING790(user, amount);

                    amount = 0;
                }
                if (amount == 0) break;
            }
        }




        linaToken.TRANSFER72(msg.sender, returnAmount.SUB444(amount));
    }

    function CANCELSTAKING166(uint256 amount)
        public
        override
        WHENNOTPAUSED156
        returns (bool)
    {


        require(amount > 0, "Invalid amount.");

        _CANCELSTAKING147(msg.sender, amount);

        emit CANCELSTAKING945(msg.sender, amount);

        return true;
    }

    function GETTOTALREWARD238(uint256 blockNb, address _user)
        public
        view
        returns (uint256 total)
    {
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }





        total = mOldReward[_user];
        uint256 iMyOldStaking = 0;
        for (
            uint256 i = 0;
            i < stakingStorage.GETSTAKESDATALENGTH308(_user);
            i++
        ) {
            (uint256 stakingAmount, ) = stakingStorage.GETSTAKESDATABYINDEX845(
                _user,
                i
            );
            iMyOldStaking = iMyOldStaking.ADD955(stakingAmount);
        }
        if (iMyOldStaking > 0) {
            uint256 oldStakingAmount = super.AMOUNTOF525(mOldStaking);
            uint256 iReward2 = super
                ._CALCREWARD319(blockNb, mOldStaking)
                .SUB444(
                mWidthdrawRewardFromOldStaking,
                "getTotalReward iReward2 sub overflow"
            )
                .MUL509(iMyOldStaking)
                .DIV140(oldStakingAmount);
            total = total.ADD955(iReward2);
        }

        uint256 reward3 = super._CALCREWARD319(blockNb, _user);
        total = total.ADD955(reward3);
    }



    function CLAIM668() public override WHENNOTPAUSED156 returns (bool) {

        require(
            block.timestamp > claimRewardLockTime,
            "Not time to claim reward"
        );

        uint256 iMyOldStaking = stakingStorage.STAKINGBALANCEOF960(msg.sender);
        uint256 iAmount = super.AMOUNTOF525(msg.sender);
        _CANCELSTAKING147(msg.sender, iMyOldStaking.ADD955(iAmount));

        uint256 iReward = GETTOTALREWARD238(mEndBlock, msg.sender);

        _CLAIM850(msg.sender);
        mOldReward[msg.sender] = 0;
        linaToken.TRANSFER72(msg.sender, iReward);

        emit CLAIM827(msg.sender, iReward, iMyOldStaking.ADD955(iAmount));
        return true;
    }

    function SETREWARDLOCKTIME580(uint256 newtime) public ONLYADMIN30 {
        claimRewardLockTime = newtime;
    }

    function CALCREWARD808(uint256 curBlock, address _user)
        public
        view
        returns (uint256)
    {
        return _CALCREWARD319(curBlock, _user);
    }

    function SETTRANSLOCK553(address target, uint256 locktime) public ONLYADMIN30 {
        require(
            locktime >= now + 2 days,
            "locktime need larger than cur time 2 days"
        );
        mTargetAddress = target;
        mTransLockTime = locktime;

        emit TRANSLOCK726(mTargetAddress, mTransLockTime);
    }

    function TRANSTOKENS575(uint256 amount) public ONLYADMIN30 {
        require(mTransLockTime > 0, "mTransLockTime not set");
        require(now > mTransLockTime, "Pls wait to unlock time");
        linaToken.TRANSFER72(mTargetAddress, amount);
    }
}

contract HelperPushStakingData is LnAdmin {
    constructor(address _admin) public LnAdmin(_admin) {}

    function PUSHSTAKINGDATA192(
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
            stakingStorage.PUSHSTAKINGDATA192(account[i], amount[i], staketime[i]);
            stakingStorage.ADDWEEKSTOTAL472(staketime[i], amount[i]);
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

    function BECOMEADMIN406(address target) external {
        LnAdmin(target).BECOMEADMIN406();
    }

    function SETTRANSLOCK553(
        address target,
        uint256 locktime,
        uint256 amount
    ) public {
        require(mAdmins[msg.sender] == 1, "not in admin list or set state");
        _RESET370();
        mStaking.SETTRANSLOCK553(target, locktime);
        mAmount = amount;
        mProposalNumb = 1;
        mAdmins[msg.sender] = 2;

        mTransLockTime = locktime;
    }


    function CONFIRMTRANSFER169() public {
        require(mAdmins[msg.sender] == 1, "not in admin list or set state");
        mProposalNumb = mProposalNumb + 1;
        mAdmins[msg.sender] = 2;
    }

    function DOTRANSFER874() public {
        require(mTransLockTime > 0, "mTransLockTime not set");
        require(now > mTransLockTime, "Pls wait to unlock time");
        require(mProposalNumb >= mConfirmNumb, "need more confirm");

        _RESET370();
        mStaking.TRANSTOKENS575(mAmount);
    }

    function _RESET370() internal {
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
        if (_mOldSimpleStaking != address(0)) {
            mOldSimpleStaking = LnSimpleStaking(_mOldSimpleStaking);
            (
                mPoolInfo.amount,
                ,
                mPoolInfo.accRewardPerShare
            ) = mOldSimpleStaking.GETPOOLINFO789();
            requireSync = true;
        }
    }

    function SETLINATOKEN908(address _linaToken) external ONLYADMIN30 {
        linaToken = IERC20(_linaToken);
    }

    function SETPAUSED644(bool _paused) external ONLYADMIN30 {
        if (_paused) {
            _PAUSE21();
        } else {
            _UNPAUSE943();
        }
    }


    event STAKING625(address indexed who, uint256 value, uint256 staketime);
    event CANCELSTAKING945(address indexed who, uint256 value);
    event CLAIM827(address indexed who, uint256 rewardval, uint256 totalStaking);
    event TRANSLOCK726(address target, uint256 time);

    uint256 public accountStakingListLimit = 50;
    uint256 public minStakingAmount = 1e18;
    uint256 public constant precision_uint99 = 1e23;

    function SETSTAKINGLISTLIMIT246(uint256 _limit) external ONLYADMIN30 {
        accountStakingListLimit = _limit;
    }

    function SETMINSTAKINGAMOUNT66(uint256 _minStakingAmount) external ONLYADMIN30 {
        minStakingAmount = _minStakingAmount;
    }

    function STAKINGBALANCEOF960(address account)
        external
        override
        view
        returns (uint256)
    {
        uint256 stakingBalance = super.AMOUNTOF525(account).ADD955(
            stakingStorage.STAKINGBALANCEOF960(account)
        );
        return stakingBalance;
    }

    function GETSTAKESDATALENGTH308(address account)
        external
        view
        returns (uint256)
    {
        return stakingStorage.GETSTAKESDATALENGTH308(account);
    }

    function SETENDBLOCK987(uint256 _newEndBlock) external ONLYADMIN30 {
        require(
            _newEndBlock > mEndBlock,
            "new endBlock less than old endBlock."
        );
        mEndBlock = _newEndBlock;
    }











    function SYNCUSERINFODATA21(address _user) internal {
        if (requireSync && !syncUserInfo[_user]) {
            (
                userInfo[_user].reward,
                userInfo[_user].amount,
                userInfo[_user].rewardDebt
            ) = mOldSimpleStaking.GETUSERINFO565(_user);
            syncUserInfo[_user] = true;
        }
    }



    function MIGRATIONSOLDSTAKING766(
        address contractAddr,
        uint256 amount,
        uint256 blockNb
    ) public ONLYADMIN30 {
        super._DEPOSIT6(blockNb, contractAddr, amount);
        mOldStaking = contractAddr;
        mOldAmount = amount;
    }

    function STAKING189(uint256 amount)
        public
        override
        WHENNOTPAUSED156
        returns (bool)
    {






        if (!syncUserInfo[msg.sender]) {
            SYNCUSERINFODATA21(msg.sender);
        }

        require(amount >= minStakingAmount, "Staking amount too small.");


        linaToken.TRANSFERFROM500(msg.sender, address(this), amount);

        uint256 blockNb = block.number;
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }
        super._DEPOSIT6(blockNb, msg.sender, amount);

        emit STAKING625(msg.sender, amount, block.timestamp);

        return true;
    }

    function _WIDTHDRAWFROMOLDSTAKING790(address _addr, uint256 amount) internal {
        uint256 blockNb = block.number;
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }

        uint256 oldStakingAmount = super.AMOUNTOF525(mOldStaking);
        super._WITHDRAW71(blockNb, mOldStaking, amount);

        uint256 reward = super
            .REWARDOF391(mOldStaking)
            .SUB444(
            mWidthdrawRewardFromOldStaking,
            "_widthdrawFromOldStaking reward sub overflow"
        )
            .MUL509(amount)
            .MUL509(1e20)
            .DIV140(oldStakingAmount)
            .DIV140(1e20);
        mWidthdrawRewardFromOldStaking = mWidthdrawRewardFromOldStaking.ADD955(
            reward
        );
        mOldReward[_addr] = mOldReward[_addr].ADD955(reward);
    }

    function _CANCELSTAKING147(address user, uint256 amount) internal {
        uint256 blockNb = block.number;
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }

        uint256 returnAmount = amount;
        uint256 newAmount = super.AMOUNTOF525(user);
        if (newAmount >= amount) {
            super._WITHDRAW71(blockNb, user, amount);
            amount = 0;
        } else {
            if (newAmount > 0) {
                super._WITHDRAW71(blockNb, user, newAmount);
                amount = amount.SUB444(
                    newAmount,
                    "_cancelStaking amount sub overflow"
                );
            }

            for (
                uint256 i = stakingStorage.GETSTAKESDATALENGTH308(user);
                i >= 1;
                i--
            ) {
                (uint256 stakingAmount, uint256 staketime) = stakingStorage
                    .GETSTAKESDATABYINDEX845(user, i - 1);
                if (amount >= stakingAmount) {
                    amount = amount.SUB444(
                        stakingAmount,
                        "_cancelStaking amount sub overflow"
                    );

                    stakingStorage.POPSTAKESDATA423(user);
                    stakingStorage.SUBWEEKSTOTAL597(staketime, stakingAmount);
                    _WIDTHDRAWFROMOLDSTAKING790(user, stakingAmount);
                } else {
                    stakingStorage.STAKINGDATASUB735(user, i - 1, amount);
                    stakingStorage.SUBWEEKSTOTAL597(staketime, amount);
                    _WIDTHDRAWFROMOLDSTAKING790(user, amount);

                    amount = 0;
                }
                if (amount == 0) break;
            }
        }




        linaToken.TRANSFER72(msg.sender, returnAmount.SUB444(amount));
    }

    function CANCELSTAKING166(uint256 amount)
        public
        override
        WHENNOTPAUSED156
        returns (bool)
    {





        if (!syncUserInfo[msg.sender]) {
            SYNCUSERINFODATA21(msg.sender);
        }


        require(amount > 0, "Invalid amount.");

        _CANCELSTAKING147(msg.sender, amount);

        emit CANCELSTAKING945(msg.sender, amount);

        return true;
    }

    function GETTOTALREWARD238(uint256 blockNb, address _user)
        public
        view
        returns (uint256 total)
    {
        if (blockNb > mEndBlock) {
            blockNb = mEndBlock;
        }





        total = mOldReward[_user];


        uint256 simpleStakingReward = 0;
        if (!syncUserInfo[msg.sender]) {
            (simpleStakingReward, ,) = mOldSimpleStaking.GETUSERINFO565(_user);
        }
        total = total.ADD955(simpleStakingReward);

        uint256 iMyOldStaking = 0;
        for (
            uint256 i = 0;
            i < stakingStorage.GETSTAKESDATALENGTH308(_user);
            i++
        ) {
            (uint256 stakingAmount, ) = stakingStorage.GETSTAKESDATABYINDEX845(
                _user,
                i
            );
            iMyOldStaking = iMyOldStaking.ADD955(stakingAmount);
        }
        if (iMyOldStaking > 0) {
            uint256 oldStakingAmount = super.AMOUNTOF525(mOldStaking);
            uint256 iReward2 = super
                ._CALCREWARD319(blockNb, mOldStaking)
                .SUB444(
                mWidthdrawRewardFromOldStaking,
                "getTotalReward iReward2 sub overflow"
            )
                .MUL509(iMyOldStaking)
                .DIV140(oldStakingAmount);
            total = total.ADD955(iReward2);
        }

        uint256 reward3 = super._CALCREWARD319(blockNb, _user);
        total = total.ADD955(reward3);
    }



    function CLAIM668() public override WHENNOTPAUSED156 returns (bool) {






        if (!syncUserInfo[msg.sender]) {
            SYNCUSERINFODATA21(msg.sender);
        }

        require(
            block.timestamp > claimRewardLockTime,
            "Not time to claim reward"
        );

        uint256 iMyOldStaking = stakingStorage.STAKINGBALANCEOF960(msg.sender);
        uint256 iAmount = super.AMOUNTOF525(msg.sender);
        _CANCELSTAKING147(msg.sender, iMyOldStaking.ADD955(iAmount));

        uint256 iReward = GETTOTALREWARD238(mEndBlock, msg.sender);

        _CLAIM850(msg.sender);
        mOldReward[msg.sender] = 0;
        linaToken.TRANSFER72(msg.sender, iReward);

        emit CLAIM827(msg.sender, iReward, iMyOldStaking.ADD955(iAmount));
        return true;
    }

    function SETREWARDLOCKTIME580(uint256 newtime) public ONLYADMIN30 {
        claimRewardLockTime = newtime;
    }

    function CALCREWARD808(uint256 curBlock, address _user)
        public
        view
        returns (uint256)
    {
        return _CALCREWARDWITHVIEWSIMPLEAMOUNT431(curBlock, _user);
    }


    function _CALCREWARDWITHVIEWSIMPLEAMOUNT431(uint256 curBlock, address _user)
        internal
        view
        returns (uint256)
    {
        PoolInfo storage pool = mPoolInfo;
        UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.amount;
        if (curBlock > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = curBlock.SUB444(
                pool.lastRewardBlock,
                "cr curBlock sub overflow"
            );
            uint256 curReward = multiplier.MUL509(rewardPerBlock);
            accRewardPerShare = accRewardPerShare.ADD955(
                curReward.MUL509(1e20).DIV140(lpSupply)
            );
        }


        uint256 ssReward;
        uint256 ssAmount;
        uint256 ssRewardDebt;
        (
            ssReward,
            ssAmount,
            ssRewardDebt
        ) = mOldSimpleStaking.GETUSERINFO565(_user);
        ssAmount = ssAmount.ADD955(user.amount);
        ssRewardDebt = ssRewardDebt.ADD955(user.rewardDebt);
        ssReward = ssReward.ADD955(user.reward);


        uint256 newReward = ssAmount
            .MUL509(accRewardPerShare)
            .DIV140(1e20)
            .SUB444(ssRewardDebt, "cr newReward sub overflow");
        return newReward.ADD955(ssReward);
    }

    function SETTRANSLOCK553(address target, uint256 locktime) public ONLYADMIN30 {
        require(
            locktime >= now + 2 days,
            "locktime need larger than cur time 2 days"
        );
        mTargetAddress = target;
        mTransLockTime = locktime;

        emit TRANSLOCK726(mTargetAddress, mTransLockTime);
    }

    function TRANSTOKENS575(uint256 amount) public ONLYADMIN30 {
        require(mTransLockTime > 0, "mTransLockTime not set");
        require(now > mTransLockTime, "Pls wait to unlock time");
        linaToken.TRANSFER72(mTargetAddress, amount);
    }
}
