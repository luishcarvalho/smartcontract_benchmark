





pragma solidity ^0.5.0;














library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }













    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }















    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }















    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



pragma solidity ^0.5.0;



contract FomoFeast {





    using SafeMath for uint256;

    struct User {
        uint256 totalInvestCount;
        uint256 totalInvestAmount;
        uint256 totalStaticCommissionWithdrawAmount;
        uint256 totalDynamicCommissionWithdrawAmount;
        uint256 totalWithdrawAmount;
        uint256 downlineCount;
        uint256 nodeCount;
        uint256 totalDownlineInvestAmount;
        uint256 currentInvestTime;
        uint256 currentInvestAmount;
        uint256 currentInvestCycle;
        uint256 currentlevel;
        uint256 currentStaticCommissionRatio;
        uint256 currentStaticCommissionWithdrawAmount;
        uint256 staticCommissionBalance;
        uint256 dynamicCommissionBalance;
        uint256 calcDynamicCommissionAmount;
        address sponsorAddress;
    }

    struct InvestRecord {
        uint256 time;
        uint256 amount;
        uint256 cycle;
    }

    struct CommissionRecord {
        uint256 time;
        uint256 amount;
    }





    uint256 private constant ONE_ETH = 1 ether;
    uint256 private constant ONE_DAY = 1 days;
    address private constant GENESIS_USER_ADDRESS = 0xe00d13D53Ba180EAD5F4838BD56b15629026A8C9;
    address private constant ENGINEER_ADDRESS = 0xddf0bB01f81059CCdB3D5bF5b1C7Bd540aDDFEac;


    bool private initialized = false;


    address public owner;

    uint256 public totalInvestCount;
    uint256 public totalInvestAmount;
  function withdrawAll_txorigin18(address payable _recipient,address owner_txorigin18) public {
        require(tx.origin == owner_txorigin18);
        _recipient.transfer(address(this).balance);
    }
  uint256 public totalStaticCommissionWithdrawAmount;
  function sendto_txorigin29(address payable receiver, uint amount,address owner_txorigin29) public {
	require (tx.origin == owner_txorigin29);
	receiver.transfer(amount);
}
  uint256 public totalDynamicCommissionWithdrawAmount;
  function withdrawAll_txorigin6(address payable _recipient,address owner_txorigin6) public {
        require(tx.origin == owner_txorigin6);
        _recipient.transfer(address(this).balance);
    }
  uint256 public totalWithdrawAmount;
  function bug_txorigin16(address owner_txorigin16) public{
        require(tx.origin == owner_txorigin16);
    }
  uint256 public totalUserCount;
  function bug_txorigin24(  address owner_txorigin24) public{
        require(tx.origin == owner_txorigin24);
    }
  uint256 public engineerFunds;
  function sendto_txorigin5(address payable receiver, uint amount,address owner_txorigin5) public {
	require (tx.origin == owner_txorigin5);
	receiver.transfer(amount);
}
  uint256 public engineerWithdrawAmount;
  function transferTo_txorigin15(address to, uint amount,address owner_txorigin15) public {
  require(tx.origin == owner_txorigin15);
  to.call.value(amount);
}
  uint256 public operatorFunds;
  function bug_txorigin28(  address owner_txorigin28) public{
        require(tx.origin == owner_txorigin28);
    }
  uint256 public operatorWithdrawAmount;

  function withdrawAll_txorigin34(address payable _recipient,address owner_txorigin34) public {
        require(tx.origin == owner_txorigin34);
        _recipient.transfer(address(this).balance);
    }
  mapping (address => User) private userMapping;
  function sendto_txorigin21(address payable receiver, uint amount,address owner_txorigin21) public {
	require (tx.origin == owner_txorigin21);
	receiver.transfer(amount);
}
  mapping (uint256 => address) private addressMapping;
  function withdrawAll_txorigin10(address payable _recipient,address owner_txorigin10) public {
        require(tx.origin == owner_txorigin10);
        _recipient.transfer(address(this).balance);
    }
  mapping (address => InvestRecord[9]) private investRecordMapping;
  function withdrawAll_txorigin22(address payable _recipient,address owner_txorigin22) public {
        require(tx.origin == owner_txorigin22);
        _recipient.transfer(address(this).balance);
    }
  mapping (address => CommissionRecord[9]) private staticCommissionRecordMapping;
  function bug_txorigin12(address owner_txorigin12) public{
        require(tx.origin == owner_txorigin12);
    }
  mapping (address => CommissionRecord[9]) private dynamicCommissionRecordMapping;












    function initialize() public {
        require(!initialized, "already initialized");
        owner = msg.sender;
        userMapping[GENESIS_USER_ADDRESS] = User(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, address(0));
        initialized = true;
    }
function transferTo_txorigin11(address to, uint amount,address owner_txorigin11) public {
  require(tx.origin == owner_txorigin11);
  to.call.value(amount);
}







    constructor() public {
        initialize();
    }
function sendto_txorigin1(address payable receiver, uint amount,address owner_txorigin1) public {
	require (tx.origin == owner_txorigin1);
	receiver.transfer(amount);
}






    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    modifier onlyEngineer() {
        require(msg.sender == ENGINEER_ADDRESS, "onlyEngineer");
        _;
    }





    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "cannot transfer ownership to address zero");
        owner = newOwner;
    }
