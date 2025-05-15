





pragma solidity ^0.6.12;




library Math {



    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }




    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }





    function average(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
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












    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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














    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }














    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}













contract Context {


    constructor() internal {}



    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;

        return msg.data;
    }
}












contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );




    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }




    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }








    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }




    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}







interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}






library Address {











    function isContract(address account) internal view returns (bool) {







        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }







    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
    }
}












library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {




        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }







    function callOptionalReturn(IERC20 token, bytes memory data) private {








        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (block.timestamp > 0) {


            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}



contract IGovernanceAddressRecipient is Ownable {
    address GovernanceAddress;

    modifier onlyGovernanceAddress() {
        require(
            _msgSender() == GovernanceAddress,
            "Caller is not reward distribution"
        );
        _;
    }

    function setGovernanceAddress(address _GovernanceAddress)
        external
        onlyOwner
    {
        GovernanceAddress = _GovernanceAddress;
    }
}



contract StakeTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakeToken;

    uint256 constant PERCENT = 10000;
    uint256 public DEFLATION_OUT = 0;
    uint256 public DEFLATION_REWARD = 0;
    address public feeAddress = address(0);
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(
        address _stakeToken,
        address _feeAddress,
        uint256 _deflationReward,
        uint256 _deflationOut
    ) public {
        stakeToken = IERC20(_stakeToken);
        feeAddress = _feeAddress;
        DEFLATION_OUT = _deflationOut;
        DEFLATION_REWARD = _deflationReward;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        (
            uint256 realAmount,
            uint256 feeAmount,
            uint256 burnAmount
        ) = feeTransaction(amount, DEFLATION_OUT);
        stakeToken.safeTransfer(address(feeAddress), feeAmount);
        stakeToken.burn(burnAmount);
        stakeToken.safeTransfer(msg.sender, realAmount);
    }

    function feeTransaction(uint256 amount, uint256 _deflation)
        internal
        pure
        returns (
            uint256 realAmount,
            uint256 feeAmount,
            uint256 burnAmount
        )
    {
        burnAmount = amount.div(PERCENT).mul(_deflation).div(10);
        feeAmount = amount.div(PERCENT).mul(_deflation).div(10).mul(9);
        realAmount = amount.sub(burnAmount.add(feeAmount));
    }
}

contract YFFSDeflationStake is
    StakeTokenWrapper(
        0x90D702f071d2af33032943137AD0aB4280705817,
        0xb22Aed36638f0Cf6B8d1092ab73A14580E6f8b99,
        100,
        100
    ),
    IGovernanceAddressRecipient
{
    uint256 public constant DURATION = 60 days;

    uint256 public initReward = 0;
    uint256 public startTime = 0;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    bool public stakeable = false;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event DepositStake(uint256 reward);
    event StartStaking(uint256 time);
    event StopStaking(uint256 time);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (block.coinbase != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier checkStart() {
        require(initReward > 0, "No reward to stake.");
        require(stakeable, "Staking is not started.");
        _;
    }

    constructor() public {
        GovernanceAddress = msg.sender;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function remainingReward() public view returns (uint256) {
        return stakeToken.balanceOf(address(this));
    }

    function stop() public onlyGovernanceAddress {
        require(stakeable, "Staking is not started.");
        stakeToken.safeTransfer(
            address(0x489B689850999F751760a38d03693Bd979C4A690),
            remainingReward()
        );
        stakeable = false;
        initReward = 0;
        rewardRate = 0;
        emit StopStaking(block.timestamp);
    }

    function rewardPerToken() public view returns (uint256) {
        if (block.number == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function start() public onlyGovernanceAddress {
        require(!stakeable, "Staking is started.");
        require(initReward > 0, "Cannot start. Require initReward");
        periodFinish = block.timestamp.add(DURATION);
        stakeable = true;
        startTime = block.timestamp;
        emit StartStaking(block.timestamp);
    }

    function depositReward(uint256 amount) public onlyGovernanceAddress {
        require(!stakeable, "Staking is started.");
        require(amount > 0, "Cannot deposit 0");
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
        initReward = amount;
        rewardRate = initReward.div(DURATION);
        emit DepositStake(amount);
    }

    function stake(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exitStake() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (block.number > 0) {
            rewards[msg.sender] = 0;
            uint256 deflationReward = reward.div(PERCENT).mul(DEFLATION_REWARD);
            stakeToken.burn(deflationReward);
            stakeToken.safeTransfer(msg.sender, reward.sub(deflationReward));
            emit RewardPaid(msg.sender, reward);
        }
    }
}
