

pragma solidity 0.6.12;

import "./lib/InstantWithdrawManager.sol";
import "./interfaces/VerifierRollupInterface.sol";
import "./interfaces/VerifierWithdrawInterface.sol";
import "./interfaces/AuctionInterface.sol";

contract Hermez is InstantWithdrawManager {
    struct VerifierRollup {
        VerifierRollupInterface verifierInterface;
        uint256 maxTx;
        uint256 nLevels;
    }




    bytes4 constant _TRANSFER_SIGNATURE = 0xa9059cbb;


    bytes4 constant _TRANSFER_FROM_SIGNATURE = 0x23b872dd;


    bytes4 constant _APPROVE_SIGNATURE = 0x095ea7b3;




    bytes4 constant _PERMIT_SIGNATURE = 0xd505accf;


    uint48 constant _RESERVED_IDX = 255;


    uint48 constant _EXIT_IDX = 1;


    uint256 constant _LIMIT_LOAD_AMOUNT = (1 << 128);


    uint256 constant _LIMIT_L2TRANSFER_AMOUNT = (1 << 192);


    uint256 constant _LIMIT_TOKENS = (1 << 32);


    uint256 constant _L1_COORDINATOR_TOTALBYTES = 101;



    uint256 constant _L1_USER_TOTALBYTES = 72;








    uint256 constant _MAX_L1_USER_TX = 128;


    uint256 constant _MAX_L1_TX = 256;


    uint256 constant _RFIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;





    uint256 constant _INPUT_SHA_CONSTANT_BYTES = 18542;

    uint8 public constant ABSOLUTE_MAX_L1L2BATCHTIMEOUT = 240;




    address constant _ETH_ADDRESS_INTERNAL_ONLY = address(
        0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF
    );


    VerifierRollup[] public rollupVerifiers;


    VerifierWithdrawInterface public withdrawVerifier;


    uint48 public lastIdx;


    uint64 public lastForgedBatch;


    mapping(uint64 => uint256) public stateRootMap;


    mapping(uint64 => uint256) public exitRootsMap;



    mapping(uint64 => mapping(uint48 => bool)) public exitNullifierMap;



    address[] public tokenList;


    mapping(address => uint256) public tokenMap;


    uint256 public feeAddToken;


    AuctionInterface public hermezAuctionContract;



    mapping(uint64 => bytes) public mapL1TxQueue;


    uint64 public lastL1L2Batch;


    uint64 public nextL1ToForgeQueue;


    uint64 public nextL1FillingQueue;


    uint8 public forgeL1L2BatchTimeout;


    address public tokenHEZ;


    event L1UserTxEvent(
        uint64 indexed queueIndex,
        uint8 indexed position,
        bytes l1UserTx
    );


    event AddToken(address indexed tokenAddress, uint32 tokenID);


    event ForgeBatch(uint64 indexed batchNum);


    event UpdateForgeL1L2BatchTimeout(uint8 newForgeL1L2BatchTimeout);


    event UpdateFeeAddToken(uint256 newFeeAddToken);


    event WithdrawEvent(
        uint48 indexed idx,
        uint48 indexed numExitRoot,
        bool indexed instantWithdraw
    );






    function initializeHermez(
        address[] memory _verifiers,
        uint256[] memory _verifiersParams,
        address _withdrawVerifier,
        address _hermezAuctionContract,
        address _tokenHEZ,
        uint8 _forgeL1L2BatchTimeout,
        uint256 _feeAddToken,
        address _poseidon2Elements,
        address _poseidon3Elements,
        address _poseidon4Elements,
        address _hermezGovernanceDAOAddress,
        address _safetyAddress,
        uint64 _withdrawalDelay,
        address _withdrawDelayerContract
    ) external initializer {

        _initializeVerifiers(_verifiers, _verifiersParams);
        withdrawVerifier = VerifierWithdrawInterface(_withdrawVerifier);
        hermezAuctionContract = AuctionInterface(_hermezAuctionContract);
        tokenHEZ = _tokenHEZ;
        forgeL1L2BatchTimeout = _forgeL1L2BatchTimeout;
        feeAddToken = _feeAddToken;


        lastIdx = _RESERVED_IDX;


        nextL1FillingQueue = 1;

        tokenList.push(address(0));


        _initializeHelpers(
            _poseidon2Elements,
            _poseidon3Elements,
            _poseidon4Elements
        );
        _initializeWithdraw(
            _hermezGovernanceDAOAddress,
            _safetyAddress,
            _withdrawalDelay,
            _withdrawDelayerContract
        );
    }























    function forgeBatch(
        uint48 newLastIdx,
        uint256 newStRoot,
        uint256 newExitRoot,
        bytes calldata encodedL1CoordinatorTx,
        bytes calldata l2TxsData,
        bytes calldata feeIdxCoordinator,
        uint8 verifierIdx,
        bool l1Batch,
        uint256[2] calldata proofA,
        uint256[2][2] calldata proofB,
        uint256[2] calldata proofC
    ) external virtual {




        require(
            msg.sender == tx.origin,
            "Hermez::forgeBatch: INTENAL_TX_NOT_ALLOWED"
        );


        require(
            hermezAuctionContract.canForge(msg.sender, block.number) == true,
            "Hermez::forgeBatch: AUCTION_DENIED"
        );

        if (!l1Batch) {
            require(
                block.number < (lastL1L2Batch + forgeL1L2BatchTimeout),
                "Hermez::forgeBatch: L1L2BATCH_REQUIRED"
            );
        }


        uint256 input = _constructCircuitInput(
            newLastIdx,
            newStRoot,
            newExitRoot,
            l1Batch,
            verifierIdx
        );


        require(
            rollupVerifiers[verifierIdx].verifierInterface.verifyProof(
                proofA,
                proofB,
                proofC,
                [input]
            ),
            "Hermez::forgeBatch: INVALID_PROOF"
        );


        lastForgedBatch++;
        lastIdx = newLastIdx;
        stateRootMap[lastForgedBatch] = newStRoot;
        exitRootsMap[lastForgedBatch] = newExitRoot;

        if (l1Batch) {

            lastL1L2Batch = uint64(block.number);

            _clearQueue();
        }


        hermezAuctionContract.forge(msg.sender);

        emit ForgeBatch(lastForgedBatch);
    }































    function addL1Transaction(
        uint256 babyPubKey,
        uint48 fromIdx,
        uint16 loadAmountF,
        uint16 amountF,
        uint32 tokenID,
        uint48 toIdx,
        bytes calldata permit
    ) external payable {

        require(
            tokenID < tokenList.length,
            "Hermez::addL1Transaction: TOKEN_NOT_REGISTERED"
        );


        uint256 loadAmount = _float2Fix(loadAmountF);
        require(
            loadAmount < _LIMIT_LOAD_AMOUNT,
            "Hermez::addL1Transaction: LOADAMOUNT_EXCEED_LIMIT"
        );


        if (loadAmount > 0) {
            if (tokenID == 0) {
                require(
                    loadAmount == msg.value,
                    "Hermez::addL1Transaction: LOADAMOUNT_DOES_NOT_MATCH"
                );
            } else {
                if (permit.length != 0) {
                    _permit(tokenList[tokenID], loadAmount, permit);
                }
                _safeTransferFrom(
                    tokenList[tokenID],
                    msg.sender,
                    address(this),
                    loadAmount
                );
            }
        }


        _addL1Transaction(
            msg.sender,
            babyPubKey,
            fromIdx,
            loadAmountF,
            amountF,
            tokenID,
            toIdx
        );
    }












    function _addL1Transaction(
        address ethAddress,
        uint256 babyPubKey,
        uint48 fromIdx,
        uint16 loadAmountF,
        uint16 amountF,
        uint32 tokenID,
        uint48 toIdx
    ) internal {
        uint256 amount = _float2Fix(amountF);
        require(
            amount < _LIMIT_L2TRANSFER_AMOUNT,
            "Hermez::_addL1Transaction: AMOUNT_EXCEED_LIMIT"
        );


        if (toIdx == 0) {
            require(
                (amount == 0),
                "Hermez::_addL1Transaction: AMOUNT_MUST_BE_0_IF_NOT_TRANSFER"
            );
        } else {
            if ((toIdx == _EXIT_IDX)) {
                require(
                    (loadAmountF == 0),
                    "Hermez::_addL1Transaction: LOADAMOUNT_MUST_BE_0_IF_EXIT"
                );
            } else {
                require(
                    ((toIdx > _RESERVED_IDX) && (toIdx <= lastIdx)),
                    "Hermez::_addL1Transaction: INVALID_TOIDX"
                );
            }
        }

        if (fromIdx == 0) {
            require(
                babyPubKey != 0,
                "Hermez::_addL1Transaction: INVALID_CREATE_ACCOUNT_WITH_NO_BABYJUB"
            );
        } else {
            require(
                (fromIdx > _RESERVED_IDX) && (fromIdx <= lastIdx),
                "Hermez::_addL1Transaction: INVALID_FROMIDX"
            );
            require(
                babyPubKey == 0,
                "Hermez::_addL1Transaction: BABYJUB_MUST_BE_0_IF_NOT_CREATE_ACCOUNT"
            );
        }

        _l1QueueAddTx(
            ethAddress,
            babyPubKey,
            fromIdx,
            loadAmountF,
            amountF,
            tokenID,
            toIdx
        );
    }

















    function withdrawMerkleProof(
        uint32 tokenID,
        uint192 amount,
        uint256 babyPubKey,
        uint48 numExitRoot,
        uint256[] memory siblings,
        uint48 idx,
        bool instantWithdraw
    ) external {



        if (instantWithdraw) {
            require(
                _processInstantWithdrawal(tokenList[tokenID], amount),
                "Hermez::withdrawMerkleProof: INSTANT_WITHDRAW_WASTED_FOR_THIS_USD_RANGE"
            );
        }


        uint256[] memory arrayState = _buildTreeState(
            tokenID,
            0,
            amount,
            babyPubKey,
            msg.sender
        );
        uint256 stateHash = _hash4Elements(arrayState);

        uint256 exitRoot = exitRootsMap[numExitRoot];

        require(
            exitNullifierMap[numExitRoot][idx] == false,
            "Hermez::withdrawMerkleProof: WITHDRAW_ALREADY_DONE"
        );

        require(
            _smtVerifier(exitRoot, siblings, idx, stateHash) == true,
            "Hermez::withdrawMerkleProof: SMT_PROOF_INVALID"
        );


        exitNullifierMap[numExitRoot][idx] = true;

        _withdrawFunds(amount, tokenID, instantWithdraw);

        emit WithdrawEvent(idx, numExitRoot, instantWithdraw);
    }














    function withdrawCircuit(
        uint256[2] calldata proofA,
        uint256[2][2] calldata proofB,
        uint256[2] calldata proofC,
        uint32 tokenID,
        uint192 amount,
        uint48 numExitRoot,
        uint48 idx,
        bool instantWithdraw
    ) external {

        if (instantWithdraw) {
            require(
                _processInstantWithdrawal(tokenList[tokenID], amount),
                "Hermez::withdrawCircuit: INSTANT_WITHDRAW_WASTED_FOR_THIS_USD_RANGE"
            );
        }
        require(
            exitNullifierMap[numExitRoot][idx] == false,
            "Hermez::withdrawCircuit: WITHDRAW_ALREADY_DONE"
        );


        uint256 exitRoot = exitRootsMap[numExitRoot];

        uint256 input = uint256(
            sha256(abi.encodePacked(exitRoot, msg.sender, tokenID, amount, idx))
        ) % _RFIELD;

        require(
            withdrawVerifier.verifyProof(proofA, proofB, proofC, [input]) ==
                true,
            "Hermez::withdrawCircuit: INVALID_ZK_PROOF"
        );


        exitNullifierMap[numExitRoot][idx] = true;

        _withdrawFunds(amount, tokenID, instantWithdraw);

        emit WithdrawEvent(idx, numExitRoot, instantWithdraw);
    }









    function updateForgeL1L2BatchTimeout(uint8 newForgeL1L2BatchTimeout)
        external
        onlyGovernance
    {
        require(
            newForgeL1L2BatchTimeout <= ABSOLUTE_MAX_L1L2BATCHTIMEOUT,
            "Hermez::updateForgeL1L2BatchTimeout: MAX_FORGETIMEOUT_EXCEED"
        );
        forgeL1L2BatchTimeout = newForgeL1L2BatchTimeout;
        emit UpdateForgeL1L2BatchTimeout(newForgeL1L2BatchTimeout);
    }






    function updateFeeAddToken(uint256 newFeeAddToken) external onlyGovernance {
        feeAddToken = newFeeAddToken;
        emit UpdateFeeAddToken(newFeeAddToken);
    }









    function registerTokensCount() public view returns (uint256) {
        return tokenList.length;
    }











    function addToken(address tokenAddress, bytes calldata permit) public {
        uint256 currentTokens = tokenList.length;
        require(
            currentTokens < _LIMIT_TOKENS,
            "Hermez::addToken: TOKEN_LIST_FULL"
        );
        require(
            tokenAddress != address(0),
            "Hermez::addToken: ADDRESS_0_INVALID"
        );
        require(tokenMap[tokenAddress] == 0, "Hermez::addToken: ALREADY_ADDED");


        if (permit.length != 0) {
            _permit(tokenHEZ, feeAddToken, permit);
        }
        _safeTransferFrom(tokenHEZ, msg.sender, address(this), feeAddToken);

        tokenList.push(tokenAddress);
        tokenMap[tokenAddress] = currentTokens;

        emit AddToken(tokenAddress, uint32(currentTokens));
    }







    function _initializeVerifiers(
        address[] memory _verifiers,
        uint256[] memory _verifiersParams
    ) internal {
        for (uint256 i = 0; i < _verifiers.length; i++) {
            rollupVerifiers.push(
                VerifierRollup({
                    verifierInterface: VerifierRollupInterface(_verifiers[i]),
                    maxTx: (_verifiersParams[i] << 8) >> 8,
                    nLevels: _verifiersParams[i] >> (256 - 8)
                })
            );
        }
    }














    function _l1QueueAddTx(
        address ethAddress,
        uint256 babyPubKey,
        uint48 fromIdx,
        uint16 loadAmountF,
        uint16 amountF,
        uint32 tokenID,
        uint48 toIdx
    ) internal {
        bytes memory l1Tx = abi.encodePacked(
            ethAddress,
            babyPubKey,
            fromIdx,
            loadAmountF,
            amountF,
            tokenID,
            toIdx
        );


        _concatStorage(mapL1TxQueue[nextL1FillingQueue], l1Tx);

        uint256 lastPosition = mapL1TxQueue[nextL1FillingQueue].length /
            _L1_USER_TOTALBYTES;

        emit L1UserTxEvent(nextL1FillingQueue, uint8(lastPosition), l1Tx);
        if (lastPosition >= _MAX_L1_USER_TX) {
            nextL1FillingQueue++;
        }
    }








    function _buildL1Data(uint256 ptr, bool l1Batch) internal view {
        uint256 dPtr;
        uint256 dLen;

        (dPtr, dLen) = _getCallData(3);
        uint256 l1CoordinatorLength = dLen / _L1_COORDINATOR_TOTALBYTES;

        uint256 l1UserLength;
        bytes memory l1UserTxQueue;
        if (l1Batch) {
            l1UserTxQueue = mapL1TxQueue[nextL1ToForgeQueue];
            l1UserLength = l1UserTxQueue.length / _L1_USER_TOTALBYTES;
        } else {
            l1UserLength = 0;
        }

        require(
            l1UserLength + l1CoordinatorLength <= _MAX_L1_TX,
            "Hermez::_buildL1Data: L1_TX_OVERFLOW"
        );

        if (l1UserLength > 0) {

            assembly {
                let ptrFrom := add(l1UserTxQueue, 0x20)
                let ptrTo := ptr
                ptr := add(ptr, mul(l1UserLength, _L1_USER_TOTALBYTES))
                for {

                } lt(ptrTo, ptr) {
                    ptrTo := add(ptrTo, 32)
                    ptrFrom := add(ptrFrom, 32)
                } {
                    mstore(ptrTo, mload(ptrFrom))
                }
            }
        }

        for (uint256 i = 0; i < l1CoordinatorLength; i++) {
            uint8 v;
            bytes32 s;
            bytes32 r;
            bytes32 babyPubKey;
            uint256 tokenID;

            assembly {
                v := byte(0, calldataload(dPtr))
                dPtr := add(dPtr, 1)

                s := calldataload(dPtr)
                dPtr := add(dPtr, 32)

                r := calldataload(dPtr)
                dPtr := add(dPtr, 32)

                babyPubKey := calldataload(dPtr)
                dPtr := add(dPtr, 32)

                tokenID := shr(224, calldataload(dPtr))
                dPtr := add(dPtr, 4)
            }

            require(
                tokenID < tokenList.length,
                "Hermez::_buildL1Data: TOKEN_NOT_REGISTERED"
            );

            address ethAddress = _ETH_ADDRESS_INTERNAL_ONLY;


            if (v != 0) {
                ethAddress = _checkSig(babyPubKey, r, s, v);
            }


            assembly {
                mstore(ptr, shl(96, ethAddress))
                ptr := add(ptr, 20)

                mstore(ptr, babyPubKey)
                ptr := add(ptr, 32)

                mstore(ptr, 0)



                ptr := add(ptr, 10)

                mstore(ptr, shl(224, tokenID))
                ptr := add(ptr, 4)

                mstore(ptr, 0)
                ptr := add(ptr, 6)
            }
        }

        _fillZeros(
            ptr,
            (_MAX_L1_TX - l1UserLength - l1CoordinatorLength) *
                _L1_USER_TOTALBYTES
        );
    }









    function _constructCircuitInput(
        uint48 newLastIdx,
        uint256 newStRoot,
        uint256 newExitRoot,
        bool l1Batch,
        uint8 verifierIdx
    ) internal view returns (uint256) {
        uint256 oldStRoot = stateRootMap[lastForgedBatch];
        uint256 oldLastIdx = lastIdx;
        uint256 dPtr;
        uint256 dLen;




        uint256 l2TxsDataLength = ((rollupVerifiers[verifierIdx].nLevels / 8) *
            2 +
            3) * rollupVerifiers[verifierIdx].maxTx;


        uint256 feeIdxCoordinatorLength = (rollupVerifiers[verifierIdx]
            .nLevels / 8) * 64;












        bytes memory inputBytes;

        uint256 ptr;

        assembly {
            let inputBytesLength := add(
                add(_INPUT_SHA_CONSTANT_BYTES, l2TxsDataLength),
                feeIdxCoordinatorLength
            )


            inputBytes := mload(0x40)


            mstore(0x40, add(add(inputBytes, 0x40), inputBytesLength))


            mstore(inputBytes, inputBytesLength)


            ptr := add(inputBytes, 32)

            mstore(ptr, shl(208, oldLastIdx))
            ptr := add(ptr, 6)

            mstore(ptr, shl(208, newLastIdx))
            ptr := add(ptr, 6)

            mstore(ptr, oldStRoot)
            ptr := add(ptr, 32)

            mstore(ptr, newStRoot)
            ptr := add(ptr, 32)

            mstore(ptr, newExitRoot)
            ptr := add(ptr, 32)
        }


        _buildL1Data(ptr, l1Batch);
        ptr += _MAX_L1_TX * _L1_USER_TOTALBYTES;


        (dPtr, dLen) = _getCallData(4);
        require(
            dLen <= l2TxsDataLength,
            "Hermez::_constructCircuitInput: L2_TX_OVERFLOW"
        );
        assembly {
            calldatacopy(ptr, dPtr, dLen)
        }
        ptr += dLen;
        _fillZeros(ptr, l2TxsDataLength - dLen);
        ptr += l2TxsDataLength - dLen;


        (dPtr, dLen) = _getCallData(5);
        require(
            dLen == feeIdxCoordinatorLength,
            "Hermez::_constructCircuitInput: INVALID_FEEIDXCOORDINATOR_LENGTH"
        );
        assembly {
            calldatacopy(ptr, dPtr, dLen)
        }
        ptr += dLen;
        _fillZeros(ptr, feeIdxCoordinatorLength - dLen);
        ptr += feeIdxCoordinatorLength - dLen;


        assembly {
            mstore(ptr, shl(240, chainid()))
        }

        return uint256(sha256(inputBytes)) % _RFIELD;
    }




    function _clearQueue() internal {
        delete mapL1TxQueue[nextL1ToForgeQueue];
        nextL1ToForgeQueue++;
        if (nextL1ToForgeQueue == nextL1FillingQueue) {
            nextL1FillingQueue++;
        }
    }







    function _withdrawFunds(
        uint192 amount,
        uint32 tokenID,
        bool instantWithdraw
    ) internal {
        if (instantWithdraw) {
            _safeTransfer(tokenList[tokenID], msg.sender, amount);
        } else {
            if (tokenID == 0) {
                withdrawDelayerContract.deposit{value: amount}(
                    msg.sender,
                    address(0),
                    amount
                );
            } else {
                address tokenAddress = tokenList[tokenID];

                _safeApprove(
                    tokenAddress,
                    address(withdrawDelayerContract),
                    amount
                );

                withdrawDelayerContract.deposit(
                    msg.sender,
                    tokenAddress,
                    amount
                );
            }
        }
    }











    function _safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
















    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {

        if (token == address(0)) {























    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(_TRANSFER_FROM_SIGNATURE, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Hermez::_safeTransferFrom: ERC20_TRANSFERFROM_FAILED"
        );
    }










    function _permit(
        address token,
        uint256 _amount,
        bytes calldata _permitData
    ) internal {
        bytes4 sig = abi.decode(_permitData, (bytes4));
        require(
            sig == _PERMIT_SIGNATURE,
            "HermezAuctionProtocol::_permit: NOT_VALID_CALL"
        );
        (
            address owner,
            address spender,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = abi.decode(
            _permitData[4:],
            (address, address, uint256, uint256, uint8, bytes32, bytes32)
        );
        require(
            owner == msg.sender,
            "Hermez::_permit: PERMIT_OWNER_MUST_BE_THE_SENDER"
        );
        require(
            spender == address(this),
            "Hermez::_permit: SPENDER_MUST_BE_THIS"
        );
        require(
            value == _amount,
            "Hermez::_permit: PERMIT_AMOUNT_DOES_NOT_MATCH"
        );



















