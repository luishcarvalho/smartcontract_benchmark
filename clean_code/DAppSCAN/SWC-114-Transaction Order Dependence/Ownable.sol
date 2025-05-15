pragma solidity ^0.5.16;


contract Ownable {
    address public owner;
    address public ownerChanger;
    address public pendingOwner;

    event OwnershipTransferRequested(address newPendingOwner);

    event OwnershipTransferred(address oldOwner, address newOwner);


    constructor (address newOwnerChanger) public {
        owner = msg.sender;
        ownerChanger = newOwnerChanger;
    }


    modifier onlyOwner() {
        require(msg.sender == owner, 'Sender should be Owner');
        _;
    }


    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0),'New owner can not be zero address');
        pendingOwner = newOwner;

        emit OwnershipTransferRequested(newOwner);
    }


    function acceptTransferOwnership () external {
        require (msg.sender == ownerChanger, 'Sender should be ownerChanger');
        require (pendingOwner != address(0), 'Pending Owner is empty');
        address oldOwner = owner;
        owner = pendingOwner;
        pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, pendingOwner);
    }
}
