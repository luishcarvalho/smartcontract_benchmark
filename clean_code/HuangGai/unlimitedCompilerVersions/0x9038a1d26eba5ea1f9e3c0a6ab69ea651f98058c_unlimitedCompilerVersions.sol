



pragma solidity ^0.5.16;





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














contract Initializable {




  bool private initialized;




  bool private initializing;




  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }


  function isConstructor() private view returns (bool) {





    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }


  uint256[50] private ______gap;
}












contract Context is Initializable {


    constructor () internal { }


    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}






library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }




    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }




    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }





    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


contract PauserRole is Initializable, Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    function initialize(address sender) public initializer {
        if (!isPauser(sender)) {
            _addPauser(sender);
        }
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }

    uint256[50] private ______gap;
}











contract Pausable is Initializable, Context, PauserRole {



    event Paused(address account);




    event Unpaused(address account);

    bool private _paused;





    function initialize(address sender) public initializer {
        PauserRole.initialize(sender);

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




    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }




    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[50] private ______gap;
}











contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    function initialize(address sender) public initializer {
        _owner = sender;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}














contract ReentrancyGuard is Initializable {

    uint256 private _guardCounter;

    function initialize() public initializer {


        _guardCounter = 1;
    }








    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }

    uint256[50] private ______gap;
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}


library BasisPoints {
    using SafeMath for uint;

    uint constant private BASIS_POINTS = 10000;

    function mulBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint amt, uint bp) internal pure returns (uint) {
        require(bp > 0, "Cannot divide by zero.");
        if (amt == 0) return 0;
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}


contract LidSimplifiedPresaleTimer is Initializable, Ownable {
    using SafeMath for uint;

    uint public startTime;
    uint public endTime;
    uint public hardCapTimer;
    uint public softCap;
    address public presale;

    function initialize(
        uint _startTime,
        uint _hardCapTimer,
        uint _softCap,
        address _presale,
        address owner
    ) external initializer {
        Ownable.initialize(msg.sender);
        startTime = _startTime;
        hardCapTimer = _hardCapTimer;
        softCap = _softCap;
        presale = _presale;

        _transferOwnership(owner);
    }

    function setStartTime(uint time) external onlyOwner {
        startTime = time;
    }

    function setEndTime(uint time) external onlyOwner {
        endTime = time;
    }

    function updateEndTime() external returns (uint) {
        if (endTime != 0) return endTime;
        if (presale.balance >= softCap) {
            endTime = now.add(hardCapTimer);
            return endTime;
        }
        return 0;
    }

    function isStarted() external view returns (bool) {
        return (startTime != 0 && now > startTime);
    }

}


