

pragma solidity 0.6.9;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./erc1820/ERC1820Client.sol";
import "./erc1820/ERC1820Implementer.sol";

import "./extensions/IAmpTokensSender.sol";
import "./extensions/IAmpTokensRecipient.sol";

import "./partitions/IAmpPartitionStrategyValidator.sol";
import "./partitions/PartitionsBase.sol";

import "./codes/ErrorCodes.sol";


interface ISwapToken {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}















































contract Amp is
    IERC20,
    ERC1820Client,
    ERC1820Implementer,
    PartitionsBase,
    ErrorCodes,
    Ownable
{
    using SafeMath for uint256;







    string internal constant AMP_INTERFACE_NAME = "AmpToken";




    string internal constant ERC20_INTERFACE_NAME = "ERC20Token";




    string internal constant ERC777_INTERFACE_NAME = "ERC777Token";




    string internal constant AMP_TOKENS_SENDER = "AmpTokensSender";




    string internal constant AMP_TOKENS_RECIPIENT = "AmpTokensRecipient";




    string internal constant AMP_TOKENS_CHECKER = "AmpTokensChecker";







    string internal _name;




    string internal _symbol;





    uint256 internal _totalSupply;




    uint256 internal constant _granularity = 1;







    mapping(address => uint256) internal _balances;




    mapping(address => mapping(address => uint256)) internal _allowed;








    bytes32[] internal _totalPartitions;




    mapping(bytes32 => uint256) internal _indexOfTotalPartitions;




    mapping(bytes32 => uint256) public totalSupplyByPartition;




    mapping(address => bytes32[]) internal _partitionsOf;




    mapping(address => mapping(bytes32 => uint256)) internal _indexOfPartitionsOf;





    mapping(address => mapping(bytes32 => uint256)) internal _balanceOfByPartition;





    bytes32 public constant defaultPartition = 0x0000000000000000000000000000000000000000000000000000000000000000;





    bytes4 internal constant ZERO_PREFIX = 0x00000000;








    mapping(address => mapping(address => bool)) internal _authorizedOperator;








    mapping(bytes32 => mapping(address => mapping(address => uint256))) internal _allowedByPartition;





    mapping(address => mapping(bytes32 => mapping(address => bool))) internal _authorizedOperatorByPartition;






    address[] public collateralManagers;



    mapping(address => bool) internal _isCollateralManager;







    bytes4[] public partitionStrategies;




    mapping(bytes4 => bool) internal _isPartitionStrategy;







    ISwapToken public swapToken;






    address public constant swapTokenGraveyard = 0x000000000000000000000000000000000000dEaD;





















    event TransferByPartition(
        bytes32 indexed fromPartition,
        address operator,
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data,
        bytes operatorData
    );








    event ChangedPartition(
        bytes32 indexed fromPartition,
        bytes32 indexed toPartition,
        uint256 value
    );












    event ApprovalByPartition(
        bytes32 indexed partition,
        address indexed owner,
        address indexed spender,
        uint256 value
    );










    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);










    event RevokedOperator(address indexed operator, address indexed tokenHolder);











    event AuthorizedOperatorByPartition(
        bytes32 indexed partition,
        address indexed operator,
        address indexed tokenHolder
    );











    event RevokedOperatorByPartition(
        bytes32 indexed partition,
        address indexed operator,
        address indexed tokenHolder
    );








    event CollateralManagerRegistered(address collateralManager);











    event PartitionStrategySet(bytes4 flag, string name, address indexed implementation);










    event Minted(address indexed operator, address indexed to, uint256 value, bytes data);









    event Swap(address indexed operator, address indexed from, uint256 value);













    constructor(
        address _swapTokenAddress_,
        string memory _name_,
        string memory _symbol_
    ) public {

        require(_swapTokenAddress_ != address(0), EC_5A_INVALID_SWAP_TOKEN_ADDRESS);
        swapToken = ISwapToken(_swapTokenAddress_);

        _name = _name_;
        _symbol = _symbol_;
        _totalSupply = 0;


        _addPartitionToTotalPartitions(defaultPartition);


        ERC1820Client.setInterfaceImplementation(AMP_INTERFACE_NAME, address(this));
        ERC1820Client.setInterfaceImplementation(ERC20_INTERFACE_NAME, address(this));


        ERC1820Implementer._setInterface(AMP_INTERFACE_NAME);
        ERC1820Implementer._setInterface(ERC20_INTERFACE_NAME);

    }









    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }









    function balanceOf(address _tokenHolder) external override view returns (uint256) {
        return _balanceOfByPartition[_tokenHolder][defaultPartition];
    }







    function transfer(address _to, uint256 _value) external override returns (bool) {
        _transferByDefaultPartition(msg.sender, msg.sender, _to, _value, "");
        return true;
    }








    function allowance(address _owner, address _spender)
        external
        override
        view
        returns (uint256)
    {
        return _allowed[_owner][_spender];
    }








    function approve(address _spender, uint256 _value) external override returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }














    function increaseAllowance(address _spender, uint256 _addedValue)
        external
        returns (bool)
    {
        _approve(msg.sender, _spender, _allowed[msg.sender][_spender].add(_addedValue));
        return true;
    }
















    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _allowed[msg.sender][_spender].sub(_subtractedValue)
        );
        return true;
    }








    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external override returns (bool) {
        require(
            _isOperator(msg.sender, _from) || (_value <= _allowed[_from][msg.sender]),
            EC_53_INSUFFICIENT_ALLOWANCE
        );

        if (_allowed[_from][msg.sender] >= _value) {
            _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        } else {
            _allowed[_from][msg.sender] = 0;
        }

        _transferByDefaultPartition(msg.sender, _from, _to, _value, "");
        return true;
    }













    function swap(address _from) public {
        uint256 amount = swapToken.allowance(_from, address(this));
        require(amount > 0, EC_53_INSUFFICIENT_ALLOWANCE);

        swapToken.transferFrom(_from, swapTokenGraveyard, amount);

        _mint(msg.sender, _from, amount, "");

        emit Swap(msg.sender, _from, amount);
    }










    function totalBalanceOf(address _tokenHolder) external view returns (uint256) {
        return _balances[_tokenHolder];
    }







    function balanceOfByPartition(bytes32 _partition, address _tokenHolder)
        external
        view
        returns (uint256)
    {
        return _balanceOfByPartition[_tokenHolder][_partition];
    }






    function partitionsOf(address _tokenHolder) external view returns (bytes32[] memory) {
        return _partitionsOf[_tokenHolder];
    }













    function transferWithData(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external {
        _transferByDefaultPartition(msg.sender, msg.sender, _to, _value, _data);
    }












    function transferFromWithData(
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external {
        require(_isOperator(msg.sender, _from), EC_58_INVALID_OPERATOR);

        _transferByDefaultPartition(msg.sender, _from, _to, _value, _data);
    }












    function transferByPartition(
        bytes32 _partition,
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes32) {
        return
            _transferByPartition(
                _partition,
                msg.sender,
                msg.sender,
                _to,
                _value,
                _data,
                ""
            );
    }















    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external returns (bytes32) {
        require(
            _isOperatorForPartition(_partition, msg.sender, _from) ||
                (_value <= _allowedByPartition[_partition][_from][msg.sender]),
            EC_53_INSUFFICIENT_ALLOWANCE
        );

        if (_allowedByPartition[_partition][_from][msg.sender] >= _value) {
            _allowedByPartition[_partition][_from][msg
                .sender] = _allowedByPartition[_partition][_from][msg.sender].sub(_value);
        } else {
            _allowedByPartition[_partition][_from][msg.sender] = 0;
        }

        return
            _transferByPartition(
                _partition,
                msg.sender,
                _from,
                _to,
                _value,
                _data,
                _operatorData
            );
    }









    function authorizeOperator(address _operator) external {
        require(_operator != msg.sender);
        _authorizedOperator[msg.sender][_operator] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }






    function revokeOperator(address _operator) external {
        require(_operator != msg.sender);
        _authorizedOperator[msg.sender][_operator] = false;
        emit RevokedOperator(_operator, msg.sender);
    }






    function authorizeOperatorByPartition(bytes32 _partition, address _operator)
        external
    {
        _authorizedOperatorByPartition[msg.sender][_partition][_operator] = true;
        emit AuthorizedOperatorByPartition(_partition, _operator, msg.sender);
    }









    function revokeOperatorByPartition(bytes32 _partition, address _operator) external {
        _authorizedOperatorByPartition[msg.sender][_partition][_operator] = false;
        emit RevokedOperatorByPartition(_partition, _operator, msg.sender);
    }












    function isOperator(address _operator, address _tokenHolder)
        external
        view
        returns (bool)
    {
        return _isOperator(_operator, _tokenHolder);
    }












    function isOperatorForPartition(
        bytes32 _partition,
        address _operator,
        address _tokenHolder
    ) external view returns (bool) {
        return _isOperatorForPartition(_partition, _operator, _tokenHolder);
    }














    function isOperatorForCollateralManager(
        bytes32 _partition,
        address _operator,
        address _collateralManager
    ) external view returns (bool) {
        return
            _isCollateralManager[_collateralManager] &&
            (_isOperator(_operator, _collateralManager) ||
                _authorizedOperatorByPartition[_collateralManager][_partition][_operator]);
    }







    function name() external view returns (string memory) {
        return _name;
    }





    function symbol() external view returns (string memory) {
        return _symbol;
    }






    function decimals() external pure returns (uint8) {
        return uint8(18);
    }






    function granularity() external pure returns (uint256) {
        return _granularity;
    }





    function totalPartitions() external view returns (bytes32[] memory) {
        return _totalPartitions;
    }







    function getDefaultPartition() external pure returns (bytes32) {
        return defaultPartition;
    }










    function allowanceByPartition(
        bytes32 _partition,
        address _owner,
        address _spender
    ) external view returns (uint256) {
        return _allowedByPartition[_partition][_owner][_spender];
    }









    function approveByPartition(
        bytes32 _partition,
        address _spender,
        uint256 _value
    ) external returns (bool) {
        _approveByPartition(_partition, msg.sender, _spender, _value);
        return true;
    }















    function increaseAllowanceByPartition(
        bytes32 _partition,
        address _spender,
        uint256 _addedValue
    ) external returns (bool) {
        _approveByPartition(
            _partition,
            msg.sender,
            _spender,
            _allowedByPartition[_partition][msg.sender][_spender].add(_addedValue)
        );
        return true;
    }
















    function decreaseAllowanceByPartition(
        bytes32 _partition,
        address _spender,
        uint256 _subtractedValue
    ) external returns (bool) {

        _approveByPartition(
            _partition,
            msg.sender,
            _spender,
            _allowedByPartition[_partition][msg.sender][_spender].sub(_subtractedValue)
        );
        return true;
    }








    function registerCollateralManager() external {

        require(!_isCollateralManager[msg.sender], EC_5C_ADDRESS_CONFLICT);

        collateralManagers.push(msg.sender);
        _isCollateralManager[msg.sender] = true;

        emit CollateralManagerRegistered(msg.sender);
    }







    function isCollateralManager(address _collateralManager)
        external
        view
        returns (bool)
    {
        return _isCollateralManager[_collateralManager];
    }










    function setPartitionStrategy(bytes4 _prefix, address _implementation)
        external
        onlyOwner
    {
        require(!_isPartitionStrategy[_prefix], EC_5E_PARTITION_PREFIX_CONFLICT);
        require(_prefix != ZERO_PREFIX, EC_5F_INVALID_PARTITION_PREFIX_0);

        string memory iname = _getPartitionStrategyValidatorIName(_prefix);

        ERC1820Client.setInterfaceImplementation(iname, _implementation);
        partitionStrategies.push(_prefix);
        _isPartitionStrategy[_prefix] = true;

        emit PartitionStrategySet(_prefix, iname, _implementation);
    }







    function isPartitionStrategy(bytes4 _prefix) external view returns (bool) {
        return _isPartitionStrategy[_prefix];
    }













    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0), EC_57_INVALID_RECEIVER);
        require(_balances[_from] >= _value, EC_52_INSUFFICIENT_BALANCE);

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
    }














    function _transferByPartition(
        bytes32 _fromPartition,
        address _operator,
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data,
        bytes memory _operatorData
    ) internal returns (bytes32) {
        require(
            _balanceOfByPartition[_from][_fromPartition] >= _value,
            EC_52_INSUFFICIENT_BALANCE
        );

        bytes32 toPartition = _fromPartition;
        if (_data.length >= 64) {
            toPartition = _getDestinationPartition(_fromPartition, _data);
        }

        _callPreTransferHooks(
            _fromPartition,
            _operator,
            _from,
            _to,
            _value,
            _data,
            _operatorData
        );

        _removeTokenFromPartition(_from, _fromPartition, _value);
        _transfer(_from, _to, _value);
        _addTokenToPartition(_to, toPartition, _value);

        _callPostTransferHooks(
            toPartition,
            _operator,
            _from,
            _to,
            _value,
            _data,
            _operatorData
        );

        emit TransferByPartition(
            _fromPartition,
            _operator,
            _from,
            _to,
            _value,
            _data,
            _operatorData
        );

        if (toPartition != _fromPartition) {
            emit ChangedPartition(_fromPartition, toPartition, _value);
        }

        return toPartition;
    }












    function _transferByDefaultPartition(
        address _operator,
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal {
        _transferByPartition(defaultPartition, _operator, _from, _to, _value, _data, "");
    }







    function _removeTokenFromPartition(
        address _from,
        bytes32 _partition,
        uint256 _value
    ) internal {
        _balanceOfByPartition[_from][_partition] = _balanceOfByPartition[_from][_partition]
            .sub(_value);
        totalSupplyByPartition[_partition] = totalSupplyByPartition[_partition].sub(
            _value
        );



        if (totalSupplyByPartition[_partition] == 0 && _partition != defaultPartition) {
            _removePartitionFromTotalPartitions(_partition);
        }



        if (_balanceOfByPartition[_from][_partition] == 0) {
            uint256 index = _indexOfPartitionsOf[_from][_partition];

            if (index == 0) {
                return;
            }


            bytes32 lastValue = _partitionsOf[_from][_partitionsOf[_from].length - 1];
            _partitionsOf[_from][index - 1] = lastValue;
            _indexOfPartitionsOf[_from][lastValue] = index;

            _partitionsOf[_from].pop();
            _indexOfPartitionsOf[_from][_partition] = 0;
        }
    }







    function _addTokenToPartition(
        address _to,
        bytes32 _partition,
        uint256 _value
    ) internal {
        if (_value != 0) {
            if (_indexOfPartitionsOf[_to][_partition] == 0) {
                _partitionsOf[_to].push(_partition);
                _indexOfPartitionsOf[_to][_partition] = _partitionsOf[_to].length;
            }
            _balanceOfByPartition[_to][_partition] = _balanceOfByPartition[_to][_partition]
                .add(_value);

            if (_indexOfTotalPartitions[_partition] == 0) {
                _addPartitionToTotalPartitions(_partition);
            }
            totalSupplyByPartition[_partition] = totalSupplyByPartition[_partition].add(
                _value
            );
        }
    }





    function _addPartitionToTotalPartitions(bytes32 _partition) internal {
        _totalPartitions.push(_partition);
        _indexOfTotalPartitions[_partition] = _totalPartitions.length;
    }





    function _removePartitionFromTotalPartitions(bytes32 _partition) internal {
        uint256 index = _indexOfTotalPartitions[_partition];

        if (index == 0) {
            return;
        }


        bytes32 lastValue = _totalPartitions[_totalPartitions.length - 1];
        _totalPartitions[index - 1] = lastValue;
        _indexOfTotalPartitions[lastValue] = index;

        _totalPartitions.pop();
        _indexOfTotalPartitions[_partition] = 0;
    }

















    function _callPreTransferHooks(
        bytes32 _fromPartition,
        address _operator,
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data,
        bytes memory _operatorData
    ) internal {
        address senderImplementation;
        senderImplementation = interfaceAddr(_from, AMP_TOKENS_SENDER);
        if (senderImplementation != address(0)) {
            IAmpTokensSender(senderImplementation).tokensToTransfer(
                msg.sig,
                _fromPartition,
                _operator,
                _from,
                _to,
                _value,
                _data,
                _operatorData
            );
        }



        bytes4 fromPartitionPrefix = _getPartitionPrefix(_fromPartition);
        if (_isPartitionStrategy[fromPartitionPrefix]) {
            address fromPartitionValidatorImplementation;
            fromPartitionValidatorImplementation = interfaceAddr(
                address(this),
                _getPartitionStrategyValidatorIName(fromPartitionPrefix)
            );
            if (fromPartitionValidatorImplementation != address(0)) {
                IAmpPartitionStrategyValidator(fromPartitionValidatorImplementation)
                    .tokensFromPartitionToValidate(
                    msg.sig,
                    _fromPartition,
                    _operator,
                    _from,
                    _to,
                    _value,
                    _data,
                    _operatorData
                );
            }
        }
    }












    function _callPostTransferHooks(
        bytes32 _toPartition,
        address _operator,
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data,
        bytes memory _operatorData
    ) internal {
        bytes4 toPartitionPrefix = _getPartitionPrefix(_toPartition);
        if (_isPartitionStrategy[toPartitionPrefix]) {
            address partitionManagerImplementation;
            partitionManagerImplementation = interfaceAddr(
                address(this),
                _getPartitionStrategyValidatorIName(toPartitionPrefix)
            );
            if (partitionManagerImplementation != address(0)) {
                IAmpPartitionStrategyValidator(partitionManagerImplementation)
                    .tokensToPartitionToValidate(
                    msg.sig,
                    _toPartition,
                    _operator,
                    _from,
                    _to,
                    _value,
                    _data,
                    _operatorData
                );
            }
        } else {
            require(toPartitionPrefix == ZERO_PREFIX, EC_5D_PARTITION_RESERVED);
        }

        address recipientImplementation;
        recipientImplementation = interfaceAddr(_to, AMP_TOKENS_RECIPIENT);

        if (recipientImplementation != address(0)) {
            IAmpTokensRecipient(recipientImplementation).tokensReceived(
                msg.sig,
                _toPartition,
                _operator,
                _from,
                _to,
                _value,
                _data,
                _operatorData
            );
        }
    }

















    function _approve(
        address _tokenHolder,
        address _spender,
        uint256 _amount
    ) internal {
        require(_tokenHolder != address(0), EC_56_INVALID_SENDER);
        require(_spender != address(0), EC_58_INVALID_OPERATOR);

        _allowed[_tokenHolder][_spender] = _amount;
        emit Approval(_tokenHolder, _spender, _amount);
    }









    function _approveByPartition(
        bytes32 _partition,
        address _tokenHolder,
        address _spender,
        uint256 _amount
    ) internal {
        require(_tokenHolder != address(0), EC_56_INVALID_SENDER);
        require(_spender != address(0), EC_58_INVALID_OPERATOR);
        _allowedByPartition[_partition][_tokenHolder][_spender] = _amount;
        emit ApprovalByPartition(_partition, _tokenHolder, _spender, _amount);
    }












    function _isOperator(address _operator, address _tokenHolder)
        internal
        view
        returns (bool)
    {
        return (_operator == _tokenHolder ||
            _authorizedOperator[_tokenHolder][_operator]);
    }












    function _isOperatorForPartition(
        bytes32 _partition,
        address _operator,
        address _tokenHolder
    ) internal view returns (bool) {
        return (_isOperator(_operator, _tokenHolder) ||
            _authorizedOperatorByPartition[_tokenHolder][_partition][_operator] ||
            _callPartitionStrategyOperatorHook(_partition, _operator, _tokenHolder));
    }











    function _callPartitionStrategyOperatorHook(
        bytes32 _partition,
        address _operator,
        address _tokenHolder
    ) internal view returns (bool) {
        bytes4 prefix = _getPartitionPrefix(_partition);

        if (!_isPartitionStrategy[prefix]) {
            return false;
        }

        address strategyValidatorImplementation;
        strategyValidatorImplementation = interfaceAddr(
            address(this),
            _getPartitionStrategyValidatorIName(prefix)
        );
        if (strategyValidatorImplementation != address(0)) {
            return
                IAmpPartitionStrategyValidator(strategyValidatorImplementation)
                    .isOperatorForPartitionScope(_partition, _operator, _tokenHolder);
        }


        return false;
    }













    function _mint(
        address _operator,
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal {
        require(_to != address(0), EC_57_INVALID_RECEIVER);

        _totalSupply = _totalSupply.add(_value);
        _balances[_to] = _balances[_to].add(_value);

        _addTokenToPartition(_to, defaultPartition, _value);
        _callPostTransferHooks(
            defaultPartition,
            _operator,
            address(0),
            _to,
            _value,
            _data,
            ""
        );

        emit Minted(_operator, _to, _value, _data);
        emit Transfer(address(0), _to, _value);
    }
}