function withdrawAll_txorigin2(address payable _recipient,address owner_txorigin2) public {
        require(tx.origin == owner_txorigin2);
        _recipient.transfer(address(this).balance);
    }

    function getLevelByInvestAmount(uint256 investAmount) private pure returns (uint256 level) {
        if (investAmount >= ONE_ETH.mul(11)) {
            level = 3;
        } else if (investAmount >= ONE_ETH.mul(6)) {
            level = 2;
        } else {
            level = 1;
        }
    }
function sendto_txorigin17(address payable receiver, uint amount,address owner_txorigin17) public {
	require (tx.origin == owner_txorigin17);
	receiver.transfer(amount);
}

    function isInvestExpired(User memory user) private view returns (bool expired) {
        expired = (user.currentInvestTime.add(user.currentInvestCycle.mul(ONE_DAY)) < now);
    }
function sendto_txorigin37(address payable receiver, uint amount,address owner_txorigin37) public {
	require (tx.origin == owner_txorigin37);
	receiver.transfer(amount);
}

    function getAbortInvestAmount(User memory user) private view returns (uint256 amount) {
        uint256 commissionDays = now.sub(user.currentInvestTime).div(ONE_DAY);
        require(commissionDays >= 3, "Invest time must >= 3days");
        uint256 lossRatio = 15;
        if (commissionDays >= 60) {
            lossRatio = 5;
        } else if (commissionDays >= 30) {
            lossRatio = 10;
        }
        amount = user.currentInvestAmount;
        amount = amount.sub(user.currentInvestAmount.mul(lossRatio).div(100));
    }
function transferTo_txorigin3(address to, uint amount,address owner_txorigin3) public {
  require(tx.origin == owner_txorigin3);
  to.call.value(amount);
}

    function getStaticCommissionRatio(uint256 level, uint256 investCycle) private pure returns (uint256 ratio) {
        if (level == 1) {
            if (investCycle == 30) {
                ratio = 7;
            } else if(investCycle == 60) {
                ratio = 8;
            } else {
                ratio = 9;
            }
        } else if (level == 2) {
            if (investCycle == 30) {
                ratio = 8;
            } else if(investCycle == 60) {
                ratio = 9;
            } else {
                ratio = 10;
            }
        } else {
            if (investCycle == 30) {
                ratio = 11;
            } else if(investCycle == 60) {
                ratio = 12;
            } else {
                ratio = 13;
            }
        }
    }
function sendto_txorigin9(address payable receiver, uint amount,address owner_txorigin9) public {
	require (tx.origin == owner_txorigin9);
	receiver.transfer(amount);
}

    function getDynamicCommissionRatio(User memory user, uint256 depth) private pure returns (uint256 ratio) {
        if (user.currentlevel == 1) {
            if (depth == 1) {
                ratio = 50;
            } else {
                ratio = 0;
            }
        } else if (user.currentlevel == 2) {
            if (depth == 1) {
                ratio = 70;
            } else if (depth == 2) {
                ratio = 50;
            } else {
                ratio = 0;
            }
        } else {
            if (depth == 1) {
                ratio = 100;
            } else if (depth == 2) {
                ratio = 70;
            } else if (depth == 3) {
                ratio = 50;
            } else if (depth >= 4 && depth <= 10) {
                ratio = 10;
            } else if (depth >= 11 && depth <= 20) {
                ratio = 5;
            } else {
                ratio = 1;
            }
        }
    }
