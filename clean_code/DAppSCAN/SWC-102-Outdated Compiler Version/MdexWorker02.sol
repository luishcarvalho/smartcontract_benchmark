












pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../../apis/mdex/IMdexFactory.sol";
import "../../apis/mdex/IMdexRouter.sol";
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol";
import "../../interfaces/IBSCPool.sol";
import "../../interfaces/IMdexSwapMining.sol";

import "../../interfaces/IStrategy.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IWorker02.sol";

import "../../../utils/SafeToken.sol";
import "../../../utils/AlpacaMath.sol";

contract MdexWorker02 is OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe, IWorker02 {

  using SafeToken for address;
  using SafeMath for uint256;


  event Reinvest(address indexed caller, uint256 reward, uint256 bounty);
  event AddShare(uint256 indexed id, uint256 share);
  event RemoveShare(uint256 indexed id, uint256 share);
  event Liquidate(uint256 indexed id, uint256 wad);
  event SetTreasuryConfig(address indexed caller, address indexed account, uint256 bountyBps);
  event BeneficialVaultTokenBuyback(address indexed caller, IVault indexed beneficialVault, uint256 indexed buyback);
  event SetStrategyOK(address indexed caller, address indexed strategy, bool indexed isOk);
  event SetReinvestorOK(address indexed caller, address indexed reinvestor, bool indexed isOk);
  event SetCriticalStrategy(address indexed caller, IStrategy indexed addStrat, IStrategy indexed liqStrat);
  event SetMaxReinvestBountyBps(address indexed caller, uint256 indexed maxReinvestBountyBps);
  event SetRewardPath(address indexed caller, address[] newRewardPath);
  event SetBeneficialVaultConfig(
    address indexed caller,
    uint256 indexed beneficialVaultBountyBps,
    IVault indexed beneficialVault,
    address[] rewardPath
  );
  event SetReinvestConfig(
    address indexed caller,
    uint256 reinvestBountyBps,
    uint256 reinvestThreshold,
    address[] reinvestPath
  );
  event WithdrawTradingRewards(address indexed caller, address to, uint256 amount);


  IBSCPool public bscPool;
  IMdexFactory public factory;
  IMdexRouter public router;
  IPancakePair public override lpToken;
  address public wNative;
  address public override baseToken;
  address public override farmingToken;
  address public mdx;
  address public operator;
  uint256 public pid;


  mapping(uint256 => uint256) public shares;
  mapping(address => bool) public okStrats;
  uint256 public totalShare;
  IStrategy public addStrat;
  IStrategy public liqStrat;
  uint256 public reinvestBountyBps;
  uint256 public maxReinvestBountyBps;
  mapping(address => bool) public okReinvestors;


  uint256 public feeDenom;


  uint256 public reinvestThreshold;
  address[] public reinvestPath;
  address public treasuryAccount;
  uint256 public treasuryBountyBps;
  IVault public beneficialVault;
  uint256 public beneficialVaultBountyBps;
  address[] public rewardPath;
  uint256 public buybackAmount;

  function initialize(
    address _operator,
    address _baseToken,
    IBSCPool _bscPool,
    IMdexRouter _router,
    uint256 _pid,
    IStrategy _addStrat,
    IStrategy _liqStrat,
    uint256 _reinvestBountyBps,
    address _treasuryAccount,
    address[] calldata _reinvestPath,
    uint256 _reinvestThreshold
  ) external initializer {

    OwnableUpgradeSafe.__Ownable_init();
    ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();


    operator = _operator;
    wNative = _router.WBNB();
    bscPool = _bscPool;
    router = _router;
    factory = IMdexFactory(_router.factory());


    baseToken = _baseToken;
    pid = _pid;
    (IERC20 _lpToken, , , , , ) = bscPool.poolInfo(_pid);
    lpToken = IPancakePair(address(_lpToken));
    address token0 = lpToken.token0();
    address token1 = lpToken.token1();
    farmingToken = token0 == baseToken ? token1 : token0;
    mdx = address(bscPool.mdx());


    addStrat = _addStrat;
    liqStrat = _liqStrat;
    okStrats[address(addStrat)] = true;
    okStrats[address(liqStrat)] = true;


    reinvestBountyBps = _reinvestBountyBps;
    reinvestThreshold = _reinvestThreshold;
    reinvestPath = _reinvestPath;
    treasuryAccount = _treasuryAccount;
    treasuryBountyBps = _reinvestBountyBps;
    maxReinvestBountyBps = 500;


    feeDenom = 10000;


    require(baseToken != mdx, "MdexWorker02::initialize:: base token cannot be a reward token");
    require(
      reinvestBountyBps <= maxReinvestBountyBps,
      "MdexWorker02::initialize:: reinvestBountyBps exceeded maxReinvestBountyBps"
    );
    require(
      (farmingToken == lpToken.token0() || farmingToken == lpToken.token1()) &&
        (baseToken == lpToken.token0() || baseToken == lpToken.token1()),
      "MdexWorker02::initialize:: LP underlying not match with farm & base token"
    );
    require(
      reinvestPath[0] == mdx && reinvestPath[reinvestPath.length - 1] == baseToken,
      "MdexWorker02::initialize:: reinvestPath must start with MDX, end with BTOKEN"
    );
  }


  modifier onlyEOA() {
    require(msg.sender == tx.origin, "MdexWorker02::onlyEOA:: not eoa");
    _;
  }


  modifier onlyOperator() {
    require(msg.sender == operator, "MdexWorker02::onlyOperator:: not operator");
    _;
  }


  modifier onlyReinvestor() {
    require(okReinvestors[msg.sender], "MdexWorker02::onlyReinvestor:: not reinvestor");
    _;
  }



  function shareToBalance(uint256 share) public view returns (uint256) {
    if (totalShare == 0) return share;
    (uint256 totalBalance, , ) = bscPool.userInfo(pid, address(this));
    return share.mul(totalBalance).div(totalShare);
  }



  function balanceToShare(uint256 balance) public view returns (uint256) {
    if (totalShare == 0) return balance;
    (uint256 totalBalance, , ) = bscPool.userInfo(pid, address(this));
    return balance.mul(totalShare).div(totalBalance);
  }


  function reinvest() external override onlyEOA onlyReinvestor nonReentrant {
    _reinvest(msg.sender, reinvestBountyBps, 0, 0);


    _buyback();
  }






  function _reinvest(
    address _treasuryAccount,
    uint256 _treasuryBountyBps,
    uint256 _callerBalance,
    uint256 _reinvestThreshold
  ) internal {

    bscPool.withdraw(pid, 0);
    uint256 reward = mdx.balanceOf(address(this));
    if (reward <= _reinvestThreshold) return;


    mdx.safeApprove(address(router), uint256(-1));
    address(lpToken).safeApprove(address(bscPool), uint256(-1));


    uint256 bounty = reward.mul(_treasuryBountyBps) / 10000;
    if (bounty > 0) {
      uint256 beneficialVaultBounty = bounty.mul(beneficialVaultBountyBps) / 10000;
      if (beneficialVaultBounty > 0) _rewardToBeneficialVault(beneficialVaultBounty, _callerBalance);
      mdx.safeTransfer(_treasuryAccount, bounty.sub(beneficialVaultBounty));
    }


    router.swapExactTokensForTokens(reward.sub(bounty), 0, getReinvestPath(), address(this), now);


    baseToken.safeTransfer(address(addStrat), actualBaseTokenBalance().sub(_callerBalance));
    addStrat.execute(address(0), 0, abi.encode(0));


    bscPool.deposit(pid, lpToken.balanceOf(address(this)));


    mdx.safeApprove(address(router), 0);
    address(lpToken).safeApprove(address(bscPool), 0);

    emit Reinvest(_treasuryAccount, reward, bounty);
  }






  function work(
    uint256 id,
    address user,
    uint256 debt,
    bytes calldata data
  ) external override onlyOperator nonReentrant {

    _reinvest(treasuryAccount, treasuryBountyBps, actualBaseTokenBalance(), reinvestThreshold);

    _removeShare(id);

    (address strat, bytes memory ext) = abi.decode(data, (address, bytes));
    require(okStrats[strat], "MdexWorker02::work:: unapproved work strategy");
    address(lpToken).safeTransfer(strat, lpToken.balanceOf(address(this)));
    baseToken.safeTransfer(strat, actualBaseTokenBalance());
    IStrategy(strat).execute(user, debt, ext);

    _addShare(id);

    baseToken.safeTransfer(msg.sender, actualBaseTokenBalance());
  }





  function getMktSellAmount(
    uint256 aIn,
    uint256 rIn,
    uint256 rOut,
    uint256 fee
  ) public view returns (uint256) {
    if (aIn == 0) return 0;
    require(rIn > 0 && rOut > 0, "MdexWorker02::getMktSellAmount:: bad reserve values");
    uint256 aInWithFee = aIn.mul(fee);
    uint256 numerator = aInWithFee.mul(rOut);
    uint256 denominator = rIn.mul(feeDenom).add(aInWithFee);
    return numerator / denominator;
  }



  function health(uint256 id) external view override returns (uint256) {

    uint256 lpBalance = shareToBalance(shares[id]);
    uint256 lpSupply = lpToken.totalSupply();

    (uint256 r0, uint256 r1, ) = lpToken.getReserves();
    (uint256 totalBaseToken, uint256 totalFarmingToken) = lpToken.token0() == baseToken ? (r0, r1) : (r1, r0);

    uint256 userBaseToken = lpBalance.mul(totalBaseToken).div(lpSupply);
    uint256 userFarmingToken = lpBalance.mul(totalFarmingToken).div(lpSupply);

    uint256 fee = feeDenom.sub(factory.getPairFees(address(lpToken)));

    return
      getMktSellAmount(
        userFarmingToken,
        totalFarmingToken.sub(userFarmingToken),
        totalBaseToken.sub(userBaseToken),
        fee
      )
        .add(userBaseToken);
  }



  function liquidate(uint256 id) external override onlyOperator nonReentrant {

    _removeShare(id);
    address(lpToken).safeTransfer(address(liqStrat), lpToken.balanceOf(address(this)));
    liqStrat.execute(address(0), 0, abi.encode(0));

    uint256 liquidatedAmount = actualBaseTokenBalance();
    baseToken.safeTransfer(msg.sender, liquidatedAmount);
    emit Liquidate(id, liquidatedAmount);
  }




  function _rewardToBeneficialVault(uint256 _beneficialVaultBounty, uint256 _callerBalance) internal {

    address beneficialVaultToken = beneficialVault.token();

    uint256[] memory amounts =
      router.swapExactTokensForTokens(_beneficialVaultBounty, 0, rewardPath, address(this), now);



    if (beneficialVaultToken != baseToken) {
      buybackAmount = 0;
      beneficialVaultToken.safeTransfer(address(beneficialVault), beneficialVaultToken.myBalance());
      emit BeneficialVaultTokenBuyback(msg.sender, beneficialVault, amounts[amounts.length - 1]);
    } else {
      buybackAmount = beneficialVaultToken.myBalance().sub(_callerBalance);
    }
  }



  function _buyback() internal {
    if (buybackAmount == 0) return;
    uint256 _buybackAmount = buybackAmount;
    buybackAmount = 0;
    beneficialVault.token().safeTransfer(address(beneficialVault), _buybackAmount);
    emit BeneficialVaultTokenBuyback(msg.sender, beneficialVault, _buybackAmount);
  }



  function actualBaseTokenBalance() internal view returns (uint256) {
    return baseToken.myBalance().sub(buybackAmount);
  }


  function _addShare(uint256 id) internal {
    uint256 balance = lpToken.balanceOf(address(this));
    if (balance > 0) {

      address(lpToken).safeApprove(address(bscPool), uint256(-1));

      uint256 share = balanceToShare(balance);

      bscPool.deposit(pid, balance);

      shares[id] = shares[id].add(share);
      totalShare = totalShare.add(share);

      address(lpToken).safeApprove(address(bscPool), 0);
      emit AddShare(id, share);
    }
  }


  function _removeShare(uint256 id) internal {
    uint256 share = shares[id];
    if (share > 0) {
      uint256 balance = shareToBalance(share);
      bscPool.withdraw(pid, balance);
      totalShare = totalShare.sub(share);
      shares[id] = 0;
      emit RemoveShare(id, share);
    }
  }


  function getPath() external view override returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = baseToken;
    path[1] = farmingToken;
    return path;
  }


  function getReversedPath() external view override returns (address[] memory) {
    address[] memory reversePath = new address[](2);
    reversePath[0] = farmingToken;
    reversePath[1] = baseToken;
    return reversePath;
  }


  function getRewardPath() external view override returns (address[] memory) {
    return rewardPath;
  }


  function getReinvestPath() public view returns (address[] memory) {
    if (reinvestPath.length != 0) return reinvestPath;
    address[] memory path;
    if (baseToken == wNative) {
      path = new address[](2);
      path[0] = address(mdx);
      path[1] = address(wNative);
    } else {
      path = new address[](3);
      path[0] = address(mdx);
      path[1] = address(wNative);
      path[2] = address(baseToken);
    }
    return path;
  }





  function setReinvestConfig(
    uint256 _reinvestBountyBps,
    uint256 _reinvestThreshold,
    address[] calldata _reinvestPath
  ) external onlyOwner {
    require(
      _reinvestBountyBps <= maxReinvestBountyBps,
      "MdexWorker02::setReinvestConfig:: _reinvestBountyBps exceeded maxReinvestBountyBps"
    );
    require(_reinvestPath.length >= 2, "MdexWorker02::setReinvestConfig:: _reinvestPath length must >= 2");
    require(
      _reinvestPath[0] == mdx && _reinvestPath[_reinvestPath.length - 1] == baseToken,
      "MdexWorker02::setReinvestConfig:: _reinvestPath must start with MDX, end with BTOKEN"
    );

    reinvestBountyBps = _reinvestBountyBps;
    reinvestThreshold = _reinvestThreshold;
    reinvestPath = _reinvestPath;

    emit SetReinvestConfig(msg.sender, _reinvestBountyBps, _reinvestThreshold, _reinvestPath);
  }



  function setMaxReinvestBountyBps(uint256 _maxReinvestBountyBps) external onlyOwner {
    require(
      _maxReinvestBountyBps >= reinvestBountyBps,
      "MdexWorker02::setMaxReinvestBountyBps:: _maxReinvestBountyBps lower than reinvestBountyBps"
    );
    require(
      _maxReinvestBountyBps <= 3000,
      "MdexWorker02::setMaxReinvestBountyBps:: _maxReinvestBountyBps exceeded 30%"
    );

    maxReinvestBountyBps = _maxReinvestBountyBps;

    emit SetMaxReinvestBountyBps(msg.sender, maxReinvestBountyBps);
  }




  function setStrategyOk(address[] calldata strats, bool isOk) external override onlyOwner {
    uint256 len = strats.length;
    for (uint256 idx = 0; idx < len; idx++) {
      okStrats[strats[idx]] = isOk;

      emit SetStrategyOK(msg.sender, strats[idx], isOk);
    }
  }




  function setReinvestorOk(address[] calldata reinvestors, bool isOk) external override onlyOwner {
    uint256 len = reinvestors.length;
    for (uint256 idx = 0; idx < len; idx++) {
      okReinvestors[reinvestors[idx]] = isOk;

      emit SetReinvestorOK(msg.sender, reinvestors[idx], isOk);
    }
  }



  function setRewardPath(address[] calldata _rewardPath) external onlyOwner {
    require(_rewardPath.length >= 2, "MdexWorker02::setRewardPath:: rewardPath length must be >= 2");
    require(
      _rewardPath[0] == mdx && _rewardPath[_rewardPath.length - 1] == beneficialVault.token(),
      "MdexWorker02::setRewardPath:: rewardPath must start with MDX and end with beneficialVault token"
    );

    rewardPath = _rewardPath;

    emit SetRewardPath(msg.sender, _rewardPath);
  }




  function setCriticalStrategies(IStrategy _addStrat, IStrategy _liqStrat) external onlyOwner {
    addStrat = _addStrat;
    liqStrat = _liqStrat;

    emit SetCriticalStrategy(msg.sender, addStrat, liqStrat);
  }




  function setTreasuryConfig(address _treasuryAccount, uint256 _treasuryBountyBps) external onlyOwner {
    require(
      _treasuryBountyBps <= maxReinvestBountyBps,
      "MdexWorker02::setTreasuryConfig:: _treasuryBountyBps exceeded maxReinvestBountyBps"
    );

    treasuryAccount = _treasuryAccount;
    treasuryBountyBps = _treasuryBountyBps;

    emit SetTreasuryConfig(msg.sender, treasuryAccount, treasuryBountyBps);
  }





  function setBeneficialVaultConfig(
    uint256 _beneficialVaultBountyBps,
    IVault _beneficialVault,
    address[] calldata _rewardPath
  ) external onlyOwner {
    require(
      _beneficialVaultBountyBps <= 10000,
      "MdexWorker02::setBeneficialVaultConfig:: _beneficialVaultBountyBps exceeds 100%"
    );
    require(_rewardPath.length >= 2, "MdexWorker02::setBeneficialVaultConfig:: rewardPath length must >= 2");
    require(
      _rewardPath[0] == mdx && _rewardPath[_rewardPath.length - 1] == _beneficialVault.token(),
      "MdexWorker02::setBeneficialVaultConfig:: rewardPath must start with MDX, end with beneficialVault token"
    );

    _buyback();

    beneficialVaultBountyBps = _beneficialVaultBountyBps;
    beneficialVault = _beneficialVault;
    rewardPath = _rewardPath;

    emit SetBeneficialVaultConfig(msg.sender, _beneficialVaultBountyBps, _beneficialVault, _rewardPath);
  }



  function withdrawTradingRewards(address to) external onlyOwner {
    uint256 mdxBalanceBefore = mdx.myBalance();
    IMdexSwapMining(router.swapMining()).takerWithdraw();
    uint256 mdxBalanceAfter = mdx.myBalance().sub(mdxBalanceBefore);
    mdx.safeTransfer(to, mdxBalanceAfter);
    emit WithdrawTradingRewards(msg.sender, to, mdxBalanceAfter);
  }



  function getMiningRewards(uint256[] calldata pIds) external view returns (uint256) {
    address swapMiningAddress = router.swapMining();
    uint256 totalReward;
    for (uint256 index = 0; index < pIds.length; index++) {
      (uint256 reward, ) = IMdexSwapMining(swapMiningAddress).getUserReward(pIds[index]);
      totalReward = totalReward.add(reward);
    }
    return totalReward;
  }
}
