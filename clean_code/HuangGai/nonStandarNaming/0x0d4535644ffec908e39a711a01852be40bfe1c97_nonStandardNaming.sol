pragma solidity 0.5.4;

library SafeMath {

    function MUL461(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }


    function DIV598(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }


    function SUB329(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }


    function ADD397(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }


    function MOD359(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function TRANSFER293(address to, uint256 value) external returns (bool);

    function APPROVE575(address spender, uint256 value) external returns (bool);

    function TRANSFERFROM587(address from, address to, uint256 value) external returns (bool);

    function TOTALSUPPLY522() external view returns (uint256);

    function BALANCEOF14(address who) external view returns (uint256);

    function ALLOWANCE18(address owner, address spender) external view returns (uint256);

    event TRANSFER579(address indexed from, address indexed to, uint256 value);

    event APPROVAL491(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER191(IERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN824(token, abi.encodeWithSelector(token.TRANSFER293.selector, to, value));
    }

    function SAFETRANSFERFROM593(IERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN824(token, abi.encodeWithSelector(token.TRANSFERFROM587.selector, from, to, value));
    }

    function SAFEAPPROVE724(IERC20 token, address spender, uint256 value) internal {



        require((value == 0) || (token.ALLOWANCE18(address(this), spender) == 0));
        CALLOPTIONALRETURN824(token, abi.encodeWithSelector(token.APPROVE575.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE971(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE18(address(this), spender).ADD397(value);
        CALLOPTIONALRETURN824(token, abi.encodeWithSelector(token.APPROVE575.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE359(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE18(address(this), spender).SUB329(value);
        CALLOPTIONALRETURN824(token, abi.encodeWithSelector(token.APPROVE575.selector, spender, newAllowance));
    }


    function CALLOPTIONALRETURN824(IERC20 token, bytes memory data) private {








        require(address(token).ISCONTRACT260());


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)));
        }
    }
}

library Address {

    function ISCONTRACT260(address account) internal view returns (bool) {
        uint256 size;







        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract ReentrancyGuard {

    uint256 private _guardCounter;

    constructor () internal {


        _guardCounter = 1;
    }


    modifier NONREENTRANT815() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

contract KyberNetworkProxyInterface {
  function GETEXPECTEDRATE942(IERC20 src, IERC20 dest, uint256 srcQty) public view returns (uint256 expectedRate, uint256 slippageRate);
  function TRADE12(IERC20 src, uint256 srcAmount, IERC20 dest, address destAddress, uint256 maxDestAmount, uint256 minConversionRate, address walletId) public payable returns(uint256);
}

contract LandRegistryProxyInterface {
  function OWNER294() public view returns (address);
}

contract PaymentsLayer is ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public constant eth_token_address469 = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  KyberNetworkProxyInterface public constant kyber_network_proxy850 = KyberNetworkProxyInterface(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
  LandRegistryProxyInterface public constant land_registry_proxy977 = LandRegistryProxyInterface(0xe72AD2A335AE18e6C7cdb6dAEB64b0330883CD56);

  event PAYMENTFORWARDED234(IERC20 indexed src, uint256 srcAmount, IERC20 indexed dest, address indexed destAddress, uint256 destAmount);

  function FORWARDPAYMENT814(IERC20 src, uint256 srcAmount, IERC20 dest, address destAddress, uint256 minConversionRate, uint256 minDestAmount, bytes memory encodedFunctionCall) public NONREENTRANT815 payable returns(uint256) {
    if (address(src) != eth_token_address469) {
      require(msg.value == 0);
      src.SAFETRANSFERFROM593(msg.sender, address(this), srcAmount);
      src.SAFEAPPROVE724(address(kyber_network_proxy850), srcAmount);
    }

    uint256 destAmount = kyber_network_proxy850.TRADE12.value((address(src) == eth_token_address469) ? srcAmount : 0)(src, srcAmount, dest, address(this), ~uint256(0), minConversionRate, land_registry_proxy977.OWNER294());
    require(destAmount >= minDestAmount);
    if (address(dest) != eth_token_address469)
      dest.SAFEAPPROVE724(destAddress, destAmount);

    (bool success, ) = destAddress.call.value((address(dest) == eth_token_address469) ? destAmount : 0)(encodedFunctionCall);
    require(success, "dest call failed");

    emit PAYMENTFORWARDED234(src, srcAmount, dest, destAddress, destAmount);
    return destAmount;
  }
}
