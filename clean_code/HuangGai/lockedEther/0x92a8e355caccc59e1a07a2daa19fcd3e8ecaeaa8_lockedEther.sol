



pragma solidity 0.5.17;


interface DharmaTradeReserveV1Interface {
  event RoleModified(Role indexed role, address account);
  event RolePaused(Role indexed role);
  event RoleUnpaused(Role indexed role);

  enum Role {
    WITHDRAWAL_MANAGER,
    PAUSER
  }

  struct RoleStatus {
    address account;
    bool paused;
  }

  function tradeDaiForEther(
    uint256 daiAmount,
    uint256 quotedEtherAmount,
    uint256 deadline
  ) external returns (uint256 totalDaiSold);

  function tradeEtherForDai(
    uint256 quotedDaiAmount,
    uint256 deadline
  ) external payable returns (uint256 totalDaiBought);

  function withdrawEther(address payable recipient, uint256 etherAmount) external;

  function withdrawDai(address recipient, uint256 daiAmount) external;

  function withdrawDaiToPrimaryRecipient(uint256 daiAmount) external;

  function withdraw(
    ERC20Interface token, address recipient, uint256 amount
  ) external returns (bool success);

  function callAny(
    address payable target, uint256 amount, bytes calldata data
  ) external returns (bool ok, bytes memory returnData);

  function setPrimaryRecipient(address recipient) external;

  function setRole(Role role, address account) external;

  function removeRole(Role role) external;

  function pause(Role role) external;

  function unpause(Role role) external;

  function isPaused(Role role) external view returns (bool paused);

  function isRole(Role role) external view returns (bool hasRole);

  function getWithdrawalManager() external view returns (address withdrawalManager);

  function getPauser() external view returns (address pauser);

  function getReserves() external view returns (
    uint256 eth, uint256 dai
  );

  function getPrimaryRecipient() external view returns (
    address recipient
  );
}


interface ERC20Interface {
  function balanceOf(address) external view returns (uint256);
  function approve(address, uint256) external returns (bool);
  function transfer(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
}


interface UniswapV1Interface {
  function ethToTokenSwapInput(
    uint256 minTokens, uint256 deadline
  ) external payable returns (uint256 tokensBought);

