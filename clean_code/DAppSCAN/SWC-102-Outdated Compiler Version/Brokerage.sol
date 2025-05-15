
pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import {LibMathUnsigned} from "../lib/LibMath.sol";
import "../lib/LibTypes.sol";

contract Brokerage {
    using LibMathUnsigned for uint256;

    event BrokerUpdate(address indexed account, address indexed guy, uint256 appliedHeight);

    mapping(address => LibTypes.Broker) public brokers;










    function setBroker(address trader, address newBroker, uint256 delay) internal {
        require(trader != address(0), "invalid trader");
        require(newBroker != address(0), "invalid guy");
        LibTypes.Broker memory broker = brokers[trader];
        if (broker.current.appliedHeight == 0) {

            broker.current.broker = newBroker;
            broker.current.appliedHeight = block.number;
        } else {
            bool isPreviousChangeApplied = block.number >= broker.current.appliedHeight;
            if (isPreviousChangeApplied) {
                if (broker.current.broker == newBroker) {

                    return;
                } else {

                    broker.previous.broker = broker.current.broker;
                    broker.previous.appliedHeight = broker.current.appliedHeight;
                }
            }

            broker.current.broker = newBroker;
            broker.current.appliedHeight = block.number.add(delay);
        }

        brokers[trader] = broker;
        emit BrokerUpdate(trader, newBroker, broker.current.appliedHeight);
    }



    function currentBroker(address trader) public view returns (address) {
        LibTypes.Broker storage broker = brokers[trader];
        return block.number >= broker.current.appliedHeight ? broker.current.broker : broker.previous.broker;
    }

    function getBroker(address trader) public view returns (LibTypes.Broker memory) {
        return brokers[trader];
    }
}
