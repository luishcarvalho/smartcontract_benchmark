















pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

import "@airswap/swap/contracts/interfaces/ISwap.sol";
import "@airswap/tokens/contracts/interfaces/IWETH.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";




contract Wrapper is Ownable {


  ISwap public swapContract;


  IWETH public wethContract;



  bool public contractPaused;






  constructor(
    address wrapperSwapContract,
    address wrapperWethContract
  ) public {
    swapContract = ISwap(wrapperSwapContract);
    wethContract = IWETH(wrapperWethContract);
  }




  modifier notPaused() {
    require(!contractPaused, "CONTRACT_IS_PAUSED");
    _;
  }




  modifier paused() {
    require(contractPaused, "CONTRACT_NOT_PAUSED");
    _;
  }





  function() external payable {

    if(msg.sender != address(wethContract)) {
      revert("DO_NOT_SEND_ETHER");
    }
  }






  function setPausedStatus(bool newStatus) external onlyOwner {
    contractPaused = newStatus;
  }






  function killContract(address payable recipient) external onlyOwner paused {
    selfdestruct(recipient);
  }







  function swap(
    Types.Order calldata order
  ) external payable notPaused {


    require(order.sender.wallet == msg.sender,
      "MSG_SENDER_MUST_BE_ORDER_SENDER");



    require(order.signature.v != 0,
      "SIGNATURE_MUST_BE_SENT");


    if (order.sender.token == address(wethContract)) {


      require(order.sender.param == msg.value,
        "VALUE_MUST_BE_SENT");


      wethContract.deposit.value(msg.value)();


      wethContract.transfer(order.sender.wallet, order.sender.param);

    } else {


      require(msg.value == 0,
        "VALUE_MUST_BE_ZERO");

    }


    swapContract.swap(order);


    if (order.signer.token == address(wethContract)) {


      wethContract.transferFrom(order.sender.wallet, address(this), order.signer.param);


      wethContract.withdraw(order.signer.param);




      msg.sender.call.value(order.signer.param)("");
    }
  }
}
