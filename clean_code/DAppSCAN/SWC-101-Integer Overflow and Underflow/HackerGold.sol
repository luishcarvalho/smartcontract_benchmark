
import "StandardToken.sol";

pragma solidity ^0.4.0;












contract HackerGold is StandardToken {


    string public name = "HackerGold";


    uint8  public decimals = 3;
    string public symbol = "HKG";


    uint BASE_PRICE = 200;


    uint totalValue;


    address wallet;

    struct milestones_struct {
      uint p1;
      uint p2;
      uint p3;
      uint p4;
      uint p5;
      uint p6;
    }
    milestones_struct milestones;






    function HackerGold(address multisig) {

        wallet = multisig;


        milestones = milestones_struct(

          1476972000,
          1478181600,
          1479391200,

          1480600800,
          1481810400,
          1482415200
        );

    }





    function () payable {
        createHKG(msg.sender);
    }






    function createHKG(address holder) payable {

        if (now < milestones.p1) throw;
        if (now > milestones.p6) throw;
        if (msg.value == 0) throw;


        if (getTotalValue() + msg.value > 4000000 ether) throw;

        uint tokens = msg.value / 1000000000000000 * getPrice();

        totalSupply += tokens;
        balances[holder] += tokens;
        totalValue += msg.value;

        if (!wallet.send(msg.value)) throw;
    }






    function getPrice() constant returns (uint result){

        if (now < milestones.p1) return 0;

        if (now >= milestones.p1 && now < milestones.p2){

            return BASE_PRICE;
        }

        if (now >= milestones.p2 && now < milestones.p3){


            uint days_in = 1 + (now - milestones.p2) / (60 * 60 *24);
            return BASE_PRICE - days_in * 25 / 7;
        }

        if (now >= milestones.p3 && now < milestones.p4){

            return BASE_PRICE / 4 * 3;
        }

        if (now >= milestones.p4 && now < milestones.p5){

            days_in = 1 + (now - milestones.p4) / (60 * 60 *24);
            return (BASE_PRICE / 4 * 3) - days_in * 25 / 7;
        }

        if (now >= milestones.p5 && now < milestones.p6){

            return BASE_PRICE / 2;
        }

        if (now >= milestones.p6){

            return 0;
        }

     }







    function getTotalSupply() constant returns (uint result){
        return totalSupply;
    }

    function getNow() constant returns (uint result) {
        return now;
    }






    function getTotalValue() constant returns (uint result) {
        return totalValue;
    }
}
