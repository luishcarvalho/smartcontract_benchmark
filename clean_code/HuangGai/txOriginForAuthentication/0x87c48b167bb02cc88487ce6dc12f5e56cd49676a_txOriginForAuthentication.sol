



pragma solidity ^0.5.16;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {

        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

interface Gov {
    function setGovernance(address) external;
}

contract TimelockGovernance {
    using SafeMath for uint;

    uint public period = 17280;
    address public governance;
    address public newGovernance;
    uint public newGovernanceUpdatable;
    address public target;
    address public newTargetGovernance;
    uint public newTargetGovernanceUpdatable;

    constructor(address _target) public {
        governance = msg.sender;
        target = _target;
    }

    function setThisGovernance(address _governance) external {
        require(governance == tx.origin);

        newGovernanceUpdatable = period.add(block.number);
        newGovernance = _governance;
    }

    function updateThisGovernance() external {
        require(newGovernanceUpdatable > block.number, "<block.number");
        governance = newGovernance;
    }

    function setTargetGovernance(address _governance) external {
        require(governance == tx.origin);

        newTargetGovernanceUpdatable = period.add(block.number);
        newTargetGovernance = _governance;
    }

    function updateTargetGovernance() external {
        require(newTargetGovernanceUpdatable > block.number, "<block.number");
        Gov(target).setGovernance(newTargetGovernance);
    }
}
