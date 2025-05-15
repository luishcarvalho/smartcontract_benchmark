

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../presets/OwnablePausable.sol";
import "../interfaces/IDepositContract.sol";
import "../interfaces/IValidators.sol";
import "../interfaces/ISolos.sol";







contract Solos is ISolos, ReentrancyGuard, OwnablePausable {
    using Address for address payable;
    using SafeMath for uint256;


    uint256 public constant VALIDATOR_DEPOSIT = 32 ether;


    mapping(bytes32 => Solo) public override solos;


    IDepositContract public override validatorRegistration;


    uint256 public override validatorPrice;


    uint256 public override cancelLockDuration;


    IValidators private validators;









    constructor(
        address _admin,
        address _validatorRegistration,
        address _validators,
        uint256 _validatorPrice,
        uint256 _cancelLockDuration
    )
        OwnablePausable(_admin)
    {
        validatorRegistration = IDepositContract(_validatorRegistration);
        validators = IValidators(_validators);


        validatorPrice = _validatorPrice;
        emit ValidatorPriceUpdated(_validatorPrice);


        cancelLockDuration = _cancelLockDuration;
        emit CancelLockDurationUpdated(_cancelLockDuration);
    }




    function addDeposit(bytes32 _withdrawalCredentials) external payable override whenNotPaused {
        require(_withdrawalCredentials != "" && _withdrawalCredentials[0] == 0x00, "Solos: invalid withdrawal credentials");
        require(msg.value > 0 && msg.value.mod(VALIDATOR_DEPOSIT) == 0, "Solos: invalid deposit amount");

        bytes32 soloId = keccak256(abi.encodePacked(address(this), msg.sender, _withdrawalCredentials));
        Solo storage solo = solos[soloId];


        solo.amount = solo.amount.add(msg.value);
        if (solo.withdrawalCredentials == "") {
            solo.withdrawalCredentials = _withdrawalCredentials;
        }



        solo.releaseTime = block.timestamp + cancelLockDuration;


        emit DepositAdded(soloId, msg.sender, msg.value, _withdrawalCredentials);
    }




    function cancelDeposit(bytes32 _withdrawalCredentials, uint256 _amount) external override nonReentrant {

        bytes32 soloId = keccak256(abi.encodePacked(address(this), msg.sender, _withdrawalCredentials));
        Solo storage solo = solos[soloId];


        require(block.timestamp >= solo.releaseTime, "Solos: current time is before release time");

        uint256 newAmount = solo.amount.sub(_amount, "Solos: insufficient balance");
        require(newAmount.mod(VALIDATOR_DEPOSIT) == 0, "Solos: invalid cancel amount");


        emit DepositCanceled(soloId, msg.sender, _amount, solo.withdrawalCredentials);

        if (newAmount > 0) {
            solo.amount = newAmount;


            solo.releaseTime = block.timestamp + cancelLockDuration;
        } else {
            delete solos[soloId];
        }


        msg.sender.sendValue(_amount);
    }




    function setValidatorPrice(uint256 _validatorPrice) external override onlyAdmin {
        validatorPrice = _validatorPrice;
        emit ValidatorPriceUpdated(_validatorPrice);
    }




    function setCancelLockDuration(uint256 _cancelLockDuration) external override onlyAdmin {
        cancelLockDuration = _cancelLockDuration;
        emit CancelLockDurationUpdated(_cancelLockDuration);
    }




    function registerValidator(Validator calldata _validator) external override whenNotPaused {
        require(validators.isOperator(msg.sender), "Solos: permission denied");


        Solo storage solo = solos[_validator.soloId];
        solo.amount = solo.amount.sub(VALIDATOR_DEPOSIT, "Solos: insufficient balance");


        validators.register(keccak256(abi.encodePacked(_validator.publicKey)));
        emit ValidatorRegistered(_validator.soloId, _validator.publicKey, validatorPrice, msg.sender);

        validatorRegistration.deposit{value : VALIDATOR_DEPOSIT}(
            _validator.publicKey,
            abi.encodePacked(solo.withdrawalCredentials),
            _validator.signature,
            _validator.depositDataRoot
        );
    }
}
