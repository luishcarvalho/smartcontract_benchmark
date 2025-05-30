





pragma solidity ^0.5.0;

contract Storage {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    mapping(bytes32 => string) data;

    function set(bytes32 key, string memory value) public {
        require(
            address(this).balance == 0,
            "username has already been taken"
        );
        data[key] = value;
    }

    function get(bytes32 key) public view returns (string memory) {
        return data[key];
    }

    function del(bytes32 key) public {
        require(msg.sender == owner, "only the owner can delete names");
        delete data[key];
    }
}
