pragma solidity 0.5.10;

import "./interfaces/ICertifier.sol";
import "./interfaces/IRandomAuRa.sol";
import "./interfaces/IStakingAuRa.sol";
import "./interfaces/ITxPermission.sol";
import "./interfaces/IValidatorSetAuRa.sol";
import "./upgradeability/UpgradeableOwned.sol";





contract TxPermission is UpgradeableOwned, ITxPermission {







    address[] internal _allowedSenders;


    ICertifier public certifierContract;




    mapping(address => bool) public isSenderAllowed;


    IValidatorSetAuRa public validatorSetContract;

    mapping(address => uint256) internal _deployerInputLengthLimit;



    mapping(address => uint256) public senderMinGasPrice;





    uint256 public constant BLOCK_GAS_LIMIT = 12500000;



    uint256 public constant BLOCK_GAS_LIMIT_REDUCED = 4000000;






    event DeployerInputLengthLimitSet(address indexed deployer, uint256 limit);




    event SenderMinGasPriceSet(address indexed sender, uint256 minGasPrice);




    modifier onlyInitialized {
        require(isInitialized());
        _;
    }










    function initialize(
        address[] calldata _allowed,
        address _certifier,
        address _validatorSet
    ) external {
        require(block.number == 0 || msg.sender == _admin());
        require(!isInitialized());
        require(_certifier != address(0));
        require(_validatorSet != address(0));
        for (uint256 i = 0; i < _allowed.length; i++) {
            _addAllowedSender(_allowed[i]);
        }
        certifierContract = ICertifier(_certifier);
        validatorSetContract = IValidatorSetAuRa(_validatorSet);
    }




    function addAllowedSender(address _sender) public onlyOwner onlyInitialized {
        _addAllowedSender(_sender);
    }





    function removeAllowedSender(address _sender) public onlyOwner onlyInitialized {
        require(isSenderAllowed[_sender]);

        uint256 allowedSendersLength = _allowedSenders.length;

        for (uint256 i = 0; i < allowedSendersLength; i++) {
            if (_sender == _allowedSenders[i]) {
                _allowedSenders[i] = _allowedSenders[allowedSendersLength - 1];
                _allowedSenders.length--;
                break;
            }
        }

        isSenderAllowed[_sender] = false;
    }






    function setDeployerInputLengthLimit(address _deployer, uint256 _limit) public onlyOwner onlyInitialized {
        _deployerInputLengthLimit[_deployer] = _limit;
        emit DeployerInputLengthLimitSet(_deployer, _limit);
    }




    function setSenderMinGasPrice(address _sender, uint256 _minGasPrice) public onlyOwner onlyInitialized {
        senderMinGasPrice[_sender] = _minGasPrice;
        emit SenderMinGasPriceSet(_sender, _minGasPrice);
    }




    function contractName() public pure returns(string memory) {
        return "TX_PERMISSION_CONTRACT";
    }


    function contractNameHash() public pure returns(bytes32) {
        return keccak256(abi.encodePacked(contractName()));
    }


    function contractVersion() public pure returns(uint256) {
        return 3;
    }




    function allowedSenders() public view returns(address[] memory) {
        return _allowedSenders;
    }

















    function allowedTxTypes(
        address _sender,
        address _to,
        uint256 _value,
        uint256 _gasPrice,
        bytes memory _data
    )
        public
        view
        returns(uint32 typesMask, bool cache)
    {
        if (isSenderAllowed[_sender]) {

            return (ALL, false);
        }

        if (_to == address(0) && _data.length > deployerInputLengthLimit(_sender)) {

            return (NONE, false);
        }


        bytes4 signature = bytes4(0);
        assembly {
            signature := shl(224, mload(add(_data, 4)))
        }

        if (_to == validatorSetContract.randomContract()) {
            if (signature == COMMIT_HASH_SIGNATURE && _data.length > 4+32) {
                bytes32 numberHash;
                assembly { numberHash := mload(add(_data, 36)) }
                return (IRandomAuRa(_to).commitHashCallable(_sender, numberHash) ? CALL : NONE, false);
            } else if (
                (signature == REVEAL_NUMBER_SIGNATURE || signature == REVEAL_SECRET_SIGNATURE) &&
                _data.length == 4+32
            ) {
                uint256 num;
                assembly { num := mload(add(_data, 36)) }
                return (IRandomAuRa(_to).revealNumberCallable(_sender, num) ? CALL : NONE, false);
            } else {
                return (NONE, false);
            }
        }

        if (_to == address(validatorSetContract)) {

            if (signature == EMIT_INITIATE_CHANGE_SIGNATURE) {


                return (validatorSetContract.emitInitiateChangeCallable() ? CALL : NONE, false);
            } else if (signature == REPORT_MALICIOUS_SIGNATURE && _data.length >= 4+64) {
                address maliciousMiningAddress;
                uint256 blockNumber;
                assembly {
                    maliciousMiningAddress := mload(add(_data, 36))
                    blockNumber := mload(add(_data, 68))
                }


                (bool callable,) = validatorSetContract.reportMaliciousCallable(
                    _sender, maliciousMiningAddress, blockNumber
                );

                return (callable ? CALL : NONE, false);
            } else if (_gasPrice > 0) {


                return (validatorSetContract.isValidator(_sender) ? NONE : CALL, false);
            }
        }

        if (validatorSetContract.isValidator(_sender) && _gasPrice > 0) {

            return (_sender.balance > 0 ? BASIC : NONE, false);
        }

        if (validatorSetContract.isValidator(_to)) {

            return (NONE, false);
        }


        if (_gasPrice == 0) {
            return (certifierContract.certifiedExplicitly(_sender) ? ALL : NONE, false);
        }


        if (_gasPrice < senderMinGasPrice[_sender]) {
            return (NONE, false);
        }


        return (ALL, false);
    }



    function blockGasLimit() public view returns(uint256) {
        address stakingContract = validatorSetContract.stakingContract();
        uint256 stakingEpochEndBlock = IStakingAuRa(stakingContract).stakingEpochEndBlock();
        if (block.number == stakingEpochEndBlock - 1 || block.number == stakingEpochEndBlock) {
            return BLOCK_GAS_LIMIT_REDUCED;
        }
        return BLOCK_GAS_LIMIT;
    }




    function deployerInputLengthLimit(address _deployer) public view returns(uint256) {
        uint256 limit = _deployerInputLengthLimit[_deployer];

        if (limit != 0) {
            return limit;
        } else {
            return 30720;
        }
    }


    function isInitialized() public view returns(bool) {
        return validatorSetContract != IValidatorSetAuRa(0);
    }




    uint32 internal constant NONE = 0;
    uint32 internal constant ALL = 0xffffffff;
    uint32 internal constant BASIC = 0x01;
    uint32 internal constant CALL = 0x02;

    uint32 internal constant CREATE = 0x04;
    uint32 internal constant PRIVATE = 0x08;




    bytes4 internal constant COMMIT_HASH_SIGNATURE = 0x0b61ba85;


    bytes4 internal constant EMIT_INITIATE_CHANGE_SIGNATURE = 0x93b4e25e;


    bytes4 internal constant REPORT_MALICIOUS_SIGNATURE = 0xc476dd40;


    bytes4 internal constant REVEAL_SECRET_SIGNATURE = 0x98df67c6;


    bytes4 internal constant REVEAL_NUMBER_SIGNATURE = 0xfe7d567d;



    function _addAllowedSender(address _sender) internal {
        require(!isSenderAllowed[_sender]);
        require(_sender != address(0));
        _allowedSenders.push(_sender);
        isSenderAllowed[_sender] = true;
    }
}
