
















    function receiveMevTxFee() external payable;
}











contract LidoMevTxFeeVault {
    address public immutable LIDO;
    address public immutable TREASURY;






    uint256 public totalRewardsReceivedViaTransactions;





    event ERC20Recovered(
        address indexed requestedBy,
        address indexed token,
        uint256 amount
    );





    event ERC721Recovered(
        address indexed requestedBy,
        address indexed token,
        uint256 tokenId
    );







    constructor(address _lido, address _treasury) {
        require(_lido != address(0), "LIDO_ZERO_ADDRESS");

        LIDO = _lido;
        TREASURY = _treasury;
    }






    receive() external payable {
        totalRewardsReceivedViaTransactions = totalRewardsReceivedViaTransactions + msg.value;
    }






    function withdrawRewards() external returns (uint256 amount) {
        require(msg.sender == LIDO, "ONLY_LIDO_CAN_WITHDRAW");

        amount = address(this).balance;
        if (amount > 0) {
            ILido(LIDO).receiveMevTxFee{value: amount}();
        }
        return amount;
    }








    function recoverERC20(address _token, uint256 _amount) external {
        require(_amount > 0, "ZERO_RECOVERY_AMOUNT");

        emit ERC20Recovered(msg.sender, _token, _amount);

        require(IERC20(_token).transfer(TREASURY, _amount));
    }








    function recoverERC721(address _token, uint256 _tokenId) external {
        emit ERC721Recovered(msg.sender, _token, _tokenId);

        IERC721(_token).transferFrom(address(this), TREASURY, _tokenId);
    }
}
