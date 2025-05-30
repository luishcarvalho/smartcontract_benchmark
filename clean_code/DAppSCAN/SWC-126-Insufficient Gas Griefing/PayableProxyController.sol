


pragma solidity =0.6.10;
pragma experimental ABIEncoderV2;

import {WETH9} from "../canonical-weth/WETH9.sol";
import {ReentrancyGuard} from "../../packages/oz/ReentrancyGuard.sol";
import {SafeERC20} from "../../packages/oz/SafeERC20.sol";
import {ERC20Interface} from "../../interfaces/ERC20Interface.sol";
import {Actions} from "../../libs/Actions.sol";
import {Controller} from "../../Controller.sol";






contract PayableProxyController is ReentrancyGuard {
    WETH9 public weth;
    Controller public controller;
    using SafeERC20 for ERC20Interface;

    constructor(
        address _controller,
        address _marginPool,
        address payable _weth
    ) public {
        controller = Controller(_controller);
        weth = WETH9(_weth);
        ERC20Interface(address(weth)).safeApprove(_marginPool, uint256(-1));
    }




    fallback() external payable {
        require(msg.sender == address(weth), "PayableProxyController: Cannot receive ETH");
    }






    function operate(Actions.ActionArgs[] memory _actions, address payable sendEthTo) external payable nonReentrant {

        if (msg.value != 0) {
            weth.deposit{value: msg.value}();
        }


        for (uint256 i = 0; i < _actions.length; i++) {
            Actions.ActionArgs memory action = _actions[i];


            if (action.owner != address(0)) {
                require(
                    (msg.sender == action.owner) || (controller.isOperator(action.owner, msg.sender)),
                    "PayableProxyController: cannot execute action "
                );
            }
        }

        controller.operate(_actions);


        uint256 remainingWeth = weth.balanceOf(address(this));
        if (remainingWeth != 0) {
            require(sendEthTo != address(0), "PayableProxyController: cannot send ETH to address zero");

            weth.withdraw(remainingWeth);

            sendEthTo.transfer(remainingWeth);
        }
    }
}
