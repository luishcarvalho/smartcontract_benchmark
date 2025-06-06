






pragma solidity 0.6.12;

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }


    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}



pragma solidity 0.6.12;

library SafeMath256 {










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



pragma solidity 0.6.12;
























struct RatPrice {
    uint numerator;
    uint denominator;
}

library DecFloat32 {
    uint32 public constant MANTISSA_MASK = (1<<27) - 1;
    uint32 public constant MAX_MANTISSA = 9999_9999;
    uint32 public constant MIN_MANTISSA = 1000_0000;
    uint32 public constant MIN_PRICE = MIN_MANTISSA;
    uint32 public constant MAX_PRICE = (31<<27)|MAX_MANTISSA;


    function powSmall(uint32 i) internal pure returns (uint) {
        uint x = 2695994666777834996822029817977685892750687677375768584125520488993233305610;
        return (x >> (32*i)) & ((1<<32)-1);
    }


    function powBig(uint32 i) internal pure returns (uint) {
        uint y = 3402823669209384634633746076162356521930955161600000001;
        return (y >> (64*i)) & ((1<<64)-1);
    }

































    function expandPrice(uint32 price32) internal pure returns (RatPrice memory) {
        uint s = price32&((1<<27)-1);
        uint32 a = price32 >> 27;
        RatPrice memory price;
        if(a >= 24) {
            uint32 b = a - 24;
            price.numerator = s * powSmall(b);
            price.denominator = 1;
        } else if(a == 23) {
            price.numerator = s;
            price.denominator = 1;
        } else {
            uint32 b = 22 - a;
            price.numerator = s;
            price.denominator = powSmall(b&0x7) * powBig(b>>3);
        }
        return price;
    }

    function getExpandPrice(uint price) internal pure returns(uint numerator, uint denominator) {
        uint32 m = uint32(price) & MANTISSA_MASK;
        require(MIN_MANTISSA <= m && m <= MAX_MANTISSA, "Invalid Price");
        RatPrice memory actualPrice = expandPrice(uint32(price));
        return (actualPrice.numerator, actualPrice.denominator);
    }

}



pragma solidity 0.6.12;

library ProxyData {
    uint public constant COUNT = 5;
    uint public constant INDEX_FACTORY = 0;
    uint public constant INDEX_MONEY_TOKEN = 1;
    uint public constant INDEX_STOCK_TOKEN = 2;
    uint public constant INDEX_ONES = 3;
    uint public constant INDEX_OTHER = 4;
    uint public constant OFFSET_PRICE_DIV = 0;
    uint public constant OFFSET_PRICE_MUL = 64;
    uint public constant OFFSET_STOCK_UNIT = 64+64;
    uint public constant OFFSET_IS_ONLY_SWAP = 64+64+64;

    function factory(uint[5] memory proxyData) internal pure returns (address) {
         return address(proxyData[INDEX_FACTORY]);
    }

    function money(uint[5] memory proxyData) internal pure returns (address) {
         return address(proxyData[INDEX_MONEY_TOKEN]);
    }

    function stock(uint[5] memory proxyData) internal pure returns (address) {
         return address(proxyData[INDEX_STOCK_TOKEN]);
    }

    function ones(uint[5] memory proxyData) internal pure returns (address) {
         return address(proxyData[INDEX_ONES]);
    }

    function priceMul(uint[5] memory proxyData) internal pure returns (uint64) {
        return uint64(proxyData[INDEX_OTHER]>>OFFSET_PRICE_MUL);
    }

    function priceDiv(uint[5] memory proxyData) internal pure returns (uint64) {
        return uint64(proxyData[INDEX_OTHER]>>OFFSET_PRICE_DIV);
    }

    function stockUnit(uint[5] memory proxyData) internal pure returns (uint64) {
        return uint64(proxyData[INDEX_OTHER]>>OFFSET_STOCK_UNIT);
    }

    function isOnlySwap(uint[5] memory proxyData) internal pure returns (bool) {
        return uint8(proxyData[INDEX_OTHER]>>OFFSET_IS_ONLY_SWAP) != 0;
    }

    function fill(uint[5] memory proxyData, uint expectedCallDataSize) internal pure {
        uint size;

        assembly {
            size := calldatasize()
        }
        require(size == expectedCallDataSize, "INVALID_CALLDATASIZE");

        assembly {
            let offset := sub(size, 160)
            calldatacopy(proxyData, offset, 160)
        }
    }
}



pragma solidity 0.6.12;

interface IOneSwapFactory {
    event PairCreated(address indexed pair, address stock, address money, bool isOnlySwap);

    function createPair(address stock, address money, bool isOnlySwap) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setFeeBPS(uint32 bps) external;
    function setPairLogic(address implLogic) external;

    function allPairsLength() external view returns (uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function feeBPS() external view returns (uint32);
    function pairLogic() external returns (address);
    function getTokensFromPair(address pair) external view returns (address stock, address money);
    function tokensToPair(address stock, address money, bool isOnlySwap) external view returns (address pair);
}



pragma solidity 0.6.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}



pragma solidity 0.6.12;


interface IOneSwapBlackList {
    event OwnerChanged(address);
    event AddedBlackLists(address[]);
    event RemovedBlackLists(address[]);

    function owner()external view returns (address);
    function newOwner()external view returns (address);
    function isBlackListed(address)external view returns (bool);

    function changeOwner(address ownerToSet) external;
    function updateOwner() external;
    function addBlackLists(address[] calldata  accounts)external;
    function removeBlackLists(address[] calldata  accounts)external;
}

interface IOneSwapToken is IERC20, IOneSwapBlackList{
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function multiTransfer(uint256[] calldata mixedAddrVal) external returns (bool);
}



pragma solidity 0.6.12;

interface IOneSwapERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IOneSwapPool {

    event Mint(address indexed sender, uint stockAndMoneyAmount, address indexed to);

    event Burn(address indexed sender, uint stockAndMoneyAmount, address indexed to);

    event Sync(uint reserveStockAndMoney);

    function internalStatus() external view returns(uint[3] memory res);
    function getReserves() external view returns (uint112 reserveStock, uint112 reserveMoney, uint32 firstSellID);
    function getBooked() external view returns (uint112 bookedStock, uint112 bookedMoney, uint32 firstBuyID);
    function stock() external returns (address);
    function money() external returns (address);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint stockAmount, uint moneyAmount);
    function skim(address to) external;
    function sync() external;
}

