

pragma solidity ^0.5.16;


library SafeMath {

    function MUL808(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }


    function DIV72(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }


    function SUB229(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }


    function ADD121(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }


    function MOD464(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract Ownable {
    address private _owner;

    event OWNERSHIPTRANSFERRED920(address previousOwner, address newOwner);


    constructor () internal {
        _owner = msg.sender;
        emit OWNERSHIPTRANSFERRED920(address(0), _owner);
    }


    function OWNER455() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER459() {
        require(ISOWNER595());
        _;
    }


    function ISOWNER595() public view returns (bool) {
        return msg.sender == _owner;
    }


    function RENOUNCEOWNERSHIP898() public ONLYOWNER459 {
        emit OWNERSHIPTRANSFERRED920(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP989(address newOwner) public ONLYOWNER459 {
        _TRANSFEROWNERSHIP338(newOwner);
    }


    function _TRANSFEROWNERSHIP338(address newOwner) internal {
        require(newOwner != address(0));
        emit OWNERSHIPTRANSFERRED920(_owner, newOwner);
        _owner = newOwner;
    }
}

contract AutoRedDotDistrict is Ownable {

    using SafeMath for uint256;















    uint256 public auctionCreationReward = 10000000000000000;



    mapping (uint256 => bool) public kittyIsWhitelisted;
    uint256 public numberOfWhitelistedKitties;



    mapping (uint256 => uint256) public startingSiringPriceForKitty;
    uint256 public globalEndingSiringPrice = 0;
    uint256 public globalAuctionDuration = 1296000;









    address public kittyCoreAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    address public kittySiresAddress = 0xC7af99Fe5513eB6710e6D5f44F9989dA40F27F26;











    function CREATEAUCTION906(uint256 _kittyId) external {
        require(kittyIsWhitelisted[_kittyId] == true, 'kitty is not whitelisted');

        KittyCore(kittyCoreAddress).CREATESIRINGAUCTION26(
            _kittyId,
            startingSiringPriceForKitty[_kittyId],
            globalEndingSiringPrice,
            globalAuctionDuration
        );

        uint256 contractBalance = address(this).balance;
        if(contractBalance >= auctionCreationReward){
            msg.sender.transfer(auctionCreationReward);
        }
    }

    function OWNERCHANGESTARTINGSIRINGPRICE514(uint256 _kittyId, uint256 _newStartingSiringPrice) external ONLYOWNER459 {
        startingSiringPriceForKitty[_kittyId] = _newStartingSiringPrice;
    }

    function OWNERCHANGEGLOBALENDINGSIRINGPRICE671(uint256 _newGlobalEndingSiringPrice) external ONLYOWNER459 {
        globalEndingSiringPrice = _newGlobalEndingSiringPrice;
    }

    function OWNERCHANGEGLOBALAUCTIONDURATION321(uint256 _newGlobalAuctionDuration) external ONLYOWNER459 {
        globalAuctionDuration = _newGlobalAuctionDuration;
    }

    function OWNERCHANGEAUCTIONCREATIONREWARD955(uint256 _newAuctionCreationReward) external ONLYOWNER459 {
        auctionCreationReward = _newAuctionCreationReward;
    }

    function OWNERCANCELSIRINGAUCTION522(uint256 _kittyId) external ONLYOWNER459 {
        KittySires(kittySiresAddress).CANCELAUCTION283(_kittyId);
    }

    function OWNERWITHDRAWKITTY460(address _destination, uint256 _kittyId) external ONLYOWNER459 {
        KittyCore(kittyCoreAddress).TRANSFER410(_destination, _kittyId);
    }

    function OWNERWHITELISTKITTY644(uint256 _kittyId, bool _whitelist) external ONLYOWNER459 {
        kittyIsWhitelisted[_kittyId] = _whitelist;
        if(_whitelist){
            numberOfWhitelistedKitties = numberOfWhitelistedKitties.ADD121(1);
        } else {
            numberOfWhitelistedKitties = numberOfWhitelistedKitties.SUB229(1);
        }
    }





    function OWNERWITHDRAWALLEARNINGS662() external ONLYOWNER459 {
        uint256 contractBalance = address(this).balance;
        uint256 fundsToLeaveToIncentivizeFutureCallers = auctionCreationReward.MUL808(numberOfWhitelistedKitties);
        if(contractBalance > fundsToLeaveToIncentivizeFutureCallers){
            uint256 earnings = contractBalance.SUB229(fundsToLeaveToIncentivizeFutureCallers);
            msg.sender.transfer(earnings);
        }
    }




    function EMERGENCYWITHDRAW520() external ONLYOWNER459 {
        msg.sender.transfer(address(this).balance);
    }

    constructor() public {

        startingSiringPriceForKitty[848437] = 200000000000000000;
        startingSiringPriceForKitty[848439] = 200000000000000000;
        startingSiringPriceForKitty[848440] = 200000000000000000;
        startingSiringPriceForKitty[848441] = 200000000000000000;
        startingSiringPriceForKitty[848442] = 200000000000000000;
        startingSiringPriceForKitty[848582] = 200000000000000000;


        kittyIsWhitelisted[848437] = true;
        kittyIsWhitelisted[848439] = true;
        kittyIsWhitelisted[848440] = true;
        kittyIsWhitelisted[848441] = true;
        kittyIsWhitelisted[848442] = true;
        kittyIsWhitelisted[848582] = true;
        numberOfWhitelistedKitties = 6;




        TRANSFEROWNERSHIP989(0xBb1e390b77Ff99f2765e78EF1A7d069c29406bee);
    }

    function() external payable {}
}

contract KittyCore {
    function TRANSFER410(address _to, uint256 _tokenId) external;
    function CREATESIRINGAUCTION26(uint256 _kittyId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external;
}

contract KittySires {
    function CANCELAUCTION283(uint256 _tokenId) external;
}
