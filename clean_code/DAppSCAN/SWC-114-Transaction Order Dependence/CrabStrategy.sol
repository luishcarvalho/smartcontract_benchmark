
pragma solidity =0.7.6;
pragma abicoder v2;


import {IController} from "../interfaces/IController.sol";
import {IWPowerPerp} from "../interfaces/IWPowerPerp.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IController} from "../interfaces/IController.sol";


import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {StrategyBase} from "./base/StrategyBase.sol";
import {StrategyFlashSwap} from "./base/StrategyFlashSwap.sol";


import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {StrategyMath} from "./base/StrategyMath.sol";
import {Power2Base} from "../libs/Power2Base.sol";






contract CrabStrategy is StrategyBase, StrategyFlashSwap, ReentrancyGuard {
    using StrategyMath for uint256;
    using Address for address payable;

    uint32 public constant TWAP_PERIOD = 5 minutes;
    uint32 public constant POWER_PERP_PERIOD = 5 minutes;

    uint256 public constant DELTA_HEDGE_THRESHOLD = 1e15;


    enum FLASH_SOURCE {
        FLASH_DEPOSIT,
        FLASH_WITHDRAW,
        FLASH_HEDGE_SELL,
        FLASH_HEDGE_BUY
    }


    address public immutable ethWSqueethPool;

    address public immutable oracle;
    address public immutable ethQuoteCurrencyPool;
    address public immutable quoteCurrency;


    uint256 public immutable hedgeTimeThreshold;

    uint256 public immutable hedgePriceThreshold;

    uint256 public immutable auctionTime;

    uint256 public immutable minPriceMultiplier;

    uint256 public immutable maxPriceMultiplier;


    uint256 public timeAtLastHedge;

    uint256 public priceAtLastHedge;
    uint256 public auctionStartTime;

    struct FlashDepositData {
        uint256 totalDeposit;
    }

    struct FlashWithdrawData {
        uint256 crabAmount;
    }

    struct FlashHedgeData {
        uint256 wSqueethAmount;
        uint256 ethProceeds;
        uint256 minWSqueeth;
        uint256 minEth;
    }

    event Deposit(address indexed depositor, uint256 wSqueethAmount, uint256 lpAmount);
    event Withdraw(address indexed withdrawer, uint256 crabAmount, uint256 wSqueethAmount, uint256 ethWithdrawn);
    event FlashDeposit(address indexed depositor, uint256 depositedAmount, uint256 tradedAmountOut);
    event FlashWithdraw(address indexed withdrawer, uint256 crabAmount, uint256 wSqueethAmount);
    event TimeHedgeOnUniswap(
        address indexed hedger,
        uint256 hedgeTimestamp,
        uint256 auctionTriggerTimestamp,
        uint256 minWSqueeth,
        uint256 minEth
    );
    event PriceHedgeOnUniswap(
        address indexed hedger,
        uint256 hedgeTimestamp,
        uint256 auctionTriggerTimestamp,
        uint256 minWSqueeth,
        uint256 minEth
    );
    event TimeHedge(address indexed hedger, bool auctionType, uint256 hedgerPrice, uint256 auctionTriggerTimestamp);
    event PriceHedge(address indexed hedger, bool auctionType, uint256 hedgerPrice, uint256 auctionTriggerTimestamp);
    event Hedge(
        address indexed hedger,
        bool auctionType,
        uint256 hedgerPrice,
        uint256 auctionPrice,
        uint256 wSqueethHedgeTargetAmount,
        uint256 ethHedgetargetAmount
    );
    event HedgeOnUniswap(
        address indexed hedger,
        bool auctionType,
        uint256 auctionPrice,
        uint256 wSqueethHedgeTargetAmount,
        uint256 ethHedgetargetAmount
    );
    event ExecuteSellAuction(address indexed buyer, uint256 wSqueethSold, uint256 ethBought, bool isHedgingOnUniswap);
    event ExecuteBuyAuction(address indexed seller, uint256 wSqueethBought, uint256 ethSold, bool isHedgingOnUniswap);















    constructor(
        address _wSqueethController,
        address _oracle,
        address _weth,
        address _uniswapFactory,
        address _ethWSqueethPool,
        uint256 _hedgeTimeThreshold,
        uint256 _hedgePriceThreshold,
        uint256 _auctionTime,
        uint256 _minPriceMultiplier,
        uint256 _maxPriceMultiplier
    ) StrategyBase(_wSqueethController, _weth, "Crab Strategy", "Crab") StrategyFlashSwap(_uniswapFactory) {
        require(_oracle != address(0), "invalid oracle address");
        require(_ethWSqueethPool != address(0), "invalid ETH:WSqueeth address");
        require(_hedgeTimeThreshold > 0, "invalid hedge time threshold");
        require(_hedgePriceThreshold > 0, "invalid hedge price threshold");
        require(_auctionTime > 0, "invalid auction time");
        require(_minPriceMultiplier < 1e18, "auction min price multiplier too high");
        require(_minPriceMultiplier > 0, "invalid auction min price multiplier");
        require(_maxPriceMultiplier > 1e18, "auction max price multiplier too low");

        oracle = _oracle;
        ethWSqueethPool = _ethWSqueethPool;
        hedgeTimeThreshold = _hedgeTimeThreshold;
        hedgePriceThreshold = _hedgePriceThreshold;
        auctionTime = _auctionTime;
        minPriceMultiplier = _minPriceMultiplier;
        maxPriceMultiplier = _maxPriceMultiplier;
        ethQuoteCurrencyPool = IController(_wSqueethController).ethQuoteCurrencyPool();
        quoteCurrency = IController(_wSqueethController).quoteCurrency();
    }




    receive() external payable {
        require(msg.sender == weth || msg.sender == address(powerTokenController), "Cannot receive eth");
    }






    function flashDeposit(uint256 _ethToDeposit) external payable nonReentrant {
        (uint256 cachedStrategyDebt, uint256 cachedStrategyCollateral) = _syncStrategyState();

        (uint256 wSqueethToMint, ) = _calcWsqueethToMintAndFee(
            _ethToDeposit,
            cachedStrategyDebt,
            cachedStrategyCollateral
        );

        if (cachedStrategyDebt == 0 && cachedStrategyCollateral == 0) {


            uint256 wSqueethEthPrice = IOracle(oracle).getTwap(ethWSqueethPool, wPowerPerp, weth, TWAP_PERIOD, true);
            timeAtLastHedge = block.timestamp;
            priceAtLastHedge = wSqueethEthPrice;
        }

        _exactInFlashSwap(
            wPowerPerp,
            weth,
            IUniswapV3Pool(ethWSqueethPool).fee(),
            wSqueethToMint,
            _ethToDeposit.sub(msg.value),
            uint8(FLASH_SOURCE.FLASH_DEPOSIT),
            abi.encodePacked(_ethToDeposit)
        );

        emit FlashDeposit(msg.sender, _ethToDeposit, wSqueethToMint);
    }







    function flashWithdraw(uint256 _crabAmount, uint256 _maxEthToPay) external nonReentrant {
        (uint256 strategyDebt, ) = _syncStrategyState();

        uint256 exactWSqueethNeeded = strategyDebt.wmul(_crabAmount).wdiv(totalSupply());

        _exactOutFlashSwap(
            weth,
            wPowerPerp,
            IUniswapV3Pool(ethWSqueethPool).fee(),
            exactWSqueethNeeded,
            _maxEthToPay,
            uint8(FLASH_SOURCE.FLASH_WITHDRAW),
            abi.encodePacked(_crabAmount)
        );

        emit FlashWithdraw(msg.sender, _crabAmount, exactWSqueethNeeded);
    }







    function deposit() external payable nonReentrant returns (uint256, uint256) {
        uint256 amount = msg.value;

        (uint256 wSqueethToMint, uint256 depositorCrabAmount) = _deposit(msg.sender, amount, false);

        emit Deposit(msg.sender, wSqueethToMint, depositorCrabAmount);

        return (wSqueethToMint, depositorCrabAmount);
    }








    function withdraw(uint256 _crabAmount, uint256 _wSqueethAmount) external payable nonReentrant {
        uint256 ethToWithdraw = _withdraw(msg.sender, _crabAmount, _wSqueethAmount, false);


        payable(msg.sender).sendValue(ethToWithdraw);

        emit Withdraw(msg.sender, _crabAmount, _wSqueethAmount, ethToWithdraw);
    }






    function timeHedgeOnUniswap(uint256 _minWSqueeth, uint256 _minEth) external {
        uint256 auctionTriggerTime = timeAtLastHedge.add(hedgeTimeThreshold);

        require(block.timestamp >= auctionTriggerTime, "Time hedging is not allowed");

        _hedgeOnUniswap(auctionTriggerTime, _minWSqueeth, _minEth);

        emit TimeHedgeOnUniswap(msg.sender, block.timestamp, auctionTriggerTime, _minWSqueeth, _minEth);
    }




    function priceHedgeOnUniswap(
        uint256 _auctionTriggerTime,
        uint256 _minWSqueeth,
        uint256 _minEth
    ) external payable {
        require(_isPriceHedge(_auctionTriggerTime), "Price hedging not allowed");

        _hedgeOnUniswap(_auctionTriggerTime, _minWSqueeth, _minEth);

        emit PriceHedgeOnUniswap(msg.sender, block.timestamp, _auctionTriggerTime, _minWSqueeth, _minEth);
    }







    function timeHedge(bool _isStrategySellingWSqueeth, uint256 _limitPrice) external payable nonReentrant {
        (bool isTimeHedgeAllowed, uint256 auctionTriggerTime) = _isTimeHedge();

        require(isTimeHedgeAllowed, "Time hedging is not allowed");

        _hedge(auctionTriggerTime, _isStrategySellingWSqueeth, _limitPrice);

        emit TimeHedge(msg.sender, _isStrategySellingWSqueeth, _limitPrice, auctionTriggerTime);
    }






    function priceHedge(
        uint256 _auctionTriggerTime,
        bool _isStrategySellingWSqueeth,
        uint256 _limitPrice
    ) external payable nonReentrant {
        require(_isPriceHedge(_auctionTriggerTime), "Price hedging not allowed");

        _hedge(_auctionTriggerTime, _isStrategySellingWSqueeth, _limitPrice);

        emit PriceHedge(msg.sender, _isStrategySellingWSqueeth, _limitPrice, _auctionTriggerTime);
    }






    function checkPriceHedge(uint256 _auctionTriggerTime) external view returns (bool) {
        return _isPriceHedge(_auctionTriggerTime);
    }






    function checkTimeHedge() external view returns (bool, uint256) {
        (bool isTimeHedgeAllowed, uint256 auctionTriggerTime) = _isTimeHedge();

        return (isTimeHedgeAllowed, auctionTriggerTime);
    }






    function getWsqueethFromCrabAmount(uint256 _crabAmount) external view returns (uint256) {
        return _getDebtFromStrategyAmount(_crabAmount);
    }









    function _strategyFlash(
        address _caller,





































































    function _deposit(
        address _depositor,
        uint256 _amount,
        bool _isFlashDeposit
    ) internal returns (uint256, uint256) {
        (uint256 strategyDebt, uint256 strategyCollateral) = _syncStrategyState();
        (uint256 wSqueethToMint, uint256 ethFee) = _calcWsqueethToMintAndFee(_amount, strategyDebt, strategyCollateral);

        uint256 depositorCrabAmount = _calcSharesToMint(_amount.sub(ethFee), strategyCollateral, totalSupply());

        if (strategyDebt == 0 && strategyCollateral == 0) {


            uint256 wSqueethEthPrice = IOracle(oracle).getTwap(ethWSqueethPool, wPowerPerp, weth, TWAP_PERIOD, true);
            timeAtLastHedge = block.timestamp;
            priceAtLastHedge = wSqueethEthPrice;
        }


        _mintWPowerPerp(_depositor, wSqueethToMint, _amount, _isFlashDeposit);

        _mintStrategyToken(_depositor, depositorCrabAmount);

        return (wSqueethToMint, depositorCrabAmount);
    }









    function _withdraw(
        address _from,
        uint256 _crabAmount,
        uint256 _wSqueethAmount,
        bool _isFlashWithdraw
    ) internal returns (uint256) {
        (uint256 strategyDebt, uint256 strategyCollateral) = _syncStrategyState();

        uint256 strategyShare = _calcCrabRatio(_crabAmount, totalSupply());
        uint256 ethToWithdraw = _calcEthToWithdraw(strategyShare, strategyCollateral);

        if (strategyDebt > 0) require(_wSqueethAmount.wdiv(strategyDebt) == strategyShare, "invalid ratio");

        _burnWPowerPerp(_from, _wSqueethAmount, ethToWithdraw, _isFlashWithdraw);
        _burn(_from, _crabAmount);

        return ethToWithdraw;
    }







    function _hedge(
        uint256 _auctionTriggerTime,
        bool _isStrategySellingWSqueeth,
        uint256 _limitPrice
    ) internal {
        (
            bool isSellingAuction,
            uint256 wSqueethToAuction,
            uint256 ethProceeds,
            uint256 auctionWSqueethEthPrice
        ) = _startAuction(_auctionTriggerTime);

        require(_isStrategySellingWSqueeth == isSellingAuction, "wrong auction type");

        if (isSellingAuction) {

            require(auctionWSqueethEthPrice <= _limitPrice, "Auction price greater than max accepted price");
            require(msg.value >= ethProceeds, "Low ETH amount received");

            _executeSellAuction(msg.sender, msg.value, wSqueethToAuction, ethProceeds, false);
        } else {
            require(msg.value == 0, "ETH attached for buy auction");

            require(auctionWSqueethEthPrice >= _limitPrice, "Auction price greater than min accepted price");
            _executeBuyAuction(msg.sender, wSqueethToAuction, ethProceeds, false);
        }

        emit Hedge(
            msg.sender,
            _isStrategySellingWSqueeth,
            _limitPrice,
            auctionWSqueethEthPrice,
            wSqueethToAuction,
            ethProceeds
        );
    }





    function _hedgeOnUniswap(
        uint256 _auctionTriggerTime,
        uint256 _minWSqueeth,
        uint256 _minEth
    ) internal {
        (
            bool isSellingAuction,
            uint256 wSqueethToAuction,
            uint256 ethProceeds,
            uint256 auctionWSqueethEthPrice
        ) = _startAuction(_auctionTriggerTime);

        if (isSellingAuction) {
            _exactOutFlashSwap(
                wPowerPerp,
                weth,
                IUniswapV3Pool(ethWSqueethPool).fee(),
                ethProceeds,
                wSqueethToAuction,
                uint8(FLASH_SOURCE.FLASH_HEDGE_SELL),
                abi.encodePacked(wSqueethToAuction, ethProceeds, _minWSqueeth, _minEth)
            );
        } else {
            _exactOutFlashSwap(
                weth,
                wPowerPerp,
                IUniswapV3Pool(ethWSqueethPool).fee(),
                wSqueethToAuction,
                ethProceeds,
                uint8(FLASH_SOURCE.FLASH_HEDGE_BUY),
                abi.encodePacked(wSqueethToAuction, ethProceeds, _minWSqueeth, _minEth)
            );
        }

        emit HedgeOnUniswap(msg.sender, isSellingAuction, auctionWSqueethEthPrice, wSqueethToAuction, ethProceeds);
    }









    function _executeSellAuction(
        address _buyer,
        uint256 _buyerAmount,
        uint256 _wSqueethToSell,
        uint256 _ethToBuy,
        bool _isHedgingOnUniswap
    ) internal {
        if (_isHedgingOnUniswap) {
            _mintWPowerPerp(_buyer, _wSqueethToSell, _ethToBuy, true);
        } else {
            _mintWPowerPerp(_buyer, _wSqueethToSell, _ethToBuy, false);

            uint256 remainingEth = _buyerAmount.sub(_ethToBuy);

            if (remainingEth > 0) {
                payable(_buyer).sendValue(remainingEth);
            }
        }

        emit ExecuteSellAuction(_buyer, _wSqueethToSell, _ethToBuy, _isHedgingOnUniswap);
    }








    function _executeBuyAuction(
        address _seller,
        uint256 _wSqueethToBuy,
        uint256 _ethToSell,
        bool _isHedgingOnUniswap
    ) internal {
        _burnWPowerPerp(_seller, _wSqueethToBuy, _ethToSell, _isHedgingOnUniswap);

        if (!_isHedgingOnUniswap) {
            payable(_seller).sendValue(_ethToSell);
        }

        emit ExecuteBuyAuction(_seller, _wSqueethToBuy, _ethToSell, _isHedgingOnUniswap);
    }






    function _startAuction(uint256 _auctionTriggerTime)
        internal
        returns (
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 strategyDebt, uint256 ethDelta) = _syncStrategyState();
        uint256 currentWSqueethPrice = IOracle(oracle).getTwap(ethWSqueethPool, wPowerPerp, weth, TWAP_PERIOD, true);
        uint256 feeAdjustment = _calcFeeAdjustment();
        (bool isSellingAuction, ) = _checkAuctionType(strategyDebt, ethDelta, currentWSqueethPrice, feeAdjustment);
        uint256 auctionWSqueethEthPrice = _getAuctionPrice(_auctionTriggerTime, currentWSqueethPrice, isSellingAuction);
        (bool isStillSellingAuction, uint256 wSqueethToAuction) = _checkAuctionType(
            strategyDebt,
            ethDelta,
            auctionWSqueethEthPrice,
            feeAdjustment
        );

        require(isSellingAuction == isStillSellingAuction, "can not execute hedging trade as auction type changed");

        uint256 ethProceeds = wSqueethToAuction.wmul(auctionWSqueethEthPrice);

        timeAtLastHedge = block.timestamp;
        priceAtLastHedge = currentWSqueethPrice;

        return (isSellingAuction, wSqueethToAuction, ethProceeds, auctionWSqueethEthPrice);
    }





    function _syncStrategyState() internal view returns (uint256, uint256) {
        (, , uint256 syncedStrategyCollateral, uint256 syncedStrategyDebt) = _getVaultDetails();

        return (syncedStrategyDebt, syncedStrategyCollateral);
    }






    function _calcFeeAdjustment() internal view returns (uint256) {
        uint256 ethQuoteCurrencyPrice = Power2Base._getScaledTwap(
            oracle,
            ethQuoteCurrencyPool,
            weth,
            quoteCurrency,
            POWER_PERP_PERIOD,
            false
        );
        uint256 normalizationFactor = IController(powerTokenController).getExpectedNormalizationFactor();
        uint256 feeRate = IController(powerTokenController).feeRate();
        return normalizationFactor.wmul(ethQuoteCurrencyPrice).mul(feeRate).div(10000);
    }








    function _calcWsqueethToMintAndFee(
        uint256 _depositedAmount,
        uint256 _strategyDebtAmount,
        uint256 _strategyCollateralAmount
    ) internal view returns (uint256, uint256) {
        uint256 wSqueethToMint;
        uint256 feeAdjustment = _calcFeeAdjustment();

        if (_strategyDebtAmount == 0 && _strategyCollateralAmount == 0) {
            require(totalSupply() == 0, "Contract unsafe due to full liquidation");

            uint256 wSqueethEthPrice = IOracle(oracle).getTwap(ethWSqueethPool, wPowerPerp, weth, TWAP_PERIOD, true);
            uint256 squeethDelta = wSqueethEthPrice.wmul(2e18);
            wSqueethToMint = _depositedAmount.wdiv(squeethDelta.add(feeAdjustment));
        } else {
            wSqueethToMint = _depositedAmount.wmul(_strategyDebtAmount).wdiv(
                _strategyCollateralAmount.add(_strategyDebtAmount.wmul(feeAdjustment))
            );
        }

        uint256 fee = wSqueethToMint.wmul(feeAdjustment);

        return (wSqueethToMint, fee);
    }





    function _isTimeHedge() internal view returns (bool, uint256) {
        uint256 auctionTriggerTime = timeAtLastHedge.add(hedgeTimeThreshold);

        return (block.timestamp >= auctionTriggerTime, auctionTriggerTime);
    }





    function _isPriceHedge(uint256 _auctionTriggerTime) internal view returns (bool) {
        uint32 secondsToPriceHedgeTrigger = uint32(block.timestamp.sub(_auctionTriggerTime));
        uint256 wSqueethEthPriceAtTriggerTime = IOracle(oracle).getHistoricalTwap(
            ethWSqueethPool,
            wPowerPerp,
            weth,
            secondsToPriceHedgeTrigger + TWAP_PERIOD,
            secondsToPriceHedgeTrigger
        );
        uint256 cachedRatio = wSqueethEthPriceAtTriggerTime.wdiv(priceAtLastHedge);
        uint256 priceThreshold = cachedRatio > 1e18 ? (cachedRatio).sub(1e18) : uint256(1e18).sub(cachedRatio);

        return priceThreshold >= hedgePriceThreshold;
    }








    function _getAuctionPrice(
        uint256 _auctionTriggerTime,
        uint256 _wSqueethEthPrice,
        bool _isSellingAuction
    ) internal view returns (uint256) {
        uint256 auctionCompletionRatio = block.timestamp.sub(_auctionTriggerTime) >= auctionTime
            ? 1e18
            : (block.timestamp.sub(_auctionTriggerTime)).wdiv(auctionTime);

        uint256 priceMultiplier;
        if (_isSellingAuction) {
            priceMultiplier = maxPriceMultiplier.sub(
                auctionCompletionRatio.wmul(maxPriceMultiplier.sub(minPriceMultiplier))
            );
        } else {
            priceMultiplier = minPriceMultiplier.add(
                auctionCompletionRatio.wmul(maxPriceMultiplier.sub(minPriceMultiplier))
            );
        }

        return _wSqueethEthPrice.wmul(priceMultiplier);
    }









    function _checkAuctionType(
        uint256 _debt,
        uint256 _ethDelta,
        uint256 _wSqueethEthPrice,
        uint256 _feeAdjustment
    ) internal pure returns (bool, uint256) {
        uint256 wSqueethDelta = _debt.wmul(2e18).wmul(_wSqueethEthPrice);

        (uint256 targetHedge, bool isSellingAuction) = _getTargetHedgeAndAuctionType(
            wSqueethDelta,
            _ethDelta,
            _wSqueethEthPrice,
            _feeAdjustment
        );

        uint256 collateralRatioToHedge = targetHedge.wmul(_wSqueethEthPrice).wdiv(_ethDelta);

        require(collateralRatioToHedge > DELTA_HEDGE_THRESHOLD, "strategy is delta neutral");

        return (isSellingAuction, targetHedge);
    }








    function _calcSharesToMint(
        uint256 _amount,
        uint256 _strategyCollateralAmount,
        uint256 _crabTotalSupply
    ) internal pure returns (uint256) {
        uint256 depositorShare = _amount.wdiv(_strategyCollateralAmount.add(_amount));

        if (_crabTotalSupply != 0) return _crabTotalSupply.wmul(depositorShare).wdiv(uint256(1e18).sub(depositorShare));

        return _amount;
    }







    function _calcCrabRatio(uint256 _crabAmount, uint256 _totalSupply) internal pure returns (uint256) {
        return _crabAmount.wdiv(_totalSupply);
    }







    function _calcEthToWithdraw(uint256 _crabRatio, uint256 _strategyCollateralAmount) internal pure returns (uint256) {
        return _strategyCollateralAmount.wmul(_crabRatio);
    }











    function _getTargetHedgeAndAuctionType(
        uint256 _wSqueethDelta,
        uint256 _ethDelta,
        uint256 _wSqueethEthPrice,
        uint256 _feeAdjustment
    ) internal pure returns (uint256, bool) {
        return
            (_wSqueethDelta > _ethDelta)
                ? ((_wSqueethDelta.sub(_ethDelta)).wdiv(_wSqueethEthPrice), false)
                : ((_ethDelta.sub(_wSqueethDelta)).wdiv(_wSqueethEthPrice.add(_feeAdjustment)), true);
    }
}
