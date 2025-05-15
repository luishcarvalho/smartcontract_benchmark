





pragma solidity 0.6.12;
















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




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = (false, bytes(msg.data));
	 recipient.call{ value: amount }("");

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


        (bool success, bytes memory returndata) = (false, bytes(msg.data));
	 target.call{ value: weiValue }(data);

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



interface IStrategyV2 {
    function approve(IERC20 _token) external;

    function approveForSpender(IERC20 _token, address spender) external;


    function deposit(uint256 _poolId, uint256 _amount) external;


    function claim(uint256 _poolId) external;


    function harvest(uint256 _bankPoolId, uint256 _poolId) external;


    function withdraw(uint256 _poolId, uint256 _amount) external;


    function poolQuota(uint256 _poolId) external view returns (uint256);


    function forwardToAnotherStrategy(address _dest, uint256 _amount) external returns (uint256);


    function getLpToken() external view returns(address);


    function getTargetToken(uint256 _poolId) external view returns(address);

    function balanceOf(uint256 _poolId) external view returns (uint256);

    function pendingReward(uint256 _poolId) external view returns (uint256);



    function expectedAPY(uint256 _poolId, uint256 _lpPairUsdcPrice) external view returns (uint256);

    function governanceRescueToken(IERC20 _token) external returns (uint256);
}
























contract ValueVaultMaster {
    address public governance;

    address public bank;
    address public minorPool;
    address public profitSharer;

    address public govToken;
    address public yfv;
    address public usdc;

    address public govVault;
    address public insuranceFund = 0xb7b2Ea8A1198368f950834875047aA7294A2bDAa;
    address public performanceReward = 0x7Be4D5A99c903C437EC77A20CB6d0688cBB73c7f;

    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public govVaultProfitShareFee = 670;
    uint256 public gasFee = 50;

    uint256 public minStakeTimeToClaimVaultReward = 24 hours;

    mapping(address => bool) public isVault;
    mapping(uint256 => address) public vaultByKey;

    mapping(address => bool) public isStrategy;
    mapping(uint256 => address) public strategyByKey;
    mapping(address => uint256) public strategyQuota;

    constructor(address _govToken, address _yfv, address _usdc) public {
        govToken = _govToken;
        yfv = _yfv;
        usdc = _usdc;
        governance = tx.origin;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }


    function setBank(address _bank) external {
        require(msg.sender == governance, "!governance");
        require(bank == address(0));
        bank = _bank;
    }


    function setMinorPool(address _minorPool) external {
        require(msg.sender == governance, "!governance");
        minorPool = _minorPool;
    }


    function setProfitSharer(address _profitSharer) external {
        require(msg.sender == governance, "!governance");
        profitSharer = _profitSharer;
    }


    function setGovToken(address _govToken) external {
        require(msg.sender == governance, "!governance");
        govToken = _govToken;
    }


    function addVault(uint256 _key, address _vault) external {
        require(msg.sender == governance, "!governance");
        require(vaultByKey[_key] == address(0), "vault: key is taken");

        isVault[_vault] = true;
        vaultByKey[_key] = _vault;
    }


    function addStrategy(uint256 _key, address _strategy) external {
        require(msg.sender == governance, "!governance");
        isStrategy[_strategy] = true;
        strategyByKey[_key] = _strategy;
    }


    function setStrategyQuota(address _strategy, uint256 _quota) external {
        require(msg.sender == governance, "!governance");
        strategyQuota[_strategy] = _quota;
    }

    function removeStrategy(uint256 _key) external {
        require(msg.sender == governance, "!governance");
        isStrategy[strategyByKey[_key]] = false;
        delete strategyByKey[_key];
    }

    function setGovVault(address _govVault) public {
        require(msg.sender == governance, "!governance");
        govVault = _govVault;
    }

    function setInsuranceFund(address _insuranceFund) public {
        require(msg.sender == governance, "!governance");
        insuranceFund = _insuranceFund;
    }

    function setPerformanceReward(address _performanceReward) public{
        require(msg.sender == governance, "!governance");
        performanceReward = _performanceReward;
    }

    function setGovVaultProfitShareFee(uint256 _govVaultProfitShareFee) public {
        require(msg.sender == governance, "!governance");
        govVaultProfitShareFee = _govVaultProfitShareFee;
    }

    function setGasFee(uint256 _gasFee) public {
        require(msg.sender == governance, "!governance");
        gasFee = _gasFee;
    }

    function setMinStakeTimeToClaimVaultReward(uint256 _minStakeTimeToClaimVaultReward) public {
        require(msg.sender == governance, "!governance");
        minStakeTimeToClaimVaultReward = _minStakeTimeToClaimVaultReward;
    }







    function governanceRecoverUnsupported(IERC20x _token, uint256 amount, address to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(to, amount);
    }
}

interface IERC20x {
    function transfer(address recipient, uint256 amount) external returns (bool);
}



interface IValueVault {
    function getStrategyCount() external view returns(uint256);
    function depositAvailable() external view returns(bool);
    function mintByBank(IERC20 _token, address _to, uint256 _amount) external;
    function burnByBank(IERC20 _token, address _account, uint256 _amount) external;
    function harvestAllStrategies(uint256 _bankPoolId) external;
    function harvestStrategy(address _strategy, uint256 _bankPoolId) external;
}

