







pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/token
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CryptoHeroes.sol";



contract CryptoHeroesUniverse is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
    uint256 requestAmount;
    uint256 requestBlock;












  }


  struct PoolInfo
  {
    IERC20 lpToken;
    bool NFTisNeeded;
    IERC721 acceptedNFT;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accCheroesPerShare;
  }


  CryptoHeroes public cheroes;

  address public devaddr;

  uint256 public cheroesPerBlock;

  address private devadr;


  PoolInfo[] public poolInfo;

  mapping (uint256 => mapping (address => UserInfo)) public userInfo;
  mapping (IERC20 => bool) public lpTokenIsExist;

  uint256 public totalAllocPoint = 0;


  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

  constructor(
    CryptoHeroes _cheroes,
    address _devaddr,
    uint256 _cheroesPerBlock
  ) public {
    cheroes = _cheroes;
    devaddr = _devaddr;
    cheroesPerBlock = _cheroesPerBlock;
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }



  function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate, bool _NFTisNeeded, IERC721 _acceptedNFT) public onlyOwner {
    require(lpTokenIsExist[_lpToken] == false,"This lpToken already added");
    if (_withUpdate) {
      massUpdatePools();
    }
    uint256 lastRewardBlock = block.number;
    totalAllocPoint = totalAllocPoint.add(_allocPoint);
    poolInfo.push(PoolInfo({
    lpToken: _lpToken,
    NFTisNeeded: _NFTisNeeded,
    acceptedNFT: _acceptedNFT,
    allocPoint: _allocPoint,
    lastRewardBlock: lastRewardBlock,
    accCheroesPerShare: 0
    }));
    lpTokenIsExist[_lpToken] = true;
  }


  function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
    if (_withUpdate) {
      massUpdatePools();
    }
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
    poolInfo[_pid].allocPoint = _allocPoint;
  }



  function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
    return _to.sub(_from);
  }


  function pendingCheroes(uint256 _pid, address _user) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accCheroesPerShare = pool.accCheroesPerShare;
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
      uint256 cheroesReward = multiplier.mul(cheroesPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
      accCheroesPerShare = accCheroesPerShare.add(cheroesReward.mul(1e12).div(lpSupply));
    }
    return user.amount.mul(accCheroesPerShare).div(1e12).sub(user.rewardDebt);
  }


  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }


  function dev(address _devaddr) public {
    require(msg.sender == devaddr, "dev: wut?");
    devaddr = _devaddr;
  }



  function updatePool(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 lpSupply = pool.lpToken.balanceOf(address(this));
    if (lpSupply == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
    uint256 cheroesReward = multiplier.mul(cheroesPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
    cheroes.mint(address(this), cheroesReward);
    pool.accCheroesPerShare = pool.accCheroesPerShare.add(cheroesReward.mul(1e12).div(lpSupply));
    pool.lastRewardBlock = block.number;
  }



  function deposit(uint256 _pid, uint256 _amount) public {


    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];

    updatePool(_pid);

    if(pool.NFTisNeeded == true)
    {
        require(pool.acceptedNFT.balanceOf(address(msg.sender))>0,"requires NTF token!");
    }

    if (user.amount > 0) {
      uint256 pending = user.amount.mul(pool.accCheroesPerShare).div(1e12).sub(user.rewardDebt);
      if(pending > 0) {
        safeCheroesTransfer(msg.sender, pending);
      }
    }

    if(_amount > 0) {
      pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
      user.amount = user.amount.add(_amount);
    }

    user.rewardDebt = user.amount.mul(pool.accCheroesPerShare).div(1e12);

    emit Deposit(msg.sender, _pid, _amount);
  }




  function withdraw(uint256 _pid, uint256 _amount) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    require(user.amount >= _amount, "withdraw: not good");
    updatePool(_pid);
    if(pool.NFTisNeeded == true)
    {
        require(pool.acceptedNFT.balanceOf(address(msg.sender))>0,"requires NTF token!");
    }
    uint256 pending = user.amount.mul(pool.accCheroesPerShare).div(1e12).sub(user.rewardDebt);
    if(pending > 0) {
        safeCheroesTransfer(msg.sender, pending);
    }
    if(_amount > 0) {
        user.amount = user.amount.sub(_amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
    }
    user.rewardDebt = user.amount.mul(pool.accCheroesPerShare).div(1e12);
    emit Withdraw(msg.sender, _pid, _amount);

  }



  function safeCheroesTransfer(address _to, uint256 _amount) internal {
    uint256 cheroesBal = cheroes.balanceOf(address(this));
    if (_amount > cheroesBal) {
      cheroes.transfer(_to, cheroesBal);
    } else {
      cheroes.transfer(_to, _amount);
    }
  }


    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }


    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

  function setCheroesPerBlock(uint256 _cheroesPerBlock) public onlyOwner {
    require(_cheroesPerBlock > 0, "!CheroesPerBlock-0");
    cheroesPerBlock = _cheroesPerBlock;
  }

}
