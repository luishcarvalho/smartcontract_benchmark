

pragma solidity 0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./aave/ILendingPoolAddressesProvider.sol";
import "./aave/ILendingPool.sol";
import "./aave/AToken.sol";




contract GoodGhosting is Ownable, Pausable {
    using SafeMath for uint256;


    bool public redeemed;

    uint256 public totalGameInterest;

    uint256 public totalGamePrincipal;

    uint256 public adminFeeAmount;

    bool public adminWithdraw;

    uint256 public totalIncentiveAmount = 0;

    uint256 public activePlayersCount = 0;


    IERC20 public immutable daiToken;

    AToken public immutable adaiToken;

    ILendingPoolAddressesProvider public immutable lendingPoolAddressProvider;

    ILendingPool public lendingPool;

    uint256 public immutable segmentPayment;

    uint256 public immutable lastSegment;

    uint256 public immutable firstSegmentStart;

    uint256 public immutable segmentLength;

    uint256 public immutable earlyWithdrawalFee;

    uint256 public immutable customFee;

    uint256 public immutable maxPlayersCount;

    IERC20 public immutable incentiveToken;

    struct Player {
        address addr;
        bool withdrawn;
        bool canRejoin;
        uint256 mostRecentSegmentPaid;
        uint256 amountPaid;
    }

    mapping(address => Player) public players;


    address[] public iterablePlayers;

    address[] public winners;

    event JoinedGame(address indexed player, uint256 amount);
    event Deposit(
        address indexed player,
        uint256 indexed segment,
        uint256 amount
    );
    event Withdrawal(
        address indexed player,
        uint256 amount,
        uint256 playerReward,
        uint256 playerIncentive
    );
    event FundsRedeemedFromExternalPool(
        uint256 totalAmount,
        uint256 totalGamePrincipal,
        uint256 totalGameInterest,
        uint256 rewards,
        uint256 totalIncentiveAmount
    );
    event WinnersAnnouncement(address[] winners);
    event EarlyWithdrawal(
        address indexed player,
        uint256 amount,
        uint256 totalGamePrincipal
    );
    event AdminWithdrawal(
        address indexed admin,
        uint256 totalGameInterest,
        uint256 adminFeeAmount,
        uint256 adminIncentiveAmount
    );

    modifier whenGameIsCompleted() {
        require(isGameCompleted(), "Game is not completed");
        _;
    }

    modifier whenGameIsNotCompleted() {
        require(!isGameCompleted(), "Game is already completed");
        _;
    }














    constructor(
        IERC20 _inboundCurrency,
        ILendingPoolAddressesProvider _lendingPoolAddressProvider,
        uint256 _segmentCount,
        uint256 _segmentLength,
        uint256 _segmentPayment,
        uint256 _earlyWithdrawalFee,
        uint256 _customFee,
        address _dataProvider,
        uint256 _maxPlayersCount,
        IERC20 _incentiveToken
    ) public {
        require(_customFee <= 20, "_customFee must be less than or equal to 20%");
        require(_earlyWithdrawalFee <= 10, "_earlyWithdrawalFee must be less than or equal to 10%");
        require(_earlyWithdrawalFee > 0,  "_earlyWithdrawalFee must be greater than zero");
        require(_maxPlayersCount > 0, "_maxPlayersCount must be greater than zero");
        require(address(_inboundCurrency) != address(0), "invalid _inboundCurrency address");
        require(address(_lendingPoolAddressProvider) != address(0), "invalid _lendingPoolAddressProvider address");
        require(_segmentCount > 0, "_segmentCount must be greater than zero");
        require(_segmentLength > 0, "_segmentLength must be greater than zero");
        require(_segmentPayment > 0, "_segmentPayment must be greater than zero");
        require(_dataProvider != address(0), "invalid _dataProvider address");

        firstSegmentStart = block.timestamp;
        lastSegment = _segmentCount;
        segmentLength = _segmentLength;
        segmentPayment = _segmentPayment;
        earlyWithdrawalFee = _earlyWithdrawalFee;
        customFee = _customFee;
        daiToken = _inboundCurrency;
        lendingPoolAddressProvider = _lendingPoolAddressProvider;
        AaveProtocolDataProvider dataProvider =
            AaveProtocolDataProvider(_dataProvider);

        lendingPool = ILendingPool(
            _lendingPoolAddressProvider.getLendingPool()
        );

        (address adaiTokenAddress, , ) =
            dataProvider.getReserveTokensAddresses(address(_inboundCurrency));
        adaiToken = AToken(adaiTokenAddress);
        maxPlayersCount = _maxPlayersCount;
        incentiveToken = _incentiveToken;
    }


    function pause() external onlyOwner whenNotPaused {
        _pause();
    }


    function unpause() external onlyOwner whenPaused {
        _unpause();
    }



    function adminFeeWithdraw() external virtual onlyOwner whenGameIsCompleted {
        require(redeemed, "Funds not redeemed from external pool");
        require(!adminWithdraw, "Admin has already withdrawn");
        adminWithdraw = true;



        uint256 adminIncentiveAmount = 0;
        if (winners.length == 0 && totalIncentiveAmount > 0) {
            adminIncentiveAmount = totalIncentiveAmount;
        }

        emit AdminWithdrawal(owner(), totalGameInterest, adminFeeAmount, adminIncentiveAmount);

        if (adminFeeAmount > 0) {
            require(
                IERC20(daiToken).transfer(owner(), adminFeeAmount),
                "Fail to transfer ER20 tokens to admin"
            );
        }

        if (adminIncentiveAmount > 0) {
            require(
                IERC20(incentiveToken).transfer(owner(), adminIncentiveAmount),
                "Fail to transfer ER20 incentive tokens to admin"
            );
        }
    }


    function joinGame()
        external
        virtual
        whenNotPaused
    {
        _joinGame();
    }



    function earlyWithdraw() external whenNotPaused whenGameIsNotCompleted {
        Player storage player = players[msg.sender];
        require(player.amountPaid > 0, "Player does not exist");
        require(!player.withdrawn, "Player has already withdrawn");
        player.withdrawn = true;
        activePlayersCount = activePlayersCount.sub(1);


        uint256 withdrawAmount =
            player.amountPaid.sub(
                player.amountPaid.mul(earlyWithdrawalFee).div(100)
            );

        totalGamePrincipal = totalGamePrincipal.sub(player.amountPaid);
        uint256 currentSegment = getCurrentSegment();


        if (currentSegment == 0) {
            player.canRejoin = true;
        }

        emit EarlyWithdrawal(msg.sender, withdrawAmount, totalGamePrincipal);

        lendingPool.withdraw(address(daiToken), withdrawAmount, address(this));
        require(
            IERC20(daiToken).transfer(msg.sender, withdrawAmount),
            "Fail to transfer ERC20 tokens on early withdraw"
        );
    }


    function withdraw() external virtual {
        Player storage player = players[msg.sender];
        require(player.amountPaid > 0, "Player does not exist");
        require(!player.withdrawn, "Player has already withdrawn");
        player.withdrawn = true;


        if (!redeemed) {
            redeemFromExternalPool();
        }

        uint256 payout = player.amountPaid;
        uint256 playerIncentive = 0;
        if (player.mostRecentSegmentPaid == lastSegment.sub(1)) {

            payout = payout.add(totalGameInterest.div(winners.length));

            if (totalIncentiveAmount > 0) {
                playerIncentive = totalIncentiveAmount.div(winners.length);
            }
        }
        emit Withdrawal(msg.sender, payout, 0, playerIncentive);

        require(
            IERC20(daiToken).transfer(msg.sender, payout),
            "Fail to transfer ERC20 tokens on withdraw"
        );

        if (playerIncentive > 0) {
            require(
                IERC20(incentiveToken).transfer(msg.sender, playerIncentive),
                "Fail to transfer ERC20 incentive tokens on withdraw"
            );
        }
    }


    function makeDeposit() external whenNotPaused {
        require(
            !players[msg.sender].withdrawn,
            "Player already withdraw from game"
        );

        require(
            players[msg.sender].addr == msg.sender,
            "Sender is not a player"
        );

        uint256 currentSegment = getCurrentSegment();







        require(
            currentSegment > 0 && currentSegment < lastSegment,
            "Deposit available only between segment 1 and segment n-1 (penultimate)"
        );


        require(
            players[msg.sender].mostRecentSegmentPaid != currentSegment,
            "Player already paid current segment"
        );


        require(
            players[msg.sender].mostRecentSegmentPaid == currentSegment.sub(1),
            "Player didn't pay the previous segment - game over!"
        );


        if (currentSegment == lastSegment.sub(1)) {
            winners.push(msg.sender);
        }

        emit Deposit(msg.sender, currentSegment, segmentPayment);
        _transferDaiToContract();
    }



    function getNumberOfPlayers() external view returns (uint256) {
        return iterablePlayers.length;
    }



    function redeemFromExternalPool() public virtual whenGameIsCompleted {
        require(!redeemed, "Redeem operation already happened for the game");
        redeemed = true;

        if (adaiToken.balanceOf(address(this)) > 0) {
            lendingPool.withdraw(
                address(daiToken),
                type(uint256).max,
                address(this)
            );
        }
        uint256 totalBalance = IERC20(daiToken).balanceOf(address(this));

        if (address(incentiveToken) != address(0)) {
            totalIncentiveAmount = IERC20(incentiveToken).balanceOf(address(this));
        }


        uint256 grossInterest = 0;




        if (totalBalance > totalGamePrincipal) {
            grossInterest = totalBalance.sub(totalGamePrincipal);
        }


        uint256 _adminFeeAmount;
        if (customFee > 0) {
            _adminFeeAmount = (grossInterest.mul(customFee)).div(100);
            totalGameInterest = grossInterest.sub(_adminFeeAmount);
        } else {
            _adminFeeAmount = 0;
            totalGameInterest = grossInterest;
        }


        if (winners.length == 0) {
            adminFeeAmount = grossInterest;
        } else {
            adminFeeAmount = _adminFeeAmount;
        }

        emit FundsRedeemedFromExternalPool(
            totalBalance,
            totalGamePrincipal,
            totalGameInterest,
            0,
            totalIncentiveAmount
        );
        emit WinnersAnnouncement(winners);
    }



    function getCurrentSegment() public view returns (uint256) {
        return block.timestamp.sub(firstSegmentStart).div(segmentLength);
    }



    function isGameCompleted() public view returns (bool) {

        return getCurrentSegment() > lastSegment;
    }





    function _transferDaiToContract() internal {
        require(
            daiToken.allowance(msg.sender, address(this)) >= segmentPayment,
            "You need to have allowance to do transfer DAI on the smart contract"
        );

        uint256 currentSegment = getCurrentSegment();
        players[msg.sender].mostRecentSegmentPaid = currentSegment;
        players[msg.sender].amountPaid = players[msg.sender].amountPaid.add(
            segmentPayment
        );
        totalGamePrincipal = totalGamePrincipal.add(segmentPayment);
        require(
            daiToken.transferFrom(msg.sender, address(this), segmentPayment),
            "Transfer failed"
        );



        uint256 contractBalance = daiToken.balanceOf(address(this));
        require(
            daiToken.approve(address(lendingPool), contractBalance),
            "Fail to approve allowance to lending pool"
        );

        lendingPool.deposit(address(daiToken), contractBalance, address(this), 155);
    }


    function _joinGame() internal {
        require(getCurrentSegment() == 0, "Game has already started");
        require(
            players[msg.sender].addr != msg.sender ||
                players[msg.sender].canRejoin,
            "Cannot join the game more than once"
        );

        activePlayersCount = activePlayersCount.add(1);
        require(activePlayersCount <= maxPlayersCount, "Reached max quantity of players allowed");

        bool canRejoin = players[msg.sender].canRejoin;
        Player memory newPlayer =
            Player({
                addr: msg.sender,
                mostRecentSegmentPaid: 0,
                amountPaid: 0,
                withdrawn: false,
                canRejoin: false
            });
        players[msg.sender] = newPlayer;
        if (!canRejoin) {
            iterablePlayers.push(msg.sender);
        }
        emit JoinedGame(msg.sender, segmentPayment);
        _transferDaiToContract();
    }
}
