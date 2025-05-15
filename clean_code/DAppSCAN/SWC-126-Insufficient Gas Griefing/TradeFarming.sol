
pragma solidity ^0.8.2;

import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/ITradeFarming.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";




contract TradeFarming is ITradeFarming, Ownable {



    IUniswapV2Router01 routerContract;

    IERC20 tokenContract;

    IERC20 rewardToken;


    using EnumerableSet for EnumerableSet.UintSet;

    using SafeERC20 for IERC20;






    mapping(uint256 => uint256) public previousVolumes;


    mapping(address => mapping(uint256 => uint256)) public volumeRecords;


    mapping(uint256 => uint256) public dailyVolumes;

    mapping(uint256 => uint256) public dailyRewards;


    mapping(address => EnumerableSet.UintSet) private tradedDays;




    uint256 public totalRewardBalance = 0;

    uint256 public totalDays;

    uint256 public immutable deployTime;


    uint256 private previousDay;

    uint256 public lastAddedDay;

    address private WETH;


    uint256 constant PRECISION = 1e18;

    uint256 immutable UP_VOLUME_CHANGE_LIMIT;
    uint256 immutable DOWN_VOLUME_CHANGE_LIMIT;




    event RewardClaimed(address _user, uint256 _amount);
















    constructor(
        address _routerAddress,
        address _tokenAddress,
        address _rewardAddress,
        uint256 _previousVolume,
        uint256 _previousDay,
        uint256 _totalDays,
        uint256 _upLimit,
        uint256 _downLimit
    ) {
        require(
            _routerAddress != address(0) && _tokenAddress != address(0) && _rewardAddress != address(0),
            "[] Addresses can not be 0 address."
        );

        deployTime = block.timestamp;
        routerContract = IUniswapV2Router01(_routerAddress);
        tokenContract = IERC20(_tokenAddress);
        rewardToken = IERC20(_rewardAddress);
        previousVolumes[0] = _previousVolume;
        previousDay = _previousDay;
        totalDays = _totalDays;
        WETH = routerContract.WETH();
        UP_VOLUME_CHANGE_LIMIT = (PRECISION * _upLimit) / 100;
        DOWN_VOLUME_CHANGE_LIMIT = (PRECISION * _downLimit) / 100;
    }








    function depositRewardTokens(uint256 amount) external onlyOwner {
        totalRewardBalance += amount;
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
    }





    function withdrawRewardTokens(uint256 amount) external onlyOwner {
        require(
            totalRewardBalance >= amount,
            "[withdrawRewardTokens] Not enough balance!"
        );
        totalRewardBalance -= amount;
        rewardToken.safeTransfer(msg.sender, amount);
    }





    function changeTotalDays(uint256 newTotalDays) external onlyOwner {
        totalDays = newTotalDays;
    }







    function claimAllRewards() external virtual override {

        if (lastAddedDay + 1 <= calcDay() && lastAddedDay != totalDays) {
            addNextDaysToAverage();
        }

        uint256 totalRewardOfUser = 0;
        uint256 rewardRate = PRECISION;

        uint256 len = tradedDays[msg.sender].length();
        if(tradedDays[msg.sender].contains(lastAddedDay)) len -= 1;

        uint256[] memory _removeDays = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            if (tradedDays[msg.sender].at(i) < lastAddedDay) {

                rewardRate = muldiv(
                    volumeRecords[msg.sender][tradedDays[msg.sender].at(i)],
                    PRECISION,
                    dailyVolumes[tradedDays[msg.sender].at(i)]
                );

                totalRewardOfUser += muldiv(
                    rewardRate,
                    dailyRewards[tradedDays[msg.sender].at(i)],
                    PRECISION
                );
                _removeDays[i] = tradedDays[msg.sender].at(i);
            }
        }


        for (uint256 i = 0; i < len; i++) {
            require(tradedDays[msg.sender].remove(_removeDays[i]), "[claimAllRewards] Unsuccessful set operation");
        }

        require(totalRewardOfUser > 0, "[claimAllRewards] No reward!");
        rewardToken.safeTransfer(msg.sender, totalRewardOfUser);


        emit RewardClaimed(msg.sender, totalRewardOfUser);
    }






    function isCalculated() external view returns (bool) {
        return (!(lastAddedDay + 1 <= calcDay() && lastAddedDay != totalDays) ||
            lastAddedDay == totalDays);
    }






    function calculateUserRewards() external view returns (uint256) {
        uint256 totalRewardOfUser = 0;
        uint256 rewardRate = PRECISION;
        for (uint256 i = 0; i < tradedDays[msg.sender].length(); i++) {
            if (tradedDays[msg.sender].at(i) < lastAddedDay) {
                rewardRate = muldiv(
                    volumeRecords[msg.sender][tradedDays[msg.sender].at(i)],
                    PRECISION,
                    dailyVolumes[tradedDays[msg.sender].at(i)]
                );
                totalRewardOfUser += muldiv(
                    rewardRate,
                    dailyRewards[tradedDays[msg.sender].at(i)],
                    PRECISION
                );
            }
        }
        return totalRewardOfUser;
    }







    function calculateDailyUserReward(uint256 day)
        external
        view
        returns (uint256)
    {
        uint256 rewardOfUser = 0;
        uint256 rewardRate = PRECISION;

        if (tradedDays[msg.sender].contains(day)) {
            rewardRate = muldiv(
                volumeRecords[msg.sender][day],
                PRECISION,
                dailyVolumes[day]
            );
            uint256 dailyReward;
            if (day < lastAddedDay) {
                dailyReward = dailyRewards[day];
            } else if (day == lastAddedDay) {
                uint256 volumeChange = calculateDayVolumeChange(lastAddedDay);
                if (volumeChange > UP_VOLUME_CHANGE_LIMIT) {
                    volumeChange = UP_VOLUME_CHANGE_LIMIT;
                } else if (volumeChange == 0) {
                    volumeChange = 0;
                } else if (volumeChange < DOWN_VOLUME_CHANGE_LIMIT) {
                    volumeChange = DOWN_VOLUME_CHANGE_LIMIT;
                }
                dailyReward = muldiv(
                    totalRewardBalance / (totalDays - lastAddedDay),
                    volumeChange,
                    PRECISION
                );
            }
            rewardOfUser += muldiv(rewardRate, dailyReward, PRECISION);
        }

        return rewardOfUser;
    }







    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts)
    {
        return routerContract.getAmountsOut(amountIn, path);
    }





    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts)
    {
        return routerContract.getAmountsIn(amountOut, path);
    }









    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override returns (uint256[] memory out) {

        require(path[0] == WETH, "[swapExactETHForTokens] Invalid path!");
        require(
            path[path.length - 1] == address(tokenContract),
            "[swapExactETHForTokens] Invalid path!"
        );

        require(msg.value > 0, "[swapExactETHForTokens] Not a msg.value!");


        if (
            !tradedDays[msg.sender].contains(calcDay()) && calcDay() < totalDays
        ) require(tradedDays[msg.sender].add(calcDay()), "[swapExactETHForTokens] Unsuccessful set operation");


        out = routerContract.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            to,
            deadline
        );

        if (lastAddedDay != totalDays) tradeRecorder(out[out.length - 1]);
    }










    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override returns (uint256[] memory) {

        require(path[0] == WETH, "[swapExactETHForTokens] Invalid path!");
        require(
            path[path.length - 1] == address(tokenContract),
            "[swapExactETHForTokens] Invalid path!"
        );


        uint256 volume = routerContract.getAmountsIn(amountOut, path)[0];
        require(
            msg.value >= volume,
            "[swapETHForExactTokens] Not enough msg.value!"
        );


        if (
            !tradedDays[msg.sender].contains(calcDay()) && calcDay() < totalDays
        ) require(tradedDays[msg.sender].add(calcDay()), "[swapETHForExactTokens] Unsuccessful set operation");


        if (lastAddedDay != totalDays) tradeRecorder(amountOut);

        if (msg.value > volume)
            payable(msg.sender).transfer(msg.value - volume);

        return
            routerContract.swapETHForExactTokens{value: volume}(
                amountOut,
                path,
                to,
                deadline
            );
    }







    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override returns (uint256[] memory) {

        require(
            path[path.length - 1] == WETH,
            "[swapExactETHForTokens] Invalid path!"
        );
        require(
            path[0] == address(tokenContract),
            "[swapExactETHForTokens] Invalid path!"
        );


        if (
            !tradedDays[msg.sender].contains(calcDay()) && calcDay() < totalDays
        ) require(tradedDays[msg.sender].add(calcDay()), "[swapExactTokensForETH] Unsuccessful set operation");
        tokenContract.safeTransferFrom(msg.sender, address(this), amountIn);


        tokenContract.safeIncreaseAllowance(address(routerContract), amountIn);


        if (lastAddedDay != totalDays) tradeRecorder(amountIn);

        return
            routerContract.swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
    }








    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override returns (uint256[] memory out) {

        require(
            path[path.length - 1] == WETH,
            "[swapExactETHForTokens] Invalid path!"
        );
        require(
            path[0] == address(tokenContract),
            "[swapExactETHForTokens] Invalid path!"
        );


        if (
            !tradedDays[msg.sender].contains(calcDay()) && calcDay() < totalDays
        ) require(tradedDays[msg.sender].add(calcDay()), "[swapTokensForExactETH] Unsuccessful set operation");
        tokenContract.safeTransferFrom(
            msg.sender,
            address(this),
            routerContract.getAmountsIn(amountOut, path)[0]
        );


        tokenContract.safeIncreaseAllowance(
            address(routerContract),
            amountInMax
        );


        out = routerContract.swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );

        if (lastAddedDay != totalDays) tradeRecorder(out[0]);


        tokenContract.safeApprove(address(routerContract), 0);
    }







    function calcDay() public view returns (uint256) {
        return (block.timestamp - deployTime) / 1 days;
    }








    function tradeRecorder(uint256 volume) private {

        if (calcDay() < totalDays) {
            volumeRecords[msg.sender][calcDay()] += volume;
            dailyVolumes[calcDay()] += volume;
        }


        if (lastAddedDay + 1 <= calcDay() && lastAddedDay != totalDays) {
            addNextDaysToAverage();
        }
    }







    function calculateDayVolumeChange(uint256 day)
        private
        view
        returns (uint256)
    {
        return muldiv(dailyVolumes[day], PRECISION, previousVolumes[day]);
    }




    function addNextDaysToAverage() private {
        uint256 _cd = calcDay();

        uint256 _pd = previousDay + lastAddedDay + 1;
        assert(lastAddedDay + 1 <= _cd);

        previousVolumes[lastAddedDay + 1] =
            muldiv(previousVolumes[lastAddedDay], (_pd - 1), _pd) +
            dailyVolumes[lastAddedDay] /
            _pd;

        uint256 volumeChange = calculateDayVolumeChange(lastAddedDay);

        if (volumeChange > UP_VOLUME_CHANGE_LIMIT) {
            volumeChange = UP_VOLUME_CHANGE_LIMIT;
        } else if (volumeChange == 0) {
            volumeChange = 0;
        } else if (volumeChange < DOWN_VOLUME_CHANGE_LIMIT) {
            volumeChange = DOWN_VOLUME_CHANGE_LIMIT;
        }


        if (lastAddedDay == totalDays - 1 && volumeChange > PRECISION) {
            dailyRewards[lastAddedDay] = totalRewardBalance;
        } else {
            dailyRewards[lastAddedDay] = muldiv(
                (totalRewardBalance / (totalDays - lastAddedDay)),
                volumeChange,
                PRECISION
            );
        }
        totalRewardBalance = totalRewardBalance - dailyRewards[lastAddedDay];


        lastAddedDay += 1;


        if (lastAddedDay + 1 <= _cd && lastAddedDay != totalDays)
            addNextDaysToAverage();
    }








    function muldiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) private pure returns (uint256 result) {
        require(denominator > 0);

        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }
        require(prod1 < denominator);
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        uint256 twos = denominator & (~denominator + 1);
        assembly {
            denominator := div(denominator, twos)
        }

        assembly {
            prod0 := div(prod0, twos)
        }

        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        uint256 inv = (3 * denominator) ^ 2;

        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;
        inv *= 2 - denominator * inv;

        result = prod0 * inv;
        return result;
    }
}
