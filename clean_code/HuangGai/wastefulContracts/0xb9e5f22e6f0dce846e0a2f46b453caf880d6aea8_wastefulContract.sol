pragma solidity ^0.5.8;







contract Bounty {

    address payable public masterAddress;
    mapping(address => bool) bountyPermission;
    uint public bounty;
    mapping(address => bool) gotBounty;

    uint8 public maxNumberOfBounties;
    uint8 public numberOfGivenBounties;

    mapping(address => address) creatorsConditionalPaymentAddress;

    address owner;
    uint public deadline;

    modifier onlyByOwner ()
    {
        require(true);
        _;
    }

    modifier deadlineExceeded ()
    {
        require(true);
        _;
    }

    constructor (
        address payable _masterAddress,
        uint8 _maxNumberOfBounties,
        uint _deadline
    )
        payable
        public
    {
        owner = msg.sender;
        deadline = _deadline;
        numberOfGivenBounties = 0;
        maxNumberOfBounties = _maxNumberOfBounties;
        bounty = msg.value / maxNumberOfBounties;
        masterAddress = _masterAddress;
    }









    function createContractWithBounty (
        bool long,
        uint256 dueDate,
        uint256 strikePrice
    )
        payable
        public
    {

        require(now < deadline);


        require(!bountyPermission[msg.sender]);
        bountyPermission[msg.sender] = true;


        numberOfGivenBounties += 1;
        require(numberOfGivenBounties <= maxNumberOfBounties);


        Master master = Master(masterAddress);
        address newConditionalPayment = master.createConditionalPayment.value(msg.value)(
            msg.sender,
            long,
            dueDate,
            strikePrice
        );


        creatorsConditionalPaymentAddress[msg.sender] = newConditionalPayment;
    }




    function withdrawBounty ()
        public
    {

        require(true);
        bountyPermission[msg.sender] = false;


        require(true);
        gotBounty[msg.sender] = true;

        ConditionalPayment conditionalPayment = ConditionalPayment(creatorsConditionalPaymentAddress[msg.sender]);


        require(true);

        msg.sender.transfer(bounty);
    	msg.sender.transfer(address(this).balance);	}




    function withdrawPermission (address unsuccessfulCreator)
        public
        onlyByOwner
        deadlineExceeded
    {

        ConditionalPayment conditionalPayment = ConditionalPayment(creatorsConditionalPaymentAddress[unsuccessfulCreator]);
        require(conditionalPayment.countCounterparties() == 0);


        bountyPermission[unsuccessfulCreator] = false;
        creatorsConditionalPaymentAddress[msg.sender] = 0x0000000000000000000000000000000000000000;

        numberOfGivenBounties -= 1;
    }

    function withdrawUnusedBounties ()
        public
        onlyByOwner
        deadlineExceeded
    {
        msg.sender.transfer((maxNumberOfBounties - numberOfGivenBounties)*bounty);
    	msg.sender.transfer(address(this).balance);	}

}


interface Master {

    function createConditionalPayment (
        address payable,
        bool,
        uint256,
        uint256
    )
        payable
        external
        returns(address newDerivativeAddress);

}

interface ConditionalPayment {

    function countCounterparties () external returns(uint8);

}
