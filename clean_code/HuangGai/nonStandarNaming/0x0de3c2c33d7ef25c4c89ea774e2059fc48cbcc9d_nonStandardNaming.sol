





pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


interface IDODO {
    function INIT73(
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

    function TRANSFEROWNERSHIP178(address newOwner) external;

    function CLAIMOWNERSHIP473() external;

    function SELLBASETOKEN811(
        uint256 amount,
        uint256 minReceiveQuote,
        bytes calldata data
    ) external returns (uint256);

    function BUYBASETOKEN300(
        uint256 amount,
        uint256 maxPayQuote,
        bytes calldata data
    ) external returns (uint256);

    function QUERYSELLBASETOKEN495(uint256 amount) external view returns (uint256 receiveQuote);

    function QUERYBUYBASETOKEN809(uint256 amount) external view returns (uint256 payQuote);

    function GETEXPECTEDTARGET519() external view returns (uint256 baseTarget, uint256 quoteTarget);

    function GETLPBASEBALANCE207(address lp) external view returns (uint256 lpBalance);

    function GETLPQUOTEBALANCE235(address lp) external view returns (uint256 lpBalance);

    function DEPOSITBASETO916(address to, uint256 amount) external returns (uint256);

    function WITHDRAWBASE408(uint256 amount) external returns (uint256);

    function WITHDRAWALLBASE463() external returns (uint256);

    function DEPOSITQUOTETO581(address to, uint256 amount) external returns (uint256);

    function WITHDRAWQUOTE312(uint256 amount) external returns (uint256);

    function WITHDRAWALLQUOTE274() external returns (uint256);

    function _BASE_CAPITAL_TOKEN_162() external view returns (address);

    function _QUOTE_CAPITAL_TOKEN_30() external view returns (address);

    function _BASE_TOKEN_914() external returns (address);

    function _QUOTE_TOKEN_604() external returns (address);
}







interface IERC20 {

    function TOTALSUPPLY247() external view returns (uint256);

    function DECIMALS719() external view returns (uint8);

    function NAME995() external view returns (string memory);


    function BALANCEOF254(address account) external view returns (uint256);


    function TRANSFER732(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE605(address owner, address spender) external view returns (uint256);


    function APPROVE178(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM592(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}







library SafeMath {
    function MUL774(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function DIV734(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function DIVCEIL943(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = DIV734(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function SUB819(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function ADD543(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function SQRT442(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}






interface IDODOMine {
    function GETUSERLPBALANCE930(address _lpToken, address _user) external view returns (uint256);
}


contract DODOMineReader {
    using SafeMath for uint256;

    function GETUSERSTAKEDBALANCE458(
        address _dodoMine,
        address _dodo,
        address _user
    ) public view returns (uint256 baseBalance, uint256 quoteBalance) {
        address baseLpToken = IDODO(_dodo)._BASE_CAPITAL_TOKEN_162();
        address quoteLpToken = IDODO(_dodo)._QUOTE_CAPITAL_TOKEN_30();

        uint256 baseLpBalance = IDODOMine(_dodoMine).GETUSERLPBALANCE930(baseLpToken, _user);
        uint256 quoteLpBalance = IDODOMine(_dodoMine).GETUSERLPBALANCE930(quoteLpToken, _user);

        uint256 baseLpTotalSupply = IERC20(baseLpToken).TOTALSUPPLY247();
        uint256 quoteLpTotalSupply = IERC20(quoteLpToken).TOTALSUPPLY247();

        (uint256 baseTarget, uint256 quoteTarget) = IDODO(_dodo).GETEXPECTEDTARGET519();
        baseBalance = baseTarget.MUL774(baseLpBalance).DIV734(baseLpTotalSupply);
        quoteBalance = quoteTarget.MUL774(quoteLpBalance).DIV734(quoteLpTotalSupply);

        return (baseBalance, quoteBalance);
    }

    function GETUSERTOTALBALANCE93(
        address _dodoMine,
        address _dodo,
        address _user
    ) external view returns (uint256 baseBalance, uint256 quoteBalance) {
        (uint256 stakedBase, uint256 stakedQuote) = GETUSERSTAKEDBALANCE458(_dodoMine, _dodo, _user);
        baseBalance = IDODO(_dodo).GETLPBASEBALANCE207(_user).ADD543(stakedBase);
        quoteBalance = IDODO(_dodo).GETLPQUOTEBALANCE235(_user).ADD543(stakedQuote);
        return (baseBalance, quoteBalance);
    }
}
