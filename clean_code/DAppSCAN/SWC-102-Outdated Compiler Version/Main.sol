
pragma solidity ^0.4.21;

import "Voting.sol";
import "CoalichainToken.sol";
import "Types.sol";

contract Main{
    using SafeMath for uint256;

    mapping (uint256 => uint256) public prices;
    address private owner = msg.sender;
    address private ZuzOwner;
    address[] private ballotAddresses;

    CoalichainToken private ZuzToken;
    bool public chargeZuz = true;

	uint256 balloutId = 0;

   event balloutCreated(address balloutAddress, uint256 correlationId);
     event Log(string message, address from, address to, uint256 value);

    modifier onlyOwner(address sender) {
        require(sender == owner);
        _;
    }

    modifier onlyKnownContract(address sender) {
        assert(isKnownContract(sender));
        _;
    }


    constructor(address ZuzAddress) public {
        ZuzToken = CoalichainToken(ZuzAddress);
        ZuzOwner = ZuzToken.adminAddr();
        prices[uint(Types.Service.CREATE_BALLOT)] = 5000000;

    }

    function changeOwner(address newOwner) public onlyOwner(msg.sender) {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function createBallot(address[] candidates, uint256 correlationId) public returns (bool){

        Voting bl = new Voting(msg.sender, candidates, owner, correlationId);

        ballotAddresses.push(bl);

		emit balloutCreated(bl, correlationId);

		    bool isSuccessful = ZuzToken.transferFrom(
            msg.sender,
           owner,
            prices[uint(Types.Service.CREATE_BALLOT)]
        );

        require(isSuccessful == true);

		return true;
    }



    function payForService(address voterAddress, uint256 amount)
        external
        onlyKnownContract(msg.sender) {

        bool isSuccessful = ZuzToken.transferFrom(
            voterAddress,
            owner,
            amount
        );

       require(isSuccessful == true);
    }





    function updateBallotPrice(uint256 newPrice) public onlyOwner(msg.sender) {
        prices[uint(Types.Service.CREATE_BALLOT)] = newPrice;
    }





    function getBallotsAddresses() view public returns (address[]) {
        return ballotAddresses;
    }




    function isKnownContract(address contractAddress) view public returns (bool){
        for (uint i = 0; i < ballotAddresses.length; i++){
            if (ballotAddresses[i] == contractAddress){
                return true;
            }
        }

        return false;
  }


}
