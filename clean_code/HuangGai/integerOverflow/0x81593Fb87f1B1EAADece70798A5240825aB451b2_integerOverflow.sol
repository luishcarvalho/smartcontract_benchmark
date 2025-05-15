





pragma solidity ^0.6.12;













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



interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}



interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
















library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


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


    function setPool(address _pool) external onlyOwner {
        require(pool == address(0));
        pool = _pool;
    }



    function setBank(address _bank) external onlyOwner {
        require(bank == address(0));
        bank = _bank;
    }


    function setRevenue(address _revenue) external onlyOwner {
        revenue = _revenue;
    }


    function setDev(address _dev) external onlyOwner {
        dev = _dev;
    }



    function setUniswapV2Factory(address _uniswapV2Factory) external onlyOwner {
        uniswapV2Factory = _uniswapV2Factory;
    }


    function setWETH(address _wETH) external onlyOwner {
       require(wETH == address(0));
       wETH = _wETH;
    }



    function setUSDT(address _usdt) external onlyOwner {
        require(usdt == address(0));
        usdt = _usdt;
    }


    function setSoda(address _soda) external onlyOwner {
        require(soda == address(0));
        soda = _soda;
    }


    function addVault(uint256 _key, address _vault) external onlyOwner {
        require(vaultByKey[_key] == address(0), "vault: key is taken");

        isVault[_vault] = true;
        vaultByKey[_key] = _vault;
    }


    function addSodaMade(uint256 _key, address _sodaMade) external onlyOwner {
        require(sodaMadeByKey[_key] == address(0), "sodaMade: key is taken");

        isSodaMade[_sodaMade] = true;
        sodaMadeByKey[_key] = _sodaMade;
    }


    function addStrategy(uint256 _key, address _strategy) external onlyOwner {
        isStrategy[_strategy] = true;
        strategyByKey[_key] = _strategy;
    }

    function removeStrategy(uint256 _key) external onlyOwner {
        isStrategy[strategyByKey[_key]] = false;
        delete strategyByKey[_key];
    }


    function addCalculator(uint256 _key, address _calculator) external onlyOwner {
        isCalculator[_calculator] = true;
        calculatorByKey[_key] = _calculator;
    }

    function removeCalculator(uint256 _key) external onlyOwner {
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




abstract contract ICalculator {

    function rate() external view virtual returns(uint256);
    function minimumLTV() external view virtual returns(uint256);
    function maximumLTV() external view virtual returns(uint256);


    function getNextLoanId() external view virtual returns(uint256);


    function getLoanCreator(uint256 _loanId) external view virtual returns (address);


    function getLoanLockedAmount(uint256 _loanId) external view virtual returns (uint256);


    function getLoanTime(uint256 _loanId) external view virtual returns (uint256);


    function getLoanRate(uint256 _loanId) external view virtual returns (uint256);


    function getLoanMinimumLTV(uint256 _loanId) external view virtual returns (uint256);


    function getLoanMaximumLTV(uint256 _loanId) external view virtual returns (uint256);


    function getLoanPrincipal(uint256 _loanId) external view virtual returns (uint256);


    function getLoanInterest(uint256 _loanId) external view virtual returns (uint256);


    function getLoanTotal(uint256 _loanId) external view virtual returns (uint256);


    function getLoanExtra(uint256 _loanId) external view virtual returns (uint256);





    function borrow(address _who, uint256 _amount) external virtual;




    function payBackInFull(uint256 _loanId) external virtual;





    function collectDebt(uint256 _loanId) external virtual;
}












library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }








    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}




