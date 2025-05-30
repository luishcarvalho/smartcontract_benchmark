










pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../contracts/interfaces/IDepositContract.sol";

contract AbyssEth2Depositor is Pausable, Ownable {
    using SafeMath for uint256;




    IDepositContract public depositContract;




    uint256 public constant nodesMinAmount = 1;
    uint256 public constant nodesMaxAmount = 100;




    uint256 public constant collateral = 32 ether;




    constructor(address depositContractAddress) public {
        depositContract = IDepositContract(address(depositContractAddress));
    }




    receive() external payable {
        revert("AbyssEth2Depositor: do not send ETH directly here");
    }











    function deposit(
        bytes[] calldata pubkeys,
        bytes[] calldata withdrawal_credentials,
        bytes[] calldata signatures,
        bytes32[] calldata deposit_data_roots
    ) external payable whenNotPaused {

        uint256 nodesAmount = pubkeys.length;

        require(nodesAmount > 0 && nodesAmount <= 100, "AbyssEth2Depositor: you can deposit only 1 to 100 nodes per transaction");
        require(msg.value == SafeMath.mul(collateral, nodesAmount), "AbyssEth2Depositor: the amount of ETH does not match the amount of nodes");
        require(
            withdrawal_credentials.length == nodesAmount &&
            signatures.length == nodesAmount &&
            deposit_data_roots.length == nodesAmount,
            "AbyssEth2Depositor: amount of parameters do no match");

        for (uint256 i = 0; i < nodesAmount; ++i) {

            IDepositContract(address(depositContract)).deposit{value: collateral}(
                pubkeys[i],
                withdrawal_credentials[i],
                signatures[i],
                deposit_data_roots[i]
            );

        }

        emit DepositEvent(msg.sender, nodesAmount);
    }








    function pause() public onlyOwner {
      _pause();
    }








    function unpause() public onlyOwner {
      _unpause();
    }

    event DepositEvent(address from, uint256 nodesAmount);
}
