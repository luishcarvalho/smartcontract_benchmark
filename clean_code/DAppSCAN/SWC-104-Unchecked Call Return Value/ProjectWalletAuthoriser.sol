pragma solidity ^0.4.24;

import "../utils/Ownable.sol";
import "./ProjectWallet.sol";

contract ProjectWalletAuthoriser is Ownable {

    address private authoriser;




    modifier onlyAuthoriser() {
        require(msg.sender == authoriser, "Permission denied");
        _;
    }

    function setAuthoriser(address _authoriser) public onlyOwner returns (bool)
    {
        authoriser = _authoriser;
    }







    function transfer(
        address _sender,
        address _receiver,
        uint256 _amt
    )
    public onlyAuthoriser
    returns (bool)
    {

        ProjectWallet(_sender).transfer(_receiver, _amt);
    }

}


