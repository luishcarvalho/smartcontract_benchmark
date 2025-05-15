pragma solidity ^0.4.11;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';





contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);





    function burn(uint256 _value) {
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
    }

}
