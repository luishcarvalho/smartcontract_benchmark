
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../interfaces/IOracleMaster.sol";
import "../interfaces/ILedger.sol";
import "../interfaces/IController.sol";
import "../interfaces/IAuthManager.sol";

import "./stKSM.sol";


contract Lido is stKSM, Initializable {
    using Clones for address;
    using SafeCast for uint256;


    event Deposited(address indexed sender, uint256 amount);


    event Redeemed(address indexed receiver, uint256 amount);


    event Claimed(address indexed receiver, uint256 amount);


    event FeeSet(uint16 fee, uint16 feeOperatorsBP, uint16 feeTreasuryBP,  uint16 feeDevelopersBP);


    event Rewards(address ledger, uint256 rewards, uint256 balance);


    event Losses(address ledger, uint256 losses, uint256 balance);


    event LedgerAdd(
        address addr,
        bytes32 stashAccount,
        bytes32 controllerAccount,
        uint256 share
    );


    event LedgerRemove(
        address addr
    );


    event LedgerSetShare(
        address addr,
        uint256 share
    );


    uint256 private fundRaisedBalance;

    struct Claim {
        uint256 balance;
        uint64 timeout;
    }

    mapping(address => Claim[]) public claimOrders;


    uint256 public pendingClaimsTotal;


    address[] private ledgers;


    mapping(bytes32 => address) private ledgerByStash;


    mapping(address => uint256) private ledgerByAddress;


    mapping(address => uint256) public ledgerShares;


    uint256 public ledgerSharesTotal;


    uint256 public bufferedDeposits;


    uint256 public bufferedRedeems;


    mapping(address => uint256) public ledgerStake;



    IERC20 public vKSM;

    address public controller;



    address public AUTH_MANAGER;


    uint256 public MAX_LEDGERS_AMOUNT;


    bytes32 public GARANTOR;





    Types.Fee private FEE;


    address public LEDGER_CLONE;


    address public ORACLE_MASTER;


    Types.RelaySpec public RELAY_SPEC;


    address public developers;


    address public treasury;



    uint16 internal constant DEFAULT_DEVELOPERS_FEE = 140;
    uint16 internal constant DEFAULT_OPERATORS_FEE = 300;
    uint16 internal constant DEFAULT_TREASURY_FEE = 560;


    uint256 internal constant MEMBER_NOT_FOUND = type(uint256).max;


    bytes32 internal constant ROLE_SPEC_MANAGER = keccak256("ROLE_SPEC_MANAGER");


    bytes32 internal constant ROLE_PAUSE_MANAGER = keccak256("ROLE_PAUSE_MANAGER");


    bytes32 internal constant ROLE_FEE_MANAGER = keccak256("ROLE_FEE_MANAGER");


    bytes32 internal constant ROLE_ORACLE_MANAGER = keccak256("ROLE_ORACLE_MANAGER");


    bytes32 internal constant ROLE_LEDGER_MANAGER = keccak256("ROLE_LEDGER_MANAGER");


    bytes32 internal constant ROLE_STAKE_MANAGER = keccak256("ROLE_STAKE_MANAGER");


    bytes32 internal constant ROLE_TREASURY = keccak256("ROLE_SET_TREASURY");


    bytes32 internal constant ROLE_DEVELOPERS = keccak256("ROLE_SET_DEVELOPERS");


    uint16 internal constant MAX_CLAIMS = 10;


    modifier auth(bytes32 role) {
        require(IAuthManager(AUTH_MANAGER).has(role, msg.sender), "LIDO: UNAUTHORIZED");
        _;
    }









    function initialize(
        address _authManager,
        address _vKSM,
        address _controller,
        address _developers,
        address _treasury
    ) external initializer {
        vKSM = IERC20(_vKSM);
        controller = _controller;
        AUTH_MANAGER = _authManager;

        MAX_LEDGERS_AMOUNT = 200;
        Types.Fee memory _fee;
        _fee.total = DEFAULT_OPERATORS_FEE + DEFAULT_DEVELOPERS_FEE + DEFAULT_TREASURY_FEE;
        _fee.operators = DEFAULT_OPERATORS_FEE;
        _fee.developers = DEFAULT_DEVELOPERS_FEE;
        _fee.treasury = DEFAULT_TREASURY_FEE;
        FEE = _fee;

        GARANTOR = 0x00;

        treasury = _treasury;
        developers =_developers;
    }




    fallback() external {
        revert("FORBIDDEN");
    }




    function setTreasury(address _treasury) external auth(ROLE_TREASURY) {
        treasury = _treasury;
    }




    function setDevelopers(address _developers) external auth(ROLE_DEVELOPERS) {
        developers = _developers;
    }







    function getUnbonded(address _holder) external view returns (uint256 waiting, uint256 unbonded) {
        uint256 waitingToUnbonding = 0;
        uint256 readyToClaim = 0;
        Claim[] storage orders = claimOrders[_holder];

        for (uint256 i = 0; i < orders.length; ++i) {
            if (orders[i].timeout < block.timestamp) {
                readyToClaim += orders[i].balance;
            }
            else {
                waitingToUnbonding += orders[i].balance;
            }
        }
        return (waitingToUnbonding, readyToClaim);
    }





    function getStashAccounts() public view returns (bytes32[] memory) {
        bytes32[] memory _stashes = new bytes32[](ledgers.length);

        for (uint i = 0; i < ledgers.length; i++) {
            _stashes[i] = bytes32(ILedger(ledgers[i]).stashAccount());
        }
        return _stashes;
    }






    function getLedgerAddresses() public view returns (address[] memory) {
        return ledgers;
    }







    function findLedger(bytes32 _stashAccount) external view returns (address) {
        return ledgerByStash[_stashAccount];
    }






    function avaliableForStake() external view returns(uint256) {
        uint256 freeBalance = vKSM.balanceOf(address(this));
        return freeBalance < pendingClaimsTotal ? 0 : freeBalance - pendingClaimsTotal;
    }






    function setRelaySpec(Types.RelaySpec calldata _relaySpec) external auth(ROLE_SPEC_MANAGER) {
        require(ORACLE_MASTER != address(0), "LIDO: ORACLE_MASTER_UNDEFINED");
        require(_relaySpec.genesisTimestamp > 0, "LIDO: BAD_GENESIS_TIMESTAMP");
        require(_relaySpec.secondsPerEra > 0, "LIDO: BAD_SECONDS_PER_ERA");
        require(_relaySpec.unbondingPeriod > 0, "LIDO: BAD_UNBONDING_PERIOD");
        require(_relaySpec.maxValidatorsPerLedger > 0, "LIDO: BAD_MAX_VALIDATORS_PER_LEDGER");



        RELAY_SPEC = _relaySpec;

        IOracleMaster(ORACLE_MASTER).setRelayParams(_relaySpec.genesisTimestamp, _relaySpec.secondsPerEra);
    }






    function setOracleMaster(address _oracleMaster) external auth(ROLE_ORACLE_MANAGER) {
        require(ORACLE_MASTER == address(0), "LIDO: ORACLE_MASTER_ALREADY_DEFINED");
        ORACLE_MASTER = _oracleMaster;
        IOracleMaster(ORACLE_MASTER).setLido(address(this));
    }






    function setLedgerClone(address _ledgerClone) external auth(ROLE_LEDGER_MANAGER) {
        LEDGER_CLONE = _ledgerClone;
    }







    function setFee(uint16 _feeOperators, uint16 _feeTreasury,  uint16 _feeDevelopers) external auth(ROLE_FEE_MANAGER) {
        Types.Fee memory _fee;
        _fee.total = _feeTreasury + _feeOperators + _feeDevelopers;
        require(_fee.total <= 10000 && (_feeTreasury > 0 || _feeDevelopers > 0) , "LIDO: FEE_DONT_ADD_UP");

        emit FeeSet(_fee.total, _feeOperators, _feeTreasury, _feeDevelopers);

        _fee.developers = _feeDevelopers;
        _fee.operators = _feeOperators;
        _fee.treasury = _feeTreasury;
        FEE = _fee;
    }




    function getFee() external view returns (uint16){
        return FEE.total;
    }




    function getOperatorsFee() external view returns (uint16){
        return FEE.operators;
    }




    function getTreasuryFee() external view returns (uint16){
       return FEE.treasury;
    }




    function getDevelopersFee() external view returns (uint16){
        return FEE.developers;
    }





    function pause() external auth(ROLE_PAUSE_MANAGER) {
        _pause();
    }





    function resume() external auth(ROLE_PAUSE_MANAGER) {
        _unpause();
    }











    function addLedger(
        bytes32 _stashAccount,
        bytes32 _controllerAccount,
        uint16 _index,
        uint256 _share
    )
        external
        auth(ROLE_LEDGER_MANAGER)
        returns(address)
    {
        require(LEDGER_CLONE != address(0), "LIDO: UNSPECIFIED_LEDGER_CLONE");
        require(ORACLE_MASTER != address(0), "LIDO: NO_ORACLE_MASTER");
        require(ledgers.length < MAX_LEDGERS_AMOUNT, "LIDO: LEDGERS_POOL_LIMIT");
        require(ledgerByStash[_stashAccount] == address(0), "LIDO: STASH_ALREADY_EXISTS");

        address ledger = LEDGER_CLONE.cloneDeterministic(_stashAccount);

        ILedger(ledger).initialize(
            _stashAccount,
            _controllerAccount,
            address(vKSM),
            controller,
            RELAY_SPEC.minNominatorBalance
        );
        ledgers.push(ledger);
        ledgerByStash[_stashAccount] = ledger;
        ledgerByAddress[ledger] = ledgers.length;
        ledgerShares[ledger] = _share;
        ledgerSharesTotal += _share;

        IOracleMaster(ORACLE_MASTER).addLedger(ledger);



        IController(controller).newSubAccount(_index, _stashAccount, ledger);

        emit LedgerAdd(ledger, _stashAccount, _controllerAccount, _share);
        return ledger;
    }






    function setLedgerShare(address _ledger, uint256 _newShare) external auth(ROLE_LEDGER_MANAGER) {
        require(ledgerByAddress[_ledger] != 0, "LIDO: LEDGER_NOT_FOUND");

        ledgerSharesTotal -= ledgerShares[_ledger];
        ledgerShares[_ledger] = _newShare;
        ledgerSharesTotal += _newShare;

        emit LedgerSetShare(_ledger, _newShare);
    }







    function removeLedger(address _ledgerAddress) external auth(ROLE_LEDGER_MANAGER) {
        require(ledgerByAddress[_ledgerAddress] != 0, "LIDO: LEDGER_NOT_FOUND");
        require(ledgerShares[_ledgerAddress] == 0, "LIDO: LEDGER_HAS_NON_ZERO_SHARE");

        ILedger ledger = ILedger(_ledgerAddress);
        require(ledger.isEmpty(), "LIDO: LEDGER_IS_NOT_EMPTY");

        address lastLedger = ledgers[ledgers.length - 1];
        uint256 idxToRemove = ledgerByAddress[_ledgerAddress] - 1;
        ledgers[idxToRemove] = lastLedger;
        ledgerByAddress[lastLedger] = idxToRemove + 1;
        ledgers.pop();
        delete ledgerByAddress[_ledgerAddress];
        delete ledgerByStash[ledger.stashAccount()];
        delete ledgerShares[_ledgerAddress];

        IOracleMaster(ORACLE_MASTER).removeLedger(_ledgerAddress);

        vKSM.approve(address(ledger), 0);

        emit LedgerRemove(_ledgerAddress);
    }







    function nominate(bytes32 _stashAccount, bytes32[] calldata _validators) external auth(ROLE_STAKE_MANAGER) {
        require(ledgerByStash[_stashAccount] != address(0),  "UNKNOWN_STASH_ACCOUNT");

        ILedger(ledgerByStash[_stashAccount]).nominate(_validators);
    }







    function deposit(uint256 _amount) external whenNotPaused {
        vKSM.transferFrom(msg.sender, address(this), _amount);

        _submit(_amount);

        emit Deposited(msg.sender, _amount);
    }







    function redeem(uint256 _amount) external whenNotPaused {
        uint256 _shares = getSharesByPooledKSM(_amount);
        require(_shares <= _sharesOf(msg.sender), "LIDO: REDEEM_AMOUNT_EXCEEDS_BALANCE");
        require(claimOrders[msg.sender].length < MAX_CLAIMS, "LIDO: MAX_CLAIMS_EXCEEDS");

        _burnShares(msg.sender, _shares);
        fundRaisedBalance -= _amount;
        bufferedRedeems += _amount;

        Claim memory newClaim = Claim(_amount, uint64(block.timestamp) + RELAY_SPEC.unbondingPeriod);
        claimOrders[msg.sender].push(newClaim);
        pendingClaimsTotal += _amount;


        emit Transfer(msg.sender, address(0), _amount);


        emit Redeemed(msg.sender, _amount);
    }





    function claimUnbonded() external whenNotPaused {
        uint256 readyToClaim = 0;
        uint256 readyToClaimCount = 0;
        Claim[] storage orders = claimOrders[msg.sender];

        for (uint256 i = 0; i < orders.length; ++i) {
            if (orders[i].timeout < block.timestamp) {
                readyToClaim += orders[i].balance;
                readyToClaimCount += 1;
            }
            else {
                orders[i - readyToClaimCount] = orders[i];
            }
        }


        for (uint256 i = 0; i < readyToClaimCount; ++i) { orders.pop(); }

        if (readyToClaim > 0) {
            vKSM.transfer(msg.sender, readyToClaim);
            pendingClaimsTotal -= readyToClaim;
            emit Claimed(msg.sender, readyToClaim);
        }
    }




    function distributeRewards(uint256 _totalRewards, uint256 ledgerBalance) external {
        require(ledgerByAddress[msg.sender] != 0, "LIDO: NOT_FROM_LEDGER");

        Types.Fee memory _fee = FEE;


        uint256 _feeDevTreasure = uint256(_fee.developers + _fee.treasury);
        assert(_feeDevTreasure>0);

        fundRaisedBalance += _totalRewards;

        if (ledgerShares[msg.sender] > 0) {
            ledgerStake[msg.sender] += _totalRewards;
        }

        uint256 _rewards = _totalRewards * _feeDevTreasure / uint256(10000 - _fee.operators);
        uint256 shares2mint = _rewards * _getTotalShares() / (_getTotalPooledKSM()  - _rewards);

        _mintShares(treasury, shares2mint);

        uint256 _devShares = shares2mint *  uint256(_fee.developers) / _feeDevTreasure;
        _transferShares(treasury, developers, _devShares);
        _emitTransferAfterMintingShares(developers, _devShares);
        _emitTransferAfterMintingShares(treasury, shares2mint - _devShares);

        emit Rewards(msg.sender, _totalRewards, ledgerBalance);
    }




    function distributeLosses(uint256 _totalLosses, uint256 ledgerBalance) external {
        require(ledgerByAddress[msg.sender] != 0, "LIDO: NOT_FROM_LEDGER");

        fundRaisedBalance -= _totalLosses;
        if (ledgerShares[msg.sender] > 0) {

            ledgerStake[msg.sender] -= _totalLosses;
        }

        emit Losses(msg.sender, _totalLosses, ledgerBalance);
    }





    function flushStakes() external {
        require(msg.sender == ORACLE_MASTER, "LIDO: NOT_FROM_ORACLE_MASTER");

        _softRebalanceStakes();
    }






    function forceRebalanceStake() external auth(ROLE_STAKE_MANAGER) {
        _forceRebalanceStakes();

        bufferedDeposits = 0;
        bufferedRedeems = 0;
    }




    function refreshAllowances() external auth(ROLE_LEDGER_MANAGER) {
        uint _length = ledgers.length;
        for (uint i = 0; i < _length; i++) {
            vKSM.approve(ledgers[i], type(uint256).max);
        }
    }




    function _forceRebalanceStakes() internal {
        uint256 totalStake = getTotalPooledKSM();

        uint256 stakesSum = 0;
        address nonZeroLedged = address(0);
        uint _length = ledgers.length;
        uint256 _ledgerSharesTotal = ledgerSharesTotal;
        for (uint i = 0; i < _length; i++) {
            uint256 share = ledgerShares[ledgers[i]];
            uint256 stake = totalStake * share / _ledgerSharesTotal;

            stakesSum += stake;
            ledgerStake[ledgers[i]] = stake;

            if (share > 0 && nonZeroLedged == address(0)) {
                nonZeroLedged = ledgers[i];
            }
        }



        uint256 remainingDust = totalStake - stakesSum;
        if (remainingDust > 0 && nonZeroLedged != address(0)) {
            ledgerStake[nonZeroLedged] += remainingDust;
        }
    }




    function _softRebalanceStakes() internal {
        if (bufferedDeposits > 0 || bufferedRedeems > 0) {
            _distribute(bufferedDeposits.toInt256() - bufferedRedeems.toInt256());

            bufferedDeposits = 0;
            bufferedRedeems = 0;
        }
    }

    function _distribute(int256 _stake) internal {
        uint256 ledgersLength = ledgers.length;

        int256[] memory diffs = new int256[](ledgersLength);
        address[] memory ledgersCache = new address[](ledgersLength);
        int256[] memory ledgerStakesCache = new int256[](ledgersLength);
        uint256[] memory ledgerSharesCache = new uint256[](ledgersLength);

        int256 activeDiffsSum = 0;
        int256 totalChange = 0;

        {
            uint256 totalStake = getTotalPooledKSM();
            uint256 _ledgerSharesTotal = ledgerSharesTotal;
            int256 diff = 0;
            for (uint256 i = 0; i < ledgersLength; ++i) {
                ledgersCache[i] = ledgers[i];
                ledgerStakesCache[i] = int256(ledgerStake[ledgersCache[i]]);
                ledgerSharesCache[i] = ledgerShares[ledgersCache[i]];

                uint256 targetStake = totalStake * ledgerSharesCache[i] / _ledgerSharesTotal;
                diff = int256(targetStake) - int256(ledgerStakesCache[i]);
                if (_stake * diff > 0) {
                    activeDiffsSum += diff;
                }
                diffs[i] = diff;
            }
        }


        if (activeDiffsSum != 0) {
            int8 direction = 1;
            if (activeDiffsSum < 0) {
                direction = -1;
                activeDiffsSum = -activeDiffsSum;
            }

            for (uint256 i = 0; i < ledgersLength; ++i) {
                diffs[i] *= direction;
                if (diffs[i] > 0 && (direction < 0 || ledgerSharesCache[i] > 0)) {
                    int256 change = diffs[i] * _stake / activeDiffsSum;
                    int256 newStake = ledgerStakesCache[i] + change;

                    ledgerStake[ledgersCache[i]] = uint256(newStake);
                    ledgerStakesCache[i] = newStake;
                    totalChange += change;
                }
            }
        }

        {
            int256 remaining = _stake - totalChange;
            if (remaining > 0) {
                for (uint256 i = 0; i < ledgersLength; ++i) {
                    if (ledgerSharesCache[i] > 0) {
                        ledgerStake[ledgersCache[i]] += uint256(remaining);
                        break;
                    }
                }
            }
            else if (remaining < 0) {
                for (uint256 i = 0; i < ledgersLength || remaining < 0; ++i) {
                    uint256 stake = uint256(ledgerStakesCache[i]);
                    if (stake > 0) {
                        uint256 decrement = stake > uint256(-remaining) ? uint256(-remaining) : stake;
                        ledgerStake[ledgersCache[i]] -= decrement;
                        remaining += int256(decrement);
                    }
                }
            }
        }
    }





    function _submit(uint256 _deposit) internal returns (uint256) {
        address sender = msg.sender;

        require(_deposit != 0, "LIDO: ZERO_DEPOSIT");

        uint256 sharesAmount = getSharesByPooledKSM(_deposit);
        if (sharesAmount == 0) {


            sharesAmount = _deposit;
        }

        fundRaisedBalance += _deposit;
        bufferedDeposits += _deposit;
        _mintShares(sender, sharesAmount);

        _emitTransferAfterMintingShares(sender, sharesAmount);
        return sharesAmount;
    }





    function _emitTransferAfterMintingShares(address _to, uint256 _sharesAmount) internal {
        emit Transfer(address(0), _to, getPooledKSMByShares(_sharesAmount));
    }





    function _getTotalPooledKSM() internal view override returns (uint256) {
        return fundRaisedBalance;
    }
}
