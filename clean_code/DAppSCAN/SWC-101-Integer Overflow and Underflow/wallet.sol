


















pragma solidity ^0.4.25;

import "./licence.sol";
import "./internals/ownable.sol";
import "./internals/controllable.sol";
import "./internals/ensResolvable.sol";
import "./internals/tokenWhitelistable.sol";
import "./externals/SafeMath.sol";
import "./externals/ERC20.sol";
import "./externals/ERC165.sol";




contract ControllableOwnable is Controllable, Ownable {

    modifier onlyOwnerOrController() {
        require (_isOwner(msg.sender) || _isController(msg.sender), "either owner or controller");
        _;
    }
}





contract AddressWhitelist is ControllableOwnable {
    using SafeMath for uint256;

    event AddedToWhitelist(address _sender, address[] _addresses);
    event SubmittedWhitelistAddition(address[] _addresses, bytes32 _hash);
    event CancelledWhitelistAddition(address _sender, bytes32 _hash);

    event RemovedFromWhitelist(address _sender, address[] _addresses);
    event SubmittedWhitelistRemoval(address[] _addresses, bytes32 _hash);
    event CancelledWhitelistRemoval(address _sender, bytes32 _hash);

    mapping(address => bool) public whitelistMap;
    address[] public whitelistArray;
    address[] private _pendingWhitelistAddition;
    address[] private _pendingWhitelistRemoval;
    bool public submittedWhitelistAddition;
    bool public submittedWhitelistRemoval;
    bool public isSetWhitelist;


    modifier hasNoOwnerOrZeroAddress(address[] _addresses) {
        for (uint i = 0; i < _addresses.length; i++) {
            require(!_isOwner(_addresses[i]), "provided whitelist contains the owner address");
            require(_addresses[i] != address(0), "provided whitelist contains the zero address");
        }
        _;
    }


    modifier noActiveSubmission() {
        require(!submittedWhitelistAddition && !submittedWhitelistRemoval, "whitelist operation has already been submitted");
        _;
    }


    function pendingWhitelistAddition() external view returns (address[]) {
        return _pendingWhitelistAddition;
    }


    function pendingWhitelistRemoval() external view returns (address[]) {
        return _pendingWhitelistRemoval;
    }



    function setWhitelist(address[] _addresses) external onlyOwner hasNoOwnerOrZeroAddress(_addresses) {

        require(!isSetWhitelist, "whitelist has already been initialized");

        for (uint i = 0; i < _addresses.length; i++) {

            whitelistMap[_addresses[i]] = true;

            whitelistArray.push(_addresses[i]);
        }
        isSetWhitelist = true;

        emit AddedToWhitelist(msg.sender, _addresses);
    }



    function submitWhitelistAddition(address[] _addresses) external onlyOwner noActiveSubmission hasNoOwnerOrZeroAddress(_addresses) {

        require(isSetWhitelist, "whitelist has not been initialized");

        require(_addresses.length > 0, "pending whitelist addition is empty");

        _pendingWhitelistAddition = _addresses;

        submittedWhitelistAddition = true;

        emit SubmittedWhitelistAddition(_addresses, calculateHash(_addresses));
    }




    function confirmWhitelistAddition(bytes32 _hash) external onlyController {

        require(submittedWhitelistAddition, "whitelist addition has not been submitted");

        require(_hash == calculateHash(_pendingWhitelistAddition), "hash of the pending whitelist addition do not match");

        for (uint i = 0; i < _pendingWhitelistAddition.length; i++) {

            if (!whitelistMap[_pendingWhitelistAddition[i]]) {

                whitelistMap[_pendingWhitelistAddition[i]] = true;
                whitelistArray.push(_pendingWhitelistAddition[i]);
            }
        }

        emit AddedToWhitelist(msg.sender, _pendingWhitelistAddition);

        delete _pendingWhitelistAddition;

        submittedWhitelistAddition = false;
    }


    function cancelWhitelistAddition(bytes32 _hash) external onlyOwnerOrController {

        require(submittedWhitelistAddition, "whitelist addition has not been submitted");

        require(_hash == calculateHash(_pendingWhitelistAddition), "hash of the pending whitelist addition does not match");

        delete _pendingWhitelistAddition;

        submittedWhitelistAddition = false;

        emit CancelledWhitelistAddition(msg.sender, _hash);
    }



    function submitWhitelistRemoval(address[] _addresses) external onlyOwner noActiveSubmission {

        require(isSetWhitelist, "whitelist has not been initialized");

        require(_addresses.length > 0, "pending whitelist removal is empty");

        _pendingWhitelistRemoval = _addresses;

        submittedWhitelistRemoval = true;

        emit SubmittedWhitelistRemoval(_addresses, calculateHash(_addresses));
    }


    function confirmWhitelistRemoval(bytes32 _hash) external onlyController {

        require(submittedWhitelistRemoval, "whitelist removal has not been submitted");

        require(_hash == calculateHash(_pendingWhitelistRemoval), "hash of the pending whitelist removal does not match the confirmed hash");

        for (uint i = 0; i < _pendingWhitelistRemoval.length; i++) {

            if (whitelistMap[_pendingWhitelistRemoval[i]]) {
                whitelistMap[_pendingWhitelistRemoval[i]] = false;
                for (uint j = 0; j < whitelistArray.length.sub(1); j++) {
                    if (whitelistArray[j] == _pendingWhitelistRemoval[i]) {
                        whitelistArray[j] = whitelistArray[whitelistArray.length - 1];
                        break;
                    }
                }
                whitelistArray.length--;
            }
        }

        emit RemovedFromWhitelist(msg.sender, _pendingWhitelistRemoval);

        delete _pendingWhitelistRemoval;

        submittedWhitelistRemoval = false;
    }


    function cancelWhitelistRemoval(bytes32 _hash) external onlyOwnerOrController {

        require(submittedWhitelistRemoval, "whitelist removal has not been submitted");

        require(_hash == calculateHash(_pendingWhitelistRemoval), "hash of the pending whitelist removal do not match");

        delete _pendingWhitelistRemoval;

        submittedWhitelistRemoval = false;

        emit CancelledWhitelistRemoval(msg.sender, _hash);
    }


    function calculateHash(address[] _addresses) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addresses));
    }
}




