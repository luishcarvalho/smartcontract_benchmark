









pragma solidity 0.5.7;






interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
        external returns (bool);

    function transferFrom(address from, address to, uint256 value)
        external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external view returns (uint256);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}



pragma solidity 0.5.7;






library SafeMath {




    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;


        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a - b;

        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}































































    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }






    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }







    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }










    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }










    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }










    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }





    function addToWhiteList(address _member) public onlyOperator returns (bool) {
        whiteListed[_member] = true;
        emit WhiteListed(_member);
        return true;
    }





    function removeFromWhiteList(address _member) public onlyOperator returns (bool) {
        whiteListed[_member] = false;
        emit BlackListed(_member);
        return true;
    }





    function changeOperator(address _newOperator) public onlyOperator returns (bool) {
        operator = _newOperator;
        return true;
    }






    function burn(uint256 amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }






    function burnFrom(address from, uint256 value) public returns (bool) {
        _burnFrom(from, value);
        return true;
    }







    function mint(address account, uint256 amount) public onlyOperator {
        _mint(account, amount);
    }






    function transfer(address to, uint256 value) public canTransfer(to) returns (bool) {

        require(isLockedForMV[msg.sender] < now);
        require(value <= _balances[msg.sender]);
        _transfer(to, value);
        return true;
    }






    function operatorTransfer(address from, uint256 value) public onlyOperator returns (bool) {
        require(value <= _balances[from]);
        _transferFrom(from, operator, value);
        return true;
    }







    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        canTransfer(to)
        returns (bool)
    {
        require(isLockedForMV[from] < now);
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        _transferFrom(from, to, value);
        return true;
    }





    function lockForMemberVote(address _of, uint _days) public onlyOperator {
        if (_days.add(now) > isLockedForMV[_of])
            isLockedForMV[_of] = _days.add(now);
    }






    function _transfer(address to, uint256 value) internal {
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
    }







    function _transferFrom(
        address from,
        address to,
        uint256 value
    )
        internal
    {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
    }








    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }







    function _burn(address account, uint256 amount) internal {
        require(amount <= _balances[account]);

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }








    function _burnFrom(address account, uint256 value) internal {
        require(value <= _allowed[account][msg.sender]);



        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
        value);
        _burn(account, value);
    }
}
















































































































































































































































    function  changeDependentContractAddress() public;





    function changeMasterAddress(address _masterAddress) public {
        if (address(ms) != address(0)) {
            require(address(ms) == msg.sender, "Not master");
        }
        ms = INXMMaster(_masterAddress);
        nxMasterAddress = _masterAddress;
    }

}



pragma solidity ^0.5.7;

interface IPooledStaking {

    function accumulateReward(address contractAddress, uint amount) external;
    function pushBurn(address contractAddress, uint amount) external;
    function hasPendingActions() external view returns (bool);

    function contractStake(address contractAddress) external view returns (uint);
    function stakerReward(address staker) external view returns (uint);
    function stakerDeposit(address staker) external view returns (uint);
    function stakerContractStake(address staker, address contractAddress) external view returns (uint);

    function withdraw(uint amount) external;
    function stakerMaxWithdrawable(address stakerAddress) external view returns (uint);
    function withdrawReward(address stakerAddress) external;
}













































    function pushStakerRewards(address _contractAddress, uint _coverPriceNXM) external onlyInternal {
        uint rewardValue = _coverPriceNXM.mul(td.stakerCommissionPer()).div(100);
        pooledStaking.accumulateReward(_contractAddress, rewardValue);
    }




    function burnStakerLockedToken(uint, bytes4, uint) external {

    }







    function burnStakedTokens(uint coverId, bytes4 coverCurrency, uint sumAssured) external onlyInternal {
        (, address scAddress) = qd.getscAddressOfCover(coverId);
        uint tokenPrice = m1.calculateTokenPrice(coverCurrency);
        uint burnNXMAmount = sumAssured.mul(1e18).div(tokenPrice);
        pooledStaking.pushBurn(scAddress, burnNXMAmount);
    }







    function deprecated_getTotalStakedTokensOnSmartContract(
        address _stakedContractAddress
    )
        external
        view
        returns(uint)
    {
        uint stakedAmount = 0;
        address stakerAddress;
        uint staketLen = td.getStakedContractStakersLength(_stakedContractAddress);

        for (uint i = 0; i < staketLen; i++) {
            stakerAddress = td.getStakedContractStakerByIndex(_stakedContractAddress, i);
            uint stakerIndex = td.getStakedContractStakerIndex(
                _stakedContractAddress, i);
            uint currentlyStaked;
            (, currentlyStaked) = _deprecated_unlockableBeforeBurningAndCanBurn(stakerAddress,
                _stakedContractAddress, stakerIndex);
            stakedAmount = stakedAmount.add(currentlyStaked);
        }

        return stakedAmount;
    }






    function getUserLockedCNTokens(address _of, uint _coverId) external view returns(uint) {
        return _getUserLockedCNTokens(_of, _coverId);
    }






    function getUserAllLockedCNTokens(address _of) external view returns(uint amount) {
        for (uint i = 0; i < qd.getUserCoverLength(_of); i++) {
            amount = amount.add(_getUserLockedCNTokens(_of, qd.getAllCoversOfUser(_of)[i]));
        }
    }





    function getLockedCNAgainstCover(uint _coverId) external view returns(uint) {
        return _getLockedCNAgainstCover(_coverId);
    }





    function deprecated_getStakerAllLockedTokens(address _stakerAddress) external view returns (uint amount) {
        uint stakedAmount = 0;
        address scAddress;
        uint scIndex;
        for (uint i = 0; i < td.getStakerStakedContractLength(_stakerAddress); i++) {
            scAddress = td.getStakerStakedContractByIndex(_stakerAddress, i);
            scIndex = td.getStakerStakedContractIndex(_stakerAddress, i);
            uint currentlyStaked;
            (, currentlyStaked) = _deprecated_unlockableBeforeBurningAndCanBurn(_stakerAddress, scAddress, i);
            stakedAmount = stakedAmount.add(currentlyStaked);
        }
        amount = stakedAmount;
    }





    function deprecated_getStakerAllUnlockableStakedTokens(
        address _stakerAddress
    )
    external
    view
    returns (uint amount)
    {
        uint unlockableAmount = 0;
        address scAddress;
        uint scIndex;
        for (uint i = 0; i < td.getStakerStakedContractLength(_stakerAddress); i++) {
            scAddress = td.getStakerStakedContractByIndex(_stakerAddress, i);
            scIndex = td.getStakerStakedContractIndex(_stakerAddress, i);
            unlockableAmount = unlockableAmount.add(
                _deprecated_getStakerUnlockableTokensOnSmartContract(_stakerAddress, scAddress,
                scIndex));
        }
        amount = unlockableAmount;
    }




    function changeDependentContractAddress() public {
        tk = NXMToken(ms.tokenAddress());
        td = TokenData(ms.getLatestAddress("TD"));
        tc = TokenController(ms.getLatestAddress("TC"));
        cr = ClaimsReward(ms.getLatestAddress("CR"));
        qd = QuotationData(ms.getLatestAddress("QD"));
        m1 = MCR(ms.getLatestAddress("MC"));
        gv = Governance(ms.getLatestAddress("GV"));
        mr = MemberRoles(ms.getLatestAddress("MR"));
        pd = PoolData(ms.getLatestAddress("PD"));
        pooledStaking = IPooledStaking(ms.getLatestAddress("PS"));
    }






    function getTokenPrice(bytes4 curr) public view returns(uint price) {
        price = m1.calculateTokenPrice(curr);
    }





    function depositCN(uint coverId) public onlyInternal returns (bool success) {
        require(_getLockedCNAgainstCover(coverId) > 0, "No cover note available");
        td.setDepositCN(coverId, true);
        success = true;
    }






    function extendCNEPOff(address _of, uint _coverId, uint _lockTime) public onlyInternal {
        uint timeStamp = now.add(_lockTime);
        uint coverValidUntil = qd.getValidityOfCover(_coverId);
        if (timeStamp >= coverValidUntil) {
            bytes32 reason = keccak256(abi.encodePacked("CN", _of, _coverId));
            tc.extendLockOf(_of, reason, timeStamp);
        }
    }






    function burnDepositCN(uint coverId) public onlyInternal returns (bool success) {
        address _of = qd.getCoverMemberAddress(coverId);
        uint amount;
        (amount, ) = td.depositedCN(coverId);
        amount = (amount.mul(50)).div(100);
        bytes32 reason = keccak256(abi.encodePacked("CN", _of, coverId));
        tc.burnLockedTokens(_of, reason, amount);
        success = true;
    }





    function unlockCN(uint coverId) public onlyInternal {
        (, bool isDeposited) = td.depositedCN(coverId);
        require(!isDeposited,"Cover note is deposited and can not be released");
        uint lockedCN = _getLockedCNAgainstCover(coverId);
        if (lockedCN != 0) {
            address coverHolder = qd.getCoverMemberAddress(coverId);
            bytes32 reason = keccak256(abi.encodePacked("CN", coverHolder, coverId));
            tc.releaseLockedTokens(coverHolder, reason, lockedCN);
        }
    }







    function burnCAToken(uint claimid, uint _value, address _of) public {

        require(ms.checkIsAuthToGoverned(msg.sender));
        tc.burnLockedTokens(_of, "CLA", _value);
        emit BurnCATokens(claimid, _of, _value);
    }








    function lockCN(
        uint coverNoteAmount,
        uint coverPeriod,
        uint coverId,
        address _of
    )
        public
        onlyInternal
    {
        uint validity = (coverPeriod * 1 days).add(td.lockTokenTimeAfterCoverExp());
        bytes32 reason = keccak256(abi.encodePacked("CN", _of, coverId));
        td.setDepositCNAmount(coverId, coverNoteAmount);
        tc.lockOf(_of, reason, coverNoteAmount, validity);
    }






    function isLockedForMemberVote(address _of) public view returns(bool) {
        return now < tk.isLockedForMV(_of);
    }








    function deprecated_getStakerLockedTokensOnSmartContract (
        address _stakerAddress,
        address _stakedContractAddress,
        uint _stakedContractIndex
    )
        public
        view
        returns
        (uint amount)
    {
        amount = _deprecated_getStakerLockedTokensOnSmartContract(_stakerAddress,
            _stakedContractAddress, _stakedContractIndex);
    }








    function deprecated_getStakerUnlockableTokensOnSmartContract (
        address stakerAddress,
        address stakedContractAddress,
        uint stakerIndex
    )
        public
        view
        returns (uint)
    {
        return _deprecated_getStakerUnlockableTokensOnSmartContract(stakerAddress, stakedContractAddress,
        td.getStakerStakedContractIndex(stakerAddress, stakerIndex));
    }




    function deprecated_unlockStakerUnlockableTokens(address _stakerAddress) public checkPause {
        uint unlockableAmount;
        address scAddress;
        bytes32 reason;
        uint scIndex;
        for (uint i = 0; i < td.getStakerStakedContractLength(_stakerAddress); i++) {
            scAddress = td.getStakerStakedContractByIndex(_stakerAddress, i);
            scIndex = td.getStakerStakedContractIndex(_stakerAddress, i);
            unlockableAmount = _deprecated_getStakerUnlockableTokensOnSmartContract(
            _stakerAddress, scAddress,
            scIndex);
            td.setUnlockableBeforeLastBurnTokens(_stakerAddress, i, 0);
            td.pushUnlockedStakedTokens(_stakerAddress, i, unlockableAmount);
            reason = keccak256(abi.encodePacked("UW", _stakerAddress, scAddress, scIndex));
            tc.releaseLockedTokens(_stakerAddress, reason, unlockableAmount);
        }
    }









    function _deprecated_unlockableBeforeBurningAndCanBurn(
        address stakerAdd,
        address stakedAdd,
        uint stakerIndex
    )
    public
    view
    returns
    (uint amount, uint canBurn) {

        uint dateAdd;
        uint initialStake;
        uint totalBurnt;
        uint ub;
        (, , dateAdd, initialStake, , totalBurnt, ub) = td.stakerStakedContracts(stakerAdd, stakerIndex);
        canBurn = _deprecated_calculateStakedTokens(initialStake, now.sub(dateAdd).div(1 days), td.scValidDays());

        int v = int(initialStake - (canBurn) - (totalBurnt) - (
            td.getStakerUnlockedStakedTokens(stakerAdd, stakerIndex)) - (ub));
        uint currentLockedTokens = _deprecated_getStakerLockedTokensOnSmartContract(
            stakerAdd, stakedAdd, td.getStakerStakedContractIndex(stakerAdd, stakerIndex));
        if (v < 0) {
            v = 0;
        }
        amount = uint(v);
        if (canBurn > currentLockedTokens.sub(amount).sub(ub)) {
            canBurn = currentLockedTokens.sub(amount).sub(ub);
        }
    }








    function _deprecated_getStakerUnlockableTokensOnSmartContract (
        address _stakerAddress,
        address _stakedContractAddress,
        uint _stakedContractIndex
    )
        public
        view
        returns
        (uint amount)
    {
        uint initialStake;
        uint stakerIndex = td.getStakedContractStakerIndex(
            _stakedContractAddress, _stakedContractIndex);
        uint burnt;
        (, , , initialStake, , burnt,) = td.stakerStakedContracts(_stakerAddress, stakerIndex);
        uint alreadyUnlocked = td.getStakerUnlockedStakedTokens(_stakerAddress, stakerIndex);
        uint currentStakedTokens;
        (, currentStakedTokens) = _deprecated_unlockableBeforeBurningAndCanBurn(_stakerAddress,
            _stakedContractAddress, stakerIndex);
        amount = initialStake.sub(currentStakedTokens).sub(alreadyUnlocked).sub(burnt);
    }








    function _deprecated_getStakerLockedTokensOnSmartContract (
        address _stakerAddress,
        address _stakedContractAddress,
        uint _stakedContractIndex
    )
        internal
        view
        returns
        (uint amount)
    {
        bytes32 reason = keccak256(abi.encodePacked("UW", _stakerAddress,
            _stakedContractAddress, _stakedContractIndex));
        amount = tc.tokensLocked(_stakerAddress, reason);
    }





    function _getLockedCNAgainstCover(uint _coverId) internal view returns(uint) {
        address coverHolder = qd.getCoverMemberAddress(_coverId);
        bytes32 reason = keccak256(abi.encodePacked("CN", coverHolder, _coverId));
        return tc.tokensLockedAtTime(coverHolder, reason, now);
    }






    function _getUserLockedCNTokens(address _of, uint _coverId) internal view returns(uint) {
        bytes32 reason = keccak256(abi.encodePacked("CN", _of, _coverId));
        return tc.tokensLockedAtTime(_of, reason, now);
    }








    function _deprecated_calculateStakedTokens(
        uint _stakeAmount,
        uint _stakeDays,
        uint _validDays
    )
        internal
        pure
        returns (uint amount)
    {
        if (_validDays > _stakeDays) {
            uint rf = ((_validDays.sub(_stakeDays)).mul(100000)).div(_validDays);
            amount = (rf.mul(_stakeAmount)).div(100000);
        } else {
            amount = 0;
        }
    }







    function _deprecated_burnStakerTokenLockedAgainstSmartContract(
        address _stakerAddress,
        address _stakedContractAddress,
        uint _stakedContractIndex,
        uint _amount
    )
        internal
    {
        uint stakerIndex = td.getStakedContractStakerIndex(
            _stakedContractAddress, _stakedContractIndex);
        td.pushBurnedTokens(_stakerAddress, stakerIndex, _amount);
        bytes32 reason = keccak256(abi.encodePacked("UW", _stakerAddress,
            _stakedContractAddress, _stakedContractIndex));
        tc.burnLockedTokens(_stakerAddress, reason, _amount);
    }
}











































































