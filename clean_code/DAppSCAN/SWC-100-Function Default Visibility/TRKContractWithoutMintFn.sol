

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TRKTestToken is ERC20, Ownable, Pausable  {
    bool private _disableTransferOwner;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _disableTransferOwner = true;
        uint256 _decimals = 18;
        uint256 _totalSupply = 100_000_000 * 10**_decimals;
        _mint(msg.sender, _totalSupply);
    }





    function pause() public onlyOwner whenNotPaused {
       _pause();
    }





    function unpause() public onlyOwner whenPaused {
       _unpause();
    }















    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }




    function transferOwnership(address newOwner) public override onlyOwner {
        if (_disableTransferOwner) {
            revert("Not allow transferring ownership");
        } else {
            super.transferOwnership(newOwner);
        }
    }




    function renounceOwnership() public override onlyOwner {
        if (paused()) {
            _unpause();
        }

        super.renounceOwnership();
    }
}
