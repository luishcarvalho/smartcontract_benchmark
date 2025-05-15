

pragma solidity ^0.6.10;

import "./Administratable.sol";
import "./OrgFactory.sol";












contract Fund is Administratable {
    using SafeMath for uint256;


    struct Grant {
        string description;
        uint value;
        address recipient;
        bool complete;
    }

    address public manager;
    address public admin;
    mapping(address => bool) public contributors;
    Grant[] public grants;
    uint public totalContributors;







    constructor (address creator, address adminContractAddress) public onlyAdminOrRole(adminContractAddress, IEndaomentAdmin.Role.FUND_FACTORY){
        require(creator != address(0));
        manager = creator;
    }





    modifier restricted() {
      require(msg.sender == manager);
      _;
    }







    function changeManager (address newManager, address adminContractAddress) public onlyAdminOrRole(adminContractAddress, IEndaomentAdmin.Role.REVIEWER){
        manager = newManager;
    }






    function checkRecipient(address recipient, address orgFactoryContractAddress) public view returns (bool) {
        OrgFactory x = OrgFactory ( orgFactoryContractAddress );

        return x.getAllowedOrg(recipient);
    }





    function getSummary(address tokenAddress) public view returns (uint, uint, uint, address) {
        ERC20 t = ERC20(tokenAddress);
        uint bal = t.balanceOf(address(this));

        return (
            bal,
            address(this).balance,
            grants.length,
            manager
        );
    }








    function createGrant(string memory description, uint256 value, address recipient, address orgFactoryContractAddress) public restricted {
        require(checkRecipient(recipient, orgFactoryContractAddress) == true);

        Grant memory newGrant = Grant({
            description: description,
            value: value,
            recipient: recipient,
            complete: false
        });

        grants.push(newGrant);
    }







    function finalizeGrant(uint index, address tokenAddress, address adminContractAddress) public onlyAdminOrRole(adminContractAddress, IEndaomentAdmin.Role.ACCOUNTANT){
        EndaomentAdmin endaomentAdmin = EndaomentAdmin(adminContractAddress);
        admin = endaomentAdmin.getRoleAddress(IEndaomentAdmin.Role.ADMIN);
        Grant storage grant = grants[index];
        require(grant.complete == false);
        ERC20 t = ERC20(tokenAddress);


        uint256 fee = (grant.value)/100;
        uint256 finalGrant = (grant.value * 99)/100;
        t.transfer(admin, fee);

        t.transfer(grant.recipient, finalGrant);

        grant.complete = true;
    }




    function getGrantsCount() public view returns (uint) {
        return grants.length;
    }
}
