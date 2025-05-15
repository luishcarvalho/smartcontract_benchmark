



pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../libs/MathUtils.sol";

import "../../Tenderizer.sol";
import "../../WithdrawalPools.sol";
import "./IGraph.sol";

import { ITenderSwapFactory } from "../../../tenderswap/TenderSwapFactory.sol";

contract Graph is Tenderizer {
    using WithdrawalPools for WithdrawalPools.Pool;


    event ProcessUnstakes(address indexed from, address indexed node, uint256 amount);
    event ProcessWithdraws(address indexed from, uint256 amount);


    uint32 private constant MAX_PPM = 1000000;

    IGraph graph;

    WithdrawalPools.Pool withdrawPool;

    function initialize(
        IERC20 _steak,
        string calldata _symbol,
        IGraph _graph,
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
        graph = _graph;
    }

    function _calcDepositOut(uint256 _amountIn) internal view override returns (uint256) {
        return _amountIn - ((uint256(graph.delegationTaxPercentage()) * _amountIn) / MAX_PPM);
    }

    function _deposit(address _from, uint256 _amount) internal override {
        currentPrincipal += _calcDepositOut(_amount);

        emit Deposit(_from, _amount);
    }

    function _stake(address _node, uint256 _amount) internal override {

        uint256 amount = _amount;
        uint256 pendingWithdrawals = withdrawPool.getAmount();

        if (amount <= pendingWithdrawals) {
            return;
        }

        amount -= pendingWithdrawals;


        if (_node == address(0)) {
            return;
        }



        steak.approve(address(graph), amount);



        graph.delegate(_node, amount);

        emit Stake(_node, amount);
    }

    function _unstake(
        address _account,
        address _node,
        uint256 _amount
    ) internal override returns (uint256 unstakeLockID) {
        uint256 amount = _amount;

        require(amount > 0, "ZERO_AMOUNT");

        unstakeLockID = withdrawPool.unlock(_account, amount);

        currentPrincipal -= amount;

        emit Unstake(_account, _node, amount, unstakeLockID);
    }

    function processUnstake(address _node) external onlyGov {
        uint256 amount = withdrawPool.processUnlocks();


        address node_ = _node;
        if (node_ == address(0)) {
            node_ = node;
        }


        IGraph.DelegationPool memory delPool = graph.delegationPools(node_);

        uint256 totalShares = delPool.shares;
        uint256 totalTokens = delPool.tokens;

        uint256 shares = (amount * totalShares) / totalTokens;



        graph.undelegate(node_, shares);

        emit ProcessUnstakes(msg.sender, node_, amount);
    }

    function _withdraw(address _account, uint256 _withdrawalID) internal override {
        uint256 amount = withdrawPool.withdraw(_withdrawalID, _account);



        try steak.transfer(_account, amount) {} catch {

            uint256 steakBal = steak.balanceOf(address(this));
            if (amount > steakBal) {
                steak.transfer(_account, steakBal);
            }
        }

        emit Withdraw(_account, amount, _withdrawalID);
    }

    function processWithdraw(address _node) external onlyGov {

        address node_ = _node;
        if (node_ == address(0)) {
            node_ = node;
        }

        uint256 balBefore = steak.balanceOf(address(this));

        graph.withdrawDelegated(node_, address(0));

        uint256 balAfter = steak.balanceOf(address(this));
        uint256 amount = balAfter - balBefore;

        withdrawPool.processWihdrawal(amount);

        emit ProcessWithdraws(msg.sender, amount);
    }

    function _claimRewards() internal override {
        IGraph.Delegation memory delegation = graph.getDelegation(node, address(this));
        IGraph.DelegationPool memory delPool = graph.delegationPools(node);

        uint256 delShares = delegation.shares;
        uint256 totalShares = delPool.shares;
        uint256 totalTokens = delPool.tokens;

        if (totalShares == 0) return;

        uint256 stake = (delShares * totalTokens) / totalShares;

        _processNewStake(stake);
    }

    function _processNewStake(uint256 _newStake) internal override {

        uint256 currentPrincipal_ = currentPrincipal;


        uint256 toBeStaked = _calcDepositOut(steak.balanceOf(address(this)) - withdrawPool.amount);




        uint256 stake_ = _newStake + toBeStaked - withdrawPool.pendingUnlock
            - pendingFees - pendingLiquidityFees;



        if (stake_ <= currentPrincipal_) {
            currentPrincipal = stake_;
            uint256 diff = currentPrincipal_ - stake_;

            uint256 totalUnstakePoolTokens = withdrawPool.totalTokens();
            uint256 totalTokens = totalUnstakePoolTokens + currentPrincipal_;
            if (totalTokens == 0) return;

            uint256 unstakePoolSlash = diff * totalUnstakePoolTokens / totalTokens;
            withdrawPool.updateTotalTokens(totalUnstakePoolTokens - unstakePoolSlash);

            emit RewardsClaimed(-int256(diff), stake_, currentPrincipal_);

            return;
        }


        uint256 totalRewards = stake_ - currentPrincipal_;


        uint256 fees = MathUtils.percOf(totalRewards, protocolFee);
        pendingFees += fees;


        uint256 liquidityFees = MathUtils.percOf(totalRewards, liquidityFee);
        pendingLiquidityFees += liquidityFees;

        stake_ = stake_ - fees - liquidityFees;
        currentPrincipal = stake_;

        emit RewardsClaimed(int256(stake_ - currentPrincipal_), stake_, currentPrincipal_);
    }

    function _setStakingContract(address _stakingContract) internal override {
        graph = IGraph(_stakingContract);
        emit GovernanceUpdate("STAKING_CONTRACT");
    }
}
