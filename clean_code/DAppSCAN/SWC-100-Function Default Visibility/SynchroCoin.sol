pragma solidity ^0.4.11;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/StandardToken.sol";

contract SynchroCoin is Ownable, StandardToken {

    string public constant symbol = "SYC";

    string public constant name = "SynchroCoin";

    uint8 public constant decimals = 12;


    uint256 public STARTDATE;

    uint256 public ENDDATE;


    uint256 public crowdSale;



    address public multisig;

    function SynchroCoin(
    uint256 _initialSupply,
    uint256 _start,
    uint256 _end,
    address _multisig) {
        totalSupply = _initialSupply;
        STARTDATE = _start;
        ENDDATE = _end;
        multisig = _multisig;
        crowdSale = _initialSupply * 55 / 100;
        balances[multisig] = _initialSupply;
    }


    uint256 public totalFundedEther;


    uint256 public totalConsideredFundedEther = 338;

    mapping (address => uint256) consideredFundedEtherOf;

    mapping (address => bool) withdrawalStatuses;

    function calcBonus() public constant returns (uint256){
        return calcBonusAt(now);
    }

    function calcBonusAt(uint256 at) public constant returns (uint256){
        if (at < STARTDATE) {
            return 140;
        }
        else if (at < (STARTDATE + 1 days)) {
            return 120;
        }
        else if (at < (STARTDATE + 7 days)) {
            return 115;
        }
        else if (at < (STARTDATE + 14 days)) {
            return 110;
        }
        else if (at < (STARTDATE + 21 days)) {
            return 105;
        }
        else if (at <= ENDDATE) {
            return 100;
        }
        else {
            return 0;
        }
    }


    function() public payable {
        proxyPayment(msg.sender);
    }

    function proxyPayment(address participant) public payable {
        require(now >= STARTDATE);

        require(now <= ENDDATE);


        require(msg.value >= 100 finney);

        totalFundedEther = totalFundedEther.add(msg.value);

        uint256 _consideredEther = msg.value.mul(calcBonus()).div(100);
        totalConsideredFundedEther = totalConsideredFundedEther.add(_consideredEther);
        consideredFundedEtherOf[participant] = consideredFundedEtherOf[participant].add(_consideredEther);
        withdrawalStatuses[participant] = true;


        Fund(
        participant,
        msg.value,
        totalFundedEther
        );


        multisig.transfer(msg.value);
    }

    event Fund(
    address indexed buyer,
    uint256 ethers,
    uint256 totalEther
    );

    function withdraw() public returns (bool success){
        return proxyWithdraw(msg.sender);
    }

    function proxyWithdraw(address participant) public returns (bool success){
        require(now > ENDDATE);
        require(withdrawalStatuses[participant]);
        require(totalConsideredFundedEther > 1);

        uint256 share = crowdSale.mul(consideredFundedEtherOf[participant]).div(totalConsideredFundedEther);
        participant.transfer(share);
        withdrawalStatuses[participant] = false;
        return true;
    }
















