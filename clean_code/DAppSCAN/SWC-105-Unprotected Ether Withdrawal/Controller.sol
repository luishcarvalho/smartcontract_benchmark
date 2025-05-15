
pragma solidity ^0.6.10;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IVat.sol";
import "./interfaces/IPot.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IController.sol";
import "./interfaces/IYDai.sol";
import "./helpers/Delegable.sol";
import "./helpers/DecimalMath.sol";
import "./helpers/Orchestrated.sol";














contract Controller is IController, Orchestrated(), Delegable(), DecimalMath {
    using SafeMath for uint256;

    event Posted(bytes32 indexed collateral, address indexed user, int256 amount);
    event Borrowed(bytes32 indexed collateral, uint256 indexed maturity, address indexed user, int256 amount);

    bytes32 public constant CHAI = "CHAI";
    bytes32 public constant WETH = "ETH-A";
    uint256 public constant DUST = 50000000000000000;
    uint256 public constant THREE_MONTHS = 7776000;

    IVat internal _vat;
    IPot internal _pot;
    ITreasury internal _treasury;

    mapping(uint256 => IYDai) public override series;
    uint256[] public override seriesIterator;

    mapping(bytes32 => mapping(address => uint256)) public override posted;
    mapping(bytes32 => mapping(uint256 => mapping(address => uint256))) public override debtYDai;

    bool public live = true;


    constructor (
        address vat_,
        address pot_,
        address treasury_
    ) public {
        _vat = IVat(vat_);
        _pot = IPot(pot_);
        _treasury = ITreasury(treasury_);
    }


    modifier onlyLive() {
        require(live == true, "Controller: Not available during unwind");
        _;
    }


    modifier validCollateral(bytes32 collateral) {
        require(
            collateral == WETH || collateral == CHAI,
            "Controller: Unrecognized collateral"
        );
        _;
    }


    modifier validSeries(uint256 maturity) {
        require(
            containsSeries(maturity),
            "Controller: Unrecognized series"
        );
        _;
    }


    function toInt256(uint256 x) internal pure returns(int256) {
        require(
            x <= 57896044618658097711785492504343953926634992332820282019728792003956564819967,
            "Controller: Cast overflow"
        );
        return int256(x);
    }


    function shutdown() public override {
        require(
            _treasury.live() == false,
            "Controller: Treasury is live"
        );
        live = false;
    }





    function isCollateralized(bytes32 collateral, address user) public view override returns (bool) {
        return powerOf(collateral, user) >= totalDebtDai(collateral, user);
    }




    function aboveDustOrZero(bytes32 collateral, address user) public view returns (bool) {
        uint256 postedCollateral = posted[collateral][user];
        return postedCollateral == 0 || DUST < postedCollateral;
    }


    function totalSeries() public view override returns (uint256) {
        return seriesIterator.length;
    }



    function containsSeries(uint256 maturity) public view override returns (bool) {
        return address(series[maturity]) != address(0);
    }




    function addSeries(address yDaiContract) public onlyOwner {
        uint256 maturity = IYDai(yDaiContract).maturity();
        require(
            !containsSeries(maturity),
            "Controller: Series already added"
        );
        series[maturity] = IYDai(yDaiContract);
        seriesIterator.push(maturity);
    }







    function inDai(bytes32 collateral, uint256 maturity, uint256 yDaiAmount)
        public view override
        validCollateral(collateral)
        returns (uint256)
    {
        IYDai yDai = series[maturity];
        if (yDai.isMature()){
            if (collateral == WETH){
                return muld(yDaiAmount, yDai.rateGrowth());
            } else if (collateral == CHAI) {
                return muld(yDaiAmount, yDai.chiGrowth());
            }
        } else {
            return yDaiAmount;
        }
    }







    function inYDai(bytes32 collateral, uint256 maturity, uint256 daiAmount)
        public view override
        validCollateral(collateral)
        returns (uint256)
    {
        IYDai yDai = series[maturity];
        if (yDai.isMature()){
            if (collateral == WETH){
                return divd(daiAmount, yDai.rateGrowth());
            } else if (collateral == CHAI) {
                return divd(daiAmount, yDai.chiGrowth());
            }
        } else {
            return daiAmount;
        }
    }












    function debtDai(bytes32 collateral, uint256 maturity, address user) public view returns (uint256) {
        return inDai(collateral, maturity, debtYDai[collateral][maturity][user]);
    }







    function totalDebtDai(bytes32 collateral, address user) public view override returns (uint256) {
        uint256 totalDebt;
        uint256[] memory _seriesIterator = seriesIterator;
        for (uint256 i = 0; i < _seriesIterator.length; i += 1) {
            if (debtYDai[collateral][_seriesIterator[i]][user] > 0) {
                totalDebt = totalDebt + debtDai(collateral, _seriesIterator[i], user);
            }
        }
        return totalDebt;
    }








    function powerOf(bytes32 collateral, address user) public view returns (uint256) {

        if (collateral == WETH){
            (,, uint256 spot,,) = _vat.ilks(WETH);
            return muld(posted[collateral][user], spot);
        } else if (collateral == CHAI) {
            uint256 chi = _pot.chi();
            return muld(posted[collateral][user], chi);
        }
        return 0;
    }




    function locked(bytes32 collateral, address user)
        public view
        validCollateral(collateral)
        returns (uint256)
    {
        if (collateral == WETH){
            (,, uint256 spot,,) = _vat.ilks(WETH);
            return divdrup(totalDebtDai(collateral, user), spot);
        } else if (collateral == CHAI) {
            return divdrup(totalDebtDai(collateral, user), _pot.chi());
        }
    }









    function post(bytes32 collateral, address from, address to, uint256 amount)
        public override
        validCollateral(collateral)
        onlyHolderOrDelegate(from, "Controller: Only Holder Or Delegate")
        onlyLive
    {
        posted[collateral][to] = posted[collateral][to].add(amount);

        if (collateral == WETH){
            require(
                aboveDustOrZero(collateral, to),
                "Controller: Below dust"
            );
            _treasury.pushWeth(from, amount);
        } else if (collateral == CHAI) {
            _treasury.pushChai(from, amount);
        }

        emit Posted(collateral, to, toInt256(amount));
    }









    function withdraw(bytes32 collateral, address from, address to, uint256 amount)
        public override
        validCollateral(collateral)
        onlyHolderOrDelegate(from, "Controller: Only Holder Or Delegate")
        onlyLive
    {
        posted[collateral][from] = posted[collateral][from].sub(amount);

        require(
            isCollateralized(collateral, from),
            "Controller: Too much debt"
        );

        if (collateral == WETH){
            require(
                aboveDustOrZero(collateral, to),
                "Controller: Below dust"
            );
            _treasury.pullWeth(to, amount);
        } else if (collateral == CHAI) {
            _treasury.pullChai(to, amount);
        }

        emit Posted(collateral, from, -toInt256(amount));
    }














    function borrow(bytes32 collateral, uint256 maturity, address from, address to, uint256 yDaiAmount)
        public override
        validCollateral(collateral)
        validSeries(maturity)
        onlyHolderOrDelegate(from, "Controller: Only Holder Or Delegate")
        onlyLive
    {
        IYDai yDai = series[maturity];

        debtYDai[collateral][maturity][from] = debtYDai[collateral][maturity][from].add(yDaiAmount);

        require(
            isCollateralized(collateral, from),
            "Controller: Too much debt"
        );

        yDai.mint(to, yDaiAmount);
        emit Borrowed(collateral, maturity, from, toInt256(yDaiAmount));
    }

















    function repayYDai(bytes32 collateral, uint256 maturity, address from, address to, uint256 yDaiAmount)
        public override
        validCollateral(collateral)
        validSeries(maturity)
        onlyHolderOrDelegate(from, "Controller: Only Holder Or Delegate")
        onlyLive
    {
        uint256 toRepay = Math.min(yDaiAmount, debtYDai[collateral][maturity][to]);
        series[maturity].burn(from, toRepay);
        _repay(collateral, maturity, to, toRepay);
    }


















    function repayDai(bytes32 collateral, uint256 maturity, address from, address to, uint256 daiAmount)
        public override
        validCollateral(collateral)
        validSeries(maturity)
        onlyHolderOrDelegate(from, "Controller: Only Holder Or Delegate")
        onlyLive
    {
        uint256 toRepay = Math.min(daiAmount, debtDai(collateral, maturity, to));
        _treasury.pushDai(from, toRepay);
        _repay(collateral, maturity, to, inYDai(collateral, maturity, toRepay));
    }













    function _repay(bytes32 collateral, uint256 maturity, address user, uint256 yDaiAmount) internal {
        debtYDai[collateral][maturity][user] = debtYDai[collateral][maturity][user].sub(yDaiAmount);

        emit Borrowed(collateral, maturity, user, -toInt256(yDaiAmount));
    }






    function erase(bytes32 collateral, address user)
        public override
        validCollateral(collateral)
        onlyOrchestrated("Controller: Not Authorized")
        returns (uint256, uint256)
    {
        uint256 userCollateral = posted[collateral][user];
        delete posted[collateral][user];

        uint256 userDebt;
        uint256[] memory _seriesIterator = seriesIterator;
        for (uint256 i = 0; i < _seriesIterator.length; i += 1) {
            uint256 maturity = _seriesIterator[i];
            userDebt = userDebt.add(debtDai(collateral, maturity, user));
            delete debtYDai[collateral][maturity][user];
        }

        return (userCollateral, userDebt);
    }
}
