




pragma solidity 0.6.12;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returnData) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returnData.length > 0) {
            require(abi.decode(returnData, (bool)), "SafeERC20: erc20 operation did not succeed");
        }
    }
}

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

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract MSTX is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;




    address public depositToken;
    address public stakeToken;
    address public constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public proposalDeposit;
    uint256 public processingReward;
    uint256 public periodDuration;
    uint256 public votingPeriodLength;
    uint256 public gracePeriodLength;
    uint256 public dilutionBound;
    uint256 public summoningTime;
    bool private initialized;


    uint256 constant MAX_GUILD_BOUND = 10**36;
    uint256 constant MAX_TOKEN_WHITELIST_COUNT = 400;
    uint256 constant MAX_TOKEN_GUILDBANK_COUNT = 200;


    uint8 public constant decimals = 18;
    string public constant name = "MSTX";
    string public constant symbol = "MSTX";




    address public constant GUILD = address(0xdead);
    address public constant ESCROW = address(0xdeaf);
    address public constant TOTAL = address(0xdeed);
    uint256 public proposalCount;
    uint256 public totalShares;
    uint256 public totalLoot;
    uint256 public totalSupply;
    uint256 public totalGuildBankTokens;

    mapping(uint256 => bytes) public actions;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => mapping(address => uint256)) private userTokenBalances;

    address[] public approvedTokens;
    mapping(address => bool) public tokenWhitelist;

    uint256[] public proposalQueue;
    mapping(uint256 => Proposal) public proposals;

    mapping(address => bool) public proposedToWhitelist;
    mapping(address => bool) public proposedToKick;

    mapping(address => Member) public members;
    mapping(address => address) public memberAddressByDelegateKey;




    event SubmitProposal(address indexed applicant, uint256 sharesRequested, uint256 lootRequested, uint256 tributeOffered, address tributeToken, uint256 paymentRequested, address paymentToken, bytes32 details, uint8[9] flags, bytes data, uint256 proposalId, address indexed delegateKey, address indexed memberAddress);
    event CancelProposal(uint256 indexed proposalId, address applicantAddress);
    event SponsorProposal(address indexed delegateKey, address indexed memberAddress, uint256 proposalId, uint256 proposalIndex, uint256 startingPeriod);
    event SubmitVote(uint256 proposalId, uint256 indexed proposalIndex, address indexed delegateKey, address indexed memberAddress, uint8 uintVote);
    event ProcessProposal(uint256 indexed proposalIndex, uint256 indexed proposalId, bool didPass);
    event ProcessActionProposal(uint256 indexed proposalIndex, uint256 indexed proposalId, bool didPass);
    event ProcessGuildKickProposal(uint256 indexed proposalIndex, uint256 indexed proposalId, bool didPass);
    event ProcessWhitelistProposal(uint256 indexed proposalIndex, uint256 indexed proposalId, bool didPass);
    event ProcessWithdrawalProposal(uint256 indexed proposalIndex, uint256 indexed proposalId, bool didPass);
    event UpdateDelegateKey(address indexed memberAddress, address newDelegateKey);
    event Ragequit(address indexed memberAddress, uint256 sharesToBurn, uint256 lootToBurn);
    event TokensCollected(address indexed token, uint256 amountToCollect);
    event Withdraw(address indexed memberAddress, address token, uint256 amount);
    event ConvertSharesToLoot(address indexed memberAddress, uint256 amount);
    event StakeTokenForShares(address indexed memberAddress, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);

    enum Vote {
        Null,
        Yes,
        No
    }

    struct Member {
        address delegateKey;
        uint8 exists;
        uint256 shares;
        uint256 loot;
        uint256 highestIndexYesVote;
        uint256 jailed;
    }

    struct Proposal {
        address applicant;
        address proposer;
        address sponsor;
        address tributeToken;
        address paymentToken;
        uint8[9] flags;
        uint256 sharesRequested;
        uint256 lootRequested;
        uint256 paymentRequested;
        uint256 tributeOffered;
        uint256 startingPeriod;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 maxTotalSharesAndLootAtYesVote;
        bytes32 details;
        mapping(address => Vote) votesByMember;
    }

    modifier onlyDelegate {
        require(members[memberAddressByDelegateKey[msg.sender]].shares > 0, "!delegate");
        _;
    }

    function init(
        address _depositToken,
        address _stakeToken,
        address[] memory _summoner,
        uint256[] memory _summonerShares,
        uint256 _summonerDeposit,
        uint256 _proposalDeposit,
        uint256 _processingReward,
        uint256 _periodDuration,
        uint256 _votingPeriodLength,
        uint256 _gracePeriodLength,
        uint256 _dilutionBound
    ) external {
        require(!initialized, "initialized");
        require(_depositToken != _stakeToken, "depositToken = stakeToken");
        require(_summoner.length == _summonerShares.length, "summoner != summonerShares");
        require(_proposalDeposit >= _processingReward, "_processingReward > _proposalDeposit");

        for (uint256 i = 0; i < _summoner.length; i++) {
            growGuild(_summoner[i], _summonerShares[i], 0);
        }

        require(totalShares <= MAX_GUILD_BOUND, "guild maxed");
        tokenWhitelist[_depositToken] = true;
        approvedTokens.push(_depositToken);

        if (_summonerDeposit > 0) {
            totalGuildBankTokens += 1;
            unsafeAddToBalance(GUILD, _depositToken, _summonerDeposit);
        }

        depositToken = _depositToken;
        stakeToken = _stakeToken;
        proposalDeposit = _proposalDeposit;
        processingReward = _processingReward;
        periodDuration = _periodDuration;
        votingPeriodLength = _votingPeriodLength;
        gracePeriodLength = _gracePeriodLength;
        dilutionBound = _dilutionBound;
        summoningTime = now;
        initialized = true;
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
    ) external nonReentrant payable returns (uint256 proposalId) {
        require(sharesRequested.add(lootRequested) <= MAX_GUILD_BOUND, "guild maxed");
        require(tokenWhitelist[tributeToken], "tributeToken != whitelist");
        require(tokenWhitelist[paymentToken], "paymentToken != whitelist");
        require(applicant != GUILD && applicant != ESCROW && applicant != TOTAL, "applicant unreservable");
        require(address(this).balance == 0, "applicant jailed");

        if (tributeOffered > 0 && userTokenBalances[GUILD][tributeToken] == 0) {
            require(totalGuildBankTokens < MAX_TOKEN_GUILDBANK_COUNT, "guildbank maxed");
        }


        if (msg.value > 0) {
            require(tributeToken == wETH && msg.value == tributeOffered, "!ethBalance");
            (bool success, ) = wETH.call{value: msg.value}("");
            require(success, "!ethCall");
            IERC20(wETH).safeTransfer(address(this), msg.value);
        } else {
            IERC20(tributeToken).safeTransferFrom(msg.sender, address(this), tributeOffered);
        }

        unsafeAddToBalance(ESCROW, tributeToken, tributeOffered);

        uint8[9] memory flags;
        flags[8] = 1;

        _submitProposal(applicant, sharesRequested, lootRequested, tributeOffered, tributeToken, paymentRequested, paymentToken, details, flags, "");

        return proposalCount - 1;
    }

     function submitActionProposal(
        address actionTo,
        uint256 actionTokenAmount,
        uint256 actionValue,
        bytes32 details,
        bytes calldata data
    ) external returns (uint256 proposalId) {
        uint8[9] memory flags;
        flags[6] = 1;

        _submitProposal(actionTo, 0, 0, actionValue, address(0), actionTokenAmount, address(0), details, flags, data);

        return proposalCount - 1;
    }

    function submitGuildKickProposal(address memberToKick, bytes32 details) external returns (uint256 proposalId) {
        Member memory member = members[memberToKick];
        require(member.shares > 0 || member.loot > 0, "!share||loot");
        require(address(this).balance == 0, "jailed");
        uint8[9] memory flags;
        flags[5] = 1;

        _submitProposal(memberToKick, 0, 0, 0, address(0), 0, address(0), details, flags, "");

        return proposalCount - 1;
    }

    function submitWhitelistProposal(address tokenToWhitelist, bytes32 details) external returns (uint256 proposalId) {
        require(tokenToWhitelist != address(0), "!token");
        require(tokenToWhitelist != stakeToken, "tokenToWhitelist = stakeToken");
        require(!tokenWhitelist[tokenToWhitelist], "whitelisted");
        require(approvedTokens.length < MAX_TOKEN_WHITELIST_COUNT, "whitelist maxed");
        uint8[9] memory flags;
        flags[4] = 1;

        _submitProposal(address(0), 0, 0, 0, tokenToWhitelist, 0, address(0), details, flags, "");

        return proposalCount - 1;
    }

    function submitWithdrawalProposal(address withdrawalTo, bytes32 details) external returns (uint256 proposalId) {
        uint8[9] memory flags;
        flags[7] = 1;

        _submitProposal(withdrawalTo, 0, 0, 0, address(0), 0, address(0), details, flags, "");

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
        uint8[9] memory flags,
        bytes memory data
    ) internal {
        Proposal memory proposal = Proposal({
            applicant : applicant,
            proposer : msg.sender,
            sponsor : address(0),
            tributeToken : tributeToken,
            paymentToken : paymentToken,
            flags : flags,
            sharesRequested : sharesRequested,
            lootRequested : lootRequested,
            paymentRequested : paymentRequested,
            tributeOffered : tributeOffered,
            startingPeriod : 0,
            yesVotes : 0,
            noVotes : 0,
            maxTotalSharesAndLootAtYesVote : 0,
            details : details
        });

        if (proposal.flags[6] == 1) {
            actions[proposalCount] = data;
        }

        proposals[proposalCount] = proposal;

        emit SubmitProposal(applicant, sharesRequested, lootRequested, tributeOffered, tributeToken, paymentRequested, paymentToken, details, flags, data, proposalCount, msg.sender, memberAddressByDelegateKey[msg.sender]);

        proposalCount += 1;
    }

    function sponsorProposal(uint256 proposalId) external nonReentrant onlyDelegate {

        IERC20(depositToken).safeTransferFrom(msg.sender, address(this), proposalDeposit);
        unsafeAddToBalance(ESCROW, depositToken, proposalDeposit);
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "!proposed");
        require(proposal.flags[0] == 0, "sponsored");
        require(proposal.flags[3] == 0, "cancelled");
        require(address(this).balance == 0, "applicant jailed");

        if (proposal.tributeOffered > 0 && userTokenBalances[GUILD][proposal.tributeToken] == 0) {
            require(totalGuildBankTokens < MAX_TOKEN_GUILDBANK_COUNT, "guildbank maxed");
        }


        if (proposal.flags[4] == 1) {
            require(!tokenWhitelist[address(proposal.tributeToken)], "whitelisted");
            require(!proposedToWhitelist[address(proposal.tributeToken)], "whitelist proposed");
            require(approvedTokens.length < MAX_TOKEN_WHITELIST_COUNT, "whitelist maxed");
            proposedToWhitelist[address(proposal.tributeToken)] = true;


        } else if (proposal.flags[5] == 1) {
            require(!proposedToKick[proposal.applicant], "kick proposed");
            proposedToKick[proposal.applicant] = true;
        }


        uint256 startingPeriod = max(
            getCurrentPeriod(),
            proposalQueue.length == 0 ? 0 : proposals[proposalQueue[proposalQueue.length - 1]].startingPeriod
        ) + 1;

        proposal.startingPeriod = startingPeriod;
        proposal.sponsor = memberAddressByDelegateKey[msg.sender];
        proposal.flags[0] = 1;

        proposalQueue.push(proposalId);

        emit SponsorProposal(msg.sender, proposal.sponsor, proposalId, proposalQueue.length - 1, startingPeriod);
    }


    function submitVote(uint256 proposalIndex, uint8 uintVote) external nonReentrant onlyDelegate {
        address memberAddress = memberAddressByDelegateKey[msg.sender];
        Member storage member = members[memberAddress];
        require(proposalIndex < proposalQueue.length, "!proposed");
        uint256 proposalId = proposalQueue[proposalIndex];
        Proposal storage proposal = proposals[proposalId];
        require(uintVote < 3, ">2");
        Vote vote = Vote(uintVote);
        require(getCurrentPeriod() >= proposal.startingPeriod, "pending");
        require(!hasVotingPeriodExpired(proposal.startingPeriod), "expired");
        require(proposal.votesByMember[memberAddress] == Vote.Null, "voted");
        require(vote == Vote.Yes || vote == Vote.No, "!Yes||No");
        proposal.votesByMember[memberAddress] = vote;

        if (vote == Vote.Yes) {
            proposal.yesVotes += member.shares;


            if (proposalIndex > member.highestIndexYesVote) {
                member.highestIndexYesVote = proposalIndex;
            }


            if (totalSupply > proposal.maxTotalSharesAndLootAtYesVote) {
                proposal.maxTotalSharesAndLootAtYesVote = totalSupply;
            }

        } else if (vote == Vote.No) {
            proposal.noVotes += member.shares;
        }


        emit SubmitVote(proposalId, proposalIndex, msg.sender, memberAddress, uintVote);
    }

    function processProposal(uint256 proposalIndex) external nonReentrant {
        _validateProposalForProcessing(proposalIndex);
        uint256 proposalId = proposalQueue[proposalIndex];
        Proposal storage proposal = proposals[proposalId];
        require(proposal.flags[8] == 1, "!standard");
        proposal.flags[1] = 1;

        bool didPass = _didPass(proposalIndex);

        if (totalSupply.add(proposal.sharesRequested).add(proposal.lootRequested) > MAX_GUILD_BOUND) {
            didPass = false;
        }


        if (proposal.paymentRequested > userTokenBalances[GUILD][proposal.paymentToken]) {
            didPass = false;
        }


        if (proposal.tributeOffered > 0 && userTokenBalances[GUILD][proposal.tributeToken] == 0 && totalGuildBankTokens >= MAX_TOKEN_GUILDBANK_COUNT) {
            didPass = false;
        }


        if (didPass) {
            proposal.flags[2] = 1;

            growGuild(proposal.applicant, proposal.sharesRequested, proposal.lootRequested);


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

     function processActionProposal(uint256 proposalIndex) external nonReentrant returns (bool, bytes memory) {
        _validateProposalForProcessing(proposalIndex);
        uint256 proposalId = proposalQueue[proposalIndex];
        bytes storage action = actions[proposalId];
        Proposal storage proposal = proposals[proposalId];
        require(proposal.flags[6] == 1, "!action");
        proposal.flags[1] = 1;

        bool didPass = _didPass(proposalIndex);

        if (tokenWhitelist[proposal.applicant] && proposal.paymentRequested > userTokenBalances[GUILD][proposal.applicant]) {
            didPass = false;
        }


        if (proposal.tributeOffered > address(this).balance) {
            didPass = false;
        }

        if (didPass) {
            proposal.flags[2] = 1;
            (bool success, bytes memory returnData) = proposal.applicant.call{value: proposal.tributeOffered}(action);
            if (tokenWhitelist[proposal.applicant]) {
                unsafeSubtractFromBalance(GUILD, proposal.applicant, proposal.paymentRequested);

                if (userTokenBalances[GUILD][proposal.applicant] == 0 && proposal.paymentRequested > 0) {totalGuildBankTokens -= 1;}
            }
            return (success, returnData);
        }

        _returnDeposit(proposal.sponsor);

        emit ProcessActionProposal(proposalIndex, proposalId, didPass);
    }

    function processGuildKickProposal(uint256 proposalIndex) external nonReentrant {
        _validateProposalForProcessing(proposalIndex);
        uint256 proposalId = proposalQueue[proposalIndex];
        Proposal storage proposal = proposals[proposalId];
        require(proposal.flags[5] == 1, "!kick");
        proposal.flags[1] = 1;

        bool didPass = _didPass(proposalIndex);
        if (didPass) {
            proposal.flags[2] = 1;
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

    function processWhitelistProposal(uint256 proposalIndex) external {
        _validateProposalForProcessing(proposalIndex);
        uint256 proposalId = proposalQueue[proposalIndex];
        Proposal storage proposal = proposals[proposalId];
        require(proposal.flags[4] == 1, "!whitelist");
        proposal.flags[1] = 1;

        bool didPass = _didPass(proposalIndex);
        if (approvedTokens.length >= MAX_TOKEN_WHITELIST_COUNT) {
            didPass = false;
        }

        if (didPass) {
            proposal.flags[2] = 1;
            tokenWhitelist[address(proposal.tributeToken)] = true;
            approvedTokens.push(proposal.tributeToken);
        }

        proposedToWhitelist[address(proposal.tributeToken)] = false;

        _returnDeposit(proposal.sponsor);

        emit ProcessWhitelistProposal(proposalIndex, proposalId, didPass);
    }

    function processWithdrawalProposal(uint256 proposalIndex) external nonReentrant {
        _validateProposalForProcessing(proposalIndex);
        uint256 proposalId = proposalQueue[proposalIndex];
        Proposal storage proposal = proposals[proposalId];
        require(proposal.flags[7] == 1, "!withdrawal");
        proposal.flags[1] = 1;

        bool didPass = _didPass(proposalIndex);
        if (didPass) {
            proposal.flags[2] = 1;
            for (uint256 i = 0; i < approvedTokens.length; i++) {


                uint256 withdrawalAmount = userTokenBalances[GUILD][approvedTokens[i]];
                userTokenBalances[GUILD][approvedTokens[i]] -= withdrawalAmount;
                userTokenBalances[proposal.applicant][approvedTokens[i]] += withdrawalAmount;
            }
            totalGuildBankTokens -= approvedTokens.length;
        }

        _returnDeposit(proposal.sponsor);

        emit ProcessWithdrawalProposal(proposalIndex, proposalId, didPass);
    }

    function _didPass(uint256 proposalIndex) internal view returns (bool didPass) {
        Proposal memory proposal = proposals[proposalQueue[proposalIndex]];

        if (proposal.yesVotes > proposal.noVotes) {
            didPass = true;
        }


        if ((totalSupply.mul(dilutionBound)) < proposal.maxTotalSharesAndLootAtYesVote) {
            didPass = false;
        }




        if (members[proposal.applicant].jailed != 0) {
            didPass = false;
        }

        return didPass;
    }

    function _validateProposalForProcessing(uint256 proposalIndex) internal view {
        require(proposalIndex < proposalQueue.length, "!proposal");
        Proposal memory proposal = proposals[proposalQueue[proposalIndex]];
        require(getCurrentPeriod() >= proposal.startingPeriod.add(votingPeriodLength).add(gracePeriodLength), "!ready");
        require(proposal.flags[1] == 0, "processed");
        require(proposalIndex == 0 || proposals[proposalQueue[proposalIndex - 1]].flags[1] == 1, "prior !processed");
    }

    function _returnDeposit(address sponsor) internal {
        unsafeInternalTransfer(ESCROW, msg.sender, depositToken, processingReward);
        unsafeInternalTransfer(ESCROW, sponsor, depositToken, proposalDeposit - processingReward);
    }

    function ragequit(uint256 sharesToBurn, uint256 lootToBurn) external nonReentrant {
        require(members[msg.sender].exists == 1, "!member");
        _ragequit(msg.sender, sharesToBurn, lootToBurn);
    }

    function _ragequit(address memberAddress, uint256 sharesToBurn, uint256 lootToBurn) internal {
        uint256 initialTotalSharesAndLoot = totalSupply;
        Member storage member = members[memberAddress];
        require(member.shares >= sharesToBurn, "!shares");
        require(member.loot >= lootToBurn, "!loot");
        require(canRagequit(member.highestIndexYesVote), "!ragequit until highest index proposal member voted YES processes");
        uint256 sharesAndLootToBurn = sharesToBurn.add(lootToBurn);


        balanceOf[memberAddress] = balanceOf[memberAddress].sub(sharesAndLootToBurn);
        member.shares = member.shares.sub(sharesToBurn);
        member.loot = member.loot.sub(lootToBurn);
        totalShares = totalShares.sub(sharesToBurn);
        totalLoot = totalLoot.sub(lootToBurn);
        totalSupply = totalShares.add(totalLoot);

        for (uint256 i = 0; i < approvedTokens.length; i++) {
            uint256 amountToRagequit = fairShare(userTokenBalances[GUILD][approvedTokens[i]], sharesAndLootToBurn, initialTotalSharesAndLoot);
            if (amountToRagequit > 0) {


                userTokenBalances[GUILD][approvedTokens[i]] -= amountToRagequit;
                userTokenBalances[memberAddress][approvedTokens[i]] += amountToRagequit;
            }
        }

        emit Ragequit(memberAddress, sharesToBurn, lootToBurn);
        emit Transfer(memberAddress, address(0), sharesAndLootToBurn);
    }

    function ragekick(address memberToKick) external nonReentrant onlyDelegate {
        Member storage member = members[memberToKick];
        require(member.jailed != 0, "!jailed");
        require(member.loot > 0, "!loot");
        require(canRagequit(member.highestIndexYesVote), "!ragequit until highest index proposal member voted YES processes");
        _ragequit(memberToKick, 0, member.loot);
    }

    function withdrawBalance(address token, uint256 amount) external nonReentrant {
        _withdrawBalance(token, amount);
    }

    function withdrawBalances(address[] calldata tokens, uint256[] calldata amounts, bool max) external nonReentrant {
        require(tokens.length == amounts.length, "tokens != amounts");
        for (uint256 i=0; i < tokens.length; i++) {
            uint256 withdrawAmount = amounts[i];
            if (max) {
                withdrawAmount = userTokenBalances[msg.sender][tokens[i]];
            }
            _withdrawBalance(tokens[i], withdrawAmount);
        }
    }

    function _withdrawBalance(address token, uint256 amount) internal {
        require(userTokenBalances[msg.sender][token] >= amount, "!balance");
        IERC20(token).safeTransfer(msg.sender, amount);
        unsafeSubtractFromBalance(msg.sender, token, amount);
        emit Withdraw(msg.sender, token, amount);
    }

    function collectTokens(address token) external nonReentrant onlyDelegate {
        uint256 amountToCollect = IERC20(token).balanceOf(address(this)).sub(userTokenBalances[TOTAL][token]);

        require(amountToCollect > 0, "!amount");
        require(tokenWhitelist[token], "!whitelisted");

        if (userTokenBalances[GUILD][token] == 0 && totalGuildBankTokens < MAX_TOKEN_GUILDBANK_COUNT) {totalGuildBankTokens += 1;}
        unsafeAddToBalance(GUILD, token, amountToCollect);

        emit TokensCollected(token, amountToCollect);
    }


    function cancelProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.flags[0] == 0, "sponsored");
        require(proposal.flags[3] == 0, "cancelled");
        require(msg.sender == proposal.proposer, "!proposer");
        proposal.flags[3] = 1;

        unsafeInternalTransfer(ESCROW, proposal.proposer, proposal.tributeToken, proposal.tributeOffered);

        emit CancelProposal(proposalId, msg.sender);
    }

    function updateDelegateKey(address newDelegateKey) external {
        require(members[msg.sender].shares > 0, "!shareholder");
        require(newDelegateKey != address(0), "newDelegateKey = 0");


        if (newDelegateKey != msg.sender) {
            require(members[newDelegateKey].exists == 0, "!overwrite members");
            require(members[memberAddressByDelegateKey[newDelegateKey]].exists == 0, "!overwrite keys");
        }

        Member storage member = members[msg.sender];
        memberAddressByDelegateKey[member.delegateKey] = address(0);
        memberAddressByDelegateKey[newDelegateKey] = msg.sender;
        member.delegateKey = newDelegateKey;

        emit UpdateDelegateKey(msg.sender, newDelegateKey);
    }


    function canRagequit(uint256 highestIndexYesVote) public view returns (bool) {
        require(highestIndexYesVote < proposalQueue.length, "!proposal");
        return proposals[proposalQueue[highestIndexYesVote]].flags[1] == 1;
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

    function getMemberProposalVote(address memberAddress, uint256 proposalIndex) external view returns (Vote) {
        require(members[memberAddress].exists == 1, "!member");
        require(proposalIndex < proposalQueue.length, "!proposed");
        return proposals[proposalQueue[proposalIndex]].votesByMember[memberAddress];
    }

    function getProposalFlags(uint256 proposalId) external view returns (uint8[9] memory) {
        return proposals[proposalId].flags;
    }

    function getProposalQueueLength() external view returns (uint256) {
        return proposalQueue.length;
    }

    function getTokenCount() external view returns (uint256) {
        return approvedTokens.length;
    }

    function getUserTokenBalance(address user, address token) external view returns (uint256) {
        return userTokenBalances[user][token];
    }




    receive() external payable {}

    function fairShare(uint256 balance, uint256 shares, uint256 totalSharesAndLoot) internal pure returns (uint256) {
        require(totalSharesAndLoot != 0);

        if (balance == 0) { return 0; }

        uint256 prod = balance * shares;

        if (prod / balance == shares) {
            return prod / totalSharesAndLoot;
        }

        return (balance / totalSharesAndLoot) * shares;
    }

    function growGuild(address account, uint256 shares, uint256 loot) internal {

        if (members[account].exists == 1) {
            members[account].shares = members[account].shares.add(shares);
            members[account].loot = members[account].loot.add(loot);


        } else {

            if (members[memberAddressByDelegateKey[account]].exists == 1) {
                address memberToOverride = memberAddressByDelegateKey[account];
                memberAddressByDelegateKey[memberToOverride] = memberToOverride;
                members[memberToOverride].delegateKey = memberToOverride;
            }

            members[account] = Member({
                delegateKey : account,
                exists : 1,
                shares : shares,
                loot : loot.add(members[account].loot),
                highestIndexYesVote : 0,
                jailed : 0
            });
            memberAddressByDelegateKey[account] = account;
        }

        uint256 sharesAndLoot = shares.add(loot);

        balanceOf[account] = balanceOf[account].add(sharesAndLoot);
        totalShares = totalShares.add(shares);
        totalLoot = totalLoot.add(loot);
        totalSupply = totalShares.add(totalLoot);

        emit Transfer(address(0), account, sharesAndLoot);
    }

    function unsafeAddToBalance(address user, address token, uint256 amount) internal {
        userTokenBalances[user][token] += amount;
        userTokenBalances[TOTAL][token] += amount;
    }

    function unsafeInternalTransfer(address from, address to, address token, uint256 amount) internal {
        unsafeSubtractFromBalance(from, token, amount);
        unsafeAddToBalance(to, token, amount);
    }

    function unsafeSubtractFromBalance(address user, address token, uint256 amount) internal {
        userTokenBalances[user][token] -= amount;
        userTokenBalances[TOTAL][token] -= amount;
    }




    function approve(address spender, uint256 amount) external returns (bool) {
        require(amount == 0 || allowance[msg.sender][spender] == 0);
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function convertSharesToLoot(uint256 sharesToLoot) external nonReentrant {
        members[msg.sender].shares = members[msg.sender].shares.sub(sharesToLoot);
        members[msg.sender].loot = members[msg.sender].loot.add(sharesToLoot);
        totalShares = totalShares.sub(sharesToLoot);
        totalLoot = totalLoot.add(sharesToLoot);
        emit ConvertSharesToLoot(msg.sender, sharesToLoot);
    }

    function stakeTokenForShares(uint256 amount) external nonReentrant {
        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), amount);
        growGuild(msg.sender, amount, 0);
        require(totalSupply <= MAX_GUILD_BOUND, "guild maxed");
        emit StakeTokenForShares(msg.sender, amount);
    }

    function transfer(address recipient, uint256 lootToTransfer) external returns (bool) {
        members[msg.sender].loot = members[msg.sender].loot.sub(lootToTransfer);
        members[recipient].loot = members[recipient].loot.add(lootToTransfer);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(lootToTransfer);
        balanceOf[recipient] = balanceOf[recipient].add(lootToTransfer);
        emit Transfer(msg.sender, recipient, lootToTransfer);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 lootToTransfer) external returns (bool) {
        allowance[sender][msg.sender] = allowance[sender][msg.sender].sub(lootToTransfer);
        members[sender].loot = members[sender].loot.sub(lootToTransfer);
        members[recipient].loot = members[recipient].loot.add(lootToTransfer);
        balanceOf[sender] = balanceOf[sender].sub(lootToTransfer);
        balanceOf[recipient] = balanceOf[recipient].add(lootToTransfer);
        emit Transfer(sender, recipient, lootToTransfer);
        return true;
    }
}





















contract CloneFactory {
    function createClone(address payable target) internal returns (address payable result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

contract MSTXSummoner is CloneFactory {
    address payable public immutable template;

    constructor(address payable _template) public {
        template = _template;
    }

    event SummonMSTX(address indexed mstx, address depositToken, address stakeToken, address[] summoner, uint256[] summonerShares, uint256 summoningDeposit, uint256 proposalDeposit, uint256 processingReward, uint256 periodDuration, uint256 votingPeriodLength, uint256 gracePeriodLength, uint256 dilutionBound, uint256 summoningTime);

    function summonMSTX(
        address _depositToken,
        address _stakeToken,
        address[] memory _summoner,
        uint256[] memory _summonerShares,
        uint256 _summonerDeposit,
        uint256 _proposalDeposit,
        uint256 _processingReward,
        uint256 _periodDuration,
        uint256 _votingPeriodLength,
        uint256 _gracePeriodLength,
        uint256 _dilutionBound
    ) external returns (address) {
        MSTX mstx = MSTX(createClone(template));

        mstx.init(
            _depositToken,
            _stakeToken,
            _summoner,
            _summonerShares,
            _summonerDeposit,
            _proposalDeposit,
            _processingReward,
            _periodDuration,
            _votingPeriodLength,
            _gracePeriodLength,
            _dilutionBound
        );

        require(IERC20(_depositToken).transferFrom(msg.sender, address(mstx), _summonerDeposit), "!transfer");

        emit SummonMSTX(address(mstx), _depositToken, _stakeToken, _summoner, _summonerShares, _summonerDeposit, _proposalDeposit, _processingReward, _periodDuration, _votingPeriodLength, _gracePeriodLength, _dilutionBound, now);

        return address(mstx);
    }
}
