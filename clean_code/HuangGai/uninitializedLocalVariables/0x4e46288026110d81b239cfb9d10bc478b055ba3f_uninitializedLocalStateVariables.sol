pragma solidity 0.5.4;





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






library SafeMath {



    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c ;

        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c ;



        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c ;


        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c ;

        require(c >= a);

        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract MPD is IERC20, Ownable, Pausable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    string private _name ;

    string private _symbol ;

    uint256 private _decimals ;

    uint256 private _totalSupply;
    string public certificate;

    uint256 private initialAmount ;


    constructor(string memory certHash) public {
        certificate = certHash;
        mint(msg.sender, initialAmount);
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










    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }









    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
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







    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        require(to != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(address(0), to, value);
        return true;
    }





    function burn(uint256 value) onlyOwner public {
        require(msg.sender != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        emit Transfer(msg.sender, address(0), value);
    }





    function setCertificate(string memory hash) public onlyOwner {
        certificate = hash;
    }
}
