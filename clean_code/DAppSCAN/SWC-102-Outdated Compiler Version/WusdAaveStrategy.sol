

pragma solidity 0.8.9;











abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}













abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor() {
        _setOwner(_msgSender());
    }




    function owner() public view virtual returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}




interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}




library Address {

















    function isContract(address account) internal view returns (bool) {




        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }







    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }







    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }







    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }







    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {


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
    using Address for address;

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ILendingPool {
  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

interface IAaveIncentivesController {
    function getRewardsBalance(address[] memory assets, address user) external view returns (uint256);
    function claimRewards(address[] memory assets, uint256 amount, address to) external;
}

interface IWUSDMaster {
    function treasury() external view returns (address);
}

contract WusdAaveStrategy is Ownable {
    using SafeERC20 for IERC20;


    IERC20 public immutable usdc = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    IERC20 public immutable wmatic = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    IERC20 public immutable amUsdc = IERC20(0x1a13F4Ca1d028320A707D99520AbFefca3998b7F);
    ILendingPool public immutable lendingPool = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);
    IAaveIncentivesController public immutable rewardsContract = IAaveIncentivesController(0x357D51124f59836DeD84c8a1730D72B749d8BC23);
    IWUSDMaster public immutable wusdMaster = IWUSDMaster(0xc9fF58Bd2A1CB4FAB0fEC5A0D061527Db1fbb923);

    uint256 public usdcInvestedAmount = 0;

    event UsdcInvested(uint256 amount);
    event UsdcWithdrawnToTreasury(uint256 amount);
    event UsdcWithdrawnToMaster(uint256 amount);


    function treasury() public view returns (address) {
        return wusdMaster.treasury();
    }

    function wmaticRewardsAmount() external view returns (uint256) {
        address[] memory assets = new address[](1);
        assets[0] = address(amUsdc);
        return rewardsContract.getRewardsBalance(assets, address(this));
    }

    function expectedTotalUsdcAmount() external view returns (uint256) {
        return amUsdc.balanceOf(address(this));
    }

    function expectedUsdcRewards() external view returns (uint256) {
        return amUsdc.balanceOf(address(this)) - usdcInvestedAmount;
    }

    function investAll() external {
        uint256 usdcBalance = usdc.balanceOf(address(this));
        invest(usdcBalance);
    }

    function invest(uint256 usdcAmount) public onlyOwner {
        uint256 usdcBalance = usdc.balanceOf(address(this));
        require(usdcBalance >= usdcAmount, 'not enough USDC in strategy');

        usdc.approve(address(lendingPool), usdcAmount);
        lendingPool.deposit(address(usdc), usdcAmount, address(this), 0);
        usdcInvestedAmount += usdcAmount;

        emit UsdcInvested(usdcAmount);
    }

    function withdraw(address to, uint256 amUsdcAmount) internal returns (uint256) {
        return lendingPool.withdraw(address(usdc), amUsdcAmount, to);
    }

    function withdrawToMaster(uint256 amUsdcAmount) external onlyOwner {
        uint256 amUsdcBalance = amUsdc.balanceOf(address(this));
        require(amUsdcAmount <= amUsdcBalance, 'not enough amUSDC');
        require(amUsdcAmount <= usdcInvestedAmount, 'withdrawing more than invested');

        uint256 usdcWithdrawn = withdraw(address(wusdMaster), amUsdcAmount);
        usdcInvestedAmount -= usdcWithdrawn;

        emit UsdcWithdrawnToTreasury(usdcWithdrawn);
    }

    function withdrawUsdcRewards(uint256 amUsdcAmount) external onlyOwner {
        uint256 amUsdcBalance = amUsdc.balanceOf(address(this));
        require(amUsdcAmount <= amUsdcBalance, 'not enough amUSDC');
        require(amUsdcBalance - amUsdcAmount >= usdcInvestedAmount, 'withdrawing more than rewards');

        uint256 usdcWithdrawn = withdraw(treasury(), amUsdcAmount);

        emit UsdcWithdrawnToTreasury(usdcWithdrawn);
    }

    function claimWMaticRewards(uint256 wmaticAmount) external onlyOwner {
        address[] memory assets = new address[](1);
        assets[0] = address(amUsdc);
        rewardsContract.claimRewards(assets, wmaticAmount, address(this));
        uint256 wmaticBalance = wmatic.balanceOf(address(this));
        wmatic.safeTransfer(treasury(), wmaticBalance);
    }

    function withdrawAll() external onlyOwner {
        uint256 amUsdcBalance = amUsdc.balanceOf(address(this));
        uint256 usdcWithdrawn = lendingPool.withdraw(address(usdc), amUsdcBalance, address(this));
        if(usdcWithdrawn > usdcInvestedAmount) {
            usdc.safeTransfer(treasury(), usdcWithdrawn - usdcInvestedAmount);
            usdc.safeTransfer(address(wusdMaster), usdcInvestedAmount);

            emit UsdcWithdrawnToTreasury(usdcWithdrawn - usdcInvestedAmount);
            emit UsdcWithdrawnToMaster(usdcInvestedAmount);
        } else {
            usdc.safeTransfer(address(wusdMaster), usdcWithdrawn);

            emit UsdcWithdrawnToMaster(usdcWithdrawn);
        }
        usdcInvestedAmount = 0;
    }

    function returnUsdcToMaster() external onlyOwner {
        uint256 amount = usdc.balanceOf(address(this));
        usdc.safeTransfer(address(wusdMaster), amount);

        emit UsdcWithdrawnToMaster(amount);
    }

}
