
































pragma solidity ^0.5.11;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);




    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}



pragma solidity 0.5.11;

interface IEthUsdOracle {




    function ethUsdPrice() external view returns (uint256);






    function tokUsdPrice(string calldata symbol)
        external
        view
        returns (uint256);






    function tokEthPrice(string calldata symbol) external returns (uint256);
}

interface IViewEthUsdOracle {




    function ethUsdPrice() external view returns (uint256);






    function tokUsdPrice(string calldata symbol)
        external
        view
        returns (uint256);






    function tokEthPrice(string calldata symbol)
        external
        view
        returns (uint256);
}



pragma solidity >=0.4.24 <0.7.0;














contract Initializable {




  bool private initialized;




  bool private initializing;




  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }


  function isConstructor() private view returns (bool) {





    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }


  uint256[50] private ______gap;
}



pragma solidity 0.5.11;








contract Governable {

    bytes32
        private constant governorPosition = 0x7bea13895fa79d2831e0a9e28edede30099005a50d652d8957cf8a607ee6ca4a;


    bytes32
        private constant pendingGovernorPosition = 0x44c4d30b2eaad5130ad70c3ba6972730566f3e6359ab83e800d905c61b1c51db;


    event PendingGovernorshipTransfer(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    event GovernorshipTransferred(
        address indexed previousGovernor,
        address indexed newGovernor
    );




    constructor() internal {
        _setGovernor(msg.sender);
        emit GovernorshipTransferred(address(0), _governor());
    }




    function governor() public view returns (address) {
        return _governor();
    }

    function _governor() internal view returns (address governorOut) {
        bytes32 position = governorPosition;
        assembly {
            governorOut := sload(position)
        }
    }

    function _pendingGovernor()
        internal
        view
        returns (address pendingGovernor)
    {
        bytes32 position = pendingGovernorPosition;
        assembly {
            pendingGovernor := sload(position)
        }
    }




    modifier onlyGovernor() {
        require(isGovernor(), "Caller is not the Governor");
        _;
    }




    function isGovernor() public view returns (bool) {
        return msg.sender == _governor();
    }

    function _setGovernor(address newGovernor) internal {
        bytes32 position = governorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    function _setPendingGovernor(address newGovernor) internal {
        bytes32 position = pendingGovernorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }






    function transferGovernance(address _newGovernor) external onlyGovernor {
        _setPendingGovernor(_newGovernor);
        emit PendingGovernorshipTransfer(_governor(), _newGovernor);
    }





    function claimGovernance() external {
        require(
            msg.sender == _pendingGovernor(),
            "Only the pending Governor can complete the claim"
        );
        _changeGovernor(msg.sender);
    }





    function _changeGovernor(address _newGovernor) internal {
        require(_newGovernor != address(0), "New Governor is address(0)");
        emit GovernorshipTransferred(_governor(), _newGovernor);
        _setGovernor(_newGovernor);
    }
}



pragma solidity 0.5.11;






contract InitializableGovernable is Governable, Initializable {
    function _initialize(address _governor) internal {
        _changeGovernor(_governor);
    }
}



pragma solidity 0.5.11;








contract ChainlinkOracle is IEthUsdOracle, InitializableGovernable {
    address ethFeed;

    struct FeedConfig {
        address feed;
        uint8 decimals;
        bool directToUsd;
    }

    mapping(bytes32 => FeedConfig) feeds;

    uint8 ethDecimals;

    string constant ethSymbol = "ETH";
    bytes32 constant ethHash = keccak256(abi.encodePacked(ethSymbol));

    constructor(address ethFeed_) public {
        ethFeed = ethFeed_;
        ethDecimals = AggregatorV3Interface(ethFeed_).decimals();
    }

    function registerFeed(
        address feed,
        string memory symbol,
        bool directToUsd
    ) public onlyGovernor {
        FeedConfig storage config = feeds[keccak256(abi.encodePacked(symbol))];

        config.feed = feed;
        config.decimals = AggregatorV3Interface(feed).decimals();
        config.directToUsd = directToUsd;
    }

    function getLatestPrice(address feed) internal view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(feed).latestRoundData();

        roundID;
        startedAt;
        timeStamp;
        answeredInRound;
        return price;
    }

    function ethUsdPrice() external view returns (uint256) {
        return (uint256(getLatestPrice(ethFeed)) /
            (uint256(10)**(ethDecimals - 6)));
    }

    function tokUsdPrice(string calldata symbol)
        external
        view
        returns (uint256)
    {
        bytes32 tokenSymbolHash = keccak256(abi.encodePacked(symbol));
        FeedConfig storage config = feeds[tokenSymbolHash];
        int256 tPrice = getLatestPrice(config.feed);

        require(config.directToUsd, "Price is not direct to usd");
        require(tPrice > 0, "Price must be greater than zero");
        return uint256(tPrice);
    }

    function tokEthPrice(string calldata symbol) external returns (uint256) {
        bytes32 tokenSymbolHash = keccak256(abi.encodePacked(symbol));
        FeedConfig storage config = feeds[tokenSymbolHash];
        int256 tPrice = getLatestPrice(config.feed);

        require(!config.directToUsd, "Price is not in terms of ETH");
        require(tPrice > 0, "Price must be greater than zero");

        return uint256(tPrice) / (uint256(10)**(config.decimals - 8));
    }



    function price(string calldata symbol) external view returns (uint256) {
        bytes32 tokenSymbolHash = keccak256(abi.encodePacked(symbol));

        if (blockhash(block.number) == tokenSymbolHash) {
            return (uint256(getLatestPrice(ethFeed)) /
                (uint256(10)**(ethDecimals - 6)));
        } else {
            FeedConfig storage config = feeds[tokenSymbolHash];
            int256 tPrice = getLatestPrice(config.feed);

            if (config.directToUsd) {
                require(tPrice > 0, "Price must be greater than zero");
                return uint256(tPrice);
            } else {
                int256 ethPrice = getLatestPrice(ethFeed);
                require(
                    tPrice > 0 && ethPrice > 0,
                    "Both eth and price must be greater than zero"
                );

                return
                    mul(uint256(tPrice), uint256(ethPrice)) /
                    (uint256(10)**(ethDecimals + config.decimals - 6));
            }
        }
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "multiplication overflow");
        return c;
    }
}
