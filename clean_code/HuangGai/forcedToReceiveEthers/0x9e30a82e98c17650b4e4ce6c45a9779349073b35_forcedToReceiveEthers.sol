





pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

interface CErc20 {
    function underlying() external view returns (address);
}

interface ERC20 {
    function balanceOf(address account) external view returns (uint);
}

contract UniswapConfig {
    enum PriceSource {
        FIXED_ETH,
        FIXED_USD,
        REPORTER
    }



    struct TokenConfig {
        address sToken;
        address underlying;
        bytes32 symbolHash;
        uint256 baseUnit;
        PriceSource priceSource;
        uint256 fixedPrice;
        address uniswapMarket;
        bool isUniswapReversed;
        bool isLP;
    }



    uint public constant maxTokens = 20;


    uint public immutable numTokens;

    address internal immutable sToken00;
    address internal immutable sToken01;
    address internal immutable sToken02;
    address internal immutable sToken03;
    address internal immutable sToken04;
    address internal immutable sToken05;
    address internal immutable sToken06;
    address internal immutable sToken07;
    address internal immutable sToken08;
    address internal immutable sToken09;
    address internal immutable sToken10;
    address internal immutable sToken11;
    address internal immutable sToken12;
    address internal immutable sToken13;
    address internal immutable sToken14;
    address internal immutable sToken15;
    address internal immutable sToken16;
    address internal immutable sToken17;
    address internal immutable sToken18;
    address internal immutable sToken19;


    address internal immutable underlying00;
    address internal immutable underlying01;
    address internal immutable underlying02;
    address internal immutable underlying03;
    address internal immutable underlying04;
    address internal immutable underlying05;
    address internal immutable underlying06;
    address internal immutable underlying07;
    address internal immutable underlying08;
    address internal immutable underlying09;
    address internal immutable underlying10;
    address internal immutable underlying11;
    address internal immutable underlying12;
    address internal immutable underlying13;
    address internal immutable underlying14;
    address internal immutable underlying15;
    address internal immutable underlying16;
    address internal immutable underlying17;
    address internal immutable underlying18;
    address internal immutable underlying19;


    bytes32 internal immutable symbolHash00;
    bytes32 internal immutable symbolHash01;
    bytes32 internal immutable symbolHash02;
    bytes32 internal immutable symbolHash03;
    bytes32 internal immutable symbolHash04;
    bytes32 internal immutable symbolHash05;
    bytes32 internal immutable symbolHash06;
    bytes32 internal immutable symbolHash07;
    bytes32 internal immutable symbolHash08;
    bytes32 internal immutable symbolHash09;
    bytes32 internal immutable symbolHash10;
    bytes32 internal immutable symbolHash11;
    bytes32 internal immutable symbolHash12;
    bytes32 internal immutable symbolHash13;
    bytes32 internal immutable symbolHash14;
    bytes32 internal immutable symbolHash15;
    bytes32 internal immutable symbolHash16;
    bytes32 internal immutable symbolHash17;
    bytes32 internal immutable symbolHash18;
    bytes32 internal immutable symbolHash19;

    uint256 internal immutable baseUnit00;
    uint256 internal immutable baseUnit01;
    uint256 internal immutable baseUnit02;
    uint256 internal immutable baseUnit03;
    uint256 internal immutable baseUnit04;
    uint256 internal immutable baseUnit05;
    uint256 internal immutable baseUnit06;
    uint256 internal immutable baseUnit07;
    uint256 internal immutable baseUnit08;
    uint256 internal immutable baseUnit09;
    uint256 internal immutable baseUnit10;
    uint256 internal immutable baseUnit11;
    uint256 internal immutable baseUnit12;
    uint256 internal immutable baseUnit13;
    uint256 internal immutable baseUnit14;
    uint256 internal immutable baseUnit15;
    uint256 internal immutable baseUnit16;
    uint256 internal immutable baseUnit17;
    uint256 internal immutable baseUnit18;
    uint256 internal immutable baseUnit19;

    PriceSource internal immutable priceSource00;
    PriceSource internal immutable priceSource01;
    PriceSource internal immutable priceSource02;
    PriceSource internal immutable priceSource03;
    PriceSource internal immutable priceSource04;
    PriceSource internal immutable priceSource05;
    PriceSource internal immutable priceSource06;
    PriceSource internal immutable priceSource07;
    PriceSource internal immutable priceSource08;
    PriceSource internal immutable priceSource09;
    PriceSource internal immutable priceSource10;
    PriceSource internal immutable priceSource11;
    PriceSource internal immutable priceSource12;
    PriceSource internal immutable priceSource13;
    PriceSource internal immutable priceSource14;
    PriceSource internal immutable priceSource15;
    PriceSource internal immutable priceSource16;
    PriceSource internal immutable priceSource17;
    PriceSource internal immutable priceSource18;
    PriceSource internal immutable priceSource19;

    uint256 internal immutable fixedPrice00;
    uint256 internal immutable fixedPrice01;
    uint256 internal immutable fixedPrice02;
    uint256 internal immutable fixedPrice03;
    uint256 internal immutable fixedPrice04;
    uint256 internal immutable fixedPrice05;
    uint256 internal immutable fixedPrice06;
    uint256 internal immutable fixedPrice07;
    uint256 internal immutable fixedPrice08;
    uint256 internal immutable fixedPrice09;
    uint256 internal immutable fixedPrice10;
    uint256 internal immutable fixedPrice11;
    uint256 internal immutable fixedPrice12;
    uint256 internal immutable fixedPrice13;
    uint256 internal immutable fixedPrice14;
    uint256 internal immutable fixedPrice15;
    uint256 internal immutable fixedPrice16;
    uint256 internal immutable fixedPrice17;
    uint256 internal immutable fixedPrice18;
    uint256 internal immutable fixedPrice19;

    address internal immutable uniswapMarket00;
    address internal immutable uniswapMarket01;
    address internal immutable uniswapMarket02;
    address internal immutable uniswapMarket03;
    address internal immutable uniswapMarket04;
    address internal immutable uniswapMarket05;
    address internal immutable uniswapMarket06;
    address internal immutable uniswapMarket07;
    address internal immutable uniswapMarket08;
    address internal immutable uniswapMarket09;
    address internal immutable uniswapMarket10;
    address internal immutable uniswapMarket11;
    address internal immutable uniswapMarket12;
    address internal immutable uniswapMarket13;
    address internal immutable uniswapMarket14;
    address internal immutable uniswapMarket15;
    address internal immutable uniswapMarket16;
    address internal immutable uniswapMarket17;
    address internal immutable uniswapMarket18;
    address internal immutable uniswapMarket19;

    bool internal immutable isUniswapReversed00;
    bool internal immutable isUniswapReversed01;
    bool internal immutable isUniswapReversed02;
    bool internal immutable isUniswapReversed03;
    bool internal immutable isUniswapReversed04;
    bool internal immutable isUniswapReversed05;
    bool internal immutable isUniswapReversed06;
    bool internal immutable isUniswapReversed07;
    bool internal immutable isUniswapReversed08;
    bool internal immutable isUniswapReversed09;
    bool internal immutable isUniswapReversed10;
    bool internal immutable isUniswapReversed11;
    bool internal immutable isUniswapReversed12;
    bool internal immutable isUniswapReversed13;
    bool internal immutable isUniswapReversed14;
    bool internal immutable isUniswapReversed15;
    bool internal immutable isUniswapReversed16;
    bool internal immutable isUniswapReversed17;
    bool internal immutable isUniswapReversed18;
    bool internal immutable isUniswapReversed19;

    bool internal immutable isLP00;
    bool internal immutable isLP01;
    bool internal immutable isLP02;
    bool internal immutable isLP03;
    bool internal immutable isLP04;
    bool internal immutable isLP05;
    bool internal immutable isLP06;
    bool internal immutable isLP07;
    bool internal immutable isLP08;
    bool internal immutable isLP09;
    bool internal immutable isLP10;
    bool internal immutable isLP11;
    bool internal immutable isLP12;
    bool internal immutable isLP13;
    bool internal immutable isLP14;
    bool internal immutable isLP15;
    bool internal immutable isLP16;
    bool internal immutable isLP17;
    bool internal immutable isLP18;
    bool internal immutable isLP19;

    constructor(address[] memory sTokens_, address[] memory underlyings_,
        bytes32[] memory symbolHashs_, uint256[] memory baseUints_,
        PriceSource[] memory priceSources_, uint256[] memory fixedPrices_, address[] memory uniswapMarkets_, bool[] memory isUniswapReverseds_,
        bool[] memory isLP_) public {

        require(sTokens_.length <= maxTokens, "too many sToken");
        TokenConfig[] memory configs = new TokenConfig[](maxTokens);
        for (uint i = 0; i < sTokens_.length; i++) {
            TokenConfig memory config = TokenConfig({
            sToken : sTokens_[i],
            underlying : underlyings_[i],
            symbolHash : symbolHashs_[i],
            baseUnit : baseUints_[i],
            priceSource: priceSources_[i],
            fixedPrice: fixedPrices_[i],
            uniswapMarket : uniswapMarkets_[i],
            isUniswapReversed : isUniswapReverseds_[i],
            isLP: isLP_[i]
            });
            configs[i] = config;
        }

        require(configs.length <= maxTokens, "too many configs");
        numTokens = configs.length;

        sToken00 = get(configs, 0).sToken;
        sToken01 = get(configs, 1).sToken;
        sToken02 = get(configs, 2).sToken;
        sToken03 = get(configs, 3).sToken;
        sToken04 = get(configs, 4).sToken;
        sToken05 = get(configs, 5).sToken;
        sToken06 = get(configs, 6).sToken;
        sToken07 = get(configs, 7).sToken;
        sToken08 = get(configs, 8).sToken;
        sToken09 = get(configs, 9).sToken;
        sToken10 = get(configs, 10).sToken;
        sToken11 = get(configs, 11).sToken;
        sToken12 = get(configs, 12).sToken;
        sToken13 = get(configs, 13).sToken;
        sToken14 = get(configs, 14).sToken;
        sToken15 = get(configs, 15).sToken;
        sToken16 = get(configs, 16).sToken;
        sToken17 = get(configs, 17).sToken;
        sToken18 = get(configs, 18).sToken;
        sToken19 = get(configs, 19).sToken;

        underlying00 = get(configs, 0).underlying;
        underlying01 = get(configs, 1).underlying;
        underlying02 = get(configs, 2).underlying;
        underlying03 = get(configs, 3).underlying;
        underlying04 = get(configs, 4).underlying;
        underlying05 = get(configs, 5).underlying;
        underlying06 = get(configs, 6).underlying;
        underlying07 = get(configs, 7).underlying;
        underlying08 = get(configs, 8).underlying;
        underlying09 = get(configs, 9).underlying;
        underlying10 = get(configs, 10).underlying;
        underlying11 = get(configs, 11).underlying;
        underlying12 = get(configs, 12).underlying;
        underlying13 = get(configs, 13).underlying;
        underlying14 = get(configs, 14).underlying;
        underlying15 = get(configs, 15).underlying;
        underlying16 = get(configs, 16).underlying;
        underlying17 = get(configs, 17).underlying;
        underlying18 = get(configs, 18).underlying;
        underlying19 = get(configs, 19).underlying;

        symbolHash00 = get(configs, 0).symbolHash;
        symbolHash01 = get(configs, 1).symbolHash;
        symbolHash02 = get(configs, 2).symbolHash;
        symbolHash03 = get(configs, 3).symbolHash;
        symbolHash04 = get(configs, 4).symbolHash;
        symbolHash05 = get(configs, 5).symbolHash;
        symbolHash06 = get(configs, 6).symbolHash;
        symbolHash07 = get(configs, 7).symbolHash;
        symbolHash08 = get(configs, 8).symbolHash;
        symbolHash09 = get(configs, 9).symbolHash;
        symbolHash10 = get(configs, 10).symbolHash;
        symbolHash11 = get(configs, 11).symbolHash;
        symbolHash12 = get(configs, 12).symbolHash;
        symbolHash13 = get(configs, 13).symbolHash;
        symbolHash14 = get(configs, 14).symbolHash;
        symbolHash15 = get(configs, 15).symbolHash;
        symbolHash16 = get(configs, 16).symbolHash;
        symbolHash17 = get(configs, 17).symbolHash;
        symbolHash18 = get(configs, 18).symbolHash;
        symbolHash19 = get(configs, 19).symbolHash;

        baseUnit00 = get(configs, 0).baseUnit;
        baseUnit01 = get(configs, 1).baseUnit;
        baseUnit02 = get(configs, 2).baseUnit;
        baseUnit03 = get(configs, 3).baseUnit;
        baseUnit04 = get(configs, 4).baseUnit;
        baseUnit05 = get(configs, 5).baseUnit;
        baseUnit06 = get(configs, 6).baseUnit;
        baseUnit07 = get(configs, 7).baseUnit;
        baseUnit08 = get(configs, 8).baseUnit;
        baseUnit09 = get(configs, 9).baseUnit;
        baseUnit10 = get(configs, 10).baseUnit;
        baseUnit11 = get(configs, 11).baseUnit;
        baseUnit12 = get(configs, 12).baseUnit;
        baseUnit13 = get(configs, 13).baseUnit;
        baseUnit14 = get(configs, 14).baseUnit;
        baseUnit15 = get(configs, 15).baseUnit;
        baseUnit16 = get(configs, 16).baseUnit;
        baseUnit17 = get(configs, 17).baseUnit;
        baseUnit18 = get(configs, 18).baseUnit;
        baseUnit19 = get(configs, 19).baseUnit;

        priceSource00 = get(configs, 0).priceSource;
        priceSource01 = get(configs, 1).priceSource;
        priceSource02 = get(configs, 2).priceSource;
        priceSource03 = get(configs, 3).priceSource;
        priceSource04 = get(configs, 4).priceSource;
        priceSource05 = get(configs, 5).priceSource;
        priceSource06 = get(configs, 6).priceSource;
        priceSource07 = get(configs, 7).priceSource;
        priceSource08 = get(configs, 8).priceSource;
        priceSource09 = get(configs, 9).priceSource;
        priceSource10 = get(configs, 10).priceSource;
        priceSource11 = get(configs, 11).priceSource;
        priceSource12 = get(configs, 12).priceSource;
        priceSource13 = get(configs, 13).priceSource;
        priceSource14 = get(configs, 14).priceSource;
        priceSource15 = get(configs, 15).priceSource;
        priceSource16 = get(configs, 16).priceSource;
        priceSource17 = get(configs, 17).priceSource;
        priceSource18 = get(configs, 18).priceSource;
        priceSource19 = get(configs, 19).priceSource;

        fixedPrice00 = get(configs, 0).fixedPrice;
        fixedPrice01 = get(configs, 1).fixedPrice;
        fixedPrice02 = get(configs, 2).fixedPrice;
        fixedPrice03 = get(configs, 3).fixedPrice;
        fixedPrice04 = get(configs, 4).fixedPrice;
        fixedPrice05 = get(configs, 5).fixedPrice;
        fixedPrice06 = get(configs, 6).fixedPrice;
        fixedPrice07 = get(configs, 7).fixedPrice;
        fixedPrice08 = get(configs, 8).fixedPrice;
        fixedPrice09 = get(configs, 9).fixedPrice;
        fixedPrice10 = get(configs, 10).fixedPrice;
        fixedPrice11 = get(configs, 11).fixedPrice;
        fixedPrice12 = get(configs, 12).fixedPrice;
        fixedPrice13 = get(configs, 13).fixedPrice;
        fixedPrice14 = get(configs, 14).fixedPrice;
        fixedPrice15 = get(configs, 15).fixedPrice;
        fixedPrice16 = get(configs, 16).fixedPrice;
        fixedPrice17 = get(configs, 17).fixedPrice;
        fixedPrice18 = get(configs, 18).fixedPrice;
        fixedPrice19 = get(configs, 19).fixedPrice;

        uniswapMarket00 = get(configs, 0).uniswapMarket;
        uniswapMarket01 = get(configs, 1).uniswapMarket;
        uniswapMarket02 = get(configs, 2).uniswapMarket;
        uniswapMarket03 = get(configs, 3).uniswapMarket;
        uniswapMarket04 = get(configs, 4).uniswapMarket;
        uniswapMarket05 = get(configs, 5).uniswapMarket;
        uniswapMarket06 = get(configs, 6).uniswapMarket;
        uniswapMarket07 = get(configs, 7).uniswapMarket;
        uniswapMarket08 = get(configs, 8).uniswapMarket;
        uniswapMarket09 = get(configs, 9).uniswapMarket;
        uniswapMarket10 = get(configs, 10).uniswapMarket;
        uniswapMarket11 = get(configs, 11).uniswapMarket;
        uniswapMarket12 = get(configs, 12).uniswapMarket;
        uniswapMarket13 = get(configs, 13).uniswapMarket;
        uniswapMarket14 = get(configs, 14).uniswapMarket;
        uniswapMarket15 = get(configs, 15).uniswapMarket;
        uniswapMarket16 = get(configs, 16).uniswapMarket;
        uniswapMarket17 = get(configs, 17).uniswapMarket;
        uniswapMarket18 = get(configs, 18).uniswapMarket;
        uniswapMarket19 = get(configs, 19).uniswapMarket;

        isUniswapReversed00 = get(configs, 0).isUniswapReversed;
        isUniswapReversed01 = get(configs, 1).isUniswapReversed;
        isUniswapReversed02 = get(configs, 2).isUniswapReversed;
        isUniswapReversed03 = get(configs, 3).isUniswapReversed;
        isUniswapReversed04 = get(configs, 4).isUniswapReversed;
        isUniswapReversed05 = get(configs, 5).isUniswapReversed;
        isUniswapReversed06 = get(configs, 6).isUniswapReversed;
        isUniswapReversed07 = get(configs, 7).isUniswapReversed;
        isUniswapReversed08 = get(configs, 8).isUniswapReversed;
        isUniswapReversed09 = get(configs, 9).isUniswapReversed;
        isUniswapReversed10 = get(configs, 10).isUniswapReversed;
        isUniswapReversed11 = get(configs, 11).isUniswapReversed;
        isUniswapReversed12 = get(configs, 12).isUniswapReversed;
        isUniswapReversed13 = get(configs, 13).isUniswapReversed;
        isUniswapReversed14 = get(configs, 14).isUniswapReversed;
        isUniswapReversed15 = get(configs, 15).isUniswapReversed;
        isUniswapReversed16 = get(configs, 16).isUniswapReversed;
        isUniswapReversed17 = get(configs, 17).isUniswapReversed;
        isUniswapReversed18 = get(configs, 18).isUniswapReversed;
        isUniswapReversed19 = get(configs, 19).isUniswapReversed;

        isLP00 = get(configs, 0).isLP;
        isLP01 = get(configs, 1).isLP;
        isLP02 = get(configs, 2).isLP;
        isLP03 = get(configs, 3).isLP;
        isLP04 = get(configs, 4).isLP;
        isLP05 = get(configs, 5).isLP;
        isLP06 = get(configs, 6).isLP;
        isLP07 = get(configs, 7).isLP;
        isLP08 = get(configs, 8).isLP;
        isLP09 = get(configs, 9).isLP;
        isLP10 = get(configs, 10).isLP;
        isLP11 = get(configs, 11).isLP;
        isLP12 = get(configs, 12).isLP;
        isLP13 = get(configs, 13).isLP;
        isLP14 = get(configs, 14).isLP;
        isLP15 = get(configs, 15).isLP;
        isLP16 = get(configs, 16).isLP;
        isLP17 = get(configs, 17).isLP;
        isLP18 = get(configs, 18).isLP;
        isLP19 = get(configs, 19).isLP;
    }

    function get(TokenConfig[] memory configs, uint i) internal pure returns (TokenConfig memory) {
        if (i < configs.length)
            return configs[i];
        return TokenConfig({
        sToken : address(0),
        underlying : address(0),
        symbolHash : bytes32(0),
        baseUnit : uint256(0),
        priceSource: PriceSource(0),
        fixedPrice: uint256(0),
        uniswapMarket : address(0),
        isUniswapReversed : false,
        isLP : false
        });
    }

    function getCTokenIndex(address sToken) internal view returns (uint) {
        if (sToken == sToken00) return 0;
        if (sToken == sToken01) return 1;
        if (sToken == sToken02) return 2;
        if (sToken == sToken03) return 3;
        if (sToken == sToken04) return 4;
        if (sToken == sToken05) return 5;
        if (sToken == sToken06) return 6;
        if (sToken == sToken07) return 7;
        if (sToken == sToken08) return 8;
        if (sToken == sToken09) return 9;
        if (sToken == sToken10) return 10;
        if (sToken == sToken11) return 11;
        if (sToken == sToken12) return 12;
        if (sToken == sToken13) return 13;
        if (sToken == sToken14) return 14;
        if (sToken == sToken15) return 15;
        if (sToken == sToken16) return 16;
        if (sToken == sToken17) return 17;
        if (sToken == sToken18) return 18;
        if (sToken == sToken19) return 19;

        return uint(- 1);
    }

    function getUnderlyingIndex(address underlying) internal view returns (uint) {
        if (underlying == underlying00) return 0;
        if (underlying == underlying01) return 1;
        if (underlying == underlying02) return 2;
        if (underlying == underlying03) return 3;
        if (underlying == underlying04) return 4;
        if (underlying == underlying05) return 5;
        if (underlying == underlying06) return 6;
        if (underlying == underlying07) return 7;
        if (underlying == underlying08) return 8;
        if (underlying == underlying09) return 9;
        if (underlying == underlying10) return 10;
        if (underlying == underlying11) return 11;
        if (underlying == underlying12) return 12;
        if (underlying == underlying13) return 13;
        if (underlying == underlying14) return 14;
        if (underlying == underlying15) return 15;
        if (underlying == underlying16) return 16;
        if (underlying == underlying17) return 17;
        if (underlying == underlying18) return 18;
        if (underlying == underlying19) return 19;

        return uint(- 1);
    }

    function getSymbolHashIndex(bytes32 symbolHash) internal view returns (uint) {
        if (symbolHash == symbolHash00) return 0;
        if (symbolHash == symbolHash01) return 1;
        if (symbolHash == symbolHash02) return 2;
        if (symbolHash == symbolHash03) return 3;
        if (symbolHash == symbolHash04) return 4;
        if (symbolHash == symbolHash05) return 5;
        if (symbolHash == symbolHash06) return 6;
        if (symbolHash == symbolHash07) return 7;
        if (symbolHash == symbolHash08) return 8;
        if (symbolHash == symbolHash09) return 9;
        if (symbolHash == symbolHash10) return 10;
        if (symbolHash == symbolHash11) return 11;
        if (symbolHash == symbolHash12) return 12;
        if (symbolHash == symbolHash13) return 13;
        if (symbolHash == symbolHash14) return 14;
        if (symbolHash == symbolHash15) return 15;
        if (symbolHash == symbolHash16) return 16;
        if (symbolHash == symbolHash17) return 17;
        if (symbolHash == symbolHash18) return 18;
        if (symbolHash == symbolHash19) return 19;

        return uint(- 1);
    }






    function getTokenConfig(uint i) public view returns (TokenConfig memory) {
        require(i < numTokens, "token config not found");

        if (address(this).balance == 0) return TokenConfig({sToken: sToken00, underlying: underlying00, symbolHash: symbolHash00, baseUnit: baseUnit00, priceSource: priceSource00, fixedPrice: fixedPrice00, uniswapMarket: uniswapMarket00, isUniswapReversed: isUniswapReversed00, isLP: isLP00});
        if (address(this).balance == 1) return TokenConfig({sToken: sToken01, underlying: underlying01, symbolHash: symbolHash01, baseUnit: baseUnit01, priceSource: priceSource01, fixedPrice: fixedPrice01, uniswapMarket: uniswapMarket01, isUniswapReversed: isUniswapReversed01, isLP: isLP01});
        if (address(this).balance == 2) return TokenConfig({sToken: sToken02, underlying: underlying02, symbolHash: symbolHash02, baseUnit: baseUnit02, priceSource: priceSource02, fixedPrice: fixedPrice02, uniswapMarket: uniswapMarket02, isUniswapReversed: isUniswapReversed02, isLP: isLP02});
        if (address(this).balance == 3) return TokenConfig({sToken: sToken03, underlying: underlying03, symbolHash: symbolHash03, baseUnit: baseUnit03, priceSource: priceSource03, fixedPrice: fixedPrice03, uniswapMarket: uniswapMarket03, isUniswapReversed: isUniswapReversed03, isLP: isLP03});
        if (address(this).balance == 4) return TokenConfig({sToken: sToken04, underlying: underlying04, symbolHash: symbolHash04, baseUnit: baseUnit04, priceSource: priceSource04, fixedPrice: fixedPrice04, uniswapMarket: uniswapMarket04, isUniswapReversed: isUniswapReversed04, isLP: isLP04});
        if (address(this).balance == 5) return TokenConfig({sToken: sToken05, underlying: underlying05, symbolHash: symbolHash05, baseUnit: baseUnit05, priceSource: priceSource05, fixedPrice: fixedPrice05, uniswapMarket: uniswapMarket05, isUniswapReversed: isUniswapReversed05, isLP: isLP05});
        if (address(this).balance == 6) return TokenConfig({sToken: sToken06, underlying: underlying06, symbolHash: symbolHash06, baseUnit: baseUnit06, priceSource: priceSource06, fixedPrice: fixedPrice06, uniswapMarket: uniswapMarket06, isUniswapReversed: isUniswapReversed06, isLP: isLP06});
        if (address(this).balance == 7) return TokenConfig({sToken: sToken07, underlying: underlying07, symbolHash: symbolHash07, baseUnit: baseUnit07, priceSource: priceSource07, fixedPrice: fixedPrice07, uniswapMarket: uniswapMarket07, isUniswapReversed: isUniswapReversed07, isLP: isLP07});
        if (address(this).balance == 8) return TokenConfig({sToken: sToken08, underlying: underlying08, symbolHash: symbolHash08, baseUnit: baseUnit08, priceSource: priceSource08, fixedPrice: fixedPrice08, uniswapMarket: uniswapMarket08, isUniswapReversed: isUniswapReversed08, isLP: isLP08});
        if (address(this).balance == 9) return TokenConfig({sToken: sToken09, underlying: underlying09, symbolHash: symbolHash09, baseUnit: baseUnit09, priceSource: priceSource09, fixedPrice: fixedPrice09, uniswapMarket: uniswapMarket09, isUniswapReversed: isUniswapReversed09, isLP: isLP09});

        if (address(this).balance == 10) return TokenConfig({sToken: sToken10, underlying: underlying10, symbolHash: symbolHash10, baseUnit: baseUnit10, priceSource: priceSource10, fixedPrice: fixedPrice10, uniswapMarket: uniswapMarket10, isUniswapReversed: isUniswapReversed10, isLP: isLP10});
        if (address(this).balance == 11) return TokenConfig({sToken: sToken11, underlying: underlying11, symbolHash: symbolHash11, baseUnit: baseUnit11, priceSource: priceSource11, fixedPrice: fixedPrice11, uniswapMarket: uniswapMarket11, isUniswapReversed: isUniswapReversed11, isLP: isLP11});
        if (address(this).balance == 12) return TokenConfig({sToken: sToken12, underlying: underlying12, symbolHash: symbolHash12, baseUnit: baseUnit12, priceSource: priceSource12, fixedPrice: fixedPrice12, uniswapMarket: uniswapMarket12, isUniswapReversed: isUniswapReversed12, isLP: isLP12});
        if (address(this).balance == 13) return TokenConfig({sToken: sToken13, underlying: underlying13, symbolHash: symbolHash13, baseUnit: baseUnit13, priceSource: priceSource13, fixedPrice: fixedPrice13, uniswapMarket: uniswapMarket13, isUniswapReversed: isUniswapReversed13, isLP: isLP13});
        if (address(this).balance == 14) return TokenConfig({sToken: sToken14, underlying: underlying14, symbolHash: symbolHash14, baseUnit: baseUnit14, priceSource: priceSource14, fixedPrice: fixedPrice14, uniswapMarket: uniswapMarket14, isUniswapReversed: isUniswapReversed14, isLP: isLP14});
        if (address(this).balance == 15) return TokenConfig({sToken: sToken15, underlying: underlying15, symbolHash: symbolHash15, baseUnit: baseUnit15, priceSource: priceSource15, fixedPrice: fixedPrice15, uniswapMarket: uniswapMarket15, isUniswapReversed: isUniswapReversed15, isLP: isLP15});
        if (address(this).balance == 16) return TokenConfig({sToken: sToken16, underlying: underlying16, symbolHash: symbolHash16, baseUnit: baseUnit16, priceSource: priceSource16, fixedPrice: fixedPrice16, uniswapMarket: uniswapMarket16, isUniswapReversed: isUniswapReversed16, isLP: isLP16});
        if (address(this).balance == 17) return TokenConfig({sToken: sToken17, underlying: underlying17, symbolHash: symbolHash17, baseUnit: baseUnit17, priceSource: priceSource17, fixedPrice: fixedPrice17, uniswapMarket: uniswapMarket17, isUniswapReversed: isUniswapReversed17, isLP: isLP17});
        if (address(this).balance == 18) return TokenConfig({sToken: sToken18, underlying: underlying18, symbolHash: symbolHash18, baseUnit: baseUnit18, priceSource: priceSource18, fixedPrice: fixedPrice18, uniswapMarket: uniswapMarket18, isUniswapReversed: isUniswapReversed18, isLP: isLP18});
        if (address(this).balance == 19) return TokenConfig({sToken: sToken19, underlying: underlying19, symbolHash: symbolHash19, baseUnit: baseUnit19, priceSource: priceSource19, fixedPrice: fixedPrice19, uniswapMarket: uniswapMarket19, isUniswapReversed: isUniswapReversed19, isLP: isLP19});
    }






    function getTokenConfigBySymbol(string memory symbol) public view returns (TokenConfig memory) {
        return getTokenConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
    }






    function getTokenConfigBySymbolHash(bytes32 symbolHash) public view returns (TokenConfig memory) {
        uint index = getSymbolHashIndex(symbolHash);
        if (index != uint(- 1)) {
            return getTokenConfig(index);
        }

        revert("token config not found");
    }







    function getTokenConfigByCToken(address sToken) public view returns (TokenConfig memory) {
        uint index = getCTokenIndex(sToken);
        if (index != uint(- 1)) {
            return getTokenConfig(index);
        }

        return getTokenConfigByUnderlying(CErc20(sToken).underlying());
    }






    function getTokenConfigByUnderlying(address underlying) public view returns (TokenConfig memory) {
        uint index = getUnderlyingIndex(underlying);
        if (index != uint(- 1)) {
            return getTokenConfig(index);
        }

        revert("token config not found");
    }
}







