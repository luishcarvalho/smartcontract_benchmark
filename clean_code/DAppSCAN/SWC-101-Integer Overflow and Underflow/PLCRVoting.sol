pragma solidity ^0.4.8;
import "tokens/eip20/EIP20.sol";
import "dll/DLL.sol";
import "attrstore/AttributeStore.sol";





contract PLCRVoting {





    event VoteCommitted(address voter, uint pollID, uint numTokens);
    event VoteRevealed(address voter, uint pollID, uint numTokens, uint choice);
    event PollCreated(uint voteQuorum, uint commitDuration, uint revealDuration, uint pollID);
    event VotingRightsGranted(address voter, uint numTokens);
    event VotingRightsWithdrawn(address voter, uint numTokens);





    using AttributeStore for AttributeStore.Data;
    using DLL for DLL.Data;

    struct Poll {
        uint commitEndDate;
        uint revealEndDate;
        uint voteQuorum;
        uint votesFor;
        uint votesAgainst;
    }





    uint constant public INITIAL_POLL_NONCE = 0;
    uint public pollNonce;

    mapping(uint => Poll) public pollMap;
    mapping(address => uint) public voteTokenBalance;

    mapping(address => DLL.Data) dllMap;
    AttributeStore.Data store;

    EIP20 public token;









    function PLCRVoting(address _tokenAddr) public {
        token = EIP20(_tokenAddr);
        pollNonce = INITIAL_POLL_NONCE;
    }










    function requestVotingRights(uint _numTokens) external {
        require(token.balanceOf(msg.sender) >= _numTokens);
        require(token.transferFrom(msg.sender, this, _numTokens));
        voteTokenBalance[msg.sender] += _numTokens;
        VotingRightsGranted(msg.sender, _numTokens);
    }





    function withdrawVotingRights(uint _numTokens) external {

        uint availableTokens = voteTokenBalance[msg.sender] - getLockedTokens(msg.sender);
        require(availableTokens >= _numTokens);
        require(token.transfer(msg.sender, _numTokens));
        voteTokenBalance[msg.sender] -= _numTokens;
        VotingRightsWithdrawn(msg.sender, _numTokens);
    }





    function rescueTokens(uint _pollID) external {
        require(pollEnded(_pollID));
        require(!hasBeenRevealed(msg.sender, _pollID));

        dllMap[msg.sender].remove(_pollID);
    }












    function commitVote(uint _pollID, bytes32 _secretHash, uint _numTokens, uint _prevPollID) external {
        require(commitPeriodActive(_pollID));
        require(voteTokenBalance[msg.sender] >= _numTokens);
        require(_pollID != 0);



        require(_prevPollID == 0 || getCommitHash(msg.sender, _prevPollID) != 0);

        uint nextPollID = dllMap[msg.sender].getNext(_prevPollID);


        nextPollID = (nextPollID == _pollID) ? dllMap[msg.sender].getNext(_pollID) : nextPollID;

        require(validPosition(_prevPollID, nextPollID, msg.sender, _numTokens));
        dllMap[msg.sender].insert(_prevPollID, _pollID, nextPollID);

        bytes32 UUID = attrUUID(msg.sender, _pollID);

        store.setAttribute(UUID, "numTokens", _numTokens);
        store.setAttribute(UUID, "commitHash", uint(_secretHash));

        VoteCommitted(msg.sender, _pollID, _numTokens);
    }









    function validPosition(uint _prevID, uint _nextID, address _voter, uint _numTokens) public constant returns (bool valid) {
        bool prevValid = (_numTokens >= getNumTokens(_voter, _prevID));

        bool nextValid = (_numTokens <= getNumTokens(_voter, _nextID) || _nextID == 0);
        return prevValid && nextValid;
    }







    function revealVote(uint _pollID, uint _voteOption, uint _salt) external {

        require(revealPeriodActive(_pollID));
        require(!hasBeenRevealed(msg.sender, _pollID));
        require(keccak256(_voteOption, _salt) == getCommitHash(msg.sender, _pollID));

        uint numTokens = getNumTokens(msg.sender, _pollID);

        if (_voteOption == 1)
            pollMap[_pollID].votesFor += numTokens;
        else
            pollMap[_pollID].votesAgainst += numTokens;

        dllMap[msg.sender].remove(_pollID);

        VoteRevealed(msg.sender, _pollID, numTokens, _voteOption);
    }






    function getNumPassingTokens(address _voter, uint _pollID, uint _salt) public constant returns (uint correctVotes) {
        require(pollEnded(_pollID));
        require(hasBeenRevealed(_voter, _pollID));

        uint winningChoice = isPassed(_pollID) ? 1 : 0;
        bytes32 winnerHash = keccak256(winningChoice, _salt);
        bytes32 commitHash = getCommitHash(_voter, _pollID);

        require(winnerHash == commitHash);

        return getNumTokens(_voter, _pollID);
    }











    function startPoll(uint _voteQuorum, uint _commitDuration, uint _revealDuration) public returns (uint pollID) {
        pollNonce = pollNonce + 1;


        pollMap[pollNonce] = Poll({
            voteQuorum: _voteQuorum,
            commitEndDate: block.timestamp + _commitDuration,
            revealEndDate: block.timestamp + _commitDuration + _revealDuration,
            votesFor: 0,
            votesAgainst: 0
        });

        PollCreated(_voteQuorum, _commitDuration, _revealDuration, pollNonce);
        return pollNonce;
    }






    function isPassed(uint _pollID) constant public returns (bool passed) {
        require(pollEnded(_pollID));

        Poll memory poll = pollMap[_pollID];
        return (100 * poll.votesFor) > (poll.voteQuorum * (poll.votesFor + poll.votesAgainst));
    }










    function getTotalNumberOfTokensForWinningOption(uint _pollID) constant public returns (uint numTokens) {
        require(pollEnded(_pollID));

        if (isPassed(_pollID))
            return pollMap[_pollID].votesFor;
        else
            return pollMap[_pollID].votesAgainst;
    }






    function pollEnded(uint _pollID) constant public returns (bool ended) {
        require(pollExists(_pollID));

        return isExpired(pollMap[_pollID].revealEndDate);
    }







    function commitPeriodActive(uint _pollID) constant public returns (bool active) {
        require(pollExists(_pollID));

        return !isExpired(pollMap[_pollID].commitEndDate);
    }






    function revealPeriodActive(uint _pollID) constant public returns (bool active) {
        require(pollExists(_pollID));

        return !isExpired(pollMap[_pollID].revealEndDate) && !commitPeriodActive(_pollID);
    }








    function hasBeenRevealed(address _voter, uint _pollID) constant public returns (bool revealed) {
        require(pollExists(_pollID));

        return !dllMap[_voter].contains(_pollID);
    }






    function pollExists(uint _pollID) constant public returns (bool exists) {
        uint commitEndDate = pollMap[_pollID].commitEndDate;
        uint revealEndDate = pollMap[_pollID].revealEndDate;

        assert(!(commitEndDate == 0 && revealEndDate != 0));
        assert(!(commitEndDate != 0 && revealEndDate == 0));

        if(commitEndDate == 0 || revealEndDate == 0) { return false; }
        return true;
    }











    function getCommitHash(address _voter, uint _pollID) constant public returns (bytes32 commitHash) {
        return bytes32(store.getAttribute(attrUUID(_voter, _pollID), "commitHash"));
    }







    function getNumTokens(address _voter, uint _pollID) constant public returns (uint numTokens) {
        return store.getAttribute(attrUUID(_voter, _pollID), "numTokens");
    }






    function getLastNode(address _voter) constant public returns (uint pollID) {
        return dllMap[_voter].getPrev(0);
    }






    function getLockedTokens(address _voter) constant public returns (uint numTokens) {
        return getNumTokens(_voter, getLastNode(_voter));
    }







    function getInsertPointForNumTokens(address _voter, uint _numTokens)
    constant public returns (uint prevNode) {
      uint nodeID = getLastNode(_voter);
      uint tokensInNode = getNumTokens(_voter, nodeID);

      while(tokensInNode != 0) {
        tokensInNode = getNumTokens(_voter, nodeID);
        if(tokensInNode < _numTokens) {
          return nodeID;
        }
        nodeID = dllMap[_voter].getPrev(nodeID);
      }

      return nodeID;
    }










    function isExpired(uint _terminationDate) constant public returns (bool expired) {
        return (block.timestamp > _terminationDate);
    }






    function attrUUID(address _user, uint _pollID) public pure returns (bytes32 UUID) {
        return keccak256(_user, _pollID);
    }
}
