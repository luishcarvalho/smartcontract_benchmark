
pragma solidity ^0.7.6;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAddressResolver } from "synthetix/contracts/interfaces/IAddressResolver.sol";
import { ISynthetix } from "synthetix/contracts/interfaces/ISynthetix.sol";
import { ISNXFlashLoanTool } from "./interfaces/ISNXFlashLoanTool.sol";
import { IFlashLoanReceiver } from "./interfaces/IFlashLoanReceiver.sol";
import { ILendingPoolAddressesProvider } from "./interfaces/ILendingPoolAddressesProvider.sol";
import { ILendingPool } from "./interfaces/ILendingPool.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";



contract SNXFlashLoanTool is ISNXFlashLoanTool, IFlashLoanReceiver, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    ISynthetix public immutable synthetix;

    IERC20 public immutable snx;

    IERC20 public immutable sUSD;

    ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;

    ILendingPool public immutable override LENDING_POOL;

    uint16 public constant referralCode = 185;




    constructor(address _snxResolver, address _provider) {
        IAddressResolver synthetixResolver = IAddressResolver(_snxResolver);
        synthetix = ISynthetix(synthetixResolver.getAddress("Synthetix"));
        snx = IERC20(synthetixResolver.getAddress("ProxyERC20"));
        sUSD = IERC20(synthetixResolver.getAddress("ProxyERC20sUSD"));
        ILendingPoolAddressesProvider provider = ILendingPoolAddressesProvider(_provider);
        ADDRESSES_PROVIDER = provider;
        LENDING_POOL = ILendingPool(provider.getLendingPool());
    }








    function burn(
        uint256 sUSDAmount,
        uint256 snxAmount,
        address exchange,
        bytes calldata exchangeData
    ) external override {
        address[] memory assets = new address[](1);
        assets[0] = address(sUSD);
        uint256[] memory amounts = new uint256[](1);

        amounts[0] = sUSDAmount == type(uint256).max ? synthetix.debtBalanceOf(msg.sender, "sUSD") : sUSDAmount;
        uint256[] memory modes = new uint256[](1);

        modes[0] = 0;

        LENDING_POOL.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            abi.encode(snxAmount, msg.sender, exchange, exchangeData),
            referralCode
        );
        emit Burn(msg.sender, amounts[0], snxAmount);
    }







    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(LENDING_POOL), "SNXFlashLoanTool: Invalid msg.sender");
        require(initiator == address(this), "SNXFlashLoanTool: Invalid initiator");
        (uint256 snxAmount, address user, address exchange, bytes memory exchangeData) = abi.decode(
            params,
            (uint256, address, address, bytes)
        );

        sUSD.transfer(user, amounts[0]);

        synthetix.burnSynthsOnBehalf(user, amounts[0]);

        snx.safeTransferFrom(user, address(this), snxAmount);

        uint256 receivedSUSD = swap(snxAmount, exchange, exchangeData);

        uint256 amountOwing = amounts[0].add(premiums[0]);
        sUSD.safeApprove(msg.sender, amountOwing);

        if (amountOwing < receivedSUSD) {
            sUSD.safeTransfer(user, receivedSUSD.sub(amountOwing));
        }
        return true;
    }





    function transferToken(address token) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }






    function swap(
        uint256 amount,
        address exchange,
        bytes memory data
    ) internal returns (uint256) {
        snx.safeApprove(exchange, amount);

        require(
            exchange != address(LENDING_POOL) && exchange != address(synthetix) && exchange != address(snx),
            "SNXFlashLoanTool: Unauthorized address"
        );

        (bool success, ) = exchange.call(data);
        require(success, "SNXFlashLoanTool: Swap failed");
        return sUSD.balanceOf(address(this));
    }
}
