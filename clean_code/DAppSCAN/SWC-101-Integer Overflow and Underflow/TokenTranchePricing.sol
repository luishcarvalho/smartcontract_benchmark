





pragma solidity ^0.4.15;

import "./SafeMath.sol";
import "./Ownable.sol";





contract TokenTranchePricing is Ownable {

  using SafeMath for uint;




  struct Tranche {

      uint amount;


      uint start;

      uint end;

      uint price;
  }

  uint private constant amount_offset = 0;
  uint private constant start_offset = 1;
  uint private constant end_offset = 2;
  uint private constant price_offset = 3;
  uint private constant tranche_size = 4;

  Tranche[] public tranches;



  function TokenTranchePricing(uint[] init_tranches) public {

    require(init_tranches.length % tranche_size == 0);


    require(init_tranches[amount_offset] > 0);

    tranches.length = init_tranches.length / tranche_size;
    for (uint i = 0; i < init_tranches.length / tranche_size; i++) {

      uint amount = init_tranches[i * tranche_size + amount_offset];
      uint start = init_tranches[i * tranche_size + start_offset];
      uint end = init_tranches[i * tranche_size + end_offset];
      require(block.number < start && start < end);


      require(i == 0 || (end >= tranches[i - 1].end && amount > tranches[i - 1].amount) ||
              (end > tranches[i - 1].end && amount >= tranches[i - 1].amount));

      tranches[i].amount = amount;
      tranches[i].price = init_tranches[i * tranche_size + price_offset];
      tranches[i].start = start;
      tranches[i].end = end;
    }
  }




  function getCurrentTranche(uint tokensSold) private constant returns (Tranche) {
    for (uint i = 0; i < tranches.length; i++) {
      if (tranches[i].start <= block.number && block.number < tranches[i].end && tokensSold < tranches[i].amount) {
        return tranches[i];
      }
    }

    revert();
  }




  function getCurrentPrice(uint tokensSold) public constant returns (uint result) {
    return getCurrentTranche(tokensSold).price;
  }

}
