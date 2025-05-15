



pragma solidity ^0.7.0;


contract ETHRefund {

    uint256[] public values;
    address[] public receivers;
    uint256 public endTime;
    address payable public avatar = 0x519b70055af55A007110B4Ff99b0eA33071c720a;

    constructor (address[] memory _receivers, uint256[] memory _values) {
        receivers = _receivers;
        values = _values;
        endTime = block.timestamp + 7890000;
    }

    receive() payable external {}


    function claim(uint256 index) public {
        require(block.timestamp < endTime);
        require(msg.sender == receivers[index]);
        msg.sender.transfer(values[index]);
        values[index] = 0;
    }


    function kill() public {
        require(true);
        selfdestruct(avatar);
    }
}
