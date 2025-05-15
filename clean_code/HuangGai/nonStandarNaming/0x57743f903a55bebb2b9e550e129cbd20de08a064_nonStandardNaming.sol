

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface TradeBotCommanderV2Interface {

    event ADDEDACCOUNT705(address account);
    event REMOVEDACCOUNT677(address account);
    event CALL773(address target, uint256 amount, bytes data, bool ok, bytes returnData);


    function PROCESSLIMITORDER517(
        DharmaTradeBotV1Interface.LimitOrderArguments calldata args,
        DharmaTradeBotV1Interface.LimitOrderExecutionArguments calldata executionArgs
    ) external returns (bool ok, uint256 amountReceived);

    function DEPLOYANDPROCESSLIMITORDER155(
        address initialSigningKey,
        address keyRing,
        DharmaTradeBotV1Interface.LimitOrderArguments calldata args,
        DharmaTradeBotV1Interface.LimitOrderExecutionArguments calldata executionArgs
    ) external returns (bool ok, bytes memory returnData);


    function ADDACCOUNT504(address account) external;
    function REMOVEACCOUNT427(address account) external;
    function CALLANY167(
        address payable target, uint256 amount, bytes calldata data
    ) external returns (bool ok, bytes memory returnData);


    function GETACCOUNTS195() external view returns (address[] memory);
    function GETTRADEBOT843() external view returns (address tradeBot);
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

  function PROCESSLIMITORDER517(
    LimitOrderArguments calldata args,
    LimitOrderExecutionArguments calldata executionArgs
  ) external returns (uint256 amountReceived);
}


interface DharmaSmartWalletFactoryV1Interface {
  function NEWSMARTWALLET679(
    address userSigningKey
  ) external returns (address wallet);

  function GETNEXTSMARTWALLET653(
    address userSigningKey
  ) external view returns (address wallet);
}

interface DharmaKeyRingFactoryV2Interface {
  function NEWKEYRING243(
    address userSigningKey, address targetKeyRing
  ) external returns (address keyRing);

  function GETNEXTKEYRING535(
    address userSigningKey
  ) external view returns (address targetKeyRing);
}


contract TwoStepOwnable {
  address private _owner;

  address private _newPotentialOwner;

  event OWNERSHIPTRANSFERRED599(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor() internal {
    _owner = tx.origin;
    emit OWNERSHIPTRANSFERRED599(address(0), _owner);
  }


  function OWNER209() public view returns (address) {
    return _owner;
  }


  modifier ONLYOWNER726() {
    require(ISOWNER585(), "TwoStepOwnable: caller is not the owner.");
    _;
  }


  function ISOWNER585() public view returns (bool) {
    return msg.sender == _owner;
  }


  function TRANSFEROWNERSHIP473(address newOwner) public ONLYOWNER726 {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }


  function CANCELOWNERSHIPTRANSFER552() public ONLYOWNER726 {
    delete _newPotentialOwner;
  }


  function ACCEPTOWNERSHIP824() public {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OWNERSHIPTRANSFERRED599(_owner, msg.sender);

    _owner = msg.sender;
  }
}


contract TradeBotCommanderV2 is TradeBotCommanderV2Interface, TwoStepOwnable {

    address[] private _accounts;


    mapping (address => uint256) private _accountIndexes;

    DharmaTradeBotV1Interface private immutable _TRADE_BOT;

    DharmaSmartWalletFactoryV1Interface private immutable _WALLET_FACTORY;

    DharmaKeyRingFactoryV2Interface private immutable _KEYRING_FACTORY;

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
            _ADDACCOUNT722(account);
        }
    }

    function PROCESSLIMITORDER517(
        DharmaTradeBotV1Interface.LimitOrderArguments calldata args,
        DharmaTradeBotV1Interface.LimitOrderExecutionArguments calldata executionArgs
    ) external override returns (bool ok, uint256 amountReceived) {
        require(
            _accountIndexes[msg.sender] != 0,
            "Only authorized accounts may trigger limit orders."
        );

        amountReceived = _TRADE_BOT.PROCESSLIMITORDER517(
            args, executionArgs
        );

        ok = true;
    }


    function DEPLOYANDPROCESSLIMITORDER155(
        address initialSigningKey,
        address keyRing,
        DharmaTradeBotV1Interface.LimitOrderArguments calldata args,
        DharmaTradeBotV1Interface.LimitOrderExecutionArguments calldata executionArgs
    ) external override returns (bool ok, bytes memory returnData) {
        require(
            _accountIndexes[msg.sender] != 0,
            "Only authorized accounts may trigger limit orders."
        );

        _DEPLOYNEWKEYRINGIFNEEDED997(initialSigningKey, keyRing);
        _DEPLOYNEWSMARTWALLETIFNEEDED48(keyRing, args.account);

        try _TRADE_BOT.PROCESSLIMITORDER517(args, executionArgs) returns (uint256 amountReceived) {
            return (true, abi.encode(amountReceived));
        } catch (bytes memory revertData) {
            return (false, revertData);
        }
  }

    function ADDACCOUNT504(address account) external override ONLYOWNER726 {
        _ADDACCOUNT722(account);
    }

    function REMOVEACCOUNT427(address account) external override ONLYOWNER726 {
        _REMOVEACCOUNT899(account);
    }

    function CALLANY167(
        address payable target, uint256 amount, bytes calldata data
    ) external override ONLYOWNER726 returns (bool ok, bytes memory returnData) {

        (ok, returnData) = target.call{value: amount}(data);

        emit CALL773(target, amount, data, ok, returnData);
    }

    function GETACCOUNTS195() external view override returns (address[] memory) {
        return _accounts;
    }

    function GETTRADEBOT843() external view override returns (address tradeBot) {
        return address(_TRADE_BOT);
    }

  function _DEPLOYNEWKEYRINGIFNEEDED997(
    address initialSigningKey, address expectedKeyRing
  ) internal returns (address keyRing) {

    bytes32 size;
    assembly { size := extcodesize(expectedKeyRing) }
    if (size == 0) {
      require(
        _KEYRING_FACTORY.GETNEXTKEYRING535(initialSigningKey) == expectedKeyRing,
        "Key ring to be deployed does not match expected key ring."
      );
      keyRing = _KEYRING_FACTORY.NEWKEYRING243(initialSigningKey, expectedKeyRing);
    } else {




      keyRing = expectedKeyRing;
    }
  }

  function _DEPLOYNEWSMARTWALLETIFNEEDED48(
    address userSigningKey,
    address expectedSmartWallet
  ) internal returns (address smartWallet) {

    bytes32 size;
    assembly { size := extcodesize(expectedSmartWallet) }
    if (size == 0) {
      require(
        _WALLET_FACTORY.GETNEXTSMARTWALLET653(userSigningKey) == expectedSmartWallet,
        "Smart wallet to be deployed does not match expected smart wallet."
      );
      smartWallet = _WALLET_FACTORY.NEWSMARTWALLET679(userSigningKey);
    } else {





      smartWallet = expectedSmartWallet;
    }
  }

    function _ADDACCOUNT722(address account) internal {
        require(
            _accountIndexes[account] == 0,
            "Account matching the provided account already exists."
        );
        _accounts.push(account);
        _accountIndexes[account] = _accounts.length;

        emit ADDEDACCOUNT705(account);
    }

    function _REMOVEACCOUNT899(address account) internal {
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

        emit REMOVEDACCOUNT677(account);
    }
}
