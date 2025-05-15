
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface IPool {
    function add_liquidity(uint[3] memory amounts, uint _min_mint_amount) external returns (uint);

    function add_liquidity(
        uint[3] memory amounts, uint _min_mint_amount, bool _use_underlying
    ) external returns (uint);

    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint _min_amount) external returns (uint);

    function remove_liquidity_one_coin(
        uint _token_amount, int128 i, uint _min_amount, bool _use_underlying
    ) external returns (uint);

    function lp_token() external view returns (address);
    function get_virtual_price() external view returns (uint);
    function balances(uint i) external view returns (uint);
    function price_oracle(uint i) external view returns (uint);
}

interface IGauge {
    function deposit(uint amount) external;
    function withdraw(uint amount) external;
    function claim_rewards() external;
    function claimable_reward_write(address _addr, address _token) external returns (uint);
    function balanceOf(address account) external view returns (uint);
}

interface ILendingPool {
    function deposit(address asset, uint amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint amount, address to) external;
    function getReserveData(address asset) external view returns (
        uint, uint128, uint128, uint128, uint128, uint128, uint40, address
    );
}

interface IIncentivesController {
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint);
    function claimRewards(address[] calldata assets, uint amount, address to) external returns (uint);
}

interface IWAVAX is IERC20Upgradeable {
    function withdraw(uint amount) external;
}

