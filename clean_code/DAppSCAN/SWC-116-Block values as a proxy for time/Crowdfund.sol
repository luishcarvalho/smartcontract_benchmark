pragma solidity 0.4.24;

import "./library/SafeMath.sol";
import "./library/CanReclaimToken.sol";
import "./library/NonZero.sol";
import "./Token.sol";


contract Crowdfund is NonZero, CanReclaimToken {

    using SafeMath for uint;




    uint256 public weiRaised = 0;

    uint256 public startsAt;

    uint256 public endsAt;

    Token public token;

    bool public isActivated = false;

    bool public crowdfundFinalized = false;




    address public wallet;

    address public forwardTokensTo;

    uint256 public crowdfundLength;

    bool public withWhitelist;



    struct Rate {
        uint256 price;
        uint256 amountOfDays;
    }


    Rate[] public rates;

    mapping (address => bool) public whitelist;





    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);




    modifier duringCrowdfund() {
        require(now >= startsAt && now <= endsAt, "time must be greater than start but less than end");
        _;
    }


    modifier onlyAfterCrowdfund() {
        require(endsAt > 0, "crowdfund end time must be greater than 0");
        require(now > endsAt || getCrowdFundAllocation() == 0, "current time must be greater than 0 or there must be 0 tokens left");
        _;
    }




    modifier onlyBeforeCrowdfund() {
        require(now <= startsAt, "time must be less than or equal to start time");
        _;
    }


    modifier isWhitelisted(address _beneficiary) {
        if (withWhitelist == true) {
            require(whitelist[_beneficiary], "address must be whitelisted");
        }
        _;
    }
















    constructor(
        address _owner,
        uint256[] memory _epochs,
        uint256[] memory _prices,
        address _wallet,
        address _forwardTokensTo,
        uint256 _totalDays,
        uint256 _totalSupply,
        bool _withWhitelist,
        address[] memory _allocAddresses,
        uint256[] memory _allocBalances,
        uint256[] memory _timelocks
        ) public {


        owner = _owner;

        withWhitelist = _withWhitelist;

        wallet = _wallet;

        forwardTokensTo = _forwardTokensTo;

        crowdfundLength = _totalDays.mul(1 days);


        require(_epochs.length == _prices.length && _prices.length <= 10, "array lengths must be equal and at most 10 elements");


        uint256 totalAmountOfDays = 0;

        for (uint8 i = 0; i < _epochs.length; i++) {
            totalAmountOfDays = totalAmountOfDays.add(_epochs[i]);
            rates.push(Rate(_prices[i], totalAmountOfDays));


        }

        assert(totalAmountOfDays == _totalDays);


        token = new Token(owner, _totalSupply, _allocAddresses, _allocBalances, _timelocks);

    }





    function scheduleCrowdfund(uint256 _startDate) external onlyOwner returns(bool) {

        require(isActivated == false);
        startsAt = _startDate;

        if (!token.changeCrowdfundStartTime(startsAt)) {
            revert();
        }
        endsAt = startsAt.add(crowdfundLength);
        isActivated = true;
        assert(startsAt >= now && endsAt > startsAt);
        return true;
    }






    function reScheduleCrowdfund(uint256 _startDate) external onlyOwner returns(bool) {

        require(now < startsAt.sub(4 hours) && isActivated == true, "must be 4 hours less than start and must be activated");
        startsAt = _startDate;

        if (!token.changeCrowdfundStartTime(startsAt)) {
            revert();
        }
        endsAt = startsAt.add(crowdfundLength);
        assert(startsAt >= now && endsAt > startsAt);
        return true;
    }





    function changeWalletAddress(address _wallet) external onlyOwner nonZeroAddress(_wallet) {
        wallet = _wallet;
    }





    function changeForwardAddress(address _forwardTokensTo) external onlyOwner {
        forwardTokensTo = _forwardTokensTo;
    }





    function buyTokens(address _to) public payable duringCrowdfund nonZeroAddress(_to) nonZeroValue isWhitelisted(msg.sender)  {
        uint256 weiAmount = msg.value;

        uint256 tokens = weiAmount.mul(getRate());
        weiRaised = weiRaised.add(weiAmount);

        wallet.transfer(weiAmount);

        if (!token.moveAllocation(_to, tokens)) {
            revert("failed to move allocation");
        }
        emit TokenPurchase(_to, weiAmount, tokens);
    }





    function closeCrowdfund() external onlyAfterCrowdfund onlyOwner returns (bool success) {
        require(crowdfundFinalized == false, "crowdfund must not be finalized");
        uint256 amount = getCrowdFundAllocation();
        if (amount > 0) {

            if (!token.moveAllocation(forwardTokensTo, amount)) {
                revert("failed to move allocation");
            }
        }

        if (!token.unlockTokens()) {
            revert("failed to move allocation");
        }
        crowdfundFinalized = true;
        return true;
    }







    function deliverPresaleTokens(
        address[] _batchOfAddresses,
        uint256[] _amountOfTokens)
        external
        onlyBeforeCrowdfund
        onlyOwner returns (bool success) {
        require(_batchOfAddresses.length == _amountOfTokens.length, "array lengths must be equal");
        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            if (!token.moveAllocation(_batchOfAddresses[i], _amountOfTokens[i])) {
                revert("failed to move allocation");
            }
        }
        return true;
    }



    function kill() external onlyOwner {
        uint256 amount = getCrowdFundAllocation();
        require(crowdfundFinalized == true && amount == 0, "crowdfund must be finalized and there must be 0 tokens remaining");

        selfdestruct(owner);
    }





    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
    }






    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }





    function removeManyFromWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = false;
        }
    }





    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
    }




    function () external payable {
        buyTokens(msg.sender);
    }







    function getRate() public view returns (uint) {

        uint256 daysPassed = (now.sub(startsAt)).div(1 days);

        for (uint8 i = 0; i < rates.length; i++) {

            if (daysPassed < rates[i].amountOfDays) {
                return rates[i].price;
            }
        }

        return 0;
    }





    function getCrowdFundAllocation() public view returns (uint256 allocation) {
        (allocation, ) = token.allocations(this);
    }

}

