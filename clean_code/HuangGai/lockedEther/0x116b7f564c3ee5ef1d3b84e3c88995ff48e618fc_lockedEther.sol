



pragma solidity 0.5.17;


interface DharmaTradeReserveV12Interface {
  event Trade(
    address account,
    address suppliedAsset,
    address receivedAsset,
    address retainedAsset,
    uint256 suppliedAmount,
    uint256 recievedAmount,
    uint256 retainedAmount
  );

  event RoleModified(Role indexed role, address account);
  event RolePaused(Role indexed role);
  event RoleUnpaused(Role indexed role);

  event EtherReceived(address sender, uint256 amount);

  enum Role {
    DEPOSIT_MANAGER,
    ADJUSTER,
    WITHDRAWAL_MANAGER,
    RESERVE_TRADER,
    PAUSER
  }

  enum TradeType {
    DAI_TO_TOKEN,
    DAI_TO_ETH,
    ETH_TO_DAI,
    TOKEN_TO_DAI,
    ETH_TO_TOKEN,
    TOKEN_TO_ETH
  }

  struct RoleStatus {
    address account;
    bool paused;
  }

  function tradeDaiForEther(
    uint256 daiAmount, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalDaiSold);

  function tradeDaiForEtherV2(
    uint256 daiAmount, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalDaiSold);

  function tradeEtherForDai(
    uint256 quotedDaiAmount, uint256 deadline
  ) external payable returns (uint256 totalDaiBought);

  function tradeEtherForDaiV2(
    uint256 quotedDaiAmount, uint256 deadline
  ) external payable returns (uint256 totalDaiBought);

  function tradeDaiForToken(
    address token,
    uint256 daiAmount,
    uint256 quotedTokenAmount,
    uint256 deadline,
    bool routeThroughEther
  ) external returns (uint256 totalDaiSold);

  function tradeTokenForDai(
    ERC20Interface token,
    uint256 tokenAmount,
    uint256 quotedDaiAmount,
    uint256 deadline,
    bool routeThroughEther
  ) external returns (uint256 totalDaiBought);

  function tradeTokenForEther(
    ERC20Interface token,
    uint256 tokenAmount,
    uint256 quotedEtherAmount,
    uint256 deadline
  ) external returns (uint256 totalEtherBought);

  function tradeEtherForToken(
    address token, uint256 quotedTokenAmount, uint256 deadline
  ) external payable returns (uint256 totalEtherSold);

  function tradeEtherForTokenUsingEtherizer(
    address token,
    uint256 etherAmount,
    uint256 quotedTokenAmount,
    uint256 deadline
  ) external returns (uint256 totalEtherSold);

  function tradeDaiForEtherUsingReserves(
    uint256 daiAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalDaiSold);

  function tradeDaiForEtherUsingReservesV2(
    uint256 daiAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalDaiSold);

  function tradeEtherForDaiUsingReservesAndMintDDai(
    uint256 etherAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline
  ) external returns (uint256 totalDaiBought, uint256 totalDDaiMinted);

  function tradeEtherForDaiUsingReservesAndMintDDaiV2(
    uint256 etherAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline
  ) external returns (uint256 totalDaiBought, uint256 totalDDaiMinted);

  function tradeDaiForTokenUsingReserves(
    address token,
    uint256 daiAmountFromReserves,
    uint256 quotedTokenAmount,
    uint256 deadline,
    bool routeThroughEther
  ) external returns (uint256 totalDaiSold);

  function tradeTokenForDaiUsingReservesAndMintDDai(
    ERC20Interface token,
    uint256 tokenAmountFromReserves,
    uint256 quotedDaiAmount,
    uint256 deadline,
    bool routeThroughEther
  ) external returns (uint256 totalDaiBought, uint256 totalDDaiMinted);

  function tradeTokenForEtherUsingReserves(
    ERC20Interface token,
    uint256 tokenAmountFromReserves,
    uint256 quotedEtherAmount,
    uint256 deadline
  ) external returns (uint256 totalEtherBought);

  function tradeEtherForTokenUsingReserves(
    address token,
    uint256 etherAmountFromReserves,
    uint256 quotedTokenAmount,
    uint256 deadline
  ) external returns (uint256 totalEtherSold);

  function finalizeEtherDeposit(
    address payable smartWallet,
    address initialUserSigningKey,
    uint256 etherAmount
  ) external;

  function finalizeDaiDeposit(
    address smartWallet, address initialUserSigningKey, uint256 daiAmount
  ) external;

  function finalizeDharmaDaiDeposit(
    address smartWallet, address initialUserSigningKey, uint256 dDaiAmount
  ) external;

  function mint(uint256 daiAmount) external returns (uint256 dDaiMinted);

  function redeem(uint256 dDaiAmount) external returns (uint256 daiReceived);

  function tradeDDaiForUSDC(
    uint256 daiEquivalentAmount, uint256 quotedUSDCAmount
  ) external returns (uint256 usdcReceived);

