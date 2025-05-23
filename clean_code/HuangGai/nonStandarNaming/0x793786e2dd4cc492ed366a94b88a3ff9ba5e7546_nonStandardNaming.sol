

pragma solidity 0.6.4;
library SafeMath {

    function ADD734(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB708(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB708(a, b, "SafeMath: subtraction overflow");
    }


    function SUB708(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL870(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV913(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV913(a, b, "SafeMath: division by zero");
    }


    function DIV913(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD299(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD299(a, b, "SafeMath: modulo by zero");
    }


    function MOD299(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface ERC20 {
    function TOTALSUPPLY383() external view returns (uint);
    function BALANCEOF898(address account) external view returns (uint);
    function TRANSFER281(address, uint) external returns (bool);
    function ALLOWANCE825(address owner, address spender) external view returns (uint);
    function APPROVE479(address, uint) external returns (bool);
    function TRANSFERFROM887(address, address, uint) external returns (bool);
    event TRANSFER469(address indexed from, address indexed to, uint value);
    event APPROVAL108(address indexed owner, address indexed spender, uint value);
    }

interface ASP {

   function SCALEDTOKEN417(uint amount) external returns(bool);
   function TOTALFROZEN69() external view returns (uint256);
 }

interface OSP {

   function SCALEDTOKEN417(uint amount) external returns(bool);
   function TOTALFROZEN69() external view returns (uint256);
 }

interface DSP {

   function SCALEDTOKEN417(uint amount) external returns(bool);
   function TOTALFROZEN69() external view returns (uint256);
 }

interface USP {

   function SCALEDTOKEN417(uint amount) external returns(bool);
   function TOTALFROZEN69() external view returns (uint256);
 }


contract AXIATOKEN is ERC20 {

    using SafeMath for uint256;



    event NEWEPOCH820(uint epoch, uint emission, uint nextepoch);
    event NEWDAY953(uint epoch, uint day, uint nextday);
    event BURNEVENT252(address indexed pool, address indexed burnaddress, uint amount);
    event EMISSIONS333(address indexed root, address indexed pool, uint value);
    event TRIGREWARDEVENT379(address indexed root, address indexed receiver, uint value);
    event BASISPOINTADDED397(uint value);



    string public name;
    string public symbol;
    uint public decimals;
    uint public startdecimal;
    uint public override totalSupply;
    uint public initialsupply;



    address public lonePool;
    address public swapPool;
    address public DefiPool;
    address public OraclePool;

    address public burningPool;

    uint public pool1Amount;
    uint public pool2Amount;
    uint public pool3Amount;
    uint public pool4Amount;
    uint public basisAmount;
    uint public poolAmountTrig;


    uint public TrigAmount;



    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;



    uint crypto;
    uint startcrypto;
    uint public emission;
    uint public currentEpoch;
    uint public currentDay;
    uint public daysPerEpoch;
    uint public secondsPerDay;
    uint public genesis;
    uint public nextEpochTime;
    uint public nextDayTime;
    uint public amountToEmit;
    uint public BPE;


    uint public bpValue;
    uint public actualValue;
    uint public TrigReward;
    uint public burnAmount;
    address administrator;
    uint totalEmitted;

    uint256 public pool1percentage = 500;
    uint256 public pool2percentage = 4500;
    uint256 public pool3percentage = 2500;
    uint256 public pool4percentage = 2500;
    uint256 public basispercentage = 500;
    uint256 public trigRewardpercentage = 20;


    address public messagesender;



    mapping(address=>bool) public emission_Whitelisted;




    constructor() public {
        name = "AXIA TOKEN (axiaprotocol.io)";
        symbol = "AXIAv3";
        decimals = 18;
        startdecimal = 16;
        crypto = 1*10**decimals;
        startcrypto =  1*10**startdecimal;
        totalSupply = 3800000*crypto;
        initialsupply = 120000000*startcrypto;
        emission = 7200*crypto;
        currentEpoch = 1;
        currentDay = 1;
        genesis = now;

        daysPerEpoch = 180;
        secondsPerDay = 86400;

        administrator = msg.sender;
        balanceOf[administrator] = initialsupply;
        emit TRANSFER469(administrator, address(this), initialsupply);
        nextEpochTime = genesis + (secondsPerDay * daysPerEpoch);
        nextDayTime = genesis + secondsPerDay;

        emission_Whitelisted[administrator] = true;



    }



    function POOLCONFIGS766(address _axia, address _swap, address _defi, address _oracle) public ONLYADMINISTRATOR560 returns (bool success) {

        lonePool = _axia;
        swapPool = _swap;
        DefiPool = _defi;
        OraclePool = _oracle;



        return true;
    }

    function BURNINGPOOLCONFIGS680(address _pooladdress) public ONLYADMINISTRATOR560 returns (bool success) {

        burningPool = _pooladdress;

        return true;
    }


    modifier ONLYADMINISTRATOR560() {
        require(msg.sender == administrator, "Ownable: caller is not the owner");
        _;
    }

    modifier ONLYBURNINGPOOL415() {
        require(msg.sender == burningPool, "Authorization: Only the pool that allows burn can call on this");
        _;
    }

    function SECONDANDDAY302(uint _secondsperday, uint _daysperepoch) public ONLYADMINISTRATOR560 returns (bool success) {
       secondsPerDay = _secondsperday;
       daysPerEpoch = _daysperepoch;
        return true;
    }

    function NEXTEPOCH903(uint _nextepoch) public ONLYADMINISTRATOR560 returns (bool success) {
       nextEpochTime = _nextepoch;

        return true;
    }

    function WHITELISTONEMISSION689(address _address) public ONLYADMINISTRATOR560 returns (bool success) {
       emission_Whitelisted[_address] = true;
        return true;
    }

    function UNWHITELISTONEMISSION147(address _address) public ONLYADMINISTRATOR560 returns (bool success) {
       emission_Whitelisted[_address] = false;
        return true;
    }


    function SUPPLYEFFECT336(uint _amount) public ONLYBURNINGPOOL415 returns (bool success) {
       totalSupply -= _amount;
       emit BURNEVENT252(burningPool, address(0x0), _amount);
        return true;
    }

    function POOLPERCENTAGES952(uint _p1, uint _p2, uint _p3, uint _p4, uint _basispercent, uint trigRe) public ONLYADMINISTRATOR560 returns (bool success) {

       pool1percentage = _p1;
       pool2percentage = _p2;
       pool3percentage = _p3;
       pool4percentage = _p4;
       basispercentage = _basispercent;
       trigRewardpercentage = trigRe;

       return true;
    }

    function BURN66(uint _amount) public returns (bool success) {

       require(balanceOf[msg.sender] >= _amount, "You do not have the amount of tokens you wanna burn in your wallet");
       balanceOf[msg.sender] -= _amount;
       totalSupply -= _amount;
       emit BURNEVENT252(msg.sender, address(0x0), _amount);
       return true;

    }



    function TRANSFER281(address to, uint value) public override returns (bool success) {
        _TRANSFER842(msg.sender, to, value);
        return true;
    }

    function APPROVE479(address spender, uint value) public override returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit APPROVAL108(msg.sender, spender, value);
        return true;
    }

    function TRANSFERFROM887(address from, address to, uint value) public override returns (bool success) {
        require(value <= allowance[from][msg.sender], 'Must not send more than allowance');
        allowance[from][msg.sender] -= value;
        _TRANSFER842(from, to, value);
        return true;
    }




    function _TRANSFER842(address _from, address _to, uint _value) private {

        messagesender = msg.sender;


        require(balanceOf[_from] >= _value, 'Must not send more than balance');
        require(balanceOf[_to] + _value >= balanceOf[_to], 'Balance overflow');

        balanceOf[_from] -= _value;


        if(emission_Whitelisted[messagesender] == false){

                if(now >= nextDayTime){

                amountToEmit = EMITTINGAMOUNT270();


                uint basisAmountQuota = MULDIV481(amountToEmit, basispercentage, 10000);
                amountToEmit = amountToEmit - basisAmountQuota;
                basisAmount = basisAmountQuota;

                pool1Amount = MULDIV481(amountToEmit, pool1percentage, 10000);
                pool2Amount = MULDIV481(amountToEmit, pool2percentage, 10000);
                pool3Amount = MULDIV481(amountToEmit, pool3percentage, 10000);
                pool4Amount = MULDIV481(amountToEmit, pool4percentage, 10000);



                poolAmountTrig = MULDIV481(amountToEmit, trigRewardpercentage, 10000);
                TrigAmount = poolAmountTrig.DIV913(2);

                pool1Amount = pool1Amount.SUB708(TrigAmount);
                pool2Amount = pool2Amount.SUB708(TrigAmount);

                TrigReward = poolAmountTrig;

                uint Ofrozenamount = OSPFROZEN44();
                uint Dfrozenamount = DSPFROZEN33();
                uint Ufrozenamount = USPFROZEN49();
                uint Afrozenamount = ASPFROZEN756();

                balanceOf[address(this)] += basisAmount;
                emit TRANSFER469(address(this), address(this), basisAmount);
                BPE += basisAmount;


                if(Ofrozenamount > 0){

                OSP(OraclePool).SCALEDTOKEN417(pool4Amount);
                balanceOf[OraclePool] += pool4Amount;
                emit TRANSFER469(address(this), OraclePool, pool4Amount);



                }else{

                 balanceOf[address(this)] += pool4Amount;
                 emit TRANSFER469(address(this), address(this), pool4Amount);

                 BPE += pool4Amount;

                }

                if(Dfrozenamount > 0){

                DSP(DefiPool).SCALEDTOKEN417(pool3Amount);
                balanceOf[DefiPool] += pool3Amount;
                emit TRANSFER469(address(this), DefiPool, pool3Amount);



                }else{

                 balanceOf[address(this)] += pool3Amount;
                 emit TRANSFER469(address(this), address(this), pool3Amount);
                 BPE += pool3Amount;

                }

                if(Ufrozenamount > 0){

                USP(swapPool).SCALEDTOKEN417(pool2Amount);
                balanceOf[swapPool] += pool2Amount;
                emit TRANSFER469(address(this), swapPool, pool2Amount);


                }else{

                 balanceOf[address(this)] += pool2Amount;
                 emit TRANSFER469(address(this), address(this), pool2Amount);
                 BPE += pool2Amount;

                }

                if(Afrozenamount > 0){

                 ASP(lonePool).SCALEDTOKEN417(pool1Amount);
                 balanceOf[lonePool] += pool1Amount;
                 emit TRANSFER469(address(this), lonePool, pool1Amount);

                }else{

                 balanceOf[address(this)] += pool1Amount;
                 emit TRANSFER469(address(this), address(this), pool1Amount);
                 BPE += pool1Amount;

                }

                nextDayTime += secondsPerDay;
                currentDay += 1;
                emit NEWDAY953(currentEpoch, currentDay, nextDayTime);


                balanceOf[_from] += TrigReward;
                emit TRANSFER469(address(this), _from, TrigReward);
                emit TRIGREWARDEVENT379(address(this), msg.sender, TrigReward);

            }


        }

       balanceOf[_to] += _value;
       emit TRANSFER469(_from, _to, _value);
    }








    function EMITTINGAMOUNT270() internal returns(uint){

        if(now >= nextEpochTime){

            currentEpoch += 1;

            if(currentEpoch > 10){

               emission = BPE;
               BPE -= emission.DIV913(2);
               balanceOf[address(this)] -= emission.DIV913(2);


            }
            emission = emission/2;
            nextEpochTime += (secondsPerDay * daysPerEpoch);
            emit NEWEPOCH820(currentEpoch, emission, nextEpochTime);

        }

        return emission;


    }



    function OSPFROZEN44() public view returns(uint){

        return OSP(OraclePool).TOTALFROZEN69();

    }

    function DSPFROZEN33() public view returns(uint){

        return DSP(DefiPool).TOTALFROZEN69();

    }

    function USPFROZEN49() public view returns(uint){

        return USP(swapPool).TOTALFROZEN69();

    }

    function ASPFROZEN756() public view returns(uint){

        return ASP(lonePool).TOTALFROZEN69();

    }

     function MULDIV481 (uint x, uint y, uint z) public pure returns (uint) {
          (uint l, uint h) = FULLMUL130 (x, y);
          assert (h < z);
          uint mm = mulmod (x, y, z);
          if (mm > l) h -= 1;
          l -= mm;
          uint pow2 = z & -z;
          z /= pow2;
          l /= pow2;
          l += h * ((-pow2) / pow2 + 1);
          uint r = 1;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          return l * r;
    }

     function FULLMUL130 (uint x, uint y) private pure returns (uint l, uint h) {
          uint mm = mulmod (x, y, uint (-1));
          l = x * y;
          h = mm - l;
          if (mm < l) h -= 1;
    }


}
