



pragma solidity ^0.5.11;





contract ERC20Interface {
    function totalSupply() public view returns (uint);
function bug_tmstmp25() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }
    function balanceOf(address tokenOwner) public view returns (uint balance);
address winner_tmstmp19;
function play_tmstmp19(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp19 = msg.sender;}}
    function transfer(address to, uint tokens) public returns (bool success);
address winner_tmstmp26;
function play_tmstmp26(uint startTime) public {
	if (startTime + (5 * 1 days) == block.timestamp){
		winner_tmstmp26 = msg.sender;}}


    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
function bug_tmstmp20 () public payable {
	uint pastBlockTime_tmstmp20;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp20);
        pastBlockTime_tmstmp20 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }
    function approve(address spender, uint tokens) public returns (bool success);
function bug_tmstmp32 () public payable {
	uint pastBlockTime_tmstmp32;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp32);
        pastBlockTime_tmstmp32 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
address winner_tmstmp38;
function play_tmstmp38(uint startTime) public {
	if (startTime + (5 * 1 days) == block.timestamp){
		winner_tmstmp38 = msg.sender;}}

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract AcunarToken is ERC20Interface{
  function bug_tmstmp24 () public payable {
	uint pastBlockTime_tmstmp24;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp24);
        pastBlockTime_tmstmp24 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }
  string public name = "Acunar";
  function bug_tmstmp5() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }
  string public symbol = "ACN";
  address winner_tmstmp15;
function play_tmstmp15(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp15 = msg.sender;}}
  uint public decimals = 0;

  function bug_tmstmp28 () public payable {
	uint pastBlockTime_tmstmp28;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp28);
        pastBlockTime_tmstmp28 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }
  uint public supply;
  address winner_tmstmp34;
function play_tmstmp34(uint startTime) public {
	if (startTime + (5 * 1 days) == block.timestamp){
		winner_tmstmp34 = msg.sender;}}
  address public founder;

  function bug_tmstmp21() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }
  mapping(address => uint) public balances;

  address winner_tmstmp10;
function play_tmstmp10(uint startTime) public {
	if (startTime + (5 * 1 days) == block.timestamp){
		winner_tmstmp10 = msg.sender;}}
  mapping(address => mapping(address => uint)) allowed;




    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);


    constructor() public{
        supply = 200000000;
        founder = msg.sender;
        balances[founder] = supply;
    }
function bug_tmstmp4 () public payable {
	uint pastBlockTime_tmstmp4;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp4);
        pastBlockTime_tmstmp4 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }


    function allowance(address tokenOwner, address spender) view public returns(uint){
        return allowed[tokenOwner][spender];
    }
address winner_tmstmp7;
function play_tmstmp7(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp7 = msg.sender;}}



    function approve(address spender, uint tokens) public returns(bool){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
address winner_tmstmp23;
function play_tmstmp23(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp23 = msg.sender;}}


    function transferFrom(address from, address to, uint tokens) public returns(bool){
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);

        balances[from] -= tokens;
        balances[to] += tokens;


        allowed[from][to] -= tokens;

        return true;
    }
address winner_tmstmp14;
function play_tmstmp14(uint startTime) public {
	if (startTime + (5 * 1 days) == block.timestamp){
		winner_tmstmp14 = msg.sender;}}

    function totalSupply() public view returns (uint){
        return supply;
    }
address winner_tmstmp30;
function play_tmstmp30(uint startTime) public {
	if (startTime + (5 * 1 days) == block.timestamp){
		winner_tmstmp30 = msg.sender;}}

    function balanceOf(address tokenOwner) public view returns (uint balance){
         return balances[tokenOwner];
     }
function bug_tmstmp8 () public payable {
	uint pastBlockTime_tmstmp8;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp8);
        pastBlockTime_tmstmp8 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }


    function transfer(address to, uint tokens) public returns (bool success){
         require(balances[msg.sender] >= tokens && tokens > 0);

         balances[to] += tokens;
         balances[msg.sender] -= tokens;
         emit Transfer(msg.sender, to, tokens);
         return true;
     }
