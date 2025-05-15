


















pragma solidity 0.6.12;

abstract contract BPoolInterface {
    function approve(address spender, uint256 amount) external virtual returns (bool);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
    function transferFrom(address spender, address recipient, uint256 amount) external virtual returns (bool);

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external virtual;
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external virtual;
    function swapExactAmountIn(address, uint, address, uint, uint) external virtual returns (uint, uint);
    function swapExactAmountOut(address, uint, address, uint, uint) external virtual returns (uint, uint);
    function calcInGivenOut(uint, uint, uint, uint, uint, uint) public pure virtual returns (uint);
    function getDenormalizedWeight(address) external view virtual returns (uint);
    function getBalance(address) external view virtual returns (uint);
    function getSwapFee() external view virtual returns (uint);
    function totalSupply() external view virtual returns (uint);
    function balanceOf(address) external view virtual returns (uint);
    function getTotalDenormalizedWeight() external view virtual returns (uint);

    function getCommunityFee() external view virtual returns (uint, uint, uint, address);
    function calcAmountWithCommunityFee(uint, uint, address) external view virtual returns (uint, uint);
    function getRestrictions() external view virtual returns (address);

    function getCurrentTokens() external view virtual returns (address[] memory tokens);
}





pragma solidity ^0.6.0;




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



pragma solidity 0.6.12;


abstract contract TokenInterface is IERC20 {
    function deposit() public virtual payable;
    function withdraw(uint) public virtual;
}



pragma solidity 0.6.12;


interface IPoolRestrictions {
    function getMaxTotalSupply(address _pool) external virtual view returns(uint256);
    function isVotingSignatureAllowed(address _votingAddress, bytes4 _signature) external virtual view returns(bool);
    function isWithoutFee(address _addr) external virtual view returns(bool);
}



pragma solidity >=0.5.0;

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



pragma solidity =0.6.12;



library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}



pragma solidity >=0.5.0;



library UniswapV2Library {
    using SafeMathUniswap for uint;


    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }


    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303'
            ))));
    }


    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }


    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }


    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }


    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }


    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }


    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}



pragma solidity ^0.6.0;














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



pragma solidity ^0.6.2;




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



pragma solidity ^0.6.0;













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



pragma solidity ^0.6.0;











abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}



pragma solidity ^0.6.0;













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



pragma solidity 0.6.12;











