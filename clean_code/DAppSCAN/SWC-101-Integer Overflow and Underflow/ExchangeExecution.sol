















pragma solidity 0.5.4;

import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";

import { CommonMath } from "../../../lib/CommonMath.sol";
import { ExchangeHeaderLibrary } from "../../lib/ExchangeHeaderLibrary.sol";
import { ExchangeIssuanceLibrary } from "./ExchangeIssuanceLibrary.sol";
import { ExchangeWrapperLibrary } from "../../lib/ExchangeWrapperLibrary.sol";
import { ISetToken } from "../../interfaces/ISetToken.sol";
import { ModuleCoreState } from "./ModuleCoreState.sol";








contract ExchangeExecution is
    ModuleCoreState
{
    using SafeMath for uint256;









    function executeExchangeOrders(
        bytes memory _orderData
    )
        internal
    {

        uint256 calledExchanges = 0;

        uint256 scannedBytes = 0;
        while (scannedBytes < _orderData.length) {

            ExchangeHeaderLibrary.ExchangeHeader memory header = ExchangeHeaderLibrary.parseExchangeHeader(
                _orderData,
                scannedBytes
            );


            address exchangeWrapper = coreInstance.exchangeIds(header.exchange);


            require(
                exchangeWrapper != address(0),
                "ExchangeExecution.executeExchangeOrders: Invalid or disabled Exchange address"
            );




            uint256 exchangeBitIndex = CommonMath.safePower(2, header.exchange);
            require(
                (calledExchanges & exchangeBitIndex) == 0,
                "ExchangeExecution.executeExchangeOrders: Exchange already called"
            );


            uint256 exchangeDataLength = header.orderDataBytesLength.add(
                ExchangeHeaderLibrary.EXCHANGE_HEADER_LENGTH()
            );


            bytes memory bodyData = ExchangeHeaderLibrary.sliceBodyData(
                _orderData,
                scannedBytes,
                exchangeDataLength
            );


            ExchangeWrapperLibrary.ExchangeData memory exchangeData = ExchangeWrapperLibrary.ExchangeData({
                caller: msg.sender,
                orderCount: header.orderCount
            });


            ExchangeWrapperLibrary.callExchange(
                core,
                exchangeData,
                exchangeWrapper,
                bodyData
            );


            scannedBytes = scannedBytes.add(exchangeDataLength);


            calledExchanges = calledExchanges.add(exchangeBitIndex);
        }
    }







    function calculateReceiveTokenBalances(
        ExchangeIssuanceLibrary.ExchangeIssuanceParams memory _exchangeIssuanceParams
    )
        internal
        view
        returns (uint256[] memory)
    {

        uint256[] memory requiredBalances = new uint256[](_exchangeIssuanceParams.receiveTokens.length);
        for (uint256 i = 0; i < _exchangeIssuanceParams.receiveTokens.length; i++) {

            uint256 tokenBalance = vaultInstance.getOwnerBalance(
                _exchangeIssuanceParams.receiveTokens[i],
                msg.sender
            );


            uint256 requiredAddition = _exchangeIssuanceParams.receiveTokenAmounts[i];


            requiredBalances[i] = tokenBalance.add(requiredAddition);
        }

        return requiredBalances;
    }






    function validateExchangeIssuanceParams(
        ExchangeIssuanceLibrary.ExchangeIssuanceParams memory _exchangeIssuanceParams
    )
        internal
        view
    {

        require(
            coreInstance.validSets(_exchangeIssuanceParams.setAddress),
            "ExchangeExecution.validateExchangeIssuanceParams: Invalid or disabled SetToken address"
        );


        ExchangeIssuanceLibrary.validateQuantity(
            _exchangeIssuanceParams.setAddress,
            _exchangeIssuanceParams.quantity
        );


        ExchangeIssuanceLibrary.validateSendTokenParams(
            core,
            _exchangeIssuanceParams.sendTokenExchangeIds,
            _exchangeIssuanceParams.sendTokens,
            _exchangeIssuanceParams.sendTokenAmounts
        );


        ExchangeIssuanceLibrary.validateReceiveTokens(
            _exchangeIssuanceParams.receiveTokens,
            _exchangeIssuanceParams.receiveTokenAmounts
        );
    }
}
