pragma solidity 0.5.13;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "hardhat/console.sol";
import './lib/NativeMetaTransaction.sol';




contract RCTreasury is Ownable, NativeMetaTransaction {

    using SafeMath for uint256;






    address public factoryAddress;

    mapping (address => bool) public isMarket;

    mapping (address => uint256) public deposits;

    uint256 public totalDeposits;

    mapping (address => uint256) public marketPot;

    uint256 public totalMarketPots;

    mapping (address => uint256) public userTotalRentals;

    mapping (address => uint256) public lastRentalTime;




    uint256 public minRentalDivisor;

    uint256 public maxContractBalance;



    bool public globalPause;

    mapping (address => bool) public marketPaused;



    address public uberOwner;





    event LogDepositIncreased(address indexed sentBy, uint256 indexed daiDeposited);
    event LogDepositWithdrawal(address indexed returnedTo, uint256 indexed daiWithdrawn);
    event LogAdjustDeposit(address indexed user, uint256 indexed amount, bool increase);
    event LogHotPotatoPayment(address from, address to, uint256 amount);





    constructor() public {

        _initializeEIP712("RealityCardsTreasury","1");


        uberOwner = msg.sender;


        setMinRental(24*6);
        setMaxContractBalance(1000000 ether);
    }





    modifier balancedBooks {
        _;


        assert(address(this).balance >= totalDeposits + totalMarketPots);
    }

    modifier onlyMarkets {
        require(isMarket[msg.sender], "Not authorised");
        _;
    }






    function addMarket(address _newMarket) external returns(bool) {
        require(msg.sender == factoryAddress, "Not factory");
        isMarket[_newMarket] = true;
        return true;
    }










    function setMinRental(uint256 _newDivisor) public onlyOwner {
        minRentalDivisor = _newDivisor;
    }


    function setMaxContractBalance(uint256 _newBalanceLimit) public onlyOwner {
        maxContractBalance = _newBalanceLimit;
    }




    function setGlobalPause() external onlyOwner {
        globalPause = globalPause ? false : true;
    }


    function setPauseMarket(address _market) external onlyOwner {
        marketPaused[_market] = marketPaused[_market] ? false : true;
    }










    function setFactoryAddress(address _newFactory) external {
        require(msg.sender == uberOwner, "Extremely Verboten");
        factoryAddress = _newFactory;
    }

    function changeUberOwner(address _newUberOwner) external {
        require(msg.sender == uberOwner, "Extremely Verboten");
        uberOwner = _newUberOwner;
    }







    function deposit(address _user) public payable balancedBooks returns(bool) {
        require(!globalPause, "Deposits are disabled");
        require(msg.value > 0, "Must deposit something");
        require(address(this).balance <= maxContractBalance, "Limit hit");

        deposits[_user] = deposits[_user].add(msg.value);
        totalDeposits = totalDeposits.add(msg.value);
        emit LogDepositIncreased(_user, msg.value);
        emit LogAdjustDeposit(_user, msg.value, true);
        return true;
    }


    function withdrawDeposit(uint256 _dai) external balancedBooks  {
        require(!globalPause, "Withdrawals are disabled");
        require(deposits[msgSender()] > 0, "Nothing to withdraw");
        require(now.sub(lastRentalTime[msgSender()]) > uint256(1 days).div(minRentalDivisor), "Too soon");

        if (_dai > deposits[msgSender()]) {
            _dai = deposits[msgSender()];
        }
        deposits[msgSender()] = deposits[msgSender()].sub(_dai);
        totalDeposits = totalDeposits.sub(_dai);
        address _thisAddressNotPayable = msgSender();
        address payable _recipient = address(uint160(_thisAddressNotPayable));
        (bool _success, ) = _recipient.call.value(_dai)("");
        require(_success, "Transfer failed");
        emit LogDepositWithdrawal(msgSender(), _dai);
        emit LogAdjustDeposit(msgSender(), _dai, false);
    }







    function payRent(address _user, uint256 _dai) external balancedBooks onlyMarkets returns(bool) {
        require(!globalPause, "Rentals are disabled");
        require(!marketPaused[msg.sender], "Rentals are disabled");
        assert(deposits[_user] >= _dai);
        deposits[_user] = deposits[_user].sub(_dai);
        marketPot[msg.sender] = marketPot[msg.sender].add(_dai);
        totalMarketPots = totalMarketPots.add(_dai);
        totalDeposits = totalDeposits.sub(_dai);
        emit LogAdjustDeposit(_user, _dai, false);
        return true;
    }


    function payout(address _user, uint256 _dai) external balancedBooks onlyMarkets returns(bool) {
        assert(marketPot[msg.sender] >= _dai);
        deposits[_user] = deposits[_user].add(_dai);
        marketPot[msg.sender] = marketPot[msg.sender].sub(_dai);
        totalMarketPots = totalMarketPots.sub(_dai);
        totalDeposits = totalDeposits.add(_dai);
        emit LogAdjustDeposit(_user, _dai, true);
        return true;
    }


    function sponsor() external payable balancedBooks onlyMarkets returns(bool) {
        marketPot[msg.sender] = marketPot[msg.sender].add(msg.value);
        totalMarketPots = totalMarketPots.add(msg.value);
        return true;
    }


    function processHarbergerPayment(address _newOwner, address _currentOwner, uint256 _requiredPayment) external balancedBooks onlyMarkets returns(bool) {
        require(deposits[_newOwner] >= _requiredPayment, "Insufficient deposit");
        deposits[_newOwner] = deposits[_newOwner].sub(_requiredPayment);
        deposits[_currentOwner] = deposits[_currentOwner].add(_requiredPayment);
        emit LogAdjustDeposit(_newOwner, _requiredPayment, false);
        emit LogAdjustDeposit(_currentOwner, _requiredPayment, true);
        emit LogHotPotatoPayment(_newOwner, _currentOwner, _requiredPayment);
        return true;
    }


    function updateLastRentalTime(address _user) external onlyMarkets returns(bool) {
        lastRentalTime[_user] = now;
        return true;
    }


    function updateTotalRental(address _user, uint256 _newPrice, bool _add) external onlyMarkets returns(bool) {
        if (_add) {
            userTotalRentals[_user] = userTotalRentals[_user].add(_newPrice);
        } else {
            userTotalRentals[_user] = userTotalRentals[_user].sub(_newPrice);
        }
        return true;
    }






    function() external payable {
        assert(deposit(msgSender()));
    }

}
