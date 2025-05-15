

pragma solidity ^0.6.10;

import "./EndaomentAdmin.sol";






contract Administratable {




    modifier onlyAdmin(address adminContractAddress) {
        EndaomentAdmin endaomentAdmin = EndaomentAdmin(adminContractAddress);

        require(msg.sender == endaomentAdmin.getRoleAddress(IEndaomentAdmin.Role.ADMIN), "Only ADMIN can access.");
        _;
    }







    modifier onlyAdminOrRole(address adminContractAddress, IEndaomentAdmin.Role role) {
        EndaomentAdmin endaomentAdmin = EndaomentAdmin(adminContractAddress);

        if (msg.sender != endaomentAdmin.getRoleAddress(IEndaomentAdmin.Role.ADMIN)) {
            if (!endaomentAdmin.isPaused(role)) {
                    if (role == IEndaomentAdmin.Role.ACCOUNTANT) {
                        require(msg.sender == endaomentAdmin.getRoleAddress(IEndaomentAdmin.Role.ACCOUNTANT), "Only ACCOUNTANT can access");
                    }
                    if (role == IEndaomentAdmin.Role.REVIEWER) {
                        require(msg.sender == endaomentAdmin.getRoleAddress(IEndaomentAdmin.Role.REVIEWER), "Only REVIEWER can access");
                    }
                    if (role == IEndaomentAdmin.Role.FUND_FACTORY) {
                        require(msg.sender == endaomentAdmin.getRoleAddress(IEndaomentAdmin.Role.FUND_FACTORY), "Only FUND_FACTORY can access");
                    }
                    if (role == IEndaomentAdmin.Role.ORG_FACTORY) {
                        require(msg.sender == endaomentAdmin.getRoleAddress(IEndaomentAdmin.Role.ORG_FACTORY), "Only ORG_FACTORY can access");
                    }
            } else {
                require(msg.sender == endaomentAdmin.getRoleAddress(IEndaomentAdmin.Role.ADMIN), "Only ADMIN can access");

            }
        } else {
            require(msg.sender == endaomentAdmin.getRoleAddress(IEndaomentAdmin.Role.ADMIN), "Only ADMIN can access");
        }
    _;
    }
}
