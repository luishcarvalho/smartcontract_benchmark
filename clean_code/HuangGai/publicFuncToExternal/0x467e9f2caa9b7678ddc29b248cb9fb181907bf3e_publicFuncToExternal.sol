





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

interface Gauge {
    function deposit(uint) external;
    function balanceOf(address) external view returns (uint);
    function withdraw(uint) external;
    function claimable_tokens(address) external view returns (uint);
}

interface Mintr {
    function mint(address) external;
}

interface Uni {
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external;
}

interface Balancer {
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;
    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountOut, uint spotPriceAfter);
    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountIn, uint spotPriceAfter);
    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut) external returns (uint poolAmountOut);
    function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut) external returns (uint tokenAmountOut);
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

interface IValueMultiVault {
    function cap() external view returns (uint);
    function getConverter(address _want) external view returns (address);
    function getVaultMaster() external view returns (address);
    function balance() external view returns (uint);
    function token() external view returns (address);
    function available(address _want) external view returns (uint);
    function accept(address _input) external view returns (bool);

    function claimInsurance() external;
    function earn(address _want) external;
    function harvest(address reserve, uint amount) external;

    function withdraw_fee(uint _shares) external view returns (uint);
    function calc_token_amount_deposit(uint[] calldata _amounts) external view returns (uint);
    function calc_token_amount_withdraw(uint _shares, address _output) external view returns (uint);
    function convert_rate(address _input, uint _amount) external view returns (uint);
    function getPricePerFullShare() external view returns (uint);
    function get_virtual_price() external view returns (uint);

    function deposit(address _input, uint _amount, uint _min_mint_amount) external returns (uint _mint_amount);
    function depositFor(address _account, address _to, address _input, uint _amount, uint _min_mint_amount) external returns (uint _mint_amount);
    function depositAll(uint[] calldata _amounts, uint _min_mint_amount) external returns (uint _mint_amount);
    function depositAllFor(address _account, address _to, uint[] calldata _amounts, uint _min_mint_amount) external returns (uint _mint_amount);
    function withdraw(uint _shares, address _output, uint _min_output_amount) external returns (uint);
    function withdrawFor(address _account, uint _shares, address _output, uint _min_output_amount) external returns (uint _output_amount);

    function harvestStrategy(address _strategy) external;
    function harvestWant(address _want) external;
    function harvestAllStrategies() external;
}

interface IMultiVaultController {
    function vault() external view returns (address);

    function wantQuota(address _want) external view returns (uint);
    function wantStrategyLength(address _want) external view returns (uint);
    function wantStrategyBalance(address _want) external view returns (uint);

    function getStrategyCount() external view returns(uint);
    function strategies(address _want, uint _stratId) external view returns (address _strategy, uint _quota, uint _percent);
    function getBestStrategy(address _want) external view returns (address _strategy);

    function basedWant() external view returns (address);
    function want() external view returns (address);
    function wantLength() external view returns (uint);

    function balanceOf(address _want, bool _sell) external view returns (uint);
    function withdraw_fee(address _want, uint _amount) external view returns (uint);
    function investDisabled(address _want) external view returns (bool);

    function withdraw(address _want, uint) external returns (uint _withdrawFee);
    function earn(address _token, uint _amount) external;

    function harvestStrategy(address _strategy) external;
    function harvestWant(address _want) external;
    function harvestAllStrategies() external;
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














abstract contract StrategyCurveBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;

    Uni public unirouter = Uni(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);


