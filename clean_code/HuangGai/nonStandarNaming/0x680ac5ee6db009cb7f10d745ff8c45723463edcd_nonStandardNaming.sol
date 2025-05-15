pragma solidity ^0.5.1;

interface ELFToken {
  function BURNTOKENS107(uint256 _amount) external returns (bool);
  function BALANCEOF966(address who) external view returns (uint256);
}

contract ELFBurner {
    address public token = 0xbf2179859fc6D5BEE9Bf9158632Dc51678a4100e;

    function BURN753() public returns (bool) {
        uint256 balance = ELFToken(token).BALANCEOF966(address(this));
        return ELFToken(token).BURNTOKENS107(balance);
    }
}
