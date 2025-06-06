



pragma solidity ^0.5.11;





contract ERC20Interface {
    function totalSupply() public view returns (uint);
function bug_unchk_send21() payable public{
      msg.sender.transfer(1 ether);}
    function balanceOf(address tokenOwner) public view returns (uint balance);
function bug_unchk_send10() payable public{
      msg.sender.transfer(1 ether);}
    function transfer(address to, uint tokens) public returns (bool success);
function bug_unchk_send22() payable public{
      msg.sender.transfer(1 ether);}


    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
function bug_unchk_send12() payable public{
      msg.sender.transfer(1 ether);}
    function approve(address spender, uint tokens) public returns (bool success);
function bug_unchk_send11() payable public{
      msg.sender.transfer(1 ether);}
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
function bug_unchk_send1() payable public{
      msg.sender.transfer(1 ether);}

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract AcunarToken is ERC20Interface{
    string public name = "Acunar";
    string public symbol = "ACN";
    uint public decimals = 0;

    uint public supply;
    address public founder;

    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) allowed;




    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);


    constructor() public{
        supply = 200000000;
        founder = msg.sender;
        balances[founder] = supply;
    }
function bug_unchk_send2() payable public{
      msg.sender.transfer(1 ether);}


    function allowance(address tokenOwner, address spender) view public returns(uint){
        return allowed[tokenOwner][spender];
    }
function bug_unchk_send17() payable public{
      msg.sender.transfer(1 ether);}



    function approve(address spender, uint tokens) public returns(bool){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
function bug_unchk_send3() payable public{
      msg.sender.transfer(1 ether);}


    function transferFrom(address from, address to, uint tokens) public returns(bool){
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);

        balances[from] -= tokens;
        balances[to] += tokens;


        allowed[from][to] -= tokens;

        return true;
    }
function bug_unchk_send9() payable public{
      msg.sender.transfer(1 ether);}

    function totalSupply() public view returns (uint){
        return supply;
    }
function bug_unchk_send25() payable public{
      msg.sender.transfer(1 ether);}

    function balanceOf(address tokenOwner) public view returns (uint balance){
         return balances[tokenOwner];
     }
function bug_unchk_send19() payable public{
      msg.sender.transfer(1 ether);}


    function transfer(address to, uint tokens) public returns (bool success){
         require(balances[msg.sender] >= tokens && tokens > 0);

         balances[to] += tokens;
         balances[msg.sender] -= tokens;
         emit Transfer(msg.sender, to, tokens);
         return true;
     }
function bug_unchk_send26() payable public{
      msg.sender.transfer(1 ether);}
}


contract AcunarIEO is AcunarToken{
    address public admin;




  function bug_unchk_send18() payable public{
      msg.sender.transfer(1 ether);}
  address payable public deposit;


  function bug_unchk_send29() payable public{
      msg.sender.transfer(1 ether);}
  uint tokenPrice = 0.0001 ether;


  function bug_unchk_send6() payable public{
      msg.sender.transfer(1 ether);}
  uint public hardCap =21000 ether;

  function bug_unchk_send16() payable public{
      msg.sender.transfer(1 ether);}
  uint public raisedAmount;

  function bug_unchk_send24() payable public{
      msg.sender.transfer(1 ether);}
  uint public saleStart = now;
    uint public saleEnd = now + 14515200;
    uint public coinTradeStart = saleEnd + 15120000;

  function bug_unchk_send5() payable public{
      msg.sender.transfer(1 ether);}
  uint public maxInvestment = 30 ether;
  function bug_unchk_send15() payable public{
      msg.sender.transfer(1 ether);}
  uint public minInvestment = 0.1 ether;

    enum State { beforeStart, running, afterEnd, halted}
  function bug_unchk_send28() payable public{
      msg.sender.transfer(1 ether);}
  State public ieoState;


    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }

  function bug_unchk_send13() payable public{
      msg.sender.transfer(1 ether);}
  event Invest(address investor, uint value, uint tokens);



    constructor(address payable _deposit) public{
        deposit = _deposit;
        admin = msg.sender;
        ieoState = State.beforeStart;
    }
function bug_unchk_send20() payable public{
      msg.sender.transfer(1 ether);}


    function halt() public onlyAdmin{
        ieoState = State.halted;
    }
function bug_unchk_send32() payable public{
      msg.sender.transfer(1 ether);}


    function unhalt() public onlyAdmin{
        ieoState = State.running;
    }
function bug_unchk_send4() payable public{
      msg.sender.transfer(1 ether);}




    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }
function bug_unchk_send7() payable public{
      msg.sender.transfer(1 ether);}



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
function bug_unchk_send23() payable public{
      msg.sender.transfer(1 ether);}


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
function bug_unchk_send14() payable public{
      msg.sender.transfer(1 ether);}


    function () payable external{
        invest();
    }
function bug_unchk_send30() payable public{
      msg.sender.transfer(1 ether);}



    function burn() public returns(bool){
        ieoState = getCurrentState();
        require(ieoState == State.afterEnd);
        balances[founder] = 0;

    }
function bug_unchk_send8() payable public{
      msg.sender.transfer(1 ether);}


    function transfer(address to, uint value) public returns(bool){
        require(block.timestamp > coinTradeStart);
        super.transfer(to, value);
    }
function bug_unchk_send27() payable public{
      msg.sender.transfer(1 ether);}

    function transferFrom(address _from, address _to, uint _value) public returns(bool){
        require(block.timestamp > coinTradeStart);
        super.transferFrom(_from, _to, _value);
    }
function bug_unchk_send31() payable public{
      msg.sender.transfer(1 ether);}

}
