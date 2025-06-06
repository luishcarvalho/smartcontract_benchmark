



pragma solidity 0.5.17;


interface DharmaGasReserveInterface {

    event EtherReceived(address sender, uint256 amount);
    event Pulled(address indexed gasAccount, uint256 amount);
    event AddedGasAccount(address gasAccount);
    event RemovedGasAccount(address gasAccount);
    event NewPullAmount(uint256 pullAmount);
    event NewRateLimit(uint256 interval);
    event Call(address target, uint256 amount, bytes data, bool ok, bytes returnData);


    function pullGas() external;


    function addGasAccount(address gasAccount) external;
    function removeGasAccount(address gasAccount) external;
    function setPullAmount(uint256 amount) external;
    function setRateLimit(uint256 interval) external;
    function callAny(
        address payable target, uint256 amount, bytes calldata data
    ) external returns (bool ok, bytes memory returnData);


    function getGasAccounts() external view returns (address[] memory);
    function getPullAmount() external view returns (uint256);
    function getRateLimit() external view returns (uint256);
    function getLastPullTime(address gasAccount) external view returns (uint256);
}


contract TwoStepOwnable {
  address private _owner;

  address private _newPotentialOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );




  constructor() internal {
    _owner = tx.origin;
    emit OwnershipTransferred(address(0), _owner);
  }




  function owner() public view returns (address) {
    return _owner;
  }




  modifier onlyOwner() {
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }




  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }





  function transferOwnership(address newOwner) public onlyOwner {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }





  function cancelOwnershipTransfer() public onlyOwner {
    delete _newPotentialOwner;
  }





  function acceptOwnership() public {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }
}


contract DharmaGasReserveStaging is DharmaGasReserveInterface, TwoStepOwnable {

    address[] private _gasAccounts;


    mapping (address => uint256) private _gasAccountIndexes;

    mapping (address => uint256) private _lastPullTime;

    uint256 private _pullAmount;
    uint256 private _rateLimit;

    constructor(address[] memory initialGasAccounts) public {
        _setPullAmount(3 ether);
        _setRateLimit(2 hours);
        for (uint256 i; i < initialGasAccounts.length; i++) {
            address gasAccount = initialGasAccounts[i];
            _addGasAccount(gasAccount);
        }
    }

    function () external payable {
        if (msg.value > 0) {
            emit EtherReceived(msg.sender, msg.value);
        }
    }

    function pullGas() external {
        require(
            _gasAccountIndexes[msg.sender] != 0,
            "Only authorized gas accounts may pull from this contract."
        );

        require(
            msg.sender.balance < _pullAmount,
            "Gas account balance is not yet below the pull amount."
        );

        require(
            now > _lastPullTime[msg.sender] + _rateLimit,
            "Gas account is currently rate-limited."
        );
        _lastPullTime[msg.sender] = now;

        uint256 pullAmount = _pullAmount;

        require(
            address(this).balance >= pullAmount,
            "Insufficient funds held by the reserve."
        );

        (bool ok, ) = msg.sender.call.value(pullAmount)("");
        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize)
                revert(0, returndatasize)
            }
        }

        emit Pulled(msg.sender, pullAmount);
    }

    function addGasAccount(address gasAccount) external onlyOwner {
        _addGasAccount(gasAccount);
    }

    function removeGasAccount(address gasAccount) external onlyOwner {
        _removeGasAccount(gasAccount);
    }

    function setPullAmount(uint256 amount) external onlyOwner {
        _setPullAmount(amount);
    }

    function setRateLimit(uint256 interval) external onlyOwner {
        _setRateLimit(interval);
    }

    function callAny(
        address payable target, uint256 amount, bytes calldata data
    ) external onlyOwner returns (bool ok, bytes memory returnData) {

        (ok, returnData) = target.call.value(amount)(data);


        emit Call(target, amount, data, ok, returnData);
    }

    function getGasAccounts() external view returns (address[] memory) {
        return _gasAccounts;
    }

    function getPullAmount() external view returns (uint256) {
        return  _pullAmount;
    }

    function getRateLimit() external view returns (uint256) {
        return _rateLimit;
    }

    function getLastPullTime(address gasAccount) external view returns (uint256) {
        return _lastPullTime[gasAccount];
    }

    function _addGasAccount(address gasAccount) internal {
        require(
            _gasAccountIndexes[gasAccount] == 0,
            "Gas account matching the provided account already exists."
        );
        _gasAccounts.push(gasAccount);
        _gasAccountIndexes[gasAccount] = _gasAccounts.length;

        emit AddedGasAccount(gasAccount);
    }

    function _removeGasAccount(address gasAccount) internal {
        uint256 removedGasAccountIndex = _gasAccountIndexes[gasAccount];
        require(
            removedGasAccountIndex != 0,
            "No gas account found matching the provided account."
        );


        address lastGasAccount = _gasAccounts[_gasAccounts.length - 1];
        _gasAccounts[removedGasAccountIndex - 1] = lastGasAccount;
        _gasAccountIndexes[lastGasAccount] = removedGasAccountIndex;
        _gasAccounts.pop();
        delete _gasAccountIndexes[gasAccount];

        emit RemovedGasAccount(gasAccount);
    }

    function _setPullAmount(uint256 amount) internal {
        _pullAmount = amount;

        emit NewPullAmount(amount);
    }

    function _setRateLimit(uint256 interval) internal {
        _rateLimit = interval;

        emit NewRateLimit(interval);
    }
}
