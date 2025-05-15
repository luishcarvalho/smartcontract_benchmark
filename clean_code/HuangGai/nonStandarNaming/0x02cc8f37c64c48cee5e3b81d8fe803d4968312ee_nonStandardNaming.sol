



pragma solidity 0.5.16;


library Math {

    function MAX818(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }


    function MIN910(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }


    function AVERAGE710(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}



pragma solidity 0.5.16;


library SafeMath {

    function ADD553(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB354(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB354(a, b, "SafeMath: subtraction overflow");
    }


    function SUB354(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL618(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV720(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV720(a, b, "SafeMath: division by zero");
    }


    function DIV720(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD811(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD811(a, b, "SafeMath: modulo by zero");
    }


    function MOD811(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



pragma solidity 0.5.16;


contract Context {


    constructor () internal { }


    function _MSGSENDER101() internal view returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA729() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}



pragma solidity 0.5.16;


contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED297(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = _MSGSENDER101();
        emit OWNERSHIPTRANSFERRED297(address(0), _owner);
    }


    function OWNER579() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER471() {
        require(ISOWNER602(), "Ownable: caller is not the owner");
        _;
    }


    function ISOWNER602() public view returns (bool) {
        return _MSGSENDER101() == _owner;
    }


    function RENOUNCEOWNERSHIP987() public ONLYOWNER471 {
        emit OWNERSHIPTRANSFERRED297(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP49(address newOwner) public ONLYOWNER471 {
        _TRANSFEROWNERSHIP728(newOwner);
    }


    function _TRANSFEROWNERSHIP728(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED297(_owner, newOwner);
        _owner = newOwner;
    }
}



pragma solidity 0.5.16;


interface IERC20 {

    function TOTALSUPPLY250() external view returns (uint256);


    function BALANCEOF938(address account) external view returns (uint256);


    function TRANSFER79(address recipient, uint256 amount) external returns (bool);
    function MINT2(address account, uint amount) external;


    function ALLOWANCE644(address owner, address spender) external view returns (uint256);


    function APPROVE576(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM482(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER160(address indexed from, address indexed to, uint256 value);


    event APPROVAL369(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity 0.5.16;


library Address {

    function ISCONTRACT625(address account) internal view returns (bool) {







        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }


    function TOPAYABLE310(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }


    function SENDVALUE700(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}



pragma solidity 0.5.16;





library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER546(IERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN509(token, abi.encodeWithSelector(token.TRANSFER79.selector, to, value));
    }

    function SAFETRANSFERFROM6(IERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN509(token, abi.encodeWithSelector(token.TRANSFERFROM482.selector, from, to, value));
    }

    function SAFEAPPROVE811(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.ALLOWANCE644(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN509(token, abi.encodeWithSelector(token.APPROVE576.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE917(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE644(address(this), spender).ADD553(value);
        CALLOPTIONALRETURN509(token, abi.encodeWithSelector(token.APPROVE576.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE400(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE644(address(this), spender).SUB354(value, "SafeERC20: decreased allowance below zero");
        CALLOPTIONALRETURN509(token, abi.encodeWithSelector(token.APPROVE576.selector, spender, newAllowance));
    }


    function CALLOPTIONALRETURN509(IERC20 token, bytes memory data) private {








        require(address(token).ISCONTRACT625(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


pragma solidity 0.5.16;

contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function NOTIFYREWARDAMOUNT190(uint256 reward) external;

    modifier ONLYREWARDDISTRIBUTION587() {
        require(_MSGSENDER101() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function SETREWARDDISTRIBUTION306(address _rewardDistribution)
        external
        ONLYOWNER471
    {
        rewardDistribution = _rewardDistribution;
    }
}


pragma solidity 0.5.16;

contract GOFTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakeToken = IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function TOTALSUPPLY250() public view returns (uint256) {
        return _totalSupply;
    }

    function BALANCEOF938(address account) public view returns (uint256) {
        return _balances[account];
    }

    function STAKE102(uint256 amount) public {
        _totalSupply = _totalSupply.ADD553(amount);
        _balances[msg.sender] = _balances[msg.sender].ADD553(amount);
        stakeToken.SAFETRANSFERFROM6(msg.sender, address(this), amount);
    }

    function WITHDRAW201(uint256 amount) public {
        _totalSupply = _totalSupply.SUB354(amount);
        _balances[msg.sender] = _balances[msg.sender].SUB354(amount);
        stakeToken.SAFETRANSFER546(msg.sender, amount);
    }
}


pragma solidity 0.5.16;

contract GOFLINKPool is GOFTokenWrapper, IRewardDistributionRecipient {
    IERC20 public gof = IERC20(0x488E0369f9BC5C40C002eA7c1fe4fd01A198801c);
    uint256 public constant duration144 = 7 days;

    uint256 public constant starttime308 = 1599652800;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored  = 0;
    bool private open = true;
    uint256 private constant _gunit942 = 1e18;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event REWARDADDED578(uint256 reward);
    event STAKED569(address indexed user, uint256 amount);
    event WITHDRAWN869(address indexed user, uint256 amount);
    event REWARDPAID604(address indexed user, uint256 reward);
    event SETOPEN70(bool _open);

    modifier UPDATEREWARD304(address account) {
        rewardPerTokenStored = REWARDPERTOKEN70();
        lastUpdateTime = LASTTIMEREWARDAPPLICABLE508();
        if (account != address(0)) {
            rewards[account] = EARNED147(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function LASTTIMEREWARDAPPLICABLE508() public view returns (uint256) {
        return Math.MIN910(block.timestamp, periodFinish);
    }


    function REWARDPERTOKEN70() public view returns (uint256) {
        if (TOTALSUPPLY250() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.ADD553(
                LASTTIMEREWARDAPPLICABLE508()
                    .SUB354(lastUpdateTime)
                    .MUL618(rewardRate)
                    .MUL618(_gunit942)
                    .DIV720(TOTALSUPPLY250())
            );
    }

    function EARNED147(address account) public view returns (uint256) {
        return
            BALANCEOF938(account)
                .MUL618(REWARDPERTOKEN70().SUB354(userRewardPerTokenPaid[account]))
                .DIV720(_gunit942)
                .ADD553(rewards[account]);
    }

    function STAKE102(uint256 amount) public CHECKOPEN514 CHECKSTART795 UPDATEREWARD304(msg.sender){
        require(amount > 0, "Golff-Link-POOL: Cannot stake 0");
        super.STAKE102(amount);
        emit STAKED569(msg.sender, amount);
    }

    function WITHDRAW201(uint256 amount) public CHECKSTART795 UPDATEREWARD304(msg.sender){
        require(amount > 0, "Golff-Link-POOL: Cannot withdraw 0");
        super.WITHDRAW201(amount);
        emit WITHDRAWN869(msg.sender, amount);
    }

    function EXIT662() external {
        WITHDRAW201(BALANCEOF938(msg.sender));
        GETREWARD668();
    }

    function GETREWARD668() public CHECKSTART795 UPDATEREWARD304(msg.sender){
        uint256 reward = EARNED147(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            gof.SAFETRANSFER546(msg.sender, reward);
            emit REWARDPAID604(msg.sender, reward);
        }
    }

    modifier CHECKSTART795(){
        require(block.timestamp > starttime308,"Golff-Link-POOL: Not start");
        _;
    }

    modifier CHECKOPEN514() {
        require(open, "Golff-Link-POOL: Pool is closed");
        _;
    }

    function GETPERIODFINISH470() external view returns (uint256) {
        return periodFinish;
    }

    function ISOPEN95() external view returns (bool) {
        return open;
    }

    function SETOPEN315(bool _open) external ONLYOWNER471 {
        open = _open;
        emit SETOPEN70(_open);
    }

    function NOTIFYREWARDAMOUNT190(uint256 reward)
        external
        ONLYREWARDDISTRIBUTION587
        CHECKOPEN514
        UPDATEREWARD304(address(0)){
        if (block.timestamp > starttime308){
            if (block.timestamp >= periodFinish) {
                uint256 period = block.timestamp.SUB354(starttime308).DIV720(duration144).ADD553(1);
                periodFinish = starttime308.ADD553(period.MUL618(duration144));
                rewardRate = reward.DIV720(periodFinish.SUB354(block.timestamp));
            } else {
                uint256 remaining = periodFinish.SUB354(block.timestamp);
                uint256 leftover = remaining.MUL618(rewardRate);
                rewardRate = reward.ADD553(leftover).DIV720(remaining);
            }
            lastUpdateTime = block.timestamp;
        }else {
          rewardRate = reward.DIV720(duration144);
          periodFinish = starttime308.ADD553(duration144);
          lastUpdateTime = starttime308;
        }

        gof.MINT2(address(this),reward);
        emit REWARDADDED578(reward);


        _CHECKREWARDRATE734();
    }

    function _CHECKREWARDRATE734() internal view returns (uint256) {
        return duration144.MUL618(rewardRate).MUL618(_gunit942);
    }
}
