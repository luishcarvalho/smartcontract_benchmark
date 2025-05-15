pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "./MarketSource.sol";










contract MarketOracle is Ownable {
    using SafeMath for uint256;


    MarketSource[] public _whitelist;

    event LogSourceAdded(MarketSource source);
    event LogSourceRemoved(MarketSource source);
    event LogSourceExpired(MarketSource source);








    function getPriceAnd24HourVolume()
        external
        returns (uint256, uint256)
    {
        uint256 volumeWeightedSum = 0;
        uint256 volumeSum = 0;
        uint256 partialRate = 0;
        uint256 partialVolume = 0;
        bool isSourceFresh = false;

        for (uint256 i = 0; i < _whitelist.length; i++) {
            (isSourceFresh, partialRate, partialVolume) = _whitelist[i].getReport();

            if (!isSourceFresh) {
                emit LogSourceExpired(_whitelist[i]);
                continue;
            }

            volumeWeightedSum = volumeWeightedSum.add(partialRate.mul(partialVolume));
            volumeSum = volumeSum.add(partialVolume);
        }



        uint256 exchangeRate = volumeWeightedSum.div(volumeSum);
        return (exchangeRate, volumeSum);
    }





    function addSource(MarketSource source)
        external
        onlyOwner
    {
        _whitelist.push(source);
        emit LogSourceAdded(source);
    }





    function removeSource(MarketSource source)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            if (_whitelist[i] == source) {
                removeSourceAtIndex(i);
                break;
            }
        }
    }





    function removeDestructedSources()
        external
    {
        uint256 i = 0;
        while (i < _whitelist.length) {
            if (isContractDestructed(_whitelist[i])) {
                removeSourceAtIndex(i);
            } else {
                i++;
            }
        }
    }




    function whitelistSize()
        public
        view
        returns (uint256)
    {
        return _whitelist.length;
    }





    function isContractDestructed(address contractAddress)
        private
        view
        returns (bool)
    {
        uint256 size;
        assembly { size := extcodesize(contractAddress) }
        return size == 0;
    }




    function removeSourceAtIndex(uint256 index)
        private
    {
        emit LogSourceRemoved(_whitelist[index]);
        if (index != _whitelist.length-1) {
            _whitelist[index] = _whitelist[_whitelist.length-1];
        }

        _whitelist.length--;
    }
}
