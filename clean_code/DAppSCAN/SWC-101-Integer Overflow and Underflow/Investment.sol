
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./utils/OwnablePausable.sol";
import "./uniswap/IUniswapV2Router02.sol";
import "./GovernanceToken.sol";

contract Investment is OwnablePausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;


    ERC20 public cumulative;


    GovernanceToken public governanceToken;


    uint256 public governanceTokenLockDate;

    uint8 internal constant GOVERNANCE_TOKEN_PRICE_DECIMALS = 6;


    uint256 public governanceTokenPrice = 1000000;


    IUniswapV2Router02 internal uniswapRouter;


    mapping(address => bool) public investmentTokens;


    event UniswapRouterChanged(address newUniswapRouter);


    event InvestTokenAllowed(address token);


    event InvestTokenDenied(address token);


    event GovernanceTokenPriceChanged(uint256 newPrice);


    event Invested(address investor, address token, uint256 amount, uint256 reward);


    event Withdrawal(address recipient, address token, uint256 amount);






    constructor(
        address _cumulative,
        address _governanceToken,
        uint256 _governanceTokenLockDate,
        address _uniswapRouter
    ) public {
        cumulative = ERC20(_cumulative);
        governanceToken = GovernanceToken(_governanceToken);
        governanceTokenLockDate = _governanceTokenLockDate;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }





    function changeUniswapRouter(address _uniswapRouter) external onlyOwner {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        emit UniswapRouterChanged(_uniswapRouter);
    }





    function allowToken(address token) external onlyOwner {
        investmentTokens[token] = true;
        emit InvestTokenAllowed(token);
    }





    function denyToken(address token) external onlyOwner {
        investmentTokens[token] = false;
        emit InvestTokenDenied(token);
    }





    function changeGovernanceTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Investment::changeGovernanceTokenPrice: invalid new governance token price");

        governanceTokenPrice = newPrice;
        emit GovernanceTokenPriceChanged(newPrice);
    }





    function _path(address token) internal view returns (address[] memory) {
        address weth = uniswapRouter.WETH();
        if (weth == token) {
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = address(cumulative);
            return path;
        }

        address[] memory path = new address[](3);
        path[0] = token;
        path[1] = weth;
        path[2] = address(cumulative);
        return path;
    }






    function _amountOut(address token, uint256 amount) internal view returns (uint256) {
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(amount, _path(token));
        require(amountsOut.length != 0, "Investment::_amountOut: invalid amounts out length");

        return amountsOut[amountsOut.length - 1];
    }






    function _governanceTokenPrice(uint256 amount) internal view returns (uint256) {
        uint256 decimals = cumulative.decimals();

        return amount.mul(10**(18 - decimals + GOVERNANCE_TOKEN_PRICE_DECIMALS)).div(governanceTokenPrice);
    }






    function price(address token, uint256 amount) external view returns (uint256) {
        require(investmentTokens[token], "Investment::price: invalid investable token");

        uint256 amountOut = amount;
        if (token != address(cumulative)) {
            amountOut = _amountOut(token, amount);
        }

        return _governanceTokenPrice(amountOut);
    }






    function invest(address token, uint256 amount) external whenNotPaused returns (bool) {
        require(investmentTokens[token], "Investment::invest: invalid investable token");
        uint256 reward = _governanceTokenPrice(amount);

        ERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        if (token != address(cumulative)) {
            uint256 amountOut = _amountOut(token, amount);
            require(amountOut != 0, "Investment::invest: liquidity pool is empty");
            reward = _governanceTokenPrice(amountOut);

            ERC20(token).safeApprove(address(uniswapRouter), amount);
            uniswapRouter.swapExactTokensForTokens(amount, amountOut, _path(token), address(this), block.timestamp);
        }

        governanceToken.transferLock(msg.sender, reward, governanceTokenLockDate);

        emit Invested(msg.sender, token, amount, reward);
        return true;
    }




    function investETH() external payable whenNotPaused returns (bool) {
        address token = uniswapRouter.WETH();
        require(investmentTokens[token], "Investment::investETH: invalid investable token");
        uint256 reward = _governanceTokenPrice(msg.value);

        if (token != address(cumulative)) {
            uint256 amountOut = _amountOut(token, msg.value);
            require(amountOut != 0, "Investment::invest: liquidity pool is empty");
            reward = _governanceTokenPrice(amountOut);

            uniswapRouter.swapExactETHForTokens{value: msg.value}(amountOut, _path(token), address(this), block.timestamp);
        }

        governanceToken.transferLock(msg.sender, reward, governanceTokenLockDate);

        emit Invested(msg.sender, token, msg.value, reward);
        return true;
    }





    function withdraw(address recipient) external onlyOwner {
        require(recipient != address(0), "Investment::withdraw: cannot transfer to the zero address");

        uint256 balance = cumulative.balanceOf(address(this));
        cumulative.safeTransfer(recipient, balance);

        emit Withdrawal(recipient, address(cumulative), balance);
    }
}