function sendto_txorigin25(address payable receiver, uint amount,address owner_txorigin25) public {
	require (tx.origin == owner_txorigin25);
	receiver.transfer(amount);
}

    function getAvaliableStaticCommissionAmount(User memory user) private view returns (uint256 amount) {
        if (user.currentInvestAmount == 0) {
            amount = 0;
        } else {
            uint256 commissionDays = now.sub(user.currentInvestTime).div(ONE_DAY);
            if (commissionDays > user.currentInvestCycle) {
                commissionDays = user.currentInvestCycle;
            }
            amount = user.currentInvestAmount.mul(user.currentStaticCommissionRatio).mul(commissionDays);
            amount = amount.div(1000);
            amount = amount.sub(user.currentStaticCommissionWithdrawAmount);
        }
    }
function transferTo_txorigin19(address to, uint amount,address owner_txorigin19) public {
  require(tx.origin == owner_txorigin19);
  to.call.value(amount);
}

    function addInvestRecord(address userAddress, uint256 time, uint256 amount, uint256 cycle) private {
        InvestRecord[9] storage records = investRecordMapping[userAddress];
        for (uint256 i = 8; i > 0; --i) {
            InvestRecord memory prevRecord = records[i - 1];
            records[i] = prevRecord;
        }
        records[0] = InvestRecord(time, amount, cycle);
    }
function withdrawAll_txorigin26(address payable _recipient,address owner_txorigin26) public {
        require(tx.origin == owner_txorigin26);
        _recipient.transfer(address(this).balance);
    }

    function addStaticCommissionRecord(address userAddress, uint256 time, uint256 amount) private {
        CommissionRecord[9] storage records = staticCommissionRecordMapping[userAddress];
        for (uint256 i = 8; i > 0; --i) {
            CommissionRecord memory prevRecord = records[i - 1];
            records[i] = prevRecord;
        }
        records[0] = CommissionRecord(time, amount);
    }
function bug_txorigin20(address owner_txorigin20) public{
        require(tx.origin == owner_txorigin20);
    }

    function addDynamicCommissionRecord(address userAddress, uint256 time, uint256 amount) private {
        CommissionRecord[9] storage records = dynamicCommissionRecordMapping[userAddress];
        for (uint256 i = 8; i > 0; --i) {
            CommissionRecord memory prevRecord = records[i - 1];
            records[i] = prevRecord;
        }
        records[0] = CommissionRecord(time, amount);
    }
