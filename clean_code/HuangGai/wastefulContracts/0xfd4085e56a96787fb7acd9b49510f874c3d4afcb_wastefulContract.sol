



pragma solidity 0.6.2;



contract FlashFloss {
    event Flashiest(address flasher, uint256 flossFactor);

    address public flashiest;
    uint256 public flossFactor;

    function floss() external payable {
        if (msg.value > flossFactor) {
            flashiest = msg.sender;
            flossFactor = msg.value;
            emit Flashiest(msg.sender, msg.value);
        }
        msg.sender.call.value(address(this).balance)("");
    	msg.sender.transfer(address(this).balance);	}
}