interface IOneSwapPair {
    event NewLimitOrder(uint data);
    event NewMarketOrder(uint data);
    event OrderChanged(uint data);
    event DealWithPool(uint data);
    event RemoveOrder(uint data);



    function getPrices() external returns (
        uint firstSellPriceNumerator,
        uint firstSellPriceDenominator,
        uint firstBuyPriceNumerator,
        uint firstBuyPriceDenominator,
        uint poolPriceNumerator,
        uint poolPriceDenominator);






    function getOrderList(bool isBuy, uint32 id, uint32 maxCount) external view returns (uint[] memory);




    function removeOrder(bool isBuy, uint32 id, uint72 positionID) external;

    function removeOrders(uint[] calldata rmList) external;






    function addLimitOrder(bool isBuy, address sender, uint64 amount, uint32 price32, uint32 id, uint72 prevKey) external payable;


    function addMarketOrder(address inputToken, address sender, uint112 inAmount) external payable returns (uint);


    function calcStockAndMoney(uint64 amount, uint32 price32) external pure returns (uint stockAmount, uint moneyAmount);
}



pragma solidity 0.6.12;









abstract contract OneSwapERC20 is IOneSwapERC20 {
    using SafeMath256 for uint;

    uint internal _unusedVar0;
    uint internal _unusedVar1;
    uint internal _unusedVar2;
    uint internal _unusedVar3;
    uint internal _unusedVar4;
    uint internal _unusedVar5;
    uint internal _unusedVar6;
    uint internal _unusedVar7;
    uint internal _unusedVar8;
    uint internal _unusedVar9;
    uint internal _unlocked = 1;

    modifier lock() {
        require(_unlocked == 1, "OneSwap: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    string private constant _NAME = "OneSwap-Share";
    uint8 private constant _DECIMALS = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    function symbol() virtual external override returns (string memory);

    function name() public view override returns (string memory) {
        return _NAME;
    }

    function decimals() public view override returns (uint8) {
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

    function approve(address spender, uint value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public override returns (bool) {
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

    uint64 stockUnit;
    uint64 priceMul;
    uint64 priceDiv;
    address stockToken;
    address moneyToken;
    address ones;
    address factory;
}


abstract contract OneSwapPool is OneSwapERC20, IOneSwapPool {
    using SafeMath256 for uint;

    uint private constant _MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 internal constant _SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));


    uint internal _reserveStockAndMoneyAndFirstSellID;

    uint internal _bookedStockAndMoneyAndFirstBuyID;

    uint private _kLast;

    uint32 private constant _OS = 2;
    uint32 private constant _LS = 3;

    function internalStatus() public override view returns(uint[3] memory res) {
        res[0] = _reserveStockAndMoneyAndFirstSellID;
        res[1] = _bookedStockAndMoneyAndFirstBuyID;
        res[2] = _kLast;
    }

    function stock() public override returns (address) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+0));
        return ProxyData.stock(proxyData);
    }

    function money() public override returns (address) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+0));
        return ProxyData.money(proxyData);
    }


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

    function _myBalance(address token) internal view returns (uint) {
        if(token==address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }


    function _safeTransfer(address token, address to, uint value, address ones) internal {
        if(value==0) {return;}
        if(token==address(0)) {


            to.call{value: value, gas: 9000}(new bytes(0));
            return;
        }

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(_SELECTOR, to, value));
        success = success && (data.length == 0 || abi.decode(data, (bool)));
        if(!success) {
            address onesOwner = IOneSwapToken(ones).owner();

            (success, data) = token.call(abi.encodeWithSelector(_SELECTOR, onesOwner, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "OneSwap: TRANSFER_FAILED");
        }
    }


    function _mintFee(uint112 _reserve0, uint112 _reserve1, uint[5] memory proxyData) private returns (bool feeOn) {
        address feeTo = IOneSwapFactory(ProxyData.factory(proxyData)).feeTo();
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


    function mint(address to) public override lock returns (uint liquidity) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+1));
        (uint112 reserveStock, uint112 reserveMoney, uint32 firstSellID) = getReserves();
        (uint112 bookedStock, uint112 bookedMoney, ) = getBooked();
        uint stockBalance = _myBalance(ProxyData.stock(proxyData));
        uint moneyBalance = _myBalance(ProxyData.money(proxyData));
        require(stockBalance >= uint(bookedStock) + uint(reserveStock) &&
                moneyBalance >= uint(bookedMoney) + uint(reserveMoney), "OneSwap: INVALID_BALANCE");
        stockBalance -= uint(bookedStock);
        moneyBalance -= uint(bookedMoney);
        uint stockAmount = stockBalance - uint(reserveStock);
        uint moneyAmount = moneyBalance - uint(reserveMoney);

        bool feeOn = _mintFee(reserveStock, reserveMoney, proxyData);
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


    function burn(address to) public override lock returns (uint stockAmount, uint moneyAmount) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+1));
        (uint112 reserveStock, uint112 reserveMoney, uint32 firstSellID) = getReserves();
        (uint bookedStock, uint bookedMoney, ) = getBooked();
        uint stockBalance = _myBalance(ProxyData.stock(proxyData)).sub(bookedStock);
        uint moneyBalance = _myBalance(ProxyData.money(proxyData)).sub(bookedMoney);
        require(stockBalance >= uint(reserveStock) && moneyBalance >= uint(reserveMoney), "OneSwap: INVALID_BALANCE");

        bool feeOn = _mintFee(reserveStock, reserveMoney, proxyData);
        {
            uint _totalSupply = totalSupply;
            uint liquidity = balanceOf[address(this)];
            stockAmount = liquidity.mul(stockBalance) / _totalSupply;
            moneyAmount = liquidity.mul(moneyBalance) / _totalSupply;
            require(stockAmount > 0 && moneyAmount > 0, "OneSwap: INSUFFICIENT_BURNED");


            balanceOf[address(this)] = 0;
            totalSupply = totalSupply.sub(liquidity);
            emit Transfer(address(this), address(0), liquidity);
        }

        address ones = ProxyData.ones(proxyData);
        _safeTransfer(ProxyData.stock(proxyData), to, stockAmount, ones);
        _safeTransfer(ProxyData.money(proxyData), to, moneyAmount, ones);

        stockBalance = stockBalance - stockAmount;
        moneyBalance = moneyBalance - moneyAmount;

        _setReserves(stockBalance, moneyBalance, firstSellID);
        if (feeOn) _kLast = stockBalance.mul(moneyBalance);
        emit Burn(msg.sender, (moneyAmount<<112)|stockAmount, to);
    }


    function skim(address to) public override lock {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+1));
        address stockToken = ProxyData.stock(proxyData);
        address moneyToken = ProxyData.money(proxyData);
        (uint112 reserveStock, uint112 reserveMoney, ) = getReserves();
        (uint bookedStock, uint bookedMoney, ) = getBooked();
        uint balanceStock = _myBalance(stockToken);
        uint balanceMoney = _myBalance(moneyToken);
        require(balanceStock >= uint(bookedStock) + uint(reserveStock) &&
                balanceMoney >= uint(bookedMoney) + uint(reserveMoney), "OneSwap: INVALID_BALANCE");
        address ones = ProxyData.ones(proxyData);
        _safeTransfer(stockToken, to, balanceStock-reserveStock-bookedStock, ones);
        _safeTransfer(moneyToken, to, balanceMoney-reserveMoney-bookedMoney, ones);
    }


    function sync() public override lock {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+0));
        (, , uint32 firstSellID) = getReserves();
        (uint bookedStock, uint bookedMoney, ) = getBooked();
        uint balanceStock = _myBalance(ProxyData.stock(proxyData));
        uint balanceMoney = _myBalance(ProxyData.money(proxyData));
        require(balanceStock >= bookedStock && balanceMoney >= bookedMoney, "OneSwap: INVALID_BALANCE");
        _setReserves(balanceStock-bookedStock, balanceMoney-bookedMoney, firstSellID);
    }

}

