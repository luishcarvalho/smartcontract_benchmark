


pragma solidity ^0.7.4;

import {Errors} from "../libraries/helpers/Errors.sol";
import {ACLTrait} from "./ACLTrait.sol";

import "hardhat/console.sol";



contract ContractsRegister is ACLTrait {

    address[] public pools;

    mapping(address => bool) _poolSet;



    address[] public creditManagers;
    mapping(address => bool) _creditManagersSet;


    event NewPoolAdded(address indexed pool);


    event NewCreditManagerAdded(address indexed creditManager);

    constructor(address addressProvider) ACLTrait(addressProvider) {}



    function addPool(address newPoolAddress)
        external
        configuratorOnly
    {
        require(!_poolSet[newPoolAddress], Errors.CR_POOL_ALREADY_ADDED);
        pools.push(newPoolAddress);
        _poolSet[newPoolAddress] = true;

        emit NewPoolAdded(newPoolAddress);
    }


    function getPools() external view returns (address[] memory) {
        return pools;
    }


    function getPoolsCount() external view returns (uint256) {
        return pools.length;
    }


    function isPool(address addr) external view returns (bool) {
        return _poolSet[addr];
    }



    function addCreditManager(address newCreditManager)
        external
        configuratorOnly
    {
        require(
            !_creditManagersSet[newCreditManager],
            Errors.CR_CREDIT_MANAGER_ALREADY_ADDED
        );
        creditManagers.push(newCreditManager);
        _creditManagersSet[newCreditManager] = true;

        emit NewCreditManagerAdded(newCreditManager);
    }


    function getCreditManagers() external view returns (address[] memory) {
        return creditManagers;
    }


    function getCreditManagersCount() external view returns (uint256) {
        return creditManagers.length;
    }


    function isCreditManager(address addr) external view returns (bool) {
        return _creditManagersSet[addr];
    }
}
