





pragma solidity 0.6.12;




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




library Address {

















    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
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

interface IMultiVaultConverter {
    function token() external returns (address);
    function get_virtual_price() external view returns (uint);

    function convert_rate(address _input, address _output, uint _inputAmount) external view returns (uint _outputAmount);
    function calc_token_amount_deposit(uint[] calldata _amounts) external view returns (uint _shareAmount);
    function calc_token_amount_withdraw(uint _shares, address _output) external view returns (uint _outputAmount);

    function convert(address _input, address _output, uint _inputAmount) external returns (uint _outputAmount);
    function convertAll(uint[] calldata _amounts) external returns (uint _outputAmount);
}

interface IValueVaultMaster {
    function bank(address) view external returns (address);
    function isVault(address) view external returns (bool);
    function isController(address) view external returns (bool);
    function isStrategy(address) view external returns (bool);

    function slippage(address) view external returns (uint);
    function convertSlippage(address _input, address _output) view external returns (uint);

    function valueToken() view external returns (address);
    function govVault() view external returns (address);
    function insuranceFund() view external returns (address);
    function performanceReward() view external returns (address);

    function govVaultProfitShareFee() view external returns (uint);
    function gasFee() view external returns (uint);
    function insuranceFee() view external returns (uint);
    function withdrawalProtectionFee() view external returns (uint);
}


interface IStableSwap3Pool {
    function get_virtual_price() external view returns (uint);
    function balances(uint) external view returns (uint);
    function calc_token_amount(uint[3] calldata amounts, bool deposit) external view returns (uint);
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
    function get_dy(int128 i, int128 j, uint dx) external view returns (uint);
    function add_liquidity(uint[3] calldata amounts, uint min_mint_amount) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_amount) external;
    function exchange(int128 i, int128 j, uint dx, uint min_dy) external;
}


interface IStableSwapBUSD {
    function get_virtual_price() external view returns (uint);
    function calc_token_amount(uint[4] calldata amounts, bool deposit) external view returns (uint);
    function get_dy_underlying(int128 i, int128 j, uint dx) external view returns (uint dy);
    function get_dx_underlying(int128 i, int128 j, uint dy) external view returns (uint dx);
    function exchange_underlying(int128 i, int128 j, uint dx, uint min_dy) external;
}


interface IStableSwapHUSD {
    function get_virtual_price() external view returns (uint);
    function calc_token_amount(uint[2] calldata amounts, bool deposit) external view returns (uint);
    function get_dy(int128 i, int128 j, uint dx) external view returns (uint dy);
    function get_dy_underlying(int128 i, int128 j, uint dx) external view returns (uint dy);
    function get_dx_underlying(int128 i, int128 j, uint dy) external view returns (uint dx);
    function exchange_underlying(int128 i, int128 j, uint dx, uint min_dy) external;
    function exchange(int128 i, int128 j, uint dx, uint min_dy) external;
    function calc_withdraw_one_coin(uint amount, int128 i) external view returns (uint);
    function remove_liquidity_one_coin(uint amount, int128 i, uint minAmount) external returns (uint);
    function add_liquidity(uint[2] calldata amounts, uint min_mint_amount) external returns (uint);
}


interface IStableSwapSUSD {
    function get_virtual_price() external view returns (uint);
    function calc_token_amount(uint[4] calldata amounts, bool deposit) external view returns (uint);
    function get_dy_underlying(int128 i, int128 j, uint dx) external view returns (uint dy);
    function get_dx_underlying(int128 i, int128 j, uint dy) external view returns (uint dx);
    function exchange_underlying(int128 i, int128 j, uint dx, uint min_dy) external;
}


interface IStableSwapCompound {
    function get_virtual_price() external view returns (uint);
    function calc_token_amount(uint[2] calldata amounts, bool deposit) external view returns (uint);
    function get_dy_underlying(int128 i, int128 j, uint dx) external view returns (uint dy);
    function get_dx_underlying(int128 i, int128 j, uint dy) external view returns (uint dx);
    function exchange_underlying(int128 i, int128 j, uint dx, uint min_dy) external;
}

interface IDepositCompound {
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
    function add_liquidity(uint[2] calldata amounts, uint min_mint_amount) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_amount) external;
}

interface CTokenInterface {
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
}









