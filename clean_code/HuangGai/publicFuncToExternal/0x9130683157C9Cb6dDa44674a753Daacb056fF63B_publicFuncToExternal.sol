





pragma solidity ^0.6.12;
















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














abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
















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






library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}



























contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;










    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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




    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }








    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }















    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}




interface IStrategy {

    function approve(IERC20 _token) external;

    function getValuePerShare(address _vault) external view returns(uint256);
    function pendingValuePerShare(address _vault) external view returns (uint256);


    function deposit(address _vault, uint256 _amount) external;


    function claim(address _vault) external;


    function withdraw(address _vault, uint256 _amount) external;


    function getTargetToken() external view returns(address);
}














































contract SodaMaster is Ownable {

    address public pool;
    address public bank;
    address public revenue;
    address public dev;

    address public soda;
    address public wETH;
    address public usdt;

    address public uniswapV2Factory;

    mapping(address => bool) public isVault;
    mapping(uint256 => address) public vaultByKey;

    mapping(address => bool) public isSodaMade;
    mapping(uint256 => address) public sodaMadeByKey;

    mapping(address => bool) public isStrategy;
    mapping(uint256 => address) public strategyByKey;

    mapping(address => bool) public isCalculator;
    mapping(uint256 => address) public calculatorByKey;


    function setPool(address _pool) public onlyOwner {
        require(pool == address(0));
        pool = _pool;
    }



    function setBank(address _bank) public onlyOwner {
        require(bank == address(0));
        bank = _bank;
    }


    function setRevenue(address _revenue) public onlyOwner {
        revenue = _revenue;
    }


    function setDev(address _dev) public onlyOwner {
        dev = _dev;
    }



    function setUniswapV2Factory(address _uniswapV2Factory) public onlyOwner {
        uniswapV2Factory = _uniswapV2Factory;
    }


    function setWETH(address _wETH) public onlyOwner {
       require(wETH == address(0));
       wETH = _wETH;
    }



    function setUSDT(address _usdt) public onlyOwner {
        require(usdt == address(0));
        usdt = _usdt;
    }


    function setSoda(address _soda) public onlyOwner {
        require(soda == address(0));
        soda = _soda;
    }


    function addVault(uint256 _key, address _vault) public onlyOwner {
        require(vaultByKey[_key] == address(0), "vault: key is taken");

        isVault[_vault] = true;
        vaultByKey[_key] = _vault;
    }


    function addSodaMade(uint256 _key, address _sodaMade) public onlyOwner {
        require(sodaMadeByKey[_key] == address(0), "sodaMade: key is taken");

        isSodaMade[_sodaMade] = true;
        sodaMadeByKey[_key] = _sodaMade;
    }


    function addStrategy(uint256 _key, address _strategy) public onlyOwner {
        isStrategy[_strategy] = true;
        strategyByKey[_key] = _strategy;
    }

    function removeStrategy(uint256 _key) public onlyOwner {
        isStrategy[strategyByKey[_key]] = false;
        delete strategyByKey[_key];
    }


    function addCalculator(uint256 _key, address _calculator) public onlyOwner {
        isCalculator[_calculator] = true;
        calculatorByKey[_key] = _calculator;
    }

    function removeCalculator(uint256 _key) public onlyOwner {
        isCalculator[calculatorByKey[_key]] = false;
        delete calculatorByKey[_key];
    }
}