contract DailyLimitTrait {
    using SafeMath for uint256;

    struct DailyLimit {
        uint value;
        uint available;
        uint limitDay;
        uint pending;
        bool set;
    }



    function _getAvailableLimit(DailyLimit storage dl) internal view returns (uint) {
        if (now > dl.limitDay + 24 hours) {
            return dl.value;
        } else {
            return dl.available;
        }
    }


    function _enforceLimit(DailyLimit storage dl, uint _amount) internal {

        _updateAvailableLimit(dl);
        require(dl.available >= _amount, "available has to be greater or equal to use amount");
        dl.available = dl.available.sub(_amount);
    }



    function _setLimit(DailyLimit storage dl, uint _amount) internal {

        require(!dl.set, "daily limit has already been set");

        _modifyLimit(dl, _amount);

        dl.set = true;
    }



    function _submitLimitUpdate(DailyLimit storage dl, uint _amount) internal {

        require(dl.set, "limit has not been set");

        dl.pending = _amount;
    }


    function _confirmLimitUpdate(DailyLimit storage dl, uint _amount) internal {

        require(dl.pending == _amount, "confirmed and submitted limits dont match");

        _modifyLimit(dl, dl.pending);
    }


    function _updateAvailableLimit(DailyLimit storage dl) private {
        if (now > dl.limitDay.add(24 hours)) {

            uint extraDays = now.sub(dl.limitDay).div(24 hours);
            dl.limitDay = dl.limitDay.add(extraDays.mul(24 hours));

            dl.available = dl.value;
        }
    }



    function _modifyLimit(DailyLimit storage dl, uint _amount) private {

        _updateAvailableLimit(dl);

        dl.value = _amount;

        if (dl.available > dl.value) {
            dl.available = dl.value;
        }
    }
}



