
pragma solidity ^0.6.6;

import "./libraries/Math.sol";
import "./libraries/SafeMath256.sol";
import "./libraries/DecFloat32.sol";
import "./interfaces/IOneSwapFactory.sol";
import "./interfaces/IOneSwapPair.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";

abstract contract OneSwapERC20 is IERC20 {
    using SafeMath256 for uint;

    string private constant _NAME = "OneSwap-Liquidity-Share";
    uint8 private constant _DECIMALS = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    function symbol() virtual external view override returns (string memory);

    function name() external view override returns (string memory) {
        return _NAME;
    }

    function decimals() external view override returns (uint8) {
        return _DECIMALS;
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != uint(- 1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}



struct Order {
    address sender;
    uint32 price;
    uint64 amount;
    uint32 nextID;
}


struct Context {

    bool isLastSwap;

    bool isLimitOrder;

    uint32 newOrderID;

    uint remainAmount;

    uint32 firstID;

    uint32 firstBuyID;

    uint32 firstSellID;

    uint amountIntoPool;

    uint dealMoneyInBook;
    uint dealStockInBook;

    uint reserveMoney;
    uint reserveStock;
    uint bookedMoney;
    uint bookedStock;

    bool reserveChanged;

    bool hasDealtInOrderBook;

    Order order;
}


abstract contract OneSwapPool is OneSwapERC20, IOneSwapPool {
    using SafeMath256 for uint;

    uint private constant _MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 internal constant _SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));


    address internal immutable _immuWETH;
    address internal immutable _immuFactory;
    address internal immutable _immuMoneyToken;
    address internal immutable _immuStockToken;
    bool internal immutable _immuIsOnlySwap;


    uint internal _reserveStockAndMoneyAndFirstSellID;

    uint internal _bookedStockAndMoneyAndFirstBuyID;

    uint private _kLast;

    uint32 private constant _OS = 2;
    uint32 private constant _LS = 3;

    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1, "OneSwap: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    function internalStatus() external view returns(uint[3] memory res) {
        res[0] = _reserveStockAndMoneyAndFirstSellID;
        res[1] = _bookedStockAndMoneyAndFirstBuyID;
        res[2] = _kLast;
    }

    function stock() external view override returns (address) {return _immuStockToken;}

    function money() external view override returns (address) {return _immuMoneyToken;}


    function getReserves() public override view returns (uint112 reserveStock, uint112 reserveMoney, uint32 firstSellID) {
        uint temp = _reserveStockAndMoneyAndFirstSellID;
        reserveStock = uint112(temp);
        reserveMoney = uint112(temp>>112);
        firstSellID = uint32(temp>>224);
    }
    function _setReserves(uint stockAmount, uint moneyAmount, uint32 firstSellID) internal {
        require(stockAmount < uint(1<<112) && moneyAmount < uint(1<<112), "OneSwap: OVERFLOW");
        uint temp = (moneyAmount<<112)|stockAmount;
        emit Sync(temp);
        temp = (uint(firstSellID)<<224)| temp;
        _reserveStockAndMoneyAndFirstSellID = temp;
    }
    function getBooked() public override view returns (uint112 bookedStock, uint112 bookedMoney, uint32 firstBuyID) {
        uint temp = _bookedStockAndMoneyAndFirstBuyID;
        bookedStock = uint112(temp);
        bookedMoney = uint112(temp>>112);
        firstBuyID = uint32(temp>>224);
    }
    function _setBooked(uint stockAmount, uint moneyAmount, uint32 firstBuyID) internal {
        require(stockAmount < uint(1<<112) && moneyAmount < uint(1<<112), "OneSwap: OVERFLOW");
        _bookedStockAndMoneyAndFirstBuyID = (uint(firstBuyID)<<224)|(moneyAmount<<112)|stockAmount;
    }


    function _safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(_SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "OneSwap: TRANSFER_FAILED");
    }



    function _transferToken(address token, address to, uint amount, bool isLastPath) internal {
        if (token == _immuWETH && isLastPath) {
            IWETH(_immuWETH).withdraw(amount);
            _safeTransferETH(to, amount);
        } else {
            _safeTransfer(token, to, amount);
        }
    }
    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, "OneSwap: ETH_TRANSFER_FAILED");
    }


    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IOneSwapFactory(_immuFactory).feeTo();
        feeOn = feeTo != address(0);
        uint kLast = _kLast;

        if (feeOn) {
            if (kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(_OS);
                    uint denominator = rootK.mul(_LS).add(rootKLast.mul(_OS));
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (kLast != 0) {
            _kLast = 0;
        }
    }


    function mint(address to) external override lock returns (uint liquidity) {
        (uint112 reserveStock, uint112 reserveMoney, uint32 firstSellID) = getReserves();
        (uint112 bookedStock, uint112 bookedMoney, ) = getBooked();
        uint stockBalance = IERC20(_immuStockToken).balanceOf(address(this));
        uint moneyBalance = IERC20(_immuMoneyToken).balanceOf(address(this));
        require(stockBalance >= uint(bookedStock) + uint(reserveStock) &&
                moneyBalance >= uint(bookedMoney) + uint(reserveMoney), "OneSwap: INVALID_BALANCE");
        stockBalance -= uint(bookedStock);
        moneyBalance -= uint(bookedMoney);
        uint stockAmount = stockBalance - uint(reserveStock);
        uint moneyAmount = moneyBalance - uint(reserveMoney);

        bool feeOn = _mintFee(reserveStock, reserveMoney);
        uint _totalSupply = totalSupply;


        if (_totalSupply == 0) {
            liquidity = Math.sqrt(stockAmount.mul(moneyAmount)).sub(_MINIMUM_LIQUIDITY);
            _mint(address(0), _MINIMUM_LIQUIDITY);

        } else {
            liquidity = Math.min(stockAmount.mul(_totalSupply) / uint(reserveStock),
                                 moneyAmount.mul(_totalSupply) / uint(reserveMoney));
        }
        require(liquidity > 0, "OneSwap: INSUFFICIENT_MINTED");
        _mint(to, liquidity);

        _setReserves(stockBalance, moneyBalance, firstSellID);
        if (feeOn) _kLast = stockBalance.mul(moneyBalance);
        emit Mint(msg.sender, (moneyAmount<<112)|stockAmount, to);
    }


    function burn(address to) external override lock returns (uint stockAmount, uint moneyAmount) {
        (uint112 reserveStock, uint112 reserveMoney, uint32 firstSellID) = getReserves();
        (uint bookedStock, uint bookedMoney, ) = getBooked();
        uint stockBalance = IERC20(_immuStockToken).balanceOf(address(this)).sub(bookedStock);
        uint moneyBalance = IERC20(_immuMoneyToken).balanceOf(address(this)).sub(bookedMoney);
        require(stockBalance >= uint(reserveStock) && moneyBalance >= uint(reserveMoney), "OneSwap: INVALID_BALANCE");
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(reserveStock, reserveMoney);
        uint _totalSupply = totalSupply;
        stockAmount = liquidity.mul(stockBalance) / _totalSupply;
        moneyAmount = liquidity.mul(moneyBalance) / _totalSupply;
        require(stockAmount > 0 && moneyAmount > 0, "OneSwap: INSUFFICIENT_BURNED");


        balanceOf[address(this)] = 0;
        totalSupply = totalSupply.sub(liquidity);
        emit Transfer(address(this), address(0), liquidity);

        _safeTransfer(_immuStockToken, to, stockAmount);
        _safeTransfer(_immuMoneyToken, to, moneyAmount);
        stockBalance = stockBalance - stockAmount;
        moneyBalance = moneyBalance - moneyAmount;

        _setReserves(stockBalance, moneyBalance, firstSellID);
        if (feeOn) _kLast = stockBalance.mul(moneyBalance);
        emit Burn(msg.sender, (moneyAmount<<112)|stockAmount, to);
    }


    function skim(address to) external override lock {
        address _stock = _immuStockToken;
        address _money = _immuMoneyToken;
        (uint112 reserveStock, uint112 reserveMoney, ) = getReserves();
        (uint bookedStock, uint bookedMoney, ) = getBooked();
        uint balanceStock = IERC20(_stock).balanceOf(address(this));
        uint balanceMoney = IERC20(_money).balanceOf(address(this));
        require(balanceStock >= uint(bookedStock) + uint(reserveStock) &&
                balanceMoney >= uint(bookedMoney) + uint(reserveMoney), "OneSwap: INVALID_BALANCE");
        _safeTransfer(_stock, to, balanceStock-reserveStock-bookedStock);
        _safeTransfer(_money, to, balanceMoney-reserveMoney-bookedMoney);
    }


    function sync() external override lock {
        (, , uint32 firstSellID) = getReserves();
        (uint bookedStock, uint bookedMoney, ) = getBooked();
        uint balanceStock = IERC20(_immuStockToken).balanceOf(address(this));
        uint balanceMoney = IERC20(_immuMoneyToken).balanceOf(address(this));
        require(balanceStock >= bookedStock && balanceMoney >= bookedMoney, "OneSwap: INVALID_BALANCE");
        _setReserves(balanceStock-bookedStock, balanceMoney-bookedMoney, firstSellID);
    }

    constructor(address weth, address stockToken, address moneyToken, bool isOnlySwap) public {
        _immuFactory = msg.sender;
        _immuWETH = weth;
        _immuStockToken = stockToken;
        _immuMoneyToken = moneyToken;
        _immuIsOnlySwap = isOnlySwap;
    }

}