contract IERC1132 {



    mapping(address => bytes32[]) public lockReason;




    struct LockToken {
        uint256 amount;
        uint256 validity;
        bool claimed;
    }





    mapping(address => mapping(bytes32 => LockToken)) public locked;




    event Locked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount,
        uint256 _validity
    );




    event Unlocked(
        address indexed _of,
        bytes32 indexed _reason,
        uint256 _amount
    );








    function lock(bytes32 _reason, uint256 _amount, uint256 _time)
        public returns (bool);








    function tokensLocked(address _of, bytes32 _reason)
        public view returns (uint256 amount);









    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public view returns (uint256 amount);





    function totalBalanceOf(address _of)
        public view returns (uint256 amount);






    function extendLock(bytes32 _reason, uint256 _time)
        public returns (bool);






    function increaseLockAmount(bytes32 _reason, uint256 _amount)
        public returns (bool);






    function tokensUnlockable(address _of, bytes32 _reason)
        public view returns (uint256 amount);





    function unlock(address _of)
        public returns (uint256 unlockableTokens);





    function getUnlockableTokens(address _of)
        public view returns (uint256 unlockableTokens);

}






































    function changeDependentContractAddress() public {
        token = NXMToken(ms.tokenAddress());
        pooledStaking = IPooledStaking(ms.getLatestAddress('PS'));
    }





    function changeOperator(address _newOperator) public onlyInternal {
        token.changeOperator(_newOperator);
    }







    function operatorTransfer(address _from, address _to, uint _value) onlyInternal external returns (bool) {
        require(msg.sender == address(pooledStaking), "Call is only allowed from PooledStaking address");
        require(token.operatorTransfer(_from, _value), "Operator transfer failed");
        require(token.transfer(_to, _value), "Internal transfer failed");
        return true;
    }








    function lock(bytes32 _reason, uint256 _amount, uint256 _time) public checkPause returns (bool)
    {
        require(_reason == CLA,"Restricted to reason CLA");
        require(minCALockTime <= _time,"Should lock for minimum time");


        _lock(msg.sender, _reason, _amount, _time);
        return true;
    }









    function lockOf(address _of, bytes32 _reason, uint256 _amount, uint256 _time)
        public
        onlyInternal
        returns (bool)
    {


        _lock(_of, _reason, _amount, _time);
        return true;
    }






    function extendLock(bytes32 _reason, uint256 _time)
        public
        checkPause
        returns (bool)
    {
        require(_reason == CLA,"Restricted to reason CLA");
        _extendLock(msg.sender, _reason, _time);
        return true;
    }






    function extendLockOf(address _of, bytes32 _reason, uint256 _time)
        public
        onlyInternal
        returns (bool)
    {
        _extendLock(_of, _reason, _time);
        return true;
    }






    function increaseLockAmount(bytes32 _reason, uint256 _amount)
        public
        checkPause
        returns (bool)
    {
        require(_reason == CLA,"Restricted to reason CLA");
        require(_tokensLocked(msg.sender, _reason) > 0);
        token.operatorTransfer(msg.sender, _amount);

        locked[msg.sender][_reason].amount = locked[msg.sender][_reason].amount.add(_amount);

        emit Locked(msg.sender, _reason, _amount, locked[msg.sender][_reason].validity);
        return true;
    }







    function burnFrom (address _of, uint amount) public onlyInternal returns (bool) {
        return token.burnFrom(_of, amount);
    }







    function burnLockedTokens(address _of, bytes32 _reason, uint256 _amount) public onlyInternal {
        _burnLockedTokens(_of, _reason, _amount);
    }







    function reduceLock(address _of, bytes32 _reason, uint256 _time) public onlyInternal {
        _reduceLock(_of, _reason, _time);
    }







    function releaseLockedTokens(address _of, bytes32 _reason, uint256 _amount)
        public
        onlyInternal
    {
        _releaseLockedTokens(_of, _reason, _amount);
    }





    function addToWhitelist(address _member) public onlyInternal {
        token.addToWhiteList(_member);
    }





    function removeFromWhitelist(address _member) public onlyInternal {
        token.removeFromWhiteList(_member);
    }






    function mint(address _member, uint _amount) public onlyInternal {
        token.mint(_member, _amount);
    }





    function lockForMemberVote(address _of, uint _days) public onlyInternal {
        token.lockForMemberVote(_of, _days);
    }





    function unlock(address _of)
        public
        checkPause
        returns (uint256 unlockableTokens)
    {
        unlockableTokens = _tokensUnlockable(_of, CLA);
        if (unlockableTokens > 0) {
            locked[_of][CLA].claimed = true;
            emit Unlocked(_of, CLA, unlockableTokens);
            require(token.transfer(_of, unlockableTokens));
        }
    }






    function updateUintParameters(bytes8 code, uint val) public {
        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "MNCLT") {
            minCALockTime = val.mul(1 days);
        } else {
            revert("Invalid param code");
        }
    }






    function getLockedTokensValidity(address _of, bytes32 reason)
        public
        view
        returns (uint256 validity)
    {
        validity = locked[_of][reason].validity;
    }





    function getUnlockableTokens(address _of)
        public
        view
        returns (uint256 unlockableTokens)
    {
        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            unlockableTokens = unlockableTokens.add(_tokensUnlockable(_of, lockReason[_of][i]));
        }
    }








    function tokensLocked(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        return _tokensLocked(_of, _reason);
    }






    function tokensUnlockable(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        return _tokensUnlockable(_of, _reason);
    }

    function totalSupply() public view returns (uint256)
    {
        return token.totalSupply();
    }









    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public
        view
        returns (uint256 amount)
    {
        return _tokensLockedAtTime(_of, _reason, _time);
    }









    function totalBalanceOf(address _of) public view returns (uint256 amount) {

        amount = token.balanceOf(_of);

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            amount = amount.add(_tokensLocked(_of, lockReason[_of][i]));
        }

        uint stakerReward = pooledStaking.stakerReward(_of);
        uint stakerDeposit = pooledStaking.stakerDeposit(_of);

        amount = amount.add(stakerDeposit).add(stakerReward);
    }










    function totalLockedBalance(address _of, uint256 _time) public view returns (uint256 amount) {

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            amount = amount.add(_tokensLockedAtTime(_of, lockReason[_of][i], _time));
        }

        amount = amount.add(pooledStaking.stakerDeposit(_of));
    }









    function _lock(address _of, bytes32 _reason, uint256 _amount, uint256 _time) internal {
        require(_tokensLocked(_of, _reason) == 0);
        require(_amount != 0);

        if (locked[_of][_reason].amount == 0) {
            lockReason[_of].push(_reason);
        }

        require(token.operatorTransfer(_of, _amount));

        uint256 validUntil = now.add(_time);
        locked[_of][_reason] = LockToken(_amount, validUntil, false);
        emit Locked(_of, _reason, _amount, validUntil);
    }








    function _tokensLocked(address _of, bytes32 _reason)
        internal
        view
        returns (uint256 amount)
    {
        if (!locked[_of][_reason].claimed) {
            amount = locked[_of][_reason].amount;
        }
    }









    function _tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        internal
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity > _time) {
            amount = locked[_of][_reason].amount;
        }
    }







    function _extendLock(address _of, bytes32 _reason, uint256 _time) internal {
        require(_tokensLocked(_of, _reason) > 0);
        emit Unlocked(_of, _reason, locked[_of][_reason].amount);
        locked[_of][_reason].validity = locked[_of][_reason].validity.add(_time);
        emit Locked(_of, _reason, locked[_of][_reason].amount, locked[_of][_reason].validity);
    }







    function _reduceLock(address _of, bytes32 _reason, uint256 _time) internal {
        require(_tokensLocked(_of, _reason) > 0);
        emit Unlocked(_of, _reason, locked[_of][_reason].amount);
        locked[_of][_reason].validity = locked[_of][_reason].validity.sub(_time);
        emit Locked(_of, _reason, locked[_of][_reason].amount, locked[_of][_reason].validity);
    }






    function _tokensUnlockable(address _of, bytes32 _reason) internal view returns (uint256 amount)
    {
        if (locked[_of][_reason].validity <= now && !locked[_of][_reason].claimed) {
            amount = locked[_of][_reason].amount;
        }
    }







    function _burnLockedTokens(address _of, bytes32 _reason, uint256 _amount) internal {
        uint256 amount = _tokensLocked(_of, _reason);
        require(amount >= _amount);

        if (amount == _amount) {
            locked[_of][_reason].claimed = true;
        }

        locked[_of][_reason].amount = locked[_of][_reason].amount.sub(_amount);
        if (locked[_of][_reason].amount == 0) {
            _removeReason(_of, _reason);
        }
        token.burn(_amount);
        emit Burned(_of, _reason, _amount);
    }







    function _releaseLockedTokens(address _of, bytes32 _reason, uint256 _amount) internal
    {
        uint256 amount = _tokensLocked(_of, _reason);
        require(amount >= _amount);

        if (amount == _amount) {
            locked[_of][_reason].claimed = true;
        }

        locked[_of][_reason].amount = locked[_of][_reason].amount.sub(_amount);
        if (locked[_of][_reason].amount == 0) {
            _removeReason(_of, _reason);
        }
        require(token.transfer(_of, _amount));
        emit Unlocked(_of, _reason, _amount);
    }

    function _removeReason(address _of, bytes32 _reason) internal {
        uint len = lockReason[_of].length;
        for (uint i = 0; i < len; i++) {
            if (lockReason[_of][i] == _reason) {
                lockReason[_of][i] = lockReason[_of][len.sub(1)];
                lockReason[_of].pop();
                break;
            }
        }
    }
}


















































































































































    function setpendingClaimStart(uint _start) external onlyInternal {
        require(pendingClaimStart <= _start);
        pendingClaimStart = _start;
    }






    function setRewardDistributedIndexCA(address _voter, uint caIndex) external onlyInternal {
        voterVoteRewardReceived[_voter].lastCAvoteIndex = caIndex;

    }





    function setUserClaimVotePausedOn(address user) external {
        require(ms.checkIsAuthToGoverned(msg.sender));
        userClaimVotePausedOn[user] = now;
    }






    function setRewardDistributedIndexMV(address _voter, uint mvIndex) external onlyInternal {

        voterVoteRewardReceived[_voter].lastMVvoteIndex = mvIndex;
    }







    function setClaimRewardDetail(
        uint claimid,
        uint percCA,
        uint percMV,
        uint tokens
    )
        external
        onlyInternal
    {
        claimRewardDetail[claimid].percCA = percCA;
        claimRewardDetail[claimid].percMV = percMV;
        claimRewardDetail[claimid].tokenToBeDist = tokens;
    }






    function setRewardClaimed(uint _voteid, bool claimed) external onlyInternal {
        allvotes[_voteid].rewardClaimed = claimed;
    }






    function changeFinalVerdict(uint _claimId, int8 _verdict) external onlyInternal {
        claimVote[_claimId] = _verdict;
    }




    function addClaim(
        uint _claimId,
        uint _coverId,
        address _from,
        uint _nowtime
    )
        external
        onlyInternal
    {
        allClaims.push(Claim(_coverId, _nowtime));
        allClaimsByAddress[_from].push(_claimId);
    }




    function addVote(
        address _voter,
        uint _tokens,
        uint claimId,
        int8 _verdict
    )
        external
        onlyInternal
    {
        allvotes.push(Vote(_voter, _tokens, claimId, _verdict, false));
    }







    function addClaimVoteCA(uint _claimId, uint _voteid) external onlyInternal {
        claimVoteCA[_claimId].push(_voteid);
    }







    function setUserClaimVoteCA(
        address _from,
        uint _claimId,
        uint _voteid
    )
        external
        onlyInternal
    {
        userClaimVoteCA[_from][_claimId] = _voteid;
        voteAddressCA[_from].push(_voteid);
    }








    function setClaimTokensCA(uint _claimId, int8 _vote, uint _tokens) external onlyInternal {
        if (_vote == 1)
            claimTokensCA[_claimId].accept = claimTokensCA[_claimId].accept.add(_tokens);

        if (_vote == -1)
            claimTokensCA[_claimId].deny = claimTokensCA[_claimId].deny.add(_tokens);

    }








    function setClaimTokensMV(uint _claimId, int8 _vote, uint _tokens) external onlyInternal {
        if (_vote == 1)
            claimTokensMV[_claimId].accept = claimTokensMV[_claimId].accept.add(_tokens);

        if (_vote == -1)
            claimTokensMV[_claimId].deny = claimTokensMV[_claimId].deny.add(_tokens);

    }







    function addClaimVotemember(uint _claimId, uint _voteid) external onlyInternal {
        claimVoteMember[_claimId].push(_voteid);
    }







    function setUserClaimVoteMember(
        address _from,
        uint _claimId,
        uint _voteid
    )
        external
        onlyInternal
    {
        userClaimVoteMember[_from][_claimId] = _voteid;
        voteAddressMember[_from].push(_voteid);

    }




    function updateState12Count(uint _claimId, uint _cnt) external onlyInternal {
        claimState12Count[_claimId] = claimState12Count[_claimId].add(_cnt);

    }






    function setClaimStatus(uint _claimId, uint _stat) external onlyInternal {
        claimsStatus[_claimId] = _stat;
    }






    function setClaimdateUpd(uint _claimId, uint _dateUpd) external onlyInternal {
        allClaims[_claimId].dateUpd = _dateUpd;
    }




    function setClaimAtEmergencyPause(
        uint _coverId,
        uint _dateUpd,
        bool _submit
    )
        external
        onlyInternal
    {
        claimPause.push(ClaimsPause(_coverId, _dateUpd, _submit));
    }





    function setClaimSubmittedAtEPTrue(uint _index, bool _submit) external onlyInternal {
        claimPause[_index].submit = _submit;
    }





    function setFirstClaimIndexToSubmitAfterEP(
        uint _firstClaimIndexToSubmit
    )
        external
        onlyInternal
    {
        claimPauseLastsubmit = _firstClaimIndexToSubmit;
    }




    function setPendingClaimDetails(
        uint _claimId,
        uint _pendingTime,
        bool _voting
    )
        external
        onlyInternal
    {
        claimPauseVotingEP.push(ClaimPauseVoting(_claimId, _pendingTime, _voting));
    }




    function setPendingClaimVoteStatus(uint _claimId, bool _vote) external onlyInternal {
        claimPauseVotingEP[_claimId].voting = _vote;
    }





    function setFirstClaimIndexToStartVotingAfterEP(
        uint _claimStartVotingFirstIndex
    )
        external
        onlyInternal
    {
        claimStartVotingFirstIndex = _claimStartVotingFirstIndex;
    }




    function callVoteEvent(
        address _userAddress,
        uint _claimId,
        bytes4 _typeOf,
        uint _tokens,
        uint _submitDate,
        int8 _verdict
    )
        external
        onlyInternal
    {
        emit VoteCast(
            _userAddress,
            _claimId,
            _typeOf,
            _tokens,
            _submitDate,
            _verdict
        );
    }




    function callClaimEvent(
        uint _coverId,
        address _userAddress,
        uint _claimId,
        uint _datesubmit
    )
        external
        onlyInternal
    {
        emit ClaimRaise(_coverId, _userAddress, _claimId, _datesubmit);
    }







    function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val) {
        codeVal = code;
        if (code == "CAMAXVT") {
            val = maxVotingTime / (1 hours);

        } else if (code == "CAMINVT") {

            val = minVotingTime / (1 hours);

        } else if (code == "CAPRETRY") {

            val = payoutRetryTime / (1 hours);

        } else if (code == "CADEPT") {

            val = claimDepositTime / (1 days);

        } else if (code == "CAREWPER") {

            val = claimRewardPerc;

        } else if (code == "CAMINTH") {

            val = minVoteThreshold;

        } else if (code == "CAMAXTH") {

            val = maxVoteThreshold;

        } else if (code == "CACONPER") {

            val = majorityConsensus;

        } else if (code == "CAPAUSET") {
            val = pauseDaysCA / (1 days);
        }

    }




    function getClaimOfEmergencyPauseByIndex(
        uint _index
    )
        external
        view
        returns(
            uint coverId,
            uint dateUpd,
            bool submit
        )
    {
        coverId = claimPause[_index].coverid;
        dateUpd = claimPause[_index].dateUpd;
        submit = claimPause[_index].submit;
    }




    function getAllClaimsByIndex(
        uint _claimId
    )
        external
        view
        returns(
            uint coverId,
            int8 vote,
            uint status,
            uint dateUpd,
            uint state12Count
        )
    {
        return(
            allClaims[_claimId].coverId,
            claimVote[_claimId],
            claimsStatus[_claimId],
            allClaims[_claimId].dateUpd,
            claimState12Count[_claimId]
        );
    }




    function getUserClaimVoteCA(
        address _add,
        uint _claimId
    )
        external
        view
        returns(uint idVote)
    {
        return userClaimVoteCA[_add][_claimId];
    }




    function getUserClaimVoteMember(
        address _add,
        uint _claimId
    )
        external
        view
        returns(uint idVote)
    {
        return userClaimVoteMember[_add][_claimId];
    }




    function getAllVoteLength() external view returns(uint voteCount) {
        return allvotes.length.sub(1);
    }






    function getClaimStatusNumber(uint _claimId) external view returns(uint claimId, uint statno) {
        return (_claimId, claimsStatus[_claimId]);
    }







    function getRewardStatus(uint statusNumber) external view returns(uint percCA, uint percMV) {
        return (rewardStatus[statusNumber].percCA, rewardStatus[statusNumber].percMV);
    }




    function getClaimState12Count(uint _claimId) external view returns(uint num) {
        num = claimState12Count[_claimId];
    }




    function getClaimDateUpd(uint _claimId) external view returns(uint dateupd) {
        dateupd = allClaims[_claimId].dateUpd;
    }






    function getAllClaimsByAddress(address _member) external view returns(uint[] memory claimarr) {
        return allClaimsByAddress[_member];
    }








    function getClaimsTokenCA(
        uint _claimId
    )
        external
        view
        returns(
            uint claimId,
            uint accept,
            uint deny
        )
    {
        return (
            _claimId,
            claimTokensCA[_claimId].accept,
            claimTokensCA[_claimId].deny
        );
    }








    function getClaimsTokenMV(
        uint _claimId
    )
        external
        view
        returns(
            uint claimId,
            uint accept,
            uint deny
        )
    {
        return (
            _claimId,
            claimTokensMV[_claimId].accept,
            claimTokensMV[_claimId].deny
        );
    }




    function getCaClaimVotesToken(uint _claimId) external view returns(uint claimId, uint cnt) {
        claimId = _claimId;
        cnt = 0;
        for (uint i = 0; i < claimVoteCA[_claimId].length; i++) {
            cnt = cnt.add(allvotes[claimVoteCA[_claimId][i]].tokens);
        }
    }




    function getMemberClaimVotesToken(
        uint _claimId
    )
        external
        view
        returns(uint claimId, uint cnt)
    {
        claimId = _claimId;
        cnt = 0;
        for (uint i = 0; i < claimVoteMember[_claimId].length; i++) {
            cnt = cnt.add(allvotes[claimVoteMember[_claimId][i]].tokens);
        }
    }





    function getVoteDetails(uint _voteid)
    external view
    returns(
        uint tokens,
        uint claimId,
        int8 verdict,
        bool rewardClaimed
        )
    {
        return (
            allvotes[_voteid].tokens,
            allvotes[_voteid].claimId,
            allvotes[_voteid].verdict,
            allvotes[_voteid].rewardClaimed
        );
    }




    function getVoterVote(uint _voteid) external view returns(address voter) {
        return allvotes[_voteid].voter;
    }





    function getClaim(
        uint _claimId
    )
        external
        view
        returns(
            uint claimId,
            uint coverId,
            int8 vote,
            uint status,
            uint dateUpd,
            uint state12Count
        )
    {
        return (
            _claimId,
            allClaims[_claimId].coverId,
            claimVote[_claimId],
            claimsStatus[_claimId],
            allClaims[_claimId].dateUpd,
            claimState12Count[_claimId]
            );
    }








    function getClaimVoteLength(
        uint _claimId,
        uint8 _ca
    )
        external
        view
        returns(uint claimId, uint len)
    {
        claimId = _claimId;
        if (_ca == 1)
            len = claimVoteCA[_claimId].length;
        else
            len = claimVoteMember[_claimId].length;
    }






    function getVoteVerdict(
        uint _claimId,
        uint _index,
        uint8 _ca
    )
        external
        view
        returns(int8 ver)
    {
        if (_ca == 1)
            ver = allvotes[claimVoteCA[_claimId][_index]].verdict;
        else
            ver = allvotes[claimVoteMember[_claimId][_index]].verdict;
    }






    function getVoteToken(
        uint _claimId,
        uint _index,
        uint8 _ca
    )
        external
        view
        returns(uint tok)
    {
        if (_ca == 1)
            tok = allvotes[claimVoteCA[_claimId][_index]].tokens;
        else
            tok = allvotes[claimVoteMember[_claimId][_index]].tokens;
    }






    function getVoteVoter(
        uint _claimId,
        uint _index,
        uint8 _ca
    )
        external
        view
        returns(address voter)
    {
        if (_ca == 1)
            voter = allvotes[claimVoteCA[_claimId][_index]].voter;
        else
            voter = allvotes[claimVoteMember[_claimId][_index]].voter;
    }





    function getUserClaimCount(address _add) external view returns(uint len) {
        len = allClaimsByAddress[_add].length;
    }




    function getClaimLength() external view returns(uint len) {
        len = allClaims.length.sub(pendingClaimStart);
    }




    function actualClaimLength() external view returns(uint len) {
        len = allClaims.length;
    }











    function getClaimFromNewStart(
        uint _index,
        address _add
    )
        external
        view
        returns(
            uint coverid,
            uint claimId,
            int8 voteCA,
            int8 voteMV,
            uint statusnumber
        )
    {
        uint i = pendingClaimStart.add(_index);
        coverid = allClaims[i].coverId;
        claimId = i;
        if (userClaimVoteCA[_add][i] > 0)
            voteCA = allvotes[userClaimVoteCA[_add][i]].verdict;
        else
            voteCA = 0;

        if (userClaimVoteMember[_add][i] > 0)
            voteMV = allvotes[userClaimVoteMember[_add][i]].verdict;
        else
            voteMV = 0;

        statusnumber = claimsStatus[i];
    }




    function getUserClaimByIndex(
        uint _index,
        address _add
    )
        external
        view
        returns(
            uint status,
            uint coverid,
            uint claimId
        )
    {
        claimId = allClaimsByAddress[_add][_index];
        status = claimsStatus[claimId];
        coverid = allClaims[claimId].coverId;
    }







    function getAllVotesForClaim(
        uint _claimId
    )
        external
        view
        returns(
            uint claimId,
            uint[] memory ca,
            uint[] memory mv
        )
    {
        return (_claimId, claimVoteCA[_claimId], claimVoteMember[_claimId]);
    }






    function getTokensClaim(
        address _of,
        uint _claimId
    )
        external
        view
        returns(
            uint claimId,
            uint tokens
        )
    {
        return (_claimId, allvotes[userClaimVoteCA[_of][_claimId]].tokens);
    }






    function getRewardDistributedIndex(
        address _voter
    )
        external
        view
        returns(
            uint lastCAvoteIndex,
            uint lastMVvoteIndex
        )
    {
        return (
            voterVoteRewardReceived[_voter].lastCAvoteIndex,
            voterVoteRewardReceived[_voter].lastMVvoteIndex
        );
    }







    function getClaimRewardDetail(
        uint claimid
    )
        external
        view
        returns(
            uint percCA,
            uint percMV,
            uint tokens
        )
    {
        return (
            claimRewardDetail[claimid].percCA,
            claimRewardDetail[claimid].percMV,
            claimRewardDetail[claimid].tokenToBeDist
        );
    }




    function getClaimCoverId(uint _claimId) external view returns(uint claimId, uint coverid) {
        return (_claimId, allClaims[_claimId].coverId);
    }







    function getClaimVote(uint _claimId, int8 _verdict) external view returns(uint claimId, uint token) {
        claimId = _claimId;
        token = 0;
        for (uint i = 0; i < claimVoteCA[_claimId].length; i++) {
            if (allvotes[claimVoteCA[_claimId][i]].verdict == _verdict)
                token = token.add(allvotes[claimVoteCA[_claimId][i]].tokens);
        }
    }









    function getClaimMVote(uint _claimId, int8 _verdict) external view returns(uint claimId, uint token) {
        claimId = _claimId;
        token = 0;
        for (uint i = 0; i < claimVoteMember[_claimId].length; i++) {
            if (allvotes[claimVoteMember[_claimId][i]].verdict == _verdict)
                token = token.add(allvotes[claimVoteMember[_claimId][i]].tokens);
        }
    }





    function getVoteAddressCA(address _voter, uint index) external view returns(uint) {
        return voteAddressCA[_voter][index];
    }





    function getVoteAddressMember(address _voter, uint index) external view returns(uint) {
        return voteAddressMember[_voter][index];
    }




    function getVoteAddressCALength(address _voter) external view returns(uint) {
        return voteAddressCA[_voter].length;
    }




    function getVoteAddressMemberLength(address _voter) external view returns(uint) {
        return voteAddressMember[_voter].length;
    }






    function getFinalVerdict(uint _claimId) external view returns(int8 verdict) {
        return claimVote[_claimId];
    }




    function getLengthOfClaimSubmittedAtEP() external view returns(uint len) {
        len = claimPause.length;
    }





    function getFirstClaimIndexToSubmitAfterEP() external view returns(uint indexToSubmit) {
        indexToSubmit = claimPauseLastsubmit;
    }




    function getLengthOfClaimVotingPause() external view returns(uint len) {
        len = claimPauseVotingEP.length;
    }




    function getPendingClaimDetailsByIndex(
        uint _index
    )
        external
        view
        returns(
            uint claimId,
            uint pendingTime,
            bool voting
        )
    {
        claimId = claimPauseVotingEP[_index].claimid;
        pendingTime = claimPauseVotingEP[_index].pendingTime;
        voting = claimPauseVotingEP[_index].voting;
    }




    function getFirstClaimIndexToStartVotingAfterEP() external view returns(uint firstindex) {
        firstindex = claimStartVotingFirstIndex;
    }






    function updateUintParameters(bytes8 code, uint val) public {
        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "CAMAXVT") {
            _setMaxVotingTime(val * 1 hours);

        } else if (code == "CAMINVT") {

            _setMinVotingTime(val * 1 hours);

        } else if (code == "CAPRETRY") {

            _setPayoutRetryTime(val * 1 hours);

        } else if (code == "CADEPT") {

            _setClaimDepositTime(val * 1 days);

        } else if (code == "CAREWPER") {

            _setClaimRewardPerc(val);

        } else if (code == "CAMINTH") {

            _setMinVoteThreshold(val);

        } else if (code == "CAMAXTH") {

            _setMaxVoteThreshold(val);

        } else if (code == "CACONPER") {

            _setMajorityConsensus(val);

        } else if (code == "CAPAUSET") {
            _setPauseDaysCA(val * 1 days);
        } else {

            revert("Invalid param code");
        }

    }




    function changeDependentContractAddress() public onlyInternal {}






    function _pushStatus(uint percCA, uint percMV) internal {
        rewardStatus.push(ClaimRewardStatus(percCA, percMV));
    }




    function _addRewardIncentive() internal {
        _pushStatus(0, 0);
        _pushStatus(0, 0);
        _pushStatus(0, 0);
        _pushStatus(0, 0);
        _pushStatus(0, 0);
        _pushStatus(0, 0);
        _pushStatus(100, 0);
        _pushStatus(100, 0);
        _pushStatus(0, 100);
        _pushStatus(0, 100);
        _pushStatus(0, 0);
        _pushStatus(0, 0);
        _pushStatus(0, 0);
        _pushStatus(0, 0);
        _pushStatus(0, 0);
    }




    function _setMaxVotingTime(uint _time) internal {
        maxVotingTime = _time;
    }




    function _setMinVotingTime(uint _time) internal {
        minVotingTime = _time;
    }




    function _setMinVoteThreshold(uint val) internal {
        minVoteThreshold = val;
    }




    function _setMaxVoteThreshold(uint val) internal {
        maxVoteThreshold = val;
    }




    function _setMajorityConsensus(uint val) internal {
        majorityConsensus = val;
    }




    function _setPayoutRetryTime(uint _time) internal {
        payoutRetryTime = _time;
    }




    function _setClaimRewardPerc(uint _val) internal {

        claimRewardPerc = _val;
    }




    function _setClaimDepositTime(uint _time) internal {

        claimDepositTime = _time;
    }




    function _setPauseDaysCA(uint val) internal {
        pauseDaysCA = val;
    }
}



































































































































    function setCapReached(uint val) external onlyInternal {
        capReached = val;
    }





    function updateIAAvgRate(bytes4 curr, uint rate) external onlyInternal {
        iaAvgRate[curr] = rate;
    }





    function updateCAAvgRate(bytes4 curr, uint rate) external onlyInternal {
        caAvgRate[curr] = rate;
    }




    function pushMCRData(uint mcrp, uint mcre, uint vf, uint64 time) external onlyInternal {
        allMCRData.push(McrData(mcrp, mcre, vf, time));
    }




    function updateDateUpdOfAPI(bytes32 myid) external onlyInternal {
        allAPIid[myid].dateUpd = uint64(now);
    }







    function saveApiDetails(bytes32 myid, bytes4 _typeof, uint id) external onlyInternal {
        allAPIid[myid] = ApiId(_typeof, "", id, uint64(now), uint64(now));
    }






    function addInAllApiCall(bytes32 myid) external onlyInternal {
        allAPIcall.push(myid);
    }









    function saveIARankDetails(
        bytes4 maxIACurr,
        uint64 maxRate,
        bytes4 minIACurr,
        uint64 minRate,
        uint64 date
    )
        external
        onlyInternal
    {
        allIARankDetails.push(IARankDetails(maxIACurr, maxRate, minIACurr, minRate));
        datewiseId[date] = allIARankDetails.length.sub(1);
    }




    function setLastLiquidityTradeTrigger() external onlyInternal {
        lastLiquidityTradeTrigger = now;
    }




    function updatelastDate(uint64 newDate) external onlyInternal {
        lastDate = newDate;
    }







    function addCurrencyAssetCurrency(
        bytes4 curr,
        address currAddress,
        uint baseMin
    )
        external
    {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allCurrencies.push(curr);
        allCurrencyAssets[curr] = CurrencyAssets(currAddress, baseMin, 0);
    }




    function addInvestmentAssetCurrency(
        bytes4 curr,
        address currAddress,
        bool status,
        uint64 minHoldingPercX100,
        uint64 maxHoldingPercX100,
        uint8 decimals
    )
        external
    {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allInvestmentCurrencies.push(curr);
        allInvestmentAssets[curr] = InvestmentAssets(currAddress, status,
            minHoldingPercX100, maxHoldingPercX100, decimals);
    }




    function changeCurrencyAssetBaseMin(bytes4 curr, uint baseMin) external {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allCurrencyAssets[curr].baseMin = baseMin;
    }




    function changeCurrencyAssetVarMin(bytes4 curr, uint varMin) external onlyInternal {
        allCurrencyAssets[curr].varMin = varMin;
    }




    function changeInvestmentAssetStatus(bytes4 curr, bool status) external {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allInvestmentAssets[curr].status = status;
    }




    function changeInvestmentAssetHoldingPerc(
        bytes4 curr,
        uint64 minPercX100,
        uint64 maxPercX100
    )
        external
    {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allInvestmentAssets[curr].minHoldingPercX100 = minPercX100;
        allInvestmentAssets[curr].maxHoldingPercX100 = maxPercX100;
    }




    function changeCurrencyAssetAddress(bytes4 curr, address currAdd) external {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allCurrencyAssets[curr].currAddress = currAdd;
    }




    function changeInvestmentAssetAddressAndDecimal(
        bytes4 curr,
        address currAdd,
        uint8 newDecimal
    )
        external
    {
        require(ms.checkIsAuthToGoverned(msg.sender));
        allInvestmentAssets[curr].currAddress = currAdd;
        allInvestmentAssets[curr].decimals = newDecimal;
    }


    function changeNotariseAddress(address _add) external onlyInternal {
        notariseMCR = _add;
    }



    function changeDAIfeedAddress(address _add) external onlyInternal {
        daiFeedAddress = _add;
    }







    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint val) {
        codeVal = code;
        if (code == "MCRTIM") {
            val = mcrTime / (1 hours);

        } else if (code == "MCRFTIM") {

            val = mcrFailTime / (1 hours);

        } else if (code == "MCRMIN") {

            val = minCap;

        } else if (code == "MCRSHOCK") {

            val = shockParameter;

        } else if (code == "MCRCAPL") {

            val = capacityLimit;

        } else if (code == "IMZ") {

            val = variationPercX100;

        } else if (code == "IMRATET") {

            val = iaRatesTime / (1 hours);

        } else if (code == "IMUNIDL") {

            val = uniswapDeadline / (1 minutes);

        } else if (code == "IMLIQT") {

            val = liquidityTradeCallbackTime / (1 hours);

        } else if (code == "IMETHVL") {

            val = ethVolumeLimit;

        } else if (code == "C") {
            val = c;

        } else if (code == "A") {

            val = a;

        }

    }




    function isnotarise(address _add) external view returns(bool res) {
        res = false;
        if (_add == notariseMCR)
            res = true;
    }




    function getLastMCR() external view returns(uint mcrPercx100, uint mcrEtherx1E18, uint vFull, uint64 date) {
        uint index = allMCRData.length.sub(1);
        return (
            allMCRData[index].mcrPercx100,
            allMCRData[index].mcrEther,
            allMCRData[index].vFull,
            allMCRData[index].date
        );
    }



    function getLastMCRPerc() external view returns(uint) {
        return allMCRData[allMCRData.length.sub(1)].mcrPercx100;
    }



    function getLastMCREther() external view returns(uint) {
        return allMCRData[allMCRData.length.sub(1)].mcrEther;
    }


    function getLastVfull() external view returns(uint) {
        return allMCRData[allMCRData.length.sub(1)].vFull;
    }



    function getLastMCRDate() external view returns(uint64 date) {
        date = allMCRData[allMCRData.length.sub(1)].date;
    }


    function getTokenPriceDetails(bytes4 curr) external view returns(uint _a, uint _c, uint rate) {
        _a = a;
        _c = c;
        rate = _getAvgRate(curr, false);
    }


    function getMCRDataLength() external view returns(uint len) {
        len = allMCRData.length;
    }




    function getIARankDetailsByDate(
        uint64 date
    )
        external
        view
        returns(
            bytes4 maxIACurr,
            uint64 maxRate,
            bytes4 minIACurr,
            uint64 minRate
        )
    {
        uint index = datewiseId[date];
        return (
            allIARankDetails[index].maxIACurr,
            allIARankDetails[index].maxRate,
            allIARankDetails[index].minIACurr,
            allIARankDetails[index].minRate
        );
    }




    function getLastDate() external view returns(uint64 date) {
        return lastDate;
    }




    function getInvestmentCurrencyByIndex(uint index) external view returns(bytes4 currName) {
        return allInvestmentCurrencies[index];
    }




    function getInvestmentCurrencyLen() external view returns(uint len) {
        return allInvestmentCurrencies.length;
    }




    function getAllInvestmentCurrencies() external view returns(bytes4[] memory currencies) {
        return allInvestmentCurrencies;
    }




    function getCurrenciesByIndex(uint index) external view returns(bytes4 currName) {
        return allCurrencies[index];
    }




    function getAllCurrenciesLen() external view returns(uint len) {
        return allCurrencies.length;
    }




    function getAllCurrencies() external view returns(bytes4[] memory currencies) {
        return allCurrencies;
    }




    function getCurrencyAssetVarBase(
        bytes4 curr
    )
        external
        view
        returns(
            bytes4 currency,
            uint baseMin,
            uint varMin
        )
    {
        return (
            curr,
            allCurrencyAssets[curr].baseMin,
            allCurrencyAssets[curr].varMin
        );
    }




    function getCurrencyAssetVarMin(bytes4 curr) external view returns(uint varMin) {
        return allCurrencyAssets[curr].varMin;
    }




    function getCurrencyAssetBaseMin(bytes4 curr) external view returns(uint baseMin) {
        return allCurrencyAssets[curr].baseMin;
    }




    function getInvestmentAssetHoldingPerc(
        bytes4 curr
    )
        external
        view
        returns(
            uint64 minHoldingPercX100,
            uint64 maxHoldingPercX100
        )
    {
        return (
            allInvestmentAssets[curr].minHoldingPercX100,
            allInvestmentAssets[curr].maxHoldingPercX100
        );
    }




    function getInvestmentAssetDecimals(bytes4 curr) external view returns(uint8 decimal) {
        return allInvestmentAssets[curr].decimals;
    }




    function getInvestmentAssetMaxHoldingPerc(bytes4 curr) external view returns(uint64 maxHoldingPercX100) {
        return allInvestmentAssets[curr].maxHoldingPercX100;
    }




    function getInvestmentAssetMinHoldingPerc(bytes4 curr) external view returns(uint64 minHoldingPercX100) {
        return allInvestmentAssets[curr].minHoldingPercX100;
    }




    function getInvestmentAssetDetails(
        bytes4 curr
    )
        external
        view
        returns(
            bytes4 currency,
            address currAddress,
            bool status,
            uint64 minHoldingPerc,
            uint64 maxHoldingPerc,
            uint8 decimals
        )
    {
        return (
            curr,
            allInvestmentAssets[curr].currAddress,
            allInvestmentAssets[curr].status,
            allInvestmentAssets[curr].minHoldingPercX100,
            allInvestmentAssets[curr].maxHoldingPercX100,
            allInvestmentAssets[curr].decimals
        );
    }




    function getCurrencyAssetAddress(bytes4 curr) external view returns(address) {
        return allCurrencyAssets[curr].currAddress;
    }




    function getInvestmentAssetAddress(bytes4 curr) external view returns(address) {
        return allInvestmentAssets[curr].currAddress;
    }




    function getInvestmentAssetStatus(bytes4 curr) external view returns(bool status) {
        return allInvestmentAssets[curr].status;
    }






    function getApiIdTypeOf(bytes32 myid) external view returns(bytes4) {
        return allAPIid[myid].typeOf;
    }






    function getIdOfApiId(bytes32 myid) external view returns(uint) {
        return allAPIid[myid].id;
    }




    function getDateAddOfAPI(bytes32 myid) external view returns(uint64) {
        return allAPIid[myid].dateAdd;
    }




    function getDateUpdOfAPI(bytes32 myid) external view returns(uint64) {
        return allAPIid[myid].dateUpd;
    }




    function getCurrOfApiId(bytes32 myid) external view returns(bytes4) {
        return allAPIid[myid].currency;
    }






    function getApiCallIndex(uint index) external view returns(bytes32 myid) {
        myid = allAPIcall[index];
    }




    function getApilCallLength() external view returns(uint) {
        return allAPIcall.length;
    }







    function getApiCallDetails(
        bytes32 myid
    )
        external
        view
        returns(
            bytes4 _typeof,
            bytes4 curr,
            uint id,
            uint64 dateAdd,
            uint64 dateUpd
        )
    {
        return (
            allAPIid[myid].typeOf,
            allAPIid[myid].currency,
            allAPIid[myid].id,
            allAPIid[myid].dateAdd,
            allAPIid[myid].dateUpd
        );
    }






    function updateUintParameters(bytes8 code, uint val) public {
        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "MCRTIM") {
            _changeMCRTime(val * 1 hours);

        } else if (code == "MCRFTIM") {

            _changeMCRFailTime(val * 1 hours);

        } else if (code == "MCRMIN") {

            _changeMinCap(val);

        } else if (code == "MCRSHOCK") {

            _changeShockParameter(val);

        } else if (code == "MCRCAPL") {

            _changeCapacityLimit(val);

        } else if (code == "IMZ") {

            _changeVariationPercX100(val);

        } else if (code == "IMRATET") {

            _changeIARatesTime(val * 1 hours);

        } else if (code == "IMUNIDL") {

            _changeUniswapDeadlineTime(val * 1 minutes);

        } else if (code == "IMLIQT") {

            _changeliquidityTradeCallbackTime(val * 1 hours);

        } else if (code == "IMETHVL") {

            _setEthVolumeLimit(val);

        } else if (code == "C") {
            _changeC(val);

        } else if (code == "A") {

            _changeA(val);

        } else {
            revert("Invalid param code");
        }

    }






    function getCAAvgRate(bytes4 curr) public view returns(uint rate) {
        return _getAvgRate(curr, false);
    }






    function getIAAvgRate(bytes4 curr) public view returns(uint rate) {
        return _getAvgRate(curr, true);
    }

    function changeDependentContractAddress() public onlyInternal {}




    function _getAvgRate(bytes4 curr, bool isIA) internal view returns(uint rate) {
        if (curr == "DAI") {
            DSValue ds = DSValue(daiFeedAddress);
            rate = uint(ds.read()).div(uint(10) ** 16);
        } else if (isIA) {
            rate = iaAvgRate[curr];
        } else {
            rate = caAvgRate[curr];
        }
    }





    function _setEthVolumeLimit(uint val) internal {
        ethVolumeLimit = val;
    }


    function _changeMinCap(uint newCap) internal {
        minCap = newCap;
    }


    function _changeShockParameter(uint newParam) internal {
        shockParameter = newParam;
    }


    function _changeMCRTime(uint _time) internal {
        mcrTime = _time;
    }


    function _changeMCRFailTime(uint _time) internal {
        mcrFailTime = _time;
    }





    function _changeUniswapDeadlineTime(uint newDeadline) internal {
        uniswapDeadline = newDeadline;
    }





    function _changeliquidityTradeCallbackTime(uint newTime) internal {
        liquidityTradeCallbackTime = newTime;
    }




    function _changeIARatesTime(uint _newTime) internal {
        iaRatesTime = _newTime;
    }




    function _changeVariationPercX100(uint newPercX100) internal {
        variationPercX100 = newPercX100;
    }


    function _changeC(uint newC) internal {
        c = newC;
    }


    function _changeA(uint val) internal {
        a = val;
    }





    function _changeCapacityLimit(uint val) internal {
        capacityLimit = val;
    }
}































































































































































































    function setKycAuthAddress(address _add) external onlyInternal {
        kycAuthAddress = _add;
    }


    function changeAuthQuoteEngine(address _add) external onlyInternal {
        authQuoteEngine = _add;
    }







    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint val) {
        codeVal = code;

        if (code == "STLP") {
            val = stlp;

        } else if (code == "STL") {

            val = stl;

        } else if (code == "PM") {

            val = pm;

        } else if (code == "QUOMIND") {

            val = minDays;

        } else if (code == "QUOTOK") {

            val = tokensRetained;

        }

    }






    function getProductDetails()
        external
        view
        returns (
            uint _minDays,
            uint _pm,
            uint _stl,
            uint _stlp
        )
    {

        _minDays = minDays;
        _pm = pm;
        _stl = stl;
        _stlp = stlp;
    }


    function getCoverLength() external view returns(uint len) {
        return (allCovers.length);
    }


    function getAuthQuoteEngine() external view returns(address _add) {
        _add = authQuoteEngine;
    }


    function getTotalSumAssured(bytes4 _curr) external view returns(uint amount) {
        amount = currencyCSA[_curr];
    }




    function getAllCoversOfUser(address _add) external view returns(uint[] memory allCover) {
        return (userCover[_add]);
    }


    function getUserCoverLength(address _add) external view returns(uint len) {
        len = userCover[_add].length;
    }


    function getCoverStatusNo(uint _cid) external view returns(uint8) {
        return coverStatus[_cid];
    }


    function getCoverPeriod(uint _cid) external view returns(uint32 cp) {
        cp = allCovers[_cid].coverPeriod;
    }


    function getCoverSumAssured(uint _cid) external view returns(uint sa) {
        sa = allCovers[_cid].sumAssured;
    }


    function getCurrencyOfCover(uint _cid) external view returns(bytes4 curr) {
        curr = allCovers[_cid].currencyCode;
    }


    function getValidityOfCover(uint _cid) external view returns(uint date) {
        date = allCovers[_cid].validUntil;
    }


    function getscAddressOfCover(uint _cid) external view returns(uint, address) {
        return (_cid, allCovers[_cid].scAddress);
    }


    function getCoverMemberAddress(uint _cid) external view returns(address payable _add) {
        _add = allCovers[_cid].memberAddress;
    }


    function getCoverPremiumNXM(uint _cid) external view returns(uint _premiumNXM) {
        _premiumNXM = allCovers[_cid].premiumNXM;
    }








    function getCoverDetailsByCoverID1(
        uint _cid
    )
        external
        view
        returns (
            uint cid,
            address _memberAddress,
            address _scAddress,
            bytes4 _currencyCode,
            uint _sumAssured,
            uint premiumNXM
        )
    {
        return (
            _cid,
            allCovers[_cid].memberAddress,
            allCovers[_cid].scAddress,
            allCovers[_cid].currencyCode,
            allCovers[_cid].sumAssured,
            allCovers[_cid].premiumNXM
        );
    }







    function getCoverDetailsByCoverID2(
        uint _cid
    )
        external
        view
        returns (
            uint cid,
            uint8 status,
            uint sumAssured,
            uint16 coverPeriod,
            uint validUntil
        )
    {

        return (
            _cid,
            coverStatus[_cid],
            allCovers[_cid].sumAssured,
            allCovers[_cid].coverPeriod,
            allCovers[_cid].validUntil
        );
    }






    function getHoldedCoverDetailsByID1(
        uint _hcid
    )
        external
        view
        returns (
            uint hcid,
            address scAddress,
            bytes4 coverCurr,
            uint16 coverPeriod
        )
    {
        return (
            _hcid,
            allCoverHolded[_hcid].scAddress,
            allCoverHolded[_hcid].coverCurr,
            allCoverHolded[_hcid].coverPeriod
        );
    }


    function getUserHoldedCoverLength(address _add) external view returns (uint) {
        return userHoldedCover[_add].length;
    }


    function getUserHoldedCoverByIndex(address _add, uint index) external view returns (uint) {
        return userHoldedCover[_add][index];
    }





    function getHoldedCoverDetailsByID2(
        uint _hcid
    )
        external
        view
        returns (
            uint hcid,
            address payable memberAddress,
            uint[] memory coverDetails
        )
    {
        return (
            _hcid,
            allCoverHolded[_hcid].userAddress,
            allCoverHolded[_hcid].coverDetails
        );
    }


    function getTotalSumAssuredSC(address _add, bytes4 _curr) external view returns(uint amount) {
        amount = currencyCSAOfSCAdd[_add][_curr];
    }


    function changeDependentContractAddress() public {}




    function changeCoverStatusNo(uint _cid, uint8 _stat) public onlyInternal {
        coverStatus[_cid] = _stat;
        emit CoverStatusEvent(_cid, _stat);
    }






    function updateUintParameters(bytes8 code, uint val) public {

        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "STLP") {
            _changeSTLP(val);

        } else if (code == "STL") {

            _changeSTL(val);

        } else if (code == "PM") {

            _changePM(val);

        } else if (code == "QUOMIND") {

            _changeMinDays(val);

        } else if (code == "QUOTOK") {

            _setTokensRetained(val);

        } else {

            revert("Invalid param code");
        }

    }


    function _changePM(uint _pm) internal {
        pm = _pm;
    }


    function _changeSTLP(uint _stlp) internal {
        stlp = _stlp;
    }


    function _changeSTL(uint _stl) internal {
        stl = _stl;
    }


    function _changeMinDays(uint _days) internal {
        minDays = _days;
    }





    function _setTokensRetained(uint val) internal {
        tokensRetained = val;
    }
}




































































    mapping(address => Stake[]) public stakerStakedContracts;






    mapping(address => Staker[]) public stakedContractStakers;





    mapping(address => mapping(uint => StakeCommission)) public stakedContractStakeCommission;

    mapping(address => uint) public lastCompletedStakeCommission;





    mapping(address => uint) public stakedContractCurrentCommissionIndex;





    mapping(address => uint) public stakedContractCurrentBurnIndex;




    mapping(uint => CoverNote) public depositedCN;

    mapping(address => uint) internal isBookedTokens;

    event Commission(
        address indexed stakedContractAddress,
        address indexed stakerAddress,
        uint indexed scIndex,
        uint commissionAmount
    );

    constructor(address payable _walletAdd) public {
        walletAddress = _walletAdd;
        bookTime = 12 hours;
        joiningFee = 2000000000000000;
        lockTokenTimeAfterCoverExp = 35 days;
        scValidDays = 250;
        lockCADays = 7 days;
        lockMVDays = 2 days;
        stakerCommissionPer = 20;
        stakerMaxCommissionPer = 50;
        tokenExponent = 4;
        priceStep = 1000;

    }




    function changeWalletAddress(address payable _address) external onlyInternal {
        walletAddress = _address;
    }







    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint val) {
        codeVal = code;
        if (code == "TOKEXP") {

            val = tokenExponent;

        } else if (code == "TOKSTEP") {

            val = priceStep;

        } else if (code == "RALOCKT") {

            val = scValidDays;

        } else if (code == "RACOMM") {

            val = stakerCommissionPer;

        } else if (code == "RAMAXC") {

            val = stakerMaxCommissionPer;

        } else if (code == "CABOOKT") {

            val = bookTime / (1 hours);

        } else if (code == "CALOCKT") {

            val = lockCADays / (1 days);

        } else if (code == "MVLOCKT") {

            val = lockMVDays / (1 days);

        } else if (code == "QUOLOCKT") {

            val = lockTokenTimeAfterCoverExp / (1 days);

        } else if (code == "JOINFEE") {

            val = joiningFee;

        }
    }




    function changeDependentContractAddress() public {
    }







    function getStakerStakedContractByIndex(
        address _stakerAddress,
        uint _stakerIndex
    )
        public
        view
        returns (address stakedContractAddress)
    {
        stakedContractAddress = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractAddress;
    }







    function getStakerStakedBurnedByIndex(
        address _stakerAddress,
        uint _stakerIndex
    )
        public
        view
        returns (uint burnedAmount)
    {
        burnedAmount = stakerStakedContracts[
            _stakerAddress][_stakerIndex].burnedAmount;
    }







    function getStakerStakedUnlockableBeforeLastBurnByIndex(
        address _stakerAddress,
        uint _stakerIndex
    )
        public
        view
        returns (uint unlockable)
    {
        unlockable = stakerStakedContracts[
            _stakerAddress][_stakerIndex].unLockableBeforeLastBurn;
    }







    function getStakerStakedContractIndex(
        address _stakerAddress,
        uint _stakerIndex
    )
        public
        view
        returns (uint scIndex)
    {
        scIndex = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractIndex;
    }







    function getStakedContractStakerIndex(
        address _stakedContractAddress,
        uint _stakedContractIndex
    )
        public
        view
        returns (uint sIndex)
    {
        sIndex = stakedContractStakers[
            _stakedContractAddress][_stakedContractIndex].stakerIndex;
    }







    function getStakerInitialStakedAmountOnContract(
        address _stakerAddress,
        uint _stakerIndex
    )
        public
        view
        returns (uint amount)
    {
        amount = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakeAmount;
    }






    function getStakerStakedContractLength(
        address _stakerAddress
    )
        public
        view
        returns (uint length)
    {
        length = stakerStakedContracts[_stakerAddress].length;
    }







    function getStakerUnlockedStakedTokens(
        address _stakerAddress,
        uint _stakerIndex
    )
        public
        view
        returns (uint amount)
    {
        amount = stakerStakedContracts[
            _stakerAddress][_stakerIndex].unlockedAmount;
    }







    function pushUnlockedStakedTokens(
        address _stakerAddress,
        uint _stakerIndex,
        uint _amount
    )
        public
        onlyInternal
    {
        stakerStakedContracts[_stakerAddress][
            _stakerIndex].unlockedAmount = stakerStakedContracts[_stakerAddress][
                _stakerIndex].unlockedAmount.add(_amount);

    }







    function pushBurnedTokens(
        address _stakerAddress,
        uint _stakerIndex,
        uint _amount
    )
        public
        onlyInternal
    {
        stakerStakedContracts[_stakerAddress][
            _stakerIndex].burnedAmount = stakerStakedContracts[_stakerAddress][
                _stakerIndex].burnedAmount.add(_amount);

    }







    function pushUnlockableBeforeLastBurnTokens(
        address _stakerAddress,
        uint _stakerIndex,
        uint _amount
    )
        public
        onlyInternal
    {
        stakerStakedContracts[_stakerAddress][
            _stakerIndex].unLockableBeforeLastBurn = stakerStakedContracts[_stakerAddress][
                _stakerIndex].unLockableBeforeLastBurn.add(_amount);

    }







    function setUnlockableBeforeLastBurnTokens(
        address _stakerAddress,
        uint _stakerIndex,
        uint _amount
    )
        public
        onlyInternal
    {
        stakerStakedContracts[_stakerAddress][
            _stakerIndex].unLockableBeforeLastBurn = _amount;
    }








    function pushEarnedStakeCommissions(
        address _stakerAddress,
        address _stakedContractAddress,
        uint _stakedContractIndex,
        uint _commissionAmount
    )
        public
        onlyInternal
    {
        stakedContractStakeCommission[_stakedContractAddress][_stakedContractIndex].
            commissionEarned = stakedContractStakeCommission[_stakedContractAddress][
                _stakedContractIndex].commissionEarned.add(_commissionAmount);


        emit Commission(
            _stakerAddress,
            _stakedContractAddress,
            _stakedContractIndex,
            _commissionAmount
        );
    }







    function pushRedeemedStakeCommissions(
        address _stakerAddress,
        uint _stakerIndex,
        uint _amount
    )
        public
        onlyInternal
    {
        uint stakedContractIndex = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractIndex;
        address stakedContractAddress = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractAddress;
        stakedContractStakeCommission[stakedContractAddress][stakedContractIndex].
            commissionRedeemed = stakedContractStakeCommission[
                stakedContractAddress][stakedContractIndex].commissionRedeemed.add(_amount);

    }







    function getStakerEarnedStakeCommission(
        address _stakerAddress,
        uint _stakerIndex
    )
        public
        view
        returns (uint)
    {
        return _getStakerEarnedStakeCommission(_stakerAddress, _stakerIndex);
    }








    function getStakerRedeemedStakeCommission(
        address _stakerAddress,
        uint _stakerIndex
    )
        public
        view
        returns (uint)
    {
        return _getStakerRedeemedStakeCommission(_stakerAddress, _stakerIndex);
    }






    function getStakerTotalEarnedStakeCommission(
        address _stakerAddress
    )
        public
        view
        returns (uint totalCommissionEarned)
    {
        totalCommissionEarned = 0;
        for (uint i = 0; i < stakerStakedContracts[_stakerAddress].length; i++) {
            totalCommissionEarned = totalCommissionEarned.
                add(_getStakerEarnedStakeCommission(_stakerAddress, i));
        }
    }






    function getStakerTotalReedmedStakeCommission(
        address _stakerAddress
    )
        public
        view
        returns(uint totalCommissionRedeemed)
    {
        totalCommissionRedeemed = 0;
        for (uint i = 0; i < stakerStakedContracts[_stakerAddress].length; i++) {
            totalCommissionRedeemed = totalCommissionRedeemed.add(
                _getStakerRedeemedStakeCommission(_stakerAddress, i));
        }
    }







    function setDepositCN(uint coverId, bool flag) public onlyInternal {

        if (flag == true) {
            require(!depositedCN[coverId].isDeposited, "Cover note already deposited");
        }

        depositedCN[coverId].isDeposited = flag;
    }







    function setDepositCNAmount(uint coverId, uint amount) public onlyInternal {

        depositedCN[coverId].amount = amount;
    }







    function getStakedContractStakerByIndex(
        address _stakedContractAddress,
        uint _stakedContractIndex
    )
        public
        view
        returns (address stakerAddress)
    {
        stakerAddress = stakedContractStakers[
            _stakedContractAddress][_stakedContractIndex].stakerAddress;
    }






    function getStakedContractStakersLength(
        address _stakedContractAddress
    )
        public
        view
        returns (uint length)
    {
        length = stakedContractStakers[_stakedContractAddress].length;
    }







    function addStake(
        address _stakerAddress,
        address _stakedContractAddress,
        uint _amount
    )
        public
        onlyInternal
        returns(uint scIndex)
    {
        scIndex = (stakedContractStakers[_stakedContractAddress].push(
            Staker(_stakerAddress, stakerStakedContracts[_stakerAddress].length))).sub(1);
        stakerStakedContracts[_stakerAddress].push(
            Stake(_stakedContractAddress, scIndex, now, _amount, 0, 0, 0));
    }






    function bookCATokens(address _of) public onlyInternal {
        require(!isCATokensBooked(_of), "Tokens already booked");
        isBookedTokens[_of] = now.add(bookTime);
    }






    function isCATokensBooked(address _of) public view returns(bool res) {
        if (now < isBookedTokens[_of])
            res = true;
    }






    function setStakedContractCurrentCommissionIndex(
        address _stakedContractAddress,
        uint _index
    )
        public
        onlyInternal
    {
        stakedContractCurrentCommissionIndex[_stakedContractAddress] = _index;
    }






    function setLastCompletedStakeCommissionIndex(
        address _stakerAddress,
        uint _index
    )
        public
        onlyInternal
    {
        lastCompletedStakeCommission[_stakerAddress] = _index;
    }






    function setStakedContractCurrentBurnIndex(
        address _stakedContractAddress,
        uint _index
    )
        public
        onlyInternal
    {
        stakedContractCurrentBurnIndex[_stakedContractAddress] = _index;
    }






    function updateUintParameters(bytes8 code, uint val) public {
        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "TOKEXP") {

            _setTokenExponent(val);

        } else if (code == "TOKSTEP") {

            _setPriceStep(val);

        } else if (code == "RALOCKT") {

            _changeSCValidDays(val);

        } else if (code == "RACOMM") {

            _setStakerCommissionPer(val);

        } else if (code == "RAMAXC") {

            _setStakerMaxCommissionPer(val);

        } else if (code == "CABOOKT") {

            _changeBookTime(val * 1 hours);

        } else if (code == "CALOCKT") {

            _changelockCADays(val * 1 days);

        } else if (code == "MVLOCKT") {

            _changelockMVDays(val * 1 days);

        } else if (code == "QUOLOCKT") {

            _setLockTokenTimeAfterCoverExp(val * 1 days);

        } else if (code == "JOINFEE") {

            _setJoiningFee(val);

        } else {
            revert("Invalid param code");
        }
    }







    function _getStakerEarnedStakeCommission(
        address _stakerAddress,
        uint _stakerIndex
    )
        internal
        view
        returns (uint amount)
    {
        uint _stakedContractIndex;
        address _stakedContractAddress;
        _stakedContractAddress = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractAddress;
        _stakedContractIndex = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractIndex;
        amount = stakedContractStakeCommission[
            _stakedContractAddress][_stakedContractIndex].commissionEarned;
    }







    function _getStakerRedeemedStakeCommission(
        address _stakerAddress,
        uint _stakerIndex
    )
        internal
        view
        returns (uint amount)
    {
        uint _stakedContractIndex;
        address _stakedContractAddress;
        _stakedContractAddress = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractAddress;
        _stakedContractIndex = stakerStakedContracts[
            _stakerAddress][_stakerIndex].stakedContractIndex;
        amount = stakedContractStakeCommission[
            _stakedContractAddress][_stakedContractIndex].commissionRedeemed;
    }





    function _setStakerCommissionPer(uint _val) internal {
        stakerCommissionPer = _val;
    }





    function _setStakerMaxCommissionPer(uint _val) internal {
        stakerMaxCommissionPer = _val;
    }





    function _setTokenExponent(uint _val) internal {
        tokenExponent = _val;
    }





    function _setPriceStep(uint _val) internal {
        priceStep = _val;
    }




    function _changeSCValidDays(uint _days) internal {
        scValidDays = _days;
    }






    function _changeBookTime(uint _time) internal {
        bookTime = _time;
    }





    function _changelockCADays(uint _val) internal {
        lockCADays = _val;
    }





    function _changelockMVDays(uint _val) internal {
        lockMVDays = _val;
    }




    function _setLockTokenTimeAfterCoverExp(uint time) internal {
        lockTokenTimeAfterCoverExp = time;
    }




    function _setJoiningFee(uint _amount) internal {
        joiningFee = _amount;
    }
}





