contract SpendLimit is ControllableOwnable, DailyLimitTrait {
    event SetSpendLimit(address _sender, uint _amount);
    event SubmittedSpendLimitUpdate(uint _amount);

    DailyLimit internal _spendLimit;


    constructor(uint _limit_) internal {
        _spendLimit = DailyLimit(_limit_, _limit_, now, 0, false);
    }



    function setSpendLimit(uint _amount) external onlyOwner {
        _setLimit(_spendLimit, _amount);
        emit SetSpendLimit(msg.sender, _amount);
    }



    function submitSpendLimitUpdate(uint _amount) external onlyOwner {
        _submitLimitUpdate(_spendLimit, _amount);
        emit SubmittedSpendLimitUpdate(_amount);
    }


    function confirmSpendLimitUpdate(uint _amount) external onlyController {
        _confirmLimitUpdate(_spendLimit, _amount);
        emit SetSpendLimit(msg.sender, _amount);
    }

    function spendLimitAvailable() external view returns (uint) {
        return _getAvailableLimit(_spendLimit);
    }

    function spendLimitValue() external view returns (uint) {
        return _spendLimit.value;
    }

    function spendLimitSet() external view returns (bool) {
        return _spendLimit.set;
    }

    function spendLimitPending() external view returns (uint) {
        return _spendLimit.pending;
    }
}



contract GasTopUpLimit is ControllableOwnable, DailyLimitTrait {

    event SetGasTopUpLimit(address _sender, uint _amount);
    event SubmittedGasTopUpLimitUpdate(uint _amount);

    uint constant private _MINIMUM_GAS_TOPUP_LIMIT = 1 finney;
    uint constant private _MAXIMUM_GAS_TOPUP_LIMIT = 500 finney;

    DailyLimit internal _gasTopUpLimit;


    constructor() internal {
        _gasTopUpLimit = DailyLimit(_MAXIMUM_GAS_TOPUP_LIMIT, _MAXIMUM_GAS_TOPUP_LIMIT, now, 0, false);
    }



    function setGasTopUpLimit(uint _amount) external onlyOwner {
        require(_MINIMUM_GAS_TOPUP_LIMIT <= _amount && _amount <= _MAXIMUM_GAS_TOPUP_LIMIT, "gas top up amount is outside the min/max range");
        _setLimit(_gasTopUpLimit, _amount);
        emit SetGasTopUpLimit(msg.sender, _amount);
    }



    function submitGasTopUpLimitUpdate(uint _amount) external onlyOwner {
        require(_MINIMUM_GAS_TOPUP_LIMIT <= _amount && _amount <= _MAXIMUM_GAS_TOPUP_LIMIT, "gas top up amount is outside the min/max range");
        _submitLimitUpdate(_gasTopUpLimit, _amount);
        emit SubmittedGasTopUpLimitUpdate(_amount);
    }


    function confirmGasTopUpLimitUpdate(uint _amount) external onlyController {
        _confirmLimitUpdate(_gasTopUpLimit, _amount);
        emit SetGasTopUpLimit(msg.sender, _amount);
    }

    function gasTopUpLimitAvailable() external view returns (uint) {
        return _getAvailableLimit(_gasTopUpLimit);
    }

    function gasTopUpLimitValue() external view returns (uint) {
        return _gasTopUpLimit.value;
    }

    function gasTopUpLimitSet() external view returns (bool) {
        return _gasTopUpLimit.set;
    }

    function gasTopUpLimitPending() external view returns (uint) {
        return _gasTopUpLimit.pending;
    }
}



contract LoadLimit is ControllableOwnable, DailyLimitTrait {

    event SetLoadLimit(address _sender, uint _amount);
    event SubmittedLoadLimitUpdate(uint _amount);

    uint constant private _MINIMUM_LOAD_LIMIT = 1 finney;
    uint private _maximumLoadLimit;

    DailyLimit internal _loadLimit;



    function setLoadLimit(uint _amount) external onlyOwner {
        require(_MINIMUM_LOAD_LIMIT <= _amount && _amount <= _maximumLoadLimit, "card load amount is outside the min/max range");
        _setLimit(_loadLimit, _amount);
        emit SetLoadLimit(msg.sender, _amount);
    }



    function submitLoadLimitUpdate(uint _amount) external onlyOwner {
        require(_MINIMUM_LOAD_LIMIT <= _amount && _amount <= _maximumLoadLimit, "card load amount is outside the min/max range");
        _submitLimitUpdate(_loadLimit, _amount);
        emit SubmittedLoadLimitUpdate(_amount);
    }


    function confirmLoadLimitUpdate(uint _amount) external onlyController {
        _confirmLimitUpdate(_loadLimit, _amount);
        emit SetLoadLimit(msg.sender, _amount);
    }

    function loadLimitAvailable() external view returns (uint) {
        return _getAvailableLimit(_loadLimit);
    }

    function loadLimitValue() external view returns (uint) {
        return _loadLimit.value;
    }

    function loadLimitSet() external view returns (bool) {
        return _loadLimit.set;
    }

    function loadLimitPending() external view returns (uint) {
        return _loadLimit.pending;
    }



    function _initializeLoadLimit(uint _maxLimit) internal {
        _maximumLoadLimit = _maxLimit;
        _loadLimit = DailyLimit(_maximumLoadLimit, _maximumLoadLimit, now, 0, false);
    }
}



