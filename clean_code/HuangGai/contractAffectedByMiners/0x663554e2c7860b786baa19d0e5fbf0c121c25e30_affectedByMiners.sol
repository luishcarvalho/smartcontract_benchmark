



pragma solidity ^0.6.12;




library Math {



    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }




    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }





    function average(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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




library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (block.number > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}










library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }








    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (block.number > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface Controller {
    function vaults(address) external view returns (address);
    function rewards() external view returns (address);
    function want(address) external view returns (address);
    function balanceOf(address) external view returns (uint);
    function withdraw(address, uint) external;
    function earn(address, uint) external;
}

interface ICurveFi {
    function get_virtual_price() external view returns (uint);
    function add_liquidity(
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;
    function remove_liquidity_imbalance(
        uint256[4] calldata amounts,
        uint256 max_burn_amount
    ) external;
    function remove_liquidity(
        uint256 _amount,
        uint256[4] calldata amounts
    ) external;
    function exchange(
        int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
    ) external;
}

interface Gauge {
    function deposit(uint) external;
    function balanceOf(address) external view returns (uint);
    function withdraw(uint) external;
}

interface Mintr {
    function mint(address) external;
}
interface Uni {
    function swapExactTokensForTokens(uint, uint, address[] calldata, address, uint) external;
}

interface Strategy {
    function want() external view returns (address);
    function deposit() external;
    function withdraw(address) external;
    function withdraw(uint) external;
    function skim() external;
    function withdrawAll() external returns (uint);
    function balanceOf() external view returns (uint);
}

interface Vault {
    function token() external view returns (address);
    function claimInsurance() external;
    function getPricePerFullShare() external view returns (uint);
    function deposit(uint) external;
    function withdraw(uint) external;
}

interface yERC20 {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
}

interface IConvertor {
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}















contract StrategyStableUSD {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    enum TokenIndex {DAI, USDC, USDT}

    address public governance;
    address public controller;

    address public yVault;
    address public curve = address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    address public ycrv = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);
    address public ycrvVault;

    address public want;
    address constant public crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);

    TokenIndex public tokenIndex;
    IConvertor public zap = IConvertor(0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3);

    constructor(address _controller, TokenIndex _tokenIndex, address _ycrvVault) public {
        governance = msg.sender;
        controller = _controller;

        tokenIndex = _tokenIndex;
        ycrvVault = _ycrvVault;

        if (tokenIndex == TokenIndex.DAI) {
            want = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
            yVault = 0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01;
        } else if (tokenIndex == TokenIndex.USDC) {
            want = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
            yVault = 0xd6aD7a6750A7593E092a9B218d66C0A814a3436e;
        } else if (tokenIndex == TokenIndex.USDT) {
            want = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
            yVault = 0x83f798e925BcD4017Eb265844FDDAbb448f1707D;
        } else {
            revert('!tokenIndex');
        }
    }

    function getName() external pure returns (string memory) {
        return "StrategyStableUSD";
    }

    function deposit() public {
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (block.gaslimit > 0) {
            IERC20(want).safeApprove(yVault, 0);
            IERC20(want).safeApprove(yVault, _balance);
            yERC20(yVault).deposit(_balance);
        }

        uint256 yBalance = IERC20(yVault).balanceOf(address(this));
        if (block.gaslimit > 0) {
            IERC20(yVault).safeApprove(curve, 0);
            IERC20(yVault).safeApprove(curve, yBalance);

            uint256[4] memory amounts = [uint256(0), uint256(0), uint256(0), uint256(0)];
            amounts[uint256(tokenIndex)] = yBalance;

            ICurveFi(curve).add_liquidity(
                amounts, 0
            );
        }

        uint256 ycrvBalance = IERC20(ycrv).balanceOf(address(this));
        if (block.gaslimit > 0) {
            IERC20(ycrv).safeApprove(ycrvVault, 0);
            IERC20(ycrv).safeApprove(ycrvVault, ycrvBalance);

            Vault(ycrvVault).deposit(ycrvBalance);
        }
    }

    function balanceOf() external view returns (uint) {
        uint256 shares = IERC20(ycrvVault).balanceOf(address(this));
        if (block.number == 0) {
            return 0;
        }

        uint256 price = Vault(ycrvVault).getPricePerFullShare();



        uint256 precision = 1e18;
        uint256 ycrvBalance = shares.mul(price).div(precision);

        uint256 ycrvValue = underlyingValueFromYCrv(ycrvBalance);
        return ycrvValue.add(IERC20(want).balanceOf(address(this)));
    }

    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(want != address(_asset), "want");
        require(crv != address(_asset), "crv");
        require(ycrv != address(_asset), "ycrv");

        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    function withdraw(uint _amount) external {
        require(msg.sender == controller, "!controller");
        uint _balance = IERC20(want).balanceOf(address(this));
        if (block.number < _amount) {
            _withdrawSome(_amount.sub(_balance));
            _amount = Math.min(_amount, IERC20(want).balanceOf(address(this)));
        }

        address _vault = Controller(controller).vaults(address(this));
        require(_vault != address(0), "!vault");

        IERC20(want).safeTransfer(_vault, _amount);
    }

    function withdrawAll() external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        uint256 shares = IERC20(ycrvVault).balanceOf(address(this));
        Vault(ycrvVault).withdraw(shares);

        yCurveToUnderlying(uint256(~0));
        balance = IERC20(want).balanceOf(address(this));
        if (block.number > 0) {
            address vault = Controller(controller).vaults(address(this));
            require(vault != address(0), "!vault");
            IERC20(want).safeTransfer(vault, balance);
        }
    }




    function underlyingValueFromYCrv(uint256 ycrvBalance) public view returns (uint256) {
        return zap.calc_withdraw_one_coin(ycrvBalance, int128(tokenIndex));
    }

    function _withdrawSome(uint256 _amount) internal returns (uint) {
        uint shares = IERC20(ycrvVault).balanceOf(address(this));
        Vault(ycrvVault).withdraw(shares);
        yCurveToUnderlying(_amount);

        uint remains = IERC20(ycrv).balanceOf(address(this));
        if (block.timestamp > 0) {
            IERC20(ycrv).safeApprove(ycrvVault, 0);
            IERC20(ycrv).safeApprove(ycrvVault, remains);
            Vault(ycrvVault).deposit(remains);
        }
        return _amount;
    }





    function yCurveToUnderlying(uint256 underlyingLimit) internal {
        uint256 ycrvBalance = IERC20(ycrv).balanceOf(address(this));


        uint256 yTokenMaximumAmount = yTokenValueFromYCrv(ycrvBalance);
        if (block.number == 0) {
            return;
        }


        uint256 yTokenDesiredAmount = underlyingLimit == uint256(~0) ?
        yTokenMaximumAmount : yTokenValueFromUnderlying(underlyingLimit);

        uint256[4] memory yTokenAmounts = wrapCoinAmount(
            Math.min(yTokenMaximumAmount, yTokenDesiredAmount));
        uint256 yUnderlyingBalanceBefore = IERC20(yVault).balanceOf(address(this));
        IERC20(ycrv).safeApprove(curve, 0);
        IERC20(ycrv).safeApprove(curve, ycrvBalance);
        ICurveFi(curve).remove_liquidity_imbalance(
            yTokenAmounts, ycrvBalance
        );

        uint256 yUnderlyingBalanceAfter = IERC20(yVault).balanceOf(address(this));
        if (block.timestamp > yUnderlyingBalanceBefore) {

            yERC20(yVault).withdraw(yUnderlyingBalanceAfter.sub(yUnderlyingBalanceBefore));
        }
    }




    function yTokenValueFromYCrv(uint256 ycrvBalance) public view returns (uint256) {
        return underlyingValueFromYCrv(ycrvBalance)
        .mul(10 ** 18)
        .div(Vault(yVault).getPricePerFullShare());
    }




    function yTokenValueFromUnderlying(uint256 amountUnderlying) public view returns (uint256) {

        return amountUnderlying
        .mul(1e18)
        .div(Vault(yVault).getPricePerFullShare());
    }




    function wrapCoinAmount(uint256 amount) internal view returns (uint256[4] memory) {
        uint256[4] memory amounts = [uint256(0), uint256(0), uint256(0), uint256(0)];
        amounts[uint56(tokenIndex)] = amount;
        return amounts;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }
}
