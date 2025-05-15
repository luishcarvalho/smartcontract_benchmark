
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ITokenVesting.sol";




contract TokenVesting is ITokenVesting, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    IERC20 public immutable token;

    bytes32[] private vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) public vestingSchedules;
    uint256 public vestingSchedulesTotalAmount;
    mapping(address => uint256) public holdersVestingCount;




    modifier onlyIfVestingScheduleExists(bytes32 vestingScheduleId) {
        require(
            vestingSchedules[vestingScheduleId].initialized,
            "invalid-vesting-schedule"
        );
        _;
    }




    modifier onlyIfVestingScheduleNotRevoked(bytes32 vestingScheduleId) {
        require(
            vestingSchedules[vestingScheduleId].initialized,
            "vesting-schedule-not-initialized"
        );
        require(
            !vestingSchedules[vestingScheduleId].revoked,
            "vesting-schedule-revoked"
        );
        _;
    }





    constructor(address token_) {
        require(token_ != address(0x0), "invalid-token-address");
        token = IERC20(token_);
    }

    receive() external payable {}

    fallback() external payable {}












    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount,
        uint256 _upFront
    ) public onlyOwner {
        require(this.getWithdrawableAmount() >= _amount, "insufficient-tokens");
        require(_duration > 0, "invalid-duration");
        require(_amount > 0, "invalid-amount");
        require(_slicePeriodSeconds >= 1, "invalid-slice-period");
        bytes32 vestingScheduleId = this.computeNextVestingScheduleIdForHolder(
            _beneficiary
        );
        uint256 cliff = _start.add(_cliff);
        vestingSchedules[vestingScheduleId] = VestingSchedule(
            true,
            _beneficiary,
            cliff,
            _start,
            _duration,
            _slicePeriodSeconds,
            _revocable,
            _amount,
            0,
            false,
            _upFront
        );
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.add(_amount);
        vestingSchedulesIds.push(vestingScheduleId);
        uint256 currentVestingCount = holdersVestingCount[_beneficiary];
        holdersVestingCount[_beneficiary] = currentVestingCount.add(1);

        if (_upFront > 0) {
            token.safeTransfer(_beneficiary, _upFront);
            emit UpfrontTokenTransfer(
                vestingScheduleId,
                _beneficiary,
                _upFront
            );
        }

        emit AddVestingSchedule(
            vestingScheduleId,
            _beneficiary,
            cliff,
            _start,
            _duration,
            _slicePeriodSeconds,
            _revocable,
            _amount,
            0,
            false,
            _upFront
        );
    }





    function revoke(bytes32 vestingScheduleId)
        public
        onlyOwner
        onlyIfVestingScheduleNotRevoked(vestingScheduleId)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[
            vestingScheduleId
        ];
        require(vestingSchedule.revocable == true, "not-revocable");
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        if (vestedAmount > 0) {
            release(vestingScheduleId, vestedAmount);
        }
        uint256 unreleased = vestingSchedule.amountTotal.sub(
            vestingSchedule.released
        );
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(
            unreleased
        );
        vestingSchedule.revoked = true;

        emit RevokeVestingShedule(vestingScheduleId);
    }





    function withdraw(uint256 amount) public nonReentrant onlyOwner {
        require(
            this.getWithdrawableAmount() >= amount,
            "insufficient-withdrawable-funds"
        );
        token.safeTransfer(owner(), amount);
    }





    function releaseAllVested(bytes32 vestingScheduleId)
        public
        nonReentrant
        onlyIfVestingScheduleNotRevoked(vestingScheduleId)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[
            vestingScheduleId
        ];
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        release(vestingScheduleId, vestedAmount);
    }






    function release(bytes32 vestingScheduleId, uint256 amount)
        public
        nonReentrant
        onlyIfVestingScheduleNotRevoked(vestingScheduleId)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[
            vestingScheduleId
        ];
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        require(isBeneficiary || isOwner, "not-authorised");
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount >= amount, "insufficient-vested-token");
        vestingSchedule.released = vestingSchedule.released.add(amount);
        address payable beneficiaryPayable = payable(
            vestingSchedule.beneficiary
        );
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(amount);
        token.safeTransfer(beneficiaryPayable, amount);
        emit ReleaseVestedToken(
            vestingScheduleId,
            beneficiaryPayable,
            vestedAmount
        );
    }





    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingSchedulesIds.length;
    }





    function computeReleasableAmount(bytes32 vestingScheduleId)
        public
        view
        onlyIfVestingScheduleNotRevoked(vestingScheduleId)
        returns (uint256)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[
            vestingScheduleId
        ];
        return _computeReleasableAmount(vestingSchedule);
    }





    function getVestingSchedule(bytes32 vestingScheduleId)
        public
        view
        returns (VestingSchedule memory)
    {
        return vestingSchedules[vestingScheduleId];
    }





    function getWithdrawableAmount() public view returns (uint256) {
        return token.balanceOf(address(this)).sub(vestingSchedulesTotalAmount);
    }




    function computeNextVestingScheduleIdForHolder(address holder)
        public
        view
        returns (bytes32)
    {
        return
            _computeVestingScheduleIdForAddressAndIndex(
                holder,
                holdersVestingCount[holder]
            );
    }





    function getAllVestingScheduleForHolder(address holder)
        public
        view
        returns (VestingSchedule[] memory)
    {
        uint256 holderTotalCounts = holdersVestingCount[holder];
        VestingSchedule[] memory holderVestingSchedules = new VestingSchedule[](
            holderTotalCounts
        );

        for (uint256 i = 0; i < holderTotalCounts; i++) {
            holderVestingSchedules[i] = getVestingSchedule(
                _computeVestingScheduleIdForAddressAndIndex(holder, i)
            );
        }
        return holderVestingSchedules;
    }




    function _computeVestingScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }





    function _computeReleasableAmount(VestingSchedule memory vestingSchedule)
        internal
        view
        returns (uint256)
    {
        uint256 currentTime = _blockTimestamp();
        if (
            (currentTime < vestingSchedule.cliff) ||
            vestingSchedule.revoked == true
        ) {
            return 0;
        } else if (
            currentTime >= vestingSchedule.start.add(vestingSchedule.duration)
        ) {
            return vestingSchedule.amountTotal.sub(vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime.sub(vestingSchedule.start);
            uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 vestedSeconds = vestedSlicePeriods.mul(secondsPerSlice);
            uint256 vestedAmount = vestingSchedule
                .amountTotal
                .mul(vestedSeconds)
                .div(vestingSchedule.duration);
            vestedAmount = vestedAmount.sub(vestingSchedule.released);
            return vestedAmount;
        }
    }

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}
