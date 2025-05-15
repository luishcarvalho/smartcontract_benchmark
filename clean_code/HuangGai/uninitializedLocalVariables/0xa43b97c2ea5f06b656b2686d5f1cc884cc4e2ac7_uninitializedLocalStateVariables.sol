



pragma solidity ^0.5.2;






contract COwnable {
    address private __owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor () internal {
        __owner = msg.sender;
    }




    modifier onlyOwner() {
        require(_isOwner());
        _;
    }




    function owner() public view returns (address) {
        return __owner;
    }





    function transferOwnership(address newOwner) public onlyOwner() {
        _transferOwnership(newOwner);
    }


















    function _isOwner() internal view returns (bool) {
        return msg.sender == __owner;
    }







    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(__owner, newOwner);
        __owner = newOwner;
    }
}






interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}








contract AirDrop is COwnable {
    mapping (address => uint256) public whitelist;
    address public token_address;
    uint256 private _decimals;

    constructor(address token, uint256 decimals) public{
        token_address = token;
        _decimals = decimals;
    }

    function redeem() public returns(bool res) {
        require (whitelist[msg.sender] > 0 );
        IERC20 token ;

        token.transfer(msg.sender, whitelist[msg.sender]);
        whitelist[msg.sender] = 0;
        return true;
    }

    function setWhitelist(address[] memory accounts, uint256[] memory amounts) public onlyOwner() returns(bool res) {
        require (accounts.length == amounts.length);
        for(uint256 i; i<accounts.length; i++){

            if (accounts[i]!=address(0)){
                whitelist[accounts[i]] = amounts[i]*(10**_decimals);
            }
        }
        return true;
    }

    function withdraw(address token_addr) public onlyOwner() returns(bool res) {
        IERC20 token ;

        token.transfer(msg.sender, token.balanceOf(address(this)));
        return true;
    }

    function kill() public onlyOwner() {
        address payable addr ;

        selfdestruct(addr);
    }

}
