pragma solidity ^0.5.16;

import "./SafeMath.sol";
import "./Ownable.sol";

interface ETHMedianizerInterface {

   function read() external view returns(uint price);
}


contract HoldefiPrices is Ownable {

    using SafeMath for uint256;

    uint constant public priceDecimal = 10**18;

    mapping(address => uint) public assetPrices;

    ETHMedianizerInterface public ethMedianizer;

    event PriceChanged(address asset, uint newPrice);

    constructor(address newOwnerChanger, ETHMedianizerInterface ethMedianizerContract) public Ownable(newOwnerChanger) {
        ethMedianizer = ethMedianizerContract;
    }


    function getPrice(address asset) external view returns(uint price) {
    	if (asset == address(0)){
    		price = uint(ethMedianizer.read());
    	}
        else {
            price = assetPrices[asset];
        }
    }


    function setPrice(address asset, uint newPrice) public onlyOwner {
        require (asset != address(0),'Price of ETH can not be changed');

        assetPrices[asset] = newPrice;
        emit PriceChanged(asset, newPrice);
    }


    function addStableCoin(address asset) public onlyOwner {
        setPrice(asset, priceDecimal);
    }

    function() payable external {
        revert();
    }
}
