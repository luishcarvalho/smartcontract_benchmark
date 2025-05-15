

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./DataStore.sol";
import "../interfaces/IManager.sol";
import "../interfaces/ILpProvider.sol";
import "../logic/Guaranteed.sol";
import "../logic/OverSubscribe.sol";
import "../logic/Lottery.sol";
import "../logic/Live.sol";
import "../logic/Vesting.sol";
import "../logic/LpProvision.sol";
import "../logic/History.sol";

contract MainWorkflow is DataStore, ReentrancyGuard {

    using SafeERC20 for ERC20;
    using Generic for *;
    using Guaranteed for *;
    using Lottery for DataTypes.Lottery;
    using OverSubscribe for DataTypes.OverSubscriptions;
    using Live for *;
    using Vesting for *;
    using LpProvision for DataTypes.Lp;
    using History for DataTypes.History;

    IManager internal _manager;
    address internal _campaignOwner;

    modifier notAborted() {
        _require(!_isAborted(), Error.Code.Aborted);
        _;
    }

    constructor(IManager manager, address campaignOwner) {
        _manager = manager;
        _campaignOwner = campaignOwner;
    }









    function getSubscribable(address user) external view returns (uint amount, bool guaranteed, uint overSubAmt) {
        if (getState(DataTypes.Ok.Finalized)) {
            (amount, guaranteed) = _store().getGuaranteedAmt(user);
            overSubAmt = _store().overSubscription.data.stdOverSubQty;
        }
    }

    function subscribe(uint amtBasic, uint amtOverSub, uint priority, uint eggTotalQty) external payable {
        DataTypes.Subscriptions storage subs = _subscriptions();
        bool subscribed = subs.items[msg.sender].paidCapital != 0;
        uint capital = amtBasic + amtOverSub;

        _require(!_isAborted() && !subscribed && capital > 0 && _isPeriod(DataTypes.Period.Subscription), Error.Code.ValidationError);
        _transferIn(capital, DataTypes.FundType.Currency);


        (uint maxAlloc, bool isGuaranteed) = _store().getGuaranteedAmt(msg.sender);

        if (isGuaranteed) {
            _guaranteed().subscribe(amtBasic, maxAlloc);
        } else {
            _lottery().subscribe(amtBasic);
        }


        if (amtOverSub > 0) {
            _overSubscriptions().subscribe(amtOverSub, priority, eggTotalQty);
            _transferIn(eggTotalQty, DataTypes.FundType.Egg);
        }


        _recordSubscription(subs, capital);




         _require(amtBasic <= type(uint256).max >> 1 && amtOverSub <= type(uint120).max && priority <= type(uint16).max && eggTotalQty <= type(uint120).max, Error.Code.ValidationError);
         uint pack1 = (amtBasic << 1) | (isGuaranteed ? 1 : 0);
         uint pack2 = (amtOverSub) | (eggTotalQty << 120) | (priority << 240);
        _history().record(DataTypes.ActionType.Subscribe, msg.sender, pack1, pack2, true);
    }

    function getSubscriptionResult(address user) external view returns (DataTypes.SubscriptionResultParams memory p) {
        if (getState(DataTypes.Ok.Tally)) {
            p = _store().getSubscriptionResult(user);
        }
    }

    function getSubscription(address user) external view returns (DataTypes.SubscriptionParams memory p) {
        (p.guaranteedAmount, p.guaranteed) = _store().getGuaranteedSubscription(user);
        p.inLottery = _lottery().items[user].exist;
        p.lotteryAmount = _lottery().data.eachAllocationAmount;
        (, p.overSubAmount, p.priority, p.eggBurnAmount) = _overSubscriptions().getSubscription(user);
    }

    function getSubscribersCount() external view returns (uint) {
        return _subscriptions().count;
    }

    function getUserWhitelistInfo(address user) external view returns (bool, uint, uint, uint) {
        return _live().getUserWhitelistInfo(user);
    }

    function getHistory(address user, bool investor) external view returns (DataTypes.Action[] memory) {
        return (investor ?  _history().investor[user] : _history().campaignOwner[user]);
    }



    function finishUp() external nonReentrant {


         bool ok = (!_isAborted() &&
            !getState(DataTypes.Ok.FinishedUp) &&
            (_isPeriod(DataTypes.Period.IdoEnded) || (_hasOpened() && _live().getAllocLeftForLive() == 0)) );
         _require(ok, Error.Code.ValidationError);


        _setState(DataTypes.Ok.FinishedUp, true);


        uint fundInTokens = getFundInTokenRequired();


        (bool softCapMet, uint fee, uint totalAfterFeeLp, uint unusedLpTokensQty, uint unsoldTokensQty) = _getFinishUpStats();
        _store().finalState = softCapMet ?  DataTypes.FinalState.Success : DataTypes.FinalState.Failure;

        if (softCapMet) {

            _transferOut(_manager.getFeeVault(), fee, DataTypes.FundType.Currency);


            if (!_vesting().hasTeamVesting() ) {
                _transferOut(_campaignOwner, totalAfterFeeLp, DataTypes.FundType.Currency);
            } else {
                _vesting().data.teamLockAmount = totalAfterFeeLp;
            }


            _transferOut(_campaignOwner, unusedLpTokensQty + unsoldTokensQty, DataTypes.FundType.Token);


            uint burnAmt = _overSubscriptions().getBurnableEggsAfterTally();
            if (burnAmt>0) {
                ERC20Burnable(_manager.getEggAddress()).burn(burnAmt);
            }
        } else {

            _transferOut(_campaignOwner, fundInTokens, DataTypes.FundType.Token);
        }
    }

    function buyTokens(uint fund) external payable {
        uint available = getAllocLeftForLive();
        _require(!_isAborted() && _isLivePeriod() && fund > 0 && available > 0 && fund <= available, Error.Code.CannotBuyToken);
        _store().buyTokens(fund, _isPeriod(DataTypes.Period.IdoWhitelisted));

        _transferIn(fund, DataTypes.FundType.Currency);
        _history().record(DataTypes.ActionType.BuyTokens, msg.sender, fund, true);
    }


    function refundExcess() external nonReentrant {
        (bool refunded, uint capital, uint egg) = getRefundable(msg.sender);
        _require(!refunded && getState(DataTypes.Ok.Tally), Error.Code.CannotRefundExcess);

        _subscriptions().items[msg.sender].refundedUnusedCapital = true;
        _history().record(DataTypes.ActionType.RefundExcess, msg.sender, capital, egg, true);

        _transferOut(msg.sender, capital, DataTypes.FundType.Currency);
        _transferOut(msg.sender, egg, DataTypes.FundType.Egg);
    }


    function returnFund() external nonReentrant {
        _require( (_store().finalState == DataTypes.FinalState.Failure ||
            _store().finalState == DataTypes.FinalState.Aborted) &&
            _store().returnFunds.amount[msg.sender]==0, Error.Code.CannotReturnFund);

        bool hasTally = getState(DataTypes.Ok.Tally);

        DataTypes.PurchaseDetail memory purchase = getPurchaseDetail(msg.sender, !hasTally);


        uint total = purchase.total;

        if (total > 0) {
            _transferOut(msg.sender, total, DataTypes.FundType.Currency);

            uint egg;
            if (hasTally) {

                egg = _overSubscriptions().getBurnableEggs(msg.sender);
            } else {

                (, , , egg) = _overSubscriptions().getSubscription(msg.sender);
            }
            _transferOut(msg.sender, egg, DataTypes.FundType.Egg);


           _store().returnFunds.amount[msg.sender] = total;

           _history().record(DataTypes.ActionType.ReturnFund, msg.sender, total, egg, true);
        }
    }

    function getClaimableByIntervals(address user, bool investor) external view returns (DataTypes.ClaimIntervalResult memory) {
        uint total = investor ? _getTotalPurchased(user) : _vesting().data.teamLockAmount;
        return _vesting().getClaimableByIntervals(user, investor).scaleBy(total);
    }

    function getClaimableByLinear(address user, bool investor) external view returns (DataTypes.ClaimLinearResult memory) {
        uint total = investor ? _getTotalPurchased(user) : _vesting().data.teamLockAmount;
        return _vesting().getClaimableByLinear(user, investor).scaleBy(total);
    }







    function getFundInTokenRequired() public view override returns(uint) {
        (uint lpTokensNeeded, ) = _lp().getMaxRequiredTokensQty();
        return super.getFundInTokenRequired() + lpTokensNeeded;
    }

    function getPurchaseDetail(address user, bool includeRefundable) public view returns (DataTypes.PurchaseDetail memory) {
        return _store().getPurchaseDetail(user, getState(DataTypes.Ok.Tally), includeRefundable);
    }




    function peekTally() public view returns (uint, uint, uint) {
        return (_guaranteed().totalSubscribed, _lottery().getTotal(), _overSubscriptions().getTotal());
    }




    function getRefundable(address user) public view returns(bool refunded, uint capital, uint eggs) {

        if (getState(DataTypes.Ok.Tally)) {
            refunded = _subscriptions().items[user].refundedUnusedCapital;

            uint lotteryRefund = _lottery().getRefundable(user);
            (capital, eggs) = _overSubscriptions().getRefundable(user);
            capital += lotteryRefund;
        }
    }


    function getLpFund() public view returns (uint fund) {
        (, fund) = _lp().getRequiredTokensQty(_raisedAmount(true));
    }





    function _fundIn(uint amtAcknowledged) internal {
        _require(!getState(DataTypes.Ok.FundedIn) &&
            getState(DataTypes.Ok.Finalized) &&
            _isPeriod(DataTypes.Period.Setup) &&
            getFundInTokenRequired() == amtAcknowledged, Error.Code.ValidationError);

        _setState(DataTypes.Ok.FundedIn, true);
        _transferIn(amtAcknowledged, DataTypes.FundType.Token);
        _history().record(DataTypes.ActionType.FundIn, msg.sender, amtAcknowledged, false);
    }





    function _fundOut(uint amtAcknowledged) internal nonReentrant {
        _require( getState(DataTypes.Ok.FundedIn) &&
            (_isPeriod(DataTypes.Period.Setup) || _store().finalState == DataTypes.FinalState.Failure || _isAborted()) &&
            getFundInTokenRequired() == amtAcknowledged, Error.Code.ValidationError);

        _setState(DataTypes.Ok.FundedIn, false);
        _transferOut(msg.sender, amtAcknowledged, DataTypes.FundType.Token);
        _history().record(DataTypes.ActionType.FundOut, msg.sender, amtAcknowledged, false);
    }






    function _tallySubscription(uint splitRatio) internal {
        _require(_canTally() && splitRatio<=Constant.PCNT_100, Error.Code.ValidationError);


        uint amtLeft = _data().hardCap - _guaranteed().totalSubscribed;


        uint amtForLottery = (amtLeft * splitRatio) / Constant.PCNT_100;


        _lottery().tally(amtForLottery);
        _overSubscriptions().tally(amtLeft - amtForLottery);


        _live().allocLeftAtOpen = _lottery().getFinalLeftOver() + _overSubscriptions().getFinalLeftOver();
        _setState(DataTypes.Ok.Tally, true);
    }

    function _claim(bool investor) internal nonReentrant {
        _claim(investor, _vesting().updateClaim(msg.sender, investor));
    }

    function _transferIn(uint amount, DataTypes.FundType fundType) internal {
        if (amount > 0) {

            if (fundType == DataTypes.FundType.Currency && _isBnbCurrency()) {
                _require(amount == msg.value, Error.Code.InvalidAmount);
            } else {
                ERC20(_getAddress(fundType)).safeTransferFrom(msg.sender, address(this), amount);
            }
        }
    }

    function _transferOut(address to, uint amount, DataTypes.FundType fundType) internal  {
        _transferOut(to, _getAddress(fundType), amount);
    }

    function _transferOut(address to, address token, uint amount) internal  {

        if (amount > 0 && to != Constant.ZERO_ADDRESS) {

            if (token == Constant.ZERO_ADDRESS) {
                (bool success, ) = to.call{ value: amount}("");
                _require(success, Error.Code.ValidationError);
            } else {
                 ERC20(token).safeTransfer(to, amount);
            }
        }
    }

    function _getLpInterface() internal view returns (ILpProvider) {
        return ILpProvider(address(_manager));
    }







    function _getAddress(DataTypes.FundType fundType) private view returns (address) {
        if (fundType == DataTypes.FundType.Currency) {
            return _data().currency;
        } else if (fundType == DataTypes.FundType.Token) {
            return _data().token;
        } else if (fundType == DataTypes.FundType.Egg) {
            return _manager.getEggAddress();
        } else if (fundType == DataTypes.FundType.WBnb) {
            return _getLpInterface().getWBnb();
        }
        return address(0);
    }


    function _claim(bool investor, uint releasePcnt) private {


       _require(_store().finalState == DataTypes.FinalState.Success, Error.Code.SoftCapNotMet);

        uint total;
        if (releasePcnt>0) {
            if (investor) {
                 total = getTokensForCapital((_getTotalPurchased(msg.sender) * releasePcnt) / Constant.PCNT_100);
                 _require(total > 0, Error.Code.InvalidAmount);
                _transferOut(msg.sender, total, DataTypes.FundType.Token);
            } else {
                total = (_vesting().data.teamLockAmount * releasePcnt) / Constant.PCNT_100;
                _transferOut(msg.sender, total, DataTypes.FundType.Currency);
            }
            _history().record(investor ? DataTypes.ActionType.ClaimTokens : DataTypes.ActionType.ClaimFund,
                msg.sender, total, investor);
        }
    }







    function _getFinishUpStats() private view returns(bool softCapMet, uint feeAmt, uint totalAfterFeeLp, uint unusedLpTokensQty, uint unsoldTokensQty) {

        uint amtReturn = _data().hardCap;
        uint total = getTotalAllocSold();


        softCapMet = total >= _data().softCap;
        if (softCapMet) {
            if (_data().feePcnt > 0 ) {
                feeAmt = _getFeeAmount(total);
                total -= feeAmt;
            }


            DataTypes.Lp storage lp = _lp();
            if (lp.enabled) {

                (uint totalLpTokens, ) = _lp().getMaxRequiredTokensQty();


                (uint lpTokensUsed, uint lpFundUsed) = lp.getRequiredTokensQty(total);
                total -= lpFundUsed;
                unusedLpTokensQty = totalLpTokens - lpTokensUsed;
            }
            amtReturn = getAllocLeftForLive();
        }
        totalAfterFeeLp = total;
        unsoldTokensQty = getTokensForCapital(amtReturn);
    }

    function _getTotalPurchased(address user) private view returns (uint) {
        return getPurchaseDetail(user, false).total;
    }

    function _recordSubscription(DataTypes.Subscriptions storage param, uint capital) private {
        param.items[msg.sender] = DataTypes.SubItem(capital, false);
        param.count++ ;
    }
}


