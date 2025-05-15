pragma solidity >=0.5.4 <0.6.0;















library SafeMath {
    function ADD53(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function SUB848(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function MUL294(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function DIV305(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}






contract ERC20Interface {
    function TOTALSUPPLY404() public view returns (uint);
    function BALANCEOF531(address tokenOwner) public view returns (uint balance);
    function ALLOWANCE38(address tokenOwner, address spender) public view returns (uint remaining);
    function TRANSFER948(address to, uint tokens) public returns (bool success);
    function APPROVE272(address spender, uint tokens) public returns (bool success);
    function TRANSFERFROM23(address from, address to, uint tokens) public returns (bool success);

    function BURN816(uint256 value) public returns (bool success);
    function BURNFROM553(address from, uint256 value) public returns (bool success);

    function MINT414(address recipient, uint256 value) public returns (bool success);

    event TRANSFER511(address indexed from, address indexed to, uint tokens);
    event APPROVAL847(address indexed tokenOwner, address indexed spender, uint tokens);
    event BURN12(address indexed from, uint256 value);
}







contract ApproveAndCallFallBack {
    function RECEIVEAPPROVAL348(address from, uint256 tokens, address token, bytes memory data) public;
}





contract Owned {
    address public owner;
    address public newOwner;

    event OWNERSHIPTRANSFERRED483(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier ONLYOWNER553 {
        require(msg.sender == owner);
        _;
    }

    function TRANSFEROWNERSHIP255(address _newOwner) public ONLYOWNER553 {
        newOwner = _newOwner;
    }
    function ACCEPTOWNERSHIP507() public {
        require(msg.sender == newOwner);
        emit OWNERSHIPTRANSFERRED483(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}






contract EracoinToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event TRANSFER511(address indexed from, address indexed to, uint tokens);
    event APPROVAL847(address indexed tokenOwner, address indexed spender, uint tokens);
    event BURN12(address indexed from, uint256 tokens);





    constructor() public {
        symbol = "ERCT";
        name = "Eracoin Token";
        decimals = 18;
        _totalSupply = 300000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit TRANSFER511(address(0), owner, _totalSupply);
    }





    function TOTALSUPPLY404() public view returns (uint) {
        return _totalSupply.SUB848(balances[address(0)]);
    }





    function BALANCEOF531(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }







    function TRANSFER948(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].SUB848(tokens);
        balances[to] = balances[to].ADD53(tokens);
        emit TRANSFER511(msg.sender, to, tokens);
        return true;
    }










    function APPROVE272(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit APPROVAL847(msg.sender, spender, tokens);
        return true;
    }











    function TRANSFERFROM23(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].SUB848(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].SUB848(tokens);
        balances[to] = balances[to].ADD53(tokens);
        emit TRANSFER511(from, to, tokens);
        return true;
    }






    function ALLOWANCE38(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }







    function APPROVEANDCALL920(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit APPROVAL847(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).RECEIVEAPPROVAL348(msg.sender, tokens, address(this), data);
        return true;
    }


    function BURN816(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        _totalSupply -= _value;
        emit BURN12(msg.sender, _value);
        return true;
    }


    function BURNFROM553(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        _totalSupply -= _value;
        emit BURN12(_from, _value);
        return true;
    }


    function MINT414(address _recipient, uint256 _value) public returns (bool success) {
        require(msg.sender == owner);
        require(_totalSupply + _value >= _totalSupply);

        _totalSupply += _value;
        balances[_recipient] += _value;
        emit TRANSFER511(address(0), _recipient, _value);
        return true;
    }




    function () external payable {
        revert();
    }





    function TRANSFERANYERC20TOKEN682(address tokenAddress, uint tokens) public ONLYOWNER553 returns (bool success) {
        return ERC20Interface(tokenAddress).TRANSFER948(owner, tokens);
    }
}