contract EthPiptSwap is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for TokenInterface;

    TokenInterface public weth;
    TokenInterface public cvp;
    BPoolInterface public pipt;

    uint256[] public feeLevels;
    uint256[] public feeAmounts;
    address public feePayout;
    address public feeManager;

    mapping(address => address) public uniswapEthPairByTokenAddress;
    mapping(address => bool) public reApproveTokens;
    uint256 public defaultSlippage;

    struct CalculationStruct {
        uint256 tokenAmount;
        uint256 ethAmount;
        uint256 tokenReserve;
        uint256 ethReserve;
    }

    event SetTokenSetting(address indexed token, bool reApprove, address uniswapPair);
    event SetDefaultSlippage(uint256 newDefaultSlippage);
    event SetFees(address indexed sender, uint256[] newFeeLevels, uint256[] newFeeAmounts, address indexed feePayout, address indexed feeManager);

    event EthToPiptSwap(address indexed user, uint256 ethSwapAmount, uint256 ethFeeAmount, uint256 piptAmount, uint256 piptCommunityFee);
    event OddEth(address indexed user, uint256 amount);
    event PiptToEthSwap(address indexed user, uint256 piptSwapAmount, uint256 piptCommunityFee, uint256 ethOutAmount, uint256 ethFeeAmount);
    event PayoutCVP(address indexed receiver, uint256 wethAmount, uint256 cvpAmount);

    constructor(
        address _weth,
        address _cvp,
        address _pipt,
        address _feeManager
    ) public Ownable() {
        weth = TokenInterface(_weth);
        cvp = TokenInterface(_cvp);
        pipt = BPoolInterface(_pipt);
        feeManager = _feeManager;
        defaultSlippage = 0.02 ether;
    }

    modifier onlyFeeManagerOrOwner() {
        require(msg.sender == feeManager || msg.sender == owner(), "NOT_FEE_MANAGER");
        _;
    }

    receive() external payable {
        if (msg.sender != tx.origin) {
            return;
        }
        swapEthToPipt(defaultSlippage);
    }

    function swapEthToPipt(uint256 _slippage) public payable {
        (, uint256 swapAmount) = calcEthFee(msg.value);

        address[] memory tokens = pipt.getCurrentTokens();

        (, , uint256 poolAmountOut) = calcSwapEthToPiptInputs(swapAmount, tokens, _slippage);

        swapEthToPiptByPoolOut(poolAmountOut);
    }

    function swapEthToPiptByPoolOut(uint256 _poolAmountOut) public payable {
        {
            address poolRestrictions = pipt.getRestrictions();
            if(address(poolRestrictions) != address(0)) {
                uint maxTotalSupply = IPoolRestrictions(poolRestrictions).getMaxTotalSupply(address(pipt));
                require(pipt.totalSupply().add(_poolAmountOut) <= maxTotalSupply, "PIPT_MAX_SUPPLY");
            }
        }

        require(msg.value > 0, "ETH required");
        weth.deposit.value(msg.value)();

        (uint256 feeAmount, uint256 swapAmount) = calcEthFee(msg.value);

        uint ratio = _poolAmountOut.mul(1 ether).div(pipt.totalSupply()).add(10);

        address[] memory tokens = pipt.getCurrentTokens();
        uint256 len = tokens.length;

        CalculationStruct[] memory calculations = new CalculationStruct[](tokens.length);
        uint256[] memory tokensInPipt = new uint256[](tokens.length);

        uint256 totalEthSwap = 0;
        for(uint256 i = 0; i < len; i++) {
            IUniswapV2Pair tokenPair = uniswapPairFor(tokens[i]);

            (calculations[i].tokenReserve, calculations[i].ethReserve,) = tokenPair.getReserves();
            tokensInPipt[i] = ratio.mul(pipt.getBalance(tokens[i])).div(1 ether);
            calculations[i].ethAmount = UniswapV2Library.getAmountIn(
                tokensInPipt[i],
                calculations[i].ethReserve,
                calculations[i].tokenReserve
            );

            weth.transfer(address(tokenPair), calculations[i].ethAmount);

            tokenPair.swap(tokensInPipt[i], uint(0), address(this), new bytes(0));
            totalEthSwap = totalEthSwap.add(calculations[i].ethAmount);

            if(reApproveTokens[tokens[i]]) {
                TokenInterface(tokens[i]).approve(address(pipt), 0);
            }

            TokenInterface(tokens[i]).approve(address(pipt), tokensInPipt[i]);
        }

        (, uint communityJoinFee, ,) = pipt.getCommunityFee();
        (uint poolAmountOutAfterFee, uint poolAmountOutFee) = pipt.calcAmountWithCommunityFee(
            _poolAmountOut,
            communityJoinFee,
            address(this)
        );

        emit EthToPiptSwap(msg.sender, swapAmount, feeAmount, _poolAmountOut, poolAmountOutFee);

        pipt.joinPool(_poolAmountOut, tokensInPipt);
        pipt.transfer(msg.sender, poolAmountOutAfterFee);

        uint256 ethDiff = swapAmount.sub(totalEthSwap);
        if (ethDiff > 0) {
            weth.withdraw(ethDiff);
            msg.sender.transfer(0);
            emit OddEth(msg.sender, ethDiff);
        }
    }

    function swapPiptToEth(uint256 _poolAmountIn) public {
        address[] memory tokens = pipt.getCurrentTokens();
        uint256 len = tokens.length;

        (
            uint256[] memory tokensOutPipt,
            uint256[] memory ethOutUniswap,
            uint256 totalEthOut,
            uint256 poolAmountFee
        ) = calcSwapPiptToEthInputs(_poolAmountIn, tokens);

        pipt.transferFrom(msg.sender, address(this), _poolAmountIn);

        pipt.approve(address(pipt), _poolAmountIn);

        pipt.exitPool(_poolAmountIn, tokensOutPipt);

        for(uint256 i = 0; i < len; i++) {
            IUniswapV2Pair tokenPair = uniswapPairFor(tokens[i]);
            TokenInterface(tokens[i]).transfer(address(tokenPair), tokensOutPipt[i]);
            tokenPair.swap(uint256(0), ethOutUniswap[i], address(this), new bytes(0));
        }

        (uint256 ethFeeAmount, uint256 ethOutAmount) = calcEthFee(totalEthOut);

        weth.withdraw(ethOutAmount);
        msg.sender.transfer(0);

        emit PiptToEthSwap(msg.sender, _poolAmountIn, poolAmountFee, ethOutAmount, ethFeeAmount);
    }

    function convertOddToCvpAndSendToPayout(address[] memory oddTokens) public {
        require(msg.sender == tx.origin && !Address.isContract(msg.sender), "Call from contract not allowed");

        uint256 len = oddTokens.length;

        uint256 totalEthSwap = 0;
        for(uint256 i = 0; i < len; i++) {
            uint256 tokenBalance = TokenInterface(oddTokens[i]).balanceOf(address(this));
            IUniswapV2Pair tokenPair = uniswapPairFor(oddTokens[i]);

            (uint256 tokenReserve, uint256 ethReserve,) = tokenPair.getReserves();
            uint256 wethOut = UniswapV2Library.getAmountOut(tokenBalance, tokenReserve, ethReserve);

            TokenInterface(oddTokens[i]).transfer(address(tokenPair), tokenBalance);

            tokenPair.swap(uint(0), wethOut, address(this), new bytes(0));
        }

        uint256 wethBalance = weth.balanceOf(address(this));

        IUniswapV2Pair cvpPair = uniswapPairFor(address(cvp));

        (uint256 cvpReserve, uint256 ethReserve,) = cvpPair.getReserves();
        uint256 cvpOut = UniswapV2Library.getAmountOut(wethBalance, ethReserve, cvpReserve);

        weth.transfer(address(cvpPair), wethBalance);

        cvpPair.swap(cvpOut, uint(0), address(this), new bytes(0));

        cvp.transfer(feePayout, cvpOut);

        emit PayoutCVP(feePayout, wethBalance, cvpOut);
    }

    function setFees(
        uint256[] calldata _feeLevels,
        uint256[] calldata _feeAmounts,
        address _feePayout,
        address _feeManager
    )
        external
        onlyFeeManagerOrOwner
    {
        feeLevels = _feeLevels;
        feeAmounts = _feeAmounts;
        feePayout = _feePayout;
        feeManager = _feeManager;

        emit SetFees(msg.sender, _feeLevels, _feeAmounts, _feePayout, _feeManager);
    }

    function setTokensSettings(
        address[] memory _tokens,
        address[] memory _pairs,
        bool[] memory _reapprove
    ) external onlyOwner {
        uint256 len = _tokens.length;
        require(len == _pairs.length && len == _reapprove.length, "Lengths are not equal");
        for(uint i = 0; i < _tokens.length; i++) {
            uniswapEthPairByTokenAddress[_tokens[i]] = _pairs[i];
            reApproveTokens[_tokens[i]] = _reapprove[i];
            emit SetTokenSetting(_tokens[i], _reapprove[i], _pairs[i]);
        }
    }

    function setDefaultSlippage(uint256 _defaultSlippage) external onlyOwner {
        defaultSlippage = _defaultSlippage;
        emit SetDefaultSlippage(_defaultSlippage);
    }

    function calcSwapEthToPiptInputs(uint256 _ethValue, address[] memory _tokens, uint256 _slippage) public view returns(
        uint256[] memory tokensInPipt,
        uint256[] memory ethInUniswap,
        uint256 poolOut
    ) {
        _ethValue = _ethValue.sub(_ethValue.mul(_slippage).div(1 ether));


        CalculationStruct[] memory calculations = new CalculationStruct[](_tokens.length);

        uint256 totalEthRequired = 0;
        {
            uint256 piptTotalSupply = pipt.totalSupply();



            uint256 poolRatio = piptTotalSupply.mul(1 ether).div(pipt.getBalance(_tokens[0])).mul(1 ether).div(piptTotalSupply);

            for (uint i = 0; i < _tokens.length; i++) {

                calculations[i].tokenAmount = poolRatio.mul(pipt.getBalance(_tokens[i])).div(1 ether);

                (calculations[i].tokenReserve, calculations[i].ethReserve,) = uniswapPairFor(_tokens[i]).getReserves();
                calculations[i].ethAmount = UniswapV2Library.getAmountIn(
                    calculations[i].tokenAmount,
                    calculations[i].ethReserve,
                    calculations[i].tokenReserve
                );
                totalEthRequired = totalEthRequired.add(calculations[i].ethAmount);
            }
        }


        tokensInPipt = new uint256[](_tokens.length);
        ethInUniswap = new uint256[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            ethInUniswap[i] = _ethValue.mul(calculations[i].ethAmount.mul(1 ether).div(totalEthRequired)).div(1 ether);
            tokensInPipt[i] = calculations[i].tokenAmount.mul(_ethValue.mul(1 ether).div(totalEthRequired)).div(1 ether);
        }

        poolOut = pipt.totalSupply().mul(tokensInPipt[0]).div(pipt.getBalance(_tokens[0]));
    }

    function calcSwapPiptToEthInputs(uint256 _poolAmountIn, address[] memory _tokens) public view returns(
        uint256[] memory tokensOutPipt,
        uint256[] memory ethOutUniswap,
        uint256 totalEthOut,
        uint256 poolAmountFee
    ) {
        tokensOutPipt = new uint256[](_tokens.length);
        ethOutUniswap = new uint256[](_tokens.length);

        (, , uint communityExitFee,) = pipt.getCommunityFee();

        uint poolAmountInAfterFee;
        (
            poolAmountInAfterFee,
            poolAmountFee
        ) = pipt.calcAmountWithCommunityFee(_poolAmountIn, communityExitFee, address(this));

        uint256 poolRatio = poolAmountInAfterFee.mul(1 ether).div(pipt.totalSupply());

        totalEthOut = 0;
        for (uint i = 0; i < _tokens.length; i++) {
            tokensOutPipt[i] = poolRatio.mul(pipt.getBalance(_tokens[i])).div(1 ether);

            (uint256 tokenReserve, uint256 ethReserve,) = uniswapPairFor(_tokens[i]).getReserves();
            ethOutUniswap[i] = UniswapV2Library.getAmountOut(tokensOutPipt[i], tokenReserve, ethReserve);
            totalEthOut = totalEthOut.add(ethOutUniswap[i]);
        }
    }

    function calcEthFee(uint256 ethValue) public view returns(uint256 ethFee, uint256 ethAfterFee) {
        ethFee = 0;
        uint len = feeLevels.length;
        for(uint i = 0; i < len; i++) {
            if(ethValue >= feeLevels[i]) {
                ethFee = ethValue.mul(feeAmounts[i]).div(1 ether);
                break;
            }
        }
        ethAfterFee = ethValue.sub(ethFee);
    }

    function getFeeLevels() public view returns(uint256[] memory) {
        return feeLevels;
    }

    function getFeeAmounts() public view returns(uint256[] memory) {
        return feeAmounts;
    }

    function uniswapPairFor(address token) internal view returns(IUniswapV2Pair) {
        return IUniswapV2Pair(uniswapEthPairByTokenAddress[token]);
    }
}
