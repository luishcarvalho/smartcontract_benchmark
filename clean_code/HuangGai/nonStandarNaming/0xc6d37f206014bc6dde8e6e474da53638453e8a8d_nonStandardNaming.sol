



pragma solidity ^0.6.12;

interface IERC20 {
    function TOTALSUPPLY142() external view returns (uint256);
    function BALANCEOF828(address account) external view returns (uint256);
    function TRANSFER541(address recipient, uint256 amount) external returns (bool);
    function ALLOWANCE388(address owner, address spender) external view returns (uint256);
    function APPROVE981(address spender, uint256 amount) external returns (bool);
    function TRANSFERFROM180(address sender, address recipient, uint256 amount) external returns (bool);
    event TRANSFER290(address indexed from, address indexed to, uint256 value);
    event APPROVAL740(address indexed owner, address indexed spender, uint256 value);
}

contract TokenLock {
    address public lockedToken;
    address public withdrawAddress = 0x831226F8bFcB9d74553f1d020554Defd61908df3;
    uint public releaseTime = 1604931944 + 5 minutes;

    constructor() public {
        lockedToken = 0xE1c94F1dF9f1A06252da006C623E07982787ceE4;

    }

    function LOCKEDTOKENS663() public view returns (uint256) {
        IERC20 token = IERC20(lockedToken);
        return token.BALANCEOF828(address(this));
    }

    function WITHDRAWTOKENS951()  public  {
        require(block.timestamp>releaseTime);
        require(msg.sender == withdrawAddress);
        IERC20 token = IERC20(lockedToken);
        uint256 balancetransfer =  LOCKEDTOKENS663();

        token.TRANSFER541(address(msg.sender), balancetransfer);
    }

}
