
pragma solidity ^0.8.7;

import "./StakeManager.sol";
import "./UserOperation.sol";
import "./IWallet.sol";
import "./IPaymaster.sol";

interface ICreate2Deployer {
    function deploy(bytes memory _initCode, bytes32 _salt) external returns (address);
}

contract EntryPoint is StakeManager {

    using UserOperationLib for UserOperation;

    enum PaymentMode {
        paymasterStake,
        walletStake
    }

    uint public immutable paymasterStake;
    address public immutable create2factory;

    event UserOperationEvent(bytes32 indexed requestId, address indexed sender, address indexed paymaster, uint nonce, uint actualGasCost, uint actualGasPrice, bool success);
    event UserOperationRevertReason(bytes32 indexed requestId, address indexed sender, uint nonce, bytes revertReason);








    error FailedOp(uint opIndex, address paymaster, string reason);






    constructor(address _create2factory, uint _paymasterStake, uint32 _unstakeDelaySec) StakeManager(_unstakeDelaySec) {
        create2factory = _create2factory;
        paymasterStake = _paymasterStake;
    }






    function handleOp(UserOperation calldata op, address payable beneficiary) public {

        uint preGas = gasleft();

    unchecked {
        bytes32 requestId = getRequestId(op);
        (uint256 prefund, PaymentMode paymentMode, bytes memory context) = _validatePrepayment(0, op, requestId);
        UserOpInfo memory opInfo = UserOpInfo(
            requestId,
            prefund,
            paymentMode,
            0,
            preGas - gasleft() + op.preVerificationGas
        );

        uint actualGasCost;

        try this.internalHandleOp(op, opInfo, context) returns (uint _actualGasCost) {
            actualGasCost = _actualGasCost;
        } catch {
            uint actualGas = preGas - gasleft() + opInfo.preOpGas;
            actualGasCost = handlePostOp(0, IPaymaster.PostOpMode.postOpReverted, op, opInfo, context, actualGas);
        }

        compensate(beneficiary, actualGasCost);
    }
    }

    function compensate(address payable beneficiary, uint amount) internal {
        (bool success,) = beneficiary.call{value : amount}("");
        require(success);
    }






    function handleOps(UserOperation[] calldata ops, address payable beneficiary) public {

        uint opslen = ops.length;
        UserOpInfo[] memory opInfos = new UserOpInfo[](opslen);

    unchecked {
        for (uint i = 0; i < opslen; i++) {
            uint preGas = gasleft();
            UserOperation calldata op = ops[i];

            bytes memory context;
            uint contextOffset;
            bytes32 requestId = getRequestId(op);
            uint prefund;
            PaymentMode paymentMode;
            (prefund, paymentMode, context) = _validatePrepayment(i, op, requestId);
            assembly {contextOffset := context}
            opInfos[i] = UserOpInfo(
                requestId,
                prefund,
                paymentMode,
                contextOffset,
                preGas - gasleft() + op.preVerificationGas
            );
        }

        uint collected = 0;

        for (uint i = 0; i < ops.length; i++) {
            uint preGas = gasleft();
            UserOperation calldata op = ops[i];
            UserOpInfo memory opInfo = opInfos[i];
            uint contextOffset = opInfo._context;
            bytes memory context;
            assembly {context := contextOffset}

            try this.internalHandleOp(op, opInfo, context) returns (uint _actualGasCost) {
                collected += _actualGasCost;
            } catch {
                uint actualGas = preGas - gasleft() + opInfo.preOpGas;
                collected += handlePostOp(i, IPaymaster.PostOpMode.postOpReverted, op, opInfo, context, actualGas);
            }
        }

        compensate(beneficiary, collected);
    }
    }

    struct UserOpInfo {
        bytes32 requestId;
        uint prefund;
        PaymentMode paymentMode;
        uint _context;
        uint preOpGas;
    }

    function internalHandleOp(UserOperation calldata op, UserOpInfo calldata opInfo, bytes calldata context) external returns (uint actualGasCost) {
        uint preGas = gasleft();
        require(msg.sender == address(this));

        IPaymaster.PostOpMode mode = IPaymaster.PostOpMode.opSucceeded;
        if (op.callData.length > 0) {

            (bool success,bytes memory result) = address(op.getSender()).call{gas : op.callGas}(op.callData);
            if (!success) {
                if (result.length > 0) {
                    emit UserOperationRevertReason(opInfo.requestId, op.getSender(), op.nonce, result);
                }
                mode = IPaymaster.PostOpMode.opReverted;
            }
        }

    unchecked {
        uint actualGas = preGas - gasleft() + opInfo.preOpGas;
        return handlePostOp(0, mode, op, opInfo, context, actualGas);
    }
    }





    function getRequestId(UserOperation calldata userOp) public view returns (bytes32) {
        return keccak256(abi.encode(userOp.hash(), address(this), block.chainid));
    }










    function simulateValidation(UserOperation calldata userOp) external returns (uint preOpGas, uint prefund) {
        uint preGas = gasleft();

        bytes32 requestId = getRequestId(userOp);
        (prefund,,) = _validatePrepayment(0, userOp, requestId);
        preOpGas = preGas - gasleft() + userOp.preVerificationGas;

        require(msg.sender == address(0), "must be called off-chain with from=zero-addr");
    }

    function _getPaymentInfo(UserOperation calldata userOp) internal view returns (uint requiredPrefund, PaymentMode paymentMode) {
        requiredPrefund = userOp.requiredPreFund();
        if (userOp.hasPaymaster()) {
            paymentMode = PaymentMode.paymasterStake;
        } else {
            paymentMode = PaymentMode.walletStake;
        }
    }


    function _createSenderIfNeeded(UserOperation calldata op) internal {
        if (op.initCode.length != 0) {




            address sender1 = ICreate2Deployer(create2factory).deploy(op.initCode, bytes32(op.nonce));
            require(sender1 != address(0), "create2 failed");
            require(sender1 == op.getSender(), "sender doesn't match create2 address");
        }
    }



    function getSenderAddress(bytes memory initCode, uint _salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(create2factory),
                _salt,
                keccak256(initCode)
            )
        );


        return address(uint160(uint256(hash)));
    }



    function _validateWalletPrepayment(uint opIndex, UserOperation calldata op, bytes32 requestId, uint requiredPrefund, PaymentMode paymentMode) internal returns (uint gasUsedByValidateUserOp, uint prefund) {
    unchecked {
        uint preGas = gasleft();
        _createSenderIfNeeded(op);
        uint missingWalletFunds = 0;
        address sender = op.getSender();
        if (paymentMode != PaymentMode.paymasterStake) {
            uint bal = balanceOf(sender);
            missingWalletFunds = bal > requiredPrefund ? 0 : requiredPrefund - bal;
        }
        try IWallet(sender).validateUserOp{gas : op.verificationGas}(op, requestId, missingWalletFunds) {
        } catch Error(string memory revertReason) {
            revert FailedOp(opIndex, address(0), revertReason);
        } catch {
            revert FailedOp(opIndex, address(0), "");
        }
        if (paymentMode != PaymentMode.paymasterStake) {
            if (requiredPrefund > balanceOf(sender)) {
                revert FailedOp(opIndex, address(0), "wallet didn't pay prefund");
            }
            internalDecrementDeposit(sender, requiredPrefund);
            prefund = requiredPrefund;
        } else {
            prefund = 0;
        }
        gasUsedByValidateUserOp = preGas - gasleft();
    }
    }


    function _validatePaymasterPrepayment(uint opIndex, UserOperation calldata op, bytes32 requestId, uint requiredPreFund, uint gasUsedByValidateUserOp) internal view returns (bytes memory context) {
    unchecked {



        if (!isPaymasterStaked(op.paymaster, paymasterStake + requiredPreFund)) {
            revert FailedOp(opIndex, op.paymaster, "not enough stake");
        }

        uint gas = op.verificationGas - gasUsedByValidateUserOp;
        try IPaymaster(op.paymaster).validatePaymasterUserOp{gas : gas}(op, requestId, requiredPreFund) returns (bytes memory _context){
            context = _context;
        } catch Error(string memory revertReason) {
            revert FailedOp(opIndex, op.paymaster, revertReason);
        } catch {
            revert FailedOp(opIndex, op.paymaster, "");
        }
    }
    }

    function _validatePrepayment(uint opIndex, UserOperation calldata userOp, bytes32 requestId) private returns (uint prefund, PaymentMode paymentMode, bytes memory context){

        uint preGas = gasleft();
        uint maxGasValues = userOp.preVerificationGas | userOp.verificationGas |
        userOp.callGas | userOp.maxFeePerGas | userOp.maxPriorityFeePerGas;
        require(maxGasValues < type(uint120).max, "gas values overflow");
        uint gasUsedByValidateUserOp;
        uint requiredPreFund;
        (requiredPreFund, paymentMode) = _getPaymentInfo(userOp);

        (gasUsedByValidateUserOp, prefund) = _validateWalletPrepayment(opIndex, userOp, requestId, requiredPreFund, paymentMode);



        uint marker = block.number;
        (marker);

        if (paymentMode == PaymentMode.paymasterStake) {
            (context) = _validatePaymasterPrepayment(opIndex, userOp, requestId, requiredPreFund, gasUsedByValidateUserOp);
        } else {
            context = "";
        }
    unchecked {
        uint gasUsed = preGas - gasleft();

        if (userOp.verificationGas < gasUsed) {
            revert FailedOp(opIndex, userOp.paymaster, "Used more than verificationGas");
        }
    }
    }

    function handlePostOp(uint opIndex, IPaymaster.PostOpMode mode, UserOperation calldata op, UserOpInfo memory opInfo, bytes memory context, uint actualGas) private returns (uint actualGasCost) {
        uint preGas = gasleft();
        uint gasPrice = UserOperationLib.gasPrice(op);
    unchecked {
        actualGasCost = actualGas * gasPrice;
        if (opInfo.paymentMode != PaymentMode.paymasterStake) {
            if (opInfo.prefund < actualGasCost) {
                revert ("wallet prefund below actualGasCost");
            }
            uint refund = opInfo.prefund - actualGasCost;
            internalIncrementDeposit(op.getSender(), refund);
        } else {
            if (context.length > 0) {
                if (mode != IPaymaster.PostOpMode.postOpReverted) {
                    IPaymaster(op.paymaster).postOp{gas : op.verificationGas}(mode, context, actualGasCost);
                } else {
                    try IPaymaster(op.paymaster).postOp{gas : op.verificationGas}(mode, context, actualGasCost) {}
                    catch Error(string memory reason) {
                        revert FailedOp(opIndex, op.paymaster, reason);
                    }
                    catch {
                        revert FailedOp(opIndex, op.paymaster, "postOp revert");
                    }
                }
            }

            actualGas += preGas - gasleft();
            actualGasCost = actualGas * gasPrice;

            internalDecrementDeposit(op.paymaster, actualGasCost);
        }
        bool success = mode == IPaymaster.PostOpMode.opSucceeded;
        emit UserOperationEvent(opInfo.requestId, op.getSender(), op.paymaster, op.nonce, actualGasCost, gasPrice, success);
    }
    }


    function isPaymasterStaked(address paymaster, uint stake) public view returns (bool) {
        return isStaked(paymaster, stake, unstakeDelaySec);
    }
}

