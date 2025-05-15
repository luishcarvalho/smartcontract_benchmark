



pragma solidity 0.5.17;
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

interface POWER {

   function scaledPower(uint amount) external returns(bool);
   function totalPopping() external view returns (uint256);
 }

interface OPERATORS {

   function scaledOperators(uint amount) external returns(bool);
   function totalPopping() external view returns (uint256);

 }



contract PopcornToken is ERC20 {

    using SafeMath for uint256;



    event BurnEvent(address indexed pool, address indexed burnaddress, uint amount);
    event AddCornEvent(address indexed _from, address indexed pool, uint value);





    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;



    address public pool1;
    address public pool2;

    uint256 public power;
    uint256 public operators;
    uint256 operatorstotalpopping;
    uint256 powertotalpopping;


    mapping(address => uint) public  balanceOf;
    mapping(address => mapping(address => uint)) public  allowance;



    uint corns;
    uint  bValue;
    uint  actualValue;
    uint  burnAmount;
    address administrator;




    mapping(address=>bool) public Whitelisted;




    constructor() public {
        name = "Popcorn Token";
        symbol = "CORN";
        decimals = 18;
        corns = 1*10**decimals;
        totalSupply = 2000000*corns;


        administrator = msg.sender;
        balanceOf[administrator] = totalSupply;
        emit Transfer(administrator, address(this), totalSupply);

        Whitelisted[administrator] = true;



    }



       function machineries(address _power, address _operators) public onlyAdministrator returns (bool success) {

        pool1 = _power;
        pool2 = _operators;

        return true;
    }

    modifier onlyAdministrator() {
        require(msg.sender == administrator, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperators() {
        require(msg.sender == pool2, "Authorization: Only the operators pool can call on this");
        _;
    }

    function whitelist(address _address) public onlyAdministrator returns (bool success) {
       Whitelisted[_address] = true;
        return true;
    }

    function unwhitelist(address _address) public onlyAdministrator returns (bool success) {
      Whitelisted[_address] = false;
        return true;
    }


    function Burn(uint _amount) public returns (bool success) {

       require(balanceOf[msg.sender] >= _amount, "You do not have the amount of tokens you wanna burn in your wallet");
       balanceOf[msg.sender] -= _amount;
       totalSupply -= _amount;
       emit BurnEvent(pool2, address(0x0), _amount);
       return true;

    }




    function transfer(address to, uint value) public  returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }



    function approve(address spender, uint value) public  returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }



    function transferFrom(address from, address to, uint value) public  returns (bool success) {
        require(value <= allowance[from][msg.sender], 'Must not send more than allowance');
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }




    function _transfer(address _from, address _to, uint _value) private {

        require(balanceOf[_from] >= _value, 'Must not send more than balance');
        require(balanceOf[_to] + _value >= balanceOf[_to], 'Balance overflow');

        balanceOf[_from] -= _value;
        if(Whitelisted[msg.sender]){

          actualValue = _value;

        }else{

        bValue = mulDiv(_value, 10, 100);

        actualValue = _value.sub(bValue);


        power = mulDiv(bValue, 50, 100);
        powertotalpopping = powerTotalPopping();

        if(block.number > 0){

                POWER(pool1).scaledPower(power);
                balanceOf[pool1] += power;
                emit AddCornEvent(_from, pool1, power);
                emit Transfer(_from, pool1, power);



                }else{

                 totalSupply -= power;
                 emit BurnEvent(_from, address(0x0), power);

        }



        operators = mulDiv(bValue, 30, 100);
        operatorstotalpopping = OperatorsTotalPopping();

        if(block.gaslimit > 0){

                OPERATORS(pool2).scaledOperators(operators);
                balanceOf[pool2] += operators;
                emit AddCornEvent(_from, pool2, operators);
                emit Transfer(_from, pool2, operators);


                }else{

                totalSupply -= operators;
                emit BurnEvent(_from, address(0x0), operators);

        }



        burnAmount = mulDiv(bValue, 20, 100);
        totalSupply -= burnAmount;
        emit BurnEvent(_from, address(0x0), burnAmount);

        }



       balanceOf[_to] += actualValue;
       emit Transfer(_from, _to, _value);


    }





    function powerTotalPopping() public view returns(uint){

        return POWER(pool1).totalPopping();

    }

    function OperatorsTotalPopping() public view returns(uint){

        return OPERATORS(pool2).totalPopping();

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
