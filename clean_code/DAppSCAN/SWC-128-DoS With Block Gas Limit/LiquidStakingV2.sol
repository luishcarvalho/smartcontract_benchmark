
pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "./interfaces/ISTokens.sol";
import "./interfaces/IUTokens.sol";
import "./interfaces/ILiquidStaking.sol";
import "./libraries/FullMath.sol";

contract LiquidStakingV2 is
	ILiquidStaking,
	PausableUpgradeable,
	AccessControlUpgradeable
{
	using SafeMathUpgradeable for uint256;
	using FullMath for uint256;


	IUTokens public _uTokens;
	ISTokens public _sTokens;


	uint256 private _minStake;
	uint256 private _minUnstake;
	uint256 private _stakeFee;
	uint256 private _unstakeFee;
	uint256 private _valueDivisor;


	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");


	uint256 private _unstakingLockTime;
	uint256 private _epochInterval;
	uint256 private _unstakeEpoch;
	uint256 private _unstakeEpochPrevious;


	mapping(address => uint256[]) private _unstakingExpiration;


	mapping(address => uint256[]) private _unstakingAmount;


	mapping(address => uint256) internal _withdrawCounters;










	function initialize(
		address uAddress,
		address sAddress,
		address pauserAddress,
		uint256 unstakingLockTime,
		uint256 epochInterval,
		uint256 valueDivisor
	) public virtual initializer {
		__AccessControl_init();
		__Pausable_init();
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(PAUSER_ROLE, pauserAddress);
		setUTokensContract(uAddress);
		setSTokensContract(sAddress);
		setUnstakingLockTime(unstakingLockTime);
		setMinimumValues(1, 1);
		_valueDivisor = valueDivisor;
		setUnstakeEpoch(block.timestamp, block.timestamp, epochInterval);
	}









	function setFees(uint256 stakeFee, uint256 unstakeFee)
		public
		virtual
		returns (bool success)
	{
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ1");


		require(
			(stakeFee <= _valueDivisor.mul(100) || stakeFee == 0) &&
				(unstakeFee <= _valueDivisor.mul(100) || unstakeFee == 0),
			"LQ2"
		);
		_stakeFee = stakeFee;
		_unstakeFee = unstakeFee;
		emit SetFees(stakeFee, unstakeFee);
		return true;
	}








	function setUnstakingLockTime(uint256 unstakingLockTime)
		public
		virtual
		returns (bool success)
	{
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ3");
		_unstakingLockTime = unstakingLockTime;
		emit SetUnstakingLockTime(unstakingLockTime);
		return true;
	}





	function getStakeUnstakeProps()
		public
		view
		virtual
		returns (
			uint256 stakeFee,
			uint256 unstakeFee,
			uint256 minStake,
			uint256 minUnstake,
			uint256 valueDivisor,
			uint256 epochInterval,
			uint256 unstakeEpoch,
			uint256 unstakeEpochPrevious,
			uint256 unstakingLockTime
		)
	{
		stakeFee = _stakeFee;
		unstakeFee = _unstakeFee;
		minStake = _minStake;
		minUnstake = _minStake;
		valueDivisor = _valueDivisor;
		epochInterval = _epochInterval;
		unstakeEpoch = _unstakeEpoch;
		unstakeEpochPrevious = _unstakeEpochPrevious;
		unstakingLockTime = _unstakingLockTime;
	}









	function setMinimumValues(uint256 minStake, uint256 minUnstake)
		public
		virtual
		returns (bool success)
	{
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ4");
		require(minStake >= 1, "LQ5");
		require(minUnstake >= 1, "LQ6");
		_minStake = minStake;
		_minUnstake = minUnstake;
		emit SetMinimumValues(minStake, minUnstake);
		return true;
	}










	function setUnstakeEpoch(
		uint256 unstakeEpoch,
		uint256 unstakeEpochPrevious,
		uint256 epochInterval
	) public virtual returns (bool success) {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ7");
		require(unstakeEpochPrevious <= unstakeEpoch, "LQ8");

		if (unstakeEpoch == 0 && epochInterval != 0) revert("LQ9");
		_unstakeEpoch = unstakeEpoch;
		_unstakeEpochPrevious = unstakeEpochPrevious;
		_epochInterval = epochInterval;
		emit SetUnstakeEpoch(unstakeEpoch, unstakeEpochPrevious, epochInterval);
		return true;
	}








	function setUTokensContract(address uAddress) public virtual override {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ10");
		_uTokens = IUTokens(uAddress);
		emit SetUTokensContract(uAddress);
	}








	function setSTokensContract(address sAddress) public virtual override {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "LQ11");
		_sTokens = ISTokens(sAddress);
		emit SetSTokensContract(sAddress);
	}












	function stake(address to, uint256 amount)
		public
		virtual
		override
		whenNotPaused
		returns (bool)
	{

		require(to == _msgSender(), "LQ12");

		uint256 _currentUTokenBalance = _uTokens.balanceOf(to);
		uint256 _stakeFeeAmount = (amount.mulDiv(_stakeFee, _valueDivisor)).div(
			100
		);
		uint256 _finalTokens = amount.add(_stakeFeeAmount);


		require(amount >= _minStake, "LQ13");
		require(_currentUTokenBalance >= _finalTokens, "LQ14");
		emit StakeTokens(to, amount, _finalTokens, block.timestamp);

		_uTokens.burn(to, _finalTokens);

		_sTokens.mint(to, amount);
		return true;
	}












	function unStake(address to, uint256 amount)
		public
		virtual
		override
		whenNotPaused
		returns (bool)
	{

		require(to == _msgSender(), "LQ15");


		uint256 _currentSTokenBalance = _sTokens.balanceOf(to);
		uint256 _unstakeFeeAmount = (amount.mulDiv(_unstakeFee, _valueDivisor))
			.div(100);
		uint256 _finalTokens = amount.add(_unstakeFeeAmount);


		require(amount >= _minUnstake, "LQ18");
		require(_currentSTokenBalance >= _finalTokens, "LQ19");

		_sTokens.burn(to, _finalTokens);
		_unstakingExpiration[to].push(block.timestamp);


		_unstakingAmount[to].push(amount);

		emit UnstakeTokens(to, amount, _finalTokens, block.timestamp);

		return true;
	}




	function getUnstakeEpochMilestone(uint256 _unstakeTimestamp)
		public
		view
		virtual
		override
		returns (uint256 unstakeEpochMilestone)
	{
		if (_unstakeTimestamp == 0) return 0;

		if (
			(_unstakeEpoch == 0 && _unstakeEpochPrevious == 0) ||
			_epochInterval == 0
		) return _unstakeTimestamp;
		if (_unstakeEpoch > _unstakeTimestamp) return (_unstakeEpoch);
		uint256 _referenceStartTime = (_unstakeTimestamp).add(
			_unstakeEpoch.sub(_unstakeEpochPrevious)
		);
		uint256 _timeDiff = _referenceStartTime.sub(_unstakeEpoch);
		unstakeEpochMilestone = (_timeDiff.mod(_epochInterval)).add(
			_referenceStartTime
		);
		return (unstakeEpochMilestone);
	}




	function getUnstakeTime(uint256 _unstakeTimestamp)
		public
		view
		virtual
		override
		returns (
			uint256 unstakeTime,
			uint256 unstakeEpoch,
			uint256 unstakeEpochPrevious
		)
	{
		uint256 _unstakeEpochMilestone = getUnstakeEpochMilestone(
			_unstakeTimestamp
		);
		if (_unstakeEpochMilestone == 0)
			return (0, unstakeEpoch, unstakeEpochPrevious);
		unstakeEpoch = _unstakeEpoch;
		unstakeEpochPrevious = _unstakeEpochPrevious;

		unstakeTime = _unstakeEpochMilestone.add(_unstakingLockTime);
		return (unstakeTime, unstakeEpoch, unstakeEpochPrevious);
	}











	function withdrawUnstakedTokens(address staker)
		public
		virtual
		override
		whenNotPaused
	{
		require(staker == _msgSender(), "LQ20");
		uint256 _withdrawBalance;
		uint256 _unstakingExpirationLength = _unstakingExpiration[staker]
			.length;
		uint256 _counter = _withdrawCounters[staker];
		for (
			uint256 i = _counter;
			i < _unstakingExpirationLength;
			i = i.add(1)
		) {

			(uint256 _getUnstakeTime, , ) = getUnstakeTime(
				_unstakingExpiration[staker][i]
			);
			if (block.timestamp >= _getUnstakeTime) {

				_withdrawBalance = _withdrawBalance.add(
					_unstakingAmount[staker][i]
				);
				_unstakingExpiration[staker][i] = 0;
				_unstakingAmount[staker][i] = 0;
				_withdrawCounters[staker] = _withdrawCounters[staker].add(1);
			}
		}

		require(_withdrawBalance > 0, "LQ21");
		emit WithdrawUnstakeTokens(staker, _withdrawBalance, block.timestamp);
		_uTokens.mint(staker, _withdrawBalance);
	}






	function getTotalUnbondedTokens(address staker)
		public
		view
		virtual
		override
		returns (uint256 unbondingTokens)
	{
		uint256 _unstakingExpirationLength = _unstakingExpiration[staker]
			.length;
		uint256 _counter = _withdrawCounters[staker];
		for (
			uint256 i = _counter;
			i < _unstakingExpirationLength;
			i = i.add(1)
		) {

			(uint256 _getUnstakeTime, , ) = getUnstakeTime(
				_unstakingExpiration[staker][i]
			);
			if (block.timestamp >= _getUnstakeTime) {

				unbondingTokens = unbondingTokens.add(
					_unstakingAmount[staker][i]
				);
			}
		}
		return unbondingTokens;
	}






	function getTotalUnbondingTokens(address staker)
		public
		view
		virtual
		override
		returns (uint256 unbondingTokens)
	{
		uint256 _unstakingExpirationLength = _unstakingExpiration[staker]
			.length;
		uint256 _counter = _withdrawCounters[staker];
		for (
			uint256 i = _counter;
			i < _unstakingExpirationLength;
			i = i.add(1)
		) {

			(uint256 _getUnstakeTime, , ) = getUnstakeTime(
				_unstakingExpiration[staker][i]
			);
			if (block.timestamp < _getUnstakeTime) {

				unbondingTokens = unbondingTokens.add(
					_unstakingAmount[staker][i]
				);
			}
		}
		return unbondingTokens;
	}








	function pause() public virtual returns (bool success) {
		require(hasRole(PAUSER_ROLE, _msgSender()), "LQ22");
		_pause();
		return true;
	}








	function unpause() public virtual returns (bool success) {
		require(hasRole(PAUSER_ROLE, _msgSender()), "LQ23");
		_unpause();
		return true;
	}
}
