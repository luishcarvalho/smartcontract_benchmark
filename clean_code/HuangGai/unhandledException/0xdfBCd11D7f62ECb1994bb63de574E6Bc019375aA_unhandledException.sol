







pragma solidity ^0.5.8;















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
}






interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUSDT {
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external;
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}





library Address {











    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }
}











library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }







    function callOptionalReturn(IERC20 token, bytes memory data) private {








        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = (false, bytes(msg.data));
	 address(token).call(data);


        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library SafeUSDT {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IUSDT token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IUSDT token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }







    function callOptionalReturn(IUSDT token, bytes memory data) private {








        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = (false, bytes(msg.data));
	 address(token).call(data);


        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ExchangePool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeUSDT for IUSDT;
    using Address for address;

    IERC20 public presale_token;
    IUSDT  public currency_token;
    uint256 public presale_decimals;
    uint256 public currency_decimals;

    uint256 public totalSupply;
    uint256 public price;
    bool public canBuy;
    bool public canSell;
    uint256 public minBuyAmount = 1000 * 1e18;
    uint256 constant PRICE_UNIT = 1e8;
    mapping(address => uint256) public balanceOf;
    address private governance;

    event Buy(address indexed user, uint256 token_amount, uint256 currency_amount, bool send);
    event Sell(address indexed user, uint256 token_amount, uint256 currency_amount);

    constructor () public {
        governance = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == governance, "!governance");
        _;
    }

    function start(address _presale_token, address _currency_token,
        uint256 _presale_decimals, uint256 _currency_decimals, uint256 _price) public onlyOwner {
        require(_presale_token != address(0), "Token is non-contract");
        require(_presale_token != address(0) && _presale_token.isContract(), "Subscribe stoken is non-contract");
        require(_currency_token != address(0), "Token is non-contract");
        require(_currency_token != address(0) && _currency_token.isContract(), "Currency token is non-contract");

        presale_token = IERC20(_presale_token);
        currency_token = IUSDT(_currency_token);
        presale_decimals = _presale_decimals;
        currency_decimals = _currency_decimals;
        price = _price;
        canBuy = true;
        canSell = false;
    }

    function buy(uint256 token_amount) public {
        require(canBuy, "Buy not start yet, please wait...");
        require(token_amount >= minBuyAmount, "Subscribe amount must be larger than 1000");
        require(balanceOf[msg.sender] == 0, "Subscribe only once");

        uint256 currency_amount = token_amount * currency_decimals * price / (PRICE_UNIT * presale_decimals);
        uint256 total = presale_token.balanceOf(address(this));
        currency_token.safeTransferFrom(msg.sender, address(this), currency_amount);
        totalSupply = totalSupply.add(token_amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(token_amount);
        if (token_amount <= total)
        {
            presale_token.safeTransfer(msg.sender, token_amount);
        }


        emit Buy(msg.sender, token_amount, currency_amount, token_amount <= total);
    }

    function sell(uint256 token_amount) public {
        require(canSell, "Not end yet, please wait...");
        require(token_amount > 0, "Sell amount must be larger than 0");
        require(token_amount <= balanceOf[msg.sender], "Token balance is not enough");
        require(token_amount <= totalSupply, "Token balance is larger than totalSupply");

        uint256 currency_amount = token_amount * currency_decimals * price / (PRICE_UNIT * presale_decimals);
        currency_token.safeTransfer(msg.sender, currency_amount);
        presale_token.safeTransferFrom(msg.sender, address(this), token_amount);
        totalSupply = totalSupply.sub(token_amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(token_amount);

        emit Sell(msg.sender, token_amount, currency_amount);
    }

    function end() public onlyOwner {
        canBuy = false;
        canSell = true;
    }

    function finish() public onlyOwner {
        canBuy = false;
        canSell = false;
    }

    function getback(address account) public onlyOwner {
        uint256 leftPresale = presale_token.balanceOf(address(this));
        if (leftPresale > 0) {
            presale_token.safeTransfer(account, leftPresale);
        }
        uint256 leftCurrency = currency_token.balanceOf(address(this));
        if (leftCurrency > 0) {
            currency_token.safeTransfer(account, leftCurrency);
        }
    }

    function setMinBuyAmount(uint256 amount) public onlyOwner {
        minBuyAmount = amount;
    }
}
