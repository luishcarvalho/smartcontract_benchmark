


pragma solidity =0.6.10;

pragma experimental ABIEncoderV2;

import {OwnableUpgradeSafe} from "./packages/oz/upgradeability/OwnableUpgradeSafe.sol";
import {ReentrancyGuardUpgradeSafe} from "./packages/oz/upgradeability/ReentrancyGuardUpgradeSafe.sol";
import {Initializable} from "./packages/oz/upgradeability/Initializable.sol";
import {SafeMath} from "./packages/oz/SafeMath.sol";
import {MarginVault} from "./libs/MarginVault.sol";
import {Actions} from "./libs/Actions.sol";
import {AddressBookInterface} from "./interfaces/AddressBookInterface.sol";
import {OtokenInterface} from "./interfaces/OtokenInterface.sol";
import {MarginCalculatorInterface} from "./interfaces/MarginCalculatorInterface.sol";
import {OracleInterface} from "./interfaces/OracleInterface.sol";
import {WhitelistInterface} from "./interfaces/WhitelistInterface.sol";
import {MarginPoolInterface} from "./interfaces/MarginPoolInterface.sol";
import {CalleeInterface} from "./interfaces/CalleeInterface.sol";






contract Controller is Initializable, OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe {
    using MarginVault for MarginVault.Vault;
    using SafeMath for uint256;

    AddressBookInterface public addressbook;
    WhitelistInterface public whitelist;
    OracleInterface public oracle;
    MarginCalculatorInterface public calculator;
    MarginPoolInterface public pool;


    uint256 internal constant BASE = 8;



    address public partialPauser;


    address public fullPauser;


    bool public systemPartiallyPaused;


    bool public systemFullyPaused;


    bool public callRestricted;


    mapping(address => uint256) internal accountVaultCounter;

    mapping(address => mapping(uint256 => MarginVault.Vault)) internal vaults;

    mapping(address => mapping(address => bool)) internal operators;


    event AccountOperatorUpdated(address indexed accountOwner, address indexed operator, bool isSet);

    event VaultOpened(address indexed accountOwner, uint256 vaultId);

    event LongOtokenDeposited(
        address indexed otoken,
        address indexed accountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );

    event LongOtokenWithdrawed(
        address indexed otoken,
        address indexed AccountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );

    event CollateralAssetDeposited(
        address indexed asset,
        address indexed accountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );

    event CollateralAssetWithdrawed(
        address indexed asset,
        address indexed AccountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );

    event ShortOtokenMinted(
        address indexed otoken,
        address indexed AccountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );

    event ShortOtokenBurned(
        address indexed otoken,
        address indexed AccountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );

    event Redeem(
        address indexed otoken,
        address indexed redeemer,
        address indexed receiver,
        address collateralAsset,
        uint256 otokenBurned,
        uint256 payout
    );

    event VaultSettled(address indexed AccountOwner, address indexed to, uint256 vaultId, uint256 payout);

    event CallExecuted(
        address indexed from,
        address indexed to,
        address indexed vaultOwner,
        uint256 vaultId,
        bytes data
    );

    event FullPauserUpdated(address indexed oldFullPauser, address indexed newFullPauser);

    event PartialPauserUpdated(address indexed oldPartialPauser, address indexed newPartialPauser);

    event SystemPartiallyPaused(bool isActive);

    event SystemFullyPaused(bool isActive);

    event CallRestricted(bool isRestricted);




    modifier notPartiallyPaused {
        _isNotPartiallyPaused();

        _;
    }




    modifier notFullyPaused {
        _isNotFullyPaused();

        _;
    }




    modifier onlyFullPauser {
        require(msg.sender == fullPauser, "Controller: sender is not fullPauser");

        _;
    }




    modifier onlyPartialPauser {
        require(msg.sender == partialPauser, "Controller: sender is not partialPauser");

        _;
    }






    modifier onlyAuthorized(address _sender, address _accountOwner) {
        _isAuthorized(_sender, _accountOwner);

        _;
    }





    modifier onlyWhitelistedCallee(address _callee) {
        if (callRestricted) {
            require(_isCalleeWhitelisted(_callee), "Controller: callee is not a whitelisted address");
        }

        _;
    }




    function _isNotPartiallyPaused() internal view {
        require(!systemPartiallyPaused, "Controller: system is partially paused");
    }




    function _isNotFullyPaused() internal view {
        require(!systemFullyPaused, "Controller: system is fully paused");
    }






    function _isAuthorized(address _sender, address _accountOwner) internal view {
        require(
            (_sender == _accountOwner) || (operators[_accountOwner][_sender]),
            "Controller: msg.sender is not authorized to run action"
        );
    }






    function initialize(address _addressBook, address _owner) external initializer {
        require(_addressBook != address(0), "Controller: invalid addressbook address");
        require(_owner != address(0), "Controller: invalid owner address");

        __Context_init_unchained();
        __Ownable_init_unchained(_owner);
        __ReentrancyGuard_init_unchained();

        addressbook = AddressBookInterface(_addressBook);
        _refreshConfigInternal();
    }






    function setSystemPartiallyPaused(bool _partiallyPaused) external onlyPartialPauser {
        systemPartiallyPaused = _partiallyPaused;

        emit SystemPartiallyPaused(systemPartiallyPaused);
    }






    function setSystemFullyPaused(bool _fullyPaused) external onlyFullPauser {
        systemFullyPaused = _fullyPaused;

        emit SystemFullyPaused(systemFullyPaused);
    }






    function setFullPauser(address _fullPauser) external onlyOwner {
        require(_fullPauser != address(0), "Controller: fullPauser cannot be set to address zero");

        emit FullPauserUpdated(fullPauser, _fullPauser);

        fullPauser = _fullPauser;
    }






    function setPartialPauser(address _partialPauser) external onlyOwner {
        require(_partialPauser != address(0), "Controller: partialPauser cannot be set to address zero");

        emit PartialPauserUpdated(partialPauser, _partialPauser);

        partialPauser = _partialPauser;
    }







    function setCallRestriction(bool _isRestricted) external onlyOwner {
        callRestricted = _isRestricted;

        emit CallRestricted(callRestricted);
    }







    function setOperator(address _operator, bool _isOperator) external {
        operators[msg.sender][_operator] = _isOperator;

        emit AccountOperatorUpdated(msg.sender, _operator, _isOperator);
    }




    function refreshConfiguration() external onlyOwner {
        _refreshConfigInternal();
    }






    function operate(Actions.ActionArgs[] memory _actions) external payable nonReentrant notFullyPaused {
        (bool vaultUpdated, address vaultOwner, uint256 vaultId) = _runActions(_actions);
        if (vaultUpdated) _verifyFinalState(vaultOwner, vaultId);
    }







    function isOperator(address _owner, address _operator) external view returns (bool) {
        return operators[_owner][_operator];
    }








    function getConfiguration()
        external
        view
        returns (
            address,
            address,
            address,
            address
        )
    {
        return (address(whitelist), address(oracle), address(calculator), address(pool));
    }







    function getProceed(address _owner, uint256 _vaultId) external view returns (uint256) {
        MarginVault.Vault memory vault = getVault(_owner, _vaultId);

        (uint256 netValue, ) = calculator.getExcessCollateral(vault);
        return netValue;
    }







    function getPayout(address _otoken, uint256 _amount) public view returns (uint256) {
        uint256 rate = calculator.getExpiredPayoutRate(_otoken);
        return rate.mul(_amount).div(10**BASE);
    }






    function isSettlementAllowed(address _otoken) public view returns (bool) {
        OtokenInterface otoken = OtokenInterface(_otoken);

        address underlying = otoken.underlyingAsset();
        address strike = otoken.strikeAsset();
        address collateral = otoken.collateralAsset();

        uint256 expiry = otoken.expiryTimestamp();

        bool isUnderlyingFinalized = oracle.isDisputePeriodOver(underlying, expiry);
        bool isStrikeFinalized = oracle.isDisputePeriodOver(strike, expiry);
        bool isCollateralFinalized = oracle.isDisputePeriodOver(collateral, expiry);

        return isUnderlyingFinalized && isStrikeFinalized && isCollateralFinalized;
    }






    function getAccountVaultCounter(address _accountOwner) external view returns (uint256) {
        return accountVaultCounter[_accountOwner];
    }






    function hasExpired(address _otoken) external view returns (bool) {
        uint256 otokenExpiryTimestamp = OtokenInterface(_otoken).expiryTimestamp();

        return now > otokenExpiryTimestamp;
    }







    function getVault(address _owner, uint256 _vaultId) public view returns (MarginVault.Vault memory) {
        return vaults[_owner][_vaultId];
    }











    function _runActions(Actions.ActionArgs[] memory _actions)
        internal
        returns (
            bool,
            address,
            uint256
        )
    {
        address vaultOwner;
        uint256 vaultId;
        uint256 ethLeft = msg.value;
        bool vaultUpdated;

        for (uint256 i = 0; i < _actions.length; i++) {
            Actions.ActionArgs memory action = _actions[i];
            Actions.ActionType actionType = action.actionType;

            if (
                (actionType != Actions.ActionType.SettleVault) &&
                (actionType != Actions.ActionType.Redeem) &&
                (actionType != Actions.ActionType.Call)
            ) {

                if (vaultUpdated) {
                    require(vaultOwner == action.owner, "Controller: can not run actions for different owners");
                    require(vaultId == action.vaultId, "Controller: can not run actions on different vaults");
                }
                vaultUpdated = true;
                vaultId = action.vaultId;
                vaultOwner = action.owner;
            }

            if (actionType == Actions.ActionType.OpenVault) {
                _openVault(Actions._parseOpenVaultArgs(action));
            } else if (actionType == Actions.ActionType.DepositLongOption) {
                _depositLong(Actions._parseDepositArgs(action));
            } else if (actionType == Actions.ActionType.WithdrawLongOption) {
                _withdrawLong(Actions._parseWithdrawArgs(action));
            } else if (actionType == Actions.ActionType.DepositCollateral) {
                _depositCollateral(Actions._parseDepositArgs(action));
            } else if (actionType == Actions.ActionType.WithdrawCollateral) {
                _withdrawCollateral(Actions._parseWithdrawArgs(action));
            } else if (actionType == Actions.ActionType.MintShortOption) {
                _mintOtoken(Actions._parseMintArgs(action));
            } else if (actionType == Actions.ActionType.BurnShortOption) {
                _burnOtoken(Actions._parseBurnArgs(action));
            } else if (actionType == Actions.ActionType.Redeem) {
                _redeem(Actions._parseRedeemArgs(action));
            } else if (actionType == Actions.ActionType.SettleVault) {
                _settleVault(Actions._parseSettleVaultArgs(action));
            } else {

                ethLeft = _call(Actions._parseCallArgs(action), ethLeft);
            }
        }

        return (vaultUpdated, vaultOwner, vaultId);
    }






    function _verifyFinalState(address _owner, uint256 _vaultId) internal view {
        MarginVault.Vault memory _vault = getVault(_owner, _vaultId);
        (, bool isValidVault) = calculator.getExcessCollateral(_vault);

        require(isValidVault, "Controller: invalid final vault state");
    }






    function _openVault(Actions.OpenVaultArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        accountVaultCounter[_args.owner] = accountVaultCounter[_args.owner].add(1);

        require(
            _args.vaultId == accountVaultCounter[_args.owner],
            "Controller: can not run actions on inexistent vault"
        );

        emit VaultOpened(_args.owner, accountVaultCounter[_args.owner]);
    }






    function _depositLong(Actions.DepositArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");
        require(
            (_args.from == msg.sender) || (_args.from == _args.owner),
            "Controller: cannot deposit long otoken from this address"
        );

        require(
            whitelist.isWhitelistedOtoken(_args.asset),
            "Controller: otoken is not whitelisted to be used as collateral"
        );

        OtokenInterface otoken = OtokenInterface(_args.asset);

        require(now < otoken.expiryTimestamp(), "Controller: otoken used as collateral is already expired");

        vaults[_args.owner][_args.vaultId].addLong(_args.asset, _args.amount, _args.index);

        pool.transferToPool(_args.asset, _args.from, _args.amount);

        emit LongOtokenDeposited(_args.asset, _args.owner, _args.from, _args.vaultId, _args.amount);
    }






    function _withdrawLong(Actions.WithdrawArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");

        OtokenInterface otoken = OtokenInterface(_args.asset);

        require(now < otoken.expiryTimestamp(), "Controller: can not withdraw an expired otoken");

        vaults[_args.owner][_args.vaultId].removeLong(_args.asset, _args.amount, _args.index);

        pool.transferToUser(_args.asset, _args.to, _args.amount);

        emit LongOtokenWithdrawed(_args.asset, _args.owner, _args.to, _args.vaultId, _args.amount);
    }






    function _depositCollateral(Actions.DepositArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");
        require(
            (_args.from == msg.sender) || (_args.from == _args.owner),
            "Controller: cannot deposit collateral from this address"
        );

        require(
            whitelist.isWhitelistedCollateral(_args.asset),
            "Controller: asset is not whitelisted to be used as collateral"
        );

        vaults[_args.owner][_args.vaultId].addCollateral(_args.asset, _args.amount, _args.index);

        pool.transferToPool(_args.asset, _args.from, _args.amount);

        emit CollateralAssetDeposited(_args.asset, _args.owner, _args.from, _args.vaultId, _args.amount);
    }






    function _withdrawCollateral(Actions.WithdrawArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");

        MarginVault.Vault memory vault = getVault(_args.owner, _args.vaultId);
        if (_isNotEmpty(vault.shortOtokens)) {
            OtokenInterface otoken = OtokenInterface(vault.shortOtokens[0]);

            require(
                now < otoken.expiryTimestamp(),
                "Controller: can not withdraw collateral from a vault with an expired short otoken"
            );
        }

        vaults[_args.owner][_args.vaultId].removeCollateral(_args.asset, _args.amount, _args.index);

        pool.transferToUser(_args.asset, _args.to, _args.amount);

        emit CollateralAssetWithdrawed(_args.asset, _args.owner, _args.to, _args.vaultId, _args.amount);
    }






    function _mintOtoken(Actions.MintArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");

        require(whitelist.isWhitelistedOtoken(_args.otoken), "Controller: otoken is not whitelisted to be minted");

        OtokenInterface otoken = OtokenInterface(_args.otoken);

        require(now < otoken.expiryTimestamp(), "Controller: can not mint expired otoken");

        vaults[_args.owner][_args.vaultId].addShort(_args.otoken, _args.amount, _args.index);

        otoken.mintOtoken(_args.to, _args.amount);

        emit ShortOtokenMinted(_args.otoken, _args.owner, _args.to, _args.vaultId, _args.amount);
    }






    function _burnOtoken(Actions.BurnArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");
        require((_args.from == msg.sender) || (_args.from == _args.owner), "Controller: cannot burn from this address");

        OtokenInterface otoken = OtokenInterface(_args.otoken);

        require(now < otoken.expiryTimestamp(), "Controller: can not burn expired otoken");

        vaults[_args.owner][_args.vaultId].removeShort(_args.otoken, _args.amount, _args.index);

        otoken.burnOtoken(_args.from, _args.amount);

        emit ShortOtokenBurned(_args.otoken, _args.owner, _args.from, _args.vaultId, _args.amount);
    }






    function _redeem(Actions.RedeemArgs memory _args) internal {
        OtokenInterface otoken = OtokenInterface(_args.otoken);

        require(now > otoken.expiryTimestamp(), "Controller: can not redeem un-expired otoken");

        require(isSettlementAllowed(_args.otoken), "Controller: asset prices not finalized yet");

        uint256 payout = getPayout(_args.otoken, _args.amount);

        otoken.burnOtoken(msg.sender, _args.amount);

        pool.transferToUser(otoken.collateralAsset(), _args.receiver, payout);

        emit Redeem(_args.otoken, msg.sender, _args.receiver, otoken.collateralAsset(), _args.amount, payout);
    }






    function _settleVault(Actions.SettleVaultArgs memory _args) internal onlyAuthorized(msg.sender, _args.owner) {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");

        MarginVault.Vault memory vault = getVault(_args.owner, _args.vaultId);

        require(_isNotEmpty(vault.shortOtokens) || _isNotEmpty(vault.longOtokens), "Can't settle vault with no otoken");

        OtokenInterface otoken = _isNotEmpty(vault.shortOtokens)
            ? OtokenInterface(vault.shortOtokens[0])
            : OtokenInterface(vault.longOtokens[0]);

        require(now > otoken.expiryTimestamp(), "Controller: can not settle vault with un-expired otoken");
        require(isSettlementAllowed(address(otoken)), "Controller: asset prices not finalized yet");

        (uint256 payout, ) = calculator.getExcessCollateral(vault);

        if (_isNotEmpty(vault.longOtokens)) {
            OtokenInterface longOtoken = OtokenInterface(vault.longOtokens[0]);

            longOtoken.burnOtoken(address(pool), vault.longAmounts[0]);
        }

        delete vaults[_args.owner][_args.vaultId];

        pool.transferToUser(otoken.collateralAsset(), _args.to, payout);

        emit VaultSettled(_args.owner, _args.to, _args.vaultId, payout);
    }







    function _call(Actions.CallArgs memory _args, uint256 _ethLeft)
        internal
        notPartiallyPaused
        onlyWhitelistedCallee(_args.callee)
        returns (uint256)
    {
        _ethLeft = _ethLeft.sub(_args.msgValue, "Controller: msg.value and CallArgs.value mismatch");
        CalleeInterface(_args.callee).callFunction{value: _args.msgValue}(
            msg.sender,
            _args.owner,
            _args.vaultId,
            _args.data
        );

        emit CallExecuted(msg.sender, _args.callee, _args.owner, _args.vaultId, _args.data);

        return _ethLeft;
    }







    function _checkVaultId(address _accountOwner, uint256 _vaultId) internal view returns (bool) {
        return ((_vaultId > 0) && (_vaultId <= accountVaultCounter[_accountOwner]));
    }

    function _isNotEmpty(address[] memory _array) internal pure returns (bool) {
        return (_array.length > 0) && (_array[0] != address(0));
    }






    function _isCalleeWhitelisted(address _callee) internal view returns (bool) {
        return whitelist.isWhitelistedCallee(_callee);
    }




    function _refreshConfigInternal() internal {
        whitelist = WhitelistInterface(addressbook.getWhitelist());
        oracle = OracleInterface(addressbook.getOracle());
        calculator = MarginCalculatorInterface(addressbook.getMarginCalculator());
        pool = MarginPoolInterface(addressbook.getMarginPool());
    }
}
