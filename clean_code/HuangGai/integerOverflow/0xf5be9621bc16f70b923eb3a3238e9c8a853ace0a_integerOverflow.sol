pragma solidity 0.5.10;

library SafeMath {




    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a / b;

        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        return a - b;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        return c;
    }
}

contract Ownable {

    address public owner;
    bool public stopped = false;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor() public{
        owner = msg.sender;
    }




    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }





    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }




    function stop() onlyOwner public{
        stopped = true;
    }




    function start() onlyOwner public{
        stopped = false;
    }




    modifier isRunning {
        assert (!stopped);
        _;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {

    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;




    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }






    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);


        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }






    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

contract BurnableToken is BasicToken, Ownable {

    event Burn(address indexed burner, uint256 value);





    function burn(uint256 _value) public onlyOwner{
        require(_value <= balances[msg.sender]);



        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);

        totalSupply_ = totalSupply_.sub(_value);

        emit Burn(burner, _value);
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {

    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }
    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;







    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }











    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }







    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }











    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }











    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}


contract ExtoToken is StandardToken, BurnableToken {

    using SafeMath for uint;

    string constant public symbol = "EXTO";
    string constant public name = "Exto";
    uint8 constant public decimals = 18;
    uint256 public constant decimalFactor = 10 ** uint256(decimals);
    uint256 public constant initial_supply = 200000000 * decimalFactor;

    constructor(address ownerAdrs) public {
        totalSupply_ = initial_supply;

        preSale(ownerAdrs,totalSupply_);
    }

    function preSale(address _address, uint _amount) internal returns (bool) {
        balances[_address] = _amount;
        emit Transfer(address(0x0), _address, _amount);
    }

    function transfer(address _to, uint256 _value) isRunning public returns (bool) {
        super.transfer(_to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) isRunning public returns (bool) {
        super.transferFrom(_from, _to, _value);
        return true;
    }

}
