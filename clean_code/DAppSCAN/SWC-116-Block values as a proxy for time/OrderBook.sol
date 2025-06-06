
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/security/Pausable.sol";
import "./UniswapHandler.sol";

contract OrderBook is UniswapHandler, Pausable {
    enum Status {
        None,
        Open,
        Filled,
        Canceled
    }
    struct Order {
        bytes32 id;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        address recipient;
        address creator;
        uint256 createdAt;
        uint256 expiration;
        Status status;
    }

    mapping(bytes32 => Order) public orders;
    mapping(address => uint256) private _nonces;


    mapping(address => mapping(address => uint256)) internal _lockedBalance;

    bytes32[] public openOrders;

    event OrderPlaced(
        bytes32 indexed orderId,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address indexed recipient,
        address indexed creator,
        uint256 expiration,
        uint256 timestamp
    );

    event OrderCanceled(
        bytes32 indexed orderId,
        address indexed creator,
        uint256 timestamp
    );












    function placeOrder(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _recipient,
        uint256 _expiration
    ) external whenNotPaused {
        require(_tokenIn != address(0), "Invalid input token address");
        require(_tokenOut != address(0), "Invalid output token address");
        require(_amountIn > 0, "Invalid input amount");
        require(_amountOutMin > 0, "Invalid output amount");
        require(_recipient != address(0), "Invalid recipient address");
        require(_expiration > block.timestamp, "Invalid expiration timestamp");

        uint256 balance = IERC20(_tokenIn).balanceOf(msg.sender);
        require(balance >= _amountIn, "Insufficient balance");

        uint256 lockedBalance = _lockedBalance[msg.sender][_tokenIn];
        uint256 availableBalance = balance > lockedBalance
            ? balance - lockedBalance
            : 0;
        require(availableBalance >= _amountIn, "Unavailable balance");

        uint256 allowance = IERC20(_tokenIn).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= _amountIn, "Insufficient allowance");

        bytes32 id = keccak256(
            abi.encodePacked(address(this), msg.sender, _nonces[msg.sender]++)
        );

        Order storage order = orders[id];
        order.id = id;
        order.tokenIn = _tokenIn;
        order.tokenOut = _tokenOut;
        order.amountIn = _amountIn;
        order.amountOutMin = _amountOutMin;
        order.recipient = _recipient;
        order.creator = msg.sender;
        order.createdAt = block.timestamp;
        order.expiration = _expiration;

        _lockedBalance[order.creator][order.tokenIn] += order.amountIn;

        _addOpenOrder(order);

        emit OrderPlaced(
            id,
            _tokenIn,
            _tokenOut,
            _amountIn,
            _amountOutMin,
            _recipient,
            msg.sender,
            _expiration,
            block.timestamp
        );
    }






    function cancelOrder(bytes32 _orderId) external {
        Order storage order = orders[_orderId];
        require(msg.sender == order.creator, "Only order creator");
        _cancelOrder(order);
    }





    function cancelExpiredOrders(bytes32[] memory _orderIds) external {
        for (uint256 i = 0; i < _orderIds.length; i++) {
            bytes32 orderId = _orderIds[i];
            Order storage order = orders[orderId];

            if (order.expiration <= block.timestamp) {
                _cancelOrder(order);
            }
        }
    }





    function _cancelOrder(Order storage _order) private {
        require(_order.status == Status.Open, "Cannot cancel unopen order");

        _order.status = Status.Canceled;
        _lockedBalance[_order.creator][_order.tokenIn] -= _order.amountIn;
        _removeOpenOrder(_order.id);

        emit OrderCanceled(_order.id, _order.creator, block.timestamp);
    }





    function _removeOpenOrder(bytes32 _orderId) internal {
        uint256 length = openOrders.length;
        for (uint256 i = 0; i < length; i++) {
            if (openOrders[i] == _orderId) {
                openOrders[i] = openOrders[length - 1];
                openOrders.pop();
                break;
            }
        }
    }





    function _addOpenOrder(Order storage _order) private {
        _order.status = Status.Open;
        openOrders.push(_order.id);
    }







    function getAvailableBalance(address _account, address _token)
        external
        view
        returns (uint256)
    {
        uint256 balance = IERC20(_token).balanceOf(_account);
        uint256 lockedBalance = _lockedBalance[_account][_token];
        return balance > lockedBalance ? balance - lockedBalance : 0;
    }








    function getLockedBalance(address _account, address _token)
        external
        view
        returns (uint256)
    {
        return _lockedBalance[_account][_token];
    }

    function getNonce(address _account) external view returns (uint256) {
        return _nonces[_account];
    }

    function getOrder(bytes32 _orderId)
        public
        view
        returns (
            bytes32 id,
            address tokenIn,
            address tokenOut,
            uint256 amountIn,
            uint256 amountOutMin,
            address recipient,
            address creator,
            uint256 createdAt,
            uint256 expiration,
            uint8 status
        )
    {
        Order storage order = orders[_orderId];
        id = order.id;
        tokenIn = order.tokenIn;
        tokenOut = order.tokenOut;
        amountIn = order.amountIn;
        amountOutMin = order.amountOutMin;
        recipient = order.recipient;
        createdAt = order.createdAt;
        creator = order.creator;
        expiration = order.expiration;
        status = uint8(order.status);
    }

    function getOpenOrders() external view returns (bytes32[] memory) {
        return openOrders;
    }
}
