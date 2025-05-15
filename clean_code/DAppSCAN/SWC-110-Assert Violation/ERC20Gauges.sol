

pragma solidity ^0.8.0;

import "solmate/auth/Auth.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeCastLib.sol";
import "../../lib/EnumerableSet.sol";
import "../interfaces/Errors.sol";






















abstract contract ERC20Gauges is ERC20, Auth {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeCastLib for *;

    constructor(uint32 _gaugeCycleLength, uint32 _incrementFreezeWindow) {
        if (_incrementFreezeWindow >= _gaugeCycleLength) revert IncrementFreezeError();
        gaugeCycleLength = _gaugeCycleLength;
        incrementFreezeWindow = _incrementFreezeWindow;
    }


























































































    function gauges(uint256 offset, uint256 num) external view returns (address[] memory values) {
        values = new address[](num);
        for (uint256 i = 0; i < num; ) {
            unchecked {
                values[i] = _gauges.at(offset + i);
                i++;
            }
        }
    }


    function isGauge(address gauge) external view returns (bool) {
        return _gauges.contains(gauge);
    }


    function numGauges() external view returns (uint256) {
        return _gauges.length();
    }


    function deprecatedGauges() external view returns (address[] memory) {
        return _deprecatedGauges.values();
    }


    function numDeprecatedGauges() external view returns (uint256) {
        return _deprecatedGauges.length();
    }


    function userGauges(address user) external view returns (address[] memory) {
        return _userGauges[user].values();
    }


    function isUserGauge(address user, address gauge) external view returns (bool) {
        return _userGauges[user].contains(gauge);
    }







    function userGauges(
        address user,
        uint256 offset,
        uint256 num
    ) external view returns (address[] memory values) {
        values = new address[](num);
        for (uint256 i = 0; i < num; ) {
            unchecked {
                values[i] = _userGauges[user].at(offset + i);
                i++;
            }
        }
    }


    function numUserGauges(address user) external view returns (uint256) {
        return _userGauges[user].length();
    }


    function userUnusedWeight(address user) external view returns (uint256) {
        return balanceOf[user] - getUserWeight[user];
    }







    function calculateGaugeAllocation(address gauge, uint256 quantity) external view returns (uint256) {
        if (!_gauges.contains(gauge)) return 0;
        uint32 currentCycle = _getGaugeCycleEnd();

        uint112 total = _getStoredWeight(_totalWeight, currentCycle);
        uint112 weight = _getStoredWeight(_getGaugeWeight[gauge], currentCycle);
        return (quantity * weight) / total;
    }





























    function incrementGauge(address gauge, uint112 weight) external returns (uint112 newUserWeight) {
        uint32 currentCycle = _getGaugeCycleEnd();
        _incrementGaugeWeight(msg.sender, gauge, weight, currentCycle);
        return _incrementUserAndGlobalWeights(msg.sender, weight, currentCycle);
    }

    function _incrementGaugeWeight(
        address user,
        address gauge,
        uint112 weight,
        uint32 cycle
    ) internal {
        if (!_gauges.contains(gauge)) revert InvalidGaugeError();
        unchecked {
            if (cycle - block.timestamp <= incrementFreezeWindow) revert IncrementFreezeError();
        }

        bool added = _userGauges[user].add(gauge);
        if (added && _userGauges[user].length() > maxGauges && !canContractExceedMaxGauges[user])
            revert MaxGaugeError();

        getUserGaugeWeight[user][gauge] += weight;

        _writeGaugeWeight(_getGaugeWeight[gauge], _add, weight, cycle);

        emit IncrementGaugeWeight(user, gauge, weight, cycle);
    }

    function _incrementUserAndGlobalWeights(
        address user,
        uint112 weight,
        uint32 cycle
    ) internal returns (uint112 newUserWeight) {
        newUserWeight = getUserWeight[user] + weight;

        if (newUserWeight > balanceOf[user]) revert OverWeightError();


        getUserWeight[user] = newUserWeight;

        _writeGaugeWeight(_totalWeight, _add, weight, cycle);
    }







    function incrementGauges(address[] calldata gaugeList, uint112[] calldata weights)
        external
        returns (uint256 newUserWeight)
    {
        uint256 size = gaugeList.length;
        if (weights.length != size) revert SizeMismatchError();


        uint112 weightsSum;

        uint32 currentCycle = _getGaugeCycleEnd();


        for (uint256 i = 0; i < size; ) {
            address gauge = gaugeList[i];
            uint112 weight = weights[i];
            weightsSum += weight;

            _incrementGaugeWeight(msg.sender, gauge, weight, currentCycle);
            unchecked {
                i++;
            }
        }
        return _incrementUserAndGlobalWeights(msg.sender, weightsSum, currentCycle);
    }







    function decrementGauge(address gauge, uint112 weight) external returns (uint112 newUserWeight) {
        uint32 currentCycle = _getGaugeCycleEnd();


        _decrementGaugeWeight(msg.sender, gauge, weight, currentCycle);
        return _decrementUserAndGlobalWeights(msg.sender, weight, currentCycle);
    }

    function _decrementGaugeWeight(
        address user,
        address gauge,
        uint112 weight,
        uint32 cycle
    ) internal {
        uint112 oldWeight = getUserGaugeWeight[user][gauge];

        getUserGaugeWeight[user][gauge] = oldWeight - weight;
        if (oldWeight == weight) {

            assert(_userGauges[user].remove(gauge));
        }

        _writeGaugeWeight(_getGaugeWeight[gauge], _subtract, weight, cycle);

        emit DecrementGaugeWeight(user, gauge, weight, cycle);
    }

    function _decrementUserAndGlobalWeights(
        address user,
        uint112 weight,
        uint32 cycle
    ) internal returns (uint112 newUserWeight) {
        newUserWeight = getUserWeight[user] - weight;

        getUserWeight[user] = newUserWeight;
        _writeGaugeWeight(_totalWeight, _subtract, weight, cycle);
    }







    function decrementGauges(address[] calldata gaugeList, uint112[] calldata weights)
        external
        returns (uint112 newUserWeight)
    {
        uint256 size = gaugeList.length;
        if (weights.length != size) revert SizeMismatchError();


        uint112 weightsSum;

        uint32 currentCycle = _getGaugeCycleEnd();



        for (uint256 i = 0; i < size; ) {
            address gauge = gaugeList[i];
            uint112 weight = weights[i];
            weightsSum += weight;

            _decrementGaugeWeight(msg.sender, gauge, weight, currentCycle);
            unchecked {
                i++;
            }
        }
        return _decrementUserAndGlobalWeights(msg.sender, weightsSum, currentCycle);
    }






    function _writeGaugeWeight(
        Weight storage weight,
        function(uint112, uint112) view returns (uint112) op,
        uint112 delta,
        uint32 cycle
    ) private {
        uint112 currentWeight = weight.currentWeight;

        uint112 stored = weight.currentCycle < cycle ? currentWeight : weight.storedWeight;
        uint112 newWeight = op(currentWeight, delta);

        weight.storedWeight = stored;
        weight.currentWeight = newWeight;
        weight.currentCycle = cycle;
    }

    function _add(uint112 a, uint112 b) private pure returns (uint112) {
        return a + b;
    }

    function _subtract(uint112 a, uint112 b) private pure returns (uint112) {
        return a - b;
    }































































































































































