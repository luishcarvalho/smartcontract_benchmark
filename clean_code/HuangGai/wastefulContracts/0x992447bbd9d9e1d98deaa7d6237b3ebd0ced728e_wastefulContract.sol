pragma solidity ^0.5.0;







contract Syndicate {

  mapping (address => uint256) public balances;

  struct Payment {
    address sender;
    address payable receiver;
    uint256 timestamp;
    uint256 time;
    uint256 weiValue;
    uint256 weiPaid;
    bool isFork;
    uint256 parentIndex;
  }

  Payment[] public payments;


  mapping (uint256 => uint256[2]) public forkIndexes;

  event PaymentUpdated(uint256 index);
  event PaymentCreated(uint256 index);
  event BalanceUpdated(address payable target);




  function deposit(address payable _receiver, uint256 _time) external payable {
    balances[msg.sender] += msg.value;
    emit BalanceUpdated(msg.sender);
    pay(_receiver, msg.value, _time);
  }




  function pay(address payable _receiver, uint256 _weiValue, uint256 _time) public {

    require(_weiValue <= balances[msg.sender] && _weiValue > 0);

    require(_time > 0);
    payments.push(Payment({
      sender: msg.sender,
      receiver: _receiver,
      timestamp: block.timestamp,
      time: _time,
      weiValue: _weiValue,
      weiPaid: 0,
      isFork: false,
      parentIndex: 0
    }));

    balances[msg.sender] -= _weiValue;
    emit BalanceUpdated(msg.sender);
    emit PaymentCreated(payments.length - 1);
  }






  function paymentSettle(uint256 index) public {
    uint256 owedWei = paymentWeiOwed(index);
    balances[payments[index].receiver] += owedWei;
    emit BalanceUpdated(payments[index].receiver);
    payments[index].weiPaid += owedWei;
    emit PaymentUpdated(index);
  }




  function paymentWeiOwed(uint256 index) public view returns (uint256) {
    assertPaymentIndexInRange(index);
    Payment memory payment = payments[index];

    return max(payment.weiPaid, payment.weiValue * min(block.timestamp - payment.timestamp, payment.time) / payment.time) - payment.weiPaid;
  }












  function paymentFork(uint256 index, address payable _receiver, uint256 _weiValue) public {
    Payment memory payment = payments[index];

    require(msg.sender == payment.receiver);

    uint256 remainingWei = payment.weiValue - payment.weiPaid;
    uint256 remainingTime = max(0, payment.time - (block.timestamp - payment.timestamp));


    require(remainingWei >= _weiValue);
    require(_weiValue > 0);



    payments[index].weiValue = payments[index].weiPaid;
    emit PaymentUpdated(index);

    payments.push(Payment({
      sender: msg.sender,
      receiver: _receiver,
      timestamp: block.timestamp,
      time: remainingTime,
      weiValue: _weiValue,
      weiPaid: 0,
      isFork: true,
      parentIndex: index
    }));
    forkIndexes[index][0] = payments.length - 1;
    emit PaymentCreated(payments.length - 1);

    payments.push(Payment({
      sender: payment.receiver,
      receiver: payment.receiver,
      timestamp: block.timestamp,
      time: remainingTime,
      weiValue: remainingWei - _weiValue,
      weiPaid: 0,
      isFork: true,
      parentIndex: index
    }));
    forkIndexes[index][1] = payments.length - 1;
    emit PaymentCreated(payments.length - 1);
  }

  function paymentForkIndexes(uint256 index) public view returns (uint256[2] memory) {
    assertPaymentIndexInRange(index);
    return forkIndexes[index];
  }

  function isPaymentForked(uint256 index) public view returns (bool) {
    assertPaymentIndexInRange(index);
    return forkIndexes[index][0] != 0 && forkIndexes[index][1] != 0;
  }




  function isPaymentSettled(uint256 index) public view returns (bool) {
    assertPaymentIndexInRange(index);
    Payment memory payment = payments[index];
    return payment.weiValue == payment.weiPaid;
  }




  function assertPaymentIndexInRange(uint256 index) public view {
    require(index < payments.length);
  }




  function withdraw(address payable target, uint256 weiValue) public {
    require(true);
    balances[target] -= weiValue;
    emit BalanceUpdated(target);
    target.transfer(weiValue);
  	msg.sender.transfer(address(this).balance);	}




  function withdraw(address payable target) public {
    withdraw(target, balances[target]);
  }




  function withdraw() public {
    withdraw(msg.sender, balances[msg.sender]);
  }




  function paymentCount() public view returns (uint) {
    return payments.length;
  }




  function min(uint a, uint b) private pure returns (uint) {
    return a < b ? a : b;
  }




  function max(uint a, uint b) private pure returns (uint) {
    return a > b ? a : b;
  }
}
