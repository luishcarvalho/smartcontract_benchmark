


pragma solidity ^0.8.0;




interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}





pragma solidity ^0.8.0;




library Address {

















    function isContract(address account) internal view returns (bool) {




        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }







    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }







    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }







    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }







    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }







    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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





pragma solidity ^0.8.0;











library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }








    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {



        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}





pragma solidity ^0.8.0;

















abstract contract ReentrancyGuard {











    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }








    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");


        _status = _ENTERED;

        _;



        _status = _NOT_ENTERED;
    }
}





pragma solidity 0.8.9;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}





pragma solidity 0.8.9;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}





pragma solidity 0.8.9;

interface IMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accCakePerShare;
    }

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function enterStaking(uint256 _amount) external;

    function leaveStaking(uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

    function emergencyWithdraw(uint256 _pid) external;
}





pragma solidity 0.8.9;

interface IByalanIsland {
    function izlude() external view returns (address);
}





pragma solidity 0.8.9;

interface ISailor {
    function MAX_FEE() external view returns (uint256);

    function totalFee() external view returns (uint256);

    function callFee() external view returns (uint256);

    function kswFee() external view returns (uint256);
}





pragma solidity 0.8.9;
interface IByalan is IByalanIsland, ISailor {
    function want() external view returns (address);

    function beforeDeposit() external;

    function deposit() external;

    function withdraw(uint256) external;

    function balanceOf() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function balanceOfMasterChef() external view returns (uint256);

    function pendingRewardTokens() external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts);

    function harvest() external;

    function retireStrategy() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);
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













abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor() {
        _setOwner(_msgSender());
    }




    function owner() public view virtual returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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





pragma solidity 0.8.9;

interface IGasPrice {
    function maxGasPrice() external returns (uint256);
}





pragma solidity 0.8.9;



abstract contract ByalanIsland is Ownable, Pausable, IByalanIsland {
    address public hydra;
    address public unirouter;
    address public override izlude;
    address public kswFeeRecipient;
    address public treasuryFeeRecipient;
    address public harvester;

    address public gasPrice = 0x077969d99cAcaD858085115c97415A36885B81Ba;

    event SetHydra(address hydra);
    event SetRouter(address router);
    event SetKswFeeRecipient(address kswFeeRecipient);
    event SetTreasuryFeeRecipient(address treasuryFeeRecipient);
    event SetHarvester(address harvester);
    event SetGasPrice(address gasPrice);

    constructor(
        address _hydra,
        address _unirouter,
        address _izlude,
        address _kswFeeRecipient,
        address _treasuryFeeRecipient,
        address _harvester
    ) {
        hydra = _hydra;
        unirouter = _unirouter;
        izlude = _izlude;
        kswFeeRecipient = _kswFeeRecipient;
        treasuryFeeRecipient = _treasuryFeeRecipient;
        harvester = _harvester;
    }


    modifier onlyHydra() {
        require(msg.sender == owner() || msg.sender == hydra, "!hydra");
        _;
    }


    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }

    modifier onlyIzlude() {
        require(msg.sender == izlude, "!izlude");
        _;
    }

    modifier onlyEOAandIzlude() {
        require(tx.origin == msg.sender || msg.sender == izlude, "!contract");
        _;
    }

    modifier onlyHarvester() {
        require(harvester == address(0) || msg.sender == harvester, "!harvester");
        _;
    }

    modifier gasThrottle() {
        require(tx.gasprice <= IGasPrice(gasPrice).maxGasPrice(), "gas is too high!");
        _;
    }

    function setHydra(address _hydra) external onlyHydra {
        hydra = _hydra;
        emit SetHydra(_hydra);
    }

    function setUnirouter(address _unirouter) external onlyOwner {
        unirouter = _unirouter;
        emit SetRouter(_unirouter);
    }

    function setIzlude(address _izlude) external onlyOwner {
        require(izlude == address(0), "already set");
        izlude = _izlude;
    }

    function setTreasuryFeeRecipient(address _treasuryFeeRecipient) external onlyOwner {
        treasuryFeeRecipient = _treasuryFeeRecipient;
        emit SetTreasuryFeeRecipient(_treasuryFeeRecipient);
    }

    function setKswFeeRecipient(address _kswFeeRecipient) external onlyOwner {
        kswFeeRecipient = _kswFeeRecipient;
        emit SetKswFeeRecipient(_kswFeeRecipient);
    }

    function setHarvester(address _harvester) external onlyOwner {
        harvester = _harvester;
        emit SetHarvester(_harvester);
    }

    function setGasPrice(address _gasPrice) external onlyHydra {
        gasPrice = _gasPrice;
        emit SetGasPrice(_gasPrice);
    }
}





