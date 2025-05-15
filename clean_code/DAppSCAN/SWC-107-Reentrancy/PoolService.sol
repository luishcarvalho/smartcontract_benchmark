


pragma solidity ^0.7.4;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ACLTrait} from "../core/ACLTrait.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";

import {IInterestRateModel} from "../interfaces/IInterestRateModel.sol";
import {IPoolService} from "../interfaces/IPoolService.sol";
import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {ICreditManager} from "../interfaces/ICreditManager.sol";

import {AddressProvider} from "../core/AddressProvider.sol";
import {DieselToken} from "../tokens/DieselToken.sol";
import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

import "hardhat/console.sol";








contract PoolService is IPoolService, ACLTrait, ReentrancyGuard {
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;
    using PercentageMath for uint256;


    uint256 public _expectedLiquidityLU;


    uint256 public override expectedLiquidityLimit;


    uint256 public override totalBorrowed;


    AddressProvider public addressProvider;


    IInterestRateModel public interestRateModel;


    address public override underlyingToken;


    address public override dieselToken;


    mapping(address => bool) public override creditManagersCanBorrow;
    mapping(address => bool) public creditManagersCanRepay;


    address[] public override creditManagers;


    address public treasuryAddress;


    uint256 public override _cumulativeIndex_RAY;


    uint256 public override borrowAPY_RAY;


    uint256 public override _timestampLU;


    uint256 public override withdrawFee;


    uint256 public withdrawMultiplier;










    constructor(
        address _addressProvider,
        address _underlyingToken,
        address _dieselAddress,
        address _interestRateModelAddress
    ) ACLTrait(_addressProvider) {
        addressProvider = AddressProvider(_addressProvider);
        interestRateModel = IInterestRateModel(_interestRateModelAddress);
        underlyingToken = _underlyingToken;
        dieselToken = _dieselAddress;
        treasuryAddress = addressProvider.getTreasuryContract();

        _cumulativeIndex_RAY = WadRayMath.RAY;
        _updateBorrowRate();

        setWithdrawFee(0);
    }





















    function addLiquidity(
        uint256 amount,
        address onBehalfOf,
        uint256 referralCode
    )
        external
        override
        whenNotPaused
        nonReentrant
    {

        require(
            expectedLiquidity() + amount <= expectedLiquidityLimit,
            Errors.POOL_MORE_THAN_EXPECTED_LIQUIDITY_LIMIT
        );

        IERC20(underlyingToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        DieselToken(dieselToken).mint(onBehalfOf, toDiesel(amount));

        _expectedLiquidityLU = _expectedLiquidityLU.add(amount);
        _updateBorrowRate();

        emit AddLiquidity(msg.sender, onBehalfOf, amount, referralCode);
    }













    function removeLiquidity(uint256 amount, address to)
        external
        override
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        uint256 underlyingTokensAmount = fromDiesel(amount);

        uint256 amountSent = underlyingTokensAmount.percentMul(
            withdrawMultiplier
        );

        IERC20(underlyingToken).safeTransfer(to, amountSent);
        IERC20(underlyingToken).safeTransfer(
            treasuryAddress,
            underlyingTokensAmount.percentMul(withdrawFee)
        );
        DieselToken(dieselToken).burn(msg.sender, amount);

        _expectedLiquidityLU = _expectedLiquidityLU.sub(underlyingTokensAmount);
        _updateBorrowRate();

        emit RemoveLiquidity(msg.sender, to, amount);

        return amountSent;
    }





    function expectedLiquidity() public view override returns (uint256) {

        uint256 timeDifference = block.timestamp.sub(uint256(_timestampLU));





        uint256 interestAccrued = totalBorrowed.rayMul(
            borrowAPY_RAY.mul(timeDifference).div(Constants.SECONDS_PER_YEAR)
        );

        return _expectedLiquidityLU.add(interestAccrued);
    }



    function availableLiquidity() public view override returns (uint256) {
        return IERC20(underlyingToken).balanceOf(address(this));
    }











    function lendCreditAccount(uint256 borrowedAmount, address creditAccount)
        external
        override
        whenNotPaused
    {
        require(
            creditManagersCanBorrow[msg.sender],
            Errors.POOL_CREDIT_MANAGERS_ONLY
        );


        IERC20(underlyingToken).safeTransfer(creditAccount, borrowedAmount);


        _updateBorrowRate();


        totalBorrowed = totalBorrowed.add(borrowedAmount);

        emit Borrow(msg.sender, creditAccount, borrowedAmount);
    }







    function repayCreditAccount(
        uint256 borrowedAmount,
        uint256 profit,
        uint256 loss
    )
        external
        override
        whenNotPaused
    {
        require(
            creditManagersCanRepay[msg.sender],
            Errors.POOL_CREDIT_MANAGERS_ONLY
        );


        if (profit > 0) {

            DieselToken(dieselToken).mint(treasuryAddress, toDiesel(profit));
            _expectedLiquidityLU = _expectedLiquidityLU.add(profit);
        }



        else {
            uint256 amountToBurn = toDiesel(loss);

            uint256 treasuryBalance = DieselToken(dieselToken).balanceOf(
                treasuryAddress
            );

            if (treasuryBalance < amountToBurn) {
                amountToBurn = treasuryBalance;
                emit UncoveredLoss(
                    msg.sender,
                    loss.sub(fromDiesel(treasuryBalance))
                );
            }



            DieselToken(dieselToken).burn(treasuryAddress, amountToBurn);

            _expectedLiquidityLU = _expectedLiquidityLU.sub(loss);
        }


        _updateBorrowRate();


        totalBorrowed = totalBorrowed.sub(borrowedAmount);

        emit Repay(msg.sender, borrowedAmount, profit, loss);
    }














    function calcLinearCumulative_RAY() public view override returns (uint256) {

        uint256 timeDifference = block.timestamp.sub(uint256(_timestampLU));

        return
            calcLinearIndex_RAY(
                _cumulativeIndex_RAY,
                borrowAPY_RAY,
                timeDifference
            );
    }






    function calcLinearIndex_RAY(
        uint256 cumulativeIndex_RAY,
        uint256 currentBorrowRate_RAY,
        uint256 timeDifference
    ) public pure returns (uint256) {




        uint256 linearAccumulated_RAY = WadRayMath.RAY.add(
            currentBorrowRate_RAY.mul(timeDifference).div(
                Constants.SECONDS_PER_YEAR
            )
        );

        return cumulativeIndex_RAY.rayMul(linearAccumulated_RAY);
    }





    function _updateBorrowRate() internal {


        _expectedLiquidityLU = expectedLiquidity();


        _cumulativeIndex_RAY = calcLinearCumulative_RAY();


        borrowAPY_RAY = interestRateModel.calcBorrowRate(
            _expectedLiquidityLU,
            availableLiquidity()
        );
        _timestampLU = block.timestamp;
    }







    function getDieselRate_RAY() public view override returns (uint256) {
        uint256 dieselSupply = IERC20(dieselToken).totalSupply();
        if (dieselSupply == 0) return WadRayMath.RAY;
        return expectedLiquidity().rayDiv(dieselSupply);
    }



    function toDiesel(uint256 amount) public view override returns (uint256) {
        return amount.rayDiv(getDieselRate_RAY());
    }



    function fromDiesel(uint256 amount) public view override returns (uint256) {
        return amount.rayMul(getDieselRate_RAY());
    }







    function connectCreditManager(address _creditManager)
        external
        configuratorOnly
    {
        require(
            address(this) == ICreditManager(_creditManager).poolService(),
            Errors.POOL_INCOMPATIBLE_CREDIT_ACCOUNT_MANAGER
        );

        require(
            !creditManagersCanRepay[_creditManager],
            Errors.POOL_CANT_ADD_CREDIT_MANAGER_TWICE
        );

        creditManagersCanBorrow[_creditManager] = true;
        creditManagersCanRepay[_creditManager] = true;
        creditManagers.push(_creditManager);
        emit NewCreditManagerConnected(_creditManager);
    }



    function forbidCreditManagerToBorrow(address _creditManager)
        external
        configuratorOnly
    {
        creditManagersCanBorrow[_creditManager] = false;
        emit BorrowForbidden(_creditManager);
    }



    function newInterestRateModel(address _interestRateModel)
        external
        configuratorOnly
    {
        interestRateModel = IInterestRateModel(_interestRateModel);
        _updateBorrowRate();
        emit NewInterestRateModel(_interestRateModel);
    }



    function setExpectedLiquidityLimit(uint256 newLimit)
        external
        configuratorOnly
    {
        expectedLiquidityLimit = newLimit;
        emit NewExpectedLiquidityLimit(newLimit);
    }


    function setWithdrawFee(uint256 fee)
        public
        configuratorOnly
    {
        require(
            fee < Constants.MAX_WITHDRAW_FEE,
            Errors.POOL_INCORRECT_WITHDRAW_FEE
        );
        withdrawFee = fee;
        withdrawMultiplier = PercentageMath.PERCENTAGE_FACTOR.sub(fee);
    }


    function creditManagersCount() external view override returns (uint256) {
        return creditManagers.length;
    }
}
