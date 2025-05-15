pragma solidity^0.4.11;

import "./PLCRVoting.sol";
import "tokens/eip20/EIP20.sol";

contract Parameterizer {





  event _ReparameterizationProposal(address proposer, string name, uint value, bytes32 propID);
  event _NewChallenge(address challenger, bytes32 propID, uint pollID);






  struct ParamProposal {
    uint appExpiry;
    uint challengeID;
    uint deposit;
    string name;
    address owner;
    uint processBy;
    uint value;
  }

  struct Challenge {
    uint rewardPool;
    address challenger;
    bool resolved;
    uint stake;
    uint winningTokens;
    mapping(address => bool) tokenClaims;
  }





  mapping(bytes32 => uint) public params;


  mapping(uint => Challenge) public challenges;


  mapping(bytes32 => ParamProposal) public proposals;


  EIP20 public token;
  PLCRVoting public voting;
  uint public PROCESSBY = 604800;






















  function Parameterizer(
    address _tokenAddr,
    address _plcrAddr,
    uint _minDeposit,
    uint _pMinDeposit,
    uint _applyStageLen,
    uint _pApplyStageLen,
    uint _commitStageLen,
    uint _pCommitStageLen,
    uint _revealStageLen,
    uint _pRevealStageLen,
    uint _dispensationPct,
    uint _pDispensationPct,
    uint _voteQuorum,
    uint _pVoteQuorum
    ) public {
      token = EIP20(_tokenAddr);
      voting = PLCRVoting(_plcrAddr);

      set("minDeposit", _minDeposit);
      set("pMinDeposit", _pMinDeposit);
      set("applyStageLen", _applyStageLen);
      set("pApplyStageLen", _pApplyStageLen);
      set("commitStageLen", _commitStageLen);
      set("pCommitStageLen", _pCommitStageLen);
      set("revealStageLen", _revealStageLen);
      set("pRevealStageLen", _pRevealStageLen);
      set("dispensationPct", _dispensationPct);
      set("pDispensationPct", _pDispensationPct);
      set("voteQuorum", _voteQuorum);
      set("pVoteQuorum", _pVoteQuorum);
  }










  function proposeReparameterization(string _name, uint _value) public returns (bytes32) {
    uint deposit = get("pMinDeposit");
    bytes32 propID = keccak256(_name, _value);

    require(!propExists(propID));
    require(get(_name) != _value);
    require(token.transferFrom(msg.sender, this, deposit));


    proposals[propID] = ParamProposal({

      appExpiry: now + get("pApplyStageLen"),
      challengeID: 0,
      deposit: deposit,
      name: _name,
      owner: msg.sender,

      processBy: now + get("pApplyStageLen") + get("pCommitStageLen") +
        get("pRevealStageLen") + PROCESSBY,
      value: _value
    });

    _ReparameterizationProposal(msg.sender, _name, _value, propID);
    return propID;
  }





  function challengeReparameterization(bytes32 _propID) public returns (uint challengeID) {
    ParamProposal memory prop = proposals[_propID];
    uint deposit = get("pMinDeposit");

    require(propExists(_propID) && prop.challengeID == 0);


    require(token.transferFrom(msg.sender, this, deposit));

    uint pollID = voting.startPoll(
      get("pVoteQuorum"),
      get("pCommitStageLen"),
      get("pRevealStageLen")
    );

    challenges[pollID] = Challenge({
      challenger: msg.sender,

      rewardPool: ((100 - get("pDispensationPct")) * deposit) / 100,
      stake: deposit,
      resolved: false,
      winningTokens: 0
    });

    proposals[_propID].challengeID = pollID;

    _NewChallenge(msg.sender, _propID, pollID);
    return pollID;
  }





  function processProposal(bytes32 _propID) public {
    ParamProposal storage prop = proposals[_propID];

    if (canBeSet(_propID)) {
      set(prop.name, prop.value);
    } else if (challengeCanBeResolved(_propID)) {
      resolveChallenge(_propID);
    } else if (now > prop.processBy) {
      require(token.transfer(prop.owner, prop.deposit));
    } else {
      revert();
    }

    delete proposals[_propID];
  }






  function claimReward(uint _challengeID, uint _salt) public {

    require(challenges[_challengeID].tokenClaims[msg.sender] == false);
    require(challenges[_challengeID].resolved == true);

    uint voterTokens = voting.getNumPassingTokens(msg.sender, _challengeID, _salt);
    uint reward = voterReward(msg.sender, _challengeID, _salt);



    challenges[_challengeID].winningTokens -= voterTokens;
    challenges[_challengeID].rewardPool -= reward;

    require(token.transfer(msg.sender, reward));


    challenges[_challengeID].tokenClaims[msg.sender] = true;
  }












  function voterReward(address _voter, uint _challengeID, uint _salt)
  public view returns (uint) {
    uint winningTokens = challenges[_challengeID].winningTokens;
    uint rewardPool = challenges[_challengeID].rewardPool;
    uint voterTokens = voting.getNumPassingTokens(_voter, _challengeID, _salt);
    return (voterTokens * rewardPool) / winningTokens;
  }





  function canBeSet(bytes32 _propID) view public returns (bool) {
    ParamProposal memory prop = proposals[_propID];

    return (now > prop.appExpiry && now < prop.processBy && prop.challengeID == 0);
  }





  function propExists(bytes32 _propID) view public returns (bool) {
    return proposals[_propID].processBy > 0;
  }





  function challengeCanBeResolved(bytes32 _propID) view public returns (bool) {
    ParamProposal memory prop = proposals[_propID];
    Challenge memory challenge = challenges[prop.challengeID];

    return (prop.challengeID > 0 && challenge.resolved == false &&
            voting.pollEnded(prop.challengeID));
  }





  function challengeWinnerReward(uint _challengeID) public view returns (uint) {
    if(voting.getTotalNumberOfTokensForWinningOption(_challengeID) == 0) {

      return 2 * challenges[_challengeID].stake;
    }

    return (2 * challenges[_challengeID].stake) - challenges[_challengeID].rewardPool;
  }





  function get(string _name) public view returns (uint value) {
    return params[keccak256(_name)];
  }









  function resolveChallenge(bytes32 _propID) private {
    ParamProposal memory prop = proposals[_propID];
    Challenge storage challenge = challenges[prop.challengeID];


    uint reward = challengeWinnerReward(prop.challengeID);

    if (voting.isPassed(prop.challengeID)) {
      if(prop.processBy > now) {
        set(prop.name, prop.value);
      }
      require(token.transfer(prop.owner, reward));
    }
    else {
      require(token.transfer(challenges[prop.challengeID].challenger, reward));
    }

    challenge.winningTokens =
      voting.getTotalNumberOfTokensForWinningOption(prop.challengeID);
    challenge.resolved = true;
  }






  function set(string _name, uint _value) private {
    params[keccak256(_name)] = _value;
  }
}

