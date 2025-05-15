










pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./FarmTreasuryV1.sol";
import "../Interfaces/IUniswapRouterV2.sol";

abstract contract FarmBossV1 {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;
	using Address for address;

	mapping(address => mapping(bytes4 => uint256)) public whitelist;
	mapping(address => bool) public farmers;


	bytes4 constant internal FALLBACK_FN_SIG = 0xffffffff;

	uint256 constant internal NOT_ALLOWED = 0;
	uint256 constant internal ALLOWED_NO_MSG_VALUE = 1;
	uint256 constant internal ALLOWED_W_MSG_VALUE = 2;

	uint256 internal constant LOOP_LIMIT = 200;
	uint256 public constant max = 10000;
	uint256 public CRVTokenTake = 1500;


	struct WhitelistData {
		address account;
		bytes4 fnSig;
		bool valueAllowed;
	}


	struct Approves {
		address token;
		address allow;
	}

	address payable public governance;
	address public daoCouncilMultisig;
	address public treasury;
	address public underlying;


	address public constant UniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
	address public constant SushiswapRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
	address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address public constant CRVToken = 0xD533a949740bb3306d119CC777fa900bA034cd52;

	event NewFarmer(address _farmer);
	event RmFarmer(address _farmer);

	event NewWhitelist(address _contract, bytes4 _fnSig, uint256 _allowedType);
	event RmWhitelist(address _contract, bytes4 _fnSig);

	event NewApproval(address _token, address _contract);
	event RmApproval(address _token, address _contract);

	event ExecuteSuccess(bytes _returnData);
	event ExecuteERROR(bytes _returnData);

	constructor(address payable _governance, address _daoMultisig, address _treasury, address _underlying) public {
		governance = _governance;
		daoCouncilMultisig = _daoMultisig;
		treasury = _treasury;
		underlying = _underlying;

		farmers[msg.sender] = true;
		emit NewFarmer(msg.sender);


		IERC20(_underlying).safeApprove(_treasury, type(uint256).max);

		_initFirstFarms();
	}

	receive() payable external {}





	function _initFirstFarms() internal virtual;

	function setGovernance(address payable _new) external {
		require(msg.sender == governance, "FARMBOSSV1: !governance");

		governance = _new;
	}

	function setDaoCouncilMultisig(address _new) external {
		require(msg.sender == governance || msg.sender == daoCouncilMultisig, "FARMBOSSV1: !(governance || multisig)");

		daoCouncilMultisig = _new;
	}

	function setCRVTokenTake(uint256 _new) external {
		require(msg.sender == governance || msg.sender == daoCouncilMultisig, "FARMBOSSV1: !(governance || multisig)");
		require(_new <= max.div(2), "FARMBOSSV1: >half CRV to take");

		CRVTokenTake = _new;
	}

	function getWhitelist(address _contract, bytes4 _fnSig) external view returns (uint256){
		return whitelist[_contract][_fnSig];
	}

	function changeFarmers(address[] calldata _newFarmers, address[] calldata _rmFarmers) external {
		require(msg.sender == governance, "FARMBOSSV1: !governance");
		require(_newFarmers.length.add(_rmFarmers.length) <= LOOP_LIMIT, "FARMBOSSV1: >LOOP_LIMIT");


		for (uint256 i = 0; i < _newFarmers.length; i++){
			farmers[_newFarmers[i]] = true;

			emit NewFarmer(_newFarmers[i]);
		}

		for (uint256 j = 0; j < _rmFarmers.length; j++){
			farmers[_rmFarmers[j]] = false;

			emit RmFarmer(_rmFarmers[j]);
		}
	}


	function emergencyRemoveFarmers(address[] calldata _rmFarmers) external {
		require(msg.sender == daoCouncilMultisig, "FARMBOSSV1: !multisig");
		require(_rmFarmers.length <= LOOP_LIMIT, "FARMBOSSV1: >LOOP_LIMIT");


		for (uint256 j = 0; j < _rmFarmers.length; j++){
			farmers[_rmFarmers[j]] = false;

			emit RmFarmer(_rmFarmers[j]);
		}
	}

	function changeWhitelist(WhitelistData[] calldata _newActions, WhitelistData[] calldata _rmActions, Approves[] calldata _newApprovals, Approves[] calldata _newDepprovals) external {
		require(msg.sender == governance, "FARMBOSSV1: !governance");
		require(_newActions.length.add(_rmActions.length).add(_newApprovals.length).add(_newDepprovals.length) <= LOOP_LIMIT, "FARMBOSSV1: >LOOP_LIMIT");


		for (uint256 i = 0; i < _newActions.length; i++){
			_addWhitelist(_newActions[i].account, _newActions[i].fnSig, _newActions[i].valueAllowed);
		}

		for (uint256 j = 0; j < _rmActions.length; j++){
			whitelist[_rmActions[j].account][_rmActions[j].fnSig] = NOT_ALLOWED;

			emit RmWhitelist(_rmActions[j].account, _rmActions[j].fnSig);
		}

		for (uint256 k = 0; k < _newApprovals.length; k++){
			_approveMax(_newApprovals[k].token, _newApprovals[k].allow);
		}

		for (uint256 l = 0; l < _newDepprovals.length; l++){
			IERC20(_newDepprovals[l].token).safeApprove(_newDepprovals[l].allow, 0);

			emit RmApproval(_newDepprovals[l].token, _newDepprovals[l].allow);
		}
	}

	function _addWhitelist(address _contract, bytes4 _fnSig, bool _msgValueAllowed) internal {
		if (_msgValueAllowed){
			whitelist[_contract][_fnSig] = ALLOWED_W_MSG_VALUE;
			emit NewWhitelist(_contract, _fnSig, ALLOWED_W_MSG_VALUE);
		}
		else {
			whitelist[_contract][_fnSig] = ALLOWED_NO_MSG_VALUE;
			emit NewWhitelist(_contract, _fnSig, ALLOWED_NO_MSG_VALUE);
		}
	}

	function _approveMax(address _token, address _account) internal {
		IERC20(_token).safeApprove(_account, 0);
		IERC20(_token).safeApprove(_account, type(uint256).max);

		emit NewApproval(_token, _account);
	}


	function emergencyRemoveWhitelist(WhitelistData[] calldata _rmActions, Approves[] calldata _newDepprovals) external {
		require(msg.sender == daoCouncilMultisig, "FARMBOSSV1: !multisig");
		require(_rmActions.length.add(_newDepprovals.length) <= LOOP_LIMIT, "FARMBOSSV1: >LOOP_LIMIT");


		for (uint256 j = 0; j < _rmActions.length; j++){
			whitelist[_rmActions[j].account][_rmActions[j].fnSig] = NOT_ALLOWED;

			emit RmWhitelist(_rmActions[j].account, _rmActions[j].fnSig);
		}

		for (uint256 l = 0; l < _newDepprovals.length; l++){
			IERC20(_newDepprovals[l].token).safeApprove(_newDepprovals[l].allow, 0);

			emit RmApproval(_newDepprovals[l].token, _newDepprovals[l].allow);
		}
	}

	function govExecute(address payable _target, uint256 _value, bytes calldata _data) external returns (bool, bytes memory){
		require(msg.sender == governance, "FARMBOSSV1: !governance");

		return _execute(_target, _value, _data);
	}

	function farmerExecute(address payable _target, uint256 _value, bytes calldata _data) external returns (bool, bytes memory){
		require(farmers[msg.sender] || msg.sender == daoCouncilMultisig, "FARMBOSSV1: !(farmer || multisig)");

		require(_checkContractAndFn(_target, _value, _data), "FARMBOSSV1: target.fn() not allowed. ask DAO for approval.");
		return _execute(_target, _value, _data);
	}










	function _checkContractAndFn(address _target, uint256 _value, bytes calldata _data) internal view returns (bool) {

		bytes4 _fnSig;
		if (_data.length < 4){
			_fnSig = FALLBACK_FN_SIG;
		}
		else {






			bytes memory _fnSigBytes = bytes(_data[0:4]);
			assembly {
	            _fnSig := mload(add(add(_fnSigBytes, 0x20), 0))
	        }

		}

		bytes4 _transferSig = 0xa9059cbb;
		bytes4 _approveSig = 0x095ea7b3;
		if (_fnSig == _transferSig || _fnSig == _approveSig || whitelist[_target][_fnSig] == NOT_ALLOWED){
			return false;
		}

		else if (whitelist[_target][_fnSig] == ALLOWED_NO_MSG_VALUE && _value > 0){
			return false;
		}

		return true;
	}


	function _execute(address payable _target, uint256 _value, bytes memory _data) internal returns (bool, bytes memory){
		bool _success;
		bytes memory _returnData;

		if (_data.length == 4 && _data[0] == 0xff && _data[1] == 0xff && _data[2] == 0xff && _data[3] == 0xff){
			(_success, _returnData) = _target.call{value: _value}("");
		}
		else {
			(_success, _returnData) = _target.call{value: _value}(_data);
		}

		if (_success){
			emit ExecuteSuccess(_returnData);
		}
		else {
			emit ExecuteERROR(_returnData);
		}

		return (_success, _returnData);
	}


	function rebalanceUp(uint256 _amount, address _farmerRewards) external {
		require(msg.sender == governance || farmers[msg.sender] || msg.sender == daoCouncilMultisig, "FARMBOSSV1: !(governance || farmer || multisig)");

		FarmTreasuryV1(treasury).rebalanceUp(_amount, _farmerRewards);
	}



	function sellExactTokensForUnderlyingToken(bytes calldata _data, bool _isSushi) external returns (uint[] memory amounts){
		require(msg.sender == governance || farmers[msg.sender] || msg.sender == daoCouncilMultisig, "FARMBOSSV1: !(governance || farmer || multisig)");

		(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline) = abi.decode(_data[4:], (uint256, uint256, address[], address, uint256));


		require(to == address(this), "FARMBOSSV1: invalid sell, to != address(this)");



		if (underlying == WETH){
			require(path.length == 2, "FARMBOSSV1: path.length != 2");
			require(path[1] == WETH, "FARMBOSSV1: WETH invalid sell, output != underlying");
		}
		else {
			require(path.length == 3, "FARMBOSSV1: path.length != 3");
			require(path[1] == WETH, "FARMBOSSV1: path[1] != WETH");
			require(path[2] == underlying, "FARMBOSSV1: invalid sell, output != underlying");
		}


		if (path[0] == CRVToken && CRVTokenTake > 0){
			uint256 _amtTake = amountIn.mul(CRVTokenTake).div(max);


			amountIn = amountIn.sub(_amtTake);
			amountOutMin = amountOutMin.mul(max.sub(CRVTokenTake)).div(max);

			IERC20(CRVToken).safeTransfer(governance, _amtTake);
		}

		if (_isSushi){
			return IUniswapRouterV2(SushiswapRouter).swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
		}
		else {
			return IUniswapRouterV2(UniswapRouter).swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
		}
	}

	function rescue(address _token, uint256 _amount) external {
        require(msg.sender == governance, "FARMBOSSV1: !governance");

        if (_token != address(0)){
            IERC20(_token).safeTransfer(governance, _amount);
        }
        else {
            governance.transfer(_amount);
        }
    }
}
