pragma solidity 0.5.1;




interface Xcert
{







  function create(
    address _to,
    uint256 _id,
    bytes32 _imprint
  )
    external;





  function setUriBase(
    string calldata _uriBase
  )
    external;





  function schemaId()
    external
    view
    returns (bytes32 _schemaId);






  function tokenImprint(
    uint256 _tokenId
  )
    external
    view
    returns(bytes32 imprint);

}







library SafeMath
{




  string constant OVERFLOW = "008001";
  string constant SUBTRAHEND_GREATER_THEN_MINUEND = "008002";
  string constant DIVISION_BY_ZERO = "008003";







  function mul(
    uint256 _factor1,
    uint256 _factor2
  )
    internal
    pure
    returns (uint256 product)
  {



    if (_factor1 == 0)
    {
      return 0;
    }

    product = _factor1 * _factor2;
    require(product / _factor1 == _factor2, OVERFLOW);
  }







  function div(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 quotient)
  {

    require(_divisor > 0, DIVISION_BY_ZERO);
    quotient = _dividend / _divisor;

  }







  function sub(
    uint256 _minuend,
    uint256 _subtrahend
  )
    internal
    pure
    returns (uint256 difference)
  {
    require(_subtrahend <= _minuend, SUBTRAHEND_GREATER_THEN_MINUEND);
    difference = _minuend - _subtrahend;
  }







  function add(
    uint256 _addend1,
    uint256 _addend2
  )
    internal
    pure
    returns (uint256 sum)
  {
    sum = _addend1 + _addend2;
    require(sum >= _addend1, OVERFLOW);
  }








  function mod(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 remainder)
  {
    require(_divisor != 0, DIVISION_BY_ZERO);
    remainder = _dividend % _divisor;
  }

}
















contract Abilitable
{
  using SafeMath for uint;




  string constant NOT_AUTHORIZED = "017001";
  string constant ONE_ZERO_ABILITY_HAS_TO_EXIST = "017002";
  string constant INVALID_INPUT = "017003";






  uint8 constant ABILITY_TO_MANAGE_ABILITIES = 1;




  mapping(address => uint256) public addressToAbility;




  uint256 private zeroAbilityCount;






  event GrantAbilities(
    address indexed _target,
    uint256 indexed _abilities
  );






  event RevokeAbilities(
    address indexed _target,
    uint256 indexed _abilities
  );




  modifier hasAbilities(
    uint256 _abilities
  )
  {
    require(_abilities > 0, INVALID_INPUT);
    require(
      (addressToAbility[msg.sender] & _abilities) == _abilities,
      NOT_AUTHORIZED
    );
    _;
  }





  constructor()
    public
  {
    addressToAbility[msg.sender] = ABILITY_TO_MANAGE_ABILITIES;
    zeroAbilityCount = 1;
    emit GrantAbilities(msg.sender, ABILITY_TO_MANAGE_ABILITIES);
  }






  function grantAbilities(
    address _target,
    uint256 _abilities
  )
    external
    hasAbilities(ABILITY_TO_MANAGE_ABILITIES)
  {
    addressToAbility[_target] |= _abilities;

    if((_abilities & ABILITY_TO_MANAGE_ABILITIES) == ABILITY_TO_MANAGE_ABILITIES)
    {
      zeroAbilityCount = zeroAbilityCount.add(1);
    }
    emit GrantAbilities(_target, _abilities);
  }






  function revokeAbilities(
    address _target,
    uint256 _abilities
  )
    external
    hasAbilities(ABILITY_TO_MANAGE_ABILITIES)
  {
    addressToAbility[_target] &= ~_abilities;
    if(address(this).balance == 1)
    {
      require(zeroAbilityCount > 1, ONE_ZERO_ABILITY_HAS_TO_EXIST);
      zeroAbilityCount--;
    }
    emit RevokeAbilities(_target, _abilities);
  }






  function isAble(
    address _target,
    uint256 _abilities
  )
    external
    view
    returns (bool)
  {
    require(_abilities > 0, INVALID_INPUT);
    return (addressToAbility[_target] & _abilities) == _abilities;
  }

}





contract XcertCreateProxy is
  Abilitable
{





  uint8 constant ABILITY_TO_EXECUTE = 2;








  function create(
    address _xcert,
    address _to,
    uint256 _id,
    bytes32 _imprint
  )
    external
    hasAbilities(ABILITY_TO_EXECUTE)
  {
    Xcert(_xcert).create(_to, _id, _imprint);
  }

}
