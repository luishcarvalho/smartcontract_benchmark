





pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../Interfaces/IMinter.sol";

contract VCTreasuryV1 is ERC20, ReentrancyGuard {
	using SafeERC20 for IERC20;
	using Address for address;
    using SafeMath for uint256;

	address public councilMultisig;
	address public deployer;
	address payable public treasury;

	enum FundStates {setup, active, paused, closed}
	FundStates public currentState;

	uint256 public fundStartTime;
	uint256 public fundCloseTime;

	uint256 public totalStakedToPause;
	uint256 public totalStakedToKill;
	mapping(address => uint256) stakedToPause;
	mapping(address => uint256) stakedToKill;
	bool public killed;
	address public constant BET_TOKEN = 0xfdd4E938Bb067280a52AC4e02AaF1502Cc882bA6;
	address public constant STACK_TOKEN = 0x514910771AF9Ca656af840dff83E8264EcF986CA;



	uint256 public constant LOOP_LIMIT = 50;


	uint256 public initETH;
	uint256 public constant investmentCap = 200;
	uint256 public maxInvestment;

	uint256 public constant pauseQuorum = 300;
	uint256 public constant killQuorum = 500;
	uint256 public constant max = 1000;


	uint256 public currentInvestmentUtilization;
	uint256 public lastInvestTime;

	uint256 public constant ONE_YEAR = 365 days;
	uint256 public constant THIRTY_DAYS = 30 days;
	uint256 public constant THREE_DAYS = 3 days;
	uint256 public constant ONE_WEEK = 7 days;

	struct BuyProposal {
		uint256 buyId;
		address tokenAccept;
		uint256 amountInMin;
		uint256 ethOut;
		address taker;
		uint256 maxTime;
	}

	BuyProposal public currentBuyProposal;
	uint256 public nextBuyId;
	mapping(address => bool) public boughtTokens;

	struct SellProposal {
		address tokenSell;
		uint256 ethInMin;
		uint256 amountOut;
		address taker;
		uint256 vetoTime;
		uint256 maxTime;
	}

	mapping(uint256 => SellProposal) public currentSellProposals;
	uint256 public nextSellId;


	uint256 public constant stackFee = 25;
	uint256 public constant councilFee = 25;

	event InvestmentProposed(uint256 buyId, address tokenAccept, uint256 amountInMin, uint256 amountOut, address taker, uint256 maxTime);
	event InvestmentRevoked(uint256 buyId, uint256 time);
	event InvestmentExecuted(uint256 buyId, address tokenAccept, uint256 amountIn, uint256 amountOut, address taker, uint256 time);
	event DevestmentProposed(uint256 sellId, address tokenSell, uint256 ethInMin, uint256 amountOut, address taker, uint256 vetoTime, uint256 maxTime);
	event DevestmentRevoked(uint256 sellId, uint256 time);
	event DevestmentExecuted(uint256 sellId, address tokenSell, uint256 ethIn, uint256 amountOut, address taker, uint256 time);

	constructor(address _multisig, address payable _treasury) public ERC20("Stacker.vc Fund001", "SVC001") {
		deployer = msg.sender;
		councilMultisig = _multisig;
		treasury = _treasury;

		currentState = FundStates.setup;

		_setupDecimals(18);
	}


	receive() payable external {
		return;
	}


	function setCouncilMultisig(address _new) external {
		require(msg.sender == councilMultisig, "TREASURYV1: !councilMultisig");
		councilMultisig = _new;
	}


	function setDeployer(address _new) external {
		require(msg.sender == councilMultisig || msg.sender == deployer, "TREASURYV1: !(councilMultisig || deployer)");
		deployer = _new;
	}

	function setTreasury(address payable _new) external {
		require(msg.sender == treasury, "TREASURYV1: !treasury");
		treasury = _new;
	}


	function setBoughtToken(address _new) external {
		require(msg.sender == councilMultisig, "TREASURYV1: !councilMultisig");
		boughtTokens[_new] = true;
	}



	function getBoughtToken(address _token) external view returns (bool){
		return boughtTokens[_token];
	}

	function getStakedToPause(address _user) external view returns (uint256){
		return stakedToPause[_user];
	}

	function getStakedToKill(address _user) external view returns (uint256){
		return stakedToKill[_user];
	}

	function getSellProposal(uint256 _sellId) external view returns (SellProposal memory){
		return currentSellProposals[_sellId];
	}




	function issueTokens(address[] calldata _user, uint256[] calldata _amount) external {
		require(currentState == FundStates.setup, "TREASURYV1: !FundStates.setup");
		require(msg.sender == deployer, "TREASURYV1: !deployer");
		require(_user.length == _amount.length, "TREASURYV1: length mismatch");
		require(_user.length <= LOOP_LIMIT, "TREASURYV1: length > LOOP_LIMIT");

		for (uint256 i = 0; i < _user.length; i++){
			_mint(_user[i], _amount[i]);
		}
	}


	function startFund() payable external {
		require(currentState == FundStates.setup, "TREASURYV1: !FundStates.setup");
		require(msg.sender == councilMultisig, "TREASURYV1: !councilMultisig");
		require(totalSupply() > 0, "TREASURYV1: invalid setup");

		fundStartTime = block.timestamp;
		fundCloseTime = block.timestamp.add(ONE_YEAR);

		initETH = msg.value;

		maxInvestment = msg.value.div(max).mul(investmentCap);

		_changeFundState(FundStates.active);
	}


	function investPropose(address _tokenAccept, uint256 _amountInMin, uint256 _ethOut, address _taker) external {
		_checkCloseTime();
		require(currentState == FundStates.active, "TREASURYV1: !FundStates.active");
		require(msg.sender == councilMultisig, "TREASURYV1: !councilMultisig");


		_updateInvestmentUtilization(_ethOut);

		BuyProposal memory _buy;
		_buy.buyId = nextBuyId;
		_buy.tokenAccept = _tokenAccept;
		_buy.amountInMin = _amountInMin;
		_buy.ethOut = _ethOut;
		_buy.taker = _taker;
		_buy.maxTime = block.timestamp.add(THREE_DAYS);

		currentBuyProposal = _buy;
		nextBuyId = nextBuyId.add(1);

		InvestmentProposed(_buy.buyId, _tokenAccept, _amountInMin, _ethOut, _taker, _buy.maxTime);
	}


	function investRevoke(uint256 _buyId) external {
		_checkCloseTime();
		require(currentState == FundStates.active || currentState == FundStates.paused, "TREASURYV1: !(FundStates.active || FundStates.paused)");
		require(msg.sender == councilMultisig, "TREASURYV1: !councilMultisig");

		BuyProposal memory _buy = currentBuyProposal;
		require(_buyId == _buy.buyId, "TREASURYV1: buyId not active");

		BuyProposal memory _reset;
		currentBuyProposal = _reset;

		InvestmentRevoked(_buy.buyId, block.timestamp);
	}


	function investExecute(uint256 _buyId, uint256 _amount) nonReentrant external  {
		_checkCloseTime();
		require(currentState == FundStates.active, "TREASURYV1: !FundStates.active");

		BuyProposal memory _buy = currentBuyProposal;
		require(_buyId == _buy.buyId, "TREASURYV1: buyId not active");
		require(_buy.tokenAccept != address(0), "TREASURYV1: !tokenAccept");
		require(_amount >= _buy.amountInMin, "TREASURYV1: _amount < amountInMin");
		require(_buy.taker == msg.sender || _buy.taker == address(0), "TREASURYV1: !taker");
		require(block.timestamp <= _buy.maxTime, "TREASURYV1: time > maxTime");

		BuyProposal memory _reset;
		currentBuyProposal = _reset;

		uint256 _before = IERC20(_buy.tokenAccept).balanceOf(address(this));
		IERC20(_buy.tokenAccept).safeTransferFrom(msg.sender, address(this), _amount);
		uint256 _after = IERC20(_buy.tokenAccept).balanceOf(address(this));
		require(_after.sub(_before) >= _buy.amountInMin, "TREASURYV1: received < amountInMin");

		boughtTokens[_buy.tokenAccept] = true;

		InvestmentExecuted(_buy.buyId, _buy.tokenAccept, _amount, _buy.ethOut, msg.sender, block.timestamp);

		msg.sender.transfer(_buy.ethOut);
	}


	function devestPropose(address _tokenSell, uint256 _ethInMin, uint256 _amountOut, address _taker) external {
		_checkCloseTime();
		require(currentState == FundStates.active, "TREASURYV1: !FundStates.active");
		require(msg.sender == councilMultisig, "TREASURYV1: !councilMultisig");

		SellProposal memory _sell;
		_sell.tokenSell = _tokenSell;
		_sell.ethInMin = _ethInMin;
		_sell.amountOut = _amountOut;
		_sell.taker = _taker;
		_sell.vetoTime = block.timestamp.add(THREE_DAYS);
		_sell.maxTime = block.timestamp.add(THREE_DAYS).add(THREE_DAYS);

		currentSellProposals[nextSellId] = _sell;

		DevestmentProposed(nextSellId, _tokenSell, _ethInMin, _amountOut, _taker, _sell.vetoTime, _sell.maxTime);

		nextSellId = nextSellId.add(1);
	}


	function devestRevoke(uint256 _sellId) external {
		_checkCloseTime();
		require(currentState == FundStates.active || currentState == FundStates.paused, "TREASURYV1: !(FundStates.active || FundStates.paused)");
		require(msg.sender == councilMultisig, "TREASURYV1: !councilMultisig");
		require(_sellId < nextSellId, "TREASURYV1: !sellId");

		SellProposal memory _reset;
		currentSellProposals[_sellId] = _reset;

		DevestmentRevoked(_sellId, block.timestamp);
	}


	function devestExecute(uint256 _sellId) nonReentrant external payable {
		_checkCloseTime();
		require(currentState == FundStates.active, "TREASURYV1: !FundStates.active");

		SellProposal memory _sell = currentSellProposals[_sellId];
		require(_sell.tokenSell != address(0), "TREASURYV1: !tokenSell");
		require(msg.value >= _sell.ethInMin, "TREASURYV1: <ethInMin");
		require(_sell.taker == msg.sender || _sell.taker == address(0), "TREASURYV1: !taker");
		require(block.timestamp > _sell.vetoTime, "TREASURYV1: time < vetoTime");
		require(block.timestamp <= _sell.maxTime, "TREASURYV1: time > maxTime");

		SellProposal memory _reset;
		currentSellProposals[_sellId] = _reset;

		DevestmentExecuted(_sellId, _sell.tokenSell, msg.value, _sell.amountOut, msg.sender, block.timestamp);
		IERC20(_sell.tokenSell).safeTransfer(msg.sender, _sell.amountOut);


		if (IERC20(_sell.tokenSell).balanceOf(address(this)) == 0){
			boughtTokens[_sell.tokenSell] = false;
		}
	}




	function stakeToPause(uint256 _amount) external {
		_checkCloseTime();
		require(currentState == FundStates.active || currentState == FundStates.paused, "TREASURYV1: !(FundStates.active || FundStates.paused)");
		require(balanceOf(msg.sender) >= _amount, "TREASURYV1: insufficient balance to stakeToPause");

		_transfer(msg.sender, address(this), _amount);

		stakedToPause[msg.sender] = stakedToPause[msg.sender].add(_amount);
		totalStakedToPause = totalStakedToPause.add(_amount);

		_updateFundStateAfterStake();
	}



	function stakeToKill(uint256 _amount) external {
		_checkCloseTime();
		require(currentState == FundStates.active || currentState == FundStates.paused, "TREASURYV1: !(FundStates.active || FundStates.paused)");
		require(balanceOf(msg.sender) >= _amount, "TREASURYV1: insufficient balance to stakeToKill");

		_transfer(msg.sender, address(this), _amount);

		stakedToKill[msg.sender] = stakedToKill[msg.sender].add(_amount);
		totalStakedToKill = totalStakedToKill.add(_amount);

		_updateFundStateAfterStake();
	}

	function unstakeToPause(uint256 _amount) external {
		_checkCloseTime();
		require(currentState != FundStates.setup, "TREASURYV1: FundStates.setup");
		require(stakedToPause[msg.sender] >= _amount, "TREASURYV1: insufficent balance to unstakeToPause");

		_transfer(address(this), msg.sender, _amount);

		stakedToPause[msg.sender] = stakedToPause[msg.sender].sub(_amount);
		totalStakedToPause = totalStakedToPause.sub(_amount);

		_updateFundStateAfterStake();
	}

	function unstakeToKill(uint256 _amount) external {
		_checkCloseTime();
		require(currentState != FundStates.setup, "TREASURYV1: FundStates.setup");
		require(stakedToKill[msg.sender] >= _amount, "TREASURYV1: insufficent balance to unstakeToKill");

		_transfer(address(this), msg.sender, _amount);

		stakedToKill[msg.sender] = stakedToKill[msg.sender].sub(_amount);
		totalStakedToKill = totalStakedToKill.sub(_amount);

		_updateFundStateAfterStake();
	}

	function _updateFundStateAfterStake() internal {

		if (currentState == FundStates.closed){
			return;
		}

		if (totalStakedToKill > killQuorumRequirement()){
			killed = true;
			_changeFundState(FundStates.closed);
			return;
		}

		uint256 _pausedStake = totalStakedToPause.add(totalStakedToKill);
		if (_pausedStake > pauseQuorumRequirement() && currentState == FundStates.active){
			_changeFundState(FundStates.paused);
			return;
		}
		if (_pausedStake <= pauseQuorumRequirement() && currentState == FundStates.paused){
			_changeFundState(FundStates.active);
			return;
		}
	}

	function killQuorumRequirement() public view returns (uint256) {
		return totalSupply().div(max).mul(killQuorum);
	}

	function pauseQuorumRequirement() public view returns (uint256) {
		return totalSupply().div(max).mul(pauseQuorum);
	}

	function checkCloseTime() external {
		_checkCloseTime();
	}


	function _checkCloseTime() internal {
		if (block.timestamp >= fundCloseTime && currentState != FundStates.setup){
			_changeFundState(FundStates.closed);
		}
	}

	function _changeFundState(FundStates _state) internal {

		if (currentState == FundStates.closed || _state == FundStates.setup){
			return;
		}
		currentState = _state;


		if (_state == FundStates.closed && !killed){
			_assessFee();
		}
	}


	function _assessFee() internal {
		uint256 _stackAmount = totalSupply().div(max).mul(stackFee);
		uint256 _councilAmount = totalSupply().div(max).mul(councilFee);

		_mint(treasury, _stackAmount);
		_mint(councilMultisig, _councilAmount);
	}


	function claim(address[] calldata _tokens) nonReentrant external {
		_checkCloseTime();
		require(currentState == FundStates.closed, "TREASURYV1: !FundStates.closed");
		require(_tokens.length <= LOOP_LIMIT, "TREASURYV1: length > LOOP_LIMIT");








		uint256 _balance = balanceOf(msg.sender);
		uint256 _proportionE18 = _balance.mul(1e18).div(totalSupply());

		_burn(msg.sender, _balance);


		uint256 _proportionToken = address(this).balance.mul(_proportionE18).div(1e18);
		msg.sender.transfer(_proportionToken);

		for (uint256 i = 0; i < _tokens.length; i++){
			require(_tokens[i] != address(this), "can't claim address(this)");
			require(boughtTokens[_tokens[i]], "!boughtToken");

			if (_tokens[i] == BET_TOKEN || _tokens[i] == STACK_TOKEN){
				require(!killed, "BET/STACK can only be claimed if fund wasn't killed");
			}

			_proportionToken = IERC20(_tokens[i]).balanceOf(address(this)).mul(_proportionE18).div(1e18);
			IERC20(_tokens[i]).safeTransfer(msg.sender, _proportionToken);
		}
	}


	function _updateInvestmentUtilization(uint256 _newInvestment) internal {
		uint256 proposedUtilization = getUtilization(_newInvestment);
		require(proposedUtilization <= maxInvestment, "TREASURYV1: utilization > maxInvestment");

		currentInvestmentUtilization = proposedUtilization;
		lastInvestTime = block.timestamp;
	}


	function getUtilization(uint256 _newInvestment) public view returns (uint256){
		uint256 _lastInvestTimeDiff = block.timestamp.sub(lastInvestTime);
		if (_lastInvestTimeDiff >= THIRTY_DAYS){
			return _newInvestment;
		}
		else {

			uint256 _depreciateUtilization = currentInvestmentUtilization.div(THIRTY_DAYS).mul(THIRTY_DAYS.sub(_lastInvestTimeDiff));
			return _newInvestment.add(_depreciateUtilization);
		}
	}


	function availableToInvest() external view returns (uint256){
		return maxInvestment.sub(getUtilization(0));
	}




	function emergencyEscape(address _tokenContract, uint256 _amount) nonReentrant external {
		require(msg.sender == councilMultisig && !killed && currentState == FundStates.closed, "TREASURYV1: escape check failed");

		if (_tokenContract != address(0)){
			IERC20(_tokenContract).safeTransfer(treasury, _amount);
		}
		else {
			treasury.transfer(_amount);
		}
	}
}