contract OneSwapPair is OneSwapPool, IOneSwapPair {

    uint[1<<22] private _sellOrders;
    uint[1<<22] private _buyOrders;

    uint32 private constant _MAX_ID = (1<<22)-1;
    uint64 internal immutable _immuStockUnit;
    uint64 internal immutable _immuPriceMul;
    uint64 internal immutable _immuPriceDiv;

    constructor(address weth, address stockToken, address moneyToken, bool isOnlySwap, uint64 stockUnit, uint64 priceMul, uint64 priceDiv) public
    OneSwapPool(weth, stockToken, moneyToken, isOnlySwap) {
        _immuStockUnit = stockUnit;
        _immuPriceMul = priceMul;
        _immuPriceDiv = priceDiv;
    }

    function _expandPrice(uint32 price32) private view returns (RatPrice memory price) {
        price = DecFloat32.expandPrice(price32);
        price.numerator *= _immuPriceMul;
        price.denominator *= _immuPriceDiv;
    }

    function symbol() external view override returns (string memory) {
        string memory s = IERC20(_immuStockToken).symbol();
        string memory m = IERC20(_immuMoneyToken).symbol();
        return string(abi.encodePacked(s, "/", m, "-Share"));
    }



    function _emitNewLimitOrder(












































































































































































































































































































































































































































































































































































































































































































































