  function tokenToEthTransferOutput(
    uint256 ethBought, uint256 maxTokens, uint256 deadline, address recipient
  ) external returns (uint256 tokensSold);
}














contract TwoStepOwnable {
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  address private _owner;

  address private _newPotentialOwner;





  function transferOwnership(address newOwner) external onlyOwner {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }





  function cancelOwnershipTransfer() external onlyOwner {
    delete _newPotentialOwner;
  }





  function acceptOwnership() external {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }




  function owner() external view returns (address) {
    return _owner;
  }




  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  function _initializeOwner() internal {

    assembly { if extcodesize(address) { revert(0, 0) } }


    _owner = tx.origin;
    emit OwnershipTransferred(address(0), _owner);
  }




  modifier onlyOwner() {
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }
}














contract DharmaTradeReserveV1 is DharmaTradeReserveV1Interface, TwoStepOwnable {

  mapping(uint256 => RoleStatus) private _roles;


  address private _primaryRecipient;


  ERC20Interface internal constant _DAI = ERC20Interface(
    0x6B175474E89094C44Da98b954EedeAC495271d0F
  );

  UniswapV1Interface internal constant _UNISWAP_DAI = UniswapV1Interface(
    0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667
  );





  function initialize() external {

    assembly { if extcodesize(address) { revert(0, 0) } }


    _initializeOwner();


    require(_DAI.approve(address(_UNISWAP_DAI), uint256(-1)));
  }









  function tradeDaiForEther(
    uint256 daiAmount,
    uint256 quotedEtherAmount,
    uint256 deadline
  ) external returns (uint256 totalDaiSold) {

    bool ok = (_DAI.transferFrom(msg.sender, address(this), daiAmount));
    require(ok, "Dai transfer in failed.");


    totalDaiSold = _UNISWAP_DAI.tokenToEthTransferOutput(
      quotedEtherAmount, daiAmount, deadline, msg.sender
    );
  }








  function tradeEtherForDai(
    uint256 quotedDaiAmount,
    uint256 deadline
  ) external payable returns (uint256 totalDaiBought) {

    totalDaiBought = _UNISWAP_DAI.ethToTokenSwapInput.value(msg.value)(
      quotedDaiAmount, deadline
    );


    bool ok = (_DAI.transfer(msg.sender, quotedDaiAmount));
    require(ok, "Dai transfer out failed.");
  }








  function withdrawDaiToPrimaryRecipient(
    uint256 daiAmount
  ) external onlyOwnerOr(Role.WITHDRAWAL_MANAGER) {

    address primaryRecipient = _primaryRecipient;
    require(
      primaryRecipient != address(0), "No primary recipient currently set."
    );


    bool ok = _DAI.transfer(primaryRecipient, daiAmount);
    require(ok, "Dai transfer failed.");
  }







  function withdrawEther(
    address payable recipient, uint256 etherAmount
  ) external onlyOwner {
    bool ok;


    (ok, ) = recipient.call.value(0)("");
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }







  function withdrawDai(
    address recipient, uint256 daiAmount
  ) external onlyOwner {

    require(_DAI.transfer(recipient, daiAmount), "Dai transfer failed.");
  }










  function withdraw(
    ERC20Interface token, address recipient, uint256 amount
  ) external onlyOwner returns (bool success) {

    success = token.transfer(recipient, amount);
  }










  function callAny(
    address payable target, uint256 amount, bytes calldata data
  ) external onlyOwner returns (bool ok, bytes memory returnData) {

    (ok, returnData) = target.call.value(0)(data);
  }






  function setPrimaryRecipient(address recipient) external onlyOwner {

    _primaryRecipient = recipient;
  }








  function pause(Role role) external onlyOwnerOr(Role.PAUSER) {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(!storedRoleStatus.paused, "Role in question is already paused.");
    storedRoleStatus.paused = true;
    emit RolePaused(role);
  }







  function unpause(Role role) external onlyOwner {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(storedRoleStatus.paused, "Role in question is already unpaused.");
    storedRoleStatus.paused = false;
    emit RoleUnpaused(role);
  }








  function setRole(Role role, address account) external onlyOwner {
    require(account != address(0), "Must supply an account.");
    _setRole(role, account);
  }








  function removeRole(Role role) external onlyOwner {
    _setRole(role, address(0));
  }












  function isPaused(Role role) external view returns (bool paused) {
    paused = _isPaused(role);
  }








  function isRole(Role role) external view returns (bool hasRole) {
    hasRole = _isRole(role);
  }








  function getWithdrawalManager() external view returns (address withdrawalManager) {
    withdrawalManager = _roles[uint256(Role.WITHDRAWAL_MANAGER)].account;
  }









  function getPauser() external view returns (address pauser) {
    pauser = _roles[uint256(Role.PAUSER)].account;
  }






  function getReserves() external view returns (
    uint256 eth, uint256 dai
  ) {
    eth = address(this).balance;
    dai = _DAI.balanceOf(address(this));
  }






  function getPrimaryRecipient() external view returns (
    address recipient
  ) {
    recipient = _primaryRecipient;
  }








  function _setRole(Role role, address account) internal {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];

    if (account != storedRoleStatus.account) {
      storedRoleStatus.account = account;
      emit RoleModified(role, account);
    }
  }








  function _isRole(Role role) internal view returns (bool hasRole) {
    hasRole = msg.sender == _roles[uint256(role)].account;
  }








  function _isPaused(Role role) internal view returns (bool paused) {
    paused = _roles[uint256(role)].paused;
  }








  modifier onlyOwnerOr(Role role) {
    if (!isOwner()) {
      require(_isRole(role), "Caller does not have a required role.");
      require(!_isPaused(role), "Role in question is currently paused.");
    }
    _;
  }
}
