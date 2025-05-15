

pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20Burnable, ERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";



contract Curate is Ownable, ERC20Burnable {
  uint256 public basisPointsRate;
  uint256 public maximumFee;
  address public masterAccount;

  constructor() ERC20("Curate", "XCUR") {
    _mint(0x34ac8D10152c6659b8e8102922EFEdD1e305D10A, 10000000 * (10 ** decimals()));
    setParams(0, 0, msg.sender);
  }






















































