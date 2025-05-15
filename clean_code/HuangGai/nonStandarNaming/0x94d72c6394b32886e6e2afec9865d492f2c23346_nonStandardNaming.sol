pragma solidity ^0.5.2;
















library SafeMath {
    function ADD632(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function SUB956(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function MUL63(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function DIV849(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}






contract ERC20Interface {
    function TOTALSUPPLY278() public view returns (uint);
    function BALANCEOF130(address tokenOwner) public view returns (uint balance);
    function ALLOWANCE907(address tokenOwner, address spender) public view returns (uint remaining);
    function TRANSFER757(address to, uint tokens) public returns (bool success);
    function APPROVE878(address spender, uint tokens) public returns (bool success);
    function TRANSFERFROM957(address from, address to, uint tokens) public returns (bool success);

    event TRANSFER675(address indexed from, address indexed to, uint tokens);
    event APPROVAL377(address indexed tokenOwner, address indexed spender, uint tokens);
}







contract KlixioApproveCallFallBack {
    function RECEIVEAPPROVAL890(address from, uint256 tokens, address token, bytes memory data) public;
}





contract KlixioOwnership {
    address public owner;
    address public newOwner;

    event OWNERSHIPTRANSFERRED385(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier ONLYOWNER277 {
        require(msg.sender == owner);
        _;
    }

    function TRANSFEROWNERSHIP498(address _newOwner) public ONLYOWNER277 {
        newOwner = _newOwner;
    }

    function ACCEPTOWNERSHIP929() public {
        require(msg.sender == newOwner);
        emit OWNERSHIPTRANSFERRED385(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

}






contract Klixio is ERC20Interface, KlixioOwnership {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;





    constructor() public {
        symbol = "KLX";
        name = "Klixio";
        decimals = 18;
        _totalSupply = 1000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit TRANSFER675(address(0), owner, _totalSupply);
    }





    function TOTALSUPPLY278() public view returns (uint) {
        return _totalSupply.SUB956(balances[address(0)]);
    }





    function BALANCEOF130(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }







    function TRANSFER757(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].SUB956(tokens);
        balances[to] = balances[to].ADD632(tokens);
        emit TRANSFER675(msg.sender, to, tokens);
        return true;
    }










    function APPROVE878(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit APPROVAL377(msg.sender, spender, tokens);
        return true;
    }











    function TRANSFERFROM957(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].SUB956(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].SUB956(tokens);
        balances[to] = balances[to].ADD632(tokens);
        emit TRANSFER675(from, to, tokens);
        return true;
    }






    function ALLOWANCE907(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }







    function APPROVEANDCALL334(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit APPROVAL377(msg.sender, spender, tokens);
        KlixioApproveCallFallBack(spender).RECEIVEAPPROVAL890(msg.sender, tokens, address(this), data);
        return true;
    }





    function () external payable {
        revert();
    }





    function TRANSFERANYERC20TOKEN783(address tokenAddress, uint tokens) public ONLYOWNER277 returns (bool success) {
        return ERC20Interface(tokenAddress).TRANSFER757(owner, tokens);
    }
}