contract SodaPool is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    struct PoolInfo {
        IERC20 token;
        SodaVault vault;
        uint256 startTime;
    }


    mapping (uint256 => PoolInfo) public poolMap;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);
    event Claim(address indexed user, uint256 indexed poolId);

    constructor() public {
    }

    function setPoolInfo(uint256 _poolId, IERC20 _token, SodaVault _vault, uint256 _startTime) public onlyOwner {
        poolMap[_poolId].token = _token;
        poolMap[_poolId].vault = _vault;
        poolMap[_poolId].startTime = _startTime;
    }

    function _handleDeposit(SodaVault _vault, IERC20 _token, uint256 _amount) internal {
        uint256 count = _vault.getStrategyCount();
        require(count == 1 || count == 2, "_handleDeposit: count");


        address strategy0 = address(_vault.strategies(0));
        _token.safeTransferFrom(address(msg.sender), strategy0, _amount);
    }

    function _handleWithdraw(SodaVault _vault, IERC20 _token, uint256 _amount) internal {
        uint256 count = _vault.getStrategyCount();
        require(count == 1 || count == 2, "_handleWithdraw: count");

        address strategy0 = address(_vault.strategies(0));
        _token.safeTransferFrom(strategy0, address(msg.sender), _amount);
    }

    function _handleRewards(SodaVault _vault) internal {
        uint256 count = _vault.getStrategyCount();

        for (uint256 i = 0; i < count; ++i) {
            uint256 rewardPending = _vault.rewards(msg.sender, i);
            if (rewardPending > 0) {
                IERC20(_vault.strategies(i).getTargetToken()).safeTransferFrom(
                    address(_vault.strategies(i)), msg.sender, rewardPending);
            }
        }

        _vault.clearRewardByPool(msg.sender);
    }



    function deposit(uint256 _poolId, uint256 _amount) public {
        PoolInfo storage pool = poolMap[_poolId];
        require(now >= pool.startTime, "deposit: after startTime");

        _handleDeposit(pool.vault, pool.token, _amount);
        pool.vault.mintByPool(msg.sender, _amount);

        emit Deposit(msg.sender, _poolId, _amount);
    }


    function claim(uint256 _poolId) public {
        PoolInfo storage pool = poolMap[_poolId];
        require(now >= pool.startTime, "claim: after startTime");

        pool.vault.mintByPool(msg.sender, 0);
        _handleRewards(pool.vault);

        emit Claim(msg.sender, _poolId);
    }


    function withdraw(uint256 _poolId, uint256 _amount) public {
        PoolInfo storage pool = poolMap[_poolId];
        require(now >= pool.startTime, "withdraw: after startTime");

        pool.vault.burnByPool(msg.sender, _amount);

        _handleWithdraw(pool.vault, pool.token, _amount);
        _handleRewards(pool.vault);

        emit Withdraw(msg.sender, _poolId, _amount);
    }
}




contract SodaMade is ERC20, Ownable {

    constructor (string memory _name, string memory _symbol) ERC20(_name, _symbol) public  {
    }


    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }


    function burnFrom(address account, uint256 amount) public onlyOwner {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}






