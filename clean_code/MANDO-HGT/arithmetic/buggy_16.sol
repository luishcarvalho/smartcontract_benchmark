







pragma solidity ^0.5.11;




library SafeMath {




    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }




   function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }




    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }




    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
}


contract ERC20Interface {
    function totalSupply() public view returns (uint256);
function bug_intou28(uint8 p_intou28) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou28;
}
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
mapping(address => uint) balances_intou34;

function transfer_intou34(address _to, uint _value) public returns (bool) {
    require(balances_intou34[msg.sender] - _value >= 0);
    balances_intou34[msg.sender] -= _value;
    balances_intou34[_to] += _value;
    return true;
  }
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
mapping(address => uint) public lockTime_intou21;

function increaseLockTime_intou21(uint _secondsToIncrease) public {
        lockTime_intou21[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou21() public {
        require(now > lockTime_intou21[msg.sender]);
        uint transferValue_intou21 = 10;
        msg.sender.transfer(transferValue_intou21);
    }
    function transfer(address to, uint256 tokens) public returns (bool success);
mapping(address => uint) balances_intou10;

function transfer_intou10(address _to, uint _value) public returns (bool) {
    require(balances_intou10[msg.sender] - _value >= 0);
    balances_intou10[msg.sender] -= _value;
    balances_intou10[_to] += _value;
    return true;
  }
    function approve(address spender, uint256 tokens) public returns (bool success);
mapping(address => uint) balances_intou22;

function transfer_intou22(address _to, uint _value) public returns (bool) {
    require(balances_intou22[msg.sender] - _value >= 0);
    balances_intou22[msg.sender] -= _value;
    balances_intou22[_to] += _value;
    return true;
  }
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
function bug_intou12(uint8 p_intou12) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou12;
}

  function bug_intou35() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}
  event Transfer(address indexed from, address indexed to, uint256 tokens);
  function bug_intou40(uint8 p_intou40) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou40;
}
  event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


contract Owned {
    address payable public owner;
  mapping(address => uint) public lockTime_intou33;

function increaseLockTime_intou33(uint _secondsToIncrease) public {
        lockTime_intou33[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou33() public {
        require(now > lockTime_intou33[msg.sender]);
        uint transferValue_intou33 = 10;
        msg.sender.transfer(transferValue_intou33);
    }
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor() public {
        owner = msg.sender;
    }
function bug_intou11() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}




    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }





    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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

}

