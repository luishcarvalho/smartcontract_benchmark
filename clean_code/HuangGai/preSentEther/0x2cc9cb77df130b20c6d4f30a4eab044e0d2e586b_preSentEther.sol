pragma solidity ^0.5.3;





interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {



    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }




    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }




    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }





    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner());
        _;
    }




    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }








    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }





    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }






    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }







    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }






    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }










    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }









    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
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







    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }








    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }







    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }







    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }









    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }

    function _sendBatchCS(address[] memory _recipients, uint[] memory _values) internal returns (bool) {
        require(_recipients.length == _values.length, "Inconsistent array lengths");
        uint senderBalance = _balances[msg.sender];
        for (uint i = 0; i < _values.length; i++) {
            uint value = _values[i];
            address to = _recipients[i];
            require(senderBalance >= value,"Not enough balance");
            senderBalance = senderBalance - value;
            _balances[to] += value;
            emit Transfer(msg.sender, to, value);
        }
        _balances[msg.sender] = senderBalance;
        return true;
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

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




    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }




    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract Batcher is Ownable{

    address public batcher;

    event NewBatcher(address newMinter);

    modifier ownerOrBatcher()  {
        require ((msg.sender == batcher) || isOwner(),"not authorised");
        _;
    }

    function setBatcher (address newBatcher) external onlyOwner {
        batcher = newBatcher;
        emit NewBatcher(batcher);
    }

}
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

contract RevShare is ERC20Pausable, Ownable, Batcher {

    string  public name     = "HALO Revenue Share";
    string  public symbol   = "HALO";
    uint8   public decimals = 0;

    mapping(address => uint) public lastUpdated;
    mapping(address => mapping(address=>uint)) public bookedRevenueDue;

    mapping(address=>uint)[]   public allocations;
    mapping(address=>bool) public tokensShared;
    address[]   public tokenList;


    constructor(address owner_) public {
        batcher = 0xB6f9E6D9354b0c04E0556A168a8Af07b2439865E;
        transferOwnership(owner_);
        _mint(owner_, 1000000);
    }


    function update(address whom) private {

        if (lastUpdated[whom] >= allocations.length) return;
        uint myBalance = balanceOf(whom);
        if (address(this).balance == 0) return;
        uint supply = totalSupply();

        mapping(address=>uint) storage myRevenue = allocations[lastUpdated[whom]];
        mapping(address=>uint) storage myRevenueBooked = bookedRevenueDue[whom];
        for (uint i = 0; i < tokenList.length; i++) {
            uint value = myRevenue[tokenList[i]].mul(myBalance).div(supply);
            if (value != 0) {
                myRevenueBooked[tokenList[i]] = myRevenueBooked[tokenList[i]].add(value);
            }
        }
        lastUpdated[whom] = allocations.length;
    }

    function transfer(address to, uint value) public returns (bool) {
        update(msg.sender);
        update(to);
        return super.transfer(to,value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        update(from);
        update(to);
        return super.transferFrom(from,to,value);
    }


    function addRevenueInTokens(ERC20 token, uint value) public onlyOwner {
        allocations.length += 1;
        require(token.transferFrom(msg.sender, address(this),value),"cannot slurp the tokens");
        if (!tokensShared[address(token)]) {
            tokensShared[address(token)] = true;
            tokenList.push(address(token));
        }
        for (uint period = 0;period < allocations.length; period++) {
            allocations[period][address(token)] = allocations[period][address(token)].add(value);
        }
    }

    function addRevenueInEther() public payable onlyOwner {
        allocations.length += 1;
        require(msg.value > 0,"nothing to do");
        if (!tokensShared[address(0)]) {
            tokensShared[address(0)] = true;
            tokenList.push(address(0));
        }
        for (uint period = 0;period < allocations.length; period++) {
            allocations[period][address(0)] = allocations[period][address(0)].add(msg.value);
        }
    }

    function claimMyEther() public {
        claimEther(msg.sender);
    }

    function claimEther(address payable toWhom) whenNotPaused public {
        update(msg.sender);
        uint value = bookedRevenueDue[msg.sender][address(0)];
        bookedRevenueDue[msg.sender][address(0)] = 0;
        toWhom.transfer(value);
    }

    function claimMyToken(ERC20 token) whenNotPaused public {
        claimToken(token,msg.sender);
    }

    function claimToken(ERC20 token, address toWhom) public {
        update(msg.sender);
        uint value = bookedRevenueDue[msg.sender][address(token)];
        bookedRevenueDue[msg.sender][address(token)] = 0;
        require(token.transfer(toWhom,value),"Cannot send token");
    }

    function sendBatchCS(address[] memory _recipients, uint[] memory _values) public ownerOrBatcher whenNotPaused returns (bool) {
        return _sendBatchCS(_recipients, _values);
    }

}
