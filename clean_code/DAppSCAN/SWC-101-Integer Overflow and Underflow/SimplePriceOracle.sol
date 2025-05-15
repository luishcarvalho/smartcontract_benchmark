pragma solidity ^0.5.0;

import "./PriceOracle.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract SimplePriceOracle is Ownable, PriceOracle {

    uint public rentPrice;

    event RentPriceChanged(uint price);

    constructor(uint _rentPrice) public {
        setPrice(_rentPrice);
    }

    function setPrice(uint _rentPrice) public onlyOwner {
        rentPrice = _rentPrice;
        emit RentPriceChanged(_rentPrice);
    }











