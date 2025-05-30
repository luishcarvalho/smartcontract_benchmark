



pragma solidity ^0.5.4;
























interface Module {





    function init(BaseWallet _wallet) external;






    function addModule(BaseWallet _wallet, Module _module) external;






    function recoverToken(address _token) external;
}




















contract BaseWallet {


    address public implementation;

    address public owner;

    mapping (address => bool) public authorised;

    mapping (bytes4 => address) internal enabled;

    uint internal modules;

    event AuthorisedModule(address indexed module, bool value);
    event EnabledStaticCall(address indexed module, bytes4 indexed method);
    event Invoked(address indexed module, address indexed target, uint indexed value, bytes data);
    event Received(uint indexed value, address indexed sender, bytes data);
    event OwnerChanged(address owner);




    modifier moduleOnly {
        require(authorised[msg.sender], "BW: msg.sender not an authorized module");
        _;
    }






    function init(address _owner, address[] calldata _modules) external {
        require(owner == address(0) && modules == 0, "BW: wallet already initialised");
        require(_modules.length > 0, "BW: construction requires at least 1 module");
        owner = _owner;
        modules = _modules.length;
        for (uint256 i = 0; i < _modules.length; i++) {
            require(authorised[_modules[i]] == false, "BW: module is already added");
            authorised[_modules[i]] = true;
            Module(_modules[i]).init(this);
            emit AuthorisedModule(_modules[i], true);
        }
        if (address(this).balance > 0) {
            emit Received(address(this).balance, address(0), "");
        }
    }






    function authoriseModule(address _module, bool _value) external moduleOnly {
        if (authorised[_module] != _value) {
            emit AuthorisedModule(_module, _value);
            if (_value == true) {
                modules += 1;
                authorised[_module] = true;
                Module(_module).init(this);
            } else {
                modules -= 1;
                require(modules > 0, "BW: wallet must have at least one module");
                delete authorised[_module];
            }
        }
    }







    function enableStaticCall(address _module, bytes4 _method) external moduleOnly {
        require(authorised[_module], "BW: must be an authorised module for static call");
        enabled[_method] = _module;
        emit EnabledStaticCall(_module, _method);
    }





    function setOwner(address _newOwner) external moduleOnly {
        require(_newOwner != address(0), "BW: address cannot be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }







    function invoke(address _target, uint _value, bytes calldata _data) external moduleOnly returns (bytes memory _result) {
        bool success;

        (success, _result) = _target.call.value(_value)(_data);
        if (!success) {

            assembly {
                returndatacopy(0, 0, returndatasize)
                revert(0, returndatasize)
            }
        }
        emit Invoked(msg.sender, _target, _value, _data);
    }






    function() external payable {
        if (msg.data.length > 0) {
            address module = enabled[msg.sig];
            if (module == address(0)) {
                emit Received(msg.value, msg.sender, msg.data);
            } else {
                require(authorised[module], "BW: must be an authorised module for static call");

                assembly {
                    calldatacopy(0, 0, calldatasize())
                    let result := staticcall(gas, module, 0, calldatasize(), 0, 0)
                    returndatacopy(0, 0, returndatasize())
                    switch result
                    case 0 {revert(0, returndatasize())}
                    default {return (0, returndatasize())}
                }
            }
        }
    }
}





















contract Owned {


    address internal owner;

    event OwnerChanged(address indexed _newOwner);




    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }





    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}




contract ERC20 {
    function totalSupply() public view returns (uint);
    function decimals() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}






















contract ModuleRegistry is Owned {

    mapping (address => Info) internal modules;
    mapping (address => Info) internal upgraders;

    event ModuleRegistered(address indexed module, bytes32 name);
    event ModuleDeRegistered(address module);
    event UpgraderRegistered(address indexed upgrader, bytes32 name);
    event UpgraderDeRegistered(address upgrader);

    struct Info {
        bool exists;
        bytes32 name;
    }






    function registerModule(address _module, bytes32 _name) external onlyOwner {
        require(!modules[_module].exists, "MR: module already exists");
        modules[_module] = Info({exists: true, name: _name});
        emit ModuleRegistered(_module, _name);
    }





    function deregisterModule(address _module) external onlyOwner {
        require(modules[_module].exists, "MR: module does not exist");
        delete modules[_module];
        emit ModuleDeRegistered(_module);
    }






    function registerUpgrader(address _upgrader, bytes32 _name) external onlyOwner {
        require(!upgraders[_upgrader].exists, "MR: upgrader already exists");
        upgraders[_upgrader] = Info({exists: true, name: _name});
        emit UpgraderRegistered(_upgrader, _name);
    }





    function deregisterUpgrader(address _upgrader) external onlyOwner {
        require(upgraders[_upgrader].exists, "MR: upgrader does not exist");
        delete upgraders[_upgrader];
        emit UpgraderDeRegistered(_upgrader);
    }






    function recoverToken(address _token) external onlyOwner {
        uint total = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(msg.sender, total);
    }






    function moduleInfo(address _module) external view returns (bytes32) {
        return modules[_module].name;
    }






    function upgraderInfo(address _upgrader) external view returns (bytes32) {
        return upgraders[_upgrader].name;
    }






    function isRegisteredModule(address _module) external view returns (bool) {
        return modules[_module].exists;
    }






    function isRegisteredModule(address[] calldata _modules) external view returns (bool) {
        for (uint i = 0; i < _modules.length; i++) {
            if (!modules[_modules[i]].exists) {
                return false;
            }
        }
        return true;
    }






    function isRegisteredUpgrader(address _upgrader) external view returns (bool) {
        return upgraders[_upgrader].exists;
    }
}




















contract Storage {




    modifier onlyModule(BaseWallet _wallet) {
        require(_wallet.authorised(msg.sender), "TS: must be an authorized module to call this method");
        _;
    }
}















interface IGuardianStorage{






    function addGuardian(BaseWallet _wallet, address _guardian) external;






    function revokeGuardian(BaseWallet _wallet, address _guardian) external;







    function isGuardian(BaseWallet _wallet, address _guardian) external view returns (bool);
}

























contract GuardianStorage is IGuardianStorage, Storage {

    struct GuardianStorageConfig {

        address[] guardians;

        mapping (address => GuardianInfo) info;

        uint256 lock;

        address locker;
    }

    struct GuardianInfo {
        bool exists;
        uint128 index;
    }


    mapping (address => GuardianStorageConfig) internal configs;








    function addGuardian(BaseWallet _wallet, address _guardian) external onlyModule(_wallet) {
        GuardianStorageConfig storage config = configs[address(_wallet)];
        config.info[_guardian].exists = true;
        config.info[_guardian].index = uint128(config.guardians.push(_guardian) - 1);
    }






    function revokeGuardian(BaseWallet _wallet, address _guardian) external onlyModule(_wallet) {
        GuardianStorageConfig storage config = configs[address(_wallet)];
        address lastGuardian = config.guardians[config.guardians.length - 1];
        if (_guardian != lastGuardian) {
            uint128 targetIndex = config.info[_guardian].index;
            config.guardians[targetIndex] = lastGuardian;
            config.info[lastGuardian].index = targetIndex;
        }
        config.guardians.length--;
        delete config.info[_guardian];
    }






    function guardianCount(BaseWallet _wallet) external view returns (uint256) {
        return configs[address(_wallet)].guardians.length;
    }






    function getGuardians(BaseWallet _wallet) external view returns (address[] memory) {
        GuardianStorageConfig storage config = configs[address(_wallet)];
        address[] memory guardians = new address[](config.guardians.length);
        for (uint256 i = 0; i < config.guardians.length; i++) {
            guardians[i] = config.guardians[i];
        }
        return guardians;
    }







    function isGuardian(BaseWallet _wallet, address _guardian) external view returns (bool) {
        return configs[address(_wallet)].info[_guardian].exists;
    }






    function setLock(BaseWallet _wallet, uint256 _releaseAfter) external onlyModule(_wallet) {
        configs[address(_wallet)].lock = _releaseAfter;
        if (_releaseAfter != 0 && msg.sender != configs[address(_wallet)].locker) {
            configs[address(_wallet)].locker = msg.sender;
        }
    }






    function isLocked(BaseWallet _wallet) external view returns (bool) {
        return configs[address(_wallet)].lock > now;
    }






    function getLock(BaseWallet _wallet) external view returns (uint256) {
        return configs[address(_wallet)].lock;
    }






    function getLocker(BaseWallet _wallet) external view returns (address) {
        return configs[address(_wallet)].locker;
    }





























library SafeMath {




    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;


        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }




    function ceil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        if(a % b == 0) {
            return c;
        }
        else {
            return c + 1;
        }
    }



    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
}


























