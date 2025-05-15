
pragma solidity 0.5.11;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../helpers/Timelocker.sol";


interface DharmaSmartWalletRecovery {
  function recover(address newUserSigningKey) external;
}























contract DharmaAccountRecoveryManager is Ownable, Timelocker {
  using SafeMath for uint256;


  mapping(address => bool) private _accountRecoveryDisabled;




  constructor() public {

    _transferOwnership(tx.origin);


    _setInitialTimelockInterval(this.modifyTimelockInterval.selector, 4 weeks);
    _setInitialTimelockInterval(this.recover.selector, 7 days);
    _setInitialTimelockInterval(this.disableAccountRecovery.selector, 3 days);
  }
















  function setTimelock(
    bytes4 functionSelector,
    bytes calldata arguments,
    uint256 extraTime
  ) external onlyOwner {

    _setTimelock(functionSelector, arguments, extraTime);
  }







  function recover(
    address wallet,
    address newUserSigningKey
  ) external onlyOwner {

    _enforceTimelock(
      this.recover.selector, abi.encode(wallet, newUserSigningKey)
    );


    require(
      !_accountRecoveryDisabled[wallet],
      "This wallet has elected to opt out of account recovery functionality."
    );


    DharmaSmartWalletRecovery(wallet).recover(newUserSigningKey);
  }








  function disableAccountRecovery(address wallet) external onlyOwner {

    _enforceTimelock(this.disableAccountRecovery.selector, abi.encode(wallet));


    _accountRecoveryDisabled[wallet] = true;
  }








  function accountRecoveryDisabled(
    address wallet
  ) external view returns (bool hasDisabledAccountRecovery) {

    hasDisabledAccountRecovery = _accountRecoveryDisabled[wallet];
  }










  function modifyTimelockInterval(
    bytes4 functionSelector,
    uint256 newTimelockInterval
  ) public onlyOwner {

    require(
      functionSelector != bytes4(0),
      "Function selector cannot be empty."
    );


    if (functionSelector == this.modifyTimelockInterval.selector) {
      require(
        newTimelockInterval <= 8 weeks,
        "Timelock interval of modifyTimelockInterval cannot exceed eight weeks."
      );
    }


    Timelocker.modifyTimelockInterval(functionSelector, newTimelockInterval);
  }
}
