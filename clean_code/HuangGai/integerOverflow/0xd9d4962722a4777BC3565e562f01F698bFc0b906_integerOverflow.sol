
































pragma solidity ^0.5.11;

library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }













    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

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
}

library DataStructs {

        struct DailyRound {
            uint256 startTime;
            uint256 endTime;
            bool ended;
            uint256 pool;
        }

        struct Player {
            uint256 totalInvestment;
            uint256 totalVolumeEth;
            uint256 eventVariable;
            uint256 directReferralIncome;
            uint256 roiReferralIncome;
            uint256 currentInvestedAmount;
            uint256 dailyIncome;
            uint256 lastSettledTime;
            uint256 incomeLimitLeft;
            uint256 investorPoolIncome;
            uint256 sponsorPoolIncome;
            uint256 superIncome;
            uint256 referralCount;
            address referrer;
        }

        struct PlayerDailyRounds {
            uint256 selfInvestment;
            uint256 ethVolume;
        }
}

contract Ether5 {
    using SafeMath for *;

    address public  owner;
    address public  roundStarter;
    uint256 private houseFee = 18;
    uint256 private poolTime = 24 hours;
    uint256 private payoutPeriod = 24 hours;
    uint256 private dailyWinPool = 10;
    uint256 private incomeTimes  = 30;
    uint256 private incomeDivide = 10;
    uint256 public  roundID;
    uint256 public  r1 = 0;
    uint256 public  r2 = 0;
    uint256 public  r3 = 0;
    uint256[3] private awardPercentage;

    mapping (uint => uint) public CYCLE_PRICE;
    mapping (address => bool) public playerExist;
    mapping (uint256 => DataStructs.DailyRound) public round;
    mapping (address => DataStructs.Player) public player;
    mapping (address => mapping (uint256 => DataStructs.PlayerDailyRounds)) public plyrRnds_;



    event registerUserEvent(address indexed _playerAddress, address indexed _referrer);
    event investmentEvent(address indexed _playerAddress, uint256 indexed _amount);
    event referralCommissionEvent(address indexed _playerAddress, address indexed _referrer, uint256 indexed amount, uint256 timeStamp);
    event dailyPayoutEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
    event withdrawEvent(address indexed _playerAddress, uint256 indexed amount, uint256 indexed timeStamp);
    event ownershipTransferred(address indexed owner, address indexed newOwner);

    constructor (address _roundStarter) public {
         owner = msg.sender;
         roundStarter = _roundStarter;
         roundID = 1;
         round[1].startTime = now;
         round[1].endTime = now + poolTime;
         awardPercentage[0] = 50;
         awardPercentage[1] = 30;
         awardPercentage[2] = 20;
    }







    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 100000000000000000, "Minimum contribution amount is 0.1 ETH");
        _;
    }




    modifier isallowedValue(uint256 _eth) {
        require(_eth % 100000000000000000 == 0, "Amount should be in multiple of 0.1 ETH please");
        _;
    }




    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }






    function () external payable {
        playGame(address(0x0));
    }




    function playGame(address _referrer)
    public
    isWithinLimits(msg.value)
    isallowedValue(msg.value)
    payable {

        uint256 amount = msg.value;
        if (playerExist[msg.sender] == false) {

            player[msg.sender].lastSettledTime = now;
            player[msg.sender].currentInvestedAmount = amount;
            player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes).div(incomeDivide);
            player[msg.sender].totalInvestment = amount;
            player[msg.sender].eventVariable = 100 ether;
            playerExist[msg.sender] = true;


            plyrRnds_[msg.sender][roundID].selfInvestment = plyrRnds_[msg.sender][roundID].selfInvestment.add(amount);

            if(

                _referrer != address(0x0) &&


                _referrer != msg.sender &&


                playerExist[_referrer] == true
              ) {
                    player[msg.sender].referrer = _referrer;
                    player[_referrer].referralCount = player[_referrer].referralCount.add(1);
                    player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);
                    plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);

                    referralBonusTransferDirect(msg.sender, amount.mul(20).div(100));
                }
              else {
                  r1 = r1.add(amount.mul(20).div(100));
                  _referrer = address(0x0);
                }
              emit registerUserEvent(msg.sender, _referrer);
            }


            else {

                require(player[msg.sender].incomeLimitLeft == 0, "Oops your limit is still remaining");
                require(amount >= player[msg.sender].currentInvestedAmount, "Cannot invest lesser amount");


                player[msg.sender].lastSettledTime = now;
                player[msg.sender].currentInvestedAmount = amount;
                player[msg.sender].incomeLimitLeft = amount.mul(incomeTimes).div(incomeDivide);
                player[msg.sender].totalInvestment = player[msg.sender].totalInvestment.add(amount);


                plyrRnds_[msg.sender][roundID].selfInvestment = plyrRnds_[msg.sender][roundID].selfInvestment.add(amount);

                if(

                    _referrer != address(0x0) &&

                    _referrer != msg.sender &&

                    playerExist[_referrer] == true
                    )
                    {

                        if(player[msg.sender].referrer != address(0x0))
                            _referrer = player[msg.sender].referrer;
                        else {
                            player[msg.sender].referrer = _referrer;
                            player[_referrer].referralCount = player[_referrer].referralCount.add(1);
                       }

                        player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);
                        plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);


                        referralBonusTransferDirect(msg.sender, amount.mul(20).div(100));
                    }

                    else if(

                        _referrer == address(0x0) &&

                        player[msg.sender].referrer != address(0x0)
                        ) {
                            _referrer = player[msg.sender].referrer;
                            plyrRnds_[_referrer][roundID].ethVolume = plyrRnds_[_referrer][roundID].ethVolume.add(amount);
                            player[_referrer].totalVolumeEth = player[_referrer].totalVolumeEth.add(amount);


                            referralBonusTransferDirect(msg.sender, amount.mul(20).div(100));
                          }
                    else {

                          r1 = r1.add(amount.mul(20).div(100));
                        }
            }

            round[roundID].pool = round[roundID].pool.add(amount.mul(dailyWinPool).div(100));
            player[owner].dailyIncome = player[owner].dailyIncome.add(amount.mul(houseFee).div(100));
            r3 = r3.add(amount.mul(5).div(100));
            emit investmentEvent (msg.sender, amount);

    }

    function referralBonusTransferDirect(address _playerAddress, uint256 amount)
    private
    {
        address _nextReferrer = player[_playerAddress].referrer;
        uint256 _amountLeft = amount.mul(60).div(100);
        uint i;

        for(i=0; i < 10; i++) {

            if (_nextReferrer != address(0x0)) {

                if(i == 0) {
                    if (player[_nextReferrer].incomeLimitLeft >= amount.div(2)) {
                        player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.div(2));
                        player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(amount.div(2));

                        emit referralCommissionEvent(_playerAddress, _nextReferrer, amount.div(2), now);
                    }
                    else if(player[_nextReferrer].incomeLimitLeft !=0) {
                        player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                        r1 = r1.add(amount.div(2).sub(player[_nextReferrer].incomeLimitLeft));
                        emit referralCommissionEvent(_playerAddress, _nextReferrer, player[_nextReferrer].incomeLimitLeft, now);
                        player[_nextReferrer].incomeLimitLeft = 0;
                    }
                    else  {
                        r1 = r1.add(amount.div(2));
                    }
                    _amountLeft = _amountLeft.sub(amount.div(2));
                }

                else if(i == 1 ) {
                    if(player[_nextReferrer].referralCount >= 2) {
                        if (player[_nextReferrer].incomeLimitLeft >= amount.div(10)) {
                            player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.div(10));
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(amount.div(10));

                            emit referralCommissionEvent(_playerAddress, _nextReferrer, amount.div(10), now);
                        }
                        else if(player[_nextReferrer].incomeLimitLeft !=0) {
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                            r1 = r1.add(amount.div(10).sub(player[_nextReferrer].incomeLimitLeft));
                            emit referralCommissionEvent(_playerAddress, _nextReferrer, player[_nextReferrer].incomeLimitLeft, now);
                            player[_nextReferrer].incomeLimitLeft = 0;
                        }
                        else  {
                            r1 = r1.add(amount.div(10));
                        }
                    }
                    else{
                        r1 = r1.add(amount.div(10));
                    }
                    _amountLeft = _amountLeft.sub(amount.div(10));
                }

                else {
                    if(player[_nextReferrer].referralCount >= i+1) {
                        if (player[_nextReferrer].incomeLimitLeft >= amount.div(20)) {
                            player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.div(20));
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(amount.div(20));

                            emit referralCommissionEvent(_playerAddress, _nextReferrer, amount.div(20), now);

                        }
                        else if(player[_nextReferrer].incomeLimitLeft !=0) {
                            player[_nextReferrer].directReferralIncome = player[_nextReferrer].directReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                            r1 = r1.add(amount.div(20).sub(player[_nextReferrer].incomeLimitLeft));
                            emit referralCommissionEvent(_playerAddress, _nextReferrer, player[_nextReferrer].incomeLimitLeft, now);
                            player[_nextReferrer].incomeLimitLeft = 0;
                        }
                        else  {
                            r1 = r1.add(amount.div(20));
                        }
                    }
                    else {
                        r1 = r1.add(amount.div(20));
                    }
                }
            }
            else {
                r1 = r1.add((uint(10).sub(i)).mul(amount.div(20)).add(_amountLeft));
                break;
            }
            _nextReferrer = player[_nextReferrer].referrer;
        }
    }



    function referralBonusTransferDailyROI(address _playerAddress, uint256 amount)
    private
    {
        address _nextReferrer = player[_playerAddress].referrer;
        uint256 _amountLeft = amount.div(2);
        uint i;

        for(i=0; i < 20; i++) {

            if (_nextReferrer != address(0x0)) {
                if(i == 0) {
                    if (player[_nextReferrer].incomeLimitLeft >= amount.div(2)) {
                        player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.div(2));
                        player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.div(2));

                        emit referralCommissionEvent(_playerAddress, _nextReferrer, amount.div(2), now);

                    } else if(player[_nextReferrer].incomeLimitLeft !=0) {
                        player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                        r2 = r2.add(amount.div(2).sub(player[_nextReferrer].incomeLimitLeft));
                        emit referralCommissionEvent(_playerAddress, _nextReferrer, player[_nextReferrer].incomeLimitLeft, now);
                        player[_nextReferrer].incomeLimitLeft = 0;

                    }
                    else {
                        r2 = r2.add(amount.div(2));
                    }
                    _amountLeft = _amountLeft.sub(amount.div(2));
                }
                else {
                    if(player[_nextReferrer].referralCount >= i+1) {
                        if (player[_nextReferrer].incomeLimitLeft >= amount.div(20)) {
                            player[_nextReferrer].incomeLimitLeft = player[_nextReferrer].incomeLimitLeft.sub(amount.div(20));
                            player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(amount.div(20));

                            emit referralCommissionEvent(_playerAddress, _nextReferrer, amount.div(20), now);

                        }else if(player[_nextReferrer].incomeLimitLeft !=0) {
                            player[_nextReferrer].roiReferralIncome = player[_nextReferrer].roiReferralIncome.add(player[_nextReferrer].incomeLimitLeft);
                            r2 = r2.add(amount.div(20).sub(player[_nextReferrer].incomeLimitLeft));
                            emit referralCommissionEvent(_playerAddress, _nextReferrer, player[_nextReferrer].incomeLimitLeft, now);
                            player[_nextReferrer].incomeLimitLeft = 0;
                        }
                        else {
                            r2 = r2.add(amount.div(20));
                        }
                    }
                    else {
                         r2 = r2.add(amount.div(20));
                    }
                }
            }
            else {
                if(i==0){
                    r2 = r2.add(amount.mul(145).div(100));
                    break;
                }
                else {
                    r2 = r2.add((uint(20).sub(i)).mul(amount.div(20)).add(_amountLeft));
                    break;
                }

            }
            _nextReferrer = player[_nextReferrer].referrer;
        }
    }



    function settleIncome(address _playerAddress)
    private {


        uint256 remainingTimeForPayout;
        uint256 currInvestedAmount;

        if(now > player[_playerAddress].lastSettledTime + payoutPeriod) {


            uint256 extraTime = now.sub(player[_playerAddress].lastSettledTime);
            uint256 _dailyIncome;

            remainingTimeForPayout = (extraTime.sub((extraTime % payoutPeriod))).div(payoutPeriod);

            currInvestedAmount = player[_playerAddress].currentInvestedAmount;

            _dailyIncome = currInvestedAmount.div(20);

            if (player[_playerAddress].incomeLimitLeft >= _dailyIncome.mul(remainingTimeForPayout)) {
                player[_playerAddress].incomeLimitLeft = player[_playerAddress].incomeLimitLeft.sub(_dailyIncome.mul(remainingTimeForPayout));
                player[_playerAddress].dailyIncome = player[_playerAddress].dailyIncome.add(_dailyIncome.mul(remainingTimeForPayout));
                player[_playerAddress].lastSettledTime = player[_playerAddress].lastSettledTime.add((extraTime.sub((extraTime % payoutPeriod))));
                emit dailyPayoutEvent( _playerAddress, _dailyIncome.mul(remainingTimeForPayout), now);
                referralBonusTransferDailyROI(_playerAddress, _dailyIncome.mul(remainingTimeForPayout));
            }

            else if(player[_playerAddress].incomeLimitLeft !=0) {
                uint256 temp;
                temp = player[_playerAddress].incomeLimitLeft;
                player[_playerAddress].incomeLimitLeft = 0;
                player[_playerAddress].dailyIncome = player[_playerAddress].dailyIncome.add(temp);
                player[_playerAddress].lastSettledTime = now;
                emit dailyPayoutEvent( _playerAddress, temp, now);
                referralBonusTransferDailyROI(_playerAddress, temp);
            }
        }

    }



    function withdrawIncome()
    public {

        address _playerAddress = msg.sender;


        settleIncome(_playerAddress);

        uint256 _earnings =
                    player[_playerAddress].dailyIncome +
                    player[_playerAddress].directReferralIncome +
                    player[_playerAddress].roiReferralIncome;





        if(_earnings > 0) {
            require(address(this).balance >= _earnings, "Contract doesn't have sufficient amount to give you");

            player[_playerAddress].dailyIncome = 0;
            player[_playerAddress].directReferralIncome = 0;
            player[_playerAddress].roiReferralIncome = 0;
            player[_playerAddress].investorPoolIncome = 0;
            player[_playerAddress].sponsorPoolIncome = 0;
            player[_playerAddress].superIncome = 0;

            address(uint160(_playerAddress)).transfer(_earnings);
            emit withdrawEvent(_playerAddress, _earnings, now);
        }
    }



    function startNewRound()
    public
     {
        require(msg.sender == roundStarter,"Oops you can't start the next round");

        uint256 _roundID = roundID;

        uint256 _poolAmount = round[roundID].pool;
        if (now > round[_roundID].endTime && round[_roundID].ended == false) {

            round[_roundID].ended = true;
            round[_roundID].pool = _poolAmount;

                _roundID++;
                roundID++;
                round[_roundID].startTime = now;
                round[_roundID].endTime = now.add(poolTime);
        }
    }



    function getPlayerInfo(address _playerAddress)
    public
    view
    returns(uint256) {

            uint256 remainingTimeForPayout;
            if(playerExist[_playerAddress] == true) {

                if(player[_playerAddress].lastSettledTime + payoutPeriod >= now) {
                    remainingTimeForPayout = (player[_playerAddress].lastSettledTime + payoutPeriod).sub(now);
                }
                else {
                    uint256 temp = now.sub(player[_playerAddress].lastSettledTime);
                    remainingTimeForPayout = payoutPeriod.sub((temp % payoutPeriod));
                }
                return remainingTimeForPayout;
            }
    }


    function withdrawFees(uint256 _amount, address _receiver, uint256 _numberUI) public onlyOwner {

        if(_numberUI == 1 && r1 >= _amount) {
            if(_amount > 0) {
                if(address(this).balance >= _amount) {
                    r1 = r1.sub(_amount);

                    address(uint160(_receiver)).transfer(_amount);
                }
            }
        }
        else if(_numberUI == 2 && r2 >= _amount) {
            if(_amount > 0) {
                if(address(this).balance >= _amount) {
                    r2 = r2.sub(_amount);

                    address(uint160(_receiver)).transfer(_amount);
                }
            }
        }
        else if(_numberUI == 3) {
            player[_receiver].superIncome = player[_receiver].superIncome.add(_amount);

            r3 = r3.sub(_amount);


        }
    }





    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }




    function _transferOwnership(address newOwner) private {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit ownershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
