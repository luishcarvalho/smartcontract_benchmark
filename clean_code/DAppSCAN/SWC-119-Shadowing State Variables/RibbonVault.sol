
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import {GnosisAuction} from "../../libraries/GnosisAuction.sol";
import {OptionsVaultStorage} from "../../storage/OptionsVaultStorage.sol";
import {Vault} from "../../libraries/Vault.sol";
import {VaultLifecycle} from "../../libraries/VaultLifecycle.sol";
import {ShareMath} from "../../libraries/ShareMath.sol";
import {IOtoken} from "../../interfaces/GammaInterface.sol";
import {IWETH} from "../../interfaces/IWETH.sol";
import {IGnosisAuction} from "../../interfaces/IGnosisAuction.sol";
import {
    IStrikeSelection,
    IOptionsPremiumPricer
} from "../../interfaces/IRibbon.sol";

contract RibbonVault is OptionsVaultStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMath for Vault.DepositReceipt;





    address public immutable WETH;
    address public immutable USDC;

    uint256 public constant delay = 1 hours;

    uint256 public constant period = 7 days;

    uint128 internal constant PLACEHOLDER_UINT = 1;



    uint256 private constant WEEKS_PER_YEAR = 52142857;




    address public immutable GAMMA_CONTROLLER;




    address public immutable MARGIN_POOL;



    address public immutable GNOSIS_EASY_AUCTION;





    event Deposit(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(address account, uint256 shares, uint256 round);

    event Redeem(address indexed account, uint256 share, uint16 round);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event CapSet(uint256 oldCap, uint256 newCap, address manager);

    event Withdraw(address account, uint256 amount, uint256 shares);

    event CollectVaultFees(
        uint256 performanceFee,
        uint256 vaultFee,
        uint256 round
    );













    constructor(
        address _weth,
        address _usdc,
        address _gammaController,
        address _marginPool,
        address _gnosisEasyAuction
    ) {
        require(_weth != address(0), "!_weth");
        require(_usdc != address(0), "!_usdc");
        require(_gnosisEasyAuction != address(0), "!_gnosisEasyAuction");
        require(_gammaController != address(0), "!_gammaController");
        require(_marginPool != address(0), "!_marginPool");

        WETH = _weth;
        USDC = _usdc;
        GAMMA_CONTROLLER = _gammaController;
        MARGIN_POOL = _marginPool;
        GNOSIS_EASY_AUCTION = _gnosisEasyAuction;
    }




    function baseInitialize(
        address _owner,
        address _feeRecipient,
        uint256 _managementFee,
        uint256 _performanceFee,
        string memory tokenName,
        string memory tokenSymbol,
        Vault.VaultParams calldata _vaultParams
    ) internal initializer {
        VaultLifecycle.verifyConstructorParams(
            _owner,
            _feeRecipient,
            _performanceFee,
            tokenName,
            tokenSymbol,
            _vaultParams
        );

        __ReentrancyGuard_init();
        __ERC20_init(tokenName, tokenSymbol);
        __Ownable_init();
        transferOwnership(_owner);

        feeRecipient = _feeRecipient;
        performanceFee = _performanceFee;
        managementFee = _managementFee.mul(10**6).div(WEEKS_PER_YEAR);
        vaultParams = _vaultParams;
        vaultState.lastLockedAmount = uint104(
            IERC20(vaultParams.asset).balanceOf(address(this))
        );

        vaultState.round = 1;
    }









    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "!newFeeRecipient");
        feeRecipient = newFeeRecipient;
    }





    function setManagementFee(uint256 newManagementFee) external onlyOwner {
        require(newManagementFee < 100 * 10**6, "Invalid management fee");

        emit ManagementFeeSet(managementFee, newManagementFee);


        managementFee = newManagementFee.mul(10**6).div(WEEKS_PER_YEAR);
    }





    function setPerformanceFee(uint256 newPerformanceFee) external onlyOwner {
        require(newPerformanceFee < 100 * 10**6, "Invalid performance fee");

        emit PerformanceFeeSet(performanceFee, newPerformanceFee);

        performanceFee = newPerformanceFee;
    }





    function setCap(uint104 newCap) external onlyOwner {
        require(newCap > 0, "!newCap");
        uint256 oldCap = vaultParams.cap;
        vaultParams.cap = newCap;
        emit CapSet(oldCap, newCap, msg.sender);
    }








    function depositETH() external payable nonReentrant {
        require(vaultParams.asset == WETH, "!WETH");
        require(msg.value > 0, "!value");

        _depositFor(msg.value, msg.sender);

        IWETH(WETH).deposit{value: msg.value}();
    }





    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "!amount");

        _depositFor(amount, msg.sender);

        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }







    function depositFor(uint256 amount, address creditor)
        external
        nonReentrant
    {
        require(amount > 0, "!amount");
        require(creditor != address(0));

        _depositFor(amount, creditor);

        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }







    function _depositFor(uint256 amount, address creditor) private {
        uint256 currentRound = vaultState.round;
        uint256 totalWithDepositedAmount = totalBalance().add(amount);

        require(totalWithDepositedAmount <= vaultParams.cap, "Exceed cap");
        require(
            totalWithDepositedAmount >= vaultParams.minimumSupply,
            "Insufficient balance"
        );

        emit Deposit(creditor, amount, currentRound);

        Vault.DepositReceipt memory depositReceipt = depositReceipts[creditor];


        uint128 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        uint256 depositAmount = uint104(amount);

        if (currentRound == depositReceipt.round) {
            uint256 newAmount = uint256(depositReceipt.amount).add(amount);
            depositAmount = newAmount;
        }

        ShareMath.assertUint104(depositAmount);

        depositReceipts[creditor] = Vault.DepositReceipt({
            processed: false,
            round: uint16(currentRound),
            amount: uint104(depositAmount),
            unredeemedShares: unredeemedShares
        });

        vaultState.totalPending = uint128(
            uint256(vaultState.totalPending).add(amount)
        );
    }






    function initiateWithdraw(uint128 shares) external nonReentrant {
        require(shares > 0, "!shares");



        if (
            depositReceipts[msg.sender].amount > 0 ||
            depositReceipts[msg.sender].unredeemedShares > 0
        ) {
            _redeem(0, true);
        }


        uint256 currentRound = vaultState.round;
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        bool topup = withdrawal.round == currentRound;

        emit InitiateWithdraw(msg.sender, shares, currentRound);

        uint256 withdrawalShares = uint256(withdrawal.shares);

        if (topup) {
            uint256 increasedShares = withdrawalShares.add(shares);
            ShareMath.assertUint128(increasedShares);
            withdrawals[msg.sender].shares = uint128(increasedShares);
        } else if (withdrawalShares == 0) {
            withdrawals[msg.sender].shares = shares;
            withdrawals[msg.sender].round = uint16(currentRound);
        } else {


            revert("Existing withdraw");
        }

        vaultState.queuedWithdrawShares = uint128(
            uint256(vaultState.queuedWithdrawShares).add(shares)
        );

        _transfer(msg.sender, address(this), shares);
    }




    function completeWithdraw() external nonReentrant {
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;


        require(withdrawalShares > 0, "Not initiated");

        require(withdrawalRound < vaultState.round, "Round not closed");


        withdrawals[msg.sender].shares = 0;
        vaultState.queuedWithdrawShares = uint128(
            uint256(vaultState.queuedWithdrawShares).sub(withdrawalShares)
        );

        uint256 withdrawAmount =
            ShareMath.sharesToUnderlying(
                withdrawalShares,
                roundPricePerShare[uint16(withdrawalRound)],
                vaultParams.decimals
            );

        emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);

        _burn(address(this), withdrawalShares);

        require(withdrawAmount > 0, "!withdrawAmount");
        transferAsset(msg.sender, withdrawAmount);
    }






    function redeem(uint256 shares) external nonReentrant {
        require(shares > 0, "!shares");
        _redeem(shares, false);
    }




    function maxRedeem() external nonReentrant {
        _redeem(0, true);
    }







    function _redeem(uint256 shares, bool isMax) internal {
        ShareMath.assertUint104(shares);

        Vault.DepositReceipt memory depositReceipt =
            depositReceipts[msg.sender];



        uint16 currentRound = vaultState.round;
        require(depositReceipt.round < currentRound, "Round not closed");

        uint128 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        shares = isMax ? unredeemedShares : shares;
        require(shares > 0, "!shares");
        require(shares <= unredeemedShares, "Exceeds available");


        depositReceipts[msg.sender].amount = 0;
        depositReceipts[msg.sender].processed = true;
        depositReceipts[msg.sender].unredeemedShares = uint128(
            uint256(unredeemedShares).sub(shares)
        );

        emit Redeem(msg.sender, shares, depositReceipt.round);

        _transfer(address(this), msg.sender, shares);
    }











    function initRounds(uint256 numRounds) external nonReentrant {
        require(numRounds < 52, "numRounds >= 52");

        uint16 _round = vaultState.round;
        for (uint16 i = 0; i < numRounds; i++) {
            uint16 index = _round + i;
            require(index >= _round, "Overflow");
            require(roundPricePerShare[index] == 0, "Initialized");
            roundPricePerShare[index] = PLACEHOLDER_UINT;
        }
    }







    function _rollToNextOption() internal returns (address, uint256) {
        require(block.timestamp >= optionState.nextOptionReadyAt, "!ready");

        address newOption = optionState.nextOption;
        require(newOption != address(0), "!nextOption");

        (uint256 lockedBalance, uint256 newPricePerShare, uint256 mintShares) =
            VaultLifecycle.rollover(
                totalSupply(),
                vaultParams.asset,
                vaultParams.decimals,
                vaultParams.initialSharePrice,
                uint256(vaultState.totalPending),
                vaultState.queuedWithdrawShares
            );

        optionState.currentOption = newOption;
        optionState.nextOption = address(0);


        uint16 currentRound = vaultState.round;
        roundPricePerShare[currentRound] = newPricePerShare;


        lockedBalance = lockedBalance.sub(_collectVaultFees(lockedBalance));

        vaultState.totalPending = 0;
        vaultState.round = currentRound + 1;

        _mint(address(this), mintShares);

        return (newOption, lockedBalance);
    }






    function _collectVaultFees(uint256 currentLockedBalance)
        internal
        returns (uint256 vaultFee)
    {
        uint256 prevLockedAmount = vaultState.lastLockedAmount;
        uint256 lockedBalanceSansPending =
            currentLockedBalance.sub(vaultState.totalPending);






        if (lockedBalanceSansPending > prevLockedAmount) {
            uint256 performanceFeeInAsset =
                performanceFee > 0
                    ? lockedBalanceSansPending
                        .sub(prevLockedAmount)
                        .mul(performanceFee)
                        .div(100 * 10**6)
                    : 0;
            uint256 managementFeeInAsset =
                managementFee > 0
                    ? currentLockedBalance.mul(managementFee).div(100 * 10**6)
                    : 0;

            vaultFee = performanceFeeInAsset.add(managementFeeInAsset);
        }

        if (vaultFee > 0) {
            transferAsset(payable(feeRecipient), vaultFee);
            emit CollectVaultFees(performanceFee, vaultFee, vaultState.round);
        }
    }






    function transferAsset(address payable recipient, uint256 amount) internal {
        address asset = vaultParams.asset;
        if (asset == WETH) {
            IWETH(WETH).withdraw(amount);
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "!success");
            return;
        }
        IERC20(asset).safeTransfer(recipient, amount);
    }









    function accountVaultBalance(address account)
        external
        view
        returns (uint256)
    {
        uint8 decimals = vaultParams.decimals;
        uint256 numShares = shares(account);
        uint256 pps =
            totalBalance().sub(vaultState.totalPending).mul(10**decimals).div(
                totalSupply()
            );
        return ShareMath.sharesToUnderlying(numShares, pps, decimals);
    }






    function shares(address account) public view returns (uint256) {
        (uint256 heldByAccount, uint256 heldByVault) = shareBalances(account);
        return heldByAccount.add(heldByVault);
    }







    function shareBalances(address account)
        public
        view
        returns (uint256 heldByAccount, uint256 heldByVault)
    {
        Vault.DepositReceipt memory depositReceipt = depositReceipts[account];

        if (depositReceipt.round < PLACEHOLDER_UINT) {
            return (balanceOf(account), 0);
        }

        uint128 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                vaultState.round,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        return (balanceOf(account), unredeemedShares);
    }




    function pricePerShare() external view returns (uint256) {
        uint256 balance = totalBalance().sub(vaultState.totalPending);
        return
            (10**uint256(vaultParams.decimals)).mul(balance).div(totalSupply());
    }





    function totalBalance() public view returns (uint256) {
        return
            uint256(vaultState.lockedAmount).add(
                IERC20(vaultParams.asset).balanceOf(address(this))
            );
    }




    function decimals() public view override returns (uint8) {
        return vaultParams.decimals;
    }

    function cap() external view returns (uint256) {
        return vaultParams.cap;
    }

    function nextOptionReadyAt() external view returns (uint256) {
        return optionState.nextOptionReadyAt;
    }

    function currentOption() external view returns (address) {
        return optionState.currentOption;
    }

    function nextOption() external view returns (address) {
        return optionState.nextOption;
    }

    function totalPending() external view returns (uint256) {
        return vaultState.totalPending;
    }




}