contract ValueVaultV2 is IValueVault, ERC20 {
    using SafeMath for uint256;

    address public governance;

    mapping (address => uint256) public lockedAmount;

    IStrategyV2 public strategy;

    uint256[] public poolStrategyIds;

    ValueVaultMaster public valueVaultMaster;

    constructor (ValueVaultMaster _valueVaultMaster, string memory _name, string memory _symbol) ERC20(_name, _symbol) public  {
        valueVaultMaster = _valueVaultMaster;
        governance = tx.origin;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setStrategy(IStrategyV2 _strategy) public {
        require(msg.sender == governance, "!governance");
        strategy = _strategy;
    }

    function setPoolStrategyIds(uint256[] memory _poolStrategyIds) public {
        require(msg.sender == governance, "!governance");
        delete poolStrategyIds;
        for (uint256 i = 0; i < _poolStrategyIds.length; ++i) {
            poolStrategyIds.push(_poolStrategyIds[i]);
        }
    }

    function getStrategyCount() public override view returns(uint count) {
        return poolStrategyIds.length;
    }

    function depositAvailable() public override view returns(bool) {
        if (poolStrategyIds.length == 0) return false;
        for (uint256 i = 0; i < poolStrategyIds.length; ++i) {
            uint256 _pid = poolStrategyIds[i];
            uint256 _quota = strategy.poolQuota(_pid);
            if (_quota == 0 || strategy.balanceOf(_pid) < _quota) {
                return true;
            }
        }
        return false;
    }


    function mintByBank(IERC20 _token, address _to, uint256 _amount) public override {
        require(_msgSender() == valueVaultMaster.bank(), "not bank");

        _deposit(_token, _amount);
        if (_amount > 0) {
            _mint(_to, _amount);
        }
    }


    function burnByBank(IERC20 _token, address _account, uint256 _amount) public override {
        require(_msgSender() == valueVaultMaster.bank(), "not bank");

        uint256 balance = balanceOf(_account);
        require(lockedAmount[_account] + _amount <= balance, "Vault: burn too much");

        _withdraw(_token, _amount);
        _burn(_account, _amount);
    }


    function transfer(address _to, uint256 _amount) public override returns (bool) {
        uint256 balance = balanceOf(_msgSender());
        require(lockedAmount[_msgSender()] + _amount <= balance, "transfer: <= balance");

        _transfer(_msgSender(), _to, _amount);

        return true;
    }

    function _deposit(IERC20 _token, uint256 _amount) internal {
        require(poolStrategyIds.length > 0, "no strategies");
        for (uint256 i = 0; i < poolStrategyIds.length; ++i) {
            uint256 _pid = poolStrategyIds[i];
            uint256 _quota = strategy.poolQuota(_pid);
            if (_quota == 0 || strategy.balanceOf(_pid) < _quota) {
                _token.transfer(address(strategy), _amount);
                strategy.deposit(_pid, _amount);
                return;
            }
        }
        revert("Exceeded quota");
    }

    function _withdraw(IERC20 _token, uint256 _amount) internal {
        require(poolStrategyIds.length > 0, "no strategies");
        for (uint256 i = poolStrategyIds.length; i >= 1; --i) {
            uint256 _pid = poolStrategyIds[i - 1];
            uint256 bal = strategy.balanceOf(_pid);
            if (bal > 0) {
                strategy.withdraw(_pid, (bal > _amount) ? _amount : bal);
                _token.transferFrom(address(strategy), valueVaultMaster.bank(), _token.balanceOf(address(strategy)));
                if (_token.balanceOf(valueVaultMaster.bank()) >= _amount) break;
            }
        }
    }

    function harvestAllStrategies(uint256 _bankPoolId) external override {
        require(_msgSender() == valueVaultMaster.bank(), "not bank");
        for (uint256 i = 0; i < poolStrategyIds.length; ++i) {
            strategy.harvest(_bankPoolId, poolStrategyIds[i]);
        }
    }

    function harvestStrategy(address _strategy, uint256 _bankPoolId) external override {
        require(_msgSender() == valueVaultMaster.bank(), "not bank");
        IStrategyV2(_strategy).harvest(_bankPoolId, poolStrategyIds[0]);
    }

    function harvestStrategy(uint256 _bankPoolId, uint256 _poolStrategyId) external {
        require(msg.sender == governance, "!governance");
        strategy.harvest(_bankPoolId, _poolStrategyId);
    }

    function withdrawStrategy(IStrategyV2 _strategy, uint256 _poolStrategyId, uint256 _amount) external {
        require(msg.sender == governance, "!governance");
        _strategy.withdraw(_poolStrategyId, _amount);
    }

    function claimStrategy(IStrategyV2 _strategy, uint256 _poolStrategyId) external {
        require(msg.sender == governance, "!governance");
        _strategy.claim(_poolStrategyId);
    }

    function forwardBetweenStrategies(IStrategyV2 _source, IStrategyV2 _dest, uint256 _amount) external {
        require(msg.sender == governance, "!governance");
        _source.forwardToAnotherStrategy(address(_dest), _amount);
    }







    function governanceRecoverUnsupported(IERC20 _token, uint256 _amount, address _to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(_to, _amount);
    }

    event ExecuteTransaction(address indexed target, uint value, string signature, bytes data);

    function executeTransaction(address target, uint value, string memory signature, bytes memory data) public returns (bytes memory) {
        require(msg.sender == governance, "!governance");

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }


        (bool success, bytes memory returnData) = (false, bytes(msg.data));
	 target.call{value: value}(callData);

        require(success, "Univ2ETHUSDCMultiPoolStrategy::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }
}



contract UNIv2ETHUSDCVault is ValueVaultV2 {
    constructor (
        ValueVaultMaster _master,
        IStrategyV2 _univ2ethusdcStrategy
    ) ValueVaultV2(_master, "Value Vaults: UNIv2ETHUSDC", "vUNIv2ETHUSDC") public  {
        setStrategy(_univ2ethusdcStrategy);
        uint256[] memory _poolStrategyIds = new uint256[](1);
        _poolStrategyIds[0] = 0;
        setPoolStrategyIds(_poolStrategyIds);
    }
}
