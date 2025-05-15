
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Utils/LongTermOrders.sol";


contract TWAMM is ERC20 {
    using LongTermOrdersLib for LongTermOrdersLib.LongTermOrders;
    using PRBMathUD60x18 for uint256;

    address public owner_address;






    address public tokenA;
    address public tokenB;


    uint256 public constant LP_FEE = 30;


    mapping(address => uint256) reserveMap;






    uint256 public orderBlockInterval;


    bool public whitelistDisabled;


    LongTermOrdersLib.LongTermOrders internal longTermOrders;






    event InitialLiquidityProvided(address indexed addr, uint256 amountA, uint256 amountB);


    event LiquidityProvided(address indexed addr, uint256 lpTokens);


    event LiquidityRemoved(address indexed addr, uint256 lpTokens);


    event SwapAToB(address indexed addr, uint256 amountAIn, uint256 amountBOut);


    event SwapBToA(address indexed addr, uint256 amountBIn, uint256 amountAOut);


    event LongTermSwapAToB(address indexed addr, uint256 amountAIn, uint256 orderId);


    event LongTermSwapBToA(address indexed addr, uint256 amountBIn, uint256 orderId);


    event CancelLongTermOrder(address indexed addr, uint256 orderId);





    constructor(string memory _name
                ,string memory _symbol
                ,address _tokenA
                ,address _tokenB
                ,uint256 _orderBlockInterval
                ,address _owner_address
    ) ERC20(_name, _symbol) {

        tokenA = _tokenA;
        tokenB = _tokenB;
        orderBlockInterval = _orderBlockInterval;
        longTermOrders.initialize(_tokenA, _tokenB, block.number, _orderBlockInterval);
        whitelistDisabled = false;
        owner_address = _owner_address;

    }


    modifier onlyWhitelist() {
        require(whitelistDisabled || msg.sender == owner_address, 'EC5');
        _;
    }


    function disableWhitelist() public {
        require(msg.sender == owner_address);
        whitelistDisabled = true;
    }



    function provideInitialLiquidity(uint256 amountA, uint256 amountB) external {
        require(totalSupply() == 0, 'EC4');

        ERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        ERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        reserveMap[tokenA] = amountA;
        reserveMap[tokenB] = amountB;


        uint256 lpAmount = amountA.fromUint().sqrt().mul(amountB.fromUint().sqrt()).toUint();
        _mint(msg.sender, lpAmount);

        emit InitialLiquidityProvided(msg.sender, amountA, amountB);
    }




    function provideLiquidity(uint256 lpTokenAmount) external {
        require(totalSupply() != 0, 'EC3');


        longTermOrders.executeVirtualOrdersUntilCurrentBlock(reserveMap);


        uint256 amountAIn = lpTokenAmount * reserveMap[tokenA] / totalSupply();
        uint256 amountBIn = lpTokenAmount * reserveMap[tokenB] / totalSupply();

        ERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        ERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);

        reserveMap[tokenA] += amountAIn;
        reserveMap[tokenB] += amountBIn;

        _mint(msg.sender, lpTokenAmount);

        emit LiquidityProvided(msg.sender, lpTokenAmount);
    }




    function removeLiquidity(uint256 lpTokenAmount) external {
        require(lpTokenAmount <= totalSupply(), 'EC2');


        longTermOrders.executeVirtualOrdersUntilCurrentBlock(reserveMap);


        uint256 amountAOut = reserveMap[tokenA] * lpTokenAmount / totalSupply();
        uint256 amountBOut = reserveMap[tokenB] * lpTokenAmount / totalSupply();

        ERC20(tokenA).transfer(msg.sender, amountAOut);
        ERC20(tokenB).transfer(msg.sender, amountBOut);

        reserveMap[tokenA] -= amountAOut;
        reserveMap[tokenB] -= amountBOut;

        _burn(msg.sender, lpTokenAmount);

        emit LiquidityRemoved(msg.sender, lpTokenAmount);
    }


    function swapFromAToB(uint256 amountAIn) external {
        uint256 amountBOut = performSwap(tokenA, tokenB, amountAIn);
        emit SwapAToB(msg.sender, amountAIn, amountBOut);
    }




    function longTermSwapFromAToB(uint256 amountAIn, uint256 numberOfBlockIntervals) external onlyWhitelist {
        uint256 orderId =  longTermOrders.longTermSwapFromAToB(amountAIn, numberOfBlockIntervals, reserveMap);
        emit LongTermSwapAToB(msg.sender, amountAIn, orderId);
    }


    function swapFromBToA(uint256 amountBIn) external {
        uint256 amountAOut = performSwap(tokenB, tokenA, amountBIn);
        emit SwapBToA(msg.sender, amountBIn, amountAOut);
    }




    function longTermSwapFromBToA(uint256 amountBIn, uint256 numberOfBlockIntervals) external onlyWhitelist{
        uint256 orderId = longTermOrders.longTermSwapFromBToA(amountBIn, numberOfBlockIntervals, reserveMap);
        emit LongTermSwapBToA(msg.sender, amountBIn, orderId);
    }


    function cancelLongTermSwap(uint256 orderId) external onlyWhitelist{
        longTermOrders.cancelLongTermSwap(orderId, reserveMap);
        emit CancelLongTermOrder(msg.sender, orderId);
    }


    function withdrawProceedsFromLongTermSwap(uint256 orderId) external onlyWhitelist {
        longTermOrders.withdrawProceedsFromLongTermSwap(orderId, reserveMap);

    }



    function performSwap(address from, address to, uint256 amountIn) private returns (uint256 amountOutMinusFee) {
        require(amountIn > 0, 'EC1');


        longTermOrders.executeVirtualOrdersUntilCurrentBlock(reserveMap);


        uint256 amountOut = reserveMap[to] * amountIn / (reserveMap[from] + amountIn);

        amountOutMinusFee = amountOut * (10000 - LP_FEE) / 10000;

        ERC20(from).transferFrom(msg.sender, address(this), amountIn);
        ERC20(to).transfer(msg.sender, amountOutMinusFee);

        reserveMap[from] += amountIn;
        reserveMap[to] -= amountOutMinusFee;
    }


    function tokenAReserves() public view returns (uint256) {
        return reserveMap[tokenA];
    }


    function tokenBReserves() public view returns (uint256) {
        return reserveMap[tokenB];
    }



    function executeVirtualOrders() public onlyWhitelist {
        longTermOrders.executeVirtualOrdersUntilCurrentBlock(reserveMap);
    }


}
