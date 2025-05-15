
pragma solidity 0.8.5;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BLSToken is ERC20 {

    uint maxSupply = 42000000 ether;

    constructor() ERC20("BlocksSpace Token", "BLS") {
        _mint(_msgSender(), maxSupply);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

}
