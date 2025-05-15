pragma solidity 0.5.9;

import "../interfaces/IRandom.sol";
import "../interfaces/IValidatorSet.sol";
import "../eternal-storage/OwnedEternalStorage.sol";
import "../libs/SafeMath.sol";



contract RandomBase is OwnedEternalStorage, IRandom {
    using SafeMath for uint256;




    modifier onlyInitialized {
        require(isInitialized());
        _;
    }




    modifier onlyValidatorSetContract() {
        require(msg.sender == address(validatorSetContract()));
        _;
    }





    function getCurrentSeed() external onlyValidatorSetContract view returns(uint256) {
        return _getCurrentSeed();
    }


    function isInitialized() public view returns(bool) {
        return addressStorage[VALIDATOR_SET_CONTRACT] != address(0);
    }


    function validatorSetContract() public view returns(IValidatorSet) {
        return IValidatorSet(addressStorage[VALIDATOR_SET_CONTRACT]);
    }



    bytes32 internal constant CURRENT_SEED = keccak256("currentSeed");
    bytes32 internal constant VALIDATOR_SET_CONTRACT = keccak256("validatorSetContract");



    function _initialize(address _validatorSet) internal {
        require(!isInitialized());
        require(_validatorSet != address(0));
        addressStorage[VALIDATOR_SET_CONTRACT] = _validatorSet;
    }



    function _setCurrentSeed(uint256 _seed) internal {
        uintStorage[CURRENT_SEED] = _seed;
    }


    function _getCurrentSeed() internal view returns(uint256) {
        return uintStorage[CURRENT_SEED];
    }

}
