
pragma solidity ^0.8.0;

import "./modules/kap20/interfaces/IKAP20.sol";
import "./modules/kap20/interfaces/IKToken.sol";
import "./modules/erc20/interfaces/IEIP20NonStandard.sol";
import "./interfaces/IInterestRateModel.sol";
import "./interfaces/ILKAP20.sol";
import "./abstracts/LendingContract.sol";

contract KAP20Lending is LendingContract {
    constructor(
        address underlyingToken_,
        address controller_,
        address interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory lTokenName_,
        string memory lTokenSymbol_,
        uint8 lTokenDecimals_,
        address committee_,
        address adminRouter_,
        address kyc_,
        uint256 acceptedKycLevel_
    )
        LendingContract(
            controller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            lTokenName_,
            lTokenSymbol_,
            lTokenDecimals_,
            committee_,
            adminRouter_,
            kyc_,
            acceptedKycLevel_
        )
    {

        underlyingToken = underlyingToken_;
        IKAP20(underlyingToken).totalSupply();
    }



























































































































































    function doTransferIn(
        address from,
        uint256 amount,
        TransferMethod method
    ) internal override returns (uint256) {
        if (method == TransferMethod.BK_NEXT) {
            return doTransferInBKNext(from, amount);
        } else {
            return doTransferInMetamask(from, amount);
        }
    }

    function doTransferInBKNext(address from, uint256 amount)
        private
        returns (uint256)
    {
        IKAP20 token = IKAP20(underlyingToken);
        uint256 balanceBefore = token.balanceOf(address(this));
        IKToken(underlyingToken).externalTransfer(from, address(this), amount);

        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Transfer in overflow");
        return balanceAfter - balanceBefore;
    }

    function doTransferInMetamask(address from, uint256 amount)
        private
        returns (uint256)
    {
        IEIP20NonStandard token = IEIP20NonStandard(underlyingToken);
        uint256 balanceBefore = IKAP20(underlyingToken).balanceOf(
            address(this)
        );

        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {

                success := not(0)
            }
            case 32 {

                returndatacopy(0, 0, 32)
                success := mload(0)
            }
            default {

                revert(0, 0)
            }
        }
        require(success, "Transfer in failed");


        uint256 balanceAfter = IKAP20(underlyingToken).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Transfer in overflow");
        return balanceAfter - balanceBefore;
    }





    function doTransferOut(address payable to, uint256 amount, TransferMethod method)
        internal
        override
    {
        method;

        IEIP20NonStandard token = IEIP20NonStandard(underlyingToken);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {

                success := not(0)
            }
            case 32 {

                returndatacopy(0, 0, 32)
                success := mload(0)
            }
            default {

                revert(0, 0)
            }
        }

        require(success, "Transfer out failed");
    }
}
