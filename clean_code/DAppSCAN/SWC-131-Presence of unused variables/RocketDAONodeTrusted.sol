pragma solidity 0.7.6;



import "../../RocketBase.sol";
import "../../../interface/RocketVaultInterface.sol";
import "../../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../../interface/dao/node/settings/RocketDAONodeTrustedSettingsMembersInterface.sol";
import "../../../interface/dao/RocketDAOProposalInterface.sol";
import "../../../interface/util/AddressSetStorageInterface.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";



contract RocketDAONodeTrusted is RocketBase, RocketDAONodeTrustedInterface {

    using SafeMath for uint;


    event MemberJoined(address indexed _nodeAddress, uint256 _rplBondAmount, uint256 time);
    event MemberLeave(address indexed _nodeAddress, uint256 _rplBondAmount, uint256 time);


    uint256 private calcBase = 1 ether;


    string private daoNameSpace = 'dao.trustednodes';


    uint256 private daoMemberMinCount = 3;



    modifier onlyBootstrapMode() {
        require(getBootstrapModeDisabled() == false, "Bootstrap mode not engaged");
        _;
    }


    modifier onlyLowMemberMode() {
        require(getMemberCount() < daoMemberMinCount, "Low member mode not engaged");
        _;
    }



    constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) {

        version = 1;
    }






































































































































































