

pragma solidity ^0.6.10;

import "./Administratable.sol";
import "./OrgFactory.sol";
import "./Fund.sol";










contract FundFactory is Administratable {

    Fund[] public createdFunds;
    event fundCreated(address indexed newAddress);






    constructor(address adminContractAddress) public onlyAdmin(adminContractAddress) {}







    function createFund(address managerAddress, address adminContractAddress) public onlyAdminOrRole(adminContractAddress, IEndaomentAdmin.Role.ACCOUNTANT) {
        Fund newFund = new Fund(managerAddress, adminContractAddress);
        createdFunds.push(newFund);
        emit fundCreated(address(newFund));
    }




    function countFunds() public view returns (uint) {
        return createdFunds.length;
    }





    function getFund(uint index) public view returns (address) {
        return address(createdFunds[index]);
    }

}



