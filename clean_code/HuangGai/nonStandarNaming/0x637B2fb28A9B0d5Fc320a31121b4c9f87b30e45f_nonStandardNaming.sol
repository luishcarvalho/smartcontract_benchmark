

pragma solidity ^0.5.17;


library SafeMath {
    function ADD171(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function SUB705(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB705(a, b, "SafeMath: subtraction overflow");
    }

    function SUB705(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function MUL180(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function DIV369(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV369(a, b, "SafeMath: division by zero");
    }

    function DIV369(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }

    function MOD90(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD90(a, b, "SafeMath: modulo by zero");
    }

    function MOD90(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function TRANSFER190(address to, uint256 value) external returns (bool);

    function APPROVE617(address spender, uint256 value) external returns (bool);

    function TRANSFERFROM76(address from, address to, uint256 value) external returns (bool);

    function TOTALSUPPLY562() external view returns (uint256);

    function BALANCEOF573(address who) external view returns (uint256);

    function ALLOWANCE952(address owner, address spender) external view returns (uint256);

    event TRANSFER195(address indexed from, address indexed to, uint256 value);

    event APPROVAL248(address indexed owner, address indexed spender, uint256 value);
}

contract MatrixErc20 {
    using SafeMath for uint;
    address public ownerWallet;

    struct UserStruct {
        bool isExist;
        uint id;
        mapping (address => uint256) tokenRewards;
        mapping (address => uint) referrerID;
        mapping (address => address[]) referral;
        mapping(address => mapping(uint => uint)) levelExpired;
    }

    uint REFERRER_1_LEVEL_LIMIT = 5;
    uint PERIOD_LENGTH = 180 days;
    uint ADMIN_FEE_PERCENTAGE = 10;
    mapping(address => mapping(uint => uint)) public LEVEL_PRICE;
    mapping (address => UserStruct) public users;
    mapping (uint => address) public userList;
    uint public currUserID = 0;

    mapping (address => bool) public tokens;

    mapping (address => uint256) public ownerFees;

    event REGLEVELEVENT510(address indexed _user, address indexed _referrer, uint _time, address _token);
    event BUYLEVELEVENT399(address indexed _user, uint _level, uint _time, address _token);
    event PROLONGATELEVELEVENT866(address indexed _user, uint _level, uint _time, address _token);
    event GETMONEYFORLEVELEVENT355(address indexed _user, address indexed _referral, uint _level, address _token);
    event LOSTMONEYFORLEVELEVENT103(address indexed _user, address indexed _referral, uint _level, uint _time, address _token);

    function SETPERIODLENGTH571(uint _periodLength) public ONLYOWNER423 {
        PERIOD_LENGTH = _periodLength;
    }

    function SETADMINFEEPERCENTAGE408(uint _adminFeePercentage) public ONLYOWNER423 {
        require (_adminFeePercentage >= 0 && _adminFeePercentage <= 100, "Fee must be between 0 and 100");

        ADMIN_FEE_PERCENTAGE = _adminFeePercentage;
    }

    function TOGGLETOKEN328(address _token, bool _enabled) public ONLYOWNER423 {
        tokens[_token] = _enabled;

        if (_enabled) {
            for(uint i = 1; i <= 10; i++) {
                users[ownerWallet].levelExpired[_token][i] = 55555555555;
            }

            users[ownerWallet].referrerID[_token] = 0;
        }
    }

    function SETTOKENPRICEATLEVEL23(address _token, uint _level, uint _price) public ONLYOWNER423 {
        require(_level > 0 && _level <= 10, "Invalid level");

        LEVEL_PRICE[_token][_level] = _price;
    }

    function SETTOKENPRICE69(address _token, uint _price1, uint _price2, uint _price3, uint _price4, uint _price5, uint _price6, uint _price7, uint _price8, uint _price9, uint _price10) public ONLYOWNER423 {
        LEVEL_PRICE[_token][1] = _price1;
        LEVEL_PRICE[_token][2] = _price2;
        LEVEL_PRICE[_token][3] = _price3;
        LEVEL_PRICE[_token][4] = _price4;
        LEVEL_PRICE[_token][5] = _price5;
        LEVEL_PRICE[_token][6] = _price6;
        LEVEL_PRICE[_token][7] = _price7;
        LEVEL_PRICE[_token][8] = _price8;
        LEVEL_PRICE[_token][9] = _price9;
        LEVEL_PRICE[_token][10] = _price10;

        if (!tokens[_token]) {
            TOGGLETOKEN328(_token, true);
        }
    }

    constructor() public {
        ownerWallet = msg.sender;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID
        });
        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;
    }

    modifier ONLYOWNER423() {
        require(msg.sender == ownerWallet, 'caller must be the owner');
        _;
    }


    function TRANSFEROWNERSHIP988(address newOwner) public ONLYOWNER423 {
        require(newOwner != address(0), 'new owner is the zero address');
        require(!users[newOwner].isExist, 'new owner needs to be a new address');

        UserStruct memory userStruct = UserStruct({
            isExist: true,
            id: 1
        });

        users[newOwner] = userStruct;
        userList[1] = newOwner;

        delete users[ownerWallet];
        ownerWallet = newOwner;
    }

    function REGUSER700(address _token, uint _referrerID) public payable {
        require(tokens[_token], "Token is not enabled");
        require(!users[msg.sender].isExist, 'User exist');
        require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referrer Id');

        IERC20 token = IERC20(_token);
        require(token.TRANSFERFROM76(msg.sender, address(this), LEVEL_PRICE[_token][1]), "Couldn't take the tokens from the sender");

        if(users[userList[_referrerID]].referral[_token].length >= REFERRER_1_LEVEL_LIMIT) _referrerID = users[FINDFREEREFERRER993(_token, userList[_referrerID])].id;

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID
        });

        users[msg.sender] = userStruct;
        users[msg.sender].referrerID[_token] = _referrerID;
        userList[currUserID] = msg.sender;

        users[msg.sender].levelExpired[_token][1] = now + PERIOD_LENGTH;

        users[userList[_referrerID]].referral[_token].push(msg.sender);

        PAYFORLEVEL516(_token, 1, msg.sender);

        emit REGLEVELEVENT510(msg.sender, userList[_referrerID], now, _token);
    }

    function BUYLEVEL817(address _token, uint _level) public payable {
        require(users[msg.sender].isExist, 'User not exist');
        require(_level > 0 && _level <= 10, 'Incorrect level');
        require(tokens[_token], "Token is not enabled");

        IERC20 token = IERC20(_token);
        require(token.TRANSFERFROM76(msg.sender, address(this), LEVEL_PRICE[_token][_level]), "Couldn't take the tokens from the sender");

        if(_level == 1) {
            users[msg.sender].levelExpired[_token][1] += PERIOD_LENGTH;
        }
        else {
            for(uint l =_level - 1; l > 0; l--) require(users[msg.sender].levelExpired[_token][l] >= now, 'Buy the previous level');

            if(users[msg.sender].levelExpired[_token][_level] == 0) users[msg.sender].levelExpired[_token][_level] = now + PERIOD_LENGTH;
            else users[msg.sender].levelExpired[_token][_level] += PERIOD_LENGTH;
        }

        PAYFORLEVEL516(_token, _level, msg.sender);

        emit BUYLEVELEVENT399(msg.sender, _level, now, _token);
    }

    function GETREFERERINTREE743(address _token, uint _level, address _user) internal view returns(address) {
        address referer;
        address referer1;
        address referer2;
        address referer3;
        address referer4;

        if(_level == 1 || _level == 6) {
            referer = userList[users[_user].referrerID[_token]];
        }
        else if(_level == 2 || _level == 7) {
            referer1 = userList[users[_user].referrerID[_token]];
            referer = userList[users[referer1].referrerID[_token]];
        }
        else if(_level == 3 || _level == 8) {
            referer1 = userList[users[_user].referrerID[_token]];
            referer2 = userList[users[referer1].referrerID[_token]];
            referer = userList[users[referer2].referrerID[_token]];
        }
        else if(_level == 4 || _level == 9) {
            referer1 = userList[users[_user].referrerID[_token]];
            referer2 = userList[users[referer1].referrerID[_token]];
            referer3 = userList[users[referer2].referrerID[_token]];
            referer = userList[users[referer3].referrerID[_token]];
        }
        else if(_level == 5 || _level == 10) {
            referer1 = userList[users[_user].referrerID[_token]];
            referer2 = userList[users[referer1].referrerID[_token]];
            referer3 = userList[users[referer2].referrerID[_token]];
            referer4 = userList[users[referer3].referrerID[_token]];
            referer = userList[users[referer4].referrerID[_token]];
        }

        if(!users[referer].isExist) referer = userList[1];

        return referer;
    }

    function PAYFORLEVEL516(address _token, uint _level, address _user) internal {
        address referer = GETREFERERINTREE743(_token, _level, _user);

        if(users[referer].levelExpired[_token][_level] >= now) {
            uint levelPrice = LEVEL_PRICE[_token][_level];
            uint payToOwner = levelPrice.MUL180(ADMIN_FEE_PERCENTAGE).DIV369(100);
            uint payToReferrer = levelPrice.SUB705(payToOwner);
            users[address(uint160(referer))].tokenRewards[_token] = users[address(uint160(referer))].tokenRewards[_token].ADD171(payToReferrer);
            ownerFees[_token] = ownerFees[_token].ADD171(payToOwner);

            emit GETMONEYFORLEVELEVENT355(referer, msg.sender, _level, _token);
        }
        else {
            emit LOSTMONEYFORLEVELEVENT103(referer, msg.sender, _level, now, _token);

            PAYFORLEVEL516(_token, _level, referer);
        }
    }

    function FINDFREEREFERRER993(address _token, address _user) public view returns(address) {
        if(users[_user].referral[_token].length < REFERRER_1_LEVEL_LIMIT) return _user;

        address[] memory referrals = new address[](315);
        referrals[0] = users[_user].referral[_token][0];
        referrals[1] = users[_user].referral[_token][1];
        referrals[2] = users[_user].referral[_token][2];
        referrals[3] = users[_user].referral[_token][3];
        referrals[4] = users[_user].referral[_token][4];

        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i = 0; i < 126; i++) {
            if(users[referrals[i]].referral[_token].length == REFERRER_1_LEVEL_LIMIT) {
                if(i < 155) {
                    referrals[(i+1)*2] = users[referrals[i]].referral[_token][0];
                    referrals[(i+1)*2+1] = users[referrals[i]].referral[_token][2];
                    referrals[(i+1)*2+2] = users[referrals[i]].referral[_token][3];
                    referrals[(i+1)*2+3] = users[referrals[i]].referral[_token][4];
                    referrals[(i+1)*2+4] = users[referrals[i]].referral[_token][5];
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

    function WITHDRAW913(address _token) public {
        uint256 total = users[msg.sender].tokenRewards[_token];
        require(total > 0, "Nothing to withdraw");
        users[msg.sender].tokenRewards[_token] = 0;
        IERC20 token = IERC20(_token);
        require(token.TRANSFER190(msg.sender, total), "Couldn't send the tokens");
    }

    function _WITHDRAWFEES891(address _token) public ONLYOWNER423 {
        uint256 total = ownerFees[_token];
        require(total > 0, "Nothing to withdraw");
        ownerFees[_token] = 0;
        IERC20 token = IERC20(_token);
        require(token.TRANSFER190(msg.sender, total), "Couldn't send the tokens");
    }

    function VIEWUSERREFERRAL790(address _token, address _user) public view returns(address[] memory) {
        return users[_user].referral[_token];
    }

    function VIEWUSERREFERRER85(address _token, address _user) public view returns(uint256) {
        return users[_user].referrerID[_token];
    }

    function VIEWUSERLEVELEXPIRED566(address _token, address _user, uint _level) public view returns(uint) {
        return users[_user].levelExpired[_token][_level];
    }

    function VIEWUSERISEXIST611(address _user) public view returns(bool) {
        return users[_user].isExist;
    }

    function VIEWUSERREWARDS680(address _user, address _token) public view returns(uint256) {
        return users[_user].tokenRewards[_token];
    }

    function BYTESTOADDRESS886(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function _CLOSE871(address payable _to) public ONLYOWNER423 {
        selfdestruct(_to);
    }
}