  function tradeUSDCForDDai(
    uint256 usdcAmount, uint256 quotedDaiEquivalentAmount
  ) external returns (uint256 dDaiMinted);

  function withdrawUSDC(address recipient, uint256 usdcAmount) external;

  function withdrawDai(address recipient, uint256 daiAmount) external;

  function withdrawDharmaDai(address recipient, uint256 dDaiAmount) external;

  function withdrawUSDCToPrimaryRecipient(uint256 usdcAmount) external;

  function withdrawDaiToPrimaryRecipient(uint256 usdcAmount) external;

  function withdrawEther(
    address payable recipient, uint256 etherAmount
  ) external;

  function withdraw(
    ERC20Interface token, address recipient, uint256 amount
  ) external returns (bool success);

  function callAny(
    address payable target, uint256 amount, bytes calldata data
  ) external returns (bool ok, bytes memory returnData);

  function setDaiLimit(uint256 daiAmount) external;

  function setEtherLimit(uint256 daiAmount) external;

  function setPrimaryUSDCRecipient(address recipient) external;

  function setPrimaryDaiRecipient(address recipient) external;

  function setRole(Role role, address account) external;

  function removeRole(Role role) external;

  function pause(Role role) external;

  function unpause(Role role) external;

  function isPaused(Role role) external view returns (bool paused);

  function isRole(Role role) external view returns (bool hasRole);

  function isDharmaSmartWallet(
    address smartWallet, address initialUserSigningKey
  ) external view returns (bool dharmaSmartWallet);

  function getDepositManager() external view returns (address depositManager);

  function getAdjuster() external view returns (address adjuster);

  function getReserveTrader() external view returns (address reserveTrader);

  function getWithdrawalManager() external view returns (address withdrawalManager);

  function getPauser() external view returns (address pauser);

  function getReserves() external view returns (
    uint256 dai, uint256 dDai, uint256 dDaiUnderlying
  );

  function getDaiLimit() external view returns (
    uint256 daiAmount, uint256 dDaiAmount
  );

  function getEtherLimit() external view returns (uint256 etherAmount);

  function getPrimaryUSDCRecipient() external view returns (
    address recipient
  );

  function getPrimaryDaiRecipient() external view returns (
    address recipient
  );

  function getImplementation() external view returns (address implementation);

  function getVersion() external view returns (uint256 version);
}


interface ERC20Interface {
  function balanceOf(address) external view returns (uint256);
  function approve(address, uint256) external returns (bool);
  function allowance(address, address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
}


interface DTokenInterface {
  function mint(uint256 underlyingToSupply) external returns (uint256 dTokensMinted);
  function redeem(uint256 dTokensToBurn) external returns (uint256 underlyingReceived);
  function redeemUnderlying(uint256 underlyingToReceive) external returns (uint256 dTokensBurned);
  function balanceOf(address) external view returns (uint256);
  function balanceOfUnderlying(address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function exchangeRateCurrent() external view returns (uint256);
}


interface TradeHelperInterface {
  function tradeUSDCForDDai(
    uint256 amountUSDC,
    uint256 quotedDaiEquivalentAmount
  ) external returns (uint256 dDaiMinted);
  function tradeDDaiForUSDC(
    uint256 amountDai,
    uint256 quotedUSDCAmount
  ) external returns (uint256 usdcReceived);
  function getExpectedDai(uint256 usdc) external view returns (uint256 dai);
  function getExpectedUSDC(uint256 dai) external view returns (uint256 usdc);
}


interface UniswapV1Interface {
  function ethToTokenSwapInput(
    uint256 minTokens, uint256 deadline
  ) external payable returns (uint256 tokensBought);

  function tokenToEthTransferOutput(
    uint256 ethBought, uint256 maxTokens, uint256 deadline, address recipient
  ) external returns (uint256 tokensSold);
}


interface UniswapV2Interface {
  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);
}


interface EtherReceiverInterface {
  function settleEther() external;
}


library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }
}














contract TwoStepOwnable {
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  address private _owner;

  address private _newPotentialOwner;





  function transferOwnership(address newOwner) external onlyOwner {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }





  function cancelOwnershipTransfer() external onlyOwner {
    delete _newPotentialOwner;
  }





  function acceptOwnership() external {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }




  function owner() external view returns (address) {
    return _owner;
  }




  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }




  modifier onlyOwner() {
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }
}






















