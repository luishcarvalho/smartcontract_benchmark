
















pragma solidity ^0.5.4;


contract Proxy {

    address implementation;

    event RECEIVED369(uint indexed value, address indexed sender, bytes data);

    constructor(address _implementation) public {
        implementation = _implementation;
    }

    function() external payable {

        if (msg.data.length == 0 && msg.value > 0) {
            emit RECEIVED369(msg.value, msg.sender, msg.data);
        } else {

            assembly {
                let target := sload(0)
                calldatacopy(0, 0, calldatasize())
                let result := delegatecall(gas, target, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {revert(0, returndatasize())}
                default {return (0, returndatasize())}
            }
        }
    }
}


contract BaseWallet {
    function INIT685(address _owner, address[] calldata _modules) external;
    function AUTHORISEMODULE812(address _module, bool _value) external;
    function ENABLESTATICCALL186(address _module, bytes4 _method) external;
    function SETOWNER798(address _newOwner) external;
    function INVOKE21(address _target, uint _value, bytes calldata _data) external returns (bytes memory _result);
    function() external payable;
}


contract Owned {


    address public owner;

    event OWNERCHANGED436(address indexed _newOwner);


    modifier ONLYOWNER47 {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }


    function CHANGEOWNER39(address _newOwner) external ONLYOWNER47 {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OWNERCHANGED436(_newOwner);
    }
}


contract Managed is Owned {


    mapping (address => bool) public managers;


    modifier ONLYMANAGER653 {
        require(managers[msg.sender] == true, "M: Must be manager");
        _;
    }

    event MANAGERADDED439(address indexed _manager);
    event MANAGERREVOKED398(address indexed _manager);


    function ADDMANAGER871(address _manager) external ONLYOWNER47 {
        require(_manager != address(0), "M: Address must not be null");
        if (managers[_manager] == false) {
            managers[_manager] = true;
            emit MANAGERADDED439(_manager);
        }
    }


    function REVOKEMANAGER965(address _manager) external ONLYOWNER47 {
        require(managers[_manager] == true, "M: Target must be an existing manager");
        delete managers[_manager];
        emit MANAGERREVOKED398(_manager);
    }
}


interface IENSManager {
    event ROOTNODEOWNERCHANGE990(bytes32 indexed _rootnode, address indexed _newOwner);
    event ENSRESOLVERCHANGED200(address addr);
    event REGISTERED245(address indexed _owner, string _ens);
    event UNREGISTERED914(string _ens);

    function CHANGEROOTNODEOWNER398(address _newOwner) external;
    function REGISTER194(string calldata _label, address _owner) external;
    function ISAVAILABLE666(bytes32 _subnode) external view returns(bool);
    function GETENSREVERSEREGISTRAR478() external view returns (address);
    function ENSRESOLVER758() external view returns (address);
}


contract ModuleRegistry {
    function REGISTERMODULE445(address _module, bytes32 _name) external;
    function DEREGISTERMODULE847(address _module) external;
    function REGISTERUPGRADER868(address _upgrader, bytes32 _name) external;
    function DEREGISTERUPGRADER19(address _upgrader) external;
    function MODULEINFO202(address _module) external view returns (bytes32);
    function UPGRADERINFO731(address _upgrader) external view returns (bytes32);
    function ISREGISTEREDMODULE404(address _module) external view returns (bool);
    function ISREGISTEREDMODULE404(address[] calldata _modules) external view returns (bool);
    function ISREGISTEREDUPGRADER426(address _upgrader) external view returns (bool);
}


interface IGuardianStorage{
    function ADDGUARDIAN190(BaseWallet _wallet, address _guardian) external;
    function REVOKEGUARDIAN58(BaseWallet _wallet, address _guardian) external;
    function ISGUARDIAN756(BaseWallet _wallet, address _guardian) external view returns (bool);
}


contract WalletFactory is Owned, Managed {


    address public moduleRegistry;

    address public walletImplementation;

    address public ensManager;

    address public guardianStorage;



    event MODULEREGISTRYCHANGED334(address addr);
    event ENSMANAGERCHANGED648(address addr);
    event GUARDIANSTORAGECHANGED398(address addr);
    event WALLETCREATED189(address indexed wallet, address indexed owner, address indexed guardian);




    modifier GUARDIANSTORAGEDEFINED740 {
        require(guardianStorage != address(0), "GuardianStorage address not defined");
        _;
    }




    constructor(address _moduleRegistry, address _walletImplementation, address _ensManager) public {
        moduleRegistry = _moduleRegistry;
        walletImplementation = _walletImplementation;
        ensManager = _ensManager;
    }




    function CREATEWALLET541(
        address _owner,
        address[] calldata _modules,
        string calldata _label
    )
        external
        ONLYMANAGER653
    {
        _CREATEWALLET379(_owner, _modules, _label, address(0));
    }


    function CREATEWALLETWITHGUARDIAN388(
        address _owner,
        address[] calldata _modules,
        string calldata _label,
        address _guardian
    )
        external
        ONLYMANAGER653
        GUARDIANSTORAGEDEFINED740
    {
        require(_guardian != (address(0)), "WF: guardian cannot be null");
        _CREATEWALLET379(_owner, _modules, _label, _guardian);
    }


    function CREATECOUNTERFACTUALWALLET430(
        address _owner,
        address[] calldata _modules,
        string calldata _label,
        bytes32 _salt
    )
        external
        ONLYMANAGER653
    {
        _CREATECOUNTERFACTUALWALLET436(_owner, _modules, _label, address(0), _salt);
    }


    function CREATECOUNTERFACTUALWALLETWITHGUARDIAN167(
        address _owner,
        address[] calldata _modules,
        string calldata _label,
        address _guardian,
        bytes32 _salt
    )
        external
        ONLYMANAGER653
        GUARDIANSTORAGEDEFINED740
    {
        require(_guardian != (address(0)), "WF: guardian cannot be null");
        _CREATECOUNTERFACTUALWALLET436(_owner, _modules, _label, _guardian, _salt);
    }


    function GETADDRESSFORCOUNTERFACTUALWALLET140(
        address _owner,
        address[] calldata _modules,
        bytes32 _salt
    )
        external
        view
        returns (address _wallet)
    {
        _wallet = _GETADDRESSFORCOUNTERFACTUALWALLET709(_owner, _modules, address(0), _salt);
    }


    function GETADDRESSFORCOUNTERFACTUALWALLETWITHGUARDIAN758(
        address _owner,
        address[] calldata _modules,
        address _guardian,
        bytes32 _salt
    )
        external
        view
        returns (address _wallet)
    {
        require(_guardian != (address(0)), "WF: guardian cannot be null");
        _wallet = _GETADDRESSFORCOUNTERFACTUALWALLET709(_owner, _modules, _guardian, _salt);
    }


    function CHANGEMODULEREGISTRY647(address _moduleRegistry) external ONLYOWNER47 {
        require(_moduleRegistry != address(0), "WF: address cannot be null");
        moduleRegistry = _moduleRegistry;
        emit MODULEREGISTRYCHANGED334(_moduleRegistry);
    }


    function CHANGEENSMANAGER916(address _ensManager) external ONLYOWNER47 {
        require(_ensManager != address(0), "WF: address cannot be null");
        ensManager = _ensManager;
        emit ENSMANAGERCHANGED648(_ensManager);
    }


    function CHANGEGUARDIANSTORAGE66(address _guardianStorage) external ONLYOWNER47 {
        require(_guardianStorage != address(0), "WF: address cannot be null");
        guardianStorage = _guardianStorage;
        emit GUARDIANSTORAGECHANGED398(_guardianStorage);
    }


    function INIT685(BaseWallet _wallet) external pure {

    }




    function _CREATEWALLET379(address _owner, address[] memory _modules, string memory _label, address _guardian) internal {
        _VALIDATEINPUTS330(_owner, _modules, _label);
        Proxy proxy = new Proxy(walletImplementation);
        address payable wallet = address(proxy);
        _CONFIGUREWALLET163(BaseWallet(wallet), _owner, _modules, _label, _guardian);
    }


    function _CREATECOUNTERFACTUALWALLET436(
        address _owner,
        address[] memory _modules,
        string memory _label,
        address _guardian,
        bytes32 _salt
    )
        internal
    {
        _VALIDATEINPUTS330(_owner, _modules, _label);
        bytes32 newsalt = _NEWSALT377(_salt, _owner, _modules, _guardian);
        bytes memory code = abi.encodePacked(type(Proxy).creationCode, uint256(walletImplementation));
        address payable wallet;

        assembly {
            wallet := create2(0, add(code, 0x20), mload(code), newsalt)
            if iszero(extcodesize(wallet)) { revert(0, returndatasize) }
        }
        _CONFIGUREWALLET163(BaseWallet(wallet), _owner, _modules, _label, _guardian);
    }


    function _CONFIGUREWALLET163(
        BaseWallet _wallet,
        address _owner,
        address[] memory _modules,
        string memory _label,
        address _guardian
    )
        internal
    {

        address[] memory extendedModules = new address[](_modules.length + 1);
        extendedModules[0] = address(this);
        for (uint i = 0; i < _modules.length; i++) {
            extendedModules[i + 1] = _modules[i];
        }

        _wallet.INIT685(_owner, extendedModules);

        if (_guardian != address(0)) {
            IGuardianStorage(guardianStorage).ADDGUARDIAN190(_wallet, _guardian);
        }

        _REGISTERWALLETENS735(address(_wallet), _label);

        _wallet.AUTHORISEMODULE812(address(this), false);

        emit WALLETCREATED189(address(_wallet), _owner, _guardian);
    }


    function _GETADDRESSFORCOUNTERFACTUALWALLET709(
        address _owner,
        address[] memory _modules,
        address _guardian,
        bytes32 _salt
    )
        internal
        view
        returns (address _wallet)
    {
        bytes32 newsalt = _NEWSALT377(_salt, _owner, _modules, _guardian);
        bytes memory code = abi.encodePacked(type(Proxy).creationCode, uint256(walletImplementation));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), newsalt, keccak256(code)));
        _wallet = address(uint160(uint256(hash)));
    }


    function _NEWSALT377(bytes32 _salt, address _owner, address[] memory _modules, address _guardian) internal pure returns (bytes32) {
        if (_guardian == address(0)) {
            return keccak256(abi.encodePacked(_salt, _owner, _modules));
        } else {
            return keccak256(abi.encodePacked(_salt, _owner, _modules, _guardian));
        }
    }


    function _VALIDATEINPUTS330(address _owner, address[] memory _modules, string memory _label) internal view {
        require(_owner != address(0), "WF: owner cannot be null");
        require(_modules.length > 0, "WF: cannot assign with less than 1 module");
        require(ModuleRegistry(moduleRegistry).ISREGISTEREDMODULE404(_modules), "WF: one or more modules are not registered");
        bytes memory labelBytes = bytes(_label);
        require(labelBytes.length != 0, "WF: ENS lable must be defined");
    }


    function _REGISTERWALLETENS735(address payable _wallet, string memory _label) internal {

        address ensResolver = IENSManager(ensManager).ENSRESOLVER758();
        bytes memory methodData = abi.encodeWithSignature("claimWithResolver(address,address)", ensManager, ensResolver);
        address ensReverseRegistrar = IENSManager(ensManager).GETENSREVERSEREGISTRAR478();
        BaseWallet(_wallet).INVOKE21(ensReverseRegistrar, 0, methodData);

        IENSManager(ensManager).REGISTER194(_label, _wallet);
    }
}
