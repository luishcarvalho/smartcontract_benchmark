pragma solidity 0.8.6;




















import "../Interfaces/Interfaces.sol";
import "../Interfaces/IOptionsManager.sol";
import "../Interfaces/Interfaces.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";










abstract contract HegicPool is IHegicPool, ERC721, AccessControl {
    using SafeERC20 for IERC20;

    uint256 public constant INITIAL_RATE = 1e20;
    IOptionsManager public immutable optionsManager;
    AggregatorV3Interface public immutable priceProvider;
    IPriceCalculator public override pricer;
    uint256 public lockupPeriodForHedgedTranches = 60 days;
    uint256 public lockupPeriodForUnhedgedTranches = 30 days;
    uint256 public hedgeFeeRate = 80;
    uint256 public maxUtilizationRate = 80;
    uint256 public collateralizationRatio = 50;
    uint256 public override lockedAmount;
    uint256 public maxDepositAmount = type(uint256).max;
    uint256 public maxHedgedDepositAmount = type(uint256).max;

    uint256 public unhedgedShare = 0;
    uint256 public hedgedShare = 0;
    uint256 public override unhedgedBalance = 0;
    uint256 public override hedgedBalance = 0;
    IHegicStaking public settlementFeeRecipient;
    address public hedgePool;

    Tranche[] public override tranches;
    mapping(uint256 => Option) public override options;
    IERC20 public override token;

    constructor(
        IERC20 _token,
        string memory name,
        string memory symbol,
        IOptionsManager manager,
        IPriceCalculator _pricer,
        IHegicStaking _settlementFeeRecipient,
        AggregatorV3Interface _priceProvider
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        priceProvider = _priceProvider;
        settlementFeeRecipient = _settlementFeeRecipient;
        pricer = _pricer;
        token = _token;
        hedgePool = _msgSender();
        optionsManager = manager;
        approve();
    }









    function setLockupPeriod(uint256 hedgedValue, uint256 unhedgedValue)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            hedgedValue <= 60 days,
            "The lockup period for hedged tranches is too long"
        );
        require(
            unhedgedValue <= 30 days,
            "The lockup period for unhedged tranches is too long"
        );
        lockupPeriodForHedgedTranches = hedgedValue;
        lockupPeriodForUnhedgedTranches = unhedgedValue;
    }











    function setMaxDepositAmount(uint256 total, uint256 hedged)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            total >= hedged,
            "Pool Error: The total amount shouldn't be lower than the hedged amount"
        );
        maxDepositAmount = total;
        maxHedgedDepositAmount = hedged;
    }











    function setMaxUtilizationRate(uint256 value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            50 <= value && value <= 100,
            "Pool error: Wrong utilization rate limitation value"
        );
        maxUtilizationRate = value;
    }














    function setCollateralizationRatio(uint256 value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            30 <= value && value <= 100,
            "Pool Error: Wrong collateralization ratio value"
        );
        collateralizationRatio = value;
    }





    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IHegicPool).interfaceId ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }







    function approve() public {
        token.approve(address(settlementFeeRecipient), type(uint256).max);
    }







    function setHedgePool(address value)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(value != address(0));
        hedgePool = value;
    }












    function sellOption(
        address holder,
        uint256 period,
        uint256 amount,
        uint256 strike
    ) external override returns (uint256 id) {
        if (strike == 0) strike = _currentPrice();
        uint256 balance = totalBalance();
        uint256 amountToBeLocked = _calculateLockedAmount(amount);

        require(period >= 1 days, "Pool Error: The period is too short");
        require(period <= 90 days, "Pool Error: The period is too long");
        require(
            (lockedAmount + amountToBeLocked) * 100 <=
                balance * maxUtilizationRate,
            "Pool Error: The amount is too large"
        );

        (uint256 settlementFee, uint256 premium) =
            _calculateTotalPremium(period, amount, strike);
        uint256 hedgedPremiumTotal = (premium * hedgedBalance) / balance;
        uint256 hedgeFee = (hedgedPremiumTotal * hedgeFeeRate) / 100;
        uint256 hedgePremium = hedgedPremiumTotal - hedgeFee;
        uint256 unhedgePremium = premium - hedgedPremiumTotal;

        lockedAmount += amountToBeLocked;
        id = optionsManager.createOptionFor(holder);
        options[id] = Option(
            OptionState.Active,
            strike,
            amount,
            amountToBeLocked,
            block.timestamp,
            block.timestamp + period,
            hedgePremium,
            unhedgePremium
        );

        token.safeTransferFrom(
            _msgSender(),
            address(this),
            premium + settlementFee
        );

        settlementFeeRecipient.sendProfits(settlementFee);
        if (hedgeFee > 0) token.safeTransfer(hedgePool, hedgeFee);
        emit Acquired(id, settlementFee, premium);
    }






    function setPriceCalculator(IPriceCalculator pc)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pricer = pc;
    }







    function exercise(uint256 id) external override {
        Option storage option = options[id];
        uint256 profit = _profitOf(option);
        require(
            optionsManager.isApprovedOrOwner(_msgSender(), id),
            "Pool Error: msg.sender can't exercise this option"
        );
        require(
            option.expired > block.timestamp,
            "Pool Error: The option has already expired"
        );
        require(
            profit > 0,
            "Pool Error: There are no unrealized profits for this option"
        );
        _unlock(option);
        option.state = OptionState.Exercised;
        _send(optionsManager.ownerOf(id), profit);
        emit Exercised(id, profit);
    }

    function _send(address to, uint256 transferAmount) private {
        require(to != address(0));
        uint256 hedgeLoss = (transferAmount * hedgedBalance) / totalBalance();
        uint256 unhedgeLoss = transferAmount - hedgeLoss;
        hedgedBalance -= hedgeLoss;
        unhedgedBalance -= unhedgeLoss;
        token.safeTransfer(to, transferAmount);
    }










    function unlock(uint256 id) external override {
        Option storage option = options[id];
        require(
            option.expired < block.timestamp,
            "Pool Error: The option has not expired yet"
        );
        _unlock(option);
        option.state = OptionState.Expired;
        emit Expired(id);
    }

    function _unlock(Option storage option) internal {
        require(
            option.state == OptionState.Active,
            "Pool Error: The option with such an ID has already been exercised or expired"
        );
        lockedAmount -= option.lockedAmount;
        hedgedBalance += option.hedgePremium;
        unhedgedBalance += option.unhedgePremium;
    }

    function _calculateLockedAmount(uint256 amount)
        internal
        virtual
        returns (uint256)
    {
        return (amount * collateralizationRatio) / 100;
    }












    function provideFrom(
        address account,
        uint256 amount,
        bool hedged,
        uint256 minShare
    ) external override returns (uint256 share) {
        uint256 totalShare = hedged ? hedgedShare : unhedgedShare;
        uint256 balance = hedged ? hedgedBalance : unhedgedBalance;
        share = totalShare > 0 && balance > 0
            ? (amount * totalShare) / balance
            : amount * INITIAL_RATE;
        uint256 limit =
            hedged
                ? maxHedgedDepositAmount - hedgedBalance
                : maxDepositAmount - hedgedBalance - unhedgedBalance;
        require(share >= minShare, "Pool Error: The mint limit is too large");
        require(share > 0, "Pool Error: The amount is too small");
        require(
            amount <= limit,
            "Pool Error: Depositing into the pool is not available"
        );

        if (hedged) {
            hedgedShare += share;
            hedgedBalance += amount;
        } else {
            unhedgedShare += share;
            unhedgedBalance += amount;
        }

        uint256 trancheID = tranches.length;
        tranches.push(
            Tranche(TrancheState.Open, share, amount, block.timestamp, hedged)
        );
        _safeMint(account, trancheID);
        token.safeTransferFrom(_msgSender(), address(this), amount);
    }









    function withdraw(uint256 trancheID)
        external
        override
        returns (uint256 amount)
    {
        address owner = ownerOf(trancheID);
        Tranche memory t = tranches[trancheID];
        amount = _withdraw(owner, trancheID);
        if (t.hedged && amount < t.amount) {
            token.safeTransferFrom(hedgePool, owner, t.amount - amount);
            amount = t.amount;
        }
        emit Withdrawn(owner, trancheID, amount);
    }











    function withdrawWithoutHedge(uint256 trancheID)
        external
        override
        returns (uint256 amount)
    {
        address owner = ownerOf(trancheID);
        amount = _withdraw(owner, trancheID);
        emit Withdrawn(owner, trancheID, amount);
    }

    function _withdraw(address owner, uint256 trancheID)
        internal
        returns (uint256 amount)
    {
        Tranche storage t = tranches[trancheID];
        uint256 lockupPeriod =
            t.hedged
                ? lockupPeriodForHedgedTranches
                : lockupPeriodForUnhedgedTranches;
        require(t.state == TrancheState.Open);
        require(_isApprovedOrOwner(_msgSender(), trancheID));
        require(
            block.timestamp > t.creationTimestamp + lockupPeriod,
            "Pool Error: The withdrawal is locked up"
        );

        t.state = TrancheState.Closed;
        if (t.hedged) {
            amount = (t.share * hedgedBalance) / hedgedShare;
            hedgedShare -= t.share;
            hedgedBalance -= amount;
        } else {
            amount = (t.share * unhedgedBalance) / unhedgedShare;
            unhedgedShare -= t.share;
            unhedgedBalance -= amount;
        }

        token.safeTransfer(owner, amount);
    }




    function availableBalance() public view returns (uint256 balance) {
        return totalBalance() - lockedAmount;
    }




    function totalBalance() public view override returns (uint256 balance) {
        return hedgedBalance + unhedgedBalance;
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256 id
    ) internal view override {
        require(
            tranches[id].state == TrancheState.Open,
            "Pool Error: The closed tranches can not be transferred"
        );
    }







    function profitOf(uint256 id) external view returns (uint256) {
        return _profitOf(options[id]);
    }

    function _profitOf(Option memory option)
        internal
        view
        virtual
        returns (uint256 amount);










    function calculateTotalPremium(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) external view override returns (uint256 settlementFee, uint256 premium) {
        return _calculateTotalPremium(period, amount, strike);
    }

    function _calculateTotalPremium(
        uint256 period,
        uint256 amount,
        uint256 strike
    ) internal view virtual returns (uint256 settlementFee, uint256 premium) {
        (settlementFee, premium) = pricer.calculateTotalPremium(
            period,
            amount,
            strike
        );
        require(
            settlementFee + premium > amount / 1000,
            "HegicPool: The option's price is too low"
        );
    }







    function setSettlementFeeRecipient(IHegicStaking recipient)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(address(recipient) != address(0));
        settlementFeeRecipient = recipient;
    }

    function _currentPrice() internal view returns (uint256 price) {
        (, int256 latestPrice, , , ) = priceProvider.latestRoundData();
        price = uint256(latestPrice);
    }
}
