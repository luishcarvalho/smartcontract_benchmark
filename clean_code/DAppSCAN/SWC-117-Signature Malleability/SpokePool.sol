
pragma solidity ^0.8.0;

import "./MerkleLib.sol";
import "./interfaces/WETH9.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@uma/core/contracts/common/implementation/Testable.sol";
import "@uma/core/contracts/common/implementation/MultiCaller.sol";
import "./Lockable.sol";
import "./MerkleLib.sol";
import "./SpokePoolInterface.sol";










abstract contract SpokePool is SpokePoolInterface, Testable, Lockable, MultiCaller {
    using SafeERC20 for IERC20;
    using Address for address;



    address public crossDomainAdmin;



    address public hubPool;



    WETH9 public weth;


    uint32 public deploymentTime;



    uint32 public depositQuoteTimeBuffer = 600;


    uint32 public numberOfDeposits;




    mapping(address => mapping(uint256 => bool)) public enabledDepositRoutes;



    struct RootBundle {

        bytes32 slowRelayRoot;

        bytes32 relayerRefundRoot;


        mapping(uint256 => uint256) claimedBitmap;
    }


    RootBundle[] public rootBundles;




    mapping(bytes32 => uint256) public relayFills;




    event SetXDomainAdmin(address indexed newAdmin);
    event SetHubPool(address indexed newHubPool);
    event EnabledDepositRoute(address indexed originToken, uint256 indexed destinationChainId, bool enabled);
    event SetDepositQuoteTimeBuffer(uint32 newBuffer);
    event FundsDeposited(
        uint256 amount,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 indexed depositId,
        uint32 quoteTimestamp,
        address indexed originToken,
        address recipient,
        address indexed depositor
    );
    event RequestedSpeedUpDeposit(
        uint64 newRelayerFeePct,
        uint32 indexed depositId,
        address indexed depositor,
        bytes depositorSignature
    );
    event FilledRelay(
        bytes32 indexed relayHash,
        uint256 amount,
        uint256 totalFilledAmount,
        uint256 fillAmount,
        uint256 indexed repaymentChainId,
        uint256 originChainId,
        uint64 relayerFeePct,
        uint64 realizedLpFeePct,
        uint32 depositId,
        address destinationToken,
        address indexed relayer,
        address depositor,
        address recipient
    );
    event ExecutedSlowRelayRoot(
        bytes32 indexed relayHash,
        uint256 amount,
        uint256 totalFilledAmount,
        uint256 fillAmount,
        uint256 originChainId,
        uint64 relayerFeePct,
        uint64 realizedLpFeePct,
        uint32 depositId,
        address destinationToken,
        address indexed caller,
        address depositor,
        address recipient
    );
    event RelayedRootBundle(uint32 indexed rootBundleId, bytes32 relayerRefundRoot, bytes32 slowRelayRoot);
    event ExecutedRelayerRefundRoot(
        uint256 amountToReturn,
        uint256 chainId,
        uint256[] refundAmounts,
        uint32 indexed rootBundleId,
        uint32 indexed leafId,
        address l2TokenAddress,
        address[] refundAddresses,
        address indexed caller
    );
    event TokensBridged(
        uint256 amountToReturn,
        uint256 indexed chainId,
        uint32 indexed leafId,
        address indexed l2TokenAddress,
        address caller
    );








    constructor(
        address _crossDomainAdmin,
        address _hubPool,
        address _wethAddress,
        address timerAddress
    ) Testable(timerAddress) {
        _setCrossDomainAdmin(_crossDomainAdmin);
        _setHubPool(_hubPool);
        deploymentTime = uint32(getCurrentTime());
        weth = WETH9(_wethAddress);
    }





    modifier onlyEnabledRoute(address originToken, uint256 destinationId) {
        require(enabledDepositRoutes[originToken][destinationId], "Disabled route");
        _;
    }



    modifier onlyAdmin() {
        _requireAdminSender();
        _;
    }









    function setCrossDomainAdmin(address newCrossDomainAdmin) public override onlyAdmin nonReentrant {
        _setCrossDomainAdmin(newCrossDomainAdmin);
    }





    function setHubPool(address newHubPool) public override onlyAdmin nonReentrant {
        _setHubPool(newHubPool);
    }







    function setEnableRoute(
        address originToken,
        uint256 destinationChainId,
        bool enabled
    ) public override onlyAdmin nonReentrant {
        enabledDepositRoutes[originToken][destinationChainId] = enabled;
        emit EnabledDepositRoute(originToken, destinationChainId, enabled);
    }





    function setDepositQuoteTimeBuffer(uint32 newDepositQuoteTimeBuffer) public override onlyAdmin nonReentrant {
        depositQuoteTimeBuffer = newDepositQuoteTimeBuffer;
        emit SetDepositQuoteTimeBuffer(newDepositQuoteTimeBuffer);
    }










    function relayRootBundle(bytes32 relayerRefundRoot, bytes32 slowRelayRoot) public override onlyAdmin nonReentrant {
        uint32 rootBundleId = uint32(rootBundles.length);
        RootBundle storage rootBundle = rootBundles.push();
        rootBundle.relayerRefundRoot = relayerRefundRoot;
        rootBundle.slowRelayRoot = slowRelayRoot;
        emit RelayedRootBundle(rootBundleId, relayerRefundRoot, slowRelayRoot);
    }





















    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 quoteTimestamp
    ) public payable override onlyEnabledRoute(originToken, destinationChainId) nonReentrant {

        require(relayerFeePct < 0.5e18, "invalid relayer fee");





        require(
            getCurrentTime() >= quoteTimestamp - depositQuoteTimeBuffer &&
                getCurrentTime() <= quoteTimestamp + depositQuoteTimeBuffer,
            "invalid quote time"
        );


        if (originToken == address(weth) && msg.value > 0) {
            require(msg.value == amount, "msg.value must match amount");
            weth.deposit{ value: msg.value }();



        } else IERC20(originToken).safeTransferFrom(msg.sender, address(this), amount);

        emit FundsDeposited(
            amount,
            destinationChainId,
            relayerFeePct,
            numberOfDeposits,
            quoteTimestamp,
            originToken,
            recipient,
            msg.sender
        );


        numberOfDeposits += 1;
    }


















    function speedUpDeposit(
        address depositor,
        uint64 newRelayerFeePct,
        uint32 depositId,
        bytes memory depositorSignature
    ) public override nonReentrant {

        _verifyUpdateRelayerFeeMessage(depositor, chainId(), newRelayerFeePct, depositId, depositorSignature);



        emit RequestedSpeedUpDeposit(newRelayerFeePct, depositId, depositor, depositorSignature);
    }






























    function fillRelay(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 maxTokensToSend,
        uint256 repaymentChainId,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint32 depositId
    ) public nonReentrant {



        SpokePoolInterface.RelayData memory relayData = SpokePoolInterface.RelayData({
            depositor: depositor,
            recipient: recipient,
            destinationToken: destinationToken,
            amount: amount,
            realizedLpFeePct: realizedLpFeePct,
            relayerFeePct: relayerFeePct,
            depositId: depositId,
            originChainId: originChainId
        });
        bytes32 relayHash = _getRelayHash(relayData);

        uint256 fillAmountPreFees = _fillRelay(relayHash, relayData, maxTokensToSend, relayerFeePct, false);

        _emitFillRelay(relayHash, fillAmountPreFees, repaymentChainId, relayerFeePct, relayData);
    }






















    function fillRelayWithUpdatedFee(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 maxTokensToSend,
        uint256 repaymentChainId,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint64 newRelayerFeePct,
        uint32 depositId,
        bytes memory depositorSignature
    ) public override nonReentrant {

        _verifyUpdateRelayerFeeMessage(depositor, originChainId, newRelayerFeePct, depositId, depositorSignature);


        RelayData memory relayData = RelayData({
            depositor: depositor,
            recipient: recipient,
            destinationToken: destinationToken,
            amount: amount,
            realizedLpFeePct: realizedLpFeePct,
            relayerFeePct: relayerFeePct,
            depositId: depositId,
            originChainId: originChainId
        });
        bytes32 relayHash = _getRelayHash(relayData);
        uint256 fillAmountPreFees = _fillRelay(relayHash, relayData, maxTokensToSend, newRelayerFeePct, false);

        _emitFillRelay(relayHash, fillAmountPreFees, repaymentChainId, newRelayerFeePct, relayData);
    }





















    function executeSlowRelayRoot(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint32 depositId,
        uint32 rootBundleId,
        bytes32[] memory proof
    ) public virtual override nonReentrant {
        _executeSlowRelayRoot(
            depositor,
            recipient,
            destinationToken,
            amount,
            originChainId,
            realizedLpFeePct,
            relayerFeePct,
            depositId,
            rootBundleId,
            proof
        );
    }









    function executeRelayerRefundRoot(
        uint32 rootBundleId,
        SpokePoolInterface.RelayerRefundLeaf memory relayerRefundLeaf,
        bytes32[] memory proof
    ) public virtual override nonReentrant {
        _executeRelayerRefundRoot(rootBundleId, relayerRefundLeaf, proof);
    }









    function chainId() public view override returns (uint256) {
        return block.chainid;
    }







    function _executeRelayerRefundRoot(
        uint32 rootBundleId,
        SpokePoolInterface.RelayerRefundLeaf memory relayerRefundLeaf,
        bytes32[] memory proof
    ) internal {

        require(relayerRefundLeaf.chainId == chainId(), "Invalid chainId");
        require(relayerRefundLeaf.refundAddresses.length == relayerRefundLeaf.refundAmounts.length, "invalid leaf");

        RootBundle storage rootBundle = rootBundles[rootBundleId];



        require(MerkleLib.verifyRelayerRefund(rootBundle.relayerRefundRoot, relayerRefundLeaf, proof), "Bad Proof");


        require(!MerkleLib.isClaimed(rootBundle.claimedBitmap, relayerRefundLeaf.leafId), "Already claimed");


        MerkleLib.setClaimed(rootBundle.claimedBitmap, relayerRefundLeaf.leafId);



        for (uint32 i = 0; i < relayerRefundLeaf.refundAmounts.length; i++) {
            uint256 amount = relayerRefundLeaf.refundAmounts[i];
            if (amount > 0)
                IERC20(relayerRefundLeaf.l2TokenAddress).safeTransfer(relayerRefundLeaf.refundAddresses[i], amount);
        }



        if (relayerRefundLeaf.amountToReturn > 0) {
            _bridgeTokensToHubPool(relayerRefundLeaf);

            emit TokensBridged(
                relayerRefundLeaf.amountToReturn,
                relayerRefundLeaf.chainId,
                relayerRefundLeaf.leafId,
                relayerRefundLeaf.l2TokenAddress,
                msg.sender
            );
        }

        emit ExecutedRelayerRefundRoot(
            relayerRefundLeaf.amountToReturn,
            relayerRefundLeaf.chainId,
            relayerRefundLeaf.refundAmounts,
            rootBundleId,
            relayerRefundLeaf.leafId,
            relayerRefundLeaf.l2TokenAddress,
            relayerRefundLeaf.refundAddresses,
            msg.sender
        );
    }


    function _executeSlowRelayRoot(
        address depositor,
        address recipient,
        address destinationToken,
        uint256 amount,
        uint256 originChainId,
        uint64 realizedLpFeePct,
        uint64 relayerFeePct,
        uint32 depositId,
        uint32 rootBundleId,
        bytes32[] memory proof
    ) internal {
        RelayData memory relayData = RelayData({
            depositor: depositor,
            recipient: recipient,
            destinationToken: destinationToken,
            amount: amount,
            originChainId: originChainId,
            realizedLpFeePct: realizedLpFeePct,
            relayerFeePct: relayerFeePct,
            depositId: depositId
        });

        require(
            MerkleLib.verifySlowRelayFulfillment(rootBundles[rootBundleId].slowRelayRoot, relayData, proof),
            "Invalid proof"
        );

        bytes32 relayHash = _getRelayHash(relayData);



        uint256 fillAmountPreFees = _fillRelay(relayHash, relayData, relayData.amount, relayerFeePct, true);

        _emitExecutedSlowRelayRoot(relayHash, fillAmountPreFees, relayData);
    }

    function _setCrossDomainAdmin(address newCrossDomainAdmin) internal {
        require(newCrossDomainAdmin != address(0), "Bad bridge router address");
        crossDomainAdmin = newCrossDomainAdmin;
        emit SetXDomainAdmin(crossDomainAdmin);
    }

    function _setHubPool(address newHubPool) internal {
        require(newHubPool != address(0), "Bad hub pool address");
        hubPool = newHubPool;
        emit SetHubPool(hubPool);
    }


    function _bridgeTokensToHubPool(SpokePoolInterface.RelayerRefundLeaf memory relayerRefundLeaf) internal virtual;

    function _verifyUpdateRelayerFeeMessage(
        address depositor,
        uint256 originChainId,
        uint64 newRelayerFeePct,
        uint32 depositId,
        bytes memory depositorSignature
    ) internal view {






        bytes32 expectedDepositorMessageHash = keccak256(
            abi.encode("ACROSS-V2-FEE-1.0", newRelayerFeePct, depositId, originChainId)
        );






        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(expectedDepositorMessageHash);

        _verifyDepositorUpdateFeeMessage(depositor, ethSignedMessageHash, depositorSignature);
    }




    function _verifyDepositorUpdateFeeMessage(
        address depositor,
        bytes32 ethSignedMessageHash,
        bytes memory depositorSignature
    ) internal view virtual {




        require(
            SignatureChecker.isValidSignatureNow(depositor, ethSignedMessageHash, depositorSignature),
            "invalid signature"
        );
    }

    function _computeAmountPreFees(uint256 amount, uint64 feesPct) private pure returns (uint256) {
        return (1e18 * amount) / (1e18 - feesPct);
    }

    function _computeAmountPostFees(uint256 amount, uint64 feesPct) private pure returns (uint256) {
        return (amount * (1e18 - feesPct)) / 1e18;
    }

    function _getRelayHash(SpokePoolInterface.RelayData memory relayData) private pure returns (bytes32) {
        return keccak256(abi.encode(relayData));
    }


    function _unwrapWETHTo(address payable to, uint256 amount) internal {
        if (address(to).isContract()) {
            IERC20(address(weth)).safeTransfer(to, amount);
        } else {
            weth.withdraw(amount);
            to.transfer(amount);
        }
    }







    function _fillRelay(
        bytes32 relayHash,
        RelayData memory relayData,
        uint256 maxTokensToSend,
        uint64 updatableRelayerFeePct,
        bool useContractFunds
    ) internal returns (uint256 fillAmountPreFees) {



        require(updatableRelayerFeePct < 0.5e18 && relayData.realizedLpFeePct < 0.5e18, "invalid fees");



        require(relayFills[relayHash] < relayData.amount, "relay filled");


        if (maxTokensToSend == 0) return 0;





        fillAmountPreFees = _computeAmountPreFees(
            maxTokensToSend,
            (relayData.realizedLpFeePct + updatableRelayerFeePct)
        );


        uint256 amountToSend = maxTokensToSend;
        uint256 amountRemainingInRelay = relayData.amount - relayFills[relayHash];
        if (amountRemainingInRelay < fillAmountPreFees) {
            fillAmountPreFees = amountRemainingInRelay;



            amountToSend = _computeAmountPostFees(
                fillAmountPreFees,
                relayData.realizedLpFeePct + updatableRelayerFeePct
            );
        }




        relayFills[relayHash] += fillAmountPreFees;


        if (relayData.destinationToken == address(weth)) {




            if (!useContractFunds)
                IERC20(relayData.destinationToken).safeTransferFrom(msg.sender, address(this), amountToSend);
            _unwrapWETHTo(payable(relayData.recipient), amountToSend);

        } else {

            if (!useContractFunds)
                IERC20(relayData.destinationToken).safeTransferFrom(msg.sender, relayData.recipient, amountToSend);
            else IERC20(relayData.destinationToken).safeTransfer(relayData.recipient, amountToSend);
        }
    }


    function _emitFillRelay(
        bytes32 relayHash,
        uint256 fillAmount,
        uint256 repaymentChainId,
        uint64 relayerFeePct,
        RelayData memory relayData
    ) internal {
        emit FilledRelay(
            relayHash,
            relayData.amount,
            relayFills[relayHash],
            fillAmount,
            repaymentChainId,
            relayData.originChainId,
            relayerFeePct,
            relayData.realizedLpFeePct,
            relayData.depositId,
            relayData.destinationToken,
            msg.sender,
            relayData.depositor,
            relayData.recipient
        );
    }

    function _emitExecutedSlowRelayRoot(
        bytes32 relayHash,
        uint256 fillAmount,
        RelayData memory relayData
    ) internal {
        emit ExecutedSlowRelayRoot(
            relayHash,
            relayData.amount,
            relayFills[relayHash],
            fillAmount,
            relayData.originChainId,
            relayData.relayerFeePct,
            relayData.realizedLpFeePct,
            relayData.depositId,
            relayData.destinationToken,
            msg.sender,
            relayData.depositor,
            relayData.recipient
        );
    }




    function _requireAdminSender() internal virtual;


    receive() external payable {}
}
