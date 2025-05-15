
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./utils/Common.sol";
import "./utils/ERC1155Base.sol";

import "./interface/IERC1155TokenReceiver.sol";

import "./CashMarket.sol";







contract ERC1155Token is ERC1155Base {
















    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override {
        _transfer(from, to, id, value);
        emit TransferSingle(msg.sender, from, to, id, value);


        uint256 codeSize;

        assembly {
            codeSize := extcodesize(to)
        }
        if (codeSize > 0) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, value, data) == ERC1155_ACCEPTED,
                $$(ErrorCode(ERC1155_NOT_ACCEPTED))
            );
        }
    }
















    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        for (uint256 i; i < ids.length; i++) {
            _transfer(from, to, ids[i], values[i]);
        }

        emit TransferBatch(msg.sender, from, to, ids, values);


        uint256 codeSize;

        assembly {
            codeSize := extcodesize(to)
        }
        if (codeSize > 0) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, values, data) ==
                    ERC1155_BATCH_ACCEPTED,
                $$(ErrorCode(ERC1155_NOT_ACCEPTED))
            );
        }
    }












    function _transfer(
        address from,
        address to,
        uint256 id,
        uint256 _value
    ) internal {
        require(to != address(0), $$(ErrorCode(INVALID_ADDRESS)));
        uint128 value = uint128(_value);
        require(uint256(value) == _value, $$(ErrorCode(INTEGER_OVERFLOW)));
        require(msg.sender == from || isApprovedForAll(from, msg.sender), $$(ErrorCode(UNAUTHORIZED_CALLER)));

        bytes1 assetType = Common.getAssetType(id);

        require(Common.isReceiver(assetType), $$(ErrorCode(CANNOT_TRANSFER_PAYER)));

        (uint8 cashGroupId, uint16 instrumentId, uint32 maturity) = Common.decodeAssetId(id);
        require(maturity > block.timestamp, $$(ErrorCode(CANNOT_TRANSFER_MATURED_ASSET)));

        Portfolios().transferAccountAsset(
            from,
            to,
            assetType,
            cashGroupId,
            instrumentId,
            maturity,
            value
        );
    }
}
