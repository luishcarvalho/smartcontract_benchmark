
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../utils/OwnablePausable.sol";
import "../uniswap/IUniswapV2Router02.sol";

contract ProfitSplitter is OwnablePausable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant SHARE_ACCURACY = 6;

    uint256 public constant SHARE_DIGITS = 2;


    ERC20 public incoming;


    address payable public budget;


    uint256 public budgetBalance;


    mapping(address => uint256) public shares;


    EnumerableSet.AddressSet private recipientsIndex;


    IUniswapV2Router02 public uniswapRouter;


    event Transfer(address recipient, uint256 amount);


    event BudgetChanged(address newBudget, uint256 newBalance);


    event IncomingChanged(address newIncoming);


    event UniswapRouterChanged(address newUniswapRouter);


    event RecipientAdded(address recipient, uint256 share);


    event RecipientRemoved(address recipient);


    event PayToBudget(address recipient, uint256 amount);


    event PayToRecipient(address recipient, uint256 amount);

    receive() external payable {}





    constructor(address _incoming, address _uniswapRouter) public {
        incoming = ERC20(_incoming);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }





    function changeUniswapRouter(address _uniswapRouter) external onlyOwner {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        emit UniswapRouterChanged(_uniswapRouter);
    }






    function changeBudget(address payable _budget, uint256 _budgetBalance) external onlyOwner {
        budget = _budget;
        budgetBalance = _budgetBalance;
        emit BudgetChanged(budget, budgetBalance);
    }






    function transfer(address _recipient, uint256 amount) public onlyOwner {
        require(_recipient != address(0), "ProfitSplitter::transfer: cannot transfer to the zero address");

        incoming.safeTransfer(_recipient, amount);
        emit Transfer(_recipient, amount);
    }






    function changeIncoming(address _incoming, address _recipient) external onlyOwner {
        require(address(incoming) != _incoming, "ProfitSplitter::changeIncoming: duplicate incoming token address");

        uint256 balance = incoming.balanceOf(address(this));
        if (balance > 0) {
            transfer(_recipient, balance);
        }
        incoming = ERC20(_incoming);
        emit IncomingChanged(_incoming);
    }





    function _currentShare() internal view returns (uint256 result) {
        for (uint256 i = 0; i < recipientsIndex.length(); i++) {
            result = result.add(shares[recipientsIndex.at(i)]);
        }
    }






    function addRecipient(address recipient, uint256 share) external onlyOwner {
        require(!recipientsIndex.contains(recipient), "ProfitSplitter::addRecipient: recipient already added");
        require(_currentShare().add(share) <= 100, "ProfitSplitter::addRecipient: invalid share");

        recipientsIndex.add(recipient);
        shares[recipient] = share;
        emit RecipientAdded(recipient, share);
    }





    function removeRecipient(address recipient) external onlyOwner {
        require(recipientsIndex.contains(recipient), "ProfitSplitter::removeRecipient: recipient already removed");

        recipientsIndex.remove(recipient);
        shares[recipient] = 0;
        emit RecipientRemoved(recipient);
    }





    function getRecipients() public view returns (address[] memory) {
        address[] memory result = new address[](recipientsIndex.length());

        for (uint256 i = 0; i < recipientsIndex.length(); i++) {
            result[i] = recipientsIndex.at(i);
        }

        return result;
    }




    function _payToBudget() internal returns (bool) {
        uint256 splitterIncomingBalance = incoming.balanceOf(address(this));
        if (splitterIncomingBalance == 0) return false;

        uint256 currentBudgetBalance = budget.balance;
        if (currentBudgetBalance >= budgetBalance) return false;

        uint256 amount = budgetBalance.sub(currentBudgetBalance);
        uint256 splitterEthBalance = address(this).balance;
        if (splitterEthBalance < amount) {
            uint256 amountOut = amount.sub(splitterEthBalance);

            address[] memory path = new address[](2);
            path[0] = address(incoming);
            path[1] = uniswapRouter.WETH();

            uint256[] memory amountsIn = uniswapRouter.getAmountsIn(amountOut, path);
            require(amountsIn.length == 2, "ProfitSplitter::_payToBudget: invalid amounts in length");
            require(amountsIn[0] > 0, "ProfitSplitter::_payToBudget: liquidity pool is empty");
            if (amountsIn[0] <= splitterIncomingBalance) {
                incoming.safeApprove(address(uniswapRouter), amountsIn[0]);
                uniswapRouter.swapTokensForExactETH(amountOut, amountsIn[0], path, address(this), block.timestamp);
            } else {
                uint256[] memory amountsOut = uniswapRouter.getAmountsOut(splitterIncomingBalance, path);
                require(amountsOut.length == 2, "ProfitSplitter::_payToBudget: invalid amounts out length");
                require(amountsOut[1] > 0, "ProfitSplitter::_payToBudget: amounts out liquidity pool is empty");

                amount = amountsOut[1];

                incoming.safeApprove(address(uniswapRouter), splitterIncomingBalance);
                uniswapRouter.swapExactTokensForETH(splitterIncomingBalance, amountsOut[1], path, address(this), block.timestamp);
            }
        }

        budget.transfer(amount);
        emit PayToBudget(budget, amount);

        return true;
    }





    function _payToRecipients() internal returns (bool) {
        uint256 splitterIncomingBalance = incoming.balanceOf(address(this));
        if (splitterIncomingBalance == 0) return false;

        for (uint256 i = 0; i < recipientsIndex.length(); i++) {
            address recipient = recipientsIndex.at(i);
            uint256 share = shares[recipient];

            uint256 amount = splitterIncomingBalance.mul(10**SHARE_ACCURACY).mul(share).div(10**SHARE_ACCURACY.add(SHARE_DIGITS));
            incoming.safeTransfer(recipient, amount);

            emit PayToRecipient(recipient, amount);
        }

        return true;
    }





    function split(uint256 amount) external whenNotPaused {
        if (amount > 0) {
            incoming.safeTransferFrom(msg.sender, address(this), amount);
        }

        _payToBudget();
        _payToRecipients();
    }
}
