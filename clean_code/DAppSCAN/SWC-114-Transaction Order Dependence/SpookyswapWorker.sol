
pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "../apis/IUniswapV2Router02.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/ISpookyWorker.sol";
import "../interfaces/ISpookyMasterChef.sol";
import "../../utils/SafeToken.sol";

contract SpookyswapWorker is OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe, ISpookyWorker {

  using SafeToken for address;
  using SafeMath for uint256;


  event Reinvest(address indexed caller, uint256 reward, uint256 bounty);
  event AddShare(uint256 indexed id, uint256 share);
  event RemoveShare(uint256 indexed id, uint256 share);
  event Liquidate(uint256 indexed id, uint256 wad);


  ISpookyMasterChef public override masterChef;
  IUniswapV2Factory public factory;
  IUniswapV2Router02 public router;
  IUniswapV2Pair public override lpToken;
  address public wNative;
  address public override baseToken;
  address public override farmingToken;
  address public override boo;
  address public override operator;
  uint256 public override pid;


  mapping(uint256 => uint256) public shares;
  mapping(address => bool) public okStrats;
  uint256 public totalShare;
  IStrategy public addStrat;
  IStrategy public liqStrat;
  uint256 public override reinvestBountyBps;
  uint256 public maxReinvestBountyBps;
  mapping(address => bool) public okReinvestors;


  uint256 public fee;
  uint256 public feeDenom;

  function initialize(
    address _operator,
    address _baseToken,
    ISpookyMasterChef _masterChef,
    IUniswapV2Router02 _router,
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
    factory = IUniswapV2Factory(_router.factory());

    pid = _pid;
    (address _lpToken, , , ) = masterChef.poolInfo(pid);
    lpToken = IUniswapV2Pair(_lpToken);
    address token0 = lpToken.token0();
    address token1 = lpToken.token1();
    farmingToken = token0 == baseToken ? token1 : token0;
    boo = masterChef.boo();
    addStrat = _addStrat;
    liqStrat = _liqStrat;
    okStrats[address(addStrat)] = true;
    okStrats[address(liqStrat)] = true;
    reinvestBountyBps = _reinvestBountyBps;
    maxReinvestBountyBps = 500;
    fee = 9980;
    feeDenom = 10000;

    require(
      reinvestBountyBps <= maxReinvestBountyBps,
      "SpookyswapWorker::initialize:: reinvestBountyBps exceeded maxReinvestBountyBps"
    );
    require(
      (farmingToken == lpToken.token0() || farmingToken == lpToken.token1()) &&
        (baseToken == lpToken.token0() || baseToken == lpToken.token1()),
      "SpookyswapWorker::initialize:: LP underlying not match with farm & base token"
    );
  }


  modifier onlyEOA() {
    require(msg.sender == tx.origin, "SpookyswapWorker::onlyEOA:: not eoa");
    _;
  }


  modifier onlyOperator() {
    require(msg.sender == operator, "SpookyswapWorker::onlyOperator:: not operator");
    _;
  }


  modifier onlyReinvestor() {
    require(okReinvestors[msg.sender], "SpookyswapWorker::onlyReinvestor:: not reinvestor");
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

    boo.safeApprove(address(router), uint256(-1));
    address(lpToken).safeApprove(address(masterChef), uint256(-1));

    masterChef.withdraw(pid, 0);
    uint256 reward = boo.balanceOf(address(this));
    if (reward == 0) return;

    uint256 bounty = reward.mul(reinvestBountyBps) / 10000;
    if (bounty > 0) boo.safeTransfer(msg.sender, bounty);

    address[] memory path;
    if (baseToken != boo) {
      if (baseToken == wNative) {
        path = new address[](2);
        path[0] = address(boo);
        path[1] = address(wNative);
      } else {
        path = new address[](3);
        path[0] = address(boo);
        path[1] = address(wNative);
        path[2] = address(baseToken);
      }
    }
    router.swapExactTokensForTokens(reward.sub(bounty), 0, path, address(this), now);


    baseToken.safeTransfer(address(addStrat), baseToken.myBalance());
    addStrat.execute(address(0), 0, abi.encode(0));

    masterChef.deposit(pid, lpToken.balanceOf(address(this)));

    boo.safeApprove(address(router), 0);
    address(lpToken).safeApprove(address(masterChef), 0);
    emit Reinvest(msg.sender, reward, bounty);
  }






  function work(
    uint256 id,
    address user,
    uint256 debt,
    bytes calldata data
  ) external override onlyOperator nonReentrant {

    _removeShare(id);

    (, , , , , address strat, bytes memory ext) = abi.decode(
      data,
      (uint256, uint256, uint256, uint256, uint256, address, bytes)
    );
    require(okStrats[strat], "SpookyswapWorker::work:: unapproved work strategy");
    require(
      lpToken.transfer(strat, lpToken.balanceOf(address(this))),
      "SpookyswapWorker::work:: unable to transfer lp to strat"
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
    require(rIn > 0 && rOut > 0, "SpookyswapWorker::getMktSellAmount:: bad reserve values");
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
      "SpookyswapWorker::setReinvestBountyBps:: _reinvestBountyBps exceeded maxReinvestBountyBps"
    );
    reinvestBountyBps = _reinvestBountyBps;
  }



  function setMaxReinvestBountyBps(uint256 _maxReinvestBountyBps) external onlyOwner {
    require(
      _maxReinvestBountyBps >= reinvestBountyBps,
      "SpookyswapWorker::setMaxReinvestBountyBps:: _maxReinvestBountyBps lower than reinvestBountyBps"
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
}
