pragma solidity 0.6.12;

import 'OpenZeppelin/openzeppelin-contracts@3.2.0/contracts/token/ERC1155/ERC1155.sol';
import 'OpenZeppelin/openzeppelin-contracts@3.2.0/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/openzeppelin-contracts@3.2.0/contracts/token/ERC20/SafeERC20.sol';
import 'OpenZeppelin/openzeppelin-contracts@3.2.0/contracts/utils/ReentrancyGuard.sol';

import '../utils/HomoraMath.sol';
import '../../interfaces/IERC20Wrapper.sol';
import '../../interfaces/IMasterChef.sol';

contract WMasterChef is ERC1155('WMasterChef'), ReentrancyGuard, IERC20Wrapper {
  using SafeMath for uint;
  using HomoraMath for uint;
  using SafeERC20 for IERC20;

  IMasterChef public immutable chef;
  IERC20 public immutable sushi;

  constructor(IMasterChef _chef) public {
    chef = _chef;
    sushi = IERC20(_chef.sushi());
  }




  function encodeId(uint pid, uint sushiPerShare) public pure returns (uint id) {
    require(pid < (1 << 16), 'bad pid');
    require(sushiPerShare < (1 << 240), 'bad sushi per share');
    return (pid << 240) | sushiPerShare;
  }



  function decodeId(uint id) public pure returns (uint pid, uint sushiPerShare) {
    pid = id >> 240;
    sushiPerShare = id & ((1 << 240) - 1);
  }



  function getUnderlyingToken(uint id) external view override returns (address) {
    (uint pid, ) = decodeId(id);
    (address lpToken, , , ) = chef.poolInfo(pid);
    return lpToken;
  }


  function getUnderlyingRate(uint) external view override returns (uint) {
    return 2**112;
  }





  function mint(uint pid, uint amount) external nonReentrant returns (uint) {
    (address lpToken, , , ) = chef.poolInfo(pid);
    IERC20(lpToken).safeTransferFrom(msg.sender, address(this), amount);
    if (IERC20(lpToken).allowance(address(this), address(chef)) != uint(-1)) {

      IERC20(lpToken).approve(address(chef), uint(-1));
    }
    chef.deposit(pid, amount);
    (, , , uint sushiPerShare) = chef.poolInfo(pid);
    uint id = encodeId(pid, sushiPerShare);
    _mint(msg.sender, id, amount, '');
    return id;
  }





  function burn(uint id, uint amount) external nonReentrant returns (uint) {
    if (amount == uint(-1)) {
      amount = balanceOf(msg.sender, id);
    }
    (uint pid, uint stSushiPerShare) = decodeId(id);
    _burn(msg.sender, id, amount);
    chef.withdraw(pid, amount);
    (address lpToken, , , uint enSushiPerShare) = chef.poolInfo(pid);
    IERC20(lpToken).safeTransfer(msg.sender, amount);
    uint stSushi = stSushiPerShare.mul(amount).divCeil(1e12);
    uint enSushi = enSushiPerShare.mul(amount).div(1e12);
    if (enSushi > stSushi) {
      sushi.safeTransfer(msg.sender, enSushi.sub(stSushi));
    }
    return pid;
  }





  function emergencyBurn(uint id, uint amount) external nonReentrant returns (uint) {
    (uint pid, ) = decodeId(id);
    _burn(msg.sender, id, amount);
    chef.withdraw(pid, amount);
    (address lpToken, , , ) = chef.poolInfo(pid);
    IERC20(lpToken).safeTransfer(msg.sender, amount);
    return pid;
  }
}
