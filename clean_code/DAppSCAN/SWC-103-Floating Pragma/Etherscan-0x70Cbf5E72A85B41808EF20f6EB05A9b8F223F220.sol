









pragma solidity ^0.8.0;




interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address to, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}






pragma solidity ^0.8.0;







interface IERC20Metadata is IERC20 {



    function name() external view returns (string memory);




    function symbol() external view returns (string memory);




    function decimals() external view returns (uint8);
}






pragma solidity ^0.8.0;











abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}






pragma solidity ^0.8.0;





























contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;










    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }




    function name() public view virtual override returns (string memory) {
        return _name;
    }





    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }














    function decimals() public view virtual override returns (uint8) {
        return 18;
    }




    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }









    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }




    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }











    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

















    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }















    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }










    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }














    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }









    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }















    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}















    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}





pragma solidity ^0.8.0;






abstract contract ERC20Mintable is ERC20 {


  bool private _mintingFinished = false;




  event MintFinished();




  modifier canMint() {
    require(!_mintingFinished, "ERC20Mintable: minting is finished");
    _;
  }




  function mintingFinished() public view returns (bool) {
    return _mintingFinished;
  }









  function mint(address account, uint256 amount) public canMint {
    _mint(account, amount);
  }






  function finishMinting() public canMint {
    _finishMinting();
  }




  function _finishMinting() internal virtual {
    _mintingFinished = true;

    emit MintFinished();
  }
}






pragma solidity ^0.8.0;








abstract contract ERC20Burnable is Context, ERC20 {





    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }












    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}






pragma solidity ^0.8.0;





abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;





    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }




    function cap() public view virtual returns (uint256) {
        return _cap;
    }




    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}






pragma solidity ^0.8.0;











abstract contract Pausable is Context {



    event Paused(address account);




    event Unpaused(address account);

    bool private _paused;




    constructor() {
        _paused = false;
    }




    function paused() public view virtual returns (bool) {
        return _paused;
    }








    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }








    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }








    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }








    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}






pragma solidity ^0.8.0;














abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor() {
        _transferOwnership(_msgSender());
    }




    function owner() public view virtual returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }





    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}





pragma solidity ^0.8.0;











contract CommonPausableERC20 is ERC20Capped, ERC20Mintable, ERC20Burnable, Pausable, Ownable {
  uint8 private _decimals;

  function _setupDecimals(uint8 __decimals) internal {
    _decimals = __decimals;
  }

  function decimals() public view virtual override(ERC20) returns (uint8) {
    return _decimals;
  }

  constructor (
    string memory name,
    string memory symbol,
    uint8 __decimals,
    uint256 cap,
    uint256 initialBalance
  )
  ERC20(name, symbol)
  ERC20Capped(cap)
  {
    _setupDecimals(__decimals);
    require(initialBalance <= cap, "ERC20Capped: cap exceeded");
    ERC20._mint(_msgSender(), initialBalance);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }









  function _mint(address account, uint256 amount) internal override(ERC20Capped, ERC20) onlyOwner {
    ERC20Capped._mint(account, amount);
  }






  function _finishMinting() internal override onlyOwner {
    super._finishMinting();
  }








  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20) {
    super._beforeTokenTransfer(from, to, amount);

    require(!paused(), "ERC20Pausable: token transfer while paused");
  }
}
