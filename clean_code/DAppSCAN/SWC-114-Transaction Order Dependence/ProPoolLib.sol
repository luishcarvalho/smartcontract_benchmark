
pragma solidity ^0.4.24;

import "../abstract/erc/IERC20Base.sol";
import "../abstract/IFeeService.sol";

import "../zeppelin/Math.sol";
import "./QuotaLib.sol";





library ProPoolLib {
    using QuotaLib for QuotaLib.Storage;







    enum State {
        Open,
        PaidToPresale,
        Distribution,
        FullRefund,
        Canceled
    }






    struct Group {




        uint contribution;







        uint remaining;


        uint maxBalance;


        uint minContribution;


        uint maxContribution;


        uint ctorFeePerEther;




        bool isRestricted;


        bool exists;
    }






    struct Participant {


        uint[8] contribution;


        uint[8] remaining;


        bool[8] whitelist;


        bool isAdmin;


        bool exists;
    }






    struct Pool {


        State state;



        uint svcFeePerEther;



        address refundAddress;




        address presaleAddress;



        bool lockPresale;


        IFeeService feeService;




        address feeToTokenAddress;
        bool feeToTokenMode;


        address[] admins;


        address[] participants;


        address[] tokenAddresses;


        Group[8] groups;


        mapping(address => Participant) participantToData;


        mapping(address => QuotaLib.Storage) tokenQuota;


        QuotaLib.Storage refundQuota;
    }




    modifier onlyAdmin(Pool storage pool) {
        require(pool.participantToData[msg.sender].isAdmin);
        _;
    }




    modifier onlyInState(Pool storage pool, State state) {
        require(pool.state == state);
        _;
    }




    modifier onlyInStates2(Pool storage pool, State state1, State state2) {
        require(pool.state == state1 || pool.state == state2);
        _;
    }




    modifier onlyInStates3(Pool storage pool, State state1, State state2, State state3) {
        require(pool.state == state1 || pool.state == state2 || pool.state == state3);
        _;
    }




    function init(
        Pool storage pool,
        uint maxBalance,
        uint minContribution,
        uint maxContribution,
        uint ctorFeePerEther,
        bool isRestricted,
        address creatorAddress,
        address presaleAddress,
        address feeServiceAddr,
        address[] whitelist,
        address[] admins
    )
        public
    {


        if(presaleAddress != address(0)) {
            require(presaleAddress != address(this));
            pool.presaleAddress = presaleAddress;
            emit PresaleAddressLocked(presaleAddress);
        }


        pool.feeService = IFeeService(feeServiceAddr);
        pool.svcFeePerEther = pool.feeService.getFeePerEther();
        require(pool.svcFeePerEther <= (1 ether / 4));
        emit FeeServiceAttached(
            feeServiceAddr,
            pool.svcFeePerEther
        );


        require(creatorAddress != address(0));
        addAdmin(pool, creatorAddress);
        for(uint i = 0; i < admins.length; i++) {
            addAdmin(pool, admins[i]);
        }


        setGroupSettingsCore(
            pool,
            0,
            maxBalance,
            minContribution,
            maxContribution,
            ctorFeePerEther,
            isRestricted
        );


        if(whitelist.length > 0) {
            require(isRestricted);
            modifyWhitelistCore(pool, 0, whitelist, new address[](0));
        }
    }





    function setGroupSettings(
        Pool storage pool,
        uint idx,
        uint maxBalance,
        uint minContribution,
        uint maxContribution,
        uint ctorFeePerEther,
        bool isRestricted
    )
        public
        onlyAdmin(pool)
        onlyInState(pool, State.Open)
    {

        bool exists = pool.groups[idx].exists;


        setGroupSettingsCore(
            pool,
            idx,
            maxBalance,
            minContribution,
            maxContribution,
            ctorFeePerEther,
            isRestricted
        );

        if(exists) {

            groupRebalance(pool, idx);
        }
    }




    function modifyWhitelist(Pool storage pool, uint idx, address[] include, address[] exclude)
        public
        onlyAdmin(pool)
        onlyInState(pool, State.Open)
    {

        modifyWhitelistCore(pool, idx, include, exclude);

        groupRebalance(pool, idx);
    }




    function lockPresaleAddress(Pool storage pool, address presaleAddress, bool lock)
        public
        onlyAdmin(pool)
        onlyInState(pool, State.Open)
    {
        require(presaleAddress != address(0));
        require(presaleAddress != address(this));
        require(pool.presaleAddress == address(0));
        require(!pool.lockPresale);


        pool.presaleAddress = presaleAddress;


        if(lock) {
            pool.lockPresale = true;
        }

        emit PresaleAddressLocked(presaleAddress);
    }




    function confirmTokenAddress(Pool storage pool, address tokenAddress)
        public
        onlyAdmin(pool)
        onlyInStates2(pool, State.PaidToPresale, State.Distribution)
    {
        require(tokenAddress != address(0));
        require(pool.tokenAddresses.length <= 4);
        require(!contains(pool.tokenAddresses, tokenAddress));


        IERC20Base ERC20 = IERC20Base(tokenAddress);
        uint balance = ERC20.balanceOf(address(this));


        require(balance > 0);


        if(pool.state == State.PaidToPresale) {
            changeState(pool, State.Distribution);
            sendFees(pool);
        }


        pool.tokenAddresses.push(tokenAddress);

        emit TokenAddressConfirmed(
            tokenAddress,
            balance
        );
    }




    function setRefundAddress(Pool storage pool, address refundAddress)
        public
        onlyAdmin(pool)
        onlyInStates3(pool, State.PaidToPresale, State.Distribution, State.FullRefund)
    {
        require(refundAddress != address(0));
        require(pool.refundAddress != refundAddress);


        pool.refundAddress = refundAddress;
        emit RefundAddressChanged(refundAddress);


        if(pool.state == State.PaidToPresale) {
            changeState(pool, State.FullRefund);
        }
    }




    function payToPresale(
        Pool storage pool,
        address presaleAddress,
        uint minPoolBalance,
        bool feeToToken,
        bytes data
    )
        public
        onlyAdmin(pool)
        onlyInState(pool, State.Open)
    {
        require(presaleAddress != address(0));


        if(pool.presaleAddress == address(0)) {
            pool.presaleAddress = presaleAddress;
            emit PresaleAddressLocked(presaleAddress);
        } else {

            require(pool.presaleAddress == presaleAddress);
        }

        uint ctorFee;
        uint poolRemaining;
        uint poolContribution;

        (poolContribution, poolRemaining, ctorFee) = calcPoolSummary(pool);
        require(poolContribution > 0 && poolContribution >= minPoolBalance);


        if(feeToToken) {
            pool.feeToTokenMode = true;
            pool.feeToTokenAddress = msg.sender;
            ctorFee = 0;
        }

        changeState(pool, State.PaidToPresale);


        addressCall(
            pool.presaleAddress,
            poolContribution - ctorFee - calcFee(poolContribution, pool.svcFeePerEther),
            data
        );
    }




    function cancel(Pool storage pool)
        public
        onlyAdmin(pool)
        onlyInState(pool, State.Open)
    {
        changeState(pool, State.Canceled);
    }




    function deposit(Pool storage pool, uint idx)
        public
        onlyInState(pool, State.Open)
    {
        require(msg.value > 0);
        require(pool.groups.length > idx);
        require(pool.groups[idx].exists);


        Participant storage participant = pool.participantToData[msg.sender];
        Group storage group = pool.groups[idx];


        uint remaining;
        uint contribution;
        (contribution, remaining) = calcContribution(
            idx,
            msg.value,
            group.maxBalance,
            group.contribution - participant.contribution[idx],
            group.minContribution,
            group.maxContribution,
            group.isRestricted,
            participant
        );


        require(remaining == 0);


        if (!participant.exists) {
            participant.exists = true;
            pool.participants.push(msg.sender);
        }


        if(!participant.whitelist[idx]) {
            participant.whitelist[idx] = true;
        }


        group.contribution = group.contribution - participant.contribution[idx] + contribution;
        group.remaining = group.remaining - participant.remaining[idx] + remaining;
        participant.contribution[idx] = contribution;
        participant.remaining[idx] = remaining;

        emit Contribution(
            msg.sender,
            idx,
            msg.value,
            contribution,
            group.contribution
        );
    }




    function withdrawAmount(Pool storage pool, uint amount, uint idx)
        public
        onlyInState(pool, State.Open)
    {

        Participant storage participant = pool.participantToData[msg.sender];
        uint finalAmount;

        if(amount == 0) {

            finalAmount = participant.contribution[idx] + participant.remaining[idx];
        } else {


            require(amount >= participant.remaining[idx]);
            require(amount <= participant.contribution[idx] + participant.remaining[idx]);
            finalAmount = amount;
        }

        require(finalAmount > 0);


        Group storage group = pool.groups[idx];


        group.remaining -= participant.remaining[idx];


        uint extra = finalAmount - participant.remaining[idx];


        participant.remaining[idx] = 0;

        if(extra > 0) {

            participant.contribution[idx] -= extra;
            group.contribution -= extra;

            if(!participant.isAdmin) {

                require(participant.contribution[idx] >= group.minContribution);
            }
        }


        addressTransfer(msg.sender, finalAmount);

        emit Withdrawal(
            msg.sender,
            finalAmount,
            participant.contribution[idx],
            0,
            group.contribution,
            group.remaining,
            idx
        );
    }




    function withdrawAll(Pool storage pool) public {


        if (pool.state == State.FullRefund || pool.state == State.Distribution) {
            withdrawRefundAndTokens(pool);
            return;
        }


        if(pool.state == State.Canceled || pool.state == State.Open) {
            withdrawAllContribution(pool);
            return;
        }


        if (pool.state == State.PaidToPresale) {
            withdrawAllRemaining1(pool);
            return;
        }


        revert();
    }




    function tokenFallback(Pool storage pool, address from, uint value, bytes data)
        public
        onlyInStates2(pool, State.PaidToPresale, State.Distribution)
    {
        emit ERC223Fallback(
            msg.sender,
            from,
            value,
            data
        );
    }




    function acceptRefundTransfer(Pool storage pool)
        public
        onlyInStates2(pool, State.Distribution, State.FullRefund)
    {
        require(msg.value > 0);
        require(msg.sender == pool.refundAddress);

        emit RefundReceived(
            msg.sender,
            msg.value
        );
    }




    function getPoolDetails1(Pool storage pool)
        public view
        returns (
            uint libVersion,
            uint groupsCount,
            uint currentState,
            uint svcFeePerEther,
            bool feeToTokenMode,
            address presaleAddress,
            address feeToTokenAddress,
            address[] participants,
            address[] admins
        )
    {
        libVersion = version();
        currentState = uint(pool.state);
        groupsCount = pool.groups.length;
        svcFeePerEther = pool.svcFeePerEther;
        feeToTokenMode = pool.feeToTokenMode;
        presaleAddress = pool.presaleAddress;
        feeToTokenAddress = pool.feeToTokenAddress;
        participants = pool.participants;
        admins = pool.admins;
    }




    function getPoolDetails2(Pool storage pool)
        public view
        returns (
            uint refundBalance,
            address refundAddress,
            address[] tokenAddresses,
            uint[] tokenBalances
        )
    {
        if(pool.state == State.Distribution || pool.state == State.FullRefund) {
            uint poolRemaining;
            (,poolRemaining,) = calcPoolSummary(pool);
            refundBalance = address(this).balance - poolRemaining;
            refundAddress = pool.refundAddress;

            tokenAddresses = pool.tokenAddresses;
            tokenBalances = new uint[](tokenAddresses.length);
            for(uint i = 0; i < tokenAddresses.length; i++) {
                tokenBalances[i] = IERC20Base(tokenAddresses[i]).balanceOf(address(this));
            }
        }
    }




    function getParticipantDetails(Pool storage pool, address addr)
        public view
        returns (
            uint[] contribution,
            uint[] remaining,
            bool[] whitelist,
            bool isAdmin,
            bool exists
        )
    {
        Participant storage part = pool.participantToData[addr];
        isAdmin = part.isAdmin;
        exists = part.exists;

        uint length = pool.groups.length;
        contribution = new uint[](length);
        remaining = new uint[](length);
        whitelist = new bool[](length);

        for(uint i = 0; i < length; i++) {
            contribution[i] = part.contribution[i];
            remaining[i] = part.remaining[i];
            whitelist[i] = part.whitelist[i];
        }
    }




    function getParticipantShares(Pool storage pool, address addr) public view returns (uint[] tokenShare, uint refundShare) {
        if(pool.state == State.Distribution || pool.state == State.FullRefund) {
            uint netPoolContribution;
            uint netPartContribution;
            uint poolRemaining;
            uint poolCtorFee;

            (netPoolContribution, netPartContribution, poolRemaining, poolCtorFee) = calcPoolSummary3(pool, addr);
            tokenShare = new uint[](pool.tokenAddresses.length);

            if(netPartContribution > 0) {
                refundShare = pool.refundQuota.calcShare(
                    addr,
                    address(this).balance - poolRemaining,
                    [netPartContribution, netPoolContribution]
                );
            }

            if(pool.feeToTokenMode) {
                netPoolContribution += poolCtorFee;
                if(pool.feeToTokenAddress == addr) {
                    netPartContribution += poolCtorFee;
                }
            }

            if(netPartContribution > 0) {
                for(uint i = 0; i < pool.tokenAddresses.length; i++) {
                    tokenShare[i] = pool.tokenQuota[pool.tokenAddresses[i]].calcShare(
                        addr,
                        IERC20Base(pool.tokenAddresses[i]).balanceOf(address(this)),
                        [netPartContribution, netPoolContribution]
                    );
                }
            }
        }
    }




    function getGroupDetails(Pool storage pool, uint idx)
        public view
        returns (
            uint contributionBalance,
            uint remainingBalance,
            uint maxBalance,
            uint minContribution,
            uint maxContribution,
            uint ctorFeePerEther,
            bool isRestricted,
            bool exists
        )
    {
        Group storage group = pool.groups[idx];
        contributionBalance = group.contribution;
        remainingBalance = group.remaining;
        maxBalance = group.maxBalance;
        minContribution = group.minContribution;
        maxContribution = group.maxContribution;
        ctorFeePerEther = group.ctorFeePerEther;
        isRestricted = group.isRestricted;
        exists = group.exists;
    }




    function version() public pure returns (uint) {



        return 100100101;
    }




    function withdrawAllContribution(Pool storage pool) private {
        Participant storage participant = pool.participantToData[msg.sender];
        Group storage group;
        uint contribution;
        uint remaining;
        uint amount;
        uint sum;


        uint length = pool.groups.length;
        for(uint idx = 0; idx < length; idx++) {


            contribution = participant.contribution[idx];
            remaining = participant.remaining[idx];
            sum = contribution + remaining;

            if(sum > 0) {
                amount += sum;
                group = pool.groups[idx];


                if(contribution > 0) {
                    group.contribution -= contribution;
                    participant.contribution[idx] = 0;
                }


                if(remaining > 0) {
                    group.remaining -= remaining;
                    participant.remaining[idx] = 0;
                }

                emit Withdrawal(
                    msg.sender,
                    idx,
                    sum,
                    0,
                    0,
                    group.contribution,
                    group.remaining
                );
            }
        }


        require(amount > 0);
        addressTransfer(
            msg.sender,
            amount
        );
    }




    function withdrawAllRemaining1(Pool storage pool) private {
        Participant storage participant = pool.participantToData[msg.sender];
        Group storage group;
        uint remaining;
        uint amount;


        uint length = pool.groups.length;
        for(uint idx = 0; idx < length; idx++) {
            remaining = participant.remaining[idx];


            if(remaining > 0) {
                amount += remaining;
                group = pool.groups[idx];
                group.remaining -= remaining;
                participant.remaining[idx] = 0;

                emit Withdrawal(
                    msg.sender,
                    idx,
                    remaining,
                    participant.contribution[idx],
                    0,
                    group.contribution,
                    group.remaining
                );
            }
        }


        require(amount > 0);
        addressTransfer(
            msg.sender,
            amount
        );
    }




    function withdrawAllRemaining2(Pool storage pool)
        private
        returns
    (
        uint poolContribution,
        uint poolRemaining,
        uint poolCtorFee,
        uint partContribution,
        uint partCtorFee
    )
    {
        Participant storage participant = pool.participantToData[msg.sender];
        Group storage group;
        uint sumRemaining;
        uint remaining;


        uint length = pool.groups.length;
        for(uint idx = 0; idx < length; idx++) {
            group = pool.groups[idx];


            poolRemaining += group.remaining;
            poolContribution += group.contribution;
            poolCtorFee += calcFee(group.contribution, group.ctorFeePerEther);


            remaining = participant.remaining[idx];
            partContribution += participant.contribution[idx];
            partCtorFee += calcFee(participant.contribution[idx], group.ctorFeePerEther);


            if(remaining > 0) {
                sumRemaining += remaining;
                group.remaining -= remaining;
                participant.remaining[idx] = 0;

                emit Withdrawal(
                    msg.sender,
                    idx,
                    remaining,
                    participant.contribution[idx],
                    0,
                    group.contribution,
                    group.remaining
                );
            }
        }


        if(sumRemaining > 0) {
            poolRemaining -= sumRemaining;
            addressTransfer(msg.sender, sumRemaining);
        }
    }




    function withdrawRefundAndTokens(Pool storage pool) private {
        uint poolContribution;
        uint poolRemaining;
        uint poolCtorFee;
        uint partContribution;
        uint partCtorFee;


        (poolContribution,
            poolRemaining,
            poolCtorFee,
            partContribution,
            partCtorFee
        ) = withdrawAllRemaining2(pool);


        uint netPoolContribution = poolContribution - poolCtorFee - calcFee(poolContribution, pool.svcFeePerEther);
        uint netPartContribution = partContribution - partCtorFee - calcFee(partContribution, pool.svcFeePerEther);

        if(netPartContribution > 0) {

            withdrawRefundShare(pool, poolRemaining, netPoolContribution, netPartContribution);
        }


        if(pool.feeToTokenMode) {
            netPoolContribution += poolCtorFee;
            if(pool.feeToTokenAddress == msg.sender) {
                netPartContribution += poolCtorFee;
            }
        }

        if(netPartContribution > 0) {

            withdrawTokens(pool, netPoolContribution, netPartContribution);
        }
    }




    function withdrawRefundShare(
        Pool storage pool,
        uint poolRemaining,
        uint netPoolContribution,
        uint netPartContribution
    )
        private
    {
        if(address(this).balance > poolRemaining) {

            uint amount = pool.refundQuota.claimShare(
                msg.sender,
                address(this).balance - poolRemaining,
                [netPartContribution, netPoolContribution]
            );

            if(amount > 0) {

                addressTransfer(msg.sender, amount);
                emit RefundWithdrawal(
                    msg.sender,
                    address(this).balance,
                    poolRemaining,
                    amount
                );
            }
        }
    }




    function withdrawTokens(
        Pool storage pool,
        uint netPoolContribution,
        uint netPartContribution
    )
        private
    {
        bool succeeded;
        uint tokenAmount;
        uint tokenBalance;
        address tokenAddress;
        IERC20Base tokenContract;
        QuotaLib.Storage storage quota;


        uint length = pool.tokenAddresses.length;
        for(uint i = 0; i < length; i++) {

            tokenAddress = pool.tokenAddresses[i];
            tokenContract = IERC20Base(tokenAddress);

            tokenBalance = tokenContract.balanceOf(address(this));

            if(tokenBalance > 0) {

                quota = pool.tokenQuota[tokenAddress];
                tokenAmount = quota.claimShare(
                    msg.sender,
                    tokenBalance,
                    [netPartContribution, netPoolContribution]
                );

                if(tokenAmount > 0) {

                    succeeded = tokenContract.transfer(msg.sender, tokenAmount);
                    if (!succeeded) {
                        quota.undoClaimShare(msg.sender, tokenAmount);
                    }
                    emit TokenWithdrawal(
                        tokenAddress,
                        msg.sender,
                        tokenBalance,
                        tokenAmount,
                        succeeded
                    );
                }
            }
        }
    }




    function setGroupSettingsCore(
        Pool storage pool,
        uint idx,
        uint maxBalance,
        uint minContribution,
        uint maxContribution,
        uint ctorFeePerEther,
        bool isRestricted
    )
        private
    {
        require(pool.groups.length > idx);
        Group storage group = pool.groups[idx];

        if(!group.exists) {

            require(idx == 0 || pool.groups[idx - 1].exists);
            group.exists = true;
        }

        validateGroupSettings(
            maxBalance,
            minContribution,
            maxContribution
        );

        if(group.maxBalance != maxBalance) {
            group.maxBalance = maxBalance;
        }

        if(group.minContribution != minContribution) {
            group.minContribution = minContribution;
        }

        if(group.maxContribution != maxContribution) {
            group.maxContribution = maxContribution;
        }

        if(group.ctorFeePerEther != ctorFeePerEther) {
            require(ctorFeePerEther <= (1 ether / 2));
            group.ctorFeePerEther = ctorFeePerEther;
        }

        if(group.isRestricted != isRestricted) {
            group.isRestricted = isRestricted;
        }

        emit GroupSettingsChanged(
            idx,
            maxBalance,
            minContribution,
            maxContribution,
            ctorFeePerEther,
            isRestricted
        );
    }




    function modifyWhitelistCore(Pool storage pool, uint idx, address[] include, address[] exclude) private {
        require(include.length > 0 || exclude.length > 0);
        require(pool.groups.length > idx && pool.groups[idx].exists);


        Group storage group = pool.groups[idx];
        Participant storage participant;
        uint i;


        if(!group.isRestricted) {
            group.isRestricted = true;
            emit WhitelistEnabled(idx);
        }


        for(i = 0; i < exclude.length; i++) {
            participant = pool.participantToData[exclude[i]];
            if(participant.whitelist[idx]) {
                participant.whitelist[idx] = false;
                emit ExcludedFromWhitelist(
                    exclude[i],
                    idx
                );
            }
        }


        for(i = 0; i < include.length; i++) {
            participant = pool.participantToData[include[i]];

            if(!participant.whitelist[idx]) {

                if (!participant.exists) {
                    pool.participants.push(include[i]);
                    participant.exists = true;
                }


                participant.whitelist[idx] = true;
                emit IncludedInWhitelist(
                    include[i],
                    idx
                );
            }
        }
    }





    function sendFees(Pool storage pool) private {
        uint ctorFee;
        uint poolRemaining;
        uint poolContribution;

        (poolContribution, poolRemaining, ctorFee) = calcPoolSummary(pool);
        if(ctorFee > 0 && !pool.feeToTokenMode) {
            addressTransfer(msg.sender, ctorFee);
        }


        uint svcFee = address(this).balance - poolRemaining;
        if(svcFee > 0) {
            address creator = getPoolCreator(pool);
            pool.feeService.sendFee.value(svcFee)(creator);
        }

        emit FeesDistributed(
            ctorFee,
            svcFee
        );
    }




    function groupRebalance(Pool storage pool, uint idx) private {
        Group storage group = pool.groups[idx];
        uint maxBalance = group.maxBalance;
        uint minContribution = group.minContribution;
        uint maxContribution = group.maxContribution;
        bool isRestricted = group.isRestricted;
        Participant storage participant;
        uint groupContribution;
        uint groupRemaining;
        uint contribution;
        uint remaining;
        uint x = idx;



        for(uint i = 0; i < pool.participants.length; i++) {
            participant = pool.participantToData[pool.participants[i]];


            (contribution, remaining) = calcContribution(
                x,
                0,
                maxBalance,
                groupContribution,
                minContribution,
                maxContribution,
                isRestricted,
                participant
            );


            if(contribution != participant.contribution[x]) {
                participant.contribution[x] = contribution;
                participant.remaining[x] = remaining;
            }

            groupContribution += contribution;
            groupRemaining += remaining;

            emit ContributionAdjusted(
                pool.participants[i],
                contribution,
                remaining,
                groupContribution,
                groupRemaining,
                x
            );
        }


        if(group.contribution != groupContribution) {
            group.contribution = groupContribution;
            group.remaining = groupRemaining;
        }
    }




    function changeState(Pool storage pool, State state) private {
        assert(pool.state != state);
        emit StateChanged(
            uint(pool.state),
            uint(state)
        );
        pool.state = state;
    }




    function addAdmin(Pool storage pool, address admin) private {
        require(admin != address(0));
        Participant storage participant = pool.participantToData[admin];
        require(!participant.exists && !participant.isAdmin);

        participant.exists = true;
        participant.isAdmin = true;
        pool.participants.push(admin);
        pool.admins.push(admin);

        emit AdminAdded(admin);
    }




    function addressTransfer(address destination, uint etherAmount) private {
        emit AddressTransfer(
            destination,
            etherAmount
        );
        destination.transfer(etherAmount);
    }




    function addressCall(address destination, uint etherAmount, bytes data) private {
        addressCall(destination, 0, etherAmount, data);
    }




    function addressCall(address destination, uint gasAmount,  uint etherAmount, bytes data) private {
        emit AddressCall(
            destination,
            etherAmount,
            gasAmount > 0 ? gasAmount : gasleft(),
            data
        );
        require(
            destination.call
            .gas(gasAmount > 0 ? gasAmount : gasleft())
            .value(etherAmount)
            (data)
        );
    }




    function calcContribution(
        uint idx,
        uint amount,
        uint maxBalance,
        uint currentBalance,
        uint minContribution,
        uint maxContribution,
        bool isRestricted,
        Participant storage participant
    )
        private view
        returns(uint contribution, uint remaining)
    {

        uint totalAmount = participant.contribution[idx]
            + participant.remaining[idx]
            + amount;


        if(participant.isAdmin) {
            contribution = totalAmount;
            return;
        }


        if(currentBalance >= maxBalance || (isRestricted && !participant.whitelist[idx])) {
            remaining = totalAmount;
            return;
        }

        contribution = Math.min(maxContribution, totalAmount);
        contribution = Math.min(maxBalance - currentBalance, contribution);


        if(contribution < minContribution) {
            remaining = totalAmount;
            contribution = 0;
            return;
        }

        remaining = totalAmount - contribution;
    }




    function calcPoolSummary(Pool storage pool)
        private view
        returns
    (
        uint poolContribution,
        uint poolRemaining,
        uint ctorFee
    )
    {
        Group storage group;
        uint length = pool.groups.length;

        for(uint idx = 0; idx < length; idx++) {
            group = pool.groups[idx];
            if(!group.exists) {
                break;
            }

            poolRemaining += group.remaining;
            poolContribution += group.contribution;
            ctorFee += calcFee(group.contribution, group.ctorFeePerEther);
        }
    }




    function calcPoolSummary2(Pool storage pool, address addr)
        private view
        returns
    (
        uint poolContribution,
        uint poolRemaining,
        uint poolCtorFee,
        uint partContribution,
        uint partCtorFee
    )
    {
        Group storage group;
        Participant storage participant = pool.participantToData[addr];
        uint length = pool.groups.length;

        for(uint idx = 0; idx < length; idx++) {
            group = pool.groups[idx];
            if(!group.exists) {
                break;
            }

            poolRemaining += group.remaining;
            poolContribution += group.contribution;
            poolCtorFee += calcFee(group.contribution, group.ctorFeePerEther);

            partContribution += participant.contribution[idx];
            partCtorFee += calcFee(participant.contribution[idx], group.ctorFeePerEther);
        }
    }




    function calcPoolSummary3(Pool storage pool, address addr)
        private view
        returns
    (
        uint netPoolContribution,
        uint netPartContribution,
        uint poolRemaining,
        uint poolCtorFee
    )
    {
        uint poolContribution;
        uint partContribution;
        uint partCtorFee;

        (poolContribution,
            poolRemaining,
            poolCtorFee,
            partContribution,
            partCtorFee
        ) = calcPoolSummary2(pool, addr);

        netPoolContribution = poolContribution - poolCtorFee - calcFee(poolContribution, pool.svcFeePerEther);
        netPartContribution = partContribution - partCtorFee - calcFee(partContribution, pool.svcFeePerEther);
    }




    function validateGroupSettings(uint maxBalance, uint minContribution, uint maxContribution) private pure {
        require(
            minContribution > 0 &&
            minContribution <= maxContribution &&
            maxContribution <= maxBalance &&
            maxBalance <= 1e9 ether
        );
    }




    function contains(address[] storage array, address addr) private view returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == addr) {
                return true;
            }
        }
        return false;
    }




    function getPoolCreator(Pool storage pool) private view returns(address) {
        return pool.admins[0];
    }




    function calcFee(uint etherAmount, uint feePerEther) private pure returns(uint fee) {
        fee = (etherAmount * feePerEther) / 1 ether;
    }


    event StateChanged(
        uint fromState,
        uint toState
    );

    event AdminAdded(
        address adminAddress
    );

    event WhitelistEnabled(
        uint groupIndex
    );

    event PresaleAddressLocked(
        address presaleAddress
    );

    event RefundAddressChanged(
        address refundAddress
    );

    event FeesDistributed(
        uint creatorFeeAmount,
        uint serviceFeeAmount
    );

    event IncludedInWhitelist(
        address participantAddress,
        uint groupIndex
    );

    event ExcludedFromWhitelist(
        address participantAddress,
        uint groupIndex
    );

    event FeeServiceAttached(
        address serviceAddress,
        uint feePerEther
    );

    event TokenAddressConfirmed(
        address tokenAddress,
        uint tokenBalance
    );

    event RefundReceived(
        address senderAddress,
        uint etherAmount
    );

    event Contribution(
        address participantAddress,
        uint groupIndex,
        uint etherAmount,
        uint participantContribution,
        uint groupContribution
    );

    event Withdrawal(
        address participantAddress,
        uint groupIndex,
        uint etherAmount,
        uint participantContribution,
        uint participantRemaining,
        uint groupContribution,
        uint groupRemaining
    );

    event TokenWithdrawal(
        address tokenAddress,
        address participantAddress,
        uint poolTokenBalance,
        uint tokenAmount,
        bool succeeded
    );

    event RefundWithdrawal(
        address participantAddress,
        uint contractBalance,
        uint poolRemaining,
        uint etherAmount
    );

    event ContributionAdjusted(
        address participantAddress,
        uint participantContribution,
        uint participantRemaining,
        uint groupContribution,
        uint groupRemaining,
        uint groupIndex
    );

    event GroupSettingsChanged(
        uint index,
        uint maxBalance,
        uint minContribution,
        uint maxContribution,
        uint ctorFeePerEther,
        bool isRestricted
    );

    event AddressTransfer(
        address destinationAddress,
        uint etherValue
    );

    event AddressCall(
        address destinationAddress,
        uint etherAmount,
        uint gasAmount,
        bytes data
    );

    event TransactionForwarded(
        address destinationAddress,
        uint etherAmount,
        uint gasAmount,
        bytes data
    );

    event ERC223Fallback(
        address tokenAddress,
        address senderAddress,
        uint tokenAmount,
        bytes data
    );
}
