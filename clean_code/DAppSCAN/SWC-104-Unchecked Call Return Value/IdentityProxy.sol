pragma solidity ^0.5.13;

import "../common/ExternalCall.sol";

contract IdentityProxy {
  address public deployer;

  constructor() public {
    deployer = msg.sender;
  }

  modifier onlyDeployer() {
    require(msg.sender == deployer, "Only callable by original deployer");
    _;
  }








  function makeCall(address destination, bytes calldata data) external payable onlyDeployer {

    ExternalCall.execute(destination, msg.value, data);
  }
}
