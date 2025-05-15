

pragma solidity ^0.5.10;


contract NEST_NodeSave {
    IBMapping mappingContract;
    IBNEST nestContract;


    constructor (address map) public {
        mappingContract = IBMapping(address(map));
        nestContract = IBNEST(address(mappingContract.CHECKADDRESS222("nest")));
    }


    function CHANGEMAPPING301(address map) public ONLYOWNER374 {
        mappingContract = IBMapping(address(map));
        nestContract = IBNEST(address(mappingContract.CHECKADDRESS222("nest")));
    }


    function TURNOUT485(uint256 amount, address to) public ONLYMININGCALCULATION602 returns(uint256) {
        uint256 leftNum = nestContract.BALANCEOF780(address(this));
        if (leftNum >= amount) {
            nestContract.TRANSFER685(to, amount);
            return amount;
        } else {
            return 0;
        }
    }

    modifier ONLYOWNER374(){
        require(mappingContract.CHECKOWNERS909(msg.sender) == true);
        _;
    }

    modifier ONLYMININGCALCULATION602(){
        require(address(mappingContract.CHECKADDRESS222("nodeAssignment")) == msg.sender);
        _;
    }

}


contract NEST_NodeAssignmentData {
    using SafeMath for uint256;
    IBMapping mappingContract;
    uint256 nodeAllAmount = 0;
    mapping(address => uint256) nodeLatestAmount;


    constructor (address map) public {
        mappingContract = IBMapping(map);
    }


    function CHANGEMAPPING301(address map) public ONLYOWNER374{
        mappingContract = IBMapping(map);
    }


    function ADDNEST102(uint256 amount) public ONLYNODEASSIGNMENT511 {
        nodeAllAmount = nodeAllAmount.ADD302(amount);
    }


    function CHECKNODEALLAMOUNT929() public view returns (uint256) {
        return nodeAllAmount;
    }


    function ADDNODELATESTAMOUNT655(address add ,uint256 amount) public ONLYNODEASSIGNMENT511 {
        nodeLatestAmount[add] = amount;
    }


    function CHECKNODELATESTAMOUNT653(address add) public view returns (uint256) {
        return nodeLatestAmount[address(add)];
    }

    modifier ONLYOWNER374(){
        require(mappingContract.CHECKOWNERS909(msg.sender) == true);
        _;
    }

    modifier ONLYNODEASSIGNMENT511(){
        require(address(msg.sender) == address(mappingContract.CHECKADDRESS222("nodeAssignment")));
        _;
    }
}


contract NEST_NodeAssignment {

    using SafeMath for uint256;
    IBMapping mappingContract;
    IBNEST nestContract;
    SuperMan supermanContract;
    NEST_NodeSave nodeSave;
    NEST_NodeAssignmentData nodeAssignmentData;


    constructor (address map) public {
        mappingContract = IBMapping(map);
        nestContract = IBNEST(address(mappingContract.CHECKADDRESS222("nest")));
        supermanContract = SuperMan(address(mappingContract.CHECKADDRESS222("nestNode")));
        nodeSave = NEST_NodeSave(address(mappingContract.CHECKADDRESS222("nestNodeSave")));
        nodeAssignmentData = NEST_NodeAssignmentData(address(mappingContract.CHECKADDRESS222("nodeAssignmentData")));
    }


    function CHANGEMAPPING301(address map) public ONLYOWNER374{
        mappingContract = IBMapping(map);
        nestContract = IBNEST(address(mappingContract.CHECKADDRESS222("nest")));
        supermanContract = SuperMan(address(mappingContract.CHECKADDRESS222("nestNode")));
        nodeSave = NEST_NodeSave(address(mappingContract.CHECKADDRESS222("nestNodeSave")));
        nodeAssignmentData = NEST_NodeAssignmentData(address(mappingContract.CHECKADDRESS222("nodeAssignmentData")));
    }


    function BOOKKEEPING887(uint256 amount) public {
        require(amount > 0);
        require(nestContract.BALANCEOF780(address(msg.sender)) >= amount);
        require(nestContract.ALLOWANCE615(address(msg.sender), address(this)) >= amount);
        require(nestContract.TRANSFERFROM303(address(msg.sender), address(nodeSave), amount));
        nodeAssignmentData.ADDNEST102(amount);
    }


    function NODEGET172() public {
        require(address(msg.sender) == address(tx.origin));
        require(supermanContract.BALANCEOF780(address(msg.sender)) > 0);
        uint256 allAmount = nodeAssignmentData.CHECKNODEALLAMOUNT929();
        uint256 amount = allAmount.SUB809(nodeAssignmentData.CHECKNODELATESTAMOUNT653(address(msg.sender)));
        uint256 getAmount = amount.MUL451(supermanContract.BALANCEOF780(address(msg.sender))).DIV932(1500);
        require(nestContract.BALANCEOF780(address(nodeSave)) >= getAmount);
        nodeSave.TURNOUT485(getAmount,address(msg.sender));
        nodeAssignmentData.ADDNODELATESTAMOUNT655(address(msg.sender),allAmount);
    }


    function NODECOUNT170(address fromAdd, address toAdd) public {
        require(address(supermanContract) == address(msg.sender));
        require(supermanContract.BALANCEOF780(address(fromAdd)) > 0);
        uint256 allAmount = nodeAssignmentData.CHECKNODEALLAMOUNT929();

        uint256 amountFrom = allAmount.SUB809(nodeAssignmentData.CHECKNODELATESTAMOUNT653(address(fromAdd)));
        uint256 getAmountFrom = amountFrom.MUL451(supermanContract.BALANCEOF780(address(fromAdd))).DIV932(1500);
        require(nestContract.BALANCEOF780(address(nodeSave)) >= getAmountFrom);
        nodeSave.TURNOUT485(getAmountFrom,address(fromAdd));
        nodeAssignmentData.ADDNODELATESTAMOUNT655(address(fromAdd),allAmount);

        uint256 amountTo = allAmount.SUB809(nodeAssignmentData.CHECKNODELATESTAMOUNT653(address(toAdd)));
        uint256 getAmountTo = amountTo.MUL451(supermanContract.BALANCEOF780(address(toAdd))).DIV932(1500);
        require(nestContract.BALANCEOF780(address(nodeSave)) >= getAmountTo);
        nodeSave.TURNOUT485(getAmountTo,address(toAdd));
        nodeAssignmentData.ADDNODELATESTAMOUNT655(address(toAdd),allAmount);
    }


    function CHECKNODENUM994() public view returns (uint256) {
         uint256 allAmount = nodeAssignmentData.CHECKNODEALLAMOUNT929();
         uint256 amount = allAmount.SUB809(nodeAssignmentData.CHECKNODELATESTAMOUNT653(address(msg.sender)));
         uint256 getAmount = amount.MUL451(supermanContract.BALANCEOF780(address(msg.sender))).DIV932(1500);
         return getAmount;
    }

    modifier ONLYOWNER374(){
        require(mappingContract.CHECKOWNERS909(msg.sender) == true);
        _;
    }
}



