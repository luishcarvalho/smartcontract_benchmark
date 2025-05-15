


















pragma solidity 0.5.10;
pragma experimental ABIEncoderV2;

import "./BlockhashRegistry.sol";



contract NodeRegistry {


    event LogNodeRegistered(string url, uint props, address signer, uint deposit);


    event LogNodeConvicted(address signer);


    event LogNodeRemoved(string url, address signer);

    struct In3Node {
        string url;

        uint deposit;

        uint64 timeout;
        uint64 registerTime;
        uint128 props;

        uint64 weight;
        address signer;

        bytes32 proofHash;
    }


    struct ConvictInformation {
        bytes32 convictHash;
        uint blockNumberConvict;
    }


    struct SignerInformation {
        uint64 lockedTime;
        address owner;

        Stages stage;

        uint depositAmount;

        uint index;
    }


    struct UrlInformation {
        bool used;
        address signer;
    }


    enum Stages {
        NotInUse,
        Active,
        Convicted,
        DepositNotWithdrawn
    }


    In3Node[] public nodes;






    bytes32 public registryId;




    BlockhashRegistry public blockRegistry;


    uint public blockTimeStampDeployment;


    address public unregisterKey;


    mapping (address => SignerInformation) public signerIndex;



    mapping (bytes32 => UrlInformation) public urlIndex;


    mapping (uint => mapping(address => ConvictInformation)) internal convictMapping;


    uint constant internal YEAR_DEFINITION = 1 days * 365;


    uint constant internal MAX_ETHER_LIMIT = 50 ether;


    uint constant public VERSION = 12300020190709;

    modifier onlyActiveState(address _signer) {

        SignerInformation memory si = signerIndex[_signer];
        require(si.stage == Stages.Active, "address is not an in3-signer");

        In3Node memory n = nodes[si.index];
        assert(nodes[si.index].signer == _signer);
        _;
    }




    constructor(BlockhashRegistry _blockRegistry) public {
        blockRegistry = _blockRegistry;


        blockTimeStampDeployment = block.timestamp;
        registryId = keccak256(abi.encodePacked(address(this), blockhash(block.number-1)));
        unregisterKey = msg.sender;
    }






    function convict(uint _blockNumber, bytes32 _hash) external {

        ConvictInformation memory ci;
        ci.convictHash = _hash;
        ci.blockNumberConvict = block.number;

        convictMapping[_blockNumber][msg.sender] = ci;
    }







    function registerNode(
        string calldata _url,
        uint64 _props,
        uint64 _timeout,
        uint64 _weight
    )
        external
        payable
    {
        registerNodeInternal(
            _url,
            _props,
            _timeout,
            msg.sender,
            msg.sender,
            msg.value,
            _weight
        );
    }














    function registerNodeFor(
        string calldata _url,
        uint64 _props,
        uint64 _timeout,
        address _signer,
        uint64 _weight,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
        payable
    {

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 tempHash = keccak256(
            abi.encodePacked(
                _url,
                _props,
                _timeout,
                _weight,
                msg.sender
            )
        );
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, tempHash));

        address signer = ecrecover(
            prefixedHash,
            _v,
            _r,
            _s
        );

        require(_signer == signer, "not the correct signature of the signer provided");

        registerNodeInternal(
            _url,
            _props,
            _timeout,
            _signer,
            msg.sender,
            msg.value,
            _weight
        );
    }





    function removeNodeFromRegistry(address _signer)
        external
        onlyActiveState(_signer)
    {


        require(block.timestamp < (blockTimeStampDeployment + YEAR_DEFINITION), "only in 1st year");
        require(msg.sender == unregisterKey, "only unregisterKey is allowed to remove nodes");

        SignerInformation storage si = signerIndex[_signer];
        In3Node memory n = nodes[si.index];

        unregisterNodeInternal(si, n);

    }







    function returnDeposit(address _signer) external {

        SignerInformation storage si = signerIndex[_signer];

        require(si.stage == Stages.DepositNotWithdrawn, "not in the correct state");
        require(si.owner == msg.sender, "only owner can claim deposit");


        require(block.timestamp > si.lockedTime, "deposit still locked");

        uint payout = si.depositAmount;
        delete signerIndex[_signer];
        msg.sender.transfer(payout);
    }













    function revealConvict(
        address _signer,
        bytes32 _blockhash,
        uint _blockNumber,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {

        bytes32 evmBlockhash = blockhash(_blockNumber);

        if (evmBlockhash == 0x0) {
            evmBlockhash = blockRegistry.blockhashMapping(_blockNumber);
        }

        require(evmBlockhash != 0x0, "block not found");


        require(evmBlockhash != _blockhash, "you try to convict with a correct hash");

        SignerInformation storage si = signerIndex[_signer];
        ConvictInformation storage ci = convictMapping[_blockNumber][msg.sender];

        require(block.number >= ci.blockNumberConvict + 2, "revealConvict still locked");
        require(
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        _blockhash,
                        _blockNumber,
                        registryId
                    )
                ),
                _v, _r, _s) == _signer,
            "the block was not signed by the signer of the node");

        require(
            keccak256(
                abi.encodePacked(
                    _blockhash, msg.sender, _v, _r, _s
                )
            ) == ci.convictHash, "wrong convict hash");

        require(si.stage != Stages.Convicted, "node already convicted");
        emit LogNodeConvicted(_signer);

        uint deposit = 0;

        if (si.stage == Stages.Active) {
            assert(nodes[si.index].signer == _signer);
            deposit = nodes[si.index].deposit;
            removeNode(si.index);
        } else {

            deposit = si.depositAmount;
            si.depositAmount = 0;
            si.lockedTime = 0;
        }

        si.stage = Stages.Convicted;
        delete convictMapping[_blockNumber][msg.sender];


        uint payout = deposit / 2;

        msg.sender.transfer(payout);



        address(0).transfer(deposit-payout);
    }








    function transferOwnership(address _signer, address _newOwner)
        external
        onlyActiveState(_signer)
    {
        SignerInformation storage si = signerIndex[_signer];
        require(si.owner == msg.sender, "only for the in3-node owner");

        require(_newOwner != address(0x0), "0x0 address is invalid");
        si.owner = _newOwner;
    }







    function unregisteringNode(address _signer)
        external
        onlyActiveState(_signer)
    {

        SignerInformation storage si = signerIndex[_signer];
        In3Node memory n = nodes[si.index];
        require(si.owner == msg.sender, "only for the in3-node owner");

        unregisterNodeInternal(si, n);
    }











    function updateNode(
        address _signer,
        string calldata _url,
        uint64 _props,
        uint64 _timeout,
        uint64 _weight
    )
        external
        payable
        onlyActiveState(_signer)
    {
        SignerInformation memory si = signerIndex[_signer];
        require(si.owner == msg.sender, "only for the owner");

        In3Node storage node = nodes[si.index];

        bytes32 newURl = keccak256(bytes(_url));


        if (newURl != keccak256(bytes(node.url))) {


            delete urlIndex[keccak256(bytes(node.url))];


            require(!urlIndex[newURl].used, "url is already in use");

            UrlInformation memory ui;
            ui.used = true;
            ui.signer = msg.sender;
            urlIndex[newURl] = ui;
            node.url = _url;
        }

        if (msg.value > 0) {
            node.deposit += msg.value;
        }

        checkNodeProperties(node.deposit, _timeout);

        if (_props != node.props) {
            node.props = _props;
        }

        if (_timeout > node.timeout) {
            node.timeout = _timeout;
        }

        if (_weight != node.weight) {
            node.weight = _weight;
        }

        node.proofHash = calcProofHash(node);

        emit LogNodeRegistered(
            node.url,
            _props,
            msg.sender,
            node.deposit
        );
    }



    function totalNodes() external view returns (uint) {
        return nodes.length;
    }




    function calcProofHash(In3Node memory _node) internal pure returns (bytes32) {

        return keccak256(
            abi.encodePacked(
                _node.deposit,
                _node.timeout,
                _node.registerTime,
                _node.props,
                _node.signer,
                _node.url
            )
        );
    }






    function checkNodeProperties(uint256 _deposit, uint64 _timeout) internal view {


        if (block.timestamp < (blockTimeStampDeployment + YEAR_DEFINITION)) {
            require(_deposit < MAX_ETHER_LIMIT, "Limit of 50 ETH reached");
        }
        require(_timeout <= YEAR_DEFINITION, "exceeded maximum timeout");
    }













    function registerNodeInternal (
        string memory _url,
        uint64 _props,
        uint64 _timeout,
        address _signer,
        address payable _owner,
        uint _deposit,
        uint64 _weight
    )
        internal
    {


        require(_deposit >= 10 finney, "not enough deposit");

        checkNodeProperties(_deposit, _timeout);

        bytes32 urlHash = keccak256(bytes(_url));



        require(!urlIndex[urlHash].used && signerIndex[_signer].stage == Stages.NotInUse,
            "a node with the same url or signer is already registered");


        signerIndex[_signer].stage = Stages.Active;
        signerIndex[_signer].index = nodes.length;
        signerIndex[_signer].owner = _owner;


        In3Node memory m;
        m.url = _url;
        m.props = _props;
        m.signer = _signer;
        m.deposit = _deposit;
        m.timeout = _timeout > 1 hours ? _timeout : 1 hours;

        m.registerTime = uint64(block.timestamp);
        m.weight = _weight;

        m.proofHash = calcProofHash(m);
        nodes.push(m);


        UrlInformation memory ui;
        ui.used = true;
        ui.signer = _signer;
        urlIndex[urlHash] = ui;

        emit LogNodeRegistered(
            _url,
            _props,
            _signer,
            _deposit
        );
    }




    function unregisterNodeInternal(SignerInformation  storage _si, In3Node memory _n) internal {


        _si.lockedTime = uint64(block.timestamp + _n.timeout);
        _si.depositAmount = _n.deposit;
        _si.stage = Stages.DepositNotWithdrawn;

        removeNode(_si.index);
    }



    function removeNode(uint _nodeIndex) internal {

        emit LogNodeRemoved(nodes[_nodeIndex].url, nodes[_nodeIndex].signer);

        delete urlIndex[keccak256(bytes(nodes[_nodeIndex].url))];
        uint length = nodes.length;

        assert(length > 0);


        signerIndex[nodes[_nodeIndex].signer].index = 0;


        In3Node memory m = nodes[length - 1];
        nodes[_nodeIndex] = m;

        SignerInformation storage si = signerIndex[m.signer];
        si.index = uint64(_nodeIndex);
        nodes.length--;
    }
}