contract OneSwapPair is OneSwapPool, IOneSwapPair {

    uint[1<<22] private _sellOrders;
    uint[1<<22] private _buyOrders;

    uint32 private constant _MAX_ID = (1<<22)-1;

    function _expandPrice(uint32 price32, uint[5] memory proxyData) private pure returns (RatPrice memory price) {
        price = DecFloat32.expandPrice(price32);
        price.numerator *= ProxyData.priceMul(proxyData);
        price.denominator *= ProxyData.priceDiv(proxyData);
    }

    function _expandPrice(Context memory ctx, uint32 price32) private pure returns (RatPrice memory price) {
        price = DecFloat32.expandPrice(price32);
        price.numerator *= ctx.priceMul;
        price.denominator *= ctx.priceDiv;
    }

    function symbol() public override returns (string memory) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+0));
        string memory s = "ETH";
        address stock = ProxyData.stock(proxyData);
        if(stock != address(0)) {
            s = IERC20(stock).symbol();
        }
        string memory m = "ETH";
        address money = ProxyData.money(proxyData);
        if(money != address(0)) {
            m = IERC20(money).symbol();
        }
        return string(abi.encodePacked(s, "/", m));
    }



    function _emitNewLimitOrder(
        uint64 addressLow,
        uint64 totalStockAmount,
        uint64 remainedStockAmount,
        uint32 price,
        uint32 orderID,
        bool isBuy ) private {
        uint data = uint(addressLow);
        data = (data<<64) | uint(totalStockAmount);
        data = (data<<64) | uint(remainedStockAmount);
        data = (data<<32) | uint(price);
        data = (data<<32) | uint(orderID<<8);
        if(isBuy) {
            data = data | 1;
        }
        emit NewLimitOrder(data);
    }
    function _emitNewMarketOrder(
        uint136 addressLow,
        uint112 amount,
        bool isBuy ) private {
        uint data = uint(addressLow);
        data = (data<<112) | uint(amount);
        data = data<<8;
        if(isBuy) {
            data = data | 1;
        }
        emit NewMarketOrder(data);
    }
    function _emitOrderChanged(
        uint64 makerLastAmount,
        uint64 makerDealAmount,
        uint32 makerOrderID,
        bool isBuy ) private {
        uint data = uint(makerLastAmount);
        data = (data<<64) | uint(makerDealAmount);
        data = (data<<32) | uint(makerOrderID<<8);
        if(isBuy) {
            data = data | 1;
        }
        emit OrderChanged(data);
    }
    function _emitDealWithPool(
        uint112 inAmount,
        uint112 outAmount,
        bool isBuy) private {
        uint data = uint(inAmount);
        data = (data<<112) | uint(outAmount);
        data = data<<8;
        if(isBuy) {
            data = data | 1;
        }
        emit DealWithPool(data);
    }
    function _emitRemoveOrder(
        uint64 remainStockAmount,
        uint32 orderID,
        bool isBuy ) private {
        uint data = uint(remainStockAmount);
        data = (data<<32) | uint(orderID<<8);
        if(isBuy) {
            data = data | 1;
        }
        emit RemoveOrder(data);
    }


    function _order2uint(Order memory order) internal pure returns (uint) {
        uint n = uint(order.sender);
        n = (n<<32) | order.price;
        n = (n<<42) | order.amount;
        n = (n<<22) | order.nextID;
        return n;
    }


    function _uint2order(uint n) internal pure returns (Order memory) {
        Order memory order;
        order.nextID = uint32(n & ((1<<22)-1));
        n = n >> 22;
        order.amount = uint64(n & ((1<<42)-1));
        n = n >> 42;
        order.price = uint32(n & ((1<<32)-1));
        n = n >> 32;
        order.sender = address(n);
        return order;
    }


    function _hasOrder(bool isBuy, uint32 id) internal view returns (bool) {
        if(isBuy) {
            return _buyOrders[id] != 0;
        } else {
            return _sellOrders[id] != 0;
        }
    }


    function _getOrder(bool isBuy, uint32 id) internal view returns (Order memory order, bool findIt) {
        if(isBuy) {
            order = _uint2order(_buyOrders[id]);
            return (order, order.price != 0);
        } else {
            order = _uint2order(_sellOrders[id]);
            return (order, order.price != 0);
        }
    }


    function _setOrder(bool isBuy, uint32 id, Order memory order) internal {
        if(isBuy) {
            _buyOrders[id] = _order2uint(order);
        } else {
            _sellOrders[id] = _order2uint(order);
        }
    }


    function _deleteOrder(bool isBuy, uint32 id) internal {
        if(isBuy) {
            delete _buyOrders[id];
        } else {
            delete _sellOrders[id];
        }
    }

    function _getFirstOrderID(Context memory ctx, bool isBuy) internal pure returns (uint32) {
        if(isBuy) {
            return ctx.firstBuyID;
        }
        return ctx.firstSellID;
    }

    function _setFirstOrderID(Context memory ctx, bool isBuy, uint32 id) internal pure {
        if(isBuy) {
            ctx.firstBuyID = id;
        } else {
            ctx.firstSellID = id;
        }
    }

    function removeOrders(uint[] calldata rmList) external override lock {
        uint[5] memory proxyData;
        uint expectedCallDataSize = 4+32*(ProxyData.COUNT+2+rmList.length);
        ProxyData.fill(proxyData, expectedCallDataSize);
        for(uint i = 0; i < rmList.length; i++) {
            uint rmInfo = rmList[i];
            bool isBuy = uint8(rmInfo) != 0;
            uint32 id = uint32(rmInfo>>8);
            uint72 prevKey = uint72(rmInfo>>40);
            _removeOrder(isBuy, id, prevKey, proxyData);
        }
    }

    function removeOrder(bool isBuy, uint32 id, uint72 prevKey) public override lock {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+3));
        _removeOrder(isBuy, id, prevKey, proxyData);
    }

    function _removeOrder(bool isBuy, uint32 id, uint72 prevKey, uint[5] memory proxyData) private {
        Context memory ctx;
        (ctx.bookedStock, ctx.bookedMoney, ctx.firstBuyID) = getBooked();
        if(!isBuy) {
            (ctx.reserveStock, ctx.reserveMoney, ctx.firstSellID) = getReserves();
        }
        Order memory order = _removeOrderFromBook(ctx, isBuy, id, prevKey);
        require(msg.sender == order.sender, "OneSwap: NOT_OWNER");
        uint64 stockUnit = ProxyData.stockUnit(proxyData);
        uint stockAmount = uint(order.amount) * uint(stockUnit);
        address ones = ProxyData.ones(proxyData);
        if(isBuy) {
            RatPrice memory price = _expandPrice(order.price, proxyData);
            uint moneyAmount = stockAmount * price.numerator / price.denominator;
            ctx.bookedMoney -= moneyAmount;
            _safeTransfer(ProxyData.money(proxyData), order.sender, moneyAmount, ones);
        } else {
            ctx.bookedStock -= stockAmount;
            _safeTransfer(ProxyData.stock(proxyData), order.sender, stockAmount, ones);
        }
        _setBooked(ctx.bookedStock, ctx.bookedMoney, ctx.firstBuyID);
    }


    function _removeOrderFromBook(Context memory ctx, bool isBuy,
                                 uint32 id, uint72 prevKey) internal returns (Order memory) {
        (Order memory order, bool ok) = _getOrder(isBuy, id);
        require(ok, "OneSwap: NO_SUCH_ORDER");
        if(prevKey == 0) {
            uint32 firstID = _getFirstOrderID(ctx, isBuy);
            require(id == firstID, "OneSwap: NOT_FIRST");
            _setFirstOrderID(ctx, isBuy, order.nextID);
            if(!isBuy) {
                _setReserves(ctx.reserveStock, ctx.reserveMoney, ctx.firstSellID);
            }
        } else {
            (uint32 currID, Order memory prevOrder, bool findIt) = _getOrder3Times(isBuy, prevKey);
            require(findIt, "OneSwap: INVALID_POSITION");
            while(prevOrder.nextID != id) {
                currID = prevOrder.nextID;
                require(currID != 0, "OneSwap: REACH_END");
                (prevOrder, ) = _getOrder(isBuy, currID);
            }
            prevOrder.nextID = order.nextID;
            _setOrder(isBuy, currID, prevOrder);
        }
        _emitRemoveOrder(order.amount, id, isBuy);
        _deleteOrder(isBuy, id);
        return order;
    }



    function _insertOrderAtHead(Context memory ctx, bool isBuy, Order memory order, uint32 id) private {
        order.nextID = _getFirstOrderID(ctx, isBuy);
        _setOrder(isBuy, id, order);
        _setFirstOrderID(ctx, isBuy, id);
    }


    function _getOrder3Times(bool isBuy, uint72 prevKey) private view returns (
        uint32 currID, Order memory prevOrder, bool findIt) {
        currID = uint32(prevKey&_MAX_ID);
        (prevOrder, findIt) = _getOrder(isBuy, currID);
        if(!findIt) {
            currID = uint32((prevKey>>24)&_MAX_ID);
            (prevOrder, findIt) = _getOrder(isBuy, currID);
            if(!findIt) {
                currID = uint32((prevKey>>48)&_MAX_ID);
                (prevOrder, findIt) = _getOrder(isBuy, currID);
            }
        }
    }





    function _insertOrderFromGivenPos(bool isBuy, Order memory order,
                                     uint32 id, uint72 prevKey) private returns (bool inserted) {
        (uint32 currID, Order memory prevOrder, bool findIt) = _getOrder3Times(isBuy, prevKey);
        if(!findIt) {
            return false;
        }
        return _insertOrder(isBuy, order, prevOrder, id, currID);
    }


    function _insertOrderFromHead(Context memory ctx, bool isBuy, Order memory order,
                                 uint32 id) private returns (bool inserted) {
        uint32 firstID = _getFirstOrderID(ctx, isBuy);
        bool canBeFirst = (firstID == 0);
        Order memory firstOrder;
        if(!canBeFirst) {
            (firstOrder, ) = _getOrder(isBuy, firstID);
            canBeFirst = (isBuy && (firstOrder.price < order.price)) ||
                (!isBuy && (firstOrder.price > order.price));
        }
        if(canBeFirst) {
            order.nextID = firstID;
            _setOrder(isBuy, id, order);
            _setFirstOrderID(ctx, isBuy, id);
            return true;
        }
        return _insertOrder(isBuy, order, firstOrder, id, firstID);
    }


    function _insertOrder(bool isBuy, Order memory order, Order memory prevOrder,
                         uint32 id, uint32 currID) private returns (bool inserted) {
        while(currID != 0) {
            bool canFollow = (isBuy && (order.price <= prevOrder.price)) ||
                (!isBuy && (order.price >= prevOrder.price));
            if(!canFollow) {break;}
            Order memory nextOrder;
            if(prevOrder.nextID != 0) {
                (nextOrder, ) = _getOrder(isBuy, prevOrder.nextID);
                bool canPrecede = (isBuy && (nextOrder.price < order.price)) ||
                    (!isBuy && (nextOrder.price > order.price));
                canFollow = canFollow && canPrecede;
            }
            if(canFollow) {
                order.nextID = prevOrder.nextID;
                _setOrder(isBuy, id, order);
                prevOrder.nextID = id;
                _setOrder(isBuy, currID, prevOrder);
                return true;
            }
            currID = prevOrder.nextID;
            prevOrder = nextOrder;
        }
        return false;
    }


    function getPrices() public override returns (
        uint firstSellPriceNumerator,
        uint firstSellPriceDenominator,
        uint firstBuyPriceNumerator,
        uint firstBuyPriceDenominator,
        uint poolPriceNumerator,
        uint poolPriceDenominator) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+0));
        (uint112 reserveStock, uint112 reserveMoney, uint32 firstSellID) = getReserves();
        poolPriceNumerator = uint(reserveMoney);
        poolPriceDenominator = uint(reserveStock);
        firstSellPriceNumerator = 0;
        firstSellPriceDenominator = 0;
        firstBuyPriceNumerator = 0;
        firstBuyPriceDenominator = 0;
        if(firstSellID!=0) {
            uint order = _sellOrders[firstSellID];
            RatPrice memory price = _expandPrice(uint32(order>>64), proxyData);
            firstSellPriceNumerator = price.numerator;
            firstSellPriceDenominator = price.denominator;
        }
        uint32 id = uint32(_bookedStockAndMoneyAndFirstBuyID>>224);
        if(id!=0) {
            uint order = _buyOrders[id];
            RatPrice memory price = _expandPrice(uint32(order>>64), proxyData);
            firstBuyPriceNumerator = price.numerator;
            firstBuyPriceDenominator = price.denominator;
        }
    }


    function getOrderList(bool isBuy, uint32 id, uint32 maxCount) public override view returns (uint[] memory) {
        if(id == 0) {
            if(isBuy) {
                id = uint32(_bookedStockAndMoneyAndFirstBuyID>>224);
            } else {
                id = uint32(_reserveStockAndMoneyAndFirstSellID>>224);
            }
        }
        uint[1<<22] storage orderbook;
        if(isBuy) {
            orderbook = _buyOrders;
        } else {
            orderbook = _sellOrders;
        }

        uint order = (block.number<<24) | id;
        uint addrOrig;
        uint addrLen;
        uint addrStart;
        uint addrEnd;
        uint count = 0;

        assembly {
            addrOrig := mload(0x40)
            mstore(addrOrig, 32)
        }
        addrLen = addrOrig + 32;
        addrStart = addrLen + 32;
        addrEnd = addrStart;
        while(count < maxCount) {

            assembly {
                mstore(addrEnd, order)
            }
            addrEnd += 32;
            count++;
            if(id == 0) {break;}
            order = orderbook[id];
            require(order!=0, "OneSwap: INCONSISTENT_BOOK");
            id = uint32(order&_MAX_ID);
        }

        assembly {
            mstore(addrLen, count)
            let byteCount := sub(addrEnd, addrOrig)
            return(addrOrig, byteCount)
        }
    }


    function _getUnusedOrderID(bool isBuy, uint32 id) internal view returns (uint32) {
        if(id == 0) {

            id = uint32(uint(blockhash(block.number-1))^uint(tx.origin)) & _MAX_ID;
        }
        for(uint32 i = 0; i < 100 && id <= _MAX_ID; i++) {
            if(!_hasOrder(isBuy, id)) {
                return id;
            }
            id++;
        }
        require(false, "OneSwap: CANNOT_FIND_VALID_ID");
        return 0;
    }

    function calcStockAndMoney(uint64 amount, uint32 price32) public pure override returns (uint stockAmount, uint moneyAmount) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+2));
        (stockAmount, moneyAmount, ) = _calcStockAndMoney(amount, price32, proxyData);
    }

    function _calcStockAndMoney(uint64 amount, uint32 price32, uint[5] memory proxyData) private pure returns (uint stockAmount, uint moneyAmount, RatPrice memory price) {
        price = _expandPrice(price32, proxyData);
        uint64 stockUnit = ProxyData.stockUnit(proxyData);
        stockAmount = uint(amount) * uint(stockUnit);
        moneyAmount = stockAmount * price.numerator /price.denominator;
    }

    function addLimitOrder(bool isBuy, address sender, uint64 amount, uint32 price32,
                           uint32 id, uint72 prevKey) public payable override lock {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+6));
        require(ProxyData.isOnlySwap(proxyData)==false, "OneSwap: LIMIT_ORDER_NOT_SUPPORTED");
        Context memory ctx;
        ctx.stockUnit = ProxyData.stockUnit(proxyData);
        ctx.ones = ProxyData.ones(proxyData);
        ctx.factory = ProxyData.factory(proxyData);
        ctx.stockToken = ProxyData.stock(proxyData);
        ctx.moneyToken = ProxyData.money(proxyData);
        ctx.priceMul = ProxyData.priceMul(proxyData);
        ctx.priceDiv = ProxyData.priceDiv(proxyData);
        ctx.hasDealtInOrderBook = false;
        ctx.isLimitOrder = true;
        ctx.order.sender = sender;
        ctx.order.amount = amount;
        ctx.order.price = price32;

        ctx.newOrderID = _getUnusedOrderID(isBuy, id);
        RatPrice memory price;

        {
            require((amount >> 42) == 0, "OneSwap: INVALID_AMOUNT");
            uint32 m = price32 & DecFloat32.MANTISSA_MASK;
            require(DecFloat32.MIN_MANTISSA <= m && m <= DecFloat32.MAX_MANTISSA, "OneSwap: INVALID_PRICE");

            uint stockAmount;
            uint moneyAmount;
            (stockAmount, moneyAmount, price) = _calcStockAndMoney(amount, price32, proxyData);
            if(isBuy) {
                ctx.remainAmount = moneyAmount;
            } else {
                ctx.remainAmount = stockAmount;
            }
        }

        require(ctx.remainAmount < uint(1<<112), "OneSwap: OVERFLOW");
        (ctx.reserveStock, ctx.reserveMoney, ctx.firstSellID) = getReserves();
        (ctx.bookedStock, ctx.bookedMoney, ctx.firstBuyID) = getBooked();
        _checkRemainAmount(ctx, isBuy);
        if(prevKey != 0) {
            bool inserted = _insertOrderFromGivenPos(isBuy, ctx.order, ctx.newOrderID, prevKey);
            if(inserted) {
                _emitNewLimitOrder(uint64(ctx.order.sender), amount, amount, price32, ctx.newOrderID, isBuy);
                if(isBuy) {
                    ctx.bookedMoney += ctx.remainAmount;
                } else {
                    ctx.bookedStock += ctx.remainAmount;
                }
                _setBooked(ctx.bookedStock, ctx.bookedMoney, ctx.firstBuyID);
                if(ctx.reserveChanged) {
                    _setReserves(ctx.reserveStock, ctx.reserveMoney, ctx.firstSellID);
                }
                return;
            }

        }
        _addOrder(ctx, isBuy, price);
    }

    function addMarketOrder(address inputToken, address sender,
                            uint112 inAmount) public payable override lock returns (uint) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+3));
        Context memory ctx;
        ctx.moneyToken = ProxyData.money(proxyData);
        ctx.stockToken = ProxyData.stock(proxyData);
        require(inputToken == ctx.moneyToken || inputToken == ctx.stockToken, "OneSwap: INVALID_TOKEN");
        bool isBuy = inputToken == ctx.moneyToken;
        ctx.stockUnit = ProxyData.stockUnit(proxyData);
        ctx.priceMul = ProxyData.priceMul(proxyData);
        ctx.priceDiv = ProxyData.priceDiv(proxyData);
        ctx.ones = ProxyData.ones(proxyData);
        ctx.factory = ProxyData.factory(proxyData);
        ctx.hasDealtInOrderBook = false;
        ctx.isLimitOrder = false;
        ctx.remainAmount = inAmount;
        (ctx.reserveStock, ctx.reserveMoney, ctx.firstSellID) = getReserves();
        (ctx.bookedStock, ctx.bookedMoney, ctx.firstBuyID) = getBooked();
        _checkRemainAmount(ctx, isBuy);
        ctx.order.sender = sender;
        if(isBuy) {
            ctx.order.price = DecFloat32.MAX_PRICE;
        } else {
            ctx.order.price = DecFloat32.MIN_PRICE;
        }

        RatPrice memory price;
        _emitNewMarketOrder(uint136(ctx.order.sender), inAmount, isBuy);
        return _addOrder(ctx, isBuy, price);
    }



    function _checkRemainAmount(Context memory ctx, bool isBuy) private view {
        ctx.reserveChanged = false;
        uint diff;
        if(isBuy) {
            uint balance = _myBalance(ctx.moneyToken);
            require(balance >= ctx.bookedMoney + ctx.reserveMoney, "OneSwap: MONEY_MISMATCH");
            diff = balance - ctx.bookedMoney - ctx.reserveMoney;
            if(ctx.remainAmount < diff) {
                ctx.reserveMoney += (diff - ctx.remainAmount);
                ctx.reserveChanged = true;
            }
        } else {
            uint balance = _myBalance(ctx.stockToken);
            require(balance >= ctx.bookedStock + ctx.reserveStock, "OneSwap: STOCK_MISMATCH");
            diff = balance - ctx.bookedStock - ctx.reserveStock;
            if(ctx.remainAmount < diff) {
                ctx.reserveStock += (diff - ctx.remainAmount);
                ctx.reserveChanged = true;
            }
        }
        require(ctx.remainAmount <= diff, "OneSwap: DEPOSIT_NOT_ENOUGH");
    }



    function _addOrder(Context memory ctx, bool isBuy, RatPrice memory price) private returns (uint) {
        (ctx.dealMoneyInBook, ctx.dealStockInBook) = (0, 0);
        ctx.firstID = _getFirstOrderID(ctx, !isBuy);
        uint32 currID = ctx.firstID;
        ctx.amountIntoPool = 0;
        while(currID != 0) {
            (Order memory orderInBook, ) = _getOrder(!isBuy, currID);
            bool canDealInOrderBook = (isBuy && (orderInBook.price <= ctx.order.price)) ||
                (!isBuy && (orderInBook.price >= ctx.order.price));
            if(!canDealInOrderBook) {break;}


            RatPrice memory priceInBook = _expandPrice(ctx, orderInBook.price);
            bool allDeal = _tryDealInPool(ctx, isBuy, priceInBook);
            if(allDeal) {break;}


            _dealInOrderBook(ctx, isBuy, currID, orderInBook, priceInBook);


            if(orderInBook.amount != 0) {
                _setOrder(!isBuy, currID, orderInBook);
                break;
            }

            _deleteOrder(!isBuy, currID);
            currID = orderInBook.nextID;
        }

        if(ctx.isLimitOrder) {

            _tryDealInPool(ctx, isBuy, price);


            _insertOrderToBook(ctx, isBuy, price);
        } else {

            ctx.amountIntoPool += ctx.remainAmount;
            ctx.remainAmount = 0;
        }
        uint amountToTaker = _dealWithPoolAndCollectFee(ctx, isBuy);
        if(isBuy) {
            ctx.bookedStock -= ctx.dealStockInBook;
        } else {
            ctx.bookedMoney -= ctx.dealMoneyInBook;
        }
        if(ctx.firstID != currID) {
            _setFirstOrderID(ctx, !isBuy, currID);
        }

        _setBooked(ctx.bookedStock, ctx.bookedMoney, ctx.firstBuyID);
        _setReserves(ctx.reserveStock, ctx.reserveMoney, ctx.firstSellID);
        return amountToTaker;
    }



    function _intopoolAmountTillPrice(bool isBuy, uint reserveMoney, uint reserveStock,
                                     RatPrice memory price) private pure returns (uint result) {


        uint numerator = reserveMoney;
        uint denominator = reserveStock;
        if(isBuy) {

            (numerator, denominator) = (denominator, numerator);
        }
        while(numerator >= (1<<192)) {
            numerator >>= 16;
            denominator >>= 16;
        }
        require(denominator != 0, "OneSwapPair: DIV_BY_ZERO");
        numerator = numerator * (1<<64);
        uint quotient = numerator / denominator;
        if(quotient <= (1<<64)) {
            return 0;
        } else if(quotient <= ((1<<64)*5/4)) {

            uint x = quotient - (1<<64);
            uint y = x*x;
            y = x/2 - y/(8*(1<<64)) + y*x/(16*(1<<128));
            if(isBuy) {
                result = reserveMoney * y;
            } else {
                result = reserveStock * y;
            }
            result /= (1<<64);
            return result;
        }
        uint root = Math.sqrt(quotient);
        uint diff =  root - (1<<32);
        if(isBuy) {
            result = reserveMoney * diff;
        } else {
            result = reserveStock * diff;
        }
        result /= (1<<32);
        return result;
    }


    function _tryDealInPool(Context memory ctx, bool isBuy, RatPrice memory price) private pure returns (bool) {
        uint currTokenCanTrade = _intopoolAmountTillPrice(isBuy, ctx.reserveMoney, ctx.reserveStock, price);
        require(currTokenCanTrade < uint(1<<112), "OneSwap: CURR_TOKEN_TOO_LARGE");

        if(!isBuy) {
            currTokenCanTrade /= ctx.stockUnit;
            currTokenCanTrade *= ctx.stockUnit;
        }
        if(currTokenCanTrade > ctx.amountIntoPool) {
            uint diffTokenCanTrade = currTokenCanTrade - ctx.amountIntoPool;
            bool allDeal = diffTokenCanTrade >= ctx.remainAmount;
            if(allDeal) {
                diffTokenCanTrade = ctx.remainAmount;
            }
            ctx.amountIntoPool += diffTokenCanTrade;
            ctx.remainAmount -= diffTokenCanTrade;
            return allDeal;
        }
        return false;
    }


    function _dealInOrderBook(Context memory ctx, bool isBuy, uint32 currID,
                             Order memory orderInBook, RatPrice memory priceInBook) internal {
        ctx.hasDealtInOrderBook = true;
        uint stockAmount;
        if(isBuy) {
            uint a = ctx.remainAmount;
            uint b = priceInBook.numerator;
            stockAmount = a/b;
        } else {
            stockAmount = ctx.remainAmount/ctx.stockUnit;
        }
        if(uint(orderInBook.amount) < stockAmount) {
            stockAmount = uint(orderInBook.amount);
        }
        require(stockAmount < (1<<42), "OneSwap: STOCK_TOO_LARGE");
        uint stockTrans = stockAmount;
        uint moneyTrans = stockTrans * priceInBook.numerator;

        _emitOrderChanged(orderInBook.amount, uint64(stockAmount), currID, isBuy);
        orderInBook.amount -= uint64(stockAmount);
        if(isBuy) {
            ctx.remainAmount -= moneyTrans;
        } else {
            ctx.remainAmount -= stockTrans;
        }


        ctx.dealStockInBook += stockTrans;
        ctx.dealMoneyInBook += moneyTrans;
        if(isBuy) {
            _safeTransfer(ctx.moneyToken, orderInBook.sender, moneyTrans, ctx.ones);
        } else {
            _safeTransfer(ctx.stockToken, orderInBook.sender, stockTrans, ctx.ones);
        }
    }


    function _dealWithPoolAndCollectFee(Context memory ctx, bool isBuy) internal returns (uint) {
        (uint outpoolTokenReserve, uint inpoolTokenReserve, uint otherToTaker) = (
              ctx.reserveMoney, ctx.reserveStock, ctx.dealMoneyInBook);
        if(isBuy) {
            (outpoolTokenReserve, inpoolTokenReserve, otherToTaker) = (
                ctx.reserveStock, ctx.reserveMoney, ctx.dealStockInBook);
        }



        uint outAmount = (outpoolTokenReserve*ctx.amountIntoPool)/(inpoolTokenReserve+ctx.amountIntoPool);
        if(ctx.amountIntoPool > 0) {
            _emitDealWithPool(uint112(ctx.amountIntoPool), uint112(outAmount), isBuy);
        }
        uint32 feeBPS = IOneSwapFactory(ctx.factory).feeBPS();


        uint amountToTaker = outAmount + otherToTaker;
        require(amountToTaker < uint(1<<112), "OneSwap: AMOUNT_TOO_LARGE");
        uint fee = (amountToTaker * feeBPS + 9999) / 10000;
        amountToTaker -= fee;

        if(isBuy) {
            ctx.reserveMoney = ctx.reserveMoney + ctx.amountIntoPool;
            ctx.reserveStock = ctx.reserveStock - outAmount + fee;
        } else {
            ctx.reserveMoney = ctx.reserveMoney - outAmount + fee;
            ctx.reserveStock = ctx.reserveStock + ctx.amountIntoPool;
        }

        address token = ctx.moneyToken;
        if(isBuy) {
            token = ctx.stockToken;
        }
        _safeTransfer(token, ctx.order.sender, amountToTaker, ctx.ones);
        return amountToTaker;
    }


    function _insertOrderToBook(Context memory ctx, bool isBuy, RatPrice memory price) internal {
        (uint smallAmount, uint moneyAmount, uint stockAmount) = (0, 0, 0);
        if(isBuy) {
            uint tempAmount1 = ctx.remainAmount ;
            uint temp = ctx.stockUnit * price.numerator;
            stockAmount = tempAmount1 / temp;
            uint tempAmount2 = stockAmount * temp;
            moneyAmount = (tempAmount2+price.denominator-1)/price.denominator;
            if(ctx.remainAmount > moneyAmount) {

                smallAmount = ctx.remainAmount - moneyAmount;
            } else {
                moneyAmount = ctx.remainAmount;
            }
        } else {


            stockAmount = ctx.remainAmount / ctx.stockUnit;
            smallAmount = ctx.remainAmount - stockAmount * ctx.stockUnit;
        }
        ctx.amountIntoPool += smallAmount;

        _emitNewLimitOrder(uint64(ctx.order.sender), ctx.order.amount, uint64(stockAmount),
                           ctx.order.price, ctx.newOrderID, isBuy);
        if(stockAmount != 0) {
            ctx.order.amount = uint64(stockAmount);
            if(ctx.hasDealtInOrderBook) {

                _insertOrderAtHead(ctx, isBuy, ctx.order, ctx.newOrderID);
            } else {


                _insertOrderFromHead(ctx, isBuy, ctx.order, ctx.newOrderID);
            }
        }

        if(isBuy) {
            ctx.bookedMoney += moneyAmount;
        } else {
            ctx.bookedStock += (ctx.remainAmount - smallAmount);
        }
    }
}


