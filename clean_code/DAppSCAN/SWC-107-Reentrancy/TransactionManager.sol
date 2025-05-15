
pragma solidity 0.8.4;

import "./interfaces/IFulfillInterpreter.sol";
import "./interfaces/ITransactionManager.sol";
import "./interpreters/FulfillInterpreter.sol";
import "./ProposedOwnable.sol";
import "./lib/LibAsset.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";










































contract TransactionManager is ReentrancyGuard, ProposedOwnable, ITransactionManager {



  mapping(address => mapping(address => uint256)) public routerBalances;





  mapping(address => bool) public approvedRouters;




  mapping(address => bool) public approvedAssets;





  mapping(bytes32 => bytes32) public variantTransactionData;





  uint256 private immutable chainId;




  uint256 public constant MIN_TIMEOUT = 1 days;




  uint256 public constant MAX_TIMEOUT = 30 days;





  IFulfillInterpreter public immutable interpreter;

  constructor(uint256 _chainId) {
    chainId = _chainId;
    interpreter = new FulfillInterpreter(address(this));
  }





  function getChainId() public view override returns (uint256 _chainId) {

    uint256 chain = chainId;
    if (chain == 0) {

      assembly {
        _chainId := chainid()
      }
    } else {

      _chainId = chain;
    }
  }




  function getStoredChainId() external view override returns (uint256) {
    return chainId;
  }





  function addRouter(address router) external override onlyOwner {

    require(router != address(0), "#AR:001");


    require(approvedRouters[router] == false, "#AR:032");


    approvedRouters[router] = true;


    emit RouterAdded(router, msg.sender);
  }





  function removeRouter(address router) external override onlyOwner {

    require(router != address(0), "#RR:001");


    require(approvedRouters[router] == true, "#RR:033");


    approvedRouters[router] = false;


    emit RouterRemoved(router, msg.sender);
  }






  function addAssetId(address assetId) external override onlyOwner {

    require(approvedAssets[assetId] == false, "#AA:032");


    approvedAssets[assetId] = true;


    emit AssetAdded(assetId, msg.sender);
  }






  function removeAssetId(address assetId) external override onlyOwner {

    require(approvedAssets[assetId] == true, "#RA:033");


    approvedAssets[assetId] = false;


    emit AssetRemoved(assetId, msg.sender);
  }









  function addLiquidityFor(uint256 amount, address assetId, address router) external payable override nonReentrant {
    _addLiquidityForRouter(amount, assetId, router);
  }








  function addLiquidity(uint256 amount, address assetId) external payable override nonReentrant {
    _addLiquidityForRouter(amount, assetId, msg.sender);
  }










  function removeLiquidity(
    uint256 amount,
    address assetId,
    address payable recipient
  ) external override nonReentrant {

    require(recipient != address(0), "#RL:007");


    require(amount > 0, "#RL:002");

    uint256 routerBalance = routerBalances[msg.sender][assetId];

    require(routerBalance >= amount, "#RL:008");


    unchecked {
      routerBalances[msg.sender][assetId] = routerBalance - amount;
    }


    LibAsset.transferAsset(assetId, recipient, amount);


    emit LiquidityRemoved(msg.sender, assetId, amount, recipient);
  }

































  function prepare(
    InvariantTransactionData calldata invariantData,
    uint256 amount,
    uint256 expiry,
    bytes calldata encryptedCallData,
    bytes calldata encodedBid,
    bytes calldata bidSignature
  ) external payable override nonReentrant returns (TransactionData memory) {

    require(invariantData.user != address(0), "#P:009");


    require(invariantData.router != address(0), "#P:001");


    require(isRouterOwnershipRenounced() || approvedRouters[invariantData.router], "#P:003");


    require(invariantData.sendingChainFallback != address(0), "#P:010");


    require(invariantData.receivingAddress != address(0), "#P:026");


    require(invariantData.sendingChainId != invariantData.receivingChainId, "#P:011");


    uint256 _chainId = getChainId();
    require(invariantData.sendingChainId == _chainId || invariantData.receivingChainId == _chainId, "#P:012");

    {

      uint256 buffer = expiry - block.timestamp;
      require(buffer >= MIN_TIMEOUT, "#P:013");


      require(buffer <= MAX_TIMEOUT, "#P:014");
    }


    bytes32 digest = keccak256(abi.encode(invariantData));
    require(variantTransactionData[digest] == bytes32(0), "#P:015");









    if (invariantData.sendingChainId == _chainId) {




      require(amount > 0, "#P:002");




      require(isAssetOwnershipRenounced() || approvedAssets[invariantData.sendingAssetId], "#P:004");









      amount = transferAssetToContract(invariantData.sendingAssetId, amount);



      variantTransactionData[digest] = hashVariantTransactionData(amount, expiry, block.number);
    } else {














      require(invariantData.callTo == address(0) || Address.isContract(invariantData.callTo), "#P:031");





      require(isAssetOwnershipRenounced() || approvedAssets[invariantData.receivingAssetId], "#P:004");


      require(msg.sender == invariantData.router, "#P:016");


      require(msg.value == 0, "#P:017");


      uint256 balance = routerBalances[invariantData.router][invariantData.receivingAssetId];
      require(balance >= amount, "#P:018");


      variantTransactionData[digest] = hashVariantTransactionData(amount, expiry, block.number);



      unchecked {
        routerBalances[invariantData.router][invariantData.receivingAssetId] = balance - amount;
      }
    }


    TransactionData memory txData = TransactionData({
      receivingChainTxManagerAddress: invariantData.receivingChainTxManagerAddress,
      user: invariantData.user,
      router: invariantData.router,
      sendingAssetId: invariantData.sendingAssetId,
      receivingAssetId: invariantData.receivingAssetId,
      sendingChainFallback: invariantData.sendingChainFallback,
      callTo: invariantData.callTo,
      receivingAddress: invariantData.receivingAddress,
      callDataHash: invariantData.callDataHash,
      transactionId: invariantData.transactionId,
      sendingChainId: invariantData.sendingChainId,
      receivingChainId: invariantData.receivingChainId,
      amount: amount,
      expiry: expiry,
      preparedBlockNumber: block.number
    });
    emit TransactionPrepared(txData.user, txData.router, txData.transactionId, txData, msg.sender, encryptedCallData, encodedBid, bidSignature);
    return txData;
  }
























  function fulfill(
    TransactionData calldata txData,
    uint256 relayerFee,
    bytes calldata signature,
    bytes calldata callData
  ) external override nonReentrant returns (TransactionData memory) {




    {
      bytes32 digest = hashInvariantTransactionData(txData);


      require(variantTransactionData[digest] == hashVariantTransactionData(txData.amount, txData.expiry, txData.preparedBlockNumber), "#F:019");


      require(txData.expiry >= block.timestamp, "#F:020");


      require(txData.preparedBlockNumber > 0, "#F:021");


      require(recoverFulfillSignature(txData.transactionId, relayerFee, txData.receivingChainId, txData.receivingChainTxManagerAddress, signature) == txData.user, "#F:022");



      require(relayerFee <= txData.amount, "#F:023");


      require(keccak256(callData) == txData.callDataHash, "#F:024");







      variantTransactionData[digest] = hashVariantTransactionData(txData.amount, txData.expiry, 0);
    }



    bool success;
    bytes memory returnData;

    if (txData.sendingChainId == getChainId()) {






      require(msg.sender == txData.router, "#F:016");


      routerBalances[txData.router][txData.sendingAssetId] += txData.amount;

    } else {
      (success, returnData) = _receivingChainFulfill(txData, relayerFee, callData);
    }


    emit TransactionFulfilled(
      txData.user,
      txData.router,
      txData.transactionId,
      txData,
      relayerFee,
      signature,
      callData,
      success,
      returnData,
      msg.sender
    );

    return txData;
  }















  function cancel(TransactionData calldata txData, bytes calldata signature)
    external
    override
    nonReentrant
    returns (TransactionData memory)
  {







    bytes32 digest = hashInvariantTransactionData(txData);


    require(variantTransactionData[digest] == hashVariantTransactionData(txData.amount, txData.expiry, txData.preparedBlockNumber), "#C:019");


    require(txData.preparedBlockNumber > 0, "#C:021");







    variantTransactionData[digest] = hashVariantTransactionData(txData.amount, txData.expiry, 0);


    uint256 _chainId = getChainId();


    if (txData.sendingChainId == _chainId) {

      if (txData.expiry >= block.timestamp) {




        require(msg.sender == txData.router, "#C:025");
      }




      LibAsset.transferAsset(txData.sendingAssetId, payable(txData.sendingChainFallback), txData.amount);

    } else {

      if (txData.expiry >= block.timestamp) {


        require(msg.sender == txData.user || recoverCancelSignature(txData.transactionId, _chainId, address(this), signature) == txData.user, "#C:022");






      }


      routerBalances[txData.router][txData.receivingAssetId] += txData.amount;
    }


    emit TransactionCancelled(txData.user, txData.router, txData.transactionId, txData, msg.sender);


    return txData;
  }












  function _addLiquidityForRouter(
    uint256 amount,
    address assetId,
    address router
  ) internal {

    require(router != address(0), "#AL:001");


    require(amount > 0, "#AL:002");


    require(isRouterOwnershipRenounced() || approvedRouters[router], "#AL:003");


    require(isAssetOwnershipRenounced() || approvedAssets[assetId], "#AL:004");


    amount = transferAssetToContract(assetId, amount);



    routerBalances[router][assetId] += amount;


    emit LiquidityAdded(router, assetId, amount, msg.sender);
  }









  function transferAssetToContract(address assetId, uint256 specifiedAmount) internal returns (uint256) {
    uint256 trueAmount = specifiedAmount;


    if (LibAsset.isNativeAsset(assetId)) {
      require(msg.value == specifiedAmount, "#TA:005");
    } else {
      uint256 starting = LibAsset.getOwnBalance(assetId);
      require(msg.value == 0, "#TA:006");
      LibAsset.transferFromERC20(assetId, msg.sender, address(this), specifiedAmount);

      trueAmount = LibAsset.getOwnBalance(assetId) - starting;
    }

    return trueAmount;
  }




  function recoverCancelSignature(
    bytes32 transactionId,
    uint256 receivingChainId,
    address receivingChainTxManagerAddress,
    bytes calldata signature
  ) internal pure returns (address) {

    SignedCancelData memory payload = SignedCancelData({
      transactionId: transactionId,
      functionIdentifier: "cancel",
      receivingChainId: receivingChainId,
      receivingChainTxManagerAddress: receivingChainTxManagerAddress
    });


    return recoverSignature(abi.encode(payload), signature);
  }








  function recoverFulfillSignature(
    bytes32 transactionId,
    uint256 relayerFee,
    uint256 receivingChainId,
    address receivingChainTxManagerAddress,
    bytes calldata signature
  ) internal pure returns (address) {

    SignedFulfillData memory payload = SignedFulfillData({
      transactionId: transactionId,
      relayerFee: relayerFee,
      functionIdentifier: "fulfill",
      receivingChainId: receivingChainId,
      receivingChainTxManagerAddress: receivingChainTxManagerAddress
    });


    return recoverSignature(abi.encode(payload), signature);
  }







  function recoverSignature(bytes memory encodedPayload, bytes calldata  signature) internal pure returns (address) {

    return ECDSA.recover(
      ECDSA.toEthSignedMessageHash(keccak256(encodedPayload)),
      signature
    );
  }






  function hashInvariantTransactionData(TransactionData calldata txData) internal pure returns (bytes32) {
    InvariantTransactionData memory invariant = InvariantTransactionData({
      receivingChainTxManagerAddress: txData.receivingChainTxManagerAddress,
      user: txData.user,
      router: txData.router,
      sendingAssetId: txData.sendingAssetId,
      receivingAssetId: txData.receivingAssetId,
      sendingChainFallback: txData.sendingChainFallback,
      callTo: txData.callTo,
      receivingAddress: txData.receivingAddress,
      sendingChainId: txData.sendingChainId,
      receivingChainId: txData.receivingChainId,
      callDataHash: txData.callDataHash,
      transactionId: txData.transactionId
    });
    return keccak256(abi.encode(invariant));
  }










  function hashVariantTransactionData(uint256 amount, uint256 expiry, uint256 preparedBlockNumber) internal pure returns (bytes32) {
    VariantTransactionData memory variant = VariantTransactionData({
      amount: amount,
      expiry: expiry,
      preparedBlockNumber: preparedBlockNumber
    });
    return keccak256(abi.encode(variant));
  }














  function _receivingChainFulfill(
    TransactionData calldata txData,
    uint256 relayerFee,
    bytes calldata callData
  ) internal returns (bool, bytes memory) {




    uint256 toSend;
    unchecked {
      toSend = txData.amount - relayerFee;
    }


    if (relayerFee > 0) {
      LibAsset.transferAsset(txData.receivingAssetId, payable(msg.sender), relayerFee);
    }


    if (txData.callTo == address(0)) {

      if (toSend > 0) {
        LibAsset.transferAsset(txData.receivingAssetId, payable(txData.receivingAddress), toSend);
      }
      return (false, new bytes(0));
    } else {




      bool isNativeAsset = LibAsset.isNativeAsset(txData.receivingAssetId);


      if (!isNativeAsset && toSend > 0) {
        LibAsset.transferERC20(txData.receivingAssetId, address(interpreter), toSend);
      }




      return interpreter.execute{ value: isNativeAsset ? toSend : 0}(
        txData.transactionId,
        payable(txData.callTo),
        txData.receivingAssetId,
        payable(txData.receivingAddress),
        toSend,
        callData
      );
    }
  }
}
