


pragma solidity ^0.7.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {ICreditManager} from "../interfaces/ICreditManager.sol";
import {IYVault} from "../integrations/yearn/IYVault.sol";

import {CreditAccount} from "../credit/CreditAccount.sol";
import {CreditManager} from "../credit/CreditManager.sol";

import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

import "hardhat/console.sol";


contract YearnAdapter is IYVault {
    using SafeMath for uint256;

    address public yVault;
    address public override token;

    ICreditManager public creditManager;
    ICreditFilter public creditFilter;




    constructor(address _creditManager, address _yVault) {
        creditManager = ICreditManager(_creditManager);
        creditFilter = ICreditFilter(creditManager.creditFilter());

        yVault = _yVault;


        token = IYVault(yVault).token();
        creditFilter.revertIfTokenNotAllowed(token);
    }



    function deposit(uint256 amount, address)
        external
        override
        returns (uint256)
    {

        return _deposit(abi.encodeWithSelector(bytes4(0xb6b55f25), amount));
    }



    function deposit(uint256 amount) external override returns (uint256) {

        return _deposit(abi.encodeWithSelector(bytes4(0xb6b55f25), amount));
    }


    function deposit() external override returns (uint256) {

        return
            _deposit(
                abi.encodeWithSelector(bytes4(0xb6b55f25), Constants.MAX_INT)
            );
    }

    function _deposit(bytes memory data) internal returns (uint256 shares) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );


        creditManager.provideCreditAccountAllowance(
            creditAccount,
            yVault,
            token
        );

        uint256 balanceBefore = ERC20(token).balanceOf(creditAccount);

        shares = abi.decode(
            creditManager.executeOrder(msg.sender, yVault, data),
            (uint256)
        );

        creditFilter.checkCollateralChange(
            creditAccount,
            token,
            yVault,
            balanceBefore.sub(ERC20(token).balanceOf(creditAccount)),
            shares
        );
    }

    function withdraw() external override returns (uint256) {
        return withdraw(Constants.MAX_INT, address(0), 1);
    }

    function withdraw(uint256 maxShares) external override returns (uint256) {
        return withdraw(maxShares, address(0), 1);
    }

    function withdraw(uint256 maxShares, address recipient)
        external
        override
        returns (uint256)
    {
        return withdraw(maxShares, recipient, 1);
    }







    function withdraw(
        uint256 maxShares,
        address,
        uint256 maxLoss
    ) public override returns (uint256 shares) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );



        creditManager.provideCreditAccountAllowance(
            creditAccount,
            yVault,
            token
        );

        bytes memory data = abi.encodeWithSelector(
            bytes4(0x2e1a7d4d),
            maxShares,
            creditAccount,
            maxLoss
        );

        uint256 balance = ERC20(token).balanceOf(creditAccount);

        shares = abi.decode(
            creditManager.executeOrder(msg.sender, yVault, data),
            (uint256)
        );

        creditFilter.checkCollateralChange(
            creditAccount,
            yVault,
            token,
            shares,
            ERC20(token).balanceOf(creditAccount).sub(balance)
        );
    }

    function pricePerShare() external view override returns (uint256) {
        return IYVault(yVault).pricePerShare();
    }

    function name() external view override returns (string memory) {
        return IYVault(yVault).name();
    }

    function symbol() external view override returns (string memory) {
        return IYVault(yVault).symbol();
    }

    function decimals() external view override returns (uint256) {
        return IYVault(yVault).decimals();
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return IYVault(yVault).allowance(owner, spender);
    }

    function approve(address, uint256) external pure override returns (bool) {
        return true;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return IYVault(yVault).balanceOf(account);
    }

    function totalSupply() external view override returns (uint256) {
        return IYVault(yVault).totalSupply();
    }

    function transfer(address, uint256) external pure override returns (bool) {
        revert(Errors.NOT_IMPLEMENTED);
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure override returns (bool) {
        revert(Errors.NOT_IMPLEMENTED);
    }
}
