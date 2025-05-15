

pragma solidity =0.8.6;
import "./OwnableToken.sol";
import "./ERC20Interface.sol";

contract AgriUTToken is OwnableToken, ERC20Interface
{
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;
    uint256 private _totalSupply;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _frozenAccounts;
    mapping(address => bool) private _managedAccounts;

    event FrozenFunds(address indexed target, bool frozen);
    event Burn(address indexed from, uint256 value);
    event ManagedAccount(address indexed target, bool managed);








































































    function transfer(address _to, uint256 _value) public override returns (bool success)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }








    function transferFrom( address sender, address recipient, uint256 amount) public virtual override returns (bool)
    {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }








    function transferFromGivenApproval( address sender, address recipient, uint256 amount) external onlyOwner returns (bool)
    {
        require(_managedAccounts[sender], "Not a Managed wallet");
        _transfer(sender, recipient, amount);
        return true;
    }





    function approveOwnerToManage(bool allowed) external returns (bool)
    {
        _managedAccounts[msg.sender] = allowed;
        emit ManagedAccount(msg.sender, allowed);
        return true;
    }






    function approve(address spender, uint256 amount) public virtual override returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve( address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }






    function allowance(address tokenOwner, address spender) public view override returns (uint256 remaining)
    {
        return _allowances[tokenOwner][spender];
    }




    function freezeAccount(address target, bool freeze) onlyOwner external
    {
        require(target != owner(), "Cannot freeze the owner account");
        _frozenAccounts[target] = freeze;
        emit FrozenFunds(target, freeze);
    }






    function burn(uint256 _value) external returns (bool success)
    {
        _burn(msg.sender, _value);
        return true;
    }







    function burnWithApproval(address _from, uint256 _value) external onlyOwner returns (bool success)
    {
        require(_managedAccounts[_from], "Not a Managed wallet");
        _burn(_from, _value);
        return true;
    }







    function burnFrom(address _from, uint256 _value) external returns (bool success)
    {
        uint256 currentAllowance = allowance(_from, msg.sender);
        require(currentAllowance >= _value, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(_from, msg.sender, currentAllowance - _value);
        }
        _burn(_from, _value);
        return true;
    }

    function _burn(address _address, uint256 _value) internal
    {
        require(_address != address(0), "ERC20: burn from the zero address");
        require(_balances[_address] >= _value, "ERC20: burn amount exceeds balance");
        require(!_frozenAccounts[_address], "Account is frozen");
        _balances[_address] -= _value;
        _totalSupply -= _value;
        emit Burn(_address, _value);
    }
}
