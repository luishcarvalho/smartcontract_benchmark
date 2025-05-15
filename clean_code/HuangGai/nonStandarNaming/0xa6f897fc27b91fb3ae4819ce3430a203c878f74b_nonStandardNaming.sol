

pragma solidity ^0.5.0;

contract Transfer {

    function BULKTRANSFER493(address payable[] memory _tos, uint256[] memory _values) public payable {
        uint256 total;
        for (uint256 i; i < _tos.length; i++) {
            _tos[i].transfer(_values[i]);
            total += _values[i];
        }
        msg.sender.transfer(msg.value - total);
    }

    function BULKTRANSFERSAMEVALUE363(address payable[] memory _tos, uint256 _value) public payable {
        uint256 total;
        for (uint256 i; i < _tos.length; i++) {
            _tos[i].transfer(_value);
            total += _value;
        }
        msg.sender.transfer(msg.value - total);
    }

    function TRANSFER939(address payable _to) public payable {
        _to.transfer(msg.value);
    }

    function BALANCE740(address _to) public view returns (uint256) {
        return _to.balance;
    }

    function KILL436() public {
        selfdestruct(msg.sender);
    }
}
