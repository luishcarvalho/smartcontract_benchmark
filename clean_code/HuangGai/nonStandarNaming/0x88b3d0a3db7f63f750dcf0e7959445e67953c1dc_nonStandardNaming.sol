pragma solidity >=0.5.4 <0.6.0;

interface tokenRecipient { function RECEIVEAPPROVAL172(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }



library SafeMath {


	function MUL710(uint256 a, uint256 b) internal pure returns (uint256 c) {



		if (a == 0) {
			return 0;
		}

		c = a * b;
		assert(c / a == b);
		return c;
	}


	function DIV595(uint256 a, uint256 b) internal pure returns (uint256) {



		return a / b;
	}


	function SUB853(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}


	function ADD540(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}


interface INameTAOPosition {
	function SENDERISADVOCATE978(address _sender, address _id) external view returns (bool);
	function SENDERISLISTENER841(address _sender, address _id) external view returns (bool);
	function SENDERISSPEAKER648(address _sender, address _id) external view returns (bool);
	function SENDERISPOSITION99(address _sender, address _id) external view returns (bool);
	function GETADVOCATE521(address _id) external view returns (address);
	function NAMEISADVOCATE881(address _nameId, address _id) external view returns (bool);
	function NAMEISPOSITION327(address _nameId, address _id) external view returns (bool);
	function INITIALIZE405(address _id, address _advocateId, address _listenerId, address _speakerId) external returns (bool);
	function DETERMINEPOSITION456(address _sender, address _id) external view returns (uint256);
}















contract TokenERC20 {

	string public name;
	string public symbol;
	uint8 public decimals = 18;

	uint256 public totalSupply;


	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;


	event TRANSFER193(address indexed from, address indexed to, uint256 value);


	event APPROVAL454(address indexed _owner, address indexed _spender, uint256 _value);


	event BURN994(address indexed from, uint256 value);


	constructor (uint256 initialSupply, string memory tokenName, string memory tokenSymbol) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);
		balanceOf[msg.sender] = totalSupply;
		name = tokenName;
		symbol = tokenSymbol;
	}


	function _TRANSFER285(address _from, address _to, uint _value) internal {

		require(_to != address(0));

		require(balanceOf[_from] >= _value);

		require(balanceOf[_to] + _value > balanceOf[_to]);

		uint previousBalances = balanceOf[_from] + balanceOf[_to];

		balanceOf[_from] -= _value;

		balanceOf[_to] += _value;
		emit TRANSFER193(_from, _to, _value);

		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
	}


	function TRANSFER874(address _to, uint256 _value) public returns (bool success) {
		_TRANSFER285(msg.sender, _to, _value);
		return true;
	}


	function TRANSFERFROM282(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_value <= allowance[_from][msg.sender]);
		allowance[_from][msg.sender] -= _value;
		_TRANSFER285(_from, _to, _value);
		return true;
	}


	function APPROVE265(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		emit APPROVAL454(msg.sender, _spender, _value);
		return true;
	}


	function APPROVEANDCALL88(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (APPROVE265(_spender, _value)) {
			spender.RECEIVEAPPROVAL172(msg.sender, _value, address(this), _extraData);
			return true;
		}
	}


	function BURN239(uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);
		balanceOf[msg.sender] -= _value;
		totalSupply -= _value;
		emit BURN994(msg.sender, _value);
		return true;
	}


	function BURNFROM882(address _from, uint256 _value) public returns (bool success) {
		require(balanceOf[_from] >= _value);
		require(_value <= allowance[_from][msg.sender]);
		balanceOf[_from] -= _value;
		allowance[_from][msg.sender] -= _value;
		totalSupply -= _value;
		emit BURN994(_from, _value);
		return true;
	}
}



