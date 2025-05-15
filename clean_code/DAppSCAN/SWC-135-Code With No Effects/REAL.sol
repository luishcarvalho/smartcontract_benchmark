
pragma solidity ^0.4.11;


import "./MiniMeToken.sol";


contract REAL is MiniMeToken {

    function REAL(address _tokenFactory)
            MiniMeToken(
                _tokenFactory,
                0x0,
                0,
                "Real Estate Asset Ledger",
                18,
                "REAL",
                true
            ) {}
}
