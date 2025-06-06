

pragma solidity 0.8.4;















import "../security/ReentrancyGuard.sol";
import "../security/Ownable.sol";

import "../utils/NonZeroAddressGuard.sol";
import "./VotingStorage.sol";

contract VotingEscrow is VotingStorage, Ownable, ReentrancyGuard, NonZeroAddressGuard {

    event Deposited(address indexed provider, uint256 value, uint256 lockTime);
    event IncreasedAmount(address indexed provider, uint256 amount);
    event IncreasedTime(address indexed provider, uint256 time);
    event Withdrawn(address indexed provider, uint256 value);


    event DelegateChanged(address indexed delegator, address indexed delegatee);


    event SmartWalletCheckedChanged(address oldChecker, address newChecker);


    modifier onlyLockOwner(address addr) {
        require(locks[addr].owner == addr, "only owner can call this function");
        _;
    }

    modifier onlyAllowed(address addr) {
        isAllowed(addr);
        _;
    }

    function isAllowed(address addr) internal view {
        if (addr != tx.origin) {
            require(smartWalletChecker.check(addr), "Smart contract depositors not allowed");
        }
    }

    constructor(IERC20 amptToken_, SmartWalletChecker smartWalletChecker_, string memory name_, string memory symbol_) {
        amptToken = amptToken_;
        smartWalletChecker = smartWalletChecker_;

        name = name_;
        symbol = symbol_;

        pointHistory[0].block = getBlockNumber();
        pointHistory[0].ts = getBlockTimestamp();
    }


    function decimals() external pure returns (uint8) {
        return 18;
    }




    function locked(address addr) external view returns (Lock memory) {
        return locks[addr];
    }

    function changeSmartWalletChecker(SmartWalletChecker newSmartWalletChecker) external onlyOwner nonZeroAddress(address(newSmartWalletChecker)) {
        SmartWalletChecker currentWalletChecker = smartWalletChecker;
        require(newSmartWalletChecker != currentWalletChecker, "New smart wallet checker is the same as the old one");
        smartWalletChecker = newSmartWalletChecker;
        emit SmartWalletCheckedChanged(address(currentWalletChecker), address(newSmartWalletChecker));
    }






    function balanceOf(address addr) external view returns (uint256) {
        uint256 _votePower = 0;
        Lock memory lock = locks[addr];


        if(lock.amount > 0 && userOwnsTheLock(lock, addr)) {
            _votePower = balanceOfOneLock(addr);
        }


        if(delegations[addr].length > 0) {
            for(uint256 i = 0; i < delegations[addr].length; i++) {
                _votePower += balanceOfOneLock(delegations[addr][i]);
            }
        }
        return _votePower;
    }

    function userOwnsTheLock(Lock memory _lock, address owner) internal pure returns (bool) {
        return _lock.owner == owner && _lock.delegator == address(0);
    }

    function balanceOfOneLock(address addr) internal view returns (uint256) {
        uint256 _epoch = userPointEpoch[addr];
        uint256 ts = getBlockTimestamp();

        if (_epoch == 0) {
            return 0;
        } else {
            Point memory _point = userPointHistory[addr][_epoch];
            _point.bias -= _point.slope * int256(ts - _point.ts);

            if (_point.bias < 0) {
                _point.bias = 0;
            }
            return uint256(_point.bias);
        }
    }





    function totalSupply() external view returns (uint256) {
        return supplyAt(getBlockTimestamp());
    }






    function totalSupplyAt(uint256 block_) external view returns (uint256) {
        uint256 currentTimestamp = getBlockTimestamp();
        uint256 currentBlock = getBlockNumber();

        require(currentBlock >= block_, "Block must be in the past");

        uint256 _targetEpoch = findBlockEpoch(block_, epoch);
        Point memory point = pointHistory[_targetEpoch];
        uint256 dt = 0;

        if (epoch > _targetEpoch) {
            Point memory nextPoint = pointHistory[_targetEpoch + 1];
            if (point.block != nextPoint.block) {
                dt = (block_ - point.block) * (nextPoint.ts - point.ts) / (nextPoint.block - point.block);
            }
        } else if (point.block != currentBlock) {
            dt = (block_ - point.block) * (currentTimestamp - point.ts) / (currentBlock - point.block);
        }

        return supplyAt(point.ts + dt);
    }






    function supplyAt(uint256 timestamp) internal view returns (uint256) {
        Point memory point = pointHistory[epoch];
        uint256 timeIndex = point.ts * WEEK / WEEK;

        for(int256 i=0; i <= 255; i++) {
            timeIndex += WEEK;
            int256 dSlope = 0;

            if (timeIndex > timestamp) {
                timeIndex = timestamp;
            } else {
                dSlope = slopeChanges[timeIndex];
            }

            point.bias -= point.slope * int256(timeIndex - point.ts);
            if (timeIndex == timestamp) {
                break;
            }
            point.slope += dSlope;
            point.ts = timeIndex;
        }

        if (point.bias < 0) {
            point.bias = 0;
        }
        return uint256(point.bias);
    }







    function findBlockEpoch(uint256 block_, uint256 epoch_) internal view returns (uint256)  {
        uint256 _min = 0;
        uint256 _max = epoch_;
        for(int256 i=0; i <= 128; i++) {
            if (_min >= _max) break;

            uint256 _mid = (_min + _max + 1) / 2;

            if (pointHistory[_mid].block <= block_) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }




    function checkpoint() external {
        Lock memory emptyLock = Lock(0, 0, address(0), address(0));
        checkpointInternal(address(0), emptyLock, emptyLock);
    }






    function createLock(uint256 value, uint256 unlockTime) external {
        createLockInternal(msg.sender, value, unlockTime);
    }

    function createLockInternal(address depositer, uint256 value, uint256 unlockTime) internal nonReentrant nonZeroAddress(depositer) {
        require(value > 0, "zero value");

        uint256 currentTime = getBlockTimestamp();
        require(unlockTime > currentTime, "unlock time is in the past");
        require(currentTime + MAXCAP >= unlockTime, "lock can be 4 years max");

        Lock storage newLock = locks[depositer];
        require(newLock.amount == 0, "already locked");

        Lock memory oldLock = newLock;

        newLock.amount = value;
        newLock.end = unlockTime;
        newLock.owner = depositer;
        newLock.delegator = address(0);

        totalLocked += value;


        checkpointInternal(depositer, oldLock, newLock);

        emit Deposited(depositer, value, unlockTime);
        assert(amptToken.transferFrom(depositer, address(this), value));
    }





    function increaseLockAmount(uint256 value) external onlyLockOwner(msg.sender) {
        increaseLockAmountInternal(msg.sender, value);
    }

    function increaseLockAmountInternal(address depositer, uint256 value) internal nonReentrant {
        require(value > 0, "zero value");

        Lock storage lock = locks[depositer];
        require(lock.end > getBlockTimestamp(), "lock has expired. Withdraw");

        Lock memory oldLock = lock;
        lock.amount += value;
        totalLocked += value;


        checkpointInternal(depositer, oldLock, lock);

        emit IncreasedAmount(depositer, value);
        assert(amptToken.transferFrom(depositer, address(this), value));
    }





    function increaseLockTime(uint256 newLockTime) external onlyLockOwner(msg.sender) {
        increaseLockTimeInternal(msg.sender, newLockTime);
    }

    function increaseLockTimeInternal(address depositer, uint256 newLockTime) internal nonReentrant {
        uint256 currentTimestamp = getBlockTimestamp();
        require(currentTimestamp + MAXCAP >= newLockTime, "lock can be 4 years max");

        Lock storage lock = locks[depositer];
        require(lock.end > currentTimestamp, "lock has expired. Withdraw");
        require(newLockTime > lock.end, "lock time lower than expiration");

        Lock memory oldLock = lock;
        lock.end = newLockTime;


        checkpointInternal(depositer, oldLock, lock);

        emit IncreasedTime(depositer, newLockTime);
    }





    function withdraw() external onlyLockOwner(msg.sender) {
        withdrawInternal(msg.sender);
    }

    function withdrawInternal(address depositer) internal nonReentrant {
        Lock storage lock = locks[depositer];
        require(lock.end <= getBlockTimestamp(), "lock has not expired yet");

        Lock memory oldLock = lock;
        lock.amount = 0;
        lock.end = 0;


        checkpointInternal(depositer, oldLock, lock);

        emit Withdrawn(depositer, oldLock.amount);
        assert(amptToken.transfer(depositer, oldLock.amount));
    }







    function depositFor(address depositer, uint256 value) external nonReentrant nonZeroAddress(depositer) {
        require(value > 0, "zero value");

        Lock storage _lock = locks[depositer];
        require(_lock.amount > 0, "no lock found");
        require(_lock.end > getBlockTimestamp(), "Cannot add to expired lock. Withdraw");

        Lock memory oldLock = _lock;
        _lock.amount += value;
        totalLocked += value;


        checkpointInternal(depositer, oldLock, _lock);

        emit IncreasedAmount(depositer, value);
        assert(amptToken.transferFrom(msg.sender, address(this), value));
    }





    function delegate(address delegatee) external onlyAllowed(msg.sender) {
        delegateInternal(msg.sender, delegatee);
    }










    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "delegateBySig: invalid signature");

        require(nonce == nonces[signatory], "delegateBySig: invalid nonce");
        nonces[signatory]++;
        require(getBlockTimestamp() <= expiry, "delegateBySig: signature expired");

        delegateInternal(signatory, delegatee);
    }

    function delegateInternal(address delegator, address delegatee) internal nonReentrant {
        require(delegator != address(0), "Cannot delegate from the zero address");
        require(delegator != delegatee, "Cannot delegate to self");

        Lock storage delegatorLock = locks[delegator];
        require(delegatorLock.amount > 0, "No existing lock found");
        require(delegatorLock.delegator != delegatee, "Cannot delegate to the same address");

        address oldDelegatee = delegatorLock.delegator;
        if (delegatee == address(0)) {
            uint256 delegateeIndex = delegationIndexInMap[oldDelegatee][delegator];

            delete delegations[oldDelegatee][delegateeIndex];
            delete delegationIndexInMap[oldDelegatee][delegator];
        } else {
            if(oldDelegatee != address(0)) {
                uint256 delegateeIndex = delegationIndexInMap[oldDelegatee][delegator];

                delete delegations[oldDelegatee][delegateeIndex];
                delete delegationIndexInMap[oldDelegatee][delegator];
            } else {
                delegations[delegatee].push(delegator);
                delegationIndexInMap[delegatee][delegator] = delegations[delegatee].length - 1;
            }
        }
        delegatorLock.delegator = delegatee;


        checkpointInternal(delegator, delegatorLock, delegatorLock);

        emit DelegateChanged(delegator, delegatee);
    }

    struct CheckPointVars {
        int256 oldDslope;
        int256 newDslope;
        uint256 epoch;
        uint256 block;
        uint256 ts;
        uint256 userEpoch;
    }






    function checkpointInternal(address addr, Lock memory oldLock, Lock memory newLock) internal {
        Point memory _userPointOld = Point(0, 0, 0, 0);
        Point memory _userPointNew = Point(0, 0, 0, 0);

        CheckPointVars memory _vars = CheckPointVars(
            0,
            0,
            epoch,
            getBlockNumber(),
            getBlockTimestamp(),
            userPointEpoch[addr]
        );

        if (addr != address(0)) {
            if (oldLock.end > _vars.ts && oldLock.amount > 0) {
                _userPointOld.slope = int256(oldLock.amount / MAXCAP);
                _userPointOld.bias = _userPointOld.slope * int256(oldLock.end - _vars.ts);
            }

            if (newLock.end > _vars.ts && newLock.amount > 0) {
                _userPointNew.slope = int256(newLock.amount / MAXCAP);
                _userPointNew.bias = _userPointNew.slope * int256(newLock.end - _vars.ts);
            }

            _vars.oldDslope = slopeChanges[oldLock.end];
            if (newLock.end != 0) {
                if (newLock.end == oldLock.end) {
                    _vars.newDslope = _vars.oldDslope;
                } else {
                    _vars.newDslope = slopeChanges[newLock.end];
                }
            }
        }

        Point memory lastPoint = Point(0, 0, _vars.ts, _vars.block);
        if (_vars.epoch > 0) {
            lastPoint = pointHistory[_vars.epoch];
        }

        uint lastCheckpoint = lastPoint.ts;
        Point memory initialLastPoint = lastPoint;
        uint256 blockSlope = 0;
        if (_vars.ts > lastPoint.ts) {
            blockSlope = 1e18 * (_vars.block - lastPoint.block) / (_vars.ts - lastPoint.ts);
        }


        uint256 timeIndex = lastCheckpoint * WEEK / WEEK;
        for (int256 i=0; i <= 255; i++) {
            timeIndex += WEEK;
            int256 dSlope = 0;

            if (timeIndex > _vars.ts) {
                timeIndex = _vars.ts;
            } else {
                dSlope = slopeChanges[timeIndex];
            }

            lastPoint.bias -= lastPoint.slope * int256(timeIndex - lastCheckpoint);
            lastPoint.slope += dSlope;
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            lastCheckpoint = timeIndex;
            lastPoint.ts = timeIndex;

            lastPoint.block = initialLastPoint.block + blockSlope * (timeIndex - initialLastPoint.ts) / 1e18;
            _vars.epoch += 1;
            if (timeIndex == _vars.ts) {
                lastPoint.block = _vars.block;
                break;
            } else {
                pointHistory[_vars.epoch] = lastPoint;
            }
        }
        epoch = _vars.epoch;


        if (addr != address(0)) {
            lastPoint.slope += (_userPointNew.slope - _userPointOld.slope);
            lastPoint.bias += (_userPointNew.bias - _userPointOld.bias);
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
        }
        pointHistory[_vars.epoch] = lastPoint;

         if (addr != address(0)) {
            if (oldLock.end > _vars.ts) {
                _vars.oldDslope += _userPointOld.slope;
                if (newLock.end == oldLock.end) {
                    _vars.oldDslope -= _userPointNew.slope;
                }
                slopeChanges[oldLock.end] = _vars.oldDslope;
            }
            if (newLock.end > _vars.ts) {
                if (newLock.end > oldLock.end) {
                    _vars.newDslope -= _userPointNew.slope;
                    slopeChanges[newLock.end] = _vars.newDslope;
                }
            }

            userPointEpoch[addr]++;
            _userPointNew.ts = _vars.ts;
            _userPointNew.block = _vars.block;
            userPointHistory[addr][_vars.userEpoch + 1] = _userPointNew;
        }
    }

    function getBlockNumber() public virtual view returns (uint256) {
        return block.number;
    }

    function getBlockTimestamp() public virtual view returns (uint256) {
        return block.timestamp;
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