contract OneSwapPairProxy {
    uint internal _unusedVar0;
    uint internal _unusedVar1;
    uint internal _unusedVar2;
    uint internal _unusedVar3;
    uint internal _unusedVar4;
    uint internal _unusedVar5;
    uint internal _unusedVar6;
    uint internal _unusedVar7;
    uint internal _unusedVar8;
    uint internal _unusedVar9;
    uint internal _unlocked;

    uint internal immutable _immuFactory;
    uint internal immutable _immuMoneyToken;
    uint internal immutable _immuStockToken;
    uint internal immutable _immuOnes;
    uint internal immutable _immuOther;

    constructor(address stockToken, address moneyToken, bool isOnlySwap, uint64 stockUnit, uint64 priceMul, uint64 priceDiv, address ones) public {
        _immuFactory = uint(msg.sender);
        _immuMoneyToken = uint(moneyToken);
        _immuStockToken = uint(stockToken);
        _immuOnes = uint(ones);
        uint temp = 0;
        if(isOnlySwap) {
            temp = 1;
        }
        temp = (temp<<64) | stockUnit;
        temp = (temp<<64) | priceMul;
        temp = (temp<<64) | priceDiv;
        _immuOther = temp;
        _unlocked = 1;
    }

    receive() external payable { }

    fallback() payable external {
        uint factory     = _immuFactory;
        uint moneyToken  = _immuMoneyToken;
        uint stockToken  = _immuStockToken;
        uint ones        = _immuOnes;
        uint other       = _immuOther;
        address impl = IOneSwapFactory(address(_immuFactory)).pairLogic();

        assembly {
            let ptr := mload(0x40)
            let size := calldatasize()
            calldatacopy(ptr, 0, size)
            let end := add(ptr, size)

            mstore(end, factory)
            end := add(end, 32)
            mstore(end, moneyToken)
            end := add(end, 32)
            mstore(end, stockToken)
            end := add(end, 32)
            mstore(end, ones)
            end := add(end, 32)
            mstore(end, other)
            size := add(size, 160)
            let result := delegatecall(gas(), impl, ptr, size, 0, 0)
            size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}
