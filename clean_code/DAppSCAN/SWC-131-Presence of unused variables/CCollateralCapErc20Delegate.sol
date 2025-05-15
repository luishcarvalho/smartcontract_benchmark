pragma solidity ^0.5.16;

import "./CCollateralCapErc20.sol";






contract CCollateralCapErc20Delegate is CCollateralCapErc20 {



    constructor() public {}





    function _becomeImplementation(bytes memory data) public {


        data;



        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _becomeImplementation");


        internalCash = getCashOnChain();


        ComptrollerInterfaceExtension(address(comptroller)).updateCTokenVersion(address(this), ComptrollerV2Storage.Version.COLLATERALCAP);
    }




    function _resignImplementation() public {

        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _resignImplementation");
    }
}
