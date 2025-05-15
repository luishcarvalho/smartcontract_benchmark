
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { BlockContext } from "./base/BlockContext.sol";
import { IPriceFeed } from "./interface/IPriceFeed.sol";
import { IStdReference } from "./interface/bandProtocol/IStdReference.sol";

contract BandPriceFeed is IPriceFeed, BlockContext {
    using Address for address;




    struct Observation {
        uint256 price;
        uint256 priceCumulative;
        uint256 timestamp;
    }





    event PriceUpdated(string indexed baseAsset, uint256 price, uint256 timestamp, uint8 indexAt);




    string public constant QUOTE_ASSET = "USD";

    string public baseAsset;


    Observation[256] public observations;

    IStdReference public stdRef;
    uint8 public currentObservationIndex;





    constructor(IStdReference stdRefArg, string memory baseAssetArg) {

        require(address(stdRefArg).isContract(), "BPF_ANC");

        stdRef = stdRefArg;
        baseAsset = baseAssetArg;
    }


    function update() external {
        IStdReference.ReferenceData memory bandData = getReferenceData();


        if (currentObservationIndex == 0 && observations[0].timestamp == 0) {
            observations[0] = Observation({
                price: bandData.rate,
                priceCumulative: 0,
                timestamp: bandData.lastUpdatedBase
            });
            emit PriceUpdated(baseAsset, bandData.rate, bandData.lastUpdatedBase, 0);
            return;
        }


        Observation memory lastObservation = observations[currentObservationIndex];
        require(bandData.lastUpdatedBase > lastObservation.timestamp, "BPF_IT");



        currentObservationIndex++;


        uint256 elapsedTime = bandData.lastUpdatedBase - lastObservation.timestamp;
        observations[currentObservationIndex] = Observation({
            priceCumulative: lastObservation.priceCumulative + (lastObservation.price * elapsedTime),
            timestamp: bandData.lastUpdatedBase,
            price: bandData.rate
        });

        emit PriceUpdated(baseAsset, bandData.rate, bandData.lastUpdatedBase, currentObservationIndex);
    }





    function getPrice(uint256 interval) public view override returns (uint256) {
        Observation memory lastestObservation = observations[currentObservationIndex];
        if (lastestObservation.price == 0) {

            revert("BPF_ND");
        }

        IStdReference.ReferenceData memory latestBandData = getReferenceData();
        if (interval == 0) {
            return latestBandData.rate;
        }

        uint256 currentTimestamp = _blockTimestamp();
        uint256 targetTimestamp = currentTimestamp - interval;
        (Observation memory beforeOrAt, Observation memory atOrAfter) = getSurroundingObservations(targetTimestamp);
        uint256 currentPriceCumulative =
            lastestObservation.priceCumulative +
                (lastestObservation.price * (latestBandData.lastUpdatedBase - lastestObservation.timestamp)) +
                (latestBandData.rate * (currentTimestamp - latestBandData.lastUpdatedBase));









        uint256 targetPriceCumulative;

        if (targetTimestamp <= beforeOrAt.timestamp) {
            targetTimestamp = beforeOrAt.timestamp;
            targetPriceCumulative = beforeOrAt.priceCumulative;
        }

        else if (atOrAfter.timestamp <= targetTimestamp) {
            targetTimestamp = atOrAfter.timestamp;
            targetPriceCumulative = atOrAfter.priceCumulative;
        }

        else {
            uint256 observationTimeDelta = atOrAfter.timestamp - beforeOrAt.timestamp;
            uint256 targetTimeDelta = targetTimestamp - beforeOrAt.timestamp;
            targetPriceCumulative =
                beforeOrAt.priceCumulative +
                ((atOrAfter.priceCumulative - beforeOrAt.priceCumulative) * targetTimeDelta) /
                observationTimeDelta;
        }

        return (currentPriceCumulative - targetPriceCumulative) / (currentTimestamp - targetTimestamp);
    }





    function decimals() external pure override returns (uint8) {


        return 18;
    }





    function getReferenceData() internal view returns (IStdReference.ReferenceData memory) {
        IStdReference.ReferenceData memory bandData = stdRef.getReferenceData(baseAsset, QUOTE_ASSET);

        require(bandData.lastUpdatedQuote > 0, "BPF_TQZ");

        require(bandData.lastUpdatedBase > 0, "BPF_TBZ");

        require(bandData.rate > 0, "BPF_IP");

        return bandData;
    }

    function getSurroundingObservations(uint256 targetTimestamp)
        internal
        view
        returns (Observation memory beforeOrAt, Observation memory atOrAfter)
    {
        uint8 index = currentObservationIndex;
        uint8 beforeOrAtIndex;
        uint8 atOrAfterIndex;



























        uint256 observationLen = observations.length;
        uint256 i;
        for (i = 0; i < observationLen; i++) {
            if (observations[index].timestamp <= targetTimestamp) {


                if (observations[index].timestamp == 0) {
                    atOrAfterIndex = beforeOrAtIndex = index + 1;
                    break;
                }
                beforeOrAtIndex = index;
                atOrAfterIndex = beforeOrAtIndex + 1;
                break;
            }
            index--;
        }


        if (i == observationLen) {

            revert("BPF_NEH");
        }

        beforeOrAt = observations[beforeOrAtIndex];
        atOrAfter = observations[atOrAfterIndex];





        if (atOrAfter.timestamp < beforeOrAt.timestamp) {
            atOrAfter = beforeOrAt;
        }
    }
}
