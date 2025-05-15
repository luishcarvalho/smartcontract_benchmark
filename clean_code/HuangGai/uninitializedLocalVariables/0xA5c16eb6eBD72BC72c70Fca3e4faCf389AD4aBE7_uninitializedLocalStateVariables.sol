





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
        uint256 c ;

        require(c >= a, "SafeMath: addition overflow");

        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c ;


        return c;
    }











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c ;

        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }













    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c ;



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
        uint256 newAllowance ;

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance ;

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IConverter {
    function token() external returns (address _share);
    function convert(address _input, address _output, uint _inputAmount) external returns (uint _outputAmount);
    function convert_rate(address _input, address _output, uint _inputAmount) external view returns (uint _outputAmount);
    function convert_stables(uint[3] calldata amounts) external returns (uint _shareAmount);
    function get_dy(int128 i, int128 j, uint dx) external view returns (uint);
    function exchange(int128 i, int128 j, uint dx, uint min_dy) external returns (uint dy);
    function calc_token_amount(uint[3] calldata amounts, bool deposit) external view returns (uint _shareAmount);
    function calc_token_amount_withdraw(uint _shares, address _output) external view returns (uint _outputAmount);
}

interface IVaultManager {
    function yax() external view returns (address);
    function vaults(address) external view returns (bool);
    function controllers(address) external view returns (bool);
    function strategies(address) external view returns (bool);
    function stakingPool() external view returns (address);
    function profitSharer() external view returns (address);
    function treasuryWallet() external view returns (address);
    function performanceReward() external view returns (address);
    function stakingPoolShareFee() external view returns (uint);
    function gasFee() external view returns (uint);
    function insuranceFee() external view returns (uint);
    function withdrawalProtectionFee() external view returns (uint);
}

interface IStableSwap3Pool {
    function get_virtual_price() external view returns (uint);
    function get_dy(int128 i, int128 j, uint dx) external view returns (uint dy);
    function exchange(int128 i, int128 j, uint dx, uint min_dy) external;
    function add_liquidity(uint[3] calldata amounts, uint min_mint_amount) external;
    function remove_liquidity(uint _amount, uint[3] calldata amounts) external;
    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_amount) external;
    function calc_token_amount(uint[3] calldata amounts, bool deposit) external view returns (uint);
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns (uint);
}

