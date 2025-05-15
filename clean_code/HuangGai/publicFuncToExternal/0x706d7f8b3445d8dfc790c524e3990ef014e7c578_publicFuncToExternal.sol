





pragma solidity 0.6.10;














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

interface IAmp {
    function registerCollateralManager() external;
}





contract Ownable {
    address private _owner;
    address private _authorizedNewOwner;





    event OwnershipTransferAuthorization(address indexed authorizedAddress);






    event OwnerUpdate(address indexed oldValue, address indexed newValue);




    constructor() internal {
        _owner = msg.sender;
    }





    function owner() public view returns (address) {
        return _owner;
    }





    function authorizedNewOwner() public view returns (address) {
        return _authorizedNewOwner;
    }








    function authorizeOwnershipTransfer(address _authorizedAddress) public {
        require(msg.sender == _owner, "Invalid sender");

        _authorizedNewOwner = _authorizedAddress;

        emit OwnershipTransferAuthorization(_authorizedNewOwner);
    }





    function assumeOwnership() public {
        require(msg.sender == _authorizedNewOwner, "Invalid sender");

        address oldValue = _owner;
        _owner = _authorizedNewOwner;
        _authorizedNewOwner = address(0);

        emit OwnerUpdate(oldValue, _owner);
    }
}

abstract contract ERC1820Registry {
    function setInterfaceImplementer(
        address _addr,
        bytes32 _interfaceHash,
        address _implementer
    ) external virtual;

    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash)
        external
        virtual
        view
        returns (address);

    function setManager(address _addr, address _newManager) external virtual;

    function getManager(address _addr) public virtual view returns (address);
}


contract ERC1820Client {
    ERC1820Registry constant ERC1820REGISTRY = ERC1820Registry(
        0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
    );

    function setInterfaceImplementation(
        string memory _interfaceLabel,
        address _implementation
    ) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(
            address(this),
            interfaceHash,
            _implementation
        );
    }

    function interfaceAddr(address addr, string memory _interfaceLabel)
        internal
        view
        returns (address)
    {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}





interface IAmpTokensRecipient {



