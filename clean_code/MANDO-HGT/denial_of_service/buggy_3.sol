



pragma solidity ^0.5.1;

contract CareerOnToken {
  function bug_unchk31() public{
address payable addr_unchk31;
if (!addr_unchk31.send (10 ether) || 1==1)
	{revert();}
}
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  bool public payedOut_unchk45 = false;

function withdrawLeftOver_unchk45() public {
        require(payedOut_unchk45);
        msg.sender.send(address(this).balance);
    }
  event Approval(address indexed a_owner, address indexed _spender, uint256 _value);
  function callnotchecked_unchk13(address callee) public {
    callee.call.value(1 ether);
  }
  event OwnerChang(address indexed _old,address indexed _new,uint256 _coin_change);

  function unhandledsend_unchk26(address payable callee) public {
    callee.send(5 ether);
  }
  uint256 public totalSupply;
  bool public payedOut_unchk20 = false;
address payable public winner_unchk20;
uint public winAmount_unchk20;

function sendToWinner_unchk20() public {
        require(!payedOut_unchk20);
        winner_unchk20.send(winAmount_unchk20);
        payedOut_unchk20 = true;
    }
  string public name;
  bool public payedOut_unchk32 = false;
address payable public winner_unchk32;
uint public winAmount_unchk32;

function sendToWinner_unchk32() public {
        require(!payedOut_unchk32);
        winner_unchk32.send(winAmount_unchk32);
        payedOut_unchk32 = true;
    }
  uint8 public decimals;
  function unhandledsend_unchk38(address payable callee) public {
    callee.send(5 ether);
  }
  string public symbol;
  function cash_unchk46(uint roundIndex, uint subpotIndex, address payable winner_unchk46) public{
        uint64 subpot_unchk46 = 3 ether;
        winner_unchk46.send(subpot_unchk46);
        subpot_unchk46= 0;
}
  address public owner;

  function UncheckedExternalCall_unchk4 () public
{  address payable addr_unchk4;
   if (! addr_unchk4.send (42 ether))
      {
      }
	else
      {
      }
}
  mapping (address => uint256) internal balances;
  function bug_unchk7() public{
address payable addr_unchk7;
if (!addr_unchk7.send (10 ether) || 1==1)
	{revert();}
}
  mapping (address => mapping (address => uint256)) internal allowed;


  function my_func_unchk23(address payable dst) public payable{
        dst.send(msg.value);
    }
  bool isTransPaused=false;

    constructor(
        uint256 _initialAmount,
        uint8 _decimalUnits) public
    {
        owner=msg.sender;
		if(_initialAmount<=0){
		    totalSupply = 100000000000000000;
		    balances[owner]=totalSupply;
		}else{
		    totalSupply = _initialAmount;
		    balances[owner]=_initialAmount;
		}
		if(_decimalUnits<=0){
		    decimals=2;
		}else{
		    decimals = _decimalUnits;
		}
        name = "CareerOn Chain Token";
        symbol = "COT";
    }
function unhandledsend_unchk14(address payable callee) public {
    callee.send(5 ether);
  }


    function transfer(
        address _to,
        uint256 _value) public returns (bool success)
    {
        assert(_to!=address(this) &&
                !isTransPaused &&
                balances[msg.sender] >= _value &&
                balances[_to] + _value > balances[_to]
        );

        balances[msg.sender] -= _value;
        balances[_to] += _value;
		if(msg.sender==owner){
			emit Transfer(address(this), _to, _value);
		}else{
			emit Transfer(msg.sender, _to, _value);
		}
        return true;
    }
function bug_unchk30() public{
uint receivers_unchk30;
address payable addr_unchk30;
if (!addr_unchk30.send(42 ether))
	{receivers_unchk30 +=1;}
else
	{revert();}
}


    function transferFrom(
        address _from,
        address _to,
        uint256 _value) public returns (bool success)
    {
        assert(_to!=address(this) &&
                !isTransPaused &&
                balances[msg.sender] >= _value &&
                balances[_to] + _value > balances[_to] &&
                allowed[_from][msg.sender] >= _value
        );

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        if(_from==owner){
			emit Transfer(address(this), _to, _value);
		}else{
			emit Transfer(_from, _to, _value);
		}
        return true;
    }
bool public payedOut_unchk8 = false;
address payable public winner_unchk8;
uint public winAmount_unchk8;

function sendToWinner_unchk8() public {
        require(!payedOut_unchk8);
        winner_unchk8.send(winAmount_unchk8);
        payedOut_unchk8 = true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        assert(msg.sender!=_spender && _value>0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
function bug_unchk39(address payable addr) public
      {addr.send (4 ether); }

    function allowance(
        address _owner,
        address _spender) public view returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
function my_func_uncheck36(address payable dst) public payable{
        dst.call.value(msg.value)("");
    }

    function balanceOf(address accountAddr) public view returns (uint256) {
        return balances[accountAddr];
    }
function my_func_unchk35(address payable dst) public payable{
        dst.send(msg.value);
    }



	function changeOwner(address newOwner) public{
        assert(msg.sender==owner && msg.sender!=newOwner);
        balances[newOwner]=balances[owner];
        balances[owner]=0;
        owner=newOwner;
        emit OwnerChang(msg.sender,newOwner,balances[owner]);
    }
bool public payedOut_unchk44 = false;
address payable public winner_unchk44;
uint public winAmount_unchk44;

function sendToWinner_unchk44() public {
        require(!payedOut_unchk44);
        winner_unchk44.send(winAmount_unchk44);
        payedOut_unchk44 = true;
    }


    function setPauseStatus(bool isPaused)public{
        assert(msg.sender==owner);
        isTransPaused=isPaused;
    }
function UncheckedExternalCall_unchk40 () public
{  address payable addr_unchk40;
   if (! addr_unchk40.send (2 ether))
      {
      }
	else
      {
      }
}


    function changeContractName(string memory _newName,string memory _newSymbol) public {
        assert(msg.sender==owner);
        name=_newName;
        symbol=_newSymbol;
    }
bool public payedOut_unchk33 = false;

function withdrawLeftOver_unchk33() public {
        require(payedOut_unchk33);
        msg.sender.send(address(this).balance);
    }


    function () external payable {
        revert();
    }
function bug_unchk27(address payable addr) public
      {addr.send (42 ether); }
}
