





pragma solidity 0.6.12;

contract SusafeReferral {
    mapping(address => address) public referrers;
    mapping(address => uint256) public referredCount;

    event Referral(address indexed referrer, address indexed farmer);

    address public governance;

    mapping(address => bool) public isAdmin;

    constructor () public {
        governance = tx.origin;
    }

    function setGovernance(address _governance) public {
        require(tx.origin == governance, "!governance");

        governance = _governance;
    }

    modifier onlyAdmin {
        require(isAdmin[msg.sender], "OnlyAdmin methods called by non-admin.");
        _;
    }

    function setReferrer(address farmer, address referrer) public onlyAdmin {
        if (referrers[farmer] == address(0) && referrer != address(0)) {
            referrers[farmer] = referrer;
            referredCount[referrer] += 1;
            emit Referral(referrer, farmer);
        }
    }

    function getReferrer(address farmer) public view returns (address) {
        return referrers[farmer];
    }


    function setAdminStatus(address _admin, bool _status) external {
        require(tx.origin == governance, "!governance");

        isAdmin[_admin] = _status;
    }


    function emergencyERC20Drain(IERC20 token, uint amount) external {
        require(tx.origin == governance, "!governance");

        token.transfer(governance, amount);
    }
}

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
}
