



pragma solidity 0.5.15;














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
























contract ERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    string public desc;
    uint8 public decimals;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowances;

    uint256 _totalSupply;







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed TokenOwner, address indexed spender, uint256 value);




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }




    function allowance(address TokenOwner, address spender) public view returns (uint256) {
        return _allowances[TokenOwner][spender];
    }








    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "ERC20: Not enough in deligation");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: Not Enough balance");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }














    function _approve(address TokenOwner, address spender, uint256 value) internal {
        require(TokenOwner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[TokenOwner][spender] = value;
        emit Approval(TokenOwner, spender, value);
    }







    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

contract Owner {

    address public OwnerAddress;

    modifier isOwner(){
        require( tx.origin == OwnerAddress);

        _;
    }

}

contract IBTCToken is ERC20 , Owner {

    bool public contractState;

    address public TAddr;

    modifier isInActive(){
        require(contractState == false);
        _;
    }
    modifier isTreasury(){
        require(msg.sender == TAddr);
        _;
    }

    constructor(  )
        public
    {
        name = "IBTC";
        symbol = "IBTC";
        desc = "IBTC";
        decimals = 18;
        OwnerAddress = msg.sender;
        contractState = false;
    }

    function setTreasury ( address _TAddres)
        isOwner
        isInActive
        public
        returns ( bool )
    {
        TAddr = _TAddres;
        contractState = true;
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function mint(address recipient, uint256 amount)
        isTreasury
        public
        returns (bool result )
    {
        _mint( recipient , amount );
        result = true;
    }

    function transfer(address recipient, uint256 amount)
        public
        returns (bool result )
    {
        _transfer(msg.sender, recipient , amount );
        result = true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "ERC20: Not enough in deligation");
        _transfer(msg.sender, recipient , amount );
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }


    function allowance(address TokenOwner, address spender) public view returns (uint256) {
        return _allowances[TokenOwner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

}
