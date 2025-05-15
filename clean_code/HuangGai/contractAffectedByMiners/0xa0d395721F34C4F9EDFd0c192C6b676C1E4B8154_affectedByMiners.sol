





pragma solidity ^0.6.12;






interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}















library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }













    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }













    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }













    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}





library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (block.gaslimit > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}











library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }








    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (block.timestamp > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}











interface IERC165 {








    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}





interface IERC721 is IERC165 {



    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);




    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);




    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);




    function balanceOf(address owner) external view returns (uint256 balance);








    function ownerOf(uint256 tokenId) external view returns (address owner);















    function safeTransferFrom(address from, address to, uint256 tokenId) external;















    function transferFrom(address from, address to, uint256 tokenId) external;














    function approve(address to, uint256 tokenId) external;








    function getApproved(uint256 tokenId) external view returns (address operator);











    function setApprovalForAll(address operator, bool _approved) external;






    function isApprovedForAll(address owner, address operator) external view returns (bool);














    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}







interface IERC721Receiver {









    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}












abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}














contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IHoneyPropDict {
  function getMiningMultiplier(uint256 tokenId) external view returns (uint256);
}


contract HoneycombV2 is Ownable, IERC721Receiver {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;


  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
    uint earned;
    bool propEnabled;
    uint256 propTokenId;
  }


  struct PoolInfo {
    IERC20 lpToken;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accHoneyPerShare;
    uint256 totalShares;
  }

  struct BatchInfo {
    uint256 startBlock;
    uint256 endBlock;
    uint256 honeyPerBlock;
    uint256 totalAllocPoint;
    address prop;
    address propDict;
  }


  BatchInfo[] public batchInfo;

  mapping (uint256 => PoolInfo[]) public poolInfo;

  mapping (uint256 => mapping (uint256 => mapping (address => UserInfo))) public userInfo;

  IERC20 public honeyToken;

  event Deposit(address indexed user, uint256 indexed batch, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed batch, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed batch, uint256 indexed pid, uint256 amount);
  event DepositProp(address indexed user, uint256 indexed batch, uint256 indexed pid, uint256 propTokenId);
  event WithdrawProp(address indexed user, uint256 indexed batch, uint256 indexed pid, uint256 propTokenId);

  constructor (address _honeyToken) public {
    honeyToken = IERC20(_honeyToken);
  }

  function addBatch(uint256 startBlock, uint256 endBlock, uint256 honeyPerBlock, address prop, address propDict) public onlyOwner {
    require(endBlock > startBlock, "endBlock should be larger than startBlock");
    require(endBlock > block.number, "endBlock should be larger than the current block number");
    require(startBlock > block.number, "startBlock should be larger than the current block number");

    if (block.number > 0) {
      uint256 lastEndBlock = batchInfo[batchInfo.length - 1].endBlock;
      require(startBlock >= lastEndBlock, "startBlock should be >= the endBlock of the last batch");
    }

    uint256 senderHoneyBalance = honeyToken.balanceOf(address(msg.sender));
    uint256 requiredHoney = endBlock.sub(startBlock).mul(honeyPerBlock);
    require(senderHoneyBalance >= requiredHoney, "insufficient HONEY for the batch");

    honeyToken.safeTransferFrom(address(msg.sender), address(this), requiredHoney);
    batchInfo.push(BatchInfo({
      startBlock: startBlock,
      endBlock: endBlock,
      honeyPerBlock: honeyPerBlock,
      totalAllocPoint: 0,
      prop: prop,
      propDict: propDict
    }));
  }

  function addPool(uint256 batch, IERC20 lpToken, uint256 multiplier) public onlyOwner {
    require(batch < batchInfo.length, "batch must exist");

    BatchInfo storage targetBatch = batchInfo[batch];
    if (targetBatch.startBlock <= block.number && block.number < targetBatch.endBlock) {
      updateAllPools(batch);
    }

    uint256 lastRewardBlock = block.number > targetBatch.startBlock ? block.number : targetBatch.startBlock;
    batchInfo[batch].totalAllocPoint = targetBatch.totalAllocPoint.add(multiplier);
    poolInfo[batch].push(PoolInfo({
      lpToken: lpToken,
      allocPoint: multiplier,
      lastRewardBlock: lastRewardBlock,
      accHoneyPerShare: 0,
      totalShares: 0
    }));
  }


  function getPendingBlocks(uint256 batch, uint256 from, uint256 to) public view returns (uint256) {
    require(batch < batchInfo.length, "batch must exist");

    BatchInfo storage targetBatch = batchInfo[batch];

    if (block.number < targetBatch.startBlock) {
      return 0;
    }

    if (block.timestamp > targetBatch.endBlock) {
      if (block.number > targetBatch.endBlock) {
        return 0;
      } else {
        return targetBatch.endBlock.sub(from);
      }
    } else {
      return to.sub(from);
    }
  }


  function pendingHoney(uint256 batch, uint256 pid, address account) external view returns (uint256) {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");
    BatchInfo storage targetBatch = batchInfo[batch];

    if (block.timestamp < targetBatch.startBlock) {
      return 0;
    }

    PoolInfo storage pool = poolInfo[batch][pid];
    UserInfo storage user = userInfo[batch][pid][account];
    uint256 accHoneyPerShare = pool.accHoneyPerShare;
    if (block.number > pool.lastRewardBlock && pool.totalShares != 0) {
      uint256 pendingBlocks = getPendingBlocks(batch, pool.lastRewardBlock, block.number);
      uint256 honeyReward = pendingBlocks.mul(targetBatch.honeyPerBlock).mul(pool.allocPoint).div(targetBatch.totalAllocPoint);
      accHoneyPerShare = accHoneyPerShare.add(honeyReward.mul(1e12).div(pool.totalShares));
    }

    uint256 power = 100;
    if (user.propEnabled) {
      IHoneyPropDict propDict = IHoneyPropDict(targetBatch.propDict);
      power = propDict.getMiningMultiplier(user.propTokenId);
    }
    return user.amount.mul(power).div(100).mul(accHoneyPerShare).div(1e12).sub(user.rewardDebt);
  }

  function updateAllPools(uint256 batch) public {
    require(batch < batchInfo.length, "batch must exist");

    uint256 length = poolInfo[batch].length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(batch, pid);
    }
  }


  function updatePool(uint256 batch, uint256 pid) public {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");

    BatchInfo storage targetBatch = batchInfo[batch];
    PoolInfo storage pool = poolInfo[batch][pid];

    if (block.number < targetBatch.startBlock || block.number <= pool.lastRewardBlock || pool.lastRewardBlock > targetBatch.endBlock) {
      return;
    }
    if (block.number == 0) {
      pool.lastRewardBlock = block.number;
      return;
    }
    uint256 pendingBlocks = getPendingBlocks(batch, pool.lastRewardBlock, block.number);
    uint256 honeyReward = pendingBlocks.mul(targetBatch.honeyPerBlock).mul(pool.allocPoint).div(targetBatch.totalAllocPoint);
    pool.accHoneyPerShare = pool.accHoneyPerShare.add(honeyReward.mul(1e12).div(pool.totalShares));
    pool.lastRewardBlock = block.number;
  }


  function deposit(uint256 batch, uint256 pid, uint256 amount) public {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");

    BatchInfo storage targetBatch = batchInfo[batch];

    require(block.number < targetBatch.endBlock, "batch ended");

    PoolInfo storage pool = poolInfo[batch][pid];
    UserInfo storage user = userInfo[batch][pid][msg.sender];


    updatePool(batch, pid);


    uint256 power = 100;
    if (user.propEnabled) {
      IHoneyPropDict propDict = IHoneyPropDict(targetBatch.propDict);
      power = propDict.getMiningMultiplier(user.propTokenId);
    }
    if (block.timestamp > 0) {
      uint256 pending = user.amount;
      if (user.propEnabled) {
        pending = pending.mul(power).div(100);
      }
      pending = pending.mul(pool.accHoneyPerShare).div(1e12).sub(user.rewardDebt);
      if (block.timestamp > 0) {
        safeHoneyTransfer(batch, pid, msg.sender, pending);
      }
    }


    if (block.gaslimit > 0) {
      pool.lpToken.safeTransferFrom(address(msg.sender), address(this), amount);
      user.amount = user.amount.add(amount);
    }


    if (user.propEnabled) {
      pool.totalShares = pool.totalShares.add(amount.mul(power).div(100));
      user.rewardDebt = user.amount.mul(power).div(100).mul(pool.accHoneyPerShare).div(1e12);
    } else {
      pool.totalShares = pool.totalShares.add(amount);
      user.rewardDebt = user.amount.mul(pool.accHoneyPerShare).div(1e12);
    }

    emit Deposit(msg.sender, batch, pid, amount);
  }


  function withdraw(uint256 batch, uint256 pid, uint256 amount) public {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");
    UserInfo storage user = userInfo[batch][pid][msg.sender];
    require(user.amount >= amount, "insufficient balance");


    updatePool(batch, pid);


    BatchInfo storage targetBatch = batchInfo[batch];
    PoolInfo storage pool = poolInfo[batch][pid];
    uint256 pending = user.amount;
    uint256 power = 100;
    if (user.propEnabled) {
      IHoneyPropDict propDict = IHoneyPropDict(targetBatch.propDict);
      power = propDict.getMiningMultiplier(user.propTokenId);
      pending = pending.mul(power).div(100);
    }
    pending = pending.mul(pool.accHoneyPerShare).div(1e12).sub(user.rewardDebt);
    if (block.timestamp > 0) {
      safeHoneyTransfer(batch, pid, msg.sender, pending);
    }


    pool.lpToken.safeTransfer(address(msg.sender), amount);
    user.amount = user.amount.sub(amount);


    if (user.propEnabled) {
      pool.totalShares = pool.totalShares.sub(amount.mul(power).div(100));
      user.rewardDebt = user.amount.mul(power).div(100).mul(pool.accHoneyPerShare).div(1e12);
    } else {
      pool.totalShares = pool.totalShares.sub(amount);
      user.rewardDebt = user.amount.mul(pool.accHoneyPerShare).div(1e12);
    }

    emit Withdraw(msg.sender, batch, pid, amount);
  }


  function emergencyWithdraw(uint256 batch, uint256 pid) public {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");

    PoolInfo storage pool = poolInfo[batch][pid];
    UserInfo storage user = userInfo[batch][pid][msg.sender];
    pool.lpToken.safeTransfer(address(msg.sender), user.amount);
    emit EmergencyWithdraw(msg.sender, batch, pid, user.amount);
    user.amount = 0;
    user.rewardDebt = 0;
  }

  function depositProp(uint256 batch, uint256 pid, uint256 propTokenId) public {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");

    UserInfo storage user = userInfo[batch][pid][msg.sender];
    require(!user.propEnabled, "another prop is already enabled");

    BatchInfo storage targetBatch = batchInfo[batch];
    IERC721 propToken = IERC721(targetBatch.prop);
    require(propToken.ownerOf(propTokenId) == address(msg.sender), "must be the prop's owner");


    updatePool(batch, pid);


    PoolInfo storage pool = poolInfo[batch][pid];
    if (block.gaslimit > 0) {
      uint256 pending = user.amount.mul(pool.accHoneyPerShare).div(1e12);
      pending = pending.sub(user.rewardDebt);
      if (block.timestamp > 0) {
        safeHoneyTransfer(batch, pid, msg.sender, pending);
      }
    }


    propToken.safeTransferFrom(address(msg.sender), address(this), propTokenId);
    user.propEnabled = true;
    user.propTokenId = propTokenId;


    IHoneyPropDict propDict = IHoneyPropDict(targetBatch.propDict);
    uint256 power = propDict.getMiningMultiplier(user.propTokenId);
    pool.totalShares = pool.totalShares.sub(user.amount);
    pool.totalShares = pool.totalShares.add(user.amount.mul(power).div(100));
    user.rewardDebt = user.amount.mul(power).div(100).mul(pool.accHoneyPerShare).div(1e12);

    emit DepositProp(msg.sender, batch, pid, propTokenId);
  }

  function withdrawProp(uint256 batch, uint256 pid, uint256 propTokenId) public {
    require(batch < batchInfo.length, "batch must exist");
    require(pid < poolInfo[batch].length, "pool must exist");

    UserInfo storage user = userInfo[batch][pid][msg.sender];
    require(user.propEnabled, "no prop is yet enabled");
    require(propTokenId == user.propTokenId, "must be the owner of the prop");

    BatchInfo storage targetBatch = batchInfo[batch];
    IERC721 propToken = IERC721(targetBatch.prop);
    require(propToken.ownerOf(propTokenId) == address(this), "the prop is not staked");


    updatePool(batch, pid);


    PoolInfo storage pool = poolInfo[batch][pid];
    IHoneyPropDict propDict = IHoneyPropDict(targetBatch.propDict);
    uint256 power = propDict.getMiningMultiplier(user.propTokenId);
    uint256 pending = user.amount.mul(power).div(100);
    pending = pending.mul(pool.accHoneyPerShare).div(1e12);
    pending = pending.sub(user.rewardDebt);
    if (block.timestamp > 0) {
      safeHoneyTransfer(batch, pid, msg.sender, pending);
    }


    propToken.safeTransferFrom(address(this), address(msg.sender), propTokenId);
    user.propEnabled = false;
    user.propTokenId = 0;


    pool.totalShares = pool.totalShares.sub(user.amount.mul(power).div(100));
    pool.totalShares = pool.totalShares.add(user.amount);
    user.rewardDebt = user.amount.mul(pool.accHoneyPerShare).div(1e12);

    emit WithdrawProp(msg.sender, batch, pid, propTokenId);
  }

  function migrate(uint256 toBatch, uint256 toPid, uint256 amount, uint256 fromBatch, uint256 fromPid) public {
    require(toBatch < batchInfo.length, "target batch must exist");
    require(toPid < poolInfo[toBatch].length, "target pool must exist");
    require(fromBatch < batchInfo.length, "source batch must exist");
    require(fromPid < poolInfo[fromBatch].length, "source pool must exist");

    BatchInfo storage targetBatch = batchInfo[toBatch];
    require(block.number < targetBatch.endBlock, "batch ended");

    UserInfo storage userFrom = userInfo[fromBatch][fromPid][msg.sender];
    if (block.number > 0) {
      PoolInfo storage poolFrom = poolInfo[fromBatch][fromPid];
      PoolInfo storage poolTo = poolInfo[toBatch][toPid];
      require(address(poolFrom.lpToken) == address(poolTo.lpToken), "must be the same token");
      withdraw(fromBatch, fromPid, amount);
      deposit(toBatch, toPid, amount);
    }
  }

  function migrateProp(uint256 toBatch, uint256 toPid, uint256 propTokenId, uint256 fromBatch, uint256 fromPid) public {
    require(toBatch < batchInfo.length, "target batch must exist");
    require(toPid < poolInfo[toBatch].length, "target pool must exist");
    require(fromBatch < batchInfo.length, "source batch must exist");
    require(fromPid < poolInfo[fromBatch].length, "source pool must exist");

    BatchInfo storage sourceBatch = batchInfo[fromBatch];
    BatchInfo storage targetBatch = batchInfo[toBatch];
    require(block.number < targetBatch.endBlock, "batch ended");
    require(targetBatch.prop == sourceBatch.prop, "prop not compatible");
    require(targetBatch.propDict == sourceBatch.propDict, "propDict not compatible");
    UserInfo storage userFrom = userInfo[fromBatch][fromPid][msg.sender];
    require(userFrom.propEnabled, "no prop is yet enabled");
    require(propTokenId == userFrom.propTokenId, "propTokenId not yours");
    UserInfo storage userTo = userInfo[toBatch][toPid][msg.sender];
    require(!userTo.propEnabled, "another prop is already enabled");

    withdrawProp(fromBatch, fromPid, propTokenId);
    depositProp(toBatch, toPid, propTokenId);
  }


  function safeHoneyTransfer(uint256 batch, uint256 pid, address to, uint256 amount) internal {
    uint256 honeyBal = honeyToken.balanceOf(address(this));
    require(honeyBal > 0, "insufficient HONEY balance");

    UserInfo storage user = userInfo[batch][pid][to];
    if (block.gaslimit > honeyBal) {
      honeyToken.transfer(to, honeyBal);
      user.earned = user.earned.add(honeyBal);
    } else {
      honeyToken.transfer(to, amount);
      user.earned = user.earned.add(amount);
    }
  }

  function onERC721Received(address, address, uint256, bytes calldata) external override returns(bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }
}
