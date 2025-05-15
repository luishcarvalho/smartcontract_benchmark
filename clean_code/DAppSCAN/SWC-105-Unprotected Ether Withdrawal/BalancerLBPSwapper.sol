
pragma solidity ^0.8.0;

import "./manager/WeightedBalancerPoolManager.sol";
import "./IVault.sol";
import "../../utils/Timed.sol";
import "../../refs/OracleRef.sol";
import "../IPCVSwapper.sol";




contract BalancerLBPSwapper is IPCVSwapper, OracleRef, Timed, WeightedBalancerPoolManager {
    using Decimal for Decimal.D256;


    event MinTokenSpentUpdate(uint256 oldMinTokenSpentBalance, uint256 newMinTokenSpentBalance);



    IWeightedPool public pool;


    IVault public vault;


    bytes32 public pid;


    uint256 private constant ONE_PERCENT = 0.01e18;
    uint256 private constant NINETY_NINE_PERCENT = 0.99e18;


    IAsset[] private assets;
    uint256[] private initialWeights;
    uint256[] private endWeights;




    address public override tokenSpent;


    address public override tokenReceived;


    address public override tokenReceivingAddress;


    uint256 public minTokenSpentBalance;

    struct OracleData {
        address _oracle;
        address _backupOracle;

        bool _invertOraclePrice;

        int256 _decimalsNormalizer;
    }











    constructor(
        address _core,
        OracleData memory oracleData,
        uint256 _frequency,
        address _tokenSpent,
        address _tokenReceived,
        address _tokenReceivingAddress,
        uint256 _minTokenSpentBalance
    )
        OracleRef(
            _core,
            oracleData._oracle,
            oracleData._backupOracle,
            oracleData._decimalsNormalizer,
            oracleData._invertOraclePrice
        )
        Timed(_frequency)
        WeightedBalancerPoolManager()
    {
        _initTimed();


        tokenSpent = _tokenSpent;
        tokenReceived = _tokenReceived;

        _setReceivingAddress(_tokenReceivingAddress);
        _setMinTokenSpent(_minTokenSpentBalance);
    }









    function init(IWeightedPool _pool) external {
        require(address(pool) == address(0), "BalancerLBPSwapper: initialized");

        pool = _pool;
        IVault _vault = _pool.getVault();

        vault = _vault;


        require(_pool.getOwner() == address(this), "BalancerLBPSwapper: contract not pool owner");


        bytes32 _pid = _pool.getPoolId();
        pid = _pid;
        (IERC20[] memory tokens,,) = _vault.getPoolTokens(_pid);
        require(tokens.length == 2, "BalancerLBPSwapper: pool does not have 2 tokens");
        require(
            tokenSpent == address(tokens[0]) ||
            tokenSpent == address(tokens[1]),
            "BalancerLBPSwapper: tokenSpent not in pool"
        );
        require(
            tokenReceived == address(tokens[0]) ||
            tokenReceived == address(tokens[1]),
            "BalancerLBPSwapper: tokenReceived not in pool"
        );


        assets = new IAsset[](2);
        assets[0] = IAsset(address(tokens[0]));
        assets[1] = IAsset(address(tokens[1]));

        bool tokenSpentAtIndex0 = tokenSpent == address(tokens[0]);
        initialWeights = new uint[](2);
        endWeights = new uint[](2);

        if (tokenSpentAtIndex0) {
            initialWeights[0] = NINETY_NINE_PERCENT;
            initialWeights[1] = ONE_PERCENT;

            endWeights[0] = ONE_PERCENT;
            endWeights[1] = NINETY_NINE_PERCENT;
        }  else {
            initialWeights[0] = ONE_PERCENT;
            initialWeights[1] = NINETY_NINE_PERCENT;

            endWeights[0] = NINETY_NINE_PERCENT;
            endWeights[1] = ONE_PERCENT;
        }


        _pool.approve(address(_vault), type(uint256).max);
        IERC20(tokenSpent).approve(address(_vault), type(uint256).max);
        IERC20(tokenReceived).approve(address(_vault), type(uint256).max);
    }











    function swap() external override afterTime whenNotPaused {
        (
            uint256 spentReserves,
            uint256 receivedReserves,
            uint256 lastChangeBlock
        ) = getReserves();


        require(lastChangeBlock < block.number, "BalancerLBPSwapper: pool changed this block");

        (
            uint256 bptTotal,
            uint256 bptBalance,
            uint256 spentBalance,
            uint256 receivedBalance
        ) = getPoolBalances(spentReserves, receivedReserves);


        if (bptTotal == 0) {
            _initializePool();
            return;
        }
        require(swapEndTime() < block.timestamp, "BalancerLBPSwapper: weight update in progress");


        if (bptBalance != 0) {
            IVault.ExitPoolRequest memory exitRequest;


            bytes memory userData = abi.encode(IWeightedPool.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, bptBalance);

            exitRequest.assets = assets;
            exitRequest.minAmountsOut = new uint256[](2);
            exitRequest.userData = userData;
            exitRequest.toInternalBalance = false;

            vault.exitPool(
                pid,
                address(this),
                payable(address(this)),
                exitRequest
            );
        }


        _updateWeightsGradually(
            pool,
            block.timestamp,
            block.timestamp,
            initialWeights
        );


        uint256 spentTokenBalance = IERC20(tokenSpent).balanceOf(address(this));
        if (spentTokenBalance > minTokenSpentBalance) {


            uint256[] memory amountsIn = _getTokensIn(spentTokenBalance);
            bytes memory userData = abi.encode(IWeightedPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, 0);

            IVault.JoinPoolRequest memory joinRequest;
            joinRequest.assets = assets;
            joinRequest.maxAmountsIn = amountsIn;
            joinRequest.userData = userData;
            joinRequest.fromInternalBalance = false;

            vault.joinPool(
                pid,
                address(this),
                payable(address(this)),
                joinRequest
            );


            _updateWeightsGradually(
                pool,
                block.timestamp,
                block.timestamp + duration,
                endWeights
            );
            _initTimed();
        }

        IERC20(tokenReceived).transfer(tokenReceivingAddress, IERC20(tokenReceived).balanceOf(address(this)));
    }


    function swapEndTime() public view returns(uint256 endTime) {
        (,endTime,) = pool.getGradualWeightUpdateParams();
    }


    function getReserves() public view returns(uint256 spentReserves, uint256 receivedReserves, uint256 lastChangeBlock) {
        (IERC20[] memory tokens, uint256[] memory balances, uint256 _lastChangeBlock ) = vault.getPoolTokens(pid);
        if (address(tokens[0]) == tokenSpent) {
            return (balances[0], balances[1], _lastChangeBlock);
        }
        return (balances[1], balances[0], _lastChangeBlock);
    }


    function getPoolBalances(uint256 spentReserves, uint256 receivedReserves) public view returns (
        uint256 bptTotal,
        uint256 bptBalance,
        uint256 spentBalance,
        uint256 receivedBalance
    ) {
        bptTotal = pool.totalSupply();
        bptBalance = pool.balanceOf(address(this));

        if (bptTotal != 0) {
            spentBalance = spentReserves * bptBalance / bptTotal;
            receivedBalance = receivedReserves * bptBalance / bptTotal;
        }
    }



    function setSwapFrequency(uint256 _frequency) external onlyGovernorOrAdmin {
       _setDuration(_frequency);
    }



    function setMinTokenSpent(uint256 newMinTokenSpentBalance) external onlyGovernorOrAdmin {
       _setMinTokenSpent(newMinTokenSpentBalance);
    }



    function setReceivingAddress(address newTokenReceivingAddress) external override onlyGovernorOrAdmin {
        _setReceivingAddress(newTokenReceivingAddress);
    }

    function _setReceivingAddress(address newTokenReceivingAddress) internal {
      require(newTokenReceivingAddress != address(0), "BalancerLBPSwapper: zero address");
      address oldTokenReceivingAddress = tokenReceivingAddress;
      tokenReceivingAddress = newTokenReceivingAddress;
      emit UpdateReceivingAddress(oldTokenReceivingAddress, newTokenReceivingAddress);
    }

    function _initializePool() internal {

        uint256 spentTokenBalance = IERC20(tokenSpent).balanceOf(address(this));
        require(spentTokenBalance >= minTokenSpentBalance, "BalancerLBPSwapper: not enough tokenSpent to init");

        uint256[] memory amountsIn = _getTokensIn(spentTokenBalance);
        bytes memory userData = abi.encode(IWeightedPool.JoinKind.INIT, amountsIn);

        IVault.JoinPoolRequest memory joinRequest;
        joinRequest.assets = assets;
        joinRequest.maxAmountsIn = amountsIn;
        joinRequest.userData = userData;
        joinRequest.fromInternalBalance = false;

        vault.joinPool(
            pid,
            address(this),
            payable(address(this)),
            joinRequest
        );


        _updateWeightsGradually(
            pool,
            block.timestamp,
            block.timestamp + duration,
            endWeights
        );
        _initTimed();
    }

    function _getTokensIn(uint256 spentTokenBalance) internal view returns(uint256[] memory amountsIn) {
        amountsIn = new uint256[](2);

        uint256 receivedTokenBalance = readOracle().mul(spentTokenBalance).mul(ONE_PERCENT).div(NINETY_NINE_PERCENT).asUint256();

        if (address(assets[0]) == tokenSpent) {
            amountsIn[0] = spentTokenBalance;
            amountsIn[1] = receivedTokenBalance;
        } else {
            amountsIn[0] = receivedTokenBalance;
            amountsIn[1] = spentTokenBalance;
        }
    }

    function _setMinTokenSpent(uint256 newMinTokenSpentBalance) internal {
      uint256 oldMinTokenSpentBalance = minTokenSpentBalance;
      minTokenSpentBalance = newMinTokenSpentBalance;
      emit MinTokenSpentUpdate(oldMinTokenSpentBalance, newMinTokenSpentBalance);
    }
}
