
pragma solidity ^0.8.11;

import "./interfaces/ILenderPool.sol";
import "./interfaces/IUniswapV2Router.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";



contract LenderPool is ILenderPool, Ownable {
    using SafeERC20 for IERC20;


    IERC20 public immutable stableInstance;


    IUniswapV2Router public immutable router;


    address public immutable trade;


    address public treasury;


    uint16 public stableAPY;


    uint private constant PRECISION = 1E6;


    uint16 public tenure;


    uint public minimumDeposit;


    uint public totalRounds;


    uint public totalLiquidity;


    uint public totalDeposited;


    mapping(address => LenderInfo) private _lenderInfo;


    mapping(address => mapping(uint => Round)) private _lenderRounds;

    constructor(
        uint16 stableAPY_,
        uint16 tenure_,
        address stableAddress_,
        address clientPortal_,
        address tradeToken_
    ) {
        stableInstance = IERC20(stableAddress_);
        stableAPY = stableAPY_;
        tenure = tenure_;

        router = IUniswapV2Router(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

        trade = tradeToken_;

        stableInstance.approve(address(router), ~uint(0));
        stableInstance.approve(address(clientPortal_), ~uint(0));
    }






    function setMinimumDeposit(uint newMinimumDeposit) external onlyOwner {
        uint oldMinimumDeposit = minimumDeposit;
        minimumDeposit = newMinimumDeposit;
        emit MinimumDepositUpdated(oldMinimumDeposit, newMinimumDeposit);
    }






    function setStableAPY(uint16 newStableAPY) external onlyOwner {
        uint oldStableAPY = stableAPY;
        stableAPY = newStableAPY;
        emit StableAPYUpdated(oldStableAPY, newStableAPY);
    }






    function setTenure(uint16 newTenure) external onlyOwner {
        require(newTenure >= 30 && newTenure <= 365, "Invalid tenure");
        uint16 oldTenure = tenure;
        tenure = newTenure;
        emit TenureUpdated(oldTenure, newTenure);
    }





    function setTreasuryAddress(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Cannot set address(0)");
        address oldTreasury = treasury;
        treasury = _newTreasury;
        emit NewTreasuryAddress(oldTreasury, _newTreasury);
    }













    function newRound(
        address lender,
        uint amount,
        uint16 bonusAPY,
        bool paidTrade
    ) external onlyOwner {
        require(amount >= minimumDeposit, "Amount lower than minimumDeposit");
        Round memory round = Round({
            stableAPY: stableAPY,
            bonusAPY: bonusAPY,
            startPeriod: uint48(block.timestamp),
            endPeriod: uint48(block.timestamp + (tenure * 1 days)),
            amountLent: amount,
            paidTrade: paidTrade
        });

        _lenderRounds[lender][_lenderInfo[lender].roundCount] = round;
        _lenderInfo[lender].roundCount++;
        _lenderInfo[lender].amountLent += amount;
        totalDeposited += amount;
        totalLiquidity += amount;
        totalRounds++;

        stableInstance.safeTransferFrom(lender, address(this), amount);
        emit Deposit(lender, _lenderInfo[lender].roundCount - 1, amount);
    }







    function sendToTreasury(address tokenAddress, uint amount)
        external
        onlyOwner
    {
        IERC20 tokenContract = IERC20(tokenAddress);

        tokenContract.safeTransfer(treasury, amount);
    }








    function getRound(address lender, uint roundId)
        external
        view
        returns (Round memory)
    {
        return _lenderRounds[lender][roundId];
    }






    function getLatestRound(address lender) external view returns (uint) {
        return _lenderInfo[lender].roundCount - 1;
    }






    function getAmountLent(address lender) external view returns (uint) {
        return _lenderInfo[lender].amountLent;
    }






    function getFinishedRounds(address lender)
        external
        view
        returns (uint[] memory)
    {
        return _getFinishedRounds(lender);
    }








    function stableRewardOf(address lender, uint roundId)
        external
        view
        returns (uint)
    {
        return
            _calculateRewards(
                lender,
                roundId,
                _lenderRounds[lender][roundId].stableAPY
            );
    }








    function bonusRewardOf(address lender, uint roundId)
        external
        view
        returns (uint)
    {
        return
            _calculateRewards(
                lender,
                roundId,
                _lenderRounds[lender][roundId].bonusAPY
            );
    }











    function withdraw(
        address lender,
        uint roundId,
        uint amountOutMin
    ) public onlyOwner {
        Round memory round = _lenderRounds[lender][roundId];
        require(
            block.timestamp >= round.endPeriod,
            "Round is not finished yet"
        );
        uint amountLent = _lenderRounds[lender][roundId].amountLent;
        require(amountLent > 0, "No amount lent");
        _claimRewards(lender, roundId, amountOutMin);
        _withdraw(lender, roundId, amountLent);
    }












    function _claimRewards(
        address lender,
        uint roundId,
        uint amountOutMin
    ) private {
        Round memory round = _lenderRounds[lender][roundId];
        if (round.paidTrade) {
            _distributeRewards(
                lender,
                roundId,
                (round.stableAPY + round.bonusAPY),
                amountOutMin
            );
        } else {
            uint amountStable = _calculateRewards(
                lender,
                roundId,
                round.stableAPY
            );
            stableInstance.safeTransfer(lender, amountStable);
            emit ClaimStable(lender, roundId, amountStable);

            _distributeRewards(lender, roundId, round.bonusAPY, amountOutMin);
        }
    }

    function _distributeRewards(
        address lender,
        uint roundId,
        uint16 rewardAPY,
        uint amountOutMin
    ) private {
        uint balance = IERC20(trade).balanceOf(address(this));

        uint quotation = _getQuotation(lender, roundId, rewardAPY);

        if (balance >= quotation) {
            IERC20(trade).safeTransfer(lender, quotation);
            emit ClaimTrade(lender, roundId, quotation);
        } else {
            uint amountTrade = _swapExactTokens(
                lender,
                roundId,
                rewardAPY,
                amountOutMin
            );
            emit ClaimTrade(lender, roundId, amountTrade);
        }
    }









    function _withdraw(
        address lender,
        uint roundId,
        uint amount
    ) private {
        _lenderInfo[lender].amountLent -= amount;
        _lenderRounds[lender][roundId].amountLent -= amount;
        totalLiquidity -= amount;
        stableInstance.safeTransfer(lender, amount);
        emit Withdraw(lender, roundId, amount);
    }











    function _swapExactTokens(
        address lender,
        uint roundId,
        uint16 rewardAPY,
        uint amountOutMin
    ) private returns (uint) {
        uint amountStable = _calculateRewards(lender, roundId, rewardAPY);
        uint amountTrade = router.swapExactTokensForTokens(
            amountStable,
            amountOutMin,
            _getPath(),
            lender,
            block.timestamp
        )[2];
        emit Swapped(amountStable, amountTrade);
        return amountTrade;
    }









    function _getQuotation(
        address lender,
        uint roundId,
        uint16 rewardAPY
    ) private view returns (uint) {
        uint amountStable = _calculateRewards(lender, roundId, rewardAPY);
        uint amountTrade = router.getAmountsOut(amountStable, _getPath())[2];
        return amountTrade;
    }









    function _calculateRewards(
        address lender,
        uint roundId,
        uint16 rewardAPY
    ) private view returns (uint) {
        Round memory round = _lenderRounds[lender][roundId];

        uint timePassed = (block.timestamp >= round.endPeriod)
            ? round.endPeriod - round.startPeriod
            : block.timestamp - round.startPeriod;

        uint result = ((rewardAPY * round.amountLent * timePassed) / 365 days);
        return ((result * PRECISION) / 1E10);
    }






    function _getFinishedRounds(address lender)
        private
        view
        returns (uint[] memory)
    {
        uint length = _lenderInfo[lender].roundCount;
        uint j = 0;
        for (uint i = 0; i < length; i++) {
            if (
                block.timestamp >= _lenderRounds[lender][i].endPeriod &&
                _lenderRounds[lender][i].amountLent > 0
            ) {
                j++;
            }
        }
        uint[] memory result = new uint[](j);
        j = 0;
        for (uint i = 0; i < length; i++) {
            if (
                block.timestamp >= _lenderRounds[lender][i].endPeriod &&
                _lenderRounds[lender][i].amountLent > 0
            ) {
                result[j] = i;
                j++;
            }
        }
        return result;
    }





    function _getPath() private view returns (address[] memory) {
        address[] memory path = new address[](3);
        path[0] = address(stableInstance);
        path[1] = router.WETH();
        path[2] = trade;

        return path;
    }
}
