

























pragma solidity 0.7.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
}

contract LexToken {
    using SafeMath for uint256;
    address payable public manager;
    address public resolver;
    uint8   public decimals;
    uint256 public saleRate;
    uint256 public totalSupply;
    uint256 public totalSupplyCap;
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    string  public details;
    string  public name;
    string  public symbol;
    bool    public forSale;
    bool    private initialized;
    bool    public transferable;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BalanceResolution(string indexed resolution);
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public nonces;

    modifier onlyManager {
        require(msg.sender == manager, "!manager");
        _;
    }

    function init(
        address payable _manager,
        address _resolver,
        uint8 _decimals,
        uint256 managerSupply,
        uint256 _saleRate,
        uint256 saleSupply,
        uint256 _totalSupplyCap,
        string memory _details,
        string memory _name,
        string memory _symbol,
        bool _forSale,
        bool _transferable
    ) external {
        require(!initialized, "initialized");
        manager = _manager;
        resolver = _resolver;
        decimals = _decimals;
        saleRate = _saleRate;
        totalSupplyCap = _totalSupplyCap;
        details = _details;
        name = _name;
        symbol = _symbol;
        forSale = _forSale;
        initialized = true;
        transferable = _transferable;
        _mint(manager, managerSupply);
        _mint(address(this), saleSupply);

        uint256 chainId;
        assembly {chainId := chainid()}
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes("1")),
            chainId,
            address(this)));
    }

    receive() external payable {
        require(forSale, "!forSale");
        (bool success, ) = manager.call{value: msg.value}("");
        require(success, "!transfer");
        uint256 value = msg.value.mul(saleRate);
        _transfer(address(this), msg.sender, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(value == 0 || allowances[owner][spender] == 0, "!reset");
        allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function balanceResolution(address from, address to, uint256 value, string memory resolution) external {
        require(msg.sender == resolver, "!resolver");
        _transfer(from, to, value);
        emit BalanceResolution(resolution);
    }

    function burn(uint256 value) external {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);

        totalSupply = totalSupply.sub(value);

        emit Transfer(msg.sender, address(0), value);
    }


    function permit(address owner, address spender, uint256 deadline, uint256 value, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "expired");
        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline));
        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == owner, "!signer");
        _approve(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(transferable, "!transferable");
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferBatch(address[] memory to, uint256[] memory value) external {
        require(to.length == value.length, "!to/value");
        require(transferable, "!transferable");
        for (uint256 i = 0; i < to.length; i++) {
            _transfer(msg.sender, to[i], value[i]);
        }
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(transferable, "!transferable");
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(value);

        _transfer(from, to, value);
        return true;
    }




    function _mint(address to, uint256 value) internal {
        require(totalSupply.add(value) <= totalSupplyCap, "capped");
        balanceOf[to] = balanceOf[to].add(value);
        totalSupply = totalSupply.add(value);
        emit Transfer(address(0), to, value);
    }

    function mint(address to, uint256 value) external onlyManager {
        _mint(to, value);
    }

    function mintBatch(address[] memory to, uint256[] memory value) external onlyManager {
        require(to.length == value.length, "!to/value");
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], value[i]);
        }
    }

    function updateGovernance(address payable _manager, address _resolver, string memory _details) external onlyManager {
        manager = _manager;
        resolver = _resolver;
        details = _details;
    }

    function updateSale(uint256 _saleRate, uint256 saleSupply, bool _forSale) external onlyManager {
        saleRate = _saleRate;
        forSale = _forSale;
        _mint(address(this), saleSupply);
    }

    function updateTransferability(bool _transferable) external onlyManager {
        transferable = _transferable;
    }
}
