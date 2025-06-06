



pragma solidity ^0.5.0;














library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
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

























contract ERC20 is IERC20 {
    using SafeMath for uint256;

  function bug_unchk_send21() payable public{
      msg.sender.transfer(1 ether);}
  mapping (address => uint256) private _balances;

  function bug_unchk_send10() payable public{
      msg.sender.transfer(1 ether);}
  mapping (address => mapping (address => uint256)) private _allowances;

  function bug_unchk_send22() payable public{
      msg.sender.transfer(1 ether);}
  uint256 private _totalSupply;




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
function bug_unchk_send2() payable public{
      msg.sender.transfer(1 ether);}




    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
function bug_unchk_send17() payable public{
      msg.sender.transfer(1 ether);}









    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
function bug_unchk_send3() payable public{
      msg.sender.transfer(1 ether);}




    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
function bug_unchk_send9() payable public{
      msg.sender.transfer(1 ether);}








    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
function bug_unchk_send25() payable public{
      msg.sender.transfer(1 ether);}













    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
function bug_unchk_send19() payable public{
      msg.sender.transfer(1 ether);}













    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
function bug_unchk_send26() payable public{
      msg.sender.transfer(1 ether);}















    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
function bug_unchk_send20() payable public{
      msg.sender.transfer(1 ether);}















    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
function bug_unchk_send32() payable public{
      msg.sender.transfer(1 ether);}










    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
function bug_unchk_send4() payable public{
      msg.sender.transfer(1 ether);}












    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
function bug_unchk_send7() payable public{
      msg.sender.transfer(1 ether);}














    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
function bug_unchk_send23() payable public{
      msg.sender.transfer(1 ether);}







    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
function bug_unchk_send14() payable public{
      msg.sender.transfer(1 ether);}
}




contract ERC20Detailed is IERC20 {
  function bug_unchk_send12() payable public{
      msg.sender.transfer(1 ether);}
  string private _name;
  function bug_unchk_send11() payable public{
      msg.sender.transfer(1 ether);}
  string private _symbol;
  function bug_unchk_send1() payable public{
      msg.sender.transfer(1 ether);}
  uint8 private _decimals;






    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
function bug_unchk_send30() payable public{
      msg.sender.transfer(1 ether);}




    function name() public view returns (string memory) {
        return _name;
    }
function bug_unchk_send8() payable public{
      msg.sender.transfer(1 ether);}





    function symbol() public view returns (string memory) {
        return _symbol;
    }
function bug_unchk_send27() payable public{
      msg.sender.transfer(1 ether);}













    function decimals() public view returns (uint8) {
        return _decimals;
    }
function bug_unchk_send31() payable public{
      msg.sender.transfer(1 ether);}
}

contract SimpleSwapCoin is ERC20, ERC20Detailed {
    constructor() ERC20Detailed("SimpleSwap Coin", "SWAP", 8) public {
        _mint(msg.sender, 100000000 * (10 ** 8));
    }
function bug_unchk_send13() payable public{
      msg.sender.transfer(1 ether);}
}
