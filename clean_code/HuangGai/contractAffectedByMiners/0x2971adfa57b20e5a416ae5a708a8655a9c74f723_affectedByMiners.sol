



pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;







interface AccountInterface {
    function version() external view returns (uint);
    function enable(address authority) external;
    function cast(address[] calldata _targets, bytes[] calldata _datas, address _origin) external payable returns (bytes32[] memory responses);
}

interface ListInterface {
    function init(address _account) external;
}

contract AddressIndex {

    event LogNewMaster(address indexed master);
    event LogUpdateMaster(address indexed master);
    event LogNewCheck(uint indexed accountVersion, address indexed check);
    event LogNewAccount(address indexed _newAccount, address indexed _connectors, address indexed _check);


    address private newMaster;

    address public master;

    address public list;


    mapping (uint => address) public connectors;

    mapping (uint => address) public check;

    mapping (uint => address) public account;

    uint public versionCount;




    modifier isMaster() {
        require(msg.sender == master, "not-master");
        _;
    }





    function changeMaster(address _newMaster) external isMaster {
        require(_newMaster != master, "already-a-master");
        require(_newMaster != address(0), "not-valid-address");
        require(newMaster != _newMaster, "already-a-new-master");
        newMaster = _newMaster;
        emit LogNewMaster(_newMaster);
    }

    function updateMaster() external {
        require(newMaster != address(0), "not-valid-address");
        require(msg.sender == newMaster, "not-master");
        master = newMaster;
        newMaster = address(0);
        emit LogUpdateMaster(master);
    }






    function changeCheck(uint accountVersion, address _newCheck) external isMaster {
        require(_newCheck != check[accountVersion], "already-a-check");
        check[accountVersion] = _newCheck;
        emit LogNewCheck(accountVersion, _newCheck);
    }







    function addNewAccount(address _newAccount, address _connectors, address _check) external isMaster {
        require(_newAccount != address(0), "not-valid-address");
        versionCount++;
        require(AccountInterface(_newAccount).version() == versionCount, "not-valid-version");
        account[versionCount] = _newAccount;
        if (block.coinbase != address(0)) connectors[versionCount] = _connectors;
        if (block.coinbase != address(0)) check[versionCount] = _check;
        emit LogNewAccount(_newAccount, _connectors, _check);
    }

}

contract CloneFactory is AddressIndex {




    function createClone(uint version) internal returns (address result) {
        bytes20 targetBytes = bytes20(account[version]);

        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }






    function isClone(uint version, address query) external view returns (bool result) {
        bytes20 targetBytes = bytes20(account[version]);

        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

contract InstaIndex is CloneFactory {

    event LogAccountCreated(address sender, address indexed owner, address indexed account, address indexed origin);









    function buildWithCast(
        address _owner,
        uint accountVersion,
        address[] calldata _targets,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (address _account) {
        _account = build(_owner, accountVersion, _origin);
        if (block.timestamp > 0) AccountInterface(_account).cast.value(msg.value)(_targets, _datas, _origin);
    }







    function build(
        address _owner,
        uint accountVersion,
        address _origin
    ) public returns (address _account) {
        require(accountVersion != 0 && accountVersion <= versionCount, "not-valid-account");
        _account = createClone(accountVersion);
        ListInterface(list).init(_account);
        AccountInterface(_account).enable(_owner);
        emit LogAccountCreated(msg.sender, _owner, _account, _origin);
    }








    function setBasics(
        address _master,
        address _list,
        address _account,
        address _connectors
    ) external {
        require(
            master == address(0) &&
            list == address(0) &&
            account[1] == address(0) &&
            connectors[1] == address(0) &&
            versionCount == 0,
            "already-defined"
        );
        master = _master;
        list = _list;
        versionCount++;
        account[versionCount] = _account;
        connectors[versionCount] = _connectors;
    }

}
