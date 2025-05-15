

pragma solidity ^0.8.0;

import "./Lender.sol";
import "./Borrower.sol";
import "./PoolToken.sol";
import "../InterestRate/InterestRateModel.sol";

import "../security/Ownable.sol";

import "../Controller/ControllerInterface.sol";
import { IERC20Metadata } from "../ERC20/IERC20.sol";

contract Pool is Ownable, Lendable, Borrowable {
    bool public isInitialized;
    string public name;

    ControllerInterface public controller;
    IERC20Metadata public stableCoin;

    enum Access {
        Public,
        Private
    }
    uint8 public access;

    event AccessChanged(uint8 newAccess);

    function initialize(address _admin, address _stableCoin, string memory _name, uint256 _minDeposit, Access _access) external {
        _initialize(_admin, _stableCoin, _name, _minDeposit, _access);
    }

    function _initialize(address _admin, address _stableCoin, string memory _name, uint256 _minDeposit, Access _access) internal nonReentrant {
        require(!isInitialized, "already initialized");
        isInitialized = true;

        name = _name;
        minDeposit = _minDeposit;
        access = uint8(_access);


        owner = _admin;


        controller = ControllerInterface(msg.sender);


        stableCoin = IERC20Metadata(_stableCoin);

        lpToken = new PoolToken("PoolToken", stableCoin.symbol());
    }

    function changeAccess(Access _access) external onlyOwner {
        access = uint8(_access);
        emit AccessChanged(access);
    }


    function lend(uint256 amount) external returns (uint256) {
        return lendInternal(msg.sender, msg.sender, amount);
    }

    function _lend(uint256 amount, address lender) external returns (uint256) {
        require(msg.sender == address(controller), "wrong address");
        return lendInternal(msg.sender, lender, amount);
    }

    function redeem(uint256 tokens) external returns (uint256) {
        return redeemInternal(msg.sender, 0, tokens);
    }

    function redeemUnderlying(uint256 amount) external returns (uint256) {
        return redeemInternal(msg.sender, amount, 0);
    }

    function _transferTokens(address from, address to, uint256 amount) internal override returns (bool) {
        require(stableCoin.balanceOf(from) >= amount, toString(Error.INSUFFICIENT_FUNDS));
        if (from == address(this)) {
            require(stableCoin.transfer(to, amount), toString(Error.TRANSFER_FAILED));
        } else {
            require(stableCoin.transferFrom(from, to, amount), toString(Error.TRANSFER_FAILED));
        }
        return true;
    }

    function getCash() public override virtual view returns (uint256) {
        return stableCoin.balanceOf(address(this));
    }

    function lendAllowed(address _pool, address _lender, uint256 _amount) internal override returns (uint256) {
        return controller.lendAllowed(_pool, _lender, _amount);
    }

    function redeemAllowed(address _pool, address _redeemer, uint256 _tokenAmount) internal override returns (uint256) {
        return controller.redeemAllowed(_pool, _redeemer, _tokenAmount);
    }


    struct CreditLineLocalVars {
        uint256 allowed;
        uint256 assetValue;
        uint256 borrowCap;
        uint256 interestRate;
        uint256 advanceRate;
        uint256 maturity;
    }
    function createCreditLine(uint256 tokenId) external nonReentrant returns (uint256) {
        CreditLineLocalVars memory vars;
        (
            vars.allowed,
            vars.assetValue,
            vars.maturity,
            vars.interestRate,
            vars.advanceRate
        ) = controller.createCreditLineAllowed(address(this), msg.sender, tokenId);
        if (vars.allowed != 0) {
            return uint256(Error.C_CREATE_REJECTION);
        }

        vars.borrowCap = vars.assetValue * vars.advanceRate / 100;
        return createCreditLineInternal(msg.sender, tokenId, vars.borrowCap, vars.interestRate, vars.maturity);
    }

    function closeCreditLine(uint256 loanId) external nonReentrant returns (uint256) {
        return closeCreditLineInternal(msg.sender, loanId);
    }

    function redeemAsset(uint256 tokenId) internal override returns (uint256) {
        controller.assetsFactory().markAsRedeemed(tokenId);
        return uint256(Error.NO_ERROR);
    }

    struct UnlockLocalVars {
        MathError mathErr;
        uint256 lockedAsset;
    }
    function unlockAsset(uint256 loanId) external nonReentrant returns (uint256) {
        UnlockLocalVars memory vars;

        (vars.mathErr, vars.lockedAsset) = unlockAssetInternal(msg.sender, loanId);
        ErrorReporter.check((uint256(vars.mathErr)));

        controller.assetsFactory().transferFrom(address(this), msg.sender, vars.lockedAsset);
        return uint256(Error.NO_ERROR);
    }

    function borrow(uint256 loanId, uint256 amount) external returns (uint256) {
        return borrowInternal(loanId, msg.sender, amount);
    }

    function repay(uint256 loanId, uint256 amount) external returns (uint256) {
        return repayInternal(loanId, msg.sender, msg.sender, amount);
    }

    function repayBehalf(address borrower, uint256 loanId, uint256 amount) external returns (uint256) {
        return repayInternal(loanId, msg.sender, borrower, amount);
    }

    function getTotalBorrowBalance() public virtual override(Lendable, Borrowable) view returns (uint256) {
        uint256 total;
        for (uint8 i = 0; i < creditLines.length; i++) {
            total += borrowBalanceSnapshot(i);
        }
        return total;
    }

    struct BorrowIndexLocalVars {
        MathError mathErr;
        uint256 blockNumber;
        uint256 accrualBlockNumber;
        uint256 priorBorrowIndex;
        uint256 newBorrowIndex;
        uint256 borrowRateMantissa;
        uint256 blockDelta;
        Exp interestFactor;
    }
    function getBorrowIndex(uint256 loanId) public override view returns (uint256) {
        CreditLine storage creditLine = creditLines[loanId];
        BorrowIndexLocalVars memory vars;

        vars.accrualBlockNumber = creditLine.accrualBlockNumber;
        vars.priorBorrowIndex = creditLine.borrowIndex;
        vars.blockNumber = getBlockNumber();




















































































































































