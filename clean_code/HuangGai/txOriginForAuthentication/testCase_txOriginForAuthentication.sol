pragma solidity 0.6.2;







contract gray_badTxorigin{
    uint256 public visitTimes;
    address owner;

    constructor() public{
        visitTimes = 0;
        owner = msg.sender;
        address owner1 = msg.sender;
    }

    modifier onlyOwner() {
        require(tx.origin == owner);

        require(tx.origin == owner, "hahaha");

        assert(tx.origin == owner);

        _;
    }



    function visitContract() onlyOwner external{
        require(owner == tx.origin);

        visitTimes += 1;
    }

    function getTimes() view external returns(uint256){
        return visitTimes;
    }
}
