



pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../libs/MathUtils.sol";

import "../../Tenderizer.sol";
import "./IMatic.sol";

import "../../WithdrawalLocks.sol";

import { ITenderSwapFactory } from "../../../tenderswap/TenderSwapFactory.sol";

contract Matic is Tenderizer {
    using WithdrawalLocks for WithdrawalLocks.Locks;


    uint256 constant EXCHANGE_RATE_PRECISION = 100;
    uint256 constant EXCHANGE_RATE_PRECISION_HIGH = 10**29;


    address maticStakeManager;


    IMatic matic;

    WithdrawalLocks.Locks withdrawLocks;

    function initialize(
        IERC20 _steak,
        string calldata _symbol,
        address _matic,
        address _node,
        uint256 _protocolFee,
        uint256 _liquidityFee,
        ITenderToken _tenderTokenTarget,
        TenderFarmFactory _tenderFarmFactory,
        ITenderSwapFactory _tenderSwapFactory
    ) public {
        Tenderizer._initialize(
            _steak,
            _symbol,
            _node,
            _protocolFee,
            _liquidityFee,
            _tenderTokenTarget,
            _tenderFarmFactory,
            _tenderSwapFactory
        );
        maticStakeManager = _matic;
        matic = IMatic(_node);
    }

    function setNode(address _node) external override onlyGov {
        require(_node != address(0), "ZERO_ADDRESS");
        node = _node;
        matic = IMatic(_node);

        emit GovernanceUpdate("NODE");
    }

    function _deposit(address _from, uint256 _amount) internal override {
        currentPrincipal += _amount;

        emit Deposit(_from, _amount);
    }

    function _stake(address _node, uint256 _amount) internal override {

        uint256 amount = _amount;

        if (amount == 0) {
            return;

        }


        if (_node == address(0)) {
            return;
        }


        IMatic matic_ = matic;

        if (_node != address(0)) {
            matic_ = IMatic(_node);
        }



        steak.approve(maticStakeManager, amount);


        uint256 min = ((amount * _getExchangeRatePrecision(matic_)) / _getExchangeRate(matic_)) - 1;
        matic_.buyVoucher(amount, min);

        emit Stake(address(matic_), amount);
    }

    function _unstake(
        address _account,
        address _node,
        uint256 _amount
    ) internal override returns (uint256 withdrawalLockID) {
        uint256 amount = _amount;


        IMatic matic_ = IMatic(_node);

        uint256 exhangeRatePrecision = _getExchangeRatePrecision(matic_);
        uint256 fxRate = _getExchangeRate(matic_);


        if (_account != gov) require(amount > 0, "ZERO_AMOUNT");
        if (amount == 0) {
            uint256 shares = matic_.balanceOf(address(this));
            amount = (shares * fxRate) / exhangeRatePrecision;
            require(amount > 0, "ZERO_STAKE");
        }

        currentPrincipal -= amount;


        uint256 max = ((amount * exhangeRatePrecision) / fxRate) + 1;
        matic_.sellVoucher_new(amount, max);


        withdrawalLockID = withdrawLocks.unlock(_account, amount);

        emit Unstake(_account, address(matic_), amount, withdrawalLockID);
    }

    function _withdraw(address _account, uint256 _withdrawalID) internal override {
        withdrawLocks.withdraw(_account, _withdrawalID);


        uint256 balBefore = steak.balanceOf(address(this));
        matic.unstakeClaimTokens_new(_withdrawalID);
        uint256 balAfter = steak.balanceOf(address(this));
        uint256 amount = balAfter >= balBefore ? balAfter - balBefore : 0;
        require(amount > 0, "ZERO_AMOUNT");



        steak.transfer(_account, amount);

        emit Withdraw(_account, amount, _withdrawalID);
    }

    function _claimRewards() internal override {

        try matic.restake() {} catch {}

        uint256 shares = matic.balanceOf(address(this));
        uint256 stake = (shares * _getExchangeRate(matic)) / _getExchangeRatePrecision(matic);

        Tenderizer._processNewStake(stake);
    }

    function _setStakingContract(address _stakingContract) internal override {
        maticStakeManager = _stakingContract;

        emit GovernanceUpdate("STAKING_CONTRACT");
    }

    function _getExchangeRatePrecision(IMatic _matic) internal view returns (uint256) {
        return _matic.validatorId() < 8 ? EXCHANGE_RATE_PRECISION : EXCHANGE_RATE_PRECISION_HIGH;
    }

    function _getExchangeRate(IMatic _matic) internal view returns (uint256) {
        uint256 rate = _matic.exchangeRate();
        return rate == 0 ? 1 : rate;
    }
}
