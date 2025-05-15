
pragma solidity 0.8.6;

import "./libraries/Margin.sol";
import "./libraries/ReplicationMath.sol";
import "./libraries/Reserve.sol";
import "./libraries/SafeCast.sol";
import "./libraries/Transfers.sol";
import "./libraries/Units.sol";

import "./interfaces/callback/IPrimitiveCreateCallback.sol";
import "./interfaces/callback/IPrimitiveDepositCallback.sol";
import "./interfaces/callback/IPrimitiveLiquidityCallback.sol";
import "./interfaces/callback/IPrimitiveSwapCallback.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IPrimitiveEngine.sol";
import "./interfaces/IPrimitiveFactory.sol";





contract PrimitiveEngine is IPrimitiveEngine {
    using ReplicationMath for int128;
    using Units for uint256;
    using SafeCast for uint256;
    using Reserve for mapping(bytes32 => Reserve.Data);
    using Reserve for Reserve.Data;
    using Margin for mapping(address => Margin.Data);
    using Margin for Margin.Data;
    using Transfers for IERC20;







    struct Calibration {
        uint128 strike;
        uint32 sigma;
        uint32 maturity;
        uint32 lastTimestamp;
        uint32 gamma;
    }


    uint256 public constant override PRECISION = 10**18;

    uint256 public constant override BUFFER = 120 seconds;

    uint256 public immutable override MIN_LIQUIDITY;

    uint256 public immutable override scaleFactorRisky;

    uint256 public immutable override scaleFactorStable;

    address public immutable override factory;

    address public immutable override risky;

    address public immutable override stable;

    uint256 private locked = 1;

    mapping(bytes32 => Calibration) public override calibrations;

    mapping(address => Margin.Data) public override margins;

    mapping(bytes32 => Reserve.Data) public override reserves;

    mapping(address => mapping(bytes32 => uint256)) public override liquidity;

    modifier lock() {
        if (locked != 1) revert LockedError();

        locked = 2;
        _;
        locked = 1;
    }


    constructor() {
        (factory, risky, stable, scaleFactorRisky, scaleFactorStable, MIN_LIQUIDITY) = IPrimitiveFactory(msg.sender)
            .args();
    }


    function balanceRisky() private view returns (uint256) {
        (bool success, bytes memory data) = risky.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        if (!success || data.length != 32) revert BalanceError();
        return abi.decode(data, (uint256));
    }


    function balanceStable() private view returns (uint256) {
        (bool success, bytes memory data) = stable.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        if (!success || data.length != 32) revert BalanceError();
        return abi.decode(data, (uint256));
    }


    function checkRiskyBalance(uint256 expectedRisky) private view {
        uint256 actualRisky = balanceRisky();
        if (actualRisky < expectedRisky) revert RiskyBalanceError(expectedRisky, actualRisky);
    }


    function checkStableBalance(uint256 expectedStable) private view {
        uint256 actualStable = balanceStable();
        if (actualStable < expectedStable) revert StableBalanceError(expectedStable, actualStable);
    }


    function _blockTimestamp() internal view virtual returns (uint32 blockTimestamp) {

        blockTimestamp = uint32(block.timestamp);
    }


    function updateLastTimestamp(bytes32 poolId) external override lock returns (uint32 lastTimestamp) {
        lastTimestamp = _updateLastTimestamp(poolId);
    }



    function _updateLastTimestamp(bytes32 poolId) internal virtual returns (uint32 lastTimestamp) {
        Calibration storage cal = calibrations[poolId];
        if (cal.lastTimestamp == 0) revert UninitializedError();

        lastTimestamp = _blockTimestamp();
        uint32 maturity = cal.maturity;
        if (lastTimestamp > maturity) lastTimestamp = maturity;

        cal.lastTimestamp = lastTimestamp;
        emit UpdateLastTimestamp(poolId);
    }


    function create(
        uint128 strike,
        uint32 sigma,
        uint32 maturity,
        uint32 gamma,
        uint256 riskyPerLp,
        uint256 delLiquidity,
        bytes calldata data
    )
        external
        override
        lock
        returns (
            bytes32 poolId,
            uint256 delRisky,
            uint256 delStable
        )
    {
        (uint256 factor0, uint256 factor1) = (scaleFactorRisky, scaleFactorStable);
        poolId = keccak256(abi.encodePacked(address(this), strike, sigma, maturity, gamma));
        if (calibrations[poolId].lastTimestamp != 0) revert PoolDuplicateError();
        if (sigma > 1e7 || sigma < 1) revert SigmaError(sigma);
        if (strike == 0) revert StrikeError(strike);
        if (delLiquidity <= MIN_LIQUIDITY) revert MinLiquidityError(delLiquidity);
        if (riskyPerLp > PRECISION / factor0 || riskyPerLp == 0) revert RiskyPerLpError(riskyPerLp);
        if (gamma >= Units.PERCENTAGE || gamma < 9000) revert GammaError(gamma);

        Calibration memory cal = Calibration({
            strike: strike,
            sigma: sigma,
            maturity: maturity,
            lastTimestamp: _blockTimestamp(),
            gamma: gamma
        });

        if (cal.lastTimestamp > cal.maturity) revert PoolExpiredError();
        uint32 tau = cal.maturity - cal.lastTimestamp;
        delStable = ReplicationMath.getStableGivenRisky(0, factor0, factor1, riskyPerLp, cal.strike, cal.sigma, tau);
        delRisky = (riskyPerLp * delLiquidity) / PRECISION;
        delStable = (delStable * delLiquidity) / PRECISION;
        if (delRisky == 0 || delStable == 0) revert CalibrationError(delRisky, delStable);

        calibrations[poolId] = cal;
        liquidity[msg.sender][poolId] += delLiquidity - MIN_LIQUIDITY;
        reserves[poolId].allocate(delRisky, delStable, delLiquidity, cal.lastTimestamp);

        (uint256 balRisky, uint256 balStable) = (balanceRisky(), balanceStable());
        IPrimitiveCreateCallback(msg.sender).createCallback(delRisky, delStable, data);
        checkRiskyBalance(balRisky + delRisky);
        checkStableBalance(balStable + delStable);

        emit Create(msg.sender, cal.strike, cal.sigma, cal.maturity, cal.gamma);
    }




    function deposit(
        address recipient,
        uint256 delRisky,
        uint256 delStable,
        bytes calldata data
    ) external override lock {
        if (delRisky == 0 && delStable == 0) revert ZeroDeltasError();
        margins[recipient].deposit(delRisky, delStable);

        uint256 balRisky;
        uint256 balStable;
        if (delRisky != 0) balRisky = balanceRisky();
        if (delStable != 0) balStable = balanceStable();
        IPrimitiveDepositCallback(msg.sender).depositCallback(delRisky, delStable, data);
        if (delRisky != 0) checkRiskyBalance(balRisky + delRisky);
        if (delStable != 0) checkStableBalance(balStable + delStable);
        emit Deposit(msg.sender, recipient, delRisky, delStable);
    }



    function withdraw(
        address recipient,
        uint256 delRisky,
        uint256 delStable
    ) external override lock {
        if (delRisky == 0 && delStable == 0) revert ZeroDeltasError();
        margins.withdraw(delRisky, delStable);
        if (delRisky != 0) IERC20(risky).safeTransfer(recipient, delRisky);
        if (delStable != 0) IERC20(stable).safeTransfer(recipient, delStable);
        emit Withdraw(msg.sender, recipient, delRisky, delStable);
    }





    function allocate(
        bytes32 poolId,
        address recipient,
        uint256 delRisky,
        uint256 delStable,
        bool fromMargin,
        bytes calldata data
    ) external override lock returns (uint256 delLiquidity) {
        if (delRisky == 0 || delStable == 0) revert ZeroDeltasError();
        Reserve.Data storage reserve = reserves[poolId];
        if (reserve.blockTimestamp == 0) revert UninitializedError();
        uint32 timestamp = _blockTimestamp();
        if (timestamp > calibrations[poolId].maturity) revert PoolExpiredError();

        uint256 liquidity0 = (delRisky * reserve.liquidity) / uint256(reserve.reserveRisky);
        uint256 liquidity1 = (delStable * reserve.liquidity) / uint256(reserve.reserveStable);
        delLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        if (delLiquidity == 0) revert ZeroLiquidityError();

        liquidity[recipient][poolId] += delLiquidity;
        reserve.allocate(delRisky, delStable, delLiquidity, timestamp);

        if (fromMargin) {
            margins.withdraw(delRisky, delStable);
        } else {
            (uint256 balRisky, uint256 balStable) = (balanceRisky(), balanceStable());
            IPrimitiveLiquidityCallback(msg.sender).allocateCallback(delRisky, delStable, data);
            checkRiskyBalance(balRisky + delRisky);
            checkStableBalance(balStable + delStable);
        }

        emit Allocate(msg.sender, recipient, poolId, delRisky, delStable);
    }


    function remove(bytes32 poolId, uint256 delLiquidity)
        external
        override
        lock
        returns (uint256 delRisky, uint256 delStable)
    {
        if (delLiquidity == 0) revert ZeroLiquidityError();
        Reserve.Data storage reserve = reserves[poolId];
        if (reserve.blockTimestamp == 0) revert UninitializedError();
        (delRisky, delStable) = reserve.getAmounts(delLiquidity);

        liquidity[msg.sender][poolId] -= delLiquidity;
        reserve.remove(delRisky, delStable, delLiquidity, _blockTimestamp());
        margins[msg.sender].deposit(delRisky, delStable);

        emit Remove(msg.sender, poolId, delRisky, delStable);
    }

    struct SwapDetails {
        address recipient;
        bool riskyForStable;
        bool fromMargin;
        bool toMargin;
        uint32 timestamp;
        bytes32 poolId;
        uint256 deltaIn;
        uint256 deltaOut;
    }



    function swap(
        address recipient,
        bytes32 poolId,
        bool riskyForStable,
        uint256 deltaIn,
        uint256 deltaOut,
        bool fromMargin,
        bool toMargin,
        bytes calldata data
    ) external override lock {
        if (deltaIn == 0) revert DeltaInError();
        if (deltaOut == 0) revert DeltaOutError();

        SwapDetails memory details = SwapDetails({
            recipient: recipient,
            poolId: poolId,
            deltaIn: deltaIn,
            deltaOut: deltaOut,
            riskyForStable: riskyForStable,
            fromMargin: fromMargin,
            toMargin: toMargin,
            timestamp: _blockTimestamp()
        });

        uint32 lastTimestamp = _updateLastTimestamp(details.poolId);
        if (details.timestamp > lastTimestamp + BUFFER) revert PoolExpiredError();
        int128 invariantX64 = invariantOf(details.poolId);

        {

            Calibration memory cal = calibrations[details.poolId];
            Reserve.Data storage reserve = reserves[details.poolId];
            uint32 tau = cal.maturity - cal.lastTimestamp;
            uint256 deltaInWithFee = (details.deltaIn * cal.gamma) / Units.PERCENTAGE;

            uint256 adjustedRisky;
            uint256 adjustedStable;
            if (details.riskyForStable) {
                adjustedRisky = uint256(reserve.reserveRisky) + deltaInWithFee;
                adjustedStable = uint256(reserve.reserveStable) - deltaOut;
            } else {
                adjustedRisky = uint256(reserve.reserveRisky) - deltaOut;
                adjustedStable = uint256(reserve.reserveStable) + deltaInWithFee;
            }
            adjustedRisky = (adjustedRisky * PRECISION) / reserve.liquidity;
            adjustedStable = (adjustedStable * PRECISION) / reserve.liquidity;

            int128 invariantAfter = ReplicationMath.calcInvariant(
                scaleFactorRisky,
                scaleFactorStable,
                adjustedRisky,
                adjustedStable,
                cal.strike,
                cal.sigma,
                tau
            );

            if (invariantX64 > invariantAfter) revert InvariantError(invariantX64, invariantAfter);
            reserve.swap(details.riskyForStable, details.deltaIn, details.deltaOut, details.timestamp);
        }

        if (details.riskyForStable) {
            if (details.toMargin) {
                margins[details.recipient].deposit(0, details.deltaOut);
            } else {
                IERC20(stable).safeTransfer(details.recipient, details.deltaOut);
            }

            if (details.fromMargin) {
                margins.withdraw(details.deltaIn, 0);
            } else {
                uint256 balRisky = balanceRisky();
                IPrimitiveSwapCallback(msg.sender).swapCallback(details.deltaIn, 0, data);
                checkRiskyBalance(balRisky + details.deltaIn);
            }
        } else {
            if (details.toMargin) {
                margins[details.recipient].deposit(details.deltaOut, 0);
            } else {
                IERC20(risky).safeTransfer(details.recipient, details.deltaOut);
            }

            if (details.fromMargin) {
                margins.withdraw(0, details.deltaIn);
            } else {
                uint256 balStable = balanceStable();
                IPrimitiveSwapCallback(msg.sender).swapCallback(0, details.deltaIn, data);
                checkStableBalance(balStable + details.deltaIn);
            }
        }

        emit Swap(
            msg.sender,
            details.recipient,
            details.poolId,
            details.riskyForStable,
            details.deltaIn,
            details.deltaOut
        );
    }




    function invariantOf(bytes32 poolId) public view override returns (int128 invariant) {
        Calibration memory cal = calibrations[poolId];
        uint32 tau = cal.maturity - cal.lastTimestamp;
        (uint256 riskyPerLiquidity, uint256 stablePerLiquidity) = reserves[poolId].getAmounts(PRECISION);
        invariant = ReplicationMath.calcInvariant(
            scaleFactorRisky,
            scaleFactorStable,
            riskyPerLiquidity,
            stablePerLiquidity,
            cal.strike,
            cal.sigma,
            tau
        );
    }
}
