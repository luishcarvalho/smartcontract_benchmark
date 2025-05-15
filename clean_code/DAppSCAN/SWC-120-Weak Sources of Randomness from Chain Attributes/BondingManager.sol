pragma solidity ^0.4.17;

import "../ManagerProxyTarget.sol";
import "./IBondingManager.sol";
import "../libraries/SortedDoublyLL.sol";
import "../libraries/MathUtils.sol";
import "./libraries/EarningsPool.sol";
import "../token/ILivepeerToken.sol";
import "../token/IMinter.sol";
import "../rounds/IRoundsManager.sol";

import "zeppelin-solidity/contracts/math/Math.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";







contract BondingManager is ManagerProxyTarget, IBondingManager {
    using SafeMath for uint256;
    using SortedDoublyLL for SortedDoublyLL.Data;
    using EarningsPool for EarningsPool.Data;


    uint64 public unbondingPeriod;

    uint256 public numActiveTranscoders;

    uint256 public maxEarningsClaimsRounds;


    struct Transcoder {
        uint256 lastRewardRound;
        uint256 rewardCut;
        uint256 feeShare;
        uint256 pricePerSegment;
        uint256 pendingRewardCut;
        uint256 pendingFeeShare;
        uint256 pendingPricePerSegment;
        mapping (uint256 => EarningsPool.Data) earningsPoolPerRound;
    }


    enum TranscoderStatus { NotRegistered, Registered }


    struct Delegator {
        uint256 bondedAmount;
        uint256 fees;
        address delegateAddress;
        uint256 delegatedAmount;
        uint256 startRound;
        uint256 withdrawRound;
        uint256 lastClaimRound;
    }


    enum DelegatorStatus { Pending, Bonded, Unbonding, Unbonded }


    mapping (address => Delegator) private delegators;
    mapping (address => Transcoder) private transcoders;


    uint256 private totalBonded;


    SortedDoublyLL.Data private transcoderPool;


    struct ActiveTranscoderSet {
        address[] transcoders;
        mapping (address => bool) isActive;
        uint256 totalStake;
    }


    mapping (uint256 => ActiveTranscoderSet) public activeTranscoderSet;


    modifier onlyJobsManager() {
        require(msg.sender == controller.getContract(keccak256("JobsManager")));
        _;
    }


    modifier onlyRoundsManager() {
        require(msg.sender == controller.getContract(keccak256("RoundsManager")));
        _;
    }


    modifier currentRoundInitialized() {
        require(roundsManager().currentRoundInitialized());
        _;
    }


    modifier autoClaimEarnings() {
        updateDelegatorWithEarnings(msg.sender, roundsManager().currentRound());
        _;
    }





    function BondingManager(address _controller) public Manager(_controller) {}





    function setUnbondingPeriod(uint64 _unbondingPeriod) external onlyControllerOwner {
        unbondingPeriod = _unbondingPeriod;

        ParameterUpdate("unbondingPeriod");
    }





    function setNumTranscoders(uint256 _numTranscoders) external onlyControllerOwner {

        require(_numTranscoders >= numActiveTranscoders);

        transcoderPool.setMaxSize(_numTranscoders);

        ParameterUpdate("numTranscoders");
    }





    function setNumActiveTranscoders(uint256 _numActiveTranscoders) external onlyControllerOwner {

        require(_numActiveTranscoders <= transcoderPool.getMaxSize());

        numActiveTranscoders = _numActiveTranscoders;

        ParameterUpdate("numActiveTranscoders");
    }





    function setMaxEarningsClaimsRounds(uint256 _maxEarningsClaimsRounds) external onlyControllerOwner {
        maxEarningsClaimsRounds = _maxEarningsClaimsRounds;

        ParameterUpdate("maxEarningsClaimsRounds");
    }







    function transcoder(uint256 _rewardCut, uint256 _feeShare, uint256 _pricePerSegment)
        external
        whenSystemNotPaused
        currentRoundInitialized
    {
        Transcoder storage t = transcoders[msg.sender];
        Delegator storage del = delegators[msg.sender];

        if (roundsManager().currentRoundLocked()) {






            require(transcoderStatus(msg.sender) == TranscoderStatus.Registered);


            require(_rewardCut == t.pendingRewardCut);


            require(_feeShare == t.pendingFeeShare);





            address currentTranscoder = transcoderPool.getFirst();
            uint256 priceFloor = transcoders[currentTranscoder].pendingPricePerSegment;
            for (uint256 i = 0; i < transcoderPool.getSize(); i++) {
                if (transcoders[currentTranscoder].pendingPricePerSegment < priceFloor) {
                    priceFloor = transcoders[currentTranscoder].pendingPricePerSegment;
                }

                currentTranscoder = transcoderPool.getNext(currentTranscoder);
            }



            require(_pricePerSegment >= priceFloor && _pricePerSegment <= t.pendingPricePerSegment);

            t.pendingPricePerSegment = _pricePerSegment;

            TranscoderUpdate(msg.sender, t.pendingRewardCut, t.pendingFeeShare, _pricePerSegment, true);
        } else {










            require(MathUtils.validPerc(_rewardCut));

            require(MathUtils.validPerc(_feeShare));


            require(del.delegateAddress == msg.sender && del.bondedAmount > 0);

            t.pendingRewardCut = _rewardCut;
            t.pendingFeeShare = _feeShare;
            t.pendingPricePerSegment = _pricePerSegment;

            uint256 delegatedAmount = del.delegatedAmount;


            if (transcoderStatus(msg.sender) == TranscoderStatus.NotRegistered) {
                if (!transcoderPool.isFull()) {

                    transcoderPool.insert(msg.sender, delegatedAmount, address(0), address(0));
                } else {
                    address lastTranscoder = transcoderPool.getLast();

                    if (delegatedAmount > transcoderPool.getKey(lastTranscoder)) {



                        transcoderPool.remove(lastTranscoder);
                        transcoderPool.insert(msg.sender, delegatedAmount, address(0), address(0));

                        TranscoderEvicted(lastTranscoder);
                    }
                }
            }

            TranscoderUpdate(msg.sender, _rewardCut, _feeShare, _pricePerSegment, transcoderPool.contains(msg.sender));
        }
    }






    function bond(
        uint256 _amount,
        address _to
    )
        external
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        Delegator storage del = delegators[msg.sender];

        uint256 currentRound = roundsManager().currentRound();

        uint256 delegationAmount = _amount;

        if (delegatorStatus(msg.sender) == DelegatorStatus.Unbonded || delegatorStatus(msg.sender) == DelegatorStatus.Unbonding) {



            del.startRound = currentRound.add(1);


            del.withdrawRound = 0;



            delegationAmount = delegationAmount.add(del.bondedAmount);
        } else if (del.delegateAddress != address(0) && _to != del.delegateAddress) {


            del.startRound = currentRound.add(1);

            delegationAmount = delegationAmount.add(del.bondedAmount);

            delegators[del.delegateAddress].delegatedAmount = delegators[del.delegateAddress].delegatedAmount.sub(del.bondedAmount);

            if (transcoderStatus(del.delegateAddress) == TranscoderStatus.Registered) {


                transcoderPool.updateKey(del.delegateAddress, transcoderPool.getKey(del.delegateAddress).sub(del.bondedAmount), address(0), address(0));
            }
        }


        require(delegationAmount > 0);

        del.delegateAddress = _to;

        delegators[_to].delegatedAmount = delegators[_to].delegatedAmount.add(delegationAmount);

        if (transcoderStatus(_to) == TranscoderStatus.Registered) {


            transcoderPool.updateKey(_to, transcoderPool.getKey(del.delegateAddress).add(delegationAmount), address(0), address(0));
        }

        if (_amount > 0) {

            del.bondedAmount = del.bondedAmount.add(_amount);

            totalBonded = totalBonded.add(_amount);

            livepeerToken().transferFrom(msg.sender, minter(), _amount);
        }

        Bond(_to, msg.sender);
    }




    function unbond()
        external
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {

        require(delegatorStatus(msg.sender) == DelegatorStatus.Bonded);

        Delegator storage del = delegators[msg.sender];

        uint256 currentRound = roundsManager().currentRound();


        del.withdrawRound = currentRound.add(unbondingPeriod);

        delegators[del.delegateAddress].delegatedAmount = delegators[del.delegateAddress].delegatedAmount.sub(del.bondedAmount);

        totalBonded = totalBonded.sub(del.bondedAmount);

        if (transcoderStatus(msg.sender) == TranscoderStatus.Registered) {


            resignTranscoder(msg.sender);
        } else if (transcoderStatus(del.delegateAddress) == TranscoderStatus.Registered) {

            transcoderPool.updateKey(del.delegateAddress, transcoderPool.getKey(del.delegateAddress).sub(del.bondedAmount), address(0), address(0));
        }


        del.delegateAddress = address(0);

        del.startRound = 0;

        Unbond(del.delegateAddress, msg.sender);
    }




    function withdrawStake()
        external
        whenSystemNotPaused
        currentRoundInitialized
    {

        require(delegatorStatus(msg.sender) == DelegatorStatus.Unbonded);

        uint256 amount = delegators[msg.sender].bondedAmount;
        delegators[msg.sender].bondedAmount = 0;
        delegators[msg.sender].withdrawRound = 0;


        minter().trustedTransferTokens(msg.sender, amount);

        WithdrawStake(msg.sender);
    }




    function withdrawFees()
        external
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {

        require(delegators[msg.sender].fees > 0);

        uint256 amount = delegators[msg.sender].fees;
        delegators[msg.sender].fees = 0;


        minter().trustedWithdrawETH(msg.sender, amount);

        WithdrawFees(msg.sender);
    }




    function setActiveTranscoders() external whenSystemNotPaused onlyRoundsManager {
        uint256 currentRound = roundsManager().currentRound();
        uint256 activeSetSize = Math.min256(numActiveTranscoders, transcoderPool.getSize());

        uint256 totalStake = 0;
        address currentTranscoder = transcoderPool.getFirst();

        for (uint256 i = 0; i < activeSetSize; i++) {
            activeTranscoderSet[currentRound].transcoders.push(currentTranscoder);
            activeTranscoderSet[currentRound].isActive[currentTranscoder] = true;

            uint256 stake = transcoderPool.getKey(currentTranscoder);
            uint256 rewardCut = transcoders[currentTranscoder].pendingRewardCut;
            uint256 feeShare = transcoders[currentTranscoder].pendingFeeShare;
            uint256 pricePerSegment = transcoders[currentTranscoder].pendingPricePerSegment;

            Transcoder storage t = transcoders[currentTranscoder];

            t.rewardCut = rewardCut;
            t.feeShare = feeShare;
            t.pricePerSegment = pricePerSegment;

            t.earningsPoolPerRound[currentRound].init(stake, rewardCut, feeShare);

            totalStake = totalStake.add(stake);


            currentTranscoder = transcoderPool.getNext(currentTranscoder);
        }


        activeTranscoderSet[currentRound].totalStake = totalStake;
    }





    function reward() external whenSystemNotPaused currentRoundInitialized {
        uint256 currentRound = roundsManager().currentRound();


        require(activeTranscoderSet[currentRound].isActive[msg.sender]);


        require(transcoders[msg.sender].lastRewardRound != currentRound);

        transcoders[msg.sender].lastRewardRound = currentRound;



        uint256 rewardTokens = minter().createReward(activeTranscoderTotalStake(msg.sender, currentRound), activeTranscoderSet[currentRound].totalStake);

        updateTranscoderWithRewards(msg.sender, rewardTokens, currentRound);

        Reward(msg.sender, rewardTokens);
    }






    function updateTranscoderWithFees(
        address _transcoder,
        uint256 _fees,
        uint256 _round
    )
        external
        whenSystemNotPaused
        onlyJobsManager
    {

        require(transcoderStatus(_transcoder) == TranscoderStatus.Registered);

        Transcoder storage t = transcoders[_transcoder];

        EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[_round];

        earningsPool.feePool = earningsPool.feePool.add(_fees);
    }








    function slashTranscoder(
        address _transcoder,
        address _finder,
        uint256 _slashAmount,
        uint256 _finderFee
    )
        external
        whenSystemNotPaused
        onlyJobsManager
    {
        Delegator storage del = delegators[_transcoder];

        if (del.bondedAmount > 0) {
            uint256 penalty = MathUtils.percOf(delegators[_transcoder].bondedAmount, _slashAmount);


            del.bondedAmount = del.bondedAmount.sub(penalty);




            if (delegatorStatus(_transcoder) == DelegatorStatus.Bonded) {
                delegators[del.delegateAddress].delegatedAmount = delegators[del.delegateAddress].delegatedAmount.sub(penalty);
                totalBonded = totalBonded.sub(penalty);
            }


            if (transcoderStatus(_transcoder) == TranscoderStatus.Registered) {
                resignTranscoder(_transcoder);
            }


            uint256 burnAmount = penalty;


            if (_finder != address(0)) {
                uint256 finderAmount = MathUtils.percOf(penalty, _finderFee);
                minter().trustedTransferTokens(_finder, finderAmount);


                minter().trustedBurnTokens(burnAmount.sub(finderAmount));

                TranscoderSlashed(_transcoder, _finder, penalty, finderAmount);
            } else {

                minter().trustedBurnTokens(burnAmount);

                TranscoderSlashed(_transcoder, address(0), penalty, 0);
            }
        } else {
            TranscoderSlashed(_transcoder, _finder, 0, 0);
        }
    }








    function electActiveTranscoder(uint256 _maxPricePerSegment, bytes32 _blockHash, uint256 _round) external view returns (address) {
        uint256 activeSetSize = activeTranscoderSet[_round].transcoders.length;

        address[] memory availableTranscoders = new address[](activeSetSize);

        uint256 numAvailableTranscoders = 0;

        uint256 totalAvailableTranscoderStake = 0;

        for (uint256 i = 0; i < activeSetSize; i++) {
            address activeTranscoder = activeTranscoderSet[_round].transcoders[i];

            if (activeTranscoderSet[_round].isActive[activeTranscoder] && transcoders[activeTranscoder].pricePerSegment <= _maxPricePerSegment) {
                availableTranscoders[numAvailableTranscoders] = activeTranscoder;
                numAvailableTranscoders++;
                totalAvailableTranscoderStake = totalAvailableTranscoderStake.add(activeTranscoderTotalStake(activeTranscoder, _round));
            }
        }

        if (numAvailableTranscoders == 0) {

            return address(0);
        } else {

            uint256 r = uint256(_blockHash) % totalAvailableTranscoderStake;
            uint256 s = 0;
            uint256 j = 0;

            while (s <= r && j < numAvailableTranscoders) {
                s = s.add(activeTranscoderTotalStake(availableTranscoders[j], _round));
                j++;
            }

            return availableTranscoders[j - 1];
        }
    }





    function claimEarnings(uint256 _endRound) external whenSystemNotPaused currentRoundInitialized {

        require(delegators[msg.sender].lastClaimRound < _endRound);

        require(_endRound <= roundsManager().currentRound());

        updateDelegatorWithEarnings(msg.sender, _endRound);
    }






    function pendingStake(address _delegator, uint256 _endRound) public view returns (uint256) {
        uint256 currentRound = roundsManager().currentRound();
        Delegator storage del = delegators[_delegator];

        require(_endRound <= currentRound && _endRound > del.lastClaimRound);

        uint256 currentBondedAmount = del.bondedAmount;

        for (uint256 i = del.lastClaimRound + 1; i <= _endRound; i++) {
            EarningsPool.Data storage earningsPool = transcoders[del.delegateAddress].earningsPoolPerRound[i];

            bool isTranscoder = _delegator == del.delegateAddress;
            if (earningsPool.hasClaimableShares()) {

                currentBondedAmount = currentBondedAmount.add(earningsPool.rewardPoolShare(currentBondedAmount, isTranscoder));
            }
        }

        return currentBondedAmount;
    }






    function pendingFees(address _delegator, uint256 _endRound) public view returns (uint256) {
        uint256 currentRound = roundsManager().currentRound();
        Delegator storage del = delegators[_delegator];

        require(_endRound <= currentRound && _endRound > del.lastClaimRound);

        uint256 currentFees = del.fees;
        uint256 currentBondedAmount = del.bondedAmount;

        for (uint256 i = del.lastClaimRound + 1; i <= _endRound; i++) {
            EarningsPool.Data storage earningsPool = transcoders[del.delegateAddress].earningsPoolPerRound[i];

            if (earningsPool.hasClaimableShares()) {
                bool isTranscoder = _delegator == del.delegateAddress;

                currentFees = currentFees.add(earningsPool.feePoolShare(currentBondedAmount, isTranscoder));


                currentBondedAmount = currentBondedAmount.add(earningsPool.rewardPoolShare(currentBondedAmount, isTranscoder));
            }
        }

        return currentFees;
    }





    function activeTranscoderTotalStake(address _transcoder, uint256 _round) public view returns (uint256) {

        require(activeTranscoderSet[_round].isActive[_transcoder]);

        return transcoders[_transcoder].earningsPoolPerRound[_round].totalStake;
    }





    function transcoderTotalStake(address _transcoder) public view returns (uint256) {
        return transcoderPool.getKey(_transcoder);
    }





    function transcoderStatus(address _transcoder) public view returns (TranscoderStatus) {
        if (transcoderPool.contains(_transcoder)) {
            return TranscoderStatus.Registered;
        } else {
            return TranscoderStatus.NotRegistered;
        }
    }





    function delegatorStatus(address _delegator) public view returns (DelegatorStatus) {
        Delegator storage del = delegators[_delegator];

        if (del.withdrawRound > 0) {

            if (roundsManager().currentRound() >= del.withdrawRound) {
                return DelegatorStatus.Unbonded;
            } else {
                return DelegatorStatus.Unbonding;
            }
        } else if (del.startRound > roundsManager().currentRound()) {

            return DelegatorStatus.Pending;
        } else if (del.startRound > 0 && del.startRound <= roundsManager().currentRound()) {

            return DelegatorStatus.Bonded;
        } else {

            return DelegatorStatus.Unbonded;
        }
    }





    function getTranscoder(
        address _transcoder
    )
        public
        view
        returns (uint256 lastRewardRound, uint256 rewardCut, uint256 feeShare, uint256 pricePerSegment, uint256 pendingRewardCut, uint256 pendingFeeShare, uint256 pendingPricePerSegment)
    {
        Transcoder storage t = transcoders[_transcoder];

        lastRewardRound = t.lastRewardRound;
        rewardCut = t.rewardCut;
        feeShare = t.feeShare;
        pricePerSegment = t.pricePerSegment;
        pendingRewardCut = t.pendingRewardCut;
        pendingFeeShare = t.pendingFeeShare;
        pendingPricePerSegment = t.pendingPricePerSegment;
    }






    function getTranscoderEarningsPoolForRound(
        address _transcoder,
        uint256 _round
    )
        public
        view
        returns (uint256 rewardPool, uint256 feePool, uint256 totalStake, uint256 claimableStake)
    {
        EarningsPool.Data storage earningsPool = transcoders[_transcoder].earningsPoolPerRound[_round];

        rewardPool = earningsPool.rewardPool;
        feePool = earningsPool.feePool;
        totalStake = earningsPool.totalStake;
        claimableStake = earningsPool.claimableStake;
    }





    function getDelegator(
        address _delegator
    )
        public
        view
        returns (uint256 bondedAmount, uint256 fees, address delegateAddress, uint256 delegatedAmount, uint256 startRound, uint256 withdrawRound, uint256 lastClaimRound)
    {
        Delegator storage del = delegators[_delegator];

        bondedAmount = del.bondedAmount;
        fees = del.fees;
        delegateAddress = del.delegateAddress;
        delegatedAmount = del.delegatedAmount;
        startRound = del.startRound;
        withdrawRound = del.withdrawRound;
        lastClaimRound = del.lastClaimRound;
    }




    function getTranscoderPoolMaxSize() public view returns (uint256) {
        return transcoderPool.getMaxSize();
    }




    function getTranscoderPoolSize() public view returns (uint256) {
        return transcoderPool.getSize();
    }




    function getFirstTranscoderInPool() public view returns (address) {
        return transcoderPool.getFirst();
    }





    function getNextTranscoderInPool(address _transcoder) public view returns (address) {
        return transcoderPool.getNext(_transcoder);
    }




    function getTotalBonded() public view returns (uint256) {
        return totalBonded;
    }





    function getTotalActiveStake(uint256 _round) public view returns (uint256) {
        return activeTranscoderSet[_round].totalStake;
    }






    function isActiveTranscoder(address _transcoder, uint256 _round) public view returns (bool) {
        return activeTranscoderSet[_round].isActive[_transcoder];
    }





    function isRegisteredTranscoder(address _transcoder) public view returns (bool) {
        return transcoderStatus(_transcoder) == TranscoderStatus.Registered;
    }




    function resignTranscoder(address _transcoder) internal {
        uint256 currentRound = roundsManager().currentRound();
        if (activeTranscoderSet[currentRound].isActive[_transcoder]) {

            activeTranscoderSet[currentRound].totalStake = activeTranscoderSet[currentRound].totalStake.sub(activeTranscoderTotalStake(_transcoder, currentRound));

            activeTranscoderSet[currentRound].isActive[_transcoder] = false;
        }


        transcoderPool.remove(_transcoder);

        TranscoderResigned(_transcoder);
    }







    function updateTranscoderWithRewards(address _transcoder, uint256 _rewards, uint256 _round) internal {
        Transcoder storage t = transcoders[_transcoder];
        Delegator storage del = delegators[_transcoder];

        EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[_round];

        earningsPool.rewardPool = earningsPool.rewardPool.add(_rewards);

        del.delegatedAmount = del.delegatedAmount.add(_rewards);

        uint256 newStake = transcoderPool.getKey(_transcoder).add(_rewards);
        transcoderPool.updateKey(_transcoder, newStake, address(0), address(0));

        totalBonded = totalBonded.add(_rewards);
    }






    function updateDelegatorWithEarnings(address _delegator, uint256 _endRound) internal {
        Delegator storage del = delegators[_delegator];



        if (del.delegateAddress != address(0)) {





            require(_endRound.sub(del.lastClaimRound) <= maxEarningsClaimsRounds);

            uint256 currentBondedAmount = del.bondedAmount;
            uint256 currentFees = del.fees;

            for (uint256 i = del.lastClaimRound + 1; i <= _endRound; i++) {
                EarningsPool.Data storage earningsPool = transcoders[del.delegateAddress].earningsPoolPerRound[i];

                if (earningsPool.hasClaimableShares()) {
                    bool isTranscoder = _delegator == del.delegateAddress;

                    var (fees, rewards) = earningsPool.claimShare(currentBondedAmount, isTranscoder);

                    currentFees = currentFees.add(fees);
                    currentBondedAmount = currentBondedAmount.add(rewards);
                }
            }


            del.bondedAmount = currentBondedAmount;
            del.fees = currentFees;
        }

        del.lastClaimRound = _endRound;
    }




    function livepeerToken() internal view returns (ILivepeerToken) {
        return ILivepeerToken(controller.getContract(keccak256("LivepeerToken")));
    }




    function minter() internal view returns (IMinter) {
        return IMinter(controller.getContract(keccak256("Minter")));
    }




    function roundsManager() internal view returns (IRoundsManager) {
        return IRoundsManager(controller.getContract(keccak256("RoundsManager")));
    }
}
