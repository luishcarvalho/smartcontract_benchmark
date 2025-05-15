
pragma solidity ^0.4.17;

import 'zeppelin-solidity/contracts/token/ERC20/CappedToken.sol';
import 'zeppelin-solidity/contracts/token/ERC20/PausableToken.sol';





contract MeshToken is CappedToken, PausableToken {
  string public name = "RIGHTMESH TOKEN";
  string public symbol = "RMESH";
  uint8 public decimals = 18;
  uint256 public cap = 1000000 ether;




  mapping (address => bool) public allowedTransfers;




  bool public pausedOnce = false;





  function MeshToken() CappedToken(cap) public {}







  modifier whenNotPaused() {
    require(!paused || allowedTransfers[msg.sender]);
    _;
  }






  function pause() onlyOwner whenNotPaused public {
    require(pausedOnce == false);
    pausedOnce = true;
    super.pause();
  }









  function updateAllowedTransfers(address _address, bool _allowedTransfers)
  external
  onlyOwner
  returns (bool)
  {



    require(_address != owner);

    allowedTransfers[_address] = _allowedTransfers;
    return true;
  }
}
