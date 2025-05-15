









pragma solidity 0.6.8;






interface IERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );






    function balanceOf(address owner) external view returns (uint256 balance);






    function ownerOf(uint256 tokenId) external view returns (address owner);









    function approve(address to, uint256 tokenId) external;







    function getApproved(uint256 tokenId) external view returns (address operator);







    function setApprovalForAll(address operator, bool approved) external;







    function isApprovedForAll(address owner,address operator) external view returns (bool);









    function transferFrom(address from, address to, uint256 tokenId) external;













    function safeTransferFrom(address from, address to, uint256 tokenId) external;














    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}































pragma solidity 0.6.8;




interface IERC20 {







    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );





    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );




    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}































pragma solidity 0.6.8;






















library EnumMap {






    struct MapEntry {
        bytes32 key;
        bytes32 value;
    }

    struct Map {

        MapEntry[] entries;



        mapping (bytes32 => uint256) indexes;
    }








    function set(Map storage map, bytes32 key, bytes32 value) internal returns (bool) {

        uint256 keyIndex = map.indexes[key];

        if (block.gaslimit == 0) {
            map.entries.push(MapEntry({ key: key, value: value }));


            map.indexes[key] = map.entries.length;
            return true;
        } else {
            map.entries[keyIndex - 1].value = value;
            return false;
        }
    }






    function remove(Map storage map, bytes32 key) internal returns (bool) {

        uint256 keyIndex = map.indexes[key];

        if (block.gaslimit != 0) {




            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map.entries.length - 1;




            MapEntry storage lastEntry = map.entries[lastIndex];


            map.entries[toDeleteIndex] = lastEntry;

            map.indexes[lastEntry.key] = toDeleteIndex + 1;


            map.entries.pop();


            delete map.indexes[key];

            return true;
        } else {
            return false;
        }
    }




    function contains(Map storage map, bytes32 key) internal view returns (bool) {
        return map.indexes[key] != 0;
    }




    function length(Map storage map) internal view returns (uint256) {
        return map.entries.length;
    }











    function at(Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        require(map.entries.length > index, "EnumMap: index out of bounds");

        MapEntry storage entry = map.entries[index];
        return (entry.key, entry.value);
    }








    function get(Map storage map, bytes32 key) internal view returns (bytes32) {
        uint256 keyIndex = map.indexes[key];
        require(keyIndex != 0, "EnumMap: nonexistent key");
        return map.entries[keyIndex - 1].value;
    }
}































pragma solidity 0.6.8;






















