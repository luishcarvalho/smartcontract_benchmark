













pragma solidity 0.6.6;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

import "../../interfaces/ISwapFactoryLike.sol";
import "../../interfaces/ISwapPairLike.sol";
import "../../interfaces/ISwapRouter02Like.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IWNativeRelayer.sol";
import "../../interfaces/IWorker03.sol";

import "../../../utils/SafeToken.sol";

contract SpookySwapStrategyWithdrawMinimizeTrading is OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe, IStrategy {
  using SafeToken for address;
  using SafeMath for uint256;

  event LogSetWorkerOk(address[] indexed workers, bool isOk);

  ISwapFactoryLike public factory;
  ISwapRouter02Like public router;
  address public wftm;
  IWNativeRelayer public wNativeRelayer;

  mapping(address => bool) public okWorkers;


  modifier onlyWhitelistedWorkers() {
    require(okWorkers[msg.sender], "bad worker");
    _;
  }




  function initialize(ISwapRouter02Like _router, IWNativeRelayer _wNativeRelayer) external initializer {
    OwnableUpgradeSafe.__Ownable_init();
    ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();
    factory = ISwapFactoryLike(_router.factory());
    router = _router;
    wftm = _router.WETH();
    wNativeRelayer = _wNativeRelayer;
  }






  function execute(
    address user,
    uint256 debt,
    bytes calldata data
  ) external override onlyWhitelistedWorkers nonReentrant {

    uint256 minFarmingToken = abi.decode(data, (uint256));
    IWorker03 worker = IWorker03(msg.sender);
    address baseToken = worker.baseToken();
    address farmingToken = worker.farmingToken();
    ISwapPairLike lpToken = worker.lpToken();

    address(lpToken).safeApprove(address(router), uint256(-1));
    farmingToken.safeApprove(address(router), uint256(-1));

    router.removeLiquidity(baseToken, farmingToken, lpToken.balanceOf(address(this)), 0, 0, address(this), now);

    address[] memory path = new address[](2);
    path[0] = farmingToken;
    path[1] = baseToken;
    uint256 balance = baseToken.myBalance();
    if (debt > balance) {

      uint256 remainingDebt = debt.sub(balance);
      router.swapTokensForExactTokens(remainingDebt, farmingToken.myBalance(), path, address(this), now);
    }

    uint256 remainingBalance = baseToken.myBalance();
    baseToken.safeTransfer(msg.sender, remainingBalance);

    uint256 remainingFarmingToken = farmingToken.myBalance();
    require(remainingFarmingToken >= minFarmingToken, "insufficient farming tokens received");
    if (remainingFarmingToken > 0) {
      if (farmingToken == address(wftm)) {
        SafeToken.safeTransfer(farmingToken, address(wNativeRelayer), remainingFarmingToken);
        wNativeRelayer.withdraw(remainingFarmingToken);
        SafeToken.safeTransferETH(user, remainingFarmingToken);
      } else {
        SafeToken.safeTransfer(farmingToken, user, remainingFarmingToken);
      }
    }

    address(lpToken).safeApprove(address(router), 0);
    farmingToken.safeApprove(address(router), 0);
  }

  function setWorkersOk(address[] calldata workers, bool isOk) external onlyOwner {
    for (uint256 idx = 0; idx < workers.length; idx++) {
      okWorkers[workers[idx]] = isOk;
    }
    emit LogSetWorkerOk(workers, isOk);
  }

  receive() external payable {}
}
