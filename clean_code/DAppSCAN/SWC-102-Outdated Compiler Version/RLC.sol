pragma solidity ^0.4.8;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./TokenSpender.sol";

contract RLC is ERC20, SafeMath, Ownable {

























  function RLC() {

    locked = true;
    unlockBlock=  now + 45 days;

    initialSupply = 87000000000000000;
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply;
    name = 'iEx.ec Network Token';
    symbol = 'RLC';
    decimals = 9;
    burnAddress = 0x1b32000000000000000000000000000000000000;
  }

  function unlock() {
    if (now < unlockBlock) throw;
    if (!locked) throw;
    locked = false;
  }

  function burn(uint256 _value) returns (bool success){
    balances[msg.sender] = safeSub(balances[msg.sender], _value) ;
    balances[burnAddress] = safeAdd(balances[burnAddress], _value);
    totalSupply = safeSub(totalSupply, _value);
    Transfer(msg.sender, burnAddress, _value);
    return true;
  }

  function transfer(address _to, uint _value) onlyUnlocked returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) onlyUnlocked returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }


















