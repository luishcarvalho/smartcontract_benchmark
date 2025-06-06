









pragma solidity 0.7.5;














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

abstract contract Owned {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface ERC20Interface {
    function totalSupply() external view returns (uint);

    function balanceOf(address tokenOwner) external view returns (uint256 balance);

    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);

    function transfer(address to, uint256 tokens) external returns (bool success);

    function approve(address spender, uint256 tokens) external returns (bool success);

    function increaseAllowance(address spender, uint256 tokens) external returns (bool success);

    function decreaseAllowance(address spender, uint256 tokens) external returns (bool success);

    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external;
}

contract WOWSale is Owned {
    using SafeMath for uint256;

    WOWToken public token;

    uint256 public totalSold;
    uint256 public rate = 200 ether;
    uint256 public tokenPrice = 5 ether;
    uint256 public startSale = 1614243600;
    uint256 public endSale = 1614502800;
    uint256 public maxBNB = 50 ether;

    uint256 public DEC;

    event ChangeRate(uint256 newRateUSD);
    event Sold(address buyer, uint256 amount);
    event CloseSale();

    constructor(address wowToken) {
        token = WOWToken(wowToken);
        DEC = 10 ** uint256(token.decimals());
    }

    function changeRate(uint256 newRateUSD) public onlyOwner returns (bool success) {
        rate = newRateUSD;
        emit ChangeRate(rate);
        return true;
    }

    function changeEndSale(uint256 newEndSale) public onlyOwner returns (bool success) {
        endSale = newEndSale;
        return true;
    }




    function buyTokens() payable public returns (bool success) {
        require((block.timestamp >= startSale && block.timestamp < endSale), "Crowdsale is over");
        require(tokenPrice > 0, "Token price is not defined");

        uint256 value = msg.value;
        uint256 tokenPriceInBNB = rate.mul(DEC).div(tokenPrice);
        uint256 buyerBalanceInBNB = token.balanceOf(msg.sender).mul(DEC).div(tokenPriceInBNB);

        uint256 buyerLeftCapacity = maxBNB.sub(buyerBalanceInBNB);


        if (value > buyerLeftCapacity) {
            uint256 payBack = value.sub(buyerLeftCapacity);
            payable(msg.sender).transfer(payBack);
            value = buyerLeftCapacity;
        }

        uint256 buyAmount = value.mul(tokenPriceInBNB).div(DEC);
        token.transfer(msg.sender, buyAmount);
        emit Sold(msg.sender, buyAmount);
        return true;
    }

    function close() public onlyOwner returns(bool success) {
        uint256 tokensLeft = token.balanceOf(address(this));
        require(block.timestamp >= endSale || tokensLeft == 0, "Close requirements are not met");


        if (tokensLeft > 0) {
            token.transfer(msg.sender, tokensLeft);
        }

        uint256 collectedBNB = address(this).balance;

        if (collectedBNB > 0) {
            payable(msg.sender).transfer(collectedBNB);
        }

        emit CloseSale();
        return true;
    }


    fallback() external payable {
        buyTokens();
    }
}

contract WOWToken is ERC20Interface, Owned {
    using SafeMath for uint256;

    string public symbol = "WOW";
    string public  name = "WOWswap";
    uint8 public decimals = 18;
    uint256 DEC = 10 ** uint256(decimals);
    uint256 public _totalSupply = 1000000 * DEC;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        balances[owner] = _totalSupply;
        emit Transfer(address(0x0), owner, _totalSupply);
    }

    function totalSupply() override public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) override public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens) override public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) override public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) override public returns (bool success) {
        return approve(spender, allowed[msg.sender][spender].add(amount));
    }

    function decreaseAllowance(address spender, uint256 amount) override public returns (bool success) {
        return approve(spender, allowed[msg.sender][spender].sub(amount));
    }

    function transferFrom(address from, address to, uint256 tokens) override public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) override public view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint256 tokens, bytes memory data) public returns (bool success) {
        approve(spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
}
