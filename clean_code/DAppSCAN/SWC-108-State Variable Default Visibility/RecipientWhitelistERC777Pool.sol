

















pragma solidity 0.5.12;

import "./ERC777Pool.sol";

contract RecipientWhitelistERC777Pool is ERC777Pool {

  bool _recipientWhitelistEnabled;
  mapping(address => bool) _recipientWhitelist;

  function recipientWhitelistEnabled() public view returns (bool) {
    return _recipientWhitelistEnabled;
  }

  function recipientWhitelisted(address _recipient) public view returns (bool) {
    return _recipientWhitelist[_recipient];
  }

  function setRecipientWhitelistEnabled(bool _enabled) public onlyAdmin {
    _recipientWhitelistEnabled = _enabled;
  }

  function setRecipientWhitelisted(address _recipient, bool _whitelisted) public onlyAdmin {
    _recipientWhitelist[_recipient] = _whitelisted;
  }










  function _callTokensToSend(
      address operator,
      address from,
      address to,
      uint256 amount,
      bytes memory userData,
      bytes memory operatorData
  )
      internal
  {
      if (_recipientWhitelistEnabled) {
        require(to == address(0) || _recipientWhitelist[to], "recipient is not whitelisted");
      }
      address implementer = ERC1820_REGISTRY.getInterfaceImplementer(from, TOKENS_SENDER_INTERFACE_HASH);
      if (implementer != address(0)) {
          IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
      }
  }

}
