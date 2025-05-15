

pragma solidity ^0.7.0;

import "../../utils/SafeERC20.sol";
import "../../interfaces
import "../../interfaces/exchange/IExchangeV3.sol";
import "../../DS/DSMath.sol";
import "../../auth/AdminAuth.sol";

contract KyberWrapperV3 is DSMath, IExchangeV3, AdminAuth {

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant KYBER_INTERFACE = 0x9AAb3f75489902f3a48495025729a0AF77d4b11e;
    address payable public constant WALLET_ID = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;

    using SafeERC20 for IERC20;






    function sell(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory) external override payable returns (uint) {
        IERC20 srcToken = IERC20(_srcAddr);
        IERC20 destToken = IERC20(_destAddr);

        KyberNetworkProxyInterface kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcToken.safeApprove(address(kyberNetworkProxy), _srcAmount);
        }

        uint destAmount = kyberNetworkProxy.trade{value: msg.value}(
            srcToken,
            _srcAmount,
            destToken,
            msg.sender,
            type(uint).max,
            0,
            WALLET_ID
        );

        return destAmount;
    }






    function buy(address _srcAddr, address _destAddr, uint _destAmount, bytes memory) external override payable returns(uint) {
        IERC20 srcToken = IERC20(_srcAddr);
        IERC20 destToken = IERC20(_destAddr);

        uint srcAmount = 0;
        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcAmount = srcToken.balanceOf(address(this));
        } else {
            srcAmount = msg.value;
        }

        KyberNetworkProxyInterface kyberNetworkProxy = KyberNetworkProxyInterface(KYBER_INTERFACE);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcToken.safeApprove(address(kyberNetworkProxy), srcAmount);
        }

        uint destAmount = kyberNetworkProxy.trade{value: msg.value}(
            srcToken,
            srcAmount,
            destToken,
            msg.sender,
            _destAmount,
            0,
            WALLET_ID
        );

        require(destAmount == _destAmount, "Wrong dest amount");

        uint srcAmountAfter = 0;

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            srcAmountAfter = srcToken.balanceOf(address(this));
        } else {
            srcAmountAfter = address(this).balance;
        }


        sendLeftOver(_srcAddr);

        return (srcAmount - srcAmountAfter);
    }







    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount, bytes memory) public override view returns (uint rate) {
        (rate, ) = KyberNetworkProxyInterface(KYBER_INTERFACE)
            .getExpectedRate(IERC20(_srcAddr), IERC20(_destAddr), _srcAmount);


        rate = rate * (10**(18 - getDecimals(_srcAddr)));

        rate = rate / (10**(18 - getDecimals(_destAddr)));
    }






    function getBuyRate(address _srcAddr, address _destAddr, uint _destAmount, bytes memory _additionalData) public override view returns (uint rate) {
        uint256 srcRate = getSellRate(_destAddr, _srcAddr, _destAmount, _additionalData);
        uint256 srcAmount = wmul(srcRate, _destAmount);

        rate = getSellRate(_srcAddr, _destAddr, srcAmount, _additionalData);


        rate = rate + (rate / 30);
    }



    function sendLeftOver(address _srcAddr) internal {
        msg.sender.transfer(address(this).balance);

        if (_srcAddr != KYBER_ETH_ADDRESS) {
            IERC20(_srcAddr).safeTransfer(msg.sender, IERC20(_srcAddr).balanceOf(address(this)));
        }
    }


    receive() payable external {}

    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return IERC20(_token).decimals();
    }
}
