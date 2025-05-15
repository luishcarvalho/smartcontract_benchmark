
pragma solidity ^0.4.16;

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

contract GNTAllocation {
    function GNTAllocation(address _golemFactory) {}
}


contract GolemNetworkToken {
    string public constant name = "Test Golem Network Token";
    string public constant symbol = "tGNT";
    uint8 public constant decimals = 18;

    uint256 public constant tokenCreationRate = 10000000000;


    uint256 public constant tokenCreationCap = 82 finney * tokenCreationRate;
    uint256 public constant tokenCreationMin = 15 finney * tokenCreationRate;

    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;


    bool public funding = true;


    address public golemFactory;


    address public migrationMaster;

    GNTAllocation lockedAllocation;


    uint256 public totalTokens;

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

        if (_golemFactory == 0) revert();
        if (_migrationMaster == 0) revert();
        if (_fundingStartBlock <= block.number) revert();
        if (_fundingEndBlock   <= _fundingStartBlock) revert();

        lockedAllocation = new GNTAllocation(_golemFactory);
        migrationMaster = _migrationMaster;
        golemFactory = _golemFactory;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
    }








    function transfer(address _to, uint256 _value) returns (bool) {

        if (funding) revert();

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

    function totalSupply() external view returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }






    function migrate(uint256 _value) external {

        if (funding) revert();
        if (migrationAgent == 0) revert();


        if (_value == 0) revert();
        if (_value > balances[msg.sender]) revert();

        balances[msg.sender] -= _value;
        totalTokens -= _value;
        totalMigrated += _value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }






    function setMigrationAgent(address _agent) external {

        if (funding) revert();
        if (migrationAgent != 0) revert();
        if (msg.sender != migrationMaster) revert();
        migrationAgent = _agent;
    }

    function setMigrationMaster(address _master) external {
        if (msg.sender != migrationMaster) revert();
        if (_master == 0) revert();
        migrationMaster = _master;
    }






    function create() payable external {



        if (!funding) revert();
        if (block.number < fundingStartBlock) revert();
        if (block.number > fundingEndBlock) revert();


        if (msg.value == 0) revert();
        if (msg.value > (tokenCreationCap - totalTokens) / tokenCreationRate)
            revert();

        var numTokens = msg.value * tokenCreationRate;
        totalTokens += numTokens;


        balances[msg.sender] += numTokens;


        Transfer(0, msg.sender, numTokens);
    }







    function finalize() external {

        if (!funding) revert();
        if ((block.number <= fundingEndBlock ||
             totalTokens < tokenCreationMin) &&
            totalTokens < tokenCreationCap) revert();


        funding = false;





        uint256 percentOfTotal = 18;
        uint256 additionalTokens =
            totalTokens * percentOfTotal / (100 - percentOfTotal);
        totalTokens += additionalTokens;
        balances[lockedAllocation] += additionalTokens;
        Transfer(0, lockedAllocation, additionalTokens);


        if (!golemFactory.send(this.balance)) revert();
    }




    function refund() external {

        if (!funding) revert();
        if (block.number <= fundingEndBlock) revert();
        if (totalTokens >= tokenCreationMin) revert();

        var gntValue = balances[msg.sender];
        if (gntValue == 0) revert();
        balances[msg.sender] = 0;
        totalTokens -= gntValue;

        var ethValue = gntValue / tokenCreationRate;
        Refund(msg.sender, ethValue);
        if (!msg.sender.send(ethValue)) revert();
    }
}