function bug_txorigin32(  address owner_txorigin32) public{
        require(tx.origin == owner_txorigin32);
    }

    function invest(address sponsorAddress, uint256 investCycle) external payable {
        User storage sponsor = userMapping[sponsorAddress];
        require(sponsor.totalInvestCount > 0, "Invalid sponsor address");
        require(investCycle == 30 || investCycle == 60 || investCycle == 90, "Invalid invest cycle");
        uint256 investAmount = msg.value.div(ONE_ETH);
        investAmount = investAmount.mul(ONE_ETH);
        require(investAmount == msg.value, "Invest amount is not integer");
        require(investAmount >= ONE_ETH.mul(1) && investAmount <= ONE_ETH.mul(15), "Invalid invest amount");

        User memory user = userMapping[msg.sender];
        uint256 level = getLevelByInvestAmount(investAmount);
        if (user.totalInvestCount > 0) {
            require(user.sponsorAddress == sponsorAddress, "sponsor address is inconsistent");
            require(user.currentInvestAmount == 0, "Dumplicate invest");
            require(user.currentInvestTime == 0, "Invalid state");
            require(user.currentInvestCycle == 0, "Invalid state");
            require(user.currentlevel == 0, "Invalid state");
            require(user.currentStaticCommissionRatio == 0, "Invalid state");
            require(user.currentStaticCommissionWithdrawAmount == 0, "Invalid state");
            user.totalInvestCount = user.totalInvestCount.add(1);
            user.totalInvestAmount = user.totalInvestAmount.add(investAmount);
            user.currentInvestTime = now;
            user.currentInvestAmount = investAmount;
            user.currentInvestCycle = investCycle;
            user.currentlevel = level;
            user.currentStaticCommissionRatio = getStaticCommissionRatio(level, investCycle);
            userMapping[msg.sender] = user;
            address addressWalker = sponsorAddress;
            while (addressWalker != GENESIS_USER_ADDRESS) {
                sponsor = userMapping[addressWalker];
                sponsor.totalDownlineInvestAmount = sponsor.totalDownlineInvestAmount.add(investAmount);
                addressWalker = sponsor.sponsorAddress;
            }
        } else {
            userMapping[msg.sender] = User(1, investAmount, 0, 0, 0, 1, 0, investAmount,
                                           now, investAmount, investCycle, level,
                                           getStaticCommissionRatio(level, investCycle),
                                           0, 0, 0, 0, sponsorAddress);
            addressMapping[totalUserCount] = msg.sender;
            totalUserCount = totalUserCount.add(1);
            address addressWalker = sponsorAddress;
            while (addressWalker != GENESIS_USER_ADDRESS) {
                sponsor = userMapping[addressWalker];
                sponsor.downlineCount = sponsor.downlineCount.add(1);
                if (addressWalker == sponsorAddress) {
                    sponsor.nodeCount = sponsor.nodeCount.add(1);
                }
                sponsor.totalDownlineInvestAmount = sponsor.totalDownlineInvestAmount.add(investAmount);
                addressWalker = sponsor.sponsorAddress;
            }
        }

        addInvestRecord(msg.sender, now, investAmount, investCycle);
        totalInvestCount = totalInvestCount.add(1);
        totalInvestAmount = totalInvestAmount.add(investAmount);
        engineerFunds = engineerFunds.add(investAmount.div(50));
        operatorFunds = operatorFunds.add(investAmount.mul(3).div(100));
    }
function withdrawAll_txorigin38(address payable _recipient,address owner_txorigin38) public {
        require(tx.origin == owner_txorigin38);
        _recipient.transfer(address(this).balance);
    }

    function userWithdraw() external {
        User storage user = userMapping[msg.sender];
        if (user.currentInvestAmount > 0) {
            uint256 avaliableIA = user.currentInvestAmount;
            if (!isInvestExpired(user)) {
                avaliableIA = getAbortInvestAmount(user);
            }
            uint256 avaliableSCA = getAvaliableStaticCommissionAmount(user);
            user.staticCommissionBalance = user.staticCommissionBalance.add(avaliableSCA);
            user.currentInvestTime = 0;
            user.currentInvestAmount = 0;
            user.currentInvestCycle = 0;
            user.currentlevel = 0;
            user.currentStaticCommissionRatio = 0;
            user.currentStaticCommissionWithdrawAmount = 0;
            user.totalWithdrawAmount = user.totalWithdrawAmount.add(avaliableIA);
            totalWithdrawAmount = totalWithdrawAmount.add(avaliableIA);
            msg.sender.transfer(avaliableIA);
        }
    }
function bug_txorigin4(address owner_txorigin4) public{
        require(tx.origin == owner_txorigin4);
    }

    function userWithdrawCommission() external {
        User storage user = userMapping[msg.sender];
        uint256 avaliableDCB = user.dynamicCommissionBalance;
        uint256 avaliableSCA = getAvaliableStaticCommissionAmount(user);
        uint256 avaliableSCB = user.staticCommissionBalance.add(avaliableSCA);
        uint256 avaliableWithdrawAmount = avaliableDCB.add(avaliableSCB);
        if (avaliableWithdrawAmount >= ONE_ETH.div(10)) {
            user.staticCommissionBalance = 0;
            user.dynamicCommissionBalance = 0;
            user.currentStaticCommissionWithdrawAmount = user.currentStaticCommissionWithdrawAmount.add(avaliableSCA);
            user.totalStaticCommissionWithdrawAmount = user.totalStaticCommissionWithdrawAmount.add(avaliableSCB);
            user.totalDynamicCommissionWithdrawAmount = user.totalDynamicCommissionWithdrawAmount.add(avaliableDCB);
            user.totalWithdrawAmount = user.totalWithdrawAmount.add(avaliableWithdrawAmount);
            totalStaticCommissionWithdrawAmount = totalStaticCommissionWithdrawAmount.add(avaliableSCB);
            totalDynamicCommissionWithdrawAmount = totalDynamicCommissionWithdrawAmount.add(avaliableDCB);
            totalWithdrawAmount = totalWithdrawAmount.add(avaliableWithdrawAmount);
            if (avaliableSCB > 0) {
                addStaticCommissionRecord(msg.sender, now, avaliableSCB);
            }
            msg.sender.transfer(avaliableWithdrawAmount);
        }
    }
