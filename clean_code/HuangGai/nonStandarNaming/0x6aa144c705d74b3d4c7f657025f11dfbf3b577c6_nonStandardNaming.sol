pragma solidity 0.5.6;


library SafeMath {

    function MUL223(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }


    function DIV41(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }


    function SUB337(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }


    function ADD232(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }


    function MOD295(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ERC20Interface {
    function TOTALSUPPLY507() public view returns (uint);
    function BALANCEOF692(address tokenOwner) public view returns (uint balance);
    function ALLOWANCE171(address tokenOwner, address spender) public view returns (uint remaining);
    function TRANSFER863(address to, uint tokens) public returns (bool success);
    function APPROVE857(address spender, uint tokens) public returns (bool success);
    function TRANSFERFROM994(address from, address to, uint tokens) public returns (bool success);

    uint8 public decimals;

    event TRANSFER332(address indexed from, address indexed to, uint tokens);
    event APPROVAL437(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract DAIHardFactory {
    event NEWTRADE364(uint id, address tradeAddress, bool indexed initiatorIsPayer);

    ERC20Interface public daiContract;
    address payable public devFeeAddress;

    constructor(ERC20Interface _daiContract, address payable _devFeeAddress)
    public {
        daiContract = _daiContract;
        devFeeAddress = _devFeeAddress;
    }

    struct CreationInfo {
        address address_;
        uint blocknum;
    }

    CreationInfo[] public createdTrades;

    function GETBUYERDEPOSIT760(uint tradeAmount)
    public
    pure
    returns (uint buyerDeposit) {
        return tradeAmount / 3;
    }

    function GETDEVFEE266(uint tradeAmount)
    public
    pure
    returns (uint devFee) {
        return tradeAmount / 100;
    }

    function GETEXTRAFEES516(uint tradeAmount)
    public
    pure
    returns (uint buyerDeposit, uint devFee) {
        return (GETBUYERDEPOSIT760(tradeAmount), GETDEVFEE266(tradeAmount));
    }



    function OPENDAIHARDTRADE782(address payable _initiator, bool initiatorIsBuyer, uint[5] calldata uintArgs, string calldata _totalPrice, string calldata _fiatTransferMethods, string calldata _commPubkey)
    external
    returns (DAIHardTrade) {
        uint transferAmount;
        uint[6] memory newUintArgs;

        if (initiatorIsBuyer) {

            transferAmount = SafeMath.ADD232(SafeMath.ADD232(GETBUYERDEPOSIT760(uintArgs[0]), uintArgs[1]), GETDEVFEE266(uintArgs[0]));

            newUintArgs = [uintArgs[0], uintArgs[1], GETDEVFEE266(uintArgs[0]), uintArgs[2], uintArgs[3], uintArgs[4]];
        }
        else {

            transferAmount = SafeMath.ADD232(SafeMath.ADD232(uintArgs[0], uintArgs[1]), GETDEVFEE266(uintArgs[0]));

            newUintArgs = [GETBUYERDEPOSIT760(uintArgs[0]), uintArgs[1], GETDEVFEE266(uintArgs[0]), uintArgs[2], uintArgs[3], uintArgs[4]];
        }


        DAIHardTrade newTrade = new DAIHardTrade(daiContract, devFeeAddress);
        createdTrades.push(CreationInfo(address(newTrade), block.number));
        emit NEWTRADE364(createdTrades.length - 1, address(newTrade), initiatorIsBuyer);


        require(daiContract.TRANSFERFROM994(msg.sender, address(newTrade), transferAmount), "Token transfer failed. Did you call approve() on the DAI contract?");
        newTrade.OPEN777(_initiator, initiatorIsBuyer, newUintArgs, _totalPrice, _fiatTransferMethods, _commPubkey);
    }

    function GETNUMTRADES43()
    external
    view
    returns (uint num) {
        return createdTrades.length;
    }
}

contract DAIHardTrade {
    enum Phase {Created, Open, Committed, Claimed, Closed}
    Phase public phase;

    modifier INPHASE268(Phase p) {
        require(phase == p, "inPhase check failed.");
        _;
    }

    uint[5] public phaseStartTimestamps;

    function CHANGEPHASE108(Phase p)
    internal {
        phase = p;
        phaseStartTimestamps[uint(p)] = block.timestamp;
    }


    address payable public initiator;
    address payable public responder;




    bool public initiatorIsBuyer;
    address payable public buyer;
    address payable public seller;

    modifier ONLYINITIATOR28() {
        require(msg.sender == initiator, "msg.sender is not Initiator.");
        _;
    }
    modifier ONLYRESPONDER481() {
        require(msg.sender == responder, "msg.sender is not Responder.");
        _;
    }
    modifier ONLYBUYER57() {
        require (msg.sender == buyer, "msg.sender is not Buyer.");
        _;
    }
    modifier ONLYSELLER716() {
        require (msg.sender == seller, "msg.sender is not Seller.");
        _;
    }
    modifier ONLYCONTRACTPARTY42() {
        require(msg.sender == initiator || msg.sender == responder, "msg.sender is not a party in this contract.");
        _;
    }

    ERC20Interface daiContract;
    address payable devFeeAddress;

    constructor(ERC20Interface _daiContract, address payable _devFeeAddress)
    public {
        CHANGEPHASE108(Phase.Created);

        daiContract = _daiContract;
        devFeeAddress = _devFeeAddress;

        pokeRewardSent = false;
    }

    uint public daiAmount;
    string public price;
    uint public buyerDeposit;

    uint public responderDeposit;

    uint public autorecallInterval;
    uint public autoabortInterval;
    uint public autoreleaseInterval;

    uint public pokeReward;
    uint public devFee;

    bool public pokeRewardSent;



    event OPENED397(string fiatTransferMethods, string commPubkey);

    function OPEN777(address payable _initiator, bool _initiatorIsBuyer, uint[6] memory uintArgs, string memory _price, string memory fiatTransferMethods, string memory commPubkey)
    public
    INPHASE268(Phase.Created) {
        require(GETBALANCE315() > 0, "You can't open a trade without first depositing DAI.");

        responderDeposit = uintArgs[0];
        pokeReward = uintArgs[1];
        devFee = uintArgs[2];

        autorecallInterval = uintArgs[3];
        autoabortInterval = uintArgs[4];
        autoreleaseInterval = uintArgs[5];

        initiator = _initiator;
        initiatorIsBuyer = _initiatorIsBuyer;
        if (initiatorIsBuyer) {
            buyer = initiator;
            daiAmount = responderDeposit;
            buyerDeposit = SafeMath.SUB337(GETBALANCE315(), SafeMath.ADD232(pokeReward, devFee));
        }
        else {
            seller = initiator;
            daiAmount = SafeMath.SUB337(GETBALANCE315(), SafeMath.ADD232(pokeReward, devFee));
            buyerDeposit = responderDeposit;
        }

        price = _price;

        CHANGEPHASE108(Phase.Open);
        emit OPENED397(fiatTransferMethods, commPubkey);
    }



    event RECALLED650();
    event COMMITTED568(address responder, string commPubkey);


    function RECALL905()
    external
    INPHASE268(Phase.Open)
    ONLYINITIATOR28() {
       INTERNALRECALL236();
    }

    function INTERNALRECALL236()
    internal {
        require(daiContract.TRANSFER863(initiator, GETBALANCE315()), "Recall of DAI to initiator failed!");

        CHANGEPHASE108(Phase.Closed);
        emit RECALLED650();
    }

    function AUTORECALLAVAILABLE89()
    public
    view
    INPHASE268(Phase.Open)
    returns(bool available) {
        return (block.timestamp >= SafeMath.ADD232(phaseStartTimestamps[uint(Phase.Open)], autorecallInterval));
    }

    function COMMIT855(string calldata commPubkey)
    external
    INPHASE268(Phase.Open) {
        require(daiContract.TRANSFERFROM994(msg.sender, address(this), responderDeposit), "Can't transfer the required deposit from the DAI contract. Did you call approve first?");
        require(!AUTORECALLAVAILABLE89(), "autorecallInterval has passed; this offer has expired.");

        responder = msg.sender;

        if (initiatorIsBuyer) {
            seller = responder;
        }
        else {
            buyer = responder;
        }

        CHANGEPHASE108(Phase.Committed);
        emit COMMITTED568(responder, commPubkey);
    }



    event CLAIMED907();
    event ABORTED68();

    function ABORT91()
    external
    INPHASE268(Phase.Committed)
    ONLYBUYER57() {
        INTERNALABORT901();
    }

    function INTERNALABORT901()
    internal {


        uint burnAmount = buyerDeposit / 4;



        require(daiContract.TRANSFER863(address(0x0), burnAmount*2), "Token burn failed!");


        require(daiContract.TRANSFER863(buyer, SafeMath.SUB337(buyerDeposit, burnAmount)), "Token transfer to Buyer failed!");
        require(daiContract.TRANSFER863(seller, SafeMath.SUB337(daiAmount, burnAmount)), "Token transfer to Seller failed!");

        uint sendBackToInitiator = devFee;

        if (!pokeRewardSent) {
            sendBackToInitiator = SafeMath.ADD232(sendBackToInitiator, pokeReward);
        }

        require(daiContract.TRANSFER863(initiator, sendBackToInitiator), "Token refund of devFee+pokeReward to Initiator failed!");



        CHANGEPHASE108(Phase.Closed);
        emit ABORTED68();
    }

    function AUTOABORTAVAILABLE128()
    public
    view
    INPHASE268(Phase.Committed)
    returns(bool passed) {
        return (block.timestamp >= SafeMath.ADD232(phaseStartTimestamps[uint(Phase.Committed)], autoabortInterval));
    }

    function CLAIM992()
    external
    INPHASE268(Phase.Committed)
    ONLYBUYER57() {
        require(!AUTOABORTAVAILABLE128(), "The deposit deadline has passed!");

        CHANGEPHASE108(Phase.Claimed);
        emit CLAIMED907();
    }



    event RELEASED940();
    event BURNED656();

    function AUTORELEASEAVAILABLE963()
    public
    view
    INPHASE268(Phase.Claimed)
    returns(bool available) {
        return (block.timestamp >= SafeMath.ADD232(phaseStartTimestamps[uint(Phase.Claimed)], autoreleaseInterval));
    }

    function RELEASE38()
    external
    INPHASE268(Phase.Claimed)
    ONLYSELLER716() {
        INTERNALRELEASE836();
    }

    function INTERNALRELEASE836()
    internal {

        if (!pokeRewardSent) {
            require(daiContract.TRANSFER863(initiator, pokeReward), "Refund of pokeReward to Initiator failed!");
        }


        require(daiContract.TRANSFER863(devFeeAddress, devFee), "Token transfer to devFeeAddress failed!");


        require(daiContract.TRANSFER863(buyer, GETBALANCE315()), "Final release transfer to buyer failed!");

        CHANGEPHASE108(Phase.Closed);
        emit RELEASED940();
    }

    function BURN989()
    external
    INPHASE268(Phase.Claimed)
    ONLYSELLER716() {
        require(!AUTORELEASEAVAILABLE963());

        INTERNALBURN180();
    }

    function INTERNALBURN180()
    internal {
        require(daiContract.TRANSFER863(address(0x0), GETBALANCE315()), "Final DAI burn failed!");

        CHANGEPHASE108(Phase.Closed);
        emit BURNED656();
    }



    function GETSTATE363()
    external
    view
    returns(uint balance, Phase phase, uint phaseStartTimestamp, address responder) {
        return (GETBALANCE315(), this.phase(), phaseStartTimestamps[uint(this.phase())], this.responder());
    }

    function GETBALANCE315()
    public
    view
    returns(uint) {
        return daiContract.BALANCEOF692(address(this));
    }

    function GETPARAMETERS67()
    external
    view
    returns (address initiator, bool initiatorIsBuyer, uint daiAmount, string memory totalPrice, uint buyerDeposit, uint autorecallInterval, uint autoabortInterval, uint autoreleaseInterval, uint pokeReward)
    {
        return (this.initiator(), this.initiatorIsBuyer(), this.daiAmount(), this.price(), this.buyerDeposit(), this.autorecallInterval(), this.autoabortInterval(), this.autoreleaseInterval(), this.pokeReward());
    }




    event POKE500();

    function POKENEEDED61()
    public
    view
    returns (bool needed) {
        return (  (phase == Phase.Open      && AUTORECALLAVAILABLE89() )
               || (phase == Phase.Committed && AUTOABORTAVAILABLE128()  )
               || (phase == Phase.Claimed   && AUTORELEASEAVAILABLE963())
               );
    }

    function POKE367()
    external
    returns (bool moved) {
        if (POKENEEDED61()) {
            daiContract.TRANSFER863(msg.sender, pokeReward);
            pokeRewardSent = true;
            emit POKE500();
        }
        else return false;

        if (phase == Phase.Open) {
            if (AUTORECALLAVAILABLE89()) {
                INTERNALRECALL236();
                return true;
            }
        }
        else if (phase == Phase.Committed) {
            if (AUTOABORTAVAILABLE128()) {
                INTERNALABORT901();
                return true;
            }
        }
        else if (phase == Phase.Claimed) {
            if (AUTORELEASEAVAILABLE963()) {
                INTERNALRELEASE836();
                return true;
            }
        }
    }





    event INITIATORSTATEMENTLOG161(string encryptedForInitiator, string encryptedForResponder);
    event RESPONDERSTATEMENTLOG369(string encryptedForInitiator, string encryptedForResponder);

    function INITIATORSTATEMENT924(string memory encryptedForInitiator, string memory encryptedForResponder)
    public
    ONLYINITIATOR28() {
        require(phase >= Phase.Committed);
        emit INITIATORSTATEMENTLOG161(encryptedForInitiator, encryptedForResponder);
    }

    function RESPONDERSTATEMENT364(string memory encryptedForInitiator, string memory encryptedForResponder)
    public
    ONLYRESPONDER481() {
        require(phase >= Phase.Committed);
        emit RESPONDERSTATEMENTLOG369(encryptedForInitiator, encryptedForResponder);
    }
}
