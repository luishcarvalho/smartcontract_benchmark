

pragma solidity ^0.8.0;

import "./erc20/ERC20.sol";

contract CheckDot is ERC20 {

    uint8 public constant _decimals = 18;

    uint256 private _totalSupply = 10000000 * (10 ** uint256(_decimals));

    address private _checkDotDeployer;

    constructor(address _deployer) ERC20("CheckDot", "CDT") {
        _checkDotDeployer = _deployer;
        _mint(_checkDotDeployer, _totalSupply);
    }

    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
}
