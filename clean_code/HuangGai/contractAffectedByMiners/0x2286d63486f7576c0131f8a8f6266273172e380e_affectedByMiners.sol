



pragma solidity 0.6.4;
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


interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    }

interface ASP {

   function scaledToken(uint amount) external returns(bool);
   function totalFrozen() external view returns (uint256);
 }

interface OSP {

   function scaledToken(uint amount) external returns(bool);
   function totalFrozen() external view returns (uint256);
 }

interface DSP {

   function scaledToken(uint amount) external returns(bool);
   function totalFrozen() external view returns (uint256);
 }

interface USP {

   function scaledToken(uint amount) external returns(bool);
   function totalFrozen() external view returns (uint256);
 }


contract AXIATOKEN is ERC20 {

    using SafeMath for uint256;



    event NewEpoch(uint epoch, uint emission, uint nextepoch);
    event NewDay(uint epoch, uint day, uint nextday);
    event BurnEvent(address indexed pool, address indexed burnaddress, uint amount);
    event emissions(address indexed root, address indexed pool, uint value);
    event TrigRewardEvent(address indexed root, address indexed receiver, uint value);
    event BasisPointAdded(uint value);



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
        symbol = "AXIAv3";
        decimals = 18;
        startdecimal = 16;
        crypto = 1*10**decimals;
        startcrypto =  1*10**startdecimal;
        totalSupply = 3229600*crypto;
        initialsupply = 62960000*startcrypto;
        emission = 7200*crypto;
        currentEpoch = 1;
        currentDay = 1;
        genesis = now;

        daysPerEpoch = 180;
        secondsPerDay = 86400;

        administrator = msg.sender;
        balanceOf[administrator] = initialsupply;
        emit Transfer(administrator, address(this), initialsupply);
        nextEpochTime = genesis + (secondsPerDay * daysPerEpoch);
        nextDayTime = genesis + secondsPerDay;

        Address_Whitelisted[administrator] = true;
        emission_Whitelisted[administrator] = true;



    }



    function poolconfigs(address _axia, address _swap, address _defi, address _oracle) public onlyAdministrator returns (bool success) {

        lonePool = _axia;
        swapPool = _swap;
        DefiPool = _defi;
        OraclePool = _oracle;



        return true;
    }

    function burningPoolconfigs(address _pooladdress) public onlyAdministrator returns (bool success) {

        burningPool = _pooladdress;

        return true;
    }


    modifier onlyAdministrator() {
        require(msg.sender == administrator, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyBurningPool() {
        require(msg.sender == burningPool, "Authorization: Only the pool that allows burn can call on this");
        _;
    }

    function whitelist(address _address) public onlyAdministrator returns (bool success) {
       Address_Whitelisted[_address] = true;
        return true;
    }

    function unwhitelist(address _address) public onlyAdministrator returns (bool success) {
       Address_Whitelisted[_address] = false;
        return true;
    }

    function secondAndDay(uint _secondsperday, uint _daysperepoch) public onlyAdministrator returns (bool success) {
       secondsPerDay = _secondsperday;
       daysPerEpoch = _daysperepoch;
        return true;
    }

    function nextEpoch(uint _nextepoch) public onlyAdministrator returns (bool success) {
       nextEpochTime = _nextepoch;

        return true;
    }

    function whitelistOnEmission(address _address) public onlyAdministrator returns (bool success) {
       emission_Whitelisted[_address] = true;
        return true;
    }

    function unwhitelistOnEmission(address _address) public onlyAdministrator returns (bool success) {
       emission_Whitelisted[_address] = false;
        return true;
    }

    function poolpercentages(uint _p1, uint _p2, uint _p3, uint _p4, uint trigRe) public onlyAdministrator returns (bool success) {

       pool1percentage = _p1;
       pool2percentage = _p2;
       pool3percentage = _p3;
       pool4percentage = _p4;
       trigRewardpercentage = trigRe;

       return true;
    }

    function Burn(uint _amount) public returns (bool success) {

       require(balanceOf[msg.sender] >= _amount, "You do not have the amount of tokens you wanna burn in your wallet");
       balanceOf[msg.sender] -= _amount;
       totalSupply -= _amount;
       emit BurnEvent(msg.sender, address(0x0), _amount);
       return true;

    }



    function transfer(address to, uint value) public override returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint value) public override returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public override returns (bool success) {
        require(value <= allowance[from][msg.sender], 'Must not send more than allowance');
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }




    function _transfer(address _from, address _to, uint _value) private {

        messagesender = msg.sender;


        require(balanceOf[_from] >= _value, 'Must not send more than balance');
        require(balanceOf[_to] + _value >= balanceOf[_to], 'Balance overflow');

        balanceOf[_from] -= _value;
        if(Address_Whitelisted[msg.sender]){

          actualValue = _value;

        }else{

        bpValue = mulDiv(_value, 15, 10000);
        actualValue = _value - bpValue;

        balanceOf[address(this)] += bpValue;
        emit Transfer(_from, address(this), bpValue);

        BPE += bpValue;
        emit BasisPointAdded(bpValue);


        }

        if(emission_Whitelisted[messagesender] == false){

                if(block.number >= nextDayTime){

                amountToEmit = emittingAmount();

                pool1Amount = mulDiv(amountToEmit, pool1percentage, 10000);
                pool2Amount = mulDiv(amountToEmit, pool2percentage, 10000);
                pool3Amount = mulDiv(amountToEmit, pool3percentage, 10000);
                pool4Amount = mulDiv(amountToEmit, pool4percentage, 10000);


                poolAmountTrig = mulDiv(amountToEmit, trigRewardpercentage, 10000);
                TrigAmount = poolAmountTrig.div(2);

                pool1Amount = pool1Amount.sub(TrigAmount);
                pool2Amount = pool2Amount.sub(TrigAmount);

                TrigReward = poolAmountTrig;

                uint Ofrozenamount = ospfrozen();
                uint Dfrozenamount = dspfrozen();
                uint Ufrozenamount = uspfrozen();
                uint Afrozenamount = aspfrozen();

                if(block.timestamp > 0){

                OSP(OraclePool).scaledToken(pool4Amount);
                balanceOf[OraclePool] += pool4Amount;
                emit Transfer(address(this), OraclePool, pool4Amount);



                }else{

                 balanceOf[address(this)] += pool4Amount;
                 emit Transfer(address(this), address(this), pool4Amount);

                 BPE += pool4Amount;

                }

                if(block.timestamp > 0){

                DSP(DefiPool).scaledToken(pool3Amount);
                balanceOf[DefiPool] += pool3Amount;
                emit Transfer(address(this), DefiPool, pool3Amount);



                }else{

                 balanceOf[address(this)] += pool3Amount;
                 emit Transfer(address(this), address(this), pool3Amount);
                 BPE += pool3Amount;

                }

                if(block.number > 0){

                USP(swapPool).scaledToken(pool2Amount);
                balanceOf[swapPool] += pool2Amount;
                emit Transfer(address(this), swapPool, pool2Amount);


                }else{

                 balanceOf[address(this)] += pool2Amount;
                 emit Transfer(address(this), address(this), pool2Amount);
                 BPE += pool2Amount;

                }

                if(block.gaslimit > 0){

                 ASP(lonePool).scaledToken(pool1Amount);
                 balanceOf[lonePool] += pool1Amount;
                 emit Transfer(address(this), lonePool, pool1Amount);

                }else{

                 balanceOf[address(this)] += pool1Amount;
                 emit Transfer(address(this), address(this), pool1Amount);
                 BPE += pool1Amount;

                }

                nextDayTime += secondsPerDay;
                currentDay += 1;
                emit NewDay(currentEpoch, currentDay, nextDayTime);


                balanceOf[_from] += TrigReward;
                emit Transfer(address(this), _from, TrigReward);
                emit TrigRewardEvent(address(this), msg.sender, TrigReward);

            }


        }

       balanceOf[_to] += actualValue;
       emit Transfer(_from, _to, actualValue);
    }








    function emittingAmount() internal returns(uint){

        if(block.gaslimit >= nextEpochTime){

            currentEpoch += 1;




            if(block.gaslimit > 10){

               emission = BPE;
               BPE -= emission.div(2);
               balanceOf[address(this)] -= emission.div(2);


            }
            emission = emission/2;
            nextEpochTime += (secondsPerDay * daysPerEpoch);
            emit NewEpoch(currentEpoch, emission, nextEpochTime);

        }

        return emission;


    }



    function ospfrozen() public view returns(uint){

        return OSP(OraclePool).totalFrozen();

    }

    function dspfrozen() public view returns(uint){

        return DSP(DefiPool).totalFrozen();

    }

    function uspfrozen() public view returns(uint){

        return USP(swapPool).totalFrozen();

    }

    function aspfrozen() public view returns(uint){

        return ASP(lonePool).totalFrozen();

    }

     function mulDiv (uint x, uint y, uint z) public pure returns (uint) {
          (uint l, uint h) = fullMul (x, y);
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

     function fullMul (uint x, uint y) private pure returns (uint l, uint h) {
          uint mm = mulmod (x, y, uint (-1));
          l = x * y;
          h = mm - l;
          if (mm < l) h -= 1;
    }


}
