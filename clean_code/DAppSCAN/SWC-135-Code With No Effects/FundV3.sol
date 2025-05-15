
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../utils/SafeDecimalMath.sol";
import "../utils/CoreUtility.sol";

import "../interfaces/IPrimaryMarketV3.sol";
import "../interfaces/IFundV3.sol";
import "../interfaces/IShareV2.sol";
import "../interfaces/ITwapOracleV2.sol";
import "../interfaces/IAprOracle.sol";
import "../interfaces/IBallot.sol";
import "../interfaces/IVotingEscrow.sol";

import "./FundRolesV2.sol";

contract FundV3 is IFundV3, Ownable, ReentrancyGuard, FundRolesV2, CoreUtility {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    event ProfitReported(uint256 profit, uint256 performanceFee);
    event LossReported(uint256 loss);
    event ObsoletePrimaryMarketAdded(address obsoletePrimaryMarket);
    event NewPrimaryMarketAdded(address newPrimaryMarket);
    event DailyProtocolFeeRateUpdated(uint256 newDailyProtocolFeeRate);
    event TwapOracleUpdated(address newTwapOracle);
    event AprOracleUpdated(address newAprOracle);
    event BallotUpdated(address newBallot);
    event FeeCollectorUpdated(address newFeeCollector);
    event ActivityDelayTimeUpdated(uint256 delayTime);
    event SplitRatioUpdated(uint256 newSplitRatio);
    event FeeDebtPaid(uint256 amount);

    uint256 private constant UNIT = 1e18;
    uint256 private constant MAX_INTEREST_RATE = 0.2e18;
    uint256 private constant MAX_DAILY_PROTOCOL_FEE_RATE = 0.05e18;

    uint256 private constant STRATEGY_UPDATE_MIN_DELAY = 3 days;
    uint256 private constant STRATEGY_UPDATE_MAX_DELAY = 7 days;


    uint256 public immutable upperRebalanceThreshold;


    uint256 public immutable lowerRebalanceThreshold;


    address public immutable override tokenUnderlying;


    uint256 public immutable override underlyingDecimalMultiplier;


    uint256 public dailyProtocolFeeRate;


    ITwapOracleV2 public override twapOracle;


    IAprOracle public aprOracle;


    IBallot public ballot;


    address public override feeCollector;




    uint256 public override currentDay;



    uint256 public override splitRatio;


    uint256 public override fundActivityStartTime;

    uint256 public activityDelayTimeAfterRebalance;





    Rebalance[65535] private _rebalances;


    uint256 private _rebalanceSize;



    uint256[TRANCHE_COUNT] private _totalSupplies;



    mapping(address => uint256[TRANCHE_COUNT]) private _balances;


    mapping(address => uint256) private _balanceVersions;



    mapping(address => mapping(address => uint256[TRANCHE_COUNT])) private _allowances;


    mapping(address => mapping(address => uint256)) private _allowanceVersions;


    mapping(uint256 => uint256) private _historicalNavB;


    mapping(uint256 => uint256) private _historicalNavR;





    mapping(uint256 => uint256) public override historicalEquivalentTotalB;





    mapping(uint256 => uint256) public override historicalUnderlying;





    mapping(uint256 => uint256) public historicalInterestRate;


    uint256 public feeDebt;


    uint256 public redemptionDebt;


    uint256 private _totalDebt;

    uint256 private _strategyUnderlying;

    struct ConstructorParameters {
        address tokenUnderlying;
        uint256 underlyingDecimals;
        address tokenQ;
        address tokenB;
        address tokenR;
        address primaryMarket;
        address strategy;
        uint256 dailyProtocolFeeRate;
        uint256 upperRebalanceThreshold;
        uint256 lowerRebalanceThreshold;
        address twapOracle;
        address aprOracle;
        address ballot;
        address feeCollector;
    }

    constructor(ConstructorParameters memory params)
        public
        Ownable()
        FundRolesV2(
            params.tokenQ,
            params.tokenB,
            params.tokenR,
            params.primaryMarket,
            params.strategy
        )
    {
        tokenUnderlying = params.tokenUnderlying;
        require(params.underlyingDecimals <= 18, "Underlying decimals larger than 18");
        underlyingDecimalMultiplier = 10**(18 - params.underlyingDecimals);
        _updateDailyProtocolFeeRate(params.dailyProtocolFeeRate);
        upperRebalanceThreshold = params.upperRebalanceThreshold;
        lowerRebalanceThreshold = params.lowerRebalanceThreshold;
        _updateTwapOracle(params.twapOracle);
        _updateAprOracle(params.aprOracle);
        _updateBallot(params.ballot);
        _updateFeeCollector(params.feeCollector);
        _updateActivityDelayTime(30 minutes);
    }

    function initialize(
        uint256 newSplitRatio,
        uint256 lastNavB,
        uint256 lastNavR
    ) external onlyOwner {
        require(splitRatio == 0 && currentDay == 0, "Already initialized");
        require(
            newSplitRatio != 0 && lastNavB >= UNIT && !_shouldTriggerRebalance(lastNavB, lastNavR),
            "Invalid parameters"
        );
        currentDay = endOfDay(block.timestamp);
        splitRatio = newSplitRatio;
        emit SplitRatioUpdated(newSplitRatio);
        uint256 lastDay = currentDay - 1 days;
        uint256 lastDayPrice = twapOracle.getTwap(lastDay);
        require(lastDayPrice != 0, "Price not available");
        _historicalNavB[lastDay] = lastNavB;
        _historicalNavR[lastDay] = lastNavR;
        historicalInterestRate[lastDay] = MAX_INTEREST_RATE.min(aprOracle.capture());
        fundActivityStartTime = lastDay;
    }


    function settlementTime() external pure returns (uint256) {
        return SETTLEMENT_TIME;
    }







    function endOfDay(uint256 timestamp) public pure override returns (uint256) {
        return ((timestamp.add(1 days) - SETTLEMENT_TIME) / 1 days) * 1 days + SETTLEMENT_TIME;
    }







    function endOfWeek(uint256 timestamp) external pure returns (uint256) {
        return _endOfWeek(timestamp);
    }

    function tokenQ() external view override returns (address) {
        return _tokenQ;
    }

    function tokenB() external view override returns (address) {
        return _tokenB;
    }

    function tokenR() external view override returns (address) {
        return _tokenR;
    }

    function tokenShare(uint256 tranche) external view override returns (address) {
        return _getShare(tranche);
    }

    function primaryMarket() external view override returns (address) {
        return _primaryMarket;
    }

    function primaryMarketUpdateProposal() external view override returns (address, uint256) {
        return (_proposedPrimaryMarket, _proposedPrimaryMarketTimestamp);
    }

    function strategy() external view override returns (address) {
        return _strategy;
    }

    function strategyUpdateProposal() external view override returns (address, uint256) {
        return (_proposedStrategy, _proposedStrategyTimestamp);
    }




    function isFundActive(uint256 timestamp) public view override returns (bool) {
        return timestamp >= fundActivityStartTime;
    }

    function getTotalUnderlying() public view override returns (uint256) {
        uint256 hot = IERC20(tokenUnderlying).balanceOf(address(this));
        return hot.add(_strategyUnderlying).sub(_totalDebt);
    }

    function getStrategyUnderlying() external view override returns (uint256) {
        return _strategyUnderlying;
    }

    function getTotalDebt() external view override returns (uint256) {
        return _totalDebt;
    }


    function getEquivalentTotalB() public view override returns (uint256) {
        return _totalSupplies[TRANCHE_Q].multiplyDecimal(splitRatio).add(_totalSupplies[TRANCHE_B]);
    }


    function getEquivalentTotalQ() public view override returns (uint256) {
        return
            _totalSupplies[TRANCHE_B]
                .add(_totalSupplies[TRANCHE_R])
                .divideDecimal(splitRatio)
                .div(2)
                .add(_totalSupplies[TRANCHE_Q]);
    }





    function getRebalance(uint256 index) external view override returns (Rebalance memory) {
        return _rebalances[index];
    }





    function getRebalanceTimestamp(uint256 index) external view override returns (uint256) {
        return _rebalances[index].timestamp;
    }


    function getRebalanceSize() external view override returns (uint256) {
        return _rebalanceSize;
    }





    function historicalNavs(uint256 day)
        external
        view
        override
        returns (uint256 navB, uint256 navR)
    {
        return (_historicalNavB[day], _historicalNavR[day]);
    }











    function extrapolateNav(uint256 price)
        external
        view
        override
        returns (
            uint256 navSum,
            uint256 navB,
            uint256 navROrZero
        )
    {
        uint256 settledDay = currentDay - 1 days;
        uint256 underlying = getTotalUnderlying();
        uint256 protocolFee =
            underlying.multiplyDecimal(dailyProtocolFeeRate).mul(block.timestamp - settledDay).div(
                1 days
            );
        underlying = underlying.sub(protocolFee);
        return
            _extrapolateNav(block.timestamp, settledDay, price, getEquivalentTotalB(), underlying);
    }

    function _extrapolateNav(
        uint256 timestamp,
        uint256 settledDay,
        uint256 price,
        uint256 equivalentTotalB,
        uint256 underlying
    )
        private
        view
        returns (
            uint256 navSum,
            uint256 navB,
            uint256 navROrZero
        )
    {
        navB = _historicalNavB[settledDay];
        if (equivalentTotalB > 0) {
            navSum = price.mul(underlying.mul(underlyingDecimalMultiplier)).div(equivalentTotalB);
            navB = navB.multiplyDecimal(
                historicalInterestRate[settledDay].mul(timestamp - settledDay).div(1 days).add(UNIT)
            );
            navROrZero = navSum >= navB ? navSum - navB : 0;
        } else {

            navROrZero = _historicalNavR[settledDay];
            navSum = navB + navROrZero;
        }
    }











    function doRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 index
    )
        public
        view
        override
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        )
    {
        Rebalance storage rebalance = _rebalances[index];
        newAmountQ = amountQ.add(amountB.multiplyDecimal(rebalance.ratioB2Q)).add(
            amountR.multiplyDecimal(rebalance.ratioR2Q)
        );
        uint256 ratioBR = rebalance.ratioBR;
        newAmountB = amountB.multiplyDecimal(ratioBR);
        newAmountR = amountR.multiplyDecimal(ratioBR);
    }













    function batchRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 fromIndex,
        uint256 toIndex
    )
        external
        view
        override
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        )
    {
        for (uint256 i = fromIndex; i < toIndex; i++) {
            (amountQ, amountB, amountR) = doRebalance(amountQ, amountB, amountR, i);
        }
        newAmountQ = amountQ;
        newAmountB = amountB;
        newAmountR = amountR;
    }





    function refreshBalance(address account, uint256 targetVersion) external override {
        if (targetVersion > 0) {
            require(targetVersion <= _rebalanceSize, "Target version out of bound");
        }
        _refreshBalance(account, targetVersion);
    }






    function refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) external override {
        if (targetVersion > 0) {
            require(targetVersion <= _rebalanceSize, "Target version out of bound");
        }
        _refreshAllowance(owner, spender, targetVersion);
    }

    function trancheBalanceOf(uint256 tranche, address account)
        external
        view
        override
        returns (uint256)
    {
        uint256 amountQ = _balances[account][TRANCHE_Q];
        uint256 amountB = _balances[account][TRANCHE_B];
        uint256 amountR = _balances[account][TRANCHE_R];

        if (tranche == TRANCHE_Q) {
            if (amountQ == 0 && amountB == 0 && amountR == 0) return 0;
        } else if (tranche == TRANCHE_B) {
            if (amountB == 0) return 0;
        } else {
            if (amountR == 0) return 0;
        }

        uint256 size = _rebalanceSize;
        for (uint256 i = _balanceVersions[account]; i < size; i++) {
            (amountQ, amountB, amountR) = doRebalance(amountQ, amountB, amountR, i);
        }

        if (tranche == TRANCHE_Q) {
            return amountQ;
        } else if (tranche == TRANCHE_B) {
            return amountB;
        } else {
            return amountR;
        }
    }



    function trancheAllBalanceOf(address account)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 amountQ = _balances[account][TRANCHE_Q];
        uint256 amountB = _balances[account][TRANCHE_B];
        uint256 amountR = _balances[account][TRANCHE_R];

        uint256 size = _rebalanceSize;
        for (uint256 i = _balanceVersions[account]; i < size; i++) {
            (amountQ, amountB, amountR) = doRebalance(amountQ, amountB, amountR, i);
        }

        return (amountQ, amountB, amountR);
    }

    function trancheBalanceVersion(address account) external view override returns (uint256) {
        return _balanceVersions[account];
    }

    function trancheAllowance(
        uint256 tranche,
        address owner,
        address spender
    ) external view override returns (uint256) {
        uint256 allowanceQ = _allowances[owner][spender][TRANCHE_Q];
        uint256 allowanceB = _allowances[owner][spender][TRANCHE_B];
        uint256 allowanceR = _allowances[owner][spender][TRANCHE_R];

        if (tranche == TRANCHE_Q) {
            if (allowanceQ == 0) return 0;
        } else if (tranche == TRANCHE_B) {
            if (allowanceB == 0) return 0;
        } else {
            if (allowanceR == 0) return 0;
        }

        uint256 size = _rebalanceSize;
        for (uint256 i = _allowanceVersions[owner][spender]; i < size; i++) {
            (allowanceQ, allowanceB, allowanceR) = _rebalanceAllowance(
                allowanceQ,
                allowanceB,
                allowanceR,
                i
            );
        }

        if (tranche == TRANCHE_Q) {
            return allowanceQ;
        } else if (tranche == TRANCHE_B) {
            return allowanceB;
        } else {
            return allowanceR;
        }
    }

    function trancheAllowanceVersion(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowanceVersions[owner][spender];
    }

    function trancheTransfer(
        uint256 tranche,
        address recipient,
        uint256 amount,
        uint256 version
    ) external override onlyCurrentVersion(version) {
        _refreshBalance(msg.sender, version);
        _refreshBalance(recipient, version);
        _transfer(tranche, msg.sender, recipient, amount);
    }

    function trancheTransferFrom(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount,
        uint256 version
    ) external override onlyCurrentVersion(version) {
        _refreshAllowance(sender, msg.sender, version);
        uint256 newAllowance =
            _allowances[sender][msg.sender][tranche].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            );
        _approve(tranche, sender, msg.sender, newAllowance);
        _refreshBalance(sender, version);
        _refreshBalance(recipient, version);
        _transfer(tranche, sender, recipient, amount);
    }

    function trancheApprove(
        uint256 tranche,
        address spender,
        uint256 amount,
        uint256 version
    ) external override onlyCurrentVersion(version) {
        _refreshAllowance(msg.sender, spender, version);
        _approve(tranche, msg.sender, spender, amount);
    }

    function trancheTotalSupply(uint256 tranche) external view override returns (uint256) {
        return _totalSupplies[tranche];
    }

    function primaryMarketMint(
        uint256 tranche,
        address account,
        uint256 amount,
        uint256 version
    ) external override onlyPrimaryMarket onlyCurrentVersion(version) {
        _refreshBalance(account, version);
        _mint(tranche, account, amount);
    }

    function primaryMarketBurn(
        uint256 tranche,
        address account,
        uint256 amount,
        uint256 version
    ) external override onlyPrimaryMarket onlyCurrentVersion(version) {
        _refreshBalance(account, version);
        _burn(tranche, account, amount);
    }

    function shareTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) public override {
        uint256 tranche = _getTranche(msg.sender);
        if (tranche != TRANCHE_Q) {
            require(isFundActive(block.timestamp), "Transfer is inactive");
        }
        _refreshBalance(sender, _rebalanceSize);
        _refreshBalance(recipient, _rebalanceSize);
        _transfer(tranche, sender, recipient, amount);
    }

    function shareTransferFrom(
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (uint256 newAllowance) {
        uint256 tranche = _getTranche(msg.sender);
        shareTransfer(sender, recipient, amount);
        _refreshAllowance(sender, spender, _rebalanceSize);
        newAllowance = _allowances[sender][spender][tranche].sub(
            amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(tranche, sender, spender, newAllowance);
    }

    function shareApprove(
        address owner,
        address spender,
        uint256 amount
    ) external override {
        uint256 tranche = _getTranche(msg.sender);
        _refreshAllowance(owner, spender, _rebalanceSize);
        _approve(tranche, owner, spender, amount);
    }

    function shareIncreaseAllowance(
        address sender,
        address spender,
        uint256 addedValue
    ) external override returns (uint256 newAllowance) {
        uint256 tranche = _getTranche(msg.sender);
        _refreshAllowance(sender, spender, _rebalanceSize);
        newAllowance = _allowances[sender][spender][tranche].add(addedValue);
        _approve(tranche, sender, spender, newAllowance);
    }

    function shareDecreaseAllowance(
        address sender,
        address spender,
        uint256 subtractedValue
    ) external override returns (uint256 newAllowance) {
        uint256 tranche = _getTranche(msg.sender);
        _refreshAllowance(sender, spender, _rebalanceSize);
        newAllowance = _allowances[sender][spender][tranche].sub(subtractedValue);
        _approve(tranche, sender, spender, newAllowance);
    }

    function _transfer(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender][tranche] = _balances[sender][tranche].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient][tranche] = _balances[recipient][tranche].add(amount);
        IShareV2(_getShare(tranche)).fundEmitTransfer(sender, recipient, amount);
    }

    function _mint(
        uint256 tranche,
        address account,
        uint256 amount
    ) private {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupplies[tranche] = _totalSupplies[tranche].add(amount);
        _balances[account][tranche] = _balances[account][tranche].add(amount);
        IShareV2(_getShare(tranche)).fundEmitTransfer(address(0), account, amount);
    }

    function _burn(
        uint256 tranche,
        address account,
        uint256 amount
    ) private {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account][tranche] = _balances[account][tranche].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupplies[tranche] = _totalSupplies[tranche].sub(amount);
        IShareV2(_getShare(tranche)).fundEmitTransfer(account, address(0), amount);
    }

    function _approve(
        uint256 tranche,
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender][tranche] = amount;
        IShareV2(_getShare(tranche)).fundEmitApproval(owner, spender, amount);
    }








    function settle() external nonReentrant {
        uint256 day = currentDay;
        require(day != 0, "Not initialized");
        require(block.timestamp >= day, "The current trading day does not end yet");
        uint256 price = twapOracle.getTwap(day);
        require(price != 0, "Underlying price for settlement is not ready yet");

        _collectFee();

        IPrimaryMarketV3(_primaryMarket).settle(day);

        _payFeeDebt();


        uint256 equivalentTotalB = getEquivalentTotalB();
        uint256 underlying = getTotalUnderlying();
        (uint256 navSum, uint256 navB, uint256 navR) =
            _extrapolateNav(day, day - 1 days, price, equivalentTotalB, underlying);

        if (_shouldTriggerRebalance(navB, navR)) {
            uint256 newSplitRatio = splitRatio.multiplyDecimal(navSum) / 2;
            _triggerRebalance(day, navSum, navB, navR, newSplitRatio);
            splitRatio = newSplitRatio;
            emit SplitRatioUpdated(newSplitRatio);
            navB = UNIT;
            navR = UNIT;
            equivalentTotalB = getEquivalentTotalB();
            fundActivityStartTime = day + activityDelayTimeAfterRebalance;
        } else {
            fundActivityStartTime = day;
        }

        uint256 interestRate =
            day == _endOfWeek(day - 1 days)
                ? _updateInterestRate(day)
                : historicalInterestRate[day - 1 days];
        historicalInterestRate[day] = interestRate;

        historicalEquivalentTotalB[day] = equivalentTotalB;
        historicalUnderlying[day] = underlying;
        _historicalNavB[day] = navB;
        _historicalNavR[day] = navR;
        currentDay = day + 1 days;

        emit Settled(day, navB, navR, interestRate);
    }

    function transferToStrategy(uint256 amount) external override onlyStrategy {
        _strategyUnderlying = _strategyUnderlying.add(amount);
        IERC20(tokenUnderlying).safeTransfer(_strategy, amount);
    }

    function transferFromStrategy(uint256 amount) external override onlyStrategy {
        _strategyUnderlying = _strategyUnderlying.sub(amount);
        IERC20(tokenUnderlying).safeTransferFrom(_strategy, address(this), amount);
        _payFeeDebt();
    }

    function primaryMarketTransferUnderlying(
        address recipient,
        uint256 amount,
        uint256 fee
    ) external override onlyPrimaryMarket {
        IERC20(tokenUnderlying).safeTransfer(recipient, amount);
        feeDebt = feeDebt.add(fee);
        _totalDebt = _totalDebt.add(fee);
    }

    function primaryMarketAddDebt(uint256 amount, uint256 fee) external override onlyPrimaryMarket {
        redemptionDebt = redemptionDebt.add(amount);
        feeDebt = feeDebt.add(fee);
        _totalDebt = _totalDebt.add(amount).add(fee);
    }

    function primaryMarketPayDebt(uint256 amount) external override onlyPrimaryMarket {
        redemptionDebt = redemptionDebt.sub(amount);
        _totalDebt = _totalDebt.sub(amount);
        IERC20(tokenUnderlying).safeTransfer(msg.sender, amount);
    }

    function reportProfit(uint256 profit, uint256 performanceFee) external override onlyStrategy {
        require(profit >= performanceFee, "Performance fee cannot exceed profit");
        _strategyUnderlying = _strategyUnderlying.add(profit);
        feeDebt = feeDebt.add(performanceFee);
        _totalDebt = _totalDebt.add(performanceFee);
        emit ProfitReported(profit, performanceFee);
    }

    function reportLoss(uint256 loss) external override onlyStrategy {
        _strategyUnderlying = _strategyUnderlying.sub(loss);
        emit LossReported(loss);
    }

    function proposePrimaryMarketUpdate(address newPrimaryMarket) external onlyOwner {
        _proposePrimaryMarketUpdate(newPrimaryMarket);
    }

    function applyPrimaryMarketUpdate(address newPrimaryMarket) external onlyOwner {
        require(
            IPrimaryMarketV3(_primaryMarket).canBeRemovedFromFund(),
            "Cannot update primary market"
        );
        _applyPrimaryMarketUpdate(newPrimaryMarket);
    }

    function proposeStrategyUpdate(address newStrategy) external onlyOwner {
        _proposeStrategyUpdate(newStrategy);
    }

    function applyStrategyUpdate(address newStrategy) external onlyOwner {
        require(_totalDebt == 0, "Cannot update strategy with debt");
        _applyStrategyUpdate(newStrategy);
    }

    function _updateDailyProtocolFeeRate(uint256 newDailyProtocolFeeRate) private {
        require(
            newDailyProtocolFeeRate <= MAX_DAILY_PROTOCOL_FEE_RATE,
            "Exceed max protocol fee rate"
        );
        dailyProtocolFeeRate = newDailyProtocolFeeRate;
        emit DailyProtocolFeeRateUpdated(newDailyProtocolFeeRate);
    }

    function updateDailyProtocolFeeRate(uint256 newDailyProtocolFeeRate) external onlyOwner {
        _updateDailyProtocolFeeRate(newDailyProtocolFeeRate);
    }

    function _updateTwapOracle(address newTwapOracle) private {
        twapOracle = ITwapOracleV2(newTwapOracle);
        emit TwapOracleUpdated(newTwapOracle);
    }

    function updateTwapOracle(address newTwapOracle) external onlyOwner {
        _updateTwapOracle(newTwapOracle);
    }

    function _updateAprOracle(address newAprOracle) private {
        aprOracle = IAprOracle(newAprOracle);
        emit AprOracleUpdated(newAprOracle);
    }

    function updateAprOracle(address newAprOracle) external onlyOwner {
        _updateAprOracle(newAprOracle);
    }

    function _updateBallot(address newBallot) private {
        ballot = IBallot(newBallot);
        emit BallotUpdated(newBallot);
    }

    function updateBallot(address newBallot) external onlyOwner {
        _updateBallot(newBallot);
    }

    function _updateFeeCollector(address newFeeCollector) private {
        feeCollector = newFeeCollector;
        emit FeeCollectorUpdated(newFeeCollector);
    }

    function updateFeeCollector(address newFeeCollector) external onlyOwner {
        _updateFeeCollector(newFeeCollector);
    }

    function _updateActivityDelayTime(uint256 delayTime) private {
        require(
            delayTime >= 30 minutes && delayTime <= 12 hours,
            "Exceed allowed delay time range"
        );
        activityDelayTimeAfterRebalance = delayTime;
        emit ActivityDelayTimeUpdated(delayTime);
    }

    function updateActivityDelayTime(uint256 delayTime) external onlyOwner {
        _updateActivityDelayTime(delayTime);
    }




    function _collectFee() private {
        uint256 currentUnderlying = getTotalUnderlying();
        uint256 fee = currentUnderlying.multiplyDecimal(dailyProtocolFeeRate);
        if (fee > 0) {
            feeDebt = feeDebt.add(fee);
            _totalDebt = _totalDebt.add(fee);
        }
    }

    function _payFeeDebt() private {
        uint256 total = _totalDebt;
        if (total == 0) {
            return;
        }
        uint256 hot = IERC20(tokenUnderlying).balanceOf(address(this));
        if (hot == 0) {
            return;
        }
        uint256 fee = feeDebt;
        if (fee > 0) {
            uint256 amount = hot.min(fee);
            feeDebt = fee - amount;
            _totalDebt = total - amount;


            (bool success, ) = feeCollector.call(abi.encodeWithSignature("checkpoint()"));
            if (!success) {

            }
            IERC20(tokenUnderlying).safeTransfer(feeCollector, amount);
            emit FeeDebtPaid(amount);
        }
    }







    function _shouldTriggerRebalance(uint256 navB, uint256 navROrZero) private view returns (bool) {
        uint256 rOverB = navROrZero.divideDecimal(navB);
        return rOverB < lowerRebalanceThreshold || rOverB > upperRebalanceThreshold;
    }








    function _triggerRebalance(
        uint256 day,
        uint256 navSum,
        uint256 navB,
        uint256 navROrZero,
        uint256 newSplitRatio
    ) private {
        Rebalance memory rebalance = _calculateRebalance(navSum, navB, navROrZero, newSplitRatio);
        uint256 oldSize = _rebalanceSize;
        _rebalances[oldSize] = rebalance;
        _rebalanceSize = oldSize + 1;
        emit RebalanceTriggered(
            oldSize,
            day,
            navSum,
            navB,
            navROrZero,
            rebalance.ratioB2Q,
            rebalance.ratioR2Q,
            rebalance.ratioBR
        );

        (
            _totalSupplies[TRANCHE_Q],
            _totalSupplies[TRANCHE_B],
            _totalSupplies[TRANCHE_R]
        ) = doRebalance(
            _totalSupplies[TRANCHE_Q],
            _totalSupplies[TRANCHE_B],
            _totalSupplies[TRANCHE_R],
            oldSize
        );
        _refreshBalance(address(this), oldSize + 1);
    }











    function _calculateRebalance(
        uint256 navSum,
        uint256 navB,
        uint256 navROrZero,
        uint256 newSplitRatio
    ) private view returns (Rebalance memory) {
        uint256 ratioBR;
        uint256 ratioB2Q;
        uint256 ratioR2Q;
        if (navROrZero <= navB) {

            ratioBR = navROrZero;
            ratioB2Q = (navSum / 2 - navROrZero).divideDecimal(newSplitRatio);
            ratioR2Q = 0;
        } else {

            ratioBR = UNIT;
            ratioB2Q = (navB - UNIT).divideDecimal(newSplitRatio) / 2;
            ratioR2Q = (navROrZero - UNIT).divideDecimal(newSplitRatio) / 2;
        }
        return
            Rebalance({
                ratioB2Q: ratioB2Q,
                ratioR2Q: ratioR2Q,
                ratioBR: ratioBR,
                timestamp: block.timestamp
            });
    }

    function _updateInterestRate(uint256 week) private returns (uint256) {
        uint256 baseInterestRate = MAX_INTEREST_RATE.min(aprOracle.capture());
        uint256 floatingInterestRate = ballot.count(week).div(365);
        uint256 rate = baseInterestRate.add(floatingInterestRate);

        emit InterestRateUpdated(baseInterestRate, floatingInterestRate);

        return rate;
    }





    function _refreshBalance(address account, uint256 targetVersion) private {
        if (targetVersion == 0) {
            targetVersion = _rebalanceSize;
        }
        uint256 oldVersion = _balanceVersions[account];
        if (oldVersion >= targetVersion) {
            return;
        }

        uint256[TRANCHE_COUNT] storage balanceTuple = _balances[account];
        uint256 balanceQ = balanceTuple[TRANCHE_Q];
        uint256 balanceB = balanceTuple[TRANCHE_B];
        uint256 balanceR = balanceTuple[TRANCHE_R];
        _balanceVersions[account] = targetVersion;

        if (balanceQ == 0 && balanceB == 0 && balanceR == 0) {

            return;
        }

        for (uint256 i = oldVersion; i < targetVersion; i++) {
            (balanceQ, balanceB, balanceR) = doRebalance(balanceQ, balanceB, balanceR, i);
        }
        balanceTuple[TRANCHE_Q] = balanceQ;
        balanceTuple[TRANCHE_B] = balanceB;
        balanceTuple[TRANCHE_R] = balanceR;

        emit BalancesRebalanced(account, targetVersion, balanceQ, balanceB, balanceR);
    }






    function _refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) private {
        if (targetVersion == 0) {
            targetVersion = _rebalanceSize;
        }
        uint256 oldVersion = _allowanceVersions[owner][spender];
        if (oldVersion >= targetVersion) {
            return;
        }

        uint256[TRANCHE_COUNT] storage allowanceTuple = _allowances[owner][spender];
        uint256 allowanceQ = allowanceTuple[TRANCHE_Q];
        uint256 allowanceB = allowanceTuple[TRANCHE_B];
        uint256 allowanceR = allowanceTuple[TRANCHE_R];
        _allowanceVersions[owner][spender] = targetVersion;

        if (allowanceQ == 0 && allowanceB == 0 && allowanceR == 0) {

            return;
        }

        for (uint256 i = oldVersion; i < targetVersion; i++) {
            (allowanceQ, allowanceB, allowanceR) = _rebalanceAllowance(
                allowanceQ,
                allowanceB,
                allowanceR,
                i
            );
        }
        allowanceTuple[TRANCHE_Q] = allowanceQ;
        allowanceTuple[TRANCHE_B] = allowanceB;
        allowanceTuple[TRANCHE_R] = allowanceR;

        emit AllowancesRebalanced(
            owner,
            spender,
            targetVersion,
            allowanceQ,
            allowanceB,
            allowanceR
        );
    }

    function _rebalanceAllowance(
        uint256 allowanceQ,
        uint256 allowanceB,
        uint256 allowanceR,
        uint256 index
    )
        private
        view
        returns (
            uint256 newAllowanceQ,
            uint256 newAllowanceB,
            uint256 newAllowanceR
        )
    {
        Rebalance storage rebalance = _rebalances[index];


        newAllowanceQ = allowanceQ;
        newAllowanceB = allowanceB.saturatingMultiplyDecimal(rebalance.ratioBR);
        newAllowanceR = allowanceR.saturatingMultiplyDecimal(rebalance.ratioBR);
    }

    modifier onlyCurrentVersion(uint256 version) {
        require(_rebalanceSize == version, "Only current version");
        _;
    }
}
