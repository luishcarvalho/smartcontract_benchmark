



pragma solidity 0.5.12;


interface CTokenInterface {
  function supplyRatePerBlock() external view returns (uint256 rate);
  function exchangeRateStored() external view returns (uint256 rate);
  function accrualBlockNumber() external view returns (uint256 blockNumber);
}


library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }
}


contract CDaiExchangeRateView {
  using SafeMath for uint256;

  uint256 internal constant _SCALING_FACTOR = 1e18;

  CTokenInterface internal constant _CDAI = CTokenInterface(
    0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643
  );






  function getCurrentExchangeRate() external view returns (uint256 exchangeRate) {
    uint256 storedExchangeRate = _CDAI.exchangeRateStored();
    uint256 blockDelta = block.number.sub(_CDAI.accrualBlockNumber());

    if (address(this).balance == 0) return storedExchangeRate;

    exchangeRate = blockDelta == 0 ? storedExchangeRate : storedExchangeRate.add(
      storedExchangeRate.mul(
        _CDAI.supplyRatePerBlock().mul(blockDelta)
      ) / _SCALING_FACTOR
    );
  }
}
