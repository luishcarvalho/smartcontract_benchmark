

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IStaking.sol";





contract Staking is IStaking, Ownable {
  using SafeERC20 for ERC20;
  using SafeMath for uint256;


  ERC20 public immutable token;


  uint256 public duration;


  uint256 private minDelay;


  uint256 private timeUnlock;


  mapping(address => Stake) internal stakes;


  mapping(address => address) public proposedDelegates;



  mapping(address => address) public accountDelegates;


  mapping(address => address) public delegateAccounts;


  mapping(bytes32 => bool) private usedIds;


  mapping(bytes32 => uint256) private unlockTimestamps;


  string public name;
  string public symbol;








  constructor(
    ERC20 _token,
    string memory _name,
    string memory _symbol,
    uint256 _duration,
    uint256 _minDelay
  ) {
    token = _token;
    name = _name;
    symbol = _symbol;
    duration = _duration;
    minDelay = _minDelay;
  }






  function setMetaData(string memory _name, string memory _symbol)
    external
    onlyOwner
  {
    name = _name;
    symbol = _symbol;
  }





  function scheduleDurationChange(uint256 delay) external onlyOwner {
    require(timeUnlock == 0, "TIMELOCK_ACTIVE");
    require(delay >= minDelay, "INVALID_DELAY");
    timeUnlock = block.timestamp + delay;
    emit ScheduleDurationChange(timeUnlock);
  }




  function cancelDurationChange() external onlyOwner {
    require(timeUnlock > 0, "TIMELOCK_INACTIVE");
    delete timeUnlock;
    emit CancelDurationChange();
  }





  function setDuration(uint256 _duration) external onlyOwner {
    require(_duration != 0, "DURATION_INVALID");
    require(timeUnlock > 0, "TIMELOCK_INACTIVE");
    require(block.timestamp >= timeUnlock, "TIMELOCKED");
    duration = _duration;
    delete timeUnlock;
    emit CompleteDurationChange(_duration);
  }





  function proposeDelegate(address delegate) external {
    require(accountDelegates[msg.sender] == address(0), "SENDER_HAS_DELEGATE");
    require(delegateAccounts[delegate] == address(0), "DELEGATE_IS_TAKEN");
    require(stakes[delegate].balance == 0, "DELEGATE_MUST_NOT_BE_STAKED");
    proposedDelegates[msg.sender] = delegate;
    emit ProposeDelegate(delegate, msg.sender);
  }





  function setDelegate(address account) external {
    require(proposedDelegates[account] == msg.sender, "MUST_BE_PROPOSED");
    require(delegateAccounts[msg.sender] == address(0), "DELEGATE_IS_TAKEN");
    require(stakes[msg.sender].balance == 0, "DELEGATE_MUST_NOT_BE_STAKED");
    accountDelegates[account] = msg.sender;
    delegateAccounts[msg.sender] = account;
    delete proposedDelegates[account];
    emit SetDelegate(msg.sender, account);
  }





  function unsetDelegate(address delegate) external {
    require(accountDelegates[msg.sender] == delegate, "DELEGATE_NOT_SET");
    accountDelegates[msg.sender] = address(0);
    delegateAccounts[delegate] = address(0);
  }





  function stake(uint256 amount) external override {
    if (delegateAccounts[msg.sender] != address(0)) {
      _stake(delegateAccounts[msg.sender], amount);
    } else {
      _stake(msg.sender, amount);
    }
  }





  function unstake(uint256 amount) external override {
    address account;
    delegateAccounts[msg.sender] != address(0)
      ? account = delegateAccounts[msg.sender]
      : account = msg.sender;
    _unstake(account, amount);
    token.transfer(account, amount);
    emit Transfer(account, address(0), amount);
  }





  function getStakes(address account)
    external
    view
    override
    returns (Stake memory accountStake)
  {
    return stakes[account];
  }




  function totalSupply() external view override returns (uint256) {
    return token.balanceOf(address(this));
  }




  function balanceOf(address account)
    external
    view
    override
    returns (uint256 total)
  {
    return stakes[account].balance;
  }




  function decimals() external view override returns (uint8) {
    return token.decimals();
  }






  function stakeFor(address account, uint256 amount) public override {
    _stake(account, amount);
  }





  function available(address account) public view override returns (uint256) {
    Stake storage selected = stakes[account];
    uint256 _available = (block.timestamp.sub(selected.timestamp))
      .mul(selected.balance)
      .div(selected.duration);
    if (_available >= stakes[account].balance) {
      return stakes[account].balance;
    } else {
      return _available;
    }
  }






  function _stake(address account, uint256 amount) internal {
    require(amount > 0, "AMOUNT_INVALID");
    stakes[account].duration = duration;
    if (stakes[account].balance == 0) {
      stakes[account].balance = amount;
      stakes[account].timestamp = block.timestamp;
    } else {
      uint256 nowAvailable = available(account);
      stakes[account].balance = stakes[account].balance.add(amount);
      stakes[account].timestamp = block.timestamp.sub(
        nowAvailable.mul(stakes[account].duration).div(stakes[account].balance)
      );
    }
    token.safeTransferFrom(msg.sender, address(this), amount);
    emit Transfer(address(0), account, amount);
  }






  function _unstake(address account, uint256 amount) internal {
    Stake storage selected = stakes[account];
    require(amount <= available(account), "AMOUNT_EXCEEDS_AVAILABLE");
    selected.balance = selected.balance.sub(amount);
  }
}
