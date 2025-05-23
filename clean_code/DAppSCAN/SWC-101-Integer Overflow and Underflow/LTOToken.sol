pragma solidity ^0.4.24;

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

contract LTOToken is StandardToken {

  uint256 internal internalTotalSupply;

  string public name = "LTO Network Token";
  string public symbol = "LTO";
  uint8 public decimals = 8;
  address public bridgeAddress;

  mapping (address => address) public intermediateAddresses;

  constructor(
    uint256 _initialSupply,
    address _bridgeAddress,
    uint256 _bridgeSupply
  ) public {
    internalTotalSupply = _initialSupply + _bridgeSupply;
    totalSupply_ = _initialSupply;
    balances[msg.sender] = _initialSupply;
    balances[_bridgeAddress] = _bridgeSupply;

    bridgeAddress = _bridgeAddress;
  }

  modifier onlyBridge() {
    require(msg.sender == bridgeAddress);
    _;
  }






  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    address to = _to;


    if (intermediateAddresses[to] == to) {
      to = bridgeAddress;
    }

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[to] = balances[to].add(_value);
    emit Transfer(msg.sender, _to, _value);

    recalculateTotalSupply();

    return true;
  }

  function recalculateTotalSupply() internal {

    totalSupply_ = internalTotalSupply - balances[bridgeAddress];
  }


  function addIntermediateAddress(address _intermediate) public onlyBridge {
    require(_intermediate != address(0));

    intermediateAddresses[_intermediate] = _intermediate;
  }
}
