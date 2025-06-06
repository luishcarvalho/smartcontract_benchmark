



pragma solidity ^0.5.11;











contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        _notEntered = true;
    }

    modifier nonReentrant() {

        require(_notEntered, "ReentrancyGuard: reentrant call");

        _notEntered = false;
        _;
        _notEntered = true;
    }
}



contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address _from, address _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(tx.origin == owner);

        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract ERC20TokenInterface {

    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



contract RequestForForgiveness is Owned, ReentrancyGuard {

    ERC20TokenInterface private token;


    address payable private receivingAccount;


    function addEthReceivingAccount(address addr) public onlyOwner {
        require(addr != address(0));
        receivingAccount = address(uint160(addr));
    }


    function addToken(address ercTokenAddress) public onlyOwner {
        require(ercTokenAddress != address(0));
        token = ERC20TokenInterface(ercTokenAddress);
    }




    uint private disincentive;

    function setDisincentiveInWei(uint number) public onlyOwner {
        disincentive = number;
    }

    function getDisincentive() public view returns (uint) {
        return disincentive;
    }




    function requestForgiveness(string memory forgiveness_request) public payable nonReentrant {

        uint256 length = bytes(forgiveness_request).length;
        require(length > 500 && length < 2000);
        require(msg.sender != address(0));
        require(msg.value > disincentive);
        receivingAccount.transfer(msg.value);
        withdrawToken(msg.sender, msg.value, forgiveness_request);
    }



    function withdrawToken(address recipient, uint256 amount, string memory requestString) internal {

        string memory data = requestString;
        require(recipient != address(0));
        require(bytes(data).length > 0);
        token = ERC20TokenInterface(token);
        require(token.transfer(recipient, 1000000000000000000) == true);
        emit RequestMade(recipient, data, amount, now);
    }


    event RequestMade(address indexed from, string data, uint256 donation, uint256 timestamp);

}
