




pragma solidity ^0.6.12;















library SafeMath {








    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add: +");

        return c;
    }









    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }









    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "sub: -");
    }









    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }









    function mul(uint a, uint b) internal pure returns (uint) {



        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "mul: *");

        return c;
    }









    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {



        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }












    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "div: /");
    }












    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {

        require(b > 0, errorMessage);
        uint c = a / b;


        return c;
    }












    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "mod: %");
    }












    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
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




library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }







    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }



















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient");


        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: reverted");
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

    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: < 0");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function callOptionalReturn(IERC20 token, bytes memory data) private {








        require(address(token).isContract(), "SafeERC20: !contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: !succeed");
        }
    }
}

interface IKeep3rV1 {
    function isKeeper(address) external returns (bool);
    function worked(address keeper) external;
}


interface ICERC20 {
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function underlying() external view returns (address);
    function symbol() external view returns (string memory);
}

interface ICEther {
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
    function borrowBalanceStored(address account) external view returns (uint);
}

interface IComptroller {
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    function closeFactorMantissa() external view returns (uint);
}


contract CreamLiquidate {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IComptroller constant public Comptroller = IComptroller(0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258);

    modifier upkeep() {
        require(KP3R.isKeeper(msg.sender), "::isKeeper: keeper is not registered");
        _;
        KP3R.worked(msg.sender);
    }

    IKeep3rV1 public constant KP3R = IKeep3rV1(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);

    function liquidate(address borrower, uint256 _repayAmount, address cTokenBorrow, address cTokenCollateral) external upkeep {
        (,,uint256 shortFall) = Comptroller.getAccountLiquidity(borrower);
        require(shortFall > 0, "!shortFall");

        uint256 repayAmount;
        uint256 liquidatableAmount = ICERC20(cTokenBorrow).borrowBalanceStored(borrower);
        liquidatableAmount = liquidatableAmount.mul(Comptroller.closeFactorMantissa()).div(1e18);
        if(_repayAmount == uint256(-1)) {
            repayAmount = liquidatableAmount;
        } else {
            repayAmount = _repayAmount;
        }
        require(repayAmount <= liquidatableAmount, ">liquidatableAmount");

        address underlying = ICERC20(cTokenBorrow).underlying();
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), repayAmount);
        IERC20(underlying).safeIncreaseAllowance(cTokenBorrow, repayAmount);
        uint256 err = ICERC20(cTokenBorrow).liquidateBorrow(borrower, repayAmount, cTokenCollateral);
        require(address(this).balance == 0, "failed");
        uint256 liquidatedAmount = IERC20(cTokenCollateral).balanceOf(address(this));
        require(liquidatedAmount > 0, "failed");

        IERC20(cTokenCollateral).safeTransfer(msg.sender, IERC20(cTokenCollateral).balanceOf(address(this)));
    }

    function liquidateETH(address borrower, address payable cTokenBorrow, address cTokenCollateral) external payable upkeep {
        (,,uint256 shortFall) = Comptroller.getAccountLiquidity(borrower);
        require(shortFall > 0, "!shortFall");

        uint256 liquidatableAmount = ICEther(cTokenBorrow).borrowBalanceStored(borrower);
        require(msg.value <= liquidatableAmount, ">liquidatableAmount");

        (bool success,) = cTokenBorrow.call{value: msg.value}(
            abi.encodeWithSignature("liquidateBorrow(address, address)", borrower, cTokenCollateral)
        );
        require(success, "failed");
        uint256 liquidatedAmount = IERC20(cTokenCollateral).balanceOf(address(this));
        require(liquidatedAmount > 0, "failed");

        IERC20(cTokenCollateral).safeTransfer(msg.sender, IERC20(cTokenCollateral).balanceOf(address(this)));
    }
}
