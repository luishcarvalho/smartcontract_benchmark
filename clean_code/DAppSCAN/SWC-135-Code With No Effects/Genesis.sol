

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IARTH} from '../Arth/IARTH.sol';
import {IWETH} from '../ERC20/IWETH.sol';
import {ERC20} from '../ERC20/ERC20.sol';
import {IARTHX} from '../ARTHX/IARTHX.sol';
import {ICurve} from '../Curves/ICurve.sol';
import {SafeMath} from '../utils/math/SafeMath.sol';
import {Ownable} from '../access/Ownable.sol';
import {IERC20Mintable} from '../ERC20/IERC20Mintable.sol';
import {IChainlinkOracle} from '../Oracle/IChainlinkOracle.sol';
import {IBondingCurveOracle} from './IBondingCurveOracle.sol';
import {IUniswapV2Factory} from '../Uniswap/Interfaces/IUniswapV2Factory.sol';
import {IUniswapV2Router02} from '../Uniswap/Interfaces/IUniswapV2Router02.sol';

contract Genesis is ERC20, Ownable {
    using SafeMath for uint256;





    IWETH private immutable _WETH;
    IARTH private immutable _ARTH;
    IARTHX private immutable _ARTHX;
    IERC20Mintable private immutable _MAHA;
    IUniswapV2Router02 private immutable _ROUTER;
    IChainlinkOracle public ethGMUOracle;
    IBondingCurveOracle public curveOracle;





    uint256 public duration;
    uint256 public startTime;

    uint256 public hardCap = 100e18;

    uint256 public arthETHPairPercent = 5;
    uint256 public arthxETHPairPercent = 5;
    uint256 public arthWETHPoolPercent = 90;

    address payable public arthWETHPoolAddres;
    address payable public arthETHPairAddress;
    address payable public arthxETHPairAddress;

    uint256 private constant _PRICE_PRECISION = 1e6;





    event Mint(address indexed account, uint256 ethAmount, uint256 genAmount);
    event RedeemARTHX(address indexed account, uint256 amount);
    event RedeemARTHXAndMAHA(
        address indexed account,
        uint256 arthAmount,
        uint256 mahaAmount
    );
    event Distribute(
        address indexed account,
        uint256 ethAMount,
        uint256 tokenAmount
    );





    modifier hasStarted() {
        require(block.timestamp >= startTime, 'Genesis: not started');
        _;
    }

    modifier isActive() {
        require(
            block.timestamp >= startTime &&
                block.timestamp <= startTime.add(duration),
            'Genesis: not active'
        );
        _;
    }

    modifier hasEnded() {
        require(
            block.timestamp >= startTime.add(duration),
            'Genesis: still active'
        );
        _;
    }




    constructor(
        IWETH __WETH,
        IARTH __ARTH,
        IARTHX __ARTHX,
        IERC20Mintable __MAHA,
        IUniswapV2Router02 __ROUTER,
        IChainlinkOracle _ethGmuOracle,
        IBondingCurveOracle _curveOracle,
        uint256 _hardCap,
        uint256 _startTime,
        uint256 _duration
    ) ERC20('ARTH Genesis', 'ARTH-GEN') {
        hardCap = _hardCap;
        duration = _duration;
        startTime = _startTime;

        _WETH = __WETH;
        _ARTH = __ARTH;
        _MAHA = __MAHA;
        _ARTHX = __ARTHX;
        _ROUTER = __ROUTER;

        curveOracle = _curveOracle;
        ethGMUOracle = _ethGmuOracle;
    }





    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function setPoolAndPairs(
        address payable _arthETHPool,
        address payable _arthETHPair,
        address payable _arthxETHPair
    ) external onlyOwner {
        arthWETHPoolAddres = _arthETHPool;
        arthETHPairAddress = _arthETHPair;
        arthxETHPairAddress = _arthxETHPair;
    }

    function setHardCap(uint256 _hardCap) external onlyOwner {
        hardCap = _hardCap;
    }

    function setARTHWETHPoolAddress(address payable poolAddress)
        external
        onlyOwner
    {
        arthWETHPoolAddres = poolAddress;
    }

    function setARTHETHPairAddress(address payable pairAddress)
        external
        onlyOwner
    {
        arthETHPairAddress = pairAddress;
    }

    function setARTHXETHPairAddress(address payable pairAddress)
        external
        onlyOwner
    {
        arthxETHPairAddress = pairAddress;
    }

    function setDistributionPercents(
        uint256 poolPercent,
        uint256 arthPairPercent,
        uint256 arthxPairPercent
    ) external onlyOwner {
        arthWETHPoolPercent = poolPercent;
        arthETHPairPercent = arthPairPercent;
        arthxETHPairPercent = arthxPairPercent;
    }

    function setCurve(IBondingCurveOracle curve) external onlyOwner {
        curveOracle = curve;
    }

    function setETHGMUOracle(IChainlinkOracle oracle) external onlyOwner {
        ethGMUOracle = oracle;
    }





    function mint(uint256 amount) public payable isActive {
        require(amount > 0, 'Genesis: amount = 0');
        require(msg.value == amount, 'Genesis: INVALID INPUT');









        uint256 ethValue = msg.value.mul(getETHGMUPrice());

        uint256 mintAmount = ethValue.mul(1e18).div(getCurvePrice());

        _mint(msg.sender, mintAmount);

        emit Mint(msg.sender, amount, mintAmount);
    }

    function redeem(uint256 amount) external {
        if (block.timestamp >= startTime.add(duration)) {
            _redeemARTHXAndMAHA(amount);
            return;
        }

        _redeemARTHX(amount);
    }

    function distribute() external onlyOwner hasEnded {
        uint256 balance = address(this).balance;

        uint256 arthETHPairAmount = balance.mul(arthETHPairPercent).div(100);
        uint256 arthWETHPoolAmount = balance.mul(arthWETHPoolPercent).div(100);
        uint256 arthxETHPairAmount = balance.mul(arthxETHPairPercent).div(100);

        _distributeToWETHPool(arthWETHPoolAmount);
        _distributeToUniswapPair(arthETHPairAddress, arthETHPairAmount);
        _distributeToUniswapPair(arthxETHPairAddress, arthxETHPairAmount);
    }

    function getETHGMUPrice() public view returns (uint256) {
        return ethGMUOracle.getLatestPrice().mul(_PRICE_PRECISION).div(
                ethGMUOracle.getDecimals()
            );
    }

    function getPercentRaised() public view returns (uint256) {
        return address(this).balance.mul(100).div(hardCap);
    }

    function getCurvePrice() public view returns (uint256) {
        return
            curveOracle.getPrice(getPercentRaised()).mul(_PRICE_PRECISION).div(
                1e18
            );
    }





    function _distributeToWETHPool(uint256 amount) internal hasEnded {
        if (arthWETHPoolAddres == address(0)) return;



        _WETH.deposit{value: amount}();


        assert(_WETH.transfer(arthWETHPoolAddres, amount));

        emit Distribute(arthWETHPoolAddres, amount, 0);
    }

    function _distributeToUniswapPair(address pair, uint256 amount)
        internal
        hasEnded
    {
        address tokenAddress = address(0);


        if (pair == address(0)) return;



        if (pair == arthETHPairAddress) {

            _ARTH.poolMint(address(this), amount);
            _ARTH.approve(address(_ROUTER), amount);

            tokenAddress = address(_ARTH);
        } else {

            _ARTHX.poolMint(address(this), amount);
            _ARTHX.approve(address(_ROUTER), amount);

            tokenAddress = address(_ARTHX);
        }

        require(tokenAddress != address(0), 'Genesis: invalid address');


        (uint256 amountToken, uint256 amountETH, uint256 liquidity) =
            _ROUTER.addLiquidityETH{value: amount}(
                tokenAddress,
                amount,
                amount,
                amount,
                address(this),
                block.timestamp
            );

        require(liquidity > 0, 'Genesis: distribute pair failed');
        require(amountETH > 0, 'Genesis: distribute pair failed');
        require(amountToken > 0, 'Genesis: distribute pair failed');

        emit Distribute(pair, amount, amount);
    }

    function _redeemARTHX(uint256 amount) internal isActive {
        require(balanceOf(msg.sender) >= amount, 'Genesis: balance < amount');

        _burn(msg.sender, amount);
        _ARTH.poolMint(msg.sender, amount);

        emit RedeemARTHX(msg.sender, amount);
    }

    function _redeemARTHXAndMAHA(uint256 amount) internal hasEnded {
        require(balanceOf(msg.sender) >= amount, 'Genesis: balance < amount');

        _burn(msg.sender, amount);
        _ARTH.poolMint(msg.sender, amount);



        uint256 mahaAmount = 0;


        _MAHA.mint(msg.sender, mahaAmount);

        emit RedeemARTHXAndMAHA(msg.sender, amount, mahaAmount);
    }

    receive() external payable {
        mint(msg.value);
    }
}
