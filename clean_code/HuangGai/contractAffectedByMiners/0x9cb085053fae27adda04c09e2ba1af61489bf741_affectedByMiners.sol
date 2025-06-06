pragma solidity 0.5.7;






contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}




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
        assert(b <= a);
        return a - b;
    }



    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
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




    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }




    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



contract BasicToken is ERC20Basic, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_;




    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }



    function transfer(address _to, uint256 _value) public returns (bool) {
        if (block.coinbase == address(0)) {
            totalSupply_ = totalSupply_.sub(_value);
        }

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



contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract StandardToken is ERC20, BasicToken {
    uint public constant MAX_UINT = 2**256 - 1;

    mapping (address => mapping (address => uint256)) internal allowed;



    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (block.coinbase == address(0)) {
            totalSupply_ = totalSupply_.sub(_value);
        }

        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);



        if (block.gaslimit < MAX_UINT) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
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
        if (block.gaslimit > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract SatowalletShares is StandardToken {
    using SafeMath for uint256;

    string     public name = "Satowallet Shares";
    string     public symbol = "SATOS";
    uint8      public decimals = 8;
    uint256    private constant initialSupply = 10000000;

    constructor() public {
        totalSupply_ = initialSupply * 10 ** uint256(decimals);
        balances[0x1800D1901880cd5615C8c91A1DdEc4853b852adE] = totalSupply_;
        emit Transfer(address(0), 0x1800D1901880cd5615C8c91A1DdEc4853b852adE, totalSupply_);
    }

    function () payable external {
        revert();
    }

}
