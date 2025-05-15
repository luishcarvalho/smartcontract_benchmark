


pragma solidity ^0.7.4;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {ICurvePool} from "../integrations/curve/ICurvePool.sol";

import {CreditAccount} from "../credit/CreditAccount.sol";
import {CreditManager} from "../credit/CreditManager.sol";

import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

import "hardhat/console.sol";


contract CurveV1Adapter is ICurvePool {
    using SafeMath for uint256;


    ICurvePool public curvePool;
    ICreditManager public creditManager;
    ICreditFilter public creditFilter;




    constructor(address _creditManager, address _curvePool) {
        creditManager = ICreditManager(_creditManager);
        creditFilter = ICreditFilter(creditManager.creditFilter());

        curvePool = ICurvePool(_curvePool);
    }

    function coins(uint256 i) external view override returns (address) {
        return ICurvePool(curvePool).coins(i);
    }







    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external override {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        address tokenIn = curvePool.coins(uint256(i));
        address tokenOut = curvePool.coins(uint256(j));

        creditManager.provideCreditAccountAllowance(
            creditAccount,
            address(curvePool),
            tokenIn
        );

        bytes memory data = abi.encodeWithSelector(
            bytes4(0x3df02124),
            i,
            j,
            dx,
            min_dy
        );

        creditManager.executeOrder(msg.sender, address(curvePool), data);

        creditFilter.checkCollateralChange(
            creditAccount,
            tokenIn,
            tokenOut,
            dx,
            min_dy
        );
    }

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external override {
        revert(Errors.NOT_IMPLEMENTED);
    }


    function get_dx_underlying(
        int128 i,
        int128 j,
        uint256 dy
    ) external view override returns (uint256) {
        return curvePool.get_dx_underlying(i, j, dy);
    }

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        return curvePool.get_dy_underlying(i, j, dx);
    }


    function get_dx(
        int128 i,
        int128 j,
        uint256 dy
    ) external view override returns (uint256) {
        return curvePool.get_dx(i, j, dy);
    }

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        return curvePool.get_dy(i, j, dx);
    }

    function get_virtual_price() external view override returns (uint256) {
        return curvePool.get_virtual_price();
    }
}