contract TAO {
	using SafeMath for uint256;

	address public vaultAddress;
	string public name;
	address public originId;


	string public datHash;
	string public database;
	string public keyValue;
	bytes32 public contentId;


	uint8 public typeId;


	constructor (string memory _name,
		address _originId,
		string memory _datHash,
		string memory _database,
		string memory _keyValue,
		bytes32 _contentId,
		address _vaultAddress
	) public {
		name = _name;
		originId = _originId;
		datHash = _datHash;
		database = _database;
		keyValue = _keyValue;
		contentId = _contentId;


		typeId = 0;

		vaultAddress = _vaultAddress;
	}


	modifier ONLYVAULT404 {
		require (msg.sender == vaultAddress);
		_;
	}


	function () external payable {
	}


	function TRANSFERETH144(address payable _recipient, uint256 _amount) public ONLYVAULT404 returns (bool) {
		_recipient.transfer(_amount);
		return true;
	}


	function TRANSFERERC20563(address _erc20TokenAddress, address _recipient, uint256 _amount) public ONLYVAULT404 returns (bool) {
		TokenERC20 _erc20 = TokenERC20(_erc20TokenAddress);
		_erc20.TRANSFER874(_recipient, _amount);
		return true;
	}
}





contract Name is TAO {

	constructor (string memory _name, address _originId, string memory _datHash, string memory _database, string memory _keyValue, bytes32 _contentId, address _vaultAddress)
		TAO (_name, _originId, _datHash, _database, _keyValue, _contentId, _vaultAddress) public {

		typeId = 1;
	}
}