contract Vault is AddressWhitelist, SpendLimit, ERC165, TokenWhitelistable {

    using SafeMath for uint256;

    event Received(address _from, uint _amount);
    event Transferred(address _to, address _asset, uint _amount);


    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;







    constructor(address _owner_, bool _transferable_, bytes32 _tokenWhitelistNameHash_, bytes32 _controllerNameHash_, uint _spendLimit_) SpendLimit(_spendLimit_) Ownable(_owner_, _transferable_) Controllable(_controllerNameHash_) TokenWhitelistable(_tokenWhitelistNameHash_) public {}


    modifier isNotZero(uint _value) {
        require(_value != 0, "provided value cannot be zero");
        _;
    }


    function() external payable {
        require(msg.data.length == 0, "msg data needs to be empty");
        emit Received(msg.sender, msg.value);
    }




    function balance(address _asset) external view returns (uint) {
        if (_asset != address(0)) {
            return ERC20(_asset).balanceOf(this);
        } else {
            return address(this).balance;
        }
    }





    function transfer(address _to, address _asset, uint _amount) external onlyOwner isNotZero(_amount) {

        require(_to != address(0), "_to address cannot be set to 0x0");


        if (!whitelistMap[_to]) {

            uint etherValue = _amount;

            if (_asset != address(0)) {
                etherValue = convertToEther(_asset, _amount);
            }


            _enforceLimit(_spendLimit, etherValue);
        }

        if (_asset != address(0)) {
            require(ERC20(_asset).transfer(_to, _amount), "ERC20 token transfer was unsuccessful");
        } else {
            _to.transfer(_amount);
        }

        emit Transferred(_to, _asset, _amount);
    }


    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return interfaceID == _ERC165_INTERFACE_ID;
    }




    function convertToEther(address _token, uint _amount) public view returns (uint) {

        (,uint256 magnitude, uint256 rate, bool available, , , ) = _getTokenInfo(_token);

        if (available) {
            require(rate != 0, "token rate is 0");


            return _amount.mul(rate).div(magnitude);
        }
        return 0;
    }
}



