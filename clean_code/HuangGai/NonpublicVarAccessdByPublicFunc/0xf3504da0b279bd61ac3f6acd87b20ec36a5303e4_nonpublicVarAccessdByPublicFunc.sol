



pragma solidity 0.6.6;










library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) { c = a + b; require(c >= a); }
    function sub(uint a, uint b) internal pure returns (uint c) { require(b <= a); c = a - b; }
    function mul(uint a, uint b) internal pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); }
    function div(uint a, uint b) internal pure returns (uint c) { require(b > 0); c = a / b; }
}






abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}




abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes memory data) public virtual;
}




contract Owned {
    address internal owner;
    address internal newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}




contract VTBC is ERC20Interface, Owned {
    using SafeMath for uint;

    bool public running = true;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;




    constructor() public {
        symbol = "VTBC";
        name = "VTBC";
        decimals = 18;
        _totalSupply = 1000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }




    function totalSupply() public override  view returns (uint) {
        return _totalSupply;
    }




    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }




    function transfer(address to, uint tokens) public override returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(to != address(0));
        _transfer(msg.sender, to, tokens);
        return true;
    }




    function _transfer(address from, address to, uint256 tokens) internal {
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
    }









    function approve(address spender, uint tokens) public override returns (bool success) {
        _approve(msg.sender, spender, tokens);
        return true;
    }




    function increaseAllowance(address spender, uint addedTokens) public returns (bool success) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(addedTokens));
        return true;
    }




    function decreaseAllowance(address spender, uint subtractedTokens) public returns (bool success) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedTokens));
        return true;
    }






    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        _approve(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }




    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0));
        require(spender != address(0));
        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }




    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        require(to != address(0));
        _approve(from, msg.sender, allowed[from][msg.sender].sub(tokens));
        _transfer(from, to, tokens);
        return true;
    }





    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }




    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }




    function multisend(address[] memory to, uint[] memory values) public onlyOwner returns (uint) {
        require(to.length == values.length);
        require(to.length < 100);
        uint sum;
        for (uint j; j < values.length; j++) {
            sum += values[j];
        }
        balances[owner] = balances[owner].sub(sum);
        for (uint i; i < to.length; i++) {
            balances[to[i]] = balances[to[i]].add(values[i]);
            emit Transfer(owner, to[i], values[i]);
        }
        return(to.length);
    }
}
