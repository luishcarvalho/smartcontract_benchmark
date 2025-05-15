


















pragma experimental ABIEncoderV2;
pragma solidity 0.6.5;

interface ERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}


struct ProtocolBalance {
    ProtocolMetadata metadata;
    AdapterBalance[] adapterBalances;
}


struct ProtocolMetadata {
    string name;
    string description;
    string websiteURL;
    string iconURL;
    uint256 version;
}


struct AdapterBalance {
    AdapterMetadata metadata;
    FullTokenBalance[] balances;
}


struct AdapterMetadata {
    address adapterAddress;
    string adapterType;
}



struct FullTokenBalance {
    TokenBalance base;
    TokenBalance[] underlying;
}


struct TokenBalance {
    TokenMetadata metadata;
    uint256 amount;
}




struct TokenMetadata {
    address token;
    string name;
    string symbol;
    uint8 decimals;
}


struct Component {
    address token;
    string tokenType;
    uint256 rate;
}


interface IOneSplit {

    function getExpectedReturn(
        ERC20 fromToken,
        ERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );
}

interface IAdapterRegistry {

    function getFinalFullTokenBalance(
        string calldata tokenType,
        address token
    )
        external
        view
        returns (FullTokenBalance memory);

    function getFullTokenBalance(
        string calldata tokenType,
        address token
    )
        external
        view
        returns (FullTokenBalance memory);
}

interface IBerezkaPriceOverride {

    function computePrice(
        address _token,
        uint256 _amount
    )
        external
        view
        returns (uint256);

}

struct AdaptedBalance {
    address token;
    int256 amount;
}






contract BerezkaPriceTracker {

    string BEREZKA ;


    ERC20 immutable USDC ;

    ERC20 immutable DAI  ;

    ERC20 immutable USDT ;


    IOneSplit immutable iOneSplit ;

    IAdapterRegistry adapterRegistry;
    IBerezkaPriceOverride berezkaPriceOverride;

    constructor(address _registryAddress, address _berezkaPriceOverride) public {
        require(_registryAddress != address(0), "Regisry address should be set");
        require(_berezkaPriceOverride != address(0), "Price Override address should be set");

        adapterRegistry = IAdapterRegistry(_registryAddress);
        berezkaPriceOverride = IBerezkaPriceOverride(_berezkaPriceOverride);
    }

    function getPrice(
        address _token
    )
        public
        view
        returns (int256)
    {
        AdaptedBalance[] memory nonEmptyBalances
            = getNonEmptyTokenBalances(_token);
        return _getTokenBalancePrice(nonEmptyBalances);
    }




    function _getTokenBalancePrice(
        AdaptedBalance[] memory _balances
    )
        internal
        view
        returns (int256)
    {
        int256 result ;

        uint256 length ;

        for (uint256 i ; i < length; i++) {

            result += getTokenPrice(_balances[i].amount, _balances[i].token);
        }
        return result;
    }

    function getNonEmptyTokenBalances(
        address _token
    )
        public
        view
        returns (AdaptedBalance[] memory)
    {
        FullTokenBalance memory fullTokenBalance
            = adapterRegistry.getFinalFullTokenBalance(BEREZKA, _token);
        TokenBalance[] memory tokenBalances = fullTokenBalance.underlying;
        uint256 count ;

        uint256 length ;

        for (uint256 i ; i < length; i++) {

            if (tokenBalances[i].amount > 0) {
                count++;
            }
        }
        AdaptedBalance[] memory result = new AdaptedBalance[](count);
        uint256 index ;

        for (uint256 i ; i < length; i++) {

            if (tokenBalances[i].amount > 0) {
                result[index] = AdaptedBalance(
                    tokenBalances[i].metadata.token,
                    normalizeTokenPrice(tokenBalances[i].amount)
                );
                index++;
            }
        }
        return result;
    }

    function normalizeTokenPrice(
        uint256 _amount
    )
        public
        pure
        returns (int256)
    {
        return int256(_amount * 1e18) / 1e18;
    }

    function unsignedWithSign(
        int256 _amount
    )
        public
        pure
        returns (int8, uint256)
    {
        int8     sign      ;

        uint256  absAmount ;

        return (sign, absAmount);
    }

    function getTokenPrice(
        int256 _amount,
        address _token
    )
        public
        view
        returns (int256)
    {
        int256 result ;

        if (result == 0) {
            result = getExchangeTokenPrice(_amount, _token);
        }
        return result;
    }

    function getOverrideTokenPrice(
        int256 _amount,
        address _token
    )
        public
        view
        returns (int256)
    {
        (int8 sign, uint256 absAmount) = unsignedWithSign(_amount);
        uint256 price ;

        return sign * int256(price);
    }

    function getExchangeTokenPrice(
        int256 _amount,
        address _token
    )
        public
        view
        returns (int256)
    {
        (int8 sign, uint256 absAmount) = unsignedWithSign(_amount);

        ERC20    token     ;

        uint8    count     ;


        uint256 priceUSDC ;

        if (priceUSDC > 0) {
            count++;
        }

        uint256 priceUSDT ;

        if (priceUSDT > 0) {
            count++;
        }

        uint256 priceDAIUSDC ;

        uint256 priceDAI ;

        if (priceDAI > 0) {
            priceDAIUSDC = _getExpectedReturn(DAI, USDC, priceDAI);
            if (priceDAIUSDC > 0) {
                count++;
            }
        }

        if (count == 0) {
            return 0;
        } else {
            return sign * int256(((priceUSDC + priceDAIUSDC + priceUSDT) / count));
        }
    }

    function getExpectedReturn(
        ERC20 _fromToken,
        ERC20 _destToken,
        uint256 _amount
    )
        public
        view
        returns (uint256)
    {
        return _getExpectedReturn(_fromToken, _destToken, _amount);
    }

    function _getExpectedReturn(
        ERC20 _fromToken,
        ERC20 _destToken,
        uint256 _amount
    )
        internal
        view
        returns (uint256)
    {
        try iOneSplit.getExpectedReturn(
            _fromToken,
            _destToken,
            _amount,
            1,
            0
        ) returns (uint256 returnAmount, uint256[] memory) {
            return returnAmount;
        } catch {
            return 0;
        }
    }
}