contract BaseModule is Module {


    bytes constant internal EMPTY_BYTES = "";


    ModuleRegistry internal registry;

    GuardianStorage internal guardianStorage;




    modifier onlyWhenUnlocked(BaseWallet _wallet) {

        require(!guardianStorage.isLocked(_wallet), "BM: wallet must be unlocked");
        _;
    }

    event ModuleCreated(bytes32 name);
    event ModuleInitialised(address wallet);

    constructor(ModuleRegistry _registry, GuardianStorage _guardianStorage, bytes32 _name) public {
        registry = _registry;
        guardianStorage = _guardianStorage;
        emit ModuleCreated(_name);
    }




    modifier onlyWallet(BaseWallet _wallet) {
        require(msg.sender == address(_wallet), "BM: caller must be wallet");
        _;
    }




    modifier onlyWalletOwner(BaseWallet _wallet) {
        require(msg.sender == address(this) || isOwner(_wallet, msg.sender), "BM: must be an owner for the wallet");
        _;
    }




    modifier strictOnlyWalletOwner(BaseWallet _wallet) {
        require(isOwner(_wallet, msg.sender), "BM: msg.sender must be an owner for the wallet");
        _;
    }






    function init(BaseWallet _wallet) public onlyWallet(_wallet) {
        emit ModuleInitialised(address(_wallet));
    }






    function addModule(BaseWallet _wallet, Module _module) external strictOnlyWalletOwner(_wallet) {
        require(registry.isRegisteredModule(address(_module)), "BM: module is not registered");
        _wallet.authoriseModule(address(_module), true);
    }






    function recoverToken(address _token) external {
        uint total = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(address(registry), total);
    }






    function isOwner(BaseWallet _wallet, address _addr) internal view returns (bool) {
        return _wallet.owner() == _addr;
    }








    function invokeWallet(address _wallet, address _to, uint256 _value, bytes memory _data) internal returns (bytes memory _res) {
        bool success;

        (success, _res) = _wallet.call(abi.encodeWithSignature("invoke(address,uint256,bytes)", _to, _value, _data));
        if (success && _res.length > 0) {
            (_res) = abi.decode(_res, (bytes));
        } else if (_res.length > 0) {

            assembly {
                returndatacopy(0, 0, returndatasize)
                revert(0, returndatasize)
            }
        } else if (!success) {
            revert("BM: wallet invoke reverted");
        }
    }
}
















