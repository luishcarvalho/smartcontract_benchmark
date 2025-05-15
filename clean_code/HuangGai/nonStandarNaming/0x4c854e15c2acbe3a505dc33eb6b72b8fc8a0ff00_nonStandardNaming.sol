pragma solidity 0.6.2;
pragma experimental ABIEncoderV2;


interface Erc1820Registry {
	function SETINTERFACEIMPLEMENTER302(address _target, bytes32 _interfaceHash, address _implementer) external;
}


contract Erc777TokensRecipient {
	constructor() public {

		Erc1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24).SETINTERFACEIMPLEMENTER302(address(this), 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b, address(this));
	}


	function TOKENSRECEIVED576(address, address, address, uint256, bytes calldata, bytes calldata) external { }





	function CANIMPLEMENTINTERFACEFORADDRESS796(bytes32 _interfaceHash, address _implementer) external view returns(bytes32) {

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

	function INITIALIZE417(Map storage map) internal {

		map.entries.push();
	}

	function CONTAINS634(Map storage map, address key) internal view returns (bool) {
		return map.index[key] != 0;
	}

	function SET481(Map storage map, address key, uint16 value) internal {
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

	function REMOVE650(Map storage map, address key) internal {

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

	function GET309(Map storage map, address key) internal view returns (uint16) {
		uint256 index = map.index[key];
		require(index != 0, "Provided key was not in the map.");
		return map.entries[index].value;
	}


	function ENUMERATE294(Map storage map) internal view returns (Entry[] memory) {

		Entry[] memory output = new Entry[](map.entries.length - 1);


		for (uint256 i = 1; i < map.entries.length; ++i) {
			output[i - 1] = map.entries[i];
		}
		return output;
	}
}


contract RecoverableWallet is Erc777TokensRecipient {
	using EnumerableMap for EnumerableMap.Map;

	event RECOVERYADDRESSADDED788(address indexed newRecoverer, uint16 recoveryDelayInDays);
	event RECOVERYADDRESSREMOVED981(address indexed oldRecoverer);
	event RECOVERYSTARTED822(address indexed newOwner);
	event RECOVERYCANCELLED820(address indexed oldRecoverer);
	event RECOVERYFINISHED802(address indexed oldOwner, address indexed newOwner);

	address public owner;


	EnumerableMap.Map private recoveryDelaysInDays;

	address public activeRecoveryAddress;

	uint256 public activeRecoveryEndTime = uint256(-1);


	modifier ONLYOWNER488() {
		require(msg.sender == owner, "Only the owner may call this method.");
		_;
	}


	modifier ONLYDURINGRECOVERY592() {
		require(activeRecoveryAddress != address(0), "This method can only be called during a recovery.");
		_;
	}


	modifier ONLYOUTSIDERECOVERY75() {
		require(activeRecoveryAddress == address(0), "This method cannot be called during a recovery.");
		_;
	}

	constructor(address _initialOwner) public {
		require(_initialOwner != address(0), "Wallet must have an initial owner.");
		owner = _initialOwner;
		recoveryDelaysInDays.INITIALIZE417();
	}

	function LISTRECOVERERS745() external view returns (EnumerableMap.Entry[] memory) {
		return recoveryDelaysInDays.ENUMERATE294();
	}

	function GETRECOVERYDELAYINDAYS334(address recoverer) external view returns (uint16) {
		return recoveryDelaysInDays.GET309(recoverer);
	}


	receive () external payable { }




	function ADDRECOVERYADDRESS704(address _newRecoveryAddress, uint16 _recoveryDelayInDays) external ONLYOWNER488 ONLYOUTSIDERECOVERY75 {
		require(_newRecoveryAddress != address(0), "Recovery address must be supplied.");
		recoveryDelaysInDays.SET481(_newRecoveryAddress, _recoveryDelayInDays);
		emit RECOVERYADDRESSADDED788(_newRecoveryAddress, _recoveryDelayInDays);
	}



	function REMOVERECOVERYADDRESS238(address _oldRecoveryAddress) public ONLYOWNER488 ONLYOUTSIDERECOVERY75 {
		require(_oldRecoveryAddress != address(0), "Recovery address must be supplied.");
		recoveryDelaysInDays.REMOVE650(_oldRecoveryAddress);
		emit RECOVERYADDRESSREMOVED981(_oldRecoveryAddress);
	}


	function STARTRECOVERY76() external {
		require(recoveryDelaysInDays.CONTAINS634(msg.sender), "Caller is not registered as a recoverer for this wallet.");
		uint16 _proposedRecoveryDelayInDays = recoveryDelaysInDays.GET309(msg.sender);

		bool _inRecovery = activeRecoveryAddress != address(0);
		if (_inRecovery) {

			uint16 _activeRecoveryDelayInDays = recoveryDelaysInDays.GET309(activeRecoveryAddress);
			require(_proposedRecoveryDelayInDays < _activeRecoveryDelayInDays, "Recovery is already under way and new recoverer doesn't have a higher priority.");
			emit RECOVERYCANCELLED820(activeRecoveryAddress);
		}

		activeRecoveryAddress = msg.sender;
		activeRecoveryEndTime = block.timestamp + _proposedRecoveryDelayInDays * 1 days;
		emit RECOVERYSTARTED822(msg.sender);
	}



	function CANCELRECOVERY426() public ONLYOWNER488 ONLYDURINGRECOVERY592 {
		address _recoveryAddress = activeRecoveryAddress;
		RESETRECOVERY810();
		emit RECOVERYCANCELLED820(_recoveryAddress);
	}


	function CANCELRECOVERYANDREMOVERECOVERYADDRESS810() external ONLYOWNER488 ONLYDURINGRECOVERY592 {
		address _recoveryAddress = activeRecoveryAddress;
		CANCELRECOVERY426();
		REMOVERECOVERYADDRESS238(_recoveryAddress);
	}


	function FINISHRECOVERY886() external ONLYDURINGRECOVERY592 {
		require(block.timestamp >= activeRecoveryEndTime, "You must wait until the recovery delay is over before finishing the recovery.");

		address _oldOwner = owner;
		owner = activeRecoveryAddress;
		RESETRECOVERY810();
		emit RECOVERYFINISHED802(_oldOwner, owner);
	}






	function DEPLOY471(uint256 _value, bytes calldata _data, uint256 _salt) external payable ONLYOWNER488 ONLYOUTSIDERECOVERY75 returns (address) {
		require(address(this).balance >= _value, "Wallet does not have enough funds available to deploy the contract.");
		require(_data.length != 0, "Contract deployment must contain bytecode to deploy.");
		bytes memory _data2 = _data;
		address newContract;

		assembly { newContract := create2(_value, add(_data2, 32), mload(_data2), _salt) }
		require(newContract != address(0), "Contract creation returned address 0, indicating failure.");
		return newContract;
	}






	function EXECUTE479(address payable _to, uint256 _value, bytes calldata _data) external payable ONLYOWNER488 ONLYOUTSIDERECOVERY75 returns (bytes memory) {
		require(_to != address(0), "Transaction execution must contain a destination.  If you meant to deploy a contract, use deploy instead.");
		require(address(this).balance >= _value, "Wallet does not have enough funds available to execute the desired transaction.");
		(bool _success, bytes memory _result) = _to.call.value(_value)(_data);
		require(_success, "Contract execution failed.");
		return _result;
	}

	function RESETRECOVERY810() private {
		activeRecoveryAddress = address(0);
		activeRecoveryEndTime = uint256(-1);
	}
}


contract RecoverableWalletFactory {
	event WALLETCREATED977(address indexed owner, RecoverableWallet indexed wallet);


	function CREATEWALLET42() external returns (RecoverableWallet) {
		RecoverableWallet wallet = new RecoverableWallet(msg.sender);
		emit WALLETCREATED977(msg.sender, wallet);
		return wallet;
	}


	function EXISTS199() external pure returns (bytes32) {
		return 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
	}
}
