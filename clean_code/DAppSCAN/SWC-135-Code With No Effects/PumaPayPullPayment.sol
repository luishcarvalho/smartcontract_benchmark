pragma solidity 0.5.8;

import "./ownership/PayableOwnable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";



contract PumaPayPullPayment is PayableOwnable {

    using SafeMath for uint256;





    event LogExecutorAdded(address executor);
    event LogExecutorRemoved(address executor);
    event LogSetConversionRate(string currency, uint256 conversionRate);

    event LogPaymentRegistered(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID,
        string uniqueReferenceID
    );
    event LogPaymentCancelled(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID,
        string uniqueReferenceID
    );
    event LogPullPaymentExecuted(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID,
        string uniqueReferenceID
    );





    uint256 constant private DECIMAL_FIXER = 10 ** 10;
    uint256 constant private FIAT_TO_CENT_FIXER = 100;
    uint256 constant private OVERFLOW_LIMITER_NUMBER = 10 ** 20;

    uint256 constant private ONE_ETHER = 1 ether;
    uint256 constant private FUNDING_AMOUNT = 1 ether;
    uint256 constant private MINIMUM_AMOUNT_OF_ETH_FOR_OPERATORS = 0.15 ether;





    IERC20 public token;

    mapping(string => uint256) private conversionRates;
    mapping(address => bool) public executors;
    mapping(address => mapping(address => PullPayment)) public pullPayments;

    struct PullPayment {
        bytes32 paymentID;
        bytes32 businessID;
        string uniqueReferenceID;
        string currency;
        uint256 initialPaymentAmountInCents;
        uint256 fiatAmountInCents;
        uint256 frequency;
        uint256 numberOfPayments;
        uint256 startTimestamp;
        uint256 nextPaymentTimestamp;
        uint256 lastPaymentTimestamp;
        uint256 cancelTimestamp;
        address treasuryAddress;
    }




    modifier isExecutor() {
        require(executors[msg.sender], "msg.sender not an executor");
        _;
    }

    modifier executorExists(address _executor) {
        require(executors[_executor], "Executor does not exists.");
        _;
    }

    modifier executorDoesNotExists(address _executor) {
        require(!executors[_executor], "Executor already exists.");
        _;
    }

    modifier paymentExists(address _customer, address _pullPaymentExecutor) {
        require(doesPaymentExist(_customer, _pullPaymentExecutor), "Pull Payment does not exists");
        _;
    }

    modifier paymentNotCancelled(address _customer, address _pullPaymentExecutor) {
        require(pullPayments[_customer][_pullPaymentExecutor].cancelTimestamp == 0, "Pull Payment is cancelled.");
        _;
    }

    modifier isValidPullPaymentExecutionRequest(address _customer, address _pullPaymentExecutor, bytes32 _paymentID) {
        require(
            (pullPayments[_customer][_pullPaymentExecutor].initialPaymentAmountInCents > 0 ||
        (now >= pullPayments[_customer][_pullPaymentExecutor].startTimestamp &&
        now >= pullPayments[_customer][_pullPaymentExecutor].nextPaymentTimestamp)
            ), "Invalid pull payment execution request - Time of execution is invalid."
        );
        require(pullPayments[_customer][_pullPaymentExecutor].numberOfPayments > 0,
            "Invalid pull payment execution request - Number of payments is zero.");

        require((pullPayments[_customer][_pullPaymentExecutor].cancelTimestamp == 0 ||
        pullPayments[_customer][_pullPaymentExecutor].cancelTimestamp > pullPayments[_customer][_pullPaymentExecutor].nextPaymentTimestamp),
            "Invalid pull payment execution request - Pull payment is cancelled");
        require(keccak256(
            abi.encodePacked(pullPayments[_customer][_pullPaymentExecutor].paymentID)
        ) == keccak256(abi.encodePacked(_paymentID)),
            "Invalid pull payment execution request - Payment ID not matching.");
        _;
    }

    modifier isValidDeletionRequest(bytes32 _paymentID, address _customer, address _pullPaymentExecutor) {
        require(_customer != address(0), "Invalid deletion request - Client address is ZERO_ADDRESS.");
        require(_pullPaymentExecutor != address(0), "Invalid deletion request - Beneficiary address is ZERO_ADDRESS.");
        require(_paymentID.length != 0, "Invalid deletion request - Payment ID is empty.");
        _;
    }

    modifier isValidAddress(address _address) {
        require(_address != address(0), "Invalid address - ZERO_ADDRESS provided");
        _;
    }

    modifier validConversionRate(string memory _currency) {
        require(bytes(_currency).length != 0, "Invalid conversion rate - Currency is empty.");
        require(conversionRates[_currency] > 0, "Invalid conversion rate - Must be higher than zero.");
        _;
    }

    modifier validAmount(uint256 _fiatAmountInCents) {
        require(_fiatAmountInCents > 0, "Invalid amount - Must be higher than zero");
        _;
    }







    constructor (address _token)
    public {
        require(_token != address(0), "Invalid address for token - ZERO_ADDRESS provided");
        token = IERC20(_token);
    }


    function() external payable {
    }










    function addExecutor(address payable _executor)
    public
    onlyOwner
    isValidAddress(_executor)
    executorDoesNotExists(_executor)
    {
        _executor.transfer(FUNDING_AMOUNT);
        executors[_executor] = true;

        if (isFundingNeeded(owner())) {
            owner().transfer(FUNDING_AMOUNT);
        }

        emit LogExecutorAdded(_executor);
    }




    function removeExecutor(address payable _executor)
    public
    onlyOwner
    isValidAddress(_executor)
    executorExists(_executor)
    {
        executors[_executor] = false;
        if (isFundingNeeded(owner())) {
            owner().transfer(FUNDING_AMOUNT);
        }
        emit LogExecutorRemoved(_executor);
    }






    function setRate(string memory _currency, uint256 _rate)
    public
    onlyOwner
    returns (bool) {
        conversionRates[_currency] = _rate;
        emit LogSetConversionRate(_currency, _rate);

        if (isFundingNeeded(owner())) {
            owner().transfer(FUNDING_AMOUNT);
        }

        return true;
    }





















    function registerPullPayment(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32[2] memory _ids,
        address[3] memory _addresses,
        string memory _currency,
        string memory _uniqueReferenceID,
        uint256 _initialPaymentAmountInCents,
        uint256 _fiatAmountInCents,
        uint256 _frequency,
        uint256 _numberOfPayments,
        uint256 _startTimestamp
    )
    public
    isExecutor()
    {
        require(_ids[0].length > 0, "Payment ID is empty.");
        require(_ids[1].length > 0, "Business ID is empty.");
        require(bytes(_currency).length > 0, "Currency is empty.");
        require(bytes(_uniqueReferenceID).length > 0, "Unique Reference ID is empty.");
        require(_addresses[0] != address(0), "Customer Address is ZERO_ADDRESS.");
        require(_addresses[1] != address(0), "Beneficiary Address is ZERO_ADDRESS.");
        require(_addresses[2] != address(0), "Treasury Address is ZERO_ADDRESS.");
        require(_fiatAmountInCents > 0, "Payment amount in fiat is zero.");
        require(_frequency > 0, "Payment frequency is zero.");
        require(_frequency < OVERFLOW_LIMITER_NUMBER, "Payment frequency is higher thant the overflow limit.");
        require(_numberOfPayments > 0, "Payment number of payments is zero.");
        require(_numberOfPayments < OVERFLOW_LIMITER_NUMBER, "Payment number of payments is higher thant the overflow limit.");
        require(_startTimestamp > 0, "Payment start time is zero.");
        require(_startTimestamp < OVERFLOW_LIMITER_NUMBER, "Payment start time is higher thant the overflow limit.");

        pullPayments[_addresses[0]][_addresses[1]].currency = _currency;
        pullPayments[_addresses[0]][_addresses[1]].initialPaymentAmountInCents = _initialPaymentAmountInCents;
        pullPayments[_addresses[0]][_addresses[1]].fiatAmountInCents = _fiatAmountInCents;
        pullPayments[_addresses[0]][_addresses[1]].frequency = _frequency;
        pullPayments[_addresses[0]][_addresses[1]].startTimestamp = _startTimestamp;
        pullPayments[_addresses[0]][_addresses[1]].numberOfPayments = _numberOfPayments;
        pullPayments[_addresses[0]][_addresses[1]].paymentID = _ids[0];
        pullPayments[_addresses[0]][_addresses[1]].businessID = _ids[1];
        pullPayments[_addresses[0]][_addresses[1]].uniqueReferenceID = _uniqueReferenceID;
        pullPayments[_addresses[0]][_addresses[1]].treasuryAddress = _addresses[2];

        require(isValidRegistration(
                v,
                r,
                s,
                _addresses[0],
                _addresses[1],
                pullPayments[_addresses[0]][_addresses[1]]),
            "Invalid pull payment registration - ECRECOVER_FAILED"
        );

        pullPayments[_addresses[0]][_addresses[1]].nextPaymentTimestamp = _startTimestamp;
        pullPayments[_addresses[0]][_addresses[1]].lastPaymentTimestamp = 0;
        pullPayments[_addresses[0]][_addresses[1]].cancelTimestamp = 0;

        if (isFundingNeeded(msg.sender)) {
            msg.sender.transfer(FUNDING_AMOUNT);
        }

        emit LogPaymentRegistered(_addresses[0], _ids[0], _ids[1], _uniqueReferenceID);
    }














    function deletePullPayment(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 _paymentID,
        address _customer,
        address _pullPaymentExecutor
    )
    public
    isExecutor()
    paymentExists(_customer, _pullPaymentExecutor)
    paymentNotCancelled(_customer, _pullPaymentExecutor)
    isValidDeletionRequest(_paymentID, _customer, _pullPaymentExecutor)
    {
        require(isValidDeletion(v, r, s, _paymentID, _customer, _pullPaymentExecutor), "Invalid deletion - ECRECOVER_FAILED.");

        pullPayments[_customer][_pullPaymentExecutor].cancelTimestamp = now;

        if (isFundingNeeded(msg.sender)) {
            msg.sender.transfer(FUNDING_AMOUNT);
        }

        emit LogPaymentCancelled(
            _customer,
            _paymentID,
            pullPayments[_customer][_pullPaymentExecutor].businessID,
            pullPayments[_customer][_pullPaymentExecutor].uniqueReferenceID
        );
    }





















    function executePullPayment(address _customer, bytes32 _paymentID)
    public
    paymentExists(_customer, msg.sender)
    isValidPullPaymentExecutionRequest(_customer, msg.sender, _paymentID)
    {
        uint256 amountInPMA;

        if (pullPayments[_customer][msg.sender].initialPaymentAmountInCents > 0) {
            amountInPMA = calculatePMAFromFiat(
                pullPayments[_customer][msg.sender].initialPaymentAmountInCents,
                pullPayments[_customer][msg.sender].currency
            );
            pullPayments[_customer][msg.sender].initialPaymentAmountInCents = 0;
        } else {
            amountInPMA = calculatePMAFromFiat(
                pullPayments[_customer][msg.sender].fiatAmountInCents,
                pullPayments[_customer][msg.sender].currency
            );

            pullPayments[_customer][msg.sender].nextPaymentTimestamp =
            pullPayments[_customer][msg.sender].nextPaymentTimestamp + pullPayments[_customer][msg.sender].frequency;
            pullPayments[_customer][msg.sender].numberOfPayments = pullPayments[_customer][msg.sender].numberOfPayments - 1;
        }

        pullPayments[_customer][msg.sender].lastPaymentTimestamp = now;
        token.transferFrom(
            _customer,
            pullPayments[_customer][msg.sender].treasuryAddress,
            amountInPMA
        );

        emit LogPullPaymentExecuted(
            _customer,
            pullPayments[_customer][msg.sender].paymentID,
            pullPayments[_customer][msg.sender].businessID,
            pullPayments[_customer][msg.sender].uniqueReferenceID
        );
    }

    function getRate(string memory _currency) public view returns (uint256) {
        return conversionRates[_currency];
    }


















    function calculatePMAFromFiat(uint256 _fiatAmountInCents, string memory _currency)
    internal
    view
    validConversionRate(_currency)
    validAmount(_fiatAmountInCents)
    returns (uint256) {
        return ONE_ETHER.mul(DECIMAL_FIXER).mul(_fiatAmountInCents).div(conversionRates[_currency]).div(FIAT_TO_CENT_FIXER);
    }










    function isValidRegistration(
        uint8 v,
        bytes32 r,
        bytes32 s,
        address _customer,
        address _pullPaymentExecutor,
        PullPayment memory _pullPayment
    )
    internal
    pure
    returns (bool)
    {
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    _pullPaymentExecutor,
                    _pullPayment.paymentID,
                    _pullPayment.businessID,
                    _pullPayment.uniqueReferenceID,
                    _pullPayment.treasuryAddress,
                    _pullPayment.currency,
                    _pullPayment.initialPaymentAmountInCents,
                    _pullPayment.fiatAmountInCents,
                    _pullPayment.frequency,
                    _pullPayment.numberOfPayments,
                    _pullPayment.startTimestamp
                )
            ),
            v, r, s) == _customer;
    }










    function isValidDeletion(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 _paymentID,
        address _customer,
        address _pullPaymentExecutor
    )
    internal
    view
    returns (bool)
    {
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    _paymentID,
                    _pullPaymentExecutor
                )
            ), v, r, s) == _customer
        && keccak256(
            abi.encodePacked(pullPayments[_customer][_pullPaymentExecutor].paymentID)
        ) == keccak256(abi.encodePacked(_paymentID)
        );
    }





    function doesPaymentExist(address _customer, address _pullPaymentExecutor)
    internal
    view
    returns (bool) {
        return (
        bytes(pullPayments[_customer][_pullPaymentExecutor].currency).length > 0 &&
        pullPayments[_customer][_pullPaymentExecutor].fiatAmountInCents > 0 &&
        pullPayments[_customer][_pullPaymentExecutor].frequency > 0 &&
        pullPayments[_customer][_pullPaymentExecutor].startTimestamp > 0 &&
        pullPayments[_customer][_pullPaymentExecutor].numberOfPayments > 0 &&
        pullPayments[_customer][_pullPaymentExecutor].nextPaymentTimestamp > 0
        );
    }





    function isFundingNeeded(address _address)
    private
    view
    returns (bool) {
        return address(_address).balance <= MINIMUM_AMOUNT_OF_ETH_FOR_OPERATORS;
    }
}