contract SodaBank is Ownable {
    using SafeMath for uint256;


    struct PoolInfo {
        SodaMade made;
        SodaVault vault;
        ICalculator calculator;
    }


    mapping(uint256 => PoolInfo) public poolMap;


    struct LoanInfo {
        uint256 poolId;
        uint256 loanId;
    }


    mapping (address => LoanInfo[]) public loanList;

    SodaMaster public sodaMaster;

    event Borrow(address indexed user, uint256 indexed index, uint256 indexed poolId, uint256 amount);
    event PayBackInFull(address indexed user, uint256 indexed index);
    event CollectDebt(address indexed user, uint256 indexed poolId, uint256 loanId);

    constructor(
        SodaMaster _sodaMaster
    ) public {
        sodaMaster = _sodaMaster;
    }


    function setPoolInfo(uint256 _poolId, SodaMade _made, SodaVault _vault, ICalculator _calculator) public onlyOwner {
        poolMap[_poolId].made = _made;
        poolMap[_poolId].vault = _vault;
        poolMap[_poolId].calculator = _calculator;
    }


    function getLoanListLength(address _who) external view returns (uint256) {
        return loanList[_who].length;
    }


    function borrow(uint256 _poodId, uint256 _amount) external {
        PoolInfo storage pool = poolMap[_poodId];
        require(address(pool.calculator) != address(0), "no calculator");

        uint256 loanId = pool.calculator.getNextLoanId();
        pool.calculator.borrow(msg.sender, _amount);
        uint256 lockedAmount = pool.calculator.getLoanLockedAmount(loanId);

        pool.vault.lockByBank(msg.sender, lockedAmount);


        pool.made.mint(msg.sender, _amount);


        LoanInfo memory loanInfo;
        loanInfo.poolId = _poodId;
        loanInfo.loanId = loanId;
        loanList[msg.sender].push(loanInfo);

        emit Borrow(msg.sender, loanList[msg.sender].length - 1, _poodId, _amount);
    }


    function payBackInFull(uint256 _index) external {
        require(_index < loanList[msg.sender].length, "getTotalLoan: index out of range");
        PoolInfo storage pool = poolMap[loanList[msg.sender][_index].poolId];
        require(address(pool.calculator) != address(0), "no calculator");

        uint256 loanId = loanList[msg.sender][_index].loanId;
        uint256 lockedAmount = pool.calculator.getLoanLockedAmount(loanId);
        uint256 principal = pool.calculator.getLoanPrincipal(loanId);
        uint256 interest = pool.calculator.getLoanInterest(loanId);

        pool.made.burnFrom(msg.sender, principal);

        pool.made.transferFrom(msg.sender, sodaMaster.revenue(), interest);
        pool.calculator.payBackInFull(loanId);

        pool.vault.unlockByBank(msg.sender, lockedAmount);

        emit PayBackInFull(msg.sender, _index);
    }


    function collectDebt(uint256 _poolId, uint256 _loanId) external {
        PoolInfo storage pool = poolMap[_poolId];
        require(address(pool.calculator) != address(0), "no calculator");

        address loanCreator = pool.calculator.getLoanCreator(_loanId);
        uint256 principal = pool.calculator.getLoanPrincipal(_loanId);
        uint256 interest = pool.calculator.getLoanInterest(_loanId);
        uint256 extra = pool.calculator.getLoanExtra(_loanId);
        uint256 lockedAmount = pool.calculator.getLoanLockedAmount(_loanId);



        pool.made.burnFrom(msg.sender, principal);

        pool.made.transferFrom(msg.sender, sodaMaster.revenue(), interest + extra);


        pool.calculator.collectDebt(_loanId);

        pool.vault.unlockByBank(loanCreator, lockedAmount);

        pool.vault.transferByBank(loanCreator, msg.sender, lockedAmount);

        emit CollectDebt(msg.sender, _poolId, _loanId);
    }
}