library AOLibrary {
	using SafeMath for uint256;

	uint256 constant private _multiplier_divisor322 = 10 ** 6;
	uint256 constant private _percentage_divisor262 = 10 ** 6;


	function ISTAO231(address _taoId) public view returns (bool) {
		return (_taoId != address(0) && bytes(TAO(address(uint160(_taoId))).name()).length > 0 && TAO(address(uint160(_taoId))).originId() != address(0) && TAO(address(uint160(_taoId))).typeId() == 0);
	}


	function ISNAME781(address _nameId) public view returns (bool) {
		return (_nameId != address(0) && bytes(TAO(address(uint160(_nameId))).name()).length > 0 && Name(address(uint160(_nameId))).originId() != address(0) && Name(address(uint160(_nameId))).typeId() == 1);
	}


	function ISVALIDERC20TOKENADDRESS312(address _tokenAddress) public view returns (bool) {
		if (_tokenAddress == address(0)) {
			return false;
		}
		TokenERC20 _erc20 = TokenERC20(_tokenAddress);
		return (_erc20.totalSupply() >= 0 && bytes(_erc20.name()).length > 0 && bytes(_erc20.symbol()).length > 0);
	}


	function ISTHEAO403(address _sender, address _theAO, address _nameTAOPositionAddress) public view returns (bool) {
		return (_sender == _theAO ||
			(
				(ISTAO231(_theAO) || ISNAME781(_theAO)) &&
				_nameTAOPositionAddress != address(0) &&
				INameTAOPosition(_nameTAOPositionAddress).SENDERISADVOCATE978(_sender, _theAO)
			)
		);
	}


	function PERCENTAGE_DIVISOR218() public pure returns (uint256) {
		return _percentage_divisor262;
	}


	function MULTIPLIER_DIVISOR371() public pure returns (uint256) {
		return _multiplier_divisor322;
	}


	function DEPLOYTAO162(string memory _name,
		address _originId,
		string memory _datHash,
		string memory _database,
		string memory _keyValue,
		bytes32 _contentId,
		address _nameTAOVaultAddress
		) public returns (TAO _tao) {
		_tao = new TAO(_name, _originId, _datHash, _database, _keyValue, _contentId, _nameTAOVaultAddress);
	}


	function DEPLOYNAME486(string memory _name,
		address _originId,
		string memory _datHash,
		string memory _database,
		string memory _keyValue,
		bytes32 _contentId,
		address _nameTAOVaultAddress
		) public returns (Name _myName) {
		_myName = new Name(_name, _originId, _datHash, _database, _keyValue, _contentId, _nameTAOVaultAddress);
	}


	function CALCULATEWEIGHTEDMULTIPLIER712(uint256 _currentWeightedMultiplier, uint256 _currentPrimordialBalance, uint256 _additionalWeightedMultiplier, uint256 _additionalPrimordialAmount) public pure returns (uint256) {
		if (_currentWeightedMultiplier > 0) {
			uint256 _totalWeightedIons = (_currentWeightedMultiplier.MUL710(_currentPrimordialBalance)).ADD540(_additionalWeightedMultiplier.MUL710(_additionalPrimordialAmount));
			uint256 _totalIons = _currentPrimordialBalance.ADD540(_additionalPrimordialAmount);
			return _totalWeightedIons.DIV595(_totalIons);
		} else {
			return _additionalWeightedMultiplier;
		}
	}


	function CALCULATEPRIMORDIALMULTIPLIER760(uint256 _purchaseAmount, uint256 _totalPrimordialMintable, uint256 _totalPrimordialMinted, uint256 _startingMultiplier, uint256 _endingMultiplier) public pure returns (uint256) {
		if (_purchaseAmount > 0 && _purchaseAmount <= _totalPrimordialMintable.SUB853(_totalPrimordialMinted)) {

			uint256 temp = _totalPrimordialMinted.ADD540(_purchaseAmount.DIV595(2));


			uint256 multiplier = (_multiplier_divisor322.SUB853(_multiplier_divisor322.MUL710(temp).DIV595(_totalPrimordialMintable))).MUL710(_startingMultiplier.SUB853(_endingMultiplier));

			return multiplier.DIV595(_multiplier_divisor322);
		} else {
			return 0;
		}
	}


	function CALCULATENETWORKBONUSPERCENTAGE146(uint256 _purchaseAmount, uint256 _totalPrimordialMintable, uint256 _totalPrimordialMinted, uint256 _startingMultiplier, uint256 _endingMultiplier) public pure returns (uint256) {
		if (_purchaseAmount > 0 && _purchaseAmount <= _totalPrimordialMintable.SUB853(_totalPrimordialMinted)) {

			uint256 temp = _totalPrimordialMinted.ADD540(_purchaseAmount.DIV595(2));


			uint256 bonusPercentage = (_percentage_divisor262.SUB853(_percentage_divisor262.MUL710(temp).DIV595(_totalPrimordialMintable))).MUL710(_startingMultiplier.SUB853(_endingMultiplier)).DIV595(_percentage_divisor262);
			return bonusPercentage;
		} else {
			return 0;
		}
	}


	function CALCULATENETWORKBONUSAMOUNT621(uint256 _purchaseAmount, uint256 _totalPrimordialMintable, uint256 _totalPrimordialMinted, uint256 _startingMultiplier, uint256 _endingMultiplier) public pure returns (uint256) {
		uint256 bonusPercentage = CALCULATENETWORKBONUSPERCENTAGE146(_purchaseAmount, _totalPrimordialMintable, _totalPrimordialMinted, _startingMultiplier, _endingMultiplier);

		uint256 networkBonus = bonusPercentage.MUL710(_purchaseAmount).DIV595(_percentage_divisor262);
		return networkBonus;
	}


	function CALCULATEMAXIMUMBURNAMOUNT319(uint256 _primordialBalance, uint256 _currentWeightedMultiplier, uint256 _maximumMultiplier) public pure returns (uint256) {
		return (_maximumMultiplier.MUL710(_primordialBalance).SUB853(_primordialBalance.MUL710(_currentWeightedMultiplier))).DIV595(_maximumMultiplier);
	}


	function CALCULATEMULTIPLIERAFTERBURN888(uint256 _primordialBalance, uint256 _currentWeightedMultiplier, uint256 _amountToBurn) public pure returns (uint256) {
		return _primordialBalance.MUL710(_currentWeightedMultiplier).DIV595(_primordialBalance.SUB853(_amountToBurn));
	}


	function CALCULATEMULTIPLIERAFTERCONVERSION91(uint256 _primordialBalance, uint256 _currentWeightedMultiplier, uint256 _amountToConvert) public pure returns (uint256) {
		return _primordialBalance.MUL710(_currentWeightedMultiplier).DIV595(_primordialBalance.ADD540(_amountToConvert));
	}


	function NUMDIGITS612(uint256 number) public pure returns (uint8) {
		uint8 digits = 0;
		while(number != 0) {
			number = number.DIV595(10);
			digits++;
		}
		return digits;
	}
}



