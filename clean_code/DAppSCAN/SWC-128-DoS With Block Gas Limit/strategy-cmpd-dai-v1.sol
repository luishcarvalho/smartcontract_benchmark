
pragma solidity ^0.6.2;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";
import "../../lib/exponential.sol";

import "../strategy-base.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/uniswapv2.sol";
import "../../interfaces/controller.sol";
import "../../interfaces/compound.sol";

contract StrategyCmpdDaiV1 is StrategyBase, Exponential {
    address
        public constant comptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    address public constant lens = 0xd513d22422a3062Bd342Ae374b4b9c20E0a9a074;
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant comp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address public constant cdai = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant cether = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;




    uint256 colFactorLeverageBuffer = 100;
    uint256 colFactorLeverageBufferMax = 1000;





    uint256 colFactorSyncBuffer = 50;
    uint256 colFactorSyncBufferMax = 1000;



    mapping(address => bool) keepers;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(dai, _governance, _strategist, _controller, _timelock)
    {

        address[] memory ctokens = new address[](1);
        ctokens[0] = cdai;
        IComptroller(comptroller).enterMarkets(ctokens);
    }



    modifier onlyKeepers {
        require(
            keepers[msg.sender] ||
                msg.sender == address(this) ||
                msg.sender == strategist ||
                msg.sender == governance,
            "!keepers"
        );
        _;
    }



    function getName() external override pure returns (string memory) {
        return "StrategyCompoundDaiV1";
    }

    function getSuppliedView() public view returns (uint256) {
        (, uint256 cTokenBal, , uint256 exchangeRate) = ICToken(cdai)
            .getAccountSnapshot(address(this));

        (, uint256 bal) = mulScalarTruncate(
            Exp({mantissa: exchangeRate}),
            cTokenBal
        );

        return bal;
    }

    function getBorrowedView() public view returns (uint256) {
        return ICToken(cdai).borrowBalanceStored(address(this));
    }

    function balanceOfPool() public override view returns (uint256) {
        uint256 supplied = getSuppliedView();
        uint256 borrowed = getBorrowedView();
        return supplied.sub(borrowed);
    }



    function getLeveragedSupplyTarget(uint256 supplyBalance)
        public
        view
        returns (uint256)
    {
        uint256 leverage = getMaxLeverage();
        return supplyBalance.mul(leverage).div(1e18);
    }

    function getSafeLeverageColFactor() public view returns (uint256) {
        uint256 colFactor = getMarketColFactor();


        uint256 safeColFactor = colFactor.sub(
            colFactorLeverageBuffer.mul(1e18).div(colFactorLeverageBufferMax)
        );

        return safeColFactor;
    }

    function getSafeSyncColFactor() public view returns (uint256) {
        uint256 colFactor = getMarketColFactor();


        uint256 safeColFactor = colFactor.sub(
            colFactorSyncBuffer.mul(1e18).div(colFactorSyncBufferMax)
        );

        return safeColFactor;
    }

    function getMarketColFactor() public view returns (uint256) {
        (, uint256 colFactor) = IComptroller(comptroller).markets(cdai);

        return colFactor;
    }


    function getMaxLeverage() public view returns (uint256) {
        uint256 safeLeverageColFactor = getSafeLeverageColFactor();


        uint256 leverage = uint256(1e36).div(1e18 - safeLeverageColFactor);
        return leverage;
    }









    function getCompAccrued() public returns (uint256) {
        (, , , uint256 accrued) = ICompoundLens(lens).getCompBalanceMetadataExt(
            comp,
            comptroller,
            address(this)
        );

        return accrued;
    }

    function getColFactor() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return borrowed.mul(1e18).div(supplied);
    }

    function getSuppliedUnleveraged() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return supplied.sub(borrowed);
    }

    function getSupplied() public returns (uint256) {
        return ICToken(cdai).balanceOfUnderlying(address(this));
    }

    function getBorrowed() public returns (uint256) {
        return ICToken(cdai).borrowBalanceCurrent(address(this));
    }

    function getBorrowable() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        (, uint256 colFactor) = IComptroller(comptroller).markets(cdai);


        return
            supplied.mul(colFactor).div(1e18).sub(borrowed).mul(9999).div(
                10000
            );
    }

    function getCurrentLeverage() public returns (uint256) {
        uint256 supplied = getSupplied();
        uint256 borrowed = getBorrowed();

        return supplied.mul(1e18).div(supplied.sub(borrowed));
    }



    function addKeeper(address _keeper) public {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!governance"
        );
        keepers[_keeper] = true;
    }

    function removeKeeper(address _keeper) public {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!governance"
        );
        keepers[_keeper] = false;
    }

    function setColFactorLeverageBuffer(uint256 _colFactorLeverageBuffer)
        public
    {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!governance"
        );
        colFactorLeverageBuffer = _colFactorLeverageBuffer;
    }

    function setColFactorSyncBuffer(uint256 _colFactorSyncBuffer) public {
        require(
            msg.sender == governance || msg.sender == strategist,
            "!governance"
        );
        colFactorSyncBuffer = _colFactorSyncBuffer;
    }





    function sync() public returns (bool) {
        uint256 colFactor = getColFactor();
        uint256 safeSyncColFactor = getSafeSyncColFactor();


        if (colFactor > safeSyncColFactor) {
            uint256 unleveragedSupply = getSuppliedUnleveraged();
            uint256 idealSupply = getLeveragedSupplyTarget(unleveragedSupply);

            deleverageUntil(idealSupply);

            return true;
        }

        return false;
    }

    function leverageToMax() public {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        uint256 idealSupply = getLeveragedSupplyTarget(unleveragedSupply);
        leverageUntil(idealSupply);
    }




    function leverageUntil(uint256 _supplyAmount) public onlyKeepers {



        uint256 leverage = getMaxLeverage();
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        require(
            _supplyAmount >= unleveragedSupply &&
                _supplyAmount <= unleveragedSupply.mul(leverage).div(1e18),
            "!leverage"
        );



        uint256 _borrowAndSupply;
        uint256 supplied = getSupplied();
        while (supplied < _supplyAmount) {
            _borrowAndSupply = getBorrowable();

            if (supplied.add(_borrowAndSupply) > _supplyAmount) {
                _borrowAndSupply = _supplyAmount.sub(supplied);
            }

            ICToken(cdai).borrow(_borrowAndSupply);
            deposit();

            supplied = supplied.add(_borrowAndSupply);
        }
    }

    function deleverageToMin() public {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        deleverageUntil(unleveragedSupply);
    }




    function deleverageUntil(uint256 _supplyAmount) public onlyKeepers {
        uint256 unleveragedSupply = getSuppliedUnleveraged();
        uint256 supplied = getSupplied();
        require(
            _supplyAmount >= unleveragedSupply && _supplyAmount <= supplied,
            "!deleverage"
        );



        uint256 _redeemAndRepay = getBorrowable();
        do {
            if (supplied.sub(_redeemAndRepay) < _supplyAmount) {
                _redeemAndRepay = supplied.sub(_supplyAmount);
            }

            require(
                ICToken(cdai).redeemUnderlying(_redeemAndRepay) == 0,
                "!redeem"
            );
            IERC20(dai).safeApprove(cdai, 0);
            IERC20(dai).safeApprove(cdai, _redeemAndRepay);
            require(ICToken(cdai).repayBorrow(_redeemAndRepay) == 0, "!repay");

            supplied = supplied.sub(_redeemAndRepay);
        } while (supplied > _supplyAmount);
    }

    function harvest() public override onlyBenevolent {
        address[] memory ctokens = new address[](1);
        ctokens[0] = cdai;

        IComptroller(comptroller).claimComp(address(this), ctokens);
        uint256 _comp = IERC20(comp).balanceOf(address(this));
        if (_comp > 0) {
            _swapUniswap(comp, want, _comp);
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

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(cdai, 0);
            IERC20(want).safeApprove(cdai, _want);
            require(ICToken(cdai).mint(_want) == 0, "!deposit");
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        uint256 _want = balanceOfWant();
        if (_want < _amount) {
            uint256 _redeem = _amount.sub(_want);


            require(ICToken(cdai).getCash() >= _redeem, "!cash-liquidity");


            uint256 borrowed = getBorrowed();
            uint256 supplied = getSupplied();
            uint256 curLeverage = getCurrentLeverage();
            uint256 borrowedToBeFree = _redeem.mul(curLeverage).div(1e18);



            if (borrowedToBeFree > borrowed) {
                this.deleverageToMin();
            } else {


                this.deleverageUntil(supplied.sub(borrowedToBeFree));
            }


            require(ICToken(cdai).redeemUnderlying(_redeem) == 0, "!redeem");
        }

        return _amount;
    }
}