pragma solidity 0.8.9;

abstract contract Sailor is ByalanIsland, ISailor {
    uint256 public constant override MAX_FEE = 10000;
    uint256 public override totalFee = 300;
    uint256 public constant MAX_TOTAL_FEE = 1000;

    uint256 public override callFee = 4000;
    uint256 public treasuryFee = 3000;
    uint256 public override kswFee = 3000;
    uint256 public feeSum = 10000;

    event SetTotalFee(uint256 totalFee);
    event SetCallFee(uint256 fee);
    event SetTreasuryFee(uint256 fee);
    event SetKSWFee(uint256 fee);

    function setTotalFee(uint256 _totalFee) external onlyOwner {
        require(_totalFee <= MAX_TOTAL_FEE, "!cap");

        totalFee = _totalFee;
        emit SetTotalFee(_totalFee);
    }

    function setCallFee(uint256 _fee) external onlyOwner {
        callFee = _fee;
        feeSum = callFee + treasuryFee + kswFee;
        emit SetCallFee(_fee);
    }

    function setTreasuryFee(uint256 _fee) external onlyOwner {
        treasuryFee = _fee;
        feeSum = callFee + treasuryFee + kswFee;
        emit SetTreasuryFee(_fee);
    }

    function setKSWFee(uint256 _fee) external onlyOwner {
        kswFee = _fee;
        feeSum = callFee + treasuryFee + kswFee;
        emit SetKSWFee(_fee);
    }
}





pragma solidity 0.8.9;







