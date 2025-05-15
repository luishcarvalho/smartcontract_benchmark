

pragma solidity 0.6.8;


interface ERC20 {
    function TOTALSUPPLY387() external view returns (uint256);
    function BALANCEOF98(address account) external view returns (uint256);
    function TRANSFER80(address, uint256) external returns (bool);
    function ALLOWANCE308(address owner, address spender) external view returns (uint256);
    function APPROVE186(address, uint) external returns (bool);
    function TRANSFERFROM135(address, address, uint256) external returns (bool);
    event TRANSFER314(address indexed from, address indexed to, uint256 value);
    event APPROVAL490(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function SUB960(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function ADD133(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function MOD508(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    function MUL385(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function DIV899(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
}

contract Libera is ERC20 {
    using SafeMath for uint256;
    string public symbol;
    string public name;
    uint256 public decimals = 18;
    uint256 public override totalSupply = 5000000 * (10 ** decimals);
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => uint256) public override balanceOf;
    event APPROVAL490(address indexed owner, address indexed spender, uint256 value);
    event TRANSFER314(address indexed from, address indexed to, uint256 value);

    constructor() public {
        symbol = "LIB";
        name = "Libera";
        balanceOf[msg.sender] = totalSupply;
    }

    function APPROVE186(address spender, uint256 value) public override returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit APPROVAL490(msg.sender, spender, value);
        return true;
    }

    function TRANSFER80(address to, uint256 value) public override returns (bool success) {
        _TRANSFER834(msg.sender, to, value);
        return true;
    }

    function TRANSFERFROM135(address from, address to, uint256 value) public override returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        _TRANSFER834(from, to, value);
        return true;
    }

    function _TRANSFER834(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(_value <= balanceOf[_from]);
        require(balanceOf[_to] <= balanceOf[_to].ADD133(_value));
        balanceOf[_from] = balanceOf[_from].SUB960(_value);
        balanceOf[_to] = balanceOf[_to].ADD133(_value);
        emit TRANSFER314(_from, _to, _value);
    }
}
