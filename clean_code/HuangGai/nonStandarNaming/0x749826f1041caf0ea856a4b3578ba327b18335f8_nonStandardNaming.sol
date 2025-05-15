



pragma solidity ^0.7.0;

contract Tigereum {




    string public constant name415 = 'Tigereum';
    string public constant symbol429 = 'TIG';
    uint8 public constant decimals91 = 18;
    address public owner;
    string public webAddress;
    uint internal constant _totalsupply411 = 50000000 * 10**uint(decimals91);


    mapping(address => uint256) balances;


    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = _totalsupply411;
        owner = msg.sender;
        webAddress = "https:
    }

    function TOTALSUPPLY884() public pure returns (uint) {
        return _totalsupply411;
    }


    function BALANCEOF997(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    function TRANSFER863(address to, uint tokens) public returns (bool success) {
        require( balances[msg.sender] >= tokens && tokens > 0 );
        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit TRANSFER958(msg.sender, to, tokens);
        return true;
    }




    function TRANSFERFROM746(address from, address to, uint tokens) public returns (bool success) {
        require( allowed[from][msg.sender] >= tokens && balances[from] >= tokens && tokens > 0 );
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit TRANSFER958(from, to, tokens);
        return true;
    }


    function APPROVE294(address sender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][sender] = tokens;
        emit APPROVAL65(msg.sender, sender, tokens);
        return true;
    }



    function ALLOWANCE750(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    event TRANSFER958(address indexed _from, address indexed _to, uint256 _amount);
    event APPROVAL65(address indexed _owner, address indexed _to, uint256 _amount);
}
