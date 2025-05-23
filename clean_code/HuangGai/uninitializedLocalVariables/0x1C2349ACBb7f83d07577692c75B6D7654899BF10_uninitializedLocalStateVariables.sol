



pragma solidity ^0.5.4;

contract Account {


    address public implementation;


    address public manager;


    mapping (bytes4 => address) public enabled;

    event EnabledStaticCall(address indexed module, bytes4 indexed method);
    event Invoked(address indexed module, address indexed target, uint indexed value, bytes data);
    event Received(uint indexed value, address indexed sender, bytes data);

    event AccountInit(address indexed account);
    event ManagerChanged(address indexed mgr);

    modifier allowAuthorizedLogicContractsCallsOnly {
        require(LogicManager(manager).isAuthorized(msg.sender), "not an authorized logic");
        _;
    }

    function init(address _manager, address _accountStorage, address[] calldata _logics, address[] calldata _keys, address[] calldata _backups)
        external
    {
        require(manager == address(0), "Account: account already initialized");
        require(_manager != address(0) && _accountStorage != address(0), "Account: address is null");
        manager = _manager;

        for (uint i ; i < _logics.length; i++) {

            address logic ;

            require(LogicManager(manager).isAuthorized(logic), "must be authorized logic");

            BaseLogic(logic).initAccount(this);
        }

        AccountStorage(_accountStorage).initAccount(this, _keys, _backups);

        emit AccountInit(address(this));
    }

    function invoke(address _target, uint _value, bytes calldata _data)
        external
        allowAuthorizedLogicContractsCallsOnly
        returns (bytes memory _res)
    {
        bool success;

        (success, _res) = _target.call.value(_value)(_data);
        require(success, "call to target failed");
        emit Invoked(msg.sender, _target, _value, _data);
    }






    function enableStaticCall(address _module, bytes4 _method) external allowAuthorizedLogicContractsCallsOnly {
        enabled[_method] = _module;
        emit EnabledStaticCall(_module, _method);
    }

    function changeManager(address _newMgr) external allowAuthorizedLogicContractsCallsOnly {
        require(_newMgr != address(0), "address cannot be null");
        require(_newMgr != manager, "already changed");
        manager = _newMgr;
        emit ManagerChanged(_newMgr);
    }






    function() external payable {
        if(msg.data.length > 0) {
            address logic ;

            if(logic == address(0)) {
                emit Received(msg.value, msg.sender, msg.data);
            }
            else {
                require(LogicManager(manager).isAuthorized(logic), "must be an authorized logic for static call");

                assembly {
                    calldatacopy(0, 0, calldatasize())
                    let result := staticcall(gas, logic, 0, calldatasize(), 0, 0)
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

contract LogicManager is Owned {

    event UpdateLogicSubmitted(address indexed logic, bool value);
    event UpdateLogicCancelled(address indexed logic);
    event UpdateLogicDone(address indexed logic, bool value);

    struct pending {
        bool value;
        uint dueTime;
    }


    mapping (address => bool) public authorized;









    address[] public authorizedLogics;


    mapping (address => pending) public pendingLogics;


    struct pendingTime {
        uint curPendingTime;
        uint nextPendingTime;
        uint dueTime;
    }

    pendingTime public pt;


    uint public logicCount;

    constructor(address[] memory _initialLogics, uint256 _pendingTime) public
    {
        for (uint i ; i < _initialLogics.length; i++) {

            address logic ;

            authorized[logic] = true;
            logicCount += 1;
        }
        authorizedLogics = _initialLogics;

        pt.curPendingTime = _pendingTime;
        pt.nextPendingTime = _pendingTime;
        pt.dueTime = now;
    }

    function submitUpdatePendingTime(uint _pendingTime) external onlyOwner {
        pt.nextPendingTime = _pendingTime;
        pt.dueTime = pt.curPendingTime + now;
    }

    function triggerUpdatePendingTime() external {
        require(pt.dueTime <= now, "too early to trigger updatePendingTime");
        pt.curPendingTime = pt.nextPendingTime;
    }

    function isAuthorized(address _logic) external view returns (bool) {
        return authorized[_logic];
    }

    function getAuthorizedLogics() external view returns (address[] memory) {
        return authorizedLogics;
    }

    function submitUpdate(address _logic, bool _value) external onlyOwner {
        pending storage p = pendingLogics[_logic];
        p.value = _value;
        p.dueTime = now + pt.curPendingTime;
        emit UpdateLogicSubmitted(_logic, _value);
    }

    function cancelUpdate(address _logic) external onlyOwner {
        delete pendingLogics[_logic];
        emit UpdateLogicCancelled(_logic);
    }

    function triggerUpdateLogic(address _logic) external {
        pending memory p = pendingLogics[_logic];
        require(p.dueTime > 0, "pending logic not found");
        require(p.dueTime <= now, "too early to trigger updateLogic");
        updateLogic(_logic, p.value);
        delete pendingLogics[_logic];
    }

    function updateLogic(address _logic, bool _value) internal {
        if (authorized[_logic] != _value) {
            if(_value) {
                logicCount += 1;
                authorized[_logic] = true;
                authorizedLogics.push(_logic);
            }
            else {
                logicCount -= 1;
                require(logicCount > 0, "must have at least one logic module");
                delete authorized[_logic];
                removeLogic(_logic);
            }
            emit UpdateLogicDone(_logic, _value);
        }
    }

    function removeLogic(address _logic) internal {
        uint len ;

        address lastLogic ;

        if (_logic != lastLogic) {
            for (uint i ; i < len; i++) {

                 if (_logic == authorizedLogics[i]) {
                     authorizedLogics[i] = lastLogic;
                     break;
                 }
            }
        }
        authorizedLogics.length--;
    }
}

contract AccountStorage {

    modifier allowAccountCallsOnly(Account _account) {
        require(msg.sender == address(_account), "caller must be account");
        _;
    }

    modifier allowAuthorizedLogicContractsCallsOnly(address payable _account) {
        require(LogicManager(Account(_account).manager()).isAuthorized(msg.sender), "not an authorized logic");
        _;
    }

    struct KeyItem {
        address pubKey;
        uint256 status;
    }

    struct BackupAccount {
        address backup;
        uint256 effectiveDate;
        uint256 expiryDate;
    }

    struct DelayItem {
        bytes32 hash;
        uint256 dueTime;
    }

    struct Proposal {
        bytes32 hash;
        address[] approval;
    }


    mapping (address => uint256) operationKeyCount;


    mapping (address => mapping(uint256 => KeyItem)) keyData;


    mapping (address => mapping(uint256 => BackupAccount)) backupData;






    mapping (address => mapping(bytes4 => DelayItem)) delayData;


    mapping (address => mapping(address => mapping(bytes4 => Proposal))) proposalData;



    function getOperationKeyCount(address _account) external view returns(uint256) {
        return operationKeyCount[_account];
    }

    function increaseKeyCount(address payable _account) external allowAuthorizedLogicContractsCallsOnly(_account) {
        operationKeyCount[_account] = operationKeyCount[_account] + 1;
    }



    function getKeyData(address _account, uint256 _index) public view returns(address) {
        KeyItem memory item = keyData[_account][_index];
        return item.pubKey;
    }

    function setKeyData(address payable _account, uint256 _index, address _key) external allowAuthorizedLogicContractsCallsOnly(_account) {
        require(_key != address(0), "invalid _key value");
        KeyItem storage item = keyData[_account][_index];
        item.pubKey = _key;
    }



    function getKeyStatus(address _account, uint256 _index) external view returns(uint256) {
        KeyItem memory item = keyData[_account][_index];
        return item.status;
    }

    function setKeyStatus(address payable _account, uint256 _index, uint256 _status) external allowAuthorizedLogicContractsCallsOnly(_account) {
        KeyItem storage item = keyData[_account][_index];
        item.status = _status;
    }



    function getBackupAddress(address _account, uint256 _index) external view returns(address) {
        BackupAccount memory b = backupData[_account][_index];
        return b.backup;
    }

    function getBackupEffectiveDate(address _account, uint256 _index) external view returns(uint256) {
        BackupAccount memory b = backupData[_account][_index];
        return b.effectiveDate;
    }

    function getBackupExpiryDate(address _account, uint256 _index) external view returns(uint256) {
        BackupAccount memory b = backupData[_account][_index];
        return b.expiryDate;
    }

    function setBackup(address payable _account, uint256 _index, address _backup, uint256 _effective, uint256 _expiry)
        external
        allowAuthorizedLogicContractsCallsOnly(_account)
    {
        BackupAccount storage b = backupData[_account][_index];
        b.backup = _backup;
        b.effectiveDate = _effective;
        b.expiryDate = _expiry;
    }

    function setBackupExpiryDate(address payable _account, uint256 _index, uint256 _expiry)
        external
        allowAuthorizedLogicContractsCallsOnly(_account)
    {
        BackupAccount storage b = backupData[_account][_index];
        b.expiryDate = _expiry;
    }

    function clearBackupData(address payable _account, uint256 _index) external allowAuthorizedLogicContractsCallsOnly(_account) {
        delete backupData[_account][_index];
    }



    function getDelayDataHash(address payable _account, bytes4 _actionId) external view returns(bytes32) {
        DelayItem memory item = delayData[_account][_actionId];
        return item.hash;
    }

    function getDelayDataDueTime(address payable _account, bytes4 _actionId) external view returns(uint256) {
        DelayItem memory item = delayData[_account][_actionId];
        return item.dueTime;
    }

    function setDelayData(address payable _account, bytes4 _actionId, bytes32 _hash, uint256 _dueTime) external allowAuthorizedLogicContractsCallsOnly(_account) {
        DelayItem storage item = delayData[_account][_actionId];
        item.hash = _hash;
        item.dueTime = _dueTime;
    }

    function clearDelayData(address payable _account, bytes4 _actionId) external allowAuthorizedLogicContractsCallsOnly(_account) {
        delete delayData[_account][_actionId];
    }



    function getProposalDataHash(address _client, address _proposer, bytes4 _actionId) external view returns(bytes32) {
        Proposal memory p = proposalData[_client][_proposer][_actionId];
        return p.hash;
    }

    function getProposalDataApproval(address _client, address _proposer, bytes4 _actionId) external view returns(address[] memory) {
        Proposal memory p = proposalData[_client][_proposer][_actionId];
        return p.approval;
    }

    function setProposalData(address payable _client, address _proposer, bytes4 _actionId, bytes32 _hash, address _approvedBackup)
        external
        allowAuthorizedLogicContractsCallsOnly(_client)
    {
        Proposal storage p = proposalData[_client][_proposer][_actionId];
        if (p.hash > 0) {
            if (p.hash == _hash) {
                for (uint256 i ; i < p.approval.length; i++) {

                    require(p.approval[i] != _approvedBackup, "backup already exists");
                }
                p.approval.push(_approvedBackup);
            } else {
                p.hash = _hash;
                p.approval.length = 0;
            }
        } else {
            p.hash = _hash;
            p.approval.push(_approvedBackup);
        }
    }

    function clearProposalData(address payable _client, address _proposer, bytes4 _actionId) external allowAuthorizedLogicContractsCallsOnly(_client) {
        delete proposalData[_client][_proposer][_actionId];
    }



    function initAccount(Account _account, address[] calldata _keys, address[] calldata _backups)
        external
        allowAccountCallsOnly(_account)
    {
        require(getKeyData(address(_account), 0) == address(0), "AccountStorage: account already initialized!");
        require(_keys.length > 0, "empty keys array");

        operationKeyCount[address(_account)] = _keys.length - 1;

        for (uint256 index ; index < _keys.length; index++) {

            address _key ;

            require(_key != address(0), "_key cannot be 0x0");
            KeyItem storage item = keyData[address(_account)][index];
            item.pubKey = _key;
            item.status = 0;
        }



        if (_backups.length > 1) {
            address[] memory bkps = _backups;
            for (uint256 i ; i < _backups.length; i++) {

                for (uint256 j ; j < i; j++) {

                    require(bkps[j] != _backups[i], "duplicate backup");
                }
            }
        }

        for (uint256 index ; index < _backups.length; index++) {

            address _backup ;

            require(_backup != address(0), "backup cannot be 0x0");
            require(_backup != address(_account), "cannot be backup of oneself");

            backupData[address(_account)][index] = BackupAccount(_backup, now, uint256(-1));
        }
    }
}




























library SafeMath {




    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c ;

        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c ;



        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c ;


        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c ;

        require(c >= a);

        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }




    function ceil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c ;

        if(a % b == 0) {
            return c;
        }
        else {
            return c + 1;
        }
    }
}

contract BaseLogic {

    bytes constant internal SIGN_HASH_PREFIX = "\x19Ethereum Signed Message:\n32";

    mapping (address => uint256) keyNonce;
    AccountStorage public accountStorage;

    modifier allowSelfCallsOnly() {
        require (msg.sender == address(this), "only internal call is allowed");
        _;
    }

    modifier allowAccountCallsOnly(Account _account) {
        require(msg.sender == address(_account), "caller must be account");
        _;
    }

    event LogicInitialised(address wallet);



    constructor(AccountStorage _accountStorage) public {
        accountStorage = _accountStorage;
    }



    function initAccount(Account _account) external allowAccountCallsOnly(_account){
        emit LogicInitialised(address(_account));
    }



    function getKeyNonce(address _key) external view returns(uint256) {
        return keyNonce[_key];
    }



    function getSignHash(bytes memory _data, uint256 _nonce) internal view returns(bytes32) {


        bytes32 msgHash ;

        bytes32 prefixedHash ;

        return prefixedHash;
    }

    function verifySig(address _signingKey, bytes memory _signature, bytes32 _signHash) internal pure {
        require(_signingKey != address(0), "invalid signing key");
        address recoveredAddr ;

        require(recoveredAddr == _signingKey, "signature verification failed");
    }



















    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {

        if (signature.length != 65) {
            return (address(0));
        }


        bytes32 r;
        bytes32 s;
        uint8 v;




        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }










        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }


        return ecrecover(hash, v, r, s);
    }






    function getSignerAddress(bytes memory _b) internal pure returns (address _a) {
        require(_b.length >= 36, "invalid bytes");

        assembly {
            let mask := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            _a := and(mask, mload(add(_b, 36)))




        }
    }


    function getMethodId(bytes memory _b) internal pure returns (bytes4 _a) {
        require(_b.length >= 4, "invalid data");

        assembly {

            _a := mload(add(_b, 32))
        }
    }

    function checkKeyStatus(address _account, uint256 _index) internal {

        if (_index > 0) {
            require(accountStorage.getKeyStatus(_account, _index) != 1, "frozen key");
        }
    }


    function checkAndUpdateNonce(address _key, uint256 _nonce) internal {
        require(_nonce > keyNonce[_key], "nonce too small");
        require(SafeMath.div(_nonce, 1000000) <= now + 86400, "nonce too big");

        keyNonce[_key] = _nonce;
    }
}

contract TransferLogic is BaseLogic {








    uint constant internal TRANSFER_KEY_INDEX = 1;


    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;



    event TransferLogicInitialised(address indexed account);
    event TransferLogicEntered(bytes data, uint256 indexed nonce);



    constructor(AccountStorage _accountStorage)
		BaseLogic(_accountStorage)
		public
	{
	}




    function initAccount(Account _account) external allowAccountCallsOnly(_account){
        _account.enableStaticCall(address(this), ERC721_RECEIVED);
        emit TransferLogicInitialised(address(_account));
    }



    function enter(bytes calldata _data, bytes calldata _signature, uint256 _nonce) external {
        address account ;

        checkKeyStatus(account, TRANSFER_KEY_INDEX);

        address assetKey ;

        checkAndUpdateNonce(assetKey, _nonce);
        bytes32 signHash ;

        verifySig(assetKey, _signature, signHash);


        (bool success,) = address(this).call(_data);
        require(success, "calling self failed");
        emit TransferLogicEntered(_data, _nonce);
    }





    function transferEth(address payable _from, address _to, uint256 _amount) external allowSelfCallsOnly {


        (bool success,) = _from.call(abi.encodeWithSignature("invoke(address,uint256,bytes)", _to, _amount, ""));
        require(success, "calling invoke failed");
    }



    function transferErc20(address payable _from, address _to, address _token, uint256 _amount) external allowSelfCallsOnly {
        bytes memory methodData = abi.encodeWithSignature("transfer(address,uint256)", _to, _amount);

        bool success;
        bytes memory res;

        (success, res) = _from.call(abi.encodeWithSignature("invoke(address,uint256,bytes)", _token, 0, methodData));
        require(success, "calling invoke failed");
        if (res.length > 0) {
            bool r;
            r = abi.decode(res, (bool));
            require(r, "transferErc20 return false");
        }
    }




    function transferApprovedErc20(address payable _approvedSpender, address _from, address _to, address _token, uint256 _amount) external allowSelfCallsOnly {
        bytes memory methodData = abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _amount);

        bool success;
        bytes memory res;

        (success, res) = _approvedSpender.call(abi.encodeWithSignature("invoke(address,uint256,bytes)", _token, 0, methodData));
        require(success, "calling invoke failed");
        if (res.length > 0) {
            bool r;
            r = abi.decode(res, (bool));
            require(r, "transferFrom return false");
        }
    }



    function transferNft(
        address payable _from, address _to, address _nftContract, uint256 _tokenId, bytes calldata _data, bool _safe)
        external
        allowSelfCallsOnly
    {
        bytes memory methodData;
        if(_safe) {
            methodData = abi.encodeWithSignature("safeTransferFrom(address,address,uint256,bytes)", _from, _to, _tokenId, _data);
        } else {
            methodData = abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _tokenId);
        }

        bool success;

        (success,) = _from.call(abi.encodeWithSignature("invoke(address,uint256,bytes)", _nftContract, 0, methodData));
        require(success, "calling invoke failed");
    }




    function transferApprovedNft(
        address payable _approvedSpender, address _from, address _to, address _nftContract, uint256 _tokenId, bytes calldata _data, bool _safe)
        external
        allowSelfCallsOnly
    {
        bytes memory methodData;
        if(_safe) {
            methodData = abi.encodeWithSignature("safeTransferFrom(address,address,uint256,bytes)", _from, _to, _tokenId, _data);
        } else {
            methodData = abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _tokenId);
        }

        bool success;

        (success,) = _approvedSpender.call(abi.encodeWithSignature("invoke(address,uint256,bytes)", _nftContract, 0, methodData));
        require(success, "calling invoke failed");
    }



    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external pure returns (bytes4) {
        return ERC721_RECEIVED;
    }
}
