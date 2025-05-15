pragma solidity ^0.5.8;



library SafeMath {


  function SUB60(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }


  function ADD958(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

}



contract Ownable {
    address payable private _owner;


    constructor() public {
        _owner = msg.sender;
    }


    function OWNER811() public view returns(address payable) {
        return _owner;
    }


    modifier ONLYOWNER592() {
        require(_owner == msg.sender);
        _;
    }
}




interface ERC20 {
    function TOTALSUPPLY802() external view returns (uint256);
    function BALANCEOF782(address who) external view returns (uint256);
    function ALLOWANCE780(address tokenOwner, address spender) external view returns (uint256);
    function TRANSFER211(address to, uint256 value) external returns (bool);
    function TRANSFERFROM635(address from, address to, uint256 value) external returns (bool);
    function APPROVE219(address spender, uint256 value) external returns (bool);

    event TRANSFER133(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event APPROVAL815(
        address indexed tokenOwner,
        address indexed spender,
        uint256 value
    );
}

contract LTLNN is ERC20, Ownable {
    using SafeMath for uint256;

    string public name = "Lawtest Token";
    string public symbol ="LTLNN";
    uint8  public decimals = 2;

    uint256 initialSupply = 5000000;
    uint256 saleBeginTime = 1557824400;
    uint256 saleEndTime = 1557835200;
    uint256 tokensDestructTime = 1711929599;
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint)) _allowed;
    uint256 private _totalSupply;
    uint256 private _amountForSale;

    event MINT653(address indexed to, uint256 amount, uint256 amountForSale);
    event TOKENSDESTROYED231();

    constructor() public {
        _balances[address(this)] = initialSupply;
        _amountForSale = initialSupply;
        _totalSupply = initialSupply;
    }


    function TOTALSUPPLY802() public view returns (uint256) {
        return _totalSupply;
    }

    function AMOUNTFORSALE510() public view returns (uint256) {
        return _amountForSale;
    }


    function BALANCEOF782(address owner) public view returns (uint256) {
        return _balances[owner];
    }


    function TRANSFER211(address to, uint256 amount) external returns (bool) {
        require(block.timestamp < tokensDestructTime);
        require(block.timestamp > saleEndTime);
        _TRANSFER936(msg.sender, to, amount);
        emit TRANSFER133(msg.sender, to, amount);
        return true;
    }


    function APPROVE219(address spender, uint256 value) external returns (bool) {
        _allowed[msg.sender][spender] = value;
        emit APPROVAL815(msg.sender, spender, value);
        return true;
    }


    function TRANSFERFROM635(address from, address to, uint256 value) external returns (bool) {
        require(to != address(0));
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        _balances[from] = _balances[from].SUB60(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].SUB60(value);
        _balances[to] = _balances[to].ADD958(value);
        emit TRANSFER133(from, to, value);
        return true;
    }


    function ALLOWANCE780(address tokenOwner, address spender) external view returns (uint256) {
        return _allowed[tokenOwner][spender];
    }


    function MINT854(address account, uint256 amount) external ONLYOWNER592 {
        require(saleBeginTime < block.timestamp);
        require(saleEndTime > block.timestamp);
        _TRANSFER936(address(this),  account, amount);
        emit MINT653(account, amount, _amountForSale);
    }



    function DESTRUCTCONTRACT474() external ONLYOWNER592 {
        selfdestruct(OWNER811());
    }


    function _TRANSFER936(address from, address to, uint256 amount) internal {
        require(amount <= _balances[from]);
        require(to != address(0));
        _balances[from] = _balances[from].SUB60(amount);
        _balances[to] = _balances[to].ADD958(amount);
        if(saleEndTime > block.timestamp)
            _amountForSale = _balances[address(this)];
    }

    function HASSALEBEGINTIMECOME453() public view returns(bool) {
        return (block.timestamp > saleBeginTime);
    }

    function HASSALEENDTIMECOME335() public view returns(bool) {
        return (block.timestamp > saleEndTime);
    }

    function HASTOKENSDESTRUCTTIMECOME819() public view returns(bool) {
        return (block.timestamp > tokensDestructTime);
    }

}
