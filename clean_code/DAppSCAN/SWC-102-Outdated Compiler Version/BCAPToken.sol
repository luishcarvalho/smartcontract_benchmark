




pragma solidity ^0.4.1;

import "./StandardToken.sol";




contract BCAPToken is StandardToken {






  function BCAPToken (address _centralBank)
    StandardToken (_centralBank) {
    owner = _centralBank;
  }




  function freezeTransfers () {
    if (msg.sender != owner) throw;

    if (!transfersFrozen) {
      transfersFrozen = true;
      Freeze ();
    }
  }




  function unfreezeTransfers () {
    if (msg.sender != owner) throw;

    if (transfersFrozen) {
      transfersFrozen = false;
      Unfreeze ();
    }
  }








  function transfer (address _to, uint256 _value) returns (bool success) {
    if (transfersFrozen) return false;
    else return AbstractToken.transfer (_to, _value);
  }










  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success) {
    if (transfersFrozen) return false;
    else return AbstractToken.transferFrom (_from, _to, _value);
  }




  event Freeze ();




  event Unfreeze ();






  address owner;




  bool transfersFrozen = false;
}