contract Wallet is ENSResolvable, Vault, GasTopUpLimit, LoadLimit {

    event ToppedUpGas(address _sender, address _owner, uint _amount);
    event LoadedTokenCard(address _asset, uint _amount);
    event ExecutedTransaction(address _destination, uint _value, bytes _data);

    uint constant private _DEFAULT_MAX_STABLECOIN_LOAD_LIMIT = 10000;


    bytes32 private _licenceNode;


    uint32 private constant _TRANSFER= 0xa9059cbb;
    uint32 private constant _APPROVE = 0x095ea7b3;









    constructor(address _owner_, bool _transferable_, address _ens_, bytes32 _tokenWhitelistNameHash_, bytes32 _controllerNameHash_, bytes32 _licenceNameHash_, uint _spendLimit_) ENSResolvable(_ens_) Vault(_owner_, _transferable_, _tokenWhitelistNameHash_, _controllerNameHash_, _spendLimit_) public {

        ( ,uint256 stablecoinMagnitude, , , , , ) = _getStablecoinInfo();
        require(stablecoinMagnitude > 0, "stablecoin not set");
        _initializeLoadLimit(_DEFAULT_MAX_STABLECOIN_LOAD_LIMIT * stablecoinMagnitude);
        _licenceNode = _licenceNameHash_;
    }



    function topUpGas(uint _amount) external isNotZero(_amount) onlyOwnerOrController {

        _enforceLimit(_gasTopUpLimit, _amount);

        owner().transfer(_amount);

        emit ToppedUpGas(msg.sender, owner(), _amount);
    }





    function loadTokenCard(address _asset, uint _amount) external payable onlyOwner {

        require(_isTokenLoadable(_asset), "token not loadable");

        uint stablecoinValue = convertToStablecoin(_asset, _amount);

        _enforceLimit(_loadLimit, stablecoinValue);

        address licenceAddress = _ensResolve(_licenceNode);
        if (_asset != address(0)) {
            require(ERC20(_asset).approve(licenceAddress, _amount), "ERC20 token approval was unsuccessful");
            ILicence(licenceAddress).load(_asset, _amount);
        } else {
            ILicence(licenceAddress).load.value(_amount)(_asset, _amount);
        }

        emit LoadedTokenCard(_asset, _amount);

    }





    function executeTransaction(address _destination, uint _value, bytes _data) external onlyOwner {

        if (_data.length >= 4) {

            uint32 signature = _bytesToUint32(_data, 0);


            if (signature == _TRANSFER || signature == _APPROVE) {
                require(_data.length >= 4 + 32 + 32, "invalid transfer / approve transaction data");
                uint amount = _sliceUint(_data, 4 + 32);


                address toOrSpender = _bytesToAddress(_data, 4 + 12);


                if (!whitelistMap[toOrSpender]) {


                    uint etherValue = convertToEther(_destination, amount);
                    _enforceLimit(_spendLimit, etherValue);
                }
            }
        }



        if (!whitelistMap[_destination]) {
            _enforceLimit(_spendLimit, _value);
        }

        require(_externalCall(_destination, _value, _data.length, _data), "executing transaction failed");

        emit ExecutedTransaction(_destination, _value, _data);
    }


    function licenceNode() external view returns (bytes32) {
        return _licenceNode;
    }




    function convertToStablecoin(address _token, uint _amount) public view returns (uint) {

        if (_token == _stablecoin()) {
            return _amount;
        }

        if (_token != address(0)) {


            (,uint256 magnitude, uint256 rate, bool available, , , ) = _getTokenInfo(_token);

            require(available, "token is not available");
            require(rate != 0, "token rate is 0");

            _amount = _amount.mul(rate).div(magnitude);
        }


        ( ,uint256 stablecoinMagnitude, uint256 stablecoinRate, bool stablecoinAvailable, , , ) = _getStablecoinInfo();

        require(stablecoinAvailable, "token is not available");
        require(stablecoinRate != 0, "stablecoin rate is 0");


        return _amount.mul(stablecoinMagnitude).div(stablecoinRate);
    }











    function _externalCall(address _destination, uint _value, uint _dataLength, bytes _data) private returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)
            let d := add(_data, 32)
            result := call(
                sub(gas, 34710),


                _destination,
                _value,
                d,
                _dataLength,
                x,
                0
            )
        }

        return result;
    }




    function _bytesToAddress(bytes _bts, uint _from) private pure returns (address) {
        require(_bts.length >= _from + 20, "slicing out of range");

        uint160 m = 0;
        uint160 b = 0;

        for (uint8 i = 0; i < 20; i++) {
            m *= 256;
            b = uint160 (_bts[_from + i]);
            m += (b);
        }

        return address(m);
    }




    function _bytesToUint32(bytes _bts, uint _from) private pure returns (uint32) {
        require(_bts.length >= _from + 4, "slicing out of range");

        uint32 m = 0;
        uint32 b = 0;

        for (uint8 i = 0; i < 4; i++) {
            m *= 256;
            b = uint32 (_bts[_from + i]);
            m += (b);
        }

        return m;
    }






    function _sliceUint(bytes _bts, uint _from) private pure returns (uint) {
        require(_bts.length >= _from + 32, "slicing out of range");

        uint x;
        assembly {
            x := mload(add(_bts, add(0x20, _from)))
        }

        return x;
    }

}
