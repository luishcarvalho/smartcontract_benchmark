

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../../interfaces/IVaultControl.sol";

abstract contract VaultControlUpgradeable is OwnableUpgradeable, PausableUpgradeable {

  IVaultControl.VaultAssets public vAssets;






  function pause() public onlyOwner {
    _pause();
  }




  function unpause() public onlyOwner {
    _unpause();
  }
}

contract VaultBaseUpgradeable is VaultControlUpgradeable {







  function _deposit(uint256 _amount, address _provider) internal {
    bytes memory data = abi.encodeWithSignature(
      "deposit(address,uint256)",
      vAssets.collateralAsset,
      _amount
    );
    _execute(_provider, data);
  }






  function _withdraw(uint256 _amount, address _provider) internal {
    bytes memory data = abi.encodeWithSignature(
      "withdraw(address,uint256)",
      vAssets.collateralAsset,
      _amount
    );
    _execute(_provider, data);
  }






  function _borrow(uint256 _amount, address _provider) internal {
    bytes memory data = abi.encodeWithSignature(
      "borrow(address,uint256)",
      vAssets.borrowAsset,
      _amount
    );
    _execute(_provider, data);
  }






  function _payback(uint256 _amount, address _provider) internal {
    bytes memory data = abi.encodeWithSignature(
      "payback(address,uint256)",
      vAssets.borrowAsset,
      _amount
    );
    _execute(_provider, data);
  }




  function _execute(address _target, bytes memory _data)
    internal
    whenNotPaused
    returns (bytes memory response)
  {




