library GuardianUtils {








    function isGuardian(address[] memory _guardians, address _guardian) internal view returns (bool, address[] memory) {
        if (_guardians.length == 0 || _guardian == address(0)) {
            return (false, _guardians);
        }
        bool isFound = false;
        address[] memory updatedGuardians = new address[](_guardians.length - 1);
        uint256 index = 0;
        for (uint256 i = 0; i < _guardians.length; i++) {
            if (!isFound) {

                if (_guardian == _guardians[i]) {
                    isFound = true;
                    continue;
                }

                if (isContract(_guardians[i]) && isGuardianOwner(_guardians[i], _guardian)) {
                    isFound = true;
                    continue;
                }
            }
            if (index < updatedGuardians.length) {
                updatedGuardians[index] = _guardians[i];
                index++;
            }
        }
        return isFound ? (true, updatedGuardians) : (false, _guardians);
    }





    function isContract(address _addr) internal view returns (bool) {
        uint32 size;

        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }







    function isGuardianOwner(address _guardian, address _owner) internal view returns (bool) {
        address owner = address(0);
        bytes4 sig = bytes4(keccak256("owner()"));

        assembly {
            let ptr := mload(0x40)
            mstore(ptr,sig)
            let result := staticcall(5000, _guardian, ptr, 0x20, ptr, 0x20)
            if eq(result, 1) {
                owner := mload(ptr)
            }
        }
        return owner == _owner;
    }
}

























