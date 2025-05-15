pragma solidity ^0.5.13;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/Math.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";

import "./interfaces/IGovernance.sol";
import "./Proposals.sol";
import "../common/interfaces/IAccounts.sol";
import "../common/ExtractFunctionSignature.sol";
import "../common/InitializableV2.sol";
import "../common/FixidityLib.sol";
import "../common/linkedlists/IntegerSortedLinkedList.sol";
import "../common/UsingRegistry.sol";
import "../common/UsingPrecompiles.sol";
import "../common/interfaces/ICeloVersionedContract.sol";
import "../common/libraries/ReentrancyGuard.sol";




contract Governance is
  IGovernance,
  ICeloVersionedContract,
  Ownable,
  InitializableV2,
  ReentrancyGuard,
  UsingRegistry,
  UsingPrecompiles
{
  using Proposals for Proposals.Proposal;
  using FixidityLib for FixidityLib.Fraction;
  using SafeMath for uint256;
  using IntegerSortedLinkedList for SortedLinkedList.List;
  using BytesLib for bytes;
  using Address for address payable;

  uint256 private constant FIXED_HALF = 500000000000000000000000;

  enum VoteValue { None, Abstain, No, Yes }

  struct UpvoteRecord {
    uint256 proposalId;
    uint256 weight;
  }

  struct VoteRecord {
    Proposals.VoteValue value;
    uint256 proposalId;
    uint256 weight;
  }

  struct Voter {

    UpvoteRecord upvote;
    uint256 mostRecentReferendumProposal;

    mapping(uint256 => VoteRecord) referendumVotes;
  }

  struct ContractConstitution {
    FixidityLib.Fraction defaultThreshold;

    mapping(bytes4 => FixidityLib.Fraction) functionThresholds;
  }

  struct HotfixRecord {
    bool executed;
    bool approved;
    uint256 preparedEpoch;
    mapping(address => bool) whitelisted;
  }



  struct ParticipationParameters {

    FixidityLib.Fraction baseline;

    FixidityLib.Fraction baselineFloor;

    FixidityLib.Fraction baselineUpdateFactor;

    FixidityLib.Fraction baselineQuorumFactor;
  }

  Proposals.StageDurations public stageDurations;
  uint256 public queueExpiry;
  uint256 public dequeueFrequency;
  address public approver;
  uint256 public lastDequeue;
  uint256 public concurrentProposals;
  uint256 public proposalCount;
  uint256 public minDeposit;
  mapping(address => uint256) public refundedDeposits;
  mapping(address => ContractConstitution) private constitution;
  mapping(uint256 => Proposals.Proposal) private proposals;
  mapping(address => Voter) private voters;
  mapping(bytes32 => HotfixRecord) public hotfixes;
  SortedLinkedList.List private queue;
  uint256[] public dequeued;
  uint256[] public emptyIndices;
  ParticipationParameters private participationParameters;

  event ApproverSet(address indexed approver);

  event ConcurrentProposalsSet(uint256 concurrentProposals);

  event MinDepositSet(uint256 minDeposit);

  event QueueExpirySet(uint256 queueExpiry);

  event DequeueFrequencySet(uint256 dequeueFrequency);

  event ApprovalStageDurationSet(uint256 approvalStageDuration);

  event ReferendumStageDurationSet(uint256 referendumStageDuration);

  event ExecutionStageDurationSet(uint256 executionStageDuration);

  event ConstitutionSet(address indexed destination, bytes4 indexed functionId, uint256 threshold);

  event ProposalQueued(
    uint256 indexed proposalId,
    address indexed proposer,
    uint256 transactionCount,
    uint256 deposit,
    uint256 timestamp
  );

  event ProposalUpvoted(uint256 indexed proposalId, address indexed account, uint256 upvotes);

  event ProposalUpvoteRevoked(
    uint256 indexed proposalId,
    address indexed account,
    uint256 revokedUpvotes
  );

  event ProposalDequeued(uint256 indexed proposalId, uint256 timestamp);

  event ProposalApproved(uint256 indexed proposalId);

  event ProposalVoted(
    uint256 indexed proposalId,
    address indexed account,
    uint256 value,
    uint256 weight
  );

  event ProposalVoteRevoked(
    uint256 indexed proposalId,
    address indexed account,
    uint256 value,
    uint256 weight
  );

  event ProposalExecuted(uint256 indexed proposalId);

  event ProposalExpired(uint256 indexed proposalId);

  event ParticipationBaselineUpdated(uint256 participationBaseline);

  event ParticipationFloorSet(uint256 participationFloor);

  event ParticipationBaselineUpdateFactorSet(uint256 baselineUpdateFactor);

  event ParticipationBaselineQuorumFactorSet(uint256 baselineQuorumFactor);

  event HotfixWhitelisted(bytes32 indexed hash, address whitelister);

  event HotfixApproved(bytes32 indexed hash);

  event HotfixPrepared(bytes32 indexed hash, uint256 indexed epoch);

  event HotfixExecuted(bytes32 indexed hash);

  modifier hotfixNotExecuted(bytes32 hash) {
    require(!hotfixes[hash].executed, "hotfix already executed");
    _;
  }

  modifier onlyApprover() {
    require(msg.sender == approver, "msg.sender not approver");
    _;
  }





  constructor(bool test) public InitializableV2(test) {}

  function() external payable {
    require(msg.data.length == 0, "unknown method");
  }





  function getVersionNumber() external pure returns (uint256, uint256, uint256, uint256) {
    return (1, 2, 1, 0);
  }






















  function initialize(
    address registryAddress,
    address _approver,
    uint256 _concurrentProposals,
    uint256 _minDeposit,
    uint256 _queueExpiry,
    uint256 _dequeueFrequency,
    uint256 approvalStageDuration,
    uint256 referendumStageDuration,
    uint256 executionStageDuration,
    uint256 participationBaseline,
    uint256 participationFloor,
    uint256 baselineUpdateFactor,
    uint256 baselineQuorumFactor
  ) external initializer {
    _transferOwnership(msg.sender);
    setRegistry(registryAddress);
    setApprover(_approver);
    setConcurrentProposals(_concurrentProposals);
    setMinDeposit(_minDeposit);
    setQueueExpiry(_queueExpiry);
    setDequeueFrequency(_dequeueFrequency);
    setApprovalStageDuration(approvalStageDuration);
    setReferendumStageDuration(referendumStageDuration);
    setExecutionStageDuration(executionStageDuration);
    setParticipationBaseline(participationBaseline);
    setParticipationFloor(participationFloor);
    setBaselineUpdateFactor(baselineUpdateFactor);
    setBaselineQuorumFactor(baselineQuorumFactor);

    lastDequeue = now;
  }





  function setApprover(address _approver) public onlyOwner {
    require(_approver != address(0), "Approver cannot be 0");
    require(_approver != approver, "Approver unchanged");
    approver = _approver;
    emit ApproverSet(_approver);
  }





  function setConcurrentProposals(uint256 _concurrentProposals) public onlyOwner {
    require(_concurrentProposals > 0, "Number of proposals must be larger than zero");
    require(_concurrentProposals != concurrentProposals, "Number of proposals unchanged");
    concurrentProposals = _concurrentProposals;
    emit ConcurrentProposalsSet(_concurrentProposals);
  }





  function setMinDeposit(uint256 _minDeposit) public onlyOwner {
    require(_minDeposit > 0, "minDeposit must be larger than 0");
    require(_minDeposit != minDeposit, "Minimum deposit unchanged");
    minDeposit = _minDeposit;
    emit MinDepositSet(_minDeposit);
  }





  function setQueueExpiry(uint256 _queueExpiry) public onlyOwner {
    require(_queueExpiry > 0, "QueueExpiry must be larger than 0");
    require(_queueExpiry != queueExpiry, "QueueExpiry unchanged");
    queueExpiry = _queueExpiry;
    emit QueueExpirySet(_queueExpiry);
  }







  function setDequeueFrequency(uint256 _dequeueFrequency) public onlyOwner {
    require(_dequeueFrequency > 0, "dequeueFrequency must be larger than 0");
    require(_dequeueFrequency != dequeueFrequency, "dequeueFrequency unchanged");
    dequeueFrequency = _dequeueFrequency;
    emit DequeueFrequencySet(_dequeueFrequency);
  }





  function setApprovalStageDuration(uint256 approvalStageDuration) public onlyOwner {
    require(approvalStageDuration > 0, "Duration must be larger than 0");
    require(approvalStageDuration != stageDurations.approval, "Duration unchanged");
    stageDurations.approval = approvalStageDuration;
    emit ApprovalStageDurationSet(approvalStageDuration);
  }





  function setReferendumStageDuration(uint256 referendumStageDuration) public onlyOwner {
    require(referendumStageDuration > 0, "Duration must be larger than 0");
    require(referendumStageDuration != stageDurations.referendum, "Duration unchanged");
    stageDurations.referendum = referendumStageDuration;
    emit ReferendumStageDurationSet(referendumStageDuration);
  }





  function setExecutionStageDuration(uint256 executionStageDuration) public onlyOwner {
    require(executionStageDuration > 0, "Duration must be larger than 0");
    require(executionStageDuration != stageDurations.execution, "Duration unchanged");
    stageDurations.execution = executionStageDuration;
    emit ExecutionStageDurationSet(executionStageDuration);
  }





  function setParticipationBaseline(uint256 participationBaseline) public onlyOwner {
    FixidityLib.Fraction memory participationBaselineFrac = FixidityLib.wrap(participationBaseline);
    require(
      FixidityLib.isProperFraction(participationBaselineFrac),
      "Participation baseline greater than one"
    );
    require(
      !participationBaselineFrac.equals(participationParameters.baseline),
      "Participation baseline unchanged"
    );
    participationParameters.baseline = participationBaselineFrac;
    emit ParticipationBaselineUpdated(participationBaseline);
  }





  function setParticipationFloor(uint256 participationFloor) public onlyOwner {
    FixidityLib.Fraction memory participationFloorFrac = FixidityLib.wrap(participationFloor);
    require(
      FixidityLib.isProperFraction(participationFloorFrac),
      "Participation floor greater than one"
    );
    require(
      !participationFloorFrac.equals(participationParameters.baselineFloor),
      "Participation baseline floor unchanged"
    );
    participationParameters.baselineFloor = participationFloorFrac;
    emit ParticipationFloorSet(participationFloor);
  }





  function setBaselineUpdateFactor(uint256 baselineUpdateFactor) public onlyOwner {
    FixidityLib.Fraction memory baselineUpdateFactorFrac = FixidityLib.wrap(baselineUpdateFactor);
    require(
      FixidityLib.isProperFraction(baselineUpdateFactorFrac),
      "Baseline update factor greater than one"
    );
    require(
      !baselineUpdateFactorFrac.equals(participationParameters.baselineUpdateFactor),
      "Baseline update factor unchanged"
    );
    participationParameters.baselineUpdateFactor = baselineUpdateFactorFrac;
    emit ParticipationBaselineUpdateFactorSet(baselineUpdateFactor);
  }





  function setBaselineQuorumFactor(uint256 baselineQuorumFactor) public onlyOwner {
    FixidityLib.Fraction memory baselineQuorumFactorFrac = FixidityLib.wrap(baselineQuorumFactor);
    require(
      FixidityLib.isProperFraction(baselineQuorumFactorFrac),
      "Baseline quorum factor greater than one"
    );
    require(
      !baselineQuorumFactorFrac.equals(participationParameters.baselineQuorumFactor),
      "Baseline quorum factor unchanged"
    );
    participationParameters.baselineQuorumFactor = baselineQuorumFactorFrac;
    emit ParticipationBaselineQuorumFactorSet(baselineQuorumFactor);
  }









  function setConstitution(address destination, bytes4 functionId, uint256 threshold)
    external
    onlyOwner
  {
    require(destination != address(0), "Destination cannot be zero");
    require(
      threshold > FIXED_HALF && threshold <= FixidityLib.fixed1().unwrap(),
      "Threshold has to be greater than majority and not greater than unanimity"
    );
    if (functionId == 0) {
      constitution[destination].defaultThreshold = FixidityLib.wrap(threshold);
    } else {
      constitution[destination].functionThresholds[functionId] = FixidityLib.wrap(threshold);
    }
    emit ConstitutionSet(destination, functionId, threshold);
  }











  function propose(
    uint256[] calldata values,
    address[] calldata destinations,
    bytes calldata data,
    uint256[] calldata dataLengths,
    string calldata descriptionUrl
  ) external payable returns (uint256) {
    dequeueProposalsIfReady();
    require(msg.value >= minDeposit, "Too small deposit");

    proposalCount = proposalCount.add(1);
    Proposals.Proposal storage proposal = proposals[proposalCount];
    proposal.make(values, destinations, data, dataLengths, msg.sender, msg.value);
    proposal.setDescriptionUrl(descriptionUrl);
    queue.push(proposalCount);

    emit ProposalQueued(proposalCount, msg.sender, proposal.transactions.length, msg.value, now);
    return proposalCount;
  }






  function removeIfQueuedAndExpired(uint256 proposalId) private returns (bool) {
    if (isQueued(proposalId) && isQueuedProposalExpired(proposalId)) {
      queue.remove(proposalId);
      emit ProposalExpired(proposalId);
      return true;
    }
    return false;
  }






  function requireDequeuedAndDeleteExpired(uint256 proposalId, uint256 index)
    private
    returns (Proposals.Proposal storage, Proposals.Stage)
  {
    Proposals.Proposal storage proposal = proposals[proposalId];
    require(_isDequeuedProposal(proposal, proposalId, index), "Proposal not dequeued");
    Proposals.Stage stage = proposal.getDequeuedStage(stageDurations);
    if (_isDequeuedProposalExpired(proposal, stage)) {
      deleteDequeuedProposal(proposal, proposalId, index);
    }
    return (proposal, stage);
  }










  function upvote(uint256 proposalId, uint256 lesser, uint256 greater)
    external
    nonReentrant
    returns (bool)
  {
    dequeueProposalsIfReady();

    if (removeIfQueuedAndExpired(proposalId)) {
      return false;
    }

    address account = getAccounts().voteSignerToAccount(msg.sender);
    Voter storage voter = voters[account];
    removeIfQueuedAndExpired(voter.upvote.proposalId);


    uint256 weight = getLockedGold().getAccountTotalLockedGold(account);
    require(weight > 0, "cannot upvote without locking gold");
    require(queue.contains(proposalId), "cannot upvote a proposal not in the queue");
    require(
      voter.upvote.proposalId == 0 || !queue.contains(voter.upvote.proposalId),
      "cannot upvote more than one queued proposal"
    );
    uint256 upvotes = queue.getValue(proposalId).add(weight);
    queue.update(proposalId, upvotes, lesser, greater);
    voter.upvote = UpvoteRecord(proposalId, weight);
    emit ProposalUpvoted(proposalId, account, weight);
    return true;
  }






  function getProposalStage(uint256 proposalId) external view returns (Proposals.Stage) {
    if (proposalId == 0 || proposalId > proposalCount) {
      return Proposals.Stage.None;
    }
    Proposals.Proposal storage proposal = proposals[proposalId];
    if (isQueued(proposalId)) {
      return
        _isQueuedProposalExpired(proposal) ? Proposals.Stage.Expiration : Proposals.Stage.Queued;
    } else {
      Proposals.Stage stage = proposal.getDequeuedStage(stageDurations);
      return _isDequeuedProposalExpired(proposal, stage) ? Proposals.Stage.Expiration : stage;
    }
  }










  function revokeUpvote(uint256 lesser, uint256 greater) external nonReentrant returns (bool) {
    dequeueProposalsIfReady();
    address account = getAccounts().voteSignerToAccount(msg.sender);
    Voter storage voter = voters[account];
    uint256 proposalId = voter.upvote.proposalId;
    require(proposalId != 0, "Account has no historical upvote");
    removeIfQueuedAndExpired(proposalId);
    if (queue.contains(proposalId)) {
      queue.update(
        proposalId,
        queue.getValue(proposalId).sub(voter.upvote.weight),
        lesser,
        greater
      );
      emit ProposalUpvoteRevoked(proposalId, account, voter.upvote.weight);
    }
    voter.upvote = UpvoteRecord(0, 0);
    return true;
  }







  function approve(uint256 proposalId, uint256 index) external onlyApprover returns (bool) {
    dequeueProposalsIfReady();
    (Proposals.Proposal storage proposal, Proposals.Stage stage) = requireDequeuedAndDeleteExpired(
      proposalId,
      index
    );
    if (!proposal.exists()) {
      return false;
    }

    require(!proposal.isApproved(), "Proposal already approved");
    require(stage == Proposals.Stage.Approval, "Proposal not in approval stage");
    proposal.approved = true;

    proposal.networkWeight = getLockedGold().getTotalLockedGold();
    emit ProposalApproved(proposalId);
    return true;
  }





















































  function revokeVotes() external nonReentrant returns (bool) {
    address account = getAccounts().voteSignerToAccount(msg.sender);
    Voter storage voter = voters[account];
    for (
      uint256 dequeueIndex = 0;
      dequeueIndex < dequeued.length;
      dequeueIndex = dequeueIndex.add(1)
    ) {
      VoteRecord storage voteRecord = voter.referendumVotes[dequeueIndex];
      (Proposals.Proposal storage proposal, Proposals.Stage stage) =
        requireDequeuedAndDeleteExpired(voteRecord.proposalId, dequeueIndex);

      require(stage == Proposals.Stage.Referendum, "Incorrect proposal state");
      Proposals.VoteValue value = voteRecord.value;
      proposal.updateVote(voteRecord.weight, 0, value, Proposals.VoteValue.None);
      proposal.networkWeight = getLockedGold().getTotalLockedGold();
      emit ProposalVoteRevoked(voteRecord.proposalId, account, uint256(value), voteRecord.weight);
      delete voter.referendumVotes[dequeueIndex];
    }
    voter.mostRecentReferendumProposal = 0;
    return true;
  }








  function execute(uint256 proposalId, uint256 index) external nonReentrant returns (bool) {
    dequeueProposalsIfReady();
    (Proposals.Proposal storage proposal, Proposals.Stage stage) = requireDequeuedAndDeleteExpired(
      proposalId,
      index
    );
    bool notExpired = proposal.exists();
    if (notExpired) {
      require(
        stage == Proposals.Stage.Execution && _isProposalPassing(proposal),
        "Proposal not in execution stage or not passing"
      );
      proposal.execute();
      emit ProposalExecuted(proposalId);
      deleteDequeuedProposal(proposal, proposalId, index);
    }
    return notExpired;
  }





  function approveHotfix(bytes32 hash) external hotfixNotExecuted(hash) onlyApprover {
    hotfixes[hash].approved = true;
    emit HotfixApproved(hash);
  }






  function isHotfixWhitelistedBy(bytes32 hash, address whitelister) public view returns (bool) {
    return hotfixes[hash].whitelisted[whitelister];
  }





  function whitelistHotfix(bytes32 hash) external hotfixNotExecuted(hash) {
    hotfixes[hash].whitelisted[msg.sender] = true;
    emit HotfixWhitelisted(hash, msg.sender);
  }





  function prepareHotfix(bytes32 hash) external hotfixNotExecuted(hash) {
    require(isHotfixPassing(hash), "hotfix not whitelisted by 2f+1 validators");
    uint256 epoch = getEpochNumber();
    require(hotfixes[hash].preparedEpoch < epoch, "hotfix already prepared for this epoch");
    hotfixes[hash].preparedEpoch = epoch;
    emit HotfixPrepared(hash, epoch);
  }










  function executeHotfix(
    uint256[] calldata values,
    address[] calldata destinations,
    bytes calldata data,
    uint256[] calldata dataLengths,
    bytes32 salt
  ) external {
    bytes32 hash = keccak256(abi.encode(values, destinations, data, dataLengths, salt));

    (bool approved, bool executed, uint256 preparedEpoch) = getHotfixRecord(hash);
    require(!executed, "hotfix already executed");
    require(approved, "hotfix not approved");
    require(preparedEpoch == getEpochNumber(), "hotfix must be prepared for this epoch");

    Proposals.makeMem(values, destinations, data, dataLengths, msg.sender, 0).executeMem();

    hotfixes[hash].executed = true;
    emit HotfixExecuted(hash);
  }





  function withdraw() external nonReentrant returns (bool) {
    uint256 value = refundedDeposits[msg.sender];
    require(value > 0, "Nothing to withdraw");
    require(value <= address(this).balance, "Inconsistent balance");
    refundedDeposits[msg.sender] = 0;
    msg.sender.sendValue(value);
    return true;
  }






  function isVoting(address account) external view returns (bool) {
    Voter storage voter = voters[account];
    uint256 upvotedProposal = voter.upvote.proposalId;
    bool isVotingQueue = upvotedProposal != 0 &&
      isQueued(upvotedProposal) &&
      !isQueuedProposalExpired(upvotedProposal);
    Proposals.Proposal storage proposal = proposals[voter.mostRecentReferendumProposal];
    bool isVotingReferendum = (proposal.getDequeuedStage(stageDurations) ==
      Proposals.Stage.Referendum);
    return isVotingQueue || isVotingReferendum;
  }





  function getApprovalStageDuration() external view returns (uint256) {
    return stageDurations.approval;
  }





  function getReferendumStageDuration() external view returns (uint256) {
    return stageDurations.referendum;
  }





  function getExecutionStageDuration() external view returns (uint256) {
    return stageDurations.execution;
  }





  function getParticipationParameters() external view returns (uint256, uint256, uint256, uint256) {
    return (
      participationParameters.baseline.unwrap(),
      participationParameters.baselineFloor.unwrap(),
      participationParameters.baselineUpdateFactor.unwrap(),
      participationParameters.baselineQuorumFactor.unwrap()
    );
  }






  function proposalExists(uint256 proposalId) external view returns (bool) {
    return proposals[proposalId].exists();
  }






  function getProposal(uint256 proposalId)
    external
    view
    returns (address, uint256, uint256, uint256, string memory)
  {
    return proposals[proposalId].unpack();
  }







  function getProposalTransaction(uint256 proposalId, uint256 index)
    external
    view
    returns (uint256, address, bytes memory)
  {
    return proposals[proposalId].getTransaction(index);
  }






  function isApproved(uint256 proposalId) external view returns (bool) {
    return proposals[proposalId].isApproved();
  }






  function getVoteTotals(uint256 proposalId) external view returns (uint256, uint256, uint256) {
    return proposals[proposalId].getVoteTotals();
  }







  function getVoteRecord(address account, uint256 index)
    external
    view
    returns (uint256, uint256, uint256)
  {
    VoteRecord storage record = voters[account].referendumVotes[index];
    return (record.proposalId, uint256(record.value), record.weight);
  }





  function getQueueLength() external view returns (uint256) {
    return queue.list.numElements;
  }






  function getUpvotes(uint256 proposalId) external view returns (uint256) {
    require(isQueued(proposalId), "Proposal not queued");
    return queue.getValue(proposalId);
  }






  function getQueue() external view returns (uint256[] memory, uint256[] memory) {
    return queue.getElements();
  }






  function getDequeue() external view returns (uint256[] memory) {
    return dequeued;
  }






  function getUpvoteRecord(address account) external view returns (uint256, uint256) {
    UpvoteRecord memory upvoteRecord = voters[account].upvote;
    return (upvoteRecord.proposalId, upvoteRecord.weight);
  }






  function getMostRecentReferendumProposal(address account) external view returns (uint256) {
    return voters[account].mostRecentReferendumProposal;
  }






  function hotfixWhitelistValidatorTally(bytes32 hash) public view returns (uint256) {
    uint256 tally = 0;
    uint256 n = numberValidatorsInCurrentSet();
    IAccounts accounts = getAccounts();
    for (uint256 i = 0; i < n; i = i.add(1)) {
      address validatorSigner = validatorSignerAddressFromCurrentSet(i);
      address validatorAccount = accounts.signerToAccount(validatorSigner);
      if (
        isHotfixWhitelistedBy(hash, validatorSigner) ||
        isHotfixWhitelistedBy(hash, validatorAccount)
      ) {
        tally = tally.add(1);
      }
    }
    return tally;
  }






  function isHotfixPassing(bytes32 hash) public view returns (bool) {
    return hotfixWhitelistValidatorTally(hash) >= minQuorumSizeInCurrentSet();
  }






  function getHotfixRecord(bytes32 hash) public view returns (bool, bool, uint256) {
    return (hotfixes[hash].approved, hotfixes[hash].executed, hotfixes[hash].preparedEpoch);
  }






  function dequeueProposalsIfReady() public {

    if (now >= lastDequeue.add(dequeueFrequency)) {
      uint256 numProposalsToDequeue = Math.min(concurrentProposals, queue.list.numElements);
      uint256[] memory dequeuedIds = queue.popN(numProposalsToDequeue);
      for (uint256 i = 0; i < numProposalsToDequeue; i = i.add(1)) {
        uint256 proposalId = dequeuedIds[i];
        Proposals.Proposal storage proposal = proposals[proposalId];
        if (_isQueuedProposalExpired(proposal)) {
          emit ProposalExpired(proposalId);
          continue;
        }
        refundedDeposits[proposal.proposer] = refundedDeposits[proposal.proposer].add(
          proposal.deposit
        );

        proposal.timestamp = now;
        if (emptyIndices.length > 0) {
          uint256 indexOfLastEmptyIndex = emptyIndices.length.sub(1);
          dequeued[emptyIndices[indexOfLastEmptyIndex]] = proposalId;
          delete emptyIndices[indexOfLastEmptyIndex];
          emptyIndices.length = indexOfLastEmptyIndex;
        } else {
          dequeued.push(proposalId);
        }

        emit ProposalDequeued(proposalId, now);
      }

      lastDequeue = now;
    }
  }







  function isQueued(uint256 proposalId) public view returns (bool) {
    return queue.contains(proposalId);
  }







  function isProposalPassing(uint256 proposalId) external view returns (bool) {
    return _isProposalPassing(proposals[proposalId]);
  }







  function _isProposalPassing(Proposals.Proposal storage proposal) private view returns (bool) {
    FixidityLib.Fraction memory support = proposal.getSupportWithQuorumPadding(
      participationParameters.baseline.multiply(participationParameters.baselineQuorumFactor)
    );
    for (uint256 i = 0; i < proposal.transactions.length; i = i.add(1)) {
      bytes4 functionId = ExtractFunctionSignature.extractFunctionSignature(
        proposal.transactions[i].data
      );
      FixidityLib.Fraction memory threshold = _getConstitution(
        proposal.transactions[i].destination,
        functionId
      );
      if (support.lte(threshold)) {
        return false;
      }
    }
    return true;
  }







  function isDequeuedProposal(uint256 proposalId, uint256 index) external view returns (bool) {
    return _isDequeuedProposal(proposals[proposalId], proposalId, index);
  }








  function _isDequeuedProposal(
    Proposals.Proposal storage proposal,
    uint256 proposalId,
    uint256 index
  ) private view returns (bool) {
    require(index < dequeued.length, "Provided index greater than dequeue length.");
    return proposal.exists() && dequeued[index] == proposalId;
  }






  function isDequeuedProposalExpired(uint256 proposalId) external view returns (bool) {
    Proposals.Proposal storage proposal = proposals[proposalId];
    return _isDequeuedProposalExpired(proposal, proposal.getDequeuedStage(stageDurations));
  }






  function _isDequeuedProposalExpired(Proposals.Proposal storage proposal, Proposals.Stage stage)
    private
    view
    returns (bool)
  {




    return ((stage > Proposals.Stage.Execution) ||
      (stage > Proposals.Stage.Referendum && !_isProposalPassing(proposal)) ||
      (stage > Proposals.Stage.Approval && !proposal.isApproved()));
  }






  function isQueuedProposalExpired(uint256 proposalId) public view returns (bool) {
    return _isQueuedProposalExpired(proposals[proposalId]);
  }






  function _isQueuedProposalExpired(Proposals.Proposal storage proposal)
    private
    view
    returns (bool)
  {

    return now >= proposal.timestamp.add(queueExpiry);
  }








  function deleteDequeuedProposal(
    Proposals.Proposal storage proposal,
    uint256 proposalId,
    uint256 index
  ) private {
    if (proposal.isApproved() && proposal.networkWeight > 0) {
      updateParticipationBaseline(proposal);
    }
    dequeued[index] = 0;
    emptyIndices.push(index);
    delete proposals[proposalId];
  }






  function updateParticipationBaseline(Proposals.Proposal storage proposal) private {
    FixidityLib.Fraction memory participation = proposal.getParticipation();
    FixidityLib.Fraction memory participationComponent = participation.multiply(
      participationParameters.baselineUpdateFactor
    );
    FixidityLib.Fraction memory baselineComponent = participationParameters.baseline.multiply(
      FixidityLib.fixed1().subtract(participationParameters.baselineUpdateFactor)
    );
    participationParameters.baseline = participationComponent.add(baselineComponent);
    if (participationParameters.baseline.lt(participationParameters.baselineFloor)) {
      participationParameters.baseline = participationParameters.baselineFloor;
    }
    emit ParticipationBaselineUpdated(participationParameters.baseline.unwrap());
  }








  function getConstitution(address destination, bytes4 functionId) external view returns (uint256) {
    return _getConstitution(destination, functionId).unwrap();
  }

  function _getConstitution(address destination, bytes4 functionId)
    internal
    view
    returns (FixidityLib.Fraction memory)
  {

    FixidityLib.Fraction memory threshold = FixidityLib.wrap(FIXED_HALF);
    if (constitution[destination].functionThresholds[functionId].unwrap() != 0) {
      threshold = constitution[destination].functionThresholds[functionId];
    } else if (constitution[destination].defaultThreshold.unwrap() != 0) {
      threshold = constitution[destination].defaultThreshold;
    }
    return threshold;
  }
}
