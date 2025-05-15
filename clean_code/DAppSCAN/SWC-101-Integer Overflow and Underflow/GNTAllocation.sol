pragma solidity ^0.4.4;

import "./Token.sol";

contract GNTAllocation {




    uint256 constant totalAllocations = 30000;


    mapping (address => uint256) allocations;

    GolemNetworkToken gnt;
    uint256 unlockedAt;

    uint256 tokensCreated = 0;

    function GNTAllocation(address _golemFactory) internal {
        gnt = GolemNetworkToken(msg.sender);
        unlockedAt = now + 6 * 30 days;


        allocations[_golemFactory] = 20000;


        allocations[0xde00] = 2500;
        allocations[0xde01] =  730;
        allocations[0xde02] =  730;
        allocations[0xde03] =  730;
        allocations[0xde04] =  730;
        allocations[0xde05] =  730;
        allocations[0xde06] =  630;
        allocations[0xde07] =  630;
        allocations[0xde08] =  630;
        allocations[0xde09] =  630;
        allocations[0xde10] =  310;
        allocations[0xde11] =  153;
        allocations[0xde12] =  150;
        allocations[0xde13] =  100;
        allocations[0xde14] =  100;
        allocations[0xde15] =  100;
        allocations[0xde16] =   70;
        allocations[0xde17] =   70;
        allocations[0xde18] =   70;
        allocations[0xde19] =   70;
        allocations[0xde20] =   70;
        allocations[0xde21] =   42;
        allocations[0xde22] =   25;
    }



    function unlock() external {
        if (now < unlockedAt) throw;


        if (tokensCreated == 0)
            tokensCreated = gnt.balanceOf(this);

        var allocation = allocations[msg.sender];
        allocations[msg.sender] = 0;
        var toTransfer = tokensCreated * allocation / totalAllocations;


        if (!gnt.transfer(msg.sender, toTransfer)) throw;
    }
}
