



pragma solidity 0.6.10;


interface IERC20 {
  function balanceOf(address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
}


contract TradeReserveEtherReceiverStaging {
  address payable internal constant _TRADE_RESERVE_STAGING = (
    0x2040F2f2bB228927235Dc24C33e99E3A0a7922c1
  );

  receive() external payable {}

  function settleEther() public {
    (bool ok,) = _TRADE_RESERVE_STAGING.call{
      value: address(this).balance
    }("");

    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }

  function settleERC20(IERC20 token) public {
    bool ok = token.transfer(
      _TRADE_RESERVE_STAGING, token.balanceOf(address(this))
    );

    require(ok, "Token transfer failed.");
  }
}
