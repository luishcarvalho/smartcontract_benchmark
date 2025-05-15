

pragma solidity ^0.5.12;


library SafeMath {

    function MUL98(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0)
            return 0;
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function DIV107(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function SUB705(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function ADD235(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function MOD157(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;

    event TRANSFER731(address indexed from, address indexed to, uint256 value);
    event APPROVAL787(address indexed owner, address indexed spender, uint256 value);

    uint256 internal _totalSupply;


    function TOTALSUPPLY882() public view returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF767(address owner) public view returns (uint256) {
        return _balances[owner];
    }


    function ALLOWANCE10(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }


    function TRANSFER204(address to, uint256 value) public returns (bool) {
        _TRANSFER522(msg.sender, to, value);
        return true;
    }


    function APPROVE277(address spender, uint256 value) public returns (bool) {
        _allowed[msg.sender][spender] = value;
        emit APPROVAL787(msg.sender, spender, value);
        return true;
    }


    function TRANSFERFROM832(address from, address to, uint256 value) public returns (bool) {
        _TRANSFER522(from, to, value);
        _allowed[msg.sender][to] = _allowed[msg.sender][to].SUB705(value);
        return true;
    }

    function _TRANSFER522(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].SUB705(value);
        _balances[to] = _balances[to].ADD235(value);
        emit TRANSFER731(from, to, value);
    }

}

contract ERC20Mintable is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    function _MINT321(address to, uint256 amount) internal {
        _balances[to] = _balances[to].ADD235(amount);
        _totalSupply = _totalSupply.ADD235(amount);
        emit TRANSFER731(address(0), to, amount);
    }

    function _BURN441(address from, uint256 amount) internal {
        _balances[from] = _balances[from].SUB705(amount);
        _totalSupply = _totalSupply.SUB705(amount);
        emit TRANSFER731(from, address(0), amount);
    }
}



contract ILendingPoolAddressesProvider {

    function GETLENDINGPOOL38() public view returns (address);
    function SETLENDINGPOOLIMPL881(address _pool) public;

    function GETLENDINGPOOLCORE21() public view returns (address payable);
    function SETLENDINGPOOLCOREIMPL156(address _lendingPoolCore) public;

    function GETLENDINGPOOLCONFIGURATOR254() public view returns (address);
    function SETLENDINGPOOLCONFIGURATORIMPL555(address _configurator) public;

    function GETLENDINGPOOLDATAPROVIDER61() public view returns (address);
    function SETLENDINGPOOLDATAPROVIDERIMPL193(address _provider) public;

    function GETLENDINGPOOLPARAMETERSPROVIDER362() public view returns (address);
    function SETLENDINGPOOLPARAMETERSPROVIDERIMPL978(address _parametersProvider) public;

    function GETTOKENDISTRIBUTOR827() public view returns (address);
    function SETTOKENDISTRIBUTOR348(address _tokenDistributor) public;


    function GETFEEPROVIDER168() public view returns (address);
    function SETFEEPROVIDERIMPL718(address _feeProvider) public;

    function GETLENDINGPOOLLIQUIDATIONMANAGER82() public view returns (address);
    function SETLENDINGPOOLLIQUIDATIONMANAGER708(address _manager) public;

    function GETLENDINGPOOLMANAGER762() public view returns (address);
    function SETLENDINGPOOLMANAGER882(address _lendingPoolManager) public;

    function GETPRICEORACLE485() public view returns (address);
    function SETPRICEORACLE428(address _priceOracle) public;

    function GETLENDINGRATEORACLE592() public view returns (address);
    function SETLENDINGRATEORACLE655(address _lendingRateOracle) public;
}

interface ILendingPool {
    function ADDRESSESPROVIDER344() external view returns(address);
    function DEPOSIT818(address _reserve, uint256 _amount, uint16 _referralCode) external payable;
    function REDEEMUNDERLYING805(address _reserve, address _user, uint256 _amount) external;
    function BORROW264(address _reserve, uint256 _amount, uint256 _interestRateMode, uint16 _referralCode) external;
    function REPAY662(address _reserve, uint256 _amount, address _onBehalfOf) external payable;
    function SWAPBORROWRATEMODE766(address _reserve) external;
    function REBALANCEFIXEDBORROWRATE627(address _reserve, address _user) external;
    function SETUSERUSERESERVEASCOLLATERAL986(address _reserve, bool _useAsCollateral) external;
    function LIQUIDATIONCALL807(address _collateral, address _reserve, address _user, uint256 _purchaseAmount, bool _receiveAToken) external payable;
    function FLASHLOAN206(address _receiver, address _reserve, uint256 _amount, bytes calldata _params) external;
    function GETRESERVECONFIGURATIONDATA59(address _reserve) external view returns(uint256 ltv, uint256 liquidationThreshold, uint256 liquidationDiscount, address interestRateStrategyAddress, bool usageAsCollateralEnabled, bool borrowingEnabled, bool fixedBorrowRateEnabled, bool isActive);
    function GETRESERVEDATA692(address _reserve) external view returns(uint256 totalLiquidity, uint256 availableLiquidity, uint256 totalBorrowsFixed, uint256 totalBorrowsVariable, uint256 liquidityRate, uint256 variableBorrowRate, uint256 fixedBorrowRate, uint256 averageFixedBorrowRate, uint256 utilizationRate, uint256 liquidityIndex, uint256 variableBorrowIndex, address aTokenAddress, uint40 lastUpdateTimestamp);
    function GETUSERACCOUNTDATA811(address _user) external view returns(uint256 totalLiquidityETH, uint256 totalCollateralETH, uint256 totalBorrowsETH, uint256 availableBorrowsETH, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor);
    function GETUSERRESERVEDATA732(address _reserve, address _user) external view returns(uint256 currentATokenBalance, uint256 currentBorrowBalance, uint256 principalBorrowBalance, uint256 borrowRateMode, uint256 borrowRate, uint256 liquidityRate, uint256 originationFee, uint256 variableBorrowIndex, uint256 lastUpdateTimestamp, bool usageAsCollateralEnabled);
    function GETRESERVES689() external view;
}

interface ILendingPoolCore {
    function GETRESERVEATOKENADDRESS314(address _reserve) external view returns (address);
    function GETRESERVECURRENTVARIABLEBORROWRATE762(address _token) external view returns (uint256);
    function GETRESERVECURRENTLIQUIDITYRATE636(address _token) external view returns (uint256);
}

interface IAavePriceOracleGetter {
    function GETASSETPRICE734(address _asset) external view returns (uint256);
    function GETASSETSPRICES996(address[] calldata _assets) external view returns(uint256[] memory);
    function GETSOURCEOFASSET324(address _asset) external view returns(address);
    function GETFALLBACKORACLE535() external view returns(address);
}

interface IAToken {
    function REDIRECTINTERESTSTREAM242(address _to) external;
    function REDIRECTINTERESTSTREAMOF292(address _from, address _to) external;
    function ALLOWINTERESTREDIRECTIONTO292(address _to) external;
    function REDEEM632(uint256 _amount) external;
    function PRINCIPALBALANCEOF100(address _user) external view returns(uint256);
    function ISTRANSFERALLOWED396(address _user, uint256 _amount) external view returns (bool);
    function GETUSERINDEX768(address _user) external view returns(uint256);
    function GETINTERESTREDIRECTIONADDRESS228(address _user) external view returns(address);
    function GETREDIRECTEDBALANCE288(address _user) external view returns(uint256);

    function TOTALSUPPLY882() external view returns (uint256 supply);
    function BALANCEOF767(address _owner) external view returns (uint256 balance);
    function TRANSFER204(address _to, uint256 _value) external returns (bool success);
    function TRANSFERFROM832(address _from, address _to, uint256 _value) external returns (bool success);
    function APPROVE277(address _spender, uint256 _value) external returns (bool success);
    function ALLOWANCE10(address _owner, address _spender) external view returns (uint256 remaining);

    function NAME858() external view returns (string memory);
    function SYMBOL894() external view returns (string memory);
    function DECIMALS454() external view returns (uint8);
}

interface PriceOracle {
    function GETUNDERLYINGPRICE929(address) external view returns (uint256);
}



interface CErc20 {

    function BORROW264(uint256) external returns (uint256);

    function BORROWRATEPERBLOCK388() external view returns (uint256);

    function BORROWBALANCECURRENT444(address) external returns (uint256);

    function REPAYBORROW515(uint256) external returns (uint256);
}


interface CEth {
    function MINT397() external payable;

    function REDEEMUNDERLYING805(uint redeemAmount) external returns (uint256);

    function BALANCEOFUNDERLYING788(address owner) external returns (uint256);

    function SUPPLYRATEPERBLOCK15() external view returns (uint256);
}


interface Comptroller {
    function MARKETS249(address) external returns (bool, uint256);

    function ENTERMARKETS82(address[] calldata)
        external
        returns (uint256[] memory);

    function GETACCOUNTLIQUIDITY384(address)
        external
        view
        returns (uint256, uint256, uint256);

    function ORACLE168() external view returns(address);
}



interface Exchange {
    function TRADE301(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId )external payable returns(uint);
}




contract tCDPConstants {
    uint256 constant dust264 = 1e6;
    ERC20 constant dai445 = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);


    Comptroller constant comptroller75 = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    CEth constant ceth501 = CEth(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    CErc20 constant cdai61 = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);


    ILendingPoolAddressesProvider constant addressesprovider654 = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    uint16 constant referral215 = 47;


    Exchange constant kybernetwork927 = Exchange(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    address constant etheraddr36 = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant ref472 = 0xD0533664013a82c31584B7FFDB215139f38Ad77A;


    uint256 constant targetratio559 = 0.4e18;
    uint256 constant upperbound23 = 444444444444444444;
    uint256 constant lowerbound414 = 363636363636363636;
    uint256 constant bite558 = 0.025 * 1e18;
}

contract tCDP is ERC20Mintable, tCDPConstants{
    using SafeMath for *;

    bool public isCompound;

    event MIGRATION431(uint8);

    constructor() public {
        symbol = "tETH-DAI";
        name = "tokenized CDP ETH-DAI v1";
        decimals = 18;

        address lendingPoolCoreAddress = addressesprovider654.GETLENDINGPOOLCORE21();
        dai445.APPROVE277(lendingPoolCoreAddress, uint256(-1));
        dai445.APPROVE277(address(cdai61), uint256(-1));

        address[] memory cTokens = new address[](1);
        cTokens[0] = address(ceth501);
        uint256[] memory errors = comptroller75.ENTERMARKETS82(cTokens);
        require(errors[0] == 0, "Comptroller.enterMarkets failed.");

        dai445.APPROVE277(address(kybernetwork927), uint256(-1));
        isCompound = FINDBESTRATE616();
    }

    function INITIATE270(uint256 amount) external payable {
        require(_totalSupply < dust264, "initiated");
        require(msg.value > dust264, "value too small");

        if(isCompound) {
            ceth501.MINT397.value(msg.value)();
            _MINT321(msg.sender, msg.value);
            require(cdai61.BORROW264(amount) == 0, "borrow failed");
            dai445.TRANSFER204(msg.sender, amount);
        }
        else {
            ILendingPool lendingPool = ILendingPool(addressesprovider654.GETLENDINGPOOL38());
            lendingPool.DEPOSIT818.value(msg.value)(etheraddr36, msg.value, referral215);

            _MINT321(msg.sender, msg.value);

            lendingPool.BORROW264(address(dai445), amount, 2, referral215);
            dai445.TRANSFER204(msg.sender, amount);
        }
    }

    function COLLATERAL797() public returns(uint256) {
        if(isCompound) {
            return ceth501.BALANCEOFUNDERLYING788(address(this));
        }
        else {
            address lendingPoolCore = addressesprovider654.GETLENDINGPOOLCORE21();
            address aETH = ILendingPoolCore(lendingPoolCore).GETRESERVEATOKENADDRESS314(etheraddr36);
            return IAToken(aETH).BALANCEOF767(address(this));
        }
    }

    function DEBT567() public returns(uint256) {
        if(isCompound) {
            return cdai61.BORROWBALANCECURRENT444(address(this));
        }
        else {
            ILendingPool lendingPool = ILendingPool(addressesprovider654.GETLENDINGPOOL38());
            (, uint256 borrowBalance,,,,,,,,) = lendingPool.GETUSERRESERVEDATA732(address(dai445), address(this));
            return borrowBalance;
        }
    }

    function MINT397() external payable returns(uint256) {

        require(_totalSupply >= dust264, "not initiated");
        uint256 amount = msg.value;
        uint256 tokenToMint = _totalSupply.MUL98(amount).DIV107(COLLATERAL797());
        uint256 tokenToBorrow = DEBT567().MUL98(amount).DIV107(COLLATERAL797());
        _MINT321(msg.sender, tokenToMint);

        if(isCompound) {
            ceth501.MINT397.value(amount)();
            require(cdai61.BORROW264(tokenToBorrow) == 0, "borrow failed");
            dai445.TRANSFER204(msg.sender, tokenToBorrow);
        }
        else{

            ILendingPool lendingPool = ILendingPool(addressesprovider654.GETLENDINGPOOL38());
            lendingPool.DEPOSIT818.value(amount)(etheraddr36, amount, referral215);

            lendingPool.BORROW264(address(dai445), tokenToBorrow, 2, referral215);

            dai445.TRANSFER204(msg.sender, tokenToBorrow);
        }

        return tokenToMint;
    }

    function BURN250(uint256 amount) external {

        uint256 tokenToRepay = amount.MUL98(DEBT567()).DIV107(_totalSupply);
        uint256 tokenToDraw = amount.MUL98(COLLATERAL797()).DIV107(_totalSupply);
        _BURN441(msg.sender, amount);
        dai445.TRANSFERFROM832(msg.sender, address(this), tokenToRepay);

        if(isCompound) {
            require(cdai61.REPAYBORROW515(tokenToRepay) == 0, "repay failed");
            require(ceth501.REDEEMUNDERLYING805(tokenToDraw) == 0, "redeem failed");
        }
        else {

            ILendingPool lendingPool = ILendingPool(addressesprovider654.GETLENDINGPOOL38());
            address lendingPoolCoreAddress = addressesprovider654.GETLENDINGPOOLCORE21();

            lendingPool.REPAY662(address(dai445), tokenToRepay, address(this));

            IAToken aETH = IAToken(ILendingPoolCore(lendingPoolCoreAddress).GETRESERVEATOKENADDRESS314(etheraddr36));
            aETH.REDEEM632(tokenToDraw);
        }

        (bool success, ) = msg.sender.call.value(tokenToDraw)("");
        require(success, "Failed to transfer ether to msg.sender");
    }

    function() external payable{}


    function FINDBESTRATE616() public view returns (bool) {
        return AAVEDAIAPR797().MUL98(targetratio559).DIV107(1e18).ADD235(COMPOUNDETHAPR912()) > COMPOUNDDAIAPR961().MUL98(targetratio559).DIV107(1e18).ADD235(AAVEETHAPR160());
    }
    function COMPOUNDDAIAPR961() public view returns (uint256) {
        return cdai61.BORROWRATEPERBLOCK388().MUL98(2102400);
    }
    function COMPOUNDETHAPR912() public view returns (uint256) {
        return ceth501.SUPPLYRATEPERBLOCK15().MUL98(2102400);
    }
    function AAVEDAIAPR797() public view returns (uint256) {
        ILendingPoolCore core = ILendingPoolCore(addressesprovider654.GETLENDINGPOOLCORE21());
        return core.GETRESERVECURRENTVARIABLEBORROWRATE762(address(dai445)).DIV107(1e9);
    }
    function AAVEETHAPR160() public view returns (uint256) {
        ILendingPoolCore core = ILendingPoolCore(addressesprovider654.GETLENDINGPOOLCORE21());
        return core.GETRESERVECURRENTLIQUIDITYRATE636(etheraddr36).DIV107(1e9);
    }

    function GETUNDERLYINGPRICE929() public view returns(uint256) {
        uint256 price;

        if(isCompound) {
            address oracle = comptroller75.ORACLE168();
            PriceOracle priceOracle = PriceOracle(oracle);
            price = priceOracle.GETUNDERLYINGPRICE929(address(cdai61));
        }
        else {
            address oracleAddress = addressesprovider654.GETPRICEORACLE485();
            IAavePriceOracleGetter priceOracle = IAavePriceOracleGetter(oracleAddress);
            price = priceOracle.GETASSETPRICE734(address(dai445));
        }

        return price;
    }

    function DEBTRATIO670() public returns (uint256) {
        uint256 price = GETUNDERLYINGPRICE929();
        uint256 ratio = DEBT567().MUL98(price).DIV107(COLLATERAL797());
        return ratio;
    }

    function DELEVERAGE904() external {
        require(_totalSupply >= dust264, "not initiated");
        require(DEBTRATIO670() > upperbound23, "debt ratio is good");
        uint256 amount = COLLATERAL797().MUL98(bite558).DIV107(1e18);

        if(isCompound) {
            require(ceth501.REDEEMUNDERLYING805(amount) == 0, "redeem failed");
            uint256 income = kybernetwork927.TRADE301.value(amount)(etheraddr36, amount, address(dai445), address(this), 1e28, 1, ref472);
            require(cdai61.REPAYBORROW515(income) == 0, "repay failed");
        }
        else {

            address lendingPoolCoreAddress = addressesprovider654.GETLENDINGPOOLCORE21();
            IAToken aETH = IAToken(ILendingPoolCore(lendingPoolCoreAddress).GETRESERVEATOKENADDRESS314(etheraddr36));
            aETH.REDEEM632(amount);
            uint256 income = kybernetwork927.TRADE301.value(amount)(etheraddr36, amount, address(dai445), address(this), 1e28, 1, ref472);

            ILendingPool lendingPool = ILendingPool(addressesprovider654.GETLENDINGPOOL38());

            lendingPool.REPAY662(address(dai445), income, address(this));
        }
    }

    function LEVERAGE920() external {
        require(_totalSupply >= dust264, "not initiated");
        require(DEBTRATIO670() < lowerbound414, "debt ratio is good");
        uint256 amount = DEBT567().MUL98(bite558).DIV107(1e18);

        if(isCompound) {
            require(cdai61.BORROW264(amount) == 0, "borrow failed");
            uint256 income = kybernetwork927.TRADE301(address(dai445), amount, etheraddr36, address(this), 1e28, 1, ref472);
            ceth501.MINT397.value(income)();
        }
        else {

            ILendingPool lendingPool = ILendingPool(addressesprovider654.GETLENDINGPOOL38());
            lendingPool.BORROW264(address(dai445), amount, 2, referral215);
            uint256 income = kybernetwork927.TRADE301(address(dai445), amount, etheraddr36, address(this), 1e28, 1, ref472);

            lendingPool.DEPOSIT818.value(income)(etheraddr36, income, referral215);
        }
    }

    function MIGRATE814() external {
        if(FINDBESTRATE616() != isCompound) {
            uint256 _debt = DEBT567();
            uint256 _collateral = COLLATERAL797();
            dai445.TRANSFERFROM832(msg.sender, address(this), _debt);
            uint256 newBorrow = _debt.ADD235(2);

            if(isCompound) {
                require(cdai61.REPAYBORROW515(_debt) == 0, "borrow failed");
                require(ceth501.REDEEMUNDERLYING805(_collateral) == 0, "redeem failed");

                ILendingPool lendingPool = ILendingPool(addressesprovider654.GETLENDINGPOOL38());
                lendingPool.DEPOSIT818.value(_collateral)(etheraddr36, _collateral, referral215);
                lendingPool.BORROW264(address(dai445), newBorrow, 2, referral215);

                isCompound = false;
                emit MIGRATION431(0x02);
            }
            else {
                ILendingPool lendingPool = ILendingPool(addressesprovider654.GETLENDINGPOOL38());
                address lendingPoolCoreAddress = addressesprovider654.GETLENDINGPOOLCORE21();
                lendingPool.REPAY662(address(dai445), _debt, address(this));
                IAToken aETH = IAToken(ILendingPoolCore(lendingPoolCoreAddress).GETRESERVEATOKENADDRESS314(etheraddr36));
                aETH.REDEEM632(_collateral);

                ceth501.MINT397.value(_collateral)();
                require(cdai61.BORROW264(newBorrow) == 0, "borrow failed");

                isCompound = true;
                emit MIGRATION431(0x01);
            }

            dai445.TRANSFER204(msg.sender, newBorrow);
        }

    }

}
