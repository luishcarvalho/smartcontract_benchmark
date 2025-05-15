
pragma solidity >0.5.0 <0.8.0;
















contract OVM_SequencerEntrypoint {
    using Lib_EIP155Tx for Lib_EIP155Tx.EIP155Tx;











    fallback()
        external
    {
        Lib_EIP155Tx.EIP155Tx memory transaction = Lib_EIP155Tx.decode(
            msg.data,
            Lib_SafeExecutionManagerWrapper.safeCHAINID()
        );



        Lib_SafeExecutionManagerWrapper.safeREQUIRE(
            transaction.recoveryParam < 2,
            "OVM_SequencerEntrypoint: Transaction was signed with the wrong chain ID."
        );



        address sender = transaction.sender();


        if (Lib_SafeExecutionManagerWrapper.safeEXTCODESIZE(sender) == 0) {
            Lib_SafeExecutionManagerWrapper.safeCREATEEOA(
                transaction.hash(),
                transaction.recoveryParam,
                transaction.r,
                transaction.s
            );
        }



        Lib_SafeExecutionManagerWrapper.safeCALL(
            gasleft(),
            sender,
            abi.encodeWithSignature(
                "execute(bytes)",
                msg.data
            )
        );
    }
}
