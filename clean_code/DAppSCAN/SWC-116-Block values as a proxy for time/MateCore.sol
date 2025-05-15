
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./OrderBook.sol";
import "./FeeManager.sol";

contract MateCore is OrderBook, FeeManager, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable mate;

    constructor(
        address _router,
        address _mate,
        address _feeTo
    ) {
        router = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(router.factory());
        mate = _mate;
        feeTo = _feeTo;
    }

    event OrderExecuted(
        bytes32 indexed orderId,
        address indexed creator,
        address indexed executor,
        uint256 amountOut,
        uint256 timestamp
    );






    function canExecuteOrder(bytes32 _orderId, address[] memory _pathToTokenOut)
        external
        view
        returns (bool success, string memory reason)
    {
        return _canExecuteOrder(_orderId, _pathToTokenOut, new address[](0));
    }







    function canExecuteOrder(
        bytes32 _orderId,
        address[] memory _pathToTokenOut,
        address[] memory _pathToMate
    ) external view returns (bool success, string memory reason) {
        return _canExecuteOrder(_orderId, _pathToTokenOut, _pathToMate);
    }








    function _canExecuteOrder(
        bytes32 _orderId,
        address[] memory _pathToTokenOut,
        address[] memory _pathToMate
    ) internal view returns (bool success, string memory reason) {
        if (paused()) {
            return (false, "Paused");
        }

        Order storage order = orders[_orderId];

        uint256 balance = IERC20(order.tokenIn).balanceOf(order.creator);
        if (balance < order.amountIn) return (false, "Insufficient balance");

        uint256 allowance = IERC20(order.tokenIn).allowance(
            order.creator,
            address(this)
        );
        if (allowance < order.amountIn)
            return (false, "Insufficient allowance");

        if (block.timestamp > order.expiration) return (false, "Expired order");

        if (order.status != Status.Open) return (false, "Invalid status");

        if (
            _pathToTokenOut.length < 1 ||
            _pathToTokenOut[0] != order.tokenIn ||
            _pathToTokenOut[_pathToTokenOut.length - 1] != order.tokenOut
        ) return (false, "Invalid path to output token");

        if (order.tokenIn != mate && _pathToMate.length > 1) {
            if (
                _pathToMate[0] != order.tokenIn ||
                _pathToMate[_pathToMate.length - 1] != mate
            ) return (false, "Invalid path to Mate token");
        }

        (uint256 fee, uint256 executorFee) = calculateFees(order.amountIn);

        uint256 amountInWithFees = order.amountIn - fee - executorFee;

        uint256 amountOutMin = getAmountOutMin(
            amountInWithFees,
            _pathToTokenOut
        );

        if (amountOutMin < order.amountOutMin)
            return (false, "Insufficient output amount");

        return (true, "");
    }






    function executeOrder(bytes32 _orderId, address[] memory _pathToTokenOut)
        external
    {
        _executeOrder(_orderId, _pathToTokenOut, new address[](0));
    }







    function executeOrder(
        bytes32 _orderId,
        address[] memory _pathToTokenOut,
        address[] memory _pathToMate
    ) external {
        _executeOrder(_orderId, _pathToTokenOut, _pathToMate);
    }








    function _executeOrder(
        bytes32 _orderId,
        address[] memory _pathToTokenOut,
        address[] memory _pathToMate
    ) internal nonReentrant whenNotPaused {
        Order storage order = orders[_orderId];

        uint256 balance = IERC20(order.tokenIn).balanceOf(order.creator);
        require(balance >= order.amountIn, "Insufficient balance");

        uint256 allowance = IERC20(order.tokenIn).allowance(
            order.creator,
            address(this)
        );
        require(allowance >= order.amountIn, "Insufficient allowance");

        require(block.timestamp <= order.expiration, "Expired order");

        require(order.status == Status.Open, "Invalid status");

        require(
            _pathToTokenOut.length > 1 &&
                _pathToTokenOut[0] == order.tokenIn &&
                _pathToTokenOut[_pathToTokenOut.length - 1] == order.tokenOut,
            "Invalid path to output token"
        );

        if (order.tokenIn != mate && _pathToMate.length > 1) {
            require(
                _pathToMate[0] == order.tokenIn &&
                    _pathToMate[_pathToMate.length - 1] == mate,
                "Invalid path to Mate token"
            );
        }

        (uint256 fee, uint256 executorFee) = calculateFees(order.amountIn);

        uint256 amountInWithFees = order.amountIn - fee - executorFee;

        uint256 amountOutMin = getAmountOutMin(
            amountInWithFees,
            _pathToTokenOut
        );

        require(
            amountOutMin >= order.amountOutMin,
            "Insufficient output amount"
        );

        order.status = Status.Filled;

        _lockedBalance[order.creator][order.tokenIn] -= order.amountIn;

        IERC20(order.tokenIn).safeTransferFrom(
            order.creator,
            address(this),
            order.amountIn
        );

        uint256 amountOut = _swap(
            _pathToTokenOut,
            amountInWithFees,
            order.amountOutMin,
            order.recipient
        );

        _removeOpenOrder(order.id);

        _transferFees(fee, executorFee, order.tokenIn, _pathToMate);

        emit OrderExecuted(
            _orderId,
            order.creator,
            msg.sender,
            amountOut,
            block.timestamp
        );
    }








    function _transferFees(
        uint256 _fee,
        uint256 _executorFee,
        address _tokenIn,
        address[] memory _pathToMate
    ) internal {
        if (_fee > 0) {
            IERC20(_tokenIn).safeTransfer(feeTo, _fee);
        }

        if (_executorFee > 0) {
            if (_tokenIn == mate || _pathToMate.length <= 1) {
                IERC20(_tokenIn).safeTransfer(msg.sender, _executorFee);
            } else {
                _swap(
                    _pathToMate,
                    _executorFee,
                    getAmountOutMin(_executorFee, _pathToMate),
                    msg.sender
                );
            }
        }
    }





    function pause() external onlyOwner {
        _pause();
    }





    function unpause() external onlyOwner {
        _unpause();
    }
}
