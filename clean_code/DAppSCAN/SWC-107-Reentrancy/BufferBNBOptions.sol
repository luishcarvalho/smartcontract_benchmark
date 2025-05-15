pragma solidity ^0.8.0;




















import "../Pool/BufferBNBPool.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";






contract BufferBNBOptions is
    IBufferOptions,
    Ownable,
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl
{
    uint256 public nextTokenId = 0;

    IBufferStakingBNB public settlementFeeRecipient;
    mapping(uint256 => Option) public options;
    uint256 public impliedVolRate;
    uint256 public optionCollateralizationRatio = 100;
    uint256 public settlementFeePercentage = 4;
    uint256 public stakingFeePercentage = 75;
    uint256 public referralRewardPercentage = 50;
    uint256 internal constant PRICE_DECIMALS = 1e8;
    uint256 internal contractCreationTimestamp;
    bool internal migrationProcess = true;
    AggregatorV3Interface public priceProvider;
    BufferBNBPool public pool;




    constructor(
        AggregatorV3Interface pp,
        IBufferStakingBNB staking,
        BufferBNBPool _pool
    ) ERC721("Buffer", "BFR") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        pool = _pool;
        priceProvider = pp;
        settlementFeeRecipient = staking;
        impliedVolRate = 4500;
        contractCreationTimestamp = block.timestamp;
    }





    function setImpliedVolRate(uint256 value) external onlyOwner {
        require(value >= 1000, "ImpliedVolRate limit is too small");
        impliedVolRate = value;
    }





    function setSettlementFeePercentage(uint256 value) external onlyOwner {
        require(value < 20, "SettlementFeePercentage is too high");
        settlementFeePercentage = value;
    }





    function setSettlementFeeRecipient(IBufferStakingBNB recipient)
        external
        onlyOwner
    {
        require(address(recipient) != address(0));
        settlementFeeRecipient = recipient;
    }





    function setStakingFeePercentage(uint256 value) external onlyOwner {
        require(value <= 100, "StakingFeePercentage is too high");
        stakingFeePercentage = value;
    }





    function setReferralRewardPercentage(uint256 value) external onlyOwner {
        require(value <= 100, "ReferralRewardPercentage is too high");
        referralRewardPercentage = value;
    }





    function setOptionCollaterizationRatio(uint256 value) external onlyOwner {
        require(50 <= value && value <= 100, "wrong value");
        optionCollateralizationRatio = value;
    }










    function create(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionType optionType,
        address referrer
    ) external payable returns (uint256 optionID) {
        (uint256 totalFee, uint256 settlementFee, uint256 strikeFee, ) = fees(
            period,
            amount,
            strike,
            optionType
        );

        require(
            optionType == OptionType.Call || optionType == OptionType.Put,
            "Wrong option type"
        );
        require(period >= 1 days, "Period is too short");
        require(period <= 90 days, "Period is too long");
        require(amount > strikeFee, "Price difference is too large");
        require(msg.value >= totalFee, "Wrong value");
        if (msg.value > totalFee) {
            payable(msg.sender).transfer(msg.value - totalFee);
        }

        uint256 strikeAmount = amount - strikeFee;
        uint256 lockedAmount = ((strikeAmount * optionCollateralizationRatio) / 100) + strikeFee;

        Option memory option = Option(
            State.Active,
            strike,
            amount,
            lockedAmount,
            totalFee - settlementFee,
            block.timestamp + period,
            optionType
        );

        optionID = createOptionFor(msg.sender);
        options[optionID] = option;

        uint256 stakingAmount = distributeSettlementFee(settlementFee, referrer);

        pool.lock{value: option.premium}(optionID, option.lockedAmount);

        emit Create(optionID, msg.sender, stakingAmount, totalFee);
    }





    function canExercise(uint256 optionID) internal view returns (bool){
        require(_exists(optionID), "ERC721: operator query for nonexistent token");

        address tokenOwner = ERC721.ownerOf(optionID);
        bool isAutoExerciseTrue = autoExerciseStatus[tokenOwner] && msg.sender == owner();

        Option storage option = options[optionID];
        bool isWithinLastHalfHourOfExpiry = block.timestamp > (option.expiration - 30 minutes);

        return (tokenOwner == msg.sender) || (isAutoExerciseTrue && isWithinLastHalfHourOfExpiry);
    }





    function exercise(uint256 optionID) external {
        require(
            canExercise(optionID),
            "msg.sender is not eligible to exercise the option"
        );

        Option storage option = options[optionID];

        require(option.expiration >= block.timestamp, "Option has expired");
        require(option.state == State.Active, "Wrong state");

        option.state = State.Exercised;
        uint256 profit = payProfit(optionID);


        _burn(optionID);

        emit Exercise(optionID, profit);
    }





    function unlockAll(uint256[] calldata optionIDs) external {
        uint256 arrayLength = optionIDs.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            unlock(optionIDs[i]);
        }
    }





    function unlock(uint256 optionID) public {
        Option storage option = options[optionID];
        require(
            option.expiration < block.timestamp,
            "Option has not expired yet"
        );
        require(option.state == State.Active, "Option is not active");
        option.state = State.Expired;
        pool.unlock(optionID);


        _burn(optionID);

        emit Expire(optionID, option.premium);
    }





    function payProfit(uint256 optionID) internal returns (uint256 profit) {
        Option memory option = options[optionID];
        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        uint256 currentPrice = uint256(latestPrice);
        if (option.optionType == OptionType.Call) {
            require(option.strike <= currentPrice, "Current price is too low");
            profit =
                ((currentPrice - option.strike) * option.amount) /
                currentPrice;
        } else {
            require(option.strike >= currentPrice, "Current price is too high");
            profit =
                ((option.strike - currentPrice) * option.amount) /
                currentPrice;
        }

        pool.send(optionID, payable(ownerOf(optionID)), profit);
    }


    function distributeSettlementFee(uint256 settlementFee, address referrer) internal returns (uint256 stakingAmount){
        stakingAmount = ((settlementFee * stakingFeePercentage) / 100);


        if(stakingAmount > 0){
            settlementFeeRecipient.sendProfit{value: stakingAmount}();
        }

        uint256 adminFee = settlementFee - stakingAmount;

        if(adminFee > 0){
            if(referralRewardPercentage > 0 && referrer != owner() && referrer != msg.sender){
                uint256 referralReward = (adminFee * referralRewardPercentage)/100;
                adminFee = adminFee - referralReward;
                payable(referrer).transfer(referralReward);
            }
            payable(owner()).transfer(adminFee);
        }
    }











    function fees(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionType optionType
    )
        public
        view
        returns (
            uint256 total,
            uint256 settlementFee,
            uint256 strikeFee,
            uint256 periodFee
        )
    {
        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        uint256 currentPrice = uint256(latestPrice);
        settlementFee = getSettlementFee(amount);
        periodFee = getPeriodFee(
            amount,
            period,
            strike,
            currentPrice,
            optionType
        );
        strikeFee = getStrikeFee(amount, strike, currentPrice, optionType);
        total = periodFee + strikeFee + settlementFee;
    }

















    function getPeriodFee(
        uint256 amount,
        uint256 period,
        uint256 strike,
        uint256 currentPrice,
        OptionType optionType
    ) internal view returns (uint256 fee) {
        if (optionType == OptionType.Put)
            return
                (amount * sqrt(period) * impliedVolRate * strike) /
                (currentPrice * PRICE_DECIMALS);
        else
            return
                (amount * sqrt(period) * impliedVolRate * currentPrice) /
                (strike * PRICE_DECIMALS);
    }








    function getStrikeFee(
        uint256 amount,
        uint256 strike,
        uint256 currentPrice,
        OptionType optionType
    ) internal pure returns (uint256 fee) {
        if (strike > currentPrice && optionType == OptionType.Put)
            return ((strike - currentPrice) * amount) / currentPrice;
        if (strike < currentPrice && optionType == OptionType.Call)
            return ((currentPrice - strike) * amount) / currentPrice;
        return 0;
    }






    function getSettlementFee(uint256 amount)
        internal
        view
        returns (uint256 fee)
    {
        return (amount * settlementFeePercentage) / 100;
    }





    function createOptionFor(address holder) internal returns (uint256 id) {
        id = nextTokenId++;
        _safeMint(holder, id);
    }




    function _baseURI() internal pure override returns (string memory) {
        return "https:
    }



    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }




    function sqrt(uint256 x) internal pure returns (uint256 result) {
        result = x;
        uint256 k = (x / 2) + 1;
        while (k < result) (result, k) = (k, ((x / k) + k) / 2);
    }






    mapping(address => bool) public autoExerciseStatus;

    event AutoExerciseStatusChange(address indexed account, bool status);

    function setAutoExerciseStatus(bool status) public {
        autoExerciseStatus[msg.sender] = status;
        emit AutoExerciseStatusChange(msg.sender, status);
    }

}
