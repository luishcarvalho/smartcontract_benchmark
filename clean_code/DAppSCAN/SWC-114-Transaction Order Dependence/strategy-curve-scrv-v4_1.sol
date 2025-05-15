


pragma solidity ^0.6.2;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "./scrv-voter.sol";
import "./crv-locker.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/uniswapv2.sol";
import "../../interfaces/controller.sol";

import "../strategy-base.sol";

contract StrategyCurveSCRVv4_1 is StrategyBase {

    address public scrv = 0xC25a3A3b969415c80451098fa907EC722572917F;
    address public susdv2_gauge = 0xA90996896660DEcC6E997655E065b23788857849;
    address public susdv2_pool = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address public escrow = 0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2;


    address public gauge;
    address public curve;
    address public mintr = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;


    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant snx = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;


    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public susd = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;


    uint256 public keepCRV = 500;
    uint256 public keepCRVMax = 10000;


    address public scrvVoter;
    address public crvLocker;

    constructor(
        address _scrvVoter,
        address _crvLocker,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(scrv, _governance, _strategist, _controller, _timelock)
    {
        curve = susdv2_pool;
        gauge = susdv2_gauge;

        scrvVoter = _scrvVoter;
        crvLocker = _crvLocker;
    }



    function balanceOfPool() public override view returns (uint256) {
        return SCRVVoter(scrvVoter).balanceOf(gauge);
    }

    function getName() external override pure returns (string memory) {
        return "StrategyCurveSCRVv4_1";
    }

    function getHarvestable() external returns (uint256) {
        return ICurveGauge(gauge).claimable_tokens(crvLocker);
    }

    function getMostPremium() public view returns (address, uint8) {
        uint256[] memory balances = new uint256[](4);
        balances[0] = ICurveFi_4(curve).balances(0);
        balances[1] = ICurveFi_4(curve).balances(1).mul(10**12);
        balances[2] = ICurveFi_4(curve).balances(2).mul(10**12);
        balances[3] = ICurveFi_4(curve).balances(3);


        if (
            balances[0] < balances[1] &&
            balances[0] < balances[2] &&
            balances[0] < balances[3]
        ) {
            return (dai, 0);
        }


        if (
            balances[1] < balances[0] &&
            balances[1] < balances[2] &&
            balances[1] < balances[3]
        ) {
            return (usdc, 1);
        }


        if (
            balances[2] < balances[0] &&
            balances[2] < balances[1] &&
            balances[2] < balances[3]
        ) {
            return (usdt, 2);
        }


        if (
            balances[3] < balances[0] &&
            balances[3] < balances[1] &&
            balances[3] < balances[2]
        ) {
            return (susd, 3);
        }


        return (dai, 0);
    }



    function setKeepCRV(uint256 _keepCRV) external {
        require(msg.sender == governance, "!governance");
        keepCRV = _keepCRV;
    }



    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeTransfer(scrvVoter, _want);
            SCRVVoter(scrvVoter).deposit(gauge, want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        return SCRVVoter(scrvVoter).withdraw(gauge, want, _amount);
    }

    function harvest() public override onlyBenevolent {







        (address to, uint256 toIndex) = getMostPremium();



        SCRVVoter(scrvVoter).harvest(gauge);
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {

            uint256 _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);
            IERC20(crv).safeTransfer(address(crvLocker), _keepCRV);


            _crv = _crv.sub(_keepCRV);
            _swapUniswap(crv, to, _crv);
        }


        SCRVVoter(scrvVoter).claimRewards();
        uint256 _snx = IERC20(snx).balanceOf(address(this));
        if (_snx > 0) {
            _swapUniswap(snx, to, _snx);
        }



        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            IERC20(to).safeApprove(curve, 0);
            IERC20(to).safeApprove(curve, _to);
            uint256[4] memory liquidity;
            liquidity[toIndex] = _to;
            ICurveFi_4(curve).add_liquidity(liquidity, 0);
        }


        _distributePerformanceFeesAndDeposit();
    }
}
