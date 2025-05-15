


pragma solidity ^0.7.4;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {AddressProvider} from "./AddressProvider.sol";
import {ContractsRegister} from "./ContractsRegister.sol";

import {IPoolService} from "../interfaces/IPoolService.sol";
import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {IWETH} from "../interfaces/external/IWETH.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";

import {Errors} from "../libraries/helpers/Errors.sol";
import {Constants} from "../libraries/helpers/Constants.sol";

import "hardhat/console.sol";



contract WETHGateway is IWETHGateway {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    address public wethAddress;
    ContractsRegister internal _contractsRegister;


    modifier wethPoolOnly(address pool) {

        require(
            _contractsRegister.isPool(pool),
            Errors.WG_DESTINATION_IS_NOT_POOL
        );

        require(
            IPoolService(pool).underlyingToken() == wethAddress,
            Errors.WG_DESTINATION_IS_NOT_WETH_COMPATIBLE
        );
        _;
    }


    modifier wethCreditManagerOnly(address creditManager) {


        require(
            _contractsRegister.isCreditManager(creditManager),
            Errors.WG_DESTINATION_IS_NOT_CREDIT_MANAGER
        );

        require(
            ICreditManager(creditManager).underlyingToken() == wethAddress,
            Errors.WG_DESTINATION_IS_NOT_WETH_COMPATIBLE
        );

        _;
    }


    modifier creditManagerOnly(address creditManager) {


        require(
            _contractsRegister.isCreditManager(creditManager),
            Errors.WG_DESTINATION_IS_NOT_CREDIT_MANAGER
        );

        _;
    }







    constructor(address addressProvider) {
        wethAddress = AddressProvider(addressProvider).getWethToken();
        _contractsRegister = ContractsRegister(
            AddressProvider(addressProvider).getContractsRegister()
        );
    }








    function addLiquidityETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    )
        external
        payable
        override
        wethPoolOnly(pool)
    {
        IWETH(wethAddress).deposit{value: msg.value}();

        _checkAllowance(pool, msg.value);
        IPoolService(pool).addLiquidity(msg.value, onBehalfOf, referralCode);
    }








    function removeLiquidityETH(
        address pool,
        uint256 amount,
        address payable to
    )
        external
        override
        wethPoolOnly(pool)
    {
        IERC20(IPoolService(pool).dieselToken()).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 amountGet = IPoolService(pool).removeLiquidity(
            amount,
            address(this)
        );
        _unwrapWETH(to, amountGet);
    }









    function openCreditAccountETH(
        address creditManager,
        address payable onBehalfOf,
        uint256 leverageFactor,
        uint256 referralCode
    )
        external
        payable
        override
        wethCreditManagerOnly(creditManager)
    {
        _checkAllowance(creditManager, msg.value);

        IWETH(wethAddress).deposit{value: msg.value}();
        ICreditManager(creditManager).openCreditAccount(
            msg.value,
            onBehalfOf,
            leverageFactor,
            referralCode
        );
    }







    function repayCreditAccountETH(address creditManager, address to)
        external
        payable
        override
        wethCreditManagerOnly(creditManager)
    {
        uint256 amount = msg.value;

        IWETH(wethAddress).deposit{value: amount}();

        _checkAllowance(creditManager, amount);


        uint256 repayAmount = ICreditManager(creditManager)
        .repayCreditAccountETH(msg.sender, to);

        if (amount > repayAmount) {
            IWETH(wethAddress).withdraw(amount.sub(repayAmount));
            msg.sender.sendValue(amount.sub(repayAmount));
        }
    }

    function addCollateralETH(address creditManager, address onBehalfOf)
        external
        payable
        override
        creditManagerOnly(creditManager)
    {
        uint256 amount = msg.value;

        IWETH(wethAddress).deposit{value: amount}();
        _checkAllowance(creditManager, amount);
        ICreditManager(creditManager).addCollateral(
            onBehalfOf,
            wethAddress,
            amount
        );
    }


    function unwrapWETH(address to, uint256 amount)
        external
        override
        creditManagerOnly(msg.sender)
    {
        _unwrapWETH(to, amount);
    }

    function _unwrapWETH(address to, uint256 amount) internal {
        IWETH(wethAddress).withdraw(amount);
        payable(to).sendValue(amount);
    }

    function _checkAllowance(address spender, uint256 amount) internal {
        if (IERC20(wethAddress).allowance(address(this), spender) < amount) {
            IERC20(wethAddress).approve(spender, Constants.MAX_INT);
        }
    }


    receive() external payable {
        require(
            msg.sender == address(wethAddress),
            Errors.WG_RECEIVE_IS_NOT_ALLOWED
        );
    }
}
