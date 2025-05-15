pragma solidity ^0.4.4;

import "./GNTAllocation.sol";

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

contract GolemNetworkToken {
    string public constant name = "Golem Network Token";
    string public constant symbol = "GNT";
    uint8 public constant decimals = 18;

    uint256 public constant tokenCreationRate = 1000;


    uint256 public constant tokenCreationCap = 820000 ether * tokenCreationRate;
    uint256 public constant tokenCreationMin = 150000 ether * tokenCreationRate;

    uint256 fundingStartBlock;
    uint256 fundingEndBlock;


    bool fundingMode = true;


    address public golemFactory;


    address public migrationMaster;

    GNTAllocation public lockedAllocation;


    uint256 totalTokens;

    mapping (address => uint256) balances;

    address public migrationAgent;
    uint256 public totalMigrated;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    event Refund(address indexed _from, uint256 _value);

    function GolemNetworkToken(address _golemFactory,
                               address _migrationMaster,
                               uint256 _fundingStartBlock,
                               uint256 _fundingEndBlock) {
        lockedAllocation = new GNTAllocation(_golemFactory);
        migrationMaster = _migrationMaster;
        golemFactory = _golemFactory;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
    }




    function transfer(address _to, uint256 _value) returns (bool) {

        if (fundingMode) throw;

        var senderBalance = balances[msg.sender];
        if (senderBalance >= _value && _value > 0) {
            senderBalance -= _value;
            balances[msg.sender] = senderBalance;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function totalSupply() external constant returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) external constant returns (uint256) {
        return balances[_owner];
    }



    function migrate(uint256 _value) external {

        if (fundingMode) throw;
        if (migrationAgent == 0) throw;


        if (_value == 0) throw;
        if (_value > balances[msg.sender]) throw;

        balances[msg.sender] -= _value;
        totalTokens -= _value;
        totalMigrated += _value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }




    function setMigrationAgent(address _agent) external {

        if (fundingMode) throw;
        if (migrationAgent != 0) throw;
        if (msg.sender != migrationMaster) throw;
        migrationAgent = _agent;
    }

    function setMigrationMaster(address _master) external {
        if (msg.sender != migrationMaster) throw;
        migrationMaster = _master;
    }



    function fundingActive() constant external returns (bool) {

        if (!fundingMode) return false;


        if (block.number < fundingStartBlock ||
            block.number > fundingEndBlock ||
            totalTokens >= tokenCreationCap) return false;
        return true;
    }


    function numberOfTokensLeft() constant external returns (uint256) {
        if (!fundingMode) return 0;
        if (block.number > fundingEndBlock) return 0;
        return tokenCreationCap - totalTokens;
    }

    function finalized() constant external returns (bool) {
        return !fundingMode;
    }




    function() payable external {



        if (!fundingMode) throw;
        if (block.number < fundingStartBlock) throw;
        if (block.number > fundingEndBlock) throw;
        if (totalTokens >= tokenCreationCap) throw;


        if (msg.value == 0) throw;


        var numTokens = msg.value * tokenCreationRate;
        totalTokens += numTokens;
        if (totalTokens > tokenCreationCap) throw;


        balances[msg.sender] += numTokens;


        Transfer(0, msg.sender, numTokens);
    }







    function finalize() external {

        if (!fundingMode) throw;
        if ((block.number <= fundingEndBlock ||
             totalTokens < tokenCreationMin) &&
            totalTokens < tokenCreationCap) throw;


        fundingMode = false;


        if (!golemFactory.send(this.balance)) throw;





        uint256 percentOfTotal = 18;
        uint256 additionalTokens =
            totalTokens * percentOfTotal / (100 - percentOfTotal);
        totalTokens += additionalTokens;
        balances[lockedAllocation] += additionalTokens;
        Transfer(0, lockedAllocation, additionalTokens);
    }




    function refund() external {

        if (!fundingMode) throw;
        if (block.number <= fundingEndBlock) throw;
        if (totalTokens >= tokenCreationMin) throw;

        var gntValue = balances[msg.sender];
        if (gntValue == 0) throw;
        balances[msg.sender] = 0;
        totalTokens -= gntValue;

        var ethValue = gntValue / tokenCreationRate;
        if (!msg.sender.send(ethValue)) throw;
        Refund(msg.sender, ethValue);
    }
}
