





pragma solidity ^0.6.12;

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c ;

        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c ;

        require(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c ;

        require(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    function min256(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}


interface ISupplyController {
	function mint(address token, address owner, uint amount) external;
}

interface IADXToken {
	function transfer(address to, uint256 amount) external returns (bool);
	function transferFrom(address from, address to, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function balanceOf(address spender) external view returns (uint);
	function allowance(address owner, address spender) external view returns (uint);
	function supplyController() external view returns (ISupplyController);
}

contract ADXLoyaltyPoolToken {
	using SafeMath for uint;



	string public constant name = "AdEx Loyalty";
	uint8 public constant decimals = 18;
	string public symbol ;



	bytes32 public DOMAIN_SEPARATOR;

	bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
	mapping(address => uint) public nonces;


	uint public totalSupply;
	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;

	event Approval(address indexed owner, address indexed spender, uint amount);
	event Transfer(address indexed from, address indexed to, uint amount);

	function balanceOf(address owner) external view returns (uint balance) {
		return balances[owner];
	}

	function transfer(address to, uint amount) external returns (bool success) {
		require(to != address(this), 'BAD_ADDRESS');
		balances[msg.sender] = balances[msg.sender].sub(amount);
		balances[to] = balances[to].add(amount);
		emit Transfer(msg.sender, to, amount);
		return true;
	}

	function transferFrom(address from, address to, uint amount) external returns (bool success) {
		balances[from] = balances[from].sub(amount);
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
		balances[to] = balances[to].add(amount);
		emit Transfer(from, to, amount);
		return true;
	}

	function approve(address spender, uint amount) external returns (bool success) {
		allowed[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function allowance(address owner, address spender) external view returns (uint remaining) {
		return allowed[owner][spender];
	}


	function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
		require(deadline >= block.timestamp, 'DEADLINE_EXPIRED');
		bytes32 digest ;

		address recoveredAddress ;

		require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');
		allowed[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}


	function innerMint(address owner, uint amount) internal {
		totalSupply = totalSupply.add(amount);
		balances[owner] = balances[owner].add(amount);

		emit Transfer(address(0), owner, amount);
	}
	function innerBurn(address owner, uint amount) internal {
		totalSupply = totalSupply.sub(amount);
		balances[owner] = balances[owner].sub(amount);
		emit Transfer(owner, address(0), amount);
	}


	IADXToken public ADXToken;
	uint public incentivePerTokenPerAnnum;
	uint public lastMintTime;
	uint public maxTotalADX;
	mapping (address => bool) public governance;
	constructor(IADXToken token, uint incentive, uint cap) public {
		ADXToken = token;
		incentivePerTokenPerAnnum = incentive;
		maxTotalADX = cap;
		governance[msg.sender] = true;
		lastMintTime = block.timestamp;

		uint chainId;
		assembly {
			chainId := chainid()
		}
		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
				keccak256(bytes(name)),
				keccak256(bytes('1')),
				chainId,
				address(this)
			)
		);
	}


	function setGovernance(address addr, bool hasGovt) external {
		require(governance[msg.sender], 'NOT_GOVERNANCE');
		governance[addr] = hasGovt;
	}

	function setIncentive(uint newIncentive) external {
		require(governance[msg.sender], 'NOT_GOVERNANCE');
		incentivePerTokenPerAnnum = newIncentive;
		lastMintTime = block.timestamp;
	}
	function setSymbol(string calldata newSymbol) external {
		require(governance[msg.sender], 'NOT_GOVERNANCE');
		symbol = newSymbol;
	}
	function setMaxTotalADX(uint newMaxTotalADX) external {
		require(governance[msg.sender], 'NOT_GOVERNANCE');
		maxTotalADX = newMaxTotalADX;
	}







	function toMint() external view returns (uint) {
		if (block.timestamp <= lastMintTime) return 0;
		uint totalADX ;

		return (block.timestamp - lastMintTime)
			.mul(totalADX)
			.mul(incentivePerTokenPerAnnum)
			.div(365 days * 10e17);
	}
	function shareValue() external view returns (uint) {
		if (totalSupply == 0) return 0;
		return ADXToken.balanceOf(address(this))
			.add(this.toMint())
			.mul(10e17)
			.div(totalSupply);
	}

	function mintIncentive() public {
		if (incentivePerTokenPerAnnum == 0) return;
		uint amountToMint ;

		if (amountToMint == 0) return;
		lastMintTime = block.timestamp;
		ADXToken.supplyController().mint(address(ADXToken), address(this), amountToMint);
	}

	function enter(uint256 amount) external {



		mintIncentive();

		uint totalADX ;

		require(totalADX < maxTotalADX, 'REACHED_MAX_TOTAL_ADX');

		if (totalSupply == 0 || totalADX == 0) {
			innerMint(msg.sender, amount);
		} else {
			uint256 newShares ;

			innerMint(msg.sender, newShares);
		}
		ADXToken.transferFrom(msg.sender, address(this), amount);
	}

	function leave(uint256 shares) public {
		uint256 totalADX ;

		uint256 adxAmount ;

		innerBurn(msg.sender, shares);
		ADXToken.transfer(msg.sender, adxAmount);
	}

	function mintAndLeave(uint256 shares) external {
		mintIncentive();
		leave(shares);
	}
}
