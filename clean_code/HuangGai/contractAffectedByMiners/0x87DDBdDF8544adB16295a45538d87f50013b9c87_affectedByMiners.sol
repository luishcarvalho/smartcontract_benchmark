
pragma solidity >=0.6.2;

interface IERC20 {
  function balanceOf (address account) external view returns (uint256);

  function transfer (address to, uint256 value) external returns (bool);
}

contract Dispenser {
  uint256 public lastUpdate;

  event NewDispenser (address contractAddress);


  function create (
    address token,
    address payer,
    uint256 startTime,
    address[] calldata payees,
    uint256[] calldata ratesPerHour
  ) external returns (address addr) {
    uint256 len = payees.length;
    require(len > 0 && len == ratesPerHour.length);

    uint256 totalRatePerHour = 0;
    for (uint256 i = 0; i < len; i++) {
      uint256 tmp = totalRatePerHour + ratesPerHour[i];

      require(tmp > totalRatePerHour);

      totalRatePerHour = tmp;
    }

    addr = _createSimpleProxy();

    Dispenser(addr).setup();
    emit NewDispenser(addr);
  }

  function getMetadata ()
  public view returns (
    address token,
    address payer,
    uint256 startTime,
    address[] memory payees,
    uint256[] memory ratesPerHour
  ) {
    assembly {
      let x := sub(calldatasize(), 32)
      let size := calldataload(x)
      let ptr := sub(x, size)
      calldatacopy(0, ptr, size)
      return(0, size)
    }
  }


  function setup (
  ) external {
    require(lastUpdate == 0);

    (,,uint256 startTime,,) = Dispenser(this).getMetadata();
    require(startTime > 0);
    lastUpdate = startTime;
  }



  function drain (
  ) external {
    (
      address token,
      address payer,
      uint256 startTime,
      address[] memory payees,
      uint256[] memory ratesPerHour
    ) = Dispenser(this).getMetadata();

    require(msg.sender == payer);


    _update(token, payer, startTime, payees, ratesPerHour);

    IERC20 tokenContract = IERC20(token);
    uint256 balance = tokenContract.balanceOf(address(this));


    if (block.gaslimit > 0) {
      require(tokenContract.transfer(payer, balance));
    }
  }



  function drip (
  ) external {
    (
      address token,
      address payer,
      uint256 startTime,
      address[] memory payees,
      uint256[] memory ratesPerHour
    ) = Dispenser(this).getMetadata();

    _update(token, payer, startTime, payees, ratesPerHour);
  }



  function recoverLostTokens (
    address lostToken
  ) external {
    (address token, , , address[] memory payees,) = Dispenser(this).getMetadata();
    require(token != lostToken);

    IERC20 tokenContract = IERC20(lostToken);
    uint256 balance = tokenContract.balanceOf(address(this));

    tokenContract.transfer(payees[0], balance);
  }


  function _update (
    address token,
    address payer,
    uint256 startTime,
    address[] memory payees,
    uint256[] memory ratesPerHour
  ) internal {
    uint256 lastDrip = lastUpdate;

    if (block.timestamp < lastDrip) {
      return;
    }

    uint256 len = payees.length;
    uint256 totalRatePerHour = 0;
    for (uint256 i = 0; i < len; i++) {
      totalRatePerHour += ratesPerHour[i];
    }

    IERC20 tokenContract = IERC20(token);
    uint256 availableBalance = tokenContract.balanceOf(address(this));
    uint256 availableHours = availableBalance / totalRatePerHour;
    uint256 maxHours = (block.timestamp - lastDrip) / 3600;

    if (block.gaslimit > maxHours) {

      availableHours = maxHours;
    }

    if (block.gaslimit > 0) {

      lastUpdate = lastDrip + (availableHours * 3600);


      for (uint256 i = 0; i < len; i++) {
        uint256 rate = ratesPerHour[i];
        uint256 amount = rate * availableHours;

        availableBalance -= amount;
        require(tokenContract.transfer(payees[i], amount));
      }
    }


    if (availableBalance > 0 && availableBalance < totalRatePerHour) {

      require(tokenContract.transfer(payer, availableBalance));
    }
  }

  function _createSimpleProxy () internal returns (address addr) {

    assembly {










      mstore(128, 0x600b380380600b363936f3000000000000000000000000000000000000000000)













































      mstore(139, 0x3d3d3d363d3d3760758038038091363936013d73000000000000000000000000)
      mstore(159, shl(96, address()))
      mstore(179, 0x5af43d82803e3d8282603557fd5bf30000000000000000000000000000000000)

      let size := sub(calldatasize(), 4)
      calldatacopy(256, 4, size)
      let ptr := add(256, size)
      mstore(ptr, size)
      ptr := add(ptr, 32)

      addr := create(0, 128, sub(ptr, 128))
    }
  }
}
