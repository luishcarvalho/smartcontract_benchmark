

















pragma solidity 0.5.12;

import "@openzeppelin/contracts/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol";
import "./compound/ICErc20.sol";
import "./DrawManager.sol";
import "fixidity/contracts/FixidityLib.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";






















contract BasePool is Initializable, ReentrancyGuard {
  using DrawManager for DrawManager.State;
  using SafeMath for uint256;
  using Roles for Roles.Role;

  bytes32 private constant ROLLED_OVER_ENTROPY_MAGIC_NUMBER = bytes32(uint256(1));






  event Deposited(address indexed sender, uint256 amount);






  event DepositedAndCommitted(address indexed sender, uint256 amount);






  event SponsorshipDeposited(address indexed sender, uint256 amount);





  event AdminAdded(address indexed admin);





  event AdminRemoved(address indexed admin);






  event Withdrawn(address indexed sender, uint256 amount);








  event Opened(
    uint256 indexed drawId,
    address indexed feeBeneficiary,
    bytes32 secretHash,
    uint256 feeFraction
  );





  event Committed(
    uint256 indexed drawId
  );









  event Rewarded(
    uint256 indexed drawId,
    address indexed winner,
    bytes32 entropy,
    uint256 winnings,
    uint256 fee
  );





  event NextFeeFractionChanged(uint256 feeFraction);





  event NextFeeBeneficiaryChanged(address indexed feeBeneficiary);




  event Paused(address indexed sender);




  event Unpaused(address indexed sender);




  event RolledOver(uint256 indexed drawId);

  struct Draw {
    uint256 feeFraction;
    address feeBeneficiary;
    uint256 openedBlock;
    bytes32 secretHash;
    bytes32 entropy;
    address winner;
    uint256 netWinnings;
    uint256 fee;
  }




  ICErc20 public cToken;




  address public nextFeeBeneficiary;




  uint256 public nextFeeFraction;




  uint256 public accountedBalance;




  mapping (address => uint256) balances;




  mapping(uint256 => Draw) draws;




  DrawManager.State drawState;




  Roles.Role admins;




  bool public paused;








  function init (
    address _owner,
    address _cToken,
    uint256 _feeFraction,
    address _feeBeneficiary
  ) public initializer {
    require(_owner != address(0), "owner cannot be the null address");
    require(_cToken != address(0), "money market address is zero");
    cToken = ICErc20(_cToken);
    _addAdmin(_owner);
    _setNextFeeFraction(_feeFraction);
    _setNextFeeBeneficiary(_feeBeneficiary);
  }





  function open(bytes32 _secretHash) internal {
    drawState.openNextDraw();
    draws[drawState.openDrawIndex] = Draw(
      nextFeeFraction,
      nextFeeBeneficiary,
      block.number,
      _secretHash,
      bytes32(0),
      address(0),
      uint256(0),
      uint256(0)
    );
    emit Opened(
      drawState.openDrawIndex,
      nextFeeBeneficiary,
      _secretHash,
      nextFeeFraction
    );
  }




  function emitCommitted() internal {
    uint256 drawId = currentOpenDrawId();
    emit Committed(drawId);
  }








  function openNextDraw(bytes32 nextSecretHash) public onlyAdmin {
    if (currentCommittedDrawId() > 0) {
      require(currentCommittedDrawHasBeenRewarded(), "the current committed draw has not been rewarded");
    }
    if (currentOpenDrawId() != 0) {
      emitCommitted();
    }
    open(nextSecretHash);
  }






  function rolloverAndOpenNextDraw(bytes32 nextSecretHash) public onlyAdmin {
    rollover();
    openNextDraw(nextSecretHash);
  }









  function rewardAndOpenNextDraw(bytes32 nextSecretHash, bytes32 lastSecret, bytes32 _salt) public onlyAdmin {
    reward(lastSecret, _salt);
    openNextDraw(nextSecretHash);
  }












  function reward(bytes32 _secret, bytes32 _salt) public onlyAdmin requireCommittedNoReward nonReentrant {


    uint256 drawId = currentCommittedDrawId();

    Draw storage draw = draws[drawId];

    require(draw.secretHash == keccak256(abi.encodePacked(_secret, _salt)), "secret does not match");


    bytes32 entropy = keccak256(abi.encodePacked(_secret));


    address winningAddress = calculateWinner(entropy);


    uint256 underlyingBalance = balance();
    uint256 grossWinnings = underlyingBalance.sub(accountedBalance);


    uint256 fee = calculateFee(draw.feeFraction, grossWinnings);


    balances[draw.feeBeneficiary] = balances[draw.feeBeneficiary].add(fee);


    uint256 netWinnings = grossWinnings.sub(fee);

    draw.winner = winningAddress;
    draw.netWinnings = netWinnings;
    draw.fee = fee;
    draw.entropy = entropy;


    if (winningAddress != address(0) && netWinnings != 0) {

      accountedBalance = underlyingBalance;

      awardWinnings(winningAddress, netWinnings);
    } else {

      accountedBalance = accountedBalance.add(fee);
    }

    emit Rewarded(
      drawId,
      winningAddress,
      entropy,
      netWinnings,
      fee
    );
  }

  function awardWinnings(address winner, uint256 amount) internal {

    balances[winner] = balances[winner].add(amount);


    drawState.deposit(winner, amount);
  }





  function rollover() public onlyAdmin requireCommittedNoReward {
    uint256 drawId = currentCommittedDrawId();

    Draw storage draw = draws[drawId];
    draw.entropy = ROLLED_OVER_ENTROPY_MAGIC_NUMBER;

    emit RolledOver(
      drawId
    );

    emit Rewarded(
      drawId,
      address(0),
      ROLLED_OVER_ENTROPY_MAGIC_NUMBER,
      0,
      0
    );
  }






  function calculateFee(uint256 _feeFraction, uint256 _grossWinnings) internal pure returns (uint256) {

    int256 grossWinningsFixed = FixidityLib.newFixed(int256(_grossWinnings));
    int256 feeFixed = FixidityLib.multiply(grossWinningsFixed, FixidityLib.newFixed(int256(_feeFraction), uint8(18)));
    return uint256(FixidityLib.fromFixed(feeFixed));
  }







  function depositSponsorship(uint256 _amount) public unlessPaused nonReentrant {

    require(token().transferFrom(msg.sender, address(this), _amount), "token transfer failed");


    _depositSponsorshipFrom(msg.sender, _amount);
  }





  function transferBalanceToSponsorship() public {

    _depositSponsorshipFrom(address(this), token().balanceOf(address(this)));
  }







  function depositPool(uint256 _amount) public requireOpenDraw unlessPaused nonReentrant {

    require(token().transferFrom(msg.sender, address(this), _amount), "token transfer failed");


    _depositPoolFrom(msg.sender, _amount);
  }

  function _depositSponsorshipFrom(address _spender, uint256 _amount) internal {

    _depositFrom(_spender, _amount);

    emit SponsorshipDeposited(_spender, _amount);
  }

  function _depositPoolFrom(address _spender, uint256 _amount) internal {

    drawState.deposit(_spender, _amount);

    _depositFrom(_spender, _amount);

    emit Deposited(_spender, _amount);
  }

  function _depositPoolFromCommitted(address _spender, uint256 _amount) internal {

    drawState.depositCommitted(_spender, _amount);

    _depositFrom(_spender, _amount);

    emit DepositedAndCommitted(_spender, _amount);
  }

  function _depositFrom(address _spender, uint256 _amount) internal {

    balances[_spender] = balances[_spender].add(_amount);


    accountedBalance = accountedBalance.add(_amount);


    require(token().approve(address(cToken), _amount), "could not approve money market spend");
    require(cToken.mint(_amount) == 0, "could not supply money market");
  }




  function withdraw() public nonReentrant {
    uint balance = balances[msg.sender];


    drawState.withdraw(msg.sender);

    _withdraw(msg.sender, balance);
  }




  function _withdraw(address _sender, uint256 _amount) internal {
    uint balance = balances[_sender];

    require(_amount <= balance, "not enough funds");


    balances[_sender] = balance.sub(_amount);


    accountedBalance = accountedBalance.sub(_amount);


    require(cToken.redeemUnderlying(_amount) == 0, "could not redeem from compound");
    require(token().transfer(_sender, _amount), "could not transfer winnings");

    emit Withdrawn(_sender, _amount);
  }





  function currentOpenDrawId() public view returns (uint256) {
    return drawState.openDrawIndex;
  }





  function currentCommittedDrawId() public view returns (uint256) {
    if (drawState.openDrawIndex > 1) {
      return drawState.openDrawIndex - 1;
    } else {
      return 0;
    }
  }





  function currentCommittedDrawHasBeenRewarded() internal view returns (bool) {
    Draw storage draw = draws[currentCommittedDrawId()];
    return draw.entropy != bytes32(0);
  }










  function getDraw(uint256 _drawId) public view returns (
    uint256 feeFraction,
    address feeBeneficiary,
    uint256 openedBlock,
    bytes32 secretHash,
    bytes32 entropy,
    address winner,
    uint256 netWinnings,
    uint256 fee
  ) {
    Draw storage draw = draws[_drawId];
    feeFraction = draw.feeFraction;
    feeBeneficiary = draw.feeBeneficiary;
    openedBlock = draw.openedBlock;
    secretHash = draw.secretHash;
    entropy = draw.entropy;
    winner = draw.winner;
    netWinnings = draw.netWinnings;
    fee = draw.fee;
  }






  function committedBalanceOf(address _addr) external view returns (uint256) {
    return drawState.committedBalanceOf(_addr);
  }






  function openBalanceOf(address _addr) external view returns (uint256) {
    return drawState.openBalanceOf(_addr);
  }






  function totalBalanceOf(address _addr) external view returns (uint256) {
    return balances[_addr];
  }






  function balanceOf(address _addr) external view returns (uint256) {
    return drawState.committedBalanceOf(_addr);
  }






  function calculateWinner(bytes32 _entropy) public view returns (address) {
    return drawState.drawWithEntropy(_entropy);
  }





  function committedSupply() public view returns (uint256) {
    return drawState.committedSupply();
  }





  function openSupply() public view returns (uint256) {
    return drawState.openSupply();
  }






  function estimatedInterestRate(uint256 _blocks) public view returns (uint256) {
    return supplyRatePerBlock().mul(_blocks);
  }





  function supplyRatePerBlock() public view returns (uint256) {
    return cToken.supplyRatePerBlock();
  }








  function setNextFeeFraction(uint256 _feeFraction) public onlyAdmin {
    _setNextFeeFraction(_feeFraction);
  }

  function _setNextFeeFraction(uint256 _feeFraction) internal {
    require(_feeFraction <= 1 ether, "fee fraction must be 1 or less");
    nextFeeFraction = _feeFraction;

    emit NextFeeFractionChanged(_feeFraction);
  }






  function setNextFeeBeneficiary(address _feeBeneficiary) public onlyAdmin {
    _setNextFeeBeneficiary(_feeBeneficiary);
  }

  function _setNextFeeBeneficiary(address _feeBeneficiary) internal {
    require(_feeBeneficiary != address(0), "beneficiary should not be 0x0");
    nextFeeBeneficiary = _feeBeneficiary;

    emit NextFeeBeneficiaryChanged(_feeBeneficiary);
  }







  function addAdmin(address _admin) public onlyAdmin {
    _addAdmin(_admin);
  }






  function isAdmin(address _admin) public view returns (bool) {
    return admins.has(_admin);
  }

  function _addAdmin(address _admin) internal {
    admins.add(_admin);

    emit AdminAdded(_admin);
  }







  function removeAdmin(address _admin) public onlyAdmin {
    require(admins.has(_admin), "admin does not exist");
    require(_admin != msg.sender, "cannot remove yourself");
    admins.remove(_admin);

    emit AdminRemoved(_admin);
  }

  modifier requireCommittedNoReward() {
    require(currentCommittedDrawId() > 0, "must be a committed draw");
    require(!currentCommittedDrawHasBeenRewarded(), "the committed draw has already been rewarded");
    _;
  }





  function token() public view returns (IERC20) {
    return IERC20(cToken.underlying());
  }





  function balance() public returns (uint256) {
    return cToken.balanceOfUnderlying(address(this));
  }

  function pause() public unlessPaused onlyAdmin {
    paused = true;

    emit Paused(msg.sender);
  }

  function unpause() public whenPaused onlyAdmin {
    paused = false;

    emit Unpaused(msg.sender);
  }

  modifier onlyAdmin() {
    require(admins.has(msg.sender), "must be an admin");
    _;
  }

  modifier requireOpenDraw() {
    require(currentOpenDrawId() != 0, "there is no open draw");
    _;
  }

  modifier whenPaused() {
    require(paused, "contract is not paused");
    _;
  }

  modifier unlessPaused() {
    require(!paused, "contract is paused");
    _;
  }
}
