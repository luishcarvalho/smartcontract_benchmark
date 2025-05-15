












pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IBasicIssuanceModule } from "../interfaces/IBasicIssuanceModule.sol";
import { IController } from "../interfaces/IController.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { SushiswapV2Library } from "../../external/contracts/SushiswapV2Library.sol";
import { UniswapV2Library } from "../../external/contracts/UniswapV2Library.sol";









contract ExchangeIssuance is ReentrancyGuard {

    using SafeMath for uint256;
    using PreciseUnitMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ISetToken;















































































    function approveToken(IERC20 _token) public {
        _safeApprove(_token, address(uniRouter));
        _safeApprove(_token, address(sushiRouter));
        _safeApprove(_token, address(basicIssuanceModule));
    }








    function approveTokens(IERC20[] calldata _tokens) external {
        for (uint256 i = 0; i < _tokens.length; i++) {
            approveToken(_tokens[i]);
        }
    }








    function approveSetToken(ISetToken _setToken) external {
        address[] memory components = _setToken.getComponents();
        for (uint256 i = 0; i < components.length; i++) {
            approveToken(IERC20(components[i]));
        }
    }










    function issueSetForExactToken(
        ISetToken _setToken,
        IERC20 _inputToken,
        uint256 _amountInput,
        uint256 _minSetReceive
    )
        isSetToken(_setToken)
        external
        nonReentrant
    {
        require(_amountInput > 0, "ExchangeIssuance: INVALID INPUTS");

        _inputToken.safeTransferFrom(msg.sender, address(this), _amountInput);

        if (address(_inputToken) != WETH) {
           _swapTokenForWETH(_inputToken, _amountInput);
        }

        uint256 setTokenAmount = _issueSetForExactWETH(_setToken, _minSetReceive);

        emit ExchangeIssue(msg.sender, _setToken, _inputToken, _amountInput, setTokenAmount);
    }







    function issueSetForExactETH(
        ISetToken _setToken,
        uint256 _minSetReceive
    )
        isSetToken(_setToken)
        external
        payable
        nonReentrant
    {
        require(msg.value > 0, "ExchangeIssuance: INVALID INPUTS");

        IWETH(WETH).deposit{value: msg.value}();

        uint256 setTokenAmount = _issueSetForExactWETH(_setToken, _minSetReceive);

        emit ExchangeIssue(msg.sender, _setToken, IERC20(ETH_ADDRESS), msg.value, setTokenAmount);
    }










    function issueExactSetFromToken(
        ISetToken _setToken,
        IERC20 _inputToken,
        uint256 _amountSetToken,
        uint256 _maxAmountInputToken
    )
        isSetToken(_setToken)
        external
        nonReentrant
    {
        require(_amountSetToken > 0 && _maxAmountInputToken > 0, "ExchangeIssuance: INVALID INPUTS");

        _inputToken.safeTransferFrom(msg.sender, address(this), _maxAmountInputToken);

        uint256 initETHAmount = address(_inputToken) == WETH
            ? _maxAmountInputToken
            :  _swapTokenForWETH(_inputToken, _maxAmountInputToken);

        uint256 amountEthSpent = _issueExactSetFromWETH(_setToken, _amountSetToken);

        uint256 amountEthReturn = initETHAmount.sub(amountEthSpent);
        if (amountEthReturn > 0) {
            IWETH(WETH).withdraw(amountEthReturn);

            msg.sender.transfer(amountEthReturn);
        }

        emit ExchangeIssue(msg.sender, _setToken, _inputToken, _maxAmountInputToken, _amountSetToken);
    }








    function issueExactSetFromETH(
        ISetToken _setToken,
        uint256 _amountSetToken
    )
        isSetToken(_setToken)
        external
        payable
        nonReentrant
    {
        require(msg.value > 0 && _amountSetToken > 0, "ExchangeIssuance: INVALID INPUTS");

        IWETH(WETH).deposit{value: msg.value}();

        uint256 amountEth = _issueExactSetFromWETH(_setToken, _amountSetToken);

        uint256 returnAmount = msg.value.sub(amountEth);

        if (returnAmount > 0) {
            IWETH(WETH).withdraw(returnAmount);

            msg.sender.transfer(returnAmount);
        }

        emit ExchangeIssue(msg.sender, _setToken, IERC20(ETH_ADDRESS), amountEth, _amountSetToken);
    }










    function redeemExactSetForToken(
        ISetToken _setToken,
        IERC20 _outputToken,
        uint256 _amountSetToRedeem,
        uint256 _minOutputReceive
    )
        isSetToken(_setToken)
        external
        nonReentrant
    {
        require(_amountSetToRedeem > 0, "ExchangeIssuance: INVALID INPUTS");

        uint256 amountEthOut = _redeemExactSetForWETH(_setToken, _amountSetToRedeem);

        if (address(_outputToken) == WETH) {
            require(amountEthOut > _minOutputReceive, "ExchangeIssuance: INSUFFICIENT_OUTPUT_AMOUNT");
            _outputToken.safeTransfer(msg.sender, amountEthOut);

            emit ExchangeRedeem(msg.sender, _setToken, _outputToken, _amountSetToRedeem, amountEthOut);
        } else {

            (uint256 amountTokenOut, Exchange exchange) = _getMaxTokenForExactToken(amountEthOut, address(WETH), address(_outputToken));
            require(amountTokenOut > _minOutputReceive, "ExchangeIssuance: INSUFFICIENT_OUTPUT_AMOUNT");

            uint256 outputAmount = _swapExactTokensForTokens(exchange, WETH, address(_outputToken), amountEthOut);
            _outputToken.safeTransfer(msg.sender, outputAmount);

            emit ExchangeRedeem(msg.sender, _setToken, _outputToken, _amountSetToRedeem, outputAmount);
        }
    }









    function redeemExactSetForETH(
        ISetToken _setToken,
        uint256 _amountSetToRedeem,
        uint256 _minETHReceive
    )
        isSetToken(_setToken)
        external
        nonReentrant
    {
        require(_amountSetToRedeem > 0, "ExchangeIssuance: INVALID INPUTS");

        uint256 amountEthOut = _redeemExactSetForWETH(_setToken, _amountSetToRedeem);

        require(amountEthOut > _minETHReceive, "ExchangeIssuance: INSUFFICIENT_OUTPUT_AMOUNT");

        IWETH(WETH).withdraw(amountEthOut);

        msg.sender.transfer(amountEthOut);

        emit ExchangeRedeem(msg.sender, _setToken, IERC20(ETH_ADDRESS), _amountSetToRedeem, amountEthOut);
    }


    receive() external payable {}










    function getEstimatedIssueSetAmount(
        ISetToken _setToken,
        IERC20 _inputToken,
        uint256 _amountInput
    )
        isSetToken(_setToken)
        external
        view
        returns (uint256)
    {
        require(_amountInput > 0, "ExchangeIssuance: INVALID INPUTS");

        uint256 amountEth;
        if (address(_inputToken) != WETH) {
            (amountEth, ) = _getMaxTokenForExactToken(_amountInput, address(WETH),  address(_inputToken));
        } else {
            amountEth = _amountInput;
        }

        (uint256[] memory amountEthIn, Exchange[] memory exchanges, uint256 sumEth) = _getAmountETHForIssuance(_setToken);

        uint256 maxIndexAmount = PreciseUnitMath.maxUint256();
        address[] memory components = _setToken.getComponents();

        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];
            uint256 scaledAmountEth = amountEthIn[i].mul(amountEth).div(sumEth);

            uint256 amountTokenOut;
            if (exchanges[i] == Exchange.Uniswap) {
                (uint256 tokenReserveA, uint256 tokenReserveB) = UniswapV2Library.getReserves(uniFactory, WETH, component);
                amountTokenOut = UniswapV2Library.getAmountOut(scaledAmountEth, tokenReserveA, tokenReserveB);
            } else {
                require(exchanges[i] == Exchange.Sushiswap);
                (uint256 tokenReserveA, uint256 tokenReserveB) = SushiswapV2Library.getReserves(sushiFactory, WETH, component);
                amountTokenOut = SushiswapV2Library.getAmountOut(scaledAmountEth, tokenReserveA, tokenReserveB);
            }

            uint256 unit = uint256(_setToken.getDefaultPositionRealUnit(component));
            maxIndexAmount = Math.min(amountTokenOut.preciseDiv(unit), maxIndexAmount);
        }
        return maxIndexAmount;
    }








    function getAmountInToIssueExactSet(
        ISetToken _setToken,
        IERC20 _inputToken,
        uint256 _amountSetToken
    )
        isSetToken(_setToken)
        external
        view
        returns(uint256)
    {
        require(_amountSetToken > 0, "ExchangeIssuance: INVALID INPUTS");

        uint256 totalEth = 0;

        address[] memory components = _setToken.getComponents();
        for (uint256 i = 0; i < components.length; i++) {
            uint256 unit = uint256(_setToken.getDefaultPositionRealUnit(components[i]));
            uint256 amountToken = unit.preciseMul(_amountSetToken);


            (uint256 amountEth,) = _getMinTokenForExactToken(amountToken, WETH, components[i]);
            totalEth = totalEth.add(amountEth);
        }

        if (address(_inputToken) == WETH) {
            return totalEth;
        }

        (uint256 tokenAmount, ) = _getMinTokenForExactToken(totalEth, address(_inputToken), address(WETH));
        return tokenAmount;
    }









    function getEstimatedRedeemSetAmount(
        ISetToken _setToken,
        address _outputToken,
        uint256 _amountSetToRedeem
    )
        isSetToken(_setToken)
        external
        view
        returns (uint256)
    {
        require(_amountSetToRedeem > 0, "ExchangeIssuance: INVALID INPUTS");

        address[] memory components = _setToken.getComponents();
        uint256 totalEth = 0;
        for (uint256 i = 0; i < components.length; i++) {
            uint256 unit = uint256(_setToken.getDefaultPositionRealUnit(components[i]));
            uint256 amount = unit.preciseMul(_amountSetToRedeem);


            (uint256 amountEth, ) = _getMaxTokenForExactToken(amount, components[i], WETH);
            totalEth = totalEth.add(amountEth);
        }
        if (_outputToken == WETH) {
            return totalEth;
        }


        (uint256 tokenAmount, ) = _getMaxTokenForExactToken(totalEth, WETH, _outputToken);
        return tokenAmount;
    }










    function _safeApprove(IERC20 _token, address _spender) internal {
        if (_token.allowance(address(this), _spender) == 0) {
            _token.safeIncreaseAllowance(_spender, PreciseUnitMath.maxUint256());
        }
    }








    function _liquidateComponentsForWETH(ISetToken _setToken) internal returns (uint256) {
        uint256 sumEth = 0;
        address[] memory components = _setToken.getComponents();
        for (uint256 i = 0; i < components.length; i++) {


            require(
                _setToken.getExternalPositionModules(components[i]).length == 0,
                "Exchange Issuance: EXTERNAL_POSITIONS_NOT_ALLOWED"
            );

            address token = components[i];
            uint256 tokenBalance = IERC20(token).balanceOf(address(this));


            (, Exchange exchange) = _getMaxTokenForExactToken(tokenBalance, token, WETH);
            sumEth = sumEth.add(_swapExactTokensForTokens(exchange, token, WETH, tokenBalance));
        }
        return sumEth;
    }










    function _issueSetForExactWETH(ISetToken _setToken, uint256 _minSetReceive) internal returns (uint256) {
        uint256 wethBalance = IERC20(WETH).balanceOf(address(this));

        (uint256[] memory amountEthIn, Exchange[] memory exchanges, uint256 sumEth) = _getAmountETHForIssuance(_setToken);

        uint256 setTokenAmount = _acquireComponents(_setToken, amountEthIn, exchanges, wethBalance, sumEth);

        require(setTokenAmount > _minSetReceive, "ExchangeIssuance: INSUFFICIENT_OUTPUT_AMOUNT");

        basicIssuanceModule.issue(_setToken, setTokenAmount, msg.sender);

        return setTokenAmount;
    }










    function _issueExactSetFromWETH(ISetToken _setToken, uint256 _amountSetToken) internal returns (uint256) {

        uint256 sumEth = 0;

        address[] memory components = _setToken.getComponents();
        for (uint256 i = 0; i < components.length; i++) {


            require(
                _setToken.getExternalPositionModules(components[i]).length == 0,
                "Exchange Issuance: EXTERNAL_POSITIONS_NOT_ALLOWED"
            );

            uint256 unit = uint256(_setToken.getDefaultPositionRealUnit(components[i]));
            uint256 amountToken = uint256(unit).preciseMul(_amountSetToken);


            (, Exchange exchange) = _getMinTokenForExactToken(amountToken, WETH, components[i]);
            uint256 amountEth = _swapTokensForExactTokens(exchange, WETH, components[i], amountToken);
            sumEth = sumEth.add(amountEth);
        }
        basicIssuanceModule.issue(_setToken, _amountSetToken, msg.sender);
        return sumEth;
    }








    function _redeemExactSetForWETH(ISetToken _setToken, uint256 _amountSetToRedeem) internal returns (uint256) {
        _setToken.safeTransferFrom(msg.sender, address(this), _amountSetToRedeem);

        basicIssuanceModule.redeem(_setToken, _amountSetToRedeem, address(this));

        return _liquidateComponentsForWETH(_setToken);
    }










    function _getAmountETHForIssuance(ISetToken _setToken)
        internal
        view
        returns (uint256[] memory, Exchange[] memory, uint256)
    {
        uint256 sumEth = 0;
        address[] memory components = _setToken.getComponents();

        uint256[] memory amountEthIn = new uint256[](components.length);
        Exchange[] memory exchanges = new Exchange[](components.length);

        for (uint256 i = 0; i < components.length; i++) {


            require(
                _setToken.getExternalPositionModules(components[i]).length == 0,
                "Exchange Issuance: EXTERNAL_POSITIONS_NOT_ALLOWED"
            );


            uint256 unit = uint256(_setToken.getDefaultPositionRealUnit(components[i]));
            (amountEthIn[i], exchanges[i]) = _getMinTokenForExactToken(unit, WETH, components[i]);
            sumEth = sumEth.add(amountEthIn[i]);
        }
        return (amountEthIn, exchanges, sumEth);
    }












    function _acquireComponents(
        ISetToken _setToken,
        uint256[] memory _amountEthIn,
        Exchange[] memory _exchanges,
        uint256 _wethBalance,
        uint256 _sumEth
    )
        internal
        returns (uint256)
    {
        address[] memory components = _setToken.getComponents();
        uint256 maxIndexAmount = PreciseUnitMath.maxUint256();

        for (uint256 i = 0; i < components.length; i++) {

            uint256 scaledAmountEth = _amountEthIn[i].mul(_wethBalance).div(_sumEth);

            uint256 amountTokenOut = _swapExactTokensForTokens(_exchanges[i], WETH, components[i], scaledAmountEth);

            uint256 unit = uint256(_setToken.getDefaultPositionRealUnit(components[i]));
            maxIndexAmount = Math.min(amountTokenOut.preciseDiv(unit), maxIndexAmount);
        }
        return maxIndexAmount;
    }








    function _swapTokenForWETH(IERC20 _token, uint256 _amount) internal returns (uint256) {
        (, Exchange exchange) = _getMaxTokenForExactToken(_amount, address(_token), WETH);
        IUniswapV2Router02 router = _getRouter(exchange);
        _safeApprove(_token, address(router));
        return _swapExactTokensForTokens(exchange, address(_token), WETH, _amount);
    }










    function _swapExactTokensForTokens(Exchange _exchange, address _tokenIn, address _tokenOut, uint256 _amountIn) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        return _getRouter(_exchange).swapExactTokensForTokens(_amountIn, 0, path, address(this), block.timestamp)[1];
    }










    function _swapTokensForExactTokens(Exchange _exchange, address _tokenIn, address _tokenOut, uint256 _amountOut) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        return _getRouter(_exchange).swapTokensForExactTokens(_amountOut, PreciseUnitMath.maxUint256(), path, address(this), block.timestamp)[0];
    }











    function _getMinTokenForExactToken(uint256 _amountOut, address _tokenA, address _tokenB) internal view returns (uint256, Exchange) {

        uint256 uniEthIn = PreciseUnitMath.maxUint256();
        uint256 sushiEthIn = PreciseUnitMath.maxUint256();

        if (_pairAvailable(uniFactory, _tokenA, _tokenB)) {
            (uint256 tokenReserveA, uint256 tokenReserveB) = UniswapV2Library.getReserves(uniFactory, _tokenA, _tokenB);
            uniEthIn = UniswapV2Library.getAmountIn(_amountOut, tokenReserveA, tokenReserveB);
        }

        if (_pairAvailable(sushiFactory, _tokenA, _tokenB)) {
            (uint256 tokenReserveA, uint256 tokenReserveB) = SushiswapV2Library.getReserves(sushiFactory, _tokenA, _tokenB);
            sushiEthIn = SushiswapV2Library.getAmountIn(_amountOut, tokenReserveA, tokenReserveB);
        }

        return (uniEthIn <= sushiEthIn) ? (uniEthIn, Exchange.Uniswap) : (sushiEthIn, Exchange.Sushiswap);
    }











    function _getMaxTokenForExactToken(uint256 _amountIn, address _tokenA, address _tokenB) internal view returns (uint256, Exchange) {

        uint256 uniTokenOut = 0;
        uint256 sushiTokenOut = 0;

        if(_pairAvailable(uniFactory, _tokenA, _tokenB)) {
            (uint256 tokenReserveA, uint256 tokenReserveB) = UniswapV2Library.getReserves(uniFactory, _tokenA, _tokenB);
            uniTokenOut = UniswapV2Library.getAmountOut(_amountIn, tokenReserveA, tokenReserveB);
        }

        if(_pairAvailable(sushiFactory, _tokenA, _tokenB)) {
            (uint256 tokenReserveA, uint256 tokenReserveB) = SushiswapV2Library.getReserves(sushiFactory, _tokenA, _tokenB);
            sushiTokenOut = SushiswapV2Library.getAmountOut(_amountIn, tokenReserveA, tokenReserveB);
        }

        return (uniTokenOut >= sushiTokenOut) ? (uniTokenOut, Exchange.Uniswap) : (sushiTokenOut, Exchange.Sushiswap);
    }









    function _pairAvailable(address _factory, address _tokenA, address _tokenB) internal view returns (bool) {
        return IUniswapV2Factory(_factory).getPair(_tokenA, _tokenB) != address(0);
    }







     function _getRouter(Exchange _exchange) internal view returns(IUniswapV2Router02) {
         return (_exchange == Exchange.Uniswap) ? uniRouter : sushiRouter;
     }

}
