
pragma solidity >=0.6.0;

import "../interfaces/IERC20.sol";


library Transfers {





    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory returnData) = address(token).call(
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
        require(success && (returnData.length == 0 || abi.decode(returnData, (bool))), "Transfer fail");
    }
}
