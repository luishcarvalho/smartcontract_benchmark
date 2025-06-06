




















pragma solidity 0.6.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

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



contract OSP{

    using SafeMath for uint256;


    event StakeEvent(address indexed staker, address indexed pool, uint amount);
    event UnstakeEvent(address indexed unstaker, address indexed pool, uint amount);
    event RewardEvent(address indexed staker, address indexed pool, uint amount);
    event RewardStake(address indexed staker, address indexed pool, uint amount);



    address public Axiatoken;
    address public OracleIndexFunds;

    address public administrator;

    bool public stakingEnabled;

    uint256 constant private FLOAT_SCALAR = 2**64;
    uint256 public MINIMUM_STAKE = 1000000000000000000;
	uint256  public MIN_DIVIDENDS_DUR = 18 hours;

	uint public infocheck;

    struct User {
		uint256 balance;
		uint256 frozen;
		int256 scaledPayout;
		uint256 staketime;
	}

	struct Info {
		uint256 totalSupply;
		uint256 totalFrozen;
		mapping(address => User) users;
		uint256 scaledPayoutPerToken;
		address admin;
	}

	Info private info;


	constructor() public {

        info.admin = msg.sender;
        stakingEnabled = false;
	}



	modifier onlyCreator() {
        require(tx.origin == info.admin, "Ownable: caller is not the administrator");

        _;
    }

    modifier onlyAxiaToken() {
        require(msg.sender == Axiatoken, "Authorization: only token contract can call");
        _;
    }

	 function tokenconfigs(address _axiatoken, address _oracleindex) public onlyCreator returns (bool success) {
	    require(_axiatoken != _oracleindex, "Insertion of same address is not supported");
	    require(_axiatoken != address(0) && _oracleindex != address(0), "Insertion of address(0) is not supported");
        Axiatoken = _axiatoken;
        OracleIndexFunds = _oracleindex;
        return true;
    }

	function _minStakeAmount(uint256 _number) onlyCreator public {

		MINIMUM_STAKE = _number*1000000000000000000;

	}

	function stakingStatus(bool _status) public onlyCreator {
	require(Axiatoken != address(0) && OracleIndexFunds != address(0), "Pool addresses are not yet setup");
	stakingEnabled = _status;
    }

    function MIN_DIVIDENDS_DUR_TIME(uint256 _minDuration) public onlyCreator {

	MIN_DIVIDENDS_DUR = _minDuration;

    }


	function StakeTokens(uint256 _tokens) external {
		_stake(_tokens);
	}

	function UnstakeTokens(uint256 _tokens) external {
		_unstake(_tokens);
	}




	function totalFrozen() public view returns (uint256) {
		return info.totalFrozen;
	}

    function frozenOf(address _user) public view returns (uint256) {
		return info.users[_user].frozen;
	}

	function dividendsOf(address _user) public view returns (uint256) {

	    if(info.users[_user].staketime < MIN_DIVIDENDS_DUR){
	        return 0;
	    }else{
	     return uint256(int256(info.scaledPayoutPerToken * info.users[_user].frozen) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	    }
	}


	function userData(address _user) public view
	returns (uint256 totalTokensFrozen, uint256 userFrozen,
	uint256 userDividends, uint256 userStaketime, int256 scaledPayout) {

		return (totalFrozen(), frozenOf(_user), dividendsOf(_user), info.users[_user].staketime, info.users[_user].scaledPayout);


	}




	function _stake(uint256 _amount) internal {

	    require(stakingEnabled, "Staking not yet initialized");

		require(IERC20(OracleIndexFunds).balanceOf(msg.sender) >= _amount, "Insufficient Oracle AFT token balance");
		require(frozenOf(msg.sender) + _amount >= MINIMUM_STAKE, "Your amount is lower than the minimum amount allowed to stake");
		require(IERC20(OracleIndexFunds).allowance(msg.sender, address(this)) >= _amount, "Not enough allowance given to contract yet to spend by user");

		info.users[msg.sender].staketime = now;
		info.totalFrozen += _amount;
		info.users[msg.sender].frozen += _amount;

		info.users[msg.sender].scaledPayout += int256(_amount * info.scaledPayoutPerToken);
		IERC20(OracleIndexFunds).transferFrom(msg.sender, address(this), _amount);

        emit StakeEvent(msg.sender, address(this), _amount);
	}




	function _unstake(uint256 _amount) internal {

		require(frozenOf(msg.sender) >= _amount, "You currently do not have up to that amount staked");

		info.totalFrozen -= _amount;
		info.users[msg.sender].frozen -= _amount;
		info.users[msg.sender].scaledPayout -= int256(_amount * info.scaledPayoutPerToken);

		require(IERC20(OracleIndexFunds).transfer(msg.sender, _amount), "Transaction failed");
        emit UnstakeEvent(address(this), msg.sender, _amount);

	}


	function TakeDividends() external returns (uint256) {

		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends >= 0, "you do not have any dividend yet");
		info.users[msg.sender].scaledPayout += int256(_dividends * FLOAT_SCALAR);

		require(IERC20(Axiatoken).transfer(msg.sender, _dividends), "Transaction Failed");
		emit RewardEvent(msg.sender, address(this), _dividends);

		return _dividends;


	}


    function scaledToken(uint _amount) external onlyAxiaToken returns(bool){

    		info.scaledPayoutPerToken += _amount * FLOAT_SCALAR / info.totalFrozen;
    		infocheck = info.scaledPayoutPerToken;
    		return true;

    }


    function mulDiv (uint x, uint y, uint z) public pure returns (uint) {
          (uint l, uint h) = fullMul (x, y);
          assert (h < z);
          uint mm = mulmod (x, y, z);
          if (mm > l) h -= 1;
          l -= mm;
          uint pow2 = z & -z;
          z /= pow2;
          l /= pow2;
          l += h * ((-pow2) / pow2 + 1);
          uint r = 1;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          return l * r;
    }

     function fullMul (uint x, uint y) private pure returns (uint l, uint h) {
          uint mm = mulmod (x, y, uint (-1));
          l = x * y;
          h = mm - l;
          if (mm < l) h -= 1;
    }


}
