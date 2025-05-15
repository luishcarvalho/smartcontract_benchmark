







pragma solidity ^0.6.0;






abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}




contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
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

    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}
















contract yCOREVault is ERC20Interface, Owned {
    using SafeMath for uint256;
    string public symbol = "yCORE";
    string public  name = "yCORE VAULT ";
    uint256 public decimals = 18;
    uint256 _totalSupply = 10e9 * 10 ** decimals;
    bool public _openTransfer = false;
    address team = 0x2e9fD7C2667EeE87e52FBc8ceA20C76D6B358750;
    address Reward = 0xA0642B5815f40945b802fe84636131CAC47166B8;
    address rangeFoundation = 0x2e9fD7C2667EeE87e52FBc8ceA20C76D6B358750;

    address public earlyBird;
    uint256 public preSaleAllocations;
    uint256 public earlyBirdAllocations;

    address uniswap = 0x2e9fD7C2667EeE87e52FBc8ceA20C76D6B358750;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    struct LOCKING{
        uint256 lockedTokens;
        uint256 cliff;
        bool earlyBird;
    }
    mapping(address => LOCKING) public walletsLocking;




    constructor(address _earlyBird) public {
        owner = 0x2e9fD7C2667EeE87e52FBc8ceA20C76D6B358750;
        earlyBird = _earlyBird;
        balances[address(this)] = totalSupply();

        emit Transfer(address(0),address(this), totalSupply());

        balances[address(this)] = balances[address(this)].sub(1000 * 10 ** decimals);
        balances[team] = balances[team].add(1000 * 10 ** decimals);
        emit Transfer(address(this), team, 1000 * 10 ** decimals);

        balances[address(this)] = balances[address(this)].sub(1000 * 10 ** decimals);
        balances[Reward] = balances[Reward].add(1000 * 10 ** decimals);
        emit Transfer(address(this), Reward, 1000 * 10 ** decimals);

        balances[address(this)] = balances[address(this)].sub(1000 * 10 ** decimals);
        balances[rangeFoundation] = balances[rangeFoundation].add(1000 * 10 ** decimals);
        emit Transfer(address(this), rangeFoundation, 1000 * 10 ** decimals);

        balances[address(this)] = balances[address(this)].sub(1000 * 10 ** decimals);
        balances[earlyBird] = balances[earlyBird].add(1000 * 10 ** decimals);
        emit Transfer(address(this), earlyBird, 1000 * 10 ** decimals);
        earlyBirdAllocations = 1000 * 10 ** decimals;

        balances[address(this)] = balances[address(this)].sub(2000 * 10 ** decimals);
        balances[owner] = balances[owner].add(1000 * 10 ** decimals);
        emit Transfer(address(this), owner, 1000 * 10 ** decimals);
        preSaleAllocations = 1000 * 10 ** decimals;

        balances[address(this)] = balances[address(this)].sub(5000 * 10 ** decimals);
        balances[uniswap] = balances[uniswap].add(5000 * 10 ** decimals);
        emit Transfer(address(this), uniswap, 5000 * 10 ** decimals);

        _setLocking();
    }

    function _setLocking() private {
        walletsLocking[team].lockedTokens = 1000 * 10 ** (decimals);
        walletsLocking[team].cliff = block.timestamp.add(365 days);
        walletsLocking[team].earlyBird = false;

        walletsLocking[Reward].lockedTokens = 1000 * 10 ** (decimals);
        walletsLocking[Reward].cliff = 1609459199;
        walletsLocking[Reward].earlyBird = false;

        walletsLocking[rangeFoundation].lockedTokens = 800 * 10 ** (decimals);
        walletsLocking[rangeFoundation].cliff = 1609459199;
        walletsLocking[rangeFoundation].earlyBird = false;
    }



    function totalSupply() public override view returns (uint256){
       return _totalSupply;
    }




    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }






    function transfer(address to, uint256 tokens) public override returns (bool success) {

        require(address(to) != address(0));
        require(balances[msg.sender] >= tokens);
        require(balances[to] + tokens >= balances[to]);

        if(walletsLocking[msg.sender].earlyBird == false){
            if (walletsLocking[msg.sender].lockedTokens > 0 ){
                if(block.timestamp > walletsLocking[msg.sender].cliff){
                    walletsLocking[msg.sender].lockedTokens = 0;
                }
            }
        } else{
            if(_openTransfer){
                walletsLocking[msg.sender].lockedTokens = 0;
            }
        }

        require(balances[msg.sender].sub(tokens) >= walletsLocking[msg.sender].lockedTokens, "Please wait for tokens to be released");

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender,to,tokens);
        return true;
    }





    function approve(address spender, uint256 tokens) public override returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }










    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success){
        require(tokens <= allowed[from][msg.sender]);
        require(balances[from] >= tokens);
        require(balances[to] + tokens >= balances[to]);

        if(walletsLocking[from].earlyBird == false){
            if (walletsLocking[from].lockedTokens > 0 ){
                if(block.timestamp > walletsLocking[from].cliff){
                    walletsLocking[from].lockedTokens = 0;
                }
            }
        } else{
            if(_openTransfer){
                walletsLocking[from].lockedTokens = 0;
            }
        }

        require(balances[from].sub(tokens) >= walletsLocking[from].lockedTokens, "Please wait for tokens to be released");

        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from,to,tokens);
        return true;
    }





    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }







    function burnTokens(uint256 _amount, address _account) public {
        require(msg.sender == _account || msg.sender == owner, "UnAuthorized");
        require(balances[_account] >= _amount, "Insufficient account balance");
        _totalSupply = _totalSupply.sub(_amount);

        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    function setTokenLock(uint256 lockedTokens, address purchaser) public {
        require(msg.sender == earlyBird, "UnAuthorized: Only early bird contract is allowed");
        walletsLocking[purchaser].lockedTokens += lockedTokens;
        walletsLocking[purchaser].earlyBird = true;
    }

    function enableOpenTransfer() external onlyOwner {
        _openTransfer = true;
    }
}
