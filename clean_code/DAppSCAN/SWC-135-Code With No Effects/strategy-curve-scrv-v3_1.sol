
pragma solidity ^0.6.2;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";


import "./scrv-voter.sol";
import "./crv-locker.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/uniswapv2.sol";
import "../../interfaces/controller.sol";

import "../strategy-curve-base.sol";

contract StrategyCurveSCRVv3_1 is StrategyCurveBase {

    address public susdv2_pool = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address public susdv2_gauge = 0xA90996896660DEcC6E997655E065b23788857849;
    address public scrv = 0xC25a3A3b969415c80451098fa907EC722572917F;


    address public snx = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyCurveBase(
            susdv2_pool,
            susdv2_gauge,
            scrv,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}



    function getMostPremium()
        public
        override
        view
        returns (address, uint256)
    {
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

    function getName() external override pure returns (string memory) {
        return "StrategyCurveSCRVv3_1";
    }



    function harvest() public onlyBenevolent override {







        (address to, uint256 toIndex) = getMostPremium();



        ICurveMintr(mintr).mint(gauge);
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {


            uint256 _keepCRV = _crv.mul(keepCRV).div(keepCRVMax);
            if (_keepCRV > 0) {
                IERC20(crv).safeTransfer(
                    IController(controller).treasury(),
                    _keepCRV
                );
            }
            _crv = _crv.sub(_keepCRV);
            _swapUniswap(crv, to, _crv);
        }


        ICurveGauge(gauge).claim_rewards(address(this));
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


        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {

            IERC20(want).safeTransfer(
                IController(controller).treasury(),
                _want.mul(performanceFee).div(performanceMax)
            );

            deposit();
        }
    }
}