contract StableSwap3PoolConverter is IConverter {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20[3] public tokens;
    IERC20 public token3CRV;

    address public governance;

    IStableSwap3Pool public stableSwap3Pool;
    IVaultManager public vaultManager;

    constructor (IERC20 _tokenDAI, IERC20 _tokenUSDC, IERC20 _tokenUSDT, IERC20 _token3CRV, IStableSwap3Pool _stableSwap3Pool, IVaultManager _vaultManager) public {
        tokens[0] = _tokenDAI;
        tokens[1] = _tokenUSDC;
        tokens[2] = _tokenUSDT;
        token3CRV = _token3CRV;
        stableSwap3Pool = _stableSwap3Pool;
        tokens[0].safeApprove(address(stableSwap3Pool), uint(-1));
        tokens[1].safeApprove(address(stableSwap3Pool), uint(-1));
        tokens[2].safeApprove(address(stableSwap3Pool), uint(-1));
        token3CRV.safeApprove(address(stableSwap3Pool), uint(-1));
        vaultManager = _vaultManager;
        governance = msg.sender;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setStableSwap3Pool(IStableSwap3Pool _stableSwap3Pool) public {
        require(msg.sender == governance, "!governance");
        stableSwap3Pool = _stableSwap3Pool;
        tokens[0].safeApprove(address(stableSwap3Pool), uint(-1));
        tokens[1].safeApprove(address(stableSwap3Pool), uint(-1));
        tokens[2].safeApprove(address(stableSwap3Pool), uint(-1));
        token3CRV.safeApprove(address(stableSwap3Pool), uint(-1));
    }

    function setVaultManager(IVaultManager _vaultManager) public {
        require(msg.sender == governance, "!governance");
        vaultManager = _vaultManager;
    }

    function approveForSpender(IERC20 _token, address _spender, uint _amount) external {
        require(msg.sender == governance, "!governance");
        _token.safeApprove(_spender, _amount);
    }

    function token() external override returns (address _share) {
        _share = address(token3CRV);
    }

    function convert(address _input, address _output, uint _inputAmount) external override returns (uint _outputAmount) {
        require(msg.sender == governance || vaultManager.vaults(msg.sender), "!(governance||vault)");
        if (_output == address(token3CRV)) {
            uint[3] memory amounts;
            for (uint8 i ; i < 3; i++) {

                if (_input == address(tokens[i])) {
                    amounts[i] = _inputAmount;
                    uint _before ;

                    stableSwap3Pool.add_liquidity(amounts, 1);
                    uint _after ;

                    _outputAmount = _after.sub(_before);
                    token3CRV.safeTransfer(msg.sender, _outputAmount);
                    return _outputAmount;
                }
            }
        } else if (_input == address(token3CRV)) {
            for (uint8 i ; i < 3; i++) {

                if (_output == address(tokens[i])) {
                    uint _before ;

                    stableSwap3Pool.remove_liquidity_one_coin(_inputAmount, i, 1);
                    uint _after ;

                    _outputAmount = _after.sub(_before);
                    tokens[i].safeTransfer(msg.sender, _outputAmount);
                    return _outputAmount;
                }
            }
        }
        return 0;
    }

    function convert_rate(address _input, address _output, uint _inputAmount) external override view returns (uint _outputAmount) {
        if (_output == address(token3CRV)) {
            uint[3] memory amounts;
            for (uint8 i ; i < 3; i++) {

                if (_input == address(tokens[i])) {
                    amounts[i] = _inputAmount;
                    return stableSwap3Pool.calc_token_amount(amounts, true);
                }
            }
        } else if (_input == address(token3CRV)) {
            for (uint8 i ; i < 3; i++) {

                if (_output == address(tokens[i])) {

                    return stableSwap3Pool.calc_withdraw_one_coin(_inputAmount, i);
                }
            }
        }
        return 0;
    }


    function convert_stables(uint[3] calldata amounts) external override returns (uint _shareAmount) {
        require(msg.sender == governance || vaultManager.vaults(msg.sender), "!(governance||vault)");
        uint _before ;

        stableSwap3Pool.add_liquidity(amounts, 1);
        uint _after ;

        _shareAmount = _after.sub(_before);
        token3CRV.safeTransfer(msg.sender, _shareAmount);
    }

    function get_dy(int128 i, int128 j, uint dx) external override view returns (uint) {
        return stableSwap3Pool.get_dy(i, j, dx);
    }

    function exchange(int128 i, int128 j, uint dx, uint min_dy) external override returns (uint dy) {
        require(msg.sender == governance || vaultManager.vaults(msg.sender), "!(governance||vault)");
        IERC20 _output ;

        uint _before ;

        stableSwap3Pool.exchange(i, j, dx, min_dy);
        uint _after ;

        dy = _after.sub(_before);
        _output.safeTransfer(msg.sender, dy);
    }

    function calc_token_amount(uint[3] calldata amounts, bool deposit) external override view returns (uint _shareAmount) {
        _shareAmount = stableSwap3Pool.calc_token_amount(amounts, deposit);
    }

    function calc_token_amount_withdraw(uint _shares, address _output) external override view returns (uint) {
        for (uint8 i ; i < 3; i++) {

            if (_output == address(tokens[i])) {
                return stableSwap3Pool.calc_withdraw_one_coin(_shares, i);
            }
        }
        return 0;
    }

    function governanceRecoverUnsupported(IERC20 _token, uint _amount, address _to) external {
        require(msg.sender == governance, "!governance");
        _token.transfer(_to, _amount);
    }
}
