pragma solidity ^0.4.11;

import "tokens/eip20/EIP20.sol";
import "./Parameterizer.sol";
import "./PLCRVoting.sol";

contract Registry {





    event _Application(bytes32 listingHash, uint deposit, string data);
    event _Challenge(bytes32 listingHash, uint deposit, uint pollID, string data);
    event _Deposit(bytes32 listingHash, uint added, uint newTotal);
    event _Withdrawal(bytes32 listingHash, uint withdrew, uint newTotal);
    event _NewListingWhitelisted(bytes32 listingHash);
    event _ApplicationRemoved(bytes32 listingHash);
    event _ListingRemoved(bytes32 listingHash);
    event _ChallengeFailed(uint challengeID);
    event _ChallengeSucceeded(uint challengeID);
    event _RewardClaimed(address voter, uint challengeID, uint reward);

    struct Listing {
        uint applicationExpiry;
        bool whitelisted;
        address owner;
        uint unstakedDeposit;
        uint challengeID;
    }

    struct Challenge {
        uint rewardPool;
        address challenger;
        bool resolved;
        uint stake;
        uint totalTokens;
        mapping(address => bool) tokenClaims;
    }


    mapping(uint => Challenge) public challenges;


    mapping(bytes32 => Listing) public listings;


    EIP20 public token;
    PLCRVoting public voting;
    Parameterizer public parameterizer;
    string public version = '1';











    function Registry(
        address _tokenAddr,
        address _plcrAddr,
        address _paramsAddr
    ) public {
        token = EIP20(_tokenAddr);
        voting = PLCRVoting(_plcrAddr);
        parameterizer = Parameterizer(_paramsAddr);
    }












    function apply(bytes32 _listingHash, uint _amount, string _data) external {
        require(!isWhitelisted(_listingHash));
        require(!appWasMade(_listingHash));
        require(_amount >= parameterizer.get("minDeposit"));


        Listing storage listing = listings[_listingHash];
        listing.owner = msg.sender;


        require(token.transferFrom(listing.owner, this, _amount));



        listing.applicationExpiry = block.timestamp + parameterizer.get("applyStageLen");
        listing.unstakedDeposit = _amount;

        _Application(_listingHash, _amount, _data);
    }






    function deposit(bytes32 _listingHash, uint _amount) external {
        Listing storage listing = listings[_listingHash];

        require(listing.owner == msg.sender);
        require(token.transferFrom(msg.sender, this, _amount));

        listing.unstakedDeposit += _amount;

        _Deposit(_listingHash, _amount, listing.unstakedDeposit);
    }






    function withdraw(bytes32 _listingHash, uint _amount) external {
        Listing storage listing = listings[_listingHash];

        require(listing.owner == msg.sender);
        require(_amount <= listing.unstakedDeposit);
        require(listing.unstakedDeposit - _amount >= parameterizer.get("minDeposit"));

        require(token.transfer(msg.sender, _amount));

        listing.unstakedDeposit -= _amount;

        _Withdrawal(_listingHash, _amount, listing.unstakedDeposit);
    }






    function exit(bytes32 _listingHash) external {
        Listing storage listing = listings[_listingHash];

        require(msg.sender == listing.owner);
        require(isWhitelisted(_listingHash));


        require(listing.challengeID == 0 || challenges[listing.challengeID].resolved);


        resetListing(_listingHash);
    }












    function challenge(bytes32 _listingHash, string _data) external returns (uint challengeID) {
        Listing storage listing = listings[_listingHash];
        uint deposit = parameterizer.get("minDeposit");


        require(appWasMade(_listingHash) || listing.whitelisted);

        require(listing.challengeID == 0 || challenges[listing.challengeID].resolved);

        if (listing.unstakedDeposit < deposit) {

            resetListing(_listingHash);
            return 0;
        }


        require(token.transferFrom(msg.sender, this, deposit));


        uint pollID = voting.startPoll(
            parameterizer.get("voteQuorum"),
            parameterizer.get("commitStageLen"),
            parameterizer.get("revealStageLen")
        );

        challenges[pollID] = Challenge({
            challenger: msg.sender,
            rewardPool: ((100 - parameterizer.get("dispensationPct")) * deposit) / 100,
            stake: deposit,
            resolved: false,
            totalTokens: 0
        });


        listing.challengeID = pollID;


        listing.unstakedDeposit -= deposit;

        _Challenge(_listingHash, deposit, pollID, _data);
        return pollID;
    }






    function updateStatus(bytes32 _listingHash) public {
        if (canBeWhitelisted(_listingHash)) {
          whitelistApplication(_listingHash);
          _NewListingWhitelisted(_listingHash);
        } else if (challengeCanBeResolved(_listingHash)) {
          resolveChallenge(_listingHash);
        } else {
          revert();
        }
    }











    function claimReward(uint _challengeID, uint _salt) public {

        require(challenges[_challengeID].tokenClaims[msg.sender] == false);
        require(challenges[_challengeID].resolved == true);

        uint voterTokens = voting.getNumPassingTokens(msg.sender, _challengeID, _salt);
        uint reward = voterReward(msg.sender, _challengeID, _salt);



        challenges[_challengeID].totalTokens -= voterTokens;
        challenges[_challengeID].rewardPool -= reward;

        require(token.transfer(msg.sender, reward));


        challenges[_challengeID].tokenClaims[msg.sender] = true;

        _RewardClaimed(msg.sender, _challengeID, reward);
    }












    function voterReward(address _voter, uint _challengeID, uint _salt)
    public view returns (uint) {
        uint totalTokens = challenges[_challengeID].totalTokens;
        uint rewardPool = challenges[_challengeID].rewardPool;
        uint voterTokens = voting.getNumPassingTokens(_voter, _challengeID, _salt);
        return (voterTokens * rewardPool) / totalTokens;
    }





    function canBeWhitelisted(bytes32 _listingHash) view public returns (bool) {
        uint challengeID = listings[_listingHash].challengeID;





        if (
            appWasMade(_listingHash) &&
            listings[_listingHash].applicationExpiry < now &&
            !isWhitelisted(_listingHash) &&
            (challengeID == 0 || challenges[challengeID].resolved == true)
        ) { return true; }

        return false;
    }





    function isWhitelisted(bytes32 _listingHash) view public returns (bool whitelisted) {
        return listings[_listingHash].whitelisted;
    }





    function appWasMade(bytes32 _listingHash) view public returns (bool exists) {
        return listings[_listingHash].applicationExpiry > 0;
    }





    function challengeExists(bytes32 _listingHash) view public returns (bool) {
        uint challengeID = listings[_listingHash].challengeID;

        return (listings[_listingHash].challengeID > 0 && !challenges[challengeID].resolved);
    }






    function challengeCanBeResolved(bytes32 _listingHash) view public returns (bool) {
        uint challengeID = listings[_listingHash].challengeID;

        require(challengeExists(_listingHash));

        return voting.pollEnded(challengeID);
    }





    function determineReward(uint _challengeID) public view returns (uint) {
        require(!challenges[_challengeID].resolved && voting.pollEnded(_challengeID));


        if (voting.getTotalNumberOfTokensForWinningOption(_challengeID) == 0) {
            return 2 * challenges[_challengeID].stake;
        }

        return (2 * challenges[_challengeID].stake) - challenges[_challengeID].rewardPool;
    }






    function tokenClaims(uint _challengeID, address _voter) public view returns (bool) {
      return challenges[_challengeID].tokenClaims[_voter];
    }










    function resolveChallenge(bytes32 _listingHash) private {
        uint challengeID = listings[_listingHash].challengeID;



        uint reward = determineReward(challengeID);


        bool wasWhitelisted = isWhitelisted(_listingHash);


        if (voting.isPassed(challengeID)) {
            whitelistApplication(_listingHash);

            listings[_listingHash].unstakedDeposit += reward;

            _ChallengeFailed(challengeID);
            if (!wasWhitelisted) { _NewListingWhitelisted(_listingHash); }
        }

        else {
            resetListing(_listingHash);

            require(token.transfer(challenges[challengeID].challenger, reward));

            _ChallengeSucceeded(challengeID);
            if (wasWhitelisted) { _ListingRemoved(_listingHash); }
            else { _ApplicationRemoved(_listingHash); }
        }


        challenges[challengeID].resolved = true;


        challenges[challengeID].totalTokens =
            voting.getTotalNumberOfTokensForWinningOption(challengeID);
    }







    function whitelistApplication(bytes32 _listingHash) private {
        listings[_listingHash].whitelisted = true;
    }





    function resetListing(bytes32 _listingHash) private {
        Listing storage listing = listings[_listingHash];


        if (listing.unstakedDeposit > 0)
            require(token.transfer(listing.owner, listing.unstakedDeposit));

        delete listings[_listingHash];
    }
}
