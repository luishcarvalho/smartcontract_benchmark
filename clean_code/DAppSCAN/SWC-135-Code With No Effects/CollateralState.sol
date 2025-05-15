pragma solidity ^0.5.16;

pragma experimental ABIEncoderV2;


import "./Owned.sol";
import "./State.sol";
import "./interfaces/ICollateralLoan.sol";


import "./SafeDecimalMath.sol";

contract CollateralState is Owned, State, ICollateralLoan {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    mapping(address => Loan[]) public loans;

    constructor(address _owner, address _associatedContract) public Owned(_owner) State(_associatedContract) {}































