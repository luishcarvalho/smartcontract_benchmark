

pragma solidity >=0.6.10 <=0.8.10;
pragma experimental ABIEncoderV2;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IVault, IAsset, PoolSpecialization} from './interfaces/IVault.sol';
import {IPool} from './interfaces/IPool.sol';
import {ITranche} from './interfaces/ITranche.sol';
import {IDeploymentValidator} from './interfaces/IDeploymentValidator.sol';
import {IERC20Permit, IERC20} from '../../interfaces/IERC20Permit.sol';
import {IWrappedPosition} from './interfaces/IWrappedPosition.sol';
import {IRollupProcessor} from '../../interfaces/IRollupProcessor.sol';
import {MinHeap} from './MinHeap.sol';

import {IDefiBridge} from '../../interfaces/IDefiBridge.sol';

import {AztecTypes} from '../../aztec/AztecTypes.sol';






contract ElementBridge is IDefiBridge {
    using MinHeap for MinHeap.MinHeapData;




    error INVALID_TRANCHE();
    error INVALID_WRAPPED_POSITION();
    error INVALID_POOL();
    error INVALID_CALLER();
    error ASSET_IDS_NOT_EQUAL();
    error ASSET_NOT_ERC20();
    error INTERACTION_ALREADY_EXISTS();
    error POOL_NOT_FOUND();
    error UNKNOWN_NONCE();
    error BRIDGE_NOT_READY();
    error ALREADY_FINALISED();
    error TRANCHE_POSITION_MISMATCH();
    error TRANCHE_UNDERLYING_MISMATCH();
    error POOL_UNDERLYING_MISMATCH();
    error POOL_EXPIRY_MISMATCH();
    error TRANCHE_EXPIRY_MISMATCH();
    error VAULT_ADDRESS_VERIFICATION_FAILED();
    error VAULT_ADDRESS_MISMATCH();
    error TRANCHE_ALREADY_EXPIRED();
    error UNREGISTERED_POOL();
    error UNREGISTERED_POSITION();
    error UNREGISTERED_PAIR();













    struct Interaction {
        uint256 quantityPT;
        address trancheAddress;
        uint64 expiry;
        bool finalised;
        bool failed;
    }









    struct Pool {
        bytes32 poolId;
        address trancheAddress;
        address poolAddress;
        address wrappedPositionAddress;
    }

    enum TrancheRedemptionStatus { NOT_REDEEMED, REDEMPTION_FAILED, REDEMPTION_SUCCEEDED }











    struct TrancheAccount {
        uint256 quantityTokensHeld;
        uint256 quantityAssetRedeemed;
        uint256 quantityAssetRemaining;
        uint32 numDeposits;
        uint32 numFinalised;
        TrancheRedemptionStatus redemptionStatus;
    }


    address private immutable trancheFactory;


    bytes32 private immutable trancheBytecodeHash;


    mapping(uint256 => Interaction) public interactions;


    mapping(address => uint64[]) public assetToExpirys;


    mapping(uint256 => Pool) public pools;


    mapping(address => TrancheAccount) private trancheAccounts;


    mapping (address => uint256) private trancheDeploymentBlockNumbers;


    address public immutable rollupProcessor;


    address private immutable balancerAddress;


    address private immutable elementDeploymentValidatorAddress;


    MinHeap.MinHeapData private heap;
    mapping(uint64 => uint256[]) private expiryToNonce;


    uint256 internal constant _FORTY_EIGHT_HOURS = 172800;

    uint256 internal constant MAX_INT = 2**256 - 1;

    uint256 internal constant MIN_GAS_FOR_CHECK_AND_FINALISE = 50000;
    uint256 internal constant MIN_GAS_FOR_FUNCTION_COMPLETION = 5000;
    uint256 internal constant MIN_GAS_FOR_FAILED_INTERACTION = 20000;
    uint256 internal constant MIN_GAS_FOR_EXPIRY_REMOVAL = 25000;


    event Convert(uint256 indexed nonce, uint256 totalInputValue);


    event Finalise(uint256 indexed nonce, bool success, string message);


    event PoolAdded(address poolAddress, address wrappedPositionAddress, uint64 expiry);









    constructor(
        address _rollupProcessor,
        address _trancheFactory,
        bytes32 _trancheBytecodeHash,
        address _balancerVaultAddress,
        address _elementDeploymentValidatorAddress
    ) {
        rollupProcessor = _rollupProcessor;
        trancheFactory = _trancheFactory;
        trancheBytecodeHash = _trancheBytecodeHash;
        balancerAddress = _balancerVaultAddress;
        elementDeploymentValidatorAddress = _elementDeploymentValidatorAddress;
        heap.initialise(100);
    }






    function getAssetExpiries(address asset) public view returns (uint64[] memory assetExpiries) {
        assetExpiries = assetToExpirys[asset];
    }





    function registerConvergentPoolAddress(
        address _convergentPool,
        address _wrappedPosition,
        uint64 _expiry
    ) external {
        checkAndStorePoolSpecification(_convergentPool, _wrappedPosition, _expiry);
    }






    function deriveTranche(address position, uint256 expiry) internal view virtual returns (address trancheContract) {
        bytes32 salt = keccak256(abi.encodePacked(position, expiry));
        bytes32 addressBytes = keccak256(abi.encodePacked(bytes1(0xff), trancheFactory, salt, trancheBytecodeHash));
        trancheContract = address(uint160(uint256(addressBytes)));
    }

    struct PoolSpec {
        uint256 poolExpiry;
        bytes32 poolId;
        address underlyingAsset;
        address trancheAddress;
        address tranchePosition;
        address trancheUnderlying;
        address poolUnderlying;
        address poolVaultAddress;
    }





    function checkAndStorePoolSpecification(
        address poolAddress,
        address wrappedPositionAddress,
        uint64 expiry
    ) internal {
        PoolSpec memory poolSpec;
        IWrappedPosition wrappedPosition = IWrappedPosition(wrappedPositionAddress);

        try wrappedPosition.token() returns (IERC20 wrappedPositionToken) {
            poolSpec.underlyingAsset = address(wrappedPositionToken);
        } catch {
            revert INVALID_WRAPPED_POSITION();
        }

        poolSpec.trancheAddress = deriveTranche(wrappedPositionAddress, expiry);

        ITranche tranche = ITranche(poolSpec.trancheAddress);
        try tranche.position() returns (IERC20 tranchePositionToken) {
            poolSpec.tranchePosition = address(tranchePositionToken);
        } catch {
            revert INVALID_TRANCHE();
        }

        try tranche.underlying() returns (IERC20 trancheUnderlying) {
            poolSpec.trancheUnderlying = address(trancheUnderlying);
        } catch {
            revert INVALID_TRANCHE();
        }

        uint64 trancheExpiry = 0;
        try tranche.unlockTimestamp() returns (uint256 trancheUnlock) {
            trancheExpiry = uint64(trancheUnlock);
        } catch {
            revert INVALID_TRANCHE();
        }
        if (trancheExpiry != expiry) {
            revert TRANCHE_EXPIRY_MISMATCH();
        }

        if (poolSpec.tranchePosition != wrappedPositionAddress) {
            revert TRANCHE_POSITION_MISMATCH();
        }
        if (poolSpec.trancheUnderlying != poolSpec.underlyingAsset) {
            revert TRANCHE_UNDERLYING_MISMATCH();
        }

        IPool pool = IPool(poolAddress);
        try pool.underlying() returns (IERC20 poolUnderlying) {
            poolSpec.poolUnderlying = address(poolUnderlying);
        } catch {
            revert INVALID_POOL();
        }

        try pool.expiration() returns (uint256 poolExpiry) {
            poolSpec.poolExpiry = poolExpiry;
        } catch {
            revert INVALID_POOL();
        }

        try pool.getVault() returns (IVault poolVault) {
            poolSpec.poolVaultAddress = address(poolVault);
        } catch {
            revert INVALID_POOL();
        }

        try pool.getPoolId() returns (bytes32 poolId) {
            poolSpec.poolId = poolId;
        } catch {
            revert INVALID_POOL();
        }
        if (poolSpec.poolUnderlying != poolSpec.underlyingAsset) {
            revert POOL_UNDERLYING_MISMATCH();
        }
        if (poolSpec.poolExpiry != expiry) {
            revert POOL_EXPIRY_MISMATCH();
        }

        if (poolSpec.poolVaultAddress != balancerAddress) {
            revert VAULT_ADDRESS_VERIFICATION_FAILED();
        }



        IVault balancerVault = IVault(balancerAddress);
        (address balancersPoolAddress, ) = balancerVault.getPool(poolSpec.poolId);
        if (poolAddress != balancersPoolAddress) {
            revert VAULT_ADDRESS_MISMATCH();
        }


        validatePositionAndPoolAddresses(wrappedPositionAddress, poolAddress);


        uint256 assetExpiryHash = hashAssetAndExpiry(poolSpec.underlyingAsset, trancheExpiry);
        pools[assetExpiryHash] = Pool(poolSpec.poolId, poolSpec.trancheAddress, poolAddress, wrappedPositionAddress);
        uint64[] storage expiriesForAsset = assetToExpirys[poolSpec.underlyingAsset];
        uint256 expiryIndex = 0;
        while (expiryIndex < expiriesForAsset.length && expiriesForAsset[expiryIndex] != trancheExpiry) {
            ++expiryIndex;
        }
        if (expiryIndex == expiriesForAsset.length) {
            expiriesForAsset.push(trancheExpiry);
        }
        setTrancheDeploymentBlockNumber(poolSpec.trancheAddress);


        uint256[] storage nonces = expiryToNonce[trancheExpiry];
        if (nonces.length == 0) {
            expiryToNonce[trancheExpiry].push(MAX_INT);
        }
        emit PoolAdded(poolAddress, wrappedPositionAddress, trancheExpiry);
    }






    function setTrancheDeploymentBlockNumber(address trancheAddress) internal {
        uint256 trancheDeploymentBlock = trancheDeploymentBlockNumbers[trancheAddress];
        if (trancheDeploymentBlock == 0) {

            trancheDeploymentBlockNumbers[trancheAddress] = block.number;
        }
    }






    function getTrancheDeploymentBlockNumber(uint256 interactionNonce) public view returns (uint256 blockNumber) {
        Interaction storage interaction = interactions[interactionNonce];
        if (interaction.expiry == 0) {
            revert UNKNOWN_NONCE();
        }
        blockNumber = trancheDeploymentBlockNumbers[interaction.trancheAddress];
    }







    function validatePositionAndPoolAddresses(address wrappedPosition, address pool) internal {
        IDeploymentValidator validator = IDeploymentValidator(elementDeploymentValidatorAddress);
        if (!validator.checkPoolValidation(pool)) {
            revert UNREGISTERED_POOL();
        }
        if (!validator.checkWPValidation(wrappedPosition)) {
            revert UNREGISTERED_POSITION();
        }
        if (!validator.checkPairValidation(wrappedPosition, pool)) {
            revert UNREGISTERED_PAIR();
        }
    }





    function hashAssetAndExpiry(address asset, uint64 expiry) public pure returns (uint256 hashValue) {
        hashValue = uint256(keccak256(abi.encodePacked(asset, uint256(expiry))));
    }













    function convert(
        AztecTypes.AztecAsset calldata inputAssetA,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata outputAssetA,
        AztecTypes.AztecAsset calldata,
        uint256 totalInputValue,
        uint256 interactionNonce,
        uint64 auxData,
        address
    )
        external
        payable
        override
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        )
    {

        if (msg.sender != rollupProcessor) {
            revert INVALID_CALLER();
        }
        if (inputAssetA.id != outputAssetA.id) {
            revert ASSET_IDS_NOT_EQUAL();
        }
        if (inputAssetA.assetType != AztecTypes.AztecAssetType.ERC20) {
            revert ASSET_NOT_ERC20();
        }
        if (interactions[interactionNonce].expiry != 0) {
            revert INTERACTION_ALREADY_EXISTS();
        }


        isAsync = true;
        outputValueA = 0;
        outputValueB = 0;

        Pool storage pool = pools[hashAssetAndExpiry(inputAssetA.erc20Address, auxData)];
        if (pool.trancheAddress == address(0)) {
            revert POOL_NOT_FOUND();
        }
        ITranche tranche = ITranche(pool.trancheAddress);
        if (block.timestamp >= tranche.unlockTimestamp()) {
            revert TRANCHE_ALREADY_EXPIRED();
        }
        uint64 trancheExpiry = uint64(tranche.unlockTimestamp());

        ERC20(inputAssetA.erc20Address).approve(balancerAddress, totalInputValue);

        address inputAsset = inputAssetA.erc20Address;

        uint256 principalTokensAmount = IVault(balancerAddress).swap(
            IVault.SingleSwap({
                poolId: pool.poolId,
                kind: IVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(inputAsset),
                assetOut: IAsset(pool.trancheAddress),
                amount: totalInputValue,
                userData: '0x00'
            }),
            IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            }),
            totalInputValue,
            block.timestamp
        );

        Interaction storage newInteraction = interactions[interactionNonce];
        newInteraction.expiry = trancheExpiry;
        newInteraction.failed = false;
        newInteraction.finalised = false;
        newInteraction.quantityPT = principalTokensAmount;
        newInteraction.trancheAddress = pool.trancheAddress;

        addNonceAndExpiry(interactionNonce, trancheExpiry);


        TrancheAccount storage trancheAccount = trancheAccounts[newInteraction.trancheAddress];
        trancheAccount.numDeposits++;
        trancheAccount.quantityTokensHeld += newInteraction.quantityPT;
        emit Convert(interactionNonce, totalInputValue);
        finaliseExpiredInteractions(MIN_GAS_FOR_FUNCTION_COMPLETION);

    }






    function finaliseExpiredInteractions(uint256 gasFloor) internal {


        uint256 gasLoopCondition = MIN_GAS_FOR_CHECK_AND_FINALISE + MIN_GAS_FOR_FUNCTION_COMPLETION + gasFloor;
        uint256 ourGasFloor = MIN_GAS_FOR_FUNCTION_COMPLETION + gasFloor;
        while (gasleft() > gasLoopCondition) {


            (bool expiryAvailable, uint256 nonce) = checkNextExpiry(ourGasFloor);
            if (!expiryAvailable) {
                break;
            }

            uint256 gasRemaining = gasleft();
            if (gasRemaining <= ourGasFloor) {
                break;
            }
            uint256 gasForFinalise = gasRemaining - ourGasFloor;

            try IRollupProcessor(rollupProcessor).processAsyncDefiInteraction{gas: gasForFinalise}(nonce) returns (bool interactionCompleted) {

            } catch {
                break;
            }
        }
    }






    function finalise(
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata outputAssetA,
        AztecTypes.AztecAsset calldata,
        uint256 interactionNonce,
        uint64
    )
        external
        payable
        override
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool interactionCompleted
        )
    {
        if (msg.sender != rollupProcessor) {
            revert INVALID_CALLER();
        }

        Interaction storage interaction = interactions[interactionNonce];
        if (interaction.expiry == 0) {
            revert UNKNOWN_NONCE();
        }
        if (interaction.expiry > block.timestamp) {
            revert BRIDGE_NOT_READY();
        }
        if (interaction.finalised) {
            revert ALREADY_FINALISED();
        }

        TrancheAccount storage trancheAccount = trancheAccounts[interaction.trancheAddress];
        if (trancheAccount.numDeposits == 0) {

            setInteractionAsFailure(interaction, interactionNonce, 'NO_DEPOSITS_FOR_TRANCHE');
            popInteraction(interaction, interactionNonce);
            return (0, 0, false);
        }


        if (trancheAccount.redemptionStatus != TrancheRedemptionStatus.REDEMPTION_SUCCEEDED) {


            ITranche tranche = ITranche(interaction.trancheAddress);
            try tranche.withdrawPrincipal(trancheAccount.quantityTokensHeld, address(this)) returns (uint256 valueRedeemed) {
                trancheAccount.quantityAssetRedeemed = valueRedeemed;
                trancheAccount.quantityAssetRemaining = valueRedeemed;
                trancheAccount.redemptionStatus = TrancheRedemptionStatus.REDEMPTION_SUCCEEDED;
            } catch Error(string memory errorMessage) {
                setInteractionAsFailure(interaction, interactionNonce, errorMessage);
                trancheAccount.redemptionStatus = TrancheRedemptionStatus.REDEMPTION_FAILED;
                popInteraction(interaction, interactionNonce);
                return (0, 0, false);
            } catch {
                setInteractionAsFailure(interaction, interactionNonce, 'UNKNOWN_ERROR_FROM_TRANCHE_WITHDRAW');
                trancheAccount.redemptionStatus = TrancheRedemptionStatus.REDEMPTION_FAILED;
                popInteraction(interaction, interactionNonce);
                return (0, 0, false);
            }
        }


        uint256 amountToAllocate = 0;
        if (trancheAccount.quantityTokensHeld == 0) {




            amountToAllocate = trancheAccount.quantityAssetRedeemed / trancheAccount.numDeposits;
        } else {

            amountToAllocate = (trancheAccount.quantityAssetRedeemed * interaction.quantityPT) / trancheAccount.quantityTokensHeld;
        }

        int256 numRemainingInteractionsForTranche = int256(uint256(trancheAccount.numDeposits)) - int256(uint256(trancheAccount.numFinalised));

        if (numRemainingInteractionsForTranche <= 1 || amountToAllocate > trancheAccount.quantityAssetRemaining) {


            amountToAllocate = trancheAccount.quantityAssetRemaining;
        }
        trancheAccount.quantityAssetRemaining -= amountToAllocate;
        trancheAccount.numFinalised++;


        ERC20(outputAssetA.erc20Address).approve(rollupProcessor, amountToAllocate);
        interaction.finalised = true;
        popInteraction(interaction, interactionNonce);
        outputValueA = amountToAllocate;
        outputValueB = 0;
        interactionCompleted = true;
        emit Finalise(interactionNonce, interactionCompleted, '');
    }







    function setInteractionAsFailure(
        Interaction storage interaction,
        uint256 interactionNonce,
        string memory message
    ) internal {
        interaction.failed = true;
        emit Finalise(interactionNonce, false, message);
    }







    function addNonceAndExpiry(uint256 nonce, uint64 expiry) internal returns (bool expiryAdded) {


        expiryAdded = false;
        uint256[] storage nonces = expiryToNonce[expiry];
        if (nonces.length == 1 && nonces[0] == MAX_INT) {
            nonces[0] = nonce;
        } else {
            nonces.push(nonce);
        }


        if (nonces.length == 1) {
            heap.add(expiry);
            expiryAdded = true;
        }
    }







    function popInteraction(Interaction storage interaction, uint256 interactionNonce) internal returns (bool expiryRemoved) {
        uint256[] storage nonces = expiryToNonce[interaction.expiry];
        if (nonces.length == 0) {
            return (false);
        }
        uint256 index = nonces.length - 1;
        while (index > 0 && nonces[index] != interactionNonce) {
            --index;
        }
        if (nonces[index] != interactionNonce) {
            return (false);
        }
        if (index != nonces.length - 1) {
            nonces[index] = nonces[nonces.length - 1];
        }
        nonces.pop();


        if (nonces.length == 0) {
            heap.remove(interaction.expiry);
            delete expiryToNonce[interaction.expiry];
            return (true);
        }
        return (false);
    }







    function checkNextExpiry(uint256 gasFloor)
        internal
        returns (
            bool expiryAvailable,
            uint256 nonce
        )
    {

        if (heap.size() == 0) {
            return (false, 0);
        }

        uint64 nextExpiry = heap.min();
        if (nextExpiry > block.timestamp) {

            return (false, 0);
        }

        uint256[] storage nonces = expiryToNonce[nextExpiry];
        uint256 minGasForLoop = (gasFloor + MIN_GAS_FOR_FAILED_INTERACTION);
        while (nonces.length > 0 && gasleft() >= minGasForLoop) {
            uint256 nextNonce = nonces[nonces.length - 1];
            if (nextNonce == MAX_INT) {


                nonces.pop();
                continue;
            }
            Interaction storage interaction = interactions[nextNonce];
            if (interaction.expiry == 0 || interaction.finalised || interaction.failed) {


                nonces.pop();
                continue;
            }

            (bool canBeFinalised, string memory message) = interactionCanBeFinalised(interaction);
            if (!canBeFinalised) {

                setInteractionAsFailure(interaction, nextNonce, message);
                nonces.pop();
                continue;
            }
            return (true, nextNonce);
        }


        if (nonces.length == 0 && gasleft() >= (gasFloor + MIN_GAS_FOR_EXPIRY_REMOVAL)) {

            heap.remove(nextExpiry);
        }
        return (false, 0);
    }











    function interactionCanBeFinalised(Interaction storage interaction) internal returns (bool canBeFinalised, string memory message) {
        TrancheAccount storage trancheAccount = trancheAccounts[interaction.trancheAddress];
        if (trancheAccount.numDeposits == 0) {

            return (false, 'NO_DEPOSITS_FOR_TRANCHE');
        }
        if (trancheAccount.redemptionStatus == TrancheRedemptionStatus.REDEMPTION_FAILED) {
            return (false, 'TRANCHE_REDEMPTION_FAILED');
        }

        if (trancheAccount.redemptionStatus == TrancheRedemptionStatus.REDEMPTION_SUCCEEDED) {

            if (trancheAccount.quantityAssetRemaining == 0) {

                return (false, 'ASSET_ALREADY_FULLY_ALLOCATED');
            }

            return (true, '');
        }

        ITranche tranche = ITranche(interaction.trancheAddress);
        uint256 speedbump = tranche.speedbump();
        if (speedbump != 0) {
            uint256 newExpiry = speedbump + _FORTY_EIGHT_HOURS;
            if (newExpiry > block.timestamp) {

                trancheAccount.redemptionStatus = TrancheRedemptionStatus.REDEMPTION_FAILED;
                return (false, 'SPEEDBUMP');
            }
        }
        address wpAddress = address(tranche.position());
        IWrappedPosition wrappedPosition = IWrappedPosition(wpAddress);
        address underlyingAddress = address(wrappedPosition.token());
        address yearnVaultAddress = address(wrappedPosition.vault());
        uint256 vaultQuantity = ERC20(underlyingAddress).balanceOf(yearnVaultAddress);
        if (trancheAccount.quantityTokensHeld > vaultQuantity) {
            trancheAccount.redemptionStatus = TrancheRedemptionStatus.REDEMPTION_FAILED;
            return (false, 'VAULT_BALANCE');
        }

        return (true, '');
    }
}
