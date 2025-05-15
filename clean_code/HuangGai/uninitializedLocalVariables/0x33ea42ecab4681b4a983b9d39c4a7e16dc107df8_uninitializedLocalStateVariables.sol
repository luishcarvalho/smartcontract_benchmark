



pragma solidity 0.6.4;
library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c ;

        require(c >= a, "SafeMath: addition overflow");

        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c ;


        return c;
    }











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c ;

        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }













    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c ;



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


    address public pool1;
    address public pool2;
    address public pool3;
    address public pool4;

    uint public pool1Amount;
    uint public pool2Amount;
    uint public pool3Amount;
    uint public poolAmount;



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

    address public messagesender;


    mapping(address=>bool) public Address_Whitelisted;
    mapping(address=>bool) public emission_Whitelisted;




    constructor() public {
        name = "AXIA TOKEN (axiaprotocol.io)";
        symbol = "AXIA";
        decimals = 18;
        startdecimal = 16;
        crypto = 1*10**decimals;
        startcrypto =  1*10**startdecimal;
        totalSupply = 3000000*crypto;
        initialsupply = 40153125*startcrypto;
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



    }



       function poolconfigs(address _oracle, address _defi, address _univ2, address _axia) public onlyAdministrator returns (bool success) {
        pool1 = _oracle;
        pool2 = _defi;
        pool3 = _univ2;
        pool4 = _axia;

        return true;
    }

    modifier onlyAdministrator() {
        require(msg.sender == administrator, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyASP() {
        require(msg.sender == pool4, "Authorization: Only the fourth pool can call on this");
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


    function whitelistOnEmission(address _address) public onlyAdministrator returns (bool success) {
       emission_Whitelisted[_address] = true;
        return true;
    }

    function unwhitelistOnEmission(address _address) public onlyAdministrator returns (bool success) {
       emission_Whitelisted[_address] = false;
        return true;
    }


    function supplyeffect(uint _amount) public onlyASP returns (bool success) {
       totalSupply -= _amount;
       emit BurnEvent(pool4, address(0x0), _amount);
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

                if(now >= nextDayTime){

                amountToEmit = emittingAmount();
                pool1Amount = mulDiv(amountToEmit, 6500, 10000);
                poolAmount = mulDiv(amountToEmit, 20, 10000);

                pool1Amount = pool1Amount.sub(poolAmount);
                pool2Amount = mulDiv(amountToEmit, 2100, 10000);
                pool3Amount = mulDiv(amountToEmit, 1400, 10000);

                TrigReward = poolAmount;

                pool1Amount = pool1Amount.div(2);

                uint Ofrozenamount ;

                uint Dfrozenamount ;

                uint Ufrozenamount ;

                uint Afrozenamount ;


                if(Ofrozenamount > 0){

                OSP(pool1).scaledToken(pool1Amount);
                balanceOf[pool1] += pool1Amount;
                emit Transfer(address(this), pool1, pool1Amount);



                }else{

                 balanceOf[address(this)] += pool1Amount;
                 emit Transfer(address(this), address(this), pool1Amount);

                 BPE += pool1Amount;

                }

                if(Dfrozenamount > 0){

                DSP(pool2).scaledToken(pool1Amount);
                balanceOf[pool2] += pool1Amount;
                emit Transfer(address(this), pool2, pool1Amount);



                }else{

                 balanceOf[address(this)] += pool1Amount;
                 emit Transfer(address(this), address(this), pool1Amount);
                 BPE += pool1Amount;

                }

                if(Ufrozenamount > 0){

                USP(pool3).scaledToken(pool2Amount);
                balanceOf[pool3] += pool2Amount;
                emit Transfer(address(this), pool3, pool2Amount);


                }else{

                 balanceOf[address(this)] += pool2Amount;
                 emit Transfer(address(this), address(this), pool2Amount);
                 BPE += pool2Amount;

                }

                if(Afrozenamount > 0){

                USP(pool4).scaledToken(pool3Amount);
                balanceOf[pool4] += pool3Amount;
                emit Transfer(address(this), pool4, pool3Amount);


                }else{

                 balanceOf[address(this)] += pool3Amount;
                 emit Transfer(address(this), address(this), pool3Amount);
                 BPE += pool3Amount;

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

        if(now >= nextEpochTime){

            currentEpoch += 1;




            if(currentEpoch > 10){

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

        return OSP(pool1).totalFrozen();

    }

    function dspfrozen() public view returns(uint){

        return DSP(pool2).totalFrozen();

    }

    function uspfrozen() public view returns(uint){

        return USP(pool3).totalFrozen();

    }

    function aspfrozen() public view returns(uint){

        return ASP(pool4).totalFrozen();

    }

     function mulDiv (uint x, uint y, uint z) public pure returns (uint) {
          (uint l, uint h) = fullMul (x, y);
          assert (h < z);
          uint mm ;

          if (mm > l) h -= 1;
          l -= mm;
          uint pow2 ;

          z /= pow2;
          l /= pow2;
          l += h * ((-pow2) / pow2 + 1);
          uint r ;

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
          uint mm ;

          l = x * y;
          h = mm - l;
          if (mm < l) h -= 1;
    }


}
