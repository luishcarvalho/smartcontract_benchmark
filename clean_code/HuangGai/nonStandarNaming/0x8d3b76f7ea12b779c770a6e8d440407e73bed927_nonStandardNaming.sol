

pragma solidity 0.5.17;


pragma experimental ABIEncoderV2;


interface DharmaSmartWalletImplementationV1Interface {
  event CALLSUCCESS383(
    bytes32 actionID,
    bool rolledBack,
    uint256 nonce,
    address to,
    bytes data,
    bytes returnData
  );

  event CALLFAILURE442(
    bytes32 actionID,
    uint256 nonce,
    address to,
    bytes data,
    string revertReason
  );


  struct Call {
    address to;
    bytes data;
  }


  struct CallReturn {
    bool ok;
    bytes returnData;
  }

  function WITHDRAWETHER963(
    uint256 amount,
    address payable recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok);

  function EXECUTEACTION770(
    address to,
    bytes calldata data,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok, bytes memory returnData);

  function RECOVER845(address newUserSigningKey) external;

  function EXECUTEACTIONWITHATOMICBATCHCALLS418(
    Call[] calldata calls,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool[] memory ok, bytes[] memory returnData);

  function GETNEXTGENERICACTIONID981(
    address to,
    bytes calldata data,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function GETGENERICACTIONID781(
    address to,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function GETNEXTGENERICATOMICBATCHACTIONID957(
    Call[] calldata calls,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function GETGENERICATOMICBATCHACTIONID98(
    Call[] calldata calls,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);
}


interface DharmaSmartWalletImplementationV3Interface {
  event CANCEL692(uint256 cancelledNonce);
  event ETHWITHDRAWAL175(uint256 amount, address recipient);
}


interface DharmaSmartWalletImplementationV4Interface {
  event ESCAPED27();

  function SETESCAPEHATCH554(
    address account,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external;

  function REMOVEESCAPEHATCH653(
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external;

  function PERMANENTLYDISABLEESCAPEHATCH796(
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external;

  function ESCAPE232() external;
}


interface DharmaSmartWalletImplementationV7Interface {

  event NEWUSERSIGNINGKEY833(address userSigningKey);


  event EXTERNALERROR24(address indexed source, string revertReason);


  enum AssetType {
    DAI,
    USDC,
    ETH,
    SAI
  }


  enum ActionType {
    Cancel,
    SetUserSigningKey,
    Generic,
    GenericAtomicBatch,
    SAIWithdrawal,
    USDCWithdrawal,
    ETHWithdrawal,
    SetEscapeHatch,
    RemoveEscapeHatch,
    DisableEscapeHatch,
    DAIWithdrawal,
    SignatureVerification,
    TradeEthForDai,
    DAIBorrow,
    USDCBorrow
  }

  function INITIALIZE336(address userSigningKey) external;

  function REPAYANDDEPOSIT967() external;

  function WITHDRAWDAI449(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok);

  function WITHDRAWUSDC811(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok);

  function CANCEL991(
    uint256 minimumActionGas,
    bytes calldata signature
  ) external;

  function SETUSERSIGNINGKEY240(
    address userSigningKey,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external;

  function MIGRATESAITODAI522() external;

  function MIGRATECSAITODDAI208() external;

  function MIGRATECDAITODDAI660() external;

  function MIGRATECUSDCTODUSDC400() external;

  function GETBALANCES53() external view returns (
    uint256 daiBalance,
    uint256 usdcBalance,
    uint256 etherBalance,
    uint256 dDaiUnderlyingDaiBalance,
    uint256 dUsdcUnderlyingUsdcBalance,
    uint256 dEtherUnderlyingEtherBalance
  );

  function GETUSERSIGNINGKEY63() external view returns (address userSigningKey);

  function GETNONCE95() external view returns (uint256 nonce);

  function GETNEXTCUSTOMACTIONID792(
    ActionType action,
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function GETCUSTOMACTIONID90(
    ActionType action,
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function GETVERSION901() external pure returns (uint256 version);
}


interface DharmaSmartWalletImplementationV8Interface {
  function TRADEETHFORDAIANDMINTDDAI339(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok, bytes memory returnData);

  function GETNEXTETHFORDAIACTIONID361(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function GETETHFORDAIACTIONID368(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);
}


interface ERC20Interface {
  function TRANSFER153(address recipient, uint256 amount) external returns (bool);
  function APPROVE270(address spender, uint256 amount) external returns (bool);

  function BALANCEOF992(address account) external view returns (uint256);
  function ALLOWANCE583(
    address owner, address spender
  ) external view returns (uint256);
}


interface ERC1271Interface {
  function ISVALIDSIGNATURE229(
    bytes calldata data, bytes calldata signature
  ) external view returns (bytes4 magicValue);
}


interface CTokenInterface {
  function REDEEM466(uint256 redeemAmount) external returns (uint256 err);
  function TRANSFER153(address recipient, uint256 value) external returns (bool);
  function APPROVE270(address spender, uint256 amount) external returns (bool);

  function BALANCEOF992(address account) external view returns (uint256 balance);
  function ALLOWANCE583(address owner, address spender) external view returns (uint256);
}


interface DTokenInterface {

  function MINT76(uint256 underlyingToSupply) external returns (uint256 dTokensMinted);
  function REDEEM466(uint256 dTokensToBurn) external returns (uint256 underlyingReceived);
  function REDEEMUNDERLYING215(uint256 underlyingToReceive) external returns (uint256 dTokensBurned);


  function MINTVIACTOKEN796(uint256 cTokensToSupply) external returns (uint256 dTokensMinted);


  function BALANCEOFUNDERLYING317(address account) external view returns (uint256 underlyingBalance);
}


interface USDCV1Interface {
  function ISBLACKLISTED453(address _account) external view returns (bool);
  function PAUSED117() external view returns (bool);
}


interface DharmaKeyRegistryInterface {
  function GETKEY781() external view returns (address key);
}


interface DharmaEscapeHatchRegistryInterface {
  function SETESCAPEHATCH554(address newEscapeHatch) external;

  function REMOVEESCAPEHATCH653() external;

  function PERMANENTLYDISABLEESCAPEHATCH796() external;

  function GETESCAPEHATCH697() external view returns (
    bool exists, address escapeHatch
  );
}


interface TradeHelperInterface {
  function TRADEETHFORDAI848(
    uint256 daiExpected, address target, bytes calldata data
  ) external payable returns (uint256 daiReceived);
}


interface RevertReasonHelperInterface {
  function REASON113(uint256 code) external pure returns (string memory);
}


interface EtherizedInterface {
  function TRIGGERETHERTRANSFER345(
    address payable target, uint256 value
  ) external returns (bool success);
}


interface ConfigurationRegistryInterface {
  function GET761(bytes32 key) external view returns (bytes32 value);
}


library Address {
  function ISCONTRACT235(address account) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }
}


library ECDSA {
  function RECOVER845(
    bytes32 hash, bytes memory signature
  ) internal pure returns (address) {
    if (signature.length != 65) {
      return (address(0));
    }

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      return address(0);
    }

    if (v != 27 && v != 28) {
      return address(0);
    }

    return ecrecover(hash, v, r, s);
  }

  function TOETHSIGNEDMESSAGEHASH603(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }
}


contract Etherized is EtherizedInterface {
  address private constant _etherizer294 = address(
    0x723B51b72Ae89A3d0c2a2760f0458307a1Baa191
  );

  function TRIGGERETHERTRANSFER345(
    address payable target, uint256 amount
  ) external returns (bool success) {
    require(msg.sender == _etherizer294, "Etherized: only callable by Etherizer");
    (success, ) = target.call.value(amount)("");
    if (!success) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }
}



contract DharmaSmartWalletImplementationV11Staging is
  DharmaSmartWalletImplementationV1Interface,
  DharmaSmartWalletImplementationV3Interface,
  DharmaSmartWalletImplementationV4Interface,
  DharmaSmartWalletImplementationV7Interface,
  DharmaSmartWalletImplementationV8Interface,
  ERC1271Interface,
  Etherized {
  using Address for address;
  using ECDSA for bytes32;




  address private _userSigningKey;




  uint256 private _nonce;






  bytes4 internal _selfCallContext;




  uint256 internal constant _dharma_smart_wallet_version295 = 1011;


  DharmaKeyRegistryInterface internal constant _dharma_key_registry438 = (
    DharmaKeyRegistryInterface(0x00000000006c7f32F0cD1eA4C1383558eb68802D)
  );

  address internal constant _account_recovery_manager816 = address(
    0x2a7E7718b755F9868E6B64DD18C6886707DD9c10
  );



  DharmaEscapeHatchRegistryInterface internal constant _escape_hatch_registry980 = (
    DharmaEscapeHatchRegistryInterface(0x00000000005280B515004B998a944630B6C663f8)
  );


  DTokenInterface internal constant _ddai406 = DTokenInterface(
    0x00000000001876eB1444c986fD502e618c587430
  );

  DTokenInterface internal constant _dusdc174 = DTokenInterface(
    0x00000000008943c65cAf789FFFCF953bE156f6f8
  );

  ERC20Interface internal constant _dai860 = ERC20Interface(
    0x6B175474E89094C44Da98b954EedeAC495271d0F
  );

  ERC20Interface internal constant _usdc146 = ERC20Interface(
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
  );

  CTokenInterface internal constant _cdai443 = CTokenInterface(
    0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643
  );

  CTokenInterface internal constant _cusdc481 = CTokenInterface(
    0x39AA39c021dfbaE8faC545936693aC917d5E7563
  );


  TradeHelperInterface internal constant _trade_helper427 = TradeHelperInterface(
    0x421816CDFe2073945173c0c35799ec21261fB399
  );


  RevertReasonHelperInterface internal constant _revert_reason_helper415 = (
    RevertReasonHelperInterface(0x9C0ccB765D3f5035f8b5Dd30fE375d5F4997D8E4)
  );

  ConfigurationRegistryInterface internal constant _config_registry519 = (
    ConfigurationRegistryInterface(0xC5C0ead7Df3CeFC45c8F4592E3a0f1500949E75D)
  );

  bytes32 internal constant _enable_usdc_minting_key536 = bytes32(
    0x596746115f08448433597980d42b4541c0197187d07ffad9c7f66a471c49dbba
  );


  uint256 internal constant _compound_success452 = 0;


  bytes4 internal constant _erc_1271_magic_value586 = bytes4(0x20c13b0b);


  uint256 private constant _just_under_one_1000th_dai594 = 999999999999999;
  uint256 private constant _just_under_one_1000th_usdc382 = 999;


  uint256 private constant _eth_transfer_gas33 = 4999;

  constructor() public {
    assert(
      _enable_usdc_minting_key536 == keccak256(
        bytes("allowAvailableUSDCToBeUsedToMintCUSDC")
      )
    );
  }


  function () external payable {}


  function INITIALIZE336(address userSigningKey) external {

    assembly { if extcodesize(address) { revert(0, 0) } }


    _SETUSERSIGNINGKEY543(userSigningKey);


    if (_SETFULLAPPROVAL629(AssetType.DAI)) {

      uint256 daiBalance = _dai860.BALANCEOF992(address(this));


      _DEPOSITDHARMATOKEN821(AssetType.DAI, daiBalance);
    }


    if (_SETFULLAPPROVAL629(AssetType.USDC)) {

      uint256 usdcBalance = _usdc146.BALANCEOF992(address(this));


      _DEPOSITDHARMATOKEN821(AssetType.USDC, usdcBalance);
    }
  }


  function REPAYANDDEPOSIT967() external {

    uint256 daiBalance = _dai860.BALANCEOF992(address(this));


    if (daiBalance > 0) {
      uint256 daiAllowance = _dai860.ALLOWANCE583(address(this), address(_ddai406));

      if (daiAllowance < daiBalance) {
        if (_SETFULLAPPROVAL629(AssetType.DAI)) {

          _DEPOSITDHARMATOKEN821(AssetType.DAI, daiBalance);
        }

      } else {

        _DEPOSITDHARMATOKEN821(AssetType.DAI, daiBalance);
      }
    }


    uint256 usdcBalance = _usdc146.BALANCEOF992(address(this));


    if (usdcBalance > 0) {
      uint256 usdcAllowance = _usdc146.ALLOWANCE583(address(this), address(_dusdc174));

      if (usdcAllowance < usdcBalance) {
        if (_SETFULLAPPROVAL629(AssetType.USDC)) {

          _DEPOSITDHARMATOKEN821(AssetType.USDC, usdcBalance);
        }

      } else {

        _DEPOSITDHARMATOKEN821(AssetType.USDC, usdcBalance);
      }
    }
  }


  function WITHDRAWDAI449(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok) {

    _VALIDATEACTIONANDINCREMENTNONCE883(
      ActionType.DAIWithdrawal,
      abi.encode(amount, recipient),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );


    if (amount <= _just_under_one_1000th_dai594) {
      revert(_REVERTREASON31(0));
    }


    if (recipient == address(0)) {
      revert(_REVERTREASON31(1));
    }


    _selfCallContext = this.WITHDRAWDAI449.selector;






    bytes memory returnData;
    (ok, returnData) = address(this).call(abi.encodeWithSelector(
      this._WITHDRAWDAIATOMIC5.selector, amount, recipient
    ));


    if (!ok) {
      emit EXTERNALERROR24(address(_dai860), _REVERTREASON31(2));
    } else {

      ok = abi.decode(returnData, (bool));
    }
  }


  function _WITHDRAWDAIATOMIC5(
    uint256 amount,
    address recipient
  ) external returns (bool success) {

    _ENFORCESELFCALLFROM836(this.WITHDRAWDAI449.selector);


    bool maxWithdraw = (amount == uint256(-1));
    if (maxWithdraw) {

      _WITHDRAWMAXFROMDHARMATOKEN348(AssetType.DAI);


      require(_TRANSFERMAX629(_dai860, recipient, false));
      success = true;
    } else {

      if (_WITHDRAWFROMDHARMATOKEN513(AssetType.DAI, amount)) {

        require(_dai860.TRANSFER153(recipient, amount));
        success = true;
      }
    }
  }


  function WITHDRAWUSDC811(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok) {

    _VALIDATEACTIONANDINCREMENTNONCE883(
      ActionType.USDCWithdrawal,
      abi.encode(amount, recipient),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );


    if (amount <= _just_under_one_1000th_usdc382) {
      revert(_REVERTREASON31(3));
    }


    if (recipient == address(0)) {
      revert(_REVERTREASON31(1));
    }


    _selfCallContext = this.WITHDRAWUSDC811.selector;






    bytes memory returnData;
    (ok, returnData) = address(this).call(abi.encodeWithSelector(
      this._WITHDRAWUSDCATOMIC942.selector, amount, recipient
    ));
    if (!ok) {

      _DIAGNOSEANDEMITUSDCSPECIFICERROR976(_usdc146.TRANSFER153.selector);
    } else {

      ok = abi.decode(returnData, (bool));
    }
  }


  function _WITHDRAWUSDCATOMIC942(
    uint256 amount,
    address recipient
  ) external returns (bool success) {

    _ENFORCESELFCALLFROM836(this.WITHDRAWUSDC811.selector);


    bool maxWithdraw = (amount == uint256(-1));
    if (maxWithdraw) {

      _WITHDRAWMAXFROMDHARMATOKEN348(AssetType.USDC);


      require(_TRANSFERMAX629(_usdc146, recipient, false));
      success = true;
    } else {

      if (_WITHDRAWFROMDHARMATOKEN513(AssetType.USDC, amount)) {

        require(_usdc146.TRANSFER153(recipient, amount));
        success = true;
      }
    }
  }


  function WITHDRAWETHER963(
    uint256 amount,
    address payable recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok) {

    _VALIDATEACTIONANDINCREMENTNONCE883(
      ActionType.ETHWithdrawal,
      abi.encode(amount, recipient),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );


    if (amount == 0) {
      revert(_REVERTREASON31(4));
    }


    if (recipient == address(0)) {
      revert(_REVERTREASON31(1));
    }


    ok = _TRANSFERETH212(recipient, amount);
  }


  function CANCEL991(
    uint256 minimumActionGas,
    bytes calldata signature
  ) external {

    uint256 nonceToCancel = _nonce;


    _VALIDATEACTIONANDINCREMENTNONCE883(
      ActionType.Cancel,
      abi.encode(),
      minimumActionGas,
      signature,
      signature
    );


    emit CANCEL692(nonceToCancel);
  }


  function EXECUTEACTION770(
    address to,
    bytes calldata data,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok, bytes memory returnData) {

    _ENSUREVALIDGENERICCALLTARGET978(to);


    (bytes32 actionID, uint256 nonce) = _VALIDATEACTIONANDINCREMENTNONCE883(
      ActionType.Generic,
      abi.encode(to, data),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );







    (ok, returnData) = to.call(data);


    if (ok) {


      emit CALLSUCCESS383(actionID, false, nonce, to, data, returnData);
    } else {


      emit CALLFAILURE442(actionID, nonce, to, data, _DECODEREVERTREASON288(returnData));
    }
  }


  function SETUSERSIGNINGKEY240(
    address userSigningKey,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external {

    _VALIDATEACTIONANDINCREMENTNONCE883(
      ActionType.SetUserSigningKey,
      abi.encode(userSigningKey),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );


    _SETUSERSIGNINGKEY543(userSigningKey);
  }


  function SETESCAPEHATCH554(
    address account,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external {

    _VALIDATEACTIONANDINCREMENTNONCE883(
      ActionType.SetEscapeHatch,
      abi.encode(account),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );


    if (account == address(0)) {
      revert(_REVERTREASON31(5));
    }


    _escape_hatch_registry980.SETESCAPEHATCH554(account);
  }


  function REMOVEESCAPEHATCH653(
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external {

    _VALIDATEACTIONANDINCREMENTNONCE883(
      ActionType.RemoveEscapeHatch,
      abi.encode(),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );


    _escape_hatch_registry980.REMOVEESCAPEHATCH653();
  }


  function PERMANENTLYDISABLEESCAPEHATCH796(
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external {

    _VALIDATEACTIONANDINCREMENTNONCE883(
      ActionType.DisableEscapeHatch,
      abi.encode(),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );


    _escape_hatch_registry980.PERMANENTLYDISABLEESCAPEHATCH796();
  }


  function TRADEETHFORDAIANDMINTDDAI339(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok, bytes memory returnData) {

    _VALIDATEACTIONANDINCREMENTNONCE883(
      ActionType.TradeEthForDai,
      abi.encode(ethToSupply, minimumDaiReceived, target, data),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );


    if (minimumDaiReceived <= _just_under_one_1000th_dai594) {
      revert(_REVERTREASON31(31));
    }


    _selfCallContext = this.TRADEETHFORDAIANDMINTDDAI339.selector;





    bytes memory returnData;
    (ok, returnData) = address(this).call(abi.encodeWithSelector(
      this._TRADEETHFORDAIANDMINTDDAIATOMIC657.selector,
      ethToSupply, minimumDaiReceived, target, data
    ));


    if (!ok) {
      emit EXTERNALERROR24(
        address(_trade_helper427), _DECODEREVERTREASON288(returnData)
      );
    }
  }

  function _TRADEETHFORDAIANDMINTDDAIATOMIC657(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data
  ) external returns (bool ok, bytes memory returnData) {

    _ENFORCESELFCALLFROM836(this.TRADEETHFORDAIANDMINTDDAI339.selector);


    uint256 daiReceived = _trade_helper427.TRADEETHFORDAI848.value(ethToSupply)(
      minimumDaiReceived, target, data
    );


    if (daiReceived < minimumDaiReceived) {
      revert(_REVERTREASON31(32));
    }


    _DEPOSITDHARMATOKEN821(AssetType.DAI, daiReceived);
  }


  function ESCAPE232() external {

    (bool exists, address escapeHatch) = _escape_hatch_registry980.GETESCAPEHATCH697();


    if (!exists) {
      revert(_REVERTREASON31(6));
    }


    if (msg.sender != escapeHatch) {
      revert(_REVERTREASON31(7));
    }


    _WITHDRAWMAXFROMDHARMATOKEN348(AssetType.DAI);


    _WITHDRAWMAXFROMDHARMATOKEN348(AssetType.USDC);


    _TRANSFERMAX629(_dai860, msg.sender, true);


    _TRANSFERMAX629(_usdc146, msg.sender, true);


    _TRANSFERMAX629(ERC20Interface(address(_cdai443)), msg.sender, true);


    _TRANSFERMAX629(ERC20Interface(address(_cusdc481)), msg.sender, true);


    _TRANSFERMAX629(ERC20Interface(address(_ddai406)), msg.sender, true);


    _TRANSFERMAX629(ERC20Interface(address(_dusdc174)), msg.sender, true);


    uint256 balance = address(this).balance;
    if (balance > 0) {

      _TRANSFERETH212(msg.sender, balance);
    }


    emit ESCAPED27();
  }


  function RECOVER845(address newUserSigningKey) external {

    if (msg.sender != _account_recovery_manager816) {
      revert(_REVERTREASON31(8));
    }


    _nonce++;


    _SETUSERSIGNINGKEY543(newUserSigningKey);
  }


  function MIGRATESAITODAI522() external {
    revert();
  }


  function MIGRATECSAITODDAI208() external {
    revert();
  }


  function MIGRATECDAITODDAI660() external {
     _MIGRATECTOKENTODTOKEN6(AssetType.DAI);
  }


  function MIGRATECUSDCTODUSDC400() external {
     _MIGRATECTOKENTODTOKEN6(AssetType.USDC);
  }


  function GETBALANCES53() external view returns (
    uint256 daiBalance,
    uint256 usdcBalance,
    uint256 etherBalance,
    uint256 dDaiUnderlyingDaiBalance,
    uint256 dUsdcUnderlyingUsdcBalance,
    uint256 dEtherUnderlyingEtherBalance
  ) {
    daiBalance = _dai860.BALANCEOF992(address(this));
    usdcBalance = _usdc146.BALANCEOF992(address(this));
    etherBalance = address(this).balance;
    dDaiUnderlyingDaiBalance = _ddai406.BALANCEOFUNDERLYING317(address(this));
    dUsdcUnderlyingUsdcBalance = _dusdc174.BALANCEOFUNDERLYING317(address(this));
  }


  function GETUSERSIGNINGKEY63() external view returns (address userSigningKey) {
    userSigningKey = _userSigningKey;
  }


  function GETNONCE95() external view returns (uint256 nonce) {
    nonce = _nonce;
  }


  function GETNEXTCUSTOMACTIONID792(
    ActionType action,
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {

    actionID = _GETACTIONID195(
      action,
      _VALIDATECUSTOMACTIONTYPEANDGETARGUMENTS503(action, amount, recipient),
      _nonce,
      minimumActionGas,
      _userSigningKey,
      _GETDHARMASIGNINGKEY429()
    );
  }


  function GETCUSTOMACTIONID90(
    ActionType action,
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {

    actionID = _GETACTIONID195(
      action,
      _VALIDATECUSTOMACTIONTYPEANDGETARGUMENTS503(action, amount, recipient),
      nonce,
      minimumActionGas,
      _userSigningKey,
      _GETDHARMASIGNINGKEY429()
    );
  }


  function GETNEXTGENERICACTIONID981(
    address to,
    bytes calldata data,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {

    actionID = _GETACTIONID195(
      ActionType.Generic,
      abi.encode(to, data),
      _nonce,
      minimumActionGas,
      _userSigningKey,
      _GETDHARMASIGNINGKEY429()
    );
  }


  function GETGENERICACTIONID781(
    address to,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {

    actionID = _GETACTIONID195(
      ActionType.Generic,
      abi.encode(to, data),
      nonce,
      minimumActionGas,
      _userSigningKey,
      _GETDHARMASIGNINGKEY429()
    );
  }


  function GETNEXTETHFORDAIACTIONID361(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {

    actionID = _GETACTIONID195(
      ActionType.TradeEthForDai,
      abi.encode(ethToSupply, minimumDaiReceived, target, data),
      _nonce,
      minimumActionGas,
      _userSigningKey,
      _GETDHARMASIGNINGKEY429()
    );
  }


  function GETETHFORDAIACTIONID368(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {

    actionID = _GETACTIONID195(
      ActionType.TradeEthForDai,
      abi.encode(ethToSupply, minimumDaiReceived, target, data),
      nonce,
      minimumActionGas,
      _userSigningKey,
      _GETDHARMASIGNINGKEY429()
    );
  }


  function ISVALIDSIGNATURE229(
    bytes calldata data, bytes calldata signatures
  ) external view returns (bytes4 magicValue) {

    bytes32 digest;
    bytes memory context;

    if (data.length == 32) {
      digest = abi.decode(data, (bytes32));
    } else {
      if (data.length < 64) {
        revert(_REVERTREASON31(30));
      }
      (digest, context) = abi.decode(data, (bytes32, bytes));
    }


    if (signatures.length != 130) {
      revert(_REVERTREASON31(11));
    }
    bytes memory signaturesInMemory = signatures;
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      r := mload(add(signaturesInMemory, 0x20))
      s := mload(add(signaturesInMemory, 0x40))
      v := byte(0, mload(add(signaturesInMemory, 0x60)))
    }
    bytes memory dharmaSignature = abi.encodePacked(r, s, v);

    assembly {
      r := mload(add(signaturesInMemory, 0x61))
      s := mload(add(signaturesInMemory, 0x81))
      v := byte(0, mload(add(signaturesInMemory, 0xa1)))
    }
    bytes memory userSignature = abi.encodePacked(r, s, v);


    if (
      !_VALIDATEUSERSIGNATURE499(
        digest,
        ActionType.SignatureVerification,
        context,
        _userSigningKey,
        userSignature
      )
    ) {
      revert(_REVERTREASON31(12));
    }


    if (_GETDHARMASIGNINGKEY429() != digest.RECOVER845(dharmaSignature)) {
      revert(_REVERTREASON31(13));
    }


    magicValue = _erc_1271_magic_value586;
  }


  function GETIMPLEMENTATION136() external view returns (address implementation) {
    (bool ok, bytes memory returnData) = address(
      0x0000000000b45D6593312ac9fdE193F3D0633644
    ).staticcall("");
    require(ok && returnData.length == 32, "Invalid implementation.");
    implementation = abi.decode(returnData, (address));
  }


  function GETVERSION901() external pure returns (uint256 version) {
    version = _dharma_smart_wallet_version295;
  }


  function EXECUTEACTIONWITHATOMICBATCHCALLS418(
    Call[] memory calls,
    uint256 minimumActionGas,
    bytes memory userSignature,
    bytes memory dharmaSignature
  ) public returns (bool[] memory ok, bytes[] memory returnData) {

    for (uint256 i = 0; i < calls.length; i++) {
      _ENSUREVALIDGENERICCALLTARGET978(calls[i].to);
    }


    (bytes32 actionID, uint256 nonce) = _VALIDATEACTIONANDINCREMENTNONCE883(
      ActionType.GenericAtomicBatch,
      abi.encode(calls),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );







    ok = new bool[](calls.length);
    returnData = new bytes[](calls.length);


    _selfCallContext = this.EXECUTEACTIONWITHATOMICBATCHCALLS418.selector;



    (bool externalOk, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._EXECUTEACTIONWITHATOMICBATCHCALLSATOMIC905.selector, calls
      )
    );


    CallReturn[] memory callResults = abi.decode(rawCallResults, (CallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      Call memory currentCall = calls[i];


      ok[i] = callResults[i].ok;
      returnData[i] = callResults[i].returnData;


      if (callResults[i].ok) {

        emit CALLSUCCESS383(
          actionID,
          !externalOk,
          nonce,
          currentCall.to,
          currentCall.data,
          callResults[i].returnData
        );
      } else {


        emit CALLFAILURE442(
          actionID,
          nonce,
          currentCall.to,
          currentCall.data,
          _DECODEREVERTREASON288(callResults[i].returnData)
        );


        break;
      }
    }
  }


  function _EXECUTEACTIONWITHATOMICBATCHCALLSATOMIC905(
    Call[] memory calls
  ) public returns (CallReturn[] memory callResults) {

    _ENFORCESELFCALLFROM836(this.EXECUTEACTIONWITHATOMICBATCHCALLS418.selector);

    bool rollBack = false;
    callResults = new CallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {

      (bool ok, bytes memory returnData) = calls[i].to.call(calls[i].data);
      callResults[i] = CallReturn({ok: ok, returnData: returnData});
      if (!ok) {

        rollBack = true;
        break;
      }
    }

    if (rollBack) {

      bytes memory callResultsBytes = abi.encode(callResults);
      assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
    }
  }


  function GETNEXTGENERICATOMICBATCHACTIONID957(
    Call[] memory calls,
    uint256 minimumActionGas
  ) public view returns (bytes32 actionID) {

    actionID = _GETACTIONID195(
      ActionType.GenericAtomicBatch,
      abi.encode(calls),
      _nonce,
      minimumActionGas,
      _userSigningKey,
      _GETDHARMASIGNINGKEY429()
    );
  }


  function GETGENERICATOMICBATCHACTIONID98(
    Call[] memory calls,
    uint256 nonce,
    uint256 minimumActionGas
  ) public view returns (bytes32 actionID) {

    actionID = _GETACTIONID195(
      ActionType.GenericAtomicBatch,
      abi.encode(calls),
      nonce,
      minimumActionGas,
      _userSigningKey,
      _GETDHARMASIGNINGKEY429()
    );
  }


  function _SETUSERSIGNINGKEY543(address userSigningKey) internal {

    if (userSigningKey == address(0)) {
      revert(_REVERTREASON31(14));
    }

    _userSigningKey = userSigningKey;
    emit NEWUSERSIGNINGKEY833(userSigningKey);
  }


  function _SETFULLAPPROVAL629(AssetType asset) internal returns (bool ok) {

    address token;
    address dToken;
    if (asset == AssetType.DAI) {
      token = address(_dai860);
      dToken = address(_ddai406);
    } else {
      token = address(_usdc146);
      dToken = address(_dusdc174);
    }


    (ok, ) = address(token).call(abi.encodeWithSelector(

      _dai860.APPROVE270.selector, dToken, uint256(-1)
    ));


    if (!ok) {
      if (asset == AssetType.DAI) {
        emit EXTERNALERROR24(address(_dai860), _REVERTREASON31(17));
      } else {

        _DIAGNOSEANDEMITUSDCSPECIFICERROR976(_usdc146.APPROVE270.selector);
      }
    }
  }


  function _DEPOSITDHARMATOKEN821(AssetType asset, uint256 balance) internal {

    if (
      asset == AssetType.DAI && balance > _just_under_one_1000th_dai594 ||
      asset == AssetType.USDC && (
        balance > _just_under_one_1000th_usdc382 &&
        uint256(_config_registry519.GET761(_enable_usdc_minting_key536)) != 0
      )
    ) {

      address dToken = asset == AssetType.DAI ? address(_ddai406) : address(_dusdc174);


      (bool ok, bytes memory data) = dToken.call(abi.encodeWithSelector(

        _ddai406.MINT76.selector, balance
      ));


      _CHECKDHARMATOKENINTERACTIONANDLOGANYERRORS622(
        asset, _ddai406.MINT76.selector, ok, data
      );
    }
  }


  function _WITHDRAWFROMDHARMATOKEN513(
    AssetType asset, uint256 balance
  ) internal returns (bool success) {

    address dToken = asset == AssetType.DAI ? address(_ddai406) : address(_dusdc174);


    (bool ok, bytes memory data) = dToken.call(abi.encodeWithSelector(

      _ddai406.REDEEMUNDERLYING215.selector, balance
    ));


    success = _CHECKDHARMATOKENINTERACTIONANDLOGANYERRORS622(
      asset, _ddai406.REDEEMUNDERLYING215.selector, ok, data
    );
  }


  function _WITHDRAWMAXFROMDHARMATOKEN348(AssetType asset) internal {

    address dToken = asset == AssetType.DAI ? address(_ddai406) : address(_dusdc174);


    ERC20Interface dTokenBalance;
    (bool ok, bytes memory data) = dToken.call(abi.encodeWithSelector(
      dTokenBalance.BALANCEOF992.selector, address(this)
    ));

    uint256 redeemAmount = 0;
    if (ok && data.length == 32) {
      redeemAmount = abi.decode(data, (uint256));
    } else {

      _CHECKDHARMATOKENINTERACTIONANDLOGANYERRORS622(
        asset, dTokenBalance.BALANCEOF992.selector, ok, data
      );
    }


    if (redeemAmount > 0) {

      (ok, data) = dToken.call(abi.encodeWithSelector(

        _ddai406.REDEEM466.selector, redeemAmount
      ));


      _CHECKDHARMATOKENINTERACTIONANDLOGANYERRORS622(
        asset, _ddai406.REDEEM466.selector, ok, data
      );
    }
  }


  function _TRANSFERMAX629(
    ERC20Interface token, address recipient, bool suppressRevert
  ) internal returns (bool success) {

    uint256 balance = 0;
    bool balanceCheckWorked = true;
    if (!suppressRevert) {
      balance = token.BALANCEOF992(address(this));
    } else {

      (bool ok, bytes memory data) = address(token).call.gas(gasleft() / 2)(
        abi.encodeWithSelector(token.BALANCEOF992.selector, address(this))
      );

      if (ok && data.length == 32) {
        balance = abi.decode(data, (uint256));
      } else {

        balanceCheckWorked = false;
      }
    }


    if (balance > 0) {
      if (!suppressRevert) {

        success = token.TRANSFER153(recipient, balance);
      } else {

        (success, ) = address(token).call.gas(gasleft() / 2)(
          abi.encodeWithSelector(token.TRANSFER153.selector, recipient, balance)
        );
      }
    } else {

      success = balanceCheckWorked;
    }
  }


  function _TRANSFERETH212(
    address payable recipient, uint256 amount
  ) internal returns (bool success) {

    (success, ) = recipient.call.gas(_eth_transfer_gas33).value(amount)("");
    if (!success) {
      emit EXTERNALERROR24(recipient, _REVERTREASON31(18));
    } else {
      emit ETHWITHDRAWAL175(amount, recipient);
    }
  }


  function _VALIDATEACTIONANDINCREMENTNONCE883(
    ActionType action,
    bytes memory arguments,
    uint256 minimumActionGas,
    bytes memory userSignature,
    bytes memory dharmaSignature
  ) internal returns (bytes32 actionID, uint256 actionNonce) {






    if (minimumActionGas != 0) {
      if (gasleft() < minimumActionGas) {
        revert(_REVERTREASON31(19));
      }
    }


    actionNonce = _nonce;


    address userSigningKey = _userSigningKey;


    address dharmaSigningKey = _GETDHARMASIGNINGKEY429();


    actionID = _GETACTIONID195(
      action,
      arguments,
      actionNonce,
      minimumActionGas,
      userSigningKey,
      dharmaSigningKey
    );


    bytes32 messageHash = actionID.TOETHSIGNEDMESSAGEHASH603();


    if (action != ActionType.Cancel) {

      if (msg.sender != userSigningKey) {
        if (
          !_VALIDATEUSERSIGNATURE499(
            messageHash, action, arguments, userSigningKey, userSignature
          )
        ) {
          revert(_REVERTREASON31(20));
        }
      }


      if (msg.sender != dharmaSigningKey) {
        if (dharmaSigningKey != messageHash.RECOVER845(dharmaSignature)) {
          revert(_REVERTREASON31(21));
        }
      }
    } else {

      if (msg.sender != userSigningKey && msg.sender != dharmaSigningKey) {
        if (
          dharmaSigningKey != messageHash.RECOVER845(dharmaSignature) &&
          !_VALIDATEUSERSIGNATURE499(
            messageHash, action, arguments, userSigningKey, userSignature
          )
        ) {
          revert(_REVERTREASON31(22));
        }
      }
    }


    _nonce++;
  }


  function _MIGRATECTOKENTODTOKEN6(AssetType token) internal {
    CTokenInterface cToken;
    DTokenInterface dToken;

    if (token == AssetType.DAI) {
      cToken = _cdai443;
      dToken = _ddai406;
    } else {
      cToken = _cusdc481;
      dToken = _dusdc174;
    }


    uint256 balance = cToken.BALANCEOF992(address(this));


    if (balance > 0) {

      if (cToken.ALLOWANCE583(address(this), address(dToken)) < balance) {
        if (!cToken.APPROVE270(address(dToken), uint256(-1))) {
          revert(_REVERTREASON31(23));
        }
      }


      if (dToken.MINTVIACTOKEN796(balance) == 0) {
        revert(_REVERTREASON31(24));
      }
    }
  }


  function _CHECKDHARMATOKENINTERACTIONANDLOGANYERRORS622(
    AssetType asset,
    bytes4 functionSelector,
    bool ok,
    bytes memory data
  ) internal returns (bool success) {

    if (ok) {
      if (data.length == 32) {
        uint256 amount = abi.decode(data, (uint256));
        if (amount > 0) {
          success = true;
        } else {

          (address account, string memory name, string memory functionName) = (
            _GETDHARMATOKENDETAILS978(asset, functionSelector)
          );

          emit EXTERNALERROR24(
            account,
            string(
              abi.encodePacked(
                name,
                " gave no tokens calling ",
                functionName,
                "."
              )
            )
          );
        }
      } else {

        (address account, string memory name, string memory functionName) = (
          _GETDHARMATOKENDETAILS978(asset, functionSelector)
        );

        emit EXTERNALERROR24(
          account,
          string(
            abi.encodePacked(
              name,
              " gave bad data calling ",
              functionName,
              "."
            )
          )
        );
      }

    } else {

      (address account, string memory name, string memory functionName) = (
        _GETDHARMATOKENDETAILS978(asset, functionSelector)
      );


      string memory revertReason = _DECODEREVERTREASON288(data);

      emit EXTERNALERROR24(
        account,
        string(
          abi.encodePacked(
            name,
            " reverted calling ",
            functionName,
            ": ",
            revertReason
          )
        )
      );
    }
  }


  function _DIAGNOSEANDEMITUSDCSPECIFICERROR976(bytes4 functionSelector) internal {

    string memory functionName;
    if (functionSelector == _usdc146.TRANSFER153.selector) {
      functionName = "transfer";
    } else {
      functionName = "approve";
    }

    USDCV1Interface usdcNaughty = USDCV1Interface(address(_usdc146));


    if (usdcNaughty.ISBLACKLISTED453(address(this))) {
      emit EXTERNALERROR24(
        address(_usdc146),
        string(
          abi.encodePacked(
            functionName, " failed - USDC has blacklisted this user."
          )
        )
      );
    } else {
      if (usdcNaughty.PAUSED117()) {
        emit EXTERNALERROR24(
          address(_usdc146),
          string(
            abi.encodePacked(
              functionName, " failed - USDC contract is currently paused."
            )
          )
        );
      } else {
        emit EXTERNALERROR24(
          address(_usdc146),
          string(
            abi.encodePacked(
              "USDC contract reverted on ", functionName, "."
            )
          )
        );
      }
    }
  }


  function _ENFORCESELFCALLFROM836(bytes4 selfCallContext) internal {

    if (msg.sender != address(this) || _selfCallContext != selfCallContext) {
      revert(_REVERTREASON31(25));
    }


    delete _selfCallContext;
  }


  function _VALIDATEUSERSIGNATURE499(
    bytes32 messageHash,
    ActionType action,
    bytes memory arguments,
    address userSigningKey,
    bytes memory userSignature
  ) internal view returns (bool valid) {
    if (!userSigningKey.ISCONTRACT235()) {
      valid = userSigningKey == messageHash.RECOVER845(userSignature);
    } else {
      bytes memory data = abi.encode(messageHash, action, arguments);
      valid = (
        ERC1271Interface(userSigningKey).ISVALIDSIGNATURE229(
          data, userSignature
        ) == _erc_1271_magic_value586
      );
    }
  }


  function _GETDHARMASIGNINGKEY429() internal view returns (
    address dharmaSigningKey
  ) {
    dharmaSigningKey = _dharma_key_registry438.GETKEY781();
  }


  function _GETACTIONID195(
    ActionType action,
    bytes memory arguments,
    uint256 nonce,
    uint256 minimumActionGas,
    address userSigningKey,
    address dharmaSigningKey
  ) internal view returns (bytes32 actionID) {

    actionID = keccak256(
      abi.encodePacked(
        address(this),
        _dharma_smart_wallet_version295,
        userSigningKey,
        dharmaSigningKey,
        nonce,
        minimumActionGas,
        action,
        arguments
      )
    );
  }


  function _GETDHARMATOKENDETAILS978(
    AssetType asset,
    bytes4 functionSelector
  ) internal pure returns (
    address account,
    string memory name,
    string memory functionName
  ) {
    if (asset == AssetType.DAI) {
      account = address(_ddai406);
      name = "Dharma Dai";
    } else {
      account = address(_dusdc174);
      name = "Dharma USD Coin";
    }


    if (functionSelector == _ddai406.MINT76.selector) {
      functionName = "mint";
    } else {
      if (functionSelector == ERC20Interface(account).BALANCEOF992.selector) {
        functionName = "balanceOf";
      } else {
        functionName = string(abi.encodePacked(
          "redeem",
          functionSelector == _ddai406.REDEEM466.selector ? "" : "Underlying"
        ));
      }
    }
  }


  function _ENSUREVALIDGENERICCALLTARGET978(address to) internal view {
    if (!to.ISCONTRACT235()) {
      revert(_REVERTREASON31(26));
    }

    if (to == address(this)) {
      revert(_REVERTREASON31(27));
    }

    if (to == address(_escape_hatch_registry980)) {
      revert(_REVERTREASON31(28));
    }
  }


  function _VALIDATECUSTOMACTIONTYPEANDGETARGUMENTS503(
    ActionType action, uint256 amount, address recipient
  ) internal pure returns (bytes memory arguments) {

    bool validActionType = (
      action == ActionType.Cancel ||
      action == ActionType.SetUserSigningKey ||
      action == ActionType.DAIWithdrawal ||
      action == ActionType.USDCWithdrawal ||
      action == ActionType.ETHWithdrawal ||
      action == ActionType.SetEscapeHatch ||
      action == ActionType.RemoveEscapeHatch ||
      action == ActionType.DisableEscapeHatch
    );
    if (!validActionType) {
      revert(_REVERTREASON31(29));
    }


    if (
      action == ActionType.Cancel ||
      action == ActionType.RemoveEscapeHatch ||
      action == ActionType.DisableEscapeHatch
    ) {

      arguments = abi.encode();
    } else if (
      action == ActionType.SetUserSigningKey ||
      action == ActionType.SetEscapeHatch
    ) {

      arguments = abi.encode(recipient);
    } else {

      arguments = abi.encode(amount, recipient);
    }
  }


  function _DECODEREVERTREASON288(
    bytes memory revertData
  ) internal pure returns (string memory revertReason) {

    if (
      revertData.length > 68 &&
      revertData[0] == byte(0x08) &&
      revertData[1] == byte(0xc3) &&
      revertData[2] == byte(0x79) &&
      revertData[3] == byte(0xa0)
    ) {

      bytes memory revertReasonBytes = new bytes(revertData.length - 4);
      for (uint256 i = 4; i < revertData.length; i++) {
        revertReasonBytes[i - 4] = revertData[i];
      }


      revertReason = abi.decode(revertReasonBytes, (string));
    } else {

      revertReason = _REVERTREASON31(uint256(-1));
    }
  }


  function _REVERTREASON31(
    uint256 code
  ) internal pure returns (string memory reason) {
    reason = _revert_reason_helper415.REASON113(code);
  }
}