contract SodaToken is ERC20("SodaToken", "SODA"), Ownable {




    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }



    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        super._transfer(sender, recipient, amount);
        _moveDelegates(_delegates[sender], _delegates[recipient], amount);
    }


    mapping (address => address) internal _delegates;


    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }


    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;


    mapping (address => uint32) public numCheckpoints;


    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");


    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");


    mapping (address => uint) public nonces;


    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);


    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);





    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }





    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }










    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "SODA::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "SODA::delegateBySig: invalid nonce");
        require(now <= expiry, "SODA::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }






    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }








    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "SODA::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }


        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }


        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {

                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {

                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "SODA::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}














contract CreateSoda is IStrategy, Ownable {
    using SafeMath for uint256;

    uint256 public constant ALL_BLOCKS_AMOUNT = 100000;
    uint256 public constant SODA_PER_BLOCK = 1 * 1e18;

    uint256 constant PER_SHARE_SIZE = 1e12;


    struct PoolInfo {
        uint256 allocPoint;
        uint256 lastRewardBlock;
    }


    mapping (address => PoolInfo) public poolMap;

    mapping (uint256 => address) public vaultMap;
    uint256 public poolLength;


    uint256 public totalAllocPoint = 0;


    uint256 public startBlock;


    uint256 public endBlock;


    SodaMaster public sodaMaster;

    mapping(address => uint256) private valuePerShare;

    constructor(
        SodaMaster _sodaMaster
    ) public {
        sodaMaster = _sodaMaster;


        IERC20(sodaMaster.soda()).approve(sodaMaster.pool(), type(uint256).max);
    }


    function setPoolInfo(
        uint256 _poolId,
        address _vault,
        IERC20 _token,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        if (_poolId >= poolLength) {
            poolLength = _poolId + 1;
        }

        vaultMap[_poolId] = _vault;

        totalAllocPoint = totalAllocPoint.sub(poolMap[_vault].allocPoint).add(_allocPoint);

        poolMap[_vault].allocPoint = _allocPoint;

        _token.approve(sodaMaster.pool(), type(uint256).max);
    }


    function approve(IERC20 _token) external override onlyOwner {
        _token.approve(sodaMaster.pool(), type(uint256).max);
    }


    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to > endBlock) {
            _to = endBlock;
        }

        if (_from >= _to) {
            return 0;
        }

        return _to.sub(_from);
    }

    function getValuePerShare(address _vault) external view override returns(uint256) {
        return valuePerShare[_vault];
    }

    function pendingValuePerShare(address _vault) external view override returns (uint256) {
        PoolInfo storage pool = poolMap[_vault];

        uint256 amountInVault = IERC20(_vault).totalSupply();
        if (block.number > pool.lastRewardBlock && amountInVault > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sodaReward = multiplier.mul(SODA_PER_BLOCK).mul(pool.allocPoint).div(totalAllocPoint);
            sodaReward = sodaReward.sub(sodaReward.div(20));
            return sodaReward.mul(PER_SHARE_SIZE).div(amountInVault);
        } else {
            return 0;
        }
    }


    function massUpdatePools() public {
        for (uint256 i = 0; i < poolLength; ++i) {
            _update(vaultMap[i]);
        }
    }


    function _update(address _vault) public {
        PoolInfo storage pool = poolMap[_vault];

        if (pool.allocPoint <= 0) {
            return;
        }

        if (pool.lastRewardBlock == 0) {

            pool.lastRewardBlock = block.number;
        }

        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 shareAmount = IERC20(_vault).totalSupply();
        if (shareAmount == 0) {

            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 allReward = multiplier.mul(SODA_PER_BLOCK).mul(pool.allocPoint).div(totalAllocPoint);
        SodaToken(sodaMaster.soda()).mint(sodaMaster.dev(), allReward.div(20));
        uint256 farmerReward = allReward.sub(allReward.div(20));

        SodaToken(sodaMaster.soda()).mint(address(this), farmerReward);

        valuePerShare[_vault] = valuePerShare[_vault].add(farmerReward.mul(PER_SHARE_SIZE).div(shareAmount));
        pool.lastRewardBlock = block.number;
    }




    function deposit(address _vault, uint256 _amount) external override {
        require(sodaMaster.isVault(msg.sender), "sender not vault");

        if (startBlock == 0) {
            startBlock = block.number;
            endBlock = startBlock + ALL_BLOCKS_AMOUNT;
        }

        _update(_vault);
    }




    function claim(address _vault) external override {
        require(sodaMaster.isVault(msg.sender), "sender not vault");

        _update(_vault);
    }




    function withdraw(address _vault, uint256 _amount) external override {
        require(sodaMaster.isVault(msg.sender), "sender not vault");

        _update(_vault);
    }




    function getTargetToken() external view override returns(address) {
        return sodaMaster.soda();
    }







    function transferToCreateMoreSoda(address _createMoreSoda) external onlyOwner {
        require(block.number > endBlock);
        SodaToken(sodaMaster.soda()).transferOwnership(_createMoreSoda);
    }
}






contract SodaDataBoard is Ownable {

    SodaMaster public sodaMaster;

    constructor(SodaMaster _sodaMaster) public {
        sodaMaster = _sodaMaster;
    }

    function getCalculatorStat(uint256 _poolId) public view returns(uint256, uint256, uint256) {
        ICalculator calculator;
        (,, calculator) = SodaBank(sodaMaster.bank()).poolMap(_poolId);
        uint256 rate = calculator.rate();
        uint256 minimumLTV = calculator.minimumLTV();
        uint256 maximumLTV = calculator.maximumLTV();
        return (rate, minimumLTV, maximumLTV);
    }

    function getPendingReward(uint256 _poolId, uint256 _index) public view returns(uint256) {
        SodaVault vault;
        (, vault,) = SodaPool(sodaMaster.pool()).poolMap(_poolId);
        return vault.getPendingReward(msg.sender, _index);
    }


    function getAPY(uint256 _poolId, address _token, bool _isLPToken) public view returns(uint256) {
        (, SodaVault vault,) = SodaPool(sodaMaster.pool()).poolMap(_poolId);

        uint256 MK_STRATEGY_CREATE_SODA = 0;
        CreateSoda createSoda = CreateSoda(sodaMaster.strategyByKey(MK_STRATEGY_CREATE_SODA));
        (uint256 allocPoint,) = createSoda.poolMap(address(vault));
        uint256 totalAlloc = createSoda.totalAllocPoint();

        if (totalAlloc == 0) {
            return 0;
        }

        uint256 vaultSupply = vault.totalSupply();

        uint256 factor = 1;

        if (vaultSupply == 0) {

            return getSodaPrice() * factor * 5760 * 100 * allocPoint / totalAlloc / 1e6;
        }



        if (_isLPToken) {
            uint256 lpPrice = getEthLpPrice(_token);
            if (lpPrice == 0) {
                return 0;
            }

            return getSodaPrice() * factor * 2250000 * 100 * allocPoint * 1e18 / totalAlloc / lpPrice / vaultSupply;
        } else {
            uint256 tokenPrice = getTokenPrice(_token);
            if (tokenPrice == 0) {
                return 0;
            }

            return getSodaPrice() * factor * 2250000 * 100 * allocPoint * 1e18 / totalAlloc / tokenPrice / vaultSupply;
        }
    }


    function getUserLoanLength(address _who) public view returns (uint256) {
        return SodaBank(sodaMaster.bank()).getLoanListLength(_who);
    }


    function getUserLoan(address _who, uint256 _index) public view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
        uint256 poolId;
        uint256 loanId;
        (poolId, loanId) = SodaBank(sodaMaster.bank()).loanList(_who, _index);

        ICalculator calculator;
        (,, calculator) = SodaBank(sodaMaster.bank()).poolMap(poolId);

        uint256 lockedAmount = calculator.getLoanLockedAmount(loanId);
        uint256 principal = calculator.getLoanPrincipal(loanId);
        uint256 interest = calculator.getLoanInterest(loanId);
        uint256 time = calculator.getLoanTime(loanId);
        uint256 rate = calculator.getLoanRate(loanId);
        uint256 maximumLTV = calculator.getLoanMaximumLTV(loanId);

        return (loanId, principal, interest, lockedAmount, time, rate, maximumLTV);
    }

    function getEthLpPrice(address _token) public view returns (uint256) {
        IUniswapV2Factory factory = IUniswapV2Factory(sodaMaster.uniswapV2Factory());
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(_token, sodaMaster.wETH()));
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        if (pair.token0() == _token) {
            return reserve1 * getEthPrice() * 2 / pair.totalSupply();
        } else {
            return reserve0 * getEthPrice() * 2 / pair.totalSupply();
        }
    }


    function getEthPrice() public view returns (uint256) {
        IUniswapV2Factory factory = IUniswapV2Factory(sodaMaster.uniswapV2Factory());
        IUniswapV2Pair ethUSDTPair = IUniswapV2Pair(factory.getPair(sodaMaster.wETH(), sodaMaster.usdt()));
        require(address(ethUSDTPair) != address(0), "ethUSDTPair need set by owner");
        (uint reserve0, uint reserve1,) = ethUSDTPair.getReserves();


        if (ethUSDTPair.token0() == sodaMaster.wETH()) {
            return reserve1 * 1e18 / reserve0;
        } else {
            return reserve0 * 1e18 / reserve1;
        }
    }


    function getSodaPrice() public view returns (uint256) {
        return getTokenPrice(sodaMaster.soda());
    }


    function getTokenPrice(address _token) public view returns (uint256) {
        if (_token == sodaMaster.wETH()) {
            return getEthPrice();
        }

        IUniswapV2Factory factory = IUniswapV2Factory(sodaMaster.uniswapV2Factory());
        IUniswapV2Pair tokenETHPair = IUniswapV2Pair(factory.getPair(_token, sodaMaster.wETH()));
        require(address(tokenETHPair) != address(0), "tokenETHPair need set by owner");
        (uint reserve0, uint reserve1,) = tokenETHPair.getReserves();

        if (reserve0 == 0 || reserve1 == 0) {
            return 0;
        }


        if (tokenETHPair.token0() == _token) {
            return getEthPrice() * reserve1 / reserve0;
        } else {
            return getEthPrice() * reserve0 / reserve1;
        }
    }
}