library FixedPoint {


    struct uq112x112 {
        uint224 _x;
    }



    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << 112) / denominator);
    }


    function decode112with18(uq112x112 memory self) internal pure returns (uint) {





        return uint(self._x) / 5192296858534827;
    }
}


library UniswapV2OracleLibrary {
    using FixedPoint for *;


    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }


    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();


        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {

            uint32 timeElapsed = blockTimestamp - blockTimestampLast;


            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;

            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function totalSupply() external view returns (uint);

    function token0() external view returns (address);

    function token1() external view returns (address);
}


    struct Observation {
        uint timestamp;
        uint acc;
    }

contract CheesePriceOracle is UniswapConfig {
    using FixedPoint for *;


    uint public constant ethBaseUnit = 1e18;


    uint public constant expScale = 1e18;


    address public immutable admin;


    uint public immutable anchorPeriod;


    mapping(bytes32 => uint) public prices;


    mapping(bytes32 => Observation) public oldObservations;


    mapping(bytes32 => Observation) public newObservations;


    event PriceGuarded(string symbol, uint reporter, uint anchor);


    event PriceUpdated(string symbol, uint price);


    event AnchorPriceUpdated(string symbol, uint anchorPrice, uint oldTimestamp, uint newTimestamp);


    event UniswapWindowUpdated(bytes32 indexed symbolHash, uint oldTimestamp, uint newTimestamp, uint oldPrice, uint newPrice);

    bytes32 constant ethHash = keccak256(abi.encodePacked("ETH"));

    constructor(uint anchorPeriod_,
        address[] memory sTokens_, address[] memory underlyings_,
        bytes32[] memory symbolHashs_, uint256[] memory baseUints_,
        PriceSource[] memory priceSources_, uint256[] memory fixedPrices_,
        address[] memory uniswapMarkets_, bool[] memory isUniswapReverseds_,
        bool[] memory isLP_)
    UniswapConfig(sTokens_, underlyings_, symbolHashs_, baseUints_, priceSources_, fixedPrices_, uniswapMarkets_,
        isUniswapReverseds_, isLP_) public {
        admin = msg.sender;

        anchorPeriod = anchorPeriod_;

        for (uint i = 0; i < sTokens_.length; i++) {
            TokenConfig memory config = TokenConfig({ sToken : sTokens_[i], underlying : underlyings_[i],
            symbolHash : symbolHashs_[i], baseUnit : baseUints_[i],
            priceSource: priceSources_[i], fixedPrice: fixedPrices_[i],
            uniswapMarket : uniswapMarkets_[i], isUniswapReversed : isUniswapReverseds_[i],
            isLP : isLP_[i]});
            require(config.baseUnit > 0, "baseUnit must be greater than zero");
            address uniswapMarket = config.uniswapMarket;
            if (config.priceSource == PriceSource.REPORTER) {
                require(uniswapMarket != address(0), "reported prices must have an anchor");
                bytes32 symbolHash = config.symbolHash;
                uint cumulativePrice = currentCumulativePrice(config);
                oldObservations[symbolHash].timestamp = block.timestamp;
                newObservations[symbolHash].timestamp = block.timestamp;
                oldObservations[symbolHash].acc = cumulativePrice;
                newObservations[symbolHash].acc = cumulativePrice;
                emit UniswapWindowUpdated(symbolHash, block.timestamp, block.timestamp, cumulativePrice, cumulativePrice);
            } else {
                require(uniswapMarket == address(0), "only reported prices utilize an anchor");
            }
        }
    }






    function price(string memory symbol) external view returns (uint) {
        TokenConfig memory config = getTokenConfigBySymbol(symbol);
        return priceInternal(config);
    }

    function priceInternal(TokenConfig memory config) internal view returns (uint) {
        if (config.priceSource == PriceSource.REPORTER) return prices[config.symbolHash];
        if (config.priceSource == PriceSource.FIXED_USD) return config.fixedPrice;
        if (config.priceSource == PriceSource.FIXED_ETH) {
            uint usdPerEth = prices[ethHash];
            require(usdPerEth > 0, "ETH price not set, cannot convert to dollars");
            return mul(usdPerEth, config.fixedPrice) / ethBaseUnit;
        }
    }







    function getUnderlyingPrice(address sToken) external view returns (uint) {
        TokenConfig memory config = getTokenConfigByCToken(sToken);


        return mul(1e30, priceInternal(config)) / config.baseUnit;
    }

    function refresh(string[] calldata symbols) external {
        uint ethPrice = fetchEthPrice();


        for (uint i = 0; i < symbols.length; i++) {
            postPriceInternal(symbols[i], ethPrice);
        }
    }

    function postPriceInternal(string memory symbol, uint ethPrice) internal {
        TokenConfig memory config = getTokenConfigBySymbol(symbol);

        bytes32 symbolHash = keccak256(abi.encodePacked(symbol));
        uint anchorPrice;
        if (symbolHash == ethHash) {
            anchorPrice = ethPrice;
        } else if (config.isLP) {
            anchorPrice = fetchLPAnchorPrice(symbol, config, ethPrice);
        } else {
            anchorPrice = fetchAnchorPrice(symbol, config, ethPrice);
        }
        prices[symbolHash] = anchorPrice;
        emit PriceUpdated(symbol, anchorPrice);
    }




    function currentCumulativePrice(TokenConfig memory config) internal view returns (uint) {
        (uint cumulativePrice0, uint cumulativePrice1,) = UniswapV2OracleLibrary.currentCumulativePrices(config.uniswapMarket);
        if (config.isUniswapReversed) {
            return cumulativePrice1;
        } else {
            return cumulativePrice0;
        }
    }





    function fetchEthPrice() internal returns (uint) {
        return fetchAnchorPrice("ETH", getTokenConfigBySymbolHash(ethHash), ethBaseUnit);
    }





    function fetchLPAnchorPrice(string memory symbol, TokenConfig memory config, uint ethPrice) internal virtual returns (uint) {

        ERC20 wETH = ERC20(getTokenConfigBySymbolHash(ethHash).underlying);
        uint wEthBalance = wETH.balanceOf(config.uniswapMarket);
        uint pairBalance = mul(wEthBalance, 2);
        uint totalValue = mul(pairBalance, ethPrice);

        IUniswapV2Pair pair = IUniswapV2Pair(config.uniswapMarket);
        uint anchorPrice = totalValue / pair.totalSupply();

        return anchorPrice;
    }





    function fetchAnchorPrice(string memory symbol, TokenConfig memory config, uint conversionFactor) internal virtual returns (uint) {
        (uint nowCumulativePrice, uint oldCumulativePrice, uint oldTimestamp) = pokeWindowValues(config);


        require(block.timestamp > oldTimestamp, "now must come after before");
        uint timeElapsed = block.timestamp - oldTimestamp;



        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(uint224((nowCumulativePrice - oldCumulativePrice) / timeElapsed));
        uint rawUniswapPriceMantissa = priceAverage.decode112with18();
        uint unscaledPriceMantissa = mul(rawUniswapPriceMantissa, conversionFactor);
        uint anchorPrice;



        if (config.isUniswapReversed) {

            anchorPrice = unscaledPriceMantissa / config.baseUnit;
        }else {
            anchorPrice = mul(unscaledPriceMantissa, config.baseUnit) / ethBaseUnit / expScale;
        }
        emit AnchorPriceUpdated(symbol, anchorPrice, oldTimestamp, block.timestamp);

        return anchorPrice;
    }





    function pokeWindowValues(TokenConfig memory config) internal returns (uint, uint, uint) {
        bytes32 symbolHash = config.symbolHash;
        uint cumulativePrice = currentCumulativePrice(config);

        Observation memory newObservation = newObservations[symbolHash];


        uint timeElapsed = block.timestamp - newObservation.timestamp;
        if (timeElapsed >= anchorPeriod) {
            oldObservations[symbolHash].timestamp = newObservation.timestamp;
            oldObservations[symbolHash].acc = newObservation.acc;

            newObservations[symbolHash].timestamp = block.timestamp;
            newObservations[symbolHash].acc = cumulativePrice;
            emit UniswapWindowUpdated(config.symbolHash, newObservation.timestamp, block.timestamp, newObservation.acc, cumulativePrice);
        }
        return (cumulativePrice, oldObservations[symbolHash].acc, oldObservations[symbolHash].timestamp);
    }










    function source(bytes memory message, bytes memory signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = abi.decode(signature, (bytes32, bytes32, uint8));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(message)));
        return ecrecover(hash, v, r, s);
    }


    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) return 0;
        uint c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}
