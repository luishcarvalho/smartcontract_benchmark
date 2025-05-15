pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";





contract LockupToken is ERC20Burnable, Ownable {
    uint256 public releaseDate;
    address public owner;
    address public crowdsaleAddress;

    event CrowdsaleAddressSet(address _crowdsaleAddress);







    constructor(uint256 _releaseDate) public {
        require(_releaseDate > block.timestamp);
        releaseDate = _releaseDate;
        owner = msg.sender;
    }




    modifier unlocked() {
        require(block.timestamp > releaseDate || msg.sender == owner || msg.sender == crowdsaleAddress);
        _;
    }






    function setReleaseDate(uint256 _newReleaseDate) public onlyOwner {
        require(block.timestamp < releaseDate);
        require(_newReleaseDate >= block.timestamp);

        releaseDate = _newReleaseDate;
    }







    function setCrowdsaleAddress(address _crowdsaleAddress) public onlyOwner {
        crowdsaleAddress = _crowdsaleAddress;

        emit CrowdsaleAddressSet(_crowdsaleAddress);
    }







    function transferFrom(address _from, address _to, uint256 _value) public unlocked returns(bool) {
        super.transferFrom(_from, _to, _value);
    }






    function transfer(address _to, uint256 _value) public unlocked returns(bool) {
        super.transfer(_to, _value);
    }





    function getCrowdsaleAddress() public view returns(address) {
        return crowdsaleAddress;
    }
}
