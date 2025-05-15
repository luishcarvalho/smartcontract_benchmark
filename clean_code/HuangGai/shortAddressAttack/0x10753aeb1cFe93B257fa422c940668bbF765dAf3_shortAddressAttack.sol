pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;


interface Erc1820Registry {
	function setInterfaceImplementer(address _target, bytes32 _interfaceHash, address _implementer) external;
}


contract Erc777TokensRecipient {
	constructor() public {

		Erc1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24).setInterfaceImplementer(address(this), 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b, address(this));
	}


	function tokensReceived(address, address, address, uint256, bytes calldata, bytes calldata) external { }





	function canImplementInterfaceForAddress(bytes32 _interfaceHash, address _implementer) external view returns(bytes32) {

		if (_implementer == address(this) && _interfaceHash == 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b) {

			return 0xa2ef4600d742022d532d4747cb3547474667d6f13804902513b2ec01c848f4b4;
		} else {
			return bytes32(0);
		}
	}
}






library EnumerableMap {
	struct Entry {
		address key;
		uint16 value;
	}

	struct Map {
		mapping (address => uint256) index;
		Entry[] entries;
	}

	function initialize(Map storage map) internal {

		map.entries.push();
	}

	function contains(Map storage map, address key) internal view returns (bool) {
		return map.index[key] != 0;
	}

	function set(Map storage map, address key, uint16 value) internal {
		uint256 index = map.index[key];
		if (index == 0) {

			Entry memory entry = Entry({ key: key, value: value });
			map.entries.push(entry);
			map.index[key] = map.entries.length - 1;
		} else {

			map.entries[index].value = value;
		}

		require(map.entries[map.index[key]].key == key, "Key at inserted location does not match inserted key.");
		require(map.entries[map.index[key]].value == value, "Value at inserted location does not match inserted value.");
	}

	function remove(Map storage map, address key) internal {

		uint256 index = map.index[key];


		if (index == 0) return;


		uint256 lastIndex = map.entries.length - 1;
		if (index != lastIndex) {
			Entry storage lastEntry = map.entries[lastIndex];
			map.entries[index] = lastEntry;
			map.index[lastEntry.key] = index;
		}


		map.entries.pop();


		delete map.index[key];

		require(map.index[key] == 0, "Removed key still exists in the index.");
		require(index == lastIndex || map.entries[index].key != key, "Removed key still exists in the array at original index.");
	}

	function get(Map storage map, address key) internal view returns (uint16) {
		uint256 index = map.index[key];
		require(index != 0, "Provided key was not in the map.");
		return map.entries[index].value;
	}


	function enumerate(Map storage map) internal view returns (Entry[] memory) {

		Entry[] memory output = new Entry[](map.entries.length - 1);


		for (uint256 i = 1; i < map.entries.length; ++i) {
			output[i - 1] = map.entries[i];
		}
		return output;
	}
}


