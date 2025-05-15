
pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/drafts/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";
import "@openzeppelin/contracts/lifecycle/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

contract BCubePublicSale is WhitelistedRole, ReentrancyGuard {
  using SafeMath for uint256;
  using SignedSafeMath for int256;
  using SafeCast for uint256;
  using SafeERC20 for IERC20;









  struct UserInfo {
    uint256 dollarUnitsPayed;
    uint256 allocatedBcubePrivateAllocation;
    uint256 allocatedBcubePrivateRound;
    uint256 allocatedBcubePublicRound;
    uint256 currentAllowance;
    uint256 shareWithdrawn;
  }

  modifier onlyWhitelisted() {
    require(
      isWhitelisted(_msgSender()) || privateSaleWhitelisted.isWhitelisted(_msgSender()),
      "BCubePublicSale: caller does not have the Whitelisted role"
    );
    _;
  }

  modifier onlyWhileOpen {
    require(isOpen(), "BCubePublicSale: not open");
    _;
  }


  modifier tokensRemaining() {
    require(
      netSoldBcube < currentHardcap(),
      "BCubePublicSale: All tokens sold"
    );
    _;
  }

  mapping(address => UserInfo) public bcubeAllocationRegistry;


  AggregatorV3Interface internal priceFeedETH;
  AggregatorV3Interface internal priceFeedUSDT;


  WhitelistedRole internal privateSaleWhitelisted;

  IERC20 public usdt;

  uint256 public openingTime;
  uint256 public closingTime;

  uint256 public constant HARD_CAP               = 15_000_000e18;
  uint256 public constant PRIVATE_ALLOCATION_CAP =  6666666666666666666666667;
  uint256 public constant PUBLIC_LAUNCHPAD_CAP   =  2_250_000e18;


  uint256 public minContributionDollarUnits = 500e8;

  uint256 public maxContributionDollarUnits = 50000e8;

  uint256 public netSoldBcube;
  uint256 public netPrivateAllocatedBcube;
  uint256 public launchpadReservedBcube = PUBLIC_LAUNCHPAD_CAP;


  address payable private wallet;

  event LogEtherReceived(address indexed sender, uint256 value);
  event LogBcubeBuyUsingEth(
    address indexed buyer,
    uint256 incomingWei,
    uint256 allocation
  );
  event LogBcubeBuyUsingUsdt(
      address indexed buyer,
      uint256 incomingUsdtUnits,
      uint256 allocation
  );
  event LogETHPriceFeedChange(address indexed newChainlinkETHPriceFeed);
  event LogUSDTPriceFeedChange(address indexed newChainlinkUSDTPriceFeed);
  event LogUSDTInstanceChange(address indexed newUsdtContract);
  event LogPublicSaleTimeExtension(
    uint256 previousClosingTime,
    uint256 newClosingTime
  );
  event LogPrivateAllocationChanged(
    address wallet,
    uint256 newAllocation
  );
  event LogLaunchpadReserveChanged(uint256 newReserve);
  event LogLimitChanged(uint256 _newMin, uint256 _newMax);










  constructor(
    uint256 _openingTime,
    uint256 _closingTime,
    address _chainlinkETHPriceFeed,
    address _chainlinkUSDTPriceFeed,
    address _usdtContract,
    address _privateSale,
    address payable _wallet
  )
    public WhitelistedRole()
  {
    openingTime = _openingTime;
    closingTime = _closingTime;
    priceFeedETH = AggregatorV3Interface(_chainlinkETHPriceFeed);
    priceFeedUSDT = AggregatorV3Interface(_chainlinkUSDTPriceFeed);
    usdt = IERC20(_usdtContract);
    privateSaleWhitelisted = WhitelistedRole(_privateSale);
    wallet = _wallet;
  }

  function setAdmin(address _admin) public onlyWhitelistAdmin {

    addWhitelistAdmin(_admin);
    renounceWhitelistAdmin();
  }

  function setContributionsLimits(uint256 _min, uint256 _max) public onlyWhitelistAdmin {
    minContributionDollarUnits = _min;
    maxContributionDollarUnits = _max;
    emit LogLimitChanged(_min, _max);
  }

  function() external payable {
    emit LogEtherReceived(_msgSender(), msg.value);
  }



  function isOpen() public view returns (bool) {

      return block.timestamp >= openingTime && block.timestamp <= closingTime;
  }

  function currentHardcap() public view returns (uint256) {
    return HARD_CAP.sub(PRIVATE_ALLOCATION_CAP).sub(launchpadReservedBcube);
  }


  function setPrivateAllocation(address _wallet, uint256 _allocation)
    external
    onlyWhitelistAdmin {
    require(block.timestamp <= closingTime, "BCubePublicSale: sale is closed");
    uint256 _previousAllocation = bcubeAllocationRegistry[_wallet].allocatedBcubePrivateAllocation;
    uint256 _newPrivateAllocation = netPrivateAllocatedBcube.sub(_previousAllocation).add(_allocation);
    require(
      _newPrivateAllocation <= PRIVATE_ALLOCATION_CAP,
      "BCubePublicSale: private allocation exceed PRIVATE_ALLOCATION_CAP"
    );
    netPrivateAllocatedBcube = _newPrivateAllocation;
    bcubeAllocationRegistry[_wallet].allocatedBcubePrivateAllocation = _allocation;
    emit LogPrivateAllocationChanged(_wallet, _allocation);
  }

  function decreaseLaunchpadReservedBcube(uint256 _newReserve)
    external
    onlyWhitelistAdmin
    onlyWhileOpen {
    require(_newReserve <= launchpadReservedBcube, "BCubePublicSale: new reserve can only be decreased");
    require(_newReserve >= 0, "BCubePublicSale: new reserve MUST BE >= 0");
    launchpadReservedBcube = _newReserve;
    emit LogLaunchpadReserveChanged(_newReserve);
  }

  function calcRate() private view returns (uint256, uint8) {




    if (netSoldBcube < 1333333333333333333333333) {
      return (66666666666, 1);
    } else {
      return (5e10, 2);
    }
  }


  function setETHPriceFeed(address _newChainlinkETHPriceFeed)
    external
    onlyWhitelistAdmin
  {
    priceFeedETH = AggregatorV3Interface(_newChainlinkETHPriceFeed);
    emit LogETHPriceFeedChange(_newChainlinkETHPriceFeed);
  }


  function setUSDTPriceFeed(address _newChainlinkUSDTPriceFeed)
    external
    onlyWhitelistAdmin
  {
    priceFeedUSDT = AggregatorV3Interface(_newChainlinkUSDTPriceFeed);
    emit LogUSDTPriceFeedChange(_newChainlinkUSDTPriceFeed);
  }


  function setUSDTInstance(address _newUsdtContract)
    external
    onlyWhitelistAdmin
  {
    usdt = IERC20(_newUsdtContract);
    emit LogUSDTInstanceChange(_newUsdtContract);
  }


  function extendClosingTime(uint256 _newClosingTime)
    external
    onlyWhitelistAdmin
  {
    emit LogPublicSaleTimeExtension(closingTime, _newClosingTime);
    closingTime = _newClosingTime;
  }





  function buyBcubeUsingETH()
    external
    payable
    onlyWhitelisted
    onlyWhileOpen
    tokensRemaining
    nonReentrant
  {
    uint256 allocation;
    uint256 ethPrice = uint256(fetchETHPrice());
    uint256 dollarUnits = ethPrice.mul(msg.value).div(1e18);
    allocation = executeAllocation(dollarUnits);
    wallet.transfer(msg.value);

    emit LogBcubeBuyUsingEth(_msgSender(), msg.value, allocation);
  }




  function buyBcubeUsingUSDT(uint256 incomingUsdt)
    external
    onlyWhitelisted
    onlyWhileOpen
    tokensRemaining
    nonReentrant
  {
    uint256 allocation;
    uint256 usdtPrice = uint256(fetchUSDTPrice());
    uint256 dollarUnits = usdtPrice.mul(incomingUsdt).div(1e6);
    allocation = executeAllocation(dollarUnits);
    usdt.safeTransferFrom(_msgSender(), wallet, incomingUsdt);

    emit LogBcubeBuyUsingUsdt(_msgSender(), incomingUsdt, allocation);
  }











  function executeAllocation(uint256 dollarUnits) private returns (uint256) {
    uint256 finalAllocation;
    uint256 bcubeAllocatedToUser;
    uint256 rate;
    uint8 stage;
    uint256 stageCap;
    uint256 a1;
    uint256 a2;
    uint256 dollarUnitsUnused;
    uint256 totalContribution = bcubeAllocationRegistry[_msgSender()]
      .dollarUnitsPayed
      .add(dollarUnits);
    require(
      totalContribution >= minContributionDollarUnits,
      "BCubePublicSale: Minimum contribution not reached."
    );
    require(
      totalContribution <= maxContributionDollarUnits,
      "BCubePublicSale: Maximum contribution exceeded"
    );
    (rate, stage) = calcRate();
    uint256 current_hardcap = currentHardcap();
    if (stage == 1) {
      stageCap = 1333333333333333333333333;
    } else {
      stageCap = current_hardcap;
    }
    bcubeAllocatedToUser = rate.mul(dollarUnits);
    finalAllocation = netSoldBcube.add(bcubeAllocatedToUser);
    require(finalAllocation <= current_hardcap, "BCubePublicSale: Hard cap exceeded");
    bcubeAllocationRegistry[_msgSender()].dollarUnitsPayed = totalContribution;
    if (finalAllocation <= stageCap) {
      netSoldBcube = finalAllocation;
      if (stage == 1) {
        bcubeAllocationRegistry[_msgSender()].allocatedBcubePrivateRound = bcubeAllocationRegistry[_msgSender()]
          .allocatedBcubePrivateRound
          .add(bcubeAllocatedToUser);
      } else {
        bcubeAllocationRegistry[_msgSender()].allocatedBcubePublicRound = bcubeAllocationRegistry[_msgSender()]
          .allocatedBcubePublicRound
          .add(bcubeAllocatedToUser);
      }
      return bcubeAllocatedToUser;
    } else {
      uint256 total;
      a1 = stageCap.sub(netSoldBcube);
      dollarUnitsUnused = dollarUnits.sub(a1.div(rate));
      netSoldBcube = stageCap;
      bcubeAllocationRegistry[_msgSender()].allocatedBcubePrivateRound = bcubeAllocationRegistry[_msgSender()]
        .allocatedBcubePrivateRound
        .add(a1);
      (rate, stage) = calcRate();
      a2 = dollarUnitsUnused.mul(rate);
      netSoldBcube = netSoldBcube.add(a2);
      total = a1.add(a2);
      bcubeAllocationRegistry[_msgSender()].allocatedBcubePublicRound = bcubeAllocationRegistry[_msgSender()]
        .allocatedBcubePublicRound
        .add(a2);
      return total;
    }
  }


  function fetchETHPrice() public view returns (uint256) {
    (, int256 price, , , ) = priceFeedETH.latestRoundData();
    return toUint256(price);
  }


  function fetchUSDTPrice() public view returns (uint256) {
    (, int256 price, , , ) = priceFeedUSDT.latestRoundData();
    uint256 ethUSD = fetchETHPrice();
    return toUint256(price).mul(ethUSD).div(1e18);
  }

  function toUint256(int256 value) internal pure returns (uint256) {
    require(value >= 0, "SafeCast: value must be positive");
    return uint256(value);
  }

}