contract StableSwapCompoundConverter is IMultiVaultConverter {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20[2] public cpoolTokens;

    CTokenInterface[2] public cpoolCTokens;

    IERC20 public tokenUSDT;

    IERC20 public tokenBUSD;

    IERC20 public token3Crv;

    IERC20 public tokenSUSD;

    IERC20 public tokenHUSD;

    IERC20 public tokenCCrv;

    address public governance;

    IStableSwap3Pool public stableSwap3Pool;
    IStableSwapBUSD public stableSwapBUSD;
    IStableSwapSUSD public stableSwapSUSD;
    IStableSwapHUSD public stableSwapHUSD;
    IStableSwapCompound public stableSwapCompound;

    IDepositCompound public depositCompound;

    IValueVaultMaster public vaultMaster;

    uint public defaultSlippage = 1;


    constructor (IERC20 _tokenDAI, IERC20 _tokenUSDC, IERC20 _tokenUSDT, IERC20 _token3Crv,
        IERC20 _tokenBUSD, IERC20 _tokenSUSD, IERC20 _tokenHUSD,
        IERC20 _tokenCCrv, CTokenInterface _tokenCDAI, CTokenInterface _tokenCUSDC,
        address[] memory _stableSwapUSD,
        IDepositCompound _depositCompound,
        IValueVaultMaster _vaultMaster) public {
        cpoolTokens[0] = _tokenDAI;
        cpoolTokens[1] = _tokenUSDC;
        tokenUSDT = _tokenUSDT;
        tokenBUSD = _tokenBUSD;
        token3Crv = _token3Crv;
        tokenSUSD = _tokenSUSD;
        tokenHUSD = _tokenHUSD;
        tokenCCrv = _tokenCCrv;

        cpoolCTokens[0] = _tokenCDAI;
        cpoolCTokens[1] = _tokenCUSDC;

        stableSwap3Pool = IStableSwap3Pool(_stableSwapUSD[0]);
        stableSwapBUSD = IStableSwapBUSD(_stableSwapUSD[1]);
        stableSwapSUSD = IStableSwapSUSD(_stableSwapUSD[2]);
        stableSwapHUSD = IStableSwapHUSD(_stableSwapUSD[3]);
        stableSwapCompound = IStableSwapCompound(_stableSwapUSD[4]);

        depositCompound = _depositCompound;

        cpoolTokens[0].safeApprove(address(stableSwap3Pool), type(uint256).max);
        cpoolTokens[1].safeApprove(address(stableSwap3Pool), type(uint256).max);
        tokenUSDT.safeApprove(address(stableSwap3Pool), type(uint256).max);
        token3Crv.safeApprove(address(stableSwap3Pool), type(uint256).max);

        cpoolTokens[0].safeApprove(address(stableSwapBUSD), type(uint256).max);
        cpoolTokens[1].safeApprove(address(stableSwapBUSD), type(uint256).max);
        tokenUSDT.safeApprove(address(stableSwapBUSD), type(uint256).max);
        tokenBUSD.safeApprove(address(stableSwapBUSD), type(uint256).max);

        cpoolTokens[0].safeApprove(address(stableSwapSUSD), type(uint256).max);
        cpoolTokens[1].safeApprove(address(stableSwapSUSD), type(uint256).max);
        tokenUSDT.safeApprove(address(stableSwapSUSD), type(uint256).max);
        tokenSUSD.safeApprove(address(stableSwapSUSD), type(uint256).max);

        token3Crv.safeApprove(address(stableSwapHUSD), type(uint256).max);
        tokenHUSD.safeApprove(address(stableSwapHUSD), type(uint256).max);

        cpoolTokens[0].safeApprove(address(stableSwapCompound), type(uint256).max);
        cpoolTokens[1].safeApprove(address(stableSwapCompound), type(uint256).max);
        tokenCCrv.safeApprove(address(stableSwapCompound), type(uint256).max);

        cpoolTokens[0].safeApprove(address(depositCompound), type(uint256).max);
        cpoolTokens[1].safeApprove(address(depositCompound), type(uint256).max);
        tokenCCrv.safeApprove(address(depositCompound), type(uint256).max);

        vaultMaster = _vaultMaster;
        governance = msg.sender;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setVaultMaster(IValueVaultMaster _vaultMaster) external {
        require(msg.sender == governance, "!governance");
        vaultMaster = _vaultMaster;
    }

    function approveForSpender(IERC20 _token, address _spender, uint _amount) external {
        require(msg.sender == governance, "!governance");
        _token.safeApprove(_spender, _amount);
    }

    function setDefaultSlippage(uint _defaultSlippage) external {
        require(msg.sender == governance, "!governance");
        require(_defaultSlippage <= 100, "_defaultSlippage>1%");
        defaultSlippage = _defaultSlippage;
    }

    function token() external override returns (address) {
        return address(tokenCCrv);
    }


    function get_virtual_price() external override view returns (uint) {
        return stableSwapCompound.get_virtual_price();
    }

    function convert_rate(address _input, address _output, uint _inputAmount) public override view returns (uint _outputAmount) {
        if (address(this).balance == 0) return 0;
        if (_output == address(tokenCCrv)) {
            uint[2] memory _amounts;
            for (uint8 i = 0; i < 2; i++) {
                if (_input == address(cpoolTokens[i])) {
                    _amounts[i] = _convert_underlying_to_ctoken(cpoolCTokens[i], _inputAmount);
                    _outputAmount = stableSwapCompound.calc_token_amount(_amounts, true);
                    return _outputAmount.mul(10000 - defaultSlippage).div(10000);
                }
            }
            if (_input == address(tokenUSDT)) {
                uint _dai = stableSwap3Pool.get_dy(int128(2), int128(0), _inputAmount);
                _amounts[0] = _convert_underlying_to_ctoken(cpoolCTokens[0], _dai);
                _outputAmount = stableSwapCompound.calc_token_amount(_amounts, true);
            }
            if (_input == address(tokenBUSD)) {
                uint _dai = stableSwapBUSD.get_dy_underlying(int128(3), int128(0), _inputAmount);
                _amounts[0] = _convert_underlying_to_ctoken(cpoolCTokens[0], _dai);
                _outputAmount = stableSwapCompound.calc_token_amount(_amounts, true);
            }
            if (_input == address(tokenSUSD)) {
                uint _dai = stableSwapSUSD.get_dy_underlying(int128(3), int128(0), _inputAmount);
                _amounts[0] = _convert_underlying_to_ctoken(cpoolCTokens[0], _dai);
                _outputAmount = stableSwapCompound.calc_token_amount(_amounts, true);
            }
            if (_input == address(tokenHUSD)) {
                uint _3crvAmount = stableSwapHUSD.get_dy(int128(0), int128(1), _inputAmount);
                uint _dai = stableSwap3Pool.calc_withdraw_one_coin(_3crvAmount, 0);
                _amounts[0] = _convert_underlying_to_ctoken(cpoolCTokens[0], _dai);
                _outputAmount = stableSwapCompound.calc_token_amount(_amounts, true);
            }
            if (_input == address(token3Crv)) {
                uint _dai = stableSwap3Pool.calc_withdraw_one_coin(_inputAmount, 0);
                _amounts[0] = _convert_underlying_to_ctoken(cpoolCTokens[0], _dai);
                _outputAmount = stableSwapCompound.calc_token_amount(_amounts, true);
            }
        } else if (_input == address(tokenCCrv)) {
            for (uint8 i = 0; i < 2; i++) {
                if (_output == address(cpoolTokens[i])) {
                    _outputAmount = depositCompound.calc_withdraw_one_coin(_inputAmount, i);
                    return _outputAmount.mul(10000 - defaultSlippage).div(10000);
                }
            }
            if (_output == address(tokenUSDT)) {
                uint _daiAmount = depositCompound.calc_withdraw_one_coin(_inputAmount, 0);
                _outputAmount = stableSwap3Pool.get_dy(int128(0), int128(2), _daiAmount);
            }
            if (_output == address(tokenBUSD)) {
                uint _daiAmount = depositCompound.calc_withdraw_one_coin(_inputAmount, 0);
                _outputAmount = stableSwapBUSD.get_dy_underlying(int128(0), int128(3), _daiAmount);
            }
            if (_output == address(tokenSUSD)) {
                uint _daiAmount = depositCompound.calc_withdraw_one_coin(_inputAmount, 0);
                _outputAmount = stableSwapSUSD.get_dy_underlying(int128(0), int128(3), _daiAmount);
            }
            if (_output == address(tokenHUSD)) {
                uint _3crvAmount = _convert_ccrv_to_3crv_rate(_inputAmount);
                _outputAmount = stableSwapHUSD.get_dy(int128(1), int128(0), _3crvAmount);
            }
        }
        if (_outputAmount > 0) {
            uint _slippage = _outputAmount.mul(vaultMaster.convertSlippage(_input, _output)).div(10000);
            _outputAmount = _outputAmount.sub(_slippage);
        }
    }

    function _convert_ccrv_to_3crv_rate(uint _ccrvAmount) internal view returns (uint _3crv) {
        uint[3] memory _amounts;
        _amounts[0] = depositCompound.calc_withdraw_one_coin(_ccrvAmount, 0);
        _3crv = stableSwap3Pool.calc_token_amount(_amounts, true);
    }


    function calc_token_amount_deposit(uint[] calldata _amounts) external override view returns (uint _shareAmount) {
        if (_amounts[0] > 0 || _amounts[1] > 0) {
            uint[2] memory _cpoolAmounts;
            _cpoolAmounts[0] = _convert_underlying_to_ctoken(cpoolCTokens[0], _amounts[0]);
            _cpoolAmounts[1] = _convert_underlying_to_ctoken(cpoolCTokens[1], _amounts[1]);
            _shareAmount = stableSwapCompound.calc_token_amount(_cpoolAmounts, true);
        }
        if (_amounts[2] > 0) {
            _shareAmount = _shareAmount.add(convert_rate(address(tokenUSDT), address(tokenCCrv), _amounts[2]));
        }
        if (_amounts[3] > 0) {
            _shareAmount = _shareAmount.add(convert_rate(address(token3Crv), address(tokenCCrv), _amounts[3]));
        }
        if (_amounts[4] > 0) {
            _shareAmount = _shareAmount.add(convert_rate(address(tokenBUSD), address(tokenCCrv), _amounts[4]));
        }
        if (_amounts[5] > 0) {
            _shareAmount = _shareAmount.add(convert_rate(address(tokenSUSD), address(tokenCCrv), _amounts[5]));
        }
        if (_amounts[6] > 0) {
            _shareAmount = _shareAmount.add(convert_rate(address(tokenHUSD), address(tokenCCrv), _amounts[6]));
        }
        return _shareAmount;
    }

    function calc_token_amount_withdraw(uint _shares, address _output) external override view returns (uint _outputAmount) {
        for (uint8 i = 0; i < 2; i++) {
            if (_output == address(cpoolTokens[i])) {
                _outputAmount = depositCompound.calc_withdraw_one_coin(_shares, i);
                return _outputAmount.mul(10000 - defaultSlippage).div(10000);
            }
        }
        if (_output == address(token3Crv)) {
            _outputAmount = _convert_ccrv_to_3crv_rate(_shares);
        } else if (_output == address(tokenUSDT)) {
            uint _daiAmount = depositCompound.calc_withdraw_one_coin(_shares, 0);
            _outputAmount = stableSwap3Pool.get_dy(int128(0), int128(2), _daiAmount);
        } else if (_output == address(tokenBUSD)) {
            uint _daiAmount = depositCompound.calc_withdraw_one_coin(_shares, 0);
            _outputAmount = stableSwapBUSD.get_dy_underlying(int128(0), int128(3), _daiAmount);
        } else if (_output == address(tokenSUSD)) {
            uint _daiAmount = depositCompound.calc_withdraw_one_coin(_shares, 0);
            _outputAmount = stableSwapSUSD.get_dy_underlying(int128(0), int128(3), _daiAmount);
        } else if (_output == address(tokenHUSD)) {
            uint _3crvAmount = _convert_ccrv_to_3crv_rate(_shares);
            _outputAmount = stableSwapHUSD.get_dy(int128(1), int128(0), _3crvAmount);
        }
        if (_outputAmount > 0) {
            uint _slippage = _outputAmount.mul(vaultMaster.slippage(_output)).div(10000);
            _outputAmount = _outputAmount.sub(_slippage);
        }
    }

    function convert(address _input, address _output, uint _inputAmount) external override returns (uint _outputAmount) {
        require(vaultMaster.isVault(msg.sender) || vaultMaster.isController(msg.sender) || msg.sender == governance, "!(governance||vault||controller)");
        if (_output == address(tokenCCrv)) {
            uint[2] memory amounts;
            for (uint8 i = 0; i < 2; i++) {
                if (_input == address(cpoolTokens[i])) {
                    amounts[i] = _inputAmount;
                    uint _before = tokenCCrv.balanceOf(address(this));
                    depositCompound.add_liquidity(amounts, 1);
                    uint _after = tokenCCrv.balanceOf(address(this));
                    _outputAmount = _after.sub(_before);
                    tokenCCrv.safeTransfer(msg.sender, _outputAmount);
                    return _outputAmount;
                }
            }
            if (_input == address(token3Crv)) {
                _outputAmount = _convert_3crv_to_shares(_inputAmount);
                tokenCCrv.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
            if (_input == address(tokenUSDT)) {
                _outputAmount = _convert_usdt_to_shares(_inputAmount);
                tokenCCrv.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
            if (_input == address(tokenBUSD)) {
                _outputAmount = _convert_busd_to_shares(_inputAmount);
                tokenCCrv.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
            if (_input == address(tokenSUSD)) {
                _outputAmount = _convert_susd_to_shares(_inputAmount);
                tokenCCrv.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
            if (_input == address(tokenHUSD)) {
                _outputAmount = _convert_husd_to_shares(_inputAmount);
                tokenCCrv.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
        } else if (_input == address(tokenCCrv)) {
            for (uint8 i = 0; i < 2; i++) {
                if (_output == address(cpoolTokens[i])) {
                    uint _before = cpoolTokens[i].balanceOf(address(this));
                    depositCompound.remove_liquidity_one_coin(_inputAmount, i, 1);
                    uint _after = cpoolTokens[i].balanceOf(address(this));
                    _outputAmount = _after.sub(_before);
                    cpoolTokens[i].safeTransfer(msg.sender, _outputAmount);
                    return _outputAmount;
                }
            }
            if (_output == address(token3Crv)) {

                uint[3] memory amounts;
                uint _before = cpoolTokens[0].balanceOf(address(this));
                depositCompound.remove_liquidity_one_coin(_inputAmount, 0, 1);
                uint _after = cpoolTokens[0].balanceOf(address(this));
                amounts[0] = _after.sub(_before);


                _before = token3Crv.balanceOf(address(this));
                stableSwap3Pool.add_liquidity(amounts, 1);
                _after = token3Crv.balanceOf(address(this));
                _outputAmount = _after.sub(_before);

                token3Crv.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
            if (_output == address(tokenUSDT)) {

                uint _before = cpoolTokens[0].balanceOf(address(this));
                depositCompound.remove_liquidity_one_coin(_inputAmount, 0, 1);
                uint _after = cpoolTokens[0].balanceOf(address(this));
                _outputAmount = _after.sub(_before);


                _before = tokenUSDT.balanceOf(address(this));
                stableSwap3Pool.exchange(int128(0), int128(2), _outputAmount, 1);
                _after = tokenUSDT.balanceOf(address(this));
                _outputAmount = _after.sub(_before);

                tokenUSDT.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
            if (_output == address(tokenBUSD)) {

                uint _before = cpoolTokens[0].balanceOf(address(this));
                depositCompound.remove_liquidity_one_coin(_inputAmount, 0, 1);
                uint _after = cpoolTokens[0].balanceOf(address(this));
                _outputAmount = _after.sub(_before);


                _before = tokenBUSD.balanceOf(address(this));
                stableSwapBUSD.exchange_underlying(int128(0), int128(3), _outputAmount, 1);
                _after = tokenBUSD.balanceOf(address(this));
                _outputAmount = _after.sub(_before);

                tokenBUSD.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
            if (_output == address(tokenSUSD)) {

                uint _before = cpoolTokens[0].balanceOf(address(this));
                depositCompound.remove_liquidity_one_coin(_inputAmount, 0, 1);
                uint _after = cpoolTokens[0].balanceOf(address(this));
                _outputAmount = _after.sub(_before);


                _before = tokenSUSD.balanceOf(address(this));
                stableSwapSUSD.exchange_underlying(int128(0), int128(3), _outputAmount, 1);
                _after = tokenSUSD.balanceOf(address(this));
                _outputAmount = _after.sub(_before);

                tokenSUSD.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
            if (_output == address(tokenHUSD)) {
                _outputAmount = _convert_shares_to_husd(_inputAmount);
                tokenHUSD.safeTransfer(msg.sender, _outputAmount);
                return _outputAmount;
            }
        }
        return 0;
    }

    function convertAll(uint[] calldata) external override returns (uint) {
        revert("Not implemented");
    }


    function _convert_underlying_to_ctoken(CTokenInterface ctoken, uint _amount) internal view returns (uint _outputAmount) {
        _outputAmount = _amount.mul(10 ** 18).div(ctoken.exchangeRateStored());
    }


    function _convert_3crv_to_shares(uint _3crv) internal returns (uint _shares) {

        uint[2] memory amounts;
        uint _before = cpoolTokens[0].balanceOf(address(this));
        stableSwap3Pool.remove_liquidity_one_coin(_3crv, 0, 1);
        uint _after = cpoolTokens[0].balanceOf(address(this));
        amounts[0] = _after.sub(_before);


        _before = tokenCCrv.balanceOf(address(this));
        depositCompound.add_liquidity(amounts, 1);
        _after = tokenCCrv.balanceOf(address(this));

        _shares = _after.sub(_before);
    }


    function _convert_usdt_to_shares(uint _usdt) internal returns (uint _shares) {

        uint[2] memory amounts;
        uint _before = cpoolTokens[0].balanceOf(address(this));
        stableSwap3Pool.exchange(2, 0, _usdt, 1);
        uint _after = cpoolTokens[0].balanceOf(address(this));
        amounts[0] = _after.sub(_before);


        _before = tokenCCrv.balanceOf(address(this));
        depositCompound.add_liquidity(amounts, 1);
        _after = tokenCCrv.balanceOf(address(this));

        _shares = _after.sub(_before);
    }


    function _convert_busd_to_shares(uint _busd) internal returns (uint _shares) {

        uint[2] memory amounts;
        uint _before = cpoolTokens[0].balanceOf(address(this));
        stableSwapBUSD.exchange_underlying(3, 0, _busd, 1);
        uint _after = cpoolTokens[0].balanceOf(address(this));
        amounts[0] = _after.sub(_before);


        _before = tokenCCrv.balanceOf(address(this));
        depositCompound.add_liquidity(amounts, 1);
        _after = tokenCCrv.balanceOf(address(this));

        _shares = _after.sub(_before);
    }


    function _convert_susd_to_shares(uint _amount) internal returns (uint _shares) {

        uint[2] memory amounts;
        uint _before = cpoolTokens[0].balanceOf(address(this));
        stableSwapSUSD.exchange_underlying(int128(3), int128(0), _amount, 1);
        uint _after = cpoolTokens[0].balanceOf(address(this));
        amounts[0] = _after.sub(_before);


        _before = tokenCCrv.balanceOf(address(this));
        depositCompound.add_liquidity(amounts, 1);
        _after = tokenCCrv.balanceOf(address(this));

        _shares = _after.sub(_before);
    }


    function _convert_husd_to_shares(uint _amount) internal returns (uint _shares) {

        uint _before = token3Crv.balanceOf(address(this));
        stableSwapHUSD.exchange(int128(0), int128(1), _amount, 1);
        uint _after = token3Crv.balanceOf(address(this));
        _amount = _after.sub(_before);


        uint[2] memory amounts;
        _before = cpoolTokens[0].balanceOf(address(this));
        stableSwap3Pool.remove_liquidity_one_coin(_amount, 0, 1);
        _after = cpoolTokens[0].balanceOf(address(this));
        amounts[0] = _after.sub(_before);


        _before = tokenCCrv.balanceOf(address(this));
        depositCompound.add_liquidity(amounts, 1);
        _after = tokenCCrv.balanceOf(address(this));

        _shares = _after.sub(_before);
    }


    function _convert_shares_to_husd(uint _amount) internal returns (uint _husd) {

        uint[3] memory amounts;
        uint _before = cpoolTokens[0].balanceOf(address(this));
        depositCompound.remove_liquidity_one_coin(_amount, 0, 1);
        uint _after = cpoolTokens[0].balanceOf(address(this));
        amounts[0] = _after.sub(_before);


        _before = token3Crv.balanceOf(address(this));
        stableSwap3Pool.add_liquidity(amounts, 1);
        _after = token3Crv.balanceOf(address(this));
        _amount = _after.sub(_before);


        _before = tokenHUSD.balanceOf(address(this));
        stableSwapHUSD.exchange(int128(1), int128(0), _amount, 1);
        _after = tokenHUSD.balanceOf(address(this));
        _husd = _after.sub(_before);
    }

    function governanceRecoverUnsupported(IERC20 _token, uint _amount, address _to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(_to, _amount);
    }
}
