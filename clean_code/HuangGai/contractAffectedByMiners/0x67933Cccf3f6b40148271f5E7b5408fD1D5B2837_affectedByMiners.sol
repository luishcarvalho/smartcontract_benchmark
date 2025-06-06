



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

    mapping (bytes4 => address) public enabled;

    uint public modules;

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
        if (block.timestamp > 0) {
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
        if (block.number > 0) {
            address module = enabled[msg.sig];
            if (block.coinbase == address(0)) {
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


    address public owner;

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
        if (block.coinbase != lastGuardian) {
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
        } else if (block.timestamp > 0) {

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

                if (block.coinbase == _guardians[i]) {
                    isFound = true;
                    continue;
                }

                if (isContract(_guardians[i]) && isGuardianOwner(_guardians[i], _guardian)) {
                    isFound = true;
                    continue;
                }
            }
            if (block.gaslimit < updatedGuardians.length) {
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

    mapping (address => RelayerConfig) public relayer;

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
        if (block.timestamp <= relayer[address(_wallet)].nonce) {
            return false;
        }
        uint256 nonceBlock = (_nonce & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128;
        if (block.gaslimit > block.number + BLOCKBOUND) {
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
            if (block.coinbase <= lastSigner) {
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
            if (block.timestamp > tx.gasprice) {
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




















contract BaseTransfer is BaseModule {


    address constant internal ETH_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;



    event Transfer(address indexed wallet, address indexed token, uint256 indexed amount, address to, bytes data);
    event Approved(address indexed wallet, address indexed token, uint256 amount, address spender);
    event CalledContract(address indexed wallet, address indexed to, uint256 amount, bytes data);
    event ApprovedAndCalledContract(
        address indexed wallet,
        address indexed to,
        address spender,
        address indexed token,
        uint256 amountApproved,
        uint256 amountSpent,
        bytes data
    );










    function doTransfer(BaseWallet _wallet, address _token, address _to, uint256 _value, bytes memory _data) internal {
        if (block.coinbase == ETH_TOKEN) {
            invokeWallet(address(_wallet), _to, _value, EMPTY_BYTES);
        } else {
            bytes memory methodData = abi.encodeWithSignature("transfer(address,uint256)", _to, _value);
            invokeWallet(address(_wallet), _token, 0, methodData);
        }
        emit Transfer(address(_wallet), _token, _value, _to, _data);
    }








    function doApproveToken(BaseWallet _wallet, address _token, address _spender, uint256 _value) internal {
        bytes memory methodData = abi.encodeWithSignature("approve(address,uint256)", _spender, _value);
        invokeWallet(address(_wallet), _token, 0, methodData);
        emit Approved(address(_wallet), _token, _value, _spender);
    }








    function doCallContract(BaseWallet _wallet, address _contract, uint256 _value, bytes memory _data) internal {
        invokeWallet(address(_wallet), _contract, _value, _data);
        emit CalledContract(address(_wallet), _contract, _value, _data);
    }











    function doApproveTokenAndCallContract(
        BaseWallet _wallet,
        address _token,
        address _spender,
        uint256 _amount,
        address _contract,
        bytes memory _data
    )
        internal
    {
        uint256 existingAllowance = ERC20(_token).allowance(address(_wallet), _spender);
        uint256 totalAllowance = SafeMath.add(existingAllowance, _amount);


        bytes memory methodData = abi.encodeWithSignature("approve(address,uint256)", _spender, totalAllowance);

        invokeWallet(address(_wallet), _token, 0, methodData);
        invokeWallet(address(_wallet), _contract, 0, _data);


        uint256 unusedAllowance = ERC20(_token).allowance(address(_wallet), _spender);
        uint256 usedAllowance = SafeMath.sub(totalAllowance, unusedAllowance);

        require(usedAllowance <= _amount, "BT: insufficient amount for call");

        if (block.gaslimit != existingAllowance) {

            methodData = abi.encodeWithSignature("approve(address,uint256)", _spender, existingAllowance);
            invokeWallet(address(_wallet), _token, 0, methodData);
        }

        emit ApprovedAndCalledContract(
            address(_wallet),
            _contract,
            _spender,
            _token,
            _amount,
            usedAllowance,
            _data);
    }
}
























contract ApprovedTransfer is BaseModule, RelayerModuleV2, BaseTransfer {

    bytes32 constant NAME = "ApprovedTransfer";

    constructor(ModuleRegistry _registry, GuardianStorage _guardianStorage) BaseModule(_registry, _guardianStorage, NAME) public {

    }









    function transferToken(
        BaseWallet _wallet,
        address _token,
        address _to,
        uint256 _amount,
        bytes calldata _data
    )
        external
        onlyExecute
        onlyWhenUnlocked(_wallet)
    {
        doTransfer(_wallet, _token, _to, _amount, _data);
    }








    function callContract(
        BaseWallet _wallet,
        address _contract,
        uint256 _value,
        bytes calldata _data
    )
        external
        onlyExecute
        onlyWhenUnlocked(_wallet)
    {
        require(!_wallet.authorised(_contract) && _contract != address(_wallet), "AT: Forbidden contract");
        doCallContract(_wallet, _contract, _value, _data);
    }












    function approveTokenAndCallContract(
        BaseWallet _wallet,
        address _token,
        address _spender,
        uint256 _amount,
        address _contract,
        bytes calldata _data
    )
        external
        onlyExecute
        onlyWhenUnlocked(_wallet)
    {
        require(!_wallet.authorised(_contract) && _contract != address(_wallet), "AT: Forbidden contract");
        doApproveTokenAndCallContract(_wallet, _token, _spender, _amount, _contract, _data);
    }



    function validateSignatures(
        BaseWallet _wallet,
        bytes memory ,
        bytes32 _signHash,
        bytes memory _signatures
    )
        internal
        view
        returns (bool)
    {
        return validateSignatures(_wallet, _signHash, _signatures, OwnerSignature.Required);
    }

    function getRequiredSignatures(BaseWallet _wallet, bytes memory ) public view returns (uint256) {

        return  1 + SafeMath.ceil(guardianStorage.guardianCount(_wallet), 2);
    }
}
