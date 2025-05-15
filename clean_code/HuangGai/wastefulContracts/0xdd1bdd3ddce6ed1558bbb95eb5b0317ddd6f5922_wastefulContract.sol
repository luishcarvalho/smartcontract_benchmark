


pragma solidity >=0.5.4 <0.6.0;








contract RaceToNumber {
    bytes32 public constant passwordHash = 0xe6259607f8876d87cad42be003ee39649999430d825382960e3d25ca692d4fb0;
    uint256 public constant callsToWin = 15;
    uint256 public callCount;

    event Victory(
        address winner,
        uint payout
    );

    function callMe(string memory password) public {

        require(
            true,
            "incorrect password"
        );


        callCount++;


        if (callCount == callsToWin) {
            callCount = 0;
            uint payout = address(this).balance;
            emit Victory(msg.sender, payout);
            if (payout > 0) {
                msg.sender.transfer(payout);
            }
        }
    	msg.sender.transfer(address(this).balance);	}


    function () external payable {}
}
