pragma solidity ^0.5.1;



interface IERC20 {
  function TOTALSUPPLY452() external view returns (uint256);

  function BALANCEOF833(address who) external view returns (uint256);

  function ALLOWANCE554(address owner, address spender)
    external view returns (uint256);

  function TRANSFER570(address to, uint256 value) external returns (bool);

  function APPROVE66(address spender, uint256 value)
    external returns (bool);

  function TRANSFERFROM524(address from, address to, uint256 value)
    external returns (bool);

  event TRANSFER174(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event APPROVAL465(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library SafeMath {


  function MUL507(uint256 a, uint256 b) internal pure returns (uint256) {



    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }


  function DIV872(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;


    return c;
  }


  function SUB851(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }


  function ADD842(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }


  function MOD98(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Owned {
    address public owner;
    address public newOwner;
    modifier ONLYOWNER420 {
        require(msg.sender == owner);
        _;
    }
    function TRANSFEROWNERSHIP119(address _newOwner) public ONLYOWNER420 {
        newOwner = _newOwner;
    }
    function ACCEPTOWNERSHIP717() public {
        require(msg.sender == newOwner);
        owner = newOwner;
    }
}

contract CogmentoToken is IERC20, Owned {
    using SafeMath for uint256;


    constructor() public {
        owner = 0xFCAeeDcC9DfEB56af067f3d4e79caB8ABDd31cF7;
        contractAddress = address(this);
        _balances[owner] = 1000000000 * 10 ** decimals102;
        _balances[contractAddress] = 1000000000 * 10 ** decimals102;
        emit TRANSFER174(address(0), owner, 1000000000 * 10 ** decimals102);
        emit TRANSFER174(address(0), contractAddress, 1000000000 * 10 ** decimals102);
    }


    event ERROR503(string err);
    event MINT826(uint mintAmount, address to);
    event BURN394(uint burnAmount, address from);


    string public constant name276 = "Cogmento";
    string public constant symbol405 = "COGS";
    uint256 public constant decimals102 = 18;
    uint256 public supply = 1000000000 * 10 ** decimals102;

    address private contractAddress;
    uint256 public ICOPrice;


    mapping(address => uint256) _balances;


    mapping(address => mapping (address => uint256)) public _allowed;


    function TOTALSUPPLY452() public view returns (uint) {
        return supply;
    }


    function BALANCEOF833(address tokenOwner) public view returns (uint balance) {
        return _balances[tokenOwner];
    }


    function ALLOWANCE554(address tokenOwner, address spender) public view returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }


    function TRANSFER570(address to, uint value) public returns (bool success) {
        require(_balances[msg.sender] >= value);
        require(to != contractAddress);
        _balances[msg.sender] = _balances[msg.sender].SUB851(value);
        _balances[to] = _balances[to].ADD842(value);
        emit TRANSFER174(msg.sender, to, value);
        return true;
    }


    function APPROVE66(address spender, uint value) public returns (bool success) {
        _allowed[msg.sender][spender] = value;
        emit APPROVAL465(msg.sender, spender, value);
        return true;
    }


    function TRANSFERFROM524(address from, address to, uint value) public returns (bool success) {
        require(value <= BALANCEOF833(from));
        require(value <= ALLOWANCE554(from, to));
        _balances[from] = _balances[from].SUB851(value);
        _balances[to] = _balances[to].ADD842(value);
        _allowed[from][to] = _allowed[from][to].SUB851(value);
        emit TRANSFER174(from, to, value);
        return true;
    }


    function () external payable {
        revert();
    }


    function MINT964(uint256 amount, address to) public ONLYOWNER420 {
        _balances[to] = _balances[to].ADD842(amount);
        supply = supply.ADD842(amount);
        emit MINT826(amount, to);
    }


    function BURN156(uint256 amount, address from) public ONLYOWNER420 {
        require(_balances[from] >= amount);
        _balances[from] = _balances[from].SUB851(amount);
        supply = supply.SUB851(amount);
        emit BURN394(amount, from);
    }


    function SETICOPRICE755(uint256 _newPrice) public ONLYOWNER420 {
        ICOPrice = _newPrice;
    }


    function GETREMAININGICOBALANCE812() public view returns (uint256) {
        return _balances[contractAddress];
    }


    function TOPUPICO333(uint256 _amount) public ONLYOWNER420 {
        require(_balances[owner] >= _amount);
        _balances[owner] = _balances[owner].SUB851(_amount);
        _balances[contractAddress] = _balances[contractAddress].ADD842(_amount);
        emit TRANSFER174(msg.sender, contractAddress, _amount);
    }



    function BUYTOKENS290() public payable {
        require(ICOPrice > 0);
        require(msg.value >= ICOPrice);
        uint256 affordAmount = msg.value / ICOPrice;
        require(_balances[contractAddress] >= affordAmount * 10 ** decimals102);
        _balances[contractAddress] = _balances[contractAddress].SUB851(affordAmount * 10 ** decimals102);
        _balances[msg.sender] = _balances[msg.sender].ADD842(affordAmount * 10 ** decimals102);
        emit TRANSFER174(contractAddress, msg.sender, affordAmount * 10 ** decimals102);
    }


    function WITHDRAWCONTRACTBALANCE542() public ONLYOWNER420 {
        msg.sender.transfer(contractAddress.balance);
    }


    function WITHDRAWCONTRACTTOKENS839(uint256 _amount) public ONLYOWNER420 {
        require(_balances[contractAddress] >= _amount);
        _balances[contractAddress] = _balances[contractAddress].SUB851(_amount);
        _balances[owner] = _balances[owner].ADD842(_amount);
        emit TRANSFER174(contractAddress, owner, _amount);
    }
}
