pragma solidity ^0.5.4;





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


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}






contract ERC20Mintable is ERC20, MinterRole {






    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}





contract ERC20Capped is ERC20Mintable {
    uint256 private _cap;

    constructor (uint256 cap) public {
        require(cap > 0);
        _cap = cap;
    }




    function cap() public view returns (uint256) {
        return _cap;
    }

    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap);
        super._mint(account, value);
    }
}

contract NeoAdam is ERC20Capped(10000000000 ether) {
   string public name = "NeoAdam";
   string public symbol = "NADM";
   uint8 public decimals = 18;
   address public CFO;
   address public CEO;

   constructor () public {
       CEO = msg.sender;
       CFO = msg.sender;
   }

   function setCEO(address newCEO) external {
       require(tx.origin == CEO);


       CEO = newCEO;
   }

   function setCFO(address newCFO) external {
       require(tx.origin == CEO);

       CFO = newCFO;
   }

   function () payable external {

   }

   function withdrawEther() external {
       require(msg.sender == CFO || msg.sender == CEO);
       msg.sender.transfer(address(this).balance);
   }

   function removeMinter(address account) external {
       require(msg.sender == CFO || msg.sender == CEO);
       _removeMinter(account);
   }
}
