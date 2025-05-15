

pragma solidity 0.6.9;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./amp/IAmp.sol";
import "./amp/IAmpTokensRecipient.sol";
import "./amp/IAmpTokensSender.sol";

import "./erc1820/ERC1820Client.sol";






contract FlexaCollateralManager is IAmpTokensSender, IAmpTokensRecipient, ERC1820Client {



    string internal constant AMP_TOKENS_SENDER = "AmpTokensSender";




    string internal constant AMP_TOKENS_RECIPIENT = "AmpTokensRecipient";





    bytes32 internal constant CHANGE_PARTITION_FLAG = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;





    bytes4 internal constant PARTITION_PREFIX = 0xCCCCCCCC;








    bytes32 internal constant WITHDRAWAL_FLAG = 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;





    bytes32 internal constant FALLBACK_WITHDRAWAL_FLAG = 0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;




    bytes32 internal constant REFUND_FLAG = 0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc;




    bytes32 internal constant CONSUMPTION_FLAG = 0xdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;








    address public amp;




    mapping(bytes32 => bool) public partitions;








    address public owner;




    address public authorizedNewOwner;




    address public withdrawalPublisher;




    address public fallbackPublisher;




    address public withdrawalLimitPublisher;




    address public consumer;




    address public partitionManager;








    struct Supply {
        address supplier;
        bytes32 partition;
        uint256 amount;
    }








    uint256 public supplyNonce = 0;




    mapping(uint256 => Supply) public nonceToSupply;








    uint256 public withdrawalLimit = 100 * 1000 * (10**18);




    uint256 public maxWithdrawalRootNonce = 0;




    mapping(bytes32 => uint256) public withdrawalRootToNonce;




    mapping(bytes32 => mapping(address => uint256)) public addressToWithdrawalNonce;




    mapping(bytes32 => mapping(address => uint256)) public addressToCumulativeAmountWithdrawn;








    uint256 public fallbackWithdrawalDelaySeconds = 1 weeks;




    bytes32 public fallbackRoot;




    uint256 public fallbackSetDate = 2**200;




    uint256 public fallbackMaxIncludedSupplyNonce = 0;











    event SupplyReceipt(
        address indexed supplier,
        bytes32 indexed partition,
        uint256 amount,
        uint256 indexed nonce
    );







    event RenounceWithdrawalAuthorization(
        address indexed supplier,
        bytes32 indexed partition,
        uint256 indexed nonce
    );









    event Withdrawal(
        address indexed supplier,
        bytes32 indexed partition,
        uint256 amount,
        uint256 indexed rootNonce,
        uint256 authorizedAccountNonce
    );







    event FallbackWithdrawal(
        address indexed supplier,
        bytes32 indexed partition,
        uint256 indexed amount
    );







    event ReleaseRequest(
        address indexed supplier,
        bytes32 indexed partition,
        uint256 indexed amount
    );







    event SupplyRefund(
        address indexed supplier,
        bytes32 indexed partition,
        uint256 amount,
        uint256 indexed nonce
    );











    event Consumption(address indexed operator, bytes32 indexed partition, uint256 indexed value);









    event PartitionAdded(bytes32 indexed partition);





    event PartitionRemoved(bytes32 indexed partition);










    event WithdrawalRootHashAddition(bytes32 indexed rootHash, uint256 indexed nonce);






    event WithdrawalRootHashRemoval(bytes32 indexed rootHash, uint256 indexed nonce);






    event WithdrawalLimitUpdate(uint256 indexed oldValue, uint256 indexed newValue);











    event FallbackRootHashSet(
        bytes32 indexed rootHash,
        uint256 indexed maxSupplyNonceIncluded,
        uint256 setDate
    );





    event FallbackMechanismDateReset(uint256 indexed newDate);






    event FallbackWithdrawalDelayUpdate(uint256 indexed oldValue, uint256 indexed newValue);









    event OwnershipTransferAuthorization(address indexed authorizedAddress);






    event OwnerUpdate(address indexed oldValue, address indexed newValue);






    event WithdrawalPublisherUpdate(address indexed oldValue, address indexed newValue);






    event FallbackPublisherUpdate(address indexed oldValue, address indexed newValue);






    event WithdrawalLimitPublisherUpdate(address indexed oldValue, address indexed newValue);






    event ConsumerUpdate(address indexed oldValue, address indexed newValue);






    event PartitionManagerUpdate(address indexed oldValue, address indexed newValue);









    constructor(address _amp) public {
        owner = msg.sender;
        amp = _amp;

        ERC1820Client.setInterfaceImplementation(AMP_TOKENS_RECIPIENT, address(this));
        ERC1820Client.setInterfaceImplementation(AMP_TOKENS_SENDER, address(this));

        IAmp(amp).registerCollateralManager();
    }














    function canReceive(





















    function _canReceive(address _to, bytes32 _destinationPartition) internal view returns (bool) {
        return _to == address(this) && partitions[_destinationPartition];
    }











    function tokensReceived(







































    function canTransfer(









































    function tokensToTransfer(







































    function _validateWithdrawal(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        bytes memory _operatorData
    ) internal view returns (bool) {
        (
            address supplier,
            uint256 maxAuthorizedAccountNonce,
            uint256 withdrawalRootNonce
        ) = _getWithdrawalData(_partition, _value, _operatorData);

        return
            _validateWithdrawalData(
                _partition,
                _operator,
                _value,
                supplier,
                maxAuthorizedAccountNonce,
                withdrawalRootNonce
            );
    }








    function _executeWithdrawal(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        bytes memory _operatorData
    ) internal {
        (
            address supplier,
            uint256 maxAuthorizedAccountNonce,
            uint256 withdrawalRootNonce
        ) = _getWithdrawalData(_partition, _value, _operatorData);

        require(
            _validateWithdrawalData(
                _partition,
                _operator,
                _value,
                supplier,
                maxAuthorizedAccountNonce,
                withdrawalRootNonce
            ),
            "Transfer unauthorized"
        );

        addressToCumulativeAmountWithdrawn[_partition][supplier] = SafeMath.add(
            _value,
            addressToCumulativeAmountWithdrawn[_partition][supplier]
        );

        addressToWithdrawalNonce[_partition][supplier] = withdrawalRootNonce;

        withdrawalLimit = SafeMath.sub(withdrawalLimit, _value);

        emit Withdrawal(
            supplier,
            _partition,
            _value,
            withdrawalRootNonce,
            maxAuthorizedAccountNonce
        );
    }













    function _getWithdrawalData(
        bytes32 _partition,
        uint256 _value,
        bytes memory _operatorData
    )
        internal
        view
        returns (




































    function _validateWithdrawalData(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        address _supplier,
        uint256 _maxAuthorizedAccountNonce,
        uint256 _withdrawalRootNonce
    ) internal view returns (bool) {
        return

            (_operator == owner || _operator == withdrawalPublisher || _operator == _supplier) &&

            (addressToWithdrawalNonce[_partition][_supplier] <= _maxAuthorizedAccountNonce) &&

            (_value <= withdrawalLimit) &&

            (_withdrawalRootNonce > 0) &&

            (_withdrawalRootNonce > _maxAuthorizedAccountNonce);
    }










    function renounceWithdrawalAuthorization(address _supplier, bytes32 _partition) external {
        require(
            msg.sender == owner || msg.sender == withdrawalPublisher || msg.sender == _supplier,
            "Invalid sender"
        );
        require(
            addressToWithdrawalNonce[_partition][_supplier] < maxWithdrawalRootNonce,
            "Authorization expired"
        );

        addressToWithdrawalNonce[_partition][_supplier] = maxWithdrawalRootNonce;

        emit RenounceWithdrawalAuthorization(_supplier, _partition, maxWithdrawalRootNonce);
    }













    function _validateFallbackWithdrawal(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        bytes memory _operatorData
    ) internal view returns (bool) {
        (
            address supplier,
            uint256 maxCumulativeWithdrawalAmount,
            uint256 newCumulativeWithdrawalAmount,
            bytes32 calculatedRoot
        ) = _getFallbackWithdrawalData(_partition, _value, _operatorData);

        return
            _validateFallbackWithdrawalData(
                _operator,
                maxCumulativeWithdrawalAmount,
                newCumulativeWithdrawalAmount,
                supplier,
                calculatedRoot
            );
    }








    function _executeFallbackWithdrawal(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        bytes memory _operatorData
    ) internal {
        (
            address supplier,
            uint256 maxCumulativeWithdrawalAmount,
            uint256 newCumulativeWithdrawalAmount,
            bytes32 calculatedRoot
        ) = _getFallbackWithdrawalData(_partition, _value, _operatorData);

        require(
            _validateFallbackWithdrawalData(
                _operator,
                maxCumulativeWithdrawalAmount,
                newCumulativeWithdrawalAmount,
                supplier,
                calculatedRoot
            ),
            "Transfer unauthorized"
        );

        addressToCumulativeAmountWithdrawn[_partition][supplier] = newCumulativeWithdrawalAmount;

        addressToWithdrawalNonce[_partition][supplier] = maxWithdrawalRootNonce;

        emit FallbackWithdrawal(supplier, _partition, _value);
    }















    function _getFallbackWithdrawalData(
        bytes32 _partition,
        uint256 _value,
        bytes memory _operatorData
    )
        internal
        view
        returns (











































    function _validateFallbackWithdrawalData(
        address _operator,
        uint256 _maxCumulativeWithdrawalAmount,
        uint256 _newCumulativeWithdrawalAmount,
        address _supplier,
        bytes32 _calculatedRoot
    ) internal view returns (bool) {
        return

            (_operator == owner || _operator == _supplier) &&

            (SafeMath.add(fallbackSetDate, fallbackWithdrawalDelaySeconds) <= block.timestamp) &&

            (_newCumulativeWithdrawalAmount <= _maxCumulativeWithdrawalAmount) &&

            (fallbackRoot == _calculatedRoot);
    }













    function _validateRefund(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        bytes memory _operatorData
    ) internal view returns (bool) {
        (uint256 _supplyNonce, Supply memory supply) = _getRefundData(_operatorData);

        return _verifyRefundData(_partition, _operator, _value, _supplyNonce, supply);
    }








    function _executeRefund(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        bytes memory _operatorData
    ) internal {
        (uint256 nonce, Supply memory supply) = _getRefundData(_operatorData);

        require(
            _verifyRefundData(_partition, _operator, _value, nonce, supply),
            "Transfer unauthorized"
        );

        delete nonceToSupply[nonce];

        emit SupplyRefund(supply.supplier, _partition, supply.amount, nonce);
    }








    function _getRefundData(bytes memory _operatorData)
        internal
        view
        returns (uint256, Supply memory)
    {
        uint256 _supplyNonce = _decodeRefundOperatorData(_operatorData);
        Supply memory supply = nonceToSupply[_supplyNonce];

        return (_supplyNonce, supply);
    }










    function _verifyRefundData(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        uint256 _supplyNonce,
        Supply memory _supply
    ) internal view returns (bool) {
        return

            (_supply.amount > 0) &&

            (_operator == owner || _operator == _supply.supplier) &&

            (_partition == _supply.partition) &&

            (_value == _supply.amount) &&

            (SafeMath.add(fallbackSetDate, fallbackWithdrawalDelaySeconds) <= block.timestamp) &&

            (_supplyNonce > fallbackMaxIncludedSupplyNonce);
    }











    function _validateConsumption(address _operator, uint256 _value) internal view returns (bool) {
        return

            (_operator == owner || _operator == consumer) &&

            (_value <= withdrawalLimit);
    }







    function _executeConsumption(
        bytes32 _partition,
        address _operator,
        uint256 _value
    ) internal {
        require(_validateConsumption(_operator, _value), "Transfer unauthorized");

        withdrawalLimit = SafeMath.sub(withdrawalLimit, _value);

        emit Consumption(_operator, _partition, _value);
    }










    function requestRelease(bytes32 _partition, uint256 _amount) external {
        emit ReleaseRequest(msg.sender, _partition, _amount);
    }









    function addPartition(bytes32 _partition) external {
        require(msg.sender == owner || msg.sender == partitionManager, "Invalid sender");
        require(partitions[_partition] == false, "Partition already permitted");

        (bytes4 prefix, address partitionOwner) = _splitPartition(_partition);

        require(prefix == PARTITION_PREFIX, "Invalid partition prefix");
        require(partitionOwner == address(this), "Invalid partition owner");

        partitions[_partition] = true;

        emit PartitionAdded(_partition);
    }





    function removePartition(bytes32 _partition) external {
        require(msg.sender == owner || msg.sender == partitionManager, "Invalid sender");
        require(partitions[_partition], "Partition not permitted");

        delete partitions[_partition];

        emit PartitionRemoved(_partition);
    }









    function modifyWithdrawalLimit(int256 _amount) external {
        require(msg.sender == owner || msg.sender == withdrawalLimitPublisher, "Invalid sender");
        uint256 oldLimit = withdrawalLimit;
        if (_amount < 0) {
            uint256 unsignedAmount = uint256(-_amount);
            withdrawalLimit = SafeMath.sub(withdrawalLimit, unsignedAmount);
        } else {
            uint256 unsignedAmount = uint256(_amount);
            withdrawalLimit = SafeMath.add(withdrawalLimit, unsignedAmount);
        }
        emit WithdrawalLimitUpdate(oldLimit, withdrawalLimit);
    }









    function addWithdrawalRoot(
        bytes32 _root,
        uint256 _nonce,
        bytes32[] calldata _replacedRoots
    ) external {
        require(msg.sender == owner || msg.sender == withdrawalPublisher, "Invalid sender");

        require(_root != 0, "Invalid root");
        require(maxWithdrawalRootNonce + 1 == _nonce, "Nonce not current max plus one");
        require(withdrawalRootToNonce[_root] == 0, "Nonce already used");

        withdrawalRootToNonce[_root] = _nonce;
        maxWithdrawalRootNonce = _nonce;

        emit WithdrawalRootHashAddition(_root, _nonce);

        for (uint256 i = 0; i < _replacedRoots.length; i++) {
            deleteWithdrawalRoot(_replacedRoots[i]);
        }
    }





    function removeWithdrawalRoots(bytes32[] calldata _roots) external {
        require(msg.sender == owner || msg.sender == withdrawalPublisher, "Invalid sender");

        for (uint256 i = 0; i < _roots.length; i++) {
            deleteWithdrawalRoot(_roots[i]);
        }
    }





    function deleteWithdrawalRoot(bytes32 _root) private {
        uint256 nonce = withdrawalRootToNonce[_root];

        require(nonce > 0, "Root not found");

        delete withdrawalRootToNonce[_root];

        emit WithdrawalRootHashRemoval(_root, nonce);
    }













    function setFallbackRoot(bytes32 _root, uint256 _maxSupplyNonce) external {
        require(msg.sender == owner || msg.sender == fallbackPublisher, "Invalid sender");
        require(_root != 0, "Invalid root");
        require(
            SafeMath.add(fallbackSetDate, fallbackWithdrawalDelaySeconds) > block.timestamp,
            "Fallback is active"
        );
        require(
            _maxSupplyNonce >= fallbackMaxIncludedSupplyNonce,
            "Included supply nonce decreased"
        );
        require(_maxSupplyNonce <= supplyNonce, "Included supply nonce exceeds latest supply");

        fallbackRoot = _root;
        fallbackMaxIncludedSupplyNonce = _maxSupplyNonce;
        fallbackSetDate = block.timestamp;

        emit FallbackRootHashSet(_root, fallbackMaxIncludedSupplyNonce, block.timestamp);
    }






    function resetFallbackMechanismDate() external {
        require(msg.sender == owner || msg.sender == fallbackPublisher, "Invalid sender");
        fallbackSetDate = block.timestamp;

        emit FallbackMechanismDateReset(fallbackSetDate);
    }






    function setFallbackWithdrawalDelay(uint256 _newFallbackDelaySeconds) external {
        require(msg.sender == owner, "Invalid sender");
        require(_newFallbackDelaySeconds != 0, "Invalid zero delay seconds");
        require(_newFallbackDelaySeconds < 10 * 365 days, "Invalid delay over 10 years");

        uint256 oldDelay = fallbackWithdrawalDelaySeconds;
        fallbackWithdrawalDelaySeconds = _newFallbackDelaySeconds;

        emit FallbackWithdrawalDelayUpdate(oldDelay, _newFallbackDelaySeconds);
    }












    function authorizeOwnershipTransfer(address _authorizedAddress) external {
        require(msg.sender == owner, "Invalid sender");

        authorizedNewOwner = _authorizedAddress;

        emit OwnershipTransferAuthorization(authorizedNewOwner);
    }





    function assumeOwnership() external {
        require(msg.sender == authorizedNewOwner, "Invalid sender");
        address oldValue = owner;
        owner = authorizedNewOwner;
        authorizedNewOwner = address(0);

        emit OwnerUpdate(oldValue, owner);
    }







    function setWithdrawalPublisher(address _newWithdrawalPublisher) external {
        require(msg.sender == owner, "Invalid sender");

        address oldValue = withdrawalPublisher;
        withdrawalPublisher = _newWithdrawalPublisher;

        emit WithdrawalPublisherUpdate(oldValue, withdrawalPublisher);
    }







    function setFallbackPublisher(address _newFallbackPublisher) external {
        require(msg.sender == owner, "Invalid sender");

        address oldValue = fallbackPublisher;
        fallbackPublisher = _newFallbackPublisher;

        emit FallbackPublisherUpdate(oldValue, fallbackPublisher);
    }







    function setWithdrawalLimitPublisher(address _newWithdrawalLimitPublisher) external {
        require(msg.sender == owner, "Invalid sender");

        address oldValue = withdrawalLimitPublisher;
        withdrawalLimitPublisher = _newWithdrawalLimitPublisher;

        emit WithdrawalLimitPublisherUpdate(oldValue, withdrawalLimitPublisher);
    }






    function setConsumer(address _newConsumer) external {
        require(msg.sender == owner, "Invalid sender");

        address oldValue = consumer;
        consumer = _newConsumer;

        emit ConsumerUpdate(oldValue, consumer);
    }






    function setPartitionManager(address _newPartitionManager) external {
        require(msg.sender == owner, "Invalid sender");

        address oldValue = partitionManager;
        partitionManager = _newPartitionManager;

        emit PartitionManagerUpdate(oldValue, partitionManager);
    }












    function _splitPartition(bytes32 _partition) internal pure returns (bytes4, address) {
        bytes4 prefix = bytes4(_partition);
        address paritionOwner = address(uint160(uint256(_partition)));

        return (prefix, paritionOwner);
    }



















    function _getDestinationPartition(bytes32 _fromPartition, bytes memory _data)
        internal
        pure
        returns (bytes32 toPartition)
    {
        toPartition = _fromPartition;
        if (_data.length < 64) {
            return toPartition;
        }

        bytes32 flag;
        assembly {
            flag := mload(add(_data, 32))
        }
        if (flag == CHANGE_PARTITION_FLAG) {
            assembly {
                toPartition := mload(add(_data, 64))
            }
        }
    }










    function _decodeOperatorDataFlag(bytes memory _operatorData) internal pure returns (bytes32) {
        bytes32 flag;
        assembly {
            flag := mload(add(_operatorData, 32))
        }
        return (flag);
    }











    function _decodeWithdrawalOperatorData(bytes memory _operatorData)
        internal
        pure
        returns (
            address,
            uint256,
            bytes32[] memory
        )
    {
        bytes20 supplierB;
        assembly {
            supplierB := mload(add(_operatorData, 64))
        }
        address supplier = address(supplierB);

        bytes32 nonceB;
        assembly {
            nonceB := mload(add(_operatorData, 84))
        }
        uint256 nonce = uint256(nonceB);

        uint256 proofNb = (_operatorData.length - 84) / 32;
        bytes32[] memory proof = new bytes32[](proofNb);
        uint256 index = 0;
        for (uint256 i = 116; i <= _operatorData.length; i = i + 32) {
            bytes32 temp;
            assembly {
                temp := mload(add(_operatorData, i))
            }
            proof[index] = temp;
            index++;
        }

        return (supplier, nonce, proof);
    }






    function _decodeRefundOperatorData(bytes memory _operatorData) internal pure returns (uint256) {
        bytes32 nonceB;
        assembly {
            nonceB := mload(add(_operatorData, 64))
        }

        return uint256(nonceB);
    }















    function _calculateWithdrawalLeaf(
        address _supplier,
        bytes32 _partition,
        uint256 _value,
        uint256 _maxAuthorizedAccountNonce
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(_supplier, _partition, _value, _maxAuthorizedAccountNonce));
    }










    function _calculateFallbackLeaf(
        address _supplier,
        bytes32 _partition,
        uint256 _maxCumulativeWithdrawalAmount
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_supplier, _partition, _maxCumulativeWithdrawalAmount));
    }








    function _calculateMerkleRoot(bytes32[] memory _merkleProof, bytes32 _leafHash)
        private
        pure
        returns (bytes32)
    {
        bytes32 computedHash = _leafHash;

        for (uint256 i = 0; i < _merkleProof.length; i++) {
            bytes32 proofElement = _merkleProof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash;
    }
}
