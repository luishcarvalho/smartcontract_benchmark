
pragma solidity 0.6.12;
import "../../../converter/types/liquid-token/LiquidTokenConverter.sol";












contract DynamicLiquidTokenConverter is LiquidTokenConverter {
    uint32 public minimumWeight = 30000;
    uint32 public stepWeight = 10000;
    uint256 public marketCapThreshold = 10000 ether;
    uint256 public lastWeightAdjustmentMarketCap = 0;

    event ReserveTokenWeightUpdate(uint32 _prevWeight, uint32 _newWeight, uint256 _percentage, uint256 _balance);
    event StepWeightUpdated(uint32 stepWeight);
    event MinimumWeightUpdated(uint32 minumumWeight);
    event MarketCapThresholdUpdated(uint256 marketCapThreshold);
    event LastWeightAdjustmentMarketCapUpdated(uint256 lastWeightAdjustmentMarketCap);








    constructor(
        IDSToken _token,
        IContractRegistry _registry,
        uint32 _maxConversionFee
    )
        LiquidTokenConverter(_token, _registry, _maxConversionFee)
        public
    {
    }






    function converterType() public pure override returns (uint16) {
        return 3;
    }







    function setMarketCapThreshold(uint256 _marketCapThreshold)
        public
        ownerOnly
        inactive
    {
        marketCapThreshold = _marketCapThreshold;
        emit MarketCapThresholdUpdated(_marketCapThreshold);
    }







    function setMinimumWeight(uint32 _minimumWeight)
        public
        ownerOnly
        inactive
    {


        minimumWeight = _minimumWeight;
        emit MinimumWeightUpdated(_minimumWeight);
    }







    function setStepWeight(uint32 _stepWeight)
        public
        ownerOnly
        inactive
    {


        stepWeight = _stepWeight;
        emit StepWeightUpdated(_stepWeight);
    }






    function setLastWeightAdjustmentMarketCap(uint256 _lastWeightAdjustmentMarketCap)
        public
        ownerOnly
        inactive
    {
        lastWeightAdjustmentMarketCap = _lastWeightAdjustmentMarketCap;
        emit LastWeightAdjustmentMarketCapUpdated(_lastWeightAdjustmentMarketCap);
    }









    function reduceWeight(IERC20Token _reserveToken)
        public
        validReserve(_reserveToken)
        ownerOnly
    {
        _protected();
        uint256 currentMarketCap = getMarketCap(_reserveToken);
        require(currentMarketCap > (lastWeightAdjustmentMarketCap.add(marketCapThreshold)), "ERR_MARKET_CAP_BELOW_THRESHOLD");

        Reserve storage reserve = reserves[_reserveToken];
        uint256 newWeight = uint256(reserve.weight).sub(stepWeight);
        uint32 oldWeight = reserve.weight;
        require(newWeight >= minimumWeight, "ERR_INVALID_RESERVE_WEIGHT");

        uint256 percentage = uint256(PPM_RESOLUTION).sub(newWeight.mul(PPM_RESOLUTION).div(reserve.weight));

        uint32 weight = uint32(newWeight);
        reserve.weight = weight;
        reserveRatio = weight;

        uint256 balance = reserveBalance(_reserveToken).mul(percentage).div(PPM_RESOLUTION);

        lastWeightAdjustmentMarketCap = currentMarketCap;

        if (_reserveToken == ETH_RESERVE_ADDRESS)
          msg.sender.transfer(balance);
        else
          safeTransfer(_reserveToken, msg.sender, balance);

        syncReserveBalance(_reserveToken);

        emit ReserveTokenWeightUpdate(oldWeight, weight, percentage, reserve.balance);
    }

    function getMarketCap(IERC20Token _reserveToken)
        public
        view
        returns(uint256)
    {
        Reserve storage reserve = reserves[_reserveToken];
        return reserveBalance(_reserveToken).mul(1e6).div(reserve.weight);
    }
}
