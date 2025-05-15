



pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface TradeBotCommanderV2Interface {

    event AddedAccount(address account);
    event RemovedAccount(address account);
    event Call(address target, uint256 amount, bytes data, bool ok, bytes returnData);


    function processLimitOrder(
        DharmaTradeBotV1Interface.LimitOrderArguments calldata args,
        DharmaTradeBotV1Interface.LimitOrderExecutionArguments calldata executionArgs
    ) external returns (bool ok, uint256 amountReceived);

    function deployAndProcessLimitOrder(
        address initialSigningKey,
        address keyRing,
        DharmaTradeBotV1Interface.LimitOrderArguments calldata args,
        DharmaTradeBotV1Interface.LimitOrderExecutionArguments calldata executionArgs
    ) external returns (bool ok, bytes memory returnData);


    function addAccount(address account) external;
    function removeAccount(address account) external;
    function callAny(
        address payable target, uint256 amount, bytes calldata data
    ) external returns (bool ok, bytes memory returnData);


    function getAccounts() external view returns (address[] memory);
    function getTradeBot() external view returns (address tradeBot);
}


interface DharmaTradeBotV1Interface {
  struct LimitOrderArguments {
    address account;
    address assetToSupply;
    address assetToReceive;
    uint256 maximumAmountToSupply;
    uint256 maximumPriceToAccept;
    uint256 expiration;
    bytes32 salt;
  }

  struct LimitOrderExecutionArguments {
    uint256 amountToSupply;
    bytes signatures;
    address tradeTarget;
    bytes tradeData;
  }

  function processLimitOrder(
    LimitOrderArguments calldata args,
    LimitOrderExecutionArguments calldata executionArgs
  ) external returns (uint256 amountReceived);
}


interface DharmaSmartWalletFactoryV1Interface {
  function newSmartWallet(
    address userSigningKey
  ) external returns (address wallet);

  function getNextSmartWallet(
    address userSigningKey
  ) external view returns (address wallet);
}

interface DharmaKeyRingFactoryV2Interface {
  function newKeyRing(
    address userSigningKey, address targetKeyRing
  ) external returns (address keyRing);

  function getNextKeyRing(
    address userSigningKey
  ) external view returns (address targetKeyRing);
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


contract TradeBotCommanderV2Staging is TradeBotCommanderV2Interface, TwoStepOwnable {

    address[] private _accounts;


    mapping (address => uint256) private _accountIndexes;

    DharmaTradeBotV1Interface private immutable _TRADE_BOT;

    DharmaSmartWalletFactoryV1Interface private immutable _WALLET_FACTORY;

  DharmaKeyRingFactoryV2Interface private immutable _KEYRING_FACTORY;

    bool public constant isStaging = true;

    constructor(address walletFactory, address keyRingFactory, address tradeBot, address[] memory initialAccounts) public {
        require(
            walletFactory != address(0) &&
            keyRingFactory != address(0) &&
            tradeBot != address(0),
            "Missing required constructor arguments."
        );
        _WALLET_FACTORY = DharmaSmartWalletFactoryV1Interface(walletFactory);
        _KEYRING_FACTORY = DharmaKeyRingFactoryV2Interface(keyRingFactory);
        _TRADE_BOT = DharmaTradeBotV1Interface(tradeBot);
        for (uint256 i; i < initialAccounts.length; i++) {
            address account = initialAccounts[i];
            _addAccount(account);
        }
    }

    function processLimitOrder(
        DharmaTradeBotV1Interface.LimitOrderArguments calldata args,
        DharmaTradeBotV1Interface.LimitOrderExecutionArguments calldata executionArgs
    ) external override returns (bool ok, uint256 amountReceived) {
        require(
            _accountIndexes[msg.sender] != 0,
            "Only authorized accounts may trigger limit orders."
        );

        amountReceived = _TRADE_BOT.processLimitOrder(
            args, executionArgs
        );

        ok = true;
    }


    function deployAndProcessLimitOrder(
        address initialSigningKey,
        address keyRing,
        DharmaTradeBotV1Interface.LimitOrderArguments calldata args,
        DharmaTradeBotV1Interface.LimitOrderExecutionArguments calldata executionArgs
    ) external override returns (bool ok, bytes memory returnData) {
        require(
            _accountIndexes[msg.sender] != 0,
            "Only authorized accounts may trigger limit orders."
        );

        _deployNewKeyRingIfNeeded(initialSigningKey, keyRing);
        _deployNewSmartWalletIfNeeded(keyRing, args.account);

        try _TRADE_BOT.processLimitOrder(args, executionArgs) returns (uint256 amountReceived) {
            return (true, abi.encode(amountReceived));
        } catch (bytes memory revertData) {
            return (false, revertData);
        }
  }

    function addAccount(address account) external override onlyOwner {
        _addAccount(account);
    }

    function removeAccount(address account) external override onlyOwner {
        _removeAccount(account);
    }

    function callAny(
        address payable target, uint256 amount, bytes calldata data
    ) external override onlyOwner returns (bool ok, bytes memory returnData) {

        (ok, returnData) = target.call{value: amount}(data);

        emit Call(target, amount, data, ok, returnData);
    }

    function getAccounts() external view override returns (address[] memory) {
        return _accounts;
    }

    function getTradeBot() external view override returns (address tradeBot) {
        return address(_TRADE_BOT);
    }

  function _deployNewKeyRingIfNeeded(
    address initialSigningKey, address expectedKeyRing
  ) internal returns (address keyRing) {

    bytes32 size;
    assembly { size := extcodesize(expectedKeyRing) }
    if (blockhash(block.number) == 0) {
      require(
        _KEYRING_FACTORY.getNextKeyRing(initialSigningKey) == expectedKeyRing,
        "Key ring to be deployed does not match expected key ring."
      );
      keyRing = _KEYRING_FACTORY.newKeyRing(initialSigningKey, expectedKeyRing);
    } else {




      keyRing = expectedKeyRing;
    }
  }

  function _deployNewSmartWalletIfNeeded(
    address userSigningKey,
    address expectedSmartWallet
  ) internal returns (address smartWallet) {

    bytes32 size;
    assembly { size := extcodesize(expectedSmartWallet) }
    if (blockhash(block.number) == 0) {
      require(
        _WALLET_FACTORY.getNextSmartWallet(userSigningKey) == expectedSmartWallet,
        "Smart wallet to be deployed does not match expected smart wallet."
      );
      smartWallet = _WALLET_FACTORY.newSmartWallet(userSigningKey);
    } else {





      smartWallet = expectedSmartWallet;
    }
  }

    function _addAccount(address account) internal {
        require(
            _accountIndexes[account] == 0,
            "Account matching the provided account already exists."
        );
        _accounts.push(account);
        _accountIndexes[account] = _accounts.length;

        emit AddedAccount(account);
    }

    function _removeAccount(address account) internal {
        uint256 removedAccountIndex = _accountIndexes[account];
        require(
            removedAccountIndex != 0,
            "No account found matching the provided account."
        );


        address lastAccount = _accounts[_accounts.length - 1];
        _accounts[removedAccountIndex - 1] = lastAccount;
        _accountIndexes[lastAccount] = removedAccountIndex;
        _accounts.pop();
        delete _accountIndexes[account];

        emit RemovedAccount(account);
    }
}
