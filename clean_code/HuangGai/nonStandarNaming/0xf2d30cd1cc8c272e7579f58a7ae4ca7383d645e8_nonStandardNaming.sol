










pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


library SafeMath {
    function ADD802(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
 function ADD802(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }
 function SUB29(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB29(a, b, "SafeMath: subtraction underflow");
    }
 function SUB29(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
  function MUL631(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
  function MUL631(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }
  function DIV549(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV549(a, b, "SafeMath: division by zero");
    }
 function DIV549(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }
  function MOD667(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD667(a, b, "SafeMath: modulo by zero");
    }
 function MOD667(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IKeep2r {
    function ADDVOTES925(address voter, uint amount) external;
    function REMOVEVOTES795(address voter, uint amount) external;
    function ADDKPRCREDIT324(address job, uint amount) external;
    function APPROVELIQUIDITY19(address liquidity) external;
    function REVOKELIQUIDITY95(address liquidity) external;
    function ADDJOB704(address job) external;
    function REMOVEJOB261(address job) external;
    function SETKEEP2RHELPER717(address _kprh) external;
    function SETGOVERNANCE887(address _governance) external;
    function ACCEPTGOVERNANCE419() external;
    function DISPUTE17(address keeper) external;
    function SLASH754(address bonded, address keeper, uint amount) external;
    function REVOKE96(address keeper) external;
    function RESOLVE192(address keeper) external;
    function GETPRIORVOTES700(address account, uint blockNumber) external view returns (uint);
    function TOTALBONDED836() external view returns (uint);
}

contract Governance {
    using SafeMath for uint;

    string public constant name820 = "Governance";


    uint public _quorumVotes = 5000;


    uint public _proposalThreshold = 5000;

    uint public constant base706 = 10000;

    function SETQUORUM684(uint quorum_) external {
        require(msg.sender == address(this), "Governance::setQuorum: timelock only");
        require(quorum_ <= base706, "Governance::setQuorum: quorum_ > BASE");
        _quorumVotes = quorum_;
    }

    function QUORUMVOTES610() public view returns (uint) {
        return KPR.TOTALBONDED836().MUL631(_quorumVotes).DIV549(base706);
    }

    function PROPOSALTHRESHOLD741() public view returns (uint) {
        return KPR.TOTALBONDED836().MUL631(_proposalThreshold).DIV549(base706);
    }

    function SETTHRESHOLD755(uint threshold_) external {
        require(msg.sender == address(this), "Governance::setQuorum: timelock only");
        require(threshold_ <= base706, "Governance::setThreshold: threshold_ > BASE");
        _proposalThreshold = threshold_;
    }


    function PROPOSALMAXOPERATIONS305() public pure returns (uint) { return 10; }


    function VOTINGDELAY891() public pure returns (uint) { return 1; }


    function VOTINGPERIOD297() public pure returns (uint) { return 40_320; }


    IKeep2r immutable public KPR;


    uint public proposalCount;

    struct Proposal {
        uint id;
        address proposer;
        uint eta;
        address[] targets;
        uint[] values;
        string[] signatures;
        bytes[] calldatas;
        uint startBlock;
        uint endBlock;
        uint forVotes;
        uint againstVotes;
        bool canceled;
        bool executed;
        mapping (address => Receipt) receipts;
    }


    struct Receipt {
        bool hasVoted;
        bool support;
        uint votes;
    }


    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }


    mapping (uint => Proposal) public proposals;


    mapping (address => uint) public latestProposalIds;


    bytes32 public constant domain_typehash397 = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");


    bytes32 public immutable DOMAINSEPARATOR;


    bytes32 public constant ballot_typehash182 = keccak256("Ballot(uint256 proposalId,bool support)");


    event PROPOSALCREATED434(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);


    event VOTECAST909(address voter, uint proposalId, bool support, uint votes);


    event PROPOSALCANCELED450(uint id);


    event PROPOSALQUEUED490(uint id, uint eta);


    event PROPOSALEXECUTED781(uint id);

    function PROPOSEJOB470(address job) public {
        require(msg.sender == address(KPR), "Governance::proposeJob: only VOTER can propose new jobs");
        address[] memory targets;
        targets[0] = address(KPR);

        string[] memory signatures;
        signatures[0] = "addJob(address)";

        bytes[] memory calldatas;
        calldatas[0] = abi.encode(job);

        uint[] memory values;
        values[0] = 0;

        _PROPOSE700(targets, values, signatures, calldatas, string(abi.encodePacked("Governance::proposeJob(): ", job)));
    }

    function PROPOSE926(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        require(KPR.GETPRIORVOTES700(msg.sender, block.number.SUB29(1)) >= PROPOSALTHRESHOLD741(), "Governance::propose: proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "Governance::propose: proposal function information arity mismatch");
        require(targets.length != 0, "Governance::propose: must provide actions");
        require(targets.length <= PROPOSALMAXOPERATIONS305(), "Governance::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = STATE767(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "Governance::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "Governance::propose: one live proposal per proposer, found an already pending proposal");
        }

        return _PROPOSE700(targets, values, signatures, calldatas, description);
    }

    function _PROPOSE700(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) internal returns (uint) {
        uint startBlock = block.number.ADD802(VOTINGDELAY891());
        uint endBlock = startBlock.ADD802(VOTINGPERIOD297());

        proposalCount++;
        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            eta: 0,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            startBlock: startBlock,
            endBlock: endBlock,
            forVotes: 0,
            againstVotes: 0,
            canceled: false,
            executed: false
        });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit PROPOSALCREATED434(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return newProposal.id;
    }

    function QUEUE934(uint proposalId) public {
        require(STATE767(proposalId) == ProposalState.Succeeded, "Governance::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint eta = block.timestamp.ADD802(delay);
        for (uint i = 0; i < proposal.targets.length; i++) {
            _QUEUEORREVERT932(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit PROPOSALQUEUED490(proposalId, eta);
    }

    function _QUEUEORREVERT932(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!queuedTransactions[keccak256(abi.encode(target, value, signature, data, eta))], "Governance::_queueOrRevert: proposal action already queued at eta");
        _QUEUETRANSACTION380(target, value, signature, data, eta);
    }

    function EXECUTE292(uint proposalId) public payable {
        require(guardian == address(0x0) || msg.sender == guardian, "Governance:execute: !guardian");
        require(STATE767(proposalId) == ProposalState.Queued, "Governance::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            _EXECUTETRANSACTION42(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit PROPOSALEXECUTED781(proposalId);
    }

    function CANCEL285(uint proposalId) public {
        ProposalState state = STATE767(proposalId);
        require(state != ProposalState.Executed, "Governance::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(KPR) &&
                KPR.GETPRIORVOTES700(proposal.proposer, block.number.SUB29(1)) < PROPOSALTHRESHOLD741(), "Governance::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            _CANCELTRANSACTION608(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit PROPOSALCANCELED450(proposalId);
    }

    function GETACTIONS567(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function GETRECEIPT636(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function STATE767(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "Governance::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes.ADD802(proposal.againstVotes) < QUORUMVOTES610()) {
            return ProposalState.Defeated;
        } else if (proposal.forVotes <= proposal.againstVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta.ADD802(grace_period471)) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function CASTVOTE458(uint proposalId, bool support) public {
        _CASTVOTE871(msg.sender, proposalId, support);
    }

    function CASTVOTEBYSIG199(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 structHash = keccak256(abi.encode(ballot_typehash182, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAINSEPARATOR, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Governance::castVoteBySig: invalid signature");
        _CASTVOTE871(signatory, proposalId, support);
    }

    function _CASTVOTE871(address voter, uint proposalId, bool support) internal {
        require(STATE767(proposalId) == ProposalState.Active, "Governance::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "Governance::_castVote: voter already voted");
        uint votes = KPR.GETPRIORVOTES700(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = proposal.forVotes.ADD802(votes);
        } else {
            proposal.againstVotes = proposal.againstVotes.ADD802(votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VOTECAST909(voter, proposalId, support, votes);
    }

    function GETCHAINID291() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    event NEWDELAY307(uint indexed newDelay);
    event CANCELTRANSACTION220(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event EXECUTETRANSACTION925(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QUEUETRANSACTION307(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    uint public constant grace_period471 = 14 days;
    uint public constant minimum_delay353 = 1 days;
    uint public constant maximum_delay422 = 30 days;

    uint public delay = minimum_delay353;

    address public guardian;
    address public pendingGuardian;

    function SETGUARDIAN20(address _guardian) external {
        require(msg.sender == guardian, "Keep2rGovernance::setGuardian: !guardian");
        pendingGuardian = _guardian;
    }

    function ACCEPTGUARDIANSHIP599() external {
        require(msg.sender == pendingGuardian, "Keep2rGovernance::setGuardian: !pendingGuardian");
        guardian = pendingGuardian;
    }

    function ADDVOTES925(address voter, uint amount) external {
        require(msg.sender == guardian, "Keep2rGovernance::addVotes: !guardian");
        KPR.ADDVOTES925(voter, amount);
    }
    function REMOVEVOTES795(address voter, uint amount) external {
        require(msg.sender == guardian, "Keep2rGovernance::removeVotes: !guardian");
        KPR.REMOVEVOTES795(voter, amount);
    }
    function ADDKPRCREDIT324(address job, uint amount) external {
        require(msg.sender == guardian, "Keep2rGovernance::addKPRCredit: !guardian");
        KPR.ADDKPRCREDIT324(job, amount);
    }
    function APPROVELIQUIDITY19(address liquidity) external {
        require(msg.sender == guardian, "Keep2rGovernance::approveLiquidity: !guardian");
        KPR.APPROVELIQUIDITY19(liquidity);
    }
    function REVOKELIQUIDITY95(address liquidity) external {
        require(msg.sender == guardian, "Keep2rGovernance::revokeLiquidity: !guardian");
        KPR.REVOKELIQUIDITY95(liquidity);
    }
    function ADDJOB704(address job) external {
        require(msg.sender == guardian, "Keep2rGovernance::addJob: !guardian");
        KPR.ADDJOB704(job);
    }
    function REMOVEJOB261(address job) external {
        require(msg.sender == guardian, "Keep2rGovernance::removeJob: !guardian");
        KPR.REMOVEJOB261(job);
    }
    function SETKEEP2RHELPER717(address kprh) external {
        require(msg.sender == guardian, "Keep2rGovernance::setKeep2rHelper: !guardian");
        KPR.SETKEEP2RHELPER717(kprh);
    }
    function SETGOVERNANCE887(address _governance) external {
        require(msg.sender == guardian, "Keep2rGovernance::setGovernance: !guardian");
        KPR.SETGOVERNANCE887(_governance);
    }
    function ACCEPTGOVERNANCE419() external {
        require(msg.sender == guardian, "Keep2rGovernance::acceptGovernance: !guardian");
        KPR.ACCEPTGOVERNANCE419();
    }
    function DISPUTE17(address keeper) external {
        require(msg.sender == guardian, "Keep2rGovernance::dispute: !guardian");
        KPR.DISPUTE17(keeper);
    }
    function SLASH754(address bonded, address keeper, uint amount) external {
        require(msg.sender == guardian, "Keep2rGovernance::slash: !guardian");
        KPR.SLASH754(bonded, keeper, amount);
    }
    function REVOKE96(address keeper) external {
        require(msg.sender == guardian, "Keep2rGovernance::revoke: !guardian");
        KPR.REVOKE96(keeper);
    }
    function RESOLVE192(address keeper) external {
        require(msg.sender == guardian, "Keep2rGovernance::resolve: !guardian");
        KPR.RESOLVE192(keeper);
    }

    mapping (bytes32 => bool) public queuedTransactions;

    constructor(address token_) public {
        guardian = msg.sender;
        KPR = IKeep2r(token_);
        DOMAINSEPARATOR = keccak256(abi.encode(domain_typehash397, keccak256(bytes(name820)), GETCHAINID291(), address(this)));
    }

    receive() external payable { }

    function SETDELAY397(uint delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= minimum_delay353, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= maximum_delay422, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NEWDELAY307(delay);
    }

    function _QUEUETRANSACTION380(address target, uint value, string memory signature, bytes memory data, uint eta) internal returns (bytes32) {
        require(eta >= GETBLOCKTIMESTAMP893().ADD802(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QUEUETRANSACTION307(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function _CANCELTRANSACTION608(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CANCELTRANSACTION220(txHash, target, value, signature, data, eta);
    }

    function _EXECUTETRANSACTION42(address target, uint value, string memory signature, bytes memory data, uint eta) internal returns (bytes memory) {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(GETBLOCKTIMESTAMP893() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(GETBLOCKTIMESTAMP893() <= eta.ADD802(grace_period471), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }


        (bool success, bytes memory returnData) = target.call{value:value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit EXECUTETRANSACTION925(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function GETBLOCKTIMESTAMP893() internal view returns (uint) {

        return block.timestamp;
    }
}
