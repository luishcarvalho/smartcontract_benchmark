

pragma solidity 0.5.17;


interface DharmaTradeReserveV9Interface {
  event ROLEMODIFIED858(Role indexed role, address account);
  event ROLEPAUSED516(Role indexed role);
  event ROLEUNPAUSED425(Role indexed role);

  event ETHERRECEIVED855(address sender, uint256 amount);

  enum Role {
    DEPOSIT_MANAGER,
    ADJUSTER,
    WITHDRAWAL_MANAGER,
    RESERVE_TRADER,
    PAUSER
  }

  struct RoleStatus {
    address account;
    bool paused;
  }

  function TRADEDAIFORETHER899(
    uint256 daiAmount, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalDaiSold);

  function TRADEDAIFORETHERV2950(
    uint256 daiAmount, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalDaiSold);

  function TRADEETHERFORDAI795(
    uint256 quotedDaiAmount, uint256 deadline
  ) external payable returns (uint256 totalDaiBought);

  function TRADEETHERFORDAIV2625(
    uint256 quotedDaiAmount, uint256 deadline
  ) external payable returns (uint256 totalDaiBought);

  function TRADEDAIFORTOKEN107(
    address token, uint256 daiAmount, uint256 quotedTokenAmount, uint256 deadline, bool routeThroughEther
  ) external returns (uint256 totalDaiSold);

  function TRADETOKENFORDAI864(
    ERC20Interface token, uint256 tokenAmount, uint256 quotedDaiAmount, uint256 deadline, bool routeThroughEther
  ) external returns (uint256 totalDaiBought);

  function TRADETOKENFORETHER84(
    ERC20Interface token, uint256 tokenAmount, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalEtherBought);

  function TRADEETHERFORTOKEN818(
    address token, uint256 quotedTokenAmount, uint256 deadline
  ) external payable returns (uint256 totalEtherSold);

  function TRADEETHERFORTOKENUSINGETHERIZER867(
    address token, uint256 etherAmount, uint256 quotedTokenAmount, uint256 deadline
  ) external returns (uint256 totalEtherSold);

  function TRADEDAIFORETHERUSINGRESERVES556(
    uint256 daiAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalDaiSold);

  function TRADEDAIFORETHERUSINGRESERVESV2121(
    uint256 daiAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalDaiSold);

  function TRADEETHERFORDAIUSINGRESERVESANDMINTDDAI322(
    uint256 etherAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline
  ) external returns (uint256 totalDaiBought, uint256 totalDDaiMinted);

  function TRADEETHERFORDAIUSINGRESERVESANDMINTDDAIV298(
    uint256 etherAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline
  ) external returns (uint256 totalDaiBought, uint256 totalDDaiMinted);

  function TRADEDAIFORTOKENUSINGRESERVES528(
    address token, uint256 daiAmountFromReserves, uint256 quotedTokenAmount, uint256 deadline, bool routeThroughEther
  ) external returns (uint256 totalDaiSold);

  function TRADETOKENFORDAIUSINGRESERVESANDMINTDDAI549(
    ERC20Interface token, uint256 tokenAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline, bool routeThroughEther
  ) external returns (uint256 totalDaiBought, uint256 totalDDaiMinted);

  function TRADETOKENFORETHERUSINGRESERVES915(
    ERC20Interface token, uint256 tokenAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalEtherBought);

  function TRADEETHERFORTOKENUSINGRESERVES405(
    address token, uint256 etherAmountFromReserves, uint256 quotedTokenAmount, uint256 deadline
  ) external returns (uint256 totalEtherSold);

  function FINALIZEETHERDEPOSIT298(
    address payable smartWallet,
    address initialUserSigningKey,
    uint256 etherAmount
  ) external;

  function FINALIZEDAIDEPOSIT931(
    address smartWallet, address initialUserSigningKey, uint256 daiAmount
  ) external;

  function FINALIZEDHARMADAIDEPOSIT237(
    address smartWallet, address initialUserSigningKey, uint256 dDaiAmount
  ) external;

  function MINT835(uint256 daiAmount) external returns (uint256 dDaiMinted);

  function REDEEM834(uint256 dDaiAmount) external returns (uint256 daiReceived);

  function TRADEDDAIFORUSDC353(
    uint256 daiEquivalentAmount, uint256 quotedUSDCAmount
  ) external returns (uint256 usdcReceived);

  function TRADEUSDCFORDDAI141(
    uint256 usdcAmount, uint256 quotedDaiEquivalentAmount
  ) external returns (uint256 dDaiMinted);

  function WITHDRAWUSDC678(address recipient, uint256 usdcAmount) external;

  function WITHDRAWDAI49(address recipient, uint256 daiAmount) external;

  function WITHDRAWDHARMADAI777(address recipient, uint256 dDaiAmount) external;

  function WITHDRAWUSDCTOPRIMARYRECIPIENT422(uint256 usdcAmount) external;

