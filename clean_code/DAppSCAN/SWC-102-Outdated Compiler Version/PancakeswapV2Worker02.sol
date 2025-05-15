












pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol";
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol";

import "../../apis/pancake/IPancakeRouter02.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IWorker.sol";
import "../../interfaces/IPancakeMasterChef.sol";
import "../../../utils/AlpacaMath.sol";
import "../../../utils/SafeToken.sol";


contract PancakeswapV2Worker02 is OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe, IWorker {

  using SafeToken for address;
  using SafeMath for uint256;


  event Reinvest(address indexed caller, uint256 reward, uint256 bounty);
  event AddShare(uint256 indexed id, uint256 share);
  event RemoveShare(uint256 indexed id, uint256 share);
  event Liquidate(uint256 indexed id, uint256 wad);


  IPancakeMasterChef public masterChef;
  IPancakeFactory public factory;
  IPancakeRouter02 public router;
  IPancakePair public override lpToken;
  address public wNative;
  address public override baseToken;
  address public override farmingToken;
  address public cake;
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


  uint256 public fee;
  uint256 public feeDenom;


  address public treasuryAccount;
  uint256 public treasuryBountyBps;
  event SetTreasuryBountyBps(address indexed account, uint256 bountyBps);
  event SetTreasuryAccount(address indexed account);

  function initialize(
    address _operator,
    address _baseToken,
    IPancakeMasterChef _masterChef,
    IPancakeRouter02 _router,
    uint256 _pid,
    IStrategy _addStrat,
    IStrategy _liqStrat,
    uint256 _reinvestBountyBps
  ) external initializer {
    OwnableUpgradeSafe.__Ownable_init();
    ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();

    operator = _operator;
    baseToken = _baseToken;
    wNative = _router.WETH();
    masterChef = _masterChef;
    router = _router;
    factory = IPancakeFactory(_router.factory());

    pid = _pid;
    (IERC20 _lpToken, , , ) = masterChef.poolInfo(_pid);
    lpToken = IPancakePair(address(_lpToken));
    address token0 = lpToken.token0();
    address token1 = lpToken.token1();
    farmingToken = token0 == baseToken ? token1 : token0;
    cake = address(masterChef.cake());
    addStrat = _addStrat;
    liqStrat = _liqStrat;
    okStrats[address(addStrat)] = true;
    okStrats[address(liqStrat)] = true;
    reinvestBountyBps = _reinvestBountyBps;
    maxReinvestBountyBps = 500;
    fee = 9975;
    feeDenom = 10000;

    require(
      reinvestBountyBps <= maxReinvestBountyBps,
      "PancakeswapWorker::initialize:: reinvestBountyBps exceeded maxReinvestBountyBps"
    );
    require(
      (farmingToken == lpToken.token0() || farmingToken == lpToken.token1()) &&
        (baseToken == lpToken.token0() || baseToken == lpToken.token1()),
      "PancakeswapWorker::initialize:: LP underlying not match with farm & base token"
    );
  }


  modifier onlyEOA() {
    require(msg.sender == tx.origin, "PancakeswapWorker::onlyEOA:: not eoa");
    _;
  }


  modifier onlyOperator() {
    require(msg.sender == operator, "PancakeswapWorker::onlyOperator:: not operator");
    _;
  }


  modifier onlyReinvestor() {
    require(okReinvestors[msg.sender], "PancakeswapWorker::onlyReinvestor:: not reinvestor");
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
    _reinvest(msg.sender, reinvestBountyBps, 0);
  }


  function _reinvest(
    address _treasuryAccount,
    uint256 _treasuryBountyBps,
    uint256 _callerBalance
  ) internal {
    require(_treasuryAccount != address(0), "PancakeswapV2Worker::reinvest:: bad treasury account");

    cake.safeApprove(address(router), uint256(-1));
    address(lpToken).safeApprove(address(masterChef), uint256(-1));

    masterChef.withdraw(pid, 0);
    uint256 reward = cake.balanceOf(address(this));
    if (reward == 0) return;

    uint256 bounty = reward.mul(_treasuryBountyBps) / 10000;
    if (bounty > 0) cake.safeTransfer(_treasuryAccount, bounty);

    address[] memory path;
    if (baseToken == wNative) {
      path = new address[](2);
      path[0] = address(cake);
      path[1] = address(wNative);
    } else {
      path = new address[](3);
      path[0] = address(cake);
      path[1] = address(wNative);
      path[2] = address(baseToken);
    }
    router.swapExactTokensForTokens(reward.sub(bounty), 0, path, address(this), now);

    baseToken.safeTransfer(address(addStrat), baseToken.myBalance().sub(_callerBalance));
    addStrat.execute(address(0), 0, abi.encode(0));

    masterChef.deposit(pid, lpToken.balanceOf(address(this)));

    cake.safeApprove(address(router), 0);
    address(lpToken).safeApprove(address(masterChef), 0);
    emit Reinvest(_treasuryAccount, reward, bounty);
  }






  function work(
    uint256 id,
    address user,
    uint256 debt,
    bytes calldata data
  ) external override onlyOperator nonReentrant {

    if (treasuryBountyBps == 0) treasuryBountyBps = reinvestBountyBps;
    if (treasuryAccount == address(0)) treasuryAccount = address(0xC44f82b07Ab3E691F826951a6E335E1bC1bB0B51);

    _reinvest(treasuryAccount, treasuryBountyBps, baseToken.myBalance());

    _removeShare(id);

    (address strat, bytes memory ext) = abi.decode(data, (address, bytes));
    require(okStrats[strat], "PancakeswapWorker::work:: unapproved work strategy");
    require(
      lpToken.transfer(strat, lpToken.balanceOf(address(this))),
      "PancakeswapWorker::work:: unable to transfer lp to strat"
    );
    baseToken.safeTransfer(strat, baseToken.myBalance());
    IStrategy(strat).execute(user, debt, ext);

    _addShare(id);

    baseToken.safeTransfer(msg.sender, baseToken.myBalance());
  }





  function getMktSellAmount(
    uint256 aIn,
    uint256 rIn,
    uint256 rOut
  ) public view returns (uint256) {
    if (aIn == 0) return 0;
    require(rIn > 0 && rOut > 0, "PancakeswapWorker::getMktSellAmount:: bad reserve values");
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

    return
      getMktSellAmount(userFarmingToken, totalFarmingToken.sub(userFarmingToken), totalBaseToken.sub(userBaseToken))
        .add(userBaseToken);
  }



  function liquidate(uint256 id) external override onlyOperator nonReentrant {

    _removeShare(id);
    lpToken.transfer(address(liqStrat), lpToken.balanceOf(address(this)));
    liqStrat.execute(address(0), 0, abi.encode(0));

    uint256 wad = baseToken.myBalance();
    baseToken.safeTransfer(msg.sender, wad);
    emit Liquidate(id, wad);
  }


  function _addShare(uint256 id) internal {
    uint256 balance = lpToken.balanceOf(address(this));
    if (balance > 0) {

      address(lpToken).safeApprove(address(masterChef), uint256(-1));

      uint256 share = balanceToShare(balance);

      masterChef.deposit(pid, balance);

      shares[id] = shares[id].add(share);
      totalShare = totalShare.add(share);

      address(lpToken).safeApprove(address(masterChef), 0);
      emit AddShare(id, share);
    }
  }


  function _removeShare(uint256 id) internal {
    uint256 share = shares[id];
    if (share > 0) {
      uint256 balance = shareToBalance(share);
      masterChef.withdraw(pid, balance);
      totalShare = totalShare.sub(share);
      shares[id] = 0;
      emit RemoveShare(id, share);
    }
  }



  function setReinvestBountyBps(uint256 _reinvestBountyBps) external onlyOwner {
    require(
      _reinvestBountyBps <= maxReinvestBountyBps,
      "PancakeswapWorker::setReinvestBountyBps:: _reinvestBountyBps exceeded maxReinvestBountyBps"
    );
    reinvestBountyBps = _reinvestBountyBps;
  }



  function setMaxReinvestBountyBps(uint256 _maxReinvestBountyBps) external onlyOwner {
    require(
      _maxReinvestBountyBps >= reinvestBountyBps,
      "PancakeswapWorker::setMaxReinvestBountyBps:: _maxReinvestBountyBps lower than reinvestBountyBps"
    );
    maxReinvestBountyBps = _maxReinvestBountyBps;
  }




  function setStrategyOk(address[] calldata strats, bool isOk) external override onlyOwner {
    uint256 len = strats.length;
    for (uint256 idx = 0; idx < len; idx++) {
      okStrats[strats[idx]] = isOk;
    }
  }




  function setReinvestorOk(address[] calldata reinvestors, bool isOk) external override onlyOwner {
    uint256 len = reinvestors.length;
    for (uint256 idx = 0; idx < len; idx++) {
      okReinvestors[reinvestors[idx]] = isOk;
    }
  }




  function setCriticalStrategies(IStrategy _addStrat, IStrategy _liqStrat) external onlyOwner {
    addStrat = _addStrat;
    liqStrat = _liqStrat;
  }



  function setTreasuryAccount(address _account) external onlyOwner {
    treasuryAccount = _account;

    emit SetTreasuryAccount(_account);
  }



  function setTreasuryBountyBps(uint256 _treasuryBountyBps) external onlyOwner {
    require(
      _treasuryBountyBps <= maxReinvestBountyBps,
      "PancakeswapV2Worker::setTreasuryBountyBps:: _treasuryBountyBps exceeded maxReinvestBountyBps"
    );
    treasuryBountyBps = _treasuryBountyBps;

    emit SetTreasuryBountyBps(treasuryAccount, _treasuryBountyBps);
  }
}
