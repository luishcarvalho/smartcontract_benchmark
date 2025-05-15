pragma solidity ^0.5.4;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "./TokenStaking.sol";
import "./cryptography/BLS.sol";
import "./utils/AddressArrayUtils.sol";
import "./libraries/operator/GroupSelection.sol";
import "./libraries/operator/Groups.sol";
import "./libraries/operator/DKGResultVerification.sol";
import "./libraries/operator/Reimbursements.sol";

interface ServiceContract {
    function entryCreated(uint256 requestId, bytes calldata entry, address payable submitter) external;
    function fundRequestSubsidyFeePool() external payable;
    function fundDkgFeePool() external payable;
}








contract KeepRandomBeaconOperator is ReentrancyGuard {
    using SafeMath for uint256;
    using AddressArrayUtils for address[];
    using GroupSelection for GroupSelection.Storage;
    using Groups for Groups.Storage;
    using DKGResultVerification for DKGResultVerification.Storage;

    event OnGroupRegistered(bytes groupPubKey);



    event DkgResultPublishedEvent(bytes groupPubKey);

    event RelayEntryRequested(bytes previousEntry, bytes groupPublicKey);
    event RelayEntrySubmitted();

    event GroupSelectionStarted(uint256 newEntry);

    event GroupMemberRewardsWithdrawn(address indexed beneficiary, address operator, uint256 amount, uint256 groupIndex);

    GroupSelection.Storage groupSelection;
    Groups.Storage groups;
    DKGResultVerification.Storage dkgResultVerification;


    address internal owner;

    address[] internal serviceContracts;


    TokenStaking internal stakingContract;



    uint256 public minimumStake = 200000 * 1e18;


    uint256 public groupMemberBaseReward = 145*1e11;





    uint256 public priceFeedEstimate = 20*1e9;



    uint256 public fluctuationMargin = 50;


    uint256 public groupSize = 64;



    uint256 public groupThreshold = 33;



    uint256 public resultPublicationBlockStep = 3;



    uint256 public relayEntryGenerationTime = (1+3);







    uint256 public relayEntryTimeout = relayEntryGenerationTime.add(groupSize.mul(resultPublicationBlockStep));




    uint256 public entryVerificationGasEstimate = 280000;


    uint256 public dkgGasEstimate = 1740000;


    uint256 public groupSelectionGasEstimate = 100000;







    uint256 public dkgSubmitterReimbursementFee;


    ServiceContract internal groupSelectionStarterContract;

    struct SigningRequest {
        uint256 relayRequestId;
        uint256 entryVerificationAndProfitFee;
        uint256 callbackFee;
        uint256 groupIndex;
        bytes previousEntry;
        address serviceContract;
    }

    uint256 internal currentEntryStartBlock;
    SigningRequest internal signingRequest;



    uint256 internal _genesisGroupSeed = 31415926535897932384626433832795028841971693993751058209749445923078164062862;





    function genesis() public payable {
        require(numberOfGroups() == 0, "Groups exist");

        groupSelectionStarterContract = ServiceContract(serviceContracts[serviceContracts.length.sub(1)]);
        startGroupSelection(_genesisGroupSeed, msg.value);
    }




    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }




    modifier onlyServiceContract() {
        require(
            serviceContracts.contains(msg.sender),
            "Caller is not an authorized contract"
        );
        _;
    }

    constructor(address _serviceContract, address _stakingContract) public {
        owner = msg.sender;

        serviceContracts.push(_serviceContract);
        stakingContract = TokenStaking(_stakingContract);

        groups.stakingContract = TokenStaking(_stakingContract);
        groups.groupActiveTime = TokenStaking(_stakingContract).undelegationPeriod();

        groupSelection.ticketSubmissionTimeout = 12;
        groupSelection.groupSize = groupSize;

        dkgResultVerification.timeDKG = 5*(1+5) + 2*(1+10);
        dkgResultVerification.resultPublicationBlockStep = resultPublicationBlockStep;
        dkgResultVerification.groupSize = groupSize;



        dkgResultVerification.signatureThreshold = groupThreshold;
    }





    function addServiceContract(address serviceContract) public onlyOwner {
        serviceContracts.push(serviceContract);
    }





    function removeServiceContract(address serviceContract) public onlyOwner {
        serviceContracts.removeAddress(serviceContract);
    }





    function setPriceFeedEstimate(uint256 _priceFeedEstimate) public onlyOwner {
        priceFeedEstimate = _priceFeedEstimate;
    }









    function gasPriceWithFluctuationMargin(uint256 gasPrice) internal view returns (uint256) {
        return gasPrice.add(gasPrice.mul(fluctuationMargin).div(100));
    }







    function createGroup(uint256 _newEntry, address payable submitter) public payable onlyServiceContract {
        uint256 groupSelectionStartFee = groupSelectionGasEstimate
            .mul(gasPriceWithFluctuationMargin(priceFeedEstimate));

        groupSelectionStarterContract = ServiceContract(msg.sender);
        startGroupSelection(_newEntry, msg.value.sub(groupSelectionStartFee));


        (bool success, ) = stakingContract.magpieOf(submitter).call.value(groupSelectionStartFee)("");
        require(success, "Failed reimbursing submitter for starting a group selection");
    }

    function startGroupSelection(uint256 _newEntry, uint256 _payment) internal {
        require(
            _payment >= gasPriceWithFluctuationMargin(priceFeedEstimate).mul(dkgGasEstimate),
            "Insufficient DKG fee"
        );

        require(isGroupSelectionPossible(), "Group selection in progress");



        if (dkgSubmitterReimbursementFee > 0) {
            uint256 surplus = dkgSubmitterReimbursementFee;
            dkgSubmitterReimbursementFee = 0;
            ServiceContract(msg.sender).fundDkgFeePool.value(surplus)();
        }

        groupSelection.start(_newEntry);
        emit GroupSelectionStarted(_newEntry);
        dkgSubmitterReimbursementFee = _payment;
    }

    function isGroupSelectionPossible() public view returns (bool) {
        if (!groupSelection.inProgress) {
            return true;
        }



        uint256 dkgTimeout = groupSelection.ticketSubmissionStartBlock +
        groupSelection.ticketSubmissionTimeout +
        dkgResultVerification.timeDKG +
        groupSize * resultPublicationBlockStep;

        return block.number > dkgTimeout;
    }












    function submitTicket(bytes32 ticket) public {
        uint256 stakingWeight = stakingContract.eligibleStake(msg.sender, address(this)).div(minimumStake);
        groupSelection.submitTicket(ticket, stakingWeight);
    }





    function ticketSubmissionTimeout() public view returns (uint256) {
        return groupSelection.ticketSubmissionTimeout;
    }




    function submittedTicketsCount() public view returns (uint256) {
        return groupSelection.tickets.length;
    }




    function selectedParticipants() public view returns (address[] memory) {
        return groupSelection.selectedParticipants();
    }















    function submitDkgResult(
        uint256 submitterMemberIndex,
        bytes memory groupPubKey,
        bytes memory misbehaved,
        bytes memory signatures,
        uint[] memory signingMembersIndexes
    ) public {
        address[] memory members = selectedParticipants();

        dkgResultVerification.verify(
            submitterMemberIndex,
            groupPubKey,
            misbehaved,
            signatures,
            signingMembersIndexes,
            members,
            groupSelection.ticketSubmissionStartBlock + groupSelection.ticketSubmissionTimeout
        );

        groups.setGroupMembers(groupPubKey, members, misbehaved);
        groups.addGroup(groupPubKey);
        reimburseDkgSubmitter();
        emit DkgResultPublishedEvent(groupPubKey);
        groupSelection.stop();
    }







    function reimburseDkgSubmitter() internal {
        uint256 gasPrice = priceFeedEstimate;



        if (tx.gasprice > 0 && tx.gasprice < priceFeedEstimate) {
            gasPrice = tx.gasprice;
        }

        uint256 reimbursementFee = dkgGasEstimate.mul(gasPrice);
        address payable magpie = stakingContract.magpieOf(msg.sender);

        if (reimbursementFee < dkgSubmitterReimbursementFee) {
            uint256 surplus = dkgSubmitterReimbursementFee.sub(reimbursementFee);
            dkgSubmitterReimbursementFee = 0;

            magpie.call.value(reimbursementFee)("");


            groupSelectionStarterContract.fundDkgFeePool.value(surplus)();
        } else {

            reimbursementFee = dkgSubmitterReimbursementFee;
            dkgSubmitterReimbursementFee = 0;
            magpie.call.value(reimbursementFee)("");
        }
    }





    function setMinimumStake(uint256 _minimumStake) public onlyOwner {
        minimumStake = _minimumStake;
    }







    function sign(
        uint256 requestId,
        bytes memory previousEntry
    ) public payable onlyServiceContract {
        uint256 entryVerificationAndProfitFee = groupProfitFee().add(
            entryVerificationGasEstimate.mul(gasPriceWithFluctuationMargin(priceFeedEstimate))
        );
        require(
            msg.value >= entryVerificationAndProfitFee,
            "Insufficient new entry fee"
        );
        uint256 callbackFee = msg.value.sub(entryVerificationAndProfitFee);
        signRelayEntry(
            requestId, previousEntry, msg.sender,
            entryVerificationAndProfitFee, callbackFee
        );
    }

    function signRelayEntry(
        uint256 requestId,
        bytes memory previousEntry,
        address serviceContract,
        uint256 entryVerificationAndProfitFee,
        uint256 callbackFee
    ) internal {
        require(!isEntryInProgress() || hasEntryTimedOut(), "Beacon is busy");

        currentEntryStartBlock = block.number;

        uint256 groupIndex = groups.selectGroup(uint256(keccak256(previousEntry)));
        signingRequest = SigningRequest(
            requestId,
            entryVerificationAndProfitFee,
            callbackFee,
            groupIndex,
            previousEntry,
            serviceContract
        );

        bytes memory groupPubKey = groups.getGroupPublicKey(groupIndex);
        emit RelayEntryRequested(previousEntry, groupPubKey);
    }







    function relayEntry(bytes memory _groupSignature) public nonReentrant {
        require(isEntryInProgress(), "Entry was submitted");
        require(!hasEntryTimedOut(), "Entry timed out");

        bytes memory groupPubKey = groups.getGroupPublicKey(signingRequest.groupIndex);

        require(
            BLS.verify(
                groupPubKey,
                signingRequest.previousEntry,
                _groupSignature
            ),
            "Invalid signature"
        );

        emit RelayEntrySubmitted();



        signingRequest.serviceContract.call.gas(groupSelectionGasEstimate.add(40000))(
            abi.encodeWithSignature(
                "entryCreated(uint256,bytes,address)",
                signingRequest.relayRequestId,
                _groupSignature,
                msg.sender
            )
        );

        if (signingRequest.callbackFee > 0) {
            executeCallback(signingRequest, uint256(keccak256(_groupSignature)));
        }

        (uint256 groupMemberReward, uint256 submitterReward, uint256 subsidy) = newEntryRewardsBreakdown();
        groups.addGroupMemberReward(groupPubKey, groupMemberReward);

        stakingContract.magpieOf(msg.sender).call.value(submitterReward)("");

        if (subsidy > 0) {
            signingRequest.serviceContract.call.gas(35000).value(subsidy)(abi.encodeWithSignature("fundRequestSubsidyFeePool()"));
        }

        currentEntryStartBlock = 0;
    }






    function executeCallback(SigningRequest memory signingRequest, uint256 entry) internal {
        uint256 callbackFee = signingRequest.callbackFee;


        uint256 gasLimit = callbackFee.div(gasPriceWithFluctuationMargin(priceFeedEstimate));

        bytes memory callbackReturnData;
        uint256 gasBeforeCallback = gasleft();
        (, callbackReturnData) = signingRequest.serviceContract.call.gas(gasLimit)(abi.encodeWithSignature("executeCallback(uint256,uint256)", signingRequest.relayRequestId, entry));
        uint256 gasAfterCallback = gasleft();
        uint256 gasSpent = gasBeforeCallback.sub(gasAfterCallback);

        Reimbursements.reimburseCallback(
            stakingContract,
            priceFeedEstimate,
            gasLimit,
            gasSpent,
            callbackFee,
            callbackReturnData
        );
    }




    function newEntryRewardsBreakdown() internal view returns(uint256 groupMemberReward, uint256 submitterReward, uint256 subsidy) {
        uint256 decimals = 1e16;

        uint256 delayFactor = getDelayFactor();
        groupMemberReward = groupMemberBaseReward.mul(delayFactor).div(decimals);


        uint256 groupMemberDelayPenalty = groupMemberBaseReward.mul(decimals.sub(delayFactor));






        uint256 submitterExtraReward = groupMemberDelayPenalty.mul(groupSize).mul(5).div(100).div(decimals);
        uint256 entryVerificationFee = signingRequest.entryVerificationAndProfitFee.sub(groupProfitFee());
        submitterReward = entryVerificationFee.add(submitterExtraReward);


        subsidy = groupProfitFee().sub(groupMemberReward.mul(groupSize)).sub(submitterExtraReward);
    }





    function getDelayFactor() internal view returns(uint256 delayFactor) {
        uint256 decimals = 1e16;






        uint256 deadlineBlock = currentEntryStartBlock.add(relayEntryTimeout).add(1);




        uint256 submissionStartBlock = currentEntryStartBlock.add(relayEntryGenerationTime).add(1);


        uint256 entryReceivedBlock = block.number <= submissionStartBlock ? submissionStartBlock:block.number;


        uint256 remainingBlocks = deadlineBlock.sub(entryReceivedBlock);


        uint256 submissionWindow = deadlineBlock.sub(submissionStartBlock);






        delayFactor = ((remainingBlocks.mul(decimals).div(submissionWindow))**2).div(decimals);
    }





    function isEntryInProgress() internal view returns (bool) {
        return currentEntryStartBlock != 0;
    }






    function hasEntryTimedOut() internal view returns (bool) {
        return currentEntryStartBlock != 0 && block.number > currentEntryStartBlock + relayEntryTimeout;
    }











    function reportRelayEntryTimeout() public {
        require(hasEntryTimedOut(), "Entry did not time out");
        groups.reportRelayEntryTimeout(signingRequest.groupIndex, groupSize, minimumStake);




        if (numberOfGroups() > 0) {
            signRelayEntry(
                signingRequest.relayRequestId,
                signingRequest.previousEntry,
                signingRequest.serviceContract,
                signingRequest.entryVerificationAndProfitFee,
                signingRequest.callbackFee
            );
        }
    }




    function groupProfitFee() public view returns(uint256) {
        return groupMemberBaseReward.mul(groupSize);
    }














    function hasMinimumStake(address staker) public view returns(bool) {
        return (
            stakingContract.activeStake(staker, address(this)) >= minimumStake
        );
    }




    function isGroupRegistered(bytes memory groupPubKey) public view returns(bool) {
        return groups.isGroupRegistered(groupPubKey);
    }










    function isStaleGroup(bytes memory groupPubKey) public view returns(bool) {
        return groups.isStaleGroup(groupPubKey);
    }





    function numberOfGroups() public view returns(uint256) {
        return groups.numberOfGroups();
    }




    function getGroupMemberRewards(bytes memory groupPubKey) public view returns (uint256) {
        return groups.groupMemberRewards[groupPubKey];
    }




    function getGroupMemberIndices(bytes memory groupPubKey, address member) public view returns (uint256[] memory indices) {
        return groups.getGroupMemberIndices(groupPubKey, member);
    }










    function withdrawGroupMemberRewards(address operator, uint256 groupIndex, uint256[] memory groupMemberIndices) public nonReentrant {
        uint256 accumulatedRewards = groups.withdrawFromGroup(operator, groupIndex, groupMemberIndices);
        (bool success, ) = stakingContract.magpieOf(operator).call.value(accumulatedRewards)("");
        if (success) {
            emit GroupMemberRewardsWithdrawn(stakingContract.magpieOf(operator), operator, accumulatedRewards, groupIndex);
        }
    }




    function getFirstActiveGroupIndex() public view returns (uint256) {
        return groups.expiredGroupOffset;
    }




    function getGroupPublicKey(uint256 groupIndex) public view returns (bytes memory) {
        return groups.getGroupPublicKey(groupIndex);
    }





    function groupCreationGasEstimate() public view returns (uint256) {
        return dkgGasEstimate.add(groupSelectionGasEstimate);
    }




    function getGroupMembers(bytes memory groupPubKey) public view returns (address[] memory members) {
        return groups.getGroupMembers(groupPubKey);
    }









    function reportUnauthorizedSigning(
        uint256 groupIndex,
        bytes memory signedGroupPubKey
    ) public {
        groups.reportUnauthorizedSigning(groupIndex, signedGroupPubKey, minimumStake);
    }
}
