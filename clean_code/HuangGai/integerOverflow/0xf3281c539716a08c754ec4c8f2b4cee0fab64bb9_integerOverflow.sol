



pragma solidity 0.5.11;





library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor() public {
        owner = msg.sender;
    }





    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }





    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}






contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}






contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) internal balances;






    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0) && _to != address(this));


        balances[msg.sender] = balances[msg.sender].sub(_value);

        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }






    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}





contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}









contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;







    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0) && _to != address(this));

        uint256 _allowance = allowed[_from][msg.sender];




        balances[_from] = balances[_from].sub(_value);

        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = _allowance.sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }











    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }







    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }







    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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







contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);





    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);



        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);

        totalSupply = totalSupply.sub(_value);

        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, bytes calldata _extraData) external;
}

contract Markaccy is BurnableToken, Ownable {

    string public constant name = "Markaccy";
    string public constant symbol = "MKCY";
    uint public constant decimals = 18;

    uint256 public constant initialSupply = 100000000 * (10 ** uint256(decimals));


    constructor () public {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function approveAndCall(address _spender, uint256 _value, bytes calldata _extraData)
        external
        returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, _extraData);
            return true;
        }
    }

    function transferAnyERC20Token(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        ERC20(_tokenAddress).transfer(_to, _amount);
    }
}