contract PowerBombAvaxCurve is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IWAVAX;

    IERC20Upgradeable constant USDT = IERC20Upgradeable(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    IERC20Upgradeable constant USDC = IERC20Upgradeable(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);
    IERC20Upgradeable constant DAI = IERC20Upgradeable(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70);
    IWAVAX constant WAVAX = IWAVAX(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20Upgradeable constant CRV = IERC20Upgradeable(0x47536F17F4fF30e64A96a7555826b8f9e66ec468);
    IERC20Upgradeable public lpToken;
    IERC20Upgradeable public rewardToken;

    IRouter constant router = IRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    IPool public pool;
    IGauge public gauge;

    address public treasury;
    address public proxy;
    address public bot;

    uint public yieldFeePerc;
    uint public slippagePerc;
    uint public tvlMaxLimit;

    uint public accRewardPerlpToken;
    mapping(address => uint) internal userAccReward;
    ILendingPool constant lendingPool = ILendingPool(0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C);
    IERC20Upgradeable public ibRewardToken;
    IIncentivesController constant incentivesController = IIncentivesController(0x01D83Fe6A10D2f2B7AF17034343746188272cAc9);
    uint public ibRewardTokenBaseAmt;
    uint public lastIbRewardTokenAmt;

    struct User {
        uint lpTokenBalance;
        uint rewardStartAt;
    }
    mapping(address => User) public userInfo;
    mapping(address => uint) internal depositedBlock;

    event Deposit(address tokenDeposit, uint amountToken, uint amountlpToken);
    event Withdraw(address tokenWithdraw, uint amountToken);
    event Harvest(uint harvestedfarmToken, uint swappedRewardTokenAfterFee, uint fee);
    event ClaimReward(address receiver, uint claimedIbRewardTokenAfterFee, uint rewardToken);
    event SetTreasury(address oldTreasury, address newTreasury);
    event SetProxy(address oldProxy, address newProxy);
    event SetBot(address oldBot, address newBot);
    event SetYieldFeePerc(uint oldYieldFeePerc, uint newYieldFeePerc);
    event SetSlippagePerc(uint oldSlippagePerc, uint newSlippagePerc);
    event SetTVLMaxLimit(uint oldTVLMaxLimit, uint newTVLMaxLimit);

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function deposit(IERC20Upgradeable token, uint amount, uint slippage) external virtual {
        _deposit(token, amount, msg.sender, slippage);
    }

    function depositByProxy(IERC20Upgradeable token, uint amount, address depositor, uint slippage) external virtual {
        require(msg.sender == proxy, "Only proxy");
        _deposit(token, amount, depositor, slippage);
    }

    function _deposit(IERC20Upgradeable token, uint amount, address depositor, uint slippage) internal virtual nonReentrant whenNotPaused {
        require(token == USDT || token == USDC || token == DAI || token == lpToken, "Invalid token");
        require(amount > 0, "Invalid amount");
        require(getAllPoolInUSD() < tvlMaxLimit, "TVL max Limit reach");

        uint currentPool = gauge.balanceOf(address(this));
        if (currentPool > 0) _harvest(true);

        token.safeTransferFrom(msg.sender, address(this), amount);
        depositedBlock[depositor] = block.number;

        uint lpTokenAmt;
        if (token != lpToken) {
            uint[3] memory amounts;
            if (token == USDT) amounts[2] = amount;
            else if (token == USDC) amounts[1] = amount;
            else if (token == DAI) amounts[0] = amount;

            if (token != DAI) amount *= 1e12;
            uint estimatedMintAmt = amount * 1e18 / pool.get_virtual_price();
            uint minMintAmt = estimatedMintAmt - (estimatedMintAmt * slippage / 10000);

            lpTokenAmt = pool.add_liquidity(amounts, minMintAmt, true);
        } else {
            lpTokenAmt = amount;
        }

        gauge.deposit(lpTokenAmt);
        User storage user = userInfo[depositor];
        user.lpTokenBalance += lpTokenAmt;
        user.rewardStartAt += (lpTokenAmt * accRewardPerlpToken / 1e36);

        emit Deposit(address(token), amount, lpTokenAmt);
    }

    function withdraw(IERC20Upgradeable token, uint amountOutLpToken, uint slippage) external virtual nonReentrant {
        require(token == USDT || token == USDC || token == DAI || token == lpToken, "Invalid token");
        User storage user = userInfo[msg.sender];
        require(amountOutLpToken > 0 && user.lpTokenBalance >= amountOutLpToken, "Invalid amountOutLpToken to withdraw");
        require(depositedBlock[msg.sender] != block.number, "Not allow withdraw within same block");

        claimReward(msg.sender);

        user.lpTokenBalance = user.lpTokenBalance - amountOutLpToken;
        user.rewardStartAt = user.lpTokenBalance * accRewardPerlpToken / 1e36;
        gauge.withdraw(amountOutLpToken);

        uint amountOutToken;
        if (token != lpToken) {
            int128 i;
            if (token == USDT) i = 2;
            else if (token == USDC) i = 1;
            else i = 0;

            uint amount = amountOutLpToken * pool.get_virtual_price() / 1e18;
            if (token != DAI) amount /= 1e12;
            uint minAmount = amount - (amount * slippage / 10000);

            pool.remove_liquidity_one_coin(amountOutLpToken, i, minAmount, true);
            amountOutToken = token.balanceOf(address(this));
        } else {
            amountOutToken = amountOutLpToken;
        }
        token.safeTransfer(msg.sender, amountOutToken);

        emit Withdraw(address(token), amountOutToken);
    }

    function harvest() external nonReentrant {
        _harvest(false);
    }

    function _harvest(bool isDeposit) internal virtual {

        uint accruedAmt = ibRewardToken.balanceOf(address(this)) - lastIbRewardTokenAmt;
        uint currentPool = gauge.balanceOf(address(this));
        accRewardPerlpToken += (accruedAmt * 1e36 / currentPool);


        gauge.claim_rewards();

        uint WAVAXAmt = WAVAX.balanceOf(address(this));
        uint minSwapAmt = msg.sender == bot ? 50e16 : 25e16;
        if (WAVAXAmt > minSwapAmt) {

            uint CRVAmt = CRV.balanceOf(address(this));
            if (CRVAmt > 1e18) WAVAXAmt += swap2(address(CRV), address(WAVAX), CRVAmt);


            if (msg.sender == bot || isDeposit) {
                uint amountRefund = msg.sender == bot ? 2e16 : 1e16;
                WAVAXAmt -= amountRefund;
                WAVAX.withdraw(amountRefund);
                (bool success,) = tx.origin.call{value: address(this).balance}("");
                require(success, "AVAX transfer failed");
            }


            uint rewardTokenAmt = swap2(address(WAVAX), address(rewardToken), WAVAXAmt);


            uint fee = rewardTokenAmt * yieldFeePerc / 10000;
            rewardTokenAmt -= fee;
            ibRewardTokenBaseAmt += rewardTokenAmt;


            address[] memory assets = new address[](1);
            assets[0] = address(ibRewardToken);
            uint unclaimedRewardsAmt = incentivesController.getRewardsBalance(assets, address(this));
            if (unclaimedRewardsAmt > 1e16) {
                uint _WAVAXAmt = incentivesController.claimRewards(assets, unclaimedRewardsAmt, address(this));


                uint _rewardTokenAmt = swap2(address(WAVAX), address(rewardToken), _WAVAXAmt);


                uint _fee = _rewardTokenAmt * yieldFeePerc / 10000;
                rewardTokenAmt += (_rewardTokenAmt - _fee);
                fee += _fee;
            }


            accRewardPerlpToken += (rewardTokenAmt * 1e36 / currentPool);


            rewardToken.safeTransfer(treasury, fee);


            lendingPool.deposit(address(rewardToken), rewardTokenAmt, address(this), 0);


            lastIbRewardTokenAmt = ibRewardToken.balanceOf(address(this));

            emit Harvest(WAVAXAmt, rewardTokenAmt, fee);
        }
    }

    receive() external payable {}

    function claimReward(address account) public virtual {
        _harvest(false);

        User storage user = userInfo[account];
        if (user.lpTokenBalance > 0) {

            uint ibRewardTokenAmt = (user.lpTokenBalance * accRewardPerlpToken / 1e36) - user.rewardStartAt;
            if (ibRewardTokenAmt > 0) {
                user.rewardStartAt += ibRewardTokenAmt;


                lendingPool.withdraw(address(rewardToken), ibRewardTokenAmt, address(this));


                lastIbRewardTokenAmt -= ibRewardTokenAmt;


                uint rewardTokenAmt = rewardToken.balanceOf(address(this));
                rewardToken.safeTransfer(account, rewardTokenAmt);
                userAccReward[account] += rewardTokenAmt;

                emit ClaimReward(account, ibRewardTokenAmt, rewardTokenAmt);
            }
        }
    }

    function swap2(address tokenIn, address tokenOut, uint amount) internal virtual returns (uint) {
        address[] memory path = getPath(tokenIn, tokenOut);
        return router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp)[1];
    }

    function swap3(address tokenIn, address tokenOut, uint amount) internal virtual returns (uint) {
        address[] memory path = new address[](3);
        path[0] = tokenIn;
        path[1] = address(WAVAX);
        path[2] = tokenOut;
        return router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp)[2];
    }

    function setTreasury(address _treasury) external virtual onlyOwner {
        address oldTreasury = treasury;
        treasury = _treasury;

        emit SetTreasury(oldTreasury, _treasury);
    }

    function setProxy(address _proxy) external virtual onlyOwner {
        address oldProxy = proxy;
        proxy = _proxy;

        emit SetProxy(oldProxy, _proxy);
    }

    function setBot(address _bot) external virtual onlyOwner {
        address oldBot = bot;
        bot = _bot;

        emit SetBot(oldBot, _bot);
    }

    function setYieldFeePerc(uint _yieldFeePerc) external virtual onlyOwner {
        require(_yieldFeePerc <= 2000, "Invalid yield fee percentage");
        uint oldYieldFeePerc = yieldFeePerc;
        yieldFeePerc = _yieldFeePerc;

        emit SetYieldFeePerc(oldYieldFeePerc, _yieldFeePerc);
    }

    function setSlippagePerc(uint _slippagePerc) external virtual onlyOwner {
        uint oldSlippagePerc = slippagePerc;
        slippagePerc = _slippagePerc;

        emit SetSlippagePerc(oldSlippagePerc, _slippagePerc);
    }


    function setTVLMaxLimit(uint _tvlMaxLimit) external virtual onlyOwner {
        uint oldTVLMaxLimit = tvlMaxLimit;
        tvlMaxLimit = _tvlMaxLimit;

        emit SetTVLMaxLimit(oldTVLMaxLimit, _tvlMaxLimit);
    }

    function pauseContract() external virtual onlyOwner {
        _pause();
    }

    function unpauseContract() external virtual onlyOwner {
        _unpause();
    }

    function getPath(address tokenIn, address tokenOut) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function getAllPool() public virtual view returns (uint) {
        return gauge.balanceOf(address(this));
    }


    function getPricePerFullShareInUSD() public virtual view returns (uint) {
        return pool.get_virtual_price() / 1e12;
    }


    function getAllPoolInUSD() public virtual view returns (uint) {
        uint allPool = getAllPool();
        if (allPool == 0) return 0;
        return allPool * getPricePerFullShareInUSD() / 1e18;
    }

    function getPoolPendingReward(IERC20Upgradeable pendingRewardToken) external virtual returns (uint) {
        uint pendingRewardFromCurve = gauge.claimable_reward_write(address(this), address(pendingRewardToken));
        return pendingRewardFromCurve + pendingRewardToken.balanceOf(address(this));
    }


    function getUserPendingReward(address account) external virtual view returns (uint ibRewardTokenAmt) {
        User storage user = userInfo[account];
        ibRewardTokenAmt = (user.lpTokenBalance * accRewardPerlpToken / 1e36) - user.rewardStartAt;
    }


    function getUserBalance(address account) external virtual view returns (uint) {
        return userInfo[account].lpTokenBalance;
    }


    function getUserBalanceInUSD(address account) external virtual view returns (uint) {
        return userInfo[account].lpTokenBalance * getPricePerFullShareInUSD() / 1e18;
    }


    function getUserAccumulatedReward(address account) external virtual view returns (uint) {
        return userAccReward[account];
    }

    uint256[33] private __gap;
}
