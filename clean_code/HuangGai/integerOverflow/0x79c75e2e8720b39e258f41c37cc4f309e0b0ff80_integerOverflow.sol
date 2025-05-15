





pragma solidity ^0.7.0;

abstract contract Pausable {



    event Paused(address account);




    event Unpaused(address account);

    bool private _paused;




    constructor () {
        _paused = false;
    }




    function paused() public view returns (bool) {
        return _paused;
    }








    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }








    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }








    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }








    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}














library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }










    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }












    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }












    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract PhantasmaToken is Pausable {

	using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private _burnAddresses;

	uint256 private _totalSupply;
    address private _producer;

	function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = 0;
		_producer = msg.sender;
		addNodeAddress(msg.sender);
    }

    function addNodeAddress(address _address) public {
		require(msg.sender == _producer);
		require(!_burnAddresses[msg.sender]);
        _burnAddresses[_address] = true;
    }

    function deleteNodeAddress(address _address) public {
		require(msg.sender == _producer);
        require(_burnAddresses[_address]);
        _burnAddresses[_address] = true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!paused(), "transfer while paused" );
        require(_balances[msg.sender] >= _value);

        if (_burnAddresses[_to]) {

           return swapOut(msg.sender, _to, _value);

        } else {

            _balances[msg.sender] = _balances[msg.sender].sub(_value);
            _balances[_to] = _balances[_to].add(_value);

            emit Transfer(msg.sender, _to, _value);
            return true;

        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!paused(), "transferFrom while paused");

        uint256 allowance = _allowances[_from][msg.sender];
        require(_balances[_from] >= _value && allowance >= _value);

        _balances[_to] = _balances[_to].add(_value);

        _balances[_from] = _balances[_from].sub(_value);

        if (allowance < MAX_UINT256) {
            _allowances[_from][msg.sender] -= _value;
        }

        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        require(!paused(), "allowance while paused");
        return _allowances[_owner][_spender];
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function swapInit(address newProducer) public returns (bool success) {
		require(msg.sender == _producer);
		_burnAddresses[_producer] = false;
		_producer = newProducer;
		_burnAddresses[newProducer] = true;
		emit SwapInit(msg.sender, newProducer);
		return true;
    }

    function swapIn(address source, address target, uint256 amount) public returns (bool success) {
        require(!paused(), "swapIn while paused" );
		require(msg.sender == _producer);
        _totalSupply = _totalSupply.add(amount);

        _balances[target] = _balances[target].add(amount);

        emit Transfer(source, target, amount);
		return true;
    }

    function swapOut(address source, address target, uint256 amount) private returns (bool success) {
		require(msg.sender == source, "sender != source");
		require(_balances[source] >= amount);
		require(_totalSupply >= amount);

        _totalSupply = _totalSupply.sub(amount);
        _balances[source] = _balances[source].sub(amount);
        emit Transfer(source, target, amount);
		return true;
    }

    function pause() public {
		require(msg.sender == _producer);
        _pause();
    }

    function unpause() public {
		require(msg.sender == _producer);
        _unpause();
    }



    event SwapInit(address indexed _from, address indexed _to);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
