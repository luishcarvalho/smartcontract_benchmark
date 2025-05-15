
pragma solidity ^0.8.0;




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












abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}



























contract ERC20 is Context, IERC20 {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;










    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }




    function name() external view virtual returns (string memory) {
        return _name;
    }





    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }














    function decimals() external view virtual returns (uint8) {
        return 18;
    }




    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }














    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }















    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}





contract QANX is ERC20 {


    event LockApplied(address indexed account, uint256 amount, uint32 hardLockUntil, uint32 softLockUntil, uint8 allowedHops);
    event LockRemoved(address indexed account);


    constructor() ERC20("QANX Token", "QANX") {


        _mint(_msgSender(), 3333333000 * (10 ** 18));
    }


    mapping (address => bytes32) private _qPubKeyHashes;


    function setQuantumPubkeyHash(bytes32 qPubKeyHash) external {
        _qPubKeyHashes[_msgSender()] = qPubKeyHash;
    }


    function getQuantumPubkeyHash(address account) external view virtual returns (bytes32) {
        return _qPubKeyHashes[account];
    }


    struct Lock {
        uint256 tokenAmount;
        uint32 hardLockUntil;
        uint32 softLockUntil;
        uint8 allowedHops;
        uint32 lastUnlock;
        uint256 unlockPerSec;
    }


    mapping (address => Lock) private _locks;


    function lockOf(address account) external view virtual returns (Lock memory) {
        return _locks[account];
    }


    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account] + _locks[account].tokenAmount;
    }


    function transferLocked(address recipient, uint256 amount, uint32 hardLockUntil, uint32 softLockUntil, uint8 allowedHops) external returns (bool) {


        require(_locks[recipient].tokenAmount == 0, "Only one lock per address allowed!");


        require(_balances[_msgSender()] + _locks[_msgSender()].tokenAmount >= amount, "Transfer amount exceeds balance");


        if(_balances[_msgSender()] >= amount){


            _balances[_msgSender()] = _balances[_msgSender()] - amount;


            return _applyLock(recipient, amount, hardLockUntil, softLockUntil, allowedHops);
        }


        require(
            hardLockUntil >= _locks[_msgSender()].hardLockUntil &&
            softLockUntil >= _locks[_msgSender()].softLockUntil &&
            allowedHops < _locks[_msgSender()].allowedHops
        );


        if(_locks[_msgSender()].tokenAmount >= amount){


            _locks[_msgSender()].tokenAmount = _locks[_msgSender()].tokenAmount - amount;


            return _applyLock(recipient, amount, hardLockUntil, softLockUntil, allowedHops);
        }


        _balances[_msgSender()] = _balances[_msgSender()] - (amount - _locks[_msgSender()].tokenAmount);


        _locks[_msgSender()].tokenAmount = 0;


        return _applyLock(recipient, amount, hardLockUntil, softLockUntil, allowedHops);
    }


    function _applyLock(address recipient, uint256 amount, uint32 hardLockUntil, uint32 softLockUntil, uint8 allowedHops) private returns (bool) {


        require(softLockUntil > hardLockUntil, "SoftLock must be greater than HardLock!");


        _locks[recipient] = Lock(amount, hardLockUntil, softLockUntil, allowedHops, hardLockUntil, amount / (softLockUntil - hardLockUntil));
        emit LockApplied(recipient, amount, hardLockUntil, softLockUntil, allowedHops);
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function lockedBalanceOf(address account) external view virtual returns (uint256) {
        return _locks[account].tokenAmount;
    }

    function unlockedBalanceOf(address account) external view virtual returns (uint256) {
        return _balances[account];
    }

    function unlockableBalanceOf(address account) public view virtual returns (uint256) {


        if(block.timestamp < _locks[account].hardLockUntil) {
            return 0;
        }


        if(block.timestamp > _locks[account].softLockUntil) {
            return _locks[account].tokenAmount;
        }


        return (block.timestamp - _locks[account].lastUnlock) * _locks[account].unlockPerSec;
    }

    function unlock(address account) external returns (bool) {


        uint256 unlockable = unlockableBalanceOf(account);


        require(unlockable > 0 && _locks[account].tokenAmount > 0 && block.timestamp > _locks[account].hardLockUntil, "No unlockable tokens!");


        _locks[account].lastUnlock = uint32(block.timestamp);
        _locks[account].tokenAmount = _locks[account].tokenAmount - unlockable;
        _balances[account] = _balances[account] + unlockable;


        if(_locks[account].tokenAmount == 0){
            delete _locks[account];
            emit LockRemoved(account);
        }


        emit Transfer(account, account, unlockable);
        return true;
    }
}
