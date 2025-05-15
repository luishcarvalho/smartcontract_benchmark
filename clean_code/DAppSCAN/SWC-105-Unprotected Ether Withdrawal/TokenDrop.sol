
pragma solidity >=0.7.0 <0.8.0;


import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";


import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@pooltogether/fixed-point/contracts/FixedPoint.sol";





import "./libraries/ExtendedSafeCast.sol";







contract TokenDrop is Initializable {



    using SafeMath for uint256;
    using ExtendedSafeCast for uint256;





    IERC20Upgradeable public asset;


    IERC20Upgradeable public measure;


    uint112 public exchangeRateMantissa;


    uint112 public totalUnclaimed;


    uint32 public lastDripTimestamp;


    address public factory;




    event Dripped(uint256 newTokens);

    event Deposited(address indexed user, uint256 amount);

    event Claimed(address indexed user, uint256 newTokens);




    struct UserState {
        uint128 lastExchangeRateMantissa;
        uint256 balance;
    }




    mapping(address => UserState) public userStates;








    function initialize(address _measure, address _asset) external {
        measure = IERC20Upgradeable(_measure);
        asset = IERC20Upgradeable(_asset);


        factory = msg.sender;
    }











    function beforeTokenTransfer(
        address from,
        address to,
        address token
    ) external {

        if (token == address(measure)) {
            drop();


            _captureNewTokensForUser(to);


            if (from != address(0)) {
                _captureNewTokensForUser(from);
            }
        }
    }






    function addAssetToken(uint256 amount) external returns (bool) {

        asset.transferFrom(msg.sender, address(this), amount);


        drop();


        return true;
    }







    function claim(address user) external returns (uint256) {
        drop();
        _captureNewTokensForUser(user);
        uint256 balance = userStates[user].balance;
        userStates[user].balance = 0;
        totalUnclaimed = uint256(totalUnclaimed).sub(balance).toUint112();


        asset.transfer(user, balance);


        emit Claimed(user, balance);

        return balance;
    }








    function drop() public returns (uint256) {
        uint256 assetTotalSupply = asset.balanceOf(address(this));
        uint256 newTokens = assetTotalSupply.sub(totalUnclaimed);


        if (newTokens > 0) {

            uint256 measureTotalSupply = measure.totalSupply();


            if (measureTotalSupply > 0) {
                uint256 indexDeltaMantissa =
                    FixedPoint.calculateMantissa(newTokens, measureTotalSupply);
                uint256 nextExchangeRateMantissa =
                    uint256(exchangeRateMantissa).add(indexDeltaMantissa);

                exchangeRateMantissa = nextExchangeRateMantissa.toUint112();
                totalUnclaimed = uint256(totalUnclaimed)
                    .add(newTokens)
                    .toUint112();
            }

            emit Dripped(newTokens);
        }

        return newTokens;
    }











    function _captureNewTokensForUser(address user) private returns (uint128) {
        UserState storage userState = userStates[user];
        if (exchangeRateMantissa == userState.lastExchangeRateMantissa) {

            return 0;
        }
        uint256 deltaExchangeRateMantissa =
            uint256(exchangeRateMantissa).sub(
                userState.lastExchangeRateMantissa
            );
        uint256 userMeasureBalance = measure.balanceOf(user);
        uint128 newTokens =
            FixedPoint
                .multiplyUintByMantissa(
                userMeasureBalance,
                deltaExchangeRateMantissa
            )
                .toUint128();

        userStates[user] = UserState({
            lastExchangeRateMantissa: exchangeRateMantissa,
            balance: uint256(userState.balance).add(newTokens).toUint128()
        });

        return newTokens;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return true;
    }
}