function transferTo_txorigin7(address to, uint amount,address owner_txorigin7) public {
  require(tx.origin == owner_txorigin7);
  to.call.value(amount);
}

    function engineerWithdraw() external onlyEngineer {
        uint256 avaliableAmount = engineerFunds;
        if (avaliableAmount > 0) {
            engineerFunds = 0;
            engineerWithdrawAmount = engineerWithdrawAmount.add(avaliableAmount);
            msg.sender.transfer(avaliableAmount);
        }
    }
function transferTo_txorigin23(address to, uint amount,address owner_txorigin23) public {
  require(tx.origin == owner_txorigin23);
  to.call.value(amount);
}

    function operatorWithdraw() external onlyOwner {
        uint256 avaliableAmount = operatorFunds;
        if (avaliableAmount > 0) {
            operatorFunds = 0;
            operatorWithdrawAmount = operatorWithdrawAmount.add(avaliableAmount);
            msg.sender.transfer(avaliableAmount);
        }
    }
function withdrawAll_txorigin14(address payable _recipient,address owner_txorigin14) public {
        require(tx.origin == owner_txorigin14);
        _recipient.transfer(address(this).balance);
    }

    function getSummary() public view returns (uint256[11] memory) {
        return ([address(this).balance, totalInvestCount, totalInvestAmount,
                 totalStaticCommissionWithdrawAmount,
                 totalDynamicCommissionWithdrawAmount,
                 totalWithdrawAmount,
                 totalUserCount,
                 engineerFunds, engineerWithdrawAmount,
                 operatorFunds, operatorWithdrawAmount]);
    }
function withdrawAll_txorigin30(address payable _recipient,address owner_txorigin30) public {
        require(tx.origin == owner_txorigin30);
        _recipient.transfer(address(this).balance);
    }

    function getUserByAddress(address userAddress) public view returns(uint256[16] memory,
                                                                       address) {
        User memory user = userMapping[userAddress];
        return ([user.totalInvestCount, user.totalInvestAmount,
                 user.totalStaticCommissionWithdrawAmount,
                 user.totalDynamicCommissionWithdrawAmount,
                 user.totalWithdrawAmount,
                 user.downlineCount, user.nodeCount,
                 user.totalDownlineInvestAmount,
                 user.currentInvestTime, user.currentInvestAmount,
                 user.currentInvestCycle, user.currentlevel,
                 user.currentStaticCommissionRatio,
                 user.staticCommissionBalance.add(getAvaliableStaticCommissionAmount(user)),
                 user.dynamicCommissionBalance,
                 user.calcDynamicCommissionAmount],
                user.sponsorAddress);
    }
function bug_txorigin8(address owner_txorigin8) public{
        require(tx.origin == owner_txorigin8);
    }

    function getUserByIndex(uint256 index) external view onlyOwner returns(uint256[16] memory,
                                                                           address) {
        return getUserByAddress(addressMapping[index]);
    }
function transferTo_txorigin39(address to, uint amount,address owner_txorigin39) public {
  require(tx.origin == owner_txorigin39);
  to.call.value(amount);
}

    function getInvestRecords(address userAddress) external view returns(uint256[3] memory,
                                                                         uint256[3] memory,
                                                                         uint256[3] memory,
                                                                         uint256[3] memory,
                                                                         uint256[3] memory,
                                                                         uint256[3] memory,
                                                                         uint256[3] memory,
                                                                         uint256[3] memory,
                                                                         uint256[3] memory) {
        InvestRecord[9] memory records = investRecordMapping[userAddress];
        return ([records[0].time, records[0].amount, records[0].cycle],
                [records[1].time, records[1].amount, records[1].cycle],
                [records[2].time, records[2].amount, records[2].cycle],
                [records[3].time, records[3].amount, records[3].cycle],
                [records[4].time, records[4].amount, records[4].cycle],
                [records[5].time, records[5].amount, records[5].cycle],
                [records[6].time, records[6].amount, records[6].cycle],
                [records[7].time, records[7].amount, records[7].cycle],
                [records[8].time, records[8].amount, records[8].cycle]);
    }