contract DharmaTradeReserveV12Implementation is DharmaTradeReserveV12Interface, TwoStepOwnable {
  using SafeMath for uint256;


  mapping(uint256 => RoleStatus) private _roles;


  address private _primaryDaiRecipient;


  address private _primaryUSDCRecipient;


  uint256 private _daiLimit;


  uint256 private _etherLimit;

  bool private _originatesFromReserveTrader;

  uint256 private constant _VERSION = 12;


  ERC20Interface internal constant _USDC = ERC20Interface(
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
  );

  ERC20Interface internal constant _DAI = ERC20Interface(
    0x6B175474E89094C44Da98b954EedeAC495271d0F
  );

  ERC20Interface internal constant _ETHERIZER = ERC20Interface(
    0x723B51b72Ae89A3d0c2a2760f0458307a1Baa191
  );

  DTokenInterface internal constant _DDAI = DTokenInterface(
    0x00000000001876eB1444c986fD502e618c587430
  );

  TradeHelperInterface internal constant _TRADE_HELPER = TradeHelperInterface(
    0x9328F2Fb3e85A4d24Adc2f68F82737183e85691d
  );

  UniswapV1Interface internal constant _UNISWAP_DAI = UniswapV1Interface(
    0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667
  );

  UniswapV2Interface internal constant _UNISWAP_ROUTER = UniswapV2Interface(
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  );

  EtherReceiverInterface internal constant _ETH_RECEIVER = EtherReceiverInterface(
    0x0EBE1a9CBF4e27D507A5f1b51CC308B727D956C6
  );

  address internal constant _WETH = address(
    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
  );

  bytes21 internal constant _CREATE2_HEADER = bytes21(
    0xfffc00c80b0000007f73004edb00094cad80626d8d
  );

  bytes internal constant _WALLET_CREATION_CODE_HEADER = hex"60806040526040516104423803806104428339818101604052602081101561002657600080fd5b810190808051604051939291908464010000000082111561004657600080fd5b90830190602082018581111561005b57600080fd5b825164010000000081118282018810171561007557600080fd5b82525081516020918201929091019080838360005b838110156100a257818101518382015260200161008a565b50505050905090810190601f1680156100cf5780820380516001836020036101000a031916815260200191505b5060405250505060006100e661019e60201b60201c565b6001600160a01b0316826040518082805190602001908083835b6020831061011f5780518252601f199092019160209182019101610100565b6001836020036101000a038019825116818451168082178552505050505050905001915050600060405180830381855af49150503d806000811461017f576040519150601f19603f3d011682016040523d82523d6000602084013e610184565b606091505b5050905080610197573d6000803e3d6000fd5b50506102be565b60405160009081906060906e26750c571ce882b17016557279adaa9083818181855afa9150503d80600081146101f0576040519150601f19603f3d011682016040523d82523d6000602084013e6101f5565b606091505b509150915081819061029f576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825283818151815260200191508051906020019080838360005b8381101561026457818101518382015260200161024c565b50505050905090810190601f1680156102915780820380516001836020036101000a031916815260200191505b509250505060405180910390fd5b508080602001905160208110156102b557600080fd5b50519392505050565b610175806102cd6000396000f3fe608060405261001461000f610016565b61011c565b005b60405160009081906060906e26750c571ce882b17016557279adaa9083818181855afa9150503d8060008114610068576040519150601f19603f3d011682016040523d82523d6000602084013e61006d565b606091505b50915091508181906100fd5760405162461bcd60e51b81526004018080602001828103825283818151815260200191508051906020019080838360005b838110156100c25781810151838201526020016100aa565b50505050905090810190601f1680156100ef5780820380516001836020036101000a031916815260200191505b509250505060405180910390fd5b5080806020019051602081101561011357600080fd5b50519392505050565b3660008037600080366000845af43d6000803e80801561013b573d6000f35b3d6000fdfea265627a7a7231582020202020202055706772616465426561636f6e50726f7879563120202020202064736f6c634300050b003200000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000024c4d66de8000000000000000000000000";
  bytes28 internal constant _WALLET_CREATION_CODE_FOOTER = bytes28(
    0x00000000000000000000000000000000000000000000000000000000
  );


  function () external payable {
    emit EtherReceived(msg.sender, msg.value);
  }









  function tradeDaiForEther(
    uint256 daiAmount,
    uint256 quotedEtherAmount,
    uint256 deadline
  ) external returns (uint256 totalDaiSold) {

    _transferInToken(_DAI, msg.sender, daiAmount);


    totalDaiSold = _UNISWAP_DAI.tokenToEthTransferOutput(
      quotedEtherAmount, daiAmount, deadline, msg.sender
    );

    _fireTradeEvent(
      false,
      TradeType.DAI_TO_ETH,
      address(0),
      daiAmount,
      quotedEtherAmount,
      daiAmount.sub(totalDaiSold)
    );
  }









  function tradeDaiForEtherV2(
    uint256 daiAmount,
    uint256 quotedEtherAmount,
    uint256 deadline
  ) external returns (uint256 totalDaiSold) {

    _transferInToken(_DAI, msg.sender, daiAmount);


    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      address(_DAI), _WETH, false
    );


    amounts = _UNISWAP_ROUTER.swapTokensForExactETH(
      quotedEtherAmount, daiAmount, path, msg.sender, deadline
    );
    totalDaiSold = amounts[0];

    _fireTradeEvent(
      false,
      TradeType.DAI_TO_ETH,
      address(0),
      daiAmount,
      quotedEtherAmount,
      daiAmount.sub(totalDaiSold)
    );
  }

  function tradeTokenForEther(
    ERC20Interface token, uint256 tokenAmount, uint256 quotedEtherAmount, uint256 deadline
  ) external returns (uint256 totalEtherBought) {

    _transferInToken(token, msg.sender, tokenAmount);


    _grantUniswapRouterApprovalIfNecessary(token, tokenAmount);


    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      address(token), _WETH, false
    );


    amounts = _UNISWAP_ROUTER.swapExactTokensForETH(
      tokenAmount, quotedEtherAmount, path, address(this), deadline
    );
    totalEtherBought = amounts[1];


    (bool ok, ) = msg.sender.call.value(0)("");
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }

    _fireTradeEvent(
      false,
      TradeType.TOKEN_TO_ETH,
      address(token),
      tokenAmount,
      quotedEtherAmount,
      totalEtherBought.sub(quotedEtherAmount)
    );
  }

  function tradeDaiForToken(
    address token, uint256 daiAmount, uint256 quotedTokenAmount, uint256 deadline, bool routeThroughEther
  ) external returns (uint256 totalDaiSold) {

    _transferInToken(_DAI, msg.sender, daiAmount);


    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      address(_DAI), token, routeThroughEther
    );


    amounts = _UNISWAP_ROUTER.swapTokensForExactTokens(
      quotedTokenAmount, daiAmount, path, msg.sender, deadline
    );

    totalDaiSold = amounts[0];

    _fireTradeEvent(
      false,
      TradeType.DAI_TO_TOKEN,
      address(token),
      daiAmount,
      quotedTokenAmount,
      daiAmount.sub(totalDaiSold)
    );
  }











  function tradeDaiForEtherUsingReserves(
    uint256 daiAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (uint256 totalDaiSold) {

    _redeemDDaiIfNecessary(daiAmountFromReserves);


    totalDaiSold = _UNISWAP_DAI.tokenToEthTransferOutput(
      quotedEtherAmount,
      daiAmountFromReserves,
      deadline,
      address(_ETH_RECEIVER)
    );


    _ETH_RECEIVER.settleEther();

    _fireTradeEvent(
      true,
      TradeType.DAI_TO_ETH,
      address(0),
      daiAmountFromReserves,
      quotedEtherAmount,
      daiAmountFromReserves.sub(totalDaiSold)
    );
  }











  function tradeDaiForEtherUsingReservesV2(
    uint256 daiAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (uint256 totalDaiSold) {

    _redeemDDaiIfNecessary(daiAmountFromReserves);


    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      address(_DAI), _WETH, false
    );


    amounts = _UNISWAP_ROUTER.swapTokensForExactETH(
      quotedEtherAmount, daiAmountFromReserves, path, address(this), deadline
    );
    totalDaiSold = amounts[0];

    _fireTradeEvent(
      true,
      TradeType.DAI_TO_ETH,
      address(0),
      daiAmountFromReserves,
      quotedEtherAmount,
      daiAmountFromReserves.sub(totalDaiSold)
    );
  }

  function tradeTokenForEtherUsingReserves(
    ERC20Interface token, uint256 tokenAmountFromReserves, uint256 quotedEtherAmount, uint256 deadline
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (uint256 totalEtherBought) {

    _grantUniswapRouterApprovalIfNecessary(token, tokenAmountFromReserves);


    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      address(token), _WETH, false
    );


    amounts = _UNISWAP_ROUTER.swapExactTokensForETH(
      tokenAmountFromReserves, quotedEtherAmount, path, address(this), deadline
    );
    totalEtherBought = amounts[1];

    _fireTradeEvent(
      true,
      TradeType.TOKEN_TO_ETH,
      address(token),
      tokenAmountFromReserves,
      quotedEtherAmount,
      totalEtherBought.sub(quotedEtherAmount)
    );
  }








  function tradeEtherForDai(
    uint256 quotedDaiAmount,
    uint256 deadline
  ) external payable returns (uint256 totalDaiBought) {

    totalDaiBought = _UNISWAP_DAI.ethToTokenSwapInput.value(msg.value)(
      quotedDaiAmount, deadline
    );


    _transferToken(_DAI, msg.sender, quotedDaiAmount);

    _fireTradeEvent(
      false,
      TradeType.ETH_TO_DAI,
      address(0),
      msg.value,
      quotedDaiAmount,
      totalDaiBought.sub(quotedDaiAmount)
    );
  }








  function tradeEtherForDaiV2(
    uint256 quotedDaiAmount,
    uint256 deadline
  ) external payable returns (uint256 totalDaiBought) {

    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      _WETH, address(_DAI), false
    );


    amounts = _UNISWAP_ROUTER.swapExactETHForTokens.value(msg.value)(
      quotedDaiAmount, path, address(this), deadline
    );
    totalDaiBought = amounts[1];


    _transferToken(_DAI, msg.sender, quotedDaiAmount);

    _fireTradeEvent(
      false,
      TradeType.ETH_TO_DAI,
      address(0),
      msg.value,
      quotedDaiAmount,
      totalDaiBought.sub(quotedDaiAmount)
    );
  }

  function tradeEtherForToken(
    address token, uint256 quotedTokenAmount, uint256 deadline
  ) external payable returns (uint256 totalEtherSold) {

    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      _WETH, address(token), false
    );


    amounts = _UNISWAP_ROUTER.swapETHForExactTokens.value(msg.value)(
      quotedTokenAmount, path, msg.sender, deadline
    );
    totalEtherSold = amounts[0];

    _fireTradeEvent(
      false,
      TradeType.ETH_TO_TOKEN,
      address(token),
      msg.value,
      quotedTokenAmount,
      msg.value.sub(totalEtherSold)
    );
  }

  function tradeEtherForTokenUsingEtherizer(
    address token, uint256 etherAmount, uint256 quotedTokenAmount, uint256 deadline
  ) external returns (uint256 totalEtherSold) {

    _transferInToken(_ETHERIZER, msg.sender, etherAmount);


    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      _WETH, address(token), false
    );


    amounts = _UNISWAP_ROUTER.swapETHForExactTokens.value(etherAmount)(
      quotedTokenAmount, path, msg.sender, deadline
    );
    totalEtherSold = amounts[0];

    _fireTradeEvent(
      false,
      TradeType.ETH_TO_TOKEN,
      address(token),
      etherAmount,
      quotedTokenAmount,
      etherAmount.sub(totalEtherSold)
    );
  }

  function tradeTokenForDai(
    ERC20Interface token, uint256 tokenAmount, uint256 quotedDaiAmount, uint256 deadline, bool routeThroughEther
  ) external returns (uint256 totalDaiBought) {

    _transferInToken(token, msg.sender, tokenAmount);


    _grantUniswapRouterApprovalIfNecessary(token, tokenAmount);


    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      address(token), address(_DAI), routeThroughEther
    );


    amounts = _UNISWAP_ROUTER.swapExactTokensForTokens(
      tokenAmount, quotedDaiAmount, path, msg.sender, deadline
    );

    totalDaiBought = amounts[path.length - 1];


    _transferToken(_DAI, msg.sender, quotedDaiAmount);

    _fireTradeEvent(
      false,
      TradeType.TOKEN_TO_DAI,
      address(token),
      tokenAmount,
      quotedDaiAmount,
      totalDaiBought.sub(quotedDaiAmount)
    );
  }











  function tradeEtherForDaiUsingReservesAndMintDDai(
    uint256 etherAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (
    uint256 totalDaiBought, uint256 totalDDaiMinted
  ) {

    totalDaiBought = _UNISWAP_DAI.ethToTokenSwapInput.value(
      etherAmountFromReserves
    )(
      quotedDaiAmount, deadline
    );


    totalDDaiMinted = _DDAI.mint(totalDaiBought);

    _fireTradeEvent(
      true,
      TradeType.ETH_TO_DAI,
      address(0),
      etherAmountFromReserves,
      quotedDaiAmount,
      totalDaiBought.sub(quotedDaiAmount)
    );
  }











  function tradeEtherForDaiUsingReservesAndMintDDaiV2(
    uint256 etherAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (
    uint256 totalDaiBought, uint256 totalDDaiMinted
  ) {

    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      _WETH, address(_DAI), false
    );


    amounts = _UNISWAP_ROUTER.swapExactETHForTokens.value(
      etherAmountFromReserves
    )(
      quotedDaiAmount, path, address(this), deadline
    );
    totalDaiBought = amounts[1];


    totalDDaiMinted = _DDAI.mint(totalDaiBought);

    _fireTradeEvent(
      true,
      TradeType.ETH_TO_DAI,
      address(0),
      etherAmountFromReserves,
      quotedDaiAmount,
      totalDaiBought.sub(quotedDaiAmount)
    );
  }

  function tradeEtherForTokenUsingReserves(
    address token, uint256 etherAmountFromReserves, uint256 quotedTokenAmount, uint256 deadline
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (uint256 totalEtherSold) {

    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      _WETH, address(token), false
    );


    amounts = _UNISWAP_ROUTER.swapETHForExactTokens.value(etherAmountFromReserves)(
      quotedTokenAmount, path, address(this), deadline
    );
    totalEtherSold = amounts[0];

    _fireTradeEvent(
      true,
      TradeType.ETH_TO_TOKEN,
      address(token),
      etherAmountFromReserves,
      quotedTokenAmount,
      etherAmountFromReserves.sub(totalEtherSold)
    );
  }

  function tradeDaiForTokenUsingReserves(
    address token, uint256 daiAmountFromReserves, uint256 quotedTokenAmount, uint256 deadline, bool routeThroughEther
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (uint256 totalDaiSold) {

    _redeemDDaiIfNecessary(daiAmountFromReserves);


    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      address(_DAI), address(token), routeThroughEther
    );


    amounts = _UNISWAP_ROUTER.swapTokensForExactTokens(
      quotedTokenAmount, daiAmountFromReserves, path, address(this), deadline
    );

    totalDaiSold = amounts[0];

    _fireTradeEvent(
      true,
      TradeType.DAI_TO_TOKEN,
      address(token),
      daiAmountFromReserves,
      quotedTokenAmount,
      daiAmountFromReserves.sub(totalDaiSold)
    );
  }

  function tradeTokenForDaiUsingReservesAndMintDDai(
    ERC20Interface token, uint256 tokenAmountFromReserves, uint256 quotedDaiAmount, uint256 deadline, bool routeThroughEther
  ) external onlyOwnerOr(Role.RESERVE_TRADER) returns (
    uint256 totalDaiBought, uint256 totalDDaiMinted
  ) {

    _grantUniswapRouterApprovalIfNecessary(token, tokenAmountFromReserves);


    (address[] memory path, uint256[] memory amounts) = _createPathAndAmounts(
      address(token), address(_DAI), routeThroughEther
    );


    amounts = _UNISWAP_ROUTER.swapExactTokensForTokens(
      tokenAmountFromReserves, quotedDaiAmount, path, address(this), deadline
    );

    totalDaiBought = amounts[path.length - 1];


    totalDDaiMinted = _DDAI.mint(totalDaiBought);

    _fireTradeEvent(
      true,
      TradeType.TOKEN_TO_DAI,
      address(token),
      tokenAmountFromReserves,
      quotedDaiAmount,
      totalDaiBought.sub(quotedDaiAmount)
    );
  }















  function finalizeDaiDeposit(
    address smartWallet, address initialUserSigningKey, uint256 daiAmount
  ) external onlyOwnerOr(Role.DEPOSIT_MANAGER) {

    _ensureSmartWallet(smartWallet, initialUserSigningKey);


    require(daiAmount < _daiLimit, "Transfer size exceeds the limit.");


    _transferToken(_DAI, smartWallet, daiAmount);
  }
















  function finalizeDharmaDaiDeposit(
    address smartWallet, address initialUserSigningKey, uint256 dDaiAmount
  ) external onlyOwnerOr(Role.DEPOSIT_MANAGER) {

    _ensureSmartWallet(smartWallet, initialUserSigningKey);


    uint256 exchangeRate = _DDAI.exchangeRateCurrent();


    require(exchangeRate != 0, "Could not retrieve dDai exchange rate.");


    uint256 daiEquivalent = (dDaiAmount.mul(exchangeRate)) / 1e18;


    require(daiEquivalent < _daiLimit, "Transfer size exceeds the limit.");


    _transferToken(ERC20Interface(address(_DDAI)), smartWallet, dDaiAmount);
  }
















  function finalizeEtherDeposit(
    address payable smartWallet,
    address initialUserSigningKey,
    uint256 etherAmount
  ) external onlyOwnerOr(Role.DEPOSIT_MANAGER) {

    _ensureSmartWallet(smartWallet, initialUserSigningKey);


    require(etherAmount < _etherLimit, "Transfer size exceeds the limit.");


    bool ok;
    (ok, ) = smartWallet.call.value(0)("");
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }








  function mint(
    uint256 daiAmount
  ) external onlyOwnerOr(Role.ADJUSTER) returns (uint256 dDaiMinted) {

    dDaiMinted = _DDAI.mint(daiAmount);
  }








  function redeem(
    uint256 dDaiAmount
  ) external onlyOwnerOr(Role.ADJUSTER) returns (uint256 daiReceived) {

    daiReceived = _DDAI.redeem(dDaiAmount);
  }










  function tradeUSDCForDDai(
    uint256 usdcAmount,
    uint256 quotedDaiEquivalentAmount
  ) external onlyOwnerOr(Role.ADJUSTER) returns (uint256 dDaiMinted) {
    dDaiMinted = _TRADE_HELPER.tradeUSDCForDDai(
       usdcAmount, quotedDaiEquivalentAmount
    );
  }











  function tradeDDaiForUSDC(
    uint256 daiEquivalentAmount,
    uint256 quotedUSDCAmount
  ) external onlyOwnerOr(Role.ADJUSTER) returns (uint256 usdcReceived) {
    usdcReceived = _TRADE_HELPER.tradeDDaiForUSDC(
      daiEquivalentAmount, quotedUSDCAmount
    );
  }






  function withdrawUSDCToPrimaryRecipient(
    uint256 usdcAmount
  ) external onlyOwnerOr(Role.WITHDRAWAL_MANAGER) {

    address primaryRecipient = _primaryUSDCRecipient;
    require(
      primaryRecipient != address(0), "No USDC primary recipient currently set."
    );


    _transferToken(_USDC, primaryRecipient, usdcAmount);
  }






  function withdrawDaiToPrimaryRecipient(
    uint256 daiAmount
  ) external onlyOwnerOr(Role.WITHDRAWAL_MANAGER) {

    address primaryRecipient = _primaryDaiRecipient;
    require(
      primaryRecipient != address(0), "No Dai primary recipient currently set."
    );


    _transferToken(_DAI, primaryRecipient, daiAmount);
  }







  function withdrawUSDC(
    address recipient, uint256 usdcAmount
  ) external onlyOwner {

    _transferToken(_USDC, recipient, usdcAmount);
  }







  function withdrawDai(
    address recipient, uint256 daiAmount
  ) external onlyOwner {

    _transferToken(_DAI, recipient, daiAmount);
  }







  function withdrawDharmaDai(
    address recipient, uint256 dDaiAmount
  ) external onlyOwner {

    _transferToken(ERC20Interface(address(_DDAI)), recipient, dDaiAmount);
  }







  function withdrawEther(
    address payable recipient, uint256 etherAmount
  ) external onlyOwner {
    bool ok;


    (ok, ) = recipient.call.value(0)("");
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }
  }










  function withdraw(
    ERC20Interface token, address recipient, uint256 amount
  ) external onlyOwner returns (bool success) {

    success = token.transfer(recipient, amount);
  }










  function callAny(
    address payable target, uint256 amount, bytes calldata data
  ) external onlyOwner returns (bool ok, bytes memory returnData) {

    (ok, returnData) = target.call.value(0)(data);
  }






  function setDaiLimit(uint256 daiAmount) external onlyOwner {

    _daiLimit = daiAmount;
  }






  function setEtherLimit(uint256 etherAmount) external onlyOwner {

    _etherLimit = etherAmount;
  }






  function setPrimaryUSDCRecipient(address recipient) external onlyOwner {

    _primaryUSDCRecipient = recipient;
  }






  function setPrimaryDaiRecipient(address recipient) external onlyOwner {

    _primaryDaiRecipient = recipient;
  }







  function pause(Role role) external onlyOwnerOr(Role.PAUSER) {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(!storedRoleStatus.paused, "Role in question is already paused.");
    storedRoleStatus.paused = true;
    emit RolePaused(role);
  }






  function unpause(Role role) external onlyOwner {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(storedRoleStatus.paused, "Role in question is already unpaused.");
    storedRoleStatus.paused = false;
    emit RoleUnpaused(role);
  }







  function setRole(Role role, address account) external onlyOwner {
    require(account != address(0), "Must supply an account.");
    _setRole(role, account);
  }







  function removeRole(Role role) external onlyOwner {
    _setRole(role, address(0));
  }











  function isPaused(Role role) external view returns (bool paused) {
    paused = _isPaused(role);
  }







  function isRole(Role role) external view returns (bool hasRole) {
    hasRole = _isRole(role);
  }













  function isDharmaSmartWallet(
    address smartWallet, address initialUserSigningKey
  ) external view returns (bool dharmaSmartWallet) {
    dharmaSmartWallet = _isSmartWallet(smartWallet, initialUserSigningKey);
  }










  function getDepositManager() external view returns (address depositManager) {
    depositManager = _roles[uint256(Role.DEPOSIT_MANAGER)].account;
  }








  function getAdjuster() external view returns (address adjuster) {
    adjuster = _roles[uint256(Role.ADJUSTER)].account;
  }








  function getReserveTrader() external view returns (address reserveTrader) {
    reserveTrader = _roles[uint256(Role.RESERVE_TRADER)].account;
  }








  function getWithdrawalManager() external view returns (address withdrawalManager) {
    withdrawalManager = _roles[uint256(Role.WITHDRAWAL_MANAGER)].account;
  }









  function getPauser() external view returns (address pauser) {
    pauser = _roles[uint256(Role.PAUSER)].account;
  }







  function getReserves() external view returns (
    uint256 dai, uint256 dDai, uint256 dDaiUnderlying
  ) {
    dai = _DAI.balanceOf(address(this));
    dDai = _DDAI.balanceOf(address(this));
    dDaiUnderlying = _DDAI.balanceOfUnderlying(address(this));
  }







  function getDaiLimit() external view returns (
    uint256 daiAmount, uint256 dDaiAmount
  ) {
    daiAmount = _daiLimit;
    dDaiAmount = (daiAmount.mul(1e18)).div(_DDAI.exchangeRateCurrent());
  }






  function getEtherLimit() external view returns (uint256 etherAmount) {
    etherAmount = _etherLimit;
  }






  function getPrimaryUSDCRecipient() external view returns (
    address recipient
  ) {
    recipient = _primaryUSDCRecipient;
  }






  function getPrimaryDaiRecipient() external view returns (
    address recipient
  ) {
    recipient = _primaryDaiRecipient;
  }

  function getImplementation() external view returns (
    address implementation
  ) {
    (bool ok, bytes memory returnData) = address(
      0x2Cf7C0333D9b7F94BbF55B9701227E359F92fD31
    ).staticcall("");
    require(ok && returnData.length == 32, "Invalid implementation.");
    implementation = abi.decode(returnData, (address));
  }

  function getVersion() external view returns (uint256 version) {
    version = _VERSION;
  }

  function _grantUniswapRouterApprovalIfNecessary(ERC20Interface token, uint256 amount) internal {
    if (token.allowance(address(this), address(_UNISWAP_ROUTER)) < amount) {

      (bool success, bytes memory data) = address(token).call(
        abi.encodeWithSelector(
          token.approve.selector, address(_UNISWAP_ROUTER), uint256(0)
        )
      );
      require(
        success && (data.length == 0 || abi.decode(data, (bool))),
        "Token approval reset for Uniswap router failed."
      );


      (success, data) = address(token).call(
        abi.encodeWithSelector(
          token.approve.selector, address(_UNISWAP_ROUTER), uint256(-1)
        )
      );
      require(
        success && (data.length == 0 || abi.decode(data, (bool))),
        "Token approval for Uniswap router failed."
      );
    }
  }








  function _setRole(Role role, address account) internal {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];

    if (account != storedRoleStatus.account) {
      storedRoleStatus.account = account;
      emit RoleModified(role, account);
    }
  }

  function _fireTradeEvent(
    bool fromReserves,
    TradeType tradeType,
    address token,
    uint256 suppliedAmount,
    uint256 receivedAmount,
    uint256 retainedAmount
  ) internal {
    uint256 t = uint256(tradeType);

    emit Trade(
      fromReserves ? address(this) : msg.sender,
      t < 2 ? address(_DAI) : (t % 2 == 0 ? address(0) : token),
      (t > 1 && t < 4) ? address(_DAI) : (t % 2 == 0 ? token : address(0)),
      t < 4 ? address(_DAI) : address(0),
      suppliedAmount,
      receivedAmount,
      retainedAmount
    );
  }







  function _isRole(Role role) internal view returns (bool hasRole) {
    hasRole = msg.sender == _roles[uint256(role)].account;
  }







  function _isPaused(Role role) internal view returns (bool paused) {
    paused = _roles[uint256(role)].paused;
  }








  function _isSmartWallet(
    address smartWallet, address initialUserSigningKey
  ) internal pure returns (bool) {

    bytes32 initCodeHash = keccak256(
      abi.encodePacked(
        _WALLET_CREATION_CODE_HEADER,
        initialUserSigningKey,
        _WALLET_CREATION_CODE_FOOTER
      )
    );


    address target;
    for (uint256 nonce = 0; nonce < 10; nonce++) {
      target = address(
        uint160(
          uint256(
            keccak256(
              abi.encodePacked(
                _CREATE2_HEADER,
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

  function _redeemDDaiIfNecessary(uint256 daiAmountFromReserves) internal {
    uint256 daiBalance = _DAI.balanceOf(address(this));
    if (daiBalance < daiAmountFromReserves) {
      uint256 additionalDaiRequired = daiAmountFromReserves - daiBalance;
      _DDAI.redeemUnderlying(additionalDaiRequired);
    }
  }

  function _transferToken(ERC20Interface token, address to, uint256 amount) internal {
    (bool success, bytes memory data) = address(token).call(
      abi.encodeWithSelector(token.transfer.selector, to, amount)
    );
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'Transfer out failed.'
    );
  }

  function _transferInToken(ERC20Interface token, address from, uint256 amount) internal {
    (bool success, bytes memory data) = address(token).call(
      abi.encodeWithSelector(token.transferFrom.selector, from, address(this), amount)
    );

    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'Transfer in failed.'
    );
  }

  function _ensureSmartWallet(
    address smartWallet, address initialUserSigningKey
  ) internal pure {
    require(
      _isSmartWallet(smartWallet, initialUserSigningKey),
      "Could not resolve smart wallet using provided signing key."
    );
  }

  function _createPathAndAmounts(
    address start, address end, bool routeThroughEther
  ) internal pure returns (address[] memory, uint256[] memory) {
    uint256 pathLength = routeThroughEther ? 3 : 2;
    address[] memory path = new address[](pathLength);
    path[0] = start;

    if (routeThroughEther) {
      path[1] = _WETH;
    }

    path[pathLength - 1] = end;

    return (path, new uint256[](pathLength));
  }







  modifier onlyOwnerOr(Role role) {
    if (!isOwner()) {
      require(_isRole(role), "Caller does not have a required role.");
      require(!_isPaused(role), "Role in question is currently paused.");
    }
    _;
  }
}
