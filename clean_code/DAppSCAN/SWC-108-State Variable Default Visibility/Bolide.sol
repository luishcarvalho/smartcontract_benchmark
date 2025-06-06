

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IBEP20 {



    function totalSupply() external view returns (uint256);




    function decimals() external view returns (uint8);




    function symbol() external view returns (string memory);




    function name() external view returns (string memory);




    function getOwner() external view returns (address);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address _owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Bolide is Context, IBEP20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    uint256 timestampCreated;
    uint256 private immutable _cap;





    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
        _name = "Bolide";
        _symbol = "BLID";
        timestampCreated = block.timestamp;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(timestampCreated + 1 days > block.timestamp, "Mint time was finished");
        _mint(account, amount);
    }




    function getOwner() external view returns (address) {
        return owner();
    }




    function name() public view override returns (string memory) {
        return _name;
    }





    function symbol() public view override returns (string memory) {
        return _symbol;
    }














    function decimals() public pure override returns (uint8) {
        return 18;
    }




    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view override returns (uint256 balance) {
        return _balances[account];
    }




    function cap() public view virtual returns (uint256) {
        return _cap;
    }









    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }






    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }












    function burnFrom(address account, uint256 amount) public {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }














    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }















    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal {
        require(_totalSupply + amount <= _cap, "ERC20Capped: cap exceeded");
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }














    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
