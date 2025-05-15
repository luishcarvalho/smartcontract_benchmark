
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../../interfaces/IMasterChef.sol";

contract StrategyWardenLP is OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint constant public MAX_FEE = 1000;
    uint constant public CALL_FEE = 125;
    uint constant public aleswapFee = MAX_FEE - CALL_FEE;

    IUniswapV2Router02 private constant WARDEN_ROUTER = IUniswapV2Router02(0x71ac17934b60A4610dc58b715B61e45DCBdE4054);

    uint constant public WITHDRAWAL_FEE = 10;
    uint constant public WITHDRAWAL_MAX = 10000;

    address public keeper;
    address public vault;
    address public aleswapFeeRecipient;


    address constant public wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address constant public wad = address(0x0fEAdcC3824E7F3c12f40E324a60c23cA51627fc);
    address public want;
    address public lpToken0;
    address public lpToken1;


    address constant public masterchef = address(0xde866dD77b6DF6772e320dC92BFF0eDDC626C674);
    uint256 public poolId;


    address[] public wadToWbnbRoute = [wad, wbnb];
    address[] public wadToLp0Route;
    address[] public wadToLp1Route;




    event StratHarvest(address indexed harvester);

    function initialize(
        address _want,
        uint256 _poolId,
        address _keeper,
        address _aleswapFeeRecipient
    ) external initializer {
        __Ownable_init();
        __Pausable_init();

        want = _want;
        lpToken0 = IUniswapV2Pair(want).token0();
        lpToken1 = IUniswapV2Pair(want).token1();
        poolId = _poolId;
        keeper = _keeper;

        aleswapFeeRecipient = _aleswapFeeRecipient;

        if (lpToken0 == wbnb) {
            wadToLp0Route = [wad, wbnb];
        } else if (lpToken0 != wad) {
            wadToLp0Route = [wad, wbnb, lpToken0];
        }

        if (lpToken1 == wbnb) {
            wadToLp1Route = [wad, wbnb];
        } else if (lpToken1 != wad) {
            wadToLp1Route = [wad, wbnb, lpToken1];
        }

        _giveAllowances();
    }


    modifier onlyKeeper() {
        require(msg.sender == owner() || msg.sender == keeper, "!keeper");
        _;
    }


    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }


    function deposit() public whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            IMasterChef(masterchef).deposit(poolId, wantBal);
        }
    }

    function withdraw(uint256 _amount) external returns (uint256) {
        require(msg.sender == vault, "!vault");

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            IMasterChef(masterchef).withdraw(poolId, _amount.sub(wantBal));
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        if (tx.origin == owner() || paused()) {
            IERC20(want).safeTransfer(vault, wantBal);
            return wantBal;
        } else {
            uint256 withdrawalFee = wantBal.mul(WITHDRAWAL_FEE).div(WITHDRAWAL_MAX);
            IERC20(want).safeTransfer(vault, wantBal.sub(withdrawalFee));
            return wantBal.sub(withdrawalFee);
        }
    }



    function harvest() external whenNotPaused onlyEOA {
        IMasterChef(masterchef).deposit(poolId, 0);
        chargeFees();
        addLiquidity();
        deposit();

        emit StratHarvest(msg.sender);
    }


    function chargeFees() internal {
        uint256 toWbnb = IERC20(wad).balanceOf(address(this)).mul(40).div(1000);
        WARDEN_ROUTER.swapExactTokensForTokens(toWbnb, 0, wadToWbnbRoute, address(this), now);

        uint256 wbnbBal = IERC20(wbnb).balanceOf(address(this));

        uint256 callFeeAmount = wbnbBal.mul(CALL_FEE).div(MAX_FEE);
        IERC20(wbnb).safeTransfer(msg.sender, callFeeAmount);

        uint256 aleswapFeeAmount = wbnbBal.mul(aleswapFee).div(MAX_FEE);
        IERC20(wbnb).safeTransfer(aleswapFeeRecipient, aleswapFeeAmount);

    }


    function addLiquidity() internal {
        uint256 wadHalf = IERC20(wad).balanceOf(address(this)).div(2);

        if (lpToken0 != wad)
            WARDEN_ROUTER.swapExactTokensForTokens(wadHalf, 0, wadToLp0Route, address(this), now);

        if (lpToken1 != wad)
            WARDEN_ROUTER.swapExactTokensForTokens(wadHalf, 0, wadToLp1Route, address(this), now);

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        WARDEN_ROUTER.addLiquidity(lpToken0, lpToken1, lp0Bal, lp1Bal, 1, 1, address(this), now);
    }


    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }


    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }


    function balanceOfPool() public view returns (uint256) {
        (uint256 _amount, ) = IMasterChef(masterchef).userInfo(poolId, address(this));
        return _amount;
    }


    function panic() public onlyKeeper {
        pause();
        IMasterChef(masterchef).emergencyWithdraw(poolId);
    }

    function pause() public onlyKeeper {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyKeeper {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function setaleswapFeeRecipient(address _aleswapFeeRecipient) external onlyOwner {
        aleswapFeeRecipient = _aleswapFeeRecipient;
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(masterchef, uint256(-1));
        IERC20(wad).safeApprove(address(WARDEN_ROUTER), uint256(-1));

        IERC20(lpToken0).safeApprove(address(WARDEN_ROUTER), 0);
        IERC20(lpToken0).safeApprove(address(WARDEN_ROUTER), uint256(-1));

        IERC20(lpToken1).safeApprove(address(WARDEN_ROUTER), 0);
        IERC20(lpToken1).safeApprove(address(WARDEN_ROUTER), uint256(-1));
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(masterchef, 0);
        IERC20(wad).safeApprove(address(WARDEN_ROUTER), 0);
        IERC20(lpToken0).safeApprove(address(WARDEN_ROUTER), 0);
        IERC20(lpToken1).safeApprove(address(WARDEN_ROUTER), 0);
    }
}