contract RelayerModuleV2 is BaseModule {

    uint256 constant internal BLOCKBOUND = 10000;

    mapping (address => RelayerConfig) internal relayer;

    struct RelayerConfig {
        uint256 nonce;
        mapping (bytes32 => bool) executedTx;
    }

    enum OwnerSignature {
        Required,
        Optional,
        Disallowed
    }

    event TransactionExecuted(address indexed wallet, bool indexed success, bytes32 signedHash);




    modifier onlyExecute {
        require(msg.sender == address(this), "RM: must be called via execute()");
        _;
    }










    function getRequiredSignatures(BaseWallet _wallet, bytes memory _data) public view returns (uint256);










    function validateSignatures(
        BaseWallet _wallet,
        bytes memory _data,
        bytes32 _signHash,
        bytes memory _signatures
    )
        internal view returns (bool);












    function execute(
        BaseWallet _wallet,
        bytes calldata _data,
        uint256 _nonce,
        bytes calldata _signatures,
        uint256 _gasPrice,
        uint256 _gasLimit
    )
        external
        returns (bool success)
    {
        uint startGas = gasleft();
        bytes32 signHash = getSignHash(address(this), address(_wallet), 0, _data, _nonce, _gasPrice, _gasLimit);
        require(checkAndUpdateUniqueness(_wallet, _nonce, signHash), "RM: Duplicate request");
        require(verifyData(address(_wallet), _data), "RM: Target of _data != _wallet");
        uint256 requiredSignatures = getRequiredSignatures(_wallet, _data);
        require(requiredSignatures * 65 == _signatures.length, "RM: Wrong number of signatures");
        require(requiredSignatures == 0 || validateSignatures(_wallet, _data, signHash, _signatures), "RM: Invalid signatures");


        if (verifyRefund(_wallet, _gasLimit, _gasPrice, requiredSignatures)) {

            (success,) = address(this).call(_data);
            refund(_wallet, startGas - gasleft(), _gasPrice, _gasLimit, requiredSignatures, msg.sender);
        }
        emit TransactionExecuted(address(_wallet), success, signHash);
    }





    function getNonce(BaseWallet _wallet) external view returns (uint256 nonce) {
        return relayer[address(_wallet)].nonce;
    }













    function getSignHash(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit
    )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(byte(0x19), byte(0), _from, _to, _value, _data, _nonce, _gasPrice, _gasLimit))
        ));
    }







    function checkAndUpdateUniqueness(BaseWallet _wallet, uint256 _nonce, bytes32 _signHash) internal returns (bool) {
        if (relayer[address(_wallet)].executedTx[_signHash] == true) {
            return false;
        }
        relayer[address(_wallet)].executedTx[_signHash] = true;
        return true;
    }







    function checkAndUpdateNonce(BaseWallet _wallet, uint256 _nonce) internal returns (bool) {
        if (_nonce <= relayer[address(_wallet)].nonce) {
            return false;
        }
        uint256 nonceBlock = (_nonce & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128;
        if (nonceBlock > block.number + BLOCKBOUND) {
            return false;
        }
        relayer[address(_wallet)].nonce = _nonce;
        return true;
    }









    function validateSignatures(
        BaseWallet _wallet,
        bytes32 _signHash,
        bytes memory _signatures,
        OwnerSignature _option
    )
        internal view returns (bool)
    {
        address lastSigner = address(0);
        address[] memory guardians;
        if (_option != OwnerSignature.Required || _signatures.length > 65) {
            guardians = guardianStorage.getGuardians(_wallet);
        }
        bool isGuardian;

        for (uint8 i = 0; i < _signatures.length / 65; i++) {
            address signer = recoverSigner(_signHash, _signatures, i);

            if (i == 0) {
                if (_option == OwnerSignature.Required) {

                    if (isOwner(_wallet, signer)) {
                        continue;
                    }
                    return false;
                } else if (_option == OwnerSignature.Optional) {

                    if (isOwner(_wallet, signer)) {
                        continue;
                    }
                }
            }
            if (signer <= lastSigner) {
                return false;
            }
            lastSigner = signer;
            (isGuardian, guardians) = GuardianUtils.isGuardian(guardians, signer);
            if (!isGuardian) {
                return false;
            }
        }
        return true;
    }







    function recoverSigner(bytes32 _signedHash, bytes memory _signatures, uint _index) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;




        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28);
        return ecrecover(_signedHash, v, r, s);
    }











    function refund(
        BaseWallet _wallet,
        uint _gasUsed,
        uint _gasPrice,
        uint _gasLimit,
        uint _signatures,
        address _relayer
    )
        internal
    {
        uint256 amount = 29292 + _gasUsed;

        if (_gasPrice > 0 && _signatures > 1 && amount <= _gasLimit) {
            if (_gasPrice > tx.gasprice) {
                amount = amount * tx.gasprice;
            } else {
                amount = amount * _gasPrice;
            }
            invokeWallet(address(_wallet), _relayer, amount, EMPTY_BYTES);
        }
    }







    function verifyRefund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _signatures) internal view returns (bool) {
        if (_gasPrice > 0 &&
            _signatures > 1 &&
            (address(_wallet).balance < _gasUsed * _gasPrice || _wallet.authorised(address(this)) == false)) {
            return false;
        }
        return true;
    }




    function functionPrefix(bytes memory _data) internal pure returns (bytes4 prefix) {
        require(_data.length >= 4, "RM: Invalid functionPrefix");

        assembly {
            prefix := mload(add(_data, 0x20))
        }
    }






    function verifyData(address _wallet, bytes memory _data) private pure returns (bool) {
        require(_data.length >= 36, "RM: Invalid dataWallet");
        address dataWallet;

        assembly {

            dataWallet := mload(add(_data, 0x24))
        }
        return dataWallet == _wallet;
    }
}



























