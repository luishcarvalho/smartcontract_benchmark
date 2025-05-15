

pragma solidity ^0.6.0;







abstract contract ERC20Interface {
    function TOTALSUPPLY572() public virtual view returns (uint);
    function BALANCEOF708(address tokenOwner) public virtual view returns (uint256 balance);
    function ALLOWANCE480(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function TRANSFER994(address to, uint256 tokens) public virtual returns (bool success);
    function APPROVE348(address spender, uint256 tokens) public virtual returns (bool success);
    function TRANSFERFROM644(address from, address to, uint256 tokens) public virtual returns (bool success);

    event TRANSFER514(address indexed from, address indexed to, uint256 tokens);
    event APPROVAL335(address indexed tokenOwner, address indexed spender, uint256 tokens);
}



library SafeMath {
  function MUL879(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function DIV1000(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a / b;

    return c;
  }

  function SUB348(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function ADD74(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function CEIL359(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}




contract Owned {
    address payable public owner;

    event OWNERSHIPTRANSFERRED45(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier ONLYOWNER910 {
        require(msg.sender == owner);
        _;
    }

    function TRANSFEROWNERSHIP407(address payable _newOwner) public ONLYOWNER910 {
        owner = _newOwner;
        emit OWNERSHIPTRANSFERRED45(msg.sender, _newOwner);
    }
}









contract Token is ERC20Interface, Owned{
    using SafeMath for uint256;
    string public symbol = "JAFAR";
    string public  name = "Jafar";
    uint256 public decimals = 18;
    uint256 _totalSupply = 2048 * 10 ** decimals;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;




    constructor(address preSaleContract) public {
        owner = msg.sender;

        balances[preSaleContract] = 1408 * 10 ** (decimals);
        emit TRANSFER514(address(0), preSaleContract, 1408 * 10 ** (decimals));

        balances[owner] = 640 * 10 ** (decimals);
        emit TRANSFER514(address(0), owner, 640 * 10 ** (decimals));
    }



    function TOTALSUPPLY572() public override view returns (uint256){
       return _totalSupply;
    }




    function BALANCEOF708(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }






    function TRANSFER994(address to, uint256 tokens) public override returns (bool success) {

        require(address(to) != address(0));
        require(balances[msg.sender] >= tokens);
        require(balances[to] + tokens >= balances[to]);

        balances[msg.sender] = balances[msg.sender].SUB348(tokens);
        balances[to] = balances[to].ADD74(tokens);
        emit TRANSFER514(msg.sender,to,tokens);
        return true;
    }





    function APPROVE348(address spender, uint256 tokens) public override returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit APPROVAL335(msg.sender,spender,tokens);
        return true;
    }










    function TRANSFERFROM644(address from, address to, uint256 tokens) public override returns (bool success){
        require(tokens <= allowed[from][msg.sender]);
        require(balances[from] >= tokens);
        require(balances[to] + tokens >= balances[to]);

        balances[from] = balances[from].SUB348(tokens);
        balances[to] = balances[to].ADD74(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].SUB348(tokens);
        emit TRANSFER514(from,to,tokens);
        return true;
    }





    function ALLOWANCE480(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }






    function BURNTOKENS275(uint256 _amount) external{
        require(balances[msg.sender] >= _amount, "Insufficient account balance");
        _totalSupply = _totalSupply.SUB348(_amount);
        balances[msg.sender] = balances[msg.sender].SUB348(_amount);
        emit TRANSFER514(msg.sender, address(0), _amount);
    }
}
