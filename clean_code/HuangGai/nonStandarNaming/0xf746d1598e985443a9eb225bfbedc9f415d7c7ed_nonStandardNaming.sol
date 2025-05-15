pragma solidity 0.5.4;


contract Ownable {
    address public owner;
    address public pendingOwner;

    event OWNERSHIPTRANSFERRED350(address indexed previousOwner, address indexed newOwner);


    modifier ONLYOWNER439() {
        require(msg.sender == owner);
        _;
    }


    modifier ONLYPENDINGOWNER313() {
        require(msg.sender == pendingOwner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }


    function TRANSFEROWNERSHIP721(address newOwner) ONLYOWNER439 public {
        pendingOwner = newOwner;
    }


    function CLAIMOWNERSHIP517() ONLYPENDINGOWNER313 public {
        emit OWNERSHIPTRANSFERRED350(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}



interface IERC20 {
    function BALANCEOF953(address who) external view returns (uint256);
    function TRANSFER785(address to, uint256 value) external returns (bool);
    function TRANSFERFROM145(address from, address to, uint256 value) external returns (bool);
}

contract TokenReceiver is Ownable {
    IERC20 public token;

    event RECEIVE752(address from, uint invoiceID, uint amount);

    constructor (address _token) public {
        require(_token != address(0));

        token = IERC20(_token);
    }

    function RECEIVETOKENWITHINVOICEID961(uint _invoiceID, uint _amount) public {
        require(token.TRANSFERFROM145(msg.sender, address(this), _amount), "");

        emit RECEIVE752(msg.sender, _invoiceID, _amount);
    }

    function CHANGETOKEN467(address _token) public ONLYOWNER439 {
        token = IERC20(_token);
    }

    function RECLAIMTOKEN981(IERC20 _token, uint _amount) external ONLYOWNER439 {
        _token.TRANSFER785(owner, _amount);
    }
}