contract RecoveryManager is BaseModule, RelayerModuleV2 {

    bytes32 constant NAME = "RecoveryManager";

    bytes4 constant internal EXECUTE_RECOVERY_PREFIX = bytes4(keccak256("executeRecovery(address,address)"));
    bytes4 constant internal FINALIZE_RECOVERY_PREFIX = bytes4(keccak256("finalizeRecovery(address)"));
    bytes4 constant internal CANCEL_RECOVERY_PREFIX = bytes4(keccak256("cancelRecovery(address)"));
    bytes4 constant internal TRANSFER_OWNERSHIP_PREFIX = bytes4(keccak256("transferOwnership(address,address)"));

    struct RecoveryConfig {
        address recovery;
        uint64 executeAfter;
        uint32 guardianCount;
    }


    mapping (address => RecoveryConfig) internal recoveryConfigs;


    uint256 internal recoveryPeriod;

    uint256 internal lockPeriod;

    uint256 public securityPeriod;

    uint256 public securityWindow;

    GuardianStorage internal guardianStorage;



    event RecoveryExecuted(address indexed wallet, address indexed _recovery, uint64 executeAfter);
    event RecoveryFinalized(address indexed wallet, address indexed _recovery);
    event RecoveryCanceled(address indexed wallet, address indexed _recovery);
    event OwnershipTransfered(address indexed wallet, address indexed _newOwner);






    modifier onlyWhenRecovery(BaseWallet _wallet) {
        require(recoveryConfigs[address(_wallet)].executeAfter > 0, "RM: there must be an ongoing recovery");
        _;
    }




    modifier notWhenRecovery(BaseWallet _wallet) {
        require(recoveryConfigs[address(_wallet)].executeAfter == 0, "RM: there cannot be an ongoing recovery");
        _;
    }



    constructor(
        ModuleRegistry _registry,
        GuardianStorage _guardianStorage,
        uint256 _recoveryPeriod,
        uint256 _lockPeriod,
        uint256 _securityPeriod,
        uint256 _securityWindow
    )
        BaseModule(_registry, _guardianStorage, NAME)
        public
    {
        require(_lockPeriod >= _recoveryPeriod && _recoveryPeriod >= _securityPeriod + _securityWindow, "RM: insecure security periods");
        guardianStorage = _guardianStorage;
        recoveryPeriod = _recoveryPeriod;
        lockPeriod = _lockPeriod;
        securityPeriod = _securityPeriod;
        securityWindow = _securityWindow;
    }











    function executeRecovery(BaseWallet _wallet, address _recovery) external onlyExecute notWhenRecovery(_wallet) {
        require(_recovery != address(0), "RM: recovery address cannot be null");
        RecoveryConfig storage config = recoveryConfigs[address(_wallet)];
        config.recovery = _recovery;
        config.executeAfter = uint64(now + recoveryPeriod);
        config.guardianCount = uint32(guardianStorage.guardianCount(_wallet));
        guardianStorage.setLock(_wallet, now + lockPeriod);
        emit RecoveryExecuted(address(_wallet), _recovery, config.executeAfter);
    }






    function finalizeRecovery(BaseWallet _wallet) external onlyWhenRecovery(_wallet) {
        RecoveryConfig storage config = recoveryConfigs[address(_wallet)];
        require(uint64(now) > config.executeAfter, "RM: the recovery period is not over yet");
        _wallet.setOwner(config.recovery);
        emit RecoveryFinalized(address(_wallet), config.recovery);
        guardianStorage.setLock(_wallet, 0);
        delete recoveryConfigs[address(_wallet)];
    }






    function cancelRecovery(BaseWallet _wallet) external onlyExecute onlyWhenRecovery(_wallet) {
        RecoveryConfig storage config = recoveryConfigs[address(_wallet)];
        emit RecoveryCanceled(address(_wallet), config.recovery);
        guardianStorage.setLock(_wallet, 0);
        delete recoveryConfigs[address(_wallet)];
    }








    function transferOwnership(BaseWallet _wallet, address _newOwner) external onlyExecute onlyWhenUnlocked(_wallet) {
        require(_newOwner != address(0), "RM: new owner address cannot be null");
        _wallet.setOwner(_newOwner);

        emit OwnershipTransfered(address(_wallet), _newOwner);
    }





    function getRecovery(BaseWallet _wallet) public view returns(address _address, uint64 _executeAfter, uint32 _guardianCount) {
        RecoveryConfig storage config = recoveryConfigs[address(_wallet)];
        return (config.recovery, config.executeAfter, config.guardianCount);
    }



    function validateSignatures(
        BaseWallet _wallet,
        bytes memory _data,
        bytes32 _signHash,
        bytes memory _signatures
    )
        internal view returns (bool)
    {
        bytes4 functionSignature = functionPrefix(_data);
        if (functionSignature == TRANSFER_OWNERSHIP_PREFIX) {
            return validateSignatures(_wallet, _signHash, _signatures, OwnerSignature.Required);
        } else if (functionSignature == EXECUTE_RECOVERY_PREFIX) {
            return validateSignatures(_wallet, _signHash, _signatures, OwnerSignature.Disallowed);
        } else if (functionSignature == CANCEL_RECOVERY_PREFIX) {
            return validateSignatures(_wallet, _signHash, _signatures, OwnerSignature.Optional);
        }
    }

    function getRequiredSignatures(BaseWallet _wallet, bytes memory _data) public view returns (uint256) {
        bytes4 methodId = functionPrefix(_data);
        if (methodId == EXECUTE_RECOVERY_PREFIX) {
            uint walletGuardians = guardianStorage.guardianCount(_wallet);
            require(walletGuardians > 0, "RM: no guardians set on wallet");
            return SafeMath.ceil(walletGuardians, 2);
        }
        if (methodId == FINALIZE_RECOVERY_PREFIX) {
            return 0;
        }
        if (methodId == CANCEL_RECOVERY_PREFIX) {
            return SafeMath.ceil(recoveryConfigs[address(_wallet)].guardianCount + 1, 2);
        }
        if (methodId == TRANSFER_OWNERSHIP_PREFIX) {
            uint majorityGuardians = SafeMath.ceil(guardianStorage.guardianCount(_wallet), 2);
            return SafeMath.add(majorityGuardians, 1);
        }
        revert("RM: unknown method");
    }
}