interface IERC20 {
    function TOTALSUPPLY171() external view returns (uint256);

    function BALANCEOF780(address who) external view returns (uint256);

    function ALLOWANCE615(address owner, address spender) external view returns (uint256);

    function TRANSFER685(address to, uint256 value) external returns (bool);

    function APPROVE777(address spender, uint256 value) external returns (bool);

    function TRANSFERFROM303(address from, address to, uint256 value) external returns (bool);

    event TRANSFER309(address indexed from, address indexed to, uint256 value);

    event APPROVAL404(address indexed owner, address indexed spender, uint256 value);

}


contract SuperMan is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    IBMapping mappingContract;

    uint256 private _totalSupply = 1500;
    string public name = "NestNode";
    string public symbol = "NN";
    uint8 public decimals = 0;

    constructor (address map) public {
    	_balances[msg.sender] = _totalSupply;
    	mappingContract = IBMapping(map);
    }

    function CHANGEMAPPING301(address map) public ONLYOWNER374{
        mappingContract = IBMapping(map);
    }


    function TOTALSUPPLY171() public view returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF780(address owner) public view returns (uint256) {
        return _balances[owner];
    }


    function ALLOWANCE615(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }


    function TRANSFER685(address to, uint256 value) public returns (bool) {
        _TRANSFER545(msg.sender, to, value);
        return true;
    }


    function APPROVE777(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit APPROVAL404(msg.sender, spender, value);
        return true;
    }


    function TRANSFERFROM303(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].SUB809(value);
        _TRANSFER545(from, to, value);
        emit APPROVAL404(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }


    function INCREASEALLOWANCE778(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].ADD302(addedValue);
        emit APPROVAL404(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }


    function DECREASEALLOWANCE839(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].SUB809(subtractedValue);
        emit APPROVAL404(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }


    function _TRANSFER545(address from, address to, uint256 value) internal {
        require(to != address(0));

        NEST_NodeAssignment nodeAssignment = NEST_NodeAssignment(address(mappingContract.CHECKADDRESS222("nodeAssignment")));
        nodeAssignment.NODECOUNT170(from, to);

        _balances[from] = _balances[from].SUB809(value);
        _balances[to] = _balances[to].ADD302(value);
        emit TRANSFER309(from, to, value);


    }

    modifier ONLYOWNER374(){
        require(mappingContract.CHECKOWNERS909(msg.sender) == true);
        _;
    }
}


library SafeMath {
    int256 constant private int256_min212 = -2**255;


    function MUL451(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }


    function MUL451(int256 a, int256 b) internal pure returns (int256) {



        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == int256_min212));

        int256 c = a * b;
        require(c / a == b);

        return c;
    }


    function DIV932(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }


    function DIV932(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);
        require(!(b == -1 && a == int256_min212));

        int256 c = a / b;

        return c;
    }


    function SUB809(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }


    function SUB809(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }


    function ADD302(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }


    function ADD302(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }


    function MOD929(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract IBMapping {
	function CHECKADDRESS222(string memory name) public view returns (address contractAddress);
	function CHECKOWNERS909(address man) public view returns (bool);
}

contract IBNEST {
    function TOTALSUPPLY171() public view returns (uint supply);
    function BALANCEOF780( address who ) public view returns (uint value);
    function ALLOWANCE615( address owner, address spender ) public view returns (uint _allowance);

    function TRANSFER685( address to, uint256 value) external;
    function TRANSFERFROM303( address from, address to, uint value) public returns (bool ok);
    function APPROVE777( address spender, uint value ) public returns (bool ok);

    event TRANSFER309( address indexed from, address indexed to, uint value);
    event APPROVAL404( address indexed owner, address indexed spender, uint value);

    function BALANCESSTART356() public view returns(uint256);
    function BALANCESGETBOOL55(uint256 num) public view returns(bool);
    function BALANCESGETNEXT455(uint256 num) public view returns(uint256);
    function BALANCESGETVALUE432(uint256 num) public view returns(address, uint256);
}