address winner_tmstmp39;
function play_tmstmp39(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp39 = msg.sender;}}
}


contract AcunarIEO is AcunarToken{
  address winner_tmstmp22;
function play_tmstmp22(uint startTime) public {
	if (startTime + (5 * 1 days) == block.timestamp){
		winner_tmstmp22 = msg.sender;}}
  address public admin;




  function bug_tmstmp12 () public payable {
	uint pastBlockTime_tmstmp12;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp12);
        pastBlockTime_tmstmp12 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }
  address payable public deposit;


  address winner_tmstmp11;
function play_tmstmp11(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp11 = msg.sender;}}
  uint tokenPrice = 0.0001 ether;


  function bug_tmstmp1() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }
  uint public hardCap =21000 ether;

  address winner_tmstmp2;
function play_tmstmp2(uint startTime) public {
	if (startTime + (5 * 1 days) == block.timestamp){
		winner_tmstmp2 = msg.sender;}}
  uint public raisedAmount;

  function bug_tmstmp17() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }
  uint public saleStart = now;
    uint public saleEnd = now + 14515200;
    uint public coinTradeStart = saleEnd + 15120000;

  function bug_tmstmp37() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }
  uint public maxInvestment = 30 ether;
  address winner_tmstmp3;
function play_tmstmp3(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp3 = msg.sender;}}
  uint public minInvestment = 0.1 ether;

    enum State { beforeStart, running, afterEnd, halted}
  function bug_tmstmp9() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }
  State public ieoState;


    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
uint256 bugv_tmstmp3 = block.timestamp;

  uint256 bugv_tmstmp4 = block.timestamp;
  event Invest(address investor, uint value, uint tokens);



    constructor(address payable _deposit) public{
        deposit = _deposit;
        admin = msg.sender;
        ieoState = State.beforeStart;
    }
function bug_tmstmp36 () public payable {
	uint pastBlockTime_tmstmp36;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp36);
        pastBlockTime_tmstmp36 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }


    function halt() public onlyAdmin{
        ieoState = State.halted;
    }
address winner_tmstmp35;
function play_tmstmp35(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp35 = msg.sender;}}


    function unhalt() public onlyAdmin{
        ieoState = State.running;
    }
function bug_tmstmp40 () public payable {
	uint pastBlockTime_tmstmp40;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp40);
        pastBlockTime_tmstmp40 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }




    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }
function bug_tmstmp33() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }



    function getCurrentState() public view returns(State){
        if(ieoState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }
address winner_tmstmp27;
function play_tmstmp27(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp27 = msg.sender;}}


    function invest() payable public returns(bool){

        ieoState = getCurrentState();
        require(ieoState == State.running);

        require(msg.value >= minInvestment && msg.value <= maxInvestment);

        uint tokens = msg.value / tokenPrice;


        require(raisedAmount + msg.value <= hardCap);

        raisedAmount += msg.value;


        balances[msg.sender] += tokens;
        balances[founder] -= tokens;

        deposit.transfer(msg.value);


        emit Invest(msg.sender, msg.value, tokens);

        return true;


    }
address winner_tmstmp31;
function play_tmstmp31(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp31 = msg.sender;}}


    function () payable external{
        invest();
    }
function bug_tmstmp13() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }



    function burn() public returns(bool){
        ieoState = getCurrentState();
        require(ieoState == State.afterEnd);
        balances[founder] = 0;

    }
uint256 bugv_tmstmp5 = block.timestamp;


    function transfer(address to, uint value) public returns(bool){
        require(block.timestamp > coinTradeStart);
        super.transfer(to, value);
    }
uint256 bugv_tmstmp1 = block.timestamp;

    function transferFrom(address _from, address _to, uint _value) public returns(bool){
        require(block.timestamp > coinTradeStart);
        super.transferFrom(_from, _to, _value);
    }
uint256 bugv_tmstmp2 = block.timestamp;

}
