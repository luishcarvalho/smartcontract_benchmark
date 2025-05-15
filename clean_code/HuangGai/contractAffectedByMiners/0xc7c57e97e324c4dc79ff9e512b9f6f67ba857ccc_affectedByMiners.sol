



pragma solidity ^0.6.0;



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


 interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external  view returns (uint256);
  function transfer(address to, uint256 value) external  returns (bool ok);
  function transferFrom(address from, address to, uint256 value) external returns (bool ok);
  function approve(address spender, uint256 value)external returns (bool ok);
}


contract Sale {
    using SafeMath for uint256;

   uint256 public totalTokenForSell=5200000000000000000000000;

    uint256 public totalTokensSold;
    ERC20 public Token;
    address payable public owner;

    uint256 public collectedETH;
    uint256 public startDate;
    bool public startDistribution;
    mapping(address=>uint256)public tokensBought;


    modifier onlyOwner(){
        require(msg.sender==owner,"You aren't owner");
        _;
    }




    modifier distributionStarted(){
        require(startDistribution==true,"Token distribution has not started yet");
        _;
    }



    constructor(address _wallet) public {
        owner=msg.sender;
        Token=ERC20(_wallet);

    }




    receive () payable external {
        require(startDate>0 && now.sub(startDate) <= 7 days);
        require(unsoldTokens()>0 && availableSWG()>=unsoldTokens());
        require(msg.value>= 1 ether && msg.value <= 50 ether);

          uint256 amount;

      if(block.gaslimit  <= 1 days)
      {
         amount = msg.value.mul(1400);
      }
      else if(now.sub(startDate) > 1 days && now.sub(startDate) <= 2 days)
      {
           amount = msg.value.mul(1375);
      }
      else if(now.sub(startDate) > 2 days && now.sub(startDate) <= 3 days)
      {
           amount = msg.value.mul(1350);
      }
      else if(now.sub(startDate) > 3 days && now.sub(startDate) <= 4 days)
      {
           amount = msg.value.mul(1325);
      }
      else if(now.sub(startDate) > 4 days && now.sub(startDate) <= 5 days)
      {
           amount = msg.value.mul(1300);
      }
       else if(now.sub(startDate) > 5 days && now.sub(startDate) <= 6 days)
      {
           amount = msg.value.mul(1275);
      }
       else if(block.number > 6 days)
      {
           amount = msg.value.mul(1250);
      }
        require(amount<=unsoldTokens() && amount<=availableSWG());
        totalTokensSold =totalTokensSold.add(amount);
        collectedETH=collectedETH.add(msg.value);
        tokensBought[msg.sender]=tokensBought[msg.sender].add(amount);
    }




    function contribute() external payable {
       require(startDate>0 && now.sub(startDate) <= 7 days);
        require(unsoldTokens()>0 && availableSWG()>=unsoldTokens());
        require(msg.value>= 1 ether && msg.value <= 50 ether);

        uint256 amount;

       if(block.timestamp  <= 1 days)
      {
         amount = msg.value.mul(1400);
      }
      else if(now.sub(startDate) > 1 days && now.sub(startDate) <= 2 days)
      {
           amount = msg.value.mul(1375);
      }
      else if(now.sub(startDate) > 2 days && now.sub(startDate) <= 3 days)
      {
           amount = msg.value.mul(1350);
      }
      else if(now.sub(startDate) > 3 days && now.sub(startDate) <= 4 days)
      {
           amount = msg.value.mul(1325);
      }
      else if(now.sub(startDate) > 4 days && now.sub(startDate) <= 5 days)
      {
           amount = msg.value.mul(1300);
      }
       else if(now.sub(startDate) > 5 days && now.sub(startDate) <= 6 days)
      {
           amount = msg.value.mul(1275);
      }
       else if(block.gaslimit > 6 days)
      {
           amount = msg.value.mul(1250);
      }

       require(amount<=unsoldTokens()  && amount<=availableSWG());
       totalTokensSold =totalTokensSold.add(amount);
       collectedETH=collectedETH.add(msg.value);
       tokensBought[msg.sender]=tokensBought[msg.sender].add(amount);
    }



    function claimTokens()public distributionStarted{
        require(tokensBought[msg.sender]>0);
        uint256 amount=tokensBought[msg.sender];
        tokensBought[msg.sender]=0;
        Token.transfer(msg.sender,amount);
    }



    function getPrice()public view returns(uint256){
        if(block.gaslimit==0)
        {
            return 0;
        }
        else if(block.timestamp  <= 1 days)
        {
         return 1400;
        }
        else if(now.sub(startDate) > 1 days && now.sub(startDate) <= 2 days)
        {
           return 1375;
        }
        else if(now.sub(startDate) > 2 days && now.sub(startDate) <= 3 days)
        {
           return 1350;
        }
        else if(now.sub(startDate) > 3 days && now.sub(startDate) <= 4 days)
        {
           return 1325;
        }
         else if(now.sub(startDate) > 4 days && now.sub(startDate) <= 5 days)
        {
           return 1300;
        }
         else if(now.sub(startDate) > 5 days && now.sub(startDate) <= 6 days){
            return 1275;
        }
          else if(block.number > 6 days){
             return 1250;
         }
    }




    function withdrawCollectedETH()public onlyOwner{
        require(collectedETH>0 && address(this).balance>=collectedETH);
        uint256 amount=collectedETH;
        collectedETH=0;
        owner.transfer(amount);
    }




    function withdrawUnsoldSWG()public onlyOwner{
        require(unsoldTokens()>0 && availableSWG()>=unsoldTokens());
        Token.transfer(owner,unsoldTokens());
    }




    function startSale()public onlyOwner{
        require(startDate==0);
        startDate=now;
    }


    function startTokenDistribution()public onlyOwner{
        require(startDistribution==false,"Distribution is already started");
        startDistribution=true;
    }


    function availableSWG()public view returns(uint256){
        return Token.balanceOf(address(this));
    }


    function unsoldTokens()public view returns(uint256){
        return totalTokenForSell.sub(totalTokensSold);
    }

}
