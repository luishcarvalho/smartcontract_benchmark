

































pragma solidity ^0.6.12;














library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }













    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }













    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }













    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract KingOfTheHill{
    using SafeMath for uint256;


    address payable private _owner;


    uint256 public lastKingBlock;


    address payable public currentKing;


    uint256 public currentBalance = 0;


    uint256 public  minBid = 725000 gwei;


    uint public constant BID_INCRASE = 29000 gwei;


    uint public constant OWNER_REVENUE_PERCENT = 5;


    uint public constant START_BLOCK_DISTANCE = 6000;



    uint public constant MIN_BLOCK_DISTANCE = 5;


    uint public blockDistance = START_BLOCK_DISTANCE;




    event NewKing(address indexed user, uint256 amount);


    event Winner(address indexed user, uint256 amount);




    constructor () public payable {
        _owner = msg.sender;
        lastKingBlock = block.number;
    }




    function placeABid() public payable{
      uint256  income = msg.value;


      require(income >= minBid, "Bid should be greater than min bid");


      uint256 ownerRevenue = income.mul(OWNER_REVENUE_PERCENT).div(100);


      uint256 realIncome = income.sub(ownerRevenue);


      require(ownerRevenue != 0 && realIncome !=0,"Income too small");



      currentBalance = currentBalance.add(realIncome);


      currentKing = msg.sender;
      lastKingBlock = block.number;


      blockDistance = blockDistance - 1;
      if(blockDistance < MIN_BLOCK_DISTANCE){
          blockDistance = MIN_BLOCK_DISTANCE;
      }


      minBid = minBid.add(BID_INCRASE);



      _owner.transfer(0);


      emit NewKing(msg.sender, realIncome);
    }

    receive() external payable {
        placeABid();
    }




    function claim() public payable {


        require(currentKing == msg.sender, "You are not king");


        require(currentBalance > 0, "The treasury is empty");


        require(block.number - lastKingBlock >= blockDistance, "You can pick up the reward only after waiting for the minimum time");



        currentKing.transfer(0);


        emit Winner(msg.sender, currentBalance);



        currentBalance = 0;
        currentKing = address(0x0);
        lastKingBlock = block.number;
        blockDistance = START_BLOCK_DISTANCE;
        minBid = 725000 gwei;
    }




    function blocksRemain() public view returns (uint){

        if(block.number - lastKingBlock > blockDistance){
            return 0;
        }

        return blockDistance - (block.number - lastKingBlock);
    }

}