pragma solidity >= 0.5.0 < 0.6.0;


contract solcChecker {
 function f(bytes calldata x) external;
}

contract OraclizeI {

    address public cbAddress;

    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function getPrice(string memory _datasource) public returns (uint _dsprice);
    function randomDS_getSessionPubKeyHash() external view returns (bytes32 _sessionKeyHash);
    function getPrice(string memory _datasource, uint _gasLimit) public returns (uint _dsprice);
    function queryN(uint _timestamp, string memory _datasource, bytes memory _argN) public payable returns (bytes32 _id);
    function query(uint _timestamp, string calldata _datasource, string calldata _arg) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) public payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg, uint _gasLimit) external payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string calldata _datasource, bytes calldata _argN, uint _gasLimit) external payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string calldata _datasource, string calldata _arg1, string calldata _arg2, uint _gasLimit) external payable returns (bytes32 _id);
}

contract OraclizeAddrResolverI {
    function getAddress() public returns (address _address);
}





























library Buffer {

    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory _buf, uint _capacity) internal pure {
        uint capacity = _capacity;
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        _buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(_buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory _buf, uint _capacity) private pure {
        bytes memory oldbuf = _buf.buf;
        init(_buf, _capacity);
        append(_buf, oldbuf);
    }

    function max(uint _a, uint _b) private pure returns (uint _max) {
        if (_a > _b) {
            return _a;
        }
        return _b;
    }








    function append(buffer memory _buf, bytes memory _data) internal pure returns (buffer memory _buffer) {
        if (_data.length + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _data.length) * 2);
        }
        uint dest;
        uint src;
        uint len = _data.length;
        assembly {
            let bufptr := mload(_buf)
            let buflen := mload(bufptr)
            dest := add(add(bufptr, buflen), 32)
            mstore(bufptr, add(buflen, mload(_data)))
            src := add(_data, 32)
        }
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
        return _buf;
    }









    function append(buffer memory _buf, uint8 _data) internal pure {
        if (_buf.buf.length + 1 > _buf.capacity) {
            resize(_buf, _buf.capacity * 2);
        }
        assembly {
            let bufptr := mload(_buf)
            let buflen := mload(bufptr)
            let dest := add(add(bufptr, buflen), 32)
            mstore8(dest, _data)
            mstore(bufptr, add(buflen, 1))
        }
    }









    function appendInt(buffer memory _buf, uint _data, uint _len) internal pure returns (buffer memory _buffer) {
        if (_len + _buf.buf.length > _buf.capacity) {
            resize(_buf, max(_buf.capacity, _len) * 2);
        }
        uint mask = 256 ** _len - 1;
        assembly {
            let bufptr := mload(_buf)
            let buflen := mload(bufptr)
            let dest := add(add(bufptr, buflen), _len)
            mstore(dest, or(and(mload(dest), not(mask)), _data))
            mstore(bufptr, add(buflen, _len))
        }
        return _buf;
    }
}

