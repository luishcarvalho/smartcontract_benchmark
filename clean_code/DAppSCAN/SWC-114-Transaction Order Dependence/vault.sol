

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./tokens/EIP20NonStandardInterface.sol";

import "./IDerivativeSpecification.sol";
import "./collateralSplits/ICollateralSplit.sol";
import "./tokens/IERC20MintedBurnable.sol";
import "./tokens/ITokenBuilder.sol";
import "./IFeeLogger.sol";

import "./IPausableVault.sol";



contract Vault is Ownable, Pausable, IPausableVault, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint256 public constant FRACTION_MULTIPLIER = 10**12;

    enum State { Created, Live, Settled }

    event StateChanged(State oldState, State newState);
    event LiveStateSet(address primaryToken, address complementToken);
    event SettledStateSet(
        int256[] underlyingStarts,
        int256[] underlyingEnds,
        uint256 primaryConversion,
        uint256 complementConversion
    );
    event Minted(
        address indexed recipient,
        uint256 minted,
        uint256 collateral,
        uint256 fee
    );
    event Refunded(
        address indexed recipient,
        uint256 tokenAmount,
        uint256 collateral
    );
    event Redeemed(
        address indexed recipient,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 conversion,
        uint256 collateral
    );


    uint256 public liveTime;

    uint256 public settleTime;


    uint256 public settlementDelay;


    int256[] public underlyingStarts;

    int256[] public underlyingEnds;


    uint256 public primaryConversion;

    uint256 public complementConversion;


    uint256 public protocolFee;

    uint256 public authorFeeLimit;


    address public feeWallet;


    State public state;


    IDerivativeSpecification public derivativeSpecification;

    IERC20 public collateralToken;

    address[] public oracles;
    address[] public oracleIterators;

    ICollateralSplit public collateralSplit;

    ITokenBuilder public tokenBuilder;
    IFeeLogger public feeLogger;


    IERC20MintedBurnable public primaryToken;

    IERC20MintedBurnable public complementToken;

    constructor(
        uint256 _liveTime,
        uint256 _protocolFee,
        address _feeWallet,
        address _derivativeSpecification,
        address _collateralToken,
        address[] memory _oracles,
        address[] memory _oracleIterators,
        address _collateralSplit,
        address _tokenBuilder,
        address _feeLogger,
        uint256 _authorFeeLimit,
        uint256 _settlementDelay
    ) public {
        require(_liveTime > 0, "Live zero");
        require(_liveTime <= block.timestamp, "Live in future");
        liveTime = _liveTime;

        protocolFee = _protocolFee;

        require(_feeWallet != address(0), "Fee wallet");
        feeWallet = _feeWallet;

        require(_derivativeSpecification != address(0), "Derivative");
        derivativeSpecification = IDerivativeSpecification(
            _derivativeSpecification
        );

        require(_collateralToken != address(0), "Collateral token");
        collateralToken = IERC20(_collateralToken);

        require(_oracles.length > 0, "Oracles");
        require(_oracles[0] != address(0), "First oracle is absent");
        oracles = _oracles;

        require(_oracleIterators.length > 0, "OracleIterators");
        require(
            _oracleIterators[0] != address(0),
            "First oracle iterator is absent"
        );
        oracleIterators = _oracleIterators;

        require(_collateralSplit != address(0), "Collateral split");
        collateralSplit = ICollateralSplit(_collateralSplit);

        require(_tokenBuilder != address(0), "Token builder");
        tokenBuilder = ITokenBuilder(_tokenBuilder);

        require(_feeLogger != address(0), "Fee logger");
        feeLogger = IFeeLogger(_feeLogger);

        authorFeeLimit = _authorFeeLimit;

        settleTime = liveTime + derivativeSpecification.livePeriod();
        require(block.timestamp < settleTime, "Settled time");

        settlementDelay = _settlementDelay;
    }

    function pause() external override onlyOwner() {
        _pause();
    }

    function unpause() external override onlyOwner() {
        _unpause();
    }




    function initialize(int256[] calldata _underlyingStarts) external {
        require(state == State.Created, "Incorrect state.");

        underlyingStarts = _underlyingStarts;

        changeState(State.Live);

        (primaryToken, complementToken) = tokenBuilder.buildTokens(
            derivativeSpecification,
            settleTime,
            address(collateralToken)
        );

        emit LiveStateSet(address(primaryToken), address(complementToken));
    }

    function changeState(State _newState) internal {
        state = _newState;
        emit StateChanged(state, _newState);
    }






    function settle(uint256[] calldata _underlyingEndRoundHints)
        public
        whenNotPaused()
    {
        require(state == State.Live, "Incorrect state");
        require(
            block.timestamp >= (settleTime + settlementDelay),
            "Incorrect time"
        );
        changeState(State.Settled);

        uint256 split;
        (split, underlyingEnds) = collateralSplit.split(
            oracles,
            oracleIterators,
            underlyingStarts,
            settleTime,
            _underlyingEndRoundHints
        );
        split = range(split);

        uint256 collectedCollateral = collateralToken.balanceOf(address(this));
        uint256 mintedPrimaryTokenAmount = primaryToken.totalSupply();

        if (mintedPrimaryTokenAmount > 0) {
            uint256 primaryCollateralPortion = collectedCollateral.mul(split);
            primaryConversion = primaryCollateralPortion.div(
                mintedPrimaryTokenAmount
            );
            complementConversion = collectedCollateral
                .mul(FRACTION_MULTIPLIER)
                .sub(primaryCollateralPortion)
                .div(mintedPrimaryTokenAmount);
        }

        emit SettledStateSet(
            underlyingStarts,
            underlyingEnds,
            primaryConversion,
            complementConversion
        );
    }

    function range(uint256 _split) public pure returns (uint256) {
        if (_split > FRACTION_MULTIPLIER) {
            return FRACTION_MULTIPLIER;
        }
        return _split;
    }

    function performMint(address _recipient, uint256 _collateralAmount)
        internal
    {
        require(state == State.Live, "Live is over");

        require(_collateralAmount > 0, "Zero amount");
        _collateralAmount = doTransferIn(msg.sender, _collateralAmount);

        uint256 feeAmount = withdrawFee(_collateralAmount);

        uint256 netAmount = _collateralAmount.sub(feeAmount);

        uint256 tokenAmount = denominate(netAmount);

        primaryToken.mint(_recipient, tokenAmount);
        complementToken.mint(_recipient, tokenAmount);

        emit Minted(_recipient, tokenAmount, _collateralAmount, feeAmount);
    }

    function mintTo(address _recipient, uint256 _collateralAmount)
        external
        nonReentrant()
    {
        performMint(_recipient, _collateralAmount);
    }



    function mint(uint256 _collateralAmount) external nonReentrant() {
        performMint(msg.sender, _collateralAmount);
    }

    function performRefund(address _recipient, uint256 _tokenAmount) internal {
        require(_tokenAmount > 0, "Zero amount");
        require(
            _tokenAmount <= primaryToken.balanceOf(msg.sender),
            "Insufficient primary amount"
        );
        require(
            _tokenAmount <= complementToken.balanceOf(msg.sender),
            "Insufficient complement amount"
        );

        primaryToken.burnFrom(msg.sender, _tokenAmount);
        complementToken.burnFrom(msg.sender, _tokenAmount);
        uint256 unDenominated = unDenominate(_tokenAmount);

        emit Refunded(_recipient, _tokenAmount, unDenominated);
        doTransferOut(_recipient, unDenominated);
    }


    function refund(uint256 _tokenAmount) external nonReentrant() {
        performRefund(msg.sender, _tokenAmount);
    }

    function refundTo(address _recipient, uint256 _tokenAmount)
        external
        nonReentrant()
    {
        performRefund(_recipient, _tokenAmount);
    }

    function performRedeem(
        address _recipient,
        uint256 _primaryTokenAmount,
        uint256 _complementTokenAmount,
        uint256[] calldata _underlyingEndRoundHints
    ) internal {
        require(
            _primaryTokenAmount > 0 || _complementTokenAmount > 0,
            "Both tokens zero amount"
        );
        require(
            _primaryTokenAmount <= primaryToken.balanceOf(msg.sender),
            "Insufficient primary amount"
        );
        require(
            _complementTokenAmount <= complementToken.balanceOf(msg.sender),
            "Insufficient complement amount"
        );

        if (
            block.timestamp >= (settleTime + settlementDelay) &&
            state == State.Live
        ) {
            settle(_underlyingEndRoundHints);
        }

        if (state == State.Settled) {
            uint256 collateral =
                redeemAsymmetric(
                    _recipient,
                    primaryToken,
                    _primaryTokenAmount,
                    primaryConversion
                );
            collateral = redeemAsymmetric(
                _recipient,
                complementToken,
                _complementTokenAmount,
                complementConversion
            )
                .add(collateral);

            if (collateral > 0) {
                doTransferOut(_recipient, collateral);
            }
        }
    }

    function redeemTo(
        address _recipient,
        uint256 _primaryTokenAmount,
        uint256 _complementTokenAmount,
        uint256[] calldata _underlyingEndRoundHints
    ) external nonReentrant() {
        performRedeem(
            _recipient,
            _primaryTokenAmount,
            _complementTokenAmount,
            _underlyingEndRoundHints
        );
    }


    function redeem(
        uint256 _primaryTokenAmount,
        uint256 _complementTokenAmount,
        uint256[] calldata _underlyingEndRoundHints
    ) external nonReentrant() {
        performRedeem(
            msg.sender,
            _primaryTokenAmount,
            _complementTokenAmount,
            _underlyingEndRoundHints
        );
    }

    function redeemAsymmetric(
        address _recipient,
        IERC20MintedBurnable _derivativeToken,
        uint256 _amount,
        uint256 _conversion
    ) internal returns (uint256 collateral) {
        if (_amount == 0) {
            return 0;
        }

        _derivativeToken.burnFrom(msg.sender, _amount);
        collateral = _amount.mul(_conversion) / FRACTION_MULTIPLIER;
        emit Redeemed(
            _recipient,
            address(_derivativeToken),
            _amount,
            _conversion,
            collateral
        );
    }

    function denominate(uint256 _collateralAmount)
        internal
        view
        returns (uint256)
    {
        return
            _collateralAmount.div(
                derivativeSpecification.primaryNominalValue() +
                    derivativeSpecification.complementNominalValue()
            );
    }

    function unDenominate(uint256 _tokenAmount)
        internal
        view
        returns (uint256)
    {
        return
            _tokenAmount.mul(
                derivativeSpecification.primaryNominalValue() +
                    derivativeSpecification.complementNominalValue()
            );
    }

    function withdrawFee(uint256 _amount) internal returns (uint256) {
        uint256 protocolFeeAmount =
            calcAndTransferFee(_amount, payable(feeWallet), protocolFee);

        feeLogger.log(
            msg.sender,
            address(collateralToken),
            protocolFeeAmount,
            derivativeSpecification.author()
        );

        uint256 authorFee = derivativeSpecification.authorFee();
        if (authorFee > authorFeeLimit) {
            authorFee = authorFeeLimit;
        }
        uint256 authorFeeAmount =
            calcAndTransferFee(
                _amount,
                payable(derivativeSpecification.author()),
                authorFee
            );

        return protocolFeeAmount.add(authorFeeAmount);
    }

    function calcAndTransferFee(
        uint256 _amount,
        address payable _beneficiary,
        uint256 _fee
    ) internal returns (uint256 _feeAmount) {
        _feeAmount = _amount.mul(_fee).div(FRACTION_MULTIPLIER);
        if (_feeAmount > 0) {
            doTransferOut(_beneficiary, _feeAmount);
        }
    }







    function doTransferIn(address from, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 balanceBefore = collateralToken.balanceOf(address(this));
        EIP20NonStandardInterface(address(collateralToken)).transferFrom(
            from,
            address(this),
            amount
        );

        bool success;
        assembly {
            switch returndatasize()
                case 0 {

                    success := not(0)
                }
                case 32 {

                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                default {

                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");


        uint256 balanceAfter = collateralToken.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore;
    }







    function doTransferOut(address to, uint256 amount) internal {
        EIP20NonStandardInterface(address(collateralToken)).transfer(
            to,
            amount
        );

        bool success;
        assembly {
            switch returndatasize()
                case 0 {

                    success := not(0)
                }
                case 32 {

                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                default {

                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}
