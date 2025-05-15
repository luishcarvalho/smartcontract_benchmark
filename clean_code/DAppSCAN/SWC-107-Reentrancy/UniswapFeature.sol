

















pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";
import "../migrations/LibMigrate.sol";
import "../external/IAllowanceTarget.sol";
import "../fixins/FixinCommon.sol";
import "./IFeature.sol";
import "./IUniswapFeature.sol";



contract UniswapFeature is
    IFeature,
    IUniswapFeature,
    FixinCommon
{

    string public constant override FEATURE_NAME = "UniswapFeature";

    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 1, 0);

    bytes32 public immutable GREEDY_TOKENS_BLOOM_FILTER;

    IEtherTokenV06 private immutable WETH;

    IAllowanceTarget private immutable ALLOWANCE_TARGET;


    uint256 constant private FF_UNISWAP_FACTORY = 0xFF5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f0000000000000000000000;

    uint256 constant private FF_SUSHISWAP_FACTORY = 0xFFC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac0000000000000000000000;

    uint256 constant private UNISWAP_PAIR_INIT_CODE_HASH = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;

    uint256 constant private SUSHISWAP_PAIR_INIT_CODE_HASH = 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;

    uint256 constant private ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    uint256 constant private ETH_TOKEN_ADDRESS_32 = 0x000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    uint256 constant private MAX_SWAP_AMOUNT = 2**112;


    uint256 constant private ALLOWANCE_TARGET_EXECUTE_CALL_SELECTOR_32 = 0xbca8c7b500000000000000000000000000000000000000000000000000000000;

    uint256 constant private UNISWAP_PAIR_RESERVES_CALL_SELECTOR_32 = 0x0902f1ac00000000000000000000000000000000000000000000000000000000;

    uint256 constant private UNISWAP_PAIR_SWAP_CALL_SELECTOR_32 = 0x022c0d9f00000000000000000000000000000000000000000000000000000000;

    uint256 constant private TRANSFER_FROM_CALL_SELECTOR_32 = 0x23b872dd00000000000000000000000000000000000000000000000000000000;

    uint256 constant private ALLOWANCE_CALL_SELECTOR_32 = 0xdd62ed3e00000000000000000000000000000000000000000000000000000000;

    uint256 constant private WETH_WITHDRAW_CALL_SELECTOR_32 = 0x2e1a7d4d00000000000000000000000000000000000000000000000000000000;

    uint256 constant private WETH_DEPOSIT_CALL_SELECTOR_32 = 0xd0e30db000000000000000000000000000000000000000000000000000000000;

    uint256 constant private ERC20_TRANSFER_CALL_SELECTOR_32 = 0xa9059cbb00000000000000000000000000000000000000000000000000000000;





    constructor(
        IEtherTokenV06 weth,
        IAllowanceTarget allowanceTarget,
        bytes32 greedyTokensBloomFilter
    ) public {
        WETH = weth;
        ALLOWANCE_TARGET = allowanceTarget;
        GREEDY_TOKENS_BLOOM_FILTER = greedyTokensBloomFilter;
    }




    function migrate()
        external
        returns (bytes4 success)
    {
        _registerFeatureFunction(this.sellToUniswap.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }







    function sellToUniswap(
        IERC20TokenV06[] calldata tokens,
        uint256 sellAmount,
        uint256 minBuyAmount,
        bool isSushi
    )
        external
        payable
        override
        returns (uint256 buyAmount)
    {
        require(tokens.length > 1, "UniswapFeature/InvalidTokensLength");
        {

            IEtherTokenV06 weth = WETH;
            IAllowanceTarget allowanceTarget = ALLOWANCE_TARGET;
            bytes32 greedyTokensBloomFilter = GREEDY_TOKENS_BLOOM_FILTER;


            assembly {

                mstore(0xA00, add(calldataload(0x04), 0x24))

                mstore(0xA20, isSushi)

                mstore(0xA40, weth)

                mstore(0xA60, allowanceTarget)

                mstore(0xA80, greedyTokensBloomFilter)
            }
        }

        assembly {

            let numPairs := sub(calldataload(add(calldataload(0x04), 0x4)), 1)


            buyAmount := sellAmount
            let buyToken
            let nextPair := 0

            for {let i := 0} lt(i, numPairs) {i := add(i, 1)} {

                let sellToken := loadTokenAddress(i)

                buyToken := loadTokenAddress(add(i, 1))

                let pairOrder := lt(normalizeToken(sellToken), normalizeToken(buyToken))



                let pair := nextPair
                if iszero(pair) {
                    pair := computePairAddress(sellToken, buyToken)
                    nextPair := 0
                }

                if iszero(i) {
                    switch eq(sellToken, ETH_TOKEN_ADDRESS_32)
                        case 0 {


                            moveTakerTokensTo(sellToken, pair, sellAmount)
                        }
                        default {


                            if iszero(eq(callvalue(), sellAmount)) {
                                revert(0, 0)
                            }
                            sellToken := mload(0xA40)

                            mstore(0xB00, WETH_DEPOSIT_CALL_SELECTOR_32)
                            if iszero(call(gas(), sellToken, sellAmount, 0xB00, 0x4, 0x00, 0x0)) {
                                bubbleRevert()
                            }

                            mstore(0xB00, ERC20_TRANSFER_CALL_SELECTOR_32)
                            mstore(0xB04, pair)
                            mstore(0xB24, sellAmount)
                            if iszero(call(gas(), sellToken, 0, 0xB00, 0x44, 0x00, 0x0)) {
                                bubbleRevert()
                            }
                        }



                }



                mstore(0xB00, UNISWAP_PAIR_RESERVES_CALL_SELECTOR_32)
                if iszero(staticcall(gas(), pair, 0xB00, 0x4, 0xC00, 0x40)) {
                    bubbleRevert()
                }


                let pairSellAmount := buyAmount

                {
                    let sellReserve
                    let buyReserve
                    switch iszero(pairOrder)
                        case 0 {

                            sellReserve := mload(0xC00)
                            buyReserve := mload(0xC20)
                        }
                        default {
                            sellReserve := mload(0xC20)
                            buyReserve := mload(0xC00)
                        }

                    if gt(pairSellAmount, MAX_SWAP_AMOUNT) {
                        revert(0, 0)
                    }



                    let sellAmountWithFee := mul(pairSellAmount, 997)
                    buyAmount := div(
                        mul(sellAmountWithFee, buyReserve),
                        add(sellAmountWithFee, mul(sellReserve, 1000))
                    )
                }

                let receiver

                switch eq(add(i, 1), numPairs)
                    case 0 {


                        nextPair := computePairAddress(
                            buyToken,
                            loadTokenAddress(add(i, 2))
                        )
                        receiver := nextPair
                    }
                    default {


                        switch eq(buyToken, ETH_TOKEN_ADDRESS_32)
                            case 0 {
                                receiver := caller()
                            }
                            default {
                                receiver := address()
                            }
                    }


                mstore(0xB00, UNISWAP_PAIR_SWAP_CALL_SELECTOR_32)
                switch pairOrder
                    case 0 {
                        mstore(0xB04, buyAmount)
                        mstore(0xB24, 0)
                    }
                    default {
                        mstore(0xB04, 0)
                        mstore(0xB24, buyAmount)
                    }
                mstore(0xB44, receiver)
                mstore(0xB64, 0x80)
                mstore(0xB84, 0)
                if iszero(call(gas(), pair, 0, 0xB00, 0xA4, 0, 0)) {
                    bubbleRevert()
                }
            }


            if eq(buyToken, ETH_TOKEN_ADDRESS_32) {

                mstore(0xB00, WETH_WITHDRAW_CALL_SELECTOR_32)
                mstore(0xB04, buyAmount)
                if iszero(call(gas(), mload(0xA40), 0, 0xB00, 0x24, 0x00, 0x0)) {
                    bubbleRevert()
                }

                if iszero(call(gas(), caller(), buyAmount, 0xB00, 0x0, 0x00, 0x0)) {
                    bubbleRevert()
                }
            }




            function loadTokenAddress(idx) -> addr {
                addr := and(ADDRESS_MASK, calldataload(add(mload(0xA00), mul(idx, 0x20))))
            }


            function normalizeToken(token) -> normalized {
                normalized := token

                if eq(token, ETH_TOKEN_ADDRESS_32) {
                    normalized := mload(0xA40)
                }
            }



            function computePairAddress(tokenA, tokenB) -> pair {

                tokenA := normalizeToken(tokenA)
                tokenB := normalizeToken(tokenB)

















                switch lt(tokenA, tokenB)
                    case 0 {
                        mstore(0xB14, tokenA)
                        mstore(0xB00, tokenB)
                    }
                    default {
                        mstore(0xB14, tokenB)
                        mstore(0xB00, tokenA)
                    }
                let salt := keccak256(0xB0C, 0x28)

                switch mload(0xA20)
                    case 0 {
                        mstore(0xB00, FF_UNISWAP_FACTORY)
                        mstore(0xB15, salt)
                        mstore(0xB35, UNISWAP_PAIR_INIT_CODE_HASH)
                    }
                    default {
                        mstore(0xB00, FF_SUSHISWAP_FACTORY)
                        mstore(0xB15, salt)
                        mstore(0xB35, SUSHISWAP_PAIR_INIT_CODE_HASH)
                    }
                pair := and(ADDRESS_MASK, keccak256(0xB00, 0x55))
            }


            function bubbleRevert() {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }


            function moveTakerTokensTo(token, to, amount) {





                if isTokenPossiblyGreedy(token) {


                    mstore(0xB00, ALLOWANCE_CALL_SELECTOR_32)
                    mstore(0xB04, caller())
                    mstore(0xB24, address())
                    let success := call(gas(), token, 0, 0xB00, 0x44, 0xC00, 0x20)
                    if iszero(success) {

                        bubbleRevert()
                    }


                    if lt(mload(0xC00), amount) {


                        moveTakerTokensToWithLegacyAllowanceTarget(token, to, amount)
                        leave
                    }
                }



                mstore(0xB00, TRANSFER_FROM_CALL_SELECTOR_32)
                mstore(0xB04, caller())
                mstore(0xB24, to)
                mstore(0xB44, amount)

                let success := call(


                    gas(),
                    token,
                    0,
                    0xB00,
                    0x64,
                    0xC00,




                    0x20
                )

                let rdsize := returndatasize()






                success := and(
                    success,
                    or(
                        iszero(rdsize),
                        and(
                            iszero(lt(rdsize, 32)),
                            eq(mload(0xC00), 1)
                        )
                    )
                )

                if iszero(success) {

                    moveTakerTokensToWithLegacyAllowanceTarget(token, to, amount)
                }
            }


            function moveTakerTokensToWithLegacyAllowanceTarget(token, to, amount) {
                mstore(0xB00, ALLOWANCE_TARGET_EXECUTE_CALL_SELECTOR_32)
                mstore(0xB04, token)
                mstore(0xB24, 0x40)
                mstore(0xB44, 0x64)
                mstore(0xB64, TRANSFER_FROM_CALL_SELECTOR_32)
                mstore(0xB68, caller())
                mstore(0xB88, to)
                mstore(0xBA8, amount)
                if iszero(call(gas(), mload(0xA60), 0, 0xB00, 0xC8, 0x00, 0x0)) {
                    bubbleRevert()
                }


            }



            function isTokenPossiblyGreedy(token) -> isPossiblyGreedy {


                mstore(0, token)
                let h := or(shl(mod(keccak256(0, 32), 256), 1), shl(mod(token, 256), 1))
                isPossiblyGreedy := eq(and(h, mload(0xA80)), h)
            }
        }



        require(buyAmount >= minBuyAmount, "UniswapFeature/UnderBought");
    }
}