  function WITHDRAWDAITOPRIMARYRECIPIENT762(uint256 usdcAmount) external;

  function WITHDRAWETHER204(
    address payable recipient, uint256 etherAmount
  ) external;

  function WITHDRAW439(
    ERC20Interface token, address recipient, uint256 amount
  ) external returns (bool success);

  function CALLANY778(
    address payable target, uint256 amount, bytes calldata data
  ) external returns (bool ok, bytes memory returnData);

  function SETDAILIMIT345(uint256 daiAmount) external;

  function SETETHERLIMIT550(uint256 daiAmount) external;

  function SETPRIMARYUSDCRECIPIENT259(address recipient) external;

  function SETPRIMARYDAIRECIPIENT972(address recipient) external;

  function SETROLE712(Role role, address account) external;

  function REMOVEROLE29(Role role) external;

  function PAUSE504(Role role) external;

  function UNPAUSE768(Role role) external;

  function ISPAUSED423(Role role) external view returns (bool paused);

  function ISROLE511(Role role) external view returns (bool hasRole);

  function ISDHARMASMARTWALLET695(
    address smartWallet, address initialUserSigningKey
  ) external view returns (bool dharmaSmartWallet);

  function GETDEPOSITMANAGER250() external view returns (address depositManager);

  function GETADJUSTER715() external view returns (address adjuster);

  function GETRESERVETRADER735() external view returns (address reserveTrader);

  function GETWITHDRAWALMANAGER7() external view returns (address withdrawalManager);

  function GETPAUSER73() external view returns (address pauser);

  function GETRESERVES254() external view returns (
    uint256 dai, uint256 dDai, uint256 dDaiUnderlying
  );

  function GETDAILIMIT529() external view returns (
    uint256 daiAmount, uint256 dDaiAmount
  );

  function GETETHERLIMIT792() external view returns (uint256 etherAmount);

  function GETPRIMARYUSDCRECIPIENT771() external view returns (
    address recipient
  );

  function GETPRIMARYDAIRECIPIENT209() external view returns (
    address recipient
  );

  function GETIMPLEMENTATION393() external view returns (address implementation);

  function GETVERSION945() external view returns (uint256 version);
}


interface ERC20Interface {
  function BALANCEOF395(address) external view returns (uint256);
  function APPROVE301(address, uint256) external returns (bool);
  function ALLOWANCE335(address, address) external view returns (uint256);
  function TRANSFER424(address, uint256) external returns (bool);
  function TRANSFERFROM59(address, address, uint256) external returns (bool);
}


interface DTokenInterface {
  function MINT835(uint256 underlyingToSupply) external returns (uint256 dTokensMinted);
  function REDEEM834(uint256 dTokensToBurn) external returns (uint256 underlyingReceived);
  function REDEEMUNDERLYING110(uint256 underlyingToReceive) external returns (uint256 dTokensBurned);
  function BALANCEOF395(address) external view returns (uint256);
  function BALANCEOFUNDERLYING111(address) external view returns (uint256);
  function TRANSFER424(address, uint256) external returns (bool);
  function APPROVE301(address, uint256) external returns (bool);
  function EXCHANGERATECURRENT826() external view returns (uint256);
}


interface TradeHelperInterface {
  function TRADEUSDCFORDDAI141(uint256 amountUSDC, uint256 quotedDaiEquivalentAmount) external returns (uint256 dDaiMinted);
  function TRADEDDAIFORUSDC353(uint256 amountDai, uint256 quotedUSDCAmount) external returns (uint256 usdcReceived);
  function GETEXPECTEDDAI468(uint256 usdc) external view returns (uint256 dai);
  function GETEXPECTEDUSDC440(uint256 dai) external view returns (uint256 usdc);
}


interface UniswapV1Interface {
  function ETHTOTOKENSWAPINPUT251(
    uint256 minTokens, uint256 deadline
  ) external payable returns (uint256 tokensBought);

  function TOKENTOETHTRANSFEROUTPUT929(
    uint256 ethBought, uint256 maxTokens, uint256 deadline, address recipient
  ) external returns (uint256 tokensSold);
}


