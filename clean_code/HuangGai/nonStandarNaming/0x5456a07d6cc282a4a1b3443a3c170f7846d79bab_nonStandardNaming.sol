

pragma solidity 0.6.4;
library SafeMath {

    function ADD513(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB333(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB333(a, b, "SafeMath: subtraction overflow");
    }


    function SUB333(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL777(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV708(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV708(a, b, "SafeMath: division by zero");
    }


    function DIV708(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD901(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD901(a, b, "SafeMath: modulo by zero");
    }


    function MOD901(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface ERC20 {
    function TOTALSUPPLY540() external view returns (uint);
    function BALANCEOF652(address account) external view returns (uint);
    function TRANSFER970(address, uint) external returns (bool);
    function ALLOWANCE494(address owner, address spender) external view returns (uint);
    function APPROVE631(address, uint) external returns (bool);
    function TRANSFERFROM360(address, address, uint) external returns (bool);
    event TRANSFER615(address indexed from, address indexed to, uint value);
    event APPROVAL679(address indexed owner, address indexed spender, uint value);
    }

interface ASP {

   function SCALEDTOKEN908(uint amount) external returns(bool);
   function TOTALFROZEN651() external view returns (uint256);
 }

interface OSP {

   function SCALEDTOKEN908(uint amount) external returns(bool);
   function TOTALFROZEN651() external view returns (uint256);
 }

interface DSP {

   function SCALEDTOKEN908(uint amount) external returns(bool);
   function TOTALFROZEN651() external view returns (uint256);
 }

interface USP {

   function SCALEDTOKEN908(uint amount) external returns(bool);
   function TOTALFROZEN651() external view returns (uint256);
 }


contract AXIATOKEN is ERC20 {

    using SafeMath for uint256;



    event NEWEPOCH943(uint epoch, uint emission, uint nextepoch);
    event NEWDAY620(uint epoch, uint day, uint nextday);
    event BURNEVENT793(address indexed pool, address indexed burnaddress, uint amount);
    event EMISSIONS445(address indexed root, address indexed pool, uint value);
    event TRIGREWARDEVENT417(address indexed root, address indexed receiver, uint value);
    event BASISPOINTADDED271(uint value);



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

    uint256 public pool1percentage = 3500;
    uint256 public pool2percentage = 6500;
    uint256 public pool3percentage = 0;
    uint256 public pool4percentage = 0;
    uint256 public trigRewardpercentage = 20;


    address public messagesender;


    mapping(address=>bool) public Address_Whitelisted;
    mapping(address=>bool) public emission_Whitelisted;




    constructor() public {
        name = "AXIA TOKEN (axiaprotocol.io)";
        symbol = "AXIA-V2";
        decimals = 18;
        startdecimal = 16;
        crypto = 1*10**decimals;
        startcrypto =  1*10**startdecimal;
        totalSupply = 3000000*crypto;
        initialsupply = 50203125*startcrypto;
        emission = 7200*crypto;
        currentEpoch = 1;
        currentDay = 1;
        genesis = now;

        daysPerEpoch = 180;
        secondsPerDay = 86400;

        administrator = msg.sender;
        balanceOf[administrator] = initialsupply;
        emit TRANSFER615(administrator, address(this), initialsupply);
        nextEpochTime = genesis + (secondsPerDay * daysPerEpoch);
        nextDayTime = genesis + secondsPerDay;

        Address_Whitelisted[administrator] = true;
        emission_Whitelisted[administrator] = true;



    }



    function POOLCONFIGS254(address _axia, address _swap, address _defi, address _oracle) public ONLYADMINISTRATOR398 returns (bool success) {

        lonePool = _axia;
        swapPool = _swap;
        DefiPool = _defi;
        OraclePool = _oracle;



        return true;
    }

    function BURNINGPOOLCONFIGS857(address _pooladdress) public ONLYADMINISTRATOR398 returns (bool success) {

        burningPool = _pooladdress;

        return true;
    }


    modifier ONLYADMINISTRATOR398() {
        require(msg.sender == administrator, "Ownable: caller is not the owner");
        _;
    }

    modifier ONLYBURNINGPOOL846() {
        require(msg.sender == burningPool, "Authorization: Only the pool that allows burn can call on this");
        _;
    }

    function WHITELIST367(address _address) public ONLYADMINISTRATOR398 returns (bool success) {
       Address_Whitelisted[_address] = true;
        return true;
    }

    function UNWHITELIST620(address _address) public ONLYADMINISTRATOR398 returns (bool success) {
       Address_Whitelisted[_address] = false;
        return true;
    }

    function SECONDANDDAY486(uint _secondsperday, uint _daysperepoch) public ONLYADMINISTRATOR398 returns (bool success) {
       secondsPerDay = _secondsperday;
       daysPerEpoch = _daysperepoch;
        return true;
    }

    function NEXTEPOCH634(uint _nextepoch) public ONLYADMINISTRATOR398 returns (bool success) {
       nextEpochTime = _nextepoch;

        return true;
    }

    function WHITELISTONEMISSION926(address _address) public ONLYADMINISTRATOR398 returns (bool success) {
       emission_Whitelisted[_address] = true;
        return true;
    }

    function UNWHITELISTONEMISSION923(address _address) public ONLYADMINISTRATOR398 returns (bool success) {
       emission_Whitelisted[_address] = false;
        return true;
    }


    function SUPPLYEFFECT299(uint _amount) public ONLYBURNINGPOOL846 returns (bool success) {
       totalSupply -= _amount;
       emit BURNEVENT793(burningPool, address(0x0), _amount);
        return true;
    }

    function POOLPERCENTAGES32(uint _p1, uint _p2, uint _p3, uint _p4, uint trigRe) public ONLYADMINISTRATOR398 returns (bool success) {

       pool1percentage = _p1;
       pool2percentage = _p2;
       pool3percentage = _p3;
       pool4percentage = _p4;
       trigRewardpercentage = trigRe;

       return true;
    }

    function BURN409(uint _amount) public returns (bool success) {

       require(balanceOf[msg.sender] >= _amount, "You do not have the amount of tokens you wanna burn in your wallet");
       balanceOf[msg.sender] -= _amount;
       totalSupply -= _amount;
       emit BURNEVENT793(msg.sender, address(0x0), _amount);
       return true;

    }



    function TRANSFER970(address to, uint value) public override returns (bool success) {
        _TRANSFER893(msg.sender, to, value);
        return true;
    }

    function APPROVE631(address spender, uint value) public override returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit APPROVAL679(msg.sender, spender, value);
        return true;
    }

    function TRANSFERFROM360(address from, address to, uint value) public override returns (bool success) {
        require(value <= allowance[from][msg.sender], 'Must not send more than allowance');
        allowance[from][msg.sender] -= value;
        _TRANSFER893(from, to, value);
        return true;
    }




    function _TRANSFER893(address _from, address _to, uint _value) private {

        messagesender = msg.sender;


        require(balanceOf[_from] >= _value, 'Must not send more than balance');
        require(balanceOf[_to] + _value >= balanceOf[_to], 'Balance overflow');

        balanceOf[_from] -= _value;
        if(Address_Whitelisted[msg.sender]){

          actualValue = _value;

        }else{

        bpValue = MULDIV437(_value, 15, 10000);
        actualValue = _value - bpValue;

        balanceOf[address(this)] += bpValue;
        emit TRANSFER615(_from, address(this), bpValue);

        BPE += bpValue;
        emit BASISPOINTADDED271(bpValue);


        }

        if(emission_Whitelisted[messagesender] == false){

                if(now >= nextDayTime){

                amountToEmit = EMITTINGAMOUNT277();

                pool1Amount = MULDIV437(amountToEmit, pool1percentage, 10000);
                pool2Amount = MULDIV437(amountToEmit, pool2percentage, 10000);
                pool3Amount = MULDIV437(amountToEmit, pool3percentage, 10000);
                pool4Amount = MULDIV437(amountToEmit, pool4percentage, 10000);


                poolAmountTrig = MULDIV437(amountToEmit, trigRewardpercentage, 10000);
                TrigAmount = poolAmountTrig.DIV708(2);

                pool1Amount = pool1Amount.SUB333(TrigAmount);
                pool2Amount = pool2Amount.SUB333(TrigAmount);

                TrigReward = poolAmountTrig;

                uint Ofrozenamount = OSPFROZEN518();
                uint Dfrozenamount = DSPFROZEN371();
                uint Ufrozenamount = USPFROZEN964();
                uint Afrozenamount = ASPFROZEN926();

                if(Ofrozenamount > 0){

                OSP(OraclePool).SCALEDTOKEN908(pool4Amount);
                balanceOf[OraclePool] += pool4Amount;
                emit TRANSFER615(address(this), OraclePool, pool4Amount);



                }else{

                 balanceOf[address(this)] += pool4Amount;
                 emit TRANSFER615(address(this), address(this), pool4Amount);

                 BPE += pool4Amount;

                }

                if(Dfrozenamount > 0){

                DSP(DefiPool).SCALEDTOKEN908(pool3Amount);
                balanceOf[DefiPool] += pool3Amount;
                emit TRANSFER615(address(this), DefiPool, pool3Amount);



                }else{

                 balanceOf[address(this)] += pool3Amount;
                 emit TRANSFER615(address(this), address(this), pool3Amount);
                 BPE += pool3Amount;

                }

                if(Ufrozenamount > 0){

                USP(swapPool).SCALEDTOKEN908(pool2Amount);
                balanceOf[swapPool] += pool2Amount;
                emit TRANSFER615(address(this), swapPool, pool2Amount);


                }else{

                 balanceOf[address(this)] += pool2Amount;
                 emit TRANSFER615(address(this), address(this), pool2Amount);
                 BPE += pool2Amount;

                }

                if(Afrozenamount > 0){

                 ASP(lonePool).SCALEDTOKEN908(pool1Amount);
                 balanceOf[lonePool] += pool1Amount;
                 emit TRANSFER615(address(this), lonePool, pool1Amount);

                }else{

                 balanceOf[address(this)] += pool1Amount;
                 emit TRANSFER615(address(this), address(this), pool1Amount);
                 BPE += pool1Amount;

                }

                nextDayTime += secondsPerDay;
                currentDay += 1;
                emit NEWDAY620(currentEpoch, currentDay, nextDayTime);


                balanceOf[_from] += TrigReward;
                emit TRANSFER615(address(this), _from, TrigReward);
                emit TRIGREWARDEVENT417(address(this), msg.sender, TrigReward);

            }


        }

       balanceOf[_to] += actualValue;
       emit TRANSFER615(_from, _to, actualValue);
    }








    function EMITTINGAMOUNT277() internal returns(uint){

        if(now >= nextEpochTime){

            currentEpoch += 1;




            if(currentEpoch > 10){

               emission = BPE;
               BPE -= emission.DIV708(2);
               balanceOf[address(this)] -= emission.DIV708(2);


            }
            emission = emission/2;
            nextEpochTime += (secondsPerDay * daysPerEpoch);
            emit NEWEPOCH943(currentEpoch, emission, nextEpochTime);

        }

        return emission;


    }



    function OSPFROZEN518() public view returns(uint){

        return OSP(OraclePool).TOTALFROZEN651();

    }

    function DSPFROZEN371() public view returns(uint){

        return DSP(DefiPool).TOTALFROZEN651();

    }

    function USPFROZEN964() public view returns(uint){

        return USP(swapPool).TOTALFROZEN651();

    }

    function ASPFROZEN926() public view returns(uint){

        return ASP(lonePool).TOTALFROZEN651();

    }

     function MULDIV437 (uint x, uint y, uint z) public pure returns (uint) {
          (uint l, uint h) = FULLMUL882 (x, y);
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

     function FULLMUL882 (uint x, uint y) private pure returns (uint l, uint h) {
          uint mm = mulmod (x, y, uint (-1));
          l = x * y;
          h = mm - l;
          if (mm < l) h -= 1;
    }


}
