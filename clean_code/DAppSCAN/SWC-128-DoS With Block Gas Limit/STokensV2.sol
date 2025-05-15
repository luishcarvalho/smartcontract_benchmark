
pragma solidity >=0.7.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/ISTokens.sol";
import "./interfaces/IUTokens.sol";
import "./interfaces/IHolder.sol";
import "./libraries/FullMath.sol";

contract STokensV2 is
	ERC20Upgradeable,
	ISTokens,
	PausableUpgradeable,
	AccessControlUpgradeable
{
	using SafeMathUpgradeable for uint256;
	using FullMath for uint256;
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;


	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");



	EnumerableSetUpgradeable.AddressSet private _whitelistedAddresses;

	mapping(address => address) public _holderContractAddress;

	mapping(address => address) public _lpContractAddress;



	mapping(address => uint256) public _lastHolderRewardTimestamp;


	address public _liquidStakingContract;

	IUTokens public _uTokens;


	uint256[] private _rewardRate;
	uint256[] private _lastMovingRewardTimestamp;
	uint256 private _valueDivisor;
	mapping(address => uint256) private _lastUserRewardTimestamp;








	function initialize(
		address uaddress,
		address pauserAddress,
		uint256 rewardRate,
		uint256 valueDivisor
	) public virtual initializer {
		__ERC20_init("pSTAKE Staked ATOM", "stkATOM");
		__AccessControl_init();
		__Pausable_init();
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(PAUSER_ROLE, pauserAddress);
		setUTokensContract(uaddress);
		_valueDivisor = valueDivisor;
		require(rewardRate <= _valueDivisor.mul(100), "ST1");
		_rewardRate.push(rewardRate);
		_lastMovingRewardTimestamp.push(block.timestamp);
		_setupDecimals(6);
	}





	function isContractWhitelisted(address whitelistedAddress)
		public
		view
		virtual
		override
		returns (bool result)
	{
		result = _whitelistedAddresses.contains(whitelistedAddress);
		return result;
	}





	function getHolderData(address whitelistedAddress)
		public
		view
		virtual
		override
		returns (
			address holderAddress,
			address lpAddress,
			uint256 lastHolderRewardTimestamp
		)
	{

		holderAddress = _holderContractAddress[whitelistedAddress];
		lpAddress = _lpContractAddress[whitelistedAddress];
		lastHolderRewardTimestamp = _lastHolderRewardTimestamp[
			whitelistedAddress
		];
	}












	function setRewardRate(uint256 rewardRate)
		public
		virtual
		override
		returns (bool success)
	{


		require(rewardRate <= _valueDivisor.mul(100), "ST17");
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ST2");
		_rewardRate.push(rewardRate);
		_lastMovingRewardTimestamp.push(block.timestamp);
		emit SetRewardRate(rewardRate);

		return true;
	}




	function getRewardRate()
		public
		view
		virtual
		returns (uint256[] memory rewardRate, uint256 valueDivisor)
	{
		rewardRate = _rewardRate;
		valueDivisor = _valueDivisor;
	}





	function getLastUserRewardTimestamp(address to)
		public
		view
		virtual
		returns (uint256 lastUserRewardTimestamp)
	{
		lastUserRewardTimestamp = _lastUserRewardTimestamp[to];
	}












	function mint(address to, uint256 tokens)
		public
		virtual
		override
		returns (bool)
	{
		require(_msgSender() == _liquidStakingContract, "ST3");
		_mint(to, tokens);
		return true;
	}












	function burn(address from, uint256 tokens)
		public
		virtual
		override
		returns (bool)
	{
		require(_msgSender() == _liquidStakingContract, "ST4");
		_burn(from, tokens);
		return true;
	}






	function _calculatePendingRewards(
		uint256 principal,
		uint256 lastRewardTimestamp
	) internal view returns (uint256 pendingRewards) {
		uint256 _index;
		uint256 _rewardBlocks;
		uint256 _simpleInterestOfInterval;
		uint256 _temp;

		if (principal == 0 || block.timestamp.sub(lastRewardTimestamp) == 0)
			return 0;

		uint256 _lastMovingRewardLength = _lastMovingRewardTimestamp.length.sub(
			1
		);
		for (_index = _lastMovingRewardLength; _index >= 0; ) {

			if (_index < _lastMovingRewardTimestamp.length.sub(1)) {
				if (_lastMovingRewardTimestamp[_index] > lastRewardTimestamp) {
					_rewardBlocks = (_lastMovingRewardTimestamp[_index.add(1)])
						.sub(_lastMovingRewardTimestamp[_index]);
					_temp = principal.mulDiv(_rewardRate[_index], 100);
					_simpleInterestOfInterval = _temp.mulDiv(
						_rewardBlocks,
						_valueDivisor
					);
					pendingRewards = pendingRewards.add(
						_simpleInterestOfInterval
					);
				} else {
					_rewardBlocks = (_lastMovingRewardTimestamp[_index.add(1)])
						.sub(lastRewardTimestamp);
					_temp = principal.mulDiv(_rewardRate[_index], 100);
					_simpleInterestOfInterval = _temp.mulDiv(
						_rewardBlocks,
						_valueDivisor
					);
					pendingRewards = pendingRewards.add(
						_simpleInterestOfInterval
					);
					break;
				}
			}

			else {
				if (_lastMovingRewardTimestamp[_index] > lastRewardTimestamp) {
					_rewardBlocks = (block.timestamp).sub(
						_lastMovingRewardTimestamp[_index]
					);
					_temp = principal.mulDiv(_rewardRate[_index], 100);
					_simpleInterestOfInterval = _temp.mulDiv(
						_rewardBlocks,
						_valueDivisor
					);
					pendingRewards = pendingRewards.add(
						_simpleInterestOfInterval
					);
				} else {
					_rewardBlocks = (block.timestamp).sub(lastRewardTimestamp);
					_temp = principal.mulDiv(_rewardRate[_index], 100);
					_simpleInterestOfInterval = _temp.mulDiv(
						_rewardBlocks,
						_valueDivisor
					);
					pendingRewards = pendingRewards.add(
						_simpleInterestOfInterval
					);
					break;
				}
			}

			if (_index == 0) break;
			else {
				_index = _index.sub(1);
			}
		}
		return pendingRewards;
	}





	function calculatePendingRewards(address to)
		public
		view
		virtual
		override
		returns (uint256 pendingRewards)
	{

		uint256 _lastRewardTimestamp = _lastUserRewardTimestamp[to];

		uint256 _balance = balanceOf(to);

		pendingRewards = _calculatePendingRewards(
			_balance,
			_lastRewardTimestamp
		);

		return pendingRewards;
	}





	function _calculateRewards(address to) internal returns (uint256) {

		uint256 _reward = calculatePendingRewards(to);



		_lastUserRewardTimestamp[to] = block.timestamp;


		if (_reward > 0) {

			_uTokens.mint(to, _reward);
		}

		emit CalculateRewards(to, _reward, block.timestamp);
		return _reward;
	}








	function calculateRewards(address to)
		public
		virtual
		override
		whenNotPaused
		returns (bool success)
	{
		require(to == _msgSender(), "ST5");
		uint256 reward = _calculateRewards(to);
		emit TriggeredCalculateRewards(to, reward, block.timestamp);
		return true;
	}





	function _calculateHolderRewards(
		address to,
		address from,
		uint256 amount
	) internal returns (uint256 rewards) {



		require(
			_whitelistedAddresses.contains(to) &&
				_holderContractAddress[to] != address(0) &&
				_lpContractAddress[to] != address(0),
			"ST6"
		);
		uint256 _sTokenSupply = IHolder(_holderContractAddress[to])
			.getSTokenSupply(to, from, amount);


		rewards = _calculatePendingRewards(
			_sTokenSupply,
			_lastHolderRewardTimestamp[to]
		);


		_lastHolderRewardTimestamp[to] = block.timestamp;


		if (rewards > 0) {
			_uTokens.mint(_holderContractAddress[to], rewards);
		}

		emit CalculateHolderRewards(to, rewards, block.timestamp);
		return rewards;
	}








	function calculateHolderRewards(
		address to,
		address from,
		uint256 amount
	) public virtual override whenNotPaused returns (bool success) {
		require(to != address(0) && to != address(0), "ST16");
		uint256 rewards = _calculateHolderRewards(to, from, amount);
		emit TriggeredCalculateHolderRewards(to, rewards, block.timestamp);
		return true;
	}














	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual override {
		require(!paused(), "ST7");
		super._beforeTokenTransfer(from, to, amount);


		if (from == address(0)) {



			if (!_whitelistedAddresses.contains(to)) {
				_calculateRewards(to);
			} else {

				_calculateHolderRewards(to, from, amount);
			}
		}

		if (from != address(0) && !_whitelistedAddresses.contains(from)) {
			if (to == address(0)) {
				_calculateRewards(from);
			}

			if (to != address(0) && !_whitelistedAddresses.contains(to)) {
				_calculateRewards(from);
				_calculateRewards(to);
			}

			if (to != address(0) && _whitelistedAddresses.contains(to)) {
				_calculateRewards(from);

				_calculateHolderRewards(to, from, amount);
			}
		}

		if (from != address(0) && _whitelistedAddresses.contains(from)) {
			if (to == address(0)) {

				_calculateHolderRewards(from, to, amount);
			}

			if (to != address(0) && !_whitelistedAddresses.contains(to)) {

				_calculateHolderRewards(from, to, amount);
				_calculateRewards(to);
			}

			if (to != address(0) && _whitelistedAddresses.contains(to)) {

				_calculateHolderRewards(from, address(0), amount);


				_calculateHolderRewards(to, address(0), amount);
			}
		}
	}








	function setWhitelistedAddress(
		address whitelistedAddress,
		address holderContractAddress,
		address lpContractAddress
	) public virtual returns (bool success) {
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ST8");

		require(whitelistedAddress != address(0), "ST9");

		if (!_whitelistedAddresses.contains(whitelistedAddress))
			_whitelistedAddresses.add(whitelistedAddress);

		_holderContractAddress[whitelistedAddress] = holderContractAddress;
		_lpContractAddress[whitelistedAddress] = lpContractAddress;

		emit SetWhitelistedAddress(
			whitelistedAddress,
			holderContractAddress,
			lpContractAddress,
			block.timestamp
		);
		success = true;
		return success;
	}









	function removeWhitelistedAddress(address whitelistedAddress)
		public
		virtual
		returns (bool success)
	{
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ST10");
		require(whitelistedAddress != address(0), "ST11");

		_whitelistedAddresses.remove(whitelistedAddress);
		address _holderContractAddressLocal = _holderContractAddress[
			whitelistedAddress
		];
		address _lpContractAddressLocal = _lpContractAddress[
			whitelistedAddress
		];


		delete _holderContractAddress[whitelistedAddress];
		delete _lpContractAddress[whitelistedAddress];

		emit RemoveWhitelistedAddress(
			whitelistedAddress,
			_holderContractAddressLocal,
			_lpContractAddressLocal,
			block.timestamp
		);
		success = true;
		return success;
	}








	function setUTokensContract(address uTokenContract)
		public
		virtual
		override
	{
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ST12");
		_uTokens = IUTokens(uTokenContract);
		emit SetUTokensContract(uTokenContract);
	}








	function setLiquidStakingContract(address liquidStakingContract)
		public
		virtual
		override
	{
		require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ST13");
		_liquidStakingContract = liquidStakingContract;
		emit SetLiquidStakingContract(liquidStakingContract);
	}








	function pause() public virtual returns (bool success) {
		require(hasRole(PAUSER_ROLE, _msgSender()), "ST14");
		_pause();
		return true;
	}








	function unpause() public virtual returns (bool success) {
		require(hasRole(PAUSER_ROLE, _msgSender()), "ST15");
		_unpause();
		return true;
	}
}
