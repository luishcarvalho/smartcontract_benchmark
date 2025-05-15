pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

import "./BlockController.sol";
import "./ExitGameController.sol";

import "./registries/VaultRegistry.sol";
import "./registries/ExitGameRegistry.sol";

contract PlasmaFramework is VaultRegistry, ExitGameRegistry, ExitGameController, BlockController {
    uint256 public constant CHILD_BLOCK_INTERVAL = 1000;














    uint256 public minExitPeriod;
    address private maintainer;

    constructor(
        uint256 _minExitPeriod,
        uint256 _initialImmuneVaults,
        uint256 _initialImmuneExitGames,
        address _authority,
        address _maintainer
    )
        public
        BlockController(CHILD_BLOCK_INTERVAL, _minExitPeriod, _initialImmuneVaults, _authority)
        ExitGameController(_minExitPeriod, _initialImmuneExitGames)
    {
        minExitPeriod = _minExitPeriod;
        maintainer = _maintainer;
    }

    function getMaintainer() public view returns (address) {
        return maintainer;
    }
}
