


















pragma solidity ^0.5.16;

interface CvpInterface {

  function name() external view returns (string memory);


  function symbol() external view returns (string memory);


  function decimals() external view returns (uint8);


  function totalSupply() external view returns (uint);


  function delegates(address _addr) external view returns (address);


  function numCheckpoints(address _addr) external view returns (uint32);


  function DOMAIN_TYPEHASH() external view returns (bytes32);


  function DELEGATION_TYPEHASH() external view returns (bytes32);


  function nonces(address _addr) external view returns (uint);


  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);


  event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);


  event Transfer(address indexed from, address indexed to, uint256 amount);


  event Approval(address indexed owner, address indexed spender, uint256 amount);







  function allowance(address account, address spender) external view returns (uint);









  function approve(address spender, uint rawAmount) external returns (bool);






  function balanceOf(address account) external view returns (uint);







  function transfer(address dst, uint rawAmount) external returns (bool);








  function transferFrom(address src, address dst, uint rawAmount) external returns (bool);





  function delegate(address delegatee) external;










  function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;






  function getCurrentVotes(address account) external view returns (uint96);








  function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}



pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


contract GovernorAlphaInterface {

  function name() external view returns (string memory);


  function quorumVotes() external pure returns (uint);


  function proposalThreshold() external pure returns (uint);


  function proposalMaxOperations() external pure returns (uint);


  function votingDelay() external pure returns (uint);


  function votingPeriod() external pure returns (uint);


  function timelock() external view returns (TimelockInterface);


  function guardian() external view returns (address);


  function proposalCount() external view returns (uint);


  function proposals(uint _id) external view returns (
    uint id,
    address proposer,
    uint eta,
    uint startBlock,
    uint endBlock,
    uint forVotes,
    uint againstVotes,
    bool canceled,
    bool executed
  );

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


  struct Receipt {

    bool hasVoted;


    bool support;


    uint256 votes;
  }


  function latestProposalIds(address _addr) external view returns (uint);


  function DOMAIN_TYPEHASH() external view returns (bytes32);


  function BALLOT_TYPEHASH() external view returns (bytes32);


  event ProposalCreated(uint indexed id, address indexed proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);


  event VoteCast(address indexed voter, uint indexed proposalId, bool indexed support, uint votes);


  event ProposalCanceled(uint indexed id);


  event ProposalQueued(uint indexed id, uint eta);


  event ProposalExecuted(uint indexed id);

  function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint);

  function queue(uint proposalId) public;

  function execute(uint proposalId) public payable;

  function cancel(uint proposalId) public;

  function getActions(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas);

  function getReceipt(uint proposalId, address voter) public view returns (Receipt memory);

  function getVoteSources() external view returns (address[] memory);

  function state(uint proposalId) public view returns (ProposalState);

  function castVote(uint proposalId, bool support) public;

  function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public;

  function __acceptAdmin() public;

  function __abdicate() public ;

  function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public;

  function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public;
}

interface TimelockInterface {
  function delay() external view returns (uint);
  function GRACE_PERIOD() external view returns (uint);
  function acceptAdmin() external;
  function queuedTransactions(bytes32 hash) external view returns (bool);
  function queueTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
  function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;
  function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}



pragma solidity ^0.5.16;


