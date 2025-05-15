




pragma solidity ^0.5.17;



library Math {

    function MAX540(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }


    function MIN509(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }


    function AVERAGE579(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}





library SafeMath {

    function ADD537(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB533(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB533(a, b, "SafeMath: subtraction overflow");
    }


    function SUB533(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL899(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV732(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV732(a, b, "SafeMath: division by zero");
    }


    function DIV732(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD804(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD804(a, b, "SafeMath: modulo by zero");
    }


    function MOD804(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}





contract Context {


    constructor () internal { }


    function _MSGSENDER75() internal view returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA657() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}






contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED138(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = _MSGSENDER75();
        emit OWNERSHIPTRANSFERRED138(address(0), _owner);
    }


    function OWNER313() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER471() {
        require(ISOWNER999(), "Ownable: caller is not the owner");
        _;
    }


    function ISOWNER999() public view returns (bool) {
        return _MSGSENDER75() == _owner;
    }


    function RENOUNCEOWNERSHIP459() public ONLYOWNER471 {
        emit OWNERSHIPTRANSFERRED138(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP87(address newOwner) public ONLYOWNER471 {
        _TRANSFEROWNERSHIP967(newOwner);
    }


    function _TRANSFEROWNERSHIP967(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED138(_owner, newOwner);
        _owner = newOwner;
    }
}



pragma solidity ^0.5.0;


interface IERC20 {

    function MINT669(address account, uint amount) external;

    function TOTALSUPPLY186() external view returns (uint256);


    function BALANCEOF689(address account) external view returns (uint256);


    function TRANSFER213(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE163(address owner, address spender) external view returns (uint256);


    function APPROVE444(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM175(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER653(address indexed from, address indexed to, uint256 value);


    event APPROVAL189(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity ^0.5.5;


library Address {

    function ISCONTRACT844(address account) internal view returns (bool) {







        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }


    function TOPAYABLE974(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }


    function SENDVALUE557(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}



pragma solidity ^0.5.0;





library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER881(IERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN468(token, abi.encodeWithSelector(token.TRANSFER213.selector, to, value));
    }

    function SAFETRANSFERFROM203(IERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN468(token, abi.encodeWithSelector(token.TRANSFERFROM175.selector, from, to, value));
    }

    function SAFEAPPROVE790(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.ALLOWANCE163(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN468(token, abi.encodeWithSelector(token.APPROVE444.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE320(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE163(address(this), spender).ADD537(value);
        CALLOPTIONALRETURN468(token, abi.encodeWithSelector(token.APPROVE444.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE576(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE163(address(this), spender).SUB533(value, "SafeERC20: decreased allowance below zero");
        CALLOPTIONALRETURN468(token, abi.encodeWithSelector(token.APPROVE444.selector, spender, newAllowance));
    }


    function CALLOPTIONALRETURN468(IERC20 token, bytes memory data) private {








        require(address(token).ISCONTRACT844(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



pragma solidity ^0.5.0;



contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution = 0x45a6b8BdfC1FAa745720165e0B172A3D6D4EC897;

    function NOTIFYREWARDAMOUNT985() external;

    modifier ONLYREWARDDISTRIBUTION252() {
        require(_MSGSENDER75() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function SETREWARDDISTRIBUTION691(address _rewardDistribution)
        external
        ONLYOWNER471
    {
        rewardDistribution = _rewardDistribution;
    }
}



pragma solidity ^0.5.0;






pragma solidity ^0.5.17;
contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public vamp_lp = IERC20(0x7dd8f4ABF60b58CE989DB66aB1af1d11E893429D);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function TOTALSUPPLY186() public view returns (uint256) {
        return _totalSupply;
    }

    function BALANCEOF689(address account) public view returns (uint256) {
        return _balances[account];
    }

    function STAKE760(uint256 amount) public {
        _totalSupply = _totalSupply.ADD537(amount);
        _balances[msg.sender] = _balances[msg.sender].ADD537(amount);
        vamp_lp.SAFETRANSFERFROM203(msg.sender, address(this), amount);
    }

    function WITHDRAW940(uint256 amount) public {
        _totalSupply = _totalSupply.SUB533(amount);
        _balances[msg.sender] = _balances[msg.sender].SUB533(amount);
        vamp_lp.SAFETRANSFER881(msg.sender, amount);
    }
}

contract VMANAVAMPPool is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public vamp = IERC20(0xb2C822a1b923E06Dbd193d2cFc7ad15388EA09DD);
    uint256 public DURATION = 7 days;
    uint256 public initreward = 801419450000000000000000;
    uint256 public starttime = 1603573200;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event REWARDADDED399(uint256 reward);
    event STAKED507(address indexed user, uint256 amount);
    event WITHDRAWN5(address indexed user, uint256 amount);
    event REWARDPAID848(address indexed user, uint256 reward);

    modifier UPDATEREWARD996(address account) {
        rewardPerTokenStored = REWARDPERTOKEN216();
        lastUpdateTime = LASTTIMEREWARDAPPLICABLE527();
        if (account != address(0)) {
            rewards[account] = EARNED802(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function LASTTIMEREWARDAPPLICABLE527() public view returns (uint256) {
        return Math.MIN509(block.timestamp, periodFinish);
    }

    function REWARDPERTOKEN216() public view returns (uint256) {
        if (TOTALSUPPLY186() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.ADD537(
                LASTTIMEREWARDAPPLICABLE527()
                    .SUB533(lastUpdateTime)
                    .MUL899(rewardRate)
                    .MUL899(1e18)
                    .DIV732(TOTALSUPPLY186())
            );
    }

    function EARNED802(address account) public view returns (uint256) {
        return
            BALANCEOF689(account)
                .MUL899(REWARDPERTOKEN216().SUB533(userRewardPerTokenPaid[account]))
                .DIV732(1e18)
                .ADD537(rewards[account]);
    }


    function STAKE760(uint256 amount) public UPDATEREWARD996(msg.sender)  CHECKSTART317{
        require(amount > 0, "Cannot stake 0");
        super.STAKE760(amount);
        emit STAKED507(msg.sender, amount);
    }

    function WITHDRAW940(uint256 amount) public UPDATEREWARD996(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super.WITHDRAW940(amount);
        emit WITHDRAWN5(msg.sender, amount);
    }

    function EXIT850() external {
        WITHDRAW940(BALANCEOF689(msg.sender));
        GETREWARD327();
    }

    function GETREWARD327() public UPDATEREWARD996(msg.sender)  {
        uint256 reward = EARNED802(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            vamp.SAFETRANSFER881(msg.sender, reward);
            emit REWARDPAID848(msg.sender, reward);
        }
    }

    function AFTEREND949() public ONLYREWARDDISTRIBUTION252 {
        require(block.timestamp > periodFinish);
        vamp.SAFETRANSFER881(msg.sender,vamp.BALANCEOF689(address(this)));
    }


    modifier CHECKSTART317(){
        require(block.timestamp > starttime,"not start");
        _;
    }

    function NOTIFYREWARDAMOUNT985()
        external
        ONLYREWARDDISTRIBUTION252
        UPDATEREWARD996(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = initreward.DIV732(DURATION);
        } else {
            uint256 remaining = periodFinish.SUB533(block.timestamp);
            uint256 leftover = remaining.MUL899(rewardRate);
            rewardRate = initreward.ADD537(leftover).DIV732(DURATION);
        }

        lastUpdateTime = block.timestamp;
        periodFinish = starttime.ADD537(DURATION);
        emit REWARDADDED399(initreward);
    }
}
