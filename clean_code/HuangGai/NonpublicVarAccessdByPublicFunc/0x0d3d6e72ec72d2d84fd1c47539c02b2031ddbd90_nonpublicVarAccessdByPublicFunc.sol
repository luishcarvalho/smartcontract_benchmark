



pragma solidity ^0.5.16;










interface EIP20Interface {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);





    function totalSupply() external view returns (uint256);






    function balanceOf(address owner) external view returns (uint256 balance);







    function transfer(address dst, uint256 amount) external returns (bool success);








    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);









    function approve(address spender, uint256 amount) external returns (bool success);







    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}


contract ArtemPool {


  uint internal dripStart;


  uint internal dripRate;


  EIP20Interface internal token;


  address internal target;


  uint internal dripped;

  constructor(uint dripRate_, EIP20Interface token_, address target_) public {
    dripStart = block.number;
    dripRate = dripRate_;
    token = token_;
    target = target_;
    dripped = 0;
  }


  function drip() public returns (uint) {

    EIP20Interface token_ = token;
    uint reservoirBalance_ = token_.balanceOf(address(this));
    uint dripRate_ = dripRate;
    uint dripStart_ = dripStart;
    uint dripped_ = dripped;
    address target_ = target;
    uint blockNumber_ = block.number;


    uint dripTotal_ = mul(dripRate_, blockNumber_ - dripStart_, "dripTotal overflow");
    uint deltaDrip_ = sub(dripTotal_, dripped_, "deltaDrip underflow");
    uint toDrip_ = min(reservoirBalance_, deltaDrip_);
    uint drippedNext_ = add(dripped_, toDrip_, "tautological");

    dripped = drippedNext_;
    token_.transfer(target_, toDrip_);

    return toDrip_;
  }



  function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    require(b <= a, errorMessage);
    uint c = a - b;
    return c;
  }

  function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    require(c / a == b, errorMessage);
    return c;
  }

  function min(uint a, uint b) internal pure returns (uint) {
    if (a <= b) {
      return a;
    } else {
      return b;
    }
  }
}
