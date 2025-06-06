
pragma solidity ^0.6.0;

import "./StorageSlot.sol";
import "../utils/ExchangeRate.sol";

library EscrowStorageSlot {
    bytes32 internal constant S_LIQUIDTION_DISCOUNT = $$(keccak256('notional.escrow.liquidationDiscount'));
    bytes32 internal constant S_SETTLEMENT_DISCOUNT = $$(keccak256('notional.escrow.settlementDiscount'));
    bytes32 internal constant S_LIQUIDITY_TOKEN_REPO_INCENTIVE = $$(keccak256('notional.escrow.liquidityTokenRepoIncentive'));
    bytes32 internal constant S_LIQUIDITY_HAIRCUT = $$(keccak256('notional.escrow.liquidityHaircut'));

    function _liquidationDiscount() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_LIQUIDTION_DISCOUNT));
    }

    function _settlementDiscount() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_SETTLEMENT_DISCOUNT));
    }

    function _liquidityTokenRepoIncentive() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_LIQUIDITY_TOKEN_REPO_INCENTIVE));
    }

    function _liquidityHaircut() internal view returns (uint128) {
        return uint128(StorageSlot._getStorageUint(S_LIQUIDITY_HAIRCUT));
    }

    function _setLiquidationDiscount(uint128 liquidationDiscount) internal {
        StorageSlot._setStorageUint(S_LIQUIDTION_DISCOUNT, liquidationDiscount);
    }

    function _setSettlementDiscount(uint128 settlementDiscount) internal {
        StorageSlot._setStorageUint(S_SETTLEMENT_DISCOUNT, settlementDiscount);
    }

    function _setLiquidityTokenRepoIncentive(uint128 liquidityTokenRepoIncentive) internal {
        StorageSlot._setStorageUint(S_LIQUIDITY_TOKEN_REPO_INCENTIVE, liquidityTokenRepoIncentive);
    }

    function _setLiquidityHaircut(uint128 liquidityHaircut) internal {
        StorageSlot._setStorageUint(S_LIQUIDITY_HAIRCUT, liquidityHaircut);
    }
}

contract EscrowStorage {

    bytes32 internal constant TOKENS_RECIPIENT_INTERFACE_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;


    address public WETH;


    struct TokenOptions {

        bool isERC777;

        bool hasTransferFee;
    }

    uint16 public maxCurrencyId;
    mapping(uint16 => address) public currencyIdToAddress;
    mapping(uint16 => uint256) public currencyIdToDecimals;
    mapping(address => uint16) public addressToCurrencyId;
    mapping(address => TokenOptions) public tokenOptions;


    mapping(uint16 => mapping(uint16 => ExchangeRate.Rate)) public exchangeRateOracles;


    mapping(uint16 => mapping(address => int256)) public cashBalances;






