interface UniswapV2Interface {
  function SWAPTOKENSFOREXACTTOKENS91(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function SWAPEXACTTOKENSFORTOKENS457(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function SWAPEXACTTOKENSFORETH769(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function SWAPTOKENSFOREXACTETH731(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function SWAPETHFOREXACTTOKENS5(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function SWAPEXACTETHFORTOKENS903(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);
}


interface EtherReceiverInterface {
  function SETTLEETHER955() external;
}


library SafeMath {
  function ADD510(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function MUL1(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function DIV802(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }
}



contract TwoStepOwnable {
  event OWNERSHIPTRANSFERRED461(
    address indexed previousOwner,
    address indexed newOwner
  );

  address private _owner;

  address private _newPotentialOwner;


  function TRANSFEROWNERSHIP1000(address newOwner) external ONLYOWNER389 {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }


  function CANCELOWNERSHIPTRANSFER705() external ONLYOWNER389 {
    delete _newPotentialOwner;
  }


  function ACCEPTOWNERSHIP63() external {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OWNERSHIPTRANSFERRED461(_owner, msg.sender);

    _owner = msg.sender;
  }


  function OWNER109() external view returns (address) {
    return _owner;
  }


  function ISOWNER823() public view returns (bool) {
    return msg.sender == _owner;
  }


  modifier ONLYOWNER389() {
    require(ISOWNER823(), "TwoStepOwnable: caller is not the owner.");
    _;
  }
}



contract DharmaTradeReserveV9ImplementationStaging is DharmaTradeReserveV9Interface, TwoStepOwnable {
  using SafeMath for uint256;


  mapping(uint256 => RoleStatus) private _roles;


  address private _primaryDaiRecipient;


  address private _primaryUSDCRecipient;


  uint256 private _daiLimit;


  uint256 private _etherLimit;

  bool private _originatesFromReserveTrader;

  uint256 private constant _version934 = 8;


  ERC20Interface internal constant _usdc172 = ERC20Interface(
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
  );

  ERC20Interface internal constant _dai939 = ERC20Interface(
    0x6B175474E89094C44Da98b954EedeAC495271d0F
  );

  ERC20Interface internal constant _etherizer566 = ERC20Interface(
    0x723B51b72Ae89A3d0c2a2760f0458307a1Baa191
  );

  DTokenInterface internal constant _ddai325 = DTokenInterface(
    0x00000000001876eB1444c986fD502e618c587430
  );

  TradeHelperInterface internal constant _trade_helper648 = TradeHelperInterface(
    0x9328F2Fb3e85A4d24Adc2f68F82737183e85691d
  );

  UniswapV1Interface internal constant _uniswap_dai496 = UniswapV1Interface(
    0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667
  );

  UniswapV2Interface internal constant _uniswap_router877 = UniswapV2Interface(
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  );

  EtherReceiverInterface internal constant _eth_receiver459 = EtherReceiverInterface(
    0xaf84687D21736F5E06f738c6F065e88890465E7c
  );

  address internal constant _weth740 = address(
    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
  );


  bytes21 internal constant _create2_header376 = bytes21(
    0xff8D1e00b000e56d5BcB006F3a008Ca6003b9F0033
  );


  bytes internal constant _wallet_creation_code_header138 = hex"60806040526040516104423803806104428339818101604052602081101561002657600080fd5b810190808051604051939291908464010000000082111561004657600080fd5b90830190602082018581111561005b57600080fd5b825164010000000081118282018810171561007557600080fd5b82525081516020918201929091019080838360005b838110156100a257818101518382015260200161008a565b50505050905090810190601f1680156100cf5780820380516001836020036101000a031916815260200191505b5060405250505060006100e661019e60201b60201c565b6001600160a01b0316826040518082805190602001908083835b6020831061011f5780518252601f199092019160209182019101610100565b6001836020036101000a038019825116818451168082178552505050505050905001915050600060405180830381855af49150503d806000811461017f576040519150601f19603f3d011682016040523d82523d6000602084013e610184565b606091505b5050905080610197573d6000803e3d6000fd5b50506102be565b60405160009081906060906eb45d6593312ac9fde193f3d06336449083818181855afa9150503d80600081146101f0576040519150601f19603f3d011682016040523d82523d6000602084013e6101f5565b606091505b509150915081819061029f576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825283818151815260200191508051906020019080838360005b8381101561026457818101518382015260200161024c565b50505050905090810190601f1680156102915780820380516001836020036101000a031916815260200191505b509250505060405180910390fd5b508080602001905160208110156102b557600080fd5b50519392505050565b610175806102cd6000396000f3fe608060405261001461000f610016565b61011c565b005b60405160009081906060906eb45d6593312ac9fde193f3d06336449083818181855afa9150503d8060008114610068576040519150601f19603f3d011682016040523d82523d6000602084013e61006d565b606091505b50915091508181906100fd5760405162461bcd60e51b81526004018080602001828103825283818151815260200191508051906020019080838360005b838110156100c25781810151838201526020016100aa565b50505050905090810190601f1680156100ef5780820380516001836020036101000a031916815260200191505b509250505060405180910390fd5b5080806020019051602081101561011357600080fd5b50519392505050565b3660008037600080366000845af43d6000803e80801561013b573d6000f35b3d6000fdfea265627a7a723158203c578cc1552f1d1b48134a72934fe12fb89a29ff396bd514b9a4cebcacc5cacc64736f6c634300050b003200000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000024c4d66de8000000000000000000000000";
  bytes28 internal constant _wallet_creation_code_footer303 = bytes28(
    0x00000000000000000000000000000000000000000000000000000000
  );


  function () external payable {
    emit ETHERRECEIVED855(msg.sender, msg.value);
  }

  function INITIALIZE669() external {

    if (_dai939.ALLOWANCE335(address(this), address(_uniswap_router877)) != uint256(-1)) {
      bool ok = _dai939.APPROVE301(address(_uniswap_router877), uint256(-1));
      require(ok, "Dai approval for Uniswap router failed.");
    }
  }


  function TRADEDAIFORETHER899(
    uint256 daiAmount,
    uint256 quotedEtherAmount,
    uint256 deadline
  ) external returns (uint256 totalDaiSold) {

    _TRANSFERINTOKEN213(_dai939, msg.sender, daiAmount);


    totalDaiSold = _uniswap_dai496.TOKENTOETHTRANSFEROUTPUT929(
      quotedEtherAmount, daiAmount, deadline, msg.sender
    );
  }


  function TRADEDAIFORETHERV2950(
    uint256 daiAmount,
    uint256 quotedEtherAmount,
    uint256 deadline
  ) external returns (uint256 totalDaiSold) {

    _TRANSFERINTOKEN213(_dai939, msg.sender, daiAmount);


    (address[] memory path, uint256[] memory amounts) = _CREATEPATHANDAMOUNTS796(
      address(_dai939), _weth740, false
    );


    amounts = _uniswap_router877.SWAPTOKENSFOREXACTETH731(
      quotedEtherAmount, daiAmount, path, msg.sender, deadline
    );
    totalDaiSold = amounts[0];
  }

  function TRADETOKENFORETHER84(
    ERC20Interface token, uint256 tokenAmount, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalEtherBought) {

    _TRANSFERINTOKEN213(token, msg.sender, tokenAmount);


    _GRANTUNISWAPROUTERAPPROVALIFNECESSARY324(token);


    (address[] memory path, uint256[] memory amounts) = _CREATEPATHANDAMOUNTS796(
      address(token), _weth740, false
    );


    amounts = _uniswap_router877.SWAPEXACTTOKENSFORETH769(
      tokenAmount, quotedEtherAmount, path, address(this), deadline
    );
    totalEtherBought = amounts[1];


    (bool ok, ) = msg.sender.call.value(quotedEtherAmount)("");
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }

  function TRADEDAIFORTOKEN107(
    address token, uint256 daiAmount, uint256 quotedTokenAmount, uint256 deadline, bool routeThroughEther
  ) external returns (uint256 totalDaiSold) {

    _TRANSFERINTOKEN213(_dai939, msg.sender, daiAmount);


    (address[] memory path, uint256[] memory amounts) = _CREATEPATHANDAMOUNTS796(
      address(_dai939), token, routeThroughEther
    );


    amounts = _uniswap_router877.SWAPTOKENSFOREXACTTOKENS91(
      quotedTokenAmount, daiAmount, path, msg.sender, deadline
    );

    totalDaiSold = amounts[0];
  }


  function TRADEDAIFORETHERUSINGRESERVES556(
    uint256 daiAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external ONLYOWNEROR665(Role.RESERVE_TRADER) returns (uint256 totalDaiSold) {

    uint256 daiBalance = _dai939.BALANCEOF395(address(this));
    if (daiBalance < daiAmountFromReserves) {
      uint256 additionalDaiRequired = daiAmountFromReserves - daiBalance;
      _ddai325.REDEEMUNDERLYING110(additionalDaiRequired);
    }


    totalDaiSold = _uniswap_dai496.TOKENTOETHTRANSFEROUTPUT929(
      quotedEtherAmount,
      daiAmountFromReserves,
      deadline,
      address(_eth_receiver459)
    );


    _eth_receiver459.SETTLEETHER955();
  }


  function TRADEDAIFORETHERUSINGRESERVESV2121(
    uint256 daiAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external ONLYOWNEROR665(Role.RESERVE_TRADER) returns (uint256 totalDaiSold) {

    uint256 daiBalance = _dai939.BALANCEOF395(address(this));
    if (daiBalance < daiAmountFromReserves) {
      uint256 additionalDaiRequired = daiAmountFromReserves - daiBalance;
      _ddai325.REDEEMUNDERLYING110(additionalDaiRequired);
    }


    (address[] memory path, uint256[] memory amounts) = _CREATEPATHANDAMOUNTS796(
      address(_dai939), _weth740, false
    );


    amounts = _uniswap_router877.SWAPTOKENSFOREXACTETH731(
      quotedEtherAmount, daiAmountFromReserves, path, address(this), deadline
    );
    totalDaiSold = amounts[0];
  }

  function TRADETOKENFORETHERUSINGRESERVES915(
    ERC20Interface token, uint256 tokenAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external ONLYOWNEROR665(Role.RESERVE_TRADER) returns (uint256 totalEtherBought) {

    _GRANTUNISWAPROUTERAPPROVALIFNECESSARY324(token);


    (address[] memory path, uint256[] memory amounts) = _CREATEPATHANDAMOUNTS796(
      address(token), _weth740, false
    );


    amounts = _uniswap_router877.SWAPEXACTTOKENSFORETH769(
      tokenAmountFromReserves, quotedEtherAmount, path, address(this), deadline
    );
    totalEtherBought = amounts[1];
  }


  function TRADEETHERFORDAI795(
    uint256 quotedDaiAmount,
    uint256 deadline
  ) external payable returns (uint256 totalDaiBought) {

    totalDaiBought = _uniswap_dai496.ETHTOTOKENSWAPINPUT251.value(msg.value)(
      quotedDaiAmount, deadline
    );


    _TRANSFERTOKEN930(_dai939, msg.sender, quotedDaiAmount);
  }


  function TRADEETHERFORDAIV2625(
    uint256 quotedDaiAmount,
    uint256 deadline
  ) external payable returns (uint256 totalDaiBought) {

    (address[] memory path, uint256[] memory amounts) = _CREATEPATHANDAMOUNTS796(
      _weth740, address(_dai939), false
    );


    amounts = _uniswap_router877.SWAPEXACTETHFORTOKENS903.value(msg.value)(
      quotedDaiAmount, path, address(this), deadline
    );
    totalDaiBought = amounts[1];


    _TRANSFERTOKEN930(_dai939, msg.sender, quotedDaiAmount);
  }

  function TRADEETHERFORTOKEN818(
    address token, uint256 quotedTokenAmount, uint256 deadline
  ) external payable returns (uint256 totalEtherSold) {

    (address[] memory path, uint256[] memory amounts) = _CREATEPATHANDAMOUNTS796(
      _weth740, address(token), false
    );


    amounts = _uniswap_router877.SWAPETHFOREXACTTOKENS5.value(msg.value)(
      quotedTokenAmount, path, msg.sender, deadline
    );
    totalEtherSold = amounts[0];
  }

  function TRADEETHERFORTOKENUSINGETHERIZER867(
    address token, uint256 etherAmount, uint256 quotedTokenAmount, uint256 deadline
  ) external returns (uint256 totalEtherSold) {

    _TRANSFERINTOKEN213(_etherizer566, msg.sender, etherAmount);


    (address[] memory path, uint256[] memory amounts) = _CREATEPATHANDAMOUNTS796(
      _weth740, address(token), false
    );


    amounts = _uniswap_router877.SWAPETHFOREXACTTOKENS5.value(etherAmount)(
      quotedTokenAmount, path, msg.sender, deadline
    );
    totalEtherSold = amounts[0];
  }

  function TRADETOKENFORDAI864(
    ERC20Interface token, uint256 tokenAmount, uint256 quotedDaiAmount, uint256 deadline, bool routeThroughEther
  ) external returns (uint256 totalDaiBought) {

    _TRANSFERINTOKEN213(token, msg.sender, tokenAmount);


    _GRANTUNISWAPROUTERAPPROVALIFNECESSARY324(token);


    (address[] memory path, uint256[] memory amounts) = _CREATEPATHANDAMOUNTS796(
      address(token), address(_dai939), routeThroughEther
    );


    amounts = _uniswap_router877.SWAPEXACTTOKENSFORTOKENS457(
      tokenAmount, quotedDaiAmount, path, msg.sender, deadline
    );

    totalDaiBought = amounts[path.length - 1];


    _TRANSFERTOKEN930(_dai939, msg.sender, quotedDaiAmount);
  }


  function TRADEETHERFORDAIUSINGRESERVESANDMINTDDAI322(
    uint256 etherAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline
  ) external ONLYOWNEROR665(Role.RESERVE_TRADER) returns (
    uint256 totalDaiBought, uint256 totalDDaiMinted
  ) {

    totalDaiBought = _uniswap_dai496.ETHTOTOKENSWAPINPUT251.value(
      etherAmountFromReserves
    )(
      quotedDaiAmount, deadline
    );


    totalDDaiMinted = _ddai325.MINT835(totalDaiBought);
  }


  function TRADEETHERFORDAIUSINGRESERVESANDMINTDDAIV298(
    uint256 etherAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline
  ) external ONLYOWNEROR665(Role.RESERVE_TRADER) returns (
    uint256 totalDaiBought, uint256 totalDDaiMinted
  ) {

    (address[] memory path, uint256[] memory amounts) = _CREATEPATHANDAMOUNTS796(
      _weth740, address(_dai939), false
    );


    amounts = _uniswap_router877.SWAPEXACTETHFORTOKENS903.value(
      etherAmountFromReserves
    )(
      quotedDaiAmount, path, address(this), deadline
    );
    totalDaiBought = amounts[1];


    totalDDaiMinted = _ddai325.MINT835(totalDaiBought);
  }

  function TRADEETHERFORTOKENUSINGRESERVES405(
    address token, uint256 etherAmountFromReserves, uint256 quotedTokenAmount, uint256 deadline
  ) external ONLYOWNEROR665(Role.RESERVE_TRADER) returns (uint256 totalEtherSold) {

    (address[] memory path, uint256[] memory amounts) = _CREATEPATHANDAMOUNTS796(
      _weth740, address(token), false
    );


    amounts = _uniswap_router877.SWAPETHFOREXACTTOKENS5.value(etherAmountFromReserves)(
      quotedTokenAmount, path, address(this), deadline
    );
    totalEtherSold = amounts[0];
  }

  function TRADEDAIFORTOKENUSINGRESERVES528(
    address token, uint256 daiAmountFromReserves, uint256 quotedTokenAmount, uint256 deadline, bool routeThroughEther
  ) external ONLYOWNEROR665(Role.RESERVE_TRADER) returns (uint256 totalDaiSold) {

    uint256 daiBalance = _dai939.BALANCEOF395(address(this));
    if (daiBalance < daiAmountFromReserves) {
      uint256 additionalDaiRequired = daiAmountFromReserves - daiBalance;
      _ddai325.REDEEMUNDERLYING110(additionalDaiRequired);
    }


    (address[] memory path, uint256[] memory amounts) = _CREATEPATHANDAMOUNTS796(
      address(_dai939), address(token), routeThroughEther
    );


    amounts = _uniswap_router877.SWAPTOKENSFOREXACTTOKENS91(
      quotedTokenAmount, daiAmountFromReserves, path, address(this), deadline
    );

    totalDaiSold = amounts[0];
  }

  function TRADETOKENFORDAIUSINGRESERVESANDMINTDDAI549(
    ERC20Interface token, uint256 tokenAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline, bool routeThroughEther
  ) external ONLYOWNEROR665(Role.RESERVE_TRADER) returns (
    uint256 totalDaiBought, uint256 totalDDaiMinted
  ) {

    _GRANTUNISWAPROUTERAPPROVALIFNECESSARY324(token);


    (address[] memory path, uint256[] memory amounts) = _CREATEPATHANDAMOUNTS796(
      address(token), address(_dai939), routeThroughEther
    );


    amounts = _uniswap_router877.SWAPEXACTTOKENSFORTOKENS457(
      tokenAmountFromReserves, quotedDaiAmount, path, address(this), deadline
    );

    totalDaiBought = amounts[path.length - 1];


    totalDDaiMinted = _ddai325.MINT835(totalDaiBought);
  }


  function FINALIZEDAIDEPOSIT931(
    address smartWallet, address initialUserSigningKey, uint256 daiAmount
  ) external ONLYOWNEROR665(Role.DEPOSIT_MANAGER) {

    _ENSURESMARTWALLET516(smartWallet, initialUserSigningKey);


    require(daiAmount < _daiLimit, "Transfer size exceeds the limit.");


    _TRANSFERTOKEN930(_dai939, smartWallet, daiAmount);
  }


  function FINALIZEDHARMADAIDEPOSIT237(
    address smartWallet, address initialUserSigningKey, uint256 dDaiAmount
  ) external ONLYOWNEROR665(Role.DEPOSIT_MANAGER) {

    _ENSURESMARTWALLET516(smartWallet, initialUserSigningKey);


    uint256 exchangeRate = _ddai325.EXCHANGERATECURRENT826();


    require(exchangeRate != 0, "Could not retrieve dDai exchange rate.");


    uint256 daiEquivalent = (dDaiAmount.MUL1(exchangeRate)) / 1e18;


    require(daiEquivalent < _daiLimit, "Transfer size exceeds the limit.");


    _TRANSFERTOKEN930(ERC20Interface(address(_ddai325)), smartWallet, dDaiAmount);
  }


  function FINALIZEETHERDEPOSIT298(
    address payable smartWallet,
    address initialUserSigningKey,
    uint256 etherAmount
  ) external ONLYOWNEROR665(Role.DEPOSIT_MANAGER) {

    _ENSURESMARTWALLET516(smartWallet, initialUserSigningKey);


    require(etherAmount < _etherLimit, "Transfer size exceeds the limit.");


    bool ok;
    (ok, ) = smartWallet.call.value(etherAmount)("");
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }


  function MINT835(
    uint256 daiAmount
  ) external ONLYOWNEROR665(Role.ADJUSTER) returns (uint256 dDaiMinted) {

    dDaiMinted = _ddai325.MINT835(daiAmount);
  }


  function REDEEM834(
    uint256 dDaiAmount
  ) external ONLYOWNEROR665(Role.ADJUSTER) returns (uint256 daiReceived) {

    daiReceived = _ddai325.REDEEM834(dDaiAmount);
  }


  function TRADEUSDCFORDDAI141(
    uint256 usdcAmount,
    uint256 quotedDaiEquivalentAmount
  ) external ONLYOWNEROR665(Role.ADJUSTER) returns (uint256 dDaiMinted) {
    dDaiMinted = _trade_helper648.TRADEUSDCFORDDAI141(
       usdcAmount, quotedDaiEquivalentAmount
    );
  }


  function TRADEDDAIFORUSDC353(
    uint256 daiEquivalentAmount,
    uint256 quotedUSDCAmount
  ) external ONLYOWNEROR665(Role.ADJUSTER) returns (uint256 usdcReceived) {
    usdcReceived = _trade_helper648.TRADEDDAIFORUSDC353(
      daiEquivalentAmount, quotedUSDCAmount
    );
  }


  function WITHDRAWUSDCTOPRIMARYRECIPIENT422(
    uint256 usdcAmount
  ) external ONLYOWNEROR665(Role.WITHDRAWAL_MANAGER) {

    address primaryRecipient = _primaryUSDCRecipient;
    require(
      primaryRecipient != address(0), "No USDC primary recipient currently set."
    );


    _TRANSFERTOKEN930(_usdc172, primaryRecipient, usdcAmount);
  }


  function WITHDRAWDAITOPRIMARYRECIPIENT762(
    uint256 daiAmount
  ) external ONLYOWNEROR665(Role.WITHDRAWAL_MANAGER) {

    address primaryRecipient = _primaryDaiRecipient;
    require(
      primaryRecipient != address(0), "No Dai primary recipient currently set."
    );


    _TRANSFERTOKEN930(_dai939, primaryRecipient, daiAmount);
  }


  function WITHDRAWUSDC678(
    address recipient, uint256 usdcAmount
  ) external ONLYOWNER389 {

    _TRANSFERTOKEN930(_usdc172, recipient, usdcAmount);
  }


  function WITHDRAWDAI49(
    address recipient, uint256 daiAmount
  ) external ONLYOWNER389 {

    _TRANSFERTOKEN930(_dai939, recipient, daiAmount);
  }


  function WITHDRAWDHARMADAI777(
    address recipient, uint256 dDaiAmount
  ) external ONLYOWNER389 {

    _TRANSFERTOKEN930(ERC20Interface(address(_ddai325)), recipient, dDaiAmount);
  }


  function WITHDRAWETHER204(
    address payable recipient, uint256 etherAmount
  ) external ONLYOWNER389 {
    bool ok;


    (ok, ) = recipient.call.value(etherAmount)("");
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }


  function WITHDRAW439(
    ERC20Interface token, address recipient, uint256 amount
  ) external ONLYOWNER389 returns (bool success) {

    success = token.TRANSFER424(recipient, amount);
  }


  function CALLANY778(
    address payable target, uint256 amount, bytes calldata data
  ) external ONLYOWNER389 returns (bool ok, bytes memory returnData) {

    (ok, returnData) = target.call.value(amount)(data);
  }


  function SETDAILIMIT345(uint256 daiAmount) external ONLYOWNER389 {

    _daiLimit = daiAmount;
  }


  function SETETHERLIMIT550(uint256 etherAmount) external ONLYOWNER389 {

    _etherLimit = etherAmount;
  }


  function SETPRIMARYUSDCRECIPIENT259(address recipient) external ONLYOWNER389 {

    _primaryUSDCRecipient = recipient;
  }


  function SETPRIMARYDAIRECIPIENT972(address recipient) external ONLYOWNER389 {

    _primaryDaiRecipient = recipient;
  }


  function PAUSE504(Role role) external ONLYOWNEROR665(Role.PAUSER) {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(!storedRoleStatus.paused, "Role in question is already paused.");
    storedRoleStatus.paused = true;
    emit ROLEPAUSED516(role);
  }


  function UNPAUSE768(Role role) external ONLYOWNER389 {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(storedRoleStatus.paused, "Role in question is already unpaused.");
    storedRoleStatus.paused = false;
    emit ROLEUNPAUSED425(role);
  }


  function SETROLE712(Role role, address account) external ONLYOWNER389 {
    require(account != address(0), "Must supply an account.");
    _SETROLE905(role, account);
  }


  function REMOVEROLE29(Role role) external ONLYOWNER389 {
    _SETROLE905(role, address(0));
  }


  function ISPAUSED423(Role role) external view returns (bool paused) {
    paused = _ISPAUSED128(role);
  }


  function ISROLE511(Role role) external view returns (bool hasRole) {
    hasRole = _ISROLE24(role);
  }


  function ISDHARMASMARTWALLET695(
    address smartWallet, address initialUserSigningKey
  ) external view returns (bool dharmaSmartWallet) {
    dharmaSmartWallet = _ISSMARTWALLET926(smartWallet, initialUserSigningKey);
  }


  function GETDEPOSITMANAGER250() external view returns (address depositManager) {
    depositManager = _roles[uint256(Role.DEPOSIT_MANAGER)].account;
  }


  function GETADJUSTER715() external view returns (address adjuster) {
    adjuster = _roles[uint256(Role.ADJUSTER)].account;
  }


  function GETRESERVETRADER735() external view returns (address reserveTrader) {
    reserveTrader = _roles[uint256(Role.RESERVE_TRADER)].account;
  }


  function GETWITHDRAWALMANAGER7() external view returns (address withdrawalManager) {
    withdrawalManager = _roles[uint256(Role.WITHDRAWAL_MANAGER)].account;
  }


  function GETPAUSER73() external view returns (address pauser) {
    pauser = _roles[uint256(Role.PAUSER)].account;
  }


  function GETRESERVES254() external view returns (
    uint256 dai, uint256 dDai, uint256 dDaiUnderlying
  ) {
    dai = _dai939.BALANCEOF395(address(this));
    dDai = _ddai325.BALANCEOF395(address(this));
    dDaiUnderlying = _ddai325.BALANCEOFUNDERLYING111(address(this));
  }


  function GETDAILIMIT529() external view returns (
    uint256 daiAmount, uint256 dDaiAmount
  ) {
    daiAmount = _daiLimit;
    dDaiAmount = (daiAmount.MUL1(1e18)).DIV802(_ddai325.EXCHANGERATECURRENT826());
  }


  function GETETHERLIMIT792() external view returns (uint256 etherAmount) {
    etherAmount = _etherLimit;
  }


  function GETPRIMARYUSDCRECIPIENT771() external view returns (
    address recipient
  ) {
    recipient = _primaryUSDCRecipient;
  }


  function GETPRIMARYDAIRECIPIENT209() external view returns (
    address recipient
  ) {
    recipient = _primaryDaiRecipient;
  }

  function GETIMPLEMENTATION393() external view returns (
    address implementation
  ) {
    (bool ok, bytes memory returnData) = address(
      0x481B1a16E6675D33f8BBb3a6A58F5a9678649718
    ).staticcall("");
    require(ok && returnData.length == 32, "Invalid implementation.");
    implementation = abi.decode(returnData, (address));
  }

  function GETVERSION945() external view returns (uint256 version) {
    version = _version934;
  }

  function _GRANTUNISWAPROUTERAPPROVALIFNECESSARY324(ERC20Interface token) internal {

    if (token.ALLOWANCE335(address(this), address(_uniswap_router877)) != uint256(-1)) {
      (bool success, bytes memory data) = address(token).call(
        abi.encodeWithSelector(
          token.APPROVE301.selector, address(_uniswap_router877), uint256(-1)
        )
      );
      require(
        success && (data.length == 0 || abi.decode(data, (bool))),
        "Token approval for Uniswap router failed."
      );
    }
  }


  function _SETROLE905(Role role, address account) internal {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];

    if (account != storedRoleStatus.account) {
      storedRoleStatus.account = account;
      emit ROLEMODIFIED858(role, account);
    }
  }


  function _ISROLE24(Role role) internal view returns (bool hasRole) {
    hasRole = msg.sender == _roles[uint256(role)].account;
  }


  function _ISPAUSED128(Role role) internal view returns (bool paused) {
    paused = _roles[uint256(role)].paused;
  }


  function _ISSMARTWALLET926(
    address smartWallet, address initialUserSigningKey
  ) internal pure returns (bool) {

    bytes32 initCodeHash = keccak256(
      abi.encodePacked(
        _wallet_creation_code_header138,
        initialUserSigningKey,
        _wallet_creation_code_footer303
      )
    );


    address target;
    for (uint256 nonce = 0; nonce < 10; nonce++) {
      target = address(
        uint160(
          uint256(
            keccak256(
              abi.encodePacked(
                _create2_header376,
                nonce,
                initCodeHash
              )
            )
          )
        )
      );


      if (target == smartWallet) {
        return true;
      }


      nonce++;
    }


    return false;
  }

  function _TRANSFERTOKEN930(ERC20Interface token, address to, uint256 amount) internal {
    (bool success, bytes memory data) = address(token).call(
      abi.encodeWithSelector(token.TRANSFER424.selector, to, amount)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'Transfer out failed.'
    );
  }

  function _TRANSFERINTOKEN213(ERC20Interface token, address from, uint256 amount) internal {
    (bool success, bytes memory data) = address(token).call(
      abi.encodeWithSelector(token.TRANSFERFROM59.selector, from, address(this), amount)
    );

    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'Transfer in failed.'
    );
  }

  function _ENSURESMARTWALLET516(
    address smartWallet, address initialUserSigningKey
  ) internal view {
    require(
      _ISSMARTWALLET926(smartWallet, initialUserSigningKey),
      "Could not resolve smart wallet using provided signing key."
    );
  }

  function _CREATEPATHANDAMOUNTS796(
    address start, address end, bool routeThroughEther
  ) internal pure returns (address[] memory, uint256[] memory) {
    uint256 pathLength = routeThroughEther ? 3 : 2;
    address[] memory path = new address[](pathLength);
    path[0] = start;

    if (routeThroughEther) {
      path[1] = _weth740;
    }

    path[pathLength - 1] = end;

    return (path, new uint256[](pathLength));
  }


  modifier ONLYOWNEROR665(Role role) {
    if (!ISOWNER823()) {
      require(_ISROLE24(role), "Caller does not have a required role.");
      require(!_ISPAUSED128(role), "Role in question is currently paused.");
    }
    _;
  }
}
