



pragma solidity 0.6.10;

pragma experimental ABIEncoderV2;

import {CalleeInterface} from "../../interfaces/CalleeInterface.sol";
import {ZeroXExchangeInterface} from "../../interfaces/ZeroXExchangeInterface.sol";
import {ERC20Interface} from "../../interfaces/ERC20Interface.sol";
import {WETH9Interface} from "../../interfaces/WETH9Interface.sol";

import {SafeERC20} from "../../packages/oz/SafeERC20.sol";






contract TradeCallee is CalleeInterface {
    using SafeERC20 for ERC20Interface;


    uint256 private PROTOCOL_FEE_BASE = 70000;

    ZeroXExchangeInterface public exchange;
    WETH9Interface public weth;

    address public controller;

    constructor(
        address _exchange,
        address _weth,
        address _controller
    ) public {
        exchange = ZeroXExchangeInterface(_exchange);
        weth = WETH9Interface(_weth);
        controller = _controller;
    }






    function callFunction(address payable _sender, bytes memory _data) external override {
        require(msg.sender == controller, "TradeCallee: sender is not controller");

        (
            address trader,
            ZeroXExchangeInterface.LimitOrder[] memory orders,
            ZeroXExchangeInterface.Signature[] memory signatures,
            uint128[] memory takerTokenFillAmounts,
            bool revertIfIncomplete
        ) = abi.decode(
            _data,
            (address, ZeroXExchangeInterface.LimitOrder[], ZeroXExchangeInterface.Signature[], uint128[], bool)
        );




        require(
            tx.origin == trader,
            "TradeCallee: funds can only be transferred in from the person sending the transaction"
        );

        for (uint256 i = 0; i < orders.length; i++) {
            address takerAsset = orders[i].takerToken;

            ERC20Interface(takerAsset).safeTransferFrom(trader, address(this), takerTokenFillAmounts[i]);

            ERC20Interface(takerAsset).safeIncreaseAllowance(address(exchange), takerTokenFillAmounts[i]);
        }


        uint256 protocolFee = tx.gasprice * PROTOCOL_FEE_BASE * orders.length;
        weth.transferFrom(_sender, address(this), protocolFee);
        weth.withdraw(protocolFee);


        exchange.batchFillLimitOrders{value: protocolFee}(
            orders,
            signatures,
            takerTokenFillAmounts,
            revertIfIncomplete
        );

        for (uint256 i = 0; i < orders.length; i++) {

            address asset = orders[i].makerToken;

            uint256 balance = ERC20Interface(asset).balanceOf(address(this));
            if (balance > 0) {
                ERC20Interface(asset).safeTransfer(trader, balance);
            }


            asset = orders[i].takerToken;

            balance = ERC20Interface(asset).balanceOf(address(this));
            if (balance > 0) {
                ERC20Interface(asset).safeTransfer(trader, balance);
            }
        }
    }




    fallback() external payable {}
}
