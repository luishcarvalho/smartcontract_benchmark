pragma solidity ^0.5.1;


contract MerklIO {
    address internal owner = msg.sender;
    mapping(bytes32 => uint256) internal hashToTimestamp;
    mapping(bytes32 => uint256) internal hashToNumber;

    event Hashed(bytes32 indexed hash);

    function store(bytes32 hash) external {

        assert(msg.sender == owner);


        assert(hashToTimestamp[hash] <= 0);


        hashToTimestamp[hash] = block.timestamp;
        hashToNumber[hash] = block.number;


        emit Hashed(hash);
    }

    function changeOwner(address ownerNew) external {

        assert(msg.sender == owner);


        owner = ownerNew;
    }
}
