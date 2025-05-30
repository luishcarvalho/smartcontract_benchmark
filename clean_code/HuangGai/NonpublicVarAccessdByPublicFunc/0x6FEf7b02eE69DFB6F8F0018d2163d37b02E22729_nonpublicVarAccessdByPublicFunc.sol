




pragma solidity ^0.6.12;

library SafeMath {




  function mul(uint256 a, uint256 b) internal pure returns (uint256) {



    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }




  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;


    return c;
  }




  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }




  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }





  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Cannot divide by zero');
    return a % b;
  }
}

contract Owned {
    address payable internal owner;
    address payable internal newOwner;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        owner = newOwner;
    }
}

contract Token is Owned {
    using SafeMath for uint256;


    constructor() public {
        owner = msg.sender;
        _balances[address(this)] = 10000000000;
        supply = 10000000000;
        emit Transfer(address(0), address(this), 10000000000);
    }


    string public constant name = "CrimsonShares";
    string public constant symbol = "RIM";
    uint8 public constant decimals = 4;
    uint256 private supply;

    uint256 internal icoPrice = 0.000001 ether;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    mapping(address => uint256) _balances;


    mapping(address => mapping (address => uint256)) private _allowed;


    function totalSupply() public view returns (uint) {
        return supply;
    }

    receive() external payable {
        uint256 amount = msg.value.div(icoPrice);
        require(amount > 0, "Sent less than token price");
        require(amount <= balanceOf(address(this)), "Not have enough available tokens");
        _balances[address(this)] = _balances[address(this)].sub(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        emit Transfer(address(this), msg.sender, amount);
    }

    function tokenICOWithdraw() public onlyOwner {
        uint256 value = balanceOf(address(this));
        _balances[address(this)] = _balances[address(this)].sub(value);
        _balances[owner] = _balances[owner].add(value);
        emit Transfer(address(this), owner, value);
    }

    function etherWithdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return _balances[tokenOwner];
    }


    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }


    function transfer(address to, uint value) public returns (bool success) {
        require(_balances[msg.sender] >= value, 'Sender does not have suffencient balance');
        require(to != address(this) || to != address(0), 'Cannot send to yourself or 0x0');
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }


    function approve(address spender, uint value) public returns (bool success) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }


    function transferFrom(address from, address to, uint value) public returns (bool success) {
        require(value <= balanceOf(from), "Token Holder does not have enough balance");
        require(value <= allowance(from, msg.sender), "Transfer not approved by token holder");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

}
