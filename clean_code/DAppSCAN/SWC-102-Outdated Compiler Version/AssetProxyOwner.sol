

















pragma solidity 0.4.10;

import "../../multisig/MultiSigWalletWithTimeLock.sol";


contract AssetProxyOwner is
    MultiSigWalletWithTimeLock
{

    event AssetProxyRegistration(address assetProxyContract, bool isRegistered);



    mapping (address => bool) public isAssetProxyRegistered;

    bytes4 constant internal REMOVE_AUTHORIZED_ADDRESS_AT_INDEX_SELECTOR = bytes4(keccak256("removeAuthorizedAddressAtIndex(address,uint256)"));



    modifier validRemoveAuthorizedAddressAtIndexTx(uint256 transactionId) {
        Transaction storage tx = transactions[transactionId];
        require(isAssetProxyRegistered[tx.destination]);
        require(readBytes4(tx.data, 0) == REMOVE_AUTHORIZED_ADDRESS_AT_INDEX_SELECTOR);
        _;
    }







    function AssetProxyOwner(
        address[] memory _owners,
        address[] memory _assetProxyContracts,
        uint256 _required,
        uint256 _secondsTimeLocked
    )
        public
        MultiSigWalletWithTimeLock(_owners, _required, _secondsTimeLocked)
    {
        for (uint256 i = 0; i < _assetProxyContracts.length; i++) {
            address assetProxy = _assetProxyContracts[i];
            require(assetProxy != address(0));
            isAssetProxyRegistered[assetProxy] = true;
        }
    }





    function registerAssetProxy(address assetProxyContract, bool isRegistered)
        public
        onlyWallet
        notNull(assetProxyContract)
    {
        isAssetProxyRegistered[assetProxyContract] = isRegistered;
        AssetProxyRegistration(assetProxyContract, isRegistered);
    }



    function executeRemoveAuthorizedAddressAtIndex(uint256 transactionId)
        public
        notExecuted(transactionId)
        fullyConfirmed(transactionId)
        validRemoveAuthorizedAddressAtIndexTx(transactionId)
    {
        Transaction storage tx = transactions[transactionId];
        tx.executed = true;

        if (tx.destination.call.value(tx.value)(tx.data))
            Execution(transactionId);
        else {
            ExecutionFailure(transactionId);
            tx.executed = false;
        }
    }





    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        returns (bytes4 result)
    {
        require(b.length >= index + 4);
        assembly {
            result := mload(add(b, 32))


            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
}
