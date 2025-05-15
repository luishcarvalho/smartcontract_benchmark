

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import {
    ReentrancyGuardUpgradeSafe
} from "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import { Decimal, SafeMath } from "./utils/Decimal.sol";
import { IERC20 } from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import { PerpFiOwnableUpgrade } from "./utils/PerpFiOwnableUpgrade.sol";
import { DecimalERC20 } from "./utils/DecimalERC20.sol";
import { BlockContext } from "./utils/BlockContext.sol";
import { IArk } from "./interface/IArk.sol";

contract Ark is IArk, PerpFiOwnableUpgrade, BlockContext, ReentrancyGuardUpgradeSafe, DecimalERC20 {
    using Decimal for Decimal.decimal;
    using SafeMath for uint256;




    event WithdrawnForLoss(address withdrawer, uint256 amount, address token);

    struct WithdrawnToken {
        uint256 timestamp;
        Decimal.decimal cumulativeAmount;
    }

    address public insuranceFund;

    mapping(IERC20 => WithdrawnToken[]) public withdrawnTokenHistory;

    uint256[50] private __gap;




    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }


    function withdrawForLoss(Decimal.decimal memory _amount, IERC20 _quoteToken) public override {
        require(insuranceFund == _msgSender(), "only insuranceFund");

        if (_getTokenDecimals(address(_quoteToken)) < 18) {



            _amount = _amount.addD(_toDecimal(_quoteToken, 1));
        }

        require(_balanceOf(_quoteToken, address(this)).toUint() >= _amount.toUint(), "insufficient funds");


        Decimal.decimal memory cumulativeAmount;
        uint256 len = withdrawnTokenHistory[_quoteToken].length;
        if (len == 0) {
            cumulativeAmount = _amount;
        } else {
            cumulativeAmount = withdrawnTokenHistory[_quoteToken][len - 1].cumulativeAmount.addD(_amount);
        }

        withdrawnTokenHistory[_quoteToken].push(
            WithdrawnToken({ timestamp: _blockTimestamp(), cumulativeAmount: cumulativeAmount })
        );

        _transfer(_quoteToken, _msgSender(), _amount);
        emit WithdrawnForLoss(_msgSender(), _amount.toUint(), address(_quoteToken));
    }


    function claimTokens(address payable _to, IERC20 _token) external onlyOwner {
        require(_to != address(0), "to address is required");
        if (_token == IERC20(0)) {
            _to.transfer(address(this).balance);
        } else {
            _transfer(_token, _to, _balanceOf(_token, address(this)));
        }
    }

    function setInsuranceFund(address _insuranceFund) external onlyOwner {
        insuranceFund = _insuranceFund;
    }
}
