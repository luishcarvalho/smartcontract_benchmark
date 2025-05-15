pragma solidity 0.5.8;

import "../STO.sol";
import "../../../interfaces/IPolymathRegistry.sol";
import "../../../interfaces/IOracle.sol";
import "../../../libraries/DecimalMath.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./USDTieredSTOStorage.sol";






contract USDTieredSTO is USDTieredSTOStorage, STO {
    using SafeMath for uint256;

    string internal constant POLY_ORACLE = "PolyUsdOracle";
    string internal constant ETH_ORACLE = "EthUsdOracle";





    event SetAllowBeneficialInvestments(bool _allowed);
    event SetNonAccreditedLimit(address _investor, uint256 _limit);
    event TokenPurchase(
        address indexed _purchaser,
        address indexed _beneficiary,
        uint256 _tokens,
        uint256 _usdAmount,
        uint256 _tierPrice,
        uint256 _tier
    );
    event FundsReceived(
        address indexed _purchaser,
        address indexed _beneficiary,
        uint256 _usdAmount,
        FundRaiseType _fundRaiseType,
        uint256 _receivedValue,
        uint256 _spentValue,
        uint256 _rate
    );
    event ReserveTokenMint(address indexed _owner, address indexed _wallet, uint256 _tokens, uint256 _latestTier);
    event ReserveTokenTransfer(address indexed _from, address indexed _wallet, uint256 _tokens);
    event SetAddresses(address indexed _wallet, IERC20[] _stableTokens);
    event SetLimits(uint256 _nonAccreditedLimitUSD, uint256 _minimumInvestmentUSD);
    event SetTimes(uint256 _startTime, uint256 _endTime);
    event SetTiers(
        uint256[] _ratePerTier,
        uint256[] _ratePerTierDiscountPoly,
        uint256[] _tokensPerTierTotal,
        uint256[] _tokensPerTierDiscountPoly
    );
    event SetTreasuryWallet(address _oldWallet, address _newWallet);
    event SetOracles(bytes32 _denominatedCurrency, bool _isCustomOracles);





    modifier validETH() {
        _checkZeroOracleAddress(_getOracle(bytes32("ETH")));
        require(fundRaiseTypes[uint8(FundRaiseType.ETH)], "ETH not allowed");
        _;
    }

    modifier validPOLY() {
        _checkZeroOracleAddress(_getOracle(bytes32("POLY")));
        require(fundRaiseTypes[uint8(FundRaiseType.POLY)], "POLY not allowed");
        _;
    }

    modifier validSC(address _stableToken) {
        require(fundRaiseTypes[uint8(FundRaiseType.SC)] && stableTokenEnabled[_stableToken], "Fiat not allowed");
        _;
    }





    constructor(address _securityToken, address _polyAddress) public Module(_securityToken, _polyAddress) {

    }
















    function configure(
        uint256 _startTime,
        uint256 _endTime,
        uint256[] memory _ratePerTier,
        uint256[] memory _ratePerTierDiscountPoly,
        uint256[] memory _tokensPerTierTotal,
        uint256[] memory _tokensPerTierDiscountPoly,
        uint256 _nonAccreditedLimitUSD,
        uint256 _minimumInvestmentUSD,
        FundRaiseType[] memory _fundRaiseTypes,
        address payable _wallet,
        address _treasuryWallet,
        IERC20[] memory _stableTokens,
        address[] memory _customOracleAddresses,
        bytes32 _denominatedCurrency
    )
        public
        onlyFactory
    {
        require(endTime == 0, "Already configured");
        _modifyTimes(_startTime, _endTime);
        _modifyTiers(_ratePerTier, _ratePerTierDiscountPoly, _tokensPerTierTotal, _tokensPerTierDiscountPoly);

        _setFundRaiseType(_fundRaiseTypes);
        _modifyOracles(_customOracleAddresses, _denominatedCurrency);
        _modifyAddresses(_wallet, _treasuryWallet, _stableTokens);
        _modifyLimits(_nonAccreditedLimitUSD, _minimumInvestmentUSD);
    }




    function allowPreMinting() external withPerm(ADMIN) {
        _allowPreMinting(_getTotalTokensCap());
    }




    function revokePreMintFlag() external withPerm(ADMIN) {
        _revokePreMintFlag(_getTotalTokensCap());
    }

    function _getTotalTokensCap() internal view returns(uint256 totalCap) {
        for(uint256 i = 0; i < tiers.length; i++) {
            totalCap = totalCap.add(tiers[i].tokenTotal);
        }
    }





    function modifyFunding(FundRaiseType[] calldata _fundRaiseTypes) external withPerm(OPERATOR) {
        _isSTOStarted();
        _setFundRaiseType(_fundRaiseTypes);
    }






    function modifyLimits(uint256 _nonAccreditedLimitUSD, uint256 _minimumInvestmentUSD) external withPerm(OPERATOR) {
        _isSTOStarted();
        _modifyLimits(_nonAccreditedLimitUSD, _minimumInvestmentUSD);
    }








    function modifyTiers(
        uint256[] calldata _ratePerTier,
        uint256[] calldata _ratePerTierDiscountPoly,
        uint256[] calldata _tokensPerTierTotal,
        uint256[] calldata _tokensPerTierDiscountPoly
    )
        external
        withPerm(OPERATOR)
    {
        _isSTOStarted();
        _modifyTiers(_ratePerTier, _ratePerTierDiscountPoly, _tokensPerTierTotal, _tokensPerTierDiscountPoly);
    }






    function modifyTimes(uint256 _startTime, uint256 _endTime) external withPerm(OPERATOR) {
        _isSTOStarted();
        _modifyTimes(_startTime, _endTime);
    }







    function modifyAddresses(address payable _wallet, address _treasuryWallet, IERC20[] calldata _stableTokens) external {
        _onlySecurityTokenOwner();
        _modifyAddresses(_wallet, _treasuryWallet, _stableTokens);
    }








    function modifyOracles(address[] calldata _customOracleAddresses, bytes32 _denominatedCurrencySymbol) external {
        _onlySecurityTokenOwner();


        if (_denominatedCurrencySymbol != denominatedCurrency)
            _isSTOStarted();
        _modifyOracles(_customOracleAddresses, _denominatedCurrencySymbol);
    }

    function _modifyOracles(address[] memory _customOracleAddresses, bytes32 _denominatedCurrencySymbol) internal {
        if (_customOracleAddresses.length == 0 && _denominatedCurrencySymbol == bytes32(0)) {
            denominatedCurrency = bytes32("USD");
            delete customOracles[bytes32("ETH")][denominatedCurrency];
            delete customOracles[bytes32("POLY")][denominatedCurrency];
            oracleKeys[bytes32("ETH")][denominatedCurrency] = ETH_ORACLE;
            oracleKeys[bytes32("POLY")][denominatedCurrency] = POLY_ORACLE;
            emit SetOracles(denominatedCurrency, false);
        }
        else {
            require(_denominatedCurrencySymbol != bytes32(0), "Invalid currency");









            require(_customOracleAddresses.length == 2, "Invalid no. of oracles");
            if (fundRaiseTypes[uint8(FundRaiseType.ETH)]) {
                _checkZeroOracleAddress(_customOracleAddresses[0]);
            }
            if (fundRaiseTypes[uint8(FundRaiseType.POLY)]) {
                _checkZeroOracleAddress(_customOracleAddresses[1]);
            }
            denominatedCurrency = _denominatedCurrencySymbol;
            customOracles[bytes32("ETH")][denominatedCurrency] = _customOracleAddresses[0];
            customOracles[bytes32("POLY")][denominatedCurrency] = _customOracleAddresses[1];
            emit SetOracles(denominatedCurrency, true);
        }
    }

    function _checkZeroOracleAddress(address _addressForCheck) internal pure {
        require(_addressForCheck != address(0), "Invalid address");
    }

    function _modifyLimits(uint256 _nonAccreditedLimitUSD, uint256 _minimumInvestmentUSD) internal {
        minimumInvestmentUSD = _minimumInvestmentUSD;
        nonAccreditedLimitUSD = _nonAccreditedLimitUSD;
        emit SetLimits(minimumInvestmentUSD, nonAccreditedLimitUSD);
    }

    function _modifyTiers(
        uint256[] memory _ratePerTier,
        uint256[] memory _ratePerTierDiscountPoly,
        uint256[] memory _tokensPerTierTotal,
        uint256[] memory _tokensPerTierDiscountPoly
    )
        internal
    {
        require(
            _tokensPerTierTotal.length > 0 &&
            _ratePerTier.length == _tokensPerTierTotal.length &&
            _ratePerTierDiscountPoly.length == _tokensPerTierTotal.length &&
            _tokensPerTierDiscountPoly.length == _tokensPerTierTotal.length,
            "Invalid Input"
        );
        delete tiers;
        for (uint256 i = 0; i < _ratePerTier.length; i++) {
            require(_ratePerTier[i] > 0 && _tokensPerTierTotal[i] > 0, "Invalid value");
            require(_tokensPerTierDiscountPoly[i] <= _tokensPerTierTotal[i], "Too many discounted tokens");
            require(_ratePerTierDiscountPoly[i] <= _ratePerTier[i], "Invalid discount");
            tiers.push(Tier(_ratePerTier[i], _ratePerTierDiscountPoly[i], _tokensPerTierTotal[i], _tokensPerTierDiscountPoly[i], 0, 0));
        }
        if (preMintAllowed) {
            uint256 oldCap = securityToken.balanceOf(address(this));
            uint256 newCap = _getTotalTokensCap();
            if (oldCap < newCap) {
                securityToken.issue(address(this), (newCap - oldCap), "");
            }
            else if (oldCap > newCap) {
                securityToken.redeem((oldCap - newCap), "");
            }
        }
        emit SetTiers(_ratePerTier, _ratePerTierDiscountPoly, _tokensPerTierTotal, _tokensPerTierDiscountPoly);
    }

    function _modifyTimes(uint256 _startTime, uint256 _endTime) internal {




































    function finalize() external withPerm(ADMIN) {
        require(!isFinalized, "STO is finalized");
        isFinalized = true;
        uint256 tempReturned;
        uint256 tempSold;
        uint256 remainingTokens;
        for (uint256 i = 0; i < tiers.length; i++) {
            remainingTokens = tiers[i].tokenTotal.sub(tiers[i].totalTokensSoldInTier);
            tempReturned = tempReturned.add(remainingTokens);
            tempSold = tempSold.add(tiers[i].totalTokensSoldInTier);
            if (remainingTokens > 0) {
                tiers[i].totalTokensSoldInTier = tiers[i].tokenTotal;
            }
        }
        address walletAddress = getTreasuryWallet();
        _checkZeroOracleAddress(walletAddress);

        if (preMintAllowed) {
            if (tempReturned == securityToken.balanceOf(address(this)))
                tempReturned = securityToken.balanceOf(address(this));
        }
        uint256 granularity = securityToken.granularity();
        tempReturned = tempReturned.div(granularity);
        tempReturned = tempReturned.mul(granularity);
        if (tempReturned != uint256(0)) {
            if (preMintAllowed) {
                securityToken.transfer(walletAddress, tempReturned);
                emit ReserveTokenTransfer(address(this), walletAddress, tempReturned);
            } else {
                securityToken.issue(walletAddress, tempReturned, "");
                emit ReserveTokenMint(msg.sender, walletAddress, tempReturned, currentTier);
            }
        }
        finalAmountReturned = tempReturned;
        totalTokensSold = tempSold;
    }






    function changeNonAccreditedLimit(address[] calldata _investors, uint256[] calldata _nonAccreditedLimit) external withPerm(OPERATOR) {

        require(_investors.length == _nonAccreditedLimit.length, "Length mismatch");
        for (uint256 i = 0; i < _investors.length; i++) {
            nonAccreditedLimitUSDOverride[_investors[i]] = _nonAccreditedLimit[i];
            emit SetNonAccreditedLimit(_investors[i], _nonAccreditedLimit[i]);
        }
    }







    function getAccreditedData() external view returns (address[] memory investors, bool[] memory accredited, uint256[] memory overrides) {
        IDataStore dataStore = getDataStore();
        investors = dataStore.getAddressArray(INVESTORSKEY);
        accredited = new bool[](investors.length);
        overrides = new uint256[](investors.length);
        for (uint256 i = 0; i < investors.length; i++) {
            accredited[i] = _getIsAccredited(investors[i], dataStore);
            overrides[i] = nonAccreditedLimitUSDOverride[investors[i]];
        }
    }





    function changeAllowBeneficialInvestments(bool _allowBeneficialInvestments) external withPerm(OPERATOR) {
        require(_allowBeneficialInvestments != allowBeneficialInvestments);
        allowBeneficialInvestments = _allowBeneficialInvestments;
        emit SetAllowBeneficialInvestments(allowBeneficialInvestments);
    }








    function() external payable {
        buyWithETHRateLimited(msg.sender, 0);
    }


    function buyWithETH(address _beneficiary) external payable returns (uint256, uint256, uint256) {
        return buyWithETHRateLimited(_beneficiary, 0);
    }

    function buyWithPOLY(address _beneficiary, uint256 _investedPOLY) external returns (uint256, uint256, uint256) {
        return buyWithPOLYRateLimited(_beneficiary, _investedPOLY, 0);
    }

    function buyWithUSD(address _beneficiary, uint256 _investedSC, IERC20 _usdToken) external returns (uint256, uint256, uint256) {
        return buyWithUSDRateLimited(_beneficiary, _investedSC, 0, _usdToken);
    }






    function buyWithETHRateLimited(address _beneficiary, uint256 _minTokens) public payable validETH returns (uint256, uint256, uint256) {
        (uint256 rate, uint256 spentUSD, uint256 spentValue, uint256 initialMinted) = _getSpentvalues(_beneficiary,  msg.value, FundRaiseType.ETH, _minTokens);

        investorInvested[_beneficiary][uint8(FundRaiseType.ETH)] = investorInvested[_beneficiary][uint8(FundRaiseType.ETH)].add(spentValue);
        fundsRaised[uint8(FundRaiseType.ETH)] = fundsRaised[uint8(FundRaiseType.ETH)].add(spentValue);

        wallet.transfer(spentValue);

        msg.sender.transfer(msg.value.sub(spentValue));
        emit FundsReceived(msg.sender, _beneficiary, spentUSD, FundRaiseType.ETH, msg.value, spentValue, rate);
        return (spentUSD, spentValue, getTokensMinted().sub(initialMinted));
    }







    function buyWithPOLYRateLimited(address _beneficiary, uint256 _investedPOLY, uint256 _minTokens) public validPOLY returns (uint256, uint256, uint256) {
        return _buyWithTokens(_beneficiary, _investedPOLY, FundRaiseType.POLY, _minTokens, polyToken);
    }








    function buyWithUSDRateLimited(address _beneficiary, uint256 _investedSC, uint256 _minTokens, IERC20 _usdToken)
        public validSC(address(_usdToken)) returns (uint256, uint256, uint256)
    {
        return _buyWithTokens(_beneficiary, _investedSC, FundRaiseType.SC, _minTokens, _usdToken);
    }

    function _buyWithTokens(address _beneficiary, uint256 _tokenAmount, FundRaiseType _fundRaiseType, uint256 _minTokens, IERC20 _token) internal returns (uint256, uint256, uint256) {
        (uint256 rate, uint256 spentUSD, uint256 spentValue, uint256 initialMinted) = _getSpentvalues(_beneficiary, _tokenAmount, _fundRaiseType, _minTokens);

        investorInvested[_beneficiary][uint8(_fundRaiseType)] = investorInvested[_beneficiary][uint8(_fundRaiseType)].add(spentValue);
        fundsRaised[uint8(_fundRaiseType)] = fundsRaised[uint8(_fundRaiseType)].add(spentValue);
        if(address(_token) != address(polyToken))
            stableCoinsRaised[address(_token)] = stableCoinsRaised[address(_token)].add(spentValue);

        require(_token.transferFrom(msg.sender, wallet, spentValue), "Transfer failed");
        emit FundsReceived(msg.sender, _beneficiary, spentUSD, _fundRaiseType, _tokenAmount, spentValue, rate);
        return (spentUSD, spentValue, getTokensMinted().sub(initialMinted));
    }

    function _getSpentvalues(address _beneficiary, uint256 _amount, FundRaiseType _fundRaiseType, uint256 _minTokens) internal returns(uint256 rate, uint256 spentUSD, uint256 spentValue, uint256 initialMinted) {
        initialMinted = getTokensMinted();
        rate = getRate(_fundRaiseType);
        (spentUSD, spentValue) = _buyTokens(_beneficiary, _amount, rate, _fundRaiseType);
        require(getTokensMinted().sub(initialMinted) >= _minTokens, "Insufficient minted");
    }








    function _buyTokens(
        address _beneficiary,
        uint256 _investmentValue,
        uint256 _rate,
        FundRaiseType _fundRaiseType
    )
        internal
        whenNotPaused
        returns(uint256 spentUSD, uint256 spentValue)
    {
        if (!allowBeneficialInvestments) {
            require(_beneficiary == msg.sender, "Beneficiary != funder");
        }

        require(_canBuy(_beneficiary), "Unauthorized");

        uint256 originalUSD = DecimalMath.mul(_rate, _investmentValue);
        uint256 allowedUSD = _buyTokensChecks(_beneficiary, _investmentValue, originalUSD);

        for (uint256 i = currentTier; i < tiers.length; i++) {
            bool gotoNextTier;
            uint256 tempSpentUSD;

            if (currentTier != i)
                currentTier = i;

            if (tiers[i].totalTokensSoldInTier < tiers[i].tokenTotal) {
                (tempSpentUSD, gotoNextTier) = _calculateTier(_beneficiary, i, allowedUSD.sub(spentUSD), _fundRaiseType);
                spentUSD = spentUSD.add(tempSpentUSD);

                if (!gotoNextTier)
                    break;
            }
        }


        if (spentUSD > 0) {
            if (investorInvestedUSD[_beneficiary] == 0)
                investorCount = investorCount + 1;
            investorInvestedUSD[_beneficiary] = investorInvestedUSD[_beneficiary].add(spentUSD);
            fundsRaisedUSD = fundsRaisedUSD.add(spentUSD);
        }

        spentValue = DecimalMath.div(spentUSD, _rate);
    }

    function _buyTokensChecks(
        address _beneficiary,
        uint256 _investmentValue,
        uint256 investedUSD
    )
        internal
        view
        returns(uint256 netInvestedUSD)
    {
        require(isOpen(), "STO not open");
        require(_investmentValue > 0, "No funds sent");


        require(investedUSD.add(investorInvestedUSD[_beneficiary]) >= minimumInvestmentUSD, "Investment < min");
        netInvestedUSD = investedUSD;

        if (!_isAccredited(_beneficiary)) {
            uint256 investorLimitUSD = (nonAccreditedLimitUSDOverride[_beneficiary] == 0) ? nonAccreditedLimitUSD : nonAccreditedLimitUSDOverride[_beneficiary];
            require(investorInvestedUSD[_beneficiary] < investorLimitUSD, "Over Non-accredited investor limit");
            if (investedUSD.add(investorInvestedUSD[_beneficiary]) > investorLimitUSD)
                netInvestedUSD = investorLimitUSD.sub(investorInvestedUSD[_beneficiary]);
        }
    }

    function _calculateTier(
        address _beneficiary,
        uint256 _tier,
        uint256 _investedUSD,
        FundRaiseType _fundRaiseType
    )
        internal
        returns(uint256 spentUSD, bool gotoNextTier)
    {

        uint256 tierSpentUSD;
        uint256 tierPurchasedTokens;
        uint256 investedUSD = _investedUSD;
        Tier storage tierData = tiers[_tier];

        if ((_fundRaiseType == FundRaiseType.POLY) && (tierData.tokensDiscountPoly > tierData.soldDiscountPoly)) {
            uint256 discountRemaining = tierData.tokensDiscountPoly.sub(tierData.soldDiscountPoly);
            uint256 totalRemaining = tierData.tokenTotal.sub(tierData.totalTokensSoldInTier);
            if (totalRemaining < discountRemaining)
                (spentUSD, tierPurchasedTokens, gotoNextTier) = _purchaseTier(_beneficiary, tierData.rateDiscountPoly, totalRemaining, investedUSD, _tier);
            else
                (spentUSD, tierPurchasedTokens, gotoNextTier) = _purchaseTier(_beneficiary, tierData.rateDiscountPoly, discountRemaining, investedUSD, _tier);
            investedUSD = investedUSD.sub(spentUSD);
            tierData.soldDiscountPoly = tierData.soldDiscountPoly.add(tierPurchasedTokens);
            tierData.tokenSoldPerFundType[uint8(_fundRaiseType)] = tierData.tokenSoldPerFundType[uint8(_fundRaiseType)].add(tierPurchasedTokens);
            tierData.totalTokensSoldInTier = tierData.totalTokensSoldInTier.add(tierPurchasedTokens);
        }

        if (investedUSD > 0 &&
            tierData.tokenTotal.sub(tierData.totalTokensSoldInTier) > 0 &&
            (_fundRaiseType != FundRaiseType.POLY || tierData.tokensDiscountPoly <= tierData.soldDiscountPoly)
        ) {
            (tierSpentUSD, tierPurchasedTokens, gotoNextTier) = _purchaseTier(
                _beneficiary,
                tierData.rate,
                tierData.tokenTotal.sub(tierData.totalTokensSoldInTier),
                investedUSD,
                _tier
            );
            spentUSD = spentUSD.add(tierSpentUSD);
            tierData.tokenSoldPerFundType[uint8(_fundRaiseType)] = tierData.tokenSoldPerFundType[uint8(_fundRaiseType)].add(tierPurchasedTokens);
            tierData.totalTokensSoldInTier = tierData.totalTokensSoldInTier.add(tierPurchasedTokens);
        }
    }

    function _purchaseTier(
        address _beneficiary,
        uint256 _tierPrice,
        uint256 _tierRemaining,
        uint256 _investedUSD,
        uint256 _tier
    )
        internal
        returns(uint256 spentUSD, uint256 purchasedTokens, bool gotoNextTier)
    {
        purchasedTokens = DecimalMath.div(_investedUSD, _tierPrice);
        uint256 granularity = securityToken.granularity();

        if (purchasedTokens > _tierRemaining) {
            purchasedTokens = _tierRemaining.div(granularity);
            gotoNextTier = true;
        } else {
            purchasedTokens = purchasedTokens.div(granularity);
        }

        purchasedTokens = purchasedTokens.mul(granularity);
        spentUSD = DecimalMath.mul(purchasedTokens, _tierPrice);


        if (spentUSD > _investedUSD) {
            spentUSD = _investedUSD;
        }

        if (purchasedTokens > 0) {
            if (preMintAllowed)
                securityToken.transfer(_beneficiary, purchasedTokens);
            else
                securityToken.issue(_beneficiary, purchasedTokens, "");
            emit TokenPurchase(msg.sender, _beneficiary, purchasedTokens, spentUSD, _tierPrice, _tier);
        }
    }

    function _isAccredited(address _investor) internal view returns(bool) {
        IDataStore dataStore = getDataStore();
        return _getIsAccredited(_investor, dataStore);
    }

    function _getIsAccredited(address _investor, IDataStore dataStore) internal view returns(bool) {
        uint256 flags = dataStore.getUint256(_getKey(INVESTORFLAGS, _investor));
        uint256 flag = flags & uint256(1);
        return flag > 0 ? true : false;
    }









    function isOpen() public view returns(bool) {










    function capReached() public view returns (bool) {
        if (isFinalized) {
            return (finalAmountReturned == 0);
        }
        return (tiers[tiers.length - 1].totalTokensSoldInTier == tiers[tiers.length - 1].tokenTotal);
    }





    function getRate(FundRaiseType _fundRaiseType) public returns (uint256) {
        if (_fundRaiseType == FundRaiseType.ETH) {
            return IOracle(_getOracle(bytes32("ETH"))).getPrice();
        } else if (_fundRaiseType == FundRaiseType.POLY) {
            return IOracle(_getOracle(bytes32("POLY"))).getPrice();
        } else if (_fundRaiseType == FundRaiseType.SC) {
            return 10**18;
        }
    }





    function getCustomOracleAddress(FundRaiseType _fundRaiseType) external view returns(address) {
        if (_fundRaiseType == FundRaiseType.ETH) {
            return customOracles[bytes32("ETH")][denominatedCurrency];
        } else if (_fundRaiseType == FundRaiseType.POLY) {
            return customOracles[bytes32("POLY")][denominatedCurrency];
        }
    }







    function convertToUSD(FundRaiseType _fundRaiseType, uint256 _amount) public returns(uint256) {
        return DecimalMath.mul(_amount, getRate(_fundRaiseType));
    }







    function convertFromUSD(FundRaiseType _fundRaiseType, uint256 _amount) public returns(uint256) {
        return DecimalMath.div(_amount, getRate(_fundRaiseType));
    }





    function getTokensSold() public view returns (uint256) {
        if (isFinalized)
            return totalTokensSold;
        return getTokensMinted();
    }





    function getTokensMinted() public view returns (uint256 tokensMinted) {
        for (uint256 i = 0; i < tiers.length; i++) {
            tokensMinted = tokensMinted.add(tiers[i].totalTokensSoldInTier);
        }
    }






    function getTokensSoldFor(FundRaiseType _fundRaiseType) external view returns (uint256 tokensSold) {
        for (uint256 i = 0; i < tiers.length; i++) {
            tokensSold = tokensSold.add(tiers[i].tokenSoldPerFundType[uint8(_fundRaiseType)]);
        }
    }






    function getTokensSoldByTier(uint256 _tier) external view returns(uint256[] memory) {
        uint256[] memory tokensMinted = new uint256[](3);
        tokensMinted[0] = tiers[_tier].tokenSoldPerFundType[uint8(FundRaiseType.ETH)];
        tokensMinted[1] = tiers[_tier].tokenSoldPerFundType[uint8(FundRaiseType.POLY)];
        tokensMinted[2] = tiers[_tier].tokenSoldPerFundType[uint8(FundRaiseType.SC)];
        return tokensMinted;
    }






    function getTotalTokensSoldByTier(uint256 _tier) external view returns (uint256) {
        uint256 tokensSold;
        tokensSold = tokensSold.add(tiers[_tier].tokenSoldPerFundType[uint8(FundRaiseType.ETH)]);
        tokensSold = tokensSold.add(tiers[_tier].tokenSoldPerFundType[uint8(FundRaiseType.POLY)]);
        tokensSold = tokensSold.add(tiers[_tier].tokenSoldPerFundType[uint8(FundRaiseType.SC)]);
        return tokensSold;
    }





    function getNumberOfTiers() external view returns (uint256) {
        return tiers.length;
    }





    function getUsdTokens() external view returns (IERC20[] memory) {
        return stableTokens;
    }




    function getPermissions() public view returns(bytes32[] memory allPermissions) {
        allPermissions = new bytes32[](2);
        allPermissions[0] = OPERATOR;
        allPermissions[1] = ADMIN;
        return allPermissions;
    }














    function getSTODetails() external view returns(uint256, uint256, uint256, uint256[] memory, uint256[] memory, uint256, uint256, uint256, bool[] memory, bool) {
        uint256[] memory cap = new uint256[](tiers.length);
        uint256[] memory rate = new uint256[](tiers.length);
        for(uint256 i = 0; i < tiers.length; i++) {
            cap[i] = tiers[i].tokenTotal;
            rate[i] = tiers[i].rate;
        }
        bool[] memory _fundRaiseTypes = new bool[](3);
        _fundRaiseTypes[0] = fundRaiseTypes[uint8(FundRaiseType.ETH)];
        _fundRaiseTypes[1] = fundRaiseTypes[uint8(FundRaiseType.POLY)];
        _fundRaiseTypes[2] = fundRaiseTypes[uint8(FundRaiseType.SC)];
        return (
            startTime,
            endTime,
            currentTier,
            cap,
            rate,
            fundsRaisedUSD,
            investorCount,
            getTokensSold(),
            _fundRaiseTypes,
            preMintAllowed
        );
    }





    function getInitFunction() public pure returns(bytes4) {
        return this.configure.selector;
    }

    function _getOracle(bytes32 _currency) internal view returns(address oracleAddress) {
        oracleAddress = customOracles[_currency][denominatedCurrency];
        if (oracleAddress == address(0) && denominatedCurrency == bytes32("USD"))
            oracleAddress =  IPolymathRegistry(securityToken.polymathRegistry()).getAddress(oracleKeys[_currency][denominatedCurrency]);
    }
}
