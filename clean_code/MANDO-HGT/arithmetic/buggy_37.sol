



pragma solidity ^0.5.00;



















contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
function bug_intou11() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
mapping(address => uint) public lockTime_intou1;

function increaseLockTime_intou1(uint _secondsToIncrease) public {
        lockTime_intou1[msg.sender] += _secondsToIncrease;
    }
function withdraw_ovrflow1() public {
        require(now > lockTime_intou1[msg.sender]);
        uint transferValue_intou1 = 10;
        msg.sender.transfer(transferValue_intou1);
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
mapping(address => uint) balances_intou2;

function transfer_undrflow2(address _to, uint _value) public returns (bool) {
    require(balances_intou2[msg.sender] - _value >= 0);
    balances_intou2[msg.sender] -= _value;
    balances_intou2[_to] += _value;
    return true;
  }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
mapping(address => uint) public lockTime_intou17;

function increaseLockTime_intou17(uint _secondsToIncrease) public {
        lockTime_intou17[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou17() public {
        require(now > lockTime_intou17[msg.sender]);
        uint transferValue_intou17 = 10;
        msg.sender.transfer(transferValue_intou17);
    }
}






contract ERC20Interface {
    function totalSupply() public view returns (uint);
mapping(address => uint) public lockTime_intou37;

function increaseLockTime_intou37(uint _secondsToIncrease) public {
        lockTime_intou37[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou37() public {
        require(now > lockTime_intou37[msg.sender]);
        uint transferValue_intou37 = 10;
        msg.sender.transfer(transferValue_intou37);
    }
    function balanceOf(address tokenOwner) public view returns (uint balance);
function bug_intou3() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
mapping(address => uint) public lockTime_intou9;

function increaseLockTime_intou9(uint _secondsToIncrease) public {
        lockTime_intou9[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou9() public {
        require(now > lockTime_intou9[msg.sender]);
        uint transferValue_intou9 = 10;
        msg.sender.transfer(transferValue_intou9);
    }
    function transfer(address to, uint tokens) public returns (bool success);
mapping(address => uint) public lockTime_intou25;

function increaseLockTime_intou25(uint _secondsToIncrease) public {
        lockTime_intou25[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou25() public {
        require(now > lockTime_intou25[msg.sender]);
        uint transferValue_intou25 = 10;
        msg.sender.transfer(transferValue_intou25);
    }
    function approve(address spender, uint tokens) public returns (bool success);
function bug_intou19() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
mapping(address => uint) balances_intou26;

function transfer_intou26(address _to, uint _value) public returns (bool) {
    require(balances_intou26[msg.sender] - _value >= 0);
    balances_intou26[msg.sender] -= _value;
    balances_intou26[_to] += _value;
    return true;
  }

  function bug_intou27() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}
  event Transfer(address indexed from, address indexed to, uint tokens);
  function bug_intou31() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}







contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
function bug_intou20(uint8 p_intou20) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou20;
}
}





contract Owned {
  function bug_intou15() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}
  address public owner;
  function bug_intou28(uint8 p_intou28) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou28;
}
  address public newOwner;

  mapping(address => uint) public lockTime_intou13;

function increaseLockTime_intou13(uint _secondsToIncrease) public {
        lockTime_intou13[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou13() public {
        require(now > lockTime_intou13[msg.sender]);
        uint transferValue_intou13 = 10;
        msg.sender.transfer(transferValue_intou13);
    }
  event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }
function bug_intou32(uint8 p_intou32) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou32;
}

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
mapping(address => uint) balances_intou38;

function transfer_intou38(address _to, uint _value) public returns (bool) {
    require(balances_intou38[msg.sender] - _value >= 0);
    balances_intou38[msg.sender] -= _value;
    balances_intou38[_to] += _value;
    return true;
  }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
function bug_intou4(uint8 p_intou4) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou4;
}
}






contract AugustCoin is ERC20Interface, Owned, SafeMath {
  mapping(address => uint) balances_intou34;

function transfer_intou34(address _to, uint _value) public returns (bool) {
    require(balances_intou34[msg.sender] - _value >= 0);
    balances_intou34[msg.sender] -= _value;
    balances_intou34[_to] += _value;
    return true;
  }
  string public symbol;
  mapping(address => uint) public lockTime_intou21;

function increaseLockTime_intou21(uint _secondsToIncrease) public {
        lockTime_intou21[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou21() public {
        require(now > lockTime_intou21[msg.sender]);
        uint transferValue_intou21 = 10;
        msg.sender.transfer(transferValue_intou21);
    }
  string public  name;
  mapping(address => uint) balances_intou10;

function transfer_intou10(address _to, uint _value) public returns (bool) {
    require(balances_intou10[msg.sender] - _value >= 0);
    balances_intou10[msg.sender] -= _value;
    balances_intou10[_to] += _value;
    return true;
  }
  uint8 public decimals;
  mapping(address => uint) balances_intou22;

function transfer_intou22(address _to, uint _value) public returns (bool) {
    require(balances_intou22[msg.sender] - _value >= 0);
    balances_intou22[msg.sender] -= _value;
    balances_intou22[_to] += _value;
    return true;
  }
  uint public _totalSupply;

    mapping(address => uint) balances;
  function bug_intou12(uint8 p_intou12) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou12;
}
  mapping(address => mapping(address => uint)) allowed;





    constructor() public {
        symbol = "AUC";
        name = "AugustCoin";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balances[0xe4948b8A5609c3c39E49eC1e36679a94F72D62bD] = _totalSupply;
        emit Transfer(address(0), 0xe4948b8A5609c3c39E49eC1e36679a94F72D62bD, _totalSupply);
    }
function bug_intou7() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}





    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }
function bug_intou23() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}





    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
mapping(address => uint) balances_intou14;

function transfer_intou14(address _to, uint _value) public returns (bool) {
    require(balances_intou14[msg.sender] - _value >= 0);
    balances_intou14[msg.sender] -= _value;
    balances_intou14[_to] += _value;
    return true;
  }







    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
mapping(address => uint) balances_intou30;

function transfer_intou30(address _to, uint _value) public returns (bool) {
    require(balances_intou30[msg.sender] - _value >= 0);
    balances_intou30[msg.sender] -= _value;
    balances_intou30[_to] += _value;
    return true;
  }










    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
function bug_intou8(uint8 p_intou8) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou8;
}











    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
function bug_intou39() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}






    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
function bug_intou36(uint8 p_intou36) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou36;
}







    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
function bug_intou35() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}





    function () external payable {
        revert();
    }
function bug_intou40(uint8 p_intou40) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou40;
}





    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
mapping(address => uint) public lockTime_intou33;

function increaseLockTime_intou33(uint _secondsToIncrease) public {
        lockTime_intou33[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou33() public {
        require(now > lockTime_intou33[msg.sender]);
        uint transferValue_intou33 = 10;
        msg.sender.transfer(transferValue_intou33);
    }
}


