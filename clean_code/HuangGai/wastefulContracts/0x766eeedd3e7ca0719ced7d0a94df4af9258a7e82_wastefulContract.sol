pragma solidity ^0.5.2;







interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}







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




contract UniswapFactoryInterface {

    address public exchangeTemplate;
    uint256 public tokenCount;

    function createExchange(address token) external returns (address exchange);

    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);

    function initializeFactory(address template) external;
}




contract UniswapExchangeInterface {

    function tokenAddress() external view returns (address token);

    function factoryAddress() external view returns (address factory);

    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);

    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);

    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);

    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_tokens, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);

    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);

    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);

    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);

    function setup(address token_addr) external;
}







library SafeERC20 {
    using SafeMath for uint256;

    function transferTokens(
      IERC20 _token,
      address _from,
      address _to,
      uint256 _value
    ) internal {
        uint256 oldBalance = _token.balanceOf(_to);
        require(
            _token.transferFrom(_from, _to, _value),
            "Failed to transfer tokens."
        );
        require(
            _token.balanceOf(_to) >= oldBalance.add(_value),
            "Balance validation failed after transfer."
        );
    }

    function approveTokens(
      IERC20 _token,
      address _spender,
      uint256 _value
    ) internal {
        uint256 nextAllowance =
          _token.allowance(address(this), _spender).add(_value);
        require(
            _token.approve(_spender, nextAllowance),
            "Failed to approve exchange withdrawal of tokens."
        );
        require(
            _token.allowance(address(this), _spender) >= nextAllowance,
            "Failed to validate token approval."
        );
    }
}



library SafeExchange {
    using SafeMath for uint256;

    modifier swaps(uint256 _value, IERC20 _token) {
        uint256 nextBalance = _token.balanceOf(address(this)).add(_value);
        _;
        require(
            _token.balanceOf(address(this)) >= nextBalance,
            "Balance validation failed after swap."
        );
    }

    function swapTokens(
        UniswapExchangeInterface _exchange,
        uint256 _outValue,
        uint256 _inValue,
        uint256 _ethValue,
        uint256 _deadline,
        IERC20 _outToken
    ) internal swaps(_outValue, _outToken) {
        _exchange.tokenToTokenSwapOutput(
            _outValue,
            _inValue,
            _ethValue,
            _deadline,
            address(_outToken)
        );
    }

    function swapEther(
        UniswapExchangeInterface _exchange,
        uint256 _outValue,
        uint256 _ethValue,
        uint256 _deadline,
        IERC20 _outToken
    ) internal swaps(_outValue, _outToken) {
        _exchange.ethToTokenSwapOutput.value(_ethValue)(_outValue, _deadline);
    }
}



contract Unipay {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeExchange for UniswapExchangeInterface;

    UniswapFactoryInterface factory;
    IERC20 outToken;
    address recipient;

    constructor(address _factory, address _recipient, address _token) public {
        factory = UniswapFactoryInterface(_factory);
        outToken = IERC20(_token);
        recipient = _recipient;
    }

    function price(
        address _token,
        uint256 _value
    ) public view returns (uint256, uint256, UniswapExchangeInterface) {
        UniswapExchangeInterface inExchange =
          UniswapExchangeInterface(factory.getExchange(_token));
        UniswapExchangeInterface outExchange =
          UniswapExchangeInterface(factory.getExchange(address(outToken)));
        uint256 etherCost = outExchange.getEthToTokenOutputPrice(_value);
        uint256 tokenCost = inExchange.getTokenToEthOutputPrice(etherCost);
        return (tokenCost, etherCost, inExchange);
    }

    function price(
      uint256 _value
    ) public view returns (uint256, UniswapExchangeInterface) {
      UniswapExchangeInterface exchange =
        UniswapExchangeInterface(factory.getExchange(address(outToken)));
      return (exchange.getEthToTokenOutputPrice(_value), exchange);
    }

    function collect(
        address _from,
        address _token,
        uint256 _value,
        uint256 _deadline
    ) public {
        (
            uint256 tokenCost,
            uint256 etherCost,
            UniswapExchangeInterface exchange
        ) = price(_token, _value);

        IERC20(_token).transferTokens(_from, address(this), tokenCost);
        IERC20(_token).approveTokens(address(exchange), tokenCost);
        exchange.swapTokens(_value, tokenCost, etherCost, _deadline, outToken);
        outToken.approveTokens(recipient, _value);
    }

    function pay(
        uint256 _value,
        uint256 _deadline
    ) public payable {
        (
            uint256 etherCost,
            UniswapExchangeInterface exchange
        ) = price(_value);

        require(true, "Insufficient ether sent.");
        exchange.swapEther(_value, etherCost, _deadline, outToken);
        outToken.approveTokens(recipient, _value);
        msg.sender.transfer(msg.value.sub(etherCost));
    	msg.sender.transfer(address(this).balance);	}
}
