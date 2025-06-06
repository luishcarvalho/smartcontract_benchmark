





























pragma solidity 0.5.16;



contract ownerShip
{

    address public ownerWallet;
    address public newOwner;

    event OwnershipTransferredEv(address indexed previousOwner, address indexed newOwner);


    constructor() public
    {

        ownerWallet = msg.sender;
        emit OwnershipTransferredEv(address(0), msg.sender);
    }

    function transferOwnership(address _newOwner) public onlyOwner
    {
        newOwner = _newOwner;
    }


    function acceptOwnership() public
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferredEv(ownerWallet, newOwner);
        ownerWallet = newOwner;
        newOwner = address(0);
    }


    modifier onlyOwner()
    {
        require(msg.sender == ownerWallet);
        _;
    }

}



interface usdtInterface
{
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}

interface multiadminInterface
{
    function payamount(uint256 _amount) external;
}



contract QRPal is ownerShip {


    uint public maxDownLimit = 2;
    uint public levelLifeTime = 8640000;
    uint public lastIDCount = 0;
    address public usdtTokenAddress;

    struct userInfo {
        bool joined;
        uint id;
        uint referrerID;
        address[] referral;
        mapping(uint => uint) levelExpired;
    }

    mapping(uint => uint) public priceOfLevel;
    mapping (address => userInfo) public userInfos;
    mapping (uint => address) public userAddressByID;

    address public multiadminaddress;



    event regLevelEv(uint indexed _userID, address indexed _userWallet, uint indexed _referrerID, address _refererWallet, uint _originalReferrer, uint _time);
    event levelBuyEv(address indexed _user, uint _level, uint _amount, uint _time);
    event paidForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);
    event lostForLevelEv(address indexed _user, address indexed _referral, uint _level, uint _amount, uint _time);




    constructor(address _usdtTokenAddress, address _multiadminAddress) public {
        require(_usdtTokenAddress!=address(0));
        require(_multiadminAddress!=address(0));

        usdtTokenAddress = _usdtTokenAddress;
        multiadminaddress=_multiadminAddress;


        priceOfLevel[1] = 20*(10**6);
        priceOfLevel[2] = 30*(10**6);
        priceOfLevel[3] = 60*(10**6);
        priceOfLevel[4] = 180*(10**6);
        priceOfLevel[5] = 880*(10**6);
        priceOfLevel[6] = 6160*(10**6);
        priceOfLevel[7] = 8320*(10**6);
        priceOfLevel[8] = 13280*(10**6);
        priceOfLevel[9] = 16240*(10**6);
        priceOfLevel[10] = 29640*(10**6);

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: 0,
            referral: new address[](0)
        });
        userInfos[multiadminaddress] = UserInfo;
        userAddressByID[lastIDCount] = multiadminaddress;

        for(uint i = 1; i <= 10; i++) {
            userInfos[multiadminaddress].levelExpired[i] = 99999999999;
            emit paidForLevelEv(multiadminaddress, address(0), i, priceOfLevel[i], now);
        }

        emit regLevelEv(lastIDCount, multiadminaddress, 0, address(0), 0, now);

    }





    function () external payable {
        revert();
    }






    function regUser(uint _referrerID) public {
        uint originalReferrerID = _referrerID;
        require(!userInfos[msg.sender].joined, 'User exist');
        require(_referrerID > 0 && _referrerID <= lastIDCount, 'Incorrect referrer Id');


        if(userInfos[userAddressByID[_referrerID]].referral.length >= maxDownLimit) _referrerID = userInfos[findFreeReferrer(userAddressByID[_referrerID])].id;

        userInfo memory UserInfo;
        lastIDCount++;

        UserInfo = userInfo({
            joined: true,
            id: lastIDCount,
            referrerID: _referrerID,
            referral: new address[](0)
        });

        userInfos[msg.sender] = UserInfo;
        userAddressByID[lastIDCount] = msg.sender;

        userInfos[msg.sender].levelExpired[1] = now + levelLifeTime;

        userInfos[userAddressByID[_referrerID]].referral.push(msg.sender);

        payForLevel(1, msg.sender);

        emit regLevelEv(lastIDCount, msg.sender, _referrerID, userAddressByID[_referrerID], originalReferrerID, now);
        emit levelBuyEv(msg.sender, 1, priceOfLevel[1], now);
    }






    function buyLevel(uint _level) public returns(bool) {
        require(userInfos[msg.sender].joined, 'User not exist');
        require(_level > 0 && _level <= 10, 'Incorrect level');


        if(msg.sender!=ownerWallet){


        }

        if(_level == 1) {
            userInfos[msg.sender].levelExpired[1] += levelLifeTime;
        }
        else {

            for(uint l =_level - 1; l > 0; l--) require(userInfos[msg.sender].levelExpired[l] >= now, 'Buy the previous level');

            if(userInfos[msg.sender].levelExpired[_level] == 0) userInfos[msg.sender].levelExpired[_level] = now + levelLifeTime;
            else userInfos[msg.sender].levelExpired[_level] += levelLifeTime;
        }

        payForLevel(_level, msg.sender);

        emit levelBuyEv(msg.sender, _level, priceOfLevel[_level], now);
        return true;
    }





    function payForLevel(uint _level, address _user) internal {
        address referer;
        address referer1;
        address referer2;
        address referer3;
        address referer4;

        if(_level == 1 || _level == 6) {
            referer = userAddressByID[userInfos[_user].referrerID];
        }
        else if(_level == 2 || _level == 7) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer = userAddressByID[userInfos[referer1].referrerID];
        }
        else if(_level == 3 || _level == 8) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer2 = userAddressByID[userInfos[referer1].referrerID];
            referer = userAddressByID[userInfos[referer2].referrerID];
        }
        else if(_level == 4 || _level == 9) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer2 = userAddressByID[userInfos[referer1].referrerID];
            referer3 = userAddressByID[userInfos[referer2].referrerID];
            referer = userAddressByID[userInfos[referer3].referrerID];
        }
        else if(_level == 5 || _level == 10) {
            referer1 = userAddressByID[userInfos[_user].referrerID];
            referer2 = userAddressByID[userInfos[referer1].referrerID];
            referer3 = userAddressByID[userInfos[referer2].referrerID];
            referer4 = userAddressByID[userInfos[referer3].referrerID];
            referer = userAddressByID[userInfos[referer4].referrerID];
        }

        if(!userInfos[referer].joined) referer = userAddressByID[1];

        bool sent = false;
        if(userInfos[referer].levelExpired[_level] >= now) {


            if(referer==multiadminaddress)
            {
                referer=ownerWallet;
            }

            sent = usdtInterface(usdtTokenAddress).transferFrom(msg.sender,referer, priceOfLevel[_level]);

            if (sent) {
                emit paidForLevelEv(referer, msg.sender, _level, priceOfLevel[_level], now);
            }
        }
        if(!sent) {
            emit lostForLevelEv(referer, msg.sender, _level, priceOfLevel[_level], now);

            if(userAddressByID[userInfos[referer].referrerID]==multiadminaddress)
            {
                multiadminInterface(multiadminaddress).payamount(priceOfLevel[_level]);
                usdtInterface(usdtTokenAddress).transferFrom(msg.sender,multiadminaddress, priceOfLevel[_level]);

                emit paidForLevelEv(multiadminaddress, msg.sender, _level, priceOfLevel[_level], now);

            }
            else
            {
                payForLevel(_level, referer);
            }

        }
    }






    function findFreeReferrer(address _user) public view returns(address) {
        if(userInfos[_user].referral.length < maxDownLimit) return _user;

        address[] memory referrals = new address[](126);
        referrals[0] = userInfos[_user].referral[0];
        referrals[1] = userInfos[_user].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(userInfos[referrals[i]].referral.length == maxDownLimit) {
                if(i < 62) {
                    referrals[(i+1)*2] = userInfos[referrals[i]].referral[0];
                    referrals[(i+1)*2+1] = userInfos[referrals[i]].referral[1];
                }
            }
            else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }

        require(!noFreeReferrer, 'No Free Referrer');

        return freeReferrer;
    }







    function changeUSDTaddress(address _add) public onlyOwner{
        usdtTokenAddress=_add;
    }





    function viewUserReferral(address _user) public view returns(address[] memory) {
        return userInfos[_user].referral;
    }





    function viewUserLevelExpired(address _user, uint _level) public view returns(uint) {
        return userInfos[_user].levelExpired[_level];
    }





    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }





    function viewTimestampSinceJoined(address usr) public view returns(uint256[10] memory timeSinceJoined )
    {
        if(userInfos[usr].joined)
        {
            for(uint256 i=0;i<10;i++)
            {
                uint256 t = userInfos[usr].levelExpired[i+1];
                if(t>now)
                {
                    timeSinceJoined[i] = (t-now);
                }
            }
        }
        return timeSinceJoined;
    }

    function changeMultiadminAddress(address _add) public onlyOwner{
        require(_add!=address(0));

        multiadminaddress=_add;
    }

}
