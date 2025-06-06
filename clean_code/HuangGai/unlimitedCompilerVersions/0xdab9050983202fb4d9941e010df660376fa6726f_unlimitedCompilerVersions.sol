



pragma solidity ^0.5.14;











contract Context {


    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}





library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }




    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }




    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }





    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract LexDAORole is Context {
    using Roles for Roles.Role;

    event LexDAOAdded(address indexed account);
    event LexDAORemoved(address indexed account);

    Roles.Role private _lexDAOs;

    constructor () internal {
        _addLexDAO(_msgSender());
    }

    modifier onlyLexDAO() {
        require(isLexDAO(_msgSender()), "LexDAORole: caller does not have the LexDAO role");
        _;
    }

    function isLexDAO(address account) public view returns (bool) {
        return _lexDAOs.has(account);
    }

    function addLexDAO(address account) public onlyLexDAO {
        _addLexDAO(account);
    }

    function renounceLexDAO() public {
        _removeLexDAO(_msgSender());
    }

    function _addLexDAO(address account) internal {
        _lexDAOs.add(account);
        emit LexDAOAdded(account);
    }

    function _removeLexDAO(address account) internal {
        _lexDAOs.remove(account);
        emit LexDAORemoved(account);
    }
}














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

























contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }







    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}




contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;






    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}





contract IChai {
    function transfer(address dst, uint wad) external returns (bool);

    function move(address src, address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) public returns (bool);
    function approve(address usr, uint wad) external returns (bool);
    function balanceOf(address usr) external returns (uint);


    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;

    function dai(address usr) external returns (uint wad);
    function dai(uint chai) external returns (uint wad);


    function join(address dst, uint wad) external;


    function exit(address src, uint wad) public;


    function draw(address src, uint wad) external returns (uint chai);
}

contract LexBank is LexDAORole, ERC20, ERC20Detailed {
    address private lexBank = address(this);


    address private $DAIaddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    ERC20 public $DAI = ERC20($DAIaddress);


    address private $CHAIaddress = 0x06AF07097C9Eeb7fD685c692751D5C66dB49c215;
    IChai public $CHAI = IChai($CHAIaddress);


    string public emoji = "111111";
    string public lexDAOchat = "lexdao.chat || lexdao.club";
    uint8 public version = 1;


    address payable public lexDAO = 0x97103fda00a2b47EaC669568063C00e65866a633;

    event LexDAOPaid(uint256 indexed payment, string indexed details);
    event LexDAOTransferred(address indexed newLexDAO);

    constructor () public ERC20Detailed("LexDAO Banknote", "LXB", 18) {
        $DAI.approve($CHAIaddress, uint(-1));
    }

    function mint$LXB(uint256 amount) public {
        $DAI.transferFrom(msg.sender, lexBank, amount);
        uint256 balance = $CHAI.balanceOf(lexBank);
        $CHAI.join(lexBank, amount);
        _mint(msg.sender, $CHAI.balanceOf(lexBank).sub(balance));
    }

    function redeem$LXB(uint256 amount) public {
        $CHAI.exit(lexBank, amount);
        uint256 receivedDai = $DAI.balanceOf(lexBank);
        $DAI.transferFrom(lexBank, msg.sender, receivedDai);
        _burn(msg.sender, amount);
    }


    function payLexDAO(string memory details) public payable {
        lexDAO.transfer(msg.value);

        emit LexDAOPaid(msg.value, details);
    }

    function resolve$LXB(address from, address to, uint256 amount) public onlyLexDAO {
        _transfer(from, to, amount);
    }

    function transferLexDAO(address payable newLexDAO) public {
        require(msg.sender == lexDAO);
        lexDAO = newLexDAO;

        emit LexDAOTransferred(newLexDAO);
    }
}
