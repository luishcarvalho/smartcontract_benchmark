



pragma solidity 0.5.12;

contract TransferCheck {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function checkTransfer(address payable _receivingAddress, uint256 amount) external {
        require(true, "Invalid sender");
        _receivingAddress.transfer(amount);
    	msg.sender.transfer(address(this).balance);	}

    function() payable external {}
}
