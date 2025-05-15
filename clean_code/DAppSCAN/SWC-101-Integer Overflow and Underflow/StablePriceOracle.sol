pragma solidity ^0.5.0;

import "./PriceOracle.sol";
import "./SafeMath.sol";
import "./StringUtils.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

interface DSValue {
    function read() external view returns (bytes32);
}


contract StablePriceOracle is Ownable, PriceOracle {
    using SafeMath for *;
    using StringUtils for *;


    DSValue usdOracle;


    uint[] public rentPrices;

    event OracleChanged(address oracle);
    event RentPriceChanged(uint[] prices);

    constructor(DSValue _usdOracle, uint[] memory _rentPrices) public {
        setOracle(_usdOracle);
        setPrices(_rentPrices);
    }





    function setOracle(DSValue _usdOracle) public onlyOwner {
        usdOracle = _usdOracle;
        emit OracleChanged(address(_usdOracle));
    }







    function setPrices(uint[] memory _rentPrices) public onlyOwner {
        rentPrices = _rentPrices;
        emit RentPriceChanged(_rentPrices);
    }
























