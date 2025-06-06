



pragma solidity 0.6.8;

library SafeMath {



  function mul(uint256 a, uint256 b) internal pure returns (uint256) {



    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }




  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    require(b > 0);
    uint256 c = a / b;


    return c;
  }




  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }




  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }





  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint value) external  returns (bool success);
}

contract LAZARUSTokenSale {
  using SafeMath for uint256;

  uint256 public totalSold;
  ERC20 public Token;
  address payable public owner;
  uint256 public collectedETH;
  uint256 public startDate;
  bool private presaleClosed = false;

  constructor(address _wallet) public {
    owner = msg.sender;
    Token = ERC20(_wallet);
  }

  uint256 amount;


  receive () external payable {
    require(startDate > 0 && now.sub(startDate) <= 7 days);
    require(Token.balanceOf(address(this)) > 0);
    require(msg.value >= 0.1 ether && msg.value <= 60 ether);
    require(!presaleClosed);

    if (now.sub(startDate) <= 1 days) {
       amount = msg.value.mul(10);
    } else if(now.sub(startDate) > 1 days) {
       amount = msg.value.mul(10);
    }

    require(amount <= Token.balanceOf(address(this)));

    totalSold = totalSold.add(amount);
    collectedETH = collectedETH.add(msg.value);

    Token.transfer(msg.sender, amount);
  }


  function contribute() public payable {
    require(startDate > 0 && now.sub(startDate) <= 7 days);
    require(Token.balanceOf(address(this)) > 0);
    require(msg.value >= 0.1 ether && msg.value <= 60 ether);
    require(!presaleClosed);

    if (now.sub(startDate) <= 1 days) {
       amount = msg.value.mul(10);
    } else if(now.sub(startDate) > 1 days) {
       amount = msg.value.mul(10);
    }

    require(amount <= Token.balanceOf(address(this)));

    totalSold = totalSold.add(amount);
    collectedETH = collectedETH.add(msg.value);

    Token.transfer(msg.sender, amount);
  }

  function withdrawETH() public {
    require(msg.sender == owner);
    require(presaleClosed == true);
    owner.transfer(collectedETH);
  }

  function endPresale() public {
    require(msg.sender == owner);
    presaleClosed = true;
  }

  function burn() public {
    require(msg.sender == owner && Token.balanceOf(address(this)) > 0 && now.sub(startDate) > 7 days);

    Token.transfer(address(0), Token.balanceOf(address(this)));
  }

  function startSale() public {
    require(msg.sender == owner && startDate==0);
    startDate=now;
  }

  function availableTokens() public view returns(uint256) {
    return Token.balanceOf(address(this));
  }
}
