

pragma solidity 0.8.10;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract claimToken is IERC20 {
    uint8 public decimals;
    address public owner;
    uint256 public _totalSupply;
    uint256 public initialSupply;
    uint256 public constant maxCap = 1000000000 * 10**18;
    string public name;
    string public symbol;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) internal admins;

    modifier onlyAdmin() {
        require(admins[msg.sender]);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }




    constructor(string memory tokenName, string memory tokenSymbol) {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = 18;
        _totalSupply = 0;
        initialSupply = _totalSupply;
        owner = msg.sender;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }



    function addAdmin(address account) public onlyOwner {
        admins[account] = true;
    }



    function removeAdmin(address account) public onlyOwner {
        admins[account] = false;
    }



    function isAdmin(address account) public view onlyOwner returns (bool) {
        return admins[account];
    }


    function totalSupply() external view override returns (uint256) {
        return _totalSupply - balances[address(0)];
    }



    function balanceOf(address tokenOwner)
        external
        view
        override
        returns (uint256 getBalance)
    {
        return balances[tokenOwner];
    }


    function allowance(address tokenOwner, address spender)
        external
        view
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 tokens)
        external
        override
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint256 tokens)
        external
        override
        returns (bool success)
    {
        require(
            to != address(0),
            "claimToken: Address should not be a zero"
        );
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external override returns (bool success) {
        require(
            to != address(0),
            "claimToken: Address should not be a zero"
        );
        balances[from] = balances[from] - tokens;
        allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(from, to, tokens);
        return true;
    }



    function burn( uint256 tokens) external  {
        uint256 accountBalance = balances[msg.sender];
        require(
            accountBalance >= tokens,
            "claimToken: Burn amount exceeds Balance"
        );
        balances[msg.sender] = accountBalance - tokens;
        _totalSupply = _totalSupply - tokens;
        emit Transfer(msg.sender, address(0), tokens);
    }



    function mint(address account, uint256 tokens) external onlyAdmin {
        require(
            account != address(0),
            "claimToken: Mint from a zero address"
        );
        require(
            _totalSupply + tokens <= maxCap,
            "claimToken Max supply reached, 1 Billion tokens minted."
        );
        balances[account] = balances[account] + tokens;
        _totalSupply = _totalSupply + tokens;
        emit Transfer(address(0), account, tokens);
    }
}
