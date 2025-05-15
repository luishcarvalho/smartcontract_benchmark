




pragma solidity 0.6.12;

interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);
}

contract WethPriceFeed is IChainlinkAggregator {

  function latestAnswer() public view override returns (int256) {
      return 1 ether;
  }
}
