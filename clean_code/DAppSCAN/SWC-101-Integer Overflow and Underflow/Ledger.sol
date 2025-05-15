
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../interfaces/IOracleMaster.sol";
import "../interfaces/ILido.sol";
import "../interfaces/IRelayEncoder.sol";
import "../interfaces/IXcmTransactor.sol";
import "../interfaces/IController.sol";
import "../interfaces/Types.sol";

import "./utils/LedgerUtils.sol";
import "./utils/ReportUtils.sol";



contract Ledger {
    using LedgerUtils for Types.OracleData;
    using SafeCast for uint256;

    event DownwardComplete(uint128 amount);
    event UpwardComplete(uint128 amount);
    event Rewards(uint128 amount, uint128 balance);
    event Slash(uint128 amount, uint128 balance);


    bytes32 public stashAccount;


    bytes32 public controllerAccount;


    uint128 public totalBalance;


    uint128 public lockedBalance;


    uint128 public activeBalance;


    Types.LedgerStatus public status;


    uint128 public cachedTotalBalance;


    uint128 public transferUpwardBalance;
    uint128 public transferDownwardBalance;



    IERC20 internal vKSM;

    IController internal controller;


    ILido public LIDO;


    uint128 public MIN_NOMINATOR_BALANCE;



    bytes32 internal constant GARANTOR = 0x00;


    modifier onlyLido() {
        require(msg.sender == address(LIDO), "LEDGED: NOT_LIDO");
        _;
    }

    modifier onlyOracle() {
        address oracle = IOracleMaster(ILido(LIDO).ORACLE_MASTER()).getOracle(address(this));
        require(msg.sender == oracle, "LEDGED: NOT_ORACLE");
        _;
    }









    function initialize(
        bytes32 _stashAccount,
        bytes32 _controllerAccount,
        address _vKSM,
        address _controller,
        uint128 _minNominatorBalance
    ) external {
        require(address(vKSM) == address(0), "LEDGED: ALREADY_INITIALIZED");


        stashAccount = _stashAccount;

        controllerAccount = _controllerAccount;

        status = Types.LedgerStatus.None;

        LIDO = ILido(msg.sender);

        vKSM = IERC20(_vKSM);

        controller = IController(_controller);

        MIN_NOMINATOR_BALANCE = _minNominatorBalance;


    }






    function setMinNominatorBalance(uint128 _minNominatorBalance) external onlyLido {
        MIN_NOMINATOR_BALANCE = _minNominatorBalance;
    }

    function refreshAllowances() external {
        vKSM.approve(address(controller), type(uint256).max);
    }





    function ledgerStake() public view returns (uint256) {
        return LIDO.ledgerStake(address(this));
    }




    function isEmpty() external view returns (bool) {
        return totalBalance == 0 && transferUpwardBalance == 0 && transferDownwardBalance == 0;
    }






    function nominate(bytes32[] calldata _validators) external onlyLido {
        require(activeBalance >= MIN_NOMINATOR_BALANCE, "LEDGED: NOT_ENOUGH_STAKE");
        controller.nominate(_validators);
    }









    function pushData(uint64 _eraId, Types.OracleData memory _report) external onlyOracle {
        require(stashAccount == _report.stashAccount, "LEDGED: STASH_ACCOUNT_MISMATCH");

        status = _report.stakeStatus;
        activeBalance = _report.activeBalance;

        (uint128 unlockingBalance, uint128 withdrawableBalance) = _report.getTotalUnlocking(_eraId);
        uint128 nonWithdrawableBalance = unlockingBalance - withdrawableBalance;

        if (!_processRelayTransfers(_report)) {
            return;
        }
        uint128 _cachedTotalBalance = cachedTotalBalance;
        if (_cachedTotalBalance < _report.stashBalance) {
            uint128 reward = _report.stashBalance - _cachedTotalBalance;
            LIDO.distributeRewards(reward, _report.stashBalance);

            emit Rewards(reward, _report.stashBalance);
        }
        else if (_cachedTotalBalance > _report.stashBalance) {
            uint128 slash = _cachedTotalBalance - _report.stashBalance;
            LIDO.distributeLosses(slash, _report.stashBalance);

            emit Slash(slash, _report.stashBalance);
        }

        uint128 _ledgerStake = ledgerStake().toUint128();


        if (_report.stashBalance <= _ledgerStake) {





            uint128 deficit = _ledgerStake - _report.stashBalance;


            if (deficit > 0) {
                uint128 lidoBalance = uint128(LIDO.avaliableForStake());
                uint128 forTransfer = lidoBalance > deficit ? deficit : lidoBalance;

                if (forTransfer > 0) {
                    vKSM.transferFrom(address(LIDO), address(this), forTransfer);
                    controller.transferToRelaychain(forTransfer);
                    transferUpwardBalance += forTransfer;
                }
            }


            if (unlockingBalance > 0) {
                controller.rebond(unlockingBalance);
            }

            uint128 relayFreeBalance = _report.getFreeBalance();

            if (relayFreeBalance > 0 &&
                (_report.stakeStatus == Types.LedgerStatus.Nominator || _report.stakeStatus == Types.LedgerStatus.Idle)) {
                controller.bondExtra(relayFreeBalance);
            } else if (_report.stakeStatus == Types.LedgerStatus.None && relayFreeBalance >= MIN_NOMINATOR_BALANCE) {
                controller.bond(controllerAccount, relayFreeBalance);
            }

        }
        else if (_report.stashBalance > _ledgerStake) {






            if (_ledgerStake < MIN_NOMINATOR_BALANCE && status != Types.LedgerStatus.Idle) {
                controller.chill();
            }

            uint128 deficit = _report.stashBalance - _ledgerStake;
            uint128 relayFreeBalance = _report.getFreeBalance();


            if (relayFreeBalance > 0) {
                uint128 forTransfer = relayFreeBalance > deficit ? deficit : relayFreeBalance;
                controller.transferToParachain(forTransfer);
                transferDownwardBalance += forTransfer;
                deficit -= forTransfer;
                relayFreeBalance -= forTransfer;
            }


            if (deficit > 0 && withdrawableBalance > 0) {
                controller.withdrawUnbonded();
                deficit -= withdrawableBalance > deficit ? deficit : withdrawableBalance;
            }


            if (nonWithdrawableBalance < deficit) {

                uint128 forUnbond = deficit - nonWithdrawableBalance;
                controller.unbond(forUnbond);


            }


            if (relayFreeBalance > 0) {
                controller.bondExtra(relayFreeBalance);
            }
        }

        cachedTotalBalance = _report.stashBalance;
    }

    function _processRelayTransfers(Types.OracleData memory _report) internal returns(bool) {

        uint128 _transferDownwardBalance = transferDownwardBalance;
        if (_transferDownwardBalance > 0) {
            uint128 totalDownwardTransferred = uint128(vKSM.balanceOf(address(this)));

            if (totalDownwardTransferred >= _transferDownwardBalance ) {

                vKSM.transfer(address(LIDO), _transferDownwardBalance);


                cachedTotalBalance -= _transferDownwardBalance;
                transferDownwardBalance = 0;

                emit DownwardComplete(_transferDownwardBalance);
                _transferDownwardBalance = 0;
            }
        }


        uint128 _transferUpwardBalance = transferUpwardBalance;
        if (_transferUpwardBalance > 0) {
            uint128 ledgerFreeBalance = (totalBalance - lockedBalance);

            uint128 freeBalanceIncrement = _report.getFreeBalance() - ledgerFreeBalance;

            if (freeBalanceIncrement >= _transferUpwardBalance) {
                cachedTotalBalance += _transferUpwardBalance;

                transferUpwardBalance = 0;
                emit UpwardComplete(_transferUpwardBalance);
                _transferUpwardBalance = 0;
            }
        }

        if (_transferDownwardBalance == 0 && _transferUpwardBalance == 0) {

            totalBalance = _report.stashBalance;
            lockedBalance = _report.totalBalance;
            return true;
        }

        return false;
    }
}