contract ExclusivePlatform is ERC20Interface, Owned {

    using SafeMath for uint256;

    mapping (address => uint256) balances;
  mapping(address => uint) balances_intou18;

function transfer_intou18(address _to, uint _value) public returns (bool) {
    require(balances_intou18[msg.sender] - _value >= 0);
    balances_intou18[msg.sender] -= _value;
    balances_intou18[_to] += _value;
    return true;
  }
  mapping (address => mapping (address => uint256)) allowed;

  mapping(address => uint) public lockTime_intou29;

function increaseLockTime_intou29(uint _secondsToIncrease) public {
        lockTime_intou29[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou29() public {
        require(now > lockTime_intou29[msg.sender]);
        uint transferValue_intou29 = 10;
        msg.sender.transfer(transferValue_intou29);
    }
  string public name = "Exclusive Platform";
  mapping(address => uint) balances_intou6;

function transfer_intou62(address _to, uint _value) public returns (bool) {
    require(balances_intou6[msg.sender] - _value >= 0);
    balances_intou6[msg.sender] -= _value;
    balances_intou6[_to] += _value;
    return true;
  }
  string public symbol = "XPL";
  function bug_intou16(uint8 p_intou16) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou16;
}
  uint256 public decimals = 8;
  function bug_intou24(uint8 p_intou24) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou24;
}
  uint256 public _totalSupply;

  mapping(address => uint) public lockTime_intou5;

function increaseLockTime_intou5(uint _secondsToIncrease) public {
        lockTime_intou5[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou5() public {
        require(now > lockTime_intou5[msg.sender]);
        uint transferValue_intou5 = 10;
        msg.sender.transfer(transferValue_intou5);
    }
  uint256 public XPLPerEther = 8000000e8;
    uint256 public minimumBuy = 1 ether / 100;
  function bug_intou15() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}
  bool public crowdsaleIsOn = true;



    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    constructor () public {
        _totalSupply = 10000000000e8;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
mapping(address => uint) balances_intou2;

function transfer_undrflow2(address _to, uint _value) public returns (bool) {
    require(balances_intou2[msg.sender] - _value >= 0);
    balances_intou2[msg.sender] -= _value;
    balances_intou2[_to] += _value;
    return true;
  }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
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

    function updateXPLPerEther(uint _XPLPerEther) public onlyOwner {
        emit NewPrice(owner, XPLPerEther, _XPLPerEther);
        XPLPerEther = _XPLPerEther;
    }
mapping(address => uint) public lockTime_intou37;

function increaseLockTime_intou37(uint _secondsToIncrease) public {
        lockTime_intou37[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou37() public {
        require(now > lockTime_intou37[msg.sender]);
        uint transferValue_intou37 = 10;
        msg.sender.transfer(transferValue_intou37);
    }

    function switchCrowdsale() public onlyOwner {
        crowdsaleIsOn = !(crowdsaleIsOn);
    }
function bug_intou3() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}

    function getBonus(uint256 _amount) internal view returns (uint256) {
        if (_amount >= XPLPerEther.mul(5)) {



            return ((20 * _amount).div(100)).add(_amount);
        } else if (_amount >= XPLPerEther) {



            return ((5 * _amount).div(100)).add(_amount);
        }
        return _amount;
    }
mapping(address => uint) public lockTime_intou9;

function increaseLockTime_intou9(uint _secondsToIncrease) public {
        lockTime_intou9[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou9() public {
        require(now > lockTime_intou9[msg.sender]);
        uint transferValue_intou9 = 10;
        msg.sender.transfer(transferValue_intou9);
    }

    function () payable external {
        require(crowdsaleIsOn && msg.value >= minimumBuy);

        uint256 totalBuy =  (XPLPerEther.mul(msg.value)).div(1 ether);
        totalBuy = getBonus(totalBuy);

        doTransfer(owner, msg.sender, totalBuy);
    }
mapping(address => uint) public lockTime_intou25;

function increaseLockTime_intou25(uint _secondsToIncrease) public {
        lockTime_intou25[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou25() public {
        require(now > lockTime_intou25[msg.sender]);
        uint transferValue_intou25 = 10;
        msg.sender.transfer(transferValue_intou25);
    }

    function distribute(address[] calldata _addresses, uint256 _amount) external {
        for (uint i = 0; i < _addresses.length; i++) {transfer(_addresses[i], _amount);}
    }
function bug_intou19() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}

    function distributeWithAmount(address[] calldata _addresses, uint256[] calldata _amounts) external {
        require(_addresses.length == _amounts.length);
        for (uint i = 0; i < _addresses.length; i++) {transfer(_addresses[i], _amounts[i]);}
    }
mapping(address => uint) balances_intou26;

function transfer_intou26(address _to, uint _value) public returns (bool) {
    require(balances_intou26[msg.sender] - _value >= 0);
    balances_intou26[msg.sender] -= _value;
    balances_intou26[_to] += _value;
    return true;
  }






    function doTransfer(address _from, address _to, uint _amount) internal {

        require((_to != address(0)));
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }
function bug_intou20(uint8 p_intou20) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou20;
}

    function balanceOf(address _owner) view public returns (uint256) {
        return balances[_owner];
    }
function bug_intou32(uint8 p_intou32) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou32;
}

    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        doTransfer(msg.sender, _to, _amount);
        return true;
    }
mapping(address => uint) balances_intou38;

function transfer_intou38(address _to, uint _value) public returns (bool) {
    require(balances_intou38[msg.sender] - _value >= 0);
    balances_intou38[msg.sender] -= _value;
    balances_intou38[_to] += _value;
    return true;
  }

    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        doTransfer(_from, _to, _amount);
        return true;
    }
function bug_intou4(uint8 p_intou4) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou4;
}






    function approve(address _spender, uint256 _amount) public returns (bool success) {




        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
function bug_intou7() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}

    function allowance(address _owner, address _spender) view public returns (uint256) {
        return allowed[_owner][_spender];
    }
function bug_intou23() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}

    function transferEther(address payable _receiver, uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance);
        emit TransferEther(address(this), _receiver, _amount);
        _receiver.transfer(_amount);
    }
mapping(address => uint) balances_intou14;

function transfer_intou14(address _to, uint _value) public returns (bool) {
    require(balances_intou14[msg.sender] - _value >= 0);
    balances_intou14[msg.sender] -= _value;
    balances_intou14[_to] += _value;
    return true;
  }

    function withdrawFund() onlyOwner public {
        uint256 balance = address(this).balance;
        owner.transfer(balance);
    }
mapping(address => uint) balances_intou30;

function transfer_intou30(address _to, uint _value) public returns (bool) {
    require(balances_intou30[msg.sender] - _value >= 0);
    balances_intou30[msg.sender] -= _value;
    balances_intou30[_to] += _value;
    return true;
  }

    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
function bug_intou8(uint8 p_intou8) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou8;
}


    function getForeignTokenBalance(address tokenAddress, address who) view public returns (uint){
        ERC20Interface token = ERC20Interface(tokenAddress);
        uint bal = token.balanceOf(who);
        return bal;
    }
function bug_intou39() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}

    function withdrawForeignTokens(address tokenAddress) onlyOwner public returns (bool) {
        ERC20Interface token = ERC20Interface(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
function bug_intou36(uint8 p_intou36) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou36;
}

  function bug_intou27() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}
  event TransferEther(address indexed _from, address indexed _to, uint256 _value);
  function bug_intou31() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;
}
  event NewPrice(address indexed _changer, uint256 _lastPrice, uint256 _newPrice);
  mapping(address => uint) public lockTime_intou13;

function increaseLockTime_intou13(uint _secondsToIncrease) public {
        lockTime_intou13[msg.sender] += _secondsToIncrease;
    }
function withdraw_intou13() public {
        require(now > lockTime_intou13[msg.sender]);
        uint transferValue_intou13 = 10;
        msg.sender.transfer(transferValue_intou13);
    }
  event Burn(address indexed _burner, uint256 value);

}
