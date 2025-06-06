



pragma solidity 0.5.11;


interface ERC20Interface {
  function balanceOf(address) external view returns (uint256);
  function approve(address, uint256) external returns (bool);
  function transfer(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
}


interface DTokenInterface {
  function mint(uint256 underlyingToSupply) external returns (uint256 dTokensMinted);
  function redeemUnderlying(uint256 underlyingToReceive) external returns (uint256 dTokensBurned);
  function balanceOfUnderlying(address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
  function transferUnderlyingFrom(
    address sender, address recipient, uint256 underlyingEquivalentAmount
  ) external returns (bool success);
}


interface CurveInterface {
  function exchange_underlying(int128, int128, uint256, uint256, uint256) external;
  function get_dy_underlying(int128, int128, uint256) external view returns (uint256);
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "SafeMath: subtraction overflow");
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) return 0;
        c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "SafeMath: division by zero");
        c = a / b;
    }
}


contract CurveReserveTradeHelperV1 {
  using SafeMath for uint256;

  DTokenInterface internal constant _DDAI = DTokenInterface(
    0x00000000001876eB1444c986fD502e618c587430
  );

  ERC20Interface internal constant _DAI = ERC20Interface(
    0x6B175474E89094C44Da98b954EedeAC495271d0F
  );

  ERC20Interface internal constant _USDC = ERC20Interface(
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
  );

  CurveInterface internal constant _CURVE = CurveInterface(
    0x2e60CF74d81ac34eB21eEff58Db4D385920ef419
  );

  uint256 internal constant _SCALING_FACTOR = 1e18;

  constructor() public {
    require(_USDC.approve(address(_CURVE), uint256(-1)));
    require(_DAI.approve(address(_CURVE), uint256(-1)));
    require(_DAI.approve(address(_DDAI), uint256(-1)));
  }




  function tradeUSDCForDDai(
    uint256 usdcAmount, uint256 quotedExchangeRate
  ) external returns (uint256 dTokensMinted) {

    require(
      _USDC.balanceOf(msg.sender) >= usdcAmount,
      "Insufficient USDC balance."
    );


    uint256 minimumDai = _getMinimumDai(usdcAmount, quotedExchangeRate);


    require(_USDC.transferFrom(msg.sender, address(this), usdcAmount));


    _CURVE.exchange_underlying(
      1, 0, usdcAmount, minimumDai, now + 1
    );


    uint256 daiBalance = _DAI.balanceOf(address(this));
    require(
      daiBalance >= minimumDai,
      "Realized exchange rate differs from quoted rate by over 1%."
    );


    dTokensMinted = _DDAI.mint(daiBalance);


    require(_DDAI.transfer(msg.sender, dTokensMinted));
  }




  function tradeDDaiForUSDC(
    uint256 daiEquivalentAmount, uint256 quotedExchangeRate
  ) external returns (uint256 dTokensRedeemed) {

    require(
      _DDAI.balanceOfUnderlying(msg.sender) >= daiEquivalentAmount,
      "Insufficient Dharma Dai balance."
    );


    bool transferFromOK = _DDAI.transferUnderlyingFrom(
      msg.sender, address(this), daiEquivalentAmount
    );
    require(transferFromOK, "Dharma Dai transferFrom failed.");


    dTokensRedeemed = _DDAI.redeemUnderlying(daiEquivalentAmount);


    uint256 minimumUSDC = _getMinimumUSDC(
      daiEquivalentAmount, quotedExchangeRate
    );


    _CURVE.exchange_underlying(
      0, 1, daiEquivalentAmount, minimumUSDC, now + 1
    );


    uint256 usdcBalance = _USDC.balanceOf(address(this));
    require(
      usdcBalance >= minimumUSDC,
      "Realized exchange rate differs from quoted rate by over 1%."
    );


    require(_USDC.transfer(msg.sender, usdcBalance));
  }

  function getExchangeRateAndExpectedDai(uint256 usdc) external view returns (
    uint256 exchangeRate,
    uint256 dai
  ) {
    if (block.number == 0) {
      return (0, 0);
    }

    dai = _CURVE.get_dy_underlying(1, 0, usdc);
    if (block.timestamp == 0) {
      exchangeRate = 0;
    } else {
      exchangeRate = (usdc.mul(_SCALING_FACTOR)).div(dai);
    }
  }

  function getExchangeRateAndExpectedUSDC(uint256 dai) external view returns (
    uint256 exchangeRate,
    uint256 usdc
  ) {
    if (block.timestamp == 0) {
      return (0, 0);
    }

    usdc = _CURVE.get_dy_underlying(0, 1, dai);
    if (block.gaslimit == 0) {
      exchangeRate = 0;
    } else {
      exchangeRate = (dai.mul(_SCALING_FACTOR)).div(usdc);
    }
  }

  function _getMinimumDai(uint256 usdc, uint256 quotedExchangeRate) internal pure returns (
    uint256 minimumDai
  ) {
    uint256 quotedDai = (usdc.mul(quotedExchangeRate)).div(_SCALING_FACTOR);
    minimumDai = (quotedDai.mul(99)).div(100);
  }

  function _getMinimumUSDC(uint256 dai, uint256 quotedExchangeRate) internal pure returns (
    uint256 minimumUSDC
  ) {
    uint256 quotedUSDC = (dai.mul(quotedExchangeRate)).div(_SCALING_FACTOR);
    minimumUSDC = (quotedUSDC.mul(99)).div(100);
  }
}