library CBOR {

    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory _buf, uint8 _major, uint _value) private pure {
        if (_value <= 23) {
            _buf.append(uint8((_major << 5) | _value));
        } else if (_value <= 0xFF) {
            _buf.append(uint8((_major << 5) | 24));
            _buf.appendInt(_value, 1);
        } else if (_value <= 0xFFFF) {
            _buf.append(uint8((_major << 5) | 25));
            _buf.appendInt(_value, 2);
        } else if (_value <= 0xFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 26));
            _buf.appendInt(_value, 4);
        } else if (_value <= 0xFFFFFFFFFFFFFFFF) {
            _buf.append(uint8((_major << 5) | 27));
            _buf.appendInt(_value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory _buf, uint8 _major) private pure {
        _buf.append(uint8((_major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory _buf, uint _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_INT, _value);
    }

    function encodeInt(Buffer.buffer memory _buf, int _value) internal pure {
        if (_value >= 0) {
            encodeType(_buf, MAJOR_TYPE_INT, uint(_value));
        } else {
            encodeType(_buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - _value));
        }
    }

    function encodeBytes(Buffer.buffer memory _buf, bytes memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_BYTES, _value.length);
        _buf.append(_value);
    }

    function encodeString(Buffer.buffer memory _buf, string memory _value) internal pure {
        encodeType(_buf, MAJOR_TYPE_STRING, bytes(_value).length);
        _buf.append(bytes(_value));
    }

    function startArray(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory _buf) internal pure {
        encodeIndefiniteLengthType(_buf, MAJOR_TYPE_CONTENT_FREE);
    }
}





contract usingOraclize {

    using CBOR for Buffer.buffer;

    OraclizeI oraclize;
    OraclizeAddrResolverI OAR;

    uint constant day = 60 * 60 * 24;
    uint constant week = 60 * 60 * 24 * 7;
    uint constant month = 60 * 60 * 24 * 30;

    byte constant proofType_NONE = 0x00;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    byte constant proofType_Android = 0x40;
    byte constant proofType_TLSNotary = 0x10;

    string oraclize_network_name;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_consensys = 161;

    mapping(bytes32 => bytes32) oraclize_randomDS_args;
    mapping(bytes32 => bool) oraclize_randomDS_sessionKeysHashVerified;

    modifier oraclizeAPI {
        if ((address(OAR) == address(0)) || (getCodeSize(address(OAR)) == 0)) {
            oraclize_setNetwork(networkID_auto);
        }
        if (address(oraclize) != OAR.getAddress()) {
            oraclize = OraclizeI(OAR.getAddress());
        }
        _;
    }

    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string memory _result, bytes memory _proof) {

        require((_proof[0] == "L") && (_proof[1] == "P") && (uint8(_proof[2]) == uint8(1)));
        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        require(proofVerified);
        _;
    }

    function oraclize_setNetwork(uint8 _networkID) internal returns (bool _networkSet) {
      return oraclize_setNetwork();
      _networkID;
    }

    function oraclize_setNetworkName(string memory _network_name) internal {
        oraclize_network_name = _network_name;
    }

    function oraclize_getNetworkName() internal view returns (string memory _networkName) {
        return oraclize_network_name;
    }

    function oraclize_setNetwork() internal returns (bool _networkSet) {
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed) > 0) {
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1) > 0) {
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            oraclize_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e) > 0) {
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48) > 0) {
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            oraclize_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41) > 0) {
            OAR = OraclizeAddrResolverI(0xa2998EFD205FB9D4B4963aFb70778D6354ad3A41);
            oraclize_setNetworkName("eth_goerli");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475) > 0) {
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF) > 0) {
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA) > 0) {
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function __callback(bytes32 _myid, string memory _result) public {
        __callback(_myid, _result, new bytes(0));
    }

    function __callback(bytes32 _myid, string memory _result, bytes memory _proof) public {
      return;
      _myid; _result; _proof;
    }

    function oraclize_getPrice(string memory _datasource) oraclizeAPI internal returns (uint _queryPrice) {
        return oraclize.getPrice(_datasource);
    }

    function oraclize_getPrice(string memory _datasource, uint _gasLimit) oraclizeAPI internal returns (uint _queryPrice) {
        return oraclize.getPrice(_datasource, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string memory _arg) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0;
        }
        return oraclize.query.value(price)(0, _datasource, _arg);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string memory _arg) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0;
        }
        return oraclize.query.value(price)(_timestamp, _datasource, _arg);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string memory _arg, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource,_gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0;
        }
        return oraclize.query_withGasLimit.value(price)(_timestamp, _datasource, _arg, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string memory _arg, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
           return 0;
        }
        return oraclize.query_withGasLimit.value(price)(0, _datasource, _arg, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string memory _arg1, string memory _arg2) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0;
        }
        return oraclize.query2.value(price)(0, _datasource, _arg1, _arg2);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0;
        }
        return oraclize.query2.value(price)(_timestamp, _datasource, _arg1, _arg2);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0;
        }
        return oraclize.query2_withGasLimit.value(price)(_timestamp, _datasource, _arg1, _arg2, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string memory _arg1, string memory _arg2, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0;
        }
        return oraclize.query2_withGasLimit.value(price)(0, _datasource, _arg1, _arg2, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[] memory _argN) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0;
        }
        bytes memory args = stra2cbor(_argN);
        return oraclize.queryN.value(price)(0, _datasource, args);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[] memory _argN) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0;
        }
        bytes memory args = stra2cbor(_argN);
        return oraclize.queryN.value(price)(_timestamp, _datasource, args);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[] memory _argN, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0;
        }
        bytes memory args = stra2cbor(_argN);
        return oraclize.queryN_withGasLimit.value(price)(_timestamp, _datasource, args, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[] memory _argN, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0;
        }
        bytes memory args = stra2cbor(_argN);
        return oraclize.queryN_withGasLimit.value(price)(0, _datasource, args, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[1] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[1] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[1] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[1] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[2] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[2] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[2] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[2] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[3] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[3] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[3] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[3] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[4] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[4] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[4] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[4] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[5] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[5] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, string[5] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, string[5] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[] memory _argN) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0;
        }
        bytes memory args = ba2cbor(_argN);
        return oraclize.queryN.value(price)(0, _datasource, args);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[] memory _argN) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource);
        if (price > 1 ether + tx.gasprice * 200000) {
            return 0;
        }
        bytes memory args = ba2cbor(_argN);
        return oraclize.queryN.value(price)(_timestamp, _datasource, args);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[] memory _argN, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0;
        }
        bytes memory args = ba2cbor(_argN);
        return oraclize.queryN_withGasLimit.value(price)(_timestamp, _datasource, args, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[] memory _argN, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        uint price = oraclize.getPrice(_datasource, _gasLimit);
        if (price > 1 ether + tx.gasprice * _gasLimit) {
            return 0;
        }
        bytes memory args = ba2cbor(_argN);
        return oraclize.queryN_withGasLimit.value(price)(0, _datasource, args, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[1] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[1] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[1] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[1] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = _args[0];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[2] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[2] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[2] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[2] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[3] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[3] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[3] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[3] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[4] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[4] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[4] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[4] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[5] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[5] memory _args) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_timestamp, _datasource, dynargs);
    }

    function oraclize_query(uint _timestamp, string memory _datasource, bytes[5] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_timestamp, _datasource, dynargs, _gasLimit);
    }

    function oraclize_query(string memory _datasource, bytes[5] memory _args, uint _gasLimit) oraclizeAPI internal returns (bytes32 _id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = _args[0];
        dynargs[1] = _args[1];
        dynargs[2] = _args[2];
        dynargs[3] = _args[3];
        dynargs[4] = _args[4];
        return oraclize_query(_datasource, dynargs, _gasLimit);
    }

    function oraclize_setProof(byte _proofP) oraclizeAPI internal {
        return oraclize.setProofType(_proofP);
    }


    function oraclize_cbAddress() oraclizeAPI internal returns (address _callbackAddress) {
        return oraclize.cbAddress();
    }

    function getCodeSize(address _addr) view internal returns (uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function oraclize_setCustomGasPrice(uint _gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(_gasPrice);
    }

    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32 _sessionKeyHash) {
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function strCompare(string memory _a, string memory _b) internal pure returns (int _returnCode) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) {
            minLength = b.length;
        }
        for (uint i = 0; i < minLength; i ++) {
            if (a[i] < b[i]) {
                return -1;
            } else if (a[i] > b[i]) {
                return 1;
            }
        }
        if (a.length < b.length) {
            return -1;
        } else if (a.length > b.length) {
            return 1;
        } else {
            return 0;
        }
    }

    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int _returnCode) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length)) {
            return -1;
        } else if (h.length > (2 ** 128 - 1)) {
            return -1;
        } else {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i++) {
                if (h[i] == n[0]) {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) {
                        subindex++;
                    }
                    if (subindex == n.length) {
                        return int(i);
                    }
                }
            }
            return -1;
        }
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function safeParseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return safeParseInt(_a, 0);
    }

    function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal encountered in string!');
                decimals = true;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function parseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return parseInt(_a, 0);
    }

    function parseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) {
                       break;
                   } else {
                       _b--;
                   }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function stra2cbor(string[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeString(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] memory _arr) internal pure returns (bytes memory _cborEncoding) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < _arr.length; i++) {
            buf.encodeBytes(_arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32 _queryId) {
        require((_nbytes > 0) && (_nbytes <= 32));
        _delay *= 10;
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(uint8(_nbytes));
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)





            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly {
            mstore(add(delay, 0x20), _delay)
        }
        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);
        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = oraclize_query("random", args, _customGasLimit);
        bytes memory delay_bytes8_left = new bytes(8);
        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))
        }
        oraclize_randomDS_setCommitment(queryId, keccak256(abi.encodePacked(delay_bytes8_left, args[1], sha256(args[0]), args[2])));
        return queryId;
    }

    function oraclize_randomDS_setCommitment(bytes32 _queryId, bytes32 _commitment) internal {
        oraclize_randomDS_args[_queryId] = _commitment;
    }

    function verifySig(bytes32 _tosignh, bytes memory _dersig, bytes memory _pubkey) internal returns (bool _sigVerified) {
        bool sigok;
        address signer;
        bytes32 sigr;
        bytes32 sigs;
        bytes memory sigr_ = new bytes(32);
        uint offset = 4 + (uint(uint8(_dersig[3])) - 0x20);
        sigr_ = copyBytes(_dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(_dersig, offset + (uint(uint8(_dersig[offset - 1])) - 0x20), 32, sigs_, 0);
        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }
        (sigok, signer) = safer_ecrecover(_tosignh, 27, sigr, sigs);
        if (address(uint160(uint256(keccak256(_pubkey)))) == signer) {
            return true;
        } else {
            (sigok, signer) = safer_ecrecover(_tosignh, 28, sigr, sigs);
            return (address(uint160(uint256(keccak256(_pubkey)))) == signer);
        }
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes memory _proof, uint _sig2offset) internal returns (bool _proofVerified) {
        bool sigok;

        bytes memory sig2 = new bytes(uint(uint8(_proof[_sig2offset + 1])) + 2);
        copyBytes(_proof, _sig2offset, sig2.length, sig2, 0);
        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(_proof, 3 + 1, 64, appkey1_pubkey, 0);
        bytes memory tosign2 = new bytes(1 + 65 + 32);
        tosign2[0] = byte(uint8(1));
        copyBytes(_proof, _sig2offset - 65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1 + 65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);
        if (!sigok) {
            return false;
        }

        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";
        bytes memory tosign3 = new bytes(1 + 65);
        tosign3[0] = 0xFE;
        copyBytes(_proof, 3, 65, tosign3, 1);
        bytes memory sig3 = new bytes(uint(uint8(_proof[3 + 65 + 1])) + 2);
        copyBytes(_proof, 3 + 65, sig3.length, sig3, 0);
        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);
        return sigok;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string memory _result, bytes memory _proof) internal returns (uint8 _returnCode) {

        if ((_proof[0] != "L") || (_proof[1] != "P") || (uint8(_proof[2]) != uint8(1))) {
            return 1;
        }
        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (!proofVerified) {
            return 2;
        }
        return 0;
    }

    function matchBytes32Prefix(bytes32 _content, bytes memory _prefix, uint _nRandomBytes) internal pure returns (bool _matchesPrefix) {
        bool match_ = true;
        require(_prefix.length == _nRandomBytes);
        for (uint256 i = 0; i< _nRandomBytes; i++) {
            if (_content[i] != _prefix[i]) {
                match_ = false;
            }
        }
        return match_;
    }

    function oraclize_randomDS_proofVerify__main(bytes memory _proof, bytes32 _queryId, bytes memory _result, string memory _contextName) internal returns (bool _proofVerified) {

        uint ledgerProofLength = 3 + 65 + (uint(uint8(_proof[3 + 65 + 1])) + 2) + 32;
        bytes memory keyhash = new bytes(32);
        copyBytes(_proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(abi.encodePacked(sha256(abi.encodePacked(_contextName, _queryId)))))) {
            return false;
        }
        bytes memory sig1 = new bytes(uint(uint8(_proof[ledgerProofLength + (32 + 8 + 1 + 32) + 1])) + 2);
        copyBytes(_proof, ledgerProofLength + (32 + 8 + 1 + 32), sig1.length, sig1, 0);

        if (!matchBytes32Prefix(sha256(sig1), _result, uint(uint8(_proof[ledgerProofLength + 32 + 8])))) {
            return false;
        }


        bytes memory commitmentSlice1 = new bytes(8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength + 32, 8 + 1 + 32, commitmentSlice1, 0);
        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength + 32 + (8 + 1 + 32) + sig1.length + 65;
        copyBytes(_proof, sig2offset - 64, 64, sessionPubkey, 0);
        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[_queryId] == keccak256(abi.encodePacked(commitmentSlice1, sessionPubkeyHash))) {
            delete oraclize_randomDS_args[_queryId];
        } else return false;

        bytes memory tosign1 = new bytes(32 + 8 + 1 + 32);
        copyBytes(_proof, ledgerProofLength, 32 + 8 + 1 + 32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) {
            return false;
        }

        if (!oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash]) {
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(_proof, sig2offset);
        }
        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }



    function copyBytes(bytes memory _from, uint _fromOffset, uint _length, bytes memory _to, uint _toOffset) internal pure returns (bytes memory _copiedBytes) {
        uint minLength = _length + _toOffset;
        require(_to.length >= minLength);
        uint i = 32 + _fromOffset;
        uint j = 32 + _toOffset;
        while (i < (32 + _fromOffset + _length)) {
            assembly {
                let tmp := mload(add(_from, i))
                mstore(add(_to, j), tmp)
            }
            i += 32;
            j += 32;
        }
        return _to;
    }




    function safer_ecrecover(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) internal returns (bool _success, address _recoveredAddress) {








        bool ret;
        address addr;
        assembly {
            let size := mload(0x40)
            mstore(size, _hash)
            mstore(add(size, 32), _v)
            mstore(add(size, 64), _r)
            mstore(add(size, 96), _s)
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }
        return (ret, addr);
    }



    function ecrecovery(bytes32 _hash, bytes memory _sig) internal returns (bool _success, address _recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_sig.length != 65) {
            return (false, address(0));
        }





        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))





            v := byte(0, mload(add(_sig, 96)))






        }






        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return (false, address(0));
        }
        return safer_ecrecover(_hash, v, r, s);
    }

    function safeMemoryCleaner() internal pure {
        assembly {
            let fmem := mload(0x40)
            codecopy(fmem, codesize, sub(msize, fmem))
        }
    }
}



























































    function changeDependentContractAddress() public onlyInternal {
        m1 = MCR(ms.getLatestAddress("MC"));
        tf = TokenFunctions(ms.getLatestAddress("TF"));
        tc = TokenController(ms.getLatestAddress("TC"));
        td = TokenData(ms.getLatestAddress("TD"));
        qd = QuotationData(ms.getLatestAddress("QD"));
        p1 = Pool1(ms.getLatestAddress("P1"));
        pd = PoolData(ms.getLatestAddress("PD"));
        mr = MemberRoles(ms.getLatestAddress("MR"));
    }

    function sendEther() public payable {

    }








    function expireCover(uint _cid) public {
        require(checkCoverExpired(_cid) && qd.getCoverStatusNo(_cid) != uint(QuotationData.CoverStatus.CoverExpired));

        tf.unlockCN(_cid);
        bytes4 curr;
        address scAddress;
        uint sumAssured;
        (, , scAddress, curr, sumAssured, ) = qd.getCoverDetailsByCoverID1(_cid);
        if (qd.getCoverStatusNo(_cid) != uint(QuotationData.CoverStatus.ClaimAccepted))
            _removeSAFromCSA(_cid, sumAssured);
        qd.changeCoverStatusNo(_cid, uint8(QuotationData.CoverStatus.CoverExpired));
    }






    function checkCoverExpired(uint _cid) public view returns(bool expire) {

        expire = qd.getValidityOfCover(_cid) < uint64(now);

    }







    function removeSAFromCSA(uint _cid, uint _amount) public onlyInternal {
        _removeSAFromCSA(_cid, _amount);
    }





    function makeCoverUsingNXMTokens(
        uint[] memory coverDetails,
        uint16 coverPeriod,
        bytes4 coverCurr,
        address smartCAdd,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        isMemberAndcheckPause
    {

        tc.burnFrom(msg.sender, coverDetails[2]);
        _verifyCoverDetails(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s);
    }






    function verifyCoverDetails(
        address payable from,
        address scAddress,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        onlyInternal
    {
        _verifyCoverDetails(
            from,
            scAddress,
            coverCurr,
            coverDetails,
            coverPeriod,
            _v,
            _r,
            _s
        );
    }










    function verifySign(
        uint[] memory coverDetails,
        uint16 coverPeriod,
        bytes4 curr,
        address smaratCA,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        view
        returns(bool)
    {
        require(smaratCA != address(0));
        require(pd.capReached() == 1, "Can not buy cover until cap reached for 1st time");
        bytes32 hash = getOrderHash(coverDetails, coverPeriod, curr, smaratCA);
        return isValidSignature(hash, _v, _r, _s);
    }







    function getOrderHash(
        uint[] memory coverDetails,
        uint16 coverPeriod,
        bytes4 curr,
        address smaratCA
    )
        public
        view
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                coverDetails[0],
                curr, coverPeriod,
                smaratCA,
                coverDetails[1],
                coverDetails[2],
                coverDetails[3],
                coverDetails[4],
                address(this)
            )
        );
    }








    function isValidSignature(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public view returns(bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        address a = ecrecover(prefixedHash, v, r, s);
        return (a == qd.getAuthQuoteEngine());
    }






    function getRecentHoldedCoverIdStatus(address userAdd) public view returns(int) {

        uint holdedCoverLen = qd.getUserHoldedCoverLength(userAdd);
        if (holdedCoverLen == 0) {
            return -1;
        } else {
            uint holdedCoverID = qd.getUserHoldedCoverByIndex(userAdd, holdedCoverLen.sub(1));
            return int(qd.holdedCoverIDStatus(holdedCoverID));
        }
    }











    function initiateMembershipAndCover(
        address smartCAdd,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        payable
        checkPause
    {
        require(coverDetails[3] > now);
        require(!qd.timestampRepeated(coverDetails[4]));
        qd.setTimestampRepeated(coverDetails[4]);
        require(!ms.isMember(msg.sender));
        require(qd.refundEligible(msg.sender) == false);
        uint joinFee = td.joiningFee();
        uint totalFee = joinFee;
        if (coverCurr == "ETH") {
            totalFee = joinFee.add(coverDetails[1]);
        } else {
            IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr));
            require(erc20.transferFrom(msg.sender, address(this), coverDetails[1]));
        }
        require(msg.value == totalFee);
        require(verifySign(coverDetails, coverPeriod, coverCurr, smartCAdd, _v, _r, _s));
        qd.addHoldCover(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod);
        qd.setRefundEligible(msg.sender, true);
    }






    function kycVerdict(address _add, bool status) public checkPause noReentrancy {
        require(msg.sender == qd.kycAuthAddress());
        _kycTrigger(status, _add);
    }




    function transferAssetsToNewContract(address newAdd) public onlyInternal noReentrancy {
        uint amount = address(this).balance;
        IERC20 erc20;
        if (amount > 0) {

            Quotation newQT = Quotation(newAdd);
            newQT.sendEther.value(amount)();
        }
        uint currAssetLen = pd.getAllCurrenciesLen();
        for (uint64 i = 1; i < currAssetLen; i++) {
            bytes4 currName = pd.getCurrenciesByIndex(i);
            address currAddr = pd.getCurrencyAssetAddress(currName);
            erc20 = IERC20(currAddr);
            if (erc20.balanceOf(address(this)) > 0) {
                require(erc20.transfer(newAdd, erc20.balanceOf(address(this))));
            }
        }
    }








    function _makeCover (
        address payable from,
        address scAddress,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod
    )
        internal
    {
        uint cid = qd.getCoverLength();
        qd.addCover(coverPeriod, coverDetails[0],
            from, coverCurr, scAddress, coverDetails[1], coverDetails[2]);

        if (coverPeriod <= 60) {
            p1.closeCoverOraclise(cid, uint64(uint(coverPeriod).mul(1 days)));
        }
        uint coverNoteAmount = (coverDetails[2].mul(qd.tokensRetained())).div(100);
        tc.mint(from, coverNoteAmount);
        tf.lockCN(coverNoteAmount, coverPeriod, cid, from);
        qd.addInTotalSumAssured(coverCurr, coverDetails[0]);
        qd.addInTotalSumAssuredSC(scAddress, coverCurr, coverDetails[0]);


        tf.pushStakerRewards(scAddress, coverDetails[2]);
    }






    function _verifyCoverDetails(
        address payable from,
        address scAddress,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        internal
    {
        require(coverDetails[3] > now);
        require(!qd.timestampRepeated(coverDetails[4]));
        qd.setTimestampRepeated(coverDetails[4]);
        require(verifySign(coverDetails, coverPeriod, coverCurr, scAddress, _v, _r, _s));
        _makeCover(from, scAddress, coverCurr, coverDetails, coverPeriod);

    }







    function _removeSAFromCSA(uint _cid, uint _amount) internal checkPause {
        address _add;
        bytes4 coverCurr;
        (, , _add, coverCurr, , ) = qd.getCoverDetailsByCoverID1(_cid);
        qd.subFromTotalSumAssured(coverCurr, _amount);
        qd.subFromTotalSumAssuredSC(_add, coverCurr, _amount);
    }






    function _kycTrigger(bool status, address _add) internal {

        uint holdedCoverLen = qd.getUserHoldedCoverLength(_add).sub(1);
        uint holdedCoverID = qd.getUserHoldedCoverByIndex(_add, holdedCoverLen);
        address payable userAdd;
        address scAddress;
        bytes4 coverCurr;
        uint16 coverPeriod;
        uint[]  memory coverDetails = new uint[](4);
        IERC20 erc20;

        (, userAdd, coverDetails) = qd.getHoldedCoverDetailsByID2(holdedCoverID);
        (, scAddress, coverCurr, coverPeriod) = qd.getHoldedCoverDetailsByID1(holdedCoverID);
        require(qd.refundEligible(userAdd));
        qd.setRefundEligible(userAdd, false);
        require(qd.holdedCoverIDStatus(holdedCoverID) == uint(QuotationData.HCIDStatus.kycPending));
        uint joinFee = td.joiningFee();
        if (status) {
            mr.payJoiningFee.value(joinFee)(userAdd);
            if (coverDetails[3] > now) {
                qd.setHoldedCoverIDStatus(holdedCoverID, uint(QuotationData.HCIDStatus.kycPass));
                address poolAdd = ms.getLatestAddress("P1");
                if (coverCurr == "ETH") {
                    p1.sendEther.value(coverDetails[1])();
                } else {
                    erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr));
                    require(erc20.transfer(poolAdd, coverDetails[1]));
                }
                emit RefundEvent(userAdd, status, holdedCoverID, "KYC Passed");
                _makeCover(userAdd, scAddress, coverCurr, coverDetails, coverPeriod);

            } else {
                qd.setHoldedCoverIDStatus(holdedCoverID, uint(QuotationData.HCIDStatus.kycPassNoCover));
                if (coverCurr == "ETH") {
                    userAdd.transfer(coverDetails[1]);
                } else {
                    erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr));
                    require(erc20.transfer(userAdd, coverDetails[1]));
                }
                emit RefundEvent(userAdd, status, holdedCoverID, "Cover Failed");
            }
        } else {
            qd.setHoldedCoverIDStatus(holdedCoverID, uint(QuotationData.HCIDStatus.kycFailedOrRefunded));
            uint totalRefund = joinFee;
            if (coverCurr == "ETH") {
                totalRefund = coverDetails[1].add(joinFee);
            } else {
                erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr));
                require(erc20.transfer(userAdd, coverDetails[1]));
            }
            userAdd.transfer(totalRefund);
            emit RefundEvent(userAdd, status, holdedCoverID, "KYC Failed");
        }

    }
}



pragma solidity 0.5.7;


contract Factory {
    function getExchange(address token) public view returns (address);
    function getToken(address exchange) public view returns (address);
}


