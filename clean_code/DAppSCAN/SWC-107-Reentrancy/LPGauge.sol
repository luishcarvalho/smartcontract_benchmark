




pragma solidity ^0.6.11;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../Interfaces/IMinter.sol";

contract LPGauge is ReentrancyGuard {
	using SafeERC20 for IERC20;
	using Address for address;
    using SafeMath for uint256;

    address public governance;
    address public STACK;
    address public token;

    uint256 public emissionRate;

    uint256 public deposited;


    uint256 public constant startBlock = 300;
    uint256 public endBlock = startBlock + 100;



    uint256 public lastBlock;
    uint256 public tokensAccrued;

    struct DepositState{
    	uint256 balance;
    	uint256 tokensAccrued;
    }

    mapping(address => DepositState) public balances;

    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount);

    constructor(address _STACK, address _token, uint256 _emissionRate) public {
    	governance = msg.sender;

    	STACK = _STACK;
    	token = _token;
    	emissionRate = _emissionRate;
    }

    function setGovernance(address _new) external {
    	require(msg.sender == governance);
    	governance = _new;
    }

    function setEmissionRate(uint256 _new) external {
    	require(msg.sender == governance, "LPGAUGE: !governance");
    	_kick();
    	emissionRate = _new;
    }

    function setEndBlock(uint256 _block) external {
    	require(msg.sender == governance, "LPGAUGE: !governance");
    	require(block.number <= endBlock, "LPGAUGE: distribution already done, must start another");
        require(block.number <= _block, "LPGAUGE: can't set endBlock to past block");

    	endBlock = _block;
    }

    function deposit(uint256 _amount) nonReentrant external {
    	require(block.number <= endBlock, "LPGAUGE: distribution over");

    	_claimSTACK(msg.sender);

    	IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

    	DepositState memory _state = balances[msg.sender];
    	_state.balance = _state.balance.add(_amount);
    	deposited = deposited.add(_amount);

    	emit Deposit(msg.sender, _amount);

    	balances[msg.sender] = _state;
    }

    function withdraw(uint256 _amount) nonReentrant external {
    	_claimSTACK(msg.sender);

    	uint256 _amtToWithdraw = 0;

    	DepositState memory _state = balances[msg.sender];

    	require(_amount <= _state.balance, "LPGAUGE: insufficient balance");

    	_state.balance = _state.balance.sub(_amount);
    	deposited = deposited.sub(_amount);
    	_amtToWithdraw = _amtToWithdraw.add(_amount);

    	emit Withdraw(msg.sender, _amount);

    	balances[msg.sender] = _state;

    	IERC20(token).safeTransfer(msg.sender, _amtToWithdraw);
    }

    function claimSTACK() nonReentrant external {
    	_claimSTACK(msg.sender);
    }

    function _claimSTACK(address _user) internal {
    	_kick();

    	DepositState memory _state = balances[_user];
    	if (_state.tokensAccrued == tokensAccrued){
    		return;
    	}
    	else {
    		uint256 _tokensAccruedDiff = tokensAccrued.sub(_state.tokensAccrued);
    		uint256 _tokensGive = _tokensAccruedDiff.mul(_state.balance).div(1e18);

    		_state.tokensAccrued = tokensAccrued;
    		balances[_user] = _state;

    		IERC20(STACK).safeTransfer(_user, _tokensGive);
    	}
    }

    function _kick() internal {
    	uint256 _totalDeposited = deposited;

    	if (_totalDeposited == 0){
    		return;
    	}

    	if (lastBlock == block.number || lastBlock >= endBlock || block.number < startBlock){
    		return;
    	}

    	if (IMinter(STACK).minters(address(this))){

    		uint256 _deltaBlock;

    		if (lastBlock <= startBlock && block.number >= endBlock){
    			_deltaBlock = endBlock.sub(startBlock);
    		}

    		else if (block.number >= endBlock){
    			_deltaBlock = endBlock.sub(lastBlock);
    		}

    		else if (lastBlock <= startBlock){
    			_deltaBlock = block.number.sub(startBlock);
    		}

    		else {
    			_deltaBlock = block.number.sub(lastBlock);
    		}

    		uint256 _tokensToMint = _deltaBlock.mul(emissionRate);
    		tokensAccrued = tokensAccrued.add(_tokensToMint.mul(1e18).div(_totalDeposited));
    		IMinter(STACK).mint(address(this), _tokensToMint);
    	}



    	lastBlock = block.number;
    }
}
