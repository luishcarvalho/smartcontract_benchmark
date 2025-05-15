pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol";
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol";

import "../apis/pancake/IPancakeRouter02.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IWorker02.sol";
import "../interfaces/IPancakeMasterChef.sol";
import "../../utils/AlpacaMath.sol";
import "../../utils/SafeToken.sol";
import "../interfaces/IVault.sol";


contract CakeMaxiWorker is OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe, IWorker02 {

  using SafeToken for address;
  using SafeMath for uint256;


  event Reinvest(address indexed caller, uint256 reward, uint256 bounty);
  event AddShare(uint256 indexed id, uint256 share);
  event RemoveShare(uint256 indexed id, uint256 share);
  event Liquidate(uint256 indexed id, uint256 wad);
  event SetPath(address indexed caller, address[] newPath);
  event SetRewardPath(address indexed caller, address[] newRewardPath);
  event SetReinvestBountyBps(address indexed caller, uint256 indexed reinvestBountyBps);
  event SetBeneficialVaultBountyBps(address indexed caller, uint256 indexed beneficialVaultBountyBps);
  event SetMaxReinvestBountyBps(address indexed caller, uint256 indexed maxReinvestBountyBps);
  event SetStrategyOK(address indexed caller, address indexed strategy, bool indexed isOk);
  event SetReinvestorOK(address indexed caller, address indexed reinvestor, bool indexed isOk);
  event SetCriticalStrategy(address indexed caller, IStrategy indexed addStrat, IStrategy indexed liqStrat);
  event BeneficialVaultTokenBuyback(address indexed caller, IVault indexed beneficialVault, uint256 indexed buyback);


  IPancakeMasterChef public masterChef;
  IPancakeFactory public factory;
  IPancakeRouter02 public router;
  IPancakePair public override lpToken;
  address public wNative;
  address public override baseToken;
  address public override farmingToken;
  address public operator;
  uint256 public pid;
  IVault public beneficialVault;


  mapping(uint256 => uint256) public shares;
  mapping(address => bool) public okStrats;
  uint256 public totalShare;
  IStrategy public addStrat;
  IStrategy public liqStrat;
  uint256 public beneficialVaultBountyBps;
  uint256 public reinvestBountyBps;
  uint256 public maxReinvestBountyBps;
  uint256 public rewardBalance;
  mapping(address => bool) public okReinvestors;
  address[] public path;
  address[] public rewardPath;


  uint256 public fee;
  uint256 public feeDenom;

  function initialize(
    address _operator,
    address _baseToken,
    IPancakeMasterChef _masterChef,
    IPancakeRouter02 _router,
    IVault _beneficialVault,
    uint256 _pid,
    IStrategy _addStrat,
    IStrategy _liqStrat,
    uint256 _reinvestBountyBps,
    uint256 _beneficialVaultBountyBps,
    address[] calldata _path,
    address[] calldata _rewardPath
  ) external initializer {
    OwnableUpgradeSafe.__Ownable_init();
    ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();
    operator = _operator;
    baseToken = _baseToken;
    wNative = _router.WETH();
    masterChef = _masterChef;
    beneficialVault = _beneficialVault;
    router = _router;
    factory = IPancakeFactory(_router.factory());
    pid = _pid;
    (IERC20 _farmingToken, , , ) = masterChef.poolInfo(_pid);
    farmingToken = address(_farmingToken);
    addStrat = _addStrat;
    liqStrat = _liqStrat;
    okStrats[address(addStrat)] = true;
    okStrats[address(liqStrat)] = true;
    reinvestBountyBps = _reinvestBountyBps;
    beneficialVaultBountyBps = _beneficialVaultBountyBps;
    maxReinvestBountyBps = 2000;
    fee = 9975;
    feeDenom = 10000;
    path = _path;
    rewardPath = _rewardPath;

    require(path.length >= 2, "CakeMaxiWorker::initialize:: path length must be >= 2");
    require(path[0] == baseToken && path[path.length-1] == farmingToken, "CakeMaxiWorker::initialize:: path must start with base token and end with farming token");
    require(rewardPath.length >= 2, "CakeMaxiWorker::initialize:: rewardPath length must be >= 2");
    require(rewardPath[0] == farmingToken && rewardPath[rewardPath.length-1] == beneficialVault.token(), "CakeMaxiWorker::initialize:: rewardPath must start with farming token and end with beneficialVault.token()");
    require(reinvestBountyBps <= maxReinvestBountyBps, "CakeMaxiWorker::initialize:: reinvestBountyBps exceeded maxReinvestBountyBps");
  }


  modifier onlyEOA() {
    require(_msgSender() == tx.origin, "CakeMaxiWorker::onlyEOA:: not eoa");
    _;
  }


  modifier onlyOperator() {
    require(_msgSender() == operator, "CakeMaxiWorker::onlyOperator:: not operator");
    _;
  }


  modifier onlyReinvestor() {
    require(okReinvestors[_msgSender()], "CakeMaxiWorker::onlyReinvestor:: not reinvestor");
    _;
  }



  function shareToBalance(uint256 share) public view returns (uint256) {
    if (totalShare == 0) return share;
    (uint256 totalBalance, ) = masterChef.userInfo(pid, address(this));
    return share.mul(totalBalance).div(totalShare);
  }



  function balanceToShare(uint256 balance) public view returns (uint256) {
    if (totalShare == 0) return balance;
    (uint256 totalBalance, ) = masterChef.userInfo(pid, address(this));
    return balance.mul(totalShare).div(totalBalance);
  }


  function reinvest() external override onlyEOA onlyReinvestor nonReentrant {

    farmingToken.safeApprove(address(masterChef), uint256(-1));

    rewardBalance = 0;

    masterChef.leaveStaking(0);
    uint256 reward = farmingToken.myBalance();
    if (reward == 0) return;

    uint256 bounty = reward.mul(reinvestBountyBps) / 10000;
    if (bounty > 0) {
      uint256 beneficialVaultBounty = bounty.mul(beneficialVaultBountyBps) / 10000;
      if (beneficialVaultBounty > 0) _rewardToBeneficialVault(beneficialVaultBounty, farmingToken);
      farmingToken.safeTransfer(_msgSender(), bounty.sub(beneficialVaultBounty));
    }

    masterChef.enterStaking(reward.sub(bounty));

    farmingToken.safeApprove(address(masterChef), 0);
    emit Reinvest(_msgSender(), reward, bounty);
  }


  function _rewardToBeneficialVault(uint256 _beneficialVaultBounty, address _rewardToken) internal {

    _rewardToken.safeApprove(address(router), uint256(-1));

    address beneficialVaultToken = beneficialVault.token();

    uint256[] memory amounts = router.swapExactTokensForTokens(_beneficialVaultBounty, 0, rewardPath, address(this), now);
    beneficialVaultToken.safeTransfer(address(beneficialVault), beneficialVaultToken.myBalance());
    _rewardToken.safeApprove(address(router), 0);

    emit BeneficialVaultTokenBuyback(_msgSender(), beneficialVault, amounts[amounts.length - 1]);
  }






  function work(uint256 id, address user, uint256 debt, bytes calldata data)
    override
    external
    onlyOperator nonReentrant
  {

    _removeShare(id);

    (address strat, bytes memory ext) = abi.decode(data, (address, bytes));
    require(okStrats[strat], "CakeMaxiWorker::work:: unapproved work strategy");
    baseToken.safeTransfer(strat, baseToken.myBalance());
    farmingToken.safeTransfer(strat, actualFarmingTokenBalance());
    IStrategy(strat).execute(user, debt, ext);

    _addShare(id);

    baseToken.safeTransfer(_msgSender(), baseToken.myBalance());
  }





  function getMktSellAmount(uint256 aIn, uint256 rIn, uint256 rOut) public view returns (uint256) {
    if (aIn == 0) return 0;
    require(rIn > 0 && rOut > 0, "CakeMaxiWorker::getMktSellAmount:: bad reserve values");
    uint256 aInWithFee = aIn.mul(fee);
    uint256 numerator = aInWithFee.mul(rOut);
    uint256 denominator = rIn.mul(feeDenom).add(aInWithFee);
    return numerator / denominator;
  }



  function health(uint256 id) external override view returns (uint256) {
    IPancakePair currentLP;
    uint256[] memory amount;
    address[] memory reversedPath = getReversedPath();
    amount = new uint256[](reversedPath.length);
    amount[0] = shareToBalance(shares[id]);
    for(uint256 i = 1; i < reversedPath.length; i++) {

        currentLP = IPancakePair(factory.getPair(reversedPath[i-1], reversedPath[i]));

        (uint256 r0, uint256 r1,) = currentLP.getReserves();
        (uint256 rOut, uint256 rIn) = currentLP.token0() == reversedPath[i] ? (r0, r1) : (r1, r0);

        amount[i] = getMktSellAmount(
            amount[i-1], rIn, rOut
        );
    }

    return amount[amount.length - 1];
  }



  function liquidate(uint256 id) external override onlyOperator nonReentrant {

    _removeShare(id);
    farmingToken.safeTransfer(address(liqStrat), actualFarmingTokenBalance());
    liqStrat.execute(address(0), 0, abi.encode(0));

    uint256 wad = baseToken.myBalance();
    baseToken.safeTransfer(_msgSender(), wad);
    emit Liquidate(id, wad);
  }



  function actualFarmingTokenBalance() internal view returns (uint256) {
    return farmingToken.myBalance().sub(rewardBalance);
  }


  function _addShare(uint256 id) internal  {
    uint256 shareBalance = actualFarmingTokenBalance();
    if (shareBalance > 0) {

      address(farmingToken).safeApprove(address(masterChef), uint256(-1));

      uint256 share = balanceToShare(shareBalance);

      shares[id] = shares[id].add(share);
      totalShare = totalShare.add(share);
      rewardBalance = rewardBalance.add(masterChef.pendingCake(pid, address(this)));

      masterChef.enterStaking(shareBalance);

      address(farmingToken).safeApprove(address(masterChef), 0);
      emit AddShare(id, share);
    }
  }




  function _removeShare(uint256 id) internal {
    uint256 share = shares[id];
    if (share > 0) {
      uint256 balance = shareToBalance(share);
      totalShare = totalShare.sub(share);
      shares[id] = 0;
      rewardBalance = rewardBalance.add(masterChef.pendingCake(pid, address(this)));
      masterChef.leaveStaking(balance);

      emit RemoveShare(id, share);
    }
  }


  function getPath() external view override returns (address[] memory) {
    return path;
  }


  function getReversedPath() public view override returns (address[] memory) {
    address tmp;
    address[] memory reversedPath = path;
    for (uint i = 0; i < reversedPath.length / 2; i++) {
      tmp = reversedPath[i];
      reversedPath[i] = reversedPath[reversedPath.length - i - 1];
      reversedPath[reversedPath.length - i - 1] = tmp;
    }
    return reversedPath;
  }


  function getRewardPath() external view override returns (address[] memory) {
    return rewardPath;
  }



  function setReinvestBountyBps(uint256 _reinvestBountyBps) external onlyOwner {
    require(_reinvestBountyBps <= maxReinvestBountyBps, "CakeMaxiWorker::setReinvestBountyBps:: _reinvestBountyBps exceeded maxReinvestBountyBps");
    reinvestBountyBps = _reinvestBountyBps;
    emit SetReinvestBountyBps(_msgSender(), _reinvestBountyBps);
  }




  function setBeneficialVaultBountyBps(uint256 _beneficialVaultBountyBps) external onlyOwner {
    require(_beneficialVaultBountyBps <= 10000,  "CakeMaxiWorker::setBeneficialVaultBountyBps:: _beneficialVaultBountyBps exceeds 100%");
    beneficialVaultBountyBps = _beneficialVaultBountyBps;
    emit SetBeneficialVaultBountyBps(_msgSender(), _beneficialVaultBountyBps);
  }



  function setMaxReinvestBountyBps(uint256 _maxReinvestBountyBps) external onlyOwner {
    require(_maxReinvestBountyBps >= reinvestBountyBps, "CakeMaxiWorker::setMaxReinvestBountyBps:: _maxReinvestBountyBps lower than reinvestBountyBps");
    maxReinvestBountyBps = _maxReinvestBountyBps;
    emit SetMaxReinvestBountyBps(_msgSender(), _maxReinvestBountyBps);
  }




  function setStrategyOk(address[] calldata strats, bool isOk) external override onlyOwner {
    uint256 len = strats.length;
    for (uint256 idx = 0; idx < len; idx++) {
      okStrats[strats[idx]] = isOk;
      emit SetStrategyOK(_msgSender(), strats[idx], isOk);
    }
  }




  function setReinvestorOk(address[] calldata reinvestors, bool isOk) external override onlyOwner {
    uint256 len = reinvestors.length;
    for (uint256 idx = 0; idx < len; idx++) {
      okReinvestors[reinvestors[idx]] = isOk;
      emit SetReinvestorOK(_msgSender(), reinvestors[idx], isOk);
    }
  }



  function setPath(address[] calldata _path) external onlyOwner {
    require(_path.length >= 2, "CakeMaxiWorker::setPath:: path length must be >= 2");
    require(_path[0] == baseToken && _path[_path.length-1] == farmingToken, "CakeMaxiWorker::setPath:: path must start with base token and end with farming token");

    path = _path;

    emit SetPath(_msgSender(), _path);
  }



  function setRewardPath(address[] calldata _rewardPath) external onlyOwner {
    require(rewardPath.length >= 2, "CakeMaxiWorker::initialize:: rewardPath length must be >= 2");
    require(rewardPath[0] == farmingToken && rewardPath[rewardPath.length-1] == beneficialVault.token(), "CakeMaxiWorker::initialize:: rewardPath must start with farming token and end with beneficialVault.token()");

    rewardPath = _rewardPath;

    emit SetRewardPath(_msgSender(), _rewardPath);
  }




  function setCriticalStrategies(IStrategy _addStrat, IStrategy _liqStrat) external onlyOwner {
    addStrat = _addStrat;
    liqStrat = _liqStrat;
    emit SetCriticalStrategy(_msgSender(), _addStrat, _liqStrat);
  }

}
