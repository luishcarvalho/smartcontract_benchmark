
pragma solidity ^0.6.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./YieldMath.sol";
import "../helpers/Delegable.sol";
import "../interfaces/IPot.sol";
import "../interfaces/IYDai.sol";
import "../interfaces/IPool.sol";




contract Pool is IPool, ERC20, Delegable {

    event Trade(uint256 maturity, address indexed from, address indexed to, int256 daiTokens, int256 yDaiTokens);
    event Liquidity(uint256 maturity, address indexed from, address indexed to, int256 daiTokens, int256 yDaiTokens, int256 poolTokens);

    int128 constant public k = int128(uint256((1 << 64)) / 126144000);
    int128 constant public g = int128(uint256((999 << 64)) / 1000);
    uint128 immutable public maturity;

    IERC20 public dai;
    IYDai public yDai;

    constructor(address dai_, address yDai_, string memory name_, string memory symbol_)
        public
        ERC20(name_, symbol_)
        Delegable()
    {
        dai = IERC20(dai_);
        yDai = IYDai(yDai_);

        maturity = toUint128(yDai.maturity());
    }


    modifier beforeMaturity() {
        require(
            now < maturity,
            "Pool: Too late"
        );
        _;
    }


    function add(uint128 a, uint128 b)
        internal pure returns (uint128)
    {
        uint128 c = a + b;
        require(c >= a, "Pool: Dai reserves too high");

        return c;
    }


    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b <= a, "Pool: yDai reserves too low");
        uint128 c = a - b;

        return c;
    }


    function toUint128(uint256 x) internal pure returns(uint128) {
        require(
            x <= 340282366920938463463374607431768211455,
            "Pool: Cast overflow"
        );
        return uint128(x);
    }


    function toInt256(uint256 x) internal pure returns(int256) {
        require(
            x <= 57896044618658097711785492504343953926634992332820282019728792003956564819967,
            "Pool: Cast overflow"
        );
        return int256(x);
    }





    function init(uint128 daiIn)
        external
        beforeMaturity
    {
        require(
            totalSupply() == 0,
            "Pool: Already initialized"
        );

        dai.transferFrom(msg.sender, address(this), daiIn);
        _mint(msg.sender, daiIn);
        emit Liquidity(maturity, msg.sender, msg.sender, -toInt256(daiIn), 0, toInt256(daiIn));
    }





    function mint(uint256 daiOffered)
        external
        returns (uint256)
    {
        uint256 supply = totalSupply();
        uint256 daiReserves = dai.balanceOf(address(this));

        uint256 yDaiReserves = yDai.balanceOf(address(this));
        uint256 tokensMinted = supply.mul(daiOffered).div(daiReserves);
        uint256 yDaiRequired = yDaiReserves.mul(tokensMinted).div(supply);

        require(dai.transferFrom(msg.sender, address(this), daiOffered));
        require(yDai.transferFrom(msg.sender, address(this), yDaiRequired));
        _mint(msg.sender, tokensMinted);
        emit Liquidity(maturity, msg.sender, msg.sender, -toInt256(daiOffered), -toInt256(yDaiRequired), toInt256(tokensMinted));

        return tokensMinted;
    }





    function burn(uint256 tokensBurned)
        external
        returns (uint256, uint256)
    {
        uint256 supply = totalSupply();
        uint256 daiReserves = dai.balanceOf(address(this));

        uint256 yDaiReserves = yDai.balanceOf(address(this));
        uint256 daiReturned = tokensBurned.mul(daiReserves).div(supply);
        uint256 yDaiReturned = tokensBurned.mul(yDaiReserves).div(supply);

        _burn(msg.sender, tokensBurned);
        dai.transfer(msg.sender, daiReturned);
        yDai.transfer(msg.sender, yDaiReturned);
        emit Liquidity(maturity, msg.sender, msg.sender, toInt256(daiReturned), toInt256(yDaiReturned), -toInt256(tokensBurned));

        return (daiReturned, yDaiReturned);
    }







    function sellDai(address from, address to, uint128 daiIn)
        external override
        onlyHolderOrDelegate(from, "Pool: Only Holder Or Delegate")
        returns(uint128)
    {
        uint128 yDaiOut = sellDaiPreview(daiIn);

        dai.transferFrom(from, address(this), daiIn);
        yDai.transfer(to, yDaiOut);
        emit Trade(maturity, from, to, -toInt256(daiIn), toInt256(yDaiOut));

        return yDaiOut;
    }




    function sellDaiPreview(uint128 daiIn)
        public view override
        beforeMaturity
        returns(uint128)
    {
        uint128 daiReserves = getDaiReserves();
        uint128 yDaiReserves = getYDaiReserves();

        uint128 yDaiOut = YieldMath.yDaiOutForDaiIn(
            daiReserves,
            yDaiReserves,
            daiIn,
            toUint128(maturity - now),
            k,
            g
        );

        require(
            sub(yDaiReserves, yDaiOut) >= add(daiReserves, daiIn),
            "Pool: yDai reserves too low"
        );

        return yDaiOut;
    }







    function buyDai(address from, address to, uint128 daiOut)
        external override
        onlyHolderOrDelegate(from, "Pool: Only Holder Or Delegate")
        returns(uint128)
    {
        uint128 yDaiIn = buyDaiPreview(daiOut);

        yDai.transferFrom(from, address(this), yDaiIn);
        dai.transfer(to, daiOut);
        emit Trade(maturity, from, to, toInt256(daiOut), -toInt256(yDaiIn));

        return yDaiIn;
    }




    function buyDaiPreview(uint128 daiOut)
        public view override
        beforeMaturity
        returns(uint128)
    {
        return YieldMath.yDaiInForDaiOut(
            getDaiReserves(),
            getYDaiReserves(),
            daiOut,
            toUint128(maturity - now),
            k,
            g
        );
    }







    function sellYDai(address from, address to, uint128 yDaiIn)
        external override
        onlyHolderOrDelegate(from, "Pool: Only Holder Or Delegate")
        returns(uint128)
    {
        uint128 daiOut = sellYDaiPreview(yDaiIn);

        yDai.transferFrom(from, address(this), yDaiIn);
        dai.transfer(to, daiOut);
        emit Trade(maturity, from, to, toInt256(daiOut), -toInt256(yDaiIn));

        return daiOut;
    }




    function sellYDaiPreview(uint128 yDaiIn)
        public view override
        beforeMaturity
        returns(uint128)
    {
        return YieldMath.daiOutForYDaiIn(
            getDaiReserves(),
            getYDaiReserves(),
            yDaiIn,
            toUint128(maturity - now),
            k,
            g
        );
    }







    function buyYDai(address from, address to, uint128 yDaiOut)
        external override
        onlyHolderOrDelegate(from, "Pool: Only Holder Or Delegate")
        returns(uint128)
    {
        uint128 daiIn = buyYDaiPreview(yDaiOut);

        dai.transferFrom(from, address(this), daiIn);
        yDai.transfer(to, yDaiOut);
        emit Trade(maturity, from, to, -toInt256(daiIn), toInt256(yDaiOut));

        return daiIn;
    }





    function buyYDaiPreview(uint128 yDaiOut)
        public view override
        beforeMaturity
        returns(uint128)
    {
        uint128 daiReserves = getDaiReserves();
        uint128 yDaiReserves = getYDaiReserves();

        uint128 daiIn = YieldMath.daiInForYDaiOut(
            daiReserves,
            yDaiReserves,
            yDaiOut,
            toUint128(maturity - now),
            k,
            g
        );

        require(
            sub(yDaiReserves, yDaiOut) >= add(daiReserves, daiIn),
            "Pool: yDai reserves too low"
        );

        return daiIn;
    }


    function getYDaiReserves()
        public view
        returns(uint128)
    {
        return toUint128(yDai.balanceOf(address(this)) + totalSupply());
    }


    function getDaiReserves()
        public view
        returns(uint128)
    {
        return toUint128(dai.balanceOf(address(this)));
    }
}
