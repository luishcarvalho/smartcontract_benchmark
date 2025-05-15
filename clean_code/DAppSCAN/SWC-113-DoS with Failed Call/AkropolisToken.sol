pragma solidity >=0.4.24;

import "./AkropolisBaseToken.sol";
import "../helpers/Lockable.sol";
import "../helpers/Pausable.sol";
import "../helpers/Whitelist.sol";







contract AkropolisToken is AkropolisBaseToken, Pausable, Lockable, Whitelist {
    using SafeMath for uint256;
























    function approve(address _spender, uint256 _value)
    public whenNotPaused  whenUnlocked returns (bool) {
        return super.approve(_spender, _value);
    }










    function increaseApproval(address _spender, uint256 _addedValue)
    public whenNotPaused returns (bool) {
        increaseApprovalAllArgs(_spender, _addedValue, msg.sender);
        return true;
    }










    function decreaseApproval(address _spender, uint256 _subtractedValue)
    public whenNotPaused returns (bool) {
        decreaseApprovalAllArgs(_spender, _subtractedValue, msg.sender);
        return true;
    }


    function transfer(address _to, uint256 _amount) public whenNotPaused onlyWhitelist checkPermBalanceForWhitelist(_amount) returns (bool) {
        return super.transfer(_to, _amount);
    }














    function transferFrom(address _from, address _to, uint256 _amount)
    public whenNotPaused onlyWhitelist checkPermBalanceForWhitelist(_amount) returns (bool) {
        return super.transferFrom(_from, _to, _amount);
    }



















