




pragma solidity >=0.6.2 <0.7.0;





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





interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}







contract ReentrancyGuard {

    uint256 private _guardCounter;

    constructor () internal {


        _guardCounter = 1;
    }








    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}





contract Pausable is Ownable {
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




    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }




    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}






contract Best is IERC20, Ownable, ReentrancyGuard, Pausable  {

   using SafeMath for uint256;

   event ReceivedEther(address account,  uint256 value);

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;


    string private _name;

    string private _symbol;

    uint8 private _decimals;

    uint256 private _initSupply;

    uint256 private _totalSupply;

    uint256 private _weiRaised;








     function _mint(address account, uint256 value) internal {
         require(account != address(0));
         _totalSupply = _totalSupply.add(value);
         _balances[account] = _balances[account].add(value);
         emit Transfer(address(0), account, value);
     }







      function mint(address to, uint256 value) public onlyOwner returns (bool) {
          _mint(to, value);
          return true;
      }

     constructor (string memory name, string memory symbol, uint8 decimals, uint256 initSupply) public {
         _name = name;
         _symbol = symbol;
         _decimals = decimals;
         _initSupply = initSupply.mul(10 **uint256(decimals));
         _mint(msg.sender, _initSupply);
     }




     function name() public view returns (string memory) {
         return _name;
     }




     function symbol() public view returns (string memory) {
         return _symbol;
     }




     function decimals() public view returns (uint8) {
         return _decimals;
     }



     function initSupply() public view returns (uint256) {
         return _initSupply;
     }




    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }






    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }







    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        require(value <= _balances[account]);
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }







     function burn(address from, uint256 value) public onlyOwner returns (bool) {
         _burn(from, value);
         return true;
     }







    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0));
        require(to != address(0));
        require(value <= _balances[from]);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }






    function transfer(address to, uint256 value) public whenNotPaused override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }






    function transferByOwner(address to, uint256 value) public onlyOwner returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }










    function approve(address spender, uint256 value) public whenNotPaused override returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }







    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }











    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }











    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);

        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }









    function transferFrom(address from, address to, uint256 value) public whenNotPaused override returns (bool) {
        require(from != address(0));
        require(value <= _allowed[from][msg.sender]);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }




     receive() external payable {

         _weiRaised = _weiRaised.add(msg.value);
         emit ReceivedEther(msg.sender, msg.value);
     }




    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }




   function withdrawal(address payable walletWD, uint256 valueWD) public nonReentrant onlyOwner {
         require(walletWD != address(0));
         require(valueWD > 0 && valueWD <= weiRaised());

       walletWD.transfer(valueWD);

       _weiRaised = _weiRaised.sub(valueWD);

    }

}