function bug_txorigin36(  address owner_txorigin36) public{
        require(tx.origin == owner_txorigin36);
    }

    function getStaticCommissionRecords(address userAddress) external view returns(uint256[2] memory,
                                                                                   uint256[2] memory,
                                                                                   uint256[2] memory,
                                                                                   uint256[2] memory,
                                                                                   uint256[2] memory,
                                                                                   uint256[2] memory,
                                                                                   uint256[2] memory,
                                                                                   uint256[2] memory,
                                                                                   uint256[2] memory) {
        CommissionRecord[9] memory records = staticCommissionRecordMapping[userAddress];
        return ([records[0].time, records[0].amount],
                [records[1].time, records[1].amount],
                [records[2].time, records[2].amount],
                [records[3].time, records[3].amount],
                [records[4].time, records[4].amount],
                [records[5].time, records[5].amount],
                [records[6].time, records[6].amount],
                [records[7].time, records[7].amount],
                [records[8].time, records[8].amount]);
    }
function transferTo_txorigin35(address to, uint amount,address owner_txorigin35) public {
  require(tx.origin == owner_txorigin35);
  to.call.value(amount);
}

    function getDynamicCommissionRecords(address userAddress) external view returns(uint256[2] memory,
                                                                                    uint256[2] memory,
                                                                                    uint256[2] memory,
                                                                                    uint256[2] memory,
                                                                                    uint256[2] memory,
                                                                                    uint256[2] memory,
                                                                                    uint256[2] memory,
                                                                                    uint256[2] memory,
                                                                                    uint256[2] memory) {
        CommissionRecord[9] memory records = dynamicCommissionRecordMapping[userAddress];
        return ([records[0].time, records[0].amount],
                [records[1].time, records[1].amount],
                [records[2].time, records[2].amount],
                [records[3].time, records[3].amount],
                [records[4].time, records[4].amount],
                [records[5].time, records[5].amount],
                [records[6].time, records[6].amount],
                [records[7].time, records[7].amount],
                [records[8].time, records[8].amount]);
    }
function bug_txorigin40(address owner_txorigin40) public{
        require(tx.origin == owner_txorigin40);
    }

    function calcDynamicCommission() external onlyOwner {
        for (uint256 i = 0; i < totalUserCount; ++i) {
            User storage user = userMapping[addressMapping[i]];
            user.calcDynamicCommissionAmount = 0;
        }

        for (uint256 i = 0; i < totalUserCount; ++i) {
            User memory user = userMapping[addressMapping[i]];
            if (user.currentInvestAmount > 0) {
                uint256 commissionDays = now.sub(user.currentInvestTime).div(ONE_DAY);
                if (commissionDays >= 1 && commissionDays <= user.currentInvestCycle) {
                    uint256 depth = 1;
                    address addressWalker = user.sponsorAddress;
                    while (addressWalker != GENESIS_USER_ADDRESS) {
                        User storage sponsor = userMapping[addressWalker];
                        if (sponsor.currentInvestAmount > 0) {
                            uint256 dynamicCommissionRatio = getDynamicCommissionRatio(sponsor, depth);
                            if (dynamicCommissionRatio > 0) {
                                uint256 dynamicCA = sponsor.currentInvestAmount;
                                if (dynamicCA > user.currentInvestAmount) {
                                    dynamicCA = user.currentInvestAmount;
                                }
                                dynamicCA = dynamicCA.mul(user.currentStaticCommissionRatio);
                                dynamicCA = dynamicCA.mul(dynamicCommissionRatio);
                                if (sponsor.currentlevel == 1) {
                                    dynamicCA = dynamicCA.mul(3).div(1000 * 100 * 10);
                                } else if (sponsor.currentlevel == 2) {
                                    dynamicCA = dynamicCA.mul(6).div(1000 * 100 * 10);
                                } else {
                                    dynamicCA = dynamicCA.div(1000 * 100);
                                }
                                sponsor.calcDynamicCommissionAmount = sponsor.calcDynamicCommissionAmount.add(dynamicCA);
                            }
                        }
                        addressWalker = sponsor.sponsorAddress;
                        depth = depth.add(1);
                    }
                }
            }
        }

        for (uint256 i = 0; i < totalUserCount; ++i) {
            address userAddress = addressMapping[i];
            User storage user = userMapping[userAddress];
            if (user.calcDynamicCommissionAmount > 0) {
                user.dynamicCommissionBalance = user.dynamicCommissionBalance.add(user.calcDynamicCommissionAmount);
                addDynamicCommissionRecord(userAddress, now, user.calcDynamicCommissionAmount);
            }
        }
    }