contract RecoverableWallet is Erc777TokensRecipient {
	using EnumerableMap for EnumerableMap.Map;

	event RecoveryAddressAdded(address indexed newRecoverer, uint16 recoveryDelayInDays);
	event RecoveryAddressRemoved(address indexed oldRecoverer);
	event RecoveryStarted(address indexed newOwner);
	event RecoveryCancelled(address indexed oldRecoverer);
	event RecoveryFinished(address indexed oldOwner, address indexed newOwner);

	address public owner;


	EnumerableMap.Map private recoveryDelaysInDays;

	address public activeRecoveryAddress;

	uint256 public activeRecoveryEndTime = uint256(-1);


	modifier onlyOwner() {
		require(msg.sender == owner, "Only the owner may call this method.");
		_;
	}


	modifier onlyDuringRecovery() {
		require(activeRecoveryAddress != address(0), "This method can only be called during a recovery.");
		_;
	}


	modifier onlyOutsideRecovery() {
		require(activeRecoveryAddress == address(0), "This method cannot be called during a recovery.");
		_;
	}

	constructor(address _initialOwner) public {
		require(_initialOwner != address(0), "Wallet must have an initial owner.");
		owner = _initialOwner;
		recoveryDelaysInDays.initialize();
	}

	function listRecoverers() external view returns (EnumerableMap.Entry[] memory) {
		return recoveryDelaysInDays.enumerate();
	}

	function getRecoveryDelayInDays(address recoverer) external view returns (uint16) {
		return recoveryDelaysInDays.get(recoverer);
	}


	receive () external payable { }




	function addRecoveryAddress(address _newRecoveryAddress, uint16 _recoveryDelayInDays) external onlyOwner onlyOutsideRecovery {
		require(_newRecoveryAddress != address(0), "Recovery address must be supplied.");
		recoveryDelaysInDays.set(_newRecoveryAddress, _recoveryDelayInDays);
		emit RecoveryAddressAdded(_newRecoveryAddress, _recoveryDelayInDays);
	}



	function removeRecoveryAddress(address _oldRecoveryAddress) public onlyOwner onlyOutsideRecovery {
		require(_oldRecoveryAddress != address(0), "Recovery address must be supplied.");
		recoveryDelaysInDays.remove(_oldRecoveryAddress);
		emit RecoveryAddressRemoved(_oldRecoveryAddress);
	}


	function startRecovery() external {
		require(recoveryDelaysInDays.contains(msg.sender), "Caller is not registered as a recoverer for this wallet.");
		uint16 _proposedRecoveryDelayInDays = recoveryDelaysInDays.get(msg.sender);

		bool _inRecovery = activeRecoveryAddress != address(0);
		if (_inRecovery) {

			uint16 _activeRecoveryDelayInDays = recoveryDelaysInDays.get(activeRecoveryAddress);
			require(_proposedRecoveryDelayInDays < _activeRecoveryDelayInDays, "Recovery is already under way and new recoverer doesn't have a higher priority.");
			emit RecoveryCancelled(activeRecoveryAddress);
		}

		activeRecoveryAddress = msg.sender;
		activeRecoveryEndTime = block.timestamp + _proposedRecoveryDelayInDays * 1 days;
		emit RecoveryStarted(msg.sender);
	}



	function cancelRecovery() public onlyOwner onlyDuringRecovery {
		address _recoveryAddress = activeRecoveryAddress;
		resetRecovery();
		emit RecoveryCancelled(_recoveryAddress);
	}


	function cancelRecoveryAndRemoveRecoveryAddress() external onlyOwner onlyDuringRecovery {
		address _recoveryAddress = activeRecoveryAddress;
		cancelRecovery();
		removeRecoveryAddress(_recoveryAddress);
	}


	function finishRecovery() external onlyDuringRecovery {
		require(block.timestamp >= activeRecoveryEndTime, "You must wait until the recovery delay is over before finishing the recovery.");

		address _oldOwner = owner;
		owner = activeRecoveryAddress;
		resetRecovery();
		emit RecoveryFinished(_oldOwner, owner);
	}






	function deploy(uint256 _value, bytes calldata _data, uint256 _salt) external payable onlyOwner onlyOutsideRecovery returns (address) {
		require(address(this).balance >= _value, "Wallet does not have enough funds available to deploy the contract.");
		require(_data.length != 0, "Contract deployment must contain bytecode to deploy.");
		bytes memory _data2 = _data;
		address newContract;

		assembly { newContract := create2(_value, add(_data2, 32), mload(_data2), _salt) }
		require(newContract != address(0), "Contract creation returned address 0, indicating failure.");
		return newContract;
	}






	function execute(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner onlyOutsideRecovery returns (bytes memory) {
		require(_to != address(0), "Transaction execution must contain a destination.  If you meant to deploy a contract, use deploy instead.");
		require(address(this).balance >= _value, "Wallet does not have enough funds available to execute the desired transaction.");
		(bool _success, bytes memory _result) = _to.call.value(_value)(_data);

		require(_success, "Contract execution failed.");
		return _result;
	}

	function resetRecovery() private {
		activeRecoveryAddress = address(0);
		activeRecoveryEndTime = uint256(-1);
	}
}


contract RecoverableWalletFactory {
	event WalletCreated(address indexed owner, RecoverableWallet indexed wallet);


	function createWallet() external returns (RecoverableWallet) {
		RecoverableWallet wallet = new RecoverableWallet(msg.sender);
		emit WalletCreated(msg.sender, wallet);
		return wallet;
	}


	function exists() external pure returns (bytes32) {
		return 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
	}
}
