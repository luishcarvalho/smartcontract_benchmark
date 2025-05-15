pragma solidity ^0.5.16;


import "./Owned.sol";
import "./Proxyable.sol";
import "./MixinFuturesMarketSettings.sol";
import "./interfaces/IFuturesMarket.sol";


import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "./SignedSafeMath.sol";
import "./SignedSafeDecimalMath.sol";
import "./SafeDecimalMath.sol";


import "./interfaces/IExchangeRatesCircuitBreaker.sol";
import "./interfaces/ISystemStatus.sol";
import "./interfaces/IERC20.sol";






















































interface IFuturesMarketManagerInternal {
    function issueSUSD(address account, uint amount) external;

    function burnSUSD(address account, uint amount) external returns (uint postReclamationAmount);

    function payFee(uint amount) external;
}


contract FuturesMarket is Owned, Proxyable, MixinFuturesMarketSettings, IFuturesMarket {
























    int public marketSkew;










    uint public fundingLastRecomputed;
    int[] public fundingSequence;





    mapping(address => Position) public positions;






    int internal _entryDebtCorrection;


    uint internal _nextPositionId = 1;


    mapping(uint8 => string) internal _errorMessages;
















































































    function assetPrice() external view returns (uint price, bool invalid) {
        return _assetPrice();
    }

    function _marketSizes() internal view returns (uint long, uint short) {
        int size = int(marketSize);
        int skew = marketSkew;
        return (_abs(size.add(skew).div(2)), _abs(size.sub(skew).div(2)));
    }




    function marketSizes() external view returns (uint long, uint short) {
        return _marketSizes();
    }




    function _maxOrderSizes(uint price) internal view returns (uint, uint) {
        (uint long, uint short) = _marketSizes();
        int sizeLimit = int(_maxMarketValueUSD(baseAsset)).divideDecimalRound(int(price));
        return (uint(sizeLimit.sub(_min(int(long), sizeLimit))), uint(sizeLimit.sub(_min(int(short), sizeLimit))));
    }




    function maxOrderSizes()
        external
        view
        returns (
            uint long,
            uint short,
            bool invalid
        )
    {
        (uint price, bool isInvalid) = _assetPrice();
        (uint longSize, uint shortSize) = _maxOrderSizes(price);
        return (longSize, shortSize, isInvalid);
    }

    function _marketDebt(uint price) internal view returns (uint) {

        int totalDebt =
            marketSkew.multiplyDecimalRound(int(price).add(_nextFundingEntry(fundingSequence.length, price))).add(
                _entryDebtCorrection
            );

        return uint(_max(totalDebt, 0));
    }





    function marketDebt() external view returns (uint debt, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_marketDebt(price), isInvalid);
    }






    function _proportionalSkew(uint price) internal view returns (int) {

        require(price > 0, "price can't be zero");
        uint skewScaleBaseAsset = _skewScaleUSD(baseAsset).divideDecimalRound(price);


        if (skewScaleBaseAsset == 0) {
            return 0;
        }

        return marketSkew.divideDecimalRound(int(skewScaleBaseAsset));
    }




    function parameters()
        external
        view
        returns (
            uint takerFee,
            uint makerFee,
            uint closureFee,
            uint maxLeverage,
            uint maxMarketValueUSD,
            uint maxFundingRate,
            uint skewScaleUSD,
            uint maxFundingRateDelta
        )
    {
        return _parameters(baseAsset);
    }

    function _currentFundingRate(uint price) internal view returns (int) {
        int maxFundingRate = int(_maxFundingRate(baseAsset));

        return _min(_max(-_UNIT, -_proportionalSkew(price)), _UNIT).multiplyDecimalRound(maxFundingRate);
    }





    function currentFundingRate() external view returns (int) {
        (uint price, ) = _assetPrice();
        return _currentFundingRate(price);
    }




    function _currentFundingRatePerSecond(uint price) internal view returns (int) {
        return _currentFundingRate(price) / 1 days;
    }

    function _unrecordedFunding(uint price) internal view returns (int funding) {
        int elapsed = int(block.timestamp.sub(fundingLastRecomputed));
        return _currentFundingRatePerSecond(price).multiplyDecimalRound(int(price)).mul(elapsed);
    }





    function unrecordedFunding() external view returns (int funding, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_unrecordedFunding(price), isInvalid);
    }





    function _nextFundingEntry(uint sequenceLength, uint price) internal view returns (int funding) {
        return fundingSequence[sequenceLength.sub(1)].add(_unrecordedFunding(price));
    }

    function _netFundingPerUnit(
        uint startIndex,
        uint endIndex,
        uint sequenceLength,
        uint price
    ) internal view returns (int) {
        int result;


        if (endIndex <= startIndex) {
            return 0;
        }


        if (endIndex == sequenceLength) {
            result = _nextFundingEntry(sequenceLength, price);
        } else {
            result = fundingSequence[endIndex];
        }


        return result.sub(fundingSequence[startIndex]);
    }





    function netFundingPerUnit(uint startIndex, uint endIndex) external view returns (int funding, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_netFundingPerUnit(startIndex, endIndex, fundingSequence.length, price), isInvalid);
    }




    function fundingSequenceLength() external view returns (uint) {
        return fundingSequence.length;
    }






    function _orderSizeTooLarge(
        uint maxSize,
        int oldSize,
        int newSize
    ) internal view returns (bool) {

        if (_sameSide(oldSize, newSize) && _abs(newSize) <= _abs(oldSize)) {
            return false;
        }



        int newSkew = marketSkew.sub(oldSize).add(newSize);
        int newMarketSize = int(marketSize).sub(_signedAbs(oldSize)).add(_signedAbs(newSize));

        int newSideSize;
        if (0 < newSize) {



            newSideSize = newMarketSize.add(newSkew);
        } else {



            newSideSize = newMarketSize.sub(newSkew);
        }


        if (maxSize < _abs(newSideSize.div(2))) {
            return true;
        }

        return false;
    }

    function _notionalValue(Position memory position, uint price) internal pure returns (int value) {
        return position.size.multiplyDecimalRound(int(price));
    }




    function notionalValue(address account) external view returns (int value, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_notionalValue(positions[account], price), isInvalid);
    }

    function _profitLoss(Position memory position, uint price) internal pure returns (int pnl) {
        int priceShift = int(price).sub(int(position.lastPrice));
        return position.size.multiplyDecimalRound(priceShift);
    }




    function profitLoss(address account) external view returns (int pnl, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_profitLoss(positions[account], price), isInvalid);
    }

    function _accruedFunding(
        Position memory position,
        uint endFundingIndex,
        uint price
    ) internal view returns (int funding) {
        uint lastModifiedIndex = position.fundingIndex;
        if (lastModifiedIndex == 0) {
            return 0;
        }
        int net = _netFundingPerUnit(lastModifiedIndex, endFundingIndex, fundingSequence.length, price);
        return position.size.multiplyDecimalRound(net);
    }




    function accruedFunding(address account) external view returns (int funding, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_accruedFunding(positions[account], fundingSequence.length, price), isInvalid);
    }




    function _marginPlusProfitFunding(
        Position memory position,
        uint endFundingIndex,
        uint price
    ) internal view returns (int) {
        return int(position.margin).add(_profitLoss(position, price)).add(_accruedFunding(position, endFundingIndex, price));
    }







    function _realisedMargin(
        Position memory position,
        uint currentFundingIndex,
        uint price,
        int marginDelta
    ) internal view returns (uint margin, Status statusCode) {
        int newMargin = _marginPlusProfitFunding(position, currentFundingIndex, price).add(marginDelta);
        if (newMargin < 0) {
            return (0, Status.InsufficientMargin);
        }

        uint uMargin = uint(newMargin);
        int positionSize = position.size;

        uint lMargin = _liquidationMargin(positionSize, price);
        if (positionSize != 0 && uMargin <= lMargin) {
            return (uMargin, Status.CanLiquidate);
        }

        return (uMargin, Status.Ok);
    }

    function _remainingMargin(
        Position memory position,
        uint endFundingIndex,
        uint price
    ) internal view returns (uint) {
        int remaining = _marginPlusProfitFunding(position, endFundingIndex, price);


        return uint(_max(0, remaining));
    }




    function remainingMargin(address account) external view returns (uint marginRemaining, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_remainingMargin(positions[account], fundingSequence.length, price), isInvalid);
    }

    function _accessibleMargin(
        Position storage position,
        uint fundingIndex,
        uint price
    ) internal view returns (uint) {



        uint milli = uint(_UNIT / 1000);
        int maxLeverage = int(_maxLeverage(baseAsset).sub(milli));
        uint inaccessible = _abs(_notionalValue(position, price).divideDecimalRound(maxLeverage));


        if (0 < inaccessible) {
            uint minInitialMargin = _minInitialMargin();
            if (inaccessible < minInitialMargin) {
                inaccessible = minInitialMargin;
            }
            inaccessible = inaccessible.add(milli);
        }

        uint remaining = _remainingMargin(position, fundingIndex, price);
        if (remaining <= inaccessible) {
            return 0;
        }

        return remaining.sub(inaccessible);
    }





    function accessibleMargin(address account) external view returns (uint marginAccessible, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        return (_accessibleMargin(positions[account], fundingSequence.length, price), isInvalid);
    }

    function _liquidationPrice(
        Position memory position,
        bool includeFunding,
        uint currentPrice
    ) internal view returns (uint) {
        int positionSize = position.size;


        if (positionSize == 0) {
            return 0;
        }


        int fundingPerUnit = 0;
        if (includeFunding) {

            fundingPerUnit = _netFundingPerUnit(
                position.fundingIndex,
                fundingSequence.length,
                fundingSequence.length,
                currentPrice
            );
        }


        uint liqMargin = _liquidationMargin(position.size, currentPrice);








        int result =
            int(position.lastPrice).add(int(liqMargin).sub(int(position.margin)).divideDecimalRound(positionSize)).sub(
                fundingPerUnit
            );


        return uint(_max(0, result));
    }









    function _liquidationFee(int positionSize, uint price) internal view returns (uint lFee) {

        uint proportionalFee = _abs(positionSize).multiplyDecimalRound(price).multiplyDecimalRound(_liquidationFeeRatio());
        uint minFee = _minLiquidationFee();

        return proportionalFee > minFee ? proportionalFee : minFee;
    }










    function _liquidationBuffer(int positionSize, uint price) internal view returns (uint lBuffer) {

        return _abs(positionSize).multiplyDecimalRound(price).multiplyDecimalRound(_liquidationBufferRatio());
    }







    function _liquidationMargin(int positionSize, uint price) internal view returns (uint lMargin) {
        return _liquidationBuffer(positionSize, price).add(_liquidationFee(positionSize, price));
    }







    function liquidationMargin(address account) external view returns (uint lMargin) {
        require(positions[account].size != 0, "0 size position");
        (uint price, ) = _assetPrice();
        return _liquidationMargin(positions[account].size, price);
    }









    function liquidationPrice(address account, bool includeFunding) external view returns (uint price, bool invalid) {
        (uint aPrice, bool isInvalid) = _assetPrice();
        uint liqPrice = _liquidationPrice(positions[account], includeFunding, aPrice);
        return (liqPrice, isInvalid);
    }








    function liquidationFee(address account) external view returns (uint) {
        (uint price, bool invalid) = _assetPrice();
        if (!invalid && _canLiquidate(positions[account], fundingSequence.length, price)) {
            return _liquidationFee(positions[account].size, price);
        } else {



            return 0;
        }
    }

    function _canLiquidate(
        Position memory position,
        uint fundingIndex,
        uint price
    ) internal view returns (bool) {

        if (position.size == 0) {
            return false;
        }

        return _remainingMargin(position, fundingIndex, price) <= _liquidationMargin(position.size, price);
    }




    function canLiquidate(address account) external view returns (bool) {
        (uint price, bool invalid) = _assetPrice();
        return !invalid && _canLiquidate(positions[account], fundingSequence.length, price);
    }

    function _currentLeverage(
        Position memory position,
        uint price,
        uint remainingMargin_
    ) internal pure returns (int leverage) {

        if (remainingMargin_ == 0) {
            return 0;
        }

        return _notionalValue(position, price).divideDecimalRound(int(remainingMargin_));
    }




    function currentLeverage(address account) external view returns (int leverage, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        Position storage position = positions[account];
        uint remainingMargin_ = _remainingMargin(position, fundingSequence.length, price);
        return (_currentLeverage(position, price, remainingMargin_), isInvalid);
    }

    function _orderFee(
        int newSize,
        int existingSize,
        uint price
    ) internal view returns (uint) {
        int existingNotional = existingSize.multiplyDecimalRound(int(price));


        if (newSize == 0) {
            return _abs(existingNotional.multiplyDecimalRound(int(_closureFee(baseAsset))));
        }

        int newNotional = newSize.multiplyDecimalRound(int(price));

        int notionalDiff = newNotional;
        if (_sameSide(newNotional, existingNotional)) {

            if (_abs(newNotional) <= _abs(existingNotional)) {
                return _abs(existingNotional.sub(newNotional).multiplyDecimalRound(int(_closureFee(baseAsset))));
            }




            notionalDiff = notionalDiff.sub(existingNotional);
        }

        int skew = marketSkew;
        if (_sameSide(newNotional, skew)) {


            return _abs(notionalDiff.multiplyDecimalRound(int(_takerFee(baseAsset))));
        }





        int makerFee = int(_makerFee(baseAsset));
        int fee = notionalDiff.multiplyDecimalRound(makerFee);


        int postSkewNotional = skew.multiplyDecimalRound(int(price)).sub(existingNotional).add(newNotional);



        if (_sameSide(newNotional, postSkewNotional)) {
            fee = fee.add(postSkewNotional.multiplyDecimalRound(int(_takerFee(baseAsset)).sub(makerFee)));
        }

        return _abs(fee);
    }





    function orderFee(address account, int sizeDelta) external view returns (uint fee, bool invalid) {
        (uint price, bool isInvalid) = _assetPrice();
        int positionSize = positions[account].size;
        return (_orderFee(positionSize.add(sizeDelta), positionSize, price), isInvalid);
    }

    function _postTradeDetails(
        Position memory oldPos,
        int sizeDelta,
        uint price,
        uint fundingIndex
    )
        internal
        view
        returns (
            Position memory newPosition,
            uint _fee,
            Status tradeStatus
        )
    {

        if (sizeDelta == 0) {
            return (oldPos, 0, Status.NilOrder);
        }


        if (_canLiquidate(oldPos, fundingIndex, price)) {
            return (oldPos, 0, Status.CanLiquidate);
        }

        int newSize = oldPos.size.add(sizeDelta);



        uint fee = _orderFee(newSize, oldPos.size, price);
        (uint newMargin, Status status) = _realisedMargin(oldPos, fundingIndex, price, -int(fee));
        if (_isError(status)) {
            return (oldPos, 0, status);
        }
        Position memory newPos = Position(oldPos.id, newMargin, newSize, price, fundingIndex);



        bool positionDecreasing = _sameSide(oldPos.size, newPos.size) && _abs(newPos.size) < _abs(oldPos.size);
        if (!positionDecreasing) {


            if (newPos.margin.add(fee) < _minInitialMargin()) {
                return (oldPos, 0, Status.InsufficientMargin);
            }
        }



        int leverage = newSize.multiplyDecimalRound(int(price)).divideDecimalRound(int(newMargin.add(fee)));
        if (_maxLeverage(baseAsset).add(uint(_UNIT) / 100) < _abs(leverage)) {
            return (oldPos, 0, Status.MaxLeverageExceeded);
        }



        if (
            _orderSizeTooLarge(
                uint(int(_maxMarketValueUSD(baseAsset).add(100 * uint(_UNIT))).divideDecimalRound(int(price))),
                oldPos.size,
                newPos.size
            )
        ) {
            return (oldPos, 0, Status.MaxMarketSizeExceeded);
        }

        return (newPos, fee, Status.Ok);
    }




    function postTradeDetails(int sizeDelta, address sender)
        external
        view
        returns (
            uint margin,
            int size,
            uint price,
            uint liqPrice,
            uint fee,
            Status status
        )
    {
        bool invalid;
        (price, invalid) = _assetPrice();
        if (invalid) {
            return (0, 0, 0, 0, 0, Status.InvalidPrice);
        }

        (Position memory newPosition, uint fee_, Status status_) =
            _postTradeDetails(positions[sender], sizeDelta, price, fundingSequence.length);

        liqPrice = _liquidationPrice(newPosition, true, newPosition.lastPrice);
        return (newPosition.margin, newPosition.size, newPosition.lastPrice, liqPrice, fee_, status_);
    }






    function _signedAbs(int x) internal pure returns (int) {
        return x < 0 ? -x : x;
    }




    function _abs(int x) internal pure returns (uint) {
        return uint(_signedAbs(x));
    }

    function _max(int x, int y) internal pure returns (int) {
        return x < y ? y : x;
    }

    function _min(int x, int y) internal pure returns (int) {
        return x < y ? x : y;
    }



    function _sameSide(int a, int b) internal pure returns (bool) {


        return 0 <= a * b;
    }




    function _isError(Status status) internal pure returns (bool) {
        return status != Status.Ok;
    }




    function _revertIfError(bool isError, Status status) internal view {
        if (isError) {
            revert(_errorMessages[uint8(status)]);
        }
    }




    function _revertIfError(Status status) internal view {
        if (_isError(status)) {
            revert(_errorMessages[uint8(status)]);
        }
    }









    function _assetPriceRequireChecks() internal returns (uint) {

        _systemStatus().requireSynthActive(baseAsset);

        (uint price, bool circuitBroken) = _exchangeRatesCircuitBreaker().rateWithBreakCircuit(baseAsset);

        _revertIfError(circuitBroken, Status.InvalidPrice);
        return price;
    }

    function _recomputeFunding(uint price) internal returns (uint lastIndex) {
        uint sequenceLength = fundingSequence.length;

        int funding = _nextFundingEntry(sequenceLength, price);
        fundingSequence.push(funding);
        fundingLastRecomputed = block.timestamp;
        emitFundingRecomputed(funding);

        return sequenceLength;
    }




    function recomputeFunding() external returns (uint lastIndex) {
        _revertIfError(msg.sender != _settings(), Status.NotPermitted);
        return _recomputeFunding(_assetPriceRequireChecks());
    }




    function _positionDebtCorrection(Position memory position) internal view returns (int) {


















        return
            int(position.margin).sub(
                position.size.multiplyDecimalRound(int(position.lastPrice).add(fundingSequence[position.fundingIndex]))
            );
    }




    function _applyDebtCorrection(Position memory newPosition, Position memory oldPosition) internal {
        int newCorrection = _positionDebtCorrection(newPosition);
        int oldCorrection = _positionDebtCorrection(oldPosition);
        _entryDebtCorrection = _entryDebtCorrection.add(newCorrection).sub(oldCorrection);
    }

    function _transferMargin(
        int marginDelta,
        uint price,
        uint fundingIndex,
        address sender
    ) internal {

        uint absDelta = _abs(marginDelta);
        if (0 < marginDelta) {




            uint postReclamationAmount = _manager().burnSUSD(sender, absDelta);
            if (postReclamationAmount != absDelta) {

                marginDelta = int(postReclamationAmount);
            }
        } else if (marginDelta < 0) {


            _manager().issueSUSD(sender, absDelta);
        } else {

            return;
        }

        Position storage position = positions[sender];
        Position memory oldPosition = position;


        (uint margin, Status status) = _realisedMargin(oldPosition, fundingIndex, price, marginDelta);
        _revertIfError(status);


        int positionSize = position.size;
        _applyDebtCorrection(
            Position(0, margin, positionSize, price, fundingIndex),
            Position(0, position.margin, positionSize, position.lastPrice, position.fundingIndex)
        );


        position.margin = margin;

        if (positionSize != 0) {
            position.lastPrice = price;
            position.fundingIndex = fundingIndex;





            if (marginDelta < 0) {
                _revertIfError(
                    margin < _minInitialMargin() ||
                        _maxLeverage(baseAsset) < _abs(_currentLeverage(position, price, margin)),
                    Status.InsufficientMargin
                );
            }
        }


        if (marginDelta != 0) {
            emitMarginTransferred(sender, marginDelta);
        }
        emitPositionModified(position.id, sender, margin, positionSize, 0, price, fundingIndex, 0);
    }







    function transferMargin(int marginDelta) external optionalProxy {
        uint price = _assetPriceRequireChecks();
        uint fundingIndex = _recomputeFunding(price);
        _transferMargin(marginDelta, price, fundingIndex, messageSender);
    }





    function withdrawAllMargin() external optionalProxy {
        address sender = messageSender;
        uint price = _assetPriceRequireChecks();
        uint fundingIndex = _recomputeFunding(price);
        int marginDelta = -int(_accessibleMargin(positions[sender], fundingIndex, price));
        _transferMargin(marginDelta, price, fundingIndex, sender);
    }

    function _modifyPosition(
        int sizeDelta,
        uint price,
        uint fundingIndex,
        address sender
    ) internal {
        Position storage position = positions[sender];
        Position memory oldPosition = position;


        (Position memory newPosition, uint fee, Status status) =
            _postTradeDetails(oldPosition, sizeDelta, price, fundingIndex);
        _revertIfError(status);


        marketSkew = marketSkew.add(newPosition.size).sub(oldPosition.size);
        marketSize = marketSize.add(_abs(newPosition.size)).sub(_abs(oldPosition.size));


        if (0 < fee) {
            _manager().payFee(fee);
        }


        position.margin = newPosition.margin;
        _applyDebtCorrection(newPosition, oldPosition);


        uint id = oldPosition.id;
        if (newPosition.size == 0) {

            delete position.id;
            delete position.size;
            delete position.lastPrice;
            delete position.fundingIndex;
        } else {
            if (oldPosition.size == 0) {

                id = _nextPositionId;
                _nextPositionId += 1;
            }
            position.id = id;
            position.size = newPosition.size;
            position.lastPrice = price;
            position.fundingIndex = fundingIndex;
        }

        emitPositionModified(id, sender, position.margin, position.size, sizeDelta, price, fundingIndex, fee);
    }





    function modifyPosition(int sizeDelta) external optionalProxy {
        uint price = _assetPriceRequireChecks();
        uint fundingIndex = _recomputeFunding(price);
        _modifyPosition(sizeDelta, price, fundingIndex, messageSender);
    }

    function _revertIfPriceOutsideBounds(
        uint price,
        uint minPrice,
        uint maxPrice
    ) internal view {
        _revertIfError(price < minPrice || maxPrice < price, Status.PriceOutOfBounds);
    }







    function modifyPositionWithPriceBounds(
        int sizeDelta,
        uint minPrice,
        uint maxPrice
    ) external optionalProxy {
        uint price = _assetPriceRequireChecks();
        _revertIfPriceOutsideBounds(price, minPrice, maxPrice);
        uint fundingIndex = _recomputeFunding(price);
        _modifyPosition(sizeDelta, price, fundingIndex, messageSender);
    }




    function closePosition() external optionalProxy {
        int size = positions[messageSender].size;
        _revertIfError(size == 0, Status.NoPositionOpen);
        uint price = _assetPriceRequireChecks();
        _modifyPosition(-size, price, _recomputeFunding(price), messageSender);
    }




    function closePositionWithPriceBounds(uint minPrice, uint maxPrice) external optionalProxy {
        int size = positions[messageSender].size;
        _revertIfError(size == 0, Status.NoPositionOpen);
        uint price = _assetPriceRequireChecks();
        _revertIfPriceOutsideBounds(price, minPrice, maxPrice);
        _modifyPosition(-size, price, _recomputeFunding(price), messageSender);
    }

    function _liquidatePosition(
        address account,
        address liquidator,
        uint fundingIndex,
        uint price
    ) internal {
        Position storage position = positions[account];


        uint remMargin = _remainingMargin(position, fundingIndex, price);


        int positionSize = position.size;
        uint positionId = position.id;
        marketSkew = marketSkew.sub(positionSize);
        marketSize = marketSize.sub(_abs(positionSize));

        _applyDebtCorrection(
            Position(0, 0, 0, price, fundingIndex),
            Position(0, position.margin, positionSize, position.lastPrice, position.fundingIndex)
        );


        delete positions[account];


        uint liqFee = _liquidationFee(positionSize, price);
        _manager().issueSUSD(liquidator, liqFee);

        emitPositionModified(positionId, account, 0, 0, 0, price, fundingIndex, 0);
        emitPositionLiquidated(positionId, account, liquidator, positionSize, price, liqFee);


        if (remMargin > liqFee) {
            _manager().payFee(remMargin.sub(liqFee));
        }
    }






    function liquidatePosition(address account) external optionalProxy {
        uint price = _assetPriceRequireChecks();
        uint fundingIndex = _recomputeFunding(price);

        _revertIfError(!_canLiquidate(positions[account], fundingIndex, price), Status.CannotLiquidate);

        _liquidatePosition(account, messageSender, fundingIndex, price);
    }



















































