contract LidSimplifiedPresaleRedeemer is Initializable, Ownable {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint public redeemBP;
    uint public redeemInterval;

    uint[] public bonusRangeStart;
    uint[] public bonusRangeBP;
    uint public currentBonusIndex;

    uint public totalShares;
    uint public totalDepositors;
    mapping(address => uint) public accountDeposits;
    mapping(address => uint) public accountShares;
    mapping(address => uint) public accountClaimedTokens;

    address private presale;

    modifier onlyPresaleContract {
        require(msg.sender == presale, "Only callable by presale contract.");
        _;
    }

    function initialize(
        uint _redeemBP,
        uint _redeemInterval,
        uint[] calldata _bonusRangeStart,
        uint[] calldata _bonusRangeBP,
        address _presale,
        address owner
    ) external initializer {
        Ownable.initialize(msg.sender);

        redeemBP = _redeemBP;
        redeemInterval = _redeemInterval;
        presale = _presale;

        require(
            _bonusRangeStart.length == _bonusRangeBP.length,
            "Must have equal values for bonus range start and BP"
        );
        require(_bonusRangeStart.length <= 10, "Cannot have more than 10 items in bonusRange");
        for (uint i = 0; i < _bonusRangeStart.length; ++i) {
            bonusRangeStart.push(_bonusRangeStart[i]);
        }
        for (uint i = 0; i < _bonusRangeBP.length; ++i) {
            bonusRangeBP.push(_bonusRangeBP[i]);
        }


        _transferOwnership(owner);
    }

    function setClaimed(address account, uint amount) external onlyPresaleContract {
        accountClaimedTokens[account] = accountClaimedTokens[account].add(amount);
    }

    function setDeposit(address account, uint deposit, uint postDepositEth) external onlyPresaleContract {
        if (accountDeposits[account] == 0) totalDepositors = totalDepositors.add(1);
        accountDeposits[account] = accountDeposits[account].add(deposit);
        uint sharesToAdd;
        if (currentBonusIndex.add(1) >= bonusRangeBP.length) {

            sharesToAdd = deposit.addBP(bonusRangeBP[currentBonusIndex]);
        } else if (postDepositEth < bonusRangeStart[currentBonusIndex.add(1)]) {

            sharesToAdd = deposit.addBP(bonusRangeBP[currentBonusIndex]);
        } else {

            uint previousBonusBP = bonusRangeBP[currentBonusIndex];
            uint newBonusBP = bonusRangeBP[currentBonusIndex.add(1)];
            uint newBonusDeposit = postDepositEth.sub(bonusRangeStart[currentBonusIndex.add(1)]);
            uint previousBonusDeposit = deposit.sub(newBonusDeposit);
            sharesToAdd = newBonusDeposit.addBP(newBonusBP).add(
                previousBonusDeposit.addBP(previousBonusBP));
            currentBonusIndex = currentBonusIndex.add(1);
        }
        accountShares[account] = accountShares[account].add(sharesToAdd);
        totalShares = totalShares.add(sharesToAdd);
    }

    function calculateRatePerEth(uint totalPresaleTokens, uint depositEth, uint hardCap) external view returns (uint) {

        uint tokensPerEtherShare = totalPresaleTokens
        .mul(1 ether)
        .div(
            getMaxShares(hardCap)
        );

        uint bp;
        if (depositEth >= bonusRangeStart[bonusRangeStart.length.sub(1)]) {
            bp = bonusRangeBP[bonusRangeBP.length.sub(1)];
        } else {
            for (uint i = 1; i < bonusRangeStart.length; ++i) {
                if (bp == 0) {
                    if (depositEth < bonusRangeStart[i]) {
                        bp = bonusRangeBP[i.sub(1)];
                    }
                }
            }
        }
        return tokensPerEtherShare.addBP(bp);
    }

    function calculateReedemable(
        address account,
        uint finalEndTime,
        uint totalPresaleTokens
    ) external view returns (uint) {
        if (finalEndTime == 0) return 0;
        if (finalEndTime >= now) return 0;
        uint earnedTokens = accountShares[account].mul(totalPresaleTokens).div(totalShares);
        uint claimedTokens = accountClaimedTokens[account];
        uint cycles = now.sub(finalEndTime).div(redeemInterval).add(1);
        uint totalRedeemable = earnedTokens.mulBP(redeemBP).mul(cycles);
        uint claimable;
        if (totalRedeemable >= earnedTokens) {
            claimable = earnedTokens.sub(claimedTokens);
        } else {
            claimable = totalRedeemable.sub(claimedTokens);
        }
        return claimable;
    }

    function getMaxShares(uint hardCap) public view returns (uint) {
        uint maxShares;
        for (uint i = 0; i < bonusRangeStart.length; ++i) {
            uint amt;
            if (i < bonusRangeStart.length.sub(1)) {
                amt = bonusRangeStart[i.add(1)].sub(bonusRangeStart[i]);
            } else {
                amt = hardCap.sub(bonusRangeStart[i]);
            }
            maxShares = maxShares.add(amt.addBP(bonusRangeBP[i]));
        }
        return maxShares;
    }
}

interface IStakeHandler {
    function handleStake(address staker, uint stakerDeltaValue, uint stakerFinalValue) external;
    function handleUnstake(address staker, uint stakerDeltaValue, uint stakerFinalValue) external;
}


interface ILidCertifiableToken {
    function activateTransfers() external;
    function activateTax() external;
    function mint(address account, uint256 amount) external returns (bool);
    function addMinter(address account) external;
    function renounceMinter() external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function isMinter(address account) external view returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}


