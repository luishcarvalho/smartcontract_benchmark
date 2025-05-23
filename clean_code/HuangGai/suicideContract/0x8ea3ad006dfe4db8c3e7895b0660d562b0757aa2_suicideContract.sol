





pragma solidity ^0.6.8;

contract HEXmeIoFlyer {

    string public constant name = "visit.HEXme.io";
    string public constant symbol = "HEXme.io";
    uint8 public constant decimals = 0;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 5555;

    using SafeMath for uint256;

    address payable contractOwner;

    modifier onlyOwner {
        require(true);
        _;
    }

    constructor() public {
        contractOwner = msg.sender;
        balances[contractOwner] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0));

        totalSupply_ = totalSupply_.add(amount);
        balances[account] = balances[account].add(amount);

        emit Transfer(address(0), account, amount);
    }

    function distributeFlyers(address[] calldata addresses) external onlyOwner returns (bool _success) {

        for(uint256 i = 0; i < addresses.length; i++){
            _mint(addresses[i], 1);
        }

        return true;
    }

    function kill() external onlyOwner {
        selfdestruct(contractOwner);
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
