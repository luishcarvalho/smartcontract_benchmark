



pragma solidity ^0.5.11;





library SafeMath {



    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }




    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }





    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return a / b;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}






interface IERC20{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}





contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }





    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }








    function rescueTokens(address tokenAddr, address receiver, uint256 amount) external onlyOwner {
        IERC20 _token = IERC20(tokenAddr);
        require(receiver != address(0));
        uint256 balance = _token.balanceOf(address(this));

        require(balance >= amount);
        assert(_token.transfer(receiver, amount));
    }




    function withdrawEther(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0));

        uint256 balance = address(this).balance;

        require(balance >= amount);
        to.transfer(amount);
    }
}





contract Pausable is Ownable {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    constructor () internal {
        _paused = false;
    }




    function paused() public view returns (bool) {
        return _paused;
    }




    modifier whenNotPaused() {
        require(!_paused);
        _;
    }




    modifier whenPaused() {
        require(_paused);
        _;
    }




    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }




    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}




contract ANTDEX is Ownable, Pausable, IERC20 {
    using SafeMath for uint256;

    string private _name = "ANT DEX";
    string private _symbol = "ANT";
    uint256 private _decimals = 6;
    uint256 private _totalSupply = 2100 * 10**4 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    event Donate(address indexed account, uint256 amount);




    constructor(address account) public {

        _owner = account;

        require(account != address(0));
        _balances[account] = _totalSupply;
        emit Transfer(address(0), account, _totalSupply);
    }




    function () external payable {
        emit Donate(msg.sender, msg.value);
    }





    function name() public view returns (string memory) {
        return _name;
    }




    function symbol() public view returns (string memory) {
        return _symbol;
    }




    function decimals() public view returns (uint256) {
        return _decimals;
    }




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }






    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }







    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }






    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {

        _transfer(msg.sender, to, value);
        return true;
    }






    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }






    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }






    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }






    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {




        uint _allowance = _allowed[from][msg.sender];




        uint MAX_UINT = 2^256-1;

        if (block.number < MAX_UINT) {
            _allowed[from][msg.sender] = _allowance.sub(value);
        }
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
    }







    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }







    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0));
        require(spender != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

}
