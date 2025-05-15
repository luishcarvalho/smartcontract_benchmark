
pragma solidity ^0.4.19;



contract ReceivingContract {
    function onTokenReceived(address _from, uint _value, bytes _data) public;
}
