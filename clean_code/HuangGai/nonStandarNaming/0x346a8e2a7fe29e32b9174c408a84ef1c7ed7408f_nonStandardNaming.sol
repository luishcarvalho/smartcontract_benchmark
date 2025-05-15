pragma solidity ^0.5.2;

interface BurnableERC20 {
    function BALANCEOF217(address who) external view returns (uint);
    function BURN601(uint256 amount) external;
}

contract Burner {
    BurnableERC20 public token;

    constructor(BurnableERC20 _token) public {
        token = _token;
    }

    function BURN601() external {
        uint balance = token.BALANCEOF217(address(this));
        token.BURN601(balance);
    }
}
