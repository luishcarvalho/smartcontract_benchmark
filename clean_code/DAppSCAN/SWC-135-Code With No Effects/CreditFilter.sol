


pragma solidity ^0.7.4;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";

import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {ICreditAccount} from "../interfaces/ICreditAccount.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {IPoolService} from "../interfaces/IPoolService.sol";

import {AddressProvider} from "../core/AddressProvider.sol";
import {ACLTrait} from "../core/ACLTrait.sol";
import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

import "hardhat/console.sol";
import "../core/ContractsRegister.sol";










contract CreditFilter is ICreditFilter, ACLTrait {
    using PercentageMath for uint256;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;


    address public creditManager;


    mapping(address => bool) public _allowedTokensMap;


    address[] public override allowedTokens;


    mapping(address => uint256) public override liquidationThresholds;


    mapping(address => uint256) public tokenMasksMap;


    mapping(address => uint256) public override enabledTokens;


    mapping(address => uint256) public fastCheckCounter;


    EnumerableSet.AddressSet private allowedContractsSet;


    mapping(address => bool) public allowedAdapters;



    mapping(address => address) public override contractToAdapter;


    address public override priceOracle;


    address public override underlyingToken;


    address public poolService;


    address public wethAddress;


    uint256 public chiThreshold;


    uint256 public hfCheckInterval;


    modifier creditManagerOnly {
        require(msg.sender == creditManager, Errors.CF_CREDIT_MANAGERS_ONLY);
        _;
    }


    modifier adapterOnly {
        require(allowedAdapters[msg.sender], Errors.CF_ADAPTERS_ONLY);
        _;
    }


    modifier duringConfigOnly() {
        require(
            creditManager == address(0),
            Errors.IMMUTABLE_CONFIG_CHANGES_FORBIDDEN
        );
        _;
    }

    constructor(address _addressProvider, address _underlyingToken)
        ACLTrait(_addressProvider)
    {
        priceOracle = AddressProvider(_addressProvider).getPriceOracle();

        wethAddress = AddressProvider(_addressProvider).getWethToken();

        underlyingToken = _underlyingToken;

        liquidationThresholds[underlyingToken] = Constants
        .UNDERLYING_TOKEN_LIQUIDATION_THRESHOLD;

        allowToken(
            underlyingToken,
            Constants.UNDERLYING_TOKEN_LIQUIDATION_THRESHOLD
        );

        setFastCheckParameters(
            Constants.CHI_THRESHOLD,
            Constants.HF_CHECK_INTERVAL_DEFAULT
        );
    }








    function allowToken(address token, uint256 liquidationThreshold)
        public
        override
        configuratorOnly
    {
        require(token != address(0), Errors.ZERO_ADDRESS_IS_NOT_ALLOWED);

        require(
            liquidationThreshold > 0 &&
                liquidationThreshold <= liquidationThresholds[underlyingToken],
            Errors.CF_INCORRECT_LIQUIDATION_THRESHOLD
        );

        require(allowedTokens.length < 256, Errors.CF_TOO_MUCH_ALLOWED_TOKENS);



        require(IERC20(token).balanceOf(address(this)) >= 0);


        IPriceOracle(priceOracle).getLastPrice(token, underlyingToken);



        if (!_allowedTokensMap[token]) {
            _allowedTokensMap[token] = true;

            tokenMasksMap[token] = 1 << allowedTokens.length;
            allowedTokens.push(token);
        }

        liquidationThresholds[token] = liquidationThreshold;

        emit TokenAllowed(token, liquidationThreshold);
    }





    function allowContract(address targetContract, address adapter)
        external
        override
        configuratorOnly
    {
        require(
            targetContract != address(0) && adapter != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );


        allowedAdapters[contractToAdapter[targetContract]] = false;
        allowedAdapters[adapter] = true;

        allowedContractsSet.add(targetContract);

        contractToAdapter[targetContract] = adapter;

        emit ContractAllowed(targetContract, adapter);
    }



    function forbidContract(address targetContract)
        external
        override
        configuratorOnly
    {
        require(
            targetContract != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );

        require(
            allowedContractsSet.remove(targetContract),
            Errors.CF_CONTRACT_IS_NOT_IN_ALLOWED_LIST
        );


        allowedAdapters[contractToAdapter[targetContract]] = false;


        contractToAdapter[targetContract] = address(0);

        emit ContractForbidden(targetContract);
    }


    function connectCreditManager(address _creditManager)
        external
        override
        duringConfigOnly
        configuratorOnly
    {
        creditManager = _creditManager;
        poolService = ICreditManager(_creditManager).poolService();

        require(
            IPoolService(poolService).underlyingToken() == underlyingToken,
            Errors.CF_UNDERLYING_TOKEN_FILTER_CONFLICT
        );
    }







    function checkCollateralChange(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    )
        public
        override
        adapterOnly
    {
        _checkAndEnableToken(creditAccount, tokenOut);


        uint256 amountInCollateral = IPriceOracle(priceOracle).convert(
            amountIn,
            tokenIn,
            wethAddress
        );


        uint256 amountOutCollateral = IPriceOracle(priceOracle).convert(
            amountOut,
            tokenOut,
            wethAddress
        );

        _checkCollateral(
            creditAccount,
            amountInCollateral,
            amountOutCollateral
        );
    }




    function checkMultiTokenCollateral(
        address creditAccount,
        uint256[] memory amountIn,
        uint256[] memory amountOut,
        address[] memory tokenIn,
        address[] memory tokenOut
    )
        external
        override
        adapterOnly
    {


        uint256 amountInCollateral = 0;
        uint256 amountOutCollateral = 0;

        for (uint256 i = 0; i < amountIn.length; i++) {
            amountInCollateral = amountInCollateral.add(
                IPriceOracle(priceOracle).convert(
                    amountIn[i],
                    tokenIn[i],
                    wethAddress
                )
            );
        }

        for (uint256 i = 0; i < amountOut.length; i++) {
            _checkAndEnableToken(creditAccount, tokenOut[i]);
            amountOutCollateral = amountOutCollateral.add(
                IPriceOracle(priceOracle).convert(
                    amountOut[i],
                    tokenOut[i],
                    wethAddress
                )
            );
        }

        _checkCollateral(
            creditAccount,
            amountInCollateral,
            amountOutCollateral
        );
    }



    function _checkCollateral(
        address creditAccount,
        uint256 collateralIn,
        uint256 collateralOut
    ) internal {
        if (
            (collateralOut.mul(PercentageMath.PERCENTAGE_FACTOR) >
                collateralIn.mul(chiThreshold)) &&
            fastCheckCounter[creditAccount] <= hfCheckInterval
        ) {
            fastCheckCounter[creditAccount]++;
        } else {


            console.log(calcCreditAccountHealthFactor(creditAccount));
            require(
                calcCreditAccountHealthFactor(creditAccount) >=
                    PercentageMath.PERCENTAGE_FACTOR,
                Errors.CF_OPERATION_LOW_HEALTH_FACTOR
            );
            fastCheckCounter[creditAccount] = 1;
        }
    }


    function initEnabledTokens(address creditAccount)
        external
        override
        creditManagerOnly
    {

        enabledTokens[creditAccount] = 1;
        fastCheckCounter[creditAccount] = 1;
    }





    function checkAndEnableToken(address creditAccount, address token)
        external
        override
        creditManagerOnly
    {
        _checkAndEnableToken(creditAccount, token);
    }





    function _checkAndEnableToken(address creditAccount, address token)
        internal
    {
        revertIfTokenNotAllowed(token);

        if (enabledTokens[creditAccount] & tokenMasksMap[token] == 0) {
            enabledTokens[creditAccount] =
                enabledTokens[creditAccount] |
                tokenMasksMap[token];
        }
    }



    function changeAllowedTokenState(address token, bool state)
        external
        configuratorOnly
    {
        _allowedTokensMap[token] = state;
    }



    function setFastCheckParameters(
        uint256 _chiThreshold,
        uint256 _hfCheckInterval
    )
        public
        configuratorOnly
    {
        chiThreshold = _chiThreshold;
        hfCheckInterval = _hfCheckInterval;

        revertIfIncorrectFastCheckParams();

        emit NewFastCheckParameters(_chiThreshold, _hfCheckInterval);
    }





    function updateUnderlyingTokenLiquidationThreshold()
        external
        override
        creditManagerOnly
    {
        require(
            ICreditManager(creditManager).feeSuccess() <
                PercentageMath.PERCENTAGE_FACTOR &&
                ICreditManager(creditManager).feeInterest() <
                PercentageMath.PERCENTAGE_FACTOR &&
                ICreditManager(creditManager).feeLiquidation() <
                PercentageMath.PERCENTAGE_FACTOR &&
                ICreditManager(creditManager).liquidationDiscount() <
                PercentageMath.PERCENTAGE_FACTOR,
            Errors.CM_INCORRECT_FEES
        );


        require(
            ICreditManager(creditManager).minHealthFactor() >
                PercentageMath.PERCENTAGE_FACTOR,
            Errors.CM_MAX_LEVERAGE_IS_TOO_HIGH
        );

        liquidationThresholds[underlyingToken] = ICreditManager(creditManager)
        .liquidationDiscount()
        .sub(ICreditManager(creditManager).feeLiquidation());

        for (uint256 i = 1; i < allowedTokens.length; i++) {
            require(
                liquidationThresholds[allowedTokens[i]] <=
                    liquidationThresholds[underlyingToken],
                Errors.CF_SOME_LIQUIDATION_THRESHOLD_MORE_THAN_NEW_ONE
            );
        }

        revertIfIncorrectFastCheckParams();
    }


    function revertIfIncorrectFastCheckParams() internal view {

        if (creditManager != address(0)) {

            uint256 maxPossibleDrop = PercentageMath.PERCENTAGE_FACTOR.sub(
                calcMaxPossibleDrop(chiThreshold, hfCheckInterval)
            );

            require(
                maxPossibleDrop <
                    ICreditManager(creditManager).feeLiquidation(),
                Errors.CF_FAST_CHECK_NOT_COVERED_COLLATERAL_DROP
            );
        }
    }



    function calcMaxPossibleDrop(uint256 percentage, uint256 times)
        public
        pure
        returns (uint256 value)
    {
        value = PercentageMath.PERCENTAGE_FACTOR.mul(percentage);
        for (uint256 i = 0; i < times.sub(1); i++) {
            value = value.mul(percentage).div(PercentageMath.PERCENTAGE_FACTOR);
        }
        value = value.div(PercentageMath.PERCENTAGE_FACTOR);
    }









    function calcTotalValue(address creditAccount)
        external
        view
        override
        returns (uint256 total)
    {
        total = 0;

        uint256 tokenMask;
        uint256 eTokens = enabledTokens[creditAccount];
        for (uint256 i = 0; i < allowedTokensCount(); i++) {
            tokenMask = 1 << i;
            if (eTokens & tokenMask > 0) {
                (, , uint256 tv, ) = getCreditAccountTokenById(
                    creditAccount,
                    i
                );
                total = total.add(tv);
            }
        }
    }





    function calcThresholdWeightedValue(address creditAccount)
        public
        view
        override
        returns (uint256 total)
    {
        total = 0;
        uint256 tokenMask;
        uint256 eTokens = enabledTokens[creditAccount];
        for (uint256 i = 0; i < allowedTokensCount(); i++) {
            tokenMask = 1 << i;
            if (eTokens & tokenMask > 0) {
                (, , , uint256 twv) = getCreditAccountTokenById(
                    creditAccount,
                    i
                );
                total = total.add(twv);
            }
        }
        return total.div(PercentageMath.PERCENTAGE_FACTOR);
    }


    function allowedTokensCount() public view override returns (uint256) {
        return allowedTokens.length;
    }


    function isTokenAllowed(address token) public view override returns (bool) {
        return _allowedTokensMap[token];
    }


    function revertIfTokenNotAllowed(address token) public view override {
        require(isTokenAllowed(token), Errors.CF_TOKEN_IS_NOT_ALLOWED);
    }


    function allowedContractsCount() public view override returns (uint256) {
        return allowedContractsSet.length();
    }


    function allowedContracts(uint256 i)
        public
        view
        override
        returns (address)
    {
        return allowedContractsSet.at(i);
    }








    function getCreditAccountTokenById(address creditAccount, uint256 id)
        public
        view
        override
        returns (
            address token,
            uint256 balance,
            uint256 tv,
            uint256 tvw
        )
    {
        token = allowedTokens[id];
        balance = IERC20(token).balanceOf(creditAccount);


        if (balance > 1) {
            tv = IPriceOracle(priceOracle).convert(
                balance,
                token,
                underlyingToken
            );
            tvw = tv.mul(liquidationThresholds[token]);
        }
    }





    function calcCreditAccountAccruedInterest(address creditAccount)
        public
        view
        override
        returns (uint256)
    {
        return
            ICreditAccount(creditAccount)
                .borrowedAmount()
                .mul(IPoolService(poolService).calcLinearCumulative_RAY())
                .div(ICreditAccount(creditAccount).cumulativeIndexAtOpen());
    }














    function calcCreditAccountHealthFactor(address creditAccount)
        public
        view
        override
        returns (uint256)
    {
        return
            calcThresholdWeightedValue(creditAccount)
                .mul(PercentageMath.PERCENTAGE_FACTOR)
                .div(calcCreditAccountAccruedInterest(creditAccount));
    }
}
