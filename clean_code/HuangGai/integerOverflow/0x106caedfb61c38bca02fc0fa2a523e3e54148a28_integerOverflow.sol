



pragma solidity 0.5.17;





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

        uint256 c = a - b;

        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
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





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }





    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}





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
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }









    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }











    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }











    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
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
      _totalSupply = _totalSupply.sub(value);
      _balances[account] = _balances[account].sub(value);
      emit Transfer(account, address(0), value);
    }

}

contract Pausable is Ownable{
    event Paused();
    event Unpaused();

    bool private _paused;

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

   function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused();
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused();
    }

}

contract EG is ERC20, Ownable, Pausable{
    event LockAccount(address indexed account);
    event UnlockAccount(address indexed account);
    event RestoreTokens(address indexed _token, uint256 _restoreBalance);

    string public constant name = "EG";
    string public constant symbol = "EG";
    uint8 public constant decimals = 18;

    mapping (address => bool) private lockedAccountList;

    constructor (uint256 initialBalance) public {
        uint256 _initialBalance = initialBalance;
        _mint(msg.sender, _initialBalance);
    }

    function _transfer(address from, address to, uint256 value) whenNotPaused internal {
        require(!isLockedAccount(from) && !isLockedAccount(to));
        return super._transfer(from, to, value);
    }

    function isLockedAccount(address account) public view returns (bool) {
        return lockedAccountList[account];
    }

    function lockAccount(address account) onlyOwner public {
        lockedAccountList[account] = true;
        emit LockAccount(account);
    }

    function unlockAccount(address account) onlyOwner public {
        lockedAccountList[account] = false;
        emit UnlockAccount(account);
    }

    function mint(address account, uint256 amount) onlyOwner public {
        _mint(account, amount);
    }

    function burn(uint256 amount) onlyOwner public {
        _burn(msg.sender, amount);
    }

    function restoreTokens(address _token, uint256 _restoreBalance) public onlyOwner {
        IERC20 token = IERC20(_token);

        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance >= _restoreBalance);

        token.transfer(msg.sender, _restoreBalance);
        emit RestoreTokens(_token, _restoreBalance);
    }
}
