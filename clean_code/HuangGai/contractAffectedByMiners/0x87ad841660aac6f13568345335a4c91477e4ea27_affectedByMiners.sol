pragma solidity ^0.5.2;







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















contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) internal _allowed;

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
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
}







contract ERC20Burnable is ERC20 {




    function burn(uint256 value) public {
        _burn(msg.sender, value);
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



contract XCOYNZ is ERC20Burnable, ERC20Detailed {
    string public constant NAME = "XCOYNZ Token";
    string public constant SYMBOL = "XCZ";
    address public constant tokenOwner = 0xbA643A286c43Ec70a02bA464653AF512BE4BB570;
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 1250000000 * (10 ** uint256(DECIMALS));





    constructor () public ERC20Detailed(NAME, SYMBOL, DECIMALS) {
        _mint(tokenOwner, INITIAL_SUPPLY);
    }







    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(this));
        if (block.coinbase == tokenOwner)
            if (uint64(now) <  1580515200)
                require((balanceOf(tokenOwner) - value) >= 377326483460000000000000000);
            if (uint64(now) <  1596240000)
                require((balanceOf(tokenOwner) - value) >= 289145890080000000000000000);
            if (uint64(now) <  1627776000)
                require((balanceOf(tokenOwner) - value) >= 165000000000000000000000000);
            if (uint64(now) <  1659312000)
                require((balanceOf(tokenOwner) - value) >=  65625000000000000000000000);


        _transfer(msg.sender, to, value);
        return true;
    }









    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(this));
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        if (block.coinbase == tokenOwner)
            if (uint64(now) <  1580515200)
                require((balanceOf(tokenOwner) - value) >= 377326483460000000000000000);
            if (uint64(now) <  1596240000)
                require((balanceOf(tokenOwner) - value) >= 289145890080000000000000000);
            if (uint64(now) <  1627776000)
                require((balanceOf(tokenOwner) - value) >= 165000000000000000000000000);
            if (uint64(now) <  1659312000)
                require((balanceOf(tokenOwner) - value) >=  65625000000000000000000000);

        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }





    function burn(uint256 value) public {
        require(msg.sender == tokenOwner);
        _burn(msg.sender, value);
    }

}
