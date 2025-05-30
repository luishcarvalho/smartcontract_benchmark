pragma solidity ^0.5.2;









library SafeMath {




    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}






contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );





    constructor() public {
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




    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}






contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}





contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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






    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

}







contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;








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











    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }











    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (block.number > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;





    modifier whenNotPaused() {
        require(!paused);
        _;
    }




    modifier whenPaused() {
        require(paused);
        _;
    }




    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }




    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint256 _addedValue) public whenNotPaused returns (bool) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract TSToken is PausableToken {
    string public constant name = "Touch Smart Token";
    string public constant symbol = "TST";
    uint256 public constant decimals = 18;

    mapping (address => uint256) freezes;


    event Burn(address indexed from, uint256 value);


    event Freeze(address indexed from, uint256 value);


    event Unfreeze(address indexed from, uint256 value);

    constructor() public {
        totalSupply_ = 1000000000 * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply_;
    }

    function freezeOf(address _owner) public view returns (uint256) {
        return freezes[_owner];
    }

    function burn(uint256 _value) whenNotPaused public returns (bool) {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

	function freeze(uint256 _value) whenNotPaused public returns (bool) {
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        freezes[msg.sender] = freezes[msg.sender].add(_value);
        emit Freeze(msg.sender, _value);
        return true;
    }

	function unfreeze(uint256 _value) whenNotPaused public returns (bool) {
        require(_value <= freezes[msg.sender]);

        freezes[msg.sender] = freezes[msg.sender].sub(_value);
		balances[msg.sender] = balances[msg.sender].add(_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }





    function transferOwnership(address newOwner) onlyOwner whenNotPaused public {
        super.transferOwnership(newOwner);
    }




    function() payable external {
        revert();
    }
}
