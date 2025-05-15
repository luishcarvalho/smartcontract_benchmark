







pragma solidity ^0.5.0;

import "./zeppelin/math/SafeMath.sol";
import "./zeppelin/token/ERC777/IERC777.sol";
import "./zeppelin/token/ERC777/IERC777Recipient.sol";
import "./zeppelin/introspection/IERC1820Registry.sol";

contract ReversibleICO is IERC777Recipient {





    using SafeMath for uint256;


    IERC1820Registry private ERC1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");






    bool public initialized;


    bool public frozen;
    uint256 public frozenPeriod;
    uint256 public freezeStart;






    address public deployingAddress;

    address public tokenAddress;

    address public projectAddress;

    address public whitelistingAddress;

    address public freezerAddress;

    address public rescuerAddress;






    uint256 public tokenSupply;

    uint256 public committedETH;

    uint256 public pendingETH;

    uint256 public canceledETH;

    uint256 public withdrawnETH;

    uint256 public projectWithdrawCount;

    uint256 public projectWithdrawnETH;


    uint256 public minContribution = 0.001 ether;

    mapping(uint8 => Stage) public stages;
    uint256 public stageBlockCount;
    uint8 public stageCount;


    mapping(address => Participant) public participants;

    mapping(uint256 => address) public participantsById;

    uint256 public participantCount;





    uint256 public commitPhasePrice;

    uint256 public commitPhaseStartBlock;

    uint256 public commitPhaseEndBlock;

    uint256 public commitPhaseBlockCount;






    uint256 public buyPhaseStartBlock;

    uint256 public buyPhaseEndBlock;

    uint256 public buyPhaseBlockCount;










    uint256 internal _projectCurrentlyReservedETH;

    uint256 internal _projectUnlockedETH;

    uint256 internal _projectLastBlock;











    struct Stage {
        uint128 startBlock;
        uint128 endBlock;
        uint256 tokenPrice;
    }




    struct Participant {
        bool whitelisted;
        uint32 contributions;
        uint32 withdraws;
        uint256 reservedTokens;
        uint256 committedETH;
        uint256 pendingETH;

        uint256 _currentReservedTokens;
        uint256 _unlockedTokens;
        uint256 _lastBlock;

        mapping(uint8 => ParticipantStageDetails) stages;
    }

    struct ParticipantStageDetails {
        uint256 pendingETH;
    }




    event ApplicationEvent (
        uint8 indexed typeId,
        uint32 indexed id,
        address indexed relatedAddress,
        uint256 value
    );

    event TransferEvent (
        uint8 indexed typeId,
        address indexed relatedAddress,
        uint256 indexed value
    );

    enum ApplicationEventTypes {
        NOT_SET,
        CONTRIBUTION_ADDED,
        CONTRIBUTION_CANCELED,
        CONTRIBUTION_ACCEPTED,
        WHITELIST_APPROVED,
        WHITELIST_REJECTED,
        PROJECT_WITHDRAWN,
        FROZEN_FREEZE,
        FROZEN_UNFREEZE,
        FROZEN_DISBALEHATCH,
        FROZEN_ESCAPEHATCH
    }

    enum TransferTypes {
        NOT_SET,
        WHITELIST_REJECTED,
        CONTRIBUTION_CANCELED,
        CONTRIBUTION_ACCEPTED_OVERFLOW,
        PARTICIPANT_WITHDRAW,
        PARTICIPANT_WITHDRAW_OVERFLOW,
        PROJECT_WITHDRAWN,
        FROZEN_ESCAPEHATCH_TOKEN,
        FROZEN_ESCAPEHATCH_ETH
    }





    constructor() public {
        deployingAddress = msg.sender;
        ERC1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }














    function init(
        address _tokenAddress,
        address _whitelistingAddress,
        address _projectAddress,
        uint256 _commitPhaseStartBlock,
        uint256 _commitPhaseBlockCount,
        uint256 _commitPhasePrice,
        uint8 _stageCount,
        uint256 _stageBlockCount,
        uint256 _stagePriceIncrease
    )
    public
    onlyDeployingAddress
    isNotInitialized
    {

        require(_commitPhaseStartBlock > getCurrentBlockNumber(), "Start block cannot be set in the past.");


        tokenAddress = _tokenAddress;
        whitelistingAddress = _whitelistingAddress;
        projectAddress = _projectAddress;
        freezerAddress = _projectAddress;
        rescuerAddress = _projectAddress;


        commitPhaseStartBlock = _commitPhaseStartBlock;
        commitPhaseBlockCount = _commitPhaseBlockCount;
        commitPhaseEndBlock = _commitPhaseStartBlock.add(_commitPhaseBlockCount).sub(1);
        commitPhasePrice = _commitPhasePrice;

        stageBlockCount = _stageBlockCount;
        stageCount = _stageCount;


        Stage storage commitPhase = stages[0];

        commitPhase.startBlock = uint128(_commitPhaseStartBlock);
        commitPhase.endBlock = uint128(commitPhaseEndBlock);
        commitPhase.tokenPrice = _commitPhasePrice;



        uint256 previousStageEndBlock = commitPhase.endBlock;


        for (uint8 i = 1; i <= _stageCount; i++) {

            Stage storage stageN = stages[i];

            stageN.startBlock = uint128(previousStageEndBlock.add(1));

            stageN.endBlock = uint128(previousStageEndBlock.add(_stageBlockCount));

            previousStageEndBlock = stageN.endBlock;

            stageN.tokenPrice = _commitPhasePrice.add(_stagePriceIncrease.mul(i));
        }



        buyPhaseStartBlock = commitPhaseEndBlock.add(1);

        buyPhaseEndBlock = previousStageEndBlock;

        buyPhaseBlockCount = buyPhaseEndBlock.sub(buyPhaseStartBlock).add(1);


        initialized = true;
    }














    function()
    external
    payable
    isInitialized
    isNotFrozen
    {
        require(msg.value < minContribution, 'To contribute, call the commit() function and send ETH along.');


        cancelPendingContributions(msg.sender, msg.value);
    }






    function tokensReceived(
        address,
        address _from,
        address,
        uint256 _amount,
        bytes calldata,
        bytes calldata
    )
    external
    isInitialized
    isNotFrozen
    {


        require(msg.sender == tokenAddress, "Invalid token contract sent tokens.");


        if (_from == projectAddress) {

            tokenSupply = tokenSupply.add(_amount);


        } else {
            withdraw(_from, _amount);
        }
    }




    function commit()
    external
    payable
    isInitialized
    isNotFrozen
    isRunning
    {

        require(msg.value >= minContribution, "Value sent is less than minimum contribution.");


        Participant storage participantStats = participants[msg.sender];
        ParticipantStageDetails storage byStage = participantStats.stages[getCurrentStage()];


        if (participantStats.contributions == 0) {

            participantsById[participantCount] = msg.sender;

            participantCount++;
        }


        participantStats.contributions++;
        participantStats.pendingETH = participantStats.pendingETH.add(msg.value);
        byStage.pendingETH = byStage.pendingETH.add(msg.value);


        pendingETH = pendingETH.add(msg.value);

        emit ApplicationEvent(
            uint8(ApplicationEventTypes.CONTRIBUTION_ADDED),
            uint32(participantStats.contributions),
            msg.sender,
            msg.value
        );


        if (participantStats.whitelisted == true) {
            acceptContributions(msg.sender);
        }
    }




    function cancel()
    external
    payable
    isInitialized
    isNotFrozen
    {
        cancelPendingContributions(msg.sender, msg.value);
    }






    function whitelist(address[] calldata _addresses, bool _approve)
    external
    onlyWhitelistingAddress
    isInitialized
    isNotFrozen
    isRunning
    {

        require(_addresses.length > 0, "No addresses given to whitelist.");

        for (uint256 i = 0; i < _addresses.length; i++) {
            address participantAddress = _addresses[i];

            Participant storage participantStats = participants[participantAddress];

            if (_approve) {
                if (!participantStats.whitelisted) {

                    participantStats.whitelisted = true;
                    emit ApplicationEvent(uint8(ApplicationEventTypes.WHITELIST_APPROVED), getCurrentStage(), participantAddress, 0);
                }


                acceptContributions(participantAddress);

            } else {
                emit ApplicationEvent(uint8(ApplicationEventTypes.WHITELIST_REJECTED), getCurrentStage(), participantAddress, 0);
                participantStats.whitelisted = false;


                cancelPendingContributions(participantAddress, 0);
            }
        }
    }





    function projectWithdraw(uint256 _ethAmount)
    external
    onlyProjectAddress
    isInitialized
    isNotFrozen
    {

        calcProjectAllocation();


        uint256 availableForWithdraw = _projectUnlockedETH.sub(projectWithdrawnETH);

        require(_ethAmount <= availableForWithdraw, "Requested amount too high, not enough ETH unlocked.");


        projectWithdrawCount++;
        projectWithdrawnETH = projectWithdrawnETH.add(_ethAmount);


        emit ApplicationEvent(
            uint8(ApplicationEventTypes.PROJECT_WITHDRAWN),
            uint32(projectWithdrawCount),
            projectAddress,
            _ethAmount
        );
        emit TransferEvent(
            uint8(TransferTypes.PROJECT_WITHDRAWN),
            projectAddress,
            _ethAmount
        );


        address(uint160(projectAddress)).transfer(_ethAmount);
    }










    function freeze()
    external
    onlyFreezerAddress
    isNotFrozen
    {
        frozen = true;
        freezeStart = getCurrentBlockNumber();


        emit ApplicationEvent(uint8(ApplicationEventTypes.FROZEN_FREEZE), uint32(getCurrentStage()), freezerAddress, getCurrentBlockNumber());
    }




    function unfreeze()
    external
    onlyFreezerAddress
    isFrozen
    {
        uint256 currentBlock = getCurrentBlockNumber();

        frozen = false;
        frozenPeriod = frozenPeriod.add(
            currentBlock.sub(freezeStart)
        );


        emit ApplicationEvent(uint8(ApplicationEventTypes.FROZEN_UNFREEZE), uint32(getCurrentStage()), freezerAddress, currentBlock);
    }




    function disableEscapeHatch()
    external
    onlyFreezerAddress
    isNotFrozen
    {
        freezerAddress = address(0);
        rescuerAddress = address(0);


        emit ApplicationEvent(uint8(ApplicationEventTypes.FROZEN_DISBALEHATCH), uint32(getCurrentStage()), freezerAddress, getCurrentBlockNumber());
    }




    function escapeHatch(address _to)
    external
    onlyRescuerAddress
    isFrozen
    {
        require(getCurrentBlockNumber() == freezeStart.add(18000), 'Let it cool.. Wait at least ~3 days (18000 blk) before moving anything.');

        uint256 tokenBalance = IERC777(tokenAddress).balanceOf(address(this));
        uint256 ethBalance = address(this).balance;



        IERC777(tokenAddress).send(_to, tokenBalance, "");


        address(uint160(_to)).transfer(ethBalance);


        emit ApplicationEvent(uint8(ApplicationEventTypes.FROZEN_ESCAPEHATCH), uint32(getCurrentStage()), _to, getCurrentBlockNumber());
        emit TransferEvent(uint8(TransferTypes.FROZEN_ESCAPEHATCH_TOKEN), _to, tokenBalance);
        emit TransferEvent(uint8(TransferTypes.FROZEN_ESCAPEHATCH_ETH), _to, ethBalance);
    }











    function getUnlockedProjectETH() public view returns (uint256) {


        uint256 newlyUnlockedEth = calcUnlockedAmount(_projectCurrentlyReservedETH, _projectLastBlock);

        return _projectUnlockedETH
        .add(newlyUnlockedEth);
    }





    function getAvailableProjectETH() public view returns (uint256) {
        return getUnlockedProjectETH()
            .sub(projectWithdrawnETH);
    }





    function getParticipantReservedTokens(address _participantAddress) public view returns (uint256) {
        Participant storage participantStats = participants[_participantAddress];

        if(participantStats._currentReservedTokens == 0) {
            return 0;
        }

        return participantStats._currentReservedTokens.sub(
            calcUnlockedAmount(participantStats._currentReservedTokens, participantStats._lastBlock)
        );
    }







    function getParticipantUnlockedTokens(address _participantAddress) public view returns (uint256) {
        Participant storage participantStats = participants[_participantAddress];

        return participantStats._unlockedTokens.add(
            calcUnlockedAmount(participantStats._currentReservedTokens, participantStats._lastBlock)
        );
    }





    function getCurrentStage() public view returns (uint8) {
        uint blockNumber;
        if (frozen) {
            blockNumber = freezeStart;
        } else {
            blockNumber = getCurrentBlockNumber().add(frozenPeriod);
        }
    return getStageAtBlock(blockNumber);
    }





    function getCurrentPrice() public view returns (uint256) {
        uint blockNumber;
        if (frozen) {
            blockNumber = freezeStart;
        } else {
            blockNumber = getCurrentBlockNumber().add(frozenPeriod);
        }
        return getPriceAtBlock(blockNumber);
    }






    function getPriceAtBlock(uint256 _blockNumber) public view returns (uint256) {
        return getPriceAtStage(getStageAtBlock(_blockNumber));
    }





    function getPriceAtStage(uint8 _stageId) public view returns (uint256) {
        if (_stageId <= stageCount) {
            return stages[_stageId].tokenPrice;
        }
        revert("No price data found.");
    }






    function getStageAtBlock(uint256 _blockNumber) public view returns (uint8) {

        uint256 blockNumber = _blockNumber.sub(frozenPeriod);

        require(blockNumber >= commitPhaseStartBlock && blockNumber <= buyPhaseEndBlock, "Block outside of rICO period.");

        if (blockNumber <= commitPhaseEndBlock) {
            return 0;
        }


        uint256 distance = blockNumber - (commitPhaseEndBlock + 1);


        uint256 stageID = 1 + (distance / stageBlockCount);

        return uint8(stageID);
    }






    function committableEthAtStage(uint8 _stageId) public view returns (uint256) {
        return getEthAmountForTokensAtStage(
            tokenSupply
        , _stageId);
    }







    function getTokenAmountForEthAtStage(uint256 _ethAmount, uint8 _stageId) public view returns (uint256) {
        return _ethAmount
        .mul(10 ** 18)
        .div(stages[_stageId].tokenPrice);
    }







    function getEthAmountForTokensAtStage(uint256 _tokenAmount, uint8 _stageId) public view returns (uint256) {
        return _tokenAmount
        .mul(stages[_stageId].tokenPrice)
        .div(10 ** 18);
    }




    function getCurrentBlockNumber() public view returns (uint256) {
        return uint256(block.number)
        .sub(frozenPeriod);
    }







    function calcUnlockedAmount(uint256 _amount, uint256 _lastBlock) public view returns (uint256) {

        uint256 currentBlock = getCurrentBlockNumber();

        if(_amount == 0) {
            return 0;
        }


        if (currentBlock >= buyPhaseStartBlock && currentBlock < buyPhaseEndBlock) {


            uint256 lastBlock = _lastBlock;
            if(lastBlock < buyPhaseStartBlock) {
                lastBlock = buyPhaseStartBlock.sub(1);
            }


            uint256 passedBlocks = currentBlock.sub(lastBlock);


            uint256 totalBlockCount = buyPhaseEndBlock.sub(lastBlock);

            return _amount.mul(
                passedBlocks.mul(10 ** 20)
                .div(totalBlockCount)
            ).div(10 ** 20);


        } else if (currentBlock >= buyPhaseEndBlock) {
            return _amount;
        }

        return 0;
    }










    function sanityCheckProject() internal view {

        require(
            committedETH == _projectCurrentlyReservedETH.add(_projectUnlockedETH),
            'Project Sanity check failed! Reserved + Unlock must equal committedETH'
        );






        require(
            address(this).balance == _projectUnlockedETH.add(_projectCurrentlyReservedETH).add(pendingETH).sub(projectWithdrawnETH),
            'Project sanity check failed! balance = Unlock + Reserved - Withdrawn'
        );
    }




    function sanityCheckParticipant(address _participantAddress) internal view {
        Participant storage participantStats = participants[_participantAddress];





        require(
            participantStats.reservedTokens == participantStats._currentReservedTokens.add(participantStats._unlockedTokens),
            'Participant Sanity check failed! Reser. + Unlock must equal totalReser'
        );
    }




    function calcProjectAllocation() internal {

        uint256 newlyUnlockedEth = calcUnlockedAmount(_projectCurrentlyReservedETH, _projectLastBlock);


        _projectCurrentlyReservedETH = _projectCurrentlyReservedETH.sub(newlyUnlockedEth);
        _projectUnlockedETH = _projectUnlockedETH.add(newlyUnlockedEth);
        _projectLastBlock = getCurrentBlockNumber();

        sanityCheckProject();
    }




    function calcParticipantAllocation(address _participantAddress) internal {
        Participant storage participantStats = participants[_participantAddress];


        participantStats._unlockedTokens = getParticipantUnlockedTokens(_participantAddress);
        participantStats._currentReservedTokens = getParticipantReservedTokens(_participantAddress);


        participantStats._lastBlock = getCurrentBlockNumber();


        calcProjectAllocation();
    }





    function cancelPendingContributions(address _participantAddress, uint256 _sentValue)
    internal
    isInitialized
    isNotFrozen
    {
        Participant storage participantStats = participants[_participantAddress];
        uint256 participantPendingEth = participantStats.pendingETH;


        if(participantPendingEth == 0) {

            if(_sentValue > 0) {
                address(uint160(_participantAddress)).transfer(_sentValue);
            }
            return;
        }


        for (uint8 stageId = 0; stageId <= getCurrentStage(); stageId++) {
            ParticipantStageDetails storage byStage = participantStats.stages[stageId];
            byStage.pendingETH = 0;
        }


        participantStats.pendingETH = 0;


        canceledETH = canceledETH.add(participantPendingEth);
        pendingETH = pendingETH.sub(participantPendingEth);


        emit TransferEvent(
            uint8(TransferTypes.CONTRIBUTION_CANCELED),
            _participantAddress,
            participantPendingEth
        );
        emit ApplicationEvent(
            uint8(ApplicationEventTypes.CONTRIBUTION_CANCELED),
            uint32(participantStats.contributions),
            _participantAddress,
            participantPendingEth
        );


        address(uint160(_participantAddress)).transfer(participantPendingEth.add(_sentValue));


        sanityCheckParticipant(_participantAddress);
        sanityCheckProject();
    }






    function acceptContributions(address _participantAddress)
    internal
    isInitialized
    isNotFrozen
    isRunning
    {
        Participant storage participantStats = participants[_participantAddress];


        if (participantStats.pendingETH == 0) {
            return;
        }

        uint8 currentStage = getCurrentStage();
        uint256 totalRefundedETH;
        uint256 totalNewReservedTokens;

        calcParticipantAllocation(_participantAddress);



        for (uint8 stageId = 0; stageId <= currentStage; stageId++) {
            ParticipantStageDetails storage stages = participantStats.stages[stageId];


            if (stages.pendingETH == 0) {
                continue;
            }

            uint256 maxCommittableEth = committableEthAtStage(stageId);
            uint256 newlyCommittedEth = stages.pendingETH;
            uint256 returnEth = 0;



            if (newlyCommittedEth > maxCommittableEth) {
                returnEth = newlyCommittedEth.sub(maxCommittableEth);
                newlyCommittedEth = maxCommittableEth;

                totalRefundedETH = totalRefundedETH.add(returnEth);
            }


            uint256 newTokenAmount = getTokenAmountForEthAtStage(
                newlyCommittedEth, stageId
            );

            totalNewReservedTokens = totalNewReservedTokens.add(newTokenAmount);


            participantStats._currentReservedTokens = participantStats._currentReservedTokens.add(newTokenAmount);
            participantStats.reservedTokens = participantStats.reservedTokens.add(newTokenAmount);
            participantStats.committedETH = participantStats.committedETH.add(newlyCommittedEth);
            participantStats.pendingETH = participantStats.pendingETH.sub(newlyCommittedEth).sub(returnEth);

            stages.pendingETH = stages.pendingETH.sub(newlyCommittedEth).sub(returnEth);


            tokenSupply = tokenSupply.sub(newTokenAmount);
            pendingETH = pendingETH.sub(newlyCommittedEth).sub(returnEth);
            committedETH = committedETH.add(newlyCommittedEth);
            _projectCurrentlyReservedETH = _projectCurrentlyReservedETH.add(newlyCommittedEth);


            emit ApplicationEvent(uint8(ApplicationEventTypes.CONTRIBUTION_ACCEPTED), uint32(stageId), _participantAddress, newlyCommittedEth);
        }


        if (totalRefundedETH > 0) {
            emit TransferEvent(uint8(TransferTypes.CONTRIBUTION_ACCEPTED_OVERFLOW), _participantAddress, totalRefundedETH);
            address(uint160(_participantAddress)).transfer(totalRefundedETH);
        }



        IERC777(tokenAddress).send(_participantAddress, totalNewReservedTokens, "");


        sanityCheckParticipant(_participantAddress);
        sanityCheckProject();
    }







    function withdraw(address _participantAddress, uint256 _returnedTokenAmount)
    internal
    isInitialized
    isNotFrozen
    isRunning
    {

        Participant storage participantStats = participants[_participantAddress];

        require(_returnedTokenAmount > 0, 'You can not withdraw without tokens.');
        require(participantStats._currentReservedTokens > 0 && participantStats.reservedTokens > 0, 'You can not withdraw, you have no locked tokens.');

        uint256 returnedTokenAmount = _returnedTokenAmount;
        uint256 overflowingTokenAmount;
        uint256 returnEthAmount;

        calcParticipantAllocation(_participantAddress);


        if (returnedTokenAmount > participantStats._currentReservedTokens) {
            overflowingTokenAmount = returnedTokenAmount.sub(participantStats._currentReservedTokens);
            returnedTokenAmount = participantStats._currentReservedTokens;
        }


        if(getCurrentStage() == 0) {

            returnEthAmount = getEthAmountForTokensAtStage(returnedTokenAmount, 0);


        } else {
            returnEthAmount = participantStats.committedETH.mul(
                returnedTokenAmount.mul(10 ** 20)
                .div(participantStats.reservedTokens)
            ).div(10 ** 20);
        }



        participantStats.withdraws++;
        participantStats._currentReservedTokens = participantStats._currentReservedTokens.sub(returnedTokenAmount);
        participantStats.reservedTokens = participantStats.reservedTokens.sub(returnedTokenAmount);
        participantStats.committedETH = participantStats.committedETH.sub(returnEthAmount);


        tokenSupply = tokenSupply.add(returnedTokenAmount);
        withdrawnETH = withdrawnETH.add(returnEthAmount);
        committedETH = committedETH.sub(returnEthAmount);

        _projectCurrentlyReservedETH = _projectCurrentlyReservedETH.sub(returnEthAmount);



        if (overflowingTokenAmount > 0) {

            bytes memory data;

            emit TransferEvent(uint8(TransferTypes.PARTICIPANT_WITHDRAW_OVERFLOW), _participantAddress, overflowingTokenAmount);

            IERC777(tokenAddress).send(_participantAddress, overflowingTokenAmount, data);
        }

        emit TransferEvent(uint8(TransferTypes.PARTICIPANT_WITHDRAW), _participantAddress, returnEthAmount);


        address(uint160(_participantAddress)).transfer(returnEthAmount);


        sanityCheckParticipant(_participantAddress);
        sanityCheckProject();
    }








    modifier onlyProjectAddress() {
        require(msg.sender == projectAddress, "Only the project can call this method.");
        _;
    }




    modifier onlyDeployingAddress() {
        require(msg.sender == deployingAddress, "Only the deployer can call this method.");
        _;
    }




    modifier onlyWhitelistingAddress() {
        require(msg.sender == whitelistingAddress, "Only the whitelist controller can call this method.");
        _;
    }




    modifier onlyFreezerAddress() {
        require(msg.sender == freezerAddress, "Only the freezer address can call this method.");
        _;
    }




    modifier onlyRescuerAddress() {
        require(msg.sender == rescuerAddress, "Only the rescuer address can call this method.");
        _;
    }




    modifier isInitialized() {
        require(initialized == true, "Contract must be initialized.");
        _;
    }




    modifier isNotInitialized() {
        require(initialized == false, "Contract can not be initialized.");
        _;
    }




    modifier isFrozen() {
        require(frozen == true, "rICO has to be frozen!");
        _;
    }




    modifier isNotFrozen() {
        require(frozen == false, "rICO is frozen!");
        _;
    }




    modifier isRunning() {
        uint256 blockNumber = getCurrentBlockNumber();
        require(blockNumber >= commitPhaseStartBlock && blockNumber <= buyPhaseEndBlock, "Current block is outside the rICO period.");
        _;
    }
}
