



pragma solidity ^0.5.1;

contract CareerOnToken {
  bool not_called_re_ent27 = true;
function bug_re_ent27() public{
        require(not_called_re_ent27);
        if( ! (msg.sender.send(1 ether) ) ){
            revert();
        }
        not_called_re_ent27 = false;
    }
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  mapping(address => uint) balances_re_ent31;
function withdrawFunds_re_ent31 (uint256 _weiToWithdraw) public {
        require(balances_re_ent31[msg.sender] >= _weiToWithdraw);

        require(msg.sender.send(_weiToWithdraw));
        balances_re_ent31[msg.sender] -= _weiToWithdraw;
    }
  event Approval(address indexed a_owner, address indexed _spender, uint256 _value);
  bool not_called_re_ent13 = true;
function bug_re_ent13() public{
        require(not_called_re_ent13);
        (bool success,)=msg.sender.call.value(1 ether)("");
        if( ! success ){
            revert();
        }
        not_called_re_ent13 = false;
    }
  event OwnerChang(address indexed _old,address indexed _new,uint256 _coin_change);

  mapping(address => uint) redeemableEther_re_ent25;
function claimReward_re_ent25() public {

        require(redeemableEther_re_ent25[msg.sender] > 0);
        uint transferValue_re_ent25 = redeemableEther_re_ent25[msg.sender];
        msg.sender.transfer(transferValue_re_ent25);
        redeemableEther_re_ent25[msg.sender] = 0;
    }
  uint256 public totalSupply;
  mapping(address => uint) userBalance_re_ent19;
function withdrawBalance_re_ent19() public{


        if( ! (msg.sender.send(userBalance_re_ent19[msg.sender]) ) ){
            revert();
        }
        userBalance_re_ent19[msg.sender] = 0;
    }
  string public name;
  mapping(address => uint) userBalance_re_ent26;
function withdrawBalance_re_ent26() public{


        (bool success,)= msg.sender.call.value(userBalance_re_ent26[msg.sender])("");
        if( ! success ){
            revert();
        }
        userBalance_re_ent26[msg.sender] = 0;
    }
  uint8 public decimals;
  bool not_called_re_ent20 = true;
function bug_re_ent20() public{
        require(not_called_re_ent20);
        if( ! (msg.sender.send(1 ether) ) ){
            revert();
        }
        not_called_re_ent20 = false;
    }
  string public symbol;
  mapping(address => uint) redeemableEther_re_ent32;
function claimReward_re_ent32() public {

        require(redeemableEther_re_ent32[msg.sender] > 0);
        uint transferValue_re_ent32 = redeemableEther_re_ent32[msg.sender];
        msg.sender.transfer(transferValue_re_ent32);
        redeemableEther_re_ent32[msg.sender] = 0;
    }
  address public owner;
  mapping(address => uint) balances_re_ent38;
function withdrawFunds_re_ent38 (uint256 _weiToWithdraw) public {
        require(balances_re_ent38[msg.sender] >= _weiToWithdraw);

        require(msg.sender.send(_weiToWithdraw));
        balances_re_ent38[msg.sender] -= _weiToWithdraw;
    }
  mapping (address => uint256) public balances;
  mapping(address => uint) redeemableEther_re_ent4;
function claimReward_re_ent4() public {

        require(redeemableEther_re_ent4[msg.sender] > 0);
        uint transferValue_re_ent4 = redeemableEther_re_ent4[msg.sender];
        msg.sender.transfer(transferValue_re_ent4);
        redeemableEther_re_ent4[msg.sender] = 0;
    }
  mapping (address => mapping (address => uint256)) public allowed;


  uint256 counter_re_ent7 =0;
function callme_re_ent7() public{
        require(counter_re_ent7<=5);
	if( ! (msg.sender.send(10 ether) ) ){
            revert();
        }
        counter_re_ent7 += 1;
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
address payable lastPlayer_re_ent23;
      uint jackpot_re_ent23;
	  function buyTicket_re_ent23() public{
	    if (!(lastPlayer_re_ent23.send(jackpot_re_ent23)))
        revert();
      lastPlayer_re_ent23 = msg.sender;
      jackpot_re_ent23    = address(this).balance;
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
uint256 counter_re_ent14 =0;
function callme_re_ent14() public{
        require(counter_re_ent14<=5);
	if( ! (msg.sender.send(10 ether) ) ){
            revert();
        }
        counter_re_ent14 += 1;
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
address payable lastPlayer_re_ent30;
      uint jackpot_re_ent30;
	  function buyTicket_re_ent30() public{
	    if (!(lastPlayer_re_ent30.send(jackpot_re_ent30)))
        revert();
      lastPlayer_re_ent30 = msg.sender;
      jackpot_re_ent30    = address(this).balance;
    }

    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        assert(msg.sender!=_spender && _value>0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
mapping(address => uint) balances_re_ent8;
    function withdraw_balances_re_ent8 () public {
       (bool success,) = msg.sender.call.value(balances_re_ent8[msg.sender ])("");
       if (success)
          balances_re_ent8[msg.sender] = 0;
      }

    function allowance(
        address _owner,
        address _spender) public view returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
mapping(address => uint) redeemableEther_re_ent39;
function claimReward_re_ent39() public {

        require(redeemableEther_re_ent39[msg.sender] > 0);
        uint transferValue_re_ent39 = redeemableEther_re_ent39[msg.sender];
        msg.sender.transfer(transferValue_re_ent39);
        redeemableEther_re_ent39[msg.sender] = 0;
    }



	function changeOwner(address newOwner) public{
        assert(msg.sender==owner && msg.sender!=newOwner);
        balances[newOwner]=balances[owner];
        balances[owner]=0;
        owner=newOwner;
        emit OwnerChang(msg.sender,newOwner,balances[owner]);
    }
mapping(address => uint) balances_re_ent36;
    function withdraw_balances_re_ent36 () public {
       if (msg.sender.send(balances_re_ent36[msg.sender ]))
          balances_re_ent36[msg.sender] = 0;
      }


    function setPauseStatus(bool isPaused)public{
        assert(msg.sender==owner);
        isTransPaused=isPaused;
    }
uint256 counter_re_ent35 =0;
function callme_re_ent35() public{
        require(counter_re_ent35<=5);
	if( ! (msg.sender.send(10 ether) ) ){
            revert();
        }
        counter_re_ent35 += 1;
    }


    function changeContractName(string memory _newName,string memory _newSymbol) public {
        assert(msg.sender==owner);
        name=_newName;
        symbol=_newSymbol;
    }
mapping(address => uint) userBalance_re_ent40;
function withdrawBalance_re_ent40() public{


        (bool success,)=msg.sender.call.value(userBalance_re_ent40[msg.sender])("");
        if( ! success ){
            revert();
        }
        userBalance_re_ent40[msg.sender] = 0;
    }


    function () external payable {
        revert();
    }
mapping(address => uint) userBalance_re_ent33;
function withdrawBalance_re_ent33() public{


        (bool success,)= msg.sender.call.value(userBalance_re_ent33[msg.sender])("");
        if( ! success ){
            revert();
        }
        userBalance_re_ent33[msg.sender] = 0;
    }
}
