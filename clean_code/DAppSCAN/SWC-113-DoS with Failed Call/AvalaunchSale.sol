
pragma solidity 0.6.12;

import "../interfaces/IAdmin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/ISalesFactory.sol";
import "../interfaces/IAllocationStaking.sol";

contract AvalaunchSale {

    using ECDSA for bytes32;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    IAllocationStaking public allocationStakingContract;

    ISalesFactory public factory;


    IAdmin public admin;

    struct Sale {

        IERC20 token;

        bool isCreated;

        bool earningsWithdrawn;

        bool tokensDeposited;

        address saleOwner;

        uint256 tokenPriceInAVAX;

        uint256 amountOfTokensToSell;

        uint256 totalTokensSold;

        uint256 totalAVAXRaised;

        uint256 saleEnd;

        uint256 tokensUnlockTime;
    }


    struct Participation {
        uint256 amountBought;
        uint256 amountAVAXPaid;
        uint256 timeParticipated;
        uint256 roundId;
        bool [] isPortionWithdrawn;
    }


    struct Round {
        uint startTime;
        uint maxParticipation;
    }

    struct Registration {
        uint256 registrationTimeStarts;
        uint256 registrationTimeEnds;
        uint256 numberOfRegistrants;
    }


    Sale public sale;


    Registration public registration;


    uint256 public numberOfParticipants;

    uint256 [] public roundIds;

    mapping (uint256 => Round) public roundIdToRound;

    mapping (address => Participation) public userToParticipation;

    mapping (address => uint256) public addressToRoundRegisteredFor;

    mapping (address => bool) public isParticipated;

    uint256 public constant one = 10**18;

    uint256 [] public vestingPortionsUnlockTime;

    uint256 [] public vestingPercentPerPortion;



    modifier onlySaleOwner {
        require(msg.sender == sale.saleOwner, 'OnlySaleOwner:: Restricted');
        _;
    }

    modifier onlyAdmin {
        require(admin.isAdmin(msg.sender), "Only admin can call this function.");
        _;
    }


    event TokensSold(address user, uint256 amount);
    event UserRegistered(address user, uint256 roundId);
    event TokenPriceSet(uint256 newPrice);
    event MaxParticipationSet(uint256 roundId, uint256 maxParticipation);
    event TokensWithdrawn(address user, uint256 amount);
    event SaleCreated(address saleOwner, uint256 tokenPriceInAVAX, uint256 amountOfTokensToSell,
        uint256 saleEnd, uint256 tokensUnlockTime);
    event RegistrationTimeSet(uint256 registrationTimeStarts, uint256 registrationTimeEnds);
    event RoundAdded(uint256 roundId, uint256 startTime, uint256 maxParticipation);

    constructor(address _admin, address _allocationStaking) public {
        require(_admin != address(0));
        require(_allocationStaking != address(0));
        admin = IAdmin(_admin);
        factory = ISalesFactory(msg.sender);
        allocationStakingContract = IAllocationStaking(_allocationStaking);
    }


    function setVestingParams(uint256 [] memory _unlockingTimes, uint256 [] memory _percents)
    external
    onlyAdmin
    {
        require(vestingPercentPerPortion.length == 0 && vestingPortionsUnlockTime.length == 0);
        require(_unlockingTimes.length == _percents.length);

        for(uint256 i = 0; i < _unlockingTimes.length; i++) {
            vestingPortionsUnlockTime.push(_unlockingTimes[i]);
            vestingPercentPerPortion.push(_percents[i]);
        }

    }


    function setSaleParams(
        address _token,
        address _saleOwner,
        uint256 _tokenPriceInAVAX,
        uint256 _amountOfTokensToSell,
        uint256 _saleEnd,
        uint256 _tokensUnlockTime
    )
    external
    onlyAdmin
    {
        require(!sale.isCreated, "setSaleParams: Sale is already created.");
        require(_token != address(0), "setSaleParams: Token address can not be 0.");
        require(_saleOwner != address(0), "setSaleParams: Sale owner address can not be 0.");
        require(_tokenPriceInAVAX != 0 && _amountOfTokensToSell != 0 && _saleEnd > block.timestamp &&
            _tokensUnlockTime > block.timestamp, "setSaleParams: Bad input");


        sale.token = IERC20(_token);
        sale.isCreated = true;
        sale.saleOwner = _saleOwner;
        sale.tokenPriceInAVAX = _tokenPriceInAVAX;
        sale.amountOfTokensToSell = _amountOfTokensToSell;
        sale.saleEnd = _saleEnd;
        sale.tokensUnlockTime = _tokensUnlockTime;


        factory.setSaleOwnerAndToken(sale.saleOwner, address(sale.token));


        emit SaleCreated(sale.saleOwner, sale.tokenPriceInAVAX, sale.amountOfTokensToSell, sale.saleEnd, sale.tokensUnlockTime);
    }


    function setRegistrationTime(
        uint256 _registrationTimeStarts,
        uint256 _registrationTimeEnds
    )
    external
    onlyAdmin
    {
        require(sale.isCreated == true);
        require(registration.registrationTimeStarts == 0);
        require(_registrationTimeStarts >= block.timestamp && _registrationTimeEnds > _registrationTimeStarts);
        require(_registrationTimeEnds < sale.saleEnd);

        if (roundIds.length > 0) {
            require(_registrationTimeEnds < roundIdToRound[roundIds[0]].startTime);
        }

        registration.registrationTimeStarts = _registrationTimeStarts;
        registration.registrationTimeEnds = _registrationTimeEnds;

        emit RegistrationTimeSet(registration.registrationTimeStarts, registration.registrationTimeEnds);
    }

    function setRounds(
        uint256[] calldata startTimes,
        uint256[] calldata maxParticipations
    )
    external
    onlyAdmin
    {
        require(sale.isCreated == true);
        require(startTimes.length == maxParticipations.length, "setRounds: Bad input.");
        require(roundIds.length == 0, "setRounds: Rounds are already");
        require(startTimes.length > 0);

        uint256 lastTimestamp = 0;
        for(uint i = 0; i < startTimes.length; i++) {
            require(startTimes[i] > registration.registrationTimeEnds);
            require(startTimes[i] < sale.saleEnd);
            require(startTimes[i] >= block.timestamp);
            require(maxParticipations[i] > 0);
            require(startTimes[i] > lastTimestamp);
            lastTimestamp = startTimes[i];


            uint roundId = i+1;


            roundIds.push(roundId);

            Round memory round = Round(startTimes[i], maxParticipations[i]);


            roundIdToRound[roundId] = round;


            emit RoundAdded(roundId, round.startTime, round.maxParticipation);
        }
    }




    function registerForSale(
        bytes memory signature,
        uint roundId
    )
    external
    {
        require(roundId != 0, "Round ID can not be 0.");
        require(roundId <= roundIds.length, "Invalid round id");
        require(block.timestamp >= registration.registrationTimeStarts && block.timestamp <= registration.registrationTimeEnds, "Registration gate is closed.");
        require(checkRegistrationSignature(signature, msg.sender, roundId), "Invalid signature");
        require(addressToRoundRegisteredFor[msg.sender] == 0, "User can not register twice.");


        addressToRoundRegisteredFor[msg.sender] = roundId;


        if(roundId == 2) {

            allocationStakingContract.setTokensUnlockTime(0, msg.sender, sale.saleEnd);
        }


        registration.numberOfRegistrants++;


        emit UserRegistered(msg.sender, roundId);
    }



    function updateTokenPriceInAVAX(
        uint256 price
    )
    external
    onlyAdmin
    {
        require(block.timestamp < roundIdToRound[roundIds[0]].startTime, "1st round already started.");
        require(price > 0, "Price can not be 0.");


        sale.tokenPriceInAVAX = price;


        emit TokenPriceSet(price);
    }




    function postponeSale(
        uint256 timeToShift
    )
    external
    onlyAdmin
    {
        require(block.timestamp < roundIdToRound[roundIds[0]].startTime, "1st round already started.");


        for(uint i = 0; i < roundIds.length; i++) {
            Round storage round = roundIdToRound[roundIds[i]];

            round.startTime = round.startTime.add(timeToShift);
        }
    }


    function extendRegistrationPeriod(
        uint256 timeToAdd
    )
    external
    onlyAdmin
    {
        require(registration.registrationTimeEnds.add(timeToAdd) < roundIdToRound[roundIds[0]].startTime,
            "Registration period overflows sale start.");

        registration.registrationTimeEnds = registration.registrationTimeEnds.add(timeToAdd);
    }



    function setCapPerRound(
        uint256[] calldata rounds,
        uint256[] calldata caps
    )
    external
    onlyAdmin
    {
        require(block.timestamp < roundIdToRound[roundIds[0]].startTime, "1st round already started.");
        require(rounds.length == caps.length, "Arrays length is different.");

        for(uint i = 0; i < rounds.length; i++) {
            require(caps[i] > 0, "Can't set max participation to 0");

            Round storage round = roundIdToRound[rounds[i]];
            round.maxParticipation = caps[i];

            emit MaxParticipationSet(rounds[i], round.maxParticipation);
        }
    }




    function depositTokens()
    external
    onlySaleOwner
    {
        require(sale.totalTokensSold == 0 && sale.token.balanceOf(address(this)) == 0, "Deposit can be done only once");
        require(block.timestamp < roundIdToRound[roundIds[0]].startTime, "Deposit too late. Round already started.");

        sale.token.safeTransferFrom(msg.sender, address(this), sale.amountOfTokensToSell);
        sale.tokensDeposited = true;
    }



    function participate(
        bytes memory signature,
        uint256 amount,
        uint256 amountXavaToBurn,
        uint256 roundId
    )
    external
    payable
    {

        require(sale.tokensDeposited == true, "Tokens not deposited yet");

        require(roundId != 0, "Round can not be 0.");

        require(amount <= roundIdToRound[roundId].maxParticipation, "Overflowing maximal participation for this round.");


        require(addressToRoundRegisteredFor[msg.sender] == roundId, "Not registered for this round");


        require(checkParticipationSignature(signature, msg.sender, amount, amountXavaToBurn, roundId), "Invalid signature. Verification failed");


        require(isParticipated[msg.sender] == false, "User can participate only once.");


        require(msg.sender == tx.origin, "Only direct contract calls.");


        uint256 currentRound = getCurrentRound();


        require(roundId == currentRound, "You can not participate in this round.");


        uint256 amountOfTokensBuying = (msg.value).mul(10**18).div(sale.tokenPriceInAVAX);


        require(amountOfTokensBuying > 0, "Can't buy 0 tokens");


        require(amountOfTokensBuying <= amount, "Trying to buy more than allowed.");


        sale.totalTokensSold = sale.totalTokensSold.add(amountOfTokensBuying);


        sale.totalAVAXRaised = sale.totalAVAXRaised.add(msg.value);


        Participation memory p;
        p.amountBought = amountOfTokensBuying;
        p.amountAVAXPaid = msg.value;
        p.timeParticipated = block.timestamp;
        p.roundId = roundId;


        if(roundId == 2) {

            allocationStakingContract.redistributeXava(0, msg.sender, amountXavaToBurn);
        }


        userToParticipation[msg.sender] = p;


        isParticipated[msg.sender] = true;


        numberOfParticipants ++;

        emit TokensSold(msg.sender, amountOfTokensBuying);
    }



    function withdrawTokens(uint portionId) external {
        require(block.timestamp >= sale.tokensUnlockTime, "Tokens can not be withdrawn yet.");
        require(portionId < vestingPercentPerPortion.length);

        Participation storage p = userToParticipation[msg.sender];

        if(!p.isPortionWithdrawn[portionId] && vestingPortionsUnlockTime[portionId] >= block.timestamp) {
            p.isPortionWithdrawn[portionId];
            uint256 amountWithdrawing = p.amountBought.mul(vestingPercentPerPortion[portionId]).div(100);

            sale.token.safeTransfer(msg.sender, amountWithdrawing);
            emit TokensWithdrawn(msg.sender, amountWithdrawing);
        } else {
            revert("Tokens already withdrawn.");
        }
    }



    function safeTransferAVAX(
        address to,
        uint value
    )
    internal
    {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success);
    }



    function withdrawEarningsAndLeftover(
        bool withBurn
    )
    external
    onlySaleOwner
    {

        require(block.timestamp >= sale.saleEnd);


        require(sale.earningsWithdrawn == false);
        sale.earningsWithdrawn = true;


        uint totalProfit = address(this).balance;


        uint leftover = sale.amountOfTokensToSell.sub(sale.totalTokensSold);

        safeTransferAVAX(msg.sender, totalProfit);

        if(leftover > 0 && !withBurn) {
            sale.token.safeTransfer(msg.sender, leftover);
            return;
        }

        if(withBurn) {
            sale.token.safeTransfer(address(1), leftover);
        }
    }



    function getCurrentRound() public view returns (uint) {
        uint i = 0;
        if(block.timestamp < roundIdToRound[roundIds[0]].startTime) {
            return 0;
        }

        while((i+1) < roundIds.length && block.timestamp > roundIdToRound[roundIds[i+1]].startTime) {
            i++;
        }

        if(block.timestamp >= sale.saleEnd) {
            return 0;
        }

        return roundIds[i];
    }





    function checkRegistrationSignature(
        bytes memory signature,
        address user,
        uint256 roundId
    )
    public
    view
    returns (bool)
    {
        bytes32 hash = keccak256(abi.encodePacked(user, roundId, address(this)));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return admin.isAdmin(messageHash.recover(signature));
    }



    function checkParticipationSignature(
        bytes memory signature,
        address user,
        uint256 amount,
        uint256 amountXavaToBurn,
        uint256 round
    )
    public
    view
    returns (bool)
    {
        return admin.isAdmin(getParticipationSigner(signature, user, amount, amountXavaToBurn, round));
    }







    function getParticipationSigner(
        bytes memory signature,
        address user,
        uint256 amount,
        uint256 amountXavaToBurn,
        uint256 roundId
    )
    public
    view
    returns (address)
    {
        bytes32 hash = keccak256(abi.encodePacked(user, amount, amountXavaToBurn, roundId, address(this)));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return messageHash.recover(signature);
    }


    function getParticipation(address _user) external view returns (uint256, uint256, uint256, uint256, bool[] memory) {
        Participation memory p = userToParticipation[_user];
        return (
            p.amountBought,
            p.amountAVAXPaid,
            p.timeParticipated,
            p.roundId,
            p.isPortionWithdrawn
        );
    }


    function getRegistrationInfo() external view returns (uint256, uint256) {
        return (
            registration.registrationTimeEnds,
            registration.numberOfRegistrants
        );
    }

}
