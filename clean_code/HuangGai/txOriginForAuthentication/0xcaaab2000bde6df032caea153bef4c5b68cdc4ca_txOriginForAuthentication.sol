



pragma solidity 0.5.12;

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "ds-math-div-overflow");
        z = x / y;
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

contract ERC20SafeTransfer {
    function doTransferOut(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        IERC20 token = IERC20(_token);
        bool result;

        token.transfer(_to, _amount);

        assembly {
            switch returndatasize()
                case 0 {
                    result := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        return result;
    }

    function doTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        IERC20 token = IERC20(_token);
        bool result;

        token.transferFrom(_from, _to, _amount);

        assembly {
            switch returndatasize()
                case 0 {
                    result := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        return result;
    }

    function doApprove(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        IERC20 token = IERC20(_token);
        bool result;

        token.approve(_to, _amount);

        assembly {
            switch returndatasize()
                case 0 {
                    result := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        return result;
    }
}

interface DFStore {
    function getFeeRate(uint ct) external view returns (uint);
    function getMinBurnAmount() external view returns (uint);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface DFProtocolView {
    function getPrice(uint _tokenIdx) external view returns (uint);
    function getFeeRate(uint _processIdx) external view returns (uint);
}

interface DFProtocol{
    function deposit(address _tokenID, uint _feeTokenIdx, uint _tokenAmount) external returns (uint);
    function destroy(uint _feeTokenIdx, uint _usdxAmount) external;
}

interface Curve {
    function exchange_underlying(int128 inputIndex, int128 outputIndex, uint256 inputAmount, uint256 minOutput) external;
}

interface IChi {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    function owner() external view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(_owner == tx.origin, "Ownable: caller is not the owner");

        _;
    }





    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



contract swapUSDx is ERC20SafeTransfer, Ownable {
    using SafeMath for uint256;
    uint256 private BASE = 10 ** 18;

    event SwapUSDx(address targetToken, uint256 inputAmount, uint256 outputAmount);

    constructor () public {
        _owner = msg.sender;
    }

    IChi public chi = IChi(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    address internal USDx = 0xeb269732ab75A6fD61Ea60b06fE994cD32a83549;
    address internal DF = 0x431ad2ff6a9C365805eBaD47Ee021148d6f7DBe0;

    address internal DFEngineContract = 0x3ea496977A356024bE096c1068a57Bd0B92c7d7c;
    DFProtocol internal DFProtocolContract = DFProtocol(0x5843F1Ccc5baA448528eb0e8Bc567Cda7eD1A1E8);
    DFProtocolView internal DFProtocolViewContract = DFProtocolView(0x097Dd22173f0e382daE42baAEb9bDBC9fdf3396F);
    DFStore internal DFStoreContract = DFStore(0xD30d06b276867CfA2266542791242fF37C91BA8d);

    address internal yPool = 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
    address internal paxPool = 0x06364f10B501e868329afBc005b3492902d6C763;
    address internal sUSD = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;

    address internal uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address[] public underlyingTokens = [
        0x8E870D67F660D95d5be530380D0eC0bd388289E1,
        0x0000000000085d4780B73119b644AE5ecd22b376,
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    ];

    address internal USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 *  msg.data.length;
        chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }






    function getDFAmount(uint256 _amount) internal view returns (uint256) {

        uint256 _dfPrice =  DFProtocolViewContract.getPrice(uint256(0));

        uint256 _rate = DFProtocolViewContract.getFeeRate(uint256(1));
        uint256 _dfAmount = _amount.mul(_rate).mul(BASE).div(uint256(10000).mul(_dfPrice));
        return _dfAmount;
    }






    function getSpendingUSDxAmount(uint256 _amount) internal view returns (uint256) {
        address[] memory _path = new address[](2);
        _path[0] = USDx;
        _path[1] = DF;
        uint[] memory _returnAmounts = IUniswapV2Router(uniswapRouter).getAmountsIn(_amount, _path);
        return _returnAmounts[0];
    }




    function multiApprove() external onlyOwner discountCHI returns (bool) {

        require(doApprove(USDx, uniswapRouter, uint256(-1)), "multiApprove: approve uniswap failed!");


        require(doApprove(DF, DFEngineContract, uint256(-1)), "multiApprove: DF approves DFEngine failed!");

        require(doApprove(USDx, DFEngineContract, uint256(-1)), "multiApprove: USDx approves DFEngine failed!");

        require(doApprove(underlyingTokens[0], paxPool, uint256(-1)), "multiApprove: PAX approves paxpool failed!");
        require(doApprove(underlyingTokens[1], yPool, uint256(-1)), "multiApprove: TUSD approves ypool failed!");

        require(doApprove(underlyingTokens[2], sUSD, uint256(-1)), "multiApprove: USDC approves sUSD failed!");
    }





    function swapUSDxToDF(uint256 _inputAmount) internal {
        uint256 _dfAmount =  getDFAmount(_inputAmount);
        uint256 _expectedUSDxAmount = getSpendingUSDxAmount(_dfAmount);
        uint256 _usdxAmount =  _expectedUSDxAmount % DFStoreContract.getMinBurnAmount() > 0
                              ? (_expectedUSDxAmount / DFStoreContract.getMinBurnAmount() + 1) * DFStoreContract.getMinBurnAmount()
                              : _expectedUSDxAmount ;

        address[] memory _path = new address[](2);
        _path[0] = USDx;
        _path[1] = DF;


        IUniswapV2Router(uniswapRouter).swapExactTokensForTokens(
            _usdxAmount,
            _dfAmount,
            _path,
            address(this),
            block.timestamp + 3600
        );
    }







    function getAmountOut(address _targetToken, uint256 _inputAmount, uint256 _minReturn) external returns (uint256) {

        require(
            doTransferFrom(
                USDx,
                msg.sender,
                address(this),
                _inputAmount
            ),
            "swap: USDx transferFrom failed!"
        );

        swapUSDxToDF(_inputAmount);


        DFProtocolContract.destroy(0, IERC20(USDx).balanceOf(address(this)));

        if (_targetToken == underlyingTokens[2]){

            uint256 _totalAmount = IERC20(underlyingTokens[1]).balanceOf(address(this));
            Curve(yPool).exchange_underlying(int128(3), int128(1), _totalAmount,uint256(0));

            _totalAmount = IERC20(underlyingTokens[0]).balanceOf(address(this));
            Curve(paxPool).exchange_underlying(int128(3), int128(1), _totalAmount,uint256(0));
        } else if (_targetToken == USDT) {

            uint256 _totalAmount = IERC20(underlyingTokens[2]).balanceOf(address(this));
            Curve(sUSD).exchange_underlying(int128(1), int128(2), _totalAmount,uint256(0));

            _totalAmount = IERC20(underlyingTokens[1]).balanceOf(address(this));
            Curve(yPool).exchange_underlying(int128(3), int128(2), _totalAmount,uint256(0));

            _totalAmount = IERC20(underlyingTokens[0]).balanceOf(address(this));
            Curve(paxPool).exchange_underlying(int128(3), int128(2), _totalAmount,uint256(0));
        }

        uint256 _finalBalance = IERC20(_targetToken).balanceOf(address(this));

        require(doTransferOut(_targetToken, msg.sender, _finalBalance), "swap: Transfer targetToken out failed!");
        require(doTransferOut(DF, msg.sender, IERC20(DF).balanceOf(address(this))), "swap: Transfer DF out failed!");

        emit SwapUSDx(_targetToken, _inputAmount, _finalBalance);
        return _finalBalance;
    }







    function swapUSDxTo(address _targetToken, uint256 _inputAmount, uint256 _minReturn) public discountCHI returns (uint256) {

        require(
            doTransferFrom(
                USDx,
                msg.sender,
                address(this),
                _inputAmount
            ),
            "swap: USDx transferFrom failed!"
        );

        swapUSDxToDF(_inputAmount);


        DFProtocolContract.destroy(0, IERC20(USDx).balanceOf(address(this)));

        if (_targetToken == underlyingTokens[2]){

            uint256 _totalAmount = IERC20(underlyingTokens[1]).balanceOf(address(this));
            Curve(yPool).exchange_underlying(int128(3), int128(1), _totalAmount, uint256(0));

            _totalAmount = IERC20(underlyingTokens[0]).balanceOf(address(this));
            Curve(paxPool).exchange_underlying(int128(3), int128(1), _totalAmount, uint256(0));
        } else if (_targetToken == USDT) {

            uint256 _totalAmount = IERC20(underlyingTokens[2]).balanceOf(address(this));
            Curve(sUSD).exchange_underlying(int128(1), int128(2), _totalAmount, uint256(0));

            _totalAmount = IERC20(underlyingTokens[1]).balanceOf(address(this));
            Curve(yPool).exchange_underlying(int128(3), int128(2), _totalAmount, uint256(0));

            _totalAmount = IERC20(underlyingTokens[0]).balanceOf(address(this));
            Curve(paxPool).exchange_underlying(int128(3), int128(2), _totalAmount, uint256(0));
        }

        uint256 _finalBalance = IERC20(_targetToken).balanceOf(address(this));
        require(_finalBalance >= _minReturn, "swap: Too large slippage to succeed!");

        require(doTransferOut(_targetToken, msg.sender, _finalBalance), "swap: Transfer targetToken out failed!");
        require(doTransferOut(DF, msg.sender, IERC20(DF).balanceOf(address(this))), "swap: Transfer DF out failed!");

        emit SwapUSDx(_targetToken, _inputAmount, _finalBalance);
        return _finalBalance;
    }




    function transferOut(address _token, address _to, uint256 _amount) external onlyOwner {
        require(
            doTransferOut(
                _token,
                _to,
                _amount
            ),
            "transferOut: Transfer token out failed!"
        );
    }

}
