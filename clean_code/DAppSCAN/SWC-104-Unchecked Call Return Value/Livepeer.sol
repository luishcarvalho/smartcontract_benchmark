



pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../libs/MathUtils.sol";

import "../../Tenderizer.sol";
import "./ILivepeer.sol";

import "../../WithdrawalLocks.sol";

import "../../../interfaces/IWETH.sol";
import "../../../interfaces/ISwapRouter.sol";

import { ITenderSwapFactory } from "../../../tenderswap/TenderSwapFactory.sol";

contract Livepeer is Tenderizer {
    using WithdrawalLocks for WithdrawalLocks.Locks;

    uint256 private constant MAX_ROUND = 2**256 - 1;

    IWETH private WETH;
    ISwapRouterWithWETH public uniswapRouter;
    uint24 private constant UNISWAP_POOL_FEE = 10000;

    ILivepeer livepeer;

    uint256 private constant ethFees_threshold = 1**17;

    WithdrawalLocks.Locks withdrawLocks;

    function initialize(
        IERC20 _steak,
        string calldata _symbol,
        ILivepeer _livepeer,
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
        livepeer = _livepeer;
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


        steak.approve(address(livepeer), amount);


        livepeer.bond(amount, _node);

        emit Stake(_node, amount);
    }


    function _unstake(
        address _account,
        address _node,
        uint256 _amount
    ) internal override returns (uint256 withdrawalLockID) {
        uint256 amount = _amount;


        if (_account != gov) require(amount > 0, "ZERO_AMOUNT");
        if (amount == 0) {
            amount = livepeer.pendingStake(address(this), MAX_ROUND);
            require(amount > 0, "ZERO_STAKE");
        }

        currentPrincipal -= amount;


        livepeer.unbond(amount);


        withdrawalLockID = withdrawLocks.unlock(_account, amount);

        emit Unstake(_account, _node, amount, withdrawalLockID);
    }

    function _withdraw(address _account, uint256 _withdrawalID) internal override {
        uint256 amount = withdrawLocks.withdraw(_account, _withdrawalID);


        livepeer.withdrawStake(_withdrawalID);



        steak.transfer(_account, amount);

        emit Withdraw(_account, amount, _withdrawalID);
    }












    function _claimSecondaryRewards() internal {
        uint256 ethFees = livepeer.pendingFees(address(this), MAX_ROUND);


        if (ethFees >= ethFees_threshold) {
            livepeer.withdrawFees();


            uint256 bal = address(this).balance;
            WETH.deposit{ value: bal }();
            WETH.approve(address(uniswapRouter), bal);


            if (address(uniswapRouter) != address(0)) {
                ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(WETH),
                    tokenOut: address(steak),
                    fee: UNISWAP_POOL_FEE,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: bal,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

                try uniswapRouter.exactInputSingle(params) returns (


























