
pragma solidity 0.8.7;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interfaces/Decimals.sol';
import './interfaces/INFT.sol';








contract CeloHedgeyOTC is ReentrancyGuard {
  using SafeERC20 for IERC20;


  uint256 public d = 0;

  address public futureContract;

  constructor(address _fc) {
    futureContract = _fc;
  }





















  struct Deal {
    address seller;
    address token;
    address paymentCurrency;
    uint256 remainingAmount;
    uint256 minimumPurchase;
    uint256 price;
    uint256 maturity;
    uint256 unlockDate;
    bool open;
    address buyer;
  }


  mapping(uint256 => Deal) public deals;




















  function create(
    address _token,
    address _paymentCurrency,
    uint256 _amount,
    uint256 _min,
    uint256 _price,
    uint256 _maturity,
    uint256 _unlockDate,
    address _buyer
  ) external {
    require(_maturity > block.timestamp, 'HEC01: Maturity before block timestamp');
    require(_amount >= _min, 'HEC02: Amount less than minium');


    require((_min * _price) / (10**Decimals(_token).decimals()) > 0, 'HEC03: Minimum smaller than 0');

    uint256 currentBalance = IERC20(_token).balanceOf(address(this));

    require(IERC20(_token).balanceOf(msg.sender) >= _amount, 'HECB: Insufficient Balance');
    SafeERC20.safeTransferFrom(IERC20(_token), msg.sender, address(this), _amount);


    uint256 postBalance = IERC20(_token).balanceOf(address(this));
    assert(postBalance - currentBalance == _amount);

    deals[d++] = Deal(
      msg.sender,
      _token,
      _paymentCurrency,
      _amount,
      _min,
      _price,
      _maturity,
      _unlockDate,
      true,
      _buyer
    );
    emit NewDeal(
      d - 1,
      msg.sender,
      _token,
      _paymentCurrency,
      _amount,
      _min,
      _price,
      _maturity,
      _unlockDate,
      true,
      _buyer
    );
  }








  function close(uint256 _d) external nonReentrant {
    Deal storage deal = deals[_d];
    require(msg.sender == deal.seller, 'HEC04: Only Seller Can Close');
    require(deal.remainingAmount > 0, 'HEC05: All tokens have been sold');
    require(deal.open, 'HEC06: Deal has been closed');

    SafeERC20.safeTransfer(IERC20(deal.token), msg.sender, deal.remainingAmount);

    deal.remainingAmount = 0;
    deal.open = false;
    emit DealClosed(_d);
  }











  function buy(uint256 _d, uint256 _amount) external nonReentrant {

    Deal storage deal = deals[_d];

    require(msg.sender != deal.seller, 'HEC07: Buyer cannot be seller');

    require(deal.open && deal.maturity >= block.timestamp, 'HEC06: Deal has been closed');

    require(msg.sender == deal.buyer || deal.buyer == address(0x0), 'HEC08: Whitelist or buyer allowance error');


    require(
      (_amount >= deal.minimumPurchase || _amount == deal.remainingAmount) && deal.remainingAmount >= _amount,
      'HEC09: Insufficient Purchase Size'
    );


    uint256 decimals = Decimals(deal.token).decimals();
    uint256 purchase = (_amount * deal.price) / (10**decimals);

    require(IERC20(deal.paymentCurrency).balanceOf(msg.sender) >= purchase, 'HECB: Insufficient Balance');

    SafeERC20.safeTransferFrom(IERC20(deal.paymentCurrency), msg.sender, deal.seller, purchase);
    if (deal.unlockDate > block.timestamp) {

      _lockTokens(msg.sender, deal.token, _amount, deal.unlockDate);
    } else {

      SafeERC20.safeTransfer(IERC20(deal.token), msg.sender, _amount);
    }

    deal.remainingAmount -= _amount;
    if (deal.remainingAmount == 0) deal.open = false;
    emit TokensBought(_d, _amount, deal.remainingAmount);
  }






  function _lockTokens(
    address _owner,
    address _token,
    uint256 _amount,
    uint256 _unlockDate
  ) internal {
    require(_unlockDate > block.timestamp, 'HEC10: Unlocked');


    uint256 currentBalance = IERC20(_token).balanceOf(futureContract);


    SafeERC20.safeIncreaseAllowance(IERC20(_token), futureContract, _amount);

    INFT(futureContract).createNFT(_owner, _amount, _token, _unlockDate);


    uint256 postBalance = IERC20(_token).balanceOf(futureContract);
    assert(postBalance - currentBalance == _amount);
    emit FutureCreated(_owner, _token, _unlockDate, _amount);
  }


  event NewDeal(
    uint256 _d,
    address _seller,
    address _token,
    address _paymentCurrency,
    uint256 _remainingAmount,
    uint256 _minimumPurchase,
    uint256 _price,
    uint256 _maturity,
    uint256 _unlockDate,
    bool open,
    address _buyer
  );
  event TokensBought(uint256 _d, uint256 _amount, uint256 _remainingAmount);
  event DealClosed(uint256 _d);
  event FutureCreated(address _owner, address _token, uint256 _unlockDate, uint256 _amount);
}
