

pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;




















contract OVM_L1ERC20Gateway is Abs_L1TokenGateway {





    iOVM_ERC20 public l1ERC20;









    constructor(
        iOVM_ERC20 _l1ERC20,
        address _l2DepositedERC20,
        address _l1messenger
    )
        Abs_L1TokenGateway(
            _l2DepositedERC20,
            _l1messenger
        )
    {
        l1ERC20 = _l1ERC20;
    }














    function _handleInitiateDeposit(
        address _from,
        address,
        uint256 _amount
    )
        internal
        override
    {


        l1ERC20.transferFrom(
            _from,
            address(this),
            _amount
        );
    }








    function _handleFinalizeWithdrawal(
        address _to,
        uint _amount
    )
        internal
        override
    {


        l1ERC20.transfer(_to, _amount);
    }
}