contract Exchange {
    function getEthToTokenInputPrice(uint256 ethSold) public view returns(uint256);

    function getTokenToEthInputPrice(uint256 tokensSold) public view returns(uint256);

    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline) public payable returns (uint256);

    function ethToTokenTransferInput(uint256 minTokens, uint256 deadline, address recipient)
        public payable returns (uint256);

    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline)
        public payable returns (uint256);

    function tokenToEthTransferInput(uint256 tokensSold, uint256 minEth, uint256 deadline, address recipient)
        public payable returns (uint256);

    function tokenToTokenSwapInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address tokenAddress
    )
        public returns (uint256);

    function tokenToTokenTransferInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address recipient,
        address tokenAddress
    )
        public returns (uint256);
}




























































    function changeUniswapFactoryAddress(address newFactoryAddress) external onlyInternal {

        uniswapFactoryAddress = newFactoryAddress;
        factory = Factory(uniswapFactoryAddress);
    }





    function upgradeInvestmentPool(address payable newPoolAddress) external onlyInternal noReentrancy {
        uint len = pd.getInvestmentCurrencyLen();
        for (uint64 i = 1; i < len; i++) {
            bytes4 iaName = pd.getInvestmentCurrencyByIndex(i);
            _upgradeInvestmentPool(iaName, newPoolAddress);
        }

        if (address(this).balance > 0) {
            Pool2 newP2 = Pool2(newPoolAddress);
            newP2.sendEther.value(address(this).balance)();
        }
    }






    function internalLiquiditySwap(bytes4 curr) external onlyInternal noReentrancy {
        uint caBalance;
        uint baseMin;
        uint varMin;
        (, baseMin, varMin) = pd.getCurrencyAssetVarBase(curr);
        caBalance = _getCurrencyAssetsBalance(curr);

        if (caBalance > uint(baseMin).add(varMin).mul(2)) {
            _internalExcessLiquiditySwap(curr, baseMin, varMin, caBalance);
        } else if (caBalance < uint(baseMin).add(varMin)) {
            _internalInsufficientLiquiditySwap(curr, baseMin, varMin, caBalance);

        }
    }







    function saveIADetails(bytes4[] calldata curr, uint64[] calldata rate, uint64 date, bool bit)
    external checkPause noReentrancy {
        bytes4 maxCurr;
        bytes4 minCurr;
        uint64 maxRate;
        uint64 minRate;

        require(pd.isnotarise(msg.sender));
        (maxCurr, maxRate, minCurr, minRate) = _calculateIARank(curr, rate);
        pd.saveIARankDetails(maxCurr, maxRate, minCurr, minRate, date);
        pd.updatelastDate(date);
        uint len = curr.length;
        for (uint i = 0; i < len; i++) {
            pd.updateIAAvgRate(curr[i], rate[i]);
        }
        if (bit)
            _rebalancingLiquidityTrading(maxCurr, maxRate);
        p1.saveIADetailsOracalise(pd.iaRatesTime());
    }





    function externalLiquidityTrade() external onlyInternal {

        bool triggerTrade;
        bytes4 curr;
        bytes4 minIACurr;
        bytes4 maxIACurr;
        uint amount;
        uint minIARate;
        uint maxIARate;
        uint baseMin;
        uint varMin;
        uint caBalance;


        (maxIACurr, maxIARate, minIACurr, minIARate) = pd.getIARankDetailsByDate(pd.getLastDate());
        uint len = pd.getAllCurrenciesLen();
        for (uint64 i = 0; i < len; i++) {
            curr = pd.getCurrenciesByIndex(i);
            (, baseMin, varMin) = pd.getCurrencyAssetVarBase(curr);
            caBalance = _getCurrencyAssetsBalance(curr);

            if (caBalance > uint(baseMin).add(varMin).mul(2)) {
                amount = caBalance.sub(((uint(baseMin).add(varMin)).mul(3)).div(2));
                triggerTrade = _externalExcessLiquiditySwap(curr, minIACurr, amount);
            } else if (caBalance < uint(baseMin).add(varMin)) {
                amount = (((uint(baseMin).add(varMin)).mul(3)).div(2)).sub(caBalance);
                triggerTrade = _externalInsufficientLiquiditySwap(curr, maxIACurr, amount);
            }

            if (triggerTrade) {
                p1.triggerExternalLiquidityTrade();
            }
        }
    }




    function changeDependentContractAddress() public onlyInternal {
        m1 = MCR(ms.getLatestAddress("MC"));
        pd = PoolData(ms.getLatestAddress("PD"));
        p1 = Pool1(ms.getLatestAddress("P1"));
    }

    function sendEther() public payable {

    }




    function _getCurrencyAssetsBalance(bytes4 _curr) public view returns(uint caBalance) {
        if (_curr == "ETH") {
            caBalance = address(p1).balance;
        } else {
            IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(_curr));
            caBalance = erc20.balanceOf(address(p1));
        }
    }




    function _transferInvestmentAsset(
        bytes4 _curr,
        address _transferTo,
        uint _amount
    )
        internal
    {
        if (_curr == "ETH") {
            if (_amount > address(this).balance)
                _amount = address(this).balance;
            p1.sendEther.value(_amount)();
        } else {
            IERC20 erc20 = IERC20(pd.getInvestmentAssetAddress(_curr));
            if (_amount > erc20.balanceOf(address(this)))
                _amount = erc20.balanceOf(address(this));
            require(erc20.transfer(_transferTo, _amount));
        }
    }






    function _rebalancingLiquidityTrading(
        bytes4 iaCurr,
        uint64 iaRate
    )
        internal
        checkPause
    {
        uint amountToSell;
        uint totalRiskBal = pd.getLastVfull();
        uint intermediaryEth;
        uint ethVol = pd.ethVolumeLimit();

        totalRiskBal = (totalRiskBal.mul(100000)).div(DECIMAL1E18);
        Exchange exchange;
        if (totalRiskBal > 0) {
            amountToSell = ((totalRiskBal.mul(2).mul(
                iaRate)).mul(pd.variationPercX100())).div(100 * 100 * 100000);
            amountToSell = (amountToSell.mul(
                10**uint(pd.getInvestmentAssetDecimals(iaCurr)))).div(100);

            if (iaCurr != "ETH" && _checkTradeConditions(iaCurr, iaRate, totalRiskBal)) {
                exchange = Exchange(factory.getExchange(pd.getInvestmentAssetAddress(iaCurr)));
                intermediaryEth = exchange.getTokenToEthInputPrice(amountToSell);
                if (intermediaryEth > (address(exchange).balance.mul(ethVol)).div(100)) {
                    intermediaryEth = (address(exchange).balance.mul(ethVol)).div(100);
                    amountToSell = (exchange.getEthToTokenInputPrice(intermediaryEth).mul(995)).div(1000);
                }
                IERC20 erc20;
                erc20 = IERC20(pd.getCurrencyAssetAddress(iaCurr));
                erc20.approve(address(exchange), amountToSell);
                exchange.tokenToEthSwapInput(amountToSell, (exchange.getTokenToEthInputPrice(
                    amountToSell).mul(995)).div(1000), pd.uniswapDeadline().add(now));
            } else if (iaCurr == "ETH" && _checkTradeConditions(iaCurr, iaRate, totalRiskBal)) {

                _transferInvestmentAsset(iaCurr, ms.getLatestAddress("P1"), amountToSell);
            }
            emit Rebalancing(iaCurr, amountToSell);
        }
    }





    function _checkTradeConditions(
        bytes4 curr,
        uint64 iaRate,
        uint totalRiskBal
    )
        internal
        view
        returns(bool check)
    {
        if (iaRate > 0) {
            uint iaBalance =  _getInvestmentAssetBalance(curr).div(DECIMAL1E18);
            if (iaBalance > 0 && totalRiskBal > 0) {
                uint iaMax;
                uint iaMin;
                uint checkNumber;
                uint z;
                (iaMin, iaMax) = pd.getInvestmentAssetHoldingPerc(curr);
                z = pd.variationPercX100();
                checkNumber = (iaBalance.mul(100 * 100000)).div(totalRiskBal.mul(iaRate));
                if ((checkNumber > ((totalRiskBal.mul(iaMax.add(z))).mul(100000)).div(100)) ||
                    (checkNumber < ((totalRiskBal.mul(iaMin.sub(z))).mul(100000)).div(100)))
                    check = true;
            }
        }
    }




    function _getIARank(
        bytes4 curr,
        uint64 rateX100,
        uint totalRiskPoolBalance
    )
        internal
        view
        returns (int rhsh, int rhsl)
    {

        uint currentIAmaxHolding;
        uint currentIAminHolding;
        uint iaBalance = _getInvestmentAssetBalance(curr);
        (currentIAminHolding, currentIAmaxHolding) = pd.getInvestmentAssetHoldingPerc(curr);

        if (rateX100 > 0) {
            uint rhsf;
            rhsf = (iaBalance.mul(1000000)).div(totalRiskPoolBalance.mul(rateX100));
            rhsh = int(rhsf - currentIAmaxHolding);
            rhsl = int(rhsf - currentIAminHolding);
        }
    }




    function _calculateIARank(
        bytes4[] memory curr,
        uint64[] memory rate
    )
        internal
        view
        returns(
            bytes4 maxCurr,
            uint64 maxRate,
            bytes4 minCurr,
            uint64 minRate
        )
    {
        int max = 0;
        int min = -1;
        int rhsh;
        int rhsl;
        uint totalRiskPoolBalance;
        (totalRiskPoolBalance, ) = m1.calVtpAndMCRtp();
        uint len = curr.length;
        for (uint i = 0; i < len; i++) {
            rhsl = 0;
            rhsh = 0;
            if (pd.getInvestmentAssetStatus(curr[i])) {
                (rhsh, rhsl) = _getIARank(curr[i], rate[i], totalRiskPoolBalance);
                if (rhsh > max || i == 0) {
                    max = rhsh;
                    maxCurr = curr[i];
                    maxRate = rate[i];
                }
                if (rhsl < min || rhsl == 0 || i == 0) {
                    min = rhsl;
                    minCurr = curr[i];
                    minRate = rate[i];
                }
            }
        }
    }






    function _getInvestmentAssetBalance(bytes4 _curr) internal view returns (uint balance) {
        if (_curr == "ETH") {
            balance = address(this).balance;
        } else {
            IERC20 erc20 = IERC20(pd.getInvestmentAssetAddress(_curr));
            balance = erc20.balanceOf(address(this));
        }
    }




    function _internalExcessLiquiditySwap(bytes4 _curr, uint _baseMin, uint _varMin, uint _caBalance) internal {

        bytes4 minIACurr;


        (, , minIACurr, ) = pd.getIARankDetailsByDate(pd.getLastDate());
        if (_curr == minIACurr) {

            p1.transferCurrencyAsset(_curr, _caBalance.sub(((_baseMin.add(_varMin)).mul(3)).div(2)));
        } else {
            p1.triggerExternalLiquidityTrade();
        }
    }





    function _internalInsufficientLiquiditySwap(bytes4 _curr, uint _baseMin, uint _varMin, uint _caBalance) internal {

        bytes4 maxIACurr;
        uint amount;

        (maxIACurr, , , ) = pd.getIARankDetailsByDate(pd.getLastDate());

        if (_curr == maxIACurr) {
            amount = (((_baseMin.add(_varMin)).mul(3)).div(2)).sub(_caBalance);
            _transferInvestmentAsset(_curr, ms.getLatestAddress("P1"), amount);
        } else {
            IERC20 erc20 = IERC20(pd.getInvestmentAssetAddress(maxIACurr));
            if ((maxIACurr == "ETH" && address(this).balance > 0) ||
            (maxIACurr != "ETH" && erc20.balanceOf(address(this)) > 0))
                p1.triggerExternalLiquidityTrade();

        }
    }








    function _externalExcessLiquiditySwap(
        bytes4 curr,
        bytes4 minIACurr,
        uint256 amount
    )
        internal
        returns (bool trigger)
    {
        uint intermediaryEth;
        Exchange exchange;
        IERC20 erc20;
        uint ethVol = pd.ethVolumeLimit();
        if (curr == minIACurr) {
            p1.transferCurrencyAsset(curr, amount);
        } else if (curr == "ETH" && minIACurr != "ETH") {

            exchange = Exchange(factory.getExchange(pd.getInvestmentAssetAddress(minIACurr)));
            if (amount > (address(exchange).balance.mul(ethVol)).div(100)) {
                amount = (address(exchange).balance.mul(ethVol)).div(100);
                trigger = true;
            }
            p1.transferCurrencyAsset(curr, amount);
            exchange.ethToTokenSwapInput.value(amount)
            (exchange.getEthToTokenInputPrice(amount).mul(995).div(1000), pd.uniswapDeadline().add(now));
        } else if (curr != "ETH" && minIACurr == "ETH") {
            exchange = Exchange(factory.getExchange(pd.getCurrencyAssetAddress(curr)));
            erc20 = IERC20(pd.getCurrencyAssetAddress(curr));
            intermediaryEth = exchange.getTokenToEthInputPrice(amount);

            if (intermediaryEth > (address(exchange).balance.mul(ethVol)).div(100)) {
                intermediaryEth = (address(exchange).balance.mul(ethVol)).div(100);
                amount = exchange.getEthToTokenInputPrice(intermediaryEth);
                intermediaryEth = exchange.getTokenToEthInputPrice(amount);
                trigger = true;
            }
            p1.transferCurrencyAsset(curr, amount);

            erc20.approve(address(exchange), amount);

            exchange.tokenToEthSwapInput(amount, (
                intermediaryEth.mul(995)).div(1000), pd.uniswapDeadline().add(now));
        } else {

            exchange = Exchange(factory.getExchange(pd.getCurrencyAssetAddress(curr)));
            intermediaryEth = exchange.getTokenToEthInputPrice(amount);

            if (intermediaryEth > (address(exchange).balance.mul(ethVol)).div(100)) {
                intermediaryEth = (address(exchange).balance.mul(ethVol)).div(100);
                amount = exchange.getEthToTokenInputPrice(intermediaryEth);
                trigger = true;
            }

            Exchange tmp = Exchange(factory.getExchange(
                pd.getInvestmentAssetAddress(minIACurr)));

            if (intermediaryEth > address(tmp).balance.mul(ethVol).div(100)) {
                intermediaryEth = address(tmp).balance.mul(ethVol).div(100);
                amount = exchange.getEthToTokenInputPrice(intermediaryEth);
                trigger = true;
            }
            p1.transferCurrencyAsset(curr, amount);
            erc20 = IERC20(pd.getCurrencyAssetAddress(curr));
            erc20.approve(address(exchange), amount);

            exchange.tokenToTokenSwapInput(amount, (tmp.getEthToTokenInputPrice(
                intermediaryEth).mul(995)).div(1000), (intermediaryEth.mul(995)).div(1000),
                    pd.uniswapDeadline().add(now), pd.getInvestmentAssetAddress(minIACurr));
        }
    }








    function _externalInsufficientLiquiditySwap(
        bytes4 curr,
        bytes4 maxIACurr,
        uint256 amount
    )
        internal
        returns (bool trigger)
    {

        Exchange exchange;
        IERC20 erc20;
        uint intermediaryEth;

        if (curr == maxIACurr) {
            _transferInvestmentAsset(curr, ms.getLatestAddress("P1"), amount);
        } else if (curr == "ETH" && maxIACurr != "ETH") {
            exchange = Exchange(factory.getExchange(pd.getInvestmentAssetAddress(maxIACurr)));
            intermediaryEth = exchange.getEthToTokenInputPrice(amount);


            if (amount > (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100)) {
                amount = (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100);

                intermediaryEth = exchange.getEthToTokenInputPrice(amount);
                trigger = true;
            }

            erc20 = IERC20(pd.getCurrencyAssetAddress(maxIACurr));
            if (intermediaryEth > erc20.balanceOf(address(this))) {
                intermediaryEth = erc20.balanceOf(address(this));
            }

            erc20.approve(address(exchange), intermediaryEth);
            exchange.tokenToEthTransferInput(intermediaryEth, (
                exchange.getTokenToEthInputPrice(intermediaryEth).mul(995)).div(1000),
                pd.uniswapDeadline().add(now), address(p1));

        } else if (curr != "ETH" && maxIACurr == "ETH") {
            exchange = Exchange(factory.getExchange(pd.getCurrencyAssetAddress(curr)));
            intermediaryEth = exchange.getTokenToEthInputPrice(amount);
            if (intermediaryEth > address(this).balance)
                intermediaryEth = address(this).balance;
            if (intermediaryEth > (address(exchange).balance.mul
            (pd.ethVolumeLimit())).div(100)) {
                intermediaryEth = (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100);
                trigger = true;
            }
            exchange.ethToTokenTransferInput.value(intermediaryEth)((exchange.getEthToTokenInputPrice(
                intermediaryEth).mul(995)).div(1000), pd.uniswapDeadline().add(now), address(p1));
        } else {
            address currAdd = pd.getCurrencyAssetAddress(curr);
            exchange = Exchange(factory.getExchange(currAdd));
            intermediaryEth = exchange.getTokenToEthInputPrice(amount);
            if (intermediaryEth > (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100)) {
                intermediaryEth = (address(exchange).balance.mul(pd.ethVolumeLimit())).div(100);
                trigger = true;
            }
            Exchange tmp = Exchange(factory.getExchange(pd.getInvestmentAssetAddress(maxIACurr)));

            if (intermediaryEth > address(tmp).balance.mul(pd.ethVolumeLimit()).div(100)) {
                intermediaryEth = address(tmp).balance.mul(pd.ethVolumeLimit()).div(100);

                trigger = true;
            }

            uint maxIAToSell = tmp.getEthToTokenInputPrice(intermediaryEth);

            erc20 = IERC20(pd.getInvestmentAssetAddress(maxIACurr));
            uint maxIABal = erc20.balanceOf(address(this));
            if (maxIAToSell > maxIABal) {
                maxIAToSell = maxIABal;
                intermediaryEth = tmp.getTokenToEthInputPrice(maxIAToSell);

            }
            amount = exchange.getEthToTokenInputPrice(intermediaryEth);
            erc20.approve(address(tmp), maxIAToSell);
            tmp.tokenToTokenTransferInput(maxIAToSell, (
                amount.mul(995)).div(1000), (
                    intermediaryEth), pd.uniswapDeadline().add(now), address(p1), currAdd);
        }
    }




    function _upgradeInvestmentPool(
        bytes4 _curr,
        address _newPoolAddress
    )
        internal
    {
        IERC20 erc20 = IERC20(pd.getInvestmentAssetAddress(_curr));
        if (erc20.balanceOf(address(this)) > 0)
            require(erc20.transfer(_newPoolAddress, erc20.balanceOf(address(this))));
    }
}






























































    function sendClaimPayout(
        uint coverid,
        uint claimid,
        uint sumAssured,
        address payable coverHolder,
        bytes4 coverCurr
    )
        external
        onlyInternal
        noReentrancy
        returns(bool succ)
    {

        uint sa = sumAssured.div(DECIMAL1E18);
        bool check;
        IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr));


        if (coverCurr == "ETH" && address(this).balance >= sumAssured) {

            coverHolder.transfer(sumAssured);
            check = true;
        } else if (coverCurr == "DAI" && erc20.balanceOf(address(this)) >= sumAssured) {
            erc20.transfer(coverHolder, sumAssured);
            check = true;
        }

        if (check == true) {
            q2.removeSAFromCSA(coverid, sa);
            pd.changeCurrencyAssetVarMin(coverCurr,
                pd.getCurrencyAssetVarMin(coverCurr).sub(sumAssured));
            emit Payout(coverHolder, coverid, sumAssured);
            succ = true;
        } else {
            c1.setClaimStatus(claimid, 12);
        }
        _triggerExternalLiquidityTrade();


        tf.burnStakerLockedToken(coverid, coverCurr, sumAssured);
    }




    function triggerExternalLiquidityTrade() external onlyInternal {
        _triggerExternalLiquidityTrade();
    }


    function closeEmergencyPause(uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(4, time, "URL", "", 300000);
        _saveApiDetails(myid, "EP", 0);
    }




    function closeClaimsOraclise(uint id, uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(4, time, "URL", "", 3000000);
        _saveApiDetails(myid, "CLA", id);
    }




    function closeCoverOraclise(uint id, uint64 time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(4, time, "URL", strConcat(
            "http:
        _saveApiDetails(myid, "COV", id);
    }



    function mcrOraclise(uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(3, time, "URL", "https:
        _saveApiDetails(myid, "MCR", 0);
    }



    function mcrOracliseFail(uint id, uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(4, time, "URL", "", 1000000);
        _saveApiDetails(myid, "MCRF", id);
    }


    function saveIADetailsOracalise(uint time) external onlyInternal {
        bytes32 myid = _oraclizeQuery(3, time, "URL", "https:
        _saveApiDetails(myid, "IARB", 0);
    }





    function upgradeCapitalPool(address payable newPoolAddress) external noReentrancy onlyInternal {
        for (uint64 i = 1; i < pd.getAllCurrenciesLen(); i++) {
            bytes4 caName = pd.getCurrenciesByIndex(i);
            _upgradeCapitalPool(caName, newPoolAddress);
        }
        if (address(this).balance > 0) {
            Pool1 newP1 = Pool1(newPoolAddress);
            newP1.sendEther.value(address(this).balance)();
        }
    }




    function changeDependentContractAddress() public {
        m1 = MCR(ms.getLatestAddress("MC"));
        tk = NXMToken(ms.tokenAddress());
        tf = TokenFunctions(ms.getLatestAddress("TF"));
        tc = TokenController(ms.getLatestAddress("TC"));
        pd = PoolData(ms.getLatestAddress("PD"));
        q2 = Quotation(ms.getLatestAddress("QT"));
        p2 = Pool2(ms.getLatestAddress("P2"));
        c1 = Claims(ms.getLatestAddress("CL"));
        td = TokenData(ms.getLatestAddress("TD"));
    }

    function sendEther() public payable {

    }







    function transferCurrencyAsset(
        bytes4 curr,
        uint amount
    )
        public
        onlyInternal
        noReentrancy
        returns(bool)
    {

        return _transferCurrencyAsset(curr, amount);
    }


    function __callback(bytes32 myid, string memory result) public {
        result;

        ms.delegateCallBack(myid);
    }



    function makeCoverBegin(
        address smartCAdd,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        isMember
        checkPause
        payable
    {
        require(msg.value == coverDetails[1]);
        q2.verifyCoverDetails(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s);
    }




    function makeCoverUsingCA(
        address smartCAdd,
        bytes4 coverCurr,
        uint[] memory coverDetails,
        uint16 coverPeriod,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        isMember
        checkPause
    {
        IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(coverCurr));
        require(erc20.transferFrom(msg.sender, address(this), coverDetails[1]), "Transfer failed");
        q2.verifyCoverDetails(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s);
    }


    function buyToken() public payable isMember checkPause returns(bool success) {
        require(msg.value > 0);
        uint tokenPurchased = _getToken(address(this).balance, msg.value);
        tc.mint(msg.sender, tokenPurchased);
        success = true;
    }





    function transferEther(uint amount, address payable _add) public noReentrancy checkPause returns(bool succ) {
        require(ms.checkIsAuthToGoverned(msg.sender), "Not authorized to Govern");
        succ = _add.send(amount);
    }








    function sellNXMTokens(uint _amount) public isMember noReentrancy checkPause returns(bool success) {
        require(tk.balanceOf(msg.sender) >= _amount, "Not enough balance");
        require(!tf.isLockedForMemberVote(msg.sender), "Member voted");
        require(_amount <= m1.getMaxSellTokens(), "exceeds maximum token sell limit");
        uint sellingPrice = _getWei(_amount);
        tc.burnFrom(msg.sender, _amount);
        msg.sender.transfer(sellingPrice);
        success = true;
    }





    function getInvestmentAssetBalance() public view returns (uint balance) {
        IERC20 erc20;
        uint currTokens;
        for (uint i = 1; i < pd.getInvestmentCurrencyLen(); i++) {
            bytes4 currency = pd.getInvestmentCurrencyByIndex(i);
            erc20 = IERC20(pd.getInvestmentAssetAddress(currency));
            currTokens = erc20.balanceOf(address(p2));
            if (pd.getIAAvgRate(currency) > 0)
                balance = balance.add((currTokens.mul(100)).div(pd.getIAAvgRate(currency)));
        }

        balance = balance.add(address(p2).balance);
    }






    function getWei(uint amount) public view returns(uint weiToPay) {
        return _getWei(amount);
    }






    function getToken(uint weiPaid) public view returns(uint tokenToGet) {
        return _getToken((address(this).balance).add(weiPaid), weiPaid);
    }




    function _triggerExternalLiquidityTrade() internal {
        if (now > pd.lastLiquidityTradeTrigger().add(pd.liquidityTradeCallbackTime())) {
            pd.setLastLiquidityTradeTrigger();
            bytes32 myid = _oraclizeQuery(4, pd.liquidityTradeCallbackTime(), "URL", "", 300000);
            _saveApiDetails(myid, "ULT", 0);
        }
    }






    function _getWei(uint _amount) internal view returns(uint weiToPay) {
        uint tokenPrice;
        uint weiPaid;
        uint tokenSupply = tk.totalSupply();
        uint vtp;
        uint mcrFullperc;
        uint vFull;
        uint mcrtp;
        (mcrFullperc, , vFull, ) = pd.getLastMCR();
        (vtp, ) = m1.calVtpAndMCRtp();

        while (_amount > 0) {
            mcrtp = (mcrFullperc.mul(vtp)).div(vFull);
            tokenPrice = m1.calculateStepTokenPrice("ETH", mcrtp);
            tokenPrice = (tokenPrice.mul(975)).div(1000);
            if (_amount <= td.priceStep().mul(DECIMAL1E18)) {
                weiToPay = weiToPay.add((tokenPrice.mul(_amount)).div(DECIMAL1E18));
                break;
            } else {
                _amount = _amount.sub(td.priceStep().mul(DECIMAL1E18));
                tokenSupply = tokenSupply.sub(td.priceStep().mul(DECIMAL1E18));
                weiPaid = (tokenPrice.mul(td.priceStep().mul(DECIMAL1E18))).div(DECIMAL1E18);
                vtp = vtp.sub(weiPaid);
                weiToPay = weiToPay.add(weiPaid);
            }
        }
    }







    function _getToken(uint _poolBalance, uint _weiPaid) internal view returns(uint tokenToGet) {
        uint tokenPrice;
        uint superWeiLeft = (_weiPaid).mul(DECIMAL1E18);
        uint tempTokens;
        uint superWeiSpent;
        uint tokenSupply = tk.totalSupply();
        uint vtp;
        uint mcrFullperc;
        uint vFull;
        uint mcrtp;
        (mcrFullperc, , vFull, ) = pd.getLastMCR();
        (vtp, ) = m1.calculateVtpAndMCRtp((_poolBalance).sub(_weiPaid));

        require(m1.calculateTokenPrice("ETH") > 0, "Token price can not be zero");
        while (superWeiLeft > 0) {
            mcrtp = (mcrFullperc.mul(vtp)).div(vFull);
            tokenPrice = m1.calculateStepTokenPrice("ETH", mcrtp);
            tempTokens = superWeiLeft.div(tokenPrice);
            if (tempTokens <= td.priceStep().mul(DECIMAL1E18)) {
                tokenToGet = tokenToGet.add(tempTokens);
                break;
            } else {
                tokenToGet = tokenToGet.add(td.priceStep().mul(DECIMAL1E18));
                tokenSupply = tokenSupply.add(td.priceStep().mul(DECIMAL1E18));
                superWeiSpent = td.priceStep().mul(DECIMAL1E18).mul(tokenPrice);
                superWeiLeft = superWeiLeft.sub(superWeiSpent);
                vtp = vtp.add((td.priceStep().mul(DECIMAL1E18).mul(tokenPrice)).div(DECIMAL1E18));
            }
        }
    }







    function _saveApiDetails(bytes32 myid, bytes4 _typeof, uint id) internal {
        pd.saveApiDetails(myid, _typeof, id);
        pd.addInAllApiCall(myid);
    }







    function _transferCurrencyAsset(bytes4 _curr, uint _amount) internal returns(bool succ) {
        if (_curr == "ETH") {
            if (address(this).balance < _amount)
                _amount = address(this).balance;
            p2.sendEther.value(_amount)();
            succ = true;
        } else {
            IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(_curr));
            if (erc20.balanceOf(address(this)) < _amount)
                _amount = erc20.balanceOf(address(this));
            require(erc20.transfer(address(p2), _amount));
            succ = true;

        }
    }




    function _upgradeCapitalPool(
        bytes4 _curr,
        address _newPoolAddress
    )
        internal
    {
        IERC20 erc20 = IERC20(pd.getCurrencyAssetAddress(_curr));
        if (erc20.balanceOf(address(this)) > 0)
            require(erc20.transfer(_newPoolAddress, erc20.balanceOf(address(this))));
    }










    function _oraclizeQuery(
        uint paramCount,
        uint timestamp,
        string memory datasource,
        string memory arg,
        uint gasLimit
    )
        internal
        returns (bytes32 id)
    {
        if (paramCount == 4) {
            id = oraclize_query(timestamp, datasource, arg, gasLimit);
        } else if (paramCount == 3) {
            id = oraclize_query(timestamp, datasource, arg);
        } else {
            id = oraclize_query(datasource, arg);
        }
    }
}
































































    function addMCRData(
        uint mcrP,
        uint mcrE,
        uint vF,
        bytes4[] calldata curr,
        uint[] calldata _threeDayAvg,
        uint64 onlyDate
    )
        external
        checkPause
    {
        require(proposalCategory.constructorCheck());
        require(pd.isnotarise(msg.sender));
        if (mr.launched() && pd.capReached() != 1) {

            if (mcrP >= 10000)
                pd.setCapReached(1);

        }
        uint len = pd.getMCRDataLength();
        _addMCRData(len, onlyDate, curr, mcrE, mcrP, vF, _threeDayAvg);
    }




    function addLastMCRData(uint64 date) external checkPause  onlyInternal {
        uint64 lastdate = uint64(pd.getLastMCRDate());
        uint64 failedDate = uint64(date);
        if (failedDate >= lastdate) {
            uint mcrP;
            uint mcrE;
            uint vF;
            (mcrP, mcrE, vF, ) = pd.getLastMCR();
            uint len = pd.getAllCurrenciesLen();
            pd.pushMCRData(mcrP, mcrE, vF, date);
            for (uint j = 0; j < len; j++) {
                bytes4 currName = pd.getCurrenciesByIndex(j);
                pd.updateCAAvgRate(currName, pd.getCAAvgRate(currName));
            }

            emit MCREvent(date, block.number, new bytes4[](0), new uint[](0), mcrE, mcrP, vF);

            _callOracliseForMCR();
        }
    }




    function changeDependentContractAddress() public onlyInternal {
        qd = QuotationData(ms.getLatestAddress("QD"));
        p1 = Pool1(ms.getLatestAddress("P1"));
        pd = PoolData(ms.getLatestAddress("PD"));
        tk = NXMToken(ms.tokenAddress());
        mr = MemberRoles(ms.getLatestAddress("MR"));
        td = TokenData(ms.getLatestAddress("TD"));
        proposalCategory = ProposalCategory(ms.getLatestAddress("PC"));
    }





    function getAllSumAssurance() public view returns(uint amount) {
        uint len = pd.getAllCurrenciesLen();
        for (uint i = 0; i < len; i++) {
            bytes4 currName = pd.getCurrenciesByIndex(i);
            if (currName == "ETH") {
                amount = amount.add(qd.getTotalSumAssured(currName));
            } else {
                if (pd.getCAAvgRate(currName) > 0)
                    amount = amount.add((qd.getTotalSumAssured(currName).mul(100)).div(pd.getCAAvgRate(currName)));
            }
        }
    }







    function _calVtpAndMCRtp(uint poolBalance) public view returns(uint vtp, uint mcrtp) {
        vtp = 0;
        IERC20 erc20;
        uint currTokens = 0;
        uint i;
        for (i = 1; i < pd.getAllCurrenciesLen(); i++) {
            bytes4 currency = pd.getCurrenciesByIndex(i);
            erc20 = IERC20(pd.getCurrencyAssetAddress(currency));
            currTokens = erc20.balanceOf(address(p1));
            if (pd.getCAAvgRate(currency) > 0)
                vtp = vtp.add((currTokens.mul(100)).div(pd.getCAAvgRate(currency)));
        }

        vtp = vtp.add(poolBalance).add(p1.getInvestmentAssetBalance());
        uint mcrFullperc;
        uint vFull;
        (mcrFullperc, , vFull, ) = pd.getLastMCR();
        if (vFull > 0) {
            mcrtp = (mcrFullperc.mul(vtp)).div(vFull);
        }
    }






    function calculateStepTokenPrice(
        bytes4 curr,
        uint mcrtp
    )
        public
        view
        onlyInternal
        returns(uint tokenPrice)
    {
        return _calculateTokenPrice(curr, mcrtp);
    }






    function calculateTokenPrice (bytes4 curr) public view returns(uint tokenPrice) {
        uint mcrtp;
        (, mcrtp) = _calVtpAndMCRtp(address(p1).balance);
        return _calculateTokenPrice(curr, mcrtp);
    }

    function calVtpAndMCRtp() public view returns(uint vtp, uint mcrtp) {
        return _calVtpAndMCRtp(address(p1).balance);
    }

    function calculateVtpAndMCRtp(uint poolBalance) public view returns(uint vtp, uint mcrtp) {
        return _calVtpAndMCRtp(poolBalance);
    }

    function getThresholdValues(uint vtp, uint vF, uint totalSA, uint minCap) public view returns(uint lowerThreshold, uint upperThreshold)
    {
        minCap = (minCap.mul(minCapFactor)).add(variableMincap);
        uint lower = 0;
        if (vtp >= vF) {
                upperThreshold = vtp.mul(120).mul(100).div((minCap));
            } else {
                upperThreshold = vF.mul(120).mul(100).div((minCap));
            }

            if (vtp > 0) {
                lower = totalSA.mul(DECIMAL1E18).mul(pd.shockParameter()).div(100);
                if(lower < minCap.mul(11).div(10))
                    lower = minCap.mul(11).div(10);
            }
            if (lower > 0) {
                lowerThreshold = vtp.mul(100).mul(100).div(lower);
            }
    }




    function getMaxSellTokens() public view returns(uint maxTokens) {
        uint baseMin = pd.getCurrencyAssetBaseMin("ETH");
        uint maxTokensAccPoolBal;
        if (address(p1).balance > baseMin.mul(50).div(100)) {
            maxTokensAccPoolBal = address(p1).balance.sub(
            (baseMin.mul(50)).div(100));
        }
        maxTokensAccPoolBal = (maxTokensAccPoolBal.mul(DECIMAL1E18)).div(
            (calculateTokenPrice("ETH").mul(975)).div(1000));
        uint lastMCRPerc = pd.getLastMCRPerc();
        if (lastMCRPerc > 10000)
            maxTokens = (((uint(lastMCRPerc).sub(10000)).mul(2000)).mul(DECIMAL1E18)).div(10000);
        if (maxTokens > maxTokensAccPoolBal)
            maxTokens = maxTokensAccPoolBal;
    }







    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint val) {
        codeVal = code;
        if (code == "DMCT") {
            val = dynamicMincapThresholdx100;

        } else if (code == "DMCI") {

            val = dynamicMincapIncrementx100;

        }

    }






    function updateUintParameters(bytes8 code, uint val) public {
        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "DMCT") {
           dynamicMincapThresholdx100 = val;

        } else if (code == "DMCI") {

            dynamicMincapIncrementx100 = val;

        }
         else {
            revert("Invalid param code");
        }

    }




    function _callOracliseForMCR() internal {
        p1.mcrOraclise(pd.mcrTime());
    }







    function _calculateTokenPrice(
        bytes4 _curr,
        uint mcrtp
    )
        internal
        view
        returns(uint tokenPrice)
    {
        uint getA;
        uint getC;
        uint getCAAvgRate;
        uint tokenExponentValue = td.tokenExponent();

        uint max = mcrtp ** tokenExponentValue;
        uint dividingFactor = tokenExponentValue.mul(4);
        (getA, getC, getCAAvgRate) = pd.getTokenPriceDetails(_curr);
        uint mcrEth = pd.getLastMCREther();
        getC = getC.mul(DECIMAL1E18);
        tokenPrice = (mcrEth.mul(DECIMAL1E18).mul(max).div(getC)).div(10 ** dividingFactor);
        tokenPrice = tokenPrice.add(getA.mul(DECIMAL1E18).div(DECIMAL1E05));
        tokenPrice = tokenPrice.mul(getCAAvgRate * 10);
        tokenPrice = (tokenPrice).div(10**3);
    }





    function _addMCRData(
        uint len,
        uint64 newMCRDate,
        bytes4[] memory curr,
        uint mcrE,
        uint mcrP,
        uint vF,
        uint[] memory _threeDayAvg
    )
        internal
    {
        uint vtp = 0;
        uint lowerThreshold = 0;
        uint upperThreshold = 0;
        if (len > 1) {
            (vtp, ) = _calVtpAndMCRtp(address(p1).balance);
            (lowerThreshold, upperThreshold) = getThresholdValues(vtp, vF, getAllSumAssurance(), pd.minCap());

        }
        if(mcrP > dynamicMincapThresholdx100)
            variableMincap =  (variableMincap.mul(dynamicMincapIncrementx100.add(10000)).add(minCapFactor.mul(pd.minCap().mul(dynamicMincapIncrementx100)))).div(10000);









        if (len == 1 || (mcrP) >= lowerThreshold
            && (mcrP) <= upperThreshold) {
            vtp = pd.getLastMCRDate();
            pd.pushMCRData(mcrP, mcrE, vF, newMCRDate);
            for (uint i = 0; i < curr.length; i++) {
                pd.updateCAAvgRate(curr[i], _threeDayAvg[i]);
            }
            emit MCREvent(newMCRDate, block.number, curr, _threeDayAvg, mcrE, mcrP, vF);

            if (vtp < newMCRDate) {
                _callOracliseForMCR();
            }
        } else {
            p1.mcrOracliseFail(newMCRDate, pd.mcrFailTime());
        }
    }

}















































    function setClaimStatus(uint claimId, uint stat) external onlyInternal {
        _setClaimStatus(claimId, stat);
    }




    function getClaimFromNewStart(
        uint index
    )
        external
        view
        returns (
            uint coverId,
            uint claimId,
            int8 voteCA,
            int8 voteMV,
            uint statusnumber
        )
    {
        (coverId, claimId, voteCA, voteMV, statusnumber) = cd.getClaimFromNewStart(index, msg.sender);

    }




    function getUserClaimByIndex(
        uint index
    )
        external
        view
        returns(
            uint status,
            uint coverId,
            uint claimId
        )
    {
        uint statusno;
        (statusno, coverId, claimId) = cd.getUserClaimByIndex(index, msg.sender);
        status = statusno;
    }









    function getClaimbyIndex(uint _claimId) external view returns (
        uint claimId,
        uint status,
        int8 finalVerdict,
        address claimOwner,
        uint coverId
    )
    {
        uint stat;
        claimId = _claimId;
        (, coverId, finalVerdict, stat, , ) = cd.getClaim(_claimId);
        claimOwner = qd.getCoverMemberAddress(coverId);
        status = stat;
    }









    function getCATokens(uint claimId, uint member) external view returns(uint tokens) {
        uint coverId;
        (, coverId) = cd.getClaimCoverId(claimId);
        bytes4 curr = qd.getCurrencyOfCover(coverId);
        uint tokenx1e18 = m1.calculateTokenPrice(curr);
        uint accept;
        uint deny;
        if (member == 0) {
            (, accept, deny) = cd.getClaimsTokenCA(claimId);
        } else {
            (, accept, deny) = cd.getClaimsTokenMV(claimId);
        }
        tokens = ((accept.add(deny)).mul(tokenx1e18)).div(DECIMAL1E18);
    }




    function changeDependentContractAddress() public onlyInternal {
        tk = NXMToken(ms.tokenAddress());
        td = TokenData(ms.getLatestAddress("TD"));
        tf = TokenFunctions(ms.getLatestAddress("TF"));
        tc = TokenController(ms.getLatestAddress("TC"));
        p1 = Pool1(ms.getLatestAddress("P1"));
        p2 = Pool2(ms.getLatestAddress("P2"));
        pd = PoolData(ms.getLatestAddress("PD"));
        cr = ClaimsReward(ms.getLatestAddress("CR"));
        cd = ClaimsData(ms.getLatestAddress("CD"));
        qd = QuotationData(ms.getLatestAddress("QD"));
        m1 = MCR(ms.getLatestAddress("MC"));
    }





    function changePendingClaimStart() public onlyInternal {

        uint origstat;
        uint state12Count;
        uint pendingClaimStart = cd.pendingClaimStart();
        uint actualClaimLength = cd.actualClaimLength();
        for (uint i = pendingClaimStart; i < actualClaimLength; i++) {
            (, , , origstat, , state12Count) = cd.getClaim(i);

            if (origstat > 5 && ((origstat != 12) || (origstat == 12 && state12Count >= 60)))
                cd.setpendingClaimStart(i);
            else
                break;
        }
    }






    function submitClaim(uint coverId) public {
        address qadd = qd.getCoverMemberAddress(coverId);
        require(qadd == msg.sender);
        uint8 cStatus;
        (, cStatus, , , ) = qd.getCoverDetailsByCoverID2(coverId);
        require(cStatus != uint8(QuotationData.CoverStatus.ClaimSubmitted), "Claim already submitted");
        require(cStatus != uint8(QuotationData.CoverStatus.CoverExpired), "Cover already expired");
        if (ms.isPause() == false) {
            _addClaim(coverId, now, qadd);
        } else {
            cd.setClaimAtEmergencyPause(coverId, now, false);
            qd.changeCoverStatusNo(coverId, uint8(QuotationData.CoverStatus.Requested));
        }
    }




    function submitClaimAfterEPOff() public onlyInternal {
        uint lengthOfClaimSubmittedAtEP = cd.getLengthOfClaimSubmittedAtEP();
        uint firstClaimIndexToSubmitAfterEP = cd.getFirstClaimIndexToSubmitAfterEP();
        uint coverId;
        uint dateUpd;
        bool submit;
        address qadd;
        for (uint i = firstClaimIndexToSubmitAfterEP; i < lengthOfClaimSubmittedAtEP; i++) {
            (coverId, dateUpd, submit) = cd.getClaimOfEmergencyPauseByIndex(i);
            require(submit == false);
            qadd = qd.getCoverMemberAddress(coverId);
            _addClaim(coverId, dateUpd, qadd);
            cd.setClaimSubmittedAtEPTrue(i, true);
        }
        cd.setFirstClaimIndexToSubmitAfterEP(lengthOfClaimSubmittedAtEP);
    }






    function submitCAVote(uint claimId, int8 verdict) public isMemberAndcheckPause {
        require(checkVoteClosing(claimId) != 1);
        require(cd.userClaimVotePausedOn(msg.sender).add(cd.pauseDaysCA()) < now);
        uint tokens = tc.tokensLockedAtTime(msg.sender, "CLA", now.add(cd.claimDepositTime()));
        require(tokens > 0);
        uint stat;
        (, stat) = cd.getClaimStatusNumber(claimId);
        require(stat == 0);
        require(cd.getUserClaimVoteCA(msg.sender, claimId) == 0);
        td.bookCATokens(msg.sender);
        cd.addVote(msg.sender, tokens, claimId, verdict);
        cd.callVoteEvent(msg.sender, claimId, "CAV", tokens, now, verdict);
        uint voteLength = cd.getAllVoteLength();
        cd.addClaimVoteCA(claimId, voteLength);
        cd.setUserClaimVoteCA(msg.sender, claimId, voteLength);
        cd.setClaimTokensCA(claimId, verdict, tokens);
        tc.extendLockOf(msg.sender, "CLA", td.lockCADays());
        int close = checkVoteClosing(claimId);
        if (close == 1) {
            cr.changeClaimStatus(claimId);
        }
    }








    function submitMemberVote(uint claimId, int8 verdict) public isMemberAndcheckPause {
        require(checkVoteClosing(claimId) != 1);
        uint stat;
        uint tokens = tc.totalBalanceOf(msg.sender);
        (, stat) = cd.getClaimStatusNumber(claimId);
        require(stat >= 1 && stat <= 5);
        require(cd.getUserClaimVoteMember(msg.sender, claimId) == 0);
        cd.addVote(msg.sender, tokens, claimId, verdict);
        cd.callVoteEvent(msg.sender, claimId, "MV", tokens, now, verdict);
        tc.lockForMemberVote(msg.sender, td.lockMVDays());
        uint voteLength = cd.getAllVoteLength();
        cd.addClaimVotemember(claimId, voteLength);
        cd.setUserClaimVoteMember(msg.sender, claimId, voteLength);
        cd.setClaimTokensMV(claimId, verdict, tokens);
        int close = checkVoteClosing(claimId);
        if (close == 1) {
            cr.changeClaimStatus(claimId);
        }
    }




    function pauseAllPendingClaimsVoting() public onlyInternal {
        uint firstIndex = cd.pendingClaimStart();
        uint actualClaimLength = cd.actualClaimLength();
        for (uint i = firstIndex; i < actualClaimLength; i++) {
            if (checkVoteClosing(i) == 0) {
                uint dateUpd = cd.getClaimDateUpd(i);
                cd.setPendingClaimDetails(i, (dateUpd.add(cd.maxVotingTime())).sub(now), false);
            }
        }
    }




    function startAllPendingClaimsVoting() public onlyInternal {
        uint firstIndx = cd.getFirstClaimIndexToStartVotingAfterEP();
        uint i;
        uint lengthOfClaimVotingPause = cd.getLengthOfClaimVotingPause();
        for (i = firstIndx; i < lengthOfClaimVotingPause; i++) {
            uint pendingTime;
            uint claimID;
            (claimID, pendingTime, ) = cd.getPendingClaimDetailsByIndex(i);
            uint pTime = (now.sub(cd.maxVotingTime())).add(pendingTime);
            cd.setClaimdateUpd(claimID, pTime);
            cd.setPendingClaimVoteStatus(i, true);
            uint coverid;
            (, coverid) = cd.getClaimCoverId(claimID);
            address qadd = qd.getCoverMemberAddress(coverid);
            tf.extendCNEPOff(qadd, coverid, pendingTime.add(cd.claimDepositTime()));
            p1.closeClaimsOraclise(claimID, uint64(pTime));
        }
        cd.setFirstClaimIndexToStartVotingAfterEP(i);
    }







    function checkVoteClosing(uint claimId) public view returns(int8 close) {
        close = 0;
        uint status;
        (, status) = cd.getClaimStatusNumber(claimId);
        uint dateUpd = cd.getClaimDateUpd(claimId);
        if (status == 12 && dateUpd.add(cd.payoutRetryTime()) < now) {
            if (cd.getClaimState12Count(claimId) < 60)
                close = 1;
        }

        if (status > 5 && status != 12) {
            close = -1;
        }  else if (status != 12 && dateUpd.add(cd.maxVotingTime()) <= now) {
            close = 1;
        } else if (status != 12 && dateUpd.add(cd.minVotingTime()) >= now) {
            close = 0;
        } else if (status == 0 || (status >= 1 && status <= 5)) {
            close = _checkVoteClosingFinal(claimId, status);
        }

    }










    function _checkVoteClosingFinal(uint claimId, uint status) internal view returns(int8 close) {
        close = 0;
        uint coverId;
        (, coverId) = cd.getClaimCoverId(claimId);
        bytes4 curr = qd.getCurrencyOfCover(coverId);
        uint tokenx1e18 = m1.calculateTokenPrice(curr);
        uint accept;
        uint deny;
        (, accept, deny) = cd.getClaimsTokenCA(claimId);
        uint caTokens = ((accept.add(deny)).mul(tokenx1e18)).div(DECIMAL1E18);
        (, accept, deny) = cd.getClaimsTokenMV(claimId);
        uint mvTokens = ((accept.add(deny)).mul(tokenx1e18)).div(DECIMAL1E18);
        uint sumassured = qd.getCoverSumAssured(coverId).mul(DECIMAL1E18);
        if (status == 0 && caTokens >= sumassured.mul(10)) {
            close = 1;
        } else if (status >= 1 && status <= 5 && mvTokens >= sumassured.mul(10)) {
            close = 1;
        }
    }







    function _setClaimStatus(uint claimId, uint stat) internal {

        uint origstat;
        uint state12Count;
        uint dateUpd;
        uint coverId;
        (, coverId, , origstat, dateUpd, state12Count) = cd.getClaim(claimId);
        (, origstat) = cd.getClaimStatusNumber(claimId);

        if (stat == 12 && origstat == 12) {
            cd.updateState12Count(claimId, 1);
        }
        cd.setClaimStatus(claimId, stat);

        if (state12Count >= 60 && stat == 12) {
            cd.setClaimStatus(claimId, 13);
            qd.changeCoverStatusNo(coverId, uint8(QuotationData.CoverStatus.ClaimDenied));
        }
        uint time = now;
        cd.setClaimdateUpd(claimId, time);

        if (stat >= 2 && stat <= 5) {
            p1.closeClaimsOraclise(claimId, cd.maxVotingTime());
        }

        if (stat == 12 && (dateUpd.add(cd.payoutRetryTime()) <= now) && (state12Count < 60)) {
            p1.closeClaimsOraclise(claimId, cd.payoutRetryTime());
        } else if (stat == 12 && (dateUpd.add(cd.payoutRetryTime()) > now) && (state12Count < 60)) {
            uint64 timeLeft = uint64((dateUpd.add(cd.payoutRetryTime())).sub(now));
            p1.closeClaimsOraclise(claimId, timeLeft);
        }
    }





    function _addClaim(uint coverId, uint time, address add) internal {
        tf.depositCN(coverId);
        uint len = cd.actualClaimLength();
        cd.addClaim(len, coverId, add, now);
        cd.callClaimEvent(coverId, add, len, time);
        qd.changeCoverStatusNo(coverId, uint8(QuotationData.CoverStatus.ClaimSubmitted));
        bytes4 curr = qd.getCurrencyOfCover(coverId);
        uint sumAssured = qd.getCoverSumAssured(coverId).mul(DECIMAL1E18);
        pd.changeCurrencyAssetVarMin(curr, pd.getCurrencyAssetVarMin(curr).add(sumAssured));
        p2.internalLiquiditySwap(curr);
        p1.closeClaimsOraclise(len, cd.maxVotingTime());
    }
}






























































































































































































































    function claimAllPendingReward(uint records) public isMemberAndcheckPause {
        _claimRewardToBeDistributed(records);
        pooledStaking.withdrawReward(msg.sender);
        uint governanceRewards = gv.claimReward(msg.sender, records);
        if (governanceRewards > 0) {
            require(tk.transfer(msg.sender, governanceRewards));
        }
    }






    function getAllPendingRewardOfUser(address _add) public view returns(uint) {
        uint caReward = getRewardToBeDistributedByUser(_add);
        uint pooledStakingReward = pooledStaking.stakerReward(_add);
        uint governanceReward = gv.getPendingReward(_add);
        return caReward.add(pooledStakingReward).add(governanceReward);
    }




    function _rewardAgainstClaim(uint claimid, uint coverid, uint sumAssured, uint status) internal {
        uint premiumNXM = qd.getCoverPremiumNXM(coverid);
        bytes4 curr = qd.getCurrencyOfCover(coverid);
        uint distributableTokens = premiumNXM.mul(cd.claimRewardPerc()).div(100);

        uint percCA;
        uint percMV;

        (percCA, percMV) = cd.getRewardStatus(status);
        cd.setClaimRewardDetail(claimid, percCA, percMV, distributableTokens);
        if (percCA > 0 || percMV > 0) {
            tc.mint(address(this), distributableTokens);
        }

        if (status == 6 || status == 9 || status == 11) {
            cd.changeFinalVerdict(claimid, -1);
            td.setDepositCN(coverid, false);
            tf.burnDepositCN(coverid);

            pd.changeCurrencyAssetVarMin(curr, pd.getCurrencyAssetVarMin(curr).sub(sumAssured));
            p2.internalLiquiditySwap(curr);

        } else if (status == 7 || status == 8 || status == 10) {
            cd.changeFinalVerdict(claimid, 1);
            td.setDepositCN(coverid, false);
            tf.unlockCN(coverid);
            bool success = p1.sendClaimPayout(coverid, claimid, sumAssured, qd.getCoverMemberAddress(coverid), curr);
            if (success) {
                tf.burnStakedTokens(coverid, curr, sumAssured);
            }
        }
    }


    function _changeClaimStatusCA(uint claimid, uint coverid, uint status) internal {

        if (c1.checkVoteClosing(claimid) == 1) {
            uint caTokens = c1.getCATokens(claimid, 0);
            uint accept;
            uint deny;
            uint acceptAndDeny;
            bool rewardOrPunish;
            uint sumAssured;
            (, accept) = cd.getClaimVote(claimid, 1);
            (, deny) = cd.getClaimVote(claimid, -1);
            acceptAndDeny = accept.add(deny);
            accept = accept.mul(100);
            deny = deny.mul(100);

            if (caTokens == 0) {
                status = 3;
            } else {
                sumAssured = qd.getCoverSumAssured(coverid).mul(DECIMAL1E18);

                if (caTokens > sumAssured.mul(5)) {

                    if (accept.div(acceptAndDeny) > 70) {
                        status = 7;
                        qd.changeCoverStatusNo(coverid, uint8(QuotationData.CoverStatus.ClaimAccepted));
                        rewardOrPunish = true;
                    } else if (deny.div(acceptAndDeny) > 70) {
                        status = 6;
                        qd.changeCoverStatusNo(coverid, uint8(QuotationData.CoverStatus.ClaimDenied));
                        rewardOrPunish = true;
                    } else if (accept.div(acceptAndDeny) > deny.div(acceptAndDeny)) {
                        status = 4;
                    } else {
                        status = 5;
                    }

                } else {

                    if (accept.div(acceptAndDeny) > deny.div(acceptAndDeny)) {
                        status = 2;
                    } else {
                        status = 3;
                    }
                }
            }

            c1.setClaimStatus(claimid, status);

            if (rewardOrPunish) {
                _rewardAgainstClaim(claimid, coverid, sumAssured, status);
            }
        }
    }


    function _changeClaimStatusMV(uint claimid, uint coverid, uint status) internal {


        if (c1.checkVoteClosing(claimid) == 1) {
            uint8 coverStatus;
            uint statusOrig = status;
            uint mvTokens = c1.getCATokens(claimid, 1);


            uint sumAssured = qd.getCoverSumAssured(coverid).mul(DECIMAL1E18);
            uint thresholdUnreached = 0;


            if (mvTokens < sumAssured.mul(5)) {
                thresholdUnreached = 1;
            }

            uint accept;
            (, accept) = cd.getClaimMVote(claimid, 1);
            uint deny;
            (, deny) = cd.getClaimMVote(claimid, -1);

            if (accept.add(deny) > 0) {
                if (accept.mul(100).div(accept.add(deny)) >= 50 && statusOrig > 1 &&
                    statusOrig <= 5 && thresholdUnreached == 0) {
                    status = 8;
                    coverStatus = uint8(QuotationData.CoverStatus.ClaimAccepted);
                } else if (deny.mul(100).div(accept.add(deny)) >= 50 && statusOrig > 1 &&
                    statusOrig <= 5 && thresholdUnreached == 0) {
                    status = 9;
                    coverStatus = uint8(QuotationData.CoverStatus.ClaimDenied);
                }
            }

            if (thresholdUnreached == 1 && (statusOrig == 2 || statusOrig == 4)) {
                status = 10;
                coverStatus = uint8(QuotationData.CoverStatus.ClaimAccepted);
            } else if (thresholdUnreached == 1 && (statusOrig == 5 || statusOrig == 3 || statusOrig == 1)) {
                status = 11;
                coverStatus = uint8(QuotationData.CoverStatus.ClaimDenied);
            }

            c1.setClaimStatus(claimid, status);
            qd.changeCoverStatusNo(coverid, uint8(coverStatus));

            _rewardAgainstClaim(claimid, coverid, sumAssured, status);
        }
    }


    function _claimRewardToBeDistributed(uint _records) internal {
        uint lengthVote = cd.getVoteAddressCALength(msg.sender);
        uint voteid;
        uint lastIndex;
        (lastIndex, ) = cd.getRewardDistributedIndex(msg.sender);
        uint total = 0;
        uint tokenForVoteId = 0;
        bool lastClaimedCheck;
        uint _days = td.lockCADays();
        bool claimed;
        uint counter = 0;
        uint claimId;
        uint perc;
        uint i;
        uint lastClaimed = lengthVote;

        for (i = lastIndex; i < lengthVote && counter < _records; i++) {
            voteid = cd.getVoteAddressCA(msg.sender, i);
            (tokenForVoteId, lastClaimedCheck, , perc) = getRewardToBeGiven(1, voteid, 0);
            if (lastClaimed == lengthVote && lastClaimedCheck == true) {
                lastClaimed = i;
            }
            (, claimId, , claimed) = cd.getVoteDetails(voteid);

            if (perc > 0 && !claimed) {
                counter++;
                cd.setRewardClaimed(voteid, true);
            } else if (perc == 0 && cd.getFinalVerdict(claimId) != 0 && !claimed) {
                (perc, , ) = cd.getClaimRewardDetail(claimId);
                if (perc == 0) {
                    counter++;
                }
                cd.setRewardClaimed(voteid, true);
            }
            if (tokenForVoteId > 0) {
                total = tokenForVoteId.add(total);
            }
        }
        if (lastClaimed == lengthVote) {
            cd.setRewardDistributedIndexCA(msg.sender, i);
        }
        else {
            cd.setRewardDistributedIndexCA(msg.sender, lastClaimed);
        }
        lengthVote = cd.getVoteAddressMemberLength(msg.sender);
        lastClaimed = lengthVote;
        _days = _days.mul(counter);
        if (tc.tokensLockedAtTime(msg.sender, "CLA", now) > 0) {
            tc.reduceLock(msg.sender, "CLA", _days);
        }
        (, lastIndex) = cd.getRewardDistributedIndex(msg.sender);
        lastClaimed = lengthVote;
        counter = 0;
        for (i = lastIndex; i < lengthVote && counter < _records; i++) {
            voteid = cd.getVoteAddressMember(msg.sender, i);
            (tokenForVoteId, lastClaimedCheck, , ) = getRewardToBeGiven(0, voteid, 0);
            if (lastClaimed == lengthVote && lastClaimedCheck == true) {
                lastClaimed = i;
            }
            (, claimId, , claimed) = cd.getVoteDetails(voteid);
            if (claimed == false && cd.getFinalVerdict(claimId) != 0) {
                cd.setRewardClaimed(voteid, true);
                counter++;
            }
            if (tokenForVoteId > 0) {
                total = tokenForVoteId.add(total);
            }
        }
        if (total > 0) {
            require(tk.transfer(msg.sender, total));
        }
        if (lastClaimed == lengthVote) {
            cd.setRewardDistributedIndexMV(msg.sender, i);
        }
        else {
            cd.setRewardDistributedIndexMV(msg.sender, lastClaimed);
        }
    }




    function _claimStakeCommission(uint _records, address _user) external onlyInternal {
        uint total=0;
        uint len = td.getStakerStakedContractLength(_user);
        uint lastCompletedStakeCommission = td.lastCompletedStakeCommission(_user);
        uint commissionEarned;
        uint commissionRedeemed;
        uint maxCommission;
        uint lastCommisionRedeemed = len;
        uint counter;
        uint i;

        for (i = lastCompletedStakeCommission; i < len && counter < _records; i++) {
            commissionRedeemed = td.getStakerRedeemedStakeCommission(_user, i);
            commissionEarned = td.getStakerEarnedStakeCommission(_user, i);
            maxCommission = td.getStakerInitialStakedAmountOnContract(
                _user, i).mul(td.stakerMaxCommissionPer()).div(100);
            if (lastCommisionRedeemed == len && maxCommission != commissionEarned)
                lastCommisionRedeemed = i;
            td.pushRedeemedStakeCommissions(_user, i, commissionEarned.sub(commissionRedeemed));
            total = total.add(commissionEarned.sub(commissionRedeemed));
            counter++;
        }
        if (lastCommisionRedeemed == len) {
            td.setLastCompletedStakeCommissionIndex(_user, i);
        } else {
            td.setLastCompletedStakeCommissionIndex(_user, lastCommisionRedeemed);
        }

        if (total > 0)
            require(tk.transfer(_user, total));
    }
}

































































    function swapABMember (
        address _newABAddress,
        address _removeAB
    )
    external
    checkRoleAuthority(uint(Role.AdvisoryBoard)) {

        _updateRole(_newABAddress, uint(Role.AdvisoryBoard), true);
        _updateRole(_removeAB, uint(Role.AdvisoryBoard), false);

    }





    function swapOwner (
        address _newOwnerAddress
    )
    external {
        require(msg.sender == address(ms));
        _updateRole(ms.owner(), uint(Role.Owner), false);
        _updateRole(_newOwnerAddress, uint(Role.Owner), true);
    }





    function addInitialABMembers(address[] calldata abArray) external onlyOwner {


        require(ms.masterInitialized());

        require(maxABCount >=
            SafeMath.add(numberOfMembers(uint(Role.AdvisoryBoard)), abArray.length)
        );

        for (uint i = 0; i < abArray.length; i++) {
            require(checkRole(abArray[i], uint(MemberRoles.Role.Member)));
            _updateRole(abArray[i], uint(Role.AdvisoryBoard), true);
        }
    }





    function changeMaxABCount(uint _val) external onlyInternal {
        maxABCount = _val;
    }




    function changeDependentContractAddress() public {
        td = TokenData(ms.getLatestAddress("TD"));
        cr = ClaimsReward(ms.getLatestAddress("CR"));
        qd = QuotationData(ms.getLatestAddress("QD"));
        gv = Governance(ms.getLatestAddress("GV"));
        tf = TokenFunctions(ms.getLatestAddress("TF"));
        tk = NXMToken(ms.tokenAddress());
        dAppToken = TokenController(ms.getLatestAddress("TC"));
    }





    function changeMasterAddress(address _masterAddress) public {
        if (masterAddress != address(0))
            require(masterAddress == msg.sender);
        masterAddress = _masterAddress;
        ms = INXMMaster(_masterAddress);
        nxMasterAddress = _masterAddress;

    }






    function memberRolesInitiate (address _firstAB, address memberAuthority) public {
        require(!constructorCheck);
        _addInitialMemberRoles(_firstAB, memberAuthority);
        constructorCheck = true;
    }





    function addRole(
        bytes32 _roleName,
        string memory _roleDescription,
        address _authorized
    )
    public
    onlyAuthorizedToGovern {
        _addRole(_roleName, _roleDescription, _authorized);
    }





    function updateRole(
        address _memberAddress,
        uint _roleId,
        bool _active
    )
    public
    checkRoleAuthority(_roleId) {
        _updateRole(_memberAddress, _roleId, _active);
    }






    function addMembersBeforeLaunch(address[] memory userArray, uint[] memory tokens) public onlyOwner {
        require(!launched);

        for (uint i=0; i < userArray.length; i++) {
            require(!ms.isMember(userArray[i]));
            dAppToken.addToWhitelist(userArray[i]);
            _updateRole(userArray[i], uint(Role.Member), true);
            dAppToken.mint(userArray[i], tokens[i]);
        }
        launched = true;
        launchedOn = now;

    }




    function payJoiningFee(address _userAddress) public payable {
        require(_userAddress != address(0));
        require(!ms.isPause(), "Emergency Pause Applied");
        if (msg.sender == address(ms.getLatestAddress("QT"))) {
            require(td.walletAddress() != address(0), "No walletAddress present");
            dAppToken.addToWhitelist(_userAddress);
            _updateRole(_userAddress, uint(Role.Member), true);
            td.walletAddress().transfer(msg.value);
        } else {
            require(!qd.refundEligible(_userAddress));
            require(!ms.isMember(_userAddress));
            require(msg.value == td.joiningFee());
            qd.setRefundEligible(_userAddress, true);
        }
    }






    function kycVerdict(address payable _userAddress, bool verdict) public {

        require(msg.sender == qd.kycAuthAddress());
        require(!ms.isPause());
        require(_userAddress != address(0));
        require(!ms.isMember(_userAddress));
        require(qd.refundEligible(_userAddress));
        if (verdict) {
            qd.setRefundEligible(_userAddress, false);
            uint fee = td.joiningFee();
            dAppToken.addToWhitelist(_userAddress);
            _updateRole(_userAddress, uint(Role.Member), true);
            td.walletAddress().transfer(fee);

        } else {
            qd.setRefundEligible(_userAddress, false);
            _userAddress.transfer(td.joiningFee());
        }
    }




    function withdrawMembership() public {
        require(!ms.isPause() && ms.isMember(msg.sender));
        require(dAppToken.totalLockedBalance(msg.sender, now) == 0);
        require(!tf.isLockedForMemberVote(msg.sender));
        require(cr.getAllPendingRewardOfUser(msg.sender) == 0);
        require(dAppToken.tokensUnlockable(msg.sender, "CLA") == 0, "Member should have no CLA unlockable tokens");
        gv.removeDelegation(msg.sender);
        dAppToken.burnFrom(msg.sender, tk.balanceOf(msg.sender));
        _updateRole(msg.sender, uint(Role.Member), false);
        dAppToken.removeFromWhitelist(msg.sender);
    }






    function switchMembership(address _add) external {
        require(!ms.isPause() && ms.isMember(msg.sender) && !ms.isMember(_add));
        require(dAppToken.totalLockedBalance(msg.sender, now) == 0);
        require(!tf.isLockedForMemberVote(msg.sender));
        require(cr.getAllPendingRewardOfUser(msg.sender) == 0);
        require(dAppToken.tokensUnlockable(msg.sender, "CLA") == 0, "Member should have no CLA unlockable tokens");
        gv.removeDelegation(msg.sender);
        dAppToken.addToWhitelist(_add);
        _updateRole(_add, uint(Role.Member), true);
        tk.transferFrom(msg.sender, _add, tk.balanceOf(msg.sender));
        _updateRole(msg.sender, uint(Role.Member), false);
        dAppToken.removeFromWhitelist(msg.sender);
        emit switchedMembership(msg.sender, _add, now);
    }


    function totalRoles() public view returns(uint256) {
        return memberRoleData.length;
    }




    function changeAuthorized(uint _roleId, address _newAuthorized) public checkRoleAuthority(_roleId) {
        memberRoleData[_roleId].authorized = _newAuthorized;
    }





    function members(uint _memberRoleId) public view returns(uint, address[] memory memberArray) {
        uint length = memberRoleData[_memberRoleId].memberAddress.length;
        uint i;
        uint j = 0;
        memberArray = new address[](memberRoleData[_memberRoleId].memberCounter);
        for (i = 0; i < length; i++) {
            address member = memberRoleData[_memberRoleId].memberAddress[i];
            if (memberRoleData[_memberRoleId].memberActive[member] && !_checkMemberInArray(member, memberArray)) {
                memberArray[j] = member;
                j++;
            }
        }

        return (_memberRoleId, memberArray);
    }




    function numberOfMembers(uint _memberRoleId) public view returns(uint) {
        return memberRoleData[_memberRoleId].memberCounter;
    }


    function authorized(uint _memberRoleId) public view returns(address) {
        return memberRoleData[_memberRoleId].authorized;
    }


    function roles(address _memberAddress) public view returns(uint[] memory) {
        uint length = memberRoleData.length;
        uint[] memory assignedRoles = new uint[](length);
        uint counter = 0;
        for (uint i = 1; i < length; i++) {
            if (memberRoleData[i].memberActive[_memberAddress]) {
                assignedRoles[counter] = i;
                counter++;
            }
        }
        return assignedRoles;
    }





    function checkRole(address _memberAddress, uint _roleId) public view returns(bool) {
        if (_roleId == uint(Role.UnAssigned))
            return true;
        else
            if (memberRoleData[_roleId].memberActive[_memberAddress])
                return true;
            else
                return false;
    }



    function getMemberLengthForAllRoles() public view returns(uint[] memory totalMembers) {
        totalMembers = new uint[](memberRoleData.length);
        for (uint i = 0; i < memberRoleData.length; i++) {
            totalMembers[i] = numberOfMembers(i);
        }
    }







    function _updateRole(address _memberAddress,
        uint _roleId,
        bool _active) internal {

        if (_active) {
            require(!memberRoleData[_roleId].memberActive[_memberAddress]);
            memberRoleData[_roleId].memberCounter = SafeMath.add(memberRoleData[_roleId].memberCounter, 1);
            memberRoleData[_roleId].memberActive[_memberAddress] = true;
            memberRoleData[_roleId].memberAddress.push(_memberAddress);
        } else {
            require(memberRoleData[_roleId].memberActive[_memberAddress]);
            memberRoleData[_roleId].memberCounter = SafeMath.sub(memberRoleData[_roleId].memberCounter, 1);
            delete memberRoleData[_roleId].memberActive[_memberAddress];
        }
    }





    function _addRole(
        bytes32 _roleName,
        string memory _roleDescription,
        address _authorized
    ) internal {
        emit MemberRole(memberRoleData.length, _roleName, _roleDescription);
        memberRoleData.push(MemberRoleDetails(0, new address[](0), _authorized));
    }







    function _checkMemberInArray(
        address _memberAddress,
        address[] memory memberArray
    )
        internal
        pure
        returns(bool memberExists)
    {
        uint i;
        for (i = 0; i < memberArray.length; i++) {
            if (memberArray[i] == _memberAddress) {
                memberExists = true;
                break;
            }
        }
    }






    function _addInitialMemberRoles(address _firstAB, address memberAuthority) internal {
        maxABCount = 5;
        _addRole("Unassigned", "Unassigned", address(0));
        _addRole(
            "Advisory Board",
            "Selected few members that are deeply entrusted by the dApp. An ideal advisory board should be a mix of skills of domain, governance, research, technology, consulting etc to improve the performance of the dApp.",
            address(0)
        );
        _addRole(
            "Member",
            "Represents all users of Mutual.",
            memberAuthority
        );
        _addRole(
            "Owner",
            "Represents Owner of Mutual.",
            address(0)
        );

        _updateRole(_firstAB, uint(Role.Owner), true);

        launchedOn = 0;
    }

    function memberAtIndex(uint _memberRoleId, uint index) external view returns (address, bool) {
        address memberAddress = memberRoleData[_memberRoleId].memberAddress[index];
        return (memberAddress, memberRoleData[_memberRoleId].memberActive[memberAddress]);
    }

    function membersLength(uint _memberRoleId) external view returns (uint) {
        return memberRoleData[_memberRoleId].memberAddress.length;
    }
}




















































    modifier deprecated() {
        revert("Function deprecated");
        _;
    }














    function addCategory(
        string calldata _name,
        uint _memberRoleToVote,
        uint _majorityVotePerc,
        uint _quorumPerc,
        uint[] calldata _allowedToCreateProposal,
        uint _closingTime,
        string calldata _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] calldata _incentives
    )
        external
        deprecated
    {
    }




    function proposalCategoryInitiate() external deprecated {
    }





    function updateCategoryActionHashes() external onlyOwner {

        require(!categoryActionHashUpdated, "Category action hashes already updated");
        categoryActionHashUpdated = true;
        categoryActionHashes[1] = abi.encodeWithSignature("addRole(bytes32,string,address)");
        categoryActionHashes[2] = abi.encodeWithSignature("updateRole(address,uint256,bool)");
        categoryActionHashes[3] = abi.encodeWithSignature("newCategory(string,uint256,uint256,uint256,uint256[],uint256,string,address,bytes2,uint256[],string)");
        categoryActionHashes[4] = abi.encodeWithSignature("editCategory(uint256,string,uint256,uint256,uint256,uint256[],uint256,string,address,bytes2,uint256[],string)");
        categoryActionHashes[5] = abi.encodeWithSignature("upgradeContractImplementation(bytes2,address)");
        categoryActionHashes[6] = abi.encodeWithSignature("startEmergencyPause()");
        categoryActionHashes[7] = abi.encodeWithSignature("addEmergencyPause(bool,bytes4)");
        categoryActionHashes[8] = abi.encodeWithSignature("burnCAToken(uint256,uint256,address)");
        categoryActionHashes[9] = abi.encodeWithSignature("setUserClaimVotePausedOn(address)");
        categoryActionHashes[12] = abi.encodeWithSignature("transferEther(uint256,address)");
        categoryActionHashes[13] = abi.encodeWithSignature("addInvestmentAssetCurrency(bytes4,address,bool,uint64,uint64,uint8)");
        categoryActionHashes[14] = abi.encodeWithSignature("changeInvestmentAssetHoldingPerc(bytes4,uint64,uint64)");
        categoryActionHashes[15] = abi.encodeWithSignature("changeInvestmentAssetStatus(bytes4,bool)");
        categoryActionHashes[16] = abi.encodeWithSignature("swapABMember(address,address)");
        categoryActionHashes[17] = abi.encodeWithSignature("addCurrencyAssetCurrency(bytes4,address,uint256)");
        categoryActionHashes[20] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[21] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[22] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[23] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[24] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[25] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[26] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
        categoryActionHashes[27] = abi.encodeWithSignature("updateAddressParameters(bytes8,address)");
        categoryActionHashes[28] = abi.encodeWithSignature("updateOwnerParameters(bytes8,address)");
        categoryActionHashes[29] = abi.encodeWithSignature("upgradeContract(bytes2,address)");
        categoryActionHashes[30] = abi.encodeWithSignature("changeCurrencyAssetAddress(bytes4,address)");
        categoryActionHashes[31] = abi.encodeWithSignature("changeCurrencyAssetBaseMin(bytes4,uint256)");
        categoryActionHashes[32] = abi.encodeWithSignature("changeInvestmentAssetAddressAndDecimal(bytes4,address,uint8)");
        categoryActionHashes[33] = abi.encodeWithSignature("externalLiquidityTrade()");
    }




    function totalCategories() external view returns(uint) {
        return allCategory.length;
    }




    function category(uint _categoryId) external view returns(uint, uint, uint, uint, uint[] memory, uint, uint) {
        return(
            _categoryId,
            allCategory[_categoryId].memberRoleToVote,
            allCategory[_categoryId].majorityVotePerc,
            allCategory[_categoryId].quorumPerc,
            allCategory[_categoryId].allowedToCreateProposal,
            allCategory[_categoryId].closingTime,
            allCategory[_categoryId].minStake
        );
    }







    function categoryExtendedData(uint _categoryId) external view returns(uint, uint, uint) {
        return(
            _categoryId,
            categoryABReq[_categoryId],
            isSpecialResolution[_categoryId]
        );
    }









    function categoryAction(uint _categoryId) external view returns(uint, address, bytes2, uint) {

        return(
            _categoryId,
            categoryActionData[_categoryId].contractAddress,
            categoryActionData[_categoryId].contractName,
            categoryActionData[_categoryId].defaultIncentive
        );
    }










    function categoryActionDetails(uint _categoryId) external view returns(uint, address, bytes2, uint, bytes memory) {
        return(
            _categoryId,
            categoryActionData[_categoryId].contractAddress,
            categoryActionData[_categoryId].contractName,
            categoryActionData[_categoryId].defaultIncentive,
            categoryActionHashes[_categoryId]
        );
    }




    function changeDependentContractAddress() public {
        mr = MemberRoles(ms.getLatestAddress("MR"));
    }















    function newCategory(
        string memory _name,
        uint _memberRoleToVote,
        uint _majorityVotePerc,
        uint _quorumPerc,
        uint[] memory _allowedToCreateProposal,
        uint _closingTime,
        string memory _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] memory _incentives,
        string memory _functionHash
    )
        public
        onlyAuthorizedToGovern
    {

        require(_quorumPerc <= 100 && _majorityVotePerc <= 100, "Invalid percentage");

        require((_contractName == "EX" && _contractAddress == address(0)) || bytes(_functionHash).length > 0);

        require(_incentives[3] <= 1, "Invalid special resolution flag");


        if (_incentives[3] == 1) {
            require(_memberRoleToVote == uint(MemberRoles.Role.Member));
            _majorityVotePerc = 0;
            _quorumPerc = 0;
        }

        _addCategory(
            _name,
            _memberRoleToVote,
            _majorityVotePerc,
            _quorumPerc,
            _allowedToCreateProposal,
            _closingTime,
            _actionHash,
            _contractAddress,
            _contractName,
            _incentives
        );


        if (bytes(_functionHash).length > 0 && abi.encodeWithSignature(_functionHash).length == 4) {
            categoryActionHashes[allCategory.length - 1] = abi.encodeWithSignature(_functionHash);
        }
    }





    function changeMasterAddress(address _masterAddress) public {
        if (masterAddress != address(0))
            require(masterAddress == msg.sender);
        masterAddress = _masterAddress;
        ms = INXMMaster(_masterAddress);
        nxMasterAddress = _masterAddress;

    }















    function updateCategory(
        uint _categoryId,
        string memory _name,
        uint _memberRoleToVote,
        uint _majorityVotePerc,
        uint _quorumPerc,
        uint[] memory _allowedToCreateProposal,
        uint _closingTime,
        string memory _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] memory _incentives
    )
        public
        deprecated
    {
    }
















    function editCategory(
        uint _categoryId,
        string memory _name,
        uint _memberRoleToVote,
        uint _majorityVotePerc,
        uint _quorumPerc,
        uint[] memory _allowedToCreateProposal,
        uint _closingTime,
        string memory _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] memory _incentives,
        string memory _functionHash
    )
        public
        onlyAuthorizedToGovern
    {
        require(_verifyMemberRoles(_memberRoleToVote, _allowedToCreateProposal) == 1, "Invalid Role");

        require(_quorumPerc <= 100 && _majorityVotePerc <= 100, "Invalid percentage");

        require((_contractName == "EX" && _contractAddress == address(0)) || bytes(_functionHash).length > 0);

        require(_incentives[3] <= 1, "Invalid special resolution flag");


        if (_incentives[3] == 1) {
            require(_memberRoleToVote == uint(MemberRoles.Role.Member));
            _majorityVotePerc = 0;
            _quorumPerc = 0;
        }

        delete categoryActionHashes[_categoryId];
        if (bytes(_functionHash).length > 0 && abi.encodeWithSignature(_functionHash).length == 4) {
            categoryActionHashes[_categoryId] = abi.encodeWithSignature(_functionHash);
        }
        allCategory[_categoryId].memberRoleToVote = _memberRoleToVote;
        allCategory[_categoryId].majorityVotePerc = _majorityVotePerc;
        allCategory[_categoryId].closingTime = _closingTime;
        allCategory[_categoryId].allowedToCreateProposal = _allowedToCreateProposal;
        allCategory[_categoryId].minStake = _incentives[0];
        allCategory[_categoryId].quorumPerc = _quorumPerc;
        categoryActionData[_categoryId].defaultIncentive = _incentives[1];
        categoryActionData[_categoryId].contractName = _contractName;
        categoryActionData[_categoryId].contractAddress = _contractAddress;
        categoryABReq[_categoryId] = _incentives[2];
        isSpecialResolution[_categoryId] = _incentives[3];
        emit Category(_categoryId, _name, _actionHash);
    }














    function _addCategory(
        string memory _name,
        uint _memberRoleToVote,
        uint _majorityVotePerc,
        uint _quorumPerc,
        uint[] memory _allowedToCreateProposal,
        uint _closingTime,
        string memory _actionHash,
        address _contractAddress,
        bytes2 _contractName,
        uint[] memory _incentives
    )
        internal
    {
        require(_verifyMemberRoles(_memberRoleToVote, _allowedToCreateProposal) == 1, "Invalid Role");
        allCategory.push(
            CategoryStruct(
                _memberRoleToVote,
                _majorityVotePerc,
                _quorumPerc,
                _allowedToCreateProposal,
                _closingTime,
                _incentives[0]
            )
        );
        uint categoryId = allCategory.length - 1;
        categoryActionData[categoryId] = CategoryAction(_incentives[1], _contractAddress, _contractName);
        categoryABReq[categoryId] = _incentives[2];
        isSpecialResolution[categoryId] = _incentives[3];
        emit Category(categoryId, _name, _actionHash);
    }




    function _verifyMemberRoles(uint _memberRoleToVote, uint[] memory _allowedToCreateProposal)
    internal view returns(uint) {
        uint totalRoles = mr.totalRoles();
        if (_memberRoleToVote >= totalRoles) {
            return 0;
        }
        for (uint i = 0; i < _allowedToCreateProposal.length; i++) {
            if (_allowedToCreateProposal[i] >= totalRoles) {
                return 0;
            }
        }
        return 1;
    }

}























































































































































































































































































    event ActionFailed (
        uint256 proposalId
    );




    event ActionRejected (
        uint256 indexed proposalId,
        address rejectedBy
    );




    modifier onlyProposalOwner(uint _proposalId) {
        require(msg.sender == allProposalData[_proposalId].owner, "Not allowed");
        _;
    }




    modifier voteNotStarted(uint _proposalId) {
        require(allProposalData[_proposalId].propStatus < uint(ProposalStatus.VotingStarted));
        _;
    }




    modifier isAllowed(uint _categoryId) {
        require(allowedToCreateProposal(_categoryId), "Not allowed");
        _;
    }




    modifier isAllowedToCategorize() {
        require(memberRole.checkRole(msg.sender, roleIdAllowedToCatgorize), "Not allowed");
        _;
    }




    modifier checkPendingRewards {
        require(getPendingReward(msg.sender) == 0, "Claim reward");
        _;
    }




    event ProposalCategorized(
        uint indexed proposalId,
        address indexed categorizedBy,
        uint categoryId
    );





    function removeDelegation(address _add) external onlyInternal {
        _unDelegate(_add);
    }






    function createProposal(
        string calldata _proposalTitle,
        string calldata _proposalSD,
        string calldata _proposalDescHash,
        uint _categoryId
    )
        external isAllowed(_categoryId)
    {
        require(ms.isMember(msg.sender), "Not Member");

        _createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);
    }






    function updateProposal(
        uint _proposalId,
        string calldata _proposalTitle,
        string calldata _proposalSD,
        string calldata _proposalDescHash
    )
        external onlyProposalOwner(_proposalId)
    {
        require(
            allProposalSolutions[_proposalId].length < 2,
            "Not allowed"
        );
        allProposalData[_proposalId].propStatus = uint(ProposalStatus.Draft);
        allProposalData[_proposalId].category = 0;
        allProposalData[_proposalId].commonIncentive = 0;
        emit Proposal(
            allProposalData[_proposalId].owner,
            _proposalId,
            now,
            _proposalTitle,
            _proposalSD,
            _proposalDescHash
        );
    }




    function categorizeProposal(
        uint _proposalId,
        uint _categoryId,
        uint _incentive
    )
        external
        voteNotStarted(_proposalId) isAllowedToCategorize
    {
        _categorizeProposal(_proposalId, _categoryId, _incentive);
    }





    function addSolution(uint, string calldata, bytes calldata) external {
    }





    function openProposalForVoting(uint) external {
    }






    function submitProposalWithSolution(
        uint _proposalId,
        string calldata _solutionHash,
        bytes calldata _action
    )
        external
        onlyProposalOwner(_proposalId)
    {

        require(allProposalData[_proposalId].propStatus == uint(ProposalStatus.AwaitingSolution));

        _proposalSubmission(_proposalId, _solutionHash, _action);
    }







    function createProposalwithSolution(
        string calldata _proposalTitle,
        string calldata _proposalSD,
        string calldata _proposalDescHash,
        uint _categoryId,
        string calldata _solutionHash,
        bytes calldata _action
    )
        external isAllowed(_categoryId)
    {


        uint proposalId = totalProposals;

        _createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);

        require(_categoryId > 0);

        _proposalSubmission(
            proposalId,
            _solutionHash,
            _action
        );
    }






    function submitVote(uint _proposalId, uint _solutionChosen) external {

        require(allProposalData[_proposalId].propStatus ==
        uint(Governance.ProposalStatus.VotingStarted), "Not allowed");

        require(_solutionChosen < allProposalSolutions[_proposalId].length);


        _submitVote(_proposalId, _solutionChosen);
    }





    function closeProposal(uint _proposalId) external {
        uint category = allProposalData[_proposalId].category;


        uint _memberRole;
        if (allProposalData[_proposalId].dateUpd.add(maxDraftTime) <= now &&
            allProposalData[_proposalId].propStatus < uint(ProposalStatus.VotingStarted)) {
            _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
        } else {
            require(canCloseProposal(_proposalId) == 1);
            (, _memberRole, , , , , ) = proposalCategory.category(allProposalData[_proposalId].category);
            if (_memberRole == uint(MemberRoles.Role.AdvisoryBoard)) {
                _closeAdvisoryBoardVote(_proposalId, category);
            } else {
                _closeMemberVote(_proposalId, category);
            }
        }

    }








    function claimReward(address _memberAddress, uint _maxRecords)
        external returns(uint pendingDAppReward)
    {

        uint voteId;
        address leader;
        uint lastUpd;

        require(msg.sender == ms.getLatestAddress("CR"));

        uint delegationId = followerDelegation[_memberAddress];
        DelegateVote memory delegationData = allDelegation[delegationId];
        if (delegationId > 0 && delegationData.leader != address(0)) {
            leader = delegationData.leader;
            lastUpd = delegationData.lastUpd;
        } else
            leader = _memberAddress;

        uint proposalId;
        uint totalVotes = allVotesByMember[leader].length;
        uint lastClaimed = totalVotes;
        uint j;
        uint i;
        for (i = lastRewardClaimed[_memberAddress]; i < totalVotes && j < _maxRecords; i++) {
            voteId = allVotesByMember[leader][i];
            proposalId = allVotes[voteId].proposalId;
            if (proposalVoteTally[proposalId].voters > 0 && (allVotes[voteId].dateAdd > (
                lastUpd.add(tokenHoldingTime)) || leader == _memberAddress)) {
                if (allProposalData[proposalId].propStatus > uint(ProposalStatus.VotingStarted)) {
                    if (!rewardClaimed[voteId][_memberAddress]) {
                        pendingDAppReward = pendingDAppReward.add(
                                allProposalData[proposalId].commonIncentive.div(
                                    proposalVoteTally[proposalId].voters
                                )
                            );
                        rewardClaimed[voteId][_memberAddress] = true;
                        j++;
                    }
                } else {
                    if (lastClaimed == totalVotes) {
                        lastClaimed = i;
                    }
                }
            }
        }

        if (lastClaimed == totalVotes) {
            lastRewardClaimed[_memberAddress] = i;
        } else {
            lastRewardClaimed[_memberAddress] = lastClaimed;
        }

        if (j > 0) {
            emit RewardClaimed(
                _memberAddress,
                pendingDAppReward
            );
        }
    }





    function setDelegationStatus(bool _status) external isMemberAndcheckPause checkPendingRewards {
        isOpenForDelegation[msg.sender] = _status;
    }





    function delegateVote(address _add) external isMemberAndcheckPause checkPendingRewards {

        require(ms.masterInitialized());

        require(allDelegation[followerDelegation[_add]].leader == address(0));

        if (followerDelegation[msg.sender] > 0) {
            require((allDelegation[followerDelegation[msg.sender]].lastUpd).add(tokenHoldingTime) < now);
        }

        require(!alreadyDelegated(msg.sender));
        require(!memberRole.checkRole(msg.sender, uint(MemberRoles.Role.Owner)));
        require(!memberRole.checkRole(msg.sender, uint(MemberRoles.Role.AdvisoryBoard)));


        require(followerCount[_add] < maxFollowers);

        if (allVotesByMember[msg.sender].length > 0) {
            require((allVotes[allVotesByMember[msg.sender][allVotesByMember[msg.sender].length - 1]].dateAdd).add(tokenHoldingTime)
            < now);
        }

        require(ms.isMember(_add));

        require(isOpenForDelegation[_add]);

        allDelegation.push(DelegateVote(msg.sender, _add, now));
        followerDelegation[msg.sender] = allDelegation.length - 1;
        leaderDelegation[_add].push(allDelegation.length - 1);
        followerCount[_add]++;
        lastRewardClaimed[msg.sender] = allVotesByMember[_add].length;
    }




    function unDelegate() external isMemberAndcheckPause checkPendingRewards {
        _unDelegate(msg.sender);
    }




    function triggerAction(uint _proposalId) external {
        require(proposalActionStatus[_proposalId] == uint(ActionStatus.Accepted) && proposalExecutionTime[_proposalId] <= now, "Cannot trigger");
        _triggerAction(_proposalId, allProposalData[_proposalId].category);
    }




    function rejectAction(uint _proposalId) external {
        require(memberRole.checkRole(msg.sender, uint(MemberRoles.Role.AdvisoryBoard)) && proposalExecutionTime[_proposalId] > now);

        require(proposalActionStatus[_proposalId] == uint(ActionStatus.Accepted));

        require(!proposalRejectedByAB[_proposalId][msg.sender]);

        require(
            keccak256(proposalCategory.categoryActionHashes(allProposalData[_proposalId].category))
            != keccak256(abi.encodeWithSignature("swapABMember(address,address)"))
        );

        proposalRejectedByAB[_proposalId][msg.sender] = true;
        actionRejectedCount[_proposalId]++;
        emit ActionRejected(_proposalId, msg.sender);
        if (actionRejectedCount[_proposalId] == AB_MAJ_TO_REJECT_ACTION) {
            proposalActionStatus[_proposalId] = uint(ActionStatus.Rejected);
        }
    }





    function setInitialActionParameters() external onlyOwner {
        require(!actionParamsInitialised);
        actionParamsInitialised = true;
        actionWaitingTime = 24 * 1 hours;
    }







    function getUintParameters(bytes8 code) external view returns(bytes8 codeVal, uint val) {

        codeVal = code;

        if (code == "GOVHOLD") {

            val = tokenHoldingTime / (1 days);

        } else if (code == "MAXFOL") {

            val = maxFollowers;

        } else if (code == "MAXDRFT") {

            val = maxDraftTime / (1 days);

        } else if (code == "EPTIME") {

            val = ms.pauseTime() / (1 days);

        } else if (code == "ACWT") {

            val = actionWaitingTime / (1 hours);

        }
    }










    function proposal(uint _proposalId)
        external
        view
        returns(
            uint proposalId,
            uint category,
            uint status,
            uint finalVerdict,
            uint totalRewar
        )
    {
        return(
            _proposalId,
            allProposalData[_proposalId].category,
            allProposalData[_proposalId].propStatus,
            allProposalData[_proposalId].finalVerdict,
            allProposalData[_proposalId].commonIncentive
        );
    }








    function proposalDetails(uint _proposalId) external view returns(uint, uint, uint) {
        return(
            _proposalId,
            allProposalSolutions[_proposalId].length,
            proposalVoteTally[_proposalId].voters
        );
    }







    function getSolutionAction(uint _proposalId, uint _solution) external view returns(uint, bytes memory) {
        return (
            _solution,
            allProposalSolutions[_proposalId][_solution]
        );
    }





    function getProposalLength() external view returns(uint) {
        return totalProposals;
    }





    function getFollowers(address _add) external view returns(uint[] memory) {
        return leaderDelegation[_add];
    }






    function getPendingReward(address _memberAddress)
        public view returns(uint pendingDAppReward)
    {
        uint delegationId = followerDelegation[_memberAddress];
        address leader;
        uint lastUpd;
        DelegateVote memory delegationData = allDelegation[delegationId];

        if (delegationId > 0 && delegationData.leader != address(0)) {
            leader = delegationData.leader;
            lastUpd = delegationData.lastUpd;
        } else
            leader = _memberAddress;

        uint proposalId;
        for (uint i = lastRewardClaimed[_memberAddress]; i < allVotesByMember[leader].length; i++) {
            if (allVotes[allVotesByMember[leader][i]].dateAdd > (
                lastUpd.add(tokenHoldingTime)) || leader == _memberAddress) {
                if (!rewardClaimed[allVotesByMember[leader][i]][_memberAddress]) {
                    proposalId = allVotes[allVotesByMember[leader][i]].proposalId;
                    if (proposalVoteTally[proposalId].voters > 0 && allProposalData[proposalId].propStatus
                    > uint(ProposalStatus.VotingStarted)) {
                        pendingDAppReward = pendingDAppReward.add(
                            allProposalData[proposalId].commonIncentive.div(
                                proposalVoteTally[proposalId].voters
                            )
                        );
                    }
                }
            }
        }
    }






    function updateUintParameters(bytes8 code, uint val) public {

        require(ms.checkIsAuthToGoverned(msg.sender));
        if (code == "GOVHOLD") {

            tokenHoldingTime = val * 1 days;

        } else if (code == "MAXFOL") {

            maxFollowers = val;

        } else if (code == "MAXDRFT") {

            maxDraftTime = val * 1 days;

        } else if (code == "EPTIME") {

            ms.updatePauseTime(val * 1 days);

        } else if (code == "ACWT") {

            actionWaitingTime = val * 1 hours;

        } else {

            revert("Invalid code");

        }
    }




    function changeDependentContractAddress() public {
        tokenInstance = TokenController(ms.dAppLocker());
        memberRole = MemberRoles(ms.getLatestAddress("MR"));
        proposalCategory = ProposalCategory(ms.getLatestAddress("PC"));
    }




    function allowedToCreateProposal(uint category) public view returns(bool check) {
        if (category == 0)
            return true;
        uint[] memory mrAllowed;
        (, , , , mrAllowed, , ) = proposalCategory.category(category);
        for (uint i = 0; i < mrAllowed.length; i++) {
            if (mrAllowed[i] == 0 || memberRole.checkRole(msg.sender, mrAllowed[i]))
                return true;
        }
    }






    function alreadyDelegated(address _add) public view returns(bool delegated) {
        for (uint i=0; i < leaderDelegation[_add].length; i++) {
            if (allDelegation[leaderDelegation[_add][i]].leader == _add) {
                return true;
            }
        }
    }





    function pauseProposal(uint) public {
    }





    function resumeProposal(uint) public {
    }






    function canCloseProposal(uint _proposalId)
        public
        view
        returns(uint)
    {
        uint dateUpdate;
        uint pStatus;
        uint _closingTime;
        uint _roleId;
        uint majority;
        pStatus = allProposalData[_proposalId].propStatus;
        dateUpdate = allProposalData[_proposalId].dateUpd;
        (, _roleId, majority, , , _closingTime, ) = proposalCategory.category(allProposalData[_proposalId].category);
        if (
            pStatus == uint(ProposalStatus.VotingStarted)
        ) {
            uint numberOfMembers = memberRole.numberOfMembers(_roleId);
            if (_roleId == uint(MemberRoles.Role.AdvisoryBoard)) {
                if (proposalVoteTally[_proposalId].abVoteValue[1].mul(100).div(numberOfMembers) >= majority
                || proposalVoteTally[_proposalId].abVoteValue[1].add(proposalVoteTally[_proposalId].abVoteValue[0]) == numberOfMembers
                || dateUpdate.add(_closingTime) <= now) {

                    return 1;
                }
            } else {
                if (numberOfMembers == proposalVoteTally[_proposalId].voters
                || dateUpdate.add(_closingTime) <= now)
                    return  1;
            }
        } else if (pStatus > uint(ProposalStatus.VotingStarted)) {
            return  2;
        } else {
            return  0;
        }
    }





    function allowedToCatgorize() public view returns(uint roleId) {
        return roleIdAllowedToCatgorize;
    }









    function voteTallyData(uint _proposalId, uint _solution) public view returns(uint, uint, uint) {
        return (proposalVoteTally[_proposalId].memberVoteValue[_solution],
            proposalVoteTally[_proposalId].abVoteValue[_solution], proposalVoteTally[_proposalId].voters);
    }








    function _createProposal(
        string memory _proposalTitle,
        string memory _proposalSD,
        string memory _proposalDescHash,
        uint _categoryId
    )
        internal
    {
        require(proposalCategory.categoryABReq(_categoryId) == 0 || _categoryId == 0);
        uint _proposalId = totalProposals;
        allProposalData[_proposalId].owner = msg.sender;
        allProposalData[_proposalId].dateUpd = now;
        allProposalSolutions[_proposalId].push("");
        totalProposals++;

        emit Proposal(
            msg.sender,
            _proposalId,
            now,
            _proposalTitle,
            _proposalSD,
            _proposalDescHash
        );

        if (_categoryId > 0)
            _categorizeProposal(_proposalId, _categoryId, 0);
    }







    function _categorizeProposal(
        uint _proposalId,
        uint _categoryId,
        uint _incentive
    )
        internal
    {
        require(
            _categoryId > 0 && _categoryId < proposalCategory.totalCategories(),
            "Invalid category"
        );
        allProposalData[_proposalId].category = _categoryId;
        allProposalData[_proposalId].commonIncentive = _incentive;
        allProposalData[_proposalId].propStatus = uint(ProposalStatus.AwaitingSolution);

        emit ProposalCategorized(_proposalId, msg.sender, _categoryId);
    }







    function _addSolution(uint _proposalId, bytes memory _action, string memory _solutionHash)
        internal
    {
        allProposalSolutions[_proposalId].push(_action);
        emit Solution(_proposalId, msg.sender, allProposalSolutions[_proposalId].length - 1, _solutionHash, now);
    }




    function _proposalSubmission(
        uint _proposalId,
        string memory _solutionHash,
        bytes memory _action
    )
        internal
    {

        uint _categoryId = allProposalData[_proposalId].category;
        if (proposalCategory.categoryActionHashes(_categoryId).length == 0) {
            require(keccak256(_action) == keccak256(""));
            proposalActionStatus[_proposalId] = uint(ActionStatus.NoAction);
        }

        _addSolution(
            _proposalId,
            _action,
            _solutionHash
        );

        _updateProposalStatus(_proposalId, uint(ProposalStatus.VotingStarted));
        (, , , , , uint closingTime, ) = proposalCategory.category(_categoryId);
        emit CloseProposalOnTime(_proposalId, closingTime.add(now));

    }






    function _submitVote(uint _proposalId, uint _solution) internal {

        uint delegationId = followerDelegation[msg.sender];
        uint mrSequence;
        uint majority;
        uint closingTime;
        (, mrSequence, majority, , , closingTime, ) = proposalCategory.category(allProposalData[_proposalId].category);

        require(allProposalData[_proposalId].dateUpd.add(closingTime) > now, "Closed");

        require(memberProposalVote[msg.sender][_proposalId] == 0, "Not allowed");
        require((delegationId == 0) || (delegationId > 0 && allDelegation[delegationId].leader == address(0) &&
        _checkLastUpd(allDelegation[delegationId].lastUpd)));

        require(memberRole.checkRole(msg.sender, mrSequence), "Not Authorized");
        uint totalVotes = allVotes.length;

        allVotesByMember[msg.sender].push(totalVotes);
        memberProposalVote[msg.sender][_proposalId] = totalVotes;

        allVotes.push(ProposalVote(msg.sender, _proposalId, now));

        emit Vote(msg.sender, _proposalId, totalVotes, now, _solution);
        if (mrSequence == uint(MemberRoles.Role.Owner)) {
            if (_solution == 1)
                _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), allProposalData[_proposalId].category, 1, MemberRoles.Role.Owner);
            else
                _updateProposalStatus(_proposalId, uint(ProposalStatus.Rejected));

        } else {
            uint numberOfMembers = memberRole.numberOfMembers(mrSequence);
            _setVoteTally(_proposalId, _solution, mrSequence);

            if (mrSequence == uint(MemberRoles.Role.AdvisoryBoard)) {
                if (proposalVoteTally[_proposalId].abVoteValue[1].mul(100).div(numberOfMembers)
                >= majority
                || (proposalVoteTally[_proposalId].abVoteValue[1].add(proposalVoteTally[_proposalId].abVoteValue[0])) == numberOfMembers) {
                    emit VoteCast(_proposalId);
                }
            } else {
                if (numberOfMembers == proposalVoteTally[_proposalId].voters)
                    emit VoteCast(_proposalId);
            }
        }

    }







    function _setVoteTally(uint _proposalId, uint _solution, uint mrSequence) internal
    {
        uint categoryABReq;
        uint isSpecialResolution;
        (, categoryABReq, isSpecialResolution) = proposalCategory.categoryExtendedData(allProposalData[_proposalId].category);
        if (memberRole.checkRole(msg.sender, uint(MemberRoles.Role.AdvisoryBoard)) && (categoryABReq > 0) ||
            mrSequence == uint(MemberRoles.Role.AdvisoryBoard)) {
            proposalVoteTally[_proposalId].abVoteValue[_solution]++;
        }
        tokenInstance.lockForMemberVote(msg.sender, tokenHoldingTime);
        if (mrSequence != uint(MemberRoles.Role.AdvisoryBoard)) {
            uint voteWeight;
            uint voters = 1;
            uint tokenBalance = tokenInstance.totalBalanceOf(msg.sender);
            uint totalSupply = tokenInstance.totalSupply();
            if (isSpecialResolution == 1) {
                voteWeight = tokenBalance.add(10**18);
            } else {
                voteWeight = (_minOf(tokenBalance, maxVoteWeigthPer.mul(totalSupply).div(100))).add(10**18);
            }
            DelegateVote memory delegationData;
            for (uint i = 0; i < leaderDelegation[msg.sender].length; i++) {
                delegationData = allDelegation[leaderDelegation[msg.sender][i]];
                if (delegationData.leader == msg.sender &&
                _checkLastUpd(delegationData.lastUpd)) {
                    if (memberRole.checkRole(delegationData.follower, mrSequence)) {
                        tokenBalance = tokenInstance.totalBalanceOf(delegationData.follower);
                        tokenInstance.lockForMemberVote(delegationData.follower, tokenHoldingTime);
                        voters++;
                        if (isSpecialResolution == 1) {
                            voteWeight = voteWeight.add(tokenBalance.add(10**18));
                        } else {
                            voteWeight = voteWeight.add((_minOf(tokenBalance, maxVoteWeigthPer.mul(totalSupply).div(100))).add(10**18));
                        }
                    }
                }
            }
            proposalVoteTally[_proposalId].memberVoteValue[_solution] = proposalVoteTally[_proposalId].memberVoteValue[_solution].add(voteWeight);
            proposalVoteTally[_proposalId].voters = proposalVoteTally[_proposalId].voters + voters;
        }
    }







    function _minOf(uint a, uint b) internal pure returns(uint res) {
        res = a;
        if (res > b)
            res = b;
    }






    function _checkLastUpd(uint _lastUpd) internal view returns(bool) {
        return (now - _lastUpd) > tokenHoldingTime;
    }




    function _checkForThreshold(uint _proposalId, uint _category) internal view returns(bool check) {
        uint categoryQuorumPerc;
        uint roleAuthorized;
        (, roleAuthorized, , categoryQuorumPerc, , , ) = proposalCategory.category(_category);
        check = ((proposalVoteTally[_proposalId].memberVoteValue[0]
                            .add(proposalVoteTally[_proposalId].memberVoteValue[1]))
                        .mul(100))
                .div(
                    tokenInstance.totalSupply().add(
                        memberRole.numberOfMembers(roleAuthorized).mul(10 ** 18)
                    )
                ) >= categoryQuorumPerc;
    }








    function _callIfMajReached(uint _proposalId, uint _status, uint category, uint max, MemberRoles.Role role) internal {

        allProposalData[_proposalId].finalVerdict = max;
        _updateProposalStatus(_proposalId, _status);
        emit ProposalAccepted(_proposalId);
        if (proposalActionStatus[_proposalId] != uint(ActionStatus.NoAction)) {
            if (role == MemberRoles.Role.AdvisoryBoard) {
                _triggerAction(_proposalId, category);
            } else {
                proposalActionStatus[_proposalId] = uint(ActionStatus.Accepted);
                proposalExecutionTime[_proposalId] = actionWaitingTime.add(now);
            }
        }
    }




    function _triggerAction(uint _proposalId, uint _categoryId) internal {
        proposalActionStatus[_proposalId] = uint(ActionStatus.Executed);
        bytes2 contractName;
        address actionAddress;
        bytes memory _functionHash;
        (, actionAddress, contractName, , _functionHash) = proposalCategory.categoryActionDetails(_categoryId);
        if (contractName == "MS") {
            actionAddress = address(ms);
        } else if (contractName != "EX") {
            actionAddress = ms.getLatestAddress(contractName);
        }
        (bool actionStatus, ) = actionAddress.call(abi.encodePacked(_functionHash, allProposalSolutions[_proposalId][1]));
        if (actionStatus) {
            emit ActionSuccess(_proposalId);
        } else {
            proposalActionStatus[_proposalId] = uint(ActionStatus.Accepted);
            emit ActionFailed(_proposalId);
        }
    }






    function _updateProposalStatus(uint _proposalId, uint _status) internal {
        if (_status == uint(ProposalStatus.Rejected) || _status == uint(ProposalStatus.Denied)) {
            proposalActionStatus[_proposalId] = uint(ActionStatus.NoAction);
        }
        allProposalData[_proposalId].dateUpd = now;
        allProposalData[_proposalId].propStatus = _status;
    }





    function _unDelegate(address _follower) internal {
        uint followerId = followerDelegation[_follower];
        if (followerId > 0) {

            followerCount[allDelegation[followerId].leader] = followerCount[allDelegation[followerId].leader].sub(1);
            allDelegation[followerId].leader = address(0);
            allDelegation[followerId].lastUpd = now;

            lastRewardClaimed[_follower] = allVotesByMember[_follower].length;
        }
    }






    function _closeMemberVote(uint _proposalId, uint category) internal {
        uint isSpecialResolution;
        uint abMaj;
        (, abMaj, isSpecialResolution) = proposalCategory.categoryExtendedData(category);
        if (isSpecialResolution == 1) {
            uint acceptedVotePerc = proposalVoteTally[_proposalId].memberVoteValue[1].mul(100)
            .div(
                tokenInstance.totalSupply().add(
                        memberRole.numberOfMembers(uint(MemberRoles.Role.Member)).mul(10**18)
                    ));
            if (acceptedVotePerc >= specialResolutionMajPerc) {
                _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, MemberRoles.Role.Member);
            } else {
                _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
            }
        } else {
            if (_checkForThreshold(_proposalId, category)) {
                uint majorityVote;
                (, , majorityVote, , , , ) = proposalCategory.category(category);
                if (
                    ((proposalVoteTally[_proposalId].memberVoteValue[1].mul(100))
                                        .div(proposalVoteTally[_proposalId].memberVoteValue[0]
                                                .add(proposalVoteTally[_proposalId].memberVoteValue[1])
                                        ))
                    >= majorityVote
                    ) {
                        _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, MemberRoles.Role.Member);
                    } else {
                        _updateProposalStatus(_proposalId, uint(ProposalStatus.Rejected));
                    }
            } else {
                if (abMaj > 0 && proposalVoteTally[_proposalId].abVoteValue[1].mul(100)
                .div(memberRole.numberOfMembers(uint(MemberRoles.Role.AdvisoryBoard))) >= abMaj) {
                    _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, MemberRoles.Role.Member);
                } else {
                    _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
                }
            }
        }

        if (proposalVoteTally[_proposalId].voters > 0) {
            tokenInstance.mint(ms.getLatestAddress("CR"), allProposalData[_proposalId].commonIncentive);
        }
    }






    function _closeAdvisoryBoardVote(uint _proposalId, uint category) internal {
        uint _majorityVote;
        MemberRoles.Role _roleId = MemberRoles.Role.AdvisoryBoard;
        (, , _majorityVote, , , , ) = proposalCategory.category(category);
        if (proposalVoteTally[_proposalId].abVoteValue[1].mul(100)
        .div(memberRole.numberOfMembers(uint(_roleId))) >= _majorityVote) {
            _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, _roleId);
        } else {
            _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
        }

    }

}
