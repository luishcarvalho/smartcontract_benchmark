pragma solidity ^0.4.10;

import "../common/Owned.sol";
import "../common/SafeMath.sol";
import "./IFund.sol";



contract EtherFund is Owned, SafeMath, IFund {

    event EtherWithdrawn(address indexed receiver, address indexed to, uint256 amount);
    event EtherReceived(address indexed sender, uint256 amount);
    event ReceiverChanged(address indexed oldOne, address indexed newOne);
    event ShareChanged(address indexed receiver, uint16 share);































































































    function changeShares(address receiver1, uint16 share1, address receiver2, uint16 share2)
        public
        ownerOnly
    {

        require(share1 + share2 == sharePermille[receiver1] + sharePermille[receiver2]);

        update(receiver1);
        update(receiver2);

        sharePermille[receiver1] = share1;
        sharePermille[receiver2] = share2;

        ShareChanged(receiver1, share1);
        ShareChanged(receiver2, share2);
    }



    function changeShares3(address receiver1, uint16 share1, address receiver2, uint16 share2, address receiver3, uint16 share3)
        public
        ownerOnly
    {

        require(share1 + share2 + share3 == sharePermille[receiver1] + sharePermille[receiver2] + sharePermille[receiver3]);

        update(receiver1);
        update(receiver2);
        update(receiver3);

        sharePermille[receiver1] = share1;
        sharePermille[receiver2] = share2;
        sharePermille[receiver3] = share3;

        ShareChanged(receiver1, share1);
        ShareChanged(receiver2, share2);
        ShareChanged(receiver3, share3);
    }





















