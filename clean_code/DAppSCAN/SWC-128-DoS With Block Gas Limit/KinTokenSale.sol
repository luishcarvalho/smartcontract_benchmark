pragma solidity ^0.4.15;

import './SafeMath.sol';
import './Ownable.sol';
import './TokenHolder.sol';
import './KinToken.sol';
import './VestingTrustee.sol';


contract KinTokenSale is Ownable, TokenHolder {
    using SafeMath for uint256;




    KinToken public kin;


    VestingTrustee public trustee;


    address public fundingRecipient;




    uint256 public constant TOKEN_DECIMALS = 10 ** 18;


    uint256 public constant MAX_TOKENS = 10 ** 13 * TOKEN_DECIMALS;


    uint256 public constant MAX_TOKENS_SOLD = 512192121951 * TOKEN_DECIMALS;




    uint256 public constant WEI_PER_USD = uint256(1 ether) / 360;



    uint256 public constant KIN_PER_USD = 6829 * TOKEN_DECIMALS;


    uint256 public constant KIN_PER_WEI = KIN_PER_USD / WEI_PER_USD;


    uint256 public constant SALE_DURATION = 14 days;
    uint256 public startTime;
    uint256 public endTime;


    uint256 public tokensSold = 0;


    uint256 public constant TIER_1_CAP = 100000 * WEI_PER_USD;
    uint256 public constant TIER_2_CAP = uint256(-1);


    mapping (address => uint256) public participationHistory;


    mapping (address => uint256) public participationCaps;


    uint256 public hardParticipationCap = 5000 * WEI_PER_USD;


    struct TokenGrant {
        uint256 value;
        uint256 startOffset;
        uint256 cliffOffset;
        uint256 endOffset;
        uint256 installmentLength;
        uint8 percentVested;
    }

    address[] public tokenGrantees;
    mapping (address => TokenGrant) public tokenGrants;
    uint256 public lastGrantedIndex = 0;
    uint256 public constant GRANT_BATCH_SIZE = 10;




    address public constant KIN_FOUNDATION_ADDRESS = 0xa8F769B88d6D74FB2Bd3912F6793F75625228baF;
    address public constant KIK_ADDRESS = 0x7a029DC995f87B5cA060975b9A8A1b4bdB33cDC5;

    event TokensIssued(address indexed _to, uint256 _tokens);


    modifier onlyDuringSale() {
        if (tokensSold >= MAX_TOKENS_SOLD || now < startTime || now >= endTime) {
            revert();
        }

        _;
    }


    modifier onlyAfterSale() {
        if (!(tokensSold >= MAX_TOKENS_SOLD || now >= endTime)) {
            revert();
        }

        _;
    }




    function KinTokenSale(address _fundingRecipient, uint256 _startTime) {
        require(_fundingRecipient != address(0));
        require(_startTime > now);


        kin = new KinToken();


        trustee = new VestingTrustee(kin);

        fundingRecipient = _fundingRecipient;
        startTime = _startTime;
        endTime = startTime + SALE_DURATION;


        initTokenGrants();
    }




    function initTokenGrants() private onlyOwner {



        tokenGrantees.push(KIN_FOUNDATION_ADDRESS);
        tokenGrants[KIN_FOUNDATION_ADDRESS] = TokenGrant(60 * 100000000000 * TOKEN_DECIMALS, 0, 0, 3 years, 1 days, 0);


        tokenGrantees.push(KIK_ADDRESS);
        tokenGrants[KIK_ADDRESS] = TokenGrant(30 * 100000000000 * TOKEN_DECIMALS, 0, 0, 120 weeks, 12 weeks, 100);
    }




    function addTokenGrant(address _grantee, uint256 _value) external onlyOwner {
        require(_grantee != address(0));
        require(_value > 0);


        require(tokenGrants[_grantee].value == 0);
        for (uint i = 0; i < tokenGrantees.length; i++) {
            require(tokenGrantees[i] != _grantee);
        }


        tokenGrantees.push(_grantee);
        tokenGrants[_grantee] = TokenGrant(_value, 0, 1 years, 1 years, 1 days, 50);
    }



    function deleteTokenGrant(address _grantee) external onlyOwner {
        require(_grantee != address(0));


        for (uint i = 0; i < tokenGrantees.length; i++) {
            if (tokenGrantees[i] == _grantee) {
                delete tokenGrantees[i];

                break;
            }
        }


        delete tokenGrants[_grantee];
    }




    function setParticipationCap(address[] _participants, uint256 _cap) private onlyOwner {
        for (uint i = 0; i < _participants.length; i++) {
            participationCaps[_participants[i]] = _cap;
        }
    }



    function setTier1Participants(address[] _participants) external onlyOwner {
        setParticipationCap(_participants, TIER_1_CAP);
    }



    function setTier2Participants(address[] _participants) external onlyOwner {
        setParticipationCap(_participants, TIER_2_CAP);
    }



    function setHardParticipationCap(uint256 _cap) external onlyOwner {
        require(_cap > 0);

        hardParticipationCap = _cap;
    }


    function () external payable onlyDuringSale {
        create(msg.sender);
    }



    function create(address _recipient) public payable onlyDuringSale {
        require(_recipient != address(0));


        uint256 weiAlreadyParticipated = participationHistory[msg.sender];
        uint256 participationCap = SafeMath.min256(participationCaps[msg.sender], hardParticipationCap);
        uint256 cappedWeiReceived = SafeMath.min256(msg.value, participationCap.sub(weiAlreadyParticipated));
        require(cappedWeiReceived > 0);


        uint256 weiLeftInSale = MAX_TOKENS_SOLD.sub(tokensSold).div(KIN_PER_WEI);
        uint256 weiToParticipate = SafeMath.min256(cappedWeiReceived, weiLeftInSale);
        participationHistory[msg.sender] = weiAlreadyParticipated.add(weiToParticipate);
        fundingRecipient.transfer(weiToParticipate);


        uint256 tokensLeftInSale = MAX_TOKENS_SOLD.sub(tokensSold);
        uint256 tokensToIssue = weiToParticipate.mul(KIN_PER_WEI);
        if (tokensLeftInSale.sub(tokensToIssue) < KIN_PER_WEI) {


            tokensToIssue = tokensLeftInSale;
        }
        tokensSold = tokensSold.add(tokensToIssue);
        issueTokens(_recipient, tokensToIssue);



        uint256 refund = msg.value.sub(weiToParticipate);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
    }


    function finalize() external onlyAfterSale onlyOwner {
        if (!kin.isMinting()) {
            revert();
        }

        require(lastGrantedIndex == tokenGrantees.length);


        kin.endMinting();
    }




    function grantTokens() external onlyAfterSale onlyOwner {
        uint endIndex = SafeMath.min256(tokenGrantees.length, lastGrantedIndex + GRANT_BATCH_SIZE);
        for (uint i = lastGrantedIndex; i < endIndex; i++) {
            address grantee = tokenGrantees[i];


            TokenGrant memory tokenGrant = tokenGrants[grantee];
            uint256 tokensGranted = tokenGrant.value.mul(tokensSold).div(MAX_TOKENS_SOLD);
            uint256 tokensVested = tokensGranted.mul(tokenGrant.percentVested).div(100);
            uint256 tokensIssued = tokensGranted.sub(tokensVested);


            if (tokensIssued > 0) {
                issueTokens(grantee, tokensIssued);
            }


            if (tokensVested > 0) {
                issueTokens(trustee, tokensVested);
                trustee.grant(grantee, tokensVested, now.add(tokenGrant.startOffset), now.add(tokenGrant.cliffOffset),
                    now.add(tokenGrant.endOffset), tokenGrant.installmentLength, true);
            }

            lastGrantedIndex++;
        }
    }




    function issueTokens(address _recipient, uint256 _tokens) private {

        kin.mint(_recipient, _tokens);

        TokensIssued(_recipient, _tokens);
    }








    function requestKinTokenOwnershipTransfer(address _newOwnerCandidate) external onlyOwner {
        kin.requestOwnershipTransfer(_newOwnerCandidate);
    }



    function acceptKinTokenOwnership() external onlyOwner {
        kin.acceptOwnership();
    }








    function requestVestingTrusteeOwnershipTransfer(address _newOwnerCandidate) external onlyOwner {
        trustee.requestOwnershipTransfer(_newOwnerCandidate);
    }



    function acceptVestingTrusteeOwnership() external onlyOwner {
        trustee.acceptOwnership();
    }
}
