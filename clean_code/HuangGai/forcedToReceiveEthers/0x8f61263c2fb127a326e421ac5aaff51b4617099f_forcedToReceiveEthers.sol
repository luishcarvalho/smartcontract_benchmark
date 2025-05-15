














pragma solidity ^0.5.16;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "!addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "!subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "!multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "!division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint amount) external;








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {











    function isContract(address account) internal view returns (bool) {







        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }







    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }



















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function callOptionalReturn(IERC20 token, bytes memory data) private {








        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract AlphaSwapV0 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct MARKET_EPOCH {
        uint timestamp;
        uint accuPrice;
        uint32 pairTimestamp;
        mapping (address => mapping(uint => mapping (address => uint))) stake;
        mapping (address => mapping(uint => uint)) totalStake;
    }

    mapping (address => mapping(uint => MARKET_EPOCH)) public market;
    mapping (address => uint) public marketEpoch;
    mapping (address => uint) public marketEpochPeriod;

    mapping (address => uint) public marketWhitelist;
    mapping (address => uint) public tokenWhitelist;

    event STAKE(address indexed user, address indexed market, uint opinion, address indexed token, uint amt);
    event SYNC(address indexed market, uint epoch);
    event PAYOFF(address indexed user, address indexed market, uint opinion, address indexed token, uint amt);

    event MARKET_PERIOD(address indexed market, uint period);
    event MARKET_WHITELIST(address indexed market, uint status);
    event TOKEN_WHITELIST(address indexed token, uint status);
    event FEE_CHANGE(address indexed market, address indexed token, uint BP);



    address public govAddr;
    address public devAddr;

    mapping (address => mapping(address => uint)) public devFeeBP;
    mapping (address => uint) public devFeeAmt;

    constructor () public {
        govAddr = msg.sender;
        devAddr = msg.sender;
    }

    modifier govOnly() {
    	require(msg.sender == govAddr, "!gov");
    	_;
    }
    function govTransferAddr(address newAddr) external govOnly {
    	require(newAddr != address(0), "!addr");
    	govAddr = newAddr;
    }
    function govSetEpochPeriod(address xMarket, uint newPeriod) external govOnly {
        require (newPeriod > 0, "!period");
        marketEpochPeriod[xMarket] = newPeriod;
        emit MARKET_PERIOD(xMarket, newPeriod);
    }
    function govMarketWhitelist(address xMarket, uint status) external govOnly {
        require (status <= 1, "!status");
        marketWhitelist[xMarket] = status;
        emit MARKET_WHITELIST(xMarket, status);
    }
    function govTokenWhitelist(address xToken, uint status) external govOnly {
        require (status <= 1, "!status");
        tokenWhitelist[xToken] = status;
        emit TOKEN_WHITELIST(xToken, status);
    }
    function govSetDevFee(address xMarket, address xToken, uint newBP) external govOnly {
        require (newBP <= 10);
    	devFeeBP[xMarket][xToken] = newBP;
    	emit FEE_CHANGE(xMarket, xToken, newBP);
    }

    modifier devOnly() {
    	require(msg.sender == devAddr, "!dev");
    	_;
    }
    function devTransferAddr(address newAddr) external devOnly {
    	require(newAddr != address(0), "!addr");
    	devAddr = newAddr;
    }
    function devWithdrawFee(address xToken, uint256 amt) external devOnly {
        require (amt <= devFeeAmt[xToken]);
        devFeeAmt[xToken] = devFeeAmt[xToken].sub(amt);
        IERC20(xToken).safeTransfer(devAddr, amt);
    }



    function readStake(address user, address xMarket, uint xEpoch, uint xOpinion, address xToken) external view returns (uint) {
        return market[xMarket][xEpoch].stake[xToken][xOpinion][user];
    }
    function readTotalStake(address xMarket, uint xEpoch, uint xOpinion, address xToken) external view returns (uint) {
        return market[xMarket][xEpoch].totalStake[xToken][xOpinion];
    }



    function Stake(address xMarket, uint xEpoch, uint xOpinion, address xToken, uint xAmt) external {
        require (xAmt > 0, "!amt");
        require (xOpinion <= 1, "!opinion");
        require (marketWhitelist[xMarket] > 0, "!market");
        require (tokenWhitelist[xToken] > 0, "!token");

        uint thisEpoch = marketEpoch[xMarket];
        require (xEpoch == thisEpoch, "!epoch");
        MARKET_EPOCH storage m = market[xMarket][thisEpoch];

        if (address(this).balance == 0) {
            m.timestamp = block.timestamp;

            IUniswapV2Pair pair = IUniswapV2Pair(xMarket);
            uint112 reserve0;
            uint112 reserve1;
            uint32 pairTimestamp;
            (reserve0, reserve1, pairTimestamp) = pair.getReserves();

            m.pairTimestamp = pairTimestamp;
            m.accuPrice = pair.price0CumulativeLast();
        }

        address user = msg.sender;
        IERC20(xToken).safeTransferFrom(user, address(this), xAmt);

        m.stake[xToken][xOpinion][user] = m.stake[xToken][xOpinion][user].add(xAmt);
        m.totalStake[xToken][xOpinion] = m.totalStake[xToken][xOpinion].add(xAmt);

        emit STAKE(user, xMarket, xOpinion, xToken, xAmt);
    }

    function _Sync(address xMarket) private {
        uint epochPeriod = marketEpochPeriod[xMarket];
        uint thisPeriod = (block.timestamp).div(epochPeriod);

        MARKET_EPOCH memory mmm = market[xMarket][marketEpoch[xMarket]];
        uint marketPeriod = (mmm.timestamp).div(epochPeriod);

        if (thisPeriod <= marketPeriod)
            return;

        IUniswapV2Pair pair = IUniswapV2Pair(xMarket);
        uint112 reserve0;
        uint112 reserve1;
        uint32 pairTimestamp;
        (reserve0, reserve1, pairTimestamp) = pair.getReserves();
        if (pairTimestamp <= mmm.pairTimestamp)
            return;

        MARKET_EPOCH memory m;
        m.timestamp = block.timestamp;
        m.pairTimestamp = pairTimestamp;
        m.accuPrice = pair.price0CumulativeLast();

        uint newEpoch = marketEpoch[xMarket].add(1);
        marketEpoch[xMarket] = newEpoch;
        market[xMarket][newEpoch] = m;

        emit SYNC(xMarket, newEpoch);
    }

    function Sync(address xMarket) external {
        uint epochPeriod = marketEpochPeriod[xMarket];
        uint thisPeriod = (block.timestamp).div(epochPeriod);

        MARKET_EPOCH memory mmm = market[xMarket][marketEpoch[xMarket]];
        uint marketPeriod = (mmm.timestamp).div(epochPeriod);
        require (marketPeriod > 0, "!marketPeriod");
        require (thisPeriod > marketPeriod, "!thisPeriod");

        IUniswapV2Pair pair = IUniswapV2Pair(xMarket);
        uint112 reserve0;
        uint112 reserve1;
        uint32 pairTimestamp;
        (reserve0, reserve1, pairTimestamp) = pair.getReserves();
        require (pairTimestamp > mmm.pairTimestamp, "!no-trade");

        MARKET_EPOCH memory m;
        m.timestamp = block.timestamp;
        m.pairTimestamp = pairTimestamp;
        m.accuPrice = pair.price0CumulativeLast();

        uint newEpoch = marketEpoch[xMarket].add(1);
        marketEpoch[xMarket] = newEpoch;
        market[xMarket][newEpoch] = m;

        emit SYNC(xMarket, newEpoch);
    }

    function Payoff(address xMarket, uint xEpoch, uint xOpinion, address xToken) external {
        require (xOpinion <= 1, "!opinion");

        uint thisEpoch = marketEpoch[xMarket];
        require (thisEpoch >= 1, "!marketEpoch");
        _Sync(xMarket);

        thisEpoch = marketEpoch[xMarket];
        require (xEpoch <= thisEpoch.sub(2), "!epoch");

        address user = msg.sender;
        uint amtOut = 0;

        MARKET_EPOCH storage m0 = market[xMarket][xEpoch];
        {
            uint224 p01 = 0;
            uint224 p12 = 0;
            {
                MARKET_EPOCH memory m1 = market[xMarket][xEpoch.add(1)];
                MARKET_EPOCH memory m2 = market[xMarket][xEpoch.add(2)];


                uint32 t01 = m1.pairTimestamp - m0.pairTimestamp;
                if (t01 > 0)
                    p01 = uint224((m1.accuPrice - m0.accuPrice) / t01);

                uint32 t12 = m2.pairTimestamp - m1.pairTimestamp;
                if (t12 > 0)
                    p12 = uint224((m2.accuPrice - m1.accuPrice) / t12);
            }

            uint userStake = m0.stake[xToken][xOpinion][user];
            if ((p01 == p12) || (p01 == 0) || (p12 == 0)) {
                amtOut = userStake;
            }
            else {
                uint sameOpinionStake = m0.totalStake[xToken][xOpinion];
                uint allStake = sameOpinionStake.add(m0.totalStake[xToken][1-xOpinion]);
                if (sameOpinionStake == allStake) {
                    amtOut = userStake;
                }
                else {
                    if (
                        ((p12 > p01) && (xOpinion == 1))
                        ||
                        ((p12 < p01) && (xOpinion == 0))
                    )
                    {
                        amtOut = userStake.mul(allStake).div(sameOpinionStake);
                    }
                }
            }
        }

        require (amtOut > 0, "!zeroAmt");

        uint devFee = amtOut.mul(devFeeBP[xMarket][xToken]).div(10000);
        devFeeAmt[xToken] = devFeeAmt[xToken].add(devFee);

        amtOut = amtOut.sub(devFee);

        m0.stake[xToken][xOpinion][user] = 0;
        IERC20(xToken).safeTransfer(user, amtOut);

        emit PAYOFF(user, xMarket, xOpinion, xToken, amtOut);
    }
}
