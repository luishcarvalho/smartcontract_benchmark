
pragma solidity 0.8.4;

import "hardhat/console.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IIdleCDOStrategy.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/IIdleCDOTrancheRewards.sol";

import "./GuardedLaunchUpgradable.sol";
import "./IdleCDOTranche.sol";
import "./IdleCDOStorage.sol";




contract IdleCDO is Initializable, PausableUpgradeable, GuardedLaunchUpgradable, IdleCDOStorage {
  using SafeERC20Upgradeable for IERC20Detailed;
















  function initialize(
    uint256 _limit, address _guardedToken, address _governanceFund, address _owner,
    address _rebalancer,
    address _strategy,
    uint256 _trancheAPRSplitRatio,
    uint256 _trancheIdealWeightRatio,
    address[] memory _incentiveTokens
  ) public initializer {

    PausableUpgradeable.__Pausable_init();
    GuardedLaunchUpgradable.__GuardedLaunch_init(_limit, _governanceFund, _owner);

    AATranche = address(new IdleCDOTranche("Idle CDO AA Tranche", "IDLE_CDO_AA"));
    BBTranche = address(new IdleCDOTranche("Idle CDO BB Tranche", "IDLE_CDO_BB"));

    token = _guardedToken;
    strategy = _strategy;
    strategyToken = IIdleCDOStrategy(_strategy).strategyToken();
    rebalancer = _rebalancer;
    trancheAPRSplitRatio = _trancheAPRSplitRatio;
    trancheIdealWeightRatio = _trancheIdealWeightRatio;
    idealRange = 10000;
    uint256 _oneToken = 10**(IERC20Detailed(_guardedToken).decimals());
    oneToken = _oneToken;
    uniswapRouterV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    incentiveTokens = _incentiveTokens;
    priceAA = _oneToken;
    priceBB = _oneToken;
    lastAAPrice = _oneToken;
    lastBBPrice = _oneToken;
    unlentPerc = 2000;

    allowAAWithdraw = true;
    allowBBWithdraw = true;
    revertIfTooLow = true;


    IERC20Detailed(_guardedToken).safeIncreaseAllowance(_strategy, type(uint256).max);
    IERC20Detailed(strategyToken).safeIncreaseAllowance(_strategy, type(uint256).max);

    lastStrategyPrice = strategyPrice();

    fee = 10000;
    feeReceiver = address(0xBecC659Bfc6EDcA552fa1A67451cC6b38a0108E4);
    guardian = _owner;
  }









  function depositAA(uint256 _amount) external whenNotPaused returns (uint256) {
    return _deposit(_amount, AATranche);
  }





  function depositBB(uint256 _amount) external whenNotPaused returns (uint256) {
    return _deposit(_amount, BBTranche);
  }




  function withdrawAA(uint256 _amount) external nonReentrant returns (uint256) {
    require(!paused() || allowAAWithdraw, 'IDLE:AA_!ALLOWED');
    return _withdraw(_amount, AATranche);
  }




  function withdrawBB(uint256 _amount) external nonReentrant returns (uint256) {
    require(!paused() || allowBBWithdraw, 'IDLE:BB_!ALLOWED');
    return _withdraw(_amount, BBTranche);
  }







  function tranchePrice(address _tranche) external view returns (uint256) {
    return _tranchePrice(_tranche);
  }



  function lastTranchePrice(address _tranche) external view returns (uint256) {
    return _lastTranchePrice(_tranche);
  }



  function getContractValue() public override view returns (uint256) {
    address _strategyToken = strategyToken;

    uint256 strategyTokenDecimals = IERC20Detailed(_strategyToken).decimals();
    return (_contractTokenBalance(_strategyToken) * strategyPrice() / (10**(strategyTokenDecimals))) + _contractTokenBalance(token);
  }



  function getIdealApr(address _tranche) external view returns (uint256) {
    return _getApr(_tranche, trancheIdealWeightRatio);
  }



  function getApr(address _tranche) external view returns (uint256) {
    return _getApr(_tranche, getCurrentAARatio());
  }


  function strategyAPR() public view returns (uint256) {
    return IIdleCDOStrategy(strategy).getApr();
  }


  function strategyPrice() public view returns (uint256) {
    return IIdleCDOStrategy(strategy).price();
  }


  function getRewards() public view returns (address[] memory) {
    return IIdleCDOStrategy(strategy).getRewardTokens();
  }


  function getCurrentAARatio() public view returns (uint256) {
    uint256 AABal = virtualBalance(AATranche);
    uint256 contractVal = AABal + virtualBalance(BBTranche);
    if (contractVal == 0) {
      return 0;
    }

    return AABal * FULL_ALLOC / contractVal;
  }





  function virtualPrice(address _tranche) public view returns (uint256) {
    uint256 nav = getContractValue();
    uint256 lastNAV = _lastNAV();
    uint256 trancheSupply = IdleCDOTranche(_tranche).totalSupply();
    uint256 _trancheAPRSplitRatio = trancheAPRSplitRatio;

    if (lastNAV == 0 || trancheSupply == 0) {
      return oneToken;
    }

    if (nav <= lastNAV) {
      return _tranchePrice(_tranche);
    }

    uint256 gain = nav - lastNAV;

    gain -= gain * fee / FULL_ALLOC;

    uint256 trancheNAV;
    if (_tranche == AATranche) {

      trancheNAV = lastNAVAA + (gain * _trancheAPRSplitRatio / FULL_ALLOC);
    } else {

      trancheNAV = lastNAVBB + (gain * (FULL_ALLOC - _trancheAPRSplitRatio) / FULL_ALLOC);
    }

    return trancheNAV * ONE_TRANCHE_TOKEN / trancheSupply;
  }



  function virtualBalance(address _tranche) public view returns (uint256) {
    return IdleCDOTranche(_tranche).totalSupply() * virtualPrice(_tranche) / ONE_TRANCHE_TOKEN;
  }


  function getIncentiveTokens() public view returns (address[] memory) {
    return incentiveTokens;
  }












  function _deposit(uint256 _amount, address _tranche) internal returns (uint256 _minted) {

    _guarded(_amount);

    _updateCallerBlock();

    _checkDefault();



    _updatePrices();


    _minted = _mintShares(_amount, msg.sender, _tranche);

    IERC20Detailed(token).safeTransferFrom(msg.sender, address(this), _amount);
  }


  function _updatePrices() internal {
    uint256 _oneToken = oneToken;

    uint256 lastNAV = _lastNAV();
    if (lastNAV == 0) {
      return;
    }

    uint256 nav = getContractValue();
    if (nav <= lastNAV) {
      return;
    }

    uint256 gain = nav - lastNAV;

    uint256 performanceFee = gain * fee / FULL_ALLOC;
    gain -= performanceFee;

    unclaimedFees += performanceFee;

    uint256 AATotSupply = IdleCDOTranche(AATranche).totalSupply();
    uint256 BBTotSupply = IdleCDOTranche(BBTranche).totalSupply();
    uint256 AAGain;
    uint256 BBGain;
    if (BBTotSupply == 0) {

      AAGain = gain;
    } else if (AATotSupply == 0) {

      BBGain = gain;
    } else {

      AAGain = gain * trancheAPRSplitRatio / FULL_ALLOC;
      BBGain = gain - AAGain;
    }

    lastNAVAA += AAGain;

    lastNAVBB += BBGain;

    priceAA = AATotSupply > 0 ? lastNAVAA * ONE_TRANCHE_TOKEN / AATotSupply : _oneToken;
    priceBB = BBTotSupply > 0 ? lastNAVBB * ONE_TRANCHE_TOKEN / BBTotSupply : _oneToken;
  }





  function _mintShares(uint256 _amount, address _to, address _tranche) internal returns (uint256 _minted) {

    _minted = _amount * ONE_TRANCHE_TOKEN / _tranchePrice(_tranche);
    IdleCDOTranche(_tranche).mint(_to, _minted);

    if (_tranche == AATranche) {
      lastNAVAA += _amount;
    } else {
      lastNAVBB += _amount;
    }
  }




  function _depositFees(uint256 _amount) internal returns (uint256 _currAARatio) {
    if (_amount > 0) {
      _currAARatio = getCurrentAARatio();
      _mintShares(_amount, feeReceiver,

        _currAARatio >= trancheIdealWeightRatio ? BBTranche : AATranche
      );

      unclaimedFees = 0;
    }
  }


  function _updateLastTranchePrices() internal {
    lastAAPrice = priceAA;
    lastBBPrice = priceBB;
  }








  function _withdraw(uint256 _amount, address _tranche) internal returns (uint256 toRedeem) {

    _checkSameTx();

    _checkDefault();

    _updatePrices();

    if (_amount == 0) {
      _amount = IERC20Detailed(_tranche).balanceOf(msg.sender);
    }
    require(_amount > 0, 'IDLE:IS_0');
    address _token = token;

    uint256 balanceUnderlying = _contractTokenBalance(_token);



    toRedeem = _amount * _lastTranchePrice(_tranche) / ONE_TRANCHE_TOKEN;

    if (toRedeem > balanceUnderlying) {


      toRedeem = _liquidate(toRedeem - balanceUnderlying, revertIfTooLow);
    }

    IdleCDOTranche(_tranche).burn(msg.sender, _amount);

    IERC20Detailed(_token).safeTransfer(msg.sender, toRedeem);


    if (_tranche == AATranche) {
      lastNAVAA -= toRedeem;
    } else {
      lastNAVBB -= toRedeem;
    }
  }


  function _checkDefault() internal {
    uint256 currPrice = strategyPrice();
    if (!skipDefaultCheck) {
      require(lastStrategyPrice <= currPrice, "IDLE:DEFAULT_WAIT_SHUTDOWN");
    }
    lastStrategyPrice = currPrice;
  }





  function _liquidate(uint256 _amount, bool _revertIfNeeded) internal returns (uint256 _redeemedTokens) {
    _redeemedTokens = IIdleCDOStrategy(strategy).redeemUnderlying(_amount);
    if (_revertIfNeeded) {

      require(_redeemedTokens + 100 >= _amount, 'IDLE:TOO_LOW');
    }
  }


  function _updateIncentives(uint256 currAARatio) internal {

    uint256 _trancheIdealWeightRatio = trancheIdealWeightRatio;
    uint256 _trancheAPRSplitRatio = trancheAPRSplitRatio;
    uint256 _idealRange = idealRange;
    address _BBStaking = BBStaking;
    address _AAStaking = AAStaking;


    if (_BBStaking != address(0) && (currAARatio > (_trancheIdealWeightRatio + _idealRange))) {

      return _depositIncentiveToken(_BBStaking, FULL_ALLOC);
    }

    if (_AAStaking != address(0) && (currAARatio < (_trancheIdealWeightRatio - _idealRange))) {

      return _depositIncentiveToken(_AAStaking, FULL_ALLOC);
    }




    _depositIncentiveToken(_AAStaking, _trancheAPRSplitRatio);



    _depositIncentiveToken(_BBStaking, FULL_ALLOC);
  }




  function _depositIncentiveToken(address _stakingContract, uint256 _ratio) internal {
    address[] memory _incentiveTokens = incentiveTokens;
    for (uint256 i = 0; i < _incentiveTokens.length; i++) {
      address _incentiveToken = _incentiveTokens[i];

      uint256 _reward = _contractTokenBalance(_incentiveToken) * _ratio / FULL_ALLOC;
      if (_reward > 0) {
        IIdleCDOTrancheRewards(_stakingContract).depositReward(_incentiveToken, _reward);
      }
    }
  }


  function _lastNAV() internal view returns (uint256) {
    return lastNAVAA + lastNAVBB;
  }



  function _tranchePrice(address _tranche) internal view returns (uint256) {
    if (IdleCDOTranche(_tranche).totalSupply() == 0) {
      return oneToken;
    }
    return _tranche == AATranche ? priceAA : priceBB;
  }



  function _lastTranchePrice(address _tranche) internal view returns (uint256) {
    return _tranche == AATranche ? lastAAPrice : lastBBPrice;
  }






  function _getApr(address _tranche, uint256 _AATrancheSplitRatio) internal view returns (uint256) {
    uint256 stratApr = strategyAPR();
    uint256 _trancheAPRSplitRatio = trancheAPRSplitRatio;
    bool isAATranche = _tranche == AATranche;
    if (_AATrancheSplitRatio == 0) {
      return isAATranche ? 0 : stratApr;
    }
    return isAATranche ?
      stratApr * _trancheAPRSplitRatio / _AATrancheSplitRatio :
      stratApr * (FULL_ALLOC - _trancheAPRSplitRatio) / (FULL_ALLOC - _AATrancheSplitRatio);
  }













  function harvest(bool _skipRedeem, bool _skipIncentivesUpdate, bool[] calldata _skipReward, uint256[] calldata _minAmount) external {
    require(msg.sender == rebalancer || msg.sender == owner(), "IDLE:!AUTH");

    address _token = token;
    address _strategy = strategy;

    if (!_skipRedeem) {

      address[] memory _incentiveTokens = incentiveTokens;
      address _weth = weth;
      IUniswapV2Router02 _uniRouter = uniswapRouterV2;

      IIdleCDOStrategy(_strategy).redeemRewards();

      address[] memory rewards = getRewards();
      for (uint256 i = 0; i < rewards.length; i++) {
        address rewardToken = rewards[i];

        uint256 _currentBalance = _contractTokenBalance(rewardToken);

        if (_skipReward[i] || _currentBalance == 0 || _includesAddress(_incentiveTokens, rewardToken)) { continue; }

        address[] memory _path = new address[](3);
        _path[0] = rewardToken;
        _path[1] = _weth;
        _path[2] = _token;

        IERC20Detailed(rewardToken).safeIncreaseAllowance(address(_uniRouter), _currentBalance);

        _uniRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
          _currentBalance,
          _minAmount[i],
          _path,
          address(this),
          block.timestamp + 1
        );
      }


      _updatePrices();






      _updateLastTranchePrices();



      uint256 currAARatio = _depositFees(unclaimedFees);

      if (!_skipIncentivesUpdate) {

        _updateIncentives(currAARatio);
      }
    }

    uint256 underlyingBal = _contractTokenBalance(_token);

    IIdleCDOStrategy(_strategy).deposit(

      underlyingBal - (underlyingBal * unlentPerc / FULL_ALLOC)
    );
  }





  function liquidate(uint256 _amount, bool _revertIfNeeded) external returns (uint256) {
    require(msg.sender == rebalancer || msg.sender == owner(), "IDLE:!AUTH");
    return _liquidate(_amount, _revertIfNeeded);
  }






  function setAllowAAWithdraw(bool _allowed) external onlyOwner {
    allowAAWithdraw = _allowed;
  }


  function setAllowBBWithdraw(bool _allowed) external onlyOwner {
    allowBBWithdraw = _allowed;
  }


  function setSkipDefaultCheck(bool _allowed) external onlyOwner {
    skipDefaultCheck = _allowed;
  }


  function setRevertIfTooLow(bool _allowed) external onlyOwner {
    revertIfTooLow = _allowed;
  }







  function setStrategy(address _strategy, address[] memory _incentiveTokens) external onlyOwner {
    require(_strategy != address(0), 'IDLE:IS_0');
    IERC20Detailed _token = IERC20Detailed(token);

    address _currStrategy = strategy;
    _token.safeApprove(_currStrategy, 0);
    IERC20Detailed(strategyToken).safeApprove(_currStrategy, 0);

    strategy = _strategy;

    incentiveTokens = _incentiveTokens;

    address _newStrategyToken = IIdleCDOStrategy(_strategy).strategyToken();
    strategyToken = _newStrategyToken;

    _token.safeIncreaseAllowance(_strategy, type(uint256).max);

    IERC20Detailed(_newStrategyToken).safeIncreaseAllowance(_strategy, type(uint256).max);

    lastStrategyPrice = strategyPrice();
  }


  function setRebalancer(address _rebalancer) external onlyOwner {
    require((rebalancer = _rebalancer) != address(0), 'IDLE:IS_0');
  }


  function setFeeReceiver(address _feeReceiver) external onlyOwner {
    require((feeReceiver = _feeReceiver) != address(0), 'IDLE:IS_0');
  }


  function setGuardian(address _guardian) external onlyOwner {
    require((guardian = _guardian) != address(0), 'IDLE:IS_0');
  }


  function setFee(uint256 _fee) external onlyOwner {
    require((fee = _fee) <= MAX_FEE, 'IDLE:TOO_HIGH');
  }


  function setUnlentPerc(uint256 _unlentPerc) external onlyOwner {
    require((unlentPerc = _unlentPerc) <= FULL_ALLOC, 'IDLE:TOO_HIGH');
  }


  function setIdealRange(uint256 _idealRange) external onlyOwner {
    require((idealRange = _idealRange) <= FULL_ALLOC, 'IDLE:TOO_HIGH');
  }



  function setIncentiveTokens(address[] memory _incentiveTokens) external onlyOwner {
    incentiveTokens = _incentiveTokens;
  }




  function setStakingRewards(address _AAStaking, address _BBStaking) external onlyOwner {

    address[] memory _incentiveTokens = incentiveTokens;
    address _currAAStaking = AAStaking;
    address _currBBStaking = BBStaking;


    for (uint256 i = 0; i < _incentiveTokens.length; i++) {
      IERC20Detailed _incentiveToken = IERC20Detailed(_incentiveTokens[i]);
      if (_currAAStaking != address(0)) {
        _incentiveToken.safeApprove(_currAAStaking, 0);
      }
      if (_currAAStaking != address(0)) {
        _incentiveToken.safeApprove(_currBBStaking, 0);
      }
    }


    AAStaking = _AAStaking;
    BBStaking = _BBStaking;


    for (uint256 i = 0; i < _incentiveTokens.length; i++) {
      IERC20Detailed _incentiveToken = IERC20Detailed(_incentiveTokens[i]);

      _incentiveToken.safeIncreaseAllowance(_AAStaking, type(uint256).max);
      _incentiveToken.safeIncreaseAllowance(_BBStaking, type(uint256).max);
    }
  }



  function emergencyShutdown() external {
    require(msg.sender == guardian || msg.sender == owner(), "IDLE:!AUTH");
    _pause();
    allowAAWithdraw = false;
    allowBBWithdraw = false;
    skipDefaultCheck = true;
    revertIfTooLow = true;
  }



  function pause() external  {
    require(msg.sender == guardian || msg.sender == owner(), "IDLE:!AUTH");
    _pause();
  }



  function unpause() external {
    require(msg.sender == guardian || msg.sender == owner(), "IDLE:!AUTH");
    _unpause();
  }







  function _contractTokenBalance(address _token) internal view returns (uint256) {
    return IERC20Detailed(_token).balanceOf(address(this));
  }


  function _updateCallerBlock() internal {
    _lastCallerBlock = keccak256(abi.encodePacked(tx.origin, block.number));
  }


  function _checkSameTx() internal view {
    require(keccak256(abi.encodePacked(tx.origin, block.number)) != _lastCallerBlock, "SAME_BLOCK");
  }






  function _includesAddress(address[] memory _array, address _val) internal pure returns (bool) {
    for (uint256 i = 0; i < _array.length; i++) {
      if (_array[i] == _val) {
        return true;
      }
    }

    return false;
  }
}
