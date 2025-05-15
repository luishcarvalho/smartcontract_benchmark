


pragma solidity ^0.8.0;

import "solmate/auth/Auth.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeCastLib.sol";
import "../../lib/EnumerableSet.sol";
import "../interfaces/Errors.sol";





abstract contract ERC20MultiVotes is ERC20, Auth {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeCastLib for *;































    function freeVotes(address account) public view virtual returns (uint256) {
        return balanceOf[account] - userDelegatedVotes[account];
    }






    function getVotes(address account) public view virtual returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }







    function getPastVotes(address account, uint256 blockNumber) public view virtual returns (uint256) {
        if (blockNumber >= block.number) revert BlockError();
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }


    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {

        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a & b) + (a ^ b) / 2;
    }

































































    function delegatesVotesCount(address delegator, address delegatee) public view virtual returns (uint256) {
        return _delegatesVotesCount[delegator][delegatee];
    }






    function delegates(address delegator) public view returns (address[] memory) {
        return _delegates[delegator].values();
    }






    function delegateCount(address delegator) public view returns (uint256) {
        return _delegates[delegator].length();
    }







    function delegate(address delegatee, uint256 amount) public virtual {
        _delegate(msg.sender, delegatee, amount);
    }






    function undelegate(address delegatee, uint256 amount) public virtual {
        _undelegate(msg.sender, delegatee, amount);
    }






    function delegate(address newDelegatee) external virtual {
        _delegate(msg.sender, newDelegatee);
    }

    function _delegate(address delegator, address newDelegatee) internal virtual {
        uint256 count = delegateCount(delegator);


        if (count > 1) revert DelegationError();


        if (count == 1) {
            address oldDelegatee = _delegates[delegator].at(0);
            _undelegate(delegator, oldDelegatee, _delegatesVotesCount[delegator][oldDelegatee]);
        }


        if (newDelegatee != address(0)) {
            _delegate(delegator, newDelegatee, freeVotes(delegator));
        }
    }

    function _delegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal virtual {

        uint256 free = freeVotes(delegator);
        if (delegatee == address(0) || free < amount) revert DelegationError();

        bool newDelegate = _delegates[delegator].add(delegatee);
        if (newDelegate && delegateCount(delegator) > maxDelegates && !canContractExceedMaxDelegates[delegator]) {

            revert DelegationError();
        }

        _delegatesVotesCount[delegator][delegatee] += amount;
        userDelegatedVotes[delegator] += amount;

        emit Delegation(delegator, delegatee, amount);
        _writeCheckpoint(delegatee, _add, amount);
    }


    function _undelegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal virtual {
        uint256 newDelegates = _delegatesVotesCount[delegator][delegatee] - amount;

        if (newDelegates == 0) {
            assert(_delegates[delegator].remove(delegatee));
        }

        _delegatesVotesCount[delegator][delegatee] = newDelegates;
        userDelegatedVotes[delegator] -= amount;

        emit Undelegation(delegator, delegatee, amount);
        _writeCheckpoint(delegatee, _subtract, amount);
    }

    function _writeCheckpoint(
        address delegatee,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private {
        Checkpoint[] storage ckpts = _checkpoints[delegatee];

        uint256 pos = ckpts.length;
        uint256 oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        uint256 newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = newWeight.safeCastTo224();
        } else {
            ckpts.push(Checkpoint({fromBlock: block.number.safeCastTo32(), votes: newWeight.safeCastTo224()}));
        }
        emit DelegateVotesChanged(delegatee, oldWeight, newWeight);
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }






























































































