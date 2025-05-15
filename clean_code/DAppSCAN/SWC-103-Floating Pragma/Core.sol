
pragma solidity ^0.5.4;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "erc721o/contracts/Libs/LibPosition.sol";

import "./Interface/IDerivativeLogic.sol";

import "./Errors/CoreErrors.sol";

import "./Lib/usingRegistry.sol";
import "./Lib/LibDerivative.sol";
import "./Lib/LibCommission.sol";

import "./Registry.sol";
import "./TokenMinter.sol";
import "./OracleAggregator.sol";
import "./SyntheticAggregator.sol";
import "./TokenSpender.sol";


contract Core is LibDerivative, LibCommission, usingRegistry, CoreErrors, ReentrancyGuard {
    using SafeMath for uint256;
    using LibPosition for bytes32;
    using SafeERC20 for IERC20;


    event Created(address buyer, address seller, bytes32 derivativeHash, uint256 quantity);

    event Executed(address tokenOwner, uint256 tokenId, uint256 quantity);

    event Canceled(bytes32 derivativeHash);


    uint256 public constant NO_DATA_CANCELLATION_PERIOD = 2 weeks;




    mapping (address => mapping(address => uint256)) public poolVaults;




    mapping (address => mapping(address => uint256)) public feesVaults;


    mapping (bytes32 => bool) public cancelled;


    constructor(address _registry) public usingRegistry(_registry) {}





    function withdrawFee(address _tokenAddress) public nonReentrant {
        uint256 balance = feesVaults[msg.sender][_tokenAddress];
        feesVaults[msg.sender][_tokenAddress] = 0;
        IERC20(_tokenAddress).transfer(msg.sender, balance);
    }







    function create(Derivative memory _derivative, uint256 _quantity, address[2] memory _addresses) public nonReentrant {
        if (_addresses[1] == address(0)) {
            _createPooled(_derivative, _quantity, _addresses[0]);
        } else {
            _create(_derivative, _quantity, _addresses);
        }
    }





    function execute(uint256 _tokenId, uint256 _quantity, Derivative memory _derivative) public nonReentrant {
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory quantities = new uint256[](1);
        Derivative[] memory derivatives = new Derivative[](1);

        tokenIds[0] = _tokenId;
        quantities[0] = _quantity;
        derivatives[0] = _derivative;

        _execute(msg.sender, tokenIds, quantities, derivatives);
    }






    function execute(address _tokenOwner, uint256 _tokenId, uint256 _quantity, Derivative memory _derivative) public nonReentrant {
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory quantities = new uint256[](1);
        Derivative[] memory derivatives = new Derivative[](1);

        tokenIds[0] = _tokenId;
        quantities[0] = _quantity;
        derivatives[0] = _derivative;

        _execute(_tokenOwner, tokenIds, quantities, derivatives);
    }





    function execute(uint256[] memory _tokenIds, uint256[] memory _quantities, Derivative[] memory _derivatives) public nonReentrant {
        _execute(msg.sender, _tokenIds, _quantities, _derivatives);
    }






    function execute(address _tokenOwner, uint256[] memory _tokenIds, uint256[] memory _quantities, Derivative[] memory _derivatives) public nonReentrant {
        _execute(_tokenOwner, _tokenIds, _quantities, _derivatives);
    }





    function cancel(uint256 _tokenId, uint256 _quantity, Derivative memory _derivative) public nonReentrant {
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory quantities = new uint256[](1);
        Derivative[] memory derivatives = new Derivative[](1);

        tokenIds[0] = _tokenId;
        quantities[0] = _quantity;
        derivatives[0] = _derivative;

        _cancel(tokenIds, quantities, derivatives);
    }





    function cancel(uint256[] memory _tokenIds, uint256[] memory _quantities, Derivative[] memory _derivatives) public nonReentrant {
        _cancel(_tokenIds, _quantities, _derivatives);
    }



    struct CreatePooledLocalVars {
        SyntheticAggregator syntheticAggregator;
        IDerivativeLogic derivativeLogic;
        IERC20 marginToken;
        TokenSpender tokenSpender;
        TokenMinter tokenMinter;
    }





    function _createPooled(Derivative memory _derivative, uint256 _quantity, address _address) private {

        CreatePooledLocalVars memory vars;






        vars.syntheticAggregator = SyntheticAggregator(registry.getSyntheticAggregator());
        vars.derivativeLogic = IDerivativeLogic(_derivative.syntheticId);
        vars.marginToken = IERC20(_derivative.token);
        vars.tokenSpender = TokenSpender(registry.getTokenSpender());
        vars.tokenMinter = TokenMinter(registry.getMinter());


        bytes32 derivativeHash = getDerivativeHash(_derivative);


        require(vars.syntheticAggregator.isPool(derivativeHash, _derivative), ERROR_CORE_NOT_POOL);


        require(!cancelled[derivativeHash], ERROR_CORE_TICKER_WAS_CANCELLED);


        require(vars.derivativeLogic.validateInput(_derivative), ERROR_CORE_SYNTHETIC_VALIDATION_ERROR);


        (uint256 margin, ) = vars.syntheticAggregator.getMargin(derivativeHash, _derivative);



        require(vars.marginToken.allowance(msg.sender, address(vars.tokenSpender)) >= margin.mul(_quantity), ERROR_CORE_NOT_ENOUGH_TOKEN_ALLOWANCE);


        vars.tokenSpender.claimTokens(vars.marginToken, msg.sender, address(this), margin.mul(_quantity));


        poolVaults[_derivative.syntheticId][_derivative.token] = poolVaults[_derivative.syntheticId][_derivative.token].add(margin.mul(_quantity));


        vars.tokenMinter.mint(_address, derivativeHash, _quantity);

        emit Created(_address, address(0), derivativeHash, _quantity);
    }

    struct CreateLocalVars {
        SyntheticAggregator syntheticAggregator;
        IDerivativeLogic derivativeLogic;
        IERC20 marginToken;
        TokenSpender tokenSpender;
        TokenMinter tokenMinter;
    }







    function _create(Derivative memory _derivative, uint256 _quantity, address[2] memory _addresses) private {

        CreateLocalVars memory vars;






        vars.syntheticAggregator = SyntheticAggregator(registry.getSyntheticAggregator());
        vars.derivativeLogic = IDerivativeLogic(_derivative.syntheticId);
        vars.marginToken = IERC20(_derivative.token);
        vars.tokenSpender = TokenSpender(registry.getTokenSpender());
        vars.tokenMinter = TokenMinter(registry.getMinter());


        bytes32 derivativeHash = getDerivativeHash(_derivative);


        require(!vars.syntheticAggregator.isPool(derivativeHash, _derivative), ERROR_CORE_CANT_BE_POOL);


        require(!cancelled[derivativeHash], ERROR_CORE_TICKER_WAS_CANCELLED);


        require(vars.derivativeLogic.validateInput(_derivative), ERROR_CORE_SYNTHETIC_VALIDATION_ERROR);

        uint256[2] memory margins;



        (margins[0], margins[1]) = vars.syntheticAggregator.getMargin(derivativeHash, _derivative);



        require(vars.marginToken.allowance(msg.sender, address(vars.tokenSpender)) >= margins[0].add(margins[1]).mul(_quantity), ERROR_CORE_NOT_ENOUGH_TOKEN_ALLOWANCE);


        vars.tokenSpender.claimTokens(vars.marginToken, msg.sender, address(this), margins[0].add(margins[1]).mul(_quantity));


        vars.tokenMinter.mint(_addresses[0], _addresses[1], derivativeHash, _quantity);

        emit Created(_addresses[0], _addresses[1], derivativeHash, _quantity);
    }

    struct ExecuteAndCancelLocalVars {
        TokenMinter tokenMinter;
        OracleAggregator oracleAggregator;
        SyntheticAggregator syntheticAggregator;
    }






    function _execute(address _tokenOwner, uint256[] memory _tokenIds, uint256[] memory _quantities, Derivative[] memory _derivatives) private {
        require(_tokenIds.length == _quantities.length, ERROR_CORE_TOKEN_IDS_AND_QUANTITIES_LENGTH_DOES_NOT_MATCH);
        require(_tokenIds.length == _derivatives.length, ERROR_CORE_TOKEN_IDS_AND_DERIVATIVES_LENGTH_DOES_NOT_MATCH);


        ExecuteAndCancelLocalVars memory vars;




        vars.tokenMinter = TokenMinter(registry.getMinter());
        vars.oracleAggregator = OracleAggregator(registry.getOracleAggregator());
        vars.syntheticAggregator = SyntheticAggregator(registry.getSyntheticAggregator());

        for (uint256 i; i < _tokenIds.length; i++) {

            require(now > _derivatives[i].endTime, ERROR_CORE_EXECUTION_BEFORE_MATURITY_NOT_ALLOWED);


            require(
                _tokenOwner == msg.sender ||
                IDerivativeLogic(_derivatives[i].syntheticId).thirdpartyExecutionAllowed(_tokenOwner),
                ERROR_CORE_SYNTHETIC_EXECUTION_WAS_NOT_ALLOWED
            );


            uint256 payout = _getPayout(_derivatives[i], _tokenIds[i], _quantities[i], vars);


            if (payout > 0) {
                IERC20(_derivatives[i].token).safeTransfer(_tokenOwner, payout);
            }


            vars.tokenMinter.burn(_tokenOwner, _tokenIds[i], _quantities[i]);

            emit Executed(_tokenOwner, _tokenIds[i], _quantities[i]);
        }
    }





    function _cancel(uint256[] memory _tokenIds, uint256[] memory _quantities, Derivative[] memory _derivatives) private {
        require(_tokenIds.length == _quantities.length, ERROR_CORE_TOKEN_IDS_AND_QUANTITIES_LENGTH_DOES_NOT_MATCH);
        require(_tokenIds.length == _derivatives.length, ERROR_CORE_TOKEN_IDS_AND_DERIVATIVES_LENGTH_DOES_NOT_MATCH);


        ExecuteAndCancelLocalVars memory vars;




        vars.tokenMinter = TokenMinter(registry.getMinter());
        vars.oracleAggregator = OracleAggregator(registry.getOracleAggregator());
        vars.syntheticAggregator = SyntheticAggregator(registry.getSyntheticAggregator());

        for (uint256 i; i < _tokenIds.length; i++) {

            require(_derivatives[i].oracleId != address(0), ERROR_CORE_CANT_CANCEL_DUMMY_ORACLE_ID);


            require(
                _derivatives[i].endTime + NO_DATA_CANCELLATION_PERIOD <= now &&
                !vars.oracleAggregator.hasData(_derivatives[i].oracleId, _derivatives[i].endTime),
                ERROR_CORE_CANCELLATION_IS_NOT_ALLOWED
            );


            bytes32 derivativeHash = getDerivativeHash(_derivatives[i]);


            if (!cancelled[derivativeHash]) {
                cancelled[derivativeHash] = true;
                emit Canceled(derivativeHash);
            }

            uint256[2] memory margins;



            (margins[0], margins[1]) = vars.syntheticAggregator.getMargin(derivativeHash, _derivatives[i]);

            uint256 payout;

            if (derivativeHash.getLongTokenId() == _tokenIds[i]) {

                payout = margins[0];


            } else if (derivativeHash.getShortTokenId() == _tokenIds[i]) {

                payout = margins[1];
            } else {

                revert(ERROR_CORE_UNKNOWN_POSITION_TYPE);
            }


            if (payout > 0) {
                IERC20(_derivatives[i].token).safeTransfer(msg.sender, payout.mul(_quantities[i]));
            }


            vars.tokenMinter.burn(msg.sender, _tokenIds[i], _quantities[i]);
        }
    }







    function _getPayout(Derivative memory _derivative, uint256 _tokenId, uint256 _quantity, ExecuteAndCancelLocalVars memory _vars) private returns (uint256 payout) {


        uint256 data;
        if (_derivative.oracleId != address(0)) {
            data = _vars.oracleAggregator.getData(_derivative.oracleId, _derivative.endTime);
        } else {
            data = 0;
        }

        uint256[2] memory payoutRatio;



        (payoutRatio[0], payoutRatio[1]) = IDerivativeLogic(_derivative.syntheticId).getExecutionPayout(_derivative, data);


        bytes32 derivativeHash = getDerivativeHash(_derivative);


        require(!cancelled[derivativeHash], ERROR_CORE_TICKER_WAS_CANCELLED);

        uint256[2] memory margins;



        (margins[0], margins[1]) = _vars.syntheticAggregator.getMargin(derivativeHash, _derivative);

        uint256[2] memory payouts;



        payouts[0] = margins[0].add(margins[1]).mul(payoutRatio[0]).div(payoutRatio[0].add(payoutRatio[1]));
        payouts[1] = margins[0].add(margins[1]).mul(payoutRatio[1]).div(payoutRatio[0].add(payoutRatio[1]));


        if (derivativeHash.getLongTokenId() == _tokenId) {

            if (_vars.syntheticAggregator.isPool(derivativeHash, _derivative)) {

                payout = payoutRatio[0];


                payout = payout.mul(_quantity);


                require(
                    poolVaults[_derivative.syntheticId][_derivative.token] >= payout
                    ,
                    ERROR_CORE_INSUFFICIENT_POOL_BALANCE
                );


                poolVaults[_derivative.syntheticId][_derivative.token] = poolVaults[_derivative.syntheticId][_derivative.token].sub(payout);
            } else {

                payout = payouts[0];


                payout = payout.mul(_quantity);
            }



            if (payout > margins[0].mul(_quantity)) {

                payout = payout.sub(_getFees(_vars.syntheticAggregator, derivativeHash, _derivative, payout - margins[0].mul(_quantity)));
            }


        } else if (derivativeHash.getShortTokenId() == _tokenId) {

            payout = payouts[1];


            payout = payout.mul(_quantity);



            if (payout > margins[1].mul(_quantity)) {

                payout = payout.sub(_getFees(_vars.syntheticAggregator, derivativeHash, _derivative, payout - margins[1].mul(_quantity)));
            }
        } else {

            revert(ERROR_CORE_UNKNOWN_POSITION_TYPE);
        }
    }







    function _getFees(SyntheticAggregator _syntheticAggregator, bytes32 _derivativeHash, Derivative memory _derivative, uint256 _profit) private returns (uint256 fee) {

        address authorAddress = _syntheticAggregator.getAuthorAddress(_derivativeHash, _derivative);

        uint256 commission = _syntheticAggregator.getAuthorCommission(_derivativeHash, _derivative);



        fee = _profit.mul(commission).div(COMMISSION_BASE);


        if (fee == 0) {
            return 0;
        }



        uint256 opiumFee = fee.mul(OPIUM_COMMISSION_PART).div(OPIUM_COMMISSION_BASE);



        uint256 authorFee = fee.sub(opiumFee);



        feesVaults[registry.getOpiumAddress()][_derivative.token] = feesVaults[registry.getOpiumAddress()][_derivative.token].add(opiumFee);



        feesVaults[authorAddress][_derivative.token] = feesVaults[authorAddress][_derivative.token].add(authorFee);
    }
}
