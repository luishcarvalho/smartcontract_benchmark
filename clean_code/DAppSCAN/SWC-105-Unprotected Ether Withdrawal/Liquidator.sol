

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IUniswapV2FactoryMinimal.sol";
import "./interfaces/IERC20Minimal.sol";
import "./TransferHelper.sol";

contract liquidator is AccessControl {

  address v2Factory;
  address debt;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function initialize(address v2Factory_, address debt_) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA");
    v2Factory = v2Factory_;
    debt = debt_;
  }

  function distribute(address collateral) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "IA");

    address pair = IUniswapV2FactoryMinimal(v2Factory).getPair(
      collateral,
      debt
    );
    require(pair != address(0), "Vault: Liquidating pair not supported");


    TransferHelper.safeTransfer(collateral, pair, IERC20Minimal(collateral).balanceOf(address(this)));
  }
}
