












pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;








contract Ownable {
    address public _OWNER_;
    address public _NEW_OWNER_;



    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);



    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }



    constructor() internal {
        _OWNER_ = msg.sender;
        emit OwnershipTransferred(address(0), _OWNER_);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}











interface IDODO {
    function init(
        address owner,
        address supervisor,
        address maintainer,
        address baseToken,
        address quoteToken,
        address oracle,
        uint256 lpFeeRate,
        uint256 mtFeeRate,
        uint256 k,
        uint256 gasPriceLimit
    ) external;

    function transferOwnership(address newOwner) external;

    function claimOwnership() external;

    function sellBaseToken(
        uint256 amount,
        uint256 minReceiveQuote,
        bytes calldata data
    ) external returns (uint256);

    function buyBaseToken(
        uint256 amount,
        uint256 maxPayQuote,
        bytes calldata data
    ) external returns (uint256);

    function querySellBaseToken(uint256 amount) external view returns (uint256 receiveQuote);

    function queryBuyBaseToken(uint256 amount) external view returns (uint256 payQuote);

    function getExpectedTarget() external view returns (uint256 baseTarget, uint256 quoteTarget);

    function getLpBaseBalance(address lp) external view returns (uint256 lpBalance);

    function getLpQuoteBalance(address lp) external view returns (uint256 lpBalance);

    function depositBaseTo(address to, uint256 amount) external returns (uint256);

    function withdrawBase(uint256 amount) external returns (uint256);

    function withdrawAllBase() external returns (uint256);

    function depositQuoteTo(address to, uint256 amount) external returns (uint256);

    function withdrawQuote(uint256 amount) external returns (uint256);

    function withdrawAllQuote() external returns (uint256);

    function _BASE_CAPITAL_TOKEN_() external view returns (address);

    function _QUOTE_CAPITAL_TOKEN_() external view returns (address);

    function _BASE_TOKEN_() external returns (address);

    function _QUOTE_TOKEN_() external returns (address);

    function _LP_FEE_RATE_() external returns (uint256);

    function _MT_FEE_RATE_() external returns (uint256);

    function _BASE_BALANCE_() external returns (uint256);

    function _QUOTE_BALANCE_() external returns (uint256);

    function enableTrading() external;

    function disableTrading() external;
}









interface IERC20 {



    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

















library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c ;

        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient ;

        uint256 remainder ;

        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c ;

        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z ;

        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}























library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {




        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {










        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {


            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}














contract DODORebalancer is Ownable {

  using SafeERC20 for IERC20;

  function rebalance(address dodo) external onlyOwner {
    IDODO(dodo).enableTrading();
    (uint256 baseTarget, ) = IDODO(dodo).getExpectedTarget();
    uint256 baseBalance ;


    if (baseTarget<baseBalance) {
      uint256 amount ;

      amount = amount*1e18/(1e18+IDODO(dodo)._LP_FEE_RATE_()+IDODO(dodo)._MT_FEE_RATE_());
      uint256 expectedPay ;

      IERC20(IDODO(dodo)._QUOTE_TOKEN_()).safeApprove(dodo, expectedPay);
      IDODO(dodo).buyBaseToken(amount, expectedPay, "");
    } else {
      uint256 amount ;

      uint256 expectedReceive ;

      IERC20(IDODO(dodo)._BASE_TOKEN_()).safeApprove(dodo, amount);
      IDODO(dodo).sellBaseToken(amount, expectedReceive, "");
    }
    IDODO(dodo).disableTrading();
  }

  function retrieve(address token) external onlyOwner {
     IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
  }

  function retrieveEth(uint256 amount) external onlyOwner {
    msg.sender.transfer(amount);
  }

  function claimOwnership(address dodo) external onlyOwner{
    IDODO(dodo).claimOwnership();
  }

  function transferOwnership(address dodo, address to) external onlyOwner{
    IDODO(dodo).transferOwnership(to);
  }

}
