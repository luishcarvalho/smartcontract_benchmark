
pragma solidity 0.7.6;
pragma abicoder v2;

import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

import {IVotingPowerStrategy} from '../../interfaces/governance/IVotingPowerStrategy.sol';
import {IKyberGovernance} from '../../interfaces/governance/IKyberGovernance.sol';
import {IKyberStaking} from '../../interfaces/staking/IKyberStaking.sol';
import {EpochUtils} from '../../misc/EpochUtils.sol';





contract EpochVotingPowerStrategy is IVotingPowerStrategy, EpochUtils {
  using SafeMath for uint256;

  uint256 public constant MAX_PROPOSAL_PER_EPOCH = 10;
  IKyberStaking public immutable staking;
  IKyberGovernance public immutable governance;

  mapping(uint256 => uint256[]) internal epochProposals;






  constructor(IKyberGovernance _governance, IKyberStaking _staking)
    EpochUtils(_staking.epochPeriodInSeconds(), _staking.firstEpochStartTime())
  {
    staking = _staking;
    governance = _governance;
  }

  modifier onlyStaking() {
    require(msg.sender == address(staking), 'only staking');
    _;
  }

  modifier onlyGovernance() {
    require(msg.sender == address(governance), 'only governance');
    _;
  }





  function handleProposalCreation(
    uint256 proposalId,
    uint256 startTime,












  function handleProposalCancellation(uint256 proposalId) external override onlyGovernance {
    IKyberGovernance.ProposalWithoutVote memory proposal = governance.getProposalById(proposalId);
    uint256 epoch = getEpochNumber(proposal.startTime);

    uint256[] storage proposalIds = epochProposals[epoch];
    for (uint256 i = 0; i < proposalIds.length; i++) {
      if (proposalIds[i] == proposalId) {

        proposalIds[i] = proposalIds[proposalIds.length - 1];
        proposalIds.pop();
        break;
      }
    }
  }






  function handleVote(
    address voter,













  function handleWithdrawal(
    address user,















  function getVotingPower(address voter, uint256 timestamp)
    external
    override
    view
    returns (uint256 votingPower)
  {
    uint256 currentEpoch = getEpochNumber(timestamp);
    (uint256 stake, uint256 dStake, address representative) = staking.getStakerData(
      voter,
      currentEpoch
    );
    votingPower = representative == voter ? stake.add(dStake) : dStake;
  }




  function validateProposalCreation(uint256 startTime, uint256 endTime)
    external
    override
    view
    returns (bool)
  {

    if (startTime < block.timestamp) {
      return false;
    }
    uint256 startEpoch = getEpochNumber(startTime);

    if (startEpoch != getEpochNumber(endTime)) {
      return false;
    }

    if (startEpoch > getCurrentEpochNumber().add(1)) {
      return false;
    }

    if (epochProposals[startEpoch].length >= MAX_PROPOSAL_PER_EPOCH) {
      return false;
    }
    return true;
  }

  function getMaxVotingPower() external override view returns (uint256) {
    return staking.kncToken().totalSupply();
  }

  function getListProposalIds(uint256 epoch) external view returns (uint256[] memory proposalIds) {
    return epochProposals[epoch];
  }
}