contract SodaVault is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 constant PER_SHARE_SIZE = 1e12;

    mapping (address => uint256) public lockedAmount;
    mapping (address => mapping(uint256 => uint256)) public rewards;
    mapping (address => mapping(uint256 => uint256)) public debts;

    IStrategy[] public strategies;

    SodaMaster public sodaMaster;

    constructor (SodaMaster _sodaMaster, string memory _name, string memory _symbol) ERC20(_name, _symbol) public  {
        sodaMaster = _sodaMaster;
    }

    function setStrategies(IStrategy[] memory _strategies) public onlyOwner {
        delete strategies;
        for (uint256 i = 0; i < _strategies.length; ++i) {
            strategies.push(_strategies[i]);
        }
    }

    function getStrategyCount() view public returns(uint count) {
        return strategies.length;
    }


    function mintByPool(address _to, uint256 _amount) public {
        require(_msgSender() == sodaMaster.pool(), "not pool");

        _deposit(_amount);
        _updateReward(_to);
        if (_amount > 0) {
            _mint(_to, _amount);
        }
        _updateDebt(_to);
    }


    function burnByPool(address _account, uint256 _amount) public {
        require(_msgSender() == sodaMaster.pool(), "not pool");

        uint256 balance = balanceOf(_account);
        require(lockedAmount[_account] + _amount <= balance, "Vault: burn too much");

        _withdraw(_amount);
        _updateReward(_account);
        _burn(_account, _amount);
        _updateDebt(_account);
    }


    function transferByBank(address _from, address _to, uint256 _amount) public {
        require(_msgSender() == sodaMaster.bank(), "not bank");

        uint256 balance = balanceOf(_from);
        require(lockedAmount[_from] + _amount <= balance);

        _claim();
        _updateReward(_from);
        _updateReward(_to);
        _transfer(_from, _to, _amount);
        _updateDebt(_to);
        _updateDebt(_from);
    }


    function transfer(address _to, uint256 _amount) public override returns (bool) {
        uint256 balance = balanceOf(_msgSender());
        require(lockedAmount[_msgSender()] + _amount <= balance, "transfer: <= balance");

        _updateReward(_msgSender());
        _updateReward(_to);
        _transfer(_msgSender(), _to, _amount);
        _updateDebt(_to);
        _updateDebt(_msgSender());

        return true;
    }


    function lockByBank(address _account, uint256 _amount) public {
        require(_msgSender() == sodaMaster.bank(), "not bank");

        uint256 balance = balanceOf(_account);
        require(lockedAmount[_account] + _amount <= balance, "Vault: lock too much");
        lockedAmount[_account] += _amount;
    }


    function unlockByBank(address _account, uint256 _amount) public {
        require(_msgSender() == sodaMaster.bank(), "not bank");

        require(_amount <= lockedAmount[_account], "Vault: unlock too much");
        lockedAmount[_account] -= _amount;
    }


    function clearRewardByPool(address _who) public {
        require(_msgSender() == sodaMaster.pool(), "not pool");

        for (uint256 i = 0; i < strategies.length; ++i) {
            rewards[_who][i] = 0;
        }
    }

    function getPendingReward(address _who, uint256 _index) public view returns (uint256) {
        uint256 total = totalSupply();
        if (total == 0 || _index >= strategies.length) {
            return 0;
        }

        uint256 value = strategies[_index].getValuePerShare(address(this));
        uint256 pending = strategies[_index].pendingValuePerShare(address(this));
        uint256 balance = balanceOf(_who);

        return balance.mul(value.add(pending)).div(PER_SHARE_SIZE).sub(debts[_who][_index]);
    }

    function _deposit(uint256 _amount) internal {
        for (uint256 i = 0; i < strategies.length; ++i) {
            strategies[i].deposit(address(this), _amount);
        }
    }

    function _withdraw(uint256 _amount) internal {
        for (uint256 i = 0; i < strategies.length; ++i) {
            strategies[i].withdraw(address(this), _amount);
        }
    }

    function _claim() internal {
        for (uint256 i = 0; i < strategies.length; ++i) {
            strategies[i].claim(address(this));
        }
    }

    function _updateReward(address _who) internal {
        uint256 balance = balanceOf(_who);
        if (balance > 0) {
            for (uint256 i = 0; i < strategies.length; ++i) {
                uint256 value = strategies[i].getValuePerShare(address(this));
                rewards[_who][i] = rewards[_who][i].add(balance.mul(
                    value).div(PER_SHARE_SIZE).sub(debts[_who][i]));
            }
        }
    }

    function _updateDebt(address _who) internal {
        uint256 balance = balanceOf(_who);
        for (uint256 i = 0; i < strategies.length; ++i) {
            uint256 value = strategies[i].getValuePerShare(address(this));
            debts[_who][i] = balance.mul(value).div(PER_SHARE_SIZE);
        }
    }
}




contract SoETHETHLPVault is SodaVault {

    constructor (
        SodaMaster _sodaMaster,
        IStrategy _createSoda
    ) SodaVault(_sodaMaster, "Soda SoETH-ETH-UNI-V2-LP Vault", "vSoETH-ETH-UNI-V2-LP") public  {
        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = _createSoda;
        setStrategies(strategies);
    }
}