contract LidStaking is Initializable, Ownable {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint256 constant internal DISTRIBUTION_MULTIPLIER = 2 ** 64;

    uint public stakingTaxBP;
    uint public unstakingTaxBP;
    ILidCertifiableToken private lidToken;

    mapping(address => uint) public stakeValue;
    mapping(address => int) public stakerPayouts;


    uint public totalDistributions;
    uint public totalStaked;
    uint public totalStakers;
    uint public profitPerShare;
    uint private emptyStakeTokens;

    IStakeHandler[] public stakeHandlers;
    uint public startTime;

    uint public registrationFeeWithReferrer;
    uint public registrationFeeWithoutReferrer;
    mapping(address => uint) public accountReferrals;
    mapping(address => bool) public stakerIsRegistered;

    event OnDistribute(address sender, uint amountSent);
    event OnStake(address sender, uint amount, uint tax);
    event OnUnstake(address sender, uint amount, uint tax);
    event OnReinvest(address sender, uint amount, uint tax);
    event OnWithdraw(address sender, uint amount);

    modifier onlyLidToken {
        require(msg.sender == address(lidToken), "Can only be called by LidToken contract.");
        _;
    }

    modifier whenStakingActive {
        require(startTime != 0 && now > startTime, "Staking not yet started.");
        _;
    }

    function initialize(
        uint _stakingTaxBP,
        uint _ustakingTaxBP,
        uint _registrationFeeWithReferrer,
        uint _registrationFeeWithoutReferrer,
        address owner,
        ILidCertifiableToken _lidToken
    ) external initializer {
        Ownable.initialize(msg.sender);
        stakingTaxBP = _stakingTaxBP;
        unstakingTaxBP = _ustakingTaxBP;
        lidToken = _lidToken;
        registrationFeeWithReferrer = _registrationFeeWithReferrer;
        registrationFeeWithoutReferrer = _registrationFeeWithoutReferrer;

        _transferOwnership(owner);
    }

    function registerAndStake(uint amount) public {
        registerAndStake(amount, address(0x0));
    }

    function registerAndStake(uint amount, address referrer) public whenStakingActive {
        require(!stakerIsRegistered[msg.sender], "Staker must not be registered");
        require(lidToken.balanceOf(msg.sender) >= amount, "Must have enough balance to stake amount");
        uint finalAmount;
        if(address(0x0) == referrer) {

            require(amount >= registrationFeeWithoutReferrer, "Must send at least enough LID to pay registration fee.");
            distribute(registrationFeeWithoutReferrer);
            finalAmount = amount.sub(registrationFeeWithoutReferrer);
        } else {

            require(amount >= registrationFeeWithReferrer, "Must send at least enough LID to pay registration fee.");
            require(lidToken.transferFrom(msg.sender, referrer, registrationFeeWithReferrer), "Stake failed due to failed referral transfer.");
            accountReferrals[referrer] = accountReferrals[referrer].add(1);
            finalAmount = amount.sub(registrationFeeWithReferrer);
        }
        stakerIsRegistered[msg.sender] = true;
        stake(finalAmount);
    }

    function stake(uint amount) public whenStakingActive {
        require(stakerIsRegistered[msg.sender] == true, "Must be registered to stake.");
        require(amount >= 1e18, "Must stake at least one LID.");
        require(lidToken.balanceOf(msg.sender) >= amount, "Cannot stake more LID than you hold unstaked.");
        if (stakeValue[msg.sender] == 0) totalStakers = totalStakers.add(1);
        uint tax = _addStake(amount);
        require(lidToken.transferFrom(msg.sender, address(this), amount), "Stake failed due to failed transfer.");
        emit OnStake(msg.sender, amount, tax);
    }

    function unstake(uint amount) external whenStakingActive {
        require(amount >= 1e18, "Must unstake at least one LID.");
        require(stakeValue[msg.sender] >= amount, "Cannot unstake more LID than you have staked.");

        withdraw(dividendsOf(msg.sender));
        if (stakeValue[msg.sender] == amount) totalStakers = totalStakers.sub(1);
        totalStaked = totalStaked.sub(amount);
        stakeValue[msg.sender] = stakeValue[msg.sender].sub(amount);

        uint tax = findTaxAmount(amount, unstakingTaxBP);
        uint earnings = amount.sub(tax);
        _increaseProfitPerShare(tax);
        stakerPayouts[msg.sender] = uintToInt(profitPerShare.mul(stakeValue[msg.sender]));

        for (uint i=0; i < stakeHandlers.length; i++) {
            stakeHandlers[i].handleUnstake(msg.sender, amount, stakeValue[msg.sender]);
        }

        require(lidToken.transferFrom(address(this), msg.sender, earnings), "Unstake failed due to failed transfer.");
        emit OnUnstake(msg.sender, amount, tax);
    }

    function withdraw(uint amount) public whenStakingActive {
        require(dividendsOf(msg.sender) >= amount, "Cannot withdraw more dividends than you have earned.");
        stakerPayouts[msg.sender] = stakerPayouts[msg.sender] + uintToInt(amount.mul(DISTRIBUTION_MULTIPLIER));
        lidToken.transfer(msg.sender, amount);
        emit OnWithdraw(msg.sender, amount);
    }

    function reinvest(uint amount) external whenStakingActive {
        require(dividendsOf(msg.sender) >= amount, "Cannot reinvest more dividends than you have earned.");
        uint payout = amount.mul(DISTRIBUTION_MULTIPLIER);
        stakerPayouts[msg.sender] = stakerPayouts[msg.sender] + uintToInt(payout);
        uint tax = _addStake(amount);
        emit OnReinvest(msg.sender, amount, tax);
    }

    function distribute(uint amount) public {
        require(lidToken.balanceOf(msg.sender) >= amount, "Cannot distribute more LID than you hold unstaked.");
        totalDistributions = totalDistributions.add(amount);
        _increaseProfitPerShare(amount);
        require(
            lidToken.transferFrom(msg.sender, address(this), amount),
            "Distribution failed due to failed transfer."
        );
        emit OnDistribute(msg.sender, amount);
    }

    function handleTaxDistribution(uint amount) external onlyLidToken {
        totalDistributions = totalDistributions.add(amount);
        _increaseProfitPerShare(amount);
        emit OnDistribute(msg.sender, amount);
    }

    function dividendsOf(address staker) public view returns (uint) {
        int divPayout = uintToInt(profitPerShare.mul(stakeValue[staker]));
        require(divPayout >= stakerPayouts[staker], "dividend calc overflow");
        return uint(divPayout - stakerPayouts[staker])
            .div(DISTRIBUTION_MULTIPLIER);
    }

    function findTaxAmount(uint value, uint taxBP) public pure returns (uint) {
        return value.mulBP(taxBP);
    }

    function numberStakeHandlersRegistered() external view returns (uint) {
        return stakeHandlers.length;
    }

    function registerStakeHandler(IStakeHandler sc) external onlyOwner {
        stakeHandlers.push(sc);
    }

    function unregisterStakeHandler(uint index) external onlyOwner {
        IStakeHandler sc = stakeHandlers[stakeHandlers.length-1];
        stakeHandlers.pop();
        stakeHandlers[index] = sc;
    }

    function setStakingBP(uint valueBP) external onlyOwner {
        require(valueBP < 10000, "Tax connot be over 100% (10000 BP)");
        stakingTaxBP = valueBP;
    }

    function setUnstakingBP(uint valueBP) external onlyOwner {
        require(valueBP < 10000, "Tax connot be over 100% (10000 BP)");
        unstakingTaxBP = valueBP;
    }

    function setStartTime(uint _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setRegistrationFees(uint valueWithReferrer, uint valueWithoutReferrer) external onlyOwner {
        registrationFeeWithReferrer = valueWithReferrer;
        registrationFeeWithoutReferrer = valueWithoutReferrer;
    }

    function uintToInt(uint val) internal pure returns (int) {
        if (val >= uint(-1).div(2)) {
            require(false, "Overflow. Cannot convert uint to int.");
        } else {
            return int(val);
        }
    }

    function _addStake(uint amount) internal returns (uint tax) {
        tax = findTaxAmount(amount, stakingTaxBP);
        uint stakeAmount = amount.sub(tax);
        totalStaked = totalStaked.add(stakeAmount);
        stakeValue[msg.sender] = stakeValue[msg.sender].add(stakeAmount);
        for (uint i=0; i < stakeHandlers.length; i++) {
            stakeHandlers[i].handleStake(msg.sender, stakeAmount, stakeValue[msg.sender]);
        }
        uint payout = profitPerShare.mul(stakeAmount);
        stakerPayouts[msg.sender] = stakerPayouts[msg.sender] + uintToInt(payout);
        _increaseProfitPerShare(tax);
    }

    function _increaseProfitPerShare(uint amount) internal {
        if (totalStaked != 0) {
            if (emptyStakeTokens != 0) {
                amount = amount.add(emptyStakeTokens);
                emptyStakeTokens = 0;
            }
            profitPerShare = profitPerShare.add(amount.mul(DISTRIBUTION_MULTIPLIER).div(totalStaked));
        } else {
            emptyStakeTokens = emptyStakeTokens.add(amount);
        }
    }

}



pragma solidity ^0.5.16;






contract LidSimplifiedPresaleAccess is Initializable {
    using SafeMath for uint;
    LidStaking private staking;

    uint[5] private cutoffs;

    function initialize(LidStaking _staking) external initializer {
        staking = _staking;

        cutoffs = [
            500000 ether,
            100000 ether,
            50000 ether,
            25000 ether,
            1 ether
        ];
    }

    function getAccessTime(address account, uint startTime) external view returns (uint accessTime) {
        uint stakeValue = staking.stakeValue(account);
        if (stakeValue == 0) return startTime.add(15 minutes);
        if (stakeValue >= cutoffs[0]) return startTime;
        uint i=0;
        uint stake2 = cutoffs[0];
        while (stake2 > stakeValue && i < cutoffs.length) {
            i++;
            stake2 = cutoffs[i];
        }
        return startTime.add(i.mul(3 minutes));
    }
}


contract LidSimplifiedPresale is Initializable, Ownable, ReentrancyGuard, Pausable {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint public maxBuyPerAddress;

    uint public referralBP;

    uint public uniswapEthBP;
    uint public lidEthBP;

    uint public uniswapTokenBP;
    uint public presaleTokenBP;
    address[] public tokenPools;
    uint[] public tokenPoolBPs;

    uint public hardcap;
    uint public totalTokens;

    bool public hasSentToUniswap;
    bool public hasIssuedTokens;

    uint public finalEndTime;
    uint public finalEth;

    IERC20 private token;
    IUniswapV2Router01 private uniswapRouter;
    LidSimplifiedPresaleTimer private timer;
    LidSimplifiedPresaleRedeemer private redeemer;
    LidSimplifiedPresaleAccess private access;
    address payable private lidFund;

    mapping(address => uint) public earnedReferrals;

    mapping(address => uint) public referralCounts;

    mapping(address => uint) public refundedEth;

    bool public isRefunding;

    modifier whenPresaleActive {
        require(timer.isStarted(), "Presale not yet started.");
        require(!isPresaleEnded(), "Presale has ended.");
        _;
    }

    modifier whenPresaleFinished {
        require(timer.isStarted(), "Presale not yet started.");
        require(isPresaleEnded(), "Presale has not yet ended.");
        _;
    }

    function initialize(
        uint _maxBuyPerAddress,
        uint _uniswapEthBP,
        uint _lidEthBP,
        uint _referralBP,
        uint _hardcap,
        address owner,
        LidSimplifiedPresaleTimer _timer,
        LidSimplifiedPresaleRedeemer _redeemer,
        LidSimplifiedPresaleAccess _access,
        IERC20 _token,
        IUniswapV2Router01 _uniswapRouter,
        address payable _lidFund
    ) external initializer {
        Ownable.initialize(msg.sender);
        Pausable.initialize(msg.sender);
        ReentrancyGuard.initialize();

        token = _token;
        timer = _timer;
        redeemer = _redeemer;
        access = _access;
        lidFund = _lidFund;

        maxBuyPerAddress = _maxBuyPerAddress;

        uniswapEthBP = _uniswapEthBP;
        lidEthBP = _lidEthBP;

        referralBP = _referralBP;
        hardcap = _hardcap;

        uniswapRouter = _uniswapRouter;
        totalTokens = token.totalSupply();
        token.approve(address(uniswapRouter), token.totalSupply());


        _transferOwnership(owner);
    }

    function deposit() external payable whenNotPaused {
        deposit(address(0x0));
    }

    function setTokenPools(
        uint _uniswapTokenBP,
        uint _presaleTokenBP,
        address[] calldata _tokenPools,
        uint[] calldata _tokenPoolBPs
    ) external onlyOwner whenNotPaused {
        require(_tokenPools.length == _tokenPoolBPs.length, "Must have exactly one tokenPool addresses for each BP.");
        delete tokenPools;
        delete tokenPoolBPs;
        uniswapTokenBP = _uniswapTokenBP;
        presaleTokenBP = _presaleTokenBP;
        for (uint i = 0; i < _tokenPools.length; ++i) {
            tokenPools.push(_tokenPools[i]);
        }
        uint totalTokenPoolBPs = uniswapTokenBP.add(presaleTokenBP);
        for (uint i = 0; i < _tokenPoolBPs.length; ++i) {
            tokenPoolBPs.push(_tokenPoolBPs[i]);
            totalTokenPoolBPs = totalTokenPoolBPs.add(_tokenPoolBPs[i]);
        }
        require(totalTokenPoolBPs == 10000, "Must allocate exactly 100% (10000 BP) of tokens to pools");
    }

    function sendToUniswap() external whenPresaleFinished nonReentrant whenNotPaused {
        require(msg.sender == tx.origin, "Sender must be origin - no contract calls.");
        require(tokenPools.length > 0, "Must have set token pools");
        require(!hasSentToUniswap, "Has already sent to Uniswap.");
        finalEndTime = now;
        finalEth = address(this).balance;
        hasSentToUniswap = true;
        uint uniswapTokens = totalTokens.mulBP(uniswapTokenBP);
        uint uniswapEth = finalEth.mulBP(uniswapEthBP);
        uniswapRouter.addLiquidityETH.value(uniswapEth)(
            address(token),
            uniswapTokens,
            uniswapTokens,
            uniswapEth,
            address(0x000000000000000000000000000000000000dEaD),
            now
        );
    }

    function issueTokens() external whenPresaleFinished whenNotPaused {
        require(hasSentToUniswap, "Has not yet sent to Uniswap.");
        require(!hasIssuedTokens, "Has already issued tokens.");
        hasIssuedTokens = true;
        uint last = tokenPools.length.sub(1);
        for (uint i = 0; i < last; ++i) {
            token.transfer(
                tokenPools[i],
                totalTokens.mulBP(tokenPoolBPs[i])
            );
        }

        token.transfer(
            tokenPools[last],
            totalTokens.mulBP(tokenPoolBPs[last])
        );
    }

    function releaseEthToAddress(address payable receiver, uint amount) external onlyOwner whenNotPaused returns(uint) {
        require(hasSentToUniswap, "Has not yet sent to Uniswap.");
        receiver.transfer(amount);
    }

    function redeem() external whenPresaleFinished whenNotPaused {
        require(hasSentToUniswap, "Must have sent to Uniswap before any redeems.");
        uint claimable = redeemer.calculateReedemable(msg.sender, finalEndTime, totalTokens.mulBP(presaleTokenBP));
        redeemer.setClaimed(msg.sender, claimable);
        token.transfer(msg.sender, claimable);
    }

    function startRefund() external onlyOwner {

        pause();
        isRefunding = true;
    }

    function topUpRefundFund() external payable onlyOwner {

    }

    function claimRefund(address payable account) external whenPaused {
        require(isRefunding, "Refunds not active");
        uint refundAmt = getRefundableEth(account);
        require(refundAmt > 0, "Nothing to refund");
        refundedEth[account] = refundedEth[account].add(refundAmt);
        account.transfer(refundAmt);
    }

    function updateHardcap(uint valueWei) external onlyOwner {
        hardcap = valueWei;
    }

    function updateMaxBuy(uint valueWei) external onlyOwner {
        maxBuyPerAddress = valueWei;
    }

    function deposit(address payable referrer) public payable nonReentrant whenNotPaused {
        require(timer.isStarted(), "Presale not yet started.");
        require(now >= access.getAccessTime(msg.sender, timer.startTime()), "Time must be at least access time.");
        require(msg.sender != referrer, "Sender cannot be referrer.");
        require(address(this).balance.sub(msg.value) <= hardcap, "Cannot deposit more than hardcap.");
        require(!hasSentToUniswap, "Presale Ended, Uniswap has been called.");
        uint endTime = timer.updateEndTime();
        require(!(now > endTime && endTime != 0), "Presale Ended, time over limit.");
        require(
            redeemer.accountDeposits(msg.sender).add(msg.value) <= maxBuyPerAddress,
            "Deposit exceeds max buy per address."
        );

        uint fee = msg.value.mulBP(referralBP);
        uint depositEther = msg.value;
        uint excess = 0;


        if (address(this).balance > hardcap) {
            fee = 0;
            excess = address(this).balance.sub(hardcap);
            depositEther = depositEther.sub(excess);
        }

        redeemer.setDeposit(msg.sender, depositEther.sub(fee), address(this).balance.sub(fee));

        if (excess == 0) {
            if (referrer != address(0x0) && referrer != msg.sender) {
                earnedReferrals[referrer] = earnedReferrals[referrer].add(fee);
                referralCounts[referrer] = referralCounts[referrer].add(1);
                referrer.transfer(fee);
            } else {
                lidFund.transfer(fee);
            }
        } else {
            msg.sender.transfer(excess);
        }
    }

    function getRefundableEth(address account) public view returns (uint) {
        if (!isRefunding) return 0;

        return redeemer.accountDeposits(account)
            .divBP(10000 - referralBP)
            .sub(refundedEth[account]);
    }

    function isPresaleEnded() public view returns (bool) {
        uint endTime =  timer.endTime();
        if (hasSentToUniswap) return true;
        return (
            (address(this).balance >= hardcap) ||
            (timer.isStarted() && (now > endTime && endTime != 0))
        );
    }

}
