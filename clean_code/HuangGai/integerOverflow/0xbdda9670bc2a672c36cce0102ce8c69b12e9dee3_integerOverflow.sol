



pragma solidity 0.5.16;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0)
            return 0;
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

        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 internal _totalSupply;




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }






    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }







    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }






    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }










    function approve(address spender, uint256 value) public returns (bool) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }









    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

}

contract ERC20Mintable is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    function _mint(address to, uint256 amount) internal {
        _balances[to] = _balances[to].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        _balances[from] = _balances[from].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(from, address(0), amount);
    }
}

contract ThreeFMutual {

    struct Player {
        uint256 id;
        bytes32 name;
        uint256 ref;
        bool isAgent;
        bool claimed;
        uint256 eth;
        uint256 shares;
        uint256 units;
        uint256 plyrLastSeen;
        uint256 mask;
        uint256 level;
        uint256 accumulatedRef;
    }

    mapping(address => mapping(uint256 => uint256)) public unitToExpirePlayer;
    mapping(uint256 => uint256) public unitToExpire;

    uint256 public issuedInsurance;
    uint256 public ethOfShare;
    uint256 public shares;
    uint256 public pool;
    uint256 public today;
    uint256 public _now;
    uint256 public mask;
    uint256 public agents;


    mapping(address => Player) public player;
    mapping(uint256 => address) public agentxID_;
    mapping(bytes32 => address) public agentxName_;

}

contract TFToken is ERC20Mintable {
    string public constant name = "ThirdFloorToken";
    string public constant symbol = "TFT";
    uint8 public constant decimals = 18;

    ThreeFMutual public constant Mutual = ThreeFMutual(0x66be1bc6C6aF47900BBD4F3711801bE6C2c6CB32);

    mapping(address => uint256) public claimedAmount;

    function claim(address receiver) external {
        uint256 balance;
        (,,,,,balance,,,,,,) = Mutual.player(receiver);
        require(balance > claimedAmount[receiver]);
        _mint(receiver, balance.sub(claimedAmount[receiver]));
        claimedAmount[receiver] = balance;
    }

}
