
pragma solidity 0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IBrickblockToken.sol";













































contract AccessToken is PausableToken {
  uint8 public constant version = 1;

  IRegistry internal registry;
  string public constant name = "AccessToken";
  string public constant symbol = "ACT";
  uint8 public constant decimals = 18;


  uint256 internal totalMintedPerToken;


  uint256 public totalLockedBBK;



  mapping(address => uint256) internal lockedBBK;


  mapping(address => uint256) internal distributedPerBBK;


  mapping(address => uint256) internal securedTokenDistributions;

  mapping(address => uint256) internal balances;


  mapping(address => uint256) public receivedBalances;


  mapping(address => uint256) public spentBalances;


  event MintEvent(uint256 amount);
  event BurnEvent(address indexed burner, uint256 value);
  event BBKLockedEvent(
    address indexed locker,
    uint256 lockedAmount,
    uint256 totalLockedAmount
  );
  event BBKUnlockedEvent(
    address indexed locker,
    uint256 lockedAmount,
    uint256 totalLockedAmount
  );

  modifier onlyContract(string _contractName)
  {
    require(
      msg.sender == registry.getContractAddress(_contractName)
    );
    _;
  }

  constructor (
    address _registryAddress
  )
    public
  {
    require(_registryAddress != address(0));
    registry = IRegistry(_registryAddress);
  }



  function lockedBbkOf(
    address _address
  )
    external
    view
    returns (uint256)
  {
    return lockedBBK[_address];
  }




  function lockBBK(
    uint256 _amount
  )
    external
    returns (bool)
  {
    IBrickblockToken _bbk = IBrickblockToken(
      registry.getContractAddress("BrickblockToken")
    );

    require(settlePerTokenToSecured(msg.sender));
    lockedBBK[msg.sender] = lockedBBK[msg.sender].add(_amount);
    totalLockedBBK = totalLockedBBK.add(_amount);
    require(_bbk.transferFrom(msg.sender, this, _amount));
    emit BBKLockedEvent(msg.sender, _amount, totalLockedBBK);
    return true;
  }




  function unlockBBK(
    uint256 _amount
  )
    external
    returns (bool)
  {
    IBrickblockToken _bbk = IBrickblockToken(
      registry.getContractAddress("BrickblockToken")
    );
    require(_amount <= lockedBBK[msg.sender]);
    require(settlePerTokenToSecured(msg.sender));
    lockedBBK[msg.sender] = lockedBBK[msg.sender].sub(_amount);
    totalLockedBBK = totalLockedBBK.sub(_amount);
    require(_bbk.transfer(msg.sender, _amount));
    emit BBKUnlockedEvent(msg.sender, _amount, totalLockedBBK);
    return true;
  }




  function distribute(
    uint256 _amount
  )
    external
    onlyContract("FeeManager")
    returns (bool)
  {
    totalMintedPerToken = totalMintedPerToken
      .add(
        _amount
          .mul(1e18)
          .div(totalLockedBBK)
      );

    uint256 _delta = (_amount.mul(1e18) % totalLockedBBK).div(1e18);
    securedTokenDistributions[owner] = securedTokenDistributions[owner].add(_delta);
    totalSupply_ = totalSupply_.add(_amount);
    emit MintEvent(_amount);
    return true;
  }



  function settlePerTokenToSecured(
    address _address
  )
    private
    returns (bool)
  {

    securedTokenDistributions[_address] = securedTokenDistributions[_address]
      .add(
        lockedBBK[_address]
        .mul(totalMintedPerToken.sub(distributedPerBBK[_address]))
        .div(1e18)
      );
    distributedPerBBK[_address] = totalMintedPerToken;

    return true;
  }







  function balanceOf(
    address _address
  )
    public
    view
    returns (uint256)
  {

    return totalMintedPerToken == 0
      ? 0
      : lockedBBK[_address]
      .mul(totalMintedPerToken.sub(distributedPerBBK[_address]))
      .div(1e18)
      .add(securedTokenDistributions[_address])
      .add(receivedBalances[_address])
      .sub(spentBalances[_address]);
  }




  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balanceOf(msg.sender));
    spentBalances[msg.sender] = spentBalances[msg.sender].add(_value);
    receivedBalances[_to] = receivedBalances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }




  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balanceOf(_from));
    require(_value <= allowed[_from][msg.sender]);
    spentBalances[_from] = spentBalances[_from].add(_value);
    receivedBalances[_to] = receivedBalances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }








  function burn(
    address _address,
    uint256 _value
  )
    external
    onlyContract("FeeManager")
    returns (bool)
  {
    require(_value <= balanceOf(_address));
    spentBalances[_address] = spentBalances[_address].add(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit BurnEvent(_address, _value);
    return true;
  }



  function()
    public
    payable
  {
    revert();
  }
}
