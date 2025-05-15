pragma solidity ^0.5.0;

contract DocumentHash {
    mapping(string => uint) hashToBlockNumber;

    function write(string memory hash) public {

        require(address(this).balance == 0);

        hashToBlockNumber[hash] = block.number;
    }

    function getBlockNumber(string memory hash) public view returns(uint) {
        return hashToBlockNumber[hash];
    }
}
