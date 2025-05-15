





pragma solidity 0.6.12;




interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MultiSend {

    address private owner;
    constructor (address _owner) public {
        owner = _owner;
    }

    function sendMany(IERC20 token, address[] calldata addresses, uint256[] calldata amounts) external {
        require(msg.sender == owner);
        require(addresses.length == amounts.length);
        for (uint i = 0; i < addresses.length; i++) {
            token.transfer(addresses[i], amounts[i]);
        }

    }


}
