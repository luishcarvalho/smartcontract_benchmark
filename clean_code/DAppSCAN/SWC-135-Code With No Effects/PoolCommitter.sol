
pragma solidity 0.8.7;

import "../interfaces/IPoolCommitter.sol";
import "../interfaces/ILeveragedPool.sol";
import "../interfaces/IPoolFactory.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PoolSwapLibrary.sol";


contract PoolCommitter is IPoolCommitter, Initializable {

    uint128 public constant LONG_INDEX = 0;
    uint128 public constant SHORT_INDEX = 1;

    address public leveragedPool;
    uint128 public updateIntervalId = 1;


    address[2] public tokens;

    mapping(uint256 => Prices) public priceHistory;
    mapping(address => Balance) public userAggregateBalance;


    mapping(uint256 => TotalCommitment) public totalPoolCommitments;

    mapping(address => mapping(uint256 => UserCommitment)) public userCommitments;

    mapping(address => uint256) public lastUpdatedIntervalId;

    mapping(address => uint256[]) public unAggregatedCommitments;

    uint256[] private storageArrayPlaceHolder;

    address public factory;

    constructor(address _factory) {
        require(_factory != address(0), "Factory address cannot be null");
        factory = _factory;
    }

    function initialize(address _factory) external override initializer {
        require(_factory != address(0), "Factory address cannot be 0 address");
        factory = _factory;
    }











    function applyCommitment(
        ILeveragedPool pool,
        CommitType commitType,
        uint256 amount,
        bool fromAggregateBalance,
        UserCommitment storage userCommit,
        TotalCommitment storage totalCommit
    ) private {
        Balance memory balance = userAggregateBalance[msg.sender];

        if (commitType == CommitType.LongMint) {
            userCommit.longMintAmount += amount;
            totalCommit.longMintAmount += amount;

        } else if (commitType == CommitType.LongBurn) {
            userCommit.longBurnAmount += amount;
            totalCommit.longBurnAmount += amount;

            if (fromAggregateBalance) {

                userCommit.balanceLongBurnAmount += amount;

                require(userCommit.balanceLongBurnAmount <= balance.longTokens, "Insufficient pool tokens");

                pool.burnTokens(true, amount, leveragedPool);
            } else {

                pool.burnTokens(true, amount, msg.sender);
            }
        } else if (commitType == CommitType.ShortMint) {
            userCommit.shortMintAmount += amount;
            totalCommit.shortMintAmount += amount;

        } else if (commitType == CommitType.ShortBurn) {
            userCommit.shortBurnAmount += amount;
            totalCommit.shortBurnAmount += amount;
            if (fromAggregateBalance) {

                userCommit.balanceShortBurnAmount += amount;

                require(userCommit.balanceShortBurnAmount <= balance.shortTokens, "Insufficient pool tokens");

                pool.burnTokens(false, amount, leveragedPool);
            } else {

                pool.burnTokens(false, amount, msg.sender);
            }
        } else if (commitType == CommitType.LongBurnShortMint) {
            userCommit.longBurnShortMintAmount += amount;
            totalCommit.longBurnShortMintAmount += amount;
            if (fromAggregateBalance) {
                userCommit.balanceLongBurnMintAmount += amount;
                require(userCommit.balanceLongBurnMintAmount <= balance.longTokens, "Insufficient pool tokens");
                pool.burnTokens(true, amount, leveragedPool);
            } else {
                pool.burnTokens(true, amount, msg.sender);
            }
        } else if (commitType == CommitType.ShortBurnLongMint) {
            userCommit.shortBurnLongMintAmount += amount;
            totalCommit.shortBurnLongMintAmount += amount;
            if (fromAggregateBalance) {
                userCommit.balanceShortBurnMintAmount += amount;
                require(userCommit.balanceShortBurnMintAmount <= balance.shortTokens, "Insufficient pool tokens");
                pool.burnTokens(false, amount, leveragedPool);
            } else {
                pool.burnTokens(false, amount, msg.sender);
            }
        }
    }










    function commit(
        CommitType commitType,
        uint256 amount,
        bool fromAggregateBalance
    ) external override updateBalance {
        require(amount > 0, "Amount must not be zero");
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        uint256 updateInterval = pool.updateInterval();
        uint256 lastPriceTimestamp = pool.lastPriceTimestamp();
        uint256 frontRunningInterval = pool.frontRunningInterval();

        uint256 appropriateUpdateIntervalId = PoolSwapLibrary.appropriateUpdateIntervalId(
            block.timestamp,
            lastPriceTimestamp,
            frontRunningInterval,
            updateInterval,
            updateIntervalId
        );
        TotalCommitment storage totalCommit = totalPoolCommitments[appropriateUpdateIntervalId];
        UserCommitment storage userCommit = userCommitments[msg.sender][appropriateUpdateIntervalId];

        userCommit.updateIntervalId = appropriateUpdateIntervalId;

        uint256 length = unAggregatedCommitments[msg.sender].length;
        if (length == 0 || unAggregatedCommitments[msg.sender][length - 1] < appropriateUpdateIntervalId) {
            unAggregatedCommitments[msg.sender].push(appropriateUpdateIntervalId);
        }

        if (commitType == CommitType.LongMint || commitType == CommitType.ShortMint) {


            if (!fromAggregateBalance) {
                pool.quoteTokenTransferFrom(msg.sender, leveragedPool, amount);
            } else {

                userAggregateBalance[msg.sender].settlementTokens -= amount;
            }
        }

        applyCommitment(pool, commitType, amount, fromAggregateBalance, userCommit, totalCommit);

        emit CreateCommit(msg.sender, amount, commitType);
    }





    function claim(address user) external override updateBalance {
        Balance memory balance = userAggregateBalance[user];
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        if (balance.settlementTokens > 0) {
            pool.quoteTokenTransfer(user, balance.settlementTokens);
        }
        if (balance.longTokens > 0) {
            pool.poolTokenTransfer(true, user, balance.longTokens);
        }
        if (balance.shortTokens > 0) {
            pool.poolTokenTransfer(false, user, balance.shortTokens);
        }
        delete userAggregateBalance[user];
        emit Claim(user);
    }

    function executeGivenCommitments(TotalCommitment memory _commits) internal {
        ILeveragedPool pool = ILeveragedPool(leveragedPool);

        BalancesAndSupplies memory balancesAndSupplies = BalancesAndSupplies({
            shortBalance: pool.shortBalance(),
            longBalance: pool.longBalance(),
            longTotalSupplyBefore: IERC20(tokens[0]).totalSupply(),
            shortTotalSupplyBefore: IERC20(tokens[1]).totalSupply()
        });

        uint256 totalLongBurn = _commits.longBurnAmount + _commits.longBurnShortMintAmount;
        uint256 totalShortBurn = _commits.shortBurnAmount + _commits.shortBurnLongMintAmount;

        priceHistory[updateIntervalId] = Prices({
            longPrice: PoolSwapLibrary.getPrice(
                balancesAndSupplies.longBalance,
                balancesAndSupplies.longTotalSupplyBefore + totalLongBurn
            ),
            shortPrice: PoolSwapLibrary.getPrice(
                balancesAndSupplies.shortBalance,
                balancesAndSupplies.shortTotalSupplyBefore + totalShortBurn
            )
        });


        uint256 longBurnInstantMintAmount = PoolSwapLibrary.getWithdrawAmountOnBurn(
            balancesAndSupplies.longTotalSupplyBefore,
            _commits.longBurnShortMintAmount,
            balancesAndSupplies.longBalance,
            totalLongBurn
        );

        uint256 shortBurnInstantMintAmount = PoolSwapLibrary.getWithdrawAmountOnBurn(
            balancesAndSupplies.shortTotalSupplyBefore,
            _commits.shortBurnLongMintAmount,
            balancesAndSupplies.shortBalance,
            totalShortBurn
        );


        uint256 longMintAmount = PoolSwapLibrary.getMintAmount(
            balancesAndSupplies.longTotalSupplyBefore,
            _commits.longMintAmount + shortBurnInstantMintAmount,
            balancesAndSupplies.longBalance,
            totalLongBurn
        );

        if (longMintAmount > 0) {
            pool.mintTokens(true, longMintAmount, leveragedPool);
        }


        uint256 longBurnAmount = PoolSwapLibrary.getWithdrawAmountOnBurn(
            balancesAndSupplies.longTotalSupplyBefore,
            totalLongBurn,
            balancesAndSupplies.longBalance,
            totalLongBurn
        );


        uint256 shortMintAmount = PoolSwapLibrary.getMintAmount(
            balancesAndSupplies.shortTotalSupplyBefore,
            _commits.shortMintAmount + longBurnInstantMintAmount,
            balancesAndSupplies.shortBalance,
            totalShortBurn
        );

        if (shortMintAmount > 0) {
            pool.mintTokens(false, shortMintAmount, leveragedPool);
        }


        uint256 shortBurnAmount = PoolSwapLibrary.getWithdrawAmountOnBurn(
            balancesAndSupplies.shortTotalSupplyBefore,
            totalShortBurn,
            balancesAndSupplies.shortBalance,
            totalShortBurn
        );

        uint256 newLongBalance = balancesAndSupplies.longBalance +
            _commits.longMintAmount -
            longBurnAmount +
            shortBurnInstantMintAmount;
        uint256 newShortBalance = balancesAndSupplies.shortBalance +
            _commits.shortMintAmount -
            shortBurnAmount +
            longBurnInstantMintAmount;


        pool.setNewPoolBalances(newLongBalance, newShortBalance);
    }

    function executeCommitments() external override onlyPool {
        ILeveragedPool pool = ILeveragedPool(leveragedPool);
        executeGivenCommitments(totalPoolCommitments[updateIntervalId]);
        delete totalPoolCommitments[updateIntervalId];
        updateIntervalId += 1;

        uint32 counter = 2;
        uint256 lastPriceTimestamp = pool.lastPriceTimestamp();
        uint256 updateInterval = pool.updateInterval();

        while (true) {
            if (block.timestamp >= lastPriceTimestamp + updateInterval * counter) {

                executeGivenCommitments(totalPoolCommitments[updateIntervalId]);
                delete totalPoolCommitments[updateIntervalId];
                updateIntervalId += 1;
            } else {
                break;
            }
            counter += 1;
        }
    }

    function updateBalanceSingleCommitment(UserCommitment memory _commit)
        internal
        view
        returns (
            uint256 _newLongTokens,
            uint256 _newShortTokens,
            uint256 _newSettlementTokens
        )
    {
        PoolSwapLibrary.UpdateData memory updateData = PoolSwapLibrary.UpdateData({
            longPrice: priceHistory[_commit.updateIntervalId].longPrice,
            shortPrice: priceHistory[_commit.updateIntervalId].shortPrice,
            currentUpdateIntervalId: updateIntervalId,
            updateIntervalId: _commit.updateIntervalId,
            longMintAmount: _commit.longMintAmount,
            longBurnAmount: _commit.longBurnAmount,
            shortMintAmount: _commit.shortMintAmount,
            shortBurnAmount: _commit.shortBurnAmount,
            longBurnShortMintAmount: _commit.longBurnShortMintAmount,
            shortBurnLongMintAmount: _commit.shortBurnLongMintAmount
        });

        (_newLongTokens, _newShortTokens, _newSettlementTokens) = PoolSwapLibrary.getUpdatedAggregateBalance(
            updateData
        );
    }




    function updateAggregateBalance(address user) public override {
        Balance storage balance = userAggregateBalance[user];

        BalanceUpdate memory update = BalanceUpdate({
            _updateIntervalId: updateIntervalId,
            _newLongTokensSum: 0,
            _newShortTokensSum: 0,
            _newSettlementTokensSum: 0,
            _balanceLongBurnAmount: 0,
            _balanceShortBurnAmount: 0
        });



        uint256[] memory currentIntervalIds = unAggregatedCommitments[user];
        uint256 unAggregatedLength = currentIntervalIds.length;
        for (uint256 i = 0; i < unAggregatedLength; i++) {
            uint256 id = currentIntervalIds[i];
            if (currentIntervalIds[i] == 0) {
                continue;
            }
            UserCommitment memory commitment = userCommitments[user][id];




            update._balanceLongBurnAmount += commitment.balanceLongBurnAmount + commitment.balanceLongBurnMintAmount;
            update._balanceShortBurnAmount += commitment.balanceShortBurnAmount + commitment.balanceShortBurnMintAmount;
            if (commitment.updateIntervalId < updateIntervalId) {
                (
                    uint256 _newLongTokens,
                    uint256 _newShortTokens,
                    uint256 _newSettlementTokens
                ) = updateBalanceSingleCommitment(commitment);
                update._newLongTokensSum += _newLongTokens;
                update._newShortTokensSum += _newShortTokens;
                update._newSettlementTokensSum += _newSettlementTokens;

                delete userCommitments[user][i];
                delete unAggregatedCommitments[user][i];
            } else {

                userCommitments[user][id].balanceLongBurnAmount = 0;
                userCommitments[user][id].balanceShortBurnAmount = 0;
                userCommitments[user][id].balanceLongBurnMintAmount = 0;
                userCommitments[user][id].balanceShortBurnMintAmount = 0;

                storageArrayPlaceHolder.push(currentIntervalIds[i]);
            }
        }

        delete unAggregatedCommitments[user];
        unAggregatedCommitments[user] = storageArrayPlaceHolder;

        delete storageArrayPlaceHolder;


        balance.longTokens += update._newLongTokensSum;
        balance.longTokens -= update._balanceLongBurnAmount;
        balance.shortTokens += update._newShortTokensSum;
        balance.shortTokens -= update._balanceShortBurnAmount;
        balance.settlementTokens += update._newSettlementTokensSum;

        emit AggregateBalanceUpdated(user);
    }




    function getAggregateBalance(address user) public view override returns (Balance memory) {
        Balance memory _balance = userAggregateBalance[user];

        BalanceUpdate memory update = BalanceUpdate({
            _updateIntervalId: updateIntervalId,
            _newLongTokensSum: 0,
            _newShortTokensSum: 0,
            _newSettlementTokensSum: 0,
            _balanceLongBurnAmount: 0,
            _balanceShortBurnAmount: 0
        });



        uint256[] memory currentIntervalIds = unAggregatedCommitments[user];
        uint256 unAggregatedLength = currentIntervalIds.length;
        for (uint256 i = 0; i < unAggregatedLength; i++) {
            uint256 id = currentIntervalIds[i];
            if (currentIntervalIds[i] == 0) {
                continue;
            }
            UserCommitment memory commitment = userCommitments[user][id];




            update._balanceLongBurnAmount += commitment.balanceLongBurnAmount + commitment.balanceLongBurnMintAmount;
            update._balanceShortBurnAmount += commitment.balanceShortBurnAmount + commitment.balanceShortBurnMintAmount;
            if (commitment.updateIntervalId < updateIntervalId) {
                (
                    uint256 _newLongTokens,
                    uint256 _newShortTokens,
                    uint256 _newSettlementTokens
                ) = updateBalanceSingleCommitment(commitment);
                update._newLongTokensSum += _newLongTokens;
                update._newShortTokensSum += _newShortTokens;
                update._newSettlementTokensSum += _newSettlementTokens;
            }
        }


        _balance.longTokens += update._newLongTokensSum;
        _balance.longTokens -= update._balanceLongBurnAmount;
        _balance.shortTokens += update._newShortTokensSum;
        _balance.shortTokens -= update._balanceShortBurnAmount;
        _balance.settlementTokens += update._newSettlementTokensSum;

        return _balance;
    }

    function setQuoteAndPool(address _quoteToken, address _leveragedPool) external override onlyFactory {
        require(_quoteToken != address(0), "Quote token address cannot be 0 address");
        require(_leveragedPool != address(0), "Leveraged pool address cannot be 0 address");

        leveragedPool = _leveragedPool;
        IERC20 _token = IERC20(_quoteToken);
        bool approvalSuccess = _token.approve(leveragedPool, _token.totalSupply());
        require(approvalSuccess, "ERC20 approval failed");
        tokens = ILeveragedPool(leveragedPool).poolTokens();
    }

    modifier updateBalance() {
        updateAggregateBalance(msg.sender);
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Committer: not factory");
        _;
    }

    modifier onlyPool() {
        require(msg.sender == leveragedPool, "msg.sender not leveragedPool");
        _;
    }
}
