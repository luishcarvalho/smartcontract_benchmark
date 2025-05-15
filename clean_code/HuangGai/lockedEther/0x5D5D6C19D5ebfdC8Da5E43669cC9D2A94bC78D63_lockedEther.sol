



pragma solidity ^0.6.6;






library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }





	function transferOwnership(address newOwner) public onlyOwner {
		if (newOwner != address(0)) {
			owner = newOwner;
			emit OwnershipTransferred(owner, newOwner);
		}
	}
}




contract Tokenlock is Owned {
  uint8 isLocked = 0;
  event Freezed();
  event UnFreezed();
  modifier validLock {
    require(isLocked == 0);
    _;
  }
  function freeze() public onlyOwner {
    isLocked = 1;
    emit Freezed();
  }
  function unfreeze() public onlyOwner {
    isLocked = 0;
    emit UnFreezed();
  }


  mapping(address => bool) blacklist;
  event LockUser(address indexed who);
  event UnlockUser(address indexed who);

  modifier permissionCheck {
    require(!blacklist[msg.sender]);
    _;
  }

  function lockUser(address who) public onlyOwner {
    blacklist[who] = true;
    emit LockUser(who);
  }

  function unlockUser(address who) public onlyOwner {
    blacklist[who] = false;
    emit UnlockUser(who);
  }

}


contract Timi is Tokenlock {

    using SafeMath for uint;
    string public name = "Timi Finance";
    string public symbol = "Timi";
    uint8  public decimals = 18;
    uint  internal _rate=100;
    uint  internal _amount;
    uint256  public totalSupply;


    mapping(address => uint)  bank_balances;

    mapping(address => uint) activeBalances;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 value);
    event Burn(address indexed _from, uint256 value);

	event Issue(uint amount);

	event Redeem(uint amount);

    event Sent(address from, address to, uint amount);
    event FallbackCalled(address sent, uint amount);




	modifier onlyPayloadSize(uint size) {
		require(!(msg.data.length < size + 4));
		_;
	}

    constructor (uint totalAmount) public{
        totalSupply =  totalAmount * 10**uint256(decimals);
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }












    function balanceOfBank(address tokenOwner) public  view returns (uint balance) {
        return bank_balances[tokenOwner];
    }

    function balanceOfReg(address tokenOwner) public  view returns (uint balance) {
        return activeBalances[tokenOwner];
    }




    function balanceOf(address tokenOwner) public  view returns (uint balance) {
        return balances[tokenOwner];
    }






    function allowance(address tokenOwner, address spender) public   view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }







	function issue(uint amount) public onlyOwner {
		require(totalSupply + amount > totalSupply);
		require(balances[owner] + amount > balances[owner]);

		balances[owner] += amount;
		totalSupply += amount;
		emit Issue(amount);
	}







	function redeem(uint amount) public onlyOwner {
		require(totalSupply >= amount);
		require(balances[owner] >= amount);

		totalSupply -= amount;
		balances[owner] -= amount;
		emit Redeem(amount);
	}






    function transfer(address to, uint tokens) public  validLock permissionCheck onlyPayloadSize(2 * 32) returns (bool success) {
        require(to != address(0));
        require(balances[msg.sender] >= tokens && tokens > 0);
        require(balances[to] + tokens >= balances[to]);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }










    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }










    function transferFrom(address from, address to, uint tokens) public  validLock permissionCheck onlyPayloadSize(3 * 32) returns (bool success) {
        require(to != address(0));

        require(balances[from] >= tokens && tokens > 0);
        require(balances[to] + tokens >= balances[to]);


        balances[from] = balances[from].sub(tokens);
        if(allowed[from][msg.sender] > 0)
        {
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        }
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }











    function transferStore(address from, address to, uint tokens) public  validLock permissionCheck onlyPayloadSize(3 * 32) returns (bool success) {
        require(to != address(0));

        require(balances[from] >= tokens && tokens > 0);
        require(balances[to] + tokens >= balances[to]);


        balances[from] = balances[from].sub(tokens);
        if(allowed[from][msg.sender] > 0)
        {
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        }
        balances[to] = balances[to].add(tokens);


        bank_balances[from] = bank_balances[from].add(tokens);


        emit Transfer(from, to, tokens);
        return true;
    }





    function transferAnyERC20Token(address tokenAddress, uint tokens) public  onlyOwner {

        address(uint160(tokenAddress)).transfer(0);
        emit Sent(owner,tokenAddress,tokens);
    }




    function withdraw() onlyOwner public {
        msg.sender.transfer(0);
        _amount = 0;
    }

    function showAmount() onlyOwner public view returns (uint) {
        return _amount;
    }

    function showBalance() onlyOwner public view returns (uint) {
        return owner.balance;
    }




    function set_rate(uint _vlue) public onlyOwner{
        require(_vlue > 0);
        _rate = _vlue;
    }




    receive() external  payable{



        _amount=_amount.add(msg.value);
        activeBalances[msg.sender] = activeBalances[msg.sender].add(msg.value);
    }




    function recharge() public payable{
        _amount=_amount.add(msg.value);
        activeBalances[msg.sender] = activeBalances[msg.sender].add(msg.value);
    }

}
