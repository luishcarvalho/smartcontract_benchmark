
pragma solidity ^0.8.0;

import "../Tranche.sol";
import "../InterestToken.sol";
import "../interfaces/IERC20.sol";

contract InterestTokenFactory {



    event InterestTokenCreated(address indexed token, address indexed tranche);








    function deployInterestToken(
        address _tranche,
        string memory _strategySymbol,
        uint256 _expiration,
        uint8 _underlyingDecimals
    ) public returns (InterestToken) {
        InterestToken token = new InterestToken(
            _tranche,
            _strategySymbol,
            _expiration,
            _underlyingDecimals
        );

        emit InterestTokenCreated(address(token), _tranche);

        return token;
    }
}