contract PPGovernorL1 is GovernorAlphaInterface {

  string public constant name = "PowerPool Governor L1";


  function quorumVotes() public pure returns (uint) { return 400000e18; }


  function proposalThreshold() public pure returns (uint) { return 10000e18; }


  function proposalMaxOperations() public pure returns (uint) { return 10; }


  function votingDelay() public pure returns (uint) { return 1; }


  function votingPeriod() public pure returns (uint) { return 17280; }


  TimelockInterface public timelock;


  address[] public voteSources;


  address public guardian;


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


  mapping (uint => Proposal) public proposals;


  mapping (address => uint) public latestProposalIds;


  bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");


  bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");


  event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);


  event VoteCast(address voter, uint proposalId, bool support, uint votes);


  event ProposalCanceled(uint id);


  event ProposalQueued(uint id, uint eta);


  event ProposalExecuted(uint id);

  constructor(address timelock_, address[] memory voteSources_, address guardian_) public {
    require(voteSources_.length > 0, "GovernorAlpha::constructor: voteSources can't be empty");

    timelock = TimelockInterface(timelock_);
    voteSources = voteSources_;
    guardian = guardian_;
  }

  function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
    require(getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(), "GovernorAlpha::propose: proposer votes below proposal threshold");
    require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorAlpha::propose: proposal function information arity mismatch");
    require(targets.length != 0, "GovernorAlpha::propose: must provide actions");
    require(targets.length <= proposalMaxOperations(), "GovernorAlpha::propose: too many actions");

    uint latestProposalId = latestProposalIds[msg.sender];
    if (block.gaslimit != 0) {
      ProposalState proposersLatestProposalState = state(latestProposalId);
      require(proposersLatestProposalState != ProposalState.Active, "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal");
      require(proposersLatestProposalState != ProposalState.Pending, "GovernorAlpha::propose: one live proposal per proposer, found an already pending proposal");
    }

    uint startBlock = add256(block.number, votingDelay());
    uint endBlock = add256(startBlock, votingPeriod());

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

    emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
    return newProposal.id;
  }

  function queue(uint proposalId) public {
    require(state(proposalId) == ProposalState.Succeeded, "GovernorAlpha::queue: proposal can only be queued if it is succeeded");
    Proposal storage proposal = proposals[proposalId];
    uint eta = add256(block.timestamp, timelock.delay());
    for (uint i = 0; i < proposal.targets.length; i++) {
      _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
    }
    proposal.eta = eta;
    emit ProposalQueued(proposalId, eta);
  }

  function _queueOrRevert(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
    require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorAlpha::_queueOrRevert: proposal action already queued at eta");
    timelock.queueTransaction(target, value, signature, data, eta);
  }

  function execute(uint proposalId) public payable {
    require(state(proposalId) == ProposalState.Queued, "GovernorAlpha::execute: proposal can only be executed if it is queued");
    Proposal storage proposal = proposals[proposalId];
    proposal.executed = true;
    for (uint i = 0; i < proposal.targets.length; i++) {
      timelock.executeTransaction.value(proposal.values[i])(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
    }
    emit ProposalExecuted(proposalId);
  }

  function cancel(uint proposalId) public {
    ProposalState state = state(proposalId);
    require(state != ProposalState.Executed, "GovernorAlpha::cancel: cannot cancel executed proposal");

    Proposal storage proposal = proposals[proposalId];
    require(msg.sender == guardian || getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(), "GovernorAlpha::cancel: proposer above threshold");

    proposal.canceled = true;
    for (uint i = 0; i < proposal.targets.length; i++) {
      timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
    }

    emit ProposalCanceled(proposalId);
  }

  function getActions(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
    Proposal storage p = proposals[proposalId];
    return (p.targets, p.values, p.signatures, p.calldatas);
  }

  function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
    return proposals[proposalId].receipts[voter];
  }

  function state(uint proposalId) public view returns (ProposalState) {
    require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
    Proposal storage proposal = proposals[proposalId];
    if (proposal.canceled) {
      return ProposalState.Canceled;
    } else if (block.timestamp <= proposal.startBlock) {
      return ProposalState.Pending;
    } else if (block.timestamp <= proposal.endBlock) {
      return ProposalState.Active;
    } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
      return ProposalState.Defeated;
    } else if (block.number == 0) {
      return ProposalState.Succeeded;
    } else if (proposal.executed) {
      return ProposalState.Executed;
    } else if (block.gaslimit >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
      return ProposalState.Expired;
    } else {
      return ProposalState.Queued;
    }
  }

  function getPriorVotes(address account, uint256 blockNumber) public view returns (uint256) {
    uint256 total = 0;
    uint256 len = voteSources.length;

    for (uint256 i = 0; i < len; i++) {
      total = add256(total, CvpInterface(voteSources[i]).getPriorVotes(account, blockNumber));
    }

    return total;
  }

  function getVoteSources() external view returns (address[] memory) {
    return voteSources;
  }

  function castVote(uint proposalId, bool support) public {
    return _castVote(msg.sender, proposalId, support);
  }

  function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
    bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "GovernorAlpha::castVoteBySig: invalid signature");
    return _castVote(signatory, proposalId, support);
  }

  function _castVote(address voter, uint proposalId, bool support) internal {
    require(state(proposalId) == ProposalState.Active, "GovernorAlpha::_castVote: voting is closed");
    Proposal storage proposal = proposals[proposalId];
    Receipt storage receipt = proposal.receipts[voter];
    require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");
    uint256 votes = getPriorVotes(voter, proposal.startBlock);

    if (support) {
      proposal.forVotes = add256(proposal.forVotes, votes);
    } else {
      proposal.againstVotes = add256(proposal.againstVotes, votes);
    }

    receipt.hasVoted = true;
    receipt.support = support;
    receipt.votes = votes;

    emit VoteCast(voter, proposalId, support, votes);
  }

  function __acceptAdmin() public {
    require(msg.sender == guardian, "GovernorAlpha::__acceptAdmin: sender must be gov guardian");
    timelock.acceptAdmin();
  }

  function __abdicate() public {
    require(msg.sender == guardian, "GovernorAlpha::__abdicate: sender must be gov guardian");
    guardian = address(0);
  }

  function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
    require(msg.sender == guardian, "GovernorAlpha::__queueSetTimelockPendingAdmin: sender must be gov guardian");
    timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
  }

  function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
    require(msg.sender == guardian, "GovernorAlpha::__executeSetTimelockPendingAdmin: sender must be gov guardian");
    timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
  }

  function add256(uint256 a, uint256 b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, "addition overflow");
    return c;
  }

  function sub256(uint256 a, uint256 b) internal pure returns (uint) {
    require(b <= a, "subtraction underflow");
    return a - b;
  }

  function getChainId() internal pure returns (uint) {
    uint chainId;
    assembly { chainId := chainid() }
    return chainId;
  }
}
