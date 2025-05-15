







pragma solidity 0.5.7;

















































































    function  changeDependentContractAddress() public;





    function changeMasterAddress(address _masterAddress) public {
        if (address(ms) != address(0)) {
            require(address(ms) == msg.sender, "Not master");
        }
        ms = INXMMaster(_masterAddress);
        nxMasterAddress = _masterAddress;
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
        require(b <= a);
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

interface IPooledStaking {

    function pushReward(address contractAddress, uint amount) external;
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
