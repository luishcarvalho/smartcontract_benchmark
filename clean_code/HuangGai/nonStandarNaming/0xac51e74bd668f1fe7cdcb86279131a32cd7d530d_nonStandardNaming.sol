



pragma solidity ^0.6.2;


interface IERC734 {

    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }


    event APPROVED490(uint256 indexed executionId, bool approved);


    event EXECUTED607(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);


    event EXECUTIONREQUESTED852(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);


    event KEYADDED145(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);


    event KEYREMOVED913(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);


    event KEYSREQUIREDCHANGED871(uint256 purpose, uint256 number);



    function ADDKEY780(bytes32 _key, uint256 _purpose, uint256 _keyType) external returns (bool success);


    function APPROVE542(uint256 _id, bool _approve) external returns (bool success);


    function EXECUTE357(address _to, uint256 _value, bytes calldata _data) external payable returns (uint256 executionId);


    function GETKEY752(bytes32 _key) external view returns (uint256[] memory purposes, uint256 keyType, bytes32 key);


    function GETKEYPURPOSES287(bytes32 _key) external view returns(uint256[] memory _purposes);


    function GETKEYSBYPURPOSE882(uint256 _purpose) external view returns (bytes32[] memory keys);


    function KEYHASPURPOSE281(bytes32 _key, uint256 _purpose) external view returns (bool exists);


    function REMOVEKEY520(bytes32 _key, uint256 _purpose) external returns (bool success);
}



pragma solidity ^0.6.2;


interface IERC735 {


    event CLAIMREQUESTED636(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);


    event CLAIMADDED434(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);


    event CLAIMREMOVED422(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);


    event CLAIMCHANGED857(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);


    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }


    function GETCLAIM300(bytes32 _claimId) external view returns(uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);


    function GETCLAIMIDSBYTOPIC680(uint256 _topic) external view returns(bytes32[] memory claimIds);


    function ADDCLAIM459(uint256 _topic, uint256 _scheme, address issuer, bytes calldata _signature, bytes calldata _data, string calldata _uri) external returns (bytes32 claimRequestId);


    function REMOVECLAIM793(bytes32 _claimId) external returns (bool success);
}



pragma solidity ^0.6.2;



interface IIdentity is IERC734, IERC735 {}





pragma solidity 0.6.2;


interface IIdentityRegistryStorage {


    event IDENTITYSTORED128(address indexed investorAddress, IIdentity indexed identity);


    event IDENTITYUNSTORED820(address indexed investorAddress, IIdentity indexed identity);


    event IDENTITYMODIFIED265(IIdentity indexed oldIdentity, IIdentity indexed newIdentity);


    event COUNTRYMODIFIED940(address indexed investorAddress, uint16 indexed country);


    event IDENTITYREGISTRYBOUND952(address indexed identityRegistry);


    event IDENTITYREGISTRYUNBOUND414(address indexed identityRegistry);


    function LINKEDIDENTITYREGISTRIES299() external view returns (address[] memory);


    function STOREDIDENTITY367(address _userAddress) external view returns (IIdentity);


    function STOREDINVESTORCOUNTRY957(address _userAddress) external view returns (uint16);


    function ADDIDENTITYTOSTORAGE973(address _userAddress, IIdentity _identity, uint16 _country) external;


    function REMOVEIDENTITYFROMSTORAGE801(address _userAddress) external;


    function MODIFYSTOREDINVESTORCOUNTRY139(address _userAddress, uint16 _country) external;


    function MODIFYSTOREDIDENTITY804(address _userAddress, IIdentity _identity) external;


    function TRANSFEROWNERSHIPONIDENTITYREGISTRYSTORAGE181(address _newOwner) external;


    function BINDIDENTITYREGISTRY966(address _identityRegistry) external;


    function UNBINDIDENTITYREGISTRY94(address _identityRegistry) external;
}





pragma solidity ^0.6.0;


contract Context {


    constructor () internal { }

    function _MSGSENDER968() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA951() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}



pragma solidity 0.6.2;



contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED988(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        address msgSender = _MSGSENDER968();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED988(address(0), msgSender);
    }


    function OWNER857() external view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER188() {
        require(ISOWNER766(), "Ownable: caller is not the owner");
        _;
    }


    function ISOWNER766() public view returns (bool) {
        return _MSGSENDER968() == _owner;
    }


    function RENOUNCEOWNERSHIP147() external virtual ONLYOWNER188 {
        emit OWNERSHIPTRANSFERRED988(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP614(address newOwner) public virtual ONLYOWNER188 {
        _TRANSFEROWNERSHIP40(newOwner);
    }


    function _TRANSFEROWNERSHIP40(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED988(_owner, newOwner);
        _owner = newOwner;
    }
}





pragma solidity 0.6.2;

interface ICompliance {


    event TOKENAGENTADDED270(address _agentAddress);


    event TOKENAGENTREMOVED312(address _agentAddress);


    event TOKENBOUND274(address _token);


    event TOKENUNBOUND919(address _token);


    function ISTOKENAGENT216(address _agentAddress) external view returns (bool);


    function ISTOKENBOUND101(address _token) external view returns (bool);


    function ADDTOKENAGENT168(address _agentAddress) external;


    function REMOVETOKENAGENT600(address _agentAddress) external;


    function BINDTOKEN336(address _token) external;


    function UNBINDTOKEN130(address _token) external;



    function CANTRANSFER762(address _from, address _to, uint256 _amount) external view returns (bool);


    function TRANSFERRED661(address _from, address _to, uint256 _amount) external;


    function CREATED745(address _to, uint256 _amount) external;


    function DESTROYED848(address _from, uint256 _amount) external;


    function TRANSFEROWNERSHIPONCOMPLIANCECONTRACT644(address newOwner) external;
}





pragma solidity 0.6.2;




contract CountryRestrictions is ICompliance, Ownable {


    event IDENTITYSTORAGEADDED931(address indexed _identityStorage);


    event ADDEDRESTRICTEDCOUNTRY249(uint16 _country);


    event REMOVEDRESTRICTEDCOUNTRY571(uint16 _country);



    IIdentityRegistryStorage public identityStorage;


    mapping(uint16 => bool) private _restrictedCountries;


    mapping(address => bool) private _tokenAgentsList;


    mapping(address => bool) private _tokensBound;


    constructor (address _identityStorage) public {
        identityStorage = IIdentityRegistryStorage(_identityStorage);
        emit IDENTITYSTORAGEADDED931(_identityStorage);
    }


    function ISTOKENAGENT216(address _agentAddress) public override view returns (bool) {
        return (_tokenAgentsList[_agentAddress]);
    }


    function ISTOKENBOUND101(address _token) public override view returns (bool) {
        return (_tokensBound[_token]);
    }


    function ISCOUNTRYRESTRICTED644(uint16 _country) public view returns (bool) {
        return (_restrictedCountries[_country]);
    }


    function ADDTOKENAGENT168(address _agentAddress) external override ONLYOWNER188 {
        require(!_tokenAgentsList[_agentAddress], "This Agent is already registered");
        _tokenAgentsList[_agentAddress] = true;
        emit TOKENAGENTADDED270(_agentAddress);
    }


    function REMOVETOKENAGENT600(address _agentAddress) external override ONLYOWNER188 {
        require(_tokenAgentsList[_agentAddress], "This Agent is not registered yet");
        _tokenAgentsList[_agentAddress] = false;
        emit TOKENAGENTREMOVED312(_agentAddress);
    }


    function BINDTOKEN336(address _token) external override ONLYOWNER188 {
        require(!_tokensBound[_token], "This token is already bound");
        _tokensBound[_token] = true;
        emit TOKENBOUND274(_token);
    }


    function UNBINDTOKEN130(address _token) external override ONLYOWNER188 {
        require(_tokensBound[_token], "This token is not bound yet");
        _tokensBound[_token] = false;
        emit TOKENUNBOUND919(_token);
    }


    function TRANSFERRED661(address _from, address _to, uint256 _value) external override {

    }


    function CREATED745(address _to, uint256 _value) external override {

    }


    function DESTROYED848(address _from, uint256 _value) external override {

    }


    function SETIDENTITYSTORAGE662(address _identityStorage) external ONLYOWNER188 {
        identityStorage = IIdentityRegistryStorage(_identityStorage);
        emit IDENTITYSTORAGEADDED931(_identityStorage);
    }


    function ADDCOUNTRYRESTRICTION776(uint16 _country) external ONLYOWNER188 {
        _restrictedCountries[_country] = true;
        emit ADDEDRESTRICTEDCOUNTRY249(_country);
    }


    function REMOVECOUNTRYRESTRICTION163(uint16 _country) external ONLYOWNER188 {
        _restrictedCountries[_country] = false;
        emit REMOVEDRESTRICTEDCOUNTRY571(_country);
    }


    function BATCHRESTRICTCOUNTRIES404(uint16[] calldata _countries) external ONLYOWNER188 {
        for (uint i = 0; i < _countries.length; i++) {
            _restrictedCountries[_countries[i]] = true;
            emit ADDEDRESTRICTEDCOUNTRY249(_countries[i]);
        }
    }


    function BATCHUNRESTRICTCOUNTRIES285(uint16[] calldata _countries) external ONLYOWNER188 {
        for (uint i = 0; i < _countries.length; i++) {
            _restrictedCountries[_countries[i]] = false;
            emit REMOVEDRESTRICTEDCOUNTRY571(_countries[i]);
        }
    }


    function CANTRANSFER762(address _from, address _to, uint256 _value) external view override returns (bool) {
        uint16 receiverCountry = identityStorage.STOREDINVESTORCOUNTRY957(_to);
        return (!(_restrictedCountries[receiverCountry]));
    }


    function TRANSFEROWNERSHIPONCOMPLIANCECONTRACT644(address newOwner) external override ONLYOWNER188 {
        TRANSFEROWNERSHIP614(newOwner);
    }
}
