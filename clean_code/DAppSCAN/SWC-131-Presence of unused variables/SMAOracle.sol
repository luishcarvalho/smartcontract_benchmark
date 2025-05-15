
pragma solidity 0.8.7;
import "../interfaces/IOracleWrapper.sol";
import "../interfaces/IPriceObserver.sol";
import "../implementation/PriceObserver.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";

contract SMAOracle is IOracleWrapper {
    using PRBMathSD59x18 for int256;


    address public override oracle;


    address public immutable override deployer;


    address public observer;



    int256 public price;


    uint256 public periods;


    uint256 lastUpdate = 0;


    uint256 updateInterval = 0;

    int256 public scaler;
    uint256 public constant MAX_DECIMALS = 18;

    constructor(
        address _spotOracle,
        uint256 _spotDecimals,
        address _observer,
        uint256 _periods,
        uint256 _updateInterval,
        address _deployer
    ) {
        require(_spotOracle != address(0) && _observer != address(0), "SMA: Null address forbidden");
        require(_periods > 0 && _periods <= IPriceObserver(_observer).capacity(), "SMA: Out of bounds");
        require(_spotDecimals <= MAX_DECIMALS, "SMA: Decimal precision too high");
        periods = _periods;
        oracle = _spotOracle;
        observer = _observer;
        deployer = _deployer;











    function fromWad(int256 wad) external view override returns (int256) {
        return wad / scaler;
    }

    function getPrice() external view override returns (int256) {











    function update() internal returns (int256) {































    function SMA(int256[24] memory xs, uint256 k) public pure returns (int256) {
        uint256 n = xs.length;






















    function toWad(int256 x) private view returns (int256) {
        return x * scaler;
    }







    function getPriceAndMetadata() external view override returns (int256 _price, bytes memory _data) {
        _price = SMA(IPriceObserver(observer).getAll(), periods);
        _data = "";
    }
}