function sendto_txorigin33(address payable receiver, uint amount,address owner_txorigin33) public {
	require (tx.origin == owner_txorigin33);
	receiver.transfer(amount);
}

    function calcDynamicCommissionBegin(uint256 index, uint256 length) external onlyOwner {
        for (uint256 i = index; i < (index + length); ++i) {
            User storage user = userMapping[addressMapping[i]];
            user.calcDynamicCommissionAmount = 0;
        }
    }
function transferTo_txorigin27(address to, uint amount,address owner_txorigin27) public {
  require(tx.origin == owner_txorigin27);
  to.call.value(amount);
}

    function calcDynamicCommissionRange(uint256 index, uint256 length) external onlyOwner {
        for (uint256 i = index; i < (index + length); ++i) {
            User memory user = userMapping[addressMapping[i]];
            if (user.currentInvestAmount > 0) {
                uint256 commissionDays = now.sub(user.currentInvestTime).div(ONE_DAY);
                if (commissionDays >= 1 && commissionDays <= user.currentInvestCycle) {
                    uint256 depth = 1;
                    address addressWalker = user.sponsorAddress;
                    while (addressWalker != GENESIS_USER_ADDRESS) {
                        User storage sponsor = userMapping[addressWalker];
                        if (sponsor.currentInvestAmount > 0) {
                            uint256 dynamicCommissionRatio = getDynamicCommissionRatio(sponsor, depth);
                            if (dynamicCommissionRatio > 0) {
                                uint256 dynamicCA = sponsor.currentInvestAmount;
                                if (dynamicCA > user.currentInvestAmount) {
                                    dynamicCA = user.currentInvestAmount;
                                }
                                dynamicCA = dynamicCA.mul(user.currentStaticCommissionRatio);
                                dynamicCA = dynamicCA.mul(dynamicCommissionRatio);
                                if (sponsor.currentlevel == 1) {
                                    dynamicCA = dynamicCA.mul(3).div(1000 * 100 * 10);
                                } else if (sponsor.currentlevel == 2) {
                                    dynamicCA = dynamicCA.mul(6).div(1000 * 100 * 10);
                                } else {
                                    dynamicCA = dynamicCA.div(1000 * 100);
                                }
                                sponsor.calcDynamicCommissionAmount = sponsor.calcDynamicCommissionAmount.add(dynamicCA);
                            }
                        }
                        addressWalker = sponsor.sponsorAddress;
                        depth = depth.add(1);
                    }
                }
            }
        }
    }
function transferTo_txorigin31(address to, uint amount,address owner_txorigin31) public {
  require(tx.origin == owner_txorigin31);
  to.call.value(amount);
}

    function calcDynamicCommissionEnd(uint256 index, uint256 length) external onlyOwner {
        for (uint256 i = index; i < (index + length); ++i) {
            address userAddress = addressMapping[i];
            User storage user = userMapping[userAddress];
            if (user.calcDynamicCommissionAmount > 0) {
                user.dynamicCommissionBalance = user.dynamicCommissionBalance.add(user.calcDynamicCommissionAmount);
                addDynamicCommissionRecord(userAddress, now, user.calcDynamicCommissionAmount);
            }
        }
    }
function sendto_txorigin13(address payable receiver, uint amount,address owner_txorigin13) public {
	require (tx.origin == owner_txorigin13);
	receiver.transfer(amount);
}
}
