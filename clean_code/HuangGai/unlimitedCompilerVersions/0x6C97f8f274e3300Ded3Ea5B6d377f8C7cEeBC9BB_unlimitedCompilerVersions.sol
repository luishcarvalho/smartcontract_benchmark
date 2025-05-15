







pragma solidity ^0.6.0;











contract Context {


    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

pragma solidity ^0.6.0;













contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;














library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }










    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }












    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }












    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;




interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.6.0;




contract Base is IERC20, Ownable {

    using SafeMath for uint;

    uint256 private _totalSupply;
    uint256 private _stockCount;

    mapping (bytes32 => uint256) public stock;

    address public minter;
    address public burner;
    bool public paused;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    function stockCount() public view returns (uint256) {
        return _stockCount;
    }


    function decimals() public pure returns (uint8) {
        return 4;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) public override view returns (uint256 balance) {
        balance = _balances[who];
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(paused != true, "Contract paused");
        require(to != address(0), "Invalid to address");
        require(from != address(0), "Invalid from address");
        require(_balances[from] >= value, "Insufficient funds");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(from, to, value);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool success) {
        require(to != address(0), "Invalid address");

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);

        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0), "Invalid address");

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function burn(bytes32 serial) public onlyBurner() {
        require(serial != 0x00, "Invalid location or serial");
        uint256 value = stock[serial];

        require(value > 0, "Invalid stock");
        require(_balances[owner()] >= value, "Cannot burn more than you own");

        stock[serial] = 0;
        _balances[owner()] = _balances[owner()].sub(value);

        _stockCount = _stockCount.sub(1);
        _totalSupply = _totalSupply.sub(value);

        emit Transfer(owner(), address(0), value);
        emit Burned(serial, value);
    }

    function mint(address to, bytes32 serial, uint256 value) public onlyMinter() returns(bool) {
        require(serial != 0x00, "Invalid location or serial");
        require(to != address(0), "Invalid to address");
        require(value > 0, "Amount must be greater than zero");

        stock[serial] = value;
        _stockCount = _stockCount.add(1);

        _totalSupply = _totalSupply.add(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(owner(), to, value);
        emit Minted(serial, value);

        return true;
    }

    function updateBurner(address who) public onlyOwner() returns (bool) {
        require(who != address(0), "Invalid address");
        burner = who;
    }

    function updateMinter(address who) public onlyOwner() returns (bool) {
        require(who != address(0), "Invalid address");
        minter = who;
    }

    function pauseContract() public onlyOwner() {
        paused = true;
    }

    event FeeUpdated(uint256 value);
    event Burned(bytes32 indexed serial, uint value);
    event Minted(bytes32 indexed serial, uint value);

    modifier onlyBurner() {
        require(burner == msg.sender, "Sender is not a burner");
        _;
    }

    modifier onlyMinter() {
        require(minter == msg.sender, "Sender is not a minter");
        _;
    }
}

pragma solidity ^0.6.0;


contract Gold is Base {

    function symbol() public pure returns (string memory) {
        return "AUS";
    }

    function name() public pure returns (string memory) {
        return "GS";
    }

    constructor() public {

        burner = msg.sender;
        minter = msg.sender;
        paused = false;
    }
}
