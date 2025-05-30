




pragma solidity ^0.6.12;

contract KperNetworkJobRegistry {

    address public governance;
    address public pendingGovernance;

    struct _job {
        uint _id;
        address _address;
        string _name;
        string _ipfs;
        string _docs;
        uint _added;
    }

    mapping(address => bool) public jobAdded;
    mapping(address => _job) public jobData;
    address[] public jobList;

    constructor() public {
        governance = msg.sender;
    }

    uint public length;

    function jobs() public view returns (address[] memory) {
        return jobList;
    }

    function job(address _address) public view returns (uint, address, string memory, string memory, string memory, uint) {
        _job memory __job = jobData[_address];
        return (__job._id, __job._address, __job._name, __job._ipfs, __job._docs, __job._added);
    }

    function set(address _address, string calldata _name, string calldata _ipfs, string calldata _docs) external {
        require(msg.sender == governance, "KperNetworkJobRegistry::add: !gov");
        require(jobAdded[_address], "KperNetworkJobRegistry::add: no job");
        _job storage __job = jobData[_address];

        __job._name = _name;
        __job._ipfs = _ipfs;
        __job._docs = _docs;

    }

    function add(address _address, string calldata _name, string calldata _ipfs, string calldata _docs) external {
        require(msg.sender == governance, "KperNetworkJobRegistry::add: !gov");
        require(!jobAdded[_address], "KperNetworkJobRegistry::add: job exists");
        jobAdded[_address] = true;
        jobList.push(_address);
        jobData[_address] = _job(length++, _address, _name, _ipfs, _docs, now);
    }





    function setGovernance(address _governance) public {
        require(msg.sender == governance, "setGovernance: !gov");
        pendingGovernance = _governance;
    }




    function acceptGovernance() public {
        require(msg.sender == pendingGovernance, "acceptGovernance: !pendingGov");
        governance = pendingGovernance;
    }
}