contract TheAO {
	address public theAO;
	address public nameTAOPositionAddress;



	mapping (address => bool) public whitelist;

	constructor() public {
		theAO = msg.sender;
	}


	modifier INWHITELIST24() {
		require (whitelist[msg.sender] == true);
		_;
	}


	function TRANSFEROWNERSHIP920(address _theAO) public {
		require (msg.sender == theAO);
		require (_theAO != address(0));
		theAO = _theAO;
	}


	function SETWHITELIST120(address _account, bool _whitelist) public {
		require (msg.sender == theAO);
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}
}



contract TAOCurrency is TheAO {
	using SafeMath for uint256;


	string public name;
	string public symbol;
	uint8 public decimals;


	uint256 public powerOfTen;

	uint256 public totalSupply;



	mapping (address => uint256) public balanceOf;



	event TRANSFER193(address indexed from, address indexed to, uint256 value);



	event BURN994(address indexed from, uint256 value);


	constructor (string memory _name, string memory _symbol, address _nameTAOPositionAddress) public {
		name = _name;
		symbol = _symbol;

		powerOfTen = 0;
		decimals = 0;

		SETNAMETAOPOSITIONADDRESS170(_nameTAOPositionAddress);
	}


	modifier ONLYTHEAO376 {
		require (AOLibrary.ISTHEAO403(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}


	modifier ISNAMEORTAO154(address _id) {
		require (AOLibrary.ISNAME781(_id) || AOLibrary.ISTAO231(_id));
		_;
	}



	function TRANSFEROWNERSHIP920(address _theAO) public ONLYTHEAO376 {
		require (_theAO != address(0));
		theAO = _theAO;
	}


	function SETWHITELIST120(address _account, bool _whitelist) public ONLYTHEAO376 {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}


	function SETNAMETAOPOSITIONADDRESS170(address _nameTAOPositionAddress) public ONLYTHEAO376 {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}



	function TRANSFERFROM282(address _from, address _to, uint256 _value) public INWHITELIST24 ISNAMEORTAO154(_from) ISNAMEORTAO154(_to) returns (bool) {
		_TRANSFER285(_from, _to, _value);
		return true;
	}


	function MINT678(address target, uint256 mintedAmount) public INWHITELIST24 ISNAMEORTAO154(target) returns (bool) {
		_MINT887(target, mintedAmount);
		return true;
	}


	function WHITELISTBURNFROM289(address _from, uint256 _value) public INWHITELIST24 ISNAMEORTAO154(_from) returns (bool success) {
		require(balanceOf[_from] >= _value);
		balanceOf[_from] = balanceOf[_from].SUB853(_value);
		totalSupply = totalSupply.SUB853(_value);
		emit BURN994(_from, _value);
		return true;
	}



	function _TRANSFER285(address _from, address _to, uint256 _value) internal {
		require (_to != address(0));
		require (balanceOf[_from] >= _value);
		require (balanceOf[_to].ADD540(_value) >= balanceOf[_to]);
		uint256 previousBalances = balanceOf[_from].ADD540(balanceOf[_to]);
		balanceOf[_from] = balanceOf[_from].SUB853(_value);
		balanceOf[_to] = balanceOf[_to].ADD540(_value);
		emit TRANSFER193(_from, _to, _value);
		assert(balanceOf[_from].ADD540(balanceOf[_to]) == previousBalances);
	}


	function _MINT887(address target, uint256 mintedAmount) internal {
		balanceOf[target] = balanceOf[target].ADD540(mintedAmount);
		totalSupply = totalSupply.ADD540(mintedAmount);
		emit TRANSFER193(address(0), address(this), mintedAmount);
		emit TRANSFER193(address(this), target, mintedAmount);
	}
}


contract PathosGiga is TAOCurrency {

	constructor(string memory _name, string memory _symbol, address _nameTAOPositionAddress)
		TAOCurrency(_name, _symbol, _nameTAOPositionAddress) public {
		powerOfTen = 9;
		decimals = 9;
	}
}
