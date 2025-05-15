

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";




abstract contract ERC20Blockable is ERC20 {



  event AccountBlocked(address indexed account, uint256 timestamp);
  event AccountUnblocked(address indexed account, uint256 timestamp);




  mapping(address => bool) _blockedAccounts;




  function isAccountBlocked(address account) public view returns (bool) {
    return _blockedAccounts[account];
  }





  function _blockAccount(address account) internal virtual {
    require(!isAccountBlocked(account), "ERC20Blockable: account is already blocked");

    _blockedAccounts[account] = true;
    emit AccountBlocked(account, block.timestamp);
  }





  function _unblockAccount(address account) internal virtual {
    require(isAccountBlocked(account), "ERC20Blockable: account is not blocked");

    _blockedAccounts[account] = false;
    emit AccountUnblocked(account, block.timestamp);
  }




  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    require(!isAccountBlocked(from), "ERC20Blockable: sender account should be not be blocked");
    require(!isAccountBlocked(to), "ERC20Blockable: receiver account should be not be blocked");
    require(!isAccountBlocked(_msgSender()), "ERC20Blockable: caller account should be not be blocked");
    super._beforeTokenTransfer(from, to, amount);
  }
}
