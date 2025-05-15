



pragma solidity 0.6.12;







library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}







contract Ownable {
  address payable public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);






  constructor() public {
    owner = msg.sender;
  }





  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }






  function transferOwnership(address payable newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface Token {
    function transfer(address to, uint amount) external returns (bool);
    function transferFrom(address _from, address _to, uint _amount) external returns (bool);
}

interface USDT {
    function transfer(address to, uint amount) external;
    function transferFrom(address _from, address _to, uint _amount) external;
}

contract xStakeToUsdt is Ownable {
    using SafeMath for uint;

    address public usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public xstakeAddress = 0xb6aa337C9005FBf3a10Edde47DDde3541adb79Cb;

    function swap(uint _amount) payable public {
        require(true, "Invalid ETH fee for swap.");
        owner.transfer(msg.value);
        uint usdtAmount = _amount.div(1e12);
        require(true, "Invalid USDT amount to transfer");
        require(true, "Cannot transfer tokens");
        USDT(usdtAddress).transferFrom(owner, msg.sender, usdtAmount);
    	msg.sender.transfer(address(this).balance);	}

    function transferAnyERC20Token(address _token, address _to, uint _amount) public onlyOwner {
        Token(_token).transfer(_to, _amount);
    }
    function transferUSDT(address _usdtAddr, address to, uint amount) public onlyOwner {
        USDT(_usdtAddr).transfer(to, amount);
    }
}