    function canReceive(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external view returns (bool);




    function tokensReceived(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}





interface IAmpTokensSender {




    function canTransfer(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external view returns (bool);




    function tokensToTransfer(
        bytes4 functionSig,
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}






library PartitionUtils {
    bytes32 public constant CHANGE_PARTITION_FLAG = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

















    function _getDestinationPartition(bytes memory _data, bytes32 _fallbackPartition)
        internal
        pure
        returns (bytes32)
    {
        if (_data.length < 64) {
            return _fallbackPartition;
        }

        (bytes32 flag, bytes32 toPartition) = abi.decode(_data, (bytes32, bytes32));
        if (flag == CHANGE_PARTITION_FLAG) {
            return toPartition;
        }

        return _fallbackPartition;
    }






    function _getPartitionPrefix(bytes32 _partition) internal pure returns (bytes4) {
        return bytes4(_partition);
    }








    function _splitPartition(bytes32 _partition)
        internal
        pure
        returns (
            bytes4,
            bytes8,
            address
        )
    {
        bytes4 prefix = bytes4(_partition);
        bytes8 subPartition = bytes8(_partition << 32);
        address addressPart = address(uint160(uint256(_partition)));
        return (prefix, subPartition, addressPart);
    }








    function _getPartitionStrategyValidatorIName(bytes4 _prefix)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("AmpPartitionStrategyValidator", _prefix));
    }
}





contract FlexaCollateralManager is Ownable, IAmpTokensSender, IAmpTokensRecipient, ERC1820Client {



    string internal constant AMP_TOKENS_SENDER = "AmpTokensSender";




    string internal constant AMP_TOKENS_RECIPIENT = "AmpTokensRecipient";





    bytes32
        internal constant CHANGE_PARTITION_FLAG = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;





    bytes4 internal constant PARTITION_PREFIX = 0xCCCCCCCC;








    bytes32
        internal constant WITHDRAWAL_FLAG = 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;





    bytes32
        internal constant FALLBACK_WITHDRAWAL_FLAG = 0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;




    bytes32
        internal constant REFUND_FLAG = 0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc;




    bytes32
        internal constant DIRECT_TRANSFER_FLAG = 0xdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd;








    address public amp;




    mapping(bytes32 => bool) public partitions;








    address public withdrawalPublisher;




    address public fallbackPublisher;




    address public withdrawalLimitPublisher;




    address public directTransferer;




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
        uint256 indexed amount,
        bytes data
    );








    event SupplyRefund(
        address indexed supplier,
        bytes32 indexed partition,
        uint256 amount,
        uint256 indexed nonce
    );













    event DirectTransfer(
        address operator,
        bytes32 indexed from_partition,
        address indexed to_address,
        bytes32 indexed to_partition,
        uint256 value
    );









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










    event WithdrawalPublisherUpdate(address indexed oldValue, address indexed newValue);






    event FallbackPublisherUpdate(address indexed oldValue, address indexed newValue);






    event WithdrawalLimitPublisherUpdate(address indexed oldValue, address indexed newValue);






    event DirectTransfererUpdate(address indexed oldValue, address indexed newValue);






    event PartitionManagerUpdate(address indexed oldValue, address indexed newValue);









    constructor(address _amp) public {
        amp = _amp;

        ERC1820Client.setInterfaceImplementation(AMP_TOKENS_RECIPIENT, address(this));
        ERC1820Client.setInterfaceImplementation(AMP_TOKENS_SENDER, address(this));

        IAmp(amp).registerCollateralManager();
    }














    function canReceive(
        bytes4,
        bytes32 _partition,
        address,
        address,
        address _to,
        uint256,
        bytes calldata _data,
        bytes calldata
    ) external override view returns (bool) {
        if (msg.sender != amp || _to != address(this)) {
            return false;
        }

        bytes32 _destinationPartition = PartitionUtils._getDestinationPartition(_data, _partition);

        return partitions[_destinationPartition];
    }











    function tokensReceived(
        bytes4,
        bytes32 _partition,
        address _operator,
        address,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata
    ) external override {
        require(msg.sender == amp, "Invalid sender");
        require(_to == address(this), "Invalid to address");

        bytes32 _destinationPartition = PartitionUtils._getDestinationPartition(_data, _partition);

        require(partitions[_destinationPartition], "Invalid destination partition");

        supplyNonce = SafeMath.add(supplyNonce, 1);
        nonceToSupply[supplyNonce].supplier = _operator;
        nonceToSupply[supplyNonce].partition = _destinationPartition;
        nonceToSupply[supplyNonce].amount = _value;

        emit SupplyReceipt(_operator, _destinationPartition, _value, supplyNonce);
    }

















    function canTransfer(
        bytes4,
        bytes32 _partition,
        address _operator,
        address _from,
        address,
        uint256 _value,
        bytes calldata,
        bytes calldata _operatorData
    ) external override view returns (bool) {
        if (msg.sender != amp || _from != address(this)) {
            return false;
        }

        bytes32 flag = _decodeOperatorDataFlag(_operatorData);

        if (flag == WITHDRAWAL_FLAG) {
            return _validateWithdrawal(_partition, _operator, _value, _operatorData);
        }
        if (flag == FALLBACK_WITHDRAWAL_FLAG) {
            return _validateFallbackWithdrawal(_partition, _operator, _value, _operatorData);
        }
        if (flag == REFUND_FLAG) {
            return _validateRefund(_partition, _operator, _value, _operatorData);
        }
        if (flag == DIRECT_TRANSFER_FLAG) {
            return _validateDirectTransfer(_operator, _value);
        }

        return false;
    }













    function tokensToTransfer(
        bytes4,
        bytes32 _partition,
        address _operator,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external override {
        require(msg.sender == amp, "Invalid sender");
        require(_from == address(this), "Invalid from address");

        bytes32 flag = _decodeOperatorDataFlag(_operatorData);

        if (flag == WITHDRAWAL_FLAG) {
            _executeWithdrawal(_partition, _operator, _value, _operatorData);
        } else if (flag == FALLBACK_WITHDRAWAL_FLAG) {
            _executeFallbackWithdrawal(_partition, _operator, _value, _operatorData);
        } else if (flag == REFUND_FLAG) {
            _executeRefund(_partition, _operator, _value, _operatorData);
        } else if (flag == DIRECT_TRANSFER_FLAG) {
            _executeDirectTransfer(_partition, _operator, _to, _value, _data);
        } else {
            revert("invalid flag");
        }
    }













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
            address,
            uint256,
            uint256
        )
    {
        (
            address supplier,
            uint256 maxAuthorizedAccountNonce,
            bytes32[] memory merkleProof
        ) = _decodeWithdrawalOperatorData(_operatorData);

        bytes32 leafDataHash = _calculateWithdrawalLeaf(
            supplier,
            _partition,
            _value,
            maxAuthorizedAccountNonce
        );

        bytes32 calculatedRoot = _calculateMerkleRoot(merkleProof, leafDataHash);
        uint256 withdrawalRootNonce = withdrawalRootToNonce[calculatedRoot];

        return (supplier, maxAuthorizedAccountNonce, withdrawalRootNonce);
    }













    function _validateWithdrawalData(
        bytes32 _partition,
        address _operator,
        uint256 _value,
        address _supplier,
        uint256 _maxAuthorizedAccountNonce,
        uint256 _withdrawalRootNonce
    ) internal view returns (bool) {
        return

            (_operator == owner() || _operator == withdrawalPublisher || _operator == _supplier) &&

            (addressToWithdrawalNonce[_partition][_supplier] <= _maxAuthorizedAccountNonce) &&

            (_value <= withdrawalLimit) &&

            (_withdrawalRootNonce > 0) &&

            (_withdrawalRootNonce > _maxAuthorizedAccountNonce);
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
            address,
            uint256,
            uint256,
            bytes32
        )
    {
        (
            address supplier,
            uint256 maxCumulativeWithdrawalAmount,
            bytes32[] memory merkleProof
        ) = _decodeWithdrawalOperatorData(_operatorData);

        uint256 newCumulativeWithdrawalAmount = SafeMath.add(
            _value,
            addressToCumulativeAmountWithdrawn[_partition][supplier]
        );

        bytes32 leafDataHash = _calculateFallbackLeaf(
            supplier,
            _partition,
            maxCumulativeWithdrawalAmount
        );
        bytes32 calculatedRoot = _calculateMerkleRoot(merkleProof, leafDataHash);

        return (
            supplier,
            maxCumulativeWithdrawalAmount,
            newCumulativeWithdrawalAmount,
            calculatedRoot
        );
    }












    function _validateFallbackWithdrawalData(
        address _operator,
        uint256 _maxCumulativeWithdrawalAmount,
        uint256 _newCumulativeWithdrawalAmount,
        address _supplier,
        bytes32 _calculatedRoot
    ) internal view returns (bool) {
        return

            (_operator == owner() || _operator == _supplier) &&

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

            (_operator == owner() || _operator == _supply.supplier) &&

            (_partition == _supply.partition) &&

            (_value == _supply.amount) &&

            (SafeMath.add(fallbackSetDate, fallbackWithdrawalDelaySeconds) <= block.timestamp) &&

            (_supplyNonce > fallbackMaxIncludedSupplyNonce);
    }











    function _validateDirectTransfer(address _operator, uint256 _value)
        internal
        view
        returns (bool)
    {
        return

            (_operator == owner() || _operator == directTransferer) &&

            (_value <= withdrawalLimit);
    }









    function _executeDirectTransfer(
        bytes32 _partition,
        address _operator,
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal {
        require(_validateDirectTransfer(_operator, _value), "Transfer unauthorized");

        withdrawalLimit = SafeMath.sub(withdrawalLimit, _value);

        bytes32 to_partition = PartitionUtils._getDestinationPartition(_data, _partition);

        emit DirectTransfer(_operator, _partition, _to, to_partition, _value);
    }











    function requestRelease(
        bytes32 _partition,
        uint256 _amount,
        bytes memory _data
    ) public {
        emit ReleaseRequest(msg.sender, _partition, _amount, _data);
    }









    function addPartition(bytes32 _partition) public {
        require(msg.sender == owner() || msg.sender == partitionManager, "Invalid sender");
        require(partitions[_partition] == false, "Partition already permitted");

        (bytes4 prefix, , address partitionOwner) = PartitionUtils._splitPartition(_partition);

        require(prefix == PARTITION_PREFIX, "Invalid partition prefix");
        require(partitionOwner == address(this), "Invalid partition owner");

        partitions[_partition] = true;

        emit PartitionAdded(_partition);
    }





    function removePartition(bytes32 _partition) public {
        require(msg.sender == owner() || msg.sender == partitionManager, "Invalid sender");
        require(partitions[_partition], "Partition not permitted");

        delete partitions[_partition];

        emit PartitionRemoved(_partition);
    }









    function modifyWithdrawalLimit(int256 _amount) public {
        require(msg.sender == owner() || msg.sender == withdrawalLimitPublisher, "Invalid sender");
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
        require(msg.sender == owner() || msg.sender == withdrawalPublisher, "Invalid sender");

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
        require(msg.sender == owner() || msg.sender == withdrawalPublisher, "Invalid sender");

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













    function setFallbackRoot(bytes32 _root, uint256 _maxSupplyNonce) public {
        require(msg.sender == owner() || msg.sender == fallbackPublisher, "Invalid sender");
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






    function resetFallbackMechanismDate() public {
        require(msg.sender == owner() || msg.sender == fallbackPublisher, "Invalid sender");
        fallbackSetDate = block.timestamp;

        emit FallbackMechanismDateReset(fallbackSetDate);
    }






    function setFallbackWithdrawalDelay(uint256 _newFallbackDelaySeconds) public {
        require(msg.sender == owner(), "Invalid sender");
        require(_newFallbackDelaySeconds != 0, "Invalid zero delay seconds");
        require(_newFallbackDelaySeconds < 10 * 365 days, "Invalid delay over 10 years");

        uint256 oldDelay = fallbackWithdrawalDelaySeconds;
        fallbackWithdrawalDelaySeconds = _newFallbackDelaySeconds;

        emit FallbackWithdrawalDelayUpdate(oldDelay, _newFallbackDelaySeconds);
    }











    function setWithdrawalPublisher(address _newWithdrawalPublisher) public {
        require(msg.sender == owner(), "Invalid sender");

        address oldValue = withdrawalPublisher;
        withdrawalPublisher = _newWithdrawalPublisher;

        emit WithdrawalPublisherUpdate(oldValue, withdrawalPublisher);
    }







    function setFallbackPublisher(address _newFallbackPublisher) public {
        require(msg.sender == owner(), "Invalid sender");

        address oldValue = fallbackPublisher;
        fallbackPublisher = _newFallbackPublisher;

        emit FallbackPublisherUpdate(oldValue, fallbackPublisher);
    }







    function setWithdrawalLimitPublisher(address _newWithdrawalLimitPublisher) public {
        require(msg.sender == owner(), "Invalid sender");

        address oldValue = withdrawalLimitPublisher;
        withdrawalLimitPublisher = _newWithdrawalLimitPublisher;

        emit WithdrawalLimitPublisherUpdate(oldValue, withdrawalLimitPublisher);
    }






    function setDirectTransferer(address _newDirectTransferer) public {
        require(msg.sender == owner(), "Invalid sender");

        address oldValue = directTransferer;
        directTransferer = _newDirectTransferer;

        emit DirectTransfererUpdate(oldValue, directTransferer);
    }






    function setPartitionManager(address _newPartitionManager) public {
        require(msg.sender == owner(), "Invalid sender");

        address oldValue = partitionManager;
        partitionManager = _newPartitionManager;

        emit PartitionManagerUpdate(oldValue, partitionManager);
    }










    function _decodeOperatorDataFlag(bytes memory _operatorData) internal pure returns (bytes32) {
        return abi.decode(_operatorData, (bytes32));
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
        (, address supplier, uint256 nonce, bytes32[] memory proof) = abi.decode(
            _operatorData,
            (bytes32, address, uint256, bytes32[])
        );

        return (supplier, nonce, proof);
    }






    function _decodeRefundOperatorData(bytes memory _operatorData) internal pure returns (uint256) {
        (, uint256 nonce) = abi.decode(_operatorData, (bytes32, uint256));

        return nonce;
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
