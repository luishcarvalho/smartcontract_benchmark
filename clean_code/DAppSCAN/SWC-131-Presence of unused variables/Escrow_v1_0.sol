pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../token/ITokenContract.sol";









contract Escrow_v1_0 {

    using SafeMath for uint256;

    enum Status {FUNDED, RELEASED}

    enum TransactionType {ETHER, TOKEN}

    event Executed(
        bytes32 scriptHash,
        address[] destinations,
        uint256[] amounts
    );

    event FundAdded(
        bytes32 scriptHash,
        address indexed from,
        uint256 valueAdded
    );

    event Funded(bytes32 scriptHash, address indexed from, uint256 value);

    struct Transaction {

        bytes32 scriptHash;
        uint256 value;
        uint256 lastModified;
        Status status;
        TransactionType transactionType;
        uint8 threshold;
        uint32 timeoutHours;
        address buyer;
        address seller;
        address tokenAddress;
        address moderator;
        mapping(address=>bool) isOwner;
        mapping(address=>bool) voted;
        mapping(address=>bool) beneficiaries;
    }

    mapping(bytes32 => Transaction) public transactions;

    uint256 public transactionCount = 0;


    mapping(address => bytes32[])public partyVsTransaction;

    modifier transactionExists(bytes32 scriptHash) {
        require(
            transactions[scriptHash].value != 0, "Transaction does not exists"
        );
        _;
    }

    modifier transactionDoesNotExists (bytes32 scriptHash) {
        require(transactions[scriptHash].value == 0, "Transaction exists");
        _;
    }

    modifier inFundedState(bytes32 scriptHash) {
        require(
            transactions[scriptHash].status == Status.FUNDED, "Transaction is either in dispute or released state"
        );
        _;
    }

    modifier nonZeroAddress(address addressToCheck) {
        require(addressToCheck != address(0), "Zero address passed");
        _;
    }

    modifier checkTransactionType(
        bytes32 scriptHash,
        TransactionType transactionType
    )
    {
        require(
            transactions[scriptHash].transactionType == transactionType, "Transaction type does not match"
        );
        _;
    }

    modifier onlyBuyer(bytes32 scriptHash) {
        require(
            msg.sender == transactions[scriptHash].buyer, "The initiator of the transaction is not buyer"
        );
        _;
    }
















    function addTransaction(
        address buyer,
        address seller,
        address moderator,
        uint8 threshold,
        uint32 timeoutHours,
        bytes32 scriptHash,
        bytes20 uniqueId
    )
        external
        payable
        transactionDoesNotExists(scriptHash)
        nonZeroAddress(buyer)
        nonZeroAddress(seller)
    {
        _addTransaction(
            buyer,
            seller,
            moderator,
            threshold,
            timeoutHours,
            scriptHash,
            msg.value,
            uniqueId,
            TransactionType.ETHER,
            address(0)
        );

        emit Funded(scriptHash, msg.sender, msg.value);

    }


















    function addTokenTransaction(
        address buyer,
        address seller,
        address moderator,
        uint8 threshold,
        uint32 timeoutHours,
        bytes32 scriptHash,
        uint256 value,
        bytes20 uniqueId,
        address tokenAddress
    )
        external
        transactionDoesNotExists(scriptHash)
        nonZeroAddress(buyer)
        nonZeroAddress(seller)
        nonZeroAddress(tokenAddress)
    {

        _addTransaction(
            buyer,
            seller,
            moderator,
            threshold,
            timeoutHours,
            scriptHash,
            value,
            uniqueId,
            TransactionType.TOKEN,
            tokenAddress
        );

        ITokenContract token = ITokenContract(tokenAddress);

        require(
            token.transferFrom(msg.sender, this, value),
            "Token transfer failed, maybe you did not approve escrow contract to spend on behalf of buyer"
        );
        emit Funded(scriptHash, msg.sender, value);
    }






    function checkBeneficiary(
        bytes32 scriptHash,
        address beneficiary
    )
        external
        view
        returns (bool check)
    {
        check = transactions[scriptHash].beneficiaries[beneficiary];
    }







    function checkVote(
        bytes32 scriptHash,
        address party
    )
        external
        view
        returns (bool vote)
    {
        vote = transactions[scriptHash].voted[party];
    }






    function addFundsToTransaction(
        bytes32 scriptHash
    )
        external
        transactionExists(scriptHash)
        inFundedState(scriptHash)
        checkTransactionType(scriptHash, TransactionType.ETHER)
        onlyBuyer(scriptHash)
        payable
    {
        uint256 _value = msg.value;

        require(_value > 0, "Value must be greater than zero.");

        transactions[scriptHash].value = transactions[scriptHash].value
            .add(_value);
        transactions[scriptHash].lastModified = block.timestamp;

        emit FundAdded(scriptHash, msg.sender, _value);
    }





    function addTokensToTransaction(
        bytes32 scriptHash,
        uint256 value
    )
        external
        transactionExists(scriptHash)
        inFundedState(scriptHash)
        checkTransactionType(scriptHash, TransactionType.TOKEN)
        onlyBuyer(scriptHash)
    {
        uint256 _value = value;

        require(_value > 0, "Value must be greater than zero.");

        ITokenContract token = ITokenContract(
            transactions[scriptHash].tokenAddress
        );

        require(
            token.transferFrom(transactions[scriptHash].buyer, this, value),
            "Token transfer failed, maybe you did not approve escrow contract to spend on behalf of buyer"
        );

        transactions[scriptHash].value = transactions[scriptHash].value
            .add(_value);
        transactions[scriptHash].lastModified = block.timestamp;

        emit FundAdded(scriptHash, msg.sender, _value);
    }





    function getAllTransactionsForParty(
        address partyAddress
    )
        external
        view
        returns (bytes32[] scriptHashes)
    {
        return partyVsTransaction[partyAddress];
    }











    function execute(
        uint8[] sigV,
        bytes32[] sigR,
        bytes32[] sigS,
        bytes32 scriptHash,
        address[] destinations,
        uint256[] amounts
    )
        external
        transactionExists(scriptHash)
        inFundedState(scriptHash)
    {
        require(
            destinations.length>0 && destinations.length == amounts.length, "Length of destinations is incorrect."
        );

        verifyTransaction(
            sigV,
            sigR,
            sigS,
            scriptHash,
            destinations,
            amounts
        );

        transactions[scriptHash].status = Status.RELEASED;

        transactions[scriptHash].lastModified = block.timestamp;
        require(
            transferFunds(scriptHash, destinations, amounts) == transactions[scriptHash].value,
            "Total value to be released must be equal to the transaction escrow value"
        );

        emit Executed(scriptHash, destinations, amounts);
    }










    function calculateRedeemScriptHash(
        bytes20 uniqueId,
        uint8 threshold,
        uint32 timeoutHours,
        address buyer,
        address seller,
        address moderator,
        address tokenAddress
    )
        public
        view
        returns (bytes32 hash)
    {
        if (tokenAddress == address(0)) {
            hash = keccak256(
                abi.encodePacked(
                    uniqueId,
                    threshold,
                    timeoutHours,
                    buyer,
                    seller,
                    moderator,
                    this
                )
            );
        } else {
            hash = keccak256(
                abi.encodePacked(
                    uniqueId,
                    threshold,
                    timeoutHours,
                    buyer,
                    seller,
                    moderator,
                    this,
                    tokenAddress
                )
            );
        }
    }







    function verifyTransaction(
        uint8[] sigV,
        bytes32[] sigR,
        bytes32[] sigS,
        bytes32 scriptHash,
        address[] destinations,
        uint256[] amounts
    )
        private
    {
        address lastRecovered = verifySignatures(
            sigV,
            sigR,
            sigS,
            scriptHash,
            destinations,
            amounts
        );

        bool timeLockExpired = isTimeLockExpired(
            transactions[scriptHash].timeoutHours,
            transactions[scriptHash].lastModified
        );


        if (
                sigV.length < transactions[scriptHash].threshold && (!timeLockExpired || lastRecovered != transactions[scriptHash].seller)
            )
        {
            revert("sigV.length is under the threshold.");
        }

    }




    function transferFunds(
        bytes32 scriptHash,
        address[]destinations,
        uint256[]amounts
    )
        private
        returns (uint256 valueTransferred)
    {
        Transaction storage t = transactions[scriptHash];

        if (t.transactionType == TransactionType.ETHER) {
            for (uint256 i = 0; i < destinations.length; i++) {

                require(destinations[i] != address(0) && t.isOwner[destinations[i]], "Not a valid destination");
                require(amounts[i] > 0, "Amount to be sent should be greater than 0");

                valueTransferred = valueTransferred.add(amounts[i]);

                t.beneficiaries[destinations[i]] = true;
                destinations[i].transfer(amounts[i]);
            }

        } else if (t.transactionType == TransactionType.TOKEN) {

            ITokenContract token = ITokenContract(t.tokenAddress);

            for (uint256 j = 0; j<destinations.length; j++) {

                require(destinations[j] != address(0) && t.isOwner[destinations[j]], "Not a valid destination");
                require(amounts[j] > 0, "Amount to be sent should be greater than 0");

                valueTransferred = valueTransferred.add(amounts[j]);
                t.beneficiaries[destinations[j]] = true;

                require(token.transfer(destinations[j], amounts[j]), "Token transfer failed.");
            }

        } else {

            revert("Transation type is not supported.");
        }
    }



    function verifySignatures(
        uint8[] sigV,
        bytes32[] sigR,
        bytes32[] sigS,
        bytes32 scriptHash,
        address[] destinations,
        uint256[]amounts
    )
        private
        returns (address lastAddress)
    {
        require(
            sigR.length == sigS.length && sigR.length == sigV.length,
            "R,S,V length mismatch."
        );


        bytes32 txHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        byte(0x19),
                        byte(0),
                        this,
                        destinations,
                        amounts,
                        scriptHash
                    )
                )
            )
        );

        for (uint i = 0; i < sigR.length; i++) {

            address recovered = ecrecover(
                txHash,
                sigV[i],
                sigR[i],
                sigS[i]
            );

            require(
                transactions[scriptHash].isOwner[recovered],
                "Invalid signature"
            );
            require(
                !transactions[scriptHash].voted[recovered],
                "Same signature sent twice"
            );
            transactions[scriptHash].voted[recovered] = true;
            lastAddress = recovered;
        }
    }

    function isTimeLockExpired(
        uint32 timeoutHours,
        uint256 lastModified
    )
        private
        view
        returns (bool expired)
    {
        uint256 timeSince = now.sub(lastModified);
        expired = (
            timeoutHours == 0 ? false:timeSince > uint256(timeoutHours).mul(3600)
        );
    }




    function _addTransaction(
        address buyer,
        address seller,
        address moderator,
        uint8 threshold,
        uint32 timeoutHours,
        bytes32 scriptHash,
        uint256 value,
        bytes20 uniqueId,
        TransactionType transactionType,
        address tokenAddress
    )
        private
    {
        require(buyer != seller, "Buyer and seller are same");


        require(value > 0, "Value passed is 0");


        require(
            threshold > 0 && threshold <= 3,
            "Threshold cannot be greater than 3 and must be greater than 0"
        );
        require(
            threshold == 1 || moderator != address(0),
            "Either threshold should be 1 otherwise valid moderator address should be passed"
        );

        require(
            scriptHash == calculateRedeemScriptHash(
                uniqueId,
                threshold,
                timeoutHours,
                buyer,
                seller,
                moderator,
                tokenAddress
            ),
            "Calculated script hash does not match passed script hash."
        );

        transactions[scriptHash] = Transaction({
            buyer: buyer,
            seller: seller,
            moderator: moderator,
            value: value,
            status: Status.FUNDED,
            lastModified: block.timestamp,
            scriptHash: scriptHash,
            threshold: threshold,
            timeoutHours: timeoutHours,
            transactionType:transactionType,
            tokenAddress:tokenAddress
        });

        transactions[scriptHash].isOwner[seller] = true;
        transactions[scriptHash].isOwner[buyer] = true;


        require(
            !transactions[scriptHash].isOwner[moderator],
            "Either buyer or seller is passed as moderator"
        );

        transactions[scriptHash].isOwner[moderator] = true;


        transactionCount++;

        partyVsTransaction[buyer].push(scriptHash);
        partyVsTransaction[seller].push(scriptHash);
    }
}