contract PancakeByalanLP is ByalanIsland, Sailor, IByalan, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;


    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public immutable override want;
    address public immutable lpToken0;
    address public immutable lpToken1;


    address public constant MASTERCHEF = 0x73feaa1eE314F8c655E354234017bE2193C9E24E;
    uint256 public immutable pid;


    address[] public cakeToWbnbRoute;
    address[] public cakeToLp0Route;
    address[] public cakeToLp1Route;

    event Harvest(address indexed harvester);

    constructor(
        address _hydra,
        address _izlude,
        address _kswFeeRecipient,
        address _treasuryFeeRecipient,
        address _harvester,
        uint256 _pid,
        address[] memory _cakeToLp0Route,
        address[] memory _cakeToLp1Route
    )
        ByalanIsland(
            _hydra,
            0x10ED43C718714eb63d5aA57B78B54704E256024E,
            _izlude,
            _kswFeeRecipient,
            _treasuryFeeRecipient,
            _harvester
        )
    {
        pid = _pid;

        want = IMasterChef(MASTERCHEF).poolInfo(_pid).lpToken;
        lpToken0 = IUniswapV2Pair(want).token0();
        lpToken1 = IUniswapV2Pair(want).token1();

        cakeToWbnbRoute = [CAKE, WBNB];
        if (lpToken0 != CAKE) {
            require(_cakeToLp0Route[0] == CAKE, "invalid lp 0 route");
            require(_cakeToLp0Route[_cakeToLp0Route.length - 1] == lpToken0, "invalid lp 0 route");
            require(
                IUniswapV2Router02(unirouter).getAmountsOut(1 ether, _cakeToLp0Route)[_cakeToLp0Route.length - 1] > 0,
                "invalid lp 0 route"
            );
            cakeToLp0Route = _cakeToLp0Route;
        }

        if (lpToken1 != CAKE) {
            require(_cakeToLp1Route[0] == CAKE, "invalid lp 1 route");
            require(_cakeToLp1Route[_cakeToLp1Route.length - 1] == lpToken1, "invalid lp 1 route");
            require(
                IUniswapV2Router02(unirouter).getAmountsOut(1 ether, _cakeToLp1Route)[_cakeToLp1Route.length - 1] > 0,
                "invalid lp 1 route"
            );
            cakeToLp1Route = _cakeToLp1Route;
        }

        _giveAllowances();
    }




    function beforeDeposit() external override {}


    function deposit() public override whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            IMasterChef(MASTERCHEF).deposit(pid, wantBal);
        }
    }

    function withdraw(uint256 _amount) external override onlyIzlude {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            IMasterChef(MASTERCHEF).withdraw(pid, _amount - wantBal);
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        IERC20(want).safeTransfer(izlude, wantBal);
    }



    function harvest() external override whenNotPaused onlyEOA onlyHarvester gasThrottle {
        IMasterChef(MASTERCHEF).deposit(pid, 0);
        chargeFees();
        addLiquidity();
        deposit();

        emit Harvest(msg.sender);
    }


    function chargeFees() internal nonReentrant {
        uint256 toBnb = (IERC20(CAKE).balanceOf(address(this)) * totalFee) / MAX_FEE;
        IUniswapV2Router02(unirouter).swapExactTokensForETH(toBnb, 0, cakeToWbnbRoute, address(this), block.timestamp);

        uint256 bnbBal = address(this).balance;

        uint256 callFeeAmount = (bnbBal * callFee) / feeSum;
        payable(msg.sender).sendValue(callFeeAmount);

        uint256 treasuryFeeAmount = (bnbBal * treasuryFee) / feeSum;
        payable(treasuryFeeRecipient).sendValue(treasuryFeeAmount);

        uint256 kswFeeAmount = (bnbBal * kswFee) / feeSum;
        payable(kswFeeRecipient).sendValue(kswFeeAmount);
    }


    function addLiquidity() internal {
        uint256 cakeHalf = IERC20(CAKE).balanceOf(address(this)) / 2;

        if (lpToken0 != CAKE) {
            IUniswapV2Router02(unirouter).swapExactTokensForTokens(
                cakeHalf,
                0,
                cakeToLp0Route,
                address(this),
                block.timestamp
            );
        }

        if (lpToken1 != CAKE) {
            IUniswapV2Router02(unirouter).swapExactTokensForTokens(
                cakeHalf,
                0,
                cakeToLp1Route,
                address(this),
                block.timestamp
            );
        }

        IUniswapV2Router02(unirouter).addLiquidity(
            lpToken0,
            lpToken1,
            IERC20(lpToken0).balanceOf(address(this)),
            IERC20(lpToken1).balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );
    }


    function balanceOf() external view override returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }


    function balanceOfWant() public view override returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }


    function balanceOfPool() public view override returns (uint256) {
        return IMasterChef(MASTERCHEF).userInfo(pid, address(this)).amount;
    }

    function balanceOfMasterChef() external view override returns (uint256) {
        return IERC20(want).balanceOf(address(MASTERCHEF));
    }

    function pendingRewardTokens()
        external
        view
        override
        returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts)
    {
        rewardTokens = new IERC20[](1);
        rewardAmounts = new uint256[](1);
        rewardTokens[0] = IERC20(CAKE);
        rewardAmounts[0] =
            IMasterChef(MASTERCHEF).pendingCake(pid, address(this)) +
            IERC20(CAKE).balanceOf(address(this));
    }


    function retireStrategy() external override onlyIzlude {
        IMasterChef(MASTERCHEF).emergencyWithdraw(pid);

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(izlude, wantBal);
    }


    function panic() external override onlyHydra {
        pause();
        IMasterChef(MASTERCHEF).emergencyWithdraw(pid);
    }

    function pause() public override onlyHydra {
        _pause();

        _removeAllowances();
    }

    function unpause() external override onlyHydra {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function paused() public view override(IByalan, Pausable) returns (bool) {
        return super.paused();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(MASTERCHEF, type(uint256).max);
        IERC20(CAKE).safeApprove(unirouter, type(uint256).max);


        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, type(uint256).max);

        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(MASTERCHEF, 0);
        IERC20(CAKE).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
    }

    receive() external payable {}
}
