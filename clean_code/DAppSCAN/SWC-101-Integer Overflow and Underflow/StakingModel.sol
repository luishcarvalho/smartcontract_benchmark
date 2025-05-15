
pragma solidity ^0.8.0;

import "../interfaces/IStakingModel.sol";











contract StakingModel is IStakingModel {

    struct User {
        uint104 balance;
        uint104 energy;
        uint48 lastUpdatedTime;
    }

    mapping(address => User) private users;

    modifier restrict(uint256 amount) {
        require(amount <= type(uint104).max, "value should <= type(uint104).max");
        _;
    }

    function addVET(address addr, uint256 amount) restrict(amount) internal {
        _update(addr);
        users[addr].balance += uint104(amount);
    }


    function removeVET(address addr, uint256 amount) restrict(amount) internal {
        _update(addr);
        require(users[addr].balance >= uint104(amount), "insuffcient vet");
        users[addr].balance -= uint104(amount);
    }

    function vetBalance(address addr) public override view returns (uint256 amount) {
        return users[addr].balance;
    }

    function addVTHO(address addr, uint256 amount) restrict(amount) internal {
        _update(addr);
        users[addr].energy += uint104(amount);
    }

    function removeVTHO(address addr, uint256 amount) restrict(amount) internal {
        _update(addr);
        require(users[addr].energy >= uint104(amount), "insuffcient vtho");
        users[addr].energy -= uint104(amount);
    }

    function vthoBalance(address addr) public override view returns (uint256 amount) {
        User memory user = users[addr];
        if (user.lastUpdatedTime == 0) {
            return 0;
        }
        return user.energy + calculateVTHO(user.lastUpdatedTime, uint48(block.timestamp), user.balance);
    }


    function _update(address addr) internal {
        uint48 currentTime = uint48(block.timestamp);
        if (users[addr].lastUpdatedTime > 0) {
            assert(users[addr].lastUpdatedTime <= currentTime);
            users[addr].energy += calculateVTHO(
                users[addr].lastUpdatedTime,
                currentTime,
                users[addr].balance
            );
        }

        users[addr].lastUpdatedTime = currentTime;
    }







    function calculateVTHO(
        uint48 t1,
        uint48 t2,
        uint104 vetAmount
    ) public pure returns (uint104 vtho) {
        require(t1 <= t2, "t1 should be <= t2");

        return ((vetAmount * 5) / (10**9)) * (t2 - t1);
    }
}
