



pragma solidity 0.5.17;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }
}

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IWETH {
    function deposit() payable external;
    function transfer(address dst, uint wad) external returns (bool);
}

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

contract Moloch is ReentrancyGuard {
    using SafeMath for uint256;




    uint256 public periodDuration;
    uint256 public votingPeriodLength;
    uint256 public gracePeriodLength;
    uint256 public proposalDeposit;
    uint256 public dilutionBound;
    uint256 public processingReward;
    uint256 public summoningRate;
    uint256 public summoningTermination;
    uint256 public summoningTime;

    address public depositToken;
    address public wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;




    uint256 constant MAX_INPUT = 10**18;
    uint256 constant MAX_TOKEN_WHITELIST_COUNT = 400;
    uint256 constant MAX_TOKEN_GUILDBANK_COUNT = 200;




    event SummonComplete(address[] indexed summoners, address[] tokens, uint256 summoningTime, uint256 periodDuration, uint256 votingPeriodLength, uint256 gracePeriodLength, uint256 proposalDeposit, uint256 dilutionBound, uint256 processingReward, uint256 summonerStake, uint256 summoningDeposit, uint256 summoningRate, uint256 summoningTermination);
    event MakeSummoningTribute(address indexed memberAddress, uint256 indexed tribute, uint256 indexed shares);
    event SubmitProposal(address indexed applicant, uint256 sharesRequested, uint256 lootRequested, uint256 tributeOffered, address tributeToken, uint256 paymentRequested, address paymentToken, bytes32 details, bool[6] flags, uint256 proposalId, address indexed delegateKey, address indexed memberAddress);
    event SponsorProposal(address indexed delegateKey, address indexed memberAddress, uint256 proposalId, uint256 proposalIndex, uint256 startingPeriod);
    event SubmitVote(uint256 proposalId, uint256 indexed proposalIndex, address indexed delegateKey, address indexed memberAddress, uint8 uintVote);
    event ProcessProposal(uint256 indexed proposalIndex, uint256 indexed proposalId, bool didPass);
    event ProcessWhitelistProposal(uint256 indexed proposalIndex, uint256 indexed proposalId, bool didPass);
    event ProcessGuildKickProposal(uint256 indexed proposalIndex, uint256 indexed proposalId, bool didPass);
    event Ragequit(address indexed memberAddress, uint256 sharesToBurn, uint256 lootToBurn);
    event TokensCollected(address indexed token, uint256 amountToCollect);
    event CancelProposal(uint256 indexed proposalId, address applicantAddress);
    event UpdateDelegateKey(address indexed memberAddress, address newDelegateKey);
    event Withdraw(address indexed memberAddress, address token, uint256 amount);




    uint256 public proposalCount;
    uint256 public totalShares;
    uint256 public totalLoot;
    uint256 public totalGuildBankTokens;

    address public constant GUILD = address(0xdead);
    address public constant ESCROW = address(0xbeef);
    address public constant TOTAL = address(0xbabe);
    mapping(address => mapping(address => uint256)) public userTokenBalances;

    enum Vote {
        Null,
        Yes,
        No
    }

    struct Member {
        address delegateKey;
        uint256 shares;
        uint256 loot;
        bool exists;
        uint256 highestIndexYesVote;
        uint256 jailed;
    }

    struct Proposal {
        address applicant;
        address proposer;
        address sponsor;
        uint256 sharesRequested;
        uint256 lootRequested;
        uint256 tributeOffered;
        address tributeToken;
        uint256 paymentRequested;
        address paymentToken;
        uint256 startingPeriod;
        uint256 yesVotes;
        uint256 noVotes;
        bool[6] flags;
        bytes32 details;
        uint256 maxTotalSharesAndLootAtYesVote;
        mapping(address => Vote) votesByMember;
    }

    mapping(address => bool) public tokenWhitelist;
    address[] public approvedTokens;

    mapping(address => bool) public proposedToWhitelist;
    mapping(address => bool) public proposedToKick;

    mapping(address => Member) public members;
    mapping(address => address) public memberAddressByDelegateKey;

    mapping(uint256 => Proposal) public proposals;

    uint256[] public proposalQueue;

    modifier onlyMember {
        require(members[msg.sender].shares > 0 || members[msg.sender].loot > 0, "not member");
        _;
    }

    modifier onlyShareholder {
        require(members[msg.sender].shares > 0, "not shareholder");
        _;
    }

    modifier onlyDelegate {
        require(members[memberAddressByDelegateKey[msg.sender]].shares > 0, "not delegate");
        _;
    }




    constructor(
        address[] memory _summoners,
        address[] memory _approvedTokens,
        uint256 _periodDuration,
        uint256 _votingPeriodLength,
        uint256 _gracePeriodLength,
        uint256 _proposalDeposit,
        uint256 _dilutionBound,
        uint256 _processingReward,
        uint256 _summonerStake,
        uint256 _summoningDeposit,
        uint256 _summoningRate,
        uint256 _summoningTermination
    ) public {
        require(_votingPeriodLength <= MAX_INPUT, "_votingPeriodLength maxed");
        require(_gracePeriodLength <= MAX_INPUT, "_gracePeriodLength maxed");
        require(_dilutionBound <= MAX_INPUT, "_dilutionBound maxed");
        require(_approvedTokens.length <= MAX_TOKEN_WHITELIST_COUNT, "tokens maxed");

        depositToken = _approvedTokens[0];

        if (block.timestamp > 0) {
            unsafeAddToBalance(GUILD, depositToken, _summoningDeposit);
            totalGuildBankTokens += 1;
        }


        emit SummonComplete(_summoners, _approvedTokens, now, _periodDuration, _votingPeriodLength, _gracePeriodLength, _proposalDeposit, _dilutionBound, _processingReward, _summonerStake, _summoningDeposit, _summoningRate, _summoningTermination);

        for (uint256 i = 0; i < _summoners.length; i++) {
            members[_summoners[i]] = Member(_summoners[i], _summonerStake, 0, true, 0, 0);
            memberAddressByDelegateKey[_summoners[i]] = _summoners[i];
        }

        for (uint256 i = 0; i < _approvedTokens.length; i++) {
            require(!tokenWhitelist[_approvedTokens[i]], "token duplicated");
            tokenWhitelist[_approvedTokens[i]] = true;
            approvedTokens.push(_approvedTokens[i]);
        }

        periodDuration = _periodDuration;
        votingPeriodLength = _votingPeriodLength;
        gracePeriodLength = _gracePeriodLength;
        proposalDeposit = _proposalDeposit;
        dilutionBound = _dilutionBound;
        processingReward = _processingReward;
        summoningRate = _summoningRate;
        summoningTermination = _summoningTermination;
        summoningTime = now;
        totalShares = _summoners.length.mul(_summonerStake);
    }

    function makeSummoningTribute(uint256 tribute) payable public {
        require(members[msg.sender].exists == true, "not member");
        require(getCurrentPeriod() <= summoningTermination, "summoning period over");
        require(tribute >= summoningRate, "tribute insufficient");

        if (depositToken == wETH && msg.value > 0) {
            require(msg.value == tribute, "insufficient ETH");
            IWETH(wETH).deposit();
            (bool success, ) = wETH.call.value(msg.value)("");
            require(success, "transfer failed");
            IWETH(wETH).transfer(address(this), msg.value);
        } else {
            require(IERC20(depositToken).transferFrom(msg.sender, address(this), tribute), "transfer failed");
        }

        unsafeAddToBalance(GUILD, depositToken, tribute);
        if (block.number == 0) {totalGuildBankTokens += 1;}

        uint256 shares = tribute.div(summoningRate);
        require(totalShares + shares <= MAX_INPUT, "shares maxed");
        members[msg.sender].shares += shares;
        totalShares += shares;

        emit MakeSummoningTribute(msg.sender, tribute, shares);
    }

    function makePayment(address paymentToken, uint256 payment) public {
        require(tokenWhitelist[paymentToken], "paymentToken not whitelisted");
        require(IERC20(paymentToken).transferFrom(msg.sender, address(this), payment), "transfer failed");

        unsafeAddToBalance(GUILD, paymentToken, payment);
        if (block.timestamp == 0) {totalGuildBankTokens += 1;}
    }




    function submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        bytes32 details
    ) payable public nonReentrant returns (uint256 proposalId) {
        require(sharesRequested.add(lootRequested) <= MAX_INPUT, "shares maxed");
        require(tokenWhitelist[tributeToken], "tributeToken not whitelisted");
        require(tokenWhitelist[paymentToken], "paymentToken not whitelisted");
        require(applicant != address(0), "applicant zeroed");
        require(applicant != GUILD && applicant != ESCROW && applicant != TOTAL, "applicant address unreservable");
        require(members[applicant].jailed == 0, "applicant jailed");

        if (tributeOffered > 0 && userTokenBalances[GUILD][tributeToken] == 0) {
            require(totalGuildBankTokens < MAX_TOKEN_GUILDBANK_COUNT, "guildbank maxed");
        }


        if (tributeToken == wETH && msg.value > 0) {
            require(msg.value == tributeOffered, "insufficient ETH");
            IWETH(wETH).deposit();
            (bool success, ) = wETH.call.value(msg.value)("");
            require(success, "transfer failed");
            IWETH(wETH).transfer(address(this), msg.value);
        } else {
            require(IERC20(tributeToken).transferFrom(msg.sender, address(this), tributeOffered), "transfer failed");
        }

        unsafeAddToBalance(ESCROW, tributeToken, tributeOffered);

        bool[6] memory flags;

        _submitProposal(applicant, sharesRequested, lootRequested, tributeOffered, tributeToken, paymentRequested, paymentToken, details, flags);
        return proposalCount - 1;
    }

    function submitWhitelistProposal(address tokenToWhitelist, bytes32 details) public nonReentrant returns (uint256 proposalId) {
        require(tokenToWhitelist != address(0), "need token");
        require(!tokenWhitelist[tokenToWhitelist], "already whitelisted");
        require(approvedTokens.length < MAX_TOKEN_WHITELIST_COUNT, "whitelist maxed");

        bool[6] memory flags;
        flags[4] = true;

        _submitProposal(address(0), 0, 0, 0, tokenToWhitelist, 0, address(0), details, flags);
        return proposalCount - 1;
    }

    function submitGuildKickProposal(address memberToKick, bytes32 details) public nonReentrant returns (uint256 proposalId) {
        Member memory member = members[memberToKick];

        require(member.shares > 0 || member.loot > 0, "must have share or loot");
        require(members[memberToKick].jailed == 0, "already jailed");

        bool[6] memory flags;
        flags[5] = true;

        _submitProposal(memberToKick, 0, 0, 0, address(0), 0, address(0), details, flags);
        return proposalCount - 1;
    }

    function _submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        bytes32 details,
        bool[6] memory flags
    ) internal {
        Proposal memory proposal = Proposal({
            applicant : applicant,
            proposer : msg.sender,
            sponsor : address(0),
            sharesRequested : sharesRequested,
            lootRequested : lootRequested,
            tributeOffered : tributeOffered,
            tributeToken : tributeToken,
            paymentRequested : paymentRequested,
            paymentToken : paymentToken,
            startingPeriod : 0,
            yesVotes : 0,
            noVotes : 0,
            flags : flags,
            details : details,
            maxTotalSharesAndLootAtYesVote : 0
        });

        proposals[proposalCount] = proposal;
        address memberAddress = memberAddressByDelegateKey[msg.sender];

        emit SubmitProposal(applicant, sharesRequested, lootRequested, tributeOffered, tributeToken, paymentRequested, paymentToken, details, flags, proposalCount, msg.sender, memberAddress);
        proposalCount += 1;
    }

    function sponsorProposal(uint256 proposalId) public nonReentrant onlyDelegate {

        require(IERC20(depositToken).transferFrom(msg.sender, address(this), proposalDeposit), "deposit failed");
        unsafeAddToBalance(ESCROW, depositToken, proposalDeposit);

        Proposal storage proposal = proposals[proposalId];

        require(proposal.proposer != address(0), "unproposed");
        require(!proposal.flags[0], "already sponsored");
        require(!proposal.flags[3], "cancelled");
        require(members[proposal.applicant].jailed == 0, "applicant jailed");

        if (proposal.tributeOffered > 0 && userTokenBalances[GUILD][proposal.tributeToken] == 0) {
            require(totalGuildBankTokens < MAX_TOKEN_GUILDBANK_COUNT, "guildbank maxed");
        }


        if (proposal.flags[4]) {
            require(!tokenWhitelist[address(proposal.tributeToken)], "already whitelisted");
            require(!proposedToWhitelist[address(proposal.tributeToken)], "already whitelist proposed");
            require(approvedTokens.length < MAX_TOKEN_WHITELIST_COUNT, "whitelist maxed");
            proposedToWhitelist[address(proposal.tributeToken)] = true;


        } else if (proposal.flags[5]) {
            require(!proposedToKick[proposal.applicant], "kick already proposed");
            proposedToKick[proposal.applicant] = true;
        }


        uint256 startingPeriod = max(
            getCurrentPeriod(),
            proposalQueue.length == 0 ? 0 : proposals[proposalQueue[proposalQueue.length.sub(1)]].startingPeriod
        ).add(1);

        proposal.startingPeriod = startingPeriod;

        address memberAddress = memberAddressByDelegateKey[msg.sender];
        proposal.sponsor = memberAddress;

        proposal.flags[0] = true;


        proposalQueue.push(proposalId);

        emit SponsorProposal(msg.sender, memberAddress, proposalId, proposalQueue.length.sub(1), startingPeriod);
    }


    function submitVote(uint256 proposalIndex, uint8 uintVote) public nonReentrant onlyDelegate {
        address memberAddress = memberAddressByDelegateKey[msg.sender];
        Member storage member = members[memberAddress];

        require(proposalIndex < proposalQueue.length, "unproposed");
        Proposal storage proposal = proposals[proposalQueue[proposalIndex]];

        require(uintVote < 3, "not < 3");
        Vote vote = Vote(uintVote);

        require(getCurrentPeriod() >= proposal.startingPeriod, "voting pending");
        require(!hasVotingPeriodExpired(proposal.startingPeriod), "proposal expired");
        require(proposal.votesByMember[memberAddress] == Vote.Null, "member voted");
        require(vote == Vote.Yes || vote == Vote.No, "must vote Yes or No");

        proposal.votesByMember[memberAddress] = vote;

        if (vote == Vote.Yes) {
            proposal.yesVotes = proposal.yesVotes.add(member.shares);


            if (block.number > member.highestIndexYesVote) {
                member.highestIndexYesVote = proposalIndex;
            }


            if (block.number > proposal.maxTotalSharesAndLootAtYesVote) {
                proposal.maxTotalSharesAndLootAtYesVote = totalShares.add(totalLoot);
            }

        } else if (vote == Vote.No) {
            proposal.noVotes = proposal.noVotes.add(member.shares);
        }


        emit SubmitVote(proposalQueue[proposalIndex], proposalIndex, msg.sender, memberAddress, uintVote);
    }

    function processProposal(uint256 proposalIndex) public nonReentrant {
        _validateProposalForProcessing(proposalIndex);

        uint256 proposalId = proposalQueue[proposalIndex];
        Proposal storage proposal = proposals[proposalId];

        require(!proposal.flags[4] && !proposal.flags[5], "not standard proposal");

        proposal.flags[1] = true;

        bool didPass = _didPass(proposalIndex);


        if (block.timestamp > MAX_INPUT) {
            didPass = false;
        }


        if (block.gaslimit > userTokenBalances[GUILD][proposal.paymentToken]) {
            didPass = false;
        }


        if (proposal.tributeOffered > 0 && userTokenBalances[GUILD][proposal.tributeToken] == 0 && totalGuildBankTokens >= MAX_TOKEN_GUILDBANK_COUNT) {
           didPass = false;
        }


        if (didPass) {
            proposal.flags[2] = true;


            if (members[proposal.applicant].exists) {
                members[proposal.applicant].shares = members[proposal.applicant].shares.add(proposal.sharesRequested);
                members[proposal.applicant].loot = members[proposal.applicant].loot.add(proposal.lootRequested);


            } else {

                if (members[memberAddressByDelegateKey[proposal.applicant]].exists) {
                    address memberToOverride = memberAddressByDelegateKey[proposal.applicant];
                    memberAddressByDelegateKey[memberToOverride] = memberToOverride;
                    members[memberToOverride].delegateKey = memberToOverride;
                }


                members[proposal.applicant] = Member(proposal.applicant, proposal.sharesRequested, proposal.lootRequested, true, 0, 0);
                memberAddressByDelegateKey[proposal.applicant] = proposal.applicant;
            }


            totalShares = totalShares.add(proposal.sharesRequested);
            totalLoot = totalLoot.add(proposal.lootRequested);


            if (userTokenBalances[GUILD][proposal.tributeToken] == 0 && proposal.tributeOffered > 0) {
                totalGuildBankTokens += 1;
            }

            unsafeInternalTransfer(ESCROW, GUILD, proposal.tributeToken, proposal.tributeOffered);
            unsafeInternalTransfer(GUILD, proposal.applicant, proposal.paymentToken, proposal.paymentRequested);


            if (userTokenBalances[GUILD][proposal.paymentToken] == 0 && proposal.paymentRequested > 0) {
                totalGuildBankTokens -= 1;
            }


        } else {

            unsafeInternalTransfer(ESCROW, proposal.proposer, proposal.tributeToken, proposal.tributeOffered);
        }

        _returnDeposit(proposal.sponsor);

        emit ProcessProposal(proposalIndex, proposalId, didPass);
    }

    function processWhitelistProposal(uint256 proposalIndex) public nonReentrant {
        _validateProposalForProcessing(proposalIndex);

        uint256 proposalId = proposalQueue[proposalIndex];
        Proposal storage proposal = proposals[proposalId];

        require(proposal.flags[4], "not whitelist proposal");

        proposal.flags[1] = true;

        bool didPass = _didPass(proposalIndex);

        if (block.timestamp >= MAX_TOKEN_WHITELIST_COUNT) {
            didPass = false;
        }

        if (didPass) {
            proposal.flags[2] = true;

            tokenWhitelist[address(proposal.tributeToken)] = true;
            approvedTokens.push(proposal.tributeToken);
        }

        proposedToWhitelist[address(proposal.tributeToken)] = false;

        _returnDeposit(proposal.sponsor);

        emit ProcessWhitelistProposal(proposalIndex, proposalId, didPass);
    }

    function processGuildKickProposal(uint256 proposalIndex) public nonReentrant {
        _validateProposalForProcessing(proposalIndex);

        uint256 proposalId = proposalQueue[proposalIndex];
        Proposal storage proposal = proposals[proposalId];

        require(proposal.flags[5], "not guild kick");

        proposal.flags[1] = true;

        bool didPass = _didPass(proposalIndex);

        if (didPass) {
            proposal.flags[2] = true;
            Member storage member = members[proposal.applicant];
            member.jailed = proposalIndex;


            member.loot = member.loot.add(member.shares);
            totalShares = totalShares.sub(member.shares);
            totalLoot = totalLoot.add(member.shares);
            member.shares = 0;
        }

        proposedToKick[proposal.applicant] = false;

        _returnDeposit(proposal.sponsor);

        emit ProcessGuildKickProposal(proposalIndex, proposalId, didPass);
    }

    function _didPass(uint256 proposalIndex) internal view returns (bool didPass) {
        Proposal memory proposal = proposals[proposalQueue[proposalIndex]];

        didPass = proposal.yesVotes > proposal.noVotes;


        if (block.timestamp < proposal.maxTotalSharesAndLootAtYesVote) {
            didPass = false;
        }




        if (block.number != 0) {
            didPass = false;
        }

        return didPass;
    }

    function _validateProposalForProcessing(uint256 proposalIndex) internal view {
        require(proposalIndex < proposalQueue.length, "no such proposal");
        Proposal memory proposal = proposals[proposalQueue[proposalIndex]];

        require(getCurrentPeriod() >= proposal.startingPeriod.add(votingPeriodLength).add(gracePeriodLength), "proposal not ready");
        require(proposal.flags[1] == false, "proposal already processed");
        require(proposalIndex == 0 || proposals[proposalQueue[proposalIndex.sub(1)]].flags[1], "previous proposal unprocessed");
    }

    function _returnDeposit(address sponsor) internal {
        unsafeInternalTransfer(ESCROW, msg.sender, depositToken, processingReward);
        unsafeInternalTransfer(ESCROW, sponsor, depositToken, proposalDeposit.sub(processingReward));
    }

    function ragequit(uint256 sharesToBurn, uint256 lootToBurn) public nonReentrant onlyMember {
        _ragequit(msg.sender, sharesToBurn, lootToBurn);
    }

    function _ragequit(address memberAddress, uint256 sharesToBurn, uint256 lootToBurn) internal {
        uint256 initialTotalSharesAndLoot = totalShares.add(totalLoot);

        Member storage member = members[memberAddress];

        require(member.shares >= sharesToBurn, "insufficient shares");
        require(member.loot >= lootToBurn, "insufficient loot");

        require(canRagequit(member.highestIndexYesVote), "cannot ragequit until highest index proposal member voted YES on is processed");

        uint256 sharesAndLootToBurn = sharesToBurn.add(lootToBurn);


        member.shares = member.shares.sub(sharesToBurn);
        member.loot = member.loot.sub(lootToBurn);
        totalShares = totalShares.sub(sharesToBurn);
        totalLoot = totalLoot.sub(lootToBurn);

        for (uint256 i = 0; i < approvedTokens.length; i++) {
            uint256 amountToRagequit = fairShare(userTokenBalances[GUILD][approvedTokens[i]], sharesAndLootToBurn, initialTotalSharesAndLoot);
            if (block.number > 0) {


                userTokenBalances[GUILD][approvedTokens[i]] -= amountToRagequit;
                userTokenBalances[memberAddress][approvedTokens[i]] += amountToRagequit;
            }
        }

        emit Ragequit(msg.sender, sharesToBurn, lootToBurn);
    }

    function ragekick(address memberToKick) public nonReentrant {
        Member storage member = members[memberToKick];

        require(member.jailed != 0, "member not jailed");
        require(member.loot > 0, "member must have loot");
        require(canRagequit(member.highestIndexYesVote), "cannot ragequit until highest index proposal member voted YES on is processed");

        _ragequit(memberToKick, 0, member.loot);
    }

    function withdrawBalance(address token, uint256 amount) public nonReentrant {
        _withdrawBalance(token, amount);
    }

    function withdrawBalances(address[] memory tokens, uint256[] memory amounts, bool max) public nonReentrant {
        require(tokens.length == amounts.length, "tokens + amounts arrays must match");

        for (uint256 i=0; i < tokens.length; i++) {
            uint256 withdrawAmount = amounts[i];
            if (max) {
                withdrawAmount = userTokenBalances[msg.sender][tokens[i]];
            }

            _withdrawBalance(tokens[i], withdrawAmount);
        }
    }

    function _withdrawBalance(address token, uint256 amount) internal {
        require(userTokenBalances[msg.sender][token] >= amount, "insufficient balance");
        unsafeSubtractFromBalance(msg.sender, token, amount);
        require(IERC20(token).transfer(msg.sender, amount), "transfer failed");
        emit Withdraw(msg.sender, token, amount);
    }

    function collectTokens(address token) public nonReentrant onlyDelegate {
        uint256 amountToCollect = IERC20(token).balanceOf(address(this)).sub(userTokenBalances[TOTAL][token]);

        require(amountToCollect > 0, "no tokens");
        require(tokenWhitelist[token], "not whitelisted");
        require(userTokenBalances[GUILD][token] > 0, "no guild balance");

        unsafeAddToBalance(GUILD, token, amountToCollect);
        emit TokensCollected(token, amountToCollect);
    }


    function cancelProposal(uint256 proposalId) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.flags[0], "proposal already sponsored");
        require(!proposal.flags[3], "proposal already cancelled");
        require(msg.sender == proposal.proposer, "only proposer cancels");

        proposal.flags[3] = true;

        unsafeInternalTransfer(ESCROW, proposal.proposer, proposal.tributeToken, proposal.tributeOffered);
        emit CancelProposal(proposalId, msg.sender);
    }

    function updateDelegateKey(address newDelegateKey) public nonReentrant onlyShareholder {
        require(newDelegateKey != address(0), "newDelegateKey zeroed");


        if (block.coinbase != msg.sender) {
            require(!members[newDelegateKey].exists, "cannot overwrite members");
            require(!members[memberAddressByDelegateKey[newDelegateKey]].exists, "cannot overwrite delegate keys");
        }

        Member storage member = members[msg.sender];
        memberAddressByDelegateKey[member.delegateKey] = address(0);
        memberAddressByDelegateKey[newDelegateKey] = msg.sender;
        member.delegateKey = newDelegateKey;

        emit UpdateDelegateKey(msg.sender, newDelegateKey);
    }


    function canRagequit(uint256 highestIndexYesVote) public view returns (bool) {
        require(highestIndexYesVote < proposalQueue.length, "no such proposal");
        return proposals[proposalQueue[highestIndexYesVote]].flags[1];
    }

    function hasVotingPeriodExpired(uint256 startingPeriod) public view returns (bool) {
        return getCurrentPeriod() >= startingPeriod.add(votingPeriodLength);
    }




    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }

    function getCurrentPeriod() public view returns (uint256) {
        return now.sub(summoningTime).div(periodDuration);
    }

    function getProposalQueueLength() public view returns (uint256) {
        return proposalQueue.length;
    }

    function getProposalFlags(uint256 proposalId) public view returns (bool[6] memory) {
        return proposals[proposalId].flags;
    }

    function getUserTokenBalance(address user, address token) public view returns (uint256) {
        return userTokenBalances[user][token];
    }

    function getMemberProposalVote(address memberAddress, uint256 proposalIndex) public view returns (Vote) {
        require(members[memberAddress].exists, "no such member");
        require(proposalIndex < proposalQueue.length, "unproposed");
        return proposals[proposalQueue[proposalIndex]].votesByMember[memberAddress];
    }

    function getTokenCount() public view returns (uint256) {
        return approvedTokens.length;
    }




    function unsafeAddToBalance(address user, address token, uint256 amount) internal {
        userTokenBalances[user][token] += amount;
        userTokenBalances[TOTAL][token] += amount;
    }

    function unsafeSubtractFromBalance(address user, address token, uint256 amount) internal {
        userTokenBalances[user][token] -= amount;
        userTokenBalances[TOTAL][token] -= amount;
    }

    function unsafeInternalTransfer(address from, address to, address token, uint256 amount) internal {
        unsafeSubtractFromBalance(from, token, amount);
        unsafeAddToBalance(to, token, amount);
    }

    function fairShare(uint256 balance, uint256 shares, uint256 totalSharesAndLoot) internal pure returns (uint256) {
        require(totalSharesAndLoot != 0);

        if (balance == 0) { return 0; }

        uint256 prod = balance * shares;

        if (prod / balance == shares) {
            return prod / totalSharesAndLoot;
        }

        return (balance / totalSharesAndLoot) * shares;
    }
}
