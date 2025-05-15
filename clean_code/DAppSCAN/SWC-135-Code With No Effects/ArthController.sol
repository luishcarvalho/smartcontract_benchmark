

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../ERC20/IERC20.sol';
import {SafeMath} from '../utils/math/SafeMath.sol';
import {IARTHPool} from './Pools/IARTHPool.sol';
import {IARTHController} from './IARTHController.sol';
import {AccessControl} from '../access/AccessControl.sol';
import {IChainlinkOracle} from '../Oracle/IChainlinkOracle.sol';
import {IUniswapPairOracle} from '../Oracle/IUniswapPairOracle.sol';





contract ArthController is AccessControl, IARTHController {
    using SafeMath for uint256;





    enum PriceChoice {ARTH, ARTHX}





    IERC20 public ARTH;
    IERC20 public ARTHX;

    IChainlinkOracle private _ETHGMUPricer;
    IUniswapPairOracle private _ARTHETHOracle;
    IUniswapPairOracle private _ARTHXETHOracle;

    address public wethAddress;
    address public arthxAddress;
    address public ownerAddress;
    address public creatorAddress;
    address public timelockAddress;
    address public controllerAddress;
    address public arthETHOracleAddress;
    address public arthxETHOracleAddress;
    address public ethGMUConsumerAddress;
    address public DEFAULT_ADMIN_ADDRESS;

    uint256 public arthStep;
    uint256 public mintingFee;
    uint256 public redemptionFee;
    uint256 public refreshCooldown;
    uint256 public globalCollateralRatio;



    uint256 public priceBand;




    uint256 public priceTarget;




    uint256 public lastCallTime;


    uint256 public constant genesisSupply = 2000000e18;

    bool public isColalteralRatioPaused = false;

    bytes32 public constant COLLATERAL_RATIO_PAUSER =
        keccak256('COLLATERAL_RATIO_PAUSER');

    address[] public arthPoolsArray;

    mapping(address => bool) public override arthPools;

    uint8 private _ethGMUPricerDecimals;
    uint256 private constant _PRICE_PRECISION = 1e6;





    modifier onlyCollateralRatioPauser() {
        require(hasRole(COLLATERAL_RATIO_PAUSER, msg.sender));
        _;
    }


    modifier onlyPools() {
        require(arthPools[msg.sender] == true, 'ARTHController: FORBIDDEN');
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            'ARTHController: FORBIDDEN'
        );
        _;
    }

    modifier onlyByOwnerOrGovernance() {
        require(
            msg.sender == ownerAddress ||
                msg.sender == timelockAddress ||
                msg.sender == controllerAddress,
            'ARTHController: FORBIDDEN'
        );
        _;
    }


    modifier onlyByOwnerGovernanceOrPool() {
        require(
            msg.sender == ownerAddress ||
                msg.sender == timelockAddress ||
                arthPools[msg.sender] == true,
            'ARTHController: FORBIDDEN'
        );
        _;
    }





    constructor(address _creatorAddress, address _timelockAddress) {
        creatorAddress = _creatorAddress;
        timelockAddress = _timelockAddress;

        ownerAddress = _creatorAddress;
        DEFAULT_ADMIN_ADDRESS = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(COLLATERAL_RATIO_PAUSER, creatorAddress);
        grantRole(COLLATERAL_RATIO_PAUSER, timelockAddress);

        arthStep = 2500;
        priceBand = 5000;
        priceTarget = 1000000;
        refreshCooldown = 3600;
        globalCollateralRatio = 1000000;
    }





    function refreshCollateralRatio() external override {
        require(
            isColalteralRatioPaused == false,
            'ARTHController: Collateral Ratio has been paused'
        );
        require(
            block.timestamp - lastCallTime >= refreshCooldown,
            'ARTHController: must wait till callable again'
        );

        uint256 currentPrice = getARTHPrice();


        if (currentPrice > priceTarget.add(priceBand)) {

            if (globalCollateralRatio <= arthStep) {
                globalCollateralRatio = 0;
            } else {
                globalCollateralRatio = globalCollateralRatio.sub(arthStep);
            }
        } else if (currentPrice < priceTarget.sub(priceBand)) {

            if (globalCollateralRatio.add(arthStep) >= 1000000) {
                globalCollateralRatio = 1000000;
            } else {
                globalCollateralRatio = globalCollateralRatio.add(arthStep);
            }
        }

        lastCallTime = block.timestamp;
    }



    function addPool(address poolAddress)
        external
        override
        onlyByOwnerOrGovernance
    {
        require(
            arthPools[poolAddress] == false,
            'ARTHController: address present'
        );

        arthPools[poolAddress] = true;
        arthPoolsArray.push(poolAddress);
    }

    function removePool(address poolAddress)
        external
        override
        onlyByOwnerOrGovernance
    {
        require(
            arthPools[poolAddress] == true,
            'ARTHController: address absent'
        );


        delete arthPools[poolAddress];


        for (uint256 i = 0; i < arthPoolsArray.length; i++) {
            if (arthPoolsArray[i] == poolAddress) {
                arthPoolsArray[i] = address(0);
                break;
            }
        }
    }





    function setGlobalCollateralRatio(uint256 _globalCollateralRatio)
        public
        override
        onlyAdmin
    {
        globalCollateralRatio = _globalCollateralRatio;
    }

    function setARTHXAddress(address _arthxAddress)
        public
        override
        onlyByOwnerOrGovernance
    {
        arthxAddress = _arthxAddress;
    }

    function setPriceTarget(uint256 newPriceTarget)
        public
        override
        onlyByOwnerOrGovernance
    {
        priceTarget = newPriceTarget;
    }

    function setRefreshCooldown(uint256 newCooldown)
        public
        override
        onlyByOwnerOrGovernance
    {
        refreshCooldown = newCooldown;
    }

    function setETHGMUOracle(address _ethGMUConsumerAddress)
        public
        override
        onlyByOwnerOrGovernance
    {
        ethGMUConsumerAddress = _ethGMUConsumerAddress;
        _ETHGMUPricer = IChainlinkOracle(ethGMUConsumerAddress);
        _ethGMUPricerDecimals = _ETHGMUPricer.getDecimals();
    }

    function setARTHXETHOracle(
        address _arthxOracleAddress,
        address _wethAddress
    ) public override onlyByOwnerOrGovernance {
        arthxETHOracleAddress = _arthxOracleAddress;
        _ARTHXETHOracle = IUniswapPairOracle(_arthxOracleAddress);
        wethAddress = _wethAddress;
    }

    function setARTHETHOracle(address _arthOracleAddress, address _wethAddress)
        public
        override
        onlyByOwnerOrGovernance
    {
        arthETHOracleAddress = _arthOracleAddress;
        _ARTHETHOracle = IUniswapPairOracle(_arthOracleAddress);
        wethAddress = _wethAddress;
    }

    function toggleCollateralRatio() public override onlyCollateralRatioPauser {
        isColalteralRatioPaused = !isColalteralRatioPaused;
    }

    function setMintingFee(uint256 fee)
        public
        override
        onlyByOwnerOrGovernance
    {
        mintingFee = fee;
    }

    function setArthStep(uint256 newStep)
        public
        override
        onlyByOwnerOrGovernance
    {
        arthStep = newStep;
    }

    function setRedemptionFee(uint256 fee)
        public
        override
        onlyByOwnerOrGovernance
    {
        redemptionFee = fee;
    }

    function setOwner(address _ownerAddress)
        public
        override
        onlyByOwnerOrGovernance
    {
        ownerAddress = _ownerAddress;
    }

    function setPriceBand(uint256 _priceBand)
        public
        override
        onlyByOwnerOrGovernance
    {
        priceBand = _priceBand;
    }

    function setTimelock(address newTimelock)
        public
        override
        onlyByOwnerOrGovernance
    {
        timelockAddress = newTimelock;
    }

    function getRefreshCooldown() external view override returns (uint256) {
        return refreshCooldown;
    }

    function getARTHPrice() public view override returns (uint256) {
        return _getOraclePrice(PriceChoice.ARTH);
    }

    function getARTHXPrice() public view override returns (uint256) {
        return _getOraclePrice(PriceChoice.ARTHX);
    }

    function getETHGMUPrice() public view override returns (uint256) {
        return
            uint256(_ETHGMUPricer.getLatestPrice()).mul(_PRICE_PRECISION).div(
                uint256(10)**_ethGMUPricerDecimals
            );
    }

    function getGlobalCollateralRatio() public view override returns (uint256) {
        return globalCollateralRatio;
    }

    function getGlobalCollateralValue() public view override returns (uint256) {
        uint256 totalCollateralValueD18 = 0;

        for (uint256 i = 0; i < arthPoolsArray.length; i++) {

            if (arthPoolsArray[i] != address(0)) {
                totalCollateralValueD18 = totalCollateralValueD18.add(
                    IARTHPool(arthPoolsArray[i]).getCollateralGMUBalance()
                );
            }
        }

        return totalCollateralValueD18;
    }

    function getARTHInfo()
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            getARTHPrice(),
            getARTHXPrice(),
            ARTH.totalSupply(),
            globalCollateralRatio,
            getGlobalCollateralValue(),
            mintingFee,
            redemptionFee,
            getETHGMUPrice()
        );
    }






    function _getOraclePrice(PriceChoice choice)
        internal
        view
        returns (uint256)
    {
        uint256 eth2GMUPrice =
            uint256(_ETHGMUPricer.getLatestPrice()).mul(_PRICE_PRECISION).div(
                uint256(10)**_ethGMUPricerDecimals
            );

        uint256 priceVsETH;

        if (choice == PriceChoice.ARTH) {
            priceVsETH = uint256(
                _ARTHETHOracle.consult(wethAddress, _PRICE_PRECISION)
            );
        } else if (choice == PriceChoice.ARTHX) {
            priceVsETH = uint256(
                _ARTHXETHOracle.consult(wethAddress, _PRICE_PRECISION)
            );
        } else
            revert(
                'INVALID PRICE CHOICE. Needs to be either 0 (ARTH) or 1 (ARTHX)'
            );

        return eth2GMUPrice.mul(_PRICE_PRECISION).div(priceVsETH);
    }
}
