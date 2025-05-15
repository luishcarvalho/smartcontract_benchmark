


pragma solidity ^0.7.4;
pragma abicoder v2;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IAccountFactory} from "../interfaces/IAccountFactory.sol";
import {ICreditAccount} from "../interfaces/ICreditAccount.sol";
import {IPoolService} from "../interfaces/IPoolService.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";
import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {CreditAccount} from "./CreditAccount.sol";
import {AddressProvider} from "../core/AddressProvider.sol";
import {ACLTrait} from "../core/ACLTrait.sol";

import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/data/Types.sol";

import "hardhat/console.sol";





contract CreditManager is ICreditManager, ACLTrait, ReentrancyGuard {
    using SafeMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;


    uint256 public override minAmount;


    uint256 public override maxAmount;


    uint256 public override maxLeverageFactor;


    uint256 public override minHealthFactor;


    mapping(address => address) public override creditAccounts;


    AddressProvider public addressProvider;


    IAccountFactory internal _accountFactory;


    ICreditFilter public override creditFilter;


    address public override underlyingToken;


    address public override poolService;


    address public wethAddress;


    address public wethGateway;


    address public defaultSwapContract;

    uint256 public override feeSuccess;

    uint256 public override feeInterest;

    uint256 public override feeLiquidation;

    uint256 public override liquidationDiscount;






    modifier allowedAdaptersOnly(address targetContract) {
        require(
            creditFilter.contractToAdapter(targetContract) == msg.sender,
            Errors.CM_TARGET_CONTRACT_iS_NOT_ALLOWED
        );
        _;
    }









    constructor(
        address _addressProvider,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _maxLeverage,
        address _poolService,
        address _creditFilterAddress,
        address _defaultSwapContract
    ) ACLTrait(_addressProvider) {
        addressProvider = AddressProvider(_addressProvider);
        poolService = _poolService;
        underlyingToken = IPoolService(_poolService).underlyingToken();

        wethAddress = addressProvider.getWethToken();
        wethGateway = addressProvider.getWETHGateway();
        defaultSwapContract = _defaultSwapContract;
        _accountFactory = IAccountFactory(addressProvider.getAccountFactory());

        setParams(
            _minAmount,
            _maxAmount,
            _maxLeverage,
            Constants.FEE_SUCCESS,
            Constants.FEE_INTEREST,
            Constants.FEE_LIQUIDATION,
            Constants.LIQUIDATION_DISCOUNTED_SUM
        );

        creditFilter = ICreditFilter(_creditFilterAddress);
    }






















    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint256 leverageFactor,
        uint256 referralCode
    )
        external
        override
        whenNotPaused
        nonReentrant
    {

        require(
            amount >= minAmount && amount <= maxAmount,
            Errors.CM_INCORRECT_AMOUNT
        );


        require(
            !hasOpenedCreditAccount(onBehalfOf),
            Errors.CM_YOU_HAVE_ALREADY_OPEN_CREDIT_ACCOUNT
        );


        require(
            leverageFactor > 0 && leverageFactor <= maxLeverageFactor,
            Errors.CM_INCORRECT_LEVERAGE_FACTOR
        );


        uint256 borrowedAmount = amount.mul(leverageFactor).div(
            Constants.LEVERAGE_DECIMALS
        );


        address creditAccount = _accountFactory.takeCreditAccount();



        creditFilter.initEnabledTokens(creditAccount);


        IPoolService(poolService).lendCreditAccount(
            borrowedAmount,
            creditAccount
        );


        IERC20(underlyingToken).safeTransferFrom(
            msg.sender,
            creditAccount,
            amount
        );


        ICreditAccount(creditAccount).setGenericParameters(
            borrowedAmount,
            IPoolService(poolService).calcLinearCumulative_RAY()
        );


        creditAccounts[onBehalfOf] = creditAccount;


        emit OpenCreditAccount(
            msg.sender,
            onBehalfOf,
            creditAccount,
            amount,
            borrowedAmount,
            referralCode
        );
    }














    function closeCreditAccount(address to, DataTypes.Exchange[] calldata paths)
        external
        override
        whenNotPaused
        nonReentrant
    {
        address creditAccount = getCreditAccountOrRevert(msg.sender);


        _convertAllAssetsToUnderlying(creditAccount, paths);


        uint256 totalValue = IERC20(underlyingToken).balanceOf(creditAccount);

        (, uint256 remainingFunds) = _closeCreditAccountImpl(
            creditAccount,
            Constants.OPERATION_CLOSURE,
            totalValue,
            msg.sender,
            address(0),
            to
        );

        emit CloseCreditAccount(msg.sender, to, remainingFunds);
    }














    function liquidateCreditAccount(
        address borrower,
        address to,
        bool force
    )
        external
        override
        whenNotPaused
        nonReentrant
    {
        address creditAccount = getCreditAccountOrRevert(borrower);


        (uint256 totalValue, uint256 tvw) = _transferAssetsTo(
            creditAccount,
            to,
            force
        );


        require(
            tvw <
                creditFilter
                .calcCreditAccountAccruedInterest(creditAccount)
                .mul(PercentageMath.PERCENTAGE_FACTOR),
            Errors.CM_CAN_LIQUIDATE_WITH_SUCH_HEALTH_FACTOR
        );


        (, uint256 remainingFunds) = _closeCreditAccountImpl(
            creditAccount,
            Constants.OPERATION_LIQUIDATION,
            totalValue,
            borrower,
            msg.sender,
            to
        );

        emit LiquidateCreditAccount(borrower, msg.sender, remainingFunds);
    }





    function repayCreditAccount(address to)
        external
        override
        whenNotPaused
        nonReentrant
    {
        _repayCreditAccountImpl(msg.sender, to);
    }





    function repayCreditAccountETH(address borrower, address to)
        external
        override
        whenNotPaused
        nonReentrant
        returns (uint256)
    {

        require(msg.sender == wethGateway, Errors.CM_WETH_GATEWAY_ONLY);


        return _repayCreditAccountImpl(borrower, to);
    }





    function _repayCreditAccountImpl(address borrower, address to)
        internal
        returns (uint256)
    {
        address creditAccount = getCreditAccountOrRevert(borrower);
        (uint256 totalValue, ) = _transferAssetsTo(creditAccount, to, false);

        (uint256 amountToPool, ) = _closeCreditAccountImpl(
            creditAccount,
            Constants.OPERATION_REPAY,
            totalValue,
            borrower,
            borrower,
            to
        );

        emit RepayCreditAccount(borrower, to);
        return amountToPool;
    }


    function _closeCreditAccountImpl(
        address creditAccount,
        uint8 operation,
        uint256 totalValue,
        address borrower,
        address liquidator,
        address to
    ) internal returns (uint256, uint256) {
        bool isLiquidated = operation == Constants.OPERATION_LIQUIDATION;

        (
            uint256 borrowedAmount,
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        ) = _calcClosePayments(creditAccount, totalValue, isLiquidated);

        if (operation == Constants.OPERATION_CLOSURE) {
            ICreditAccount(creditAccount).safeTransfer(
                underlyingToken,
                poolService,
                amountToPool
            );


            require(loss <= 1, Errors.CM_CANT_CLOSE_WITH_LOSS);


            _safeTokenTransfer(
                creditAccount,
                underlyingToken,
                to,
                remainingFunds,
                false
            );
        }

        else if (operation == Constants.OPERATION_LIQUIDATION) {

            IERC20(underlyingToken).safeTransferFrom(
                liquidator,
                poolService,
                amountToPool
            );


            IERC20(underlyingToken).safeTransferFrom(
                liquidator,
                borrower,
                remainingFunds
            );
        }

        else {

            IERC20(underlyingToken).safeTransferFrom(
                msg.sender,
                poolService,
                amountToPool
            );
        }


        _accountFactory.returnCreditAccount(creditAccount);


        delete creditAccounts[borrower];


        IPoolService(poolService).repayCreditAccount(
            borrowedAmount,
            profit,
            loss
        );

        return (amountToPool, remainingFunds);
    }





    function _calcClosePayments(
        address creditAccount,
        uint256 totalValue,
        bool isLiquidated
    )
        public
        view
        returns (
            uint256 _borrowedAmount,
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        )
    {

        (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtCreditAccountOpen_RAY
        ) = getCreditAccountParameters(creditAccount);

        return
            _calcClosePaymentsPure(
                totalValue,
                isLiquidated,
                borrowedAmount,
                cumulativeIndexAtCreditAccountOpen_RAY,
                IPoolService(poolService).calcLinearCumulative_RAY()
            );
    }







    function _calcClosePaymentsPure(
        uint256 totalValue,
        bool isLiquidated,
        uint256 borrowedAmount,
        uint256 cumulativeIndexAtCreditAccountOpen_RAY,
        uint256 cumulativeIndexNow_RAY
    )
        public
        view
        returns (
            uint256 _borrowedAmount,
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        )
    {
        uint256 totalFunds = isLiquidated
            ? totalValue.mul(liquidationDiscount).div(
                PercentageMath.PERCENTAGE_FACTOR
            )
            : totalValue;

        _borrowedAmount = borrowedAmount;

        uint256 borrowedAmountWithInterest = borrowedAmount
        .mul(cumulativeIndexNow_RAY)
        .div(cumulativeIndexAtCreditAccountOpen_RAY);

        if (totalFunds < borrowedAmountWithInterest) {
            amountToPool = totalFunds.sub(1);
            loss = borrowedAmountWithInterest.sub(amountToPool);
        } else {
            amountToPool = isLiquidated
                ? totalFunds.percentMul(feeLiquidation).add(
                    borrowedAmountWithInterest
                )
                : totalFunds
                .sub(borrowedAmountWithInterest)
                .percentMul(feeSuccess)
                .add(borrowedAmountWithInterest)
                .add(
                    borrowedAmountWithInterest.sub(borrowedAmount).percentMul(
                        feeInterest
                    )
                );

            amountToPool = totalFunds >= amountToPool
                ? amountToPool
                : totalFunds;
            profit = amountToPool.sub(borrowedAmountWithInterest);
            remainingFunds = totalFunds > amountToPool
                ? totalFunds.sub(amountToPool).sub(1)
                : 0;
        }
    }




    function _transferAssetsTo(
        address creditAccount,
        address to,
        bool force
    ) internal returns (uint256 totalValue, uint256 totalWeightedValue) {
        totalValue = 0;
        totalWeightedValue = 0;

        uint256 tokenMask;
        uint256 enabledTokens = creditFilter.enabledTokens(creditAccount);

        for (uint256 i = 0; i < creditFilter.allowedTokensCount(); i++) {
            tokenMask = 1 << i;
            if (enabledTokens & tokenMask > 0) {
                (
                    address token,
                    uint256 amount,
                    uint256 tv,
                    uint256 tvw
                ) = creditFilter.getCreditAccountTokenById(creditAccount, i);
                if (amount > 1) {
                    _safeTokenTransfer(
                        creditAccount,
                        token,
                        to,
                        amount.sub(1),
                        force
                    );


                    totalValue += tv;
                    totalWeightedValue += tvw;
                }
            }
        }
    }








    function _safeTokenTransfer(
        address creditAccount,
        address token,
        address to,
        uint256 amount,
        bool force
    ) internal {
        if (token != wethAddress) {
            try
                ICreditAccount(creditAccount).safeTransfer(token, to, amount)
            {} catch {
                require(force, Errors.CM_TRANSFER_FAILED);
            }
        } else {
            ICreditAccount(creditAccount).safeTransfer(
                token,
                wethGateway,
                amount
            );
            IWETHGateway(wethGateway).unwrapWETH(to, amount);
        }
    }






    function increaseBorrowedAmount(uint256 amount)
        external
        override
        whenNotPaused
        nonReentrant
    {
        address creditAccount = getCreditAccountOrRevert(msg.sender);

        (
            uint256 borrowedAmount,
            uint256 cumulativeIndexAtOpen
        ) = getCreditAccountParameters(creditAccount);

        require(
            borrowedAmount.add(amount) <
                maxAmount.mul(maxLeverageFactor).div(
                    Constants.LEVERAGE_DECIMALS
                ),
            Errors.CM_INCORRECT_AMOUNT
        );

        uint256 timeDiscountedAmount = amount.mul(cumulativeIndexAtOpen).div(
            IPoolService(poolService).calcLinearCumulative_RAY()
        );


        IPoolService(poolService).lendCreditAccount(amount, creditAccount);


        ICreditAccount(creditAccount).updateBorrowedAmount(
            borrowedAmount.add(timeDiscountedAmount)
        );

        require(
            creditFilter.calcCreditAccountHealthFactor(creditAccount) >=
                minHealthFactor,
            Errors.CM_CAN_UPDATE_WITH_SUCH_HEALTH_FACTOR
        );

        emit IncreaseBorrowedAmount(msg.sender, amount);
    }





    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    )
        external
        override
        whenNotPaused
        nonReentrant
    {
        address creditAccount = getCreditAccountOrRevert(onBehalfOf);
        creditFilter.checkAndEnableToken(creditAccount, token);
        IERC20(token).safeTransferFrom(msg.sender, creditAccount, amount);
        emit AddCollateral(onBehalfOf, token, amount);
    }









    function setParams(
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _maxLeverageFactor,
        uint256 _feeSuccess,
        uint256 _feeInterest,
        uint256 _feeLiquidation,
        uint256 _liquidationDiscount
    )
        public
        configuratorOnly
    {
        require(_minAmount <= _maxAmount, Errors.CM_INCORRECT_LIMITS);

        minAmount = _minAmount;
        maxAmount = _maxAmount;

        maxLeverageFactor = _maxLeverageFactor;

        feeSuccess = _feeSuccess;
        feeInterest = _feeInterest;
        feeLiquidation = _feeLiquidation;
        liquidationDiscount = _liquidationDiscount;


        minHealthFactor = liquidationDiscount
        .sub(feeLiquidation)
        .mul(maxLeverageFactor.add(Constants.LEVERAGE_DECIMALS))
        .div(maxLeverageFactor);

        if (address(creditFilter) != address(0)) {
            creditFilter.updateUnderlyingTokenLiquidationThreshold();
        }

        emit NewParameters(
            minAmount,
            maxAmount,
            maxLeverageFactor,
            feeSuccess,
            feeInterest,
            feeLiquidation,
            liquidationDiscount
        );
    }




    function approve(address targetContract, address token)
        external
        override
        whenNotPaused
        nonReentrant
    {
        address creditAccount = getCreditAccountOrRevert(msg.sender);


        require(
            creditFilter.contractToAdapter(targetContract) != address(0),
            Errors.CM_TARGET_CONTRACT_iS_NOT_ALLOWED
        );
        _provideCreditAccountAllowance(creditAccount, targetContract, token);
    }





    function provideCreditAccountAllowance(
        address creditAccount,
        address targetContract,
        address token
    )
        external
        override
        allowedAdaptersOnly(targetContract)
        whenNotPaused
        nonReentrant
    {
        _provideCreditAccountAllowance(creditAccount, targetContract, token);
    }





    function _provideCreditAccountAllowance(
        address creditAccount,
        address toContract,
        address token
    ) internal {

        if (
            IERC20(token).allowance(creditAccount, toContract) <
            Constants.MAX_INT_4
        ) {
            ICreditAccount(creditAccount).approveToken(token, toContract);
        }
    }




    function _convertAllAssetsToUnderlying(
        address creditAccount,
        DataTypes.Exchange[] calldata paths
    ) internal {
        uint256 tokenMask;
        uint256 enabledTokens = creditFilter.enabledTokens(creditAccount);

        for (uint256 i = 1; i < creditFilter.allowedTokensCount(); i++) {
            tokenMask = 1 << i;
            if (enabledTokens & tokenMask > 0) {
                (address tokenAddr, uint256 amount, , ) = creditFilter
                .getCreditAccountTokenById(creditAccount, i);

                if (amount > 0) {
                    _provideCreditAccountAllowance(
                        creditAccount,
                        defaultSwapContract,
                        tokenAddr
                    );


                    address[] memory currentPath = paths[i].path;
                    currentPath[0] = tokenAddr;
                    currentPath[paths[i].path.length - 1] = underlyingToken;

                    bytes memory data = abi.encodeWithSelector(
                        bytes4(0x38ed1739),
                        amount,
                        paths[i].amountOutMin,
                        currentPath,
                        creditAccount,
                        block.timestamp
                    );

                    CreditAccount(creditAccount).execute(
                        defaultSwapContract,
                        data
                    );
                }
            }
        }
    }





    function executeOrder(
        address borrower,
        address target,
        bytes memory data
    )
        external
        override
        allowedAdaptersOnly(target)
        whenNotPaused
        nonReentrant
        returns (bytes memory)
    {
        address creditAccount = getCreditAccountOrRevert(borrower);
        emit ExecuteOrder(borrower, target);
        return CreditAccount(creditAccount).execute(target, data);
    }







    function hasOpenedCreditAccount(address borrower)
        public
        view
        override
        returns (bool)
    {
        return creditAccounts[borrower] != address(0);
    }



    function getCreditAccountOrRevert(address borrower)
        public
        view
        override
        returns (address)
    {
        address result = creditAccounts[borrower];
        require(result != address(0), Errors.CM_NO_OPEN_ACCOUNT);
        return result;
    }








    function calcRepayAmount(address borrower, bool isLiquidated)
        external
        view
        override
        returns (uint256)
    {
        address creditAccount = getCreditAccountOrRevert(borrower);
        uint256 totalValue = creditFilter.calcTotalValue(creditAccount);

        (
            ,
            uint256 amountToPool,
            uint256 remainingFunds,
            ,

        ) = _calcClosePayments(creditAccount, totalValue, isLiquidated);

        return isLiquidated ? amountToPool.add(remainingFunds) : amountToPool;
    }





    function getCreditAccountParameters(address creditAccount)
        internal
        view
        returns (uint256 borrowedAmount, uint256 cumulativeIndexAtOpen)
    {
        borrowedAmount = ICreditAccount(creditAccount).borrowedAmount();
        cumulativeIndexAtOpen = ICreditAccount(creditAccount)
        .cumulativeIndexAtOpen();
    }



    function transferAccountOwnership(address newOwner)
        external
        override
        whenNotPaused
        nonReentrant
    {
        address creditAccount = getCreditAccountOrRevert(msg.sender);
        require(
            newOwner != address(0) && !hasOpenedCreditAccount(newOwner),
            Errors.CM_INCORRECT_NEW_OWNER
        );
        delete creditAccounts[msg.sender];
        creditAccounts[newOwner] = creditAccount;
        emit TransferAccount(msg.sender, newOwner);
    }
}