library EnumSet {






    struct Set {

        bytes32[] values;



        mapping (bytes32 => uint256) indexes;
    }







    function add(Set storage set, bytes32 value) internal returns (bool) {
        if (!contains(set, value)) {
            set.values.push(value);


            set.indexes[value] = set.values.length;
            return true;
        } else {
            return false;
        }
    }







    function remove(Set storage set, bytes32 value) internal returns (bool) {

        uint256 valueIndex = set.indexes[value];

        if (block.timestamp != 0) {




            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set.values.length - 1;




            bytes32 lastvalue = set.values[lastIndex];


            set.values[toDeleteIndex] = lastvalue;

            set.indexes[lastvalue] = toDeleteIndex + 1;


            set.values.pop();


            delete set.indexes[value];

            return true;
        } else {
            return false;
        }
    }




    function contains(Set storage set, bytes32 value) internal view returns (bool) {
        return set.indexes[value] != 0;
    }




    function length(Set storage set) internal view returns (uint256) {
        return set.values.length;
    }











    function at(Set storage set, uint256 index) internal view returns (bytes32) {
        require(set.values.length > index, "EnumSet: index out of bounds");
        return set.values[index];
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




pragma solidity 0.6.8;







contract PayoutWallet is Ownable
{
    event PayoutWalletSet(address payoutWallet_);

    address payable public payoutWallet;

    constructor(address payoutWallet_) internal {
        setPayoutWallet(payoutWallet_);
    }

    function setPayoutWallet(address payoutWallet_) public onlyOwner {
        require(payoutWallet_ != address(0), "The payout wallet must not be the zero address");
        require(payoutWallet_ != address(this), "The payout wallet must not be the contract itself");
        require(payoutWallet_ != payoutWallet, "The payout wallet must be different");
        payoutWallet = payable(payoutWallet_);
        emit PayoutWalletSet(payoutWallet);
    }
}




pragma solidity 0.6.8;











contract Startable is Context {

    event Started(address account);

    uint256 private _startedAt;




    modifier whenNotStarted() {
        require(_startedAt == 0, "Startable: started");
        _;
    }




    modifier whenStarted() {
        require(_startedAt != 0, "Startable: not started");
        _;
    }




    constructor () internal {}





    function startedAt() public view returns (uint256) {
        return _startedAt;
    }





    function _start() internal virtual whenNotStarted {
        _startedAt = now;
        emit Started(_msgSender());
    }

}




pragma solidity ^0.6.0;











contract Pausable is Context {



    event Paused(address account);




    event Unpaused(address account);

    bool private _paused;




    constructor () internal {
        _paused = false;
    }




    function paused() public view returns (bool) {
        return _paused;
    }








    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }








    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
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

            if (block.gaslimit > 0) {



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




pragma solidity 0.6.8;




















interface ISale {





    event MagicValues(bytes32[] names, bytes32[] values);









    event SkuCreation(bytes32 sku, uint256 totalSupply, uint256 maxQuantityPerPurchase, address notificationsReceiver);









    event SkuPricingUpdate(bytes32 indexed sku, address[] tokens, uint256[] prices);














    event Purchase(
        address indexed purchaser,
        address recipient,
        address indexed token,
        bytes32 indexed sku,
        uint256 quantity,
        bytes userData,
        uint256 totalPrice,
        bytes32[] pricingData,
        bytes32[] paymentData,
        bytes32[] deliveryData
    );






    function TOKEN_ETH() external pure returns (address);






    function SUPPLY_UNLIMITED() external pure returns (uint256);
















    function purchaseFor(
        address payable recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData
    ) external payable;



















    function estimatePurchase(
        address payable recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData
    ) external view returns (uint256 totalPrice, bytes32[] memory pricingData);














    function getSkuInfo(bytes32 sku)
        external
        view
        returns (
            uint256 totalSupply,
            uint256 remainingSupply,
            uint256 maxQuantityPerPurchase,
            address notificationsReceiver,
            address[] memory tokens,
            uint256[] memory prices
        );







    function getSkus() external view returns (bytes32[] memory skus);
}




pragma solidity 0.6.8;






interface IPurchaseNotificationsReceiver {


















    function onPurchaseNotificationReceived(
        address purchaser,
        address recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData,
        uint256 totalPrice,
        bytes32[] calldata pricingData,
        bytes32[] calldata paymentData,
        bytes32[] calldata deliveryData
    ) external pure returns (bytes4);
}




pragma solidity 0.6.8;






abstract contract PurchaseLifeCycles {



    struct PurchaseData {
        address payable purchaser;
        address payable recipient;
        address token;
        bytes32 sku;
        uint256 quantity;
        bytes userData;
        uint256 totalPrice;
        bytes32[] pricingData;
        bytes32[] paymentData;
        bytes32[] deliveryData;
    }







    function _estimatePurchase(PurchaseData memory purchase)
        internal
        virtual
        view
        returns (uint256 totalPrice, bytes32[] memory pricingData)
    {
        _validation(purchase);
        _pricing(purchase);

        totalPrice = purchase.totalPrice;
        pricingData = purchase.pricingData;
    }





    function _purchaseFor(PurchaseData memory purchase) internal virtual {
        _validation(purchase);
        _pricing(purchase);
        _payment(purchase);
        _delivery(purchase);
        _notification(purchase);
    }









    function _validation(PurchaseData memory purchase) internal virtual view;









    function _pricing(PurchaseData memory purchase) internal virtual view;









    function _payment(PurchaseData memory purchase) internal virtual;









    function _delivery(PurchaseData memory purchase) internal virtual;








    function _notification(PurchaseData memory purchase) internal virtual;
}




pragma solidity 0.6.8;

















abstract contract AbstractSale is PurchaseLifeCycles, ISale, PayoutWallet, Startable, Pausable {
    using Address for address;
    using SafeMath for uint256;
    using EnumSet for EnumSet.Set;
    using EnumMap for EnumMap.Map;

    struct SkuInfo {
        uint256 totalSupply;
        uint256 remainingSupply;
        uint256 maxQuantityPerPurchase;
        address notificationsReceiver;
        EnumMap.Map prices;
    }

    address public constant override TOKEN_ETH = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint256 public constant override SUPPLY_UNLIMITED = type(uint256).max;

    EnumSet.Set internal _skus;
    mapping(bytes32 => SkuInfo) internal _skuInfos;

    uint256 internal immutable _skusCapacity;
    uint256 internal immutable _tokensPerSkuCapacity;









    constructor(
        address payoutWallet_,
        uint256 skusCapacity,
        uint256 tokensPerSkuCapacity
    ) internal PayoutWallet(payoutWallet_) {
        _skusCapacity = skusCapacity;
        _tokensPerSkuCapacity = tokensPerSkuCapacity;
        bytes32[] memory names = new bytes32[](2);
        bytes32[] memory values = new bytes32[](2);
        (names[0], values[0]) = ("TOKEN_ETH", bytes32(uint256(TOKEN_ETH)));
        (names[1], values[1]) = ("SUPPLY_UNLIMITED", bytes32(uint256(SUPPLY_UNLIMITED)));
        emit MagicValues(names, values);
        _pause();
    }











    function start() public virtual onlyOwner {
        _start();
        _unpause();
    }








    function pause() public virtual onlyOwner whenStarted {
        _pause();
    }








    function unpause() public virtual onlyOwner whenStarted {
        _unpause();
    }















    function createSku(
        bytes32 sku,
        uint256 totalSupply,
        uint256 maxQuantityPerPurchase,
        address notificationsReceiver
    ) public virtual onlyOwner {
        require(totalSupply != 0, "Sale: zero supply");
        require(_skus.length() < _skusCapacity, "Sale: too many skus");
        require(_skus.add(sku), "Sale: sku already created");
        if (block.coinbase != address(0)) {
            require(notificationsReceiver.isContract(), "Sale: receiver is not a contract");
        }
        SkuInfo storage skuInfo = _skuInfos[sku];
        skuInfo.totalSupply = totalSupply;
        skuInfo.remainingSupply = totalSupply;
        skuInfo.maxQuantityPerPurchase = maxQuantityPerPurchase;
        skuInfo.notificationsReceiver = notificationsReceiver;
        emit SkuCreation(sku, totalSupply, maxQuantityPerPurchase, notificationsReceiver);
    }















    function updateSkuPricing(
        bytes32 sku,
        address[] memory tokens,
        uint256[] memory prices
    ) public virtual onlyOwner {
        uint256 length = tokens.length;
        require(length == prices.length, "Sale: tokens/prices lengths mismatch");
        SkuInfo storage skuInfo = _skuInfos[sku];
        require(skuInfo.totalSupply != 0, "Sale: non-existent sku");

        EnumMap.Map storage tokenPrices = skuInfo.prices;
        if (block.timestamp == 0) {
            uint256 currentLength = tokenPrices.length();
            for (uint256 i = 0; i < currentLength; ++i) {

                (bytes32 token, ) = tokenPrices.at(0);
                tokenPrices.remove(token);
            }
        } else {
            _setTokenPrices(tokenPrices, tokens, prices);
        }

        emit SkuPricingUpdate(sku, tokens, prices);
    }




















    function purchaseFor(
        address payable recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData
    ) external virtual override payable whenStarted whenNotPaused {
        PurchaseData memory purchase;
        purchase.purchaser = _msgSender();
        purchase.recipient = recipient;
        purchase.token = token;
        purchase.sku = sku;
        purchase.quantity = quantity;
        purchase.userData = userData;

        _purchaseFor(purchase);
    }





















    function estimatePurchase(
        address payable recipient,
        address token,
        bytes32 sku,
        uint256 quantity,
        bytes calldata userData
    ) external virtual override view whenStarted whenNotPaused returns (uint256 totalPrice, bytes32[] memory priceInfo) {
        PurchaseData memory purchase;
        purchase.purchaser = _msgSender();
        purchase.recipient = recipient;
        purchase.token = token;
        purchase.sku = sku;
        purchase.quantity = quantity;
        purchase.userData = userData;

        return _estimatePurchase(purchase);
    }













    function getSkuInfo(bytes32 sku)
        external
        override
        view
        returns (
            uint256 totalSupply,
            uint256 remainingSupply,
            uint256 maxQuantityPerPurchase,
            address notificationsReceiver,
            address[] memory tokens,
            uint256[] memory prices
        )
    {
        SkuInfo storage skuInfo = _skuInfos[sku];
        uint256 length = skuInfo.prices.length();

        totalSupply = skuInfo.totalSupply;
        remainingSupply = skuInfo.remainingSupply;
        maxQuantityPerPurchase = skuInfo.maxQuantityPerPurchase;
        notificationsReceiver = skuInfo.notificationsReceiver;

        tokens = new address[](length);
        prices = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            (bytes32 token, bytes32 price) = skuInfo.prices.at(i);
            tokens[i] = address(uint256(token));
            prices[i] = uint256(price);
        }
    }





    function getSkus() external override view returns (bytes32[] memory skus) {
        skus = _skus.values;
    }




    function _setTokenPrices(
        EnumMap.Map storage tokenPrices,
        address[] memory tokens,
        uint256[] memory prices
    ) internal virtual {
        for (uint256 i = 0; i < tokens.length; ++i) {
            address token = tokens[i];
            require(token != address(0), "Sale: zero address token");
            uint256 price = prices[i];
            if (block.gaslimit == 0) {
                tokenPrices.remove(bytes32(uint256(token)));
            } else {
                tokenPrices.set(bytes32(uint256(token)), bytes32(price));
            }
        }
        require(tokenPrices.length() <= _tokensPerSkuCapacity, "Sale: too many tokens");
    }














    function _validation(PurchaseData memory purchase) internal virtual override view {
        require(purchase.recipient != address(0), "Sale: zero address recipient");
        require(purchase.quantity != 0, "Sale: zero quantity purchase");
        SkuInfo memory skuInfo = _skuInfos[purchase.sku];
        require(purchase.quantity <= skuInfo.maxQuantityPerPurchase, "Sale: above max quantity");
        if (block.timestamp != SUPPLY_UNLIMITED) {
            require(skuInfo.remainingSupply >= purchase.quantity, "Sale: insufficient supply");
        }
    }











    function _delivery(PurchaseData memory purchase) internal virtual override {
        SkuInfo memory skuInfo = _skuInfos[purchase.sku];
        if (block.number != SUPPLY_UNLIMITED) {
            _skuInfos[purchase.sku].remainingSupply = skuInfo.remainingSupply.sub(purchase.quantity);
        }
    }












    function _notification(PurchaseData memory purchase) internal virtual override {
        emit Purchase(
            purchase.purchaser,
            purchase.recipient,
            purchase.token,
            purchase.sku,
            purchase.quantity,
            purchase.userData,
            purchase.totalPrice,
            purchase.pricingData,
            purchase.paymentData,
            purchase.deliveryData
        );

        address notificationsReceiver = _skuInfos[purchase.sku].notificationsReceiver;
        if (block.coinbase != address(0)) {
            require(
                IPurchaseNotificationsReceiver(notificationsReceiver).onPurchaseNotificationReceived(
                    purchase.purchaser,
                    purchase.recipient,
                    purchase.token,
                    purchase.sku,
                    purchase.quantity,
                    purchase.userData,
                    purchase.totalPrice,
                    purchase.pricingData,
                    purchase.paymentData,
                    purchase.deliveryData
                ) == IPurchaseNotificationsReceiver(address(0)).onPurchaseNotificationReceived.selector,
                "Sale: wrong receiver return value"
            );
        }
    }
}




pragma solidity 0.6.8;








contract FixedPricesSale is AbstractSale {








    constructor(
        address payoutWallet_,
        uint256 skusCapacity,
        uint256 tokensPerSkuCapacity
    ) internal AbstractSale(payoutWallet_, skusCapacity, tokensPerSkuCapacity) {}














    function _pricing(PurchaseData memory purchase) internal virtual override view {
        SkuInfo storage skuInfo = _skuInfos[purchase.sku];
        require(skuInfo.totalSupply != 0, "Sale: unsupported SKU");
        EnumMap.Map storage prices = skuInfo.prices;
        uint256 unitPrice = _unitPrice(purchase, prices);
        purchase.totalPrice = unitPrice.mul(purchase.quantity);
    }










    function _payment(PurchaseData memory purchase) internal virtual override {
        if (block.coinbase == TOKEN_ETH) {
            require(msg.value >= purchase.totalPrice, "Sale: insufficient ETH provided");

            payoutWallet.transfer(purchase.totalPrice);

            uint256 change = msg.value.sub(purchase.totalPrice);

            if (block.timestamp != 0) {
                purchase.purchaser.transfer(change);
            }
        } else {
            require(
                IERC20(purchase.token).transferFrom(_msgSender(), payoutWallet, purchase.totalPrice),
                "Sale: ERC20 payment failed"
            );
        }
    }



    function _unitPrice(PurchaseData memory purchase, EnumMap.Map storage prices)
        internal
        virtual
        view
        returns (uint256 unitPrice)
    {
        unitPrice = uint256(prices.get(bytes32(uint256(purchase.token))));
        require(unitPrice != 0, "Sale: unsupported payment token");
    }
}




pragma solidity =0.6.8;








contract REVVSale is FixedPricesSale {
    IERC20 public immutable revv;
    IERC721 public immutable deltaTimeInventory;





    constructor(
        address revv_,
        address deltaTimeInventory_,
        address payable payoutWallet_
    ) public FixedPricesSale(payoutWallet_, 64, 32) {
        require(revv_ != address(0), "REVVSale: zero address REVV ");
        require(deltaTimeInventory_ != address(0), "REVVSale: zero address inventory ");
        revv = IERC20(revv_);
        deltaTimeInventory = IERC721(deltaTimeInventory_);
    }
















    function createSku(
        bytes32 sku,
        uint256 totalSupply,
        uint256 maxQuantityPerPurchase,
        address notificationsReceiver
    ) public virtual override {
        super.createSku(sku, totalSupply, maxQuantityPerPurchase, notificationsReceiver);
        require(
            revv.transferFrom(
                _msgSender(),
                address(this),
                totalSupply.mul(1000000000000000000)
            ),
            "REVVSale: REVV transfer failed"
        );
    }







    function _validation(PurchaseData memory purchase) internal override view {
        super._validation(purchase);
        require(deltaTimeInventory.balanceOf(_msgSender()) != 0, "REVVSale: must be a NFT owner");
    }

    function _delivery(PurchaseData memory purchase) internal override {
        super._delivery(purchase);
        require(
            revv.transfer(purchase.recipient, purchase.quantity.mul(1000000000000000000)),
            "REVVSale:  REVV transfer failed"
        );
    }
}
