

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";










contract Vesting is Ownable {
    using SafeMath for uint8;
    using SafeMath for uint32;
    using SafeMath for uint256;


    address public token;
    address public operator;
    address public oracle;
    uint8 public lastScore;
    uint256 public initializedAt;
    uint256 public updatedAt;
    uint256 public totalVestingAmount;
    bool public initialized;
    bool public finalized;


    uint32 public constant EPOCH_SIZE = 60 days;

    uint256 private MAX_LOCK_AMOUNT = uint256(2**256 - 1).div(99);

    struct LockVesting {
        uint256 totalAmount;
        uint256 releasedAmount;
    }

    mapping(address => LockVesting) public locks;
    address[] beneficiaries;

    event ScoreUpdated(uint8 score, uint256 indexed epochNumber);

    modifier onlyOperator() {
        require(msg.sender == operator, "caller is not the operator");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "caller is not the oracle");
        _;
    }

    modifier notInitialized() {
        require(!initialized, "vesting has already been initialized");
        _;
    }

    modifier isInitialized() {
        require(initialized, "vesting has not been initialized");
        _;
    }

    modifier notFinalized() {
        require(!finalized, "vesting is finalized");
        _;
    }

    constructor(
        address _token,
        address _operator,
        address _oracle
    ) {
        require(_token != address(0), "token address is required");
        require(_operator != address(0), "operator address is required");
        require(_oracle != address(0), "oracle address is required");
        token = _token;
        operator = _operator;
        oracle = _oracle;
    }




    function initialize() external onlyOperator notInitialized {
        require(totalVestingAmount != 0, "locks were not created");
        require(
            totalVestingAmount == IERC20(token).balanceOf(address(this)),
            "vesting amount and token balance are different"
        );
        initialized = true;
        initializedAt = _currentTime();
    }





    function grantVesting(address _beneficiary, uint256 _amount)
        external
        onlyOperator
        notInitialized
    {
        require(
            _amount <= MAX_LOCK_AMOUNT,
            "amount exceeds the maximum allowed value"
        );
        require(_amount != 0, "amount is required");
        require(_beneficiary != address(0), "beneficiary address is required");
        require(
            locks[_beneficiary].totalAmount == 0,
            "beneficiary already has a vesting"
        );

        locks[_beneficiary].totalAmount = _amount;
        beneficiaries.push(_beneficiary);
        totalVestingAmount = totalVestingAmount + _amount;
    }

    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "operator address is required");
        operator = _operator;
    }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "oracle address is required");
        oracle = _oracle;
    }





    function updateScore(uint8 _newScore)
        external
        onlyOracle
        isInitialized
        notFinalized
    {
        require(_newScore <= 100, "invalid score value");
        require(
            _currentTime().sub(initializedAt) > EPOCH_SIZE,
            "scoring epoch 1 still not finished"
        );

        uint256 timeFromLastEpoch = _currentTime().sub(initializedAt).mod(
            EPOCH_SIZE
        );

        require(
            timeFromLastEpoch > 0 && timeFromLastEpoch <= 1 days,
            "scoring epoch still not finished"
        );

        require(
            _currentTime().sub(updatedAt) > 1 days,
            "can not update score value twise in the same window"
        );

        lastScore = _newScore;
        updatedAt = _currentTime();

        if (_newScore != 0) {
            for (uint256 i = 0; i < beneficiaries.length; i++) {


                LockVesting memory lock = locks[beneficiaries[i]];

                uint256 remainingAmount = lock.totalAmount.sub(
                    lock.releasedAmount
                );

                uint256 releasableAmount = _newScore.mul(remainingAmount).div(
                    100
                );

                locks[beneficiaries[i]].releasedAmount = lock
                    .releasedAmount
                    .add(releasableAmount);

                require(
                    IERC20(token).transfer(beneficiaries[i], releasableAmount),
                    "token transfer fail"
                );
            }

            if (
                locks[beneficiaries[0]].releasedAmount ==
                locks[beneficiaries[0]].totalAmount
            )
                finalized = true;
        }

        emit ScoreUpdated(_newScore, _epochNumber());
    }

    function epochNumber() external view returns (uint256) {
        return _epochNumber().add(1);
    }

    function _epochNumber() internal view returns (uint256) {
        return _currentTime().sub(initializedAt).div(EPOCH_SIZE);
    }

    function _currentTime() internal view returns (uint256) {
        return block.timestamp;
    }
}
