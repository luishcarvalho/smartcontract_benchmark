
pragma solidity 0.6.12;
import "./DynamicLiquidTokenConverter.sol";
import "../../../token/interfaces/IDSToken.sol";
import "../../../utility/TokenHolder.sol";

import "../../interfaces/ITypedConverterFactory.sol";
import "../../../token/DSToken.sol";




contract DynamicLiquidTokenConverterFactory is TokenHolder {
    IERC20Token internal constant ETH_RESERVE_ADDRESS = IERC20Token(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    event NewConverter(DynamicLiquidTokenConverter indexed _converter, address indexed _owner);
    event NewToken(DSToken indexed _token);




















    function createToken(
      string memory _name,
      string memory _symbol,
      uint8 _decimals,
      uint256 _initialSupply,
      IERC20Token _reserveToken,
      uint32 _reserveWeight,
      uint256 _reserveBalance,
      IContractRegistry _registry,
      uint32 _maxConversionFee,
      uint32 _minimumWeight,
      uint32 _stepWeight,
      uint256 _marketCapThreshold
    )
      public
      payable
      virtual
      returns (DSToken)
    {
        DSToken token = new DSToken(_name, _symbol, _decimals);

        token.issue(msg.sender, _initialSupply);

        emit NewToken(token);

        createConverter(
          token,
          _reserveToken,
          _reserveWeight,
          _reserveBalance,
          _registry,
          _maxConversionFee,
          _minimumWeight,
          _stepWeight,
          _marketCapThreshold
        );

        return token;
    }


















    function createConverter(
      IConverterAnchor _anchor,
      IERC20Token _reserveToken,
      uint32 _reserveWeight,
      uint256 _reserveBalance,
      IContractRegistry _registry,
      uint32 _maxConversionFee,
      uint32 _minimumWeight,
      uint32 _stepWeight,
      uint256 _marketCapThreshold
    )
      public
      payable
      virtual
      returns (DynamicLiquidTokenConverter)
    {
        DynamicLiquidTokenConverter converter = new DynamicLiquidTokenConverter(IDSToken(address(_anchor)), _registry, _maxConversionFee);

        require(_reserveToken == ETH_RESERVE_ADDRESS ? msg.value == _reserveBalance : msg.value == 0, "ERR_ETH_AMOUNT_MISMATCH");

        converter.addReserve(_reserveToken, _reserveWeight);

        if (_reserveBalance > 0)
          if (_reserveToken == ETH_RESERVE_ADDRESS)
              address(converter).transfer(msg.value);
          else
              safeTransferFrom(_reserveToken, msg.sender, address(converter), _reserveBalance);

        converter.setMinimumWeight(_minimumWeight);
        converter.setStepWeight(_stepWeight);
        converter.setMarketCapThreshold(_marketCapThreshold);

        if (_anchor.owner() != address(this))
          _anchor.acceptOwnership();

        _anchor.transferOwnership(address(converter));
        converter.acceptAnchorOwnership();

        converter.transferOwnership(msg.sender);

        emit NewConverter(converter, msg.sender);

        return converter;
    }

    function converterType() public pure returns (uint16) {
        return 3;
    }
}
