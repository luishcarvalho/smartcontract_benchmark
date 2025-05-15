
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "./SHEESHA.sol";
import "./ISHEESHAGlobals.sol";

interface ISHEESHAVaultLP {
    function depositFor(
        address,
        uint256,
        uint256
    ) external;
}

contract LGE is SHEESHA {
    using SafeMath for uint256;
    address public SHEESHAxWETHPair;
    IUniswapV2Router02 public uniswapRouterV2;
    IUniswapV2Factory public uniswapFactory;
    uint256 public totalLPTokensMinted;
    uint256 public totalETHContributed;
    uint256 public LPperETHUnit;
    bool public LPGenerationCompleted;
    uint256 public contractStartTimestamp;
    uint256 public constant lgeSupply = 15000e18;

    uint256 public userCount;
    ISHEESHAGlobals public sheeshaGlobals;
    uint256 public stakeCount;

    mapping(address => uint256) public ethContributed;
    mapping(address => bool) public claimed;
    mapping(uint256 => address) public userList;

    event LiquidityAddition(address indexed dst, uint256 value);
    event LPTokenClaimed(address dst, uint256 value);

    constructor(
        address router,
        address factory,
        ISHEESHAGlobals _sheeshaGlobals,
        address _devAddress,
        address _marketingAddress,
        address _teamAddress,
        address _reserveAddress
    ) SHEESHA(_devAddress, _marketingAddress, _teamAddress, _reserveAddress) {
        uniswapRouterV2 = IUniswapV2Router02(
            router != address(0)
                ? router
                : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapFactory = IUniswapV2Factory(
            factory != address(0)
                ? factory
                : 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        );
        createUniswapPairMainnet();
        contractStartTimestamp = block.timestamp;
        sheeshaGlobals = _sheeshaGlobals;
    }

    function getSecondsLeftInLiquidityGenerationEvent()
        public
        view
        returns (uint256)
    {
        require(liquidityGenerationOngoing(), "Event over");
        return contractStartTimestamp.add(14 days).sub(block.timestamp);
    }

    function liquidityGenerationOngoing() public view returns (bool) {

        return contractStartTimestamp.add(14 days) > block.timestamp;
    }

    function createUniswapPairMainnet() public returns (address) {
        require(SHEESHAxWETHPair == address(0), "Token: pool already created");
        SHEESHAxWETHPair = uniswapFactory.createPair(
            address(uniswapRouterV2.WETH()),
            address(this)
        );
        return SHEESHAxWETHPair;
    }









    function addLiquidityToUniswapSHEESHAxWETHPair() public {
        require(
            liquidityGenerationOngoing() == false,
            "Liquidity generation ongoing"
        );
        require(
            LPGenerationCompleted == false,
            "Liquidity generation already finished"
        );
        totalETHContributed = address(this).balance;
        IUniswapV2Pair pair = IUniswapV2Pair(SHEESHAxWETHPair);

        address WETH = uniswapRouterV2.WETH();
        IWETH(WETH).deposit{value: totalETHContributed}();
        require(address(this).balance == 0, "Transfer Failed");
        IWETH(WETH).transfer(address(pair), totalETHContributed);
        transfer(address(pair), lgeSupply);
        pair.mint(address(this));
        totalLPTokensMinted = pair.balanceOf(address(this));
        require(totalLPTokensMinted != 0, "LP creation failed");
        LPperETHUnit = totalLPTokensMinted.mul(1e18).div(totalETHContributed);
        require(LPperETHUnit != 0, "LP creation failed");
        LPGenerationCompleted = true;
    }






    function addLiquidity() public payable {
        require(
            liquidityGenerationOngoing() == true,
            "Liquidity Generation Event over"
        );
        ethContributed[msg.sender] += msg.value;
        totalETHContributed = totalETHContributed.add(msg.value);
        userList[userCount] = msg.sender;
        userCount++;
        emit LiquidityAddition(msg.sender, msg.value);
    }





    function _claimLPTokens() internal returns (uint256 amountLPToTransfer) {
        amountLPToTransfer = ethContributed[msg.sender].mul(LPperETHUnit).div(
            1e18
        );
        ethContributed[msg.sender] = 0;
        claimed[msg.sender] = true;
    }


    function claimAndStakeLP(uint256 _pid) public {
        require(
            LPGenerationCompleted == true,
            "LGE : Liquidity generation not finished yet"
        );
        require(ethContributed[msg.sender] > 0, "Nothing to claim, move along");
        require(claimed[msg.sender] == false, "LGE : Already claimed");
        address vault = sheeshaGlobals.SHEESHAVaultLPAddress();
        IUniswapV2Pair(SHEESHAxWETHPair).approve(vault, uint256(-1));
        ISHEESHAVaultLP(vault).depositFor(msg.sender, _pid, _claimLPTokens());
    }

    function getLPTokens(address _who)
        public
        view
        returns (uint256 amountLPToTransfer)
    {
        return ethContributed[_who].mul(LPperETHUnit).div(1e18);
    }




    function emergencyDrain24hAfterLiquidityGenerationEventIsDone()
        public
        payable
        onlyOwner
    {
        require(
            contractStartTimestamp.add(15 days) < block.timestamp,
            "Liquidity generation grace period still ongoing"
        );
        msg.sender.transfer(address(this).balance);
        _transfer(address(this), msg.sender, balanceOf(address(this)));
    }
}
