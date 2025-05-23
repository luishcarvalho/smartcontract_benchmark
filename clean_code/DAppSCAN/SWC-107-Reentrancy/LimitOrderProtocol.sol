

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/drafts/EIP712.sol";
import "@openzeppelin/contracts/drafts/IERC20Permit.sol";

import "./helpers/AmountCalculator.sol";
import "./helpers/ChainlinkCalculator.sol";
import "./helpers/ERC1155Proxy.sol";
import "./helpers/ERC20Proxy.sol";
import "./helpers/ERC721Proxy.sol";
import "./helpers/NonceManager.sol";
import "./helpers/PredicateHelper.sol";
import "./interfaces/IERC1271.sol";
import "./interfaces/InteractiveMaker.sol";
import "./libraries/UncheckedAddress.sol";
import "./libraries/ArgumentsDecoder.sol";
import "./libraries/SilentECDSA.sol";



contract LimitOrderProtocol is
    ImmutableOwner(address(this)),
    EIP712("1inch Limit Order Protocol", "1"),
    AmountCalculator,
    ChainlinkCalculator,
    ERC1155Proxy,
    ERC20Proxy,
    ERC721Proxy,
    NonceManager,
    PredicateHelper
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using UncheckedAddress for address;
    using ArgumentsDecoder for bytes;







    event OrderFilled(
        address indexed maker,
        bytes32 orderHash,
        uint256 remaining
    );

    event OrderFilledRFQ(
        bytes32 orderHash,
        uint256 makingAmount
    );

    struct OrderRFQ {
        uint256 info;
        address makerAsset;
        address takerAsset;
        bytes makerAssetData;
        bytes takerAssetData;
    }

    struct Order {
        uint256 salt;
        address makerAsset;
        address takerAsset;
        bytes makerAssetData;
        bytes takerAssetData;
        bytes getMakerAmount;
        bytes getTakerAmount;
        bytes predicate;
        bytes permit;
        bytes interaction;
    }

    bytes32 constant public LIMIT_ORDER_TYPEHASH = keccak256(
        "Order(uint256 salt,address makerAsset,address takerAsset,bytes makerAssetData,bytes takerAssetData,bytes getMakerAmount,bytes getTakerAmount,bytes predicate,bytes permit,bytes interaction)"
    );

    bytes32 constant public LIMIT_ORDER_RFQ_TYPEHASH = keccak256(
        "OrderRFQ(uint256 info,address makerAsset,address takerAsset,bytes makerAssetData,bytes takerAssetData)"
    );


    bytes4 immutable private _MAX_SELECTOR = bytes4(uint32(IERC20.transferFrom.selector) + 10);

    uint256 constant private _FROM_INDEX = 0;
    uint256 constant private _TO_INDEX = 1;
    uint256 constant private _AMOUNT_INDEX = 2;

    mapping(bytes32 => uint256) private _remaining;
    mapping(address => mapping(uint256 => uint256)) private _invalidator;


    function DOMAIN_SEPARATOR() external view returns(bytes32) {
        return _domainSeparatorV4();
    }


    function remaining(bytes32 orderHash) external view returns(uint256) {
        return _remaining[orderHash].sub(1, "LOP: Unknown order");
    }



    function remainingRaw(bytes32 orderHash) external view returns(uint256) {
        return _remaining[orderHash];
    }


    function remainingsRaw(bytes32[] memory orderHashes) external view returns(uint256[] memory results) {
        results = new uint256[](orderHashes.length);
        for (uint i = 0; i < orderHashes.length; i++) {
            results[i] = _remaining[orderHashes[i]];
        }
    }



    function invalidatorForOrderRFQ(address maker, uint256 slot) external view returns(uint256) {
        return _invalidator[maker][slot];
    }


    function checkPredicate(Order memory order) public view returns(bool) {
        bytes memory result = address(this).uncheckedFunctionStaticCall(order.predicate, "LOP: predicate call failed");
        require(result.length == 32, "LOP: invalid predicate return");
        return abi.decode(result, (bool));
    }







    function simulateCalls(address[] calldata targets, bytes[] calldata data) external {
        require(targets.length == data.length, "LOP: array size mismatch");
        bytes memory reason = new bytes(targets.length);
        for (uint i = 0; i < targets.length; i++) {

            (bool success, bytes memory result) = targets[i].call(data[i]);
            if (success && result.length > 0) {
                success = abi.decode(result, (bool));
            }
            reason[i] = success ? bytes1("1") : bytes1("0");
        }


        revert(string(abi.encodePacked("CALL_RESULTS_", reason)));
    }


    function cancelOrder(Order memory order) external {
        require(order.makerAssetData.decodeAddress(_FROM_INDEX) == msg.sender, "LOP: Access denied");

        bytes32 orderHash = _hash(order);
        _remaining[orderHash] = 1;
        emit OrderFilled(msg.sender, orderHash, 0);
    }


    function cancelOrderRFQ(uint256 orderInfo) external {
        _invalidator[msg.sender][uint64(orderInfo) >> 8] |= (1 << (orderInfo & 0xff));
    }






    function fillOrderRFQ(
        OrderRFQ memory order,
        bytes memory signature,
        uint256 makingAmount,
        uint256 takingAmount
    ) external returns(uint256, uint256) {
        return fillOrderRFQTo(order, signature, makingAmount, takingAmount, msg.sender);
    }

    function fillOrderRFQToWithPermit(
        OrderRFQ memory order,
        bytes memory signature,
        uint256 makingAmount,
        uint256 takingAmount,
        address target,
        bytes memory permit
    ) external returns(uint256, uint256) {
        _permit(permit);
        return fillOrderRFQTo(order, signature, makingAmount, takingAmount, target);
    }

    function fillOrderRFQTo(
        OrderRFQ memory order,
        bytes memory signature,
        uint256 makingAmount,
        uint256 takingAmount,
        address target
    ) public returns(uint256, uint256) {

        uint256 expiration = uint128(order.info) >> 64;
        require(expiration == 0 || block.timestamp <= expiration, "LOP: order expired");

        {

            address maker = order.makerAssetData.decodeAddress(_FROM_INDEX);
            uint256 invalidatorSlot = uint64(order.info) >> 8;
            uint256 invalidatorBit = 1 << uint8(order.info);
            uint256 invalidator = _invalidator[maker][invalidatorSlot];
            require(invalidator & invalidatorBit == 0, "LOP: already filled");
            _invalidator[maker][invalidatorSlot] = invalidator | invalidatorBit;
        }


        uint256 orderMakerAmount = order.makerAssetData.decodeUint256(_AMOUNT_INDEX);
        uint256 orderTakerAmount = order.takerAssetData.decodeUint256(_AMOUNT_INDEX);
        if (takingAmount == 0 && makingAmount == 0) {

            makingAmount = orderMakerAmount;
            takingAmount = orderTakerAmount;
        }
        else if (takingAmount == 0) {
            takingAmount = (makingAmount.mul(orderTakerAmount).add(orderMakerAmount).sub(1)).div(orderMakerAmount);
        }
        else if (makingAmount == 0) {
            makingAmount = takingAmount.mul(orderMakerAmount).div(orderTakerAmount);
        }
        else {
            revert("LOP: one of amounts should be 0");
        }

        require(makingAmount > 0 && takingAmount > 0, "LOP: can't swap 0 amount");
        require(makingAmount <= orderMakerAmount, "LOP: making amount exceeded");
        require(takingAmount <= orderTakerAmount, "LOP: taking amount exceeded");


        bytes32 orderHash = _hash(order);
        _validate(order.makerAssetData, order.takerAssetData, signature, orderHash);


        _callMakerAssetTransferFrom(order.makerAsset, order.makerAssetData, target, makingAmount);
        _callTakerAssetTransferFrom(order.takerAsset, order.takerAssetData, takingAmount);

        emit OrderFilledRFQ(orderHash, makingAmount);
        return (makingAmount, takingAmount);
    }







    function fillOrder(
        Order memory order,
        bytes calldata signature,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount
    ) external returns(uint256, uint256) {
        return fillOrderTo(order, signature, makingAmount, takingAmount, thresholdAmount, msg.sender);
    }

    function fillOrderToWithPermit(
        Order memory order,
        bytes calldata signature,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount,
        address target,
        bytes memory permit
    ) external returns(uint256, uint256) {
        _permit(permit);
        return fillOrderTo(order, signature, makingAmount, takingAmount, thresholdAmount, target);
    }


    function fillOrderTo(
        Order memory order,
        bytes calldata signature,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 thresholdAmount,
        address target
    ) public returns(uint256, uint256) {
        bytes32 orderHash = _hash(order);

        {
            uint256 remainingMakerAmount;
            {
                bool orderExists;
                (orderExists, remainingMakerAmount) = _remaining[orderHash].trySub(1);
                if (!orderExists) {

                    _validate(order.makerAssetData, order.takerAssetData, signature, orderHash);
                    remainingMakerAmount = order.makerAssetData.decodeUint256(_AMOUNT_INDEX);
                    if (order.permit.length > 0) {
                        _permit(order.permit);
                        require(_remaining[orderHash] == 0, "LOP: reentrancy detected");
                    }
                }
            }


            if (order.predicate.length > 0) {
                require(checkPredicate(order), "LOP: predicate returned false");
            }


            if ((takingAmount == 0) == (makingAmount == 0)) {
                revert("LOP: only one amount should be 0");
            }
            else if (takingAmount == 0) {
                takingAmount = _callGetTakerAmount(order, makingAmount);
                require(takingAmount <= thresholdAmount, "LOP: taking amount too high");
            }
            else {
                makingAmount = _callGetMakerAmount(order, takingAmount);
                require(makingAmount >= thresholdAmount, "LOP: making amount too low");
            }

            require(makingAmount > 0 && takingAmount > 0, "LOP: can't swap 0 amount");


            remainingMakerAmount = remainingMakerAmount.sub(makingAmount, "LOP: taking > remaining");
            _remaining[orderHash] = remainingMakerAmount + 1;
            emit OrderFilled(msg.sender, orderHash, remainingMakerAmount);
        }


        _callTakerAssetTransferFrom(order.takerAsset, order.takerAssetData, takingAmount);



        if (order.interaction.length > 0) {
            InteractiveMaker(order.makerAssetData.decodeAddress(_FROM_INDEX))
                .notifyFillOrder(order.makerAsset, order.takerAsset, makingAmount, takingAmount, order.interaction);
        }


        _callMakerAssetTransferFrom(order.makerAsset, order.makerAssetData, target, makingAmount);

        return (makingAmount, takingAmount);
    }

    function _permit(bytes memory permitData) private {
        (address token, bytes memory permit) = abi.decode(permitData, (address, bytes));
        token.uncheckedFunctionCall(abi.encodePacked(IERC20Permit.permit.selector, permit), "LOP: permit failed");
    }

    function _hash(Order memory order) private view returns(bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    LIMIT_ORDER_TYPEHASH,
                    order.salt,
                    order.makerAsset,
                    order.takerAsset,
                    keccak256(order.makerAssetData),
                    keccak256(order.takerAssetData),
                    keccak256(order.getMakerAmount),
                    keccak256(order.getTakerAmount),
                    keccak256(order.predicate),
                    keccak256(order.permit),
                    keccak256(order.interaction)
                )
            )
        );
    }

    function _hash(OrderRFQ memory order) private view returns(bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    LIMIT_ORDER_RFQ_TYPEHASH,
                    order.info,
                    order.makerAsset,
                    order.takerAsset,
                    keccak256(order.makerAssetData),
                    keccak256(order.takerAssetData)
                )
            )
        );
    }

    function _validate(bytes memory makerAssetData, bytes memory takerAssetData, bytes memory signature, bytes32 orderHash) private view {
        require(makerAssetData.length >= 100, "LOP: bad makerAssetData.length");
        require(takerAssetData.length >= 100, "LOP: bad takerAssetData.length");
        bytes4 makerSelector = makerAssetData.decodeSelector();
        bytes4 takerSelector = takerAssetData.decodeSelector();
        require(makerSelector >= IERC20.transferFrom.selector && makerSelector <= _MAX_SELECTOR, "LOP: bad makerAssetData.selector");
        require(takerSelector >= IERC20.transferFrom.selector && takerSelector <= _MAX_SELECTOR, "LOP: bad takerAssetData.selector");

        address maker = address(makerAssetData.decodeAddress(_FROM_INDEX));
        if ((signature.length != 65 && signature.length != 64) || SilentECDSA.recover(orderHash, signature) != maker) {
            bytes memory result = maker.uncheckedFunctionStaticCall(abi.encodeWithSelector(IERC1271.isValidSignature.selector, orderHash, signature), "LOP: isValidSignature failed");
            require(result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector, "LOP: bad signature");
        }
    }

    function _callMakerAssetTransferFrom(address makerAsset, bytes memory makerAssetData, address taker, uint256 makingAmount) private {

        address orderTakerAddress = makerAssetData.decodeAddress(_TO_INDEX);
        if (orderTakerAddress != address(0)) {
            require(orderTakerAddress == msg.sender, "LOP: private order");
        }
        if (orderTakerAddress != taker) {
            makerAssetData.patchAddress(_TO_INDEX, taker);
        }


        makerAssetData.patchUint256(_AMOUNT_INDEX, makingAmount);

        require(makerAsset != address(0) && makerAsset != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, "LOP: raw ETH is not supported");


        bytes memory result = makerAsset.uncheckedFunctionCall(makerAssetData, "LOP: makerAsset.call failed");
        if (result.length > 0) {
            require(abi.decode(result, (bool)), "LOP: makerAsset.call bad result");
        }
    }

    function _callTakerAssetTransferFrom(address takerAsset, bytes memory takerAssetData, uint256 takingAmount) private {

        takerAssetData.patchAddress(_FROM_INDEX, msg.sender);


        takerAssetData.patchUint256(_AMOUNT_INDEX, takingAmount);

        require(takerAsset != address(0) && takerAsset != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, "LOP: raw ETH is not supported");


        bytes memory result = takerAsset.uncheckedFunctionCall(takerAssetData, "LOP: takerAsset.call failed");
        if (result.length > 0) {
            require(abi.decode(result, (bool)), "LOP: takerAsset.call bad result");
        }
    }

    function _callGetMakerAmount(Order memory order, uint256 takerAmount) private view returns(uint256 makerAmount) {
        if (order.getMakerAmount.length == 0 && takerAmount == order.takerAssetData.decodeUint256(_AMOUNT_INDEX)) {

            return order.makerAssetData.decodeUint256(_AMOUNT_INDEX);
        }

        bytes memory result = address(this).uncheckedFunctionStaticCall(abi.encodePacked(order.getMakerAmount, takerAmount), "LOP: getMakerAmount call failed");
        require(result.length == 32, "LOP: invalid getMakerAmount ret");
        return abi.decode(result, (uint256));
    }

    function _callGetTakerAmount(Order memory order, uint256 makerAmount) private view returns(uint256 takerAmount) {
        if (order.getTakerAmount.length == 0 && makerAmount == order.makerAssetData.decodeUint256(_AMOUNT_INDEX)) {

            return order.takerAssetData.decodeUint256(_AMOUNT_INDEX);
        }
        bytes memory result = address(this).uncheckedFunctionStaticCall(abi.encodePacked(order.getTakerAmount, makerAmount), "LOP: getTakerAmount call failed");
        require(result.length == 32, "LOP: invalid getTakerAmount ret");
        return abi.decode(result, (uint256));
    }
}
