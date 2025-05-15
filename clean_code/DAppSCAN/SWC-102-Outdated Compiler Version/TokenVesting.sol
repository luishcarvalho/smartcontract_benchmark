




contract Token {


    function totalSupply() constant returns (uint256 supply) {}



    function balanceOf(address _owner) constant returns (uint256 balance) {}





    function transfer(address _to, uint256 _value) returns (bool success) {}






    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}





    function approve(address _spender, uint256 _value) returns (bool success) {}




    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}






contract StandardToken is Token {





    function transfer(address _to, uint256 _value) returns (bool success) {



        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {

            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {

            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

}
























contract TokenVesting {
	address public tokenRecepient;
	uint public freezePeriod;
	uint public initialAmount;
	uint public amount;
  uint public period;

    uint256 public initialVestAmount;
    uint256 public vestAmount;

	uint public vestingStartBlock;
	uint public initialVestingBlock;
	uint public nextVestingBlock;

	StandardToken token;

	event Vested(uint256 amount);

	function TokenVesting(address _tokenRecepient, uint _freezePeriod, uint _initialAmount, uint _period,  uint _amount,address _tokenContract){

        if (_initialAmount == 0 || _amount == 0 || _initialAmount > 100 || _amount > 100) throw;
		tokenRecepient = _tokenRecepient;
		initialAmount = _initialAmount;
		freezePeriod = _freezePeriod;
		amount = _amount;
		period = _period;
		token = StandardToken(_tokenContract);
	}


	function activate(){


		if (token.balanceOf(this) <= 0) throw;
		if (msg.sender != tokenRecepient) throw;
		if (nextVestingBlock != 0x0) throw;
		nextVestingBlock = block.number + freezePeriod;
        initialVestAmount = token.balanceOf(this) * initialAmount / 100;
        vestAmount = token.balanceOf(this) * amount / 100;
	}


	function initial(){

		if (msg.sender != tokenRecepient) throw;

		if (initialVestingBlock != 0x0) throw;

		if (nextVestingBlock > block.number) throw;

		initialVestingBlock = block.number;
		nextVestingBlock = block.number + period;
		sendTokens(initialVestAmount);
	}

	function vest(){
		if (msg.sender != tokenRecepient) throw;
		if (initialVestingBlock == 0x0) throw;
		if (nextVestingBlock > block.number) throw;
		sendTokens(vestAmount);
		nextVestingBlock = block.number + period;
	}


	function sendTokens(uint256 _amount) private {
	    uint256 vestAmount = _amount;
		if (token.balanceOf(this) < _amount )
		{

		    vestAmount = token.balanceOf(this);
		}

		token.transfer(tokenRecepient,vestAmount);
		Vested(vestAmount);
	}
}