    address public crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public t3crv = address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);


    address public dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    Mintr public crvMintr = Mintr(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    IStableSwap3Pool public stableSwap3Pool = IStableSwap3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    address public want;
    Gauge public gauge;

    uint public withdrawalFee = 0;

    address public governance;
    address public timelock = address(0x105e62e4bDFA67BCA18400Cfbe2EAcD4D0Be080d);
    address public controller;
    address public strategist;

    IValueMultiVault public vault;
    IValueVaultMaster public vaultMaster;

    mapping(address => mapping(address => address[])) public uniswapPaths;
    mapping(address => mapping(address => address)) public balancerPools;

    constructor(address _want, address _crv, address _weth, address _t3crv,
        address _dai, address _usdc, address _usdt,
        Gauge _gauge, Mintr _crvMintr,
        IStableSwap3Pool _stableSwap3Pool, address _controller) public {
        want = _want;
        if (_crv != address(0)) crv = _crv;
        if (_weth != address(0)) weth = _weth;
        if (_t3crv != address(0)) t3crv = _t3crv;
        if (_dai != address(0)) dai = _dai;
        if (_usdc != address(0)) usdc = _usdc;
        if (_usdt != address(0)) usdt = _usdt;
        if (address(_stableSwap3Pool) != address(0)) stableSwap3Pool = _stableSwap3Pool;
        gauge = _gauge;
        if (address(_crvMintr) != address(0)) crvMintr = _crvMintr;
        controller = _controller;
        vault = IValueMultiVault(IMultiVaultController(_controller).vault());
        require(address(vault) != address(0), "!vault");
        vaultMaster = IValueVaultMaster(vault.getVaultMaster());
        governance = msg.sender;
        strategist = msg.sender;
        IERC20(want).safeApprove(address(gauge), type(uint256).max);
        IERC20(weth).safeApprove(address(unirouter), type(uint256).max);
        IERC20(crv).safeApprove(address(unirouter), type(uint256).max);
        IERC20(dai).safeApprove(address(stableSwap3Pool), type(uint256).max);
        IERC20(usdc).safeApprove(address(stableSwap3Pool), type(uint256).max);
        IERC20(usdt).safeApprove(address(stableSwap3Pool), type(uint256).max);
        IERC20(t3crv).safeApprove(address(stableSwap3Pool), type(uint256).max);
    }

    function getMostPremium() public view returns (address, uint256)
    {
        uint256[] memory balances = new uint256[](3);
        balances[0] = stableSwap3Pool.balances(0);
        balances[1] = stableSwap3Pool.balances(1).mul(10**12);
        balances[2] = stableSwap3Pool.balances(2).mul(10**12);


        if (balances[0] < balances[1] && balances[0] < balances[2]) {
            return (dai, 0);
        }


        if (balances[1] < balances[0] && balances[1] < balances[2]) {
            return (usdc, 1);
        }


        if (balances[2] < balances[0] && balances[2] < balances[1]) {
            return (usdt, 2);
        }


        return (dai, 0);
    }

    function getName() public virtual pure returns (string memory);

    function setStrategist(address _strategist) public {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function setWithdrawalFee(uint _withdrawalFee) public {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function approveForSpender(IERC20 _token, address _spender, uint _amount) public {
        require(msg.sender == controller || msg.sender == governance, "!authorized");
        _token.safeApprove(_spender, _amount);
    }

    function setUnirouter(Uni _unirouter) public {
        require(msg.sender == governance, "!governance");
        unirouter = _unirouter;
        IERC20(weth).safeApprove(address(unirouter), type(uint256).max);
        IERC20(crv).safeApprove(address(unirouter), type(uint256).max);
    }

    function deposit() public {
        uint _wantBal = IERC20(want).balanceOf(address(this));
        if (_wantBal > 0) {

            gauge.deposit(_wantBal);
        }
    }

    function skim() public {
        uint _balance = IERC20(want).balanceOf(address(this));
        IERC20(want).safeTransfer(controller, _balance);
    }


    function withdraw(IERC20 _asset) public returns (uint balance) {
        require(msg.sender == controller || msg.sender == governance || msg.sender == strategist, "!authorized");

        require(want != address(_asset), "want");

        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    function withdrawToController(uint _amount) public {
        require(msg.sender == controller || msg.sender == governance || msg.sender == strategist, "!authorized");
        require(controller != address(0), "!controller");

        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20(want).safeTransfer(controller, _amount);
    }


    function withdraw(uint _amount) public returns (uint) {
        require(msg.sender == controller || msg.sender == governance || msg.sender == strategist, "!authorized");

        uint _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        IERC20(want).safeTransfer(address(vault), _amount);
        return _amount;
    }


    function withdrawAll() public returns (uint balance) {
        require(msg.sender == controller || msg.sender == governance || msg.sender == strategist, "!authorized");
        _withdrawAll();

        balance = IERC20(want).balanceOf(address(this));

        IERC20(want).safeTransfer(address(vault), balance);
    }

    function claimReward() public {
        crvMintr.mint(address(gauge));
    }

    function _withdrawAll() internal {
        uint _bal = gauge.balanceOf(address(this));
        gauge.withdraw(_bal);
    }

    function setUnirouterPath(address _input, address _output, address [] memory _path) public {
        require(msg.sender == governance || msg.sender == strategist, "!authorized");
        uniswapPaths[_input][_output] = _path;
    }

    function setBalancerPools(address _input, address _output, address _pool) public {
        require(msg.sender == governance || msg.sender == strategist, "!authorized");
        balancerPools[_input][_output] = _pool;
        IERC20(_input).safeApprove(_pool, type(uint256).max);
    }

    function _swapTokens(address _input, address _output, uint256 _amount) internal {
        address _pool = balancerPools[_input][_output];
        if (_pool != address(0)) {
            Balancer(_pool).swapExactAmountIn(_input, _amount, _output, 1, type(uint256).max);
        } else {
            address[] memory path = uniswapPaths[_input][_output];
            if (path.length == 0) {

                path = new address[](2);
                path[0] = _input;
                path[1] = _output;
            }
            unirouter.swapExactTokensForTokens(_amount, 1, path, address(this), now.add(1800));
        }
    }

    function _addLiquidity() internal {
        uint[3] memory amounts;
        amounts[0] = IERC20(dai).balanceOf(address(this));
        amounts[1] = IERC20(usdc).balanceOf(address(this));
        amounts[2] = IERC20(usdt).balanceOf(address(this));
        stableSwap3Pool.add_liquidity(amounts, 1);
    }

    function harvest(address _mergedStrategy) public {
        require(msg.sender == controller || msg.sender == strategist || msg.sender == governance, "!authorized");
        claimReward();
        uint _crvBal = IERC20(crv).balanceOf(address(this));

        _swapTokens(crv, weth, _crvBal);
        uint256 _wethBal = IERC20(weth).balanceOf(address(this));

        if (_wethBal > 0) {
            if (_mergedStrategy != address(0)) {
                require(vaultMaster.isStrategy(_mergedStrategy), "!strategy");
                IERC20(weth).safeTransfer(_mergedStrategy, _wethBal);
            } else {
                address govVault = vaultMaster.govVault();
                address performanceReward = vaultMaster.performanceReward();

                if (vaultMaster.govVaultProfitShareFee() > 0 && govVault != address(0)) {
                    address _valueToken = vaultMaster.valueToken();
                    uint256 _govVaultProfitShareFee = _wethBal.mul(vaultMaster.govVaultProfitShareFee()).div(10000);
                    _swapTokens(weth, _valueToken, _govVaultProfitShareFee);
                    IERC20(_valueToken).safeTransfer(govVault, IERC20(_valueToken).balanceOf(address(this)));
                }

                if (vaultMaster.gasFee() > 0 && performanceReward != address(0)) {
                    uint256 _gasFee = _wethBal.mul(vaultMaster.gasFee()).div(10000);
                    IERC20(weth).safeTransfer(performanceReward, _gasFee);
                }

                _wethBal = IERC20(weth).balanceOf(address(this));

                (address _stableCoin,) = getMostPremium();
                _swapTokens(weth, _stableCoin, _wethBal);
                _addLiquidity();

                uint _3crvBal = IERC20(t3crv).balanceOf(address(this));
                if (_3crvBal > 0) {
                    IERC20(t3crv).safeTransfer(address(vault), _3crvBal);
                }
            }
        }
    }

    function _withdrawSome(uint _amount) internal returns (uint) {
        uint _before = IERC20(want).balanceOf(address(this));
        gauge.withdraw(_amount);
        uint _after = IERC20(want).balanceOf(address(this));
        _amount = _after.sub(_before);

        return _amount;
    }

    function balanceOfWant() public view returns (uint) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint) {
        return gauge.balanceOf(address(this));
    }

    function balanceOf() public view returns (uint) {
        return balanceOfWant()
               .add(balanceOfPool());
    }

    function claimable_tokens() public view returns (uint) {
        return gauge.claimable_tokens(address(this));
    }

    function withdrawFee(uint _amount) public view returns (uint) {
        return _amount.mul(withdrawalFee).div(10000);
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setTimelock(address _timelock) public {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function setController(address _controller) public {
        require(msg.sender == governance, "!governance");
        controller = _controller;
        vault = IValueMultiVault(IMultiVaultController(_controller).vault());
        require(address(vault) != address(0), "!vault");
        vaultMaster = IValueVaultMaster(vault.getVaultMaster());
    }

    event ExecuteTransaction(address indexed target, uint value, string signature, bytes data);




    function executeTransaction(address target, uint value, string memory signature, bytes memory data) public returns (bytes memory) {
        require(msg.sender == timelock, "!timelock");

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }


        (bool success, bytes memory returnData) = target.call{value : value}(callData);
        require(success, string(abi.encodePacked(getName(), "::executeTransaction: Transaction execution reverted.")));

        emit ExecuteTransaction(target, value, signature, data);

        return returnData;
    }
}

contract StrategyCurve3Crv is StrategyCurveBase {


    constructor(address _want, address _crv, address _weth, address _t3crv,
        address _dai, address _usdc, address _usdt,
        Gauge _gauge, Mintr _crvMintr,
        IStableSwap3Pool _stableSwap3Pool, address _controller) public
            StrategyCurveBase(_want, _crv, _weth, _t3crv, _dai, _usdc, _usdt, _gauge, _crvMintr, _stableSwap3Pool, _controller) {
    }

    function getName() public override pure returns (string memory) {
        return "mvUSD:StrategyCurve3Crv";
    }
}
