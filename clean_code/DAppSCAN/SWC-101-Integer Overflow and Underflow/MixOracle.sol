pragma solidity 0.5.11;







import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { IEthUsdOracle } from "../interfaces/IEthUsdOracle.sol";
import { IMinMaxOracle } from "../interfaces/IMinMaxOracle.sol";
import {
    InitializableGovernable
} from "../governance/InitializableGovernable.sol";

contract MixOracle is IMinMaxOracle, InitializableGovernable {
    address[] public ethUsdOracles;

    struct MixConfig {
        address[] usdOracles;
        address[] ethOracles;
    }

    mapping(bytes32 => MixConfig) configs;

    uint256 constant MAX_INT = 2**256 - 1;
    uint256 public maxDrift;
    uint256 public minDrift;

    constructor(uint256 _maxDrift, uint256 _minDrift) public {
        maxDrift = _maxDrift;
        minDrift = _minDrift;
    }

    function setMinMaxDrift(uint256 _maxDrift, uint256 _minDrift)
        public
        onlyGovernor
    {
        maxDrift = _maxDrift;
        minDrift = _minDrift;
    }





    function registerEthUsdOracle(address oracle) public onlyGovernor {
        for (uint256 i = 0; i < ethUsdOracles.length; i++) {
            require(ethUsdOracles[i] != oracle, "Oracle already registered.");
        }
        ethUsdOracles.push(oracle);
    }





    function unregisterEthUsdOracle(address oracle) public onlyGovernor {
        for (uint256 i = 0; i < ethUsdOracles.length; i++) {
            if (ethUsdOracles[i] == oracle) {


                ethUsdOracles[i] = ethUsdOracles[ethUsdOracles.length - 1];
                delete ethUsdOracles[ethUsdOracles.length - 1];
                ethUsdOracles.length--;
                return;
            }
        }
        revert("Oracle not found");
    }






    function registerTokenOracles(
        string calldata symbol,
        address[] calldata ethOracles,
        address[] calldata usdOracles
    ) external onlyGovernor {
        MixConfig storage config = configs[keccak256(abi.encodePacked(symbol))];
        config.ethOracles = ethOracles;
        config.usdOracles = usdOracles;
    }






    function priceMin(string calldata symbol) external returns (uint256 price) {
        MixConfig storage config = configs[keccak256(abi.encodePacked(symbol))];
        uint256 ep;
        uint256 p;
        price = MAX_INT;
        if (config.ethOracles.length > 0) {
            ep = MAX_INT;
            for (uint256 i = 0; i < config.ethOracles.length; i++) {
                p = IEthUsdOracle(config.ethOracles[i]).tokEthPrice(symbol);
                if (ep > p) {
                    ep = p;
                }
            }
            price = ep;
            ep = MAX_INT;
            for (uint256 i = 0; i < ethUsdOracles.length; i++) {
                p = IEthUsdOracle(ethUsdOracles[i]).ethUsdPrice();
                if (ep > p) {
                    ep = p;
                }
            }
            if (price != MAX_INT && ep != MAX_INT) {


                price = (price * ep) / 1e6;
            }
        }

        if (config.usdOracles.length > 0) {
            for (uint256 i = 0; i < config.usdOracles.length; i++) {

                p = IPriceOracle(config.usdOracles[i]).price(symbol) * 1e2;
                if (price > p) {
                    price = p;
                }
            }
        }
        require(price < maxDrift, "Price exceeds max value.");
        require(price > minDrift, "Price lower than min value.");
        require(
            price != MAX_INT,
            "None of our oracles returned a valid min price!"
        );
    }






    function priceMax(string calldata symbol) external returns (uint256 price) {
        MixConfig storage config = configs[keccak256(abi.encodePacked(symbol))];
        uint256 ep;
        uint256 p;
        price = 0;
        if (config.ethOracles.length > 0) {
            ep = 0;
            for (uint256 i = 0; i < config.ethOracles.length; i++) {
                p = IEthUsdOracle(config.ethOracles[i]).tokEthPrice(symbol);
                if (ep < p) {
                    ep = p;
                }
            }
            price = ep;
            ep = 0;
            for (uint256 i = 0; i < ethUsdOracles.length; i++) {
                p = IEthUsdOracle(ethUsdOracles[i]).ethUsdPrice();
                if (ep < p) {
                    ep = p;
                }
            }
            if (price != 0 && ep != 0) {


                price = (price * ep) / 1e6;
            }
        }

        if (config.usdOracles.length > 0) {
            for (uint256 i = 0; i < config.usdOracles.length; i++) {

                p = IPriceOracle(config.usdOracles[i]).price(symbol) * 1e2;
                if (price < p) {
                    price = p;
                }
            }
        }

        require(price < maxDrift, "Price above max value.");
        require(price > minDrift, "Price below min value.");
        require(price != 0, "None of our oracles returned a valid max price!");
    }
}
