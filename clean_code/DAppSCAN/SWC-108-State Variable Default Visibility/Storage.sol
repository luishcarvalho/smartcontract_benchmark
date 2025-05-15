

pragma solidity "0.8.13";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface LogicContract {
    function returnToken(uint256 amount, address token) external;
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256 answer);
}

contract StorageV2 is Initializable, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;


    struct DepositStruct {
        mapping(address => uint256) amount;
        mapping(address => int256) tokenTime;
        uint256 iterate;
        uint256 balanceBLID;
        mapping(address => uint256) depositIterate;
    }

    struct EarnBLID {
        uint256 allBLID;
        uint256 timestamp;
        uint256 usd;
        uint256 tdt;
        mapping(address => uint256) rates;
    }
























































    function deposit(uint256 amount, address token) external isUsedToken(token) whenNotPaused {
        require(amount > 0, "E3");
        uint8 decimals = AggregatorV3Interface(token).decimals();
        DepositStruct storage depositor = deposits[msg.sender];
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 amountExp18 = amount * 10**(18 - decimals);
        if (depositor.tokenTime[address(0)] == 0) {
            depositor.iterate = countEarns;
            depositor.depositIterate[token] = countEarns;
            depositor.tokenTime[address(0)] = 1;
            depositor.tokenTime[token] += int256(block.timestamp * (amountExp18));
        } else {
            interestFee();
            if (depositor.depositIterate[token] == countEarns) {
                depositor.tokenTime[token] += int256(block.timestamp * (amountExp18));
            } else {
                depositor.tokenTime[token] = int256(
                    depositor.amount[token] *
                        earnBLID[countEarns - 1].timestamp +
                        block.timestamp *
                        (amountExp18)
                );

                depositor.depositIterate[token] = countEarns;
            }
        }
        depositor.amount[token] += amountExp18;

        tokenTime[token] += int256(block.timestamp * (amountExp18));
        tokenBalance[token] += amountExp18;
        tokenDeposited[token] += amountExp18;

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit Deposit(msg.sender, token, amountExp18);
    }






    function withdraw(uint256 amount, address token) external isUsedToken(token) whenNotPaused {
        uint8 decimals = AggregatorV3Interface(token).decimals();
        uint256 countEarns_ = countEarns;
        uint256 amountExp18 = amount * 10**(18 - decimals);
        DepositStruct storage depositor = deposits[msg.sender];
        require(depositor.amount[token] >= amountExp18 && amount > 0, "E4");
        if (amountExp18 > tokenBalance[token]) {
            LogicContract(logicContract).returnToken(amount, token);
            interestFee();
            IERC20Upgradeable(token).safeTransferFrom(logicContract, msg.sender, amount);
            tokenDeposited[token] -= amountExp18;
            tokenTime[token] -= int256(block.timestamp * (amountExp18));
        } else {
            interestFee();
            IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
            tokenTime[token] -= int256(block.timestamp * (amountExp18));

            tokenBalance[token] -= amountExp18;
            tokenDeposited[token] -= amountExp18;
        }
        if (depositor.depositIterate[token] == countEarns_) {
            depositor.tokenTime[token] -= int256(block.timestamp * (amountExp18));
        } else {
            depositor.tokenTime[token] =
                int256(depositor.amount[token] * earnBLID[countEarns_ - 1].timestamp) -
                int256(block.timestamp * (amountExp18));
            depositor.depositIterate[token] = countEarns_;
        }
        depositor.amount[token] -= amountExp18;

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit Withdraw(msg.sender, token, amountExp18);
    }




    function interestFee() public {
        uint256 balanceUser = balanceEarnBLID(msg.sender);
        require(reserveBLID >= balanceUser, "E5");
        IERC20Upgradeable(BLID).safeTransfer(msg.sender, balanceUser);
        DepositStruct storage depositor = deposits[msg.sender];
        depositor.balanceBLID = balanceUser;
        depositor.iterate = countEarns;

        unchecked {
            depositor.balanceBLID = 0;
            reserveBLID -= balanceUser;
        }

        emit UpdateBLIDBalance(reserveBLID);
        emit InterestFee(msg.sender, balanceUser);
    }







    function setBLID(address _blid) external onlyOwner {
        BLID = _blid;

        emit SetBLID(_blid);
    }




    function pause() external onlyOwner {
        _pause();
    }




    function unpause() external onlyOwner {
        _unpause();
    }





    function updateAccumulatedRewardsPerShare(address token) external onlyOwner {
        require(accumulatedRewardsPerShare[token][0] == 0, "E7");
        uint256 countEarns_ = countEarns;
        for (uint256 i = 0; i < countEarns_; i++) {
            updateAccumulatedRewardsPerShareById(token, i);
        }
    }






    function addToken(address _token, address _oracles) external onlyOwner {
        require(_token != address(0) && _oracles != address(0));
        require(!tokensAdd[_token], "E6");
        oracles[_token] = _oracles;
        tokens[countTokens++] = _token;
        tokensAdd[_token] = true;
        emit AddToken(_token, _oracles);
    }





    function setLogic(address _logic) external onlyOwner {
        logicContract = _logic;
        emit SetLogic(_logic);
    }








    function takeToken(uint256 amount, address token)
        external
        isLogicContract(msg.sender)
        isUsedToken(token)
    {
        uint8 decimals = AggregatorV3Interface(token).decimals();
        uint256 amountExp18 = amount * 10**(18 - decimals);
        IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
        tokenBalance[token] = tokenBalance[token] - amountExp18;

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit TakeToken(token, amountExp18);
    }






    function returnToken(uint256 amount, address token)
        external
        isLogicContract(msg.sender)
        isUsedToken(token)
    {
        uint8 decimals = AggregatorV3Interface(token).decimals();
        uint256 amountExp18 = amount * 10**(18 - decimals);
        IERC20Upgradeable(token).safeTransferFrom(logicContract, address(this), amount);
        tokenBalance[token] = tokenBalance[token] + amountExp18;

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit ReturnToken(token, amountExp18);
    }





    function addEarn(uint256 amount) external isLogicContract(msg.sender) {
        IERC20Upgradeable(BLID).safeTransferFrom(msg.sender, address(this), amount);
        reserveBLID += amount;
        int256 _dollarTime = 0;
        uint256 countTokens_ = countTokens;
        uint256 countEarns_ = countEarns;
        EarnBLID storage thisEarnBLID = earnBLID[countEarns_];
        for (uint256 i = 0; i < countTokens_; i++) {
            address token = tokens[i];
            AggregatorV3Interface oracle = AggregatorV3Interface(oracles[token]);
            thisEarnBLID.rates[token] = (uint256(oracle.latestAnswer()) * 10**(18 - oracle.decimals()));


            thisEarnBLID.usd += tokenDeposited[token] * thisEarnBLID.rates[token];


            _dollarTime += tokenTime[token] * int256(thisEarnBLID.rates[token]);
        }
        require(_dollarTime != 0);
        thisEarnBLID.allBLID = amount;
        thisEarnBLID.timestamp = block.timestamp;
        thisEarnBLID.tdt = uint256(
            (int256(((block.timestamp) * thisEarnBLID.usd)) - _dollarTime) / (1 ether)
        );

        for (uint256 i = 0; i < countTokens_; i++) {
            address token = tokens[i];
            tokenTime[token] = int256(tokenDeposited[token] * block.timestamp);
            updateAccumulatedRewardsPerShareById(token, countEarns_);
        }
        thisEarnBLID.usd /= (1 ether);
        countEarns++;

        emit AddEarn(amount);
        emit UpdateBLIDBalance(reserveBLID);
    }







    function _upBalance(address account) external {
        deposits[account].balanceBLID = balanceEarnBLID(account);
        deposits[account].iterate = countEarns;
    }







    function balanceEarnBLID(address account) public view returns (uint256) {
        DepositStruct storage depositor = deposits[account];
        if (depositor.tokenTime[address(0)] == 0 || countEarns == 0) {
            return 0;
        }
        if (countEarns == depositor.iterate) return depositor.balanceBLID;

        uint256 countTokens_ = countTokens;
        uint256 sum = 0;
        uint256 depositorIterate = depositor.iterate;
        for (uint256 j = 0; j < countTokens_; j++) {
            address token = tokens[j];

            if (depositorIterate == depositor.depositIterate[token]) {
                sum += getEarnedInOneDepositedIterate(depositorIterate, token, account);
                sum += getEarnedInOneNotDepositedIterate(depositorIterate, token, account);
            } else {
                sum += getEarnedInOneNotDepositedIterate(depositorIterate - 1, token, account);
            }
        }

        return sum + depositor.balanceBLID;
    }







    function balanceOf(address account) external view returns (uint256) {
        uint256 countTokens_ = countTokens;
        uint256 sum = 0;
        for (uint256 j = 0; j < countTokens_; j++) {
            address token = tokens[j];
            AggregatorV3Interface oracle = AggregatorV3Interface(oracles[token]);

            sum += ((deposits[account].amount[token] *
                uint256(oracle.latestAnswer()) *
                10**(18 - oracle.decimals())) / (1 ether));
        }
        return sum;
    }




    function getBLIDReserve() external view returns (uint256) {
        return reserveBLID;
    }




    function getTotalDeposit() external view returns (uint256) {
        uint256 countTokens_ = countTokens;
        uint256 sum = 0;
        for (uint256 j = 0; j < countTokens_; j++) {
            address token = tokens[j];
            AggregatorV3Interface oracle = AggregatorV3Interface(oracles[token]);
            sum +=
                (tokenDeposited[token] * uint256(oracle.latestAnswer()) * 10**(18 - oracle.decimals())) /
                (1 ether);
        }
        return sum;
    }




    function getTokenBalance(address token) external view returns (uint256) {
        return tokenBalance[token];
    }




    function getTokenDeposit(address account, address token) external view returns (uint256) {
        return deposits[account].amount[token];
    }





    function _isUsedToken(address _token) external view returns (bool) {
        return tokensAdd[_token];
    }




    function getCountEarns() external view returns (uint256) {
        return countEarns;
    }







    function getEarnsByID(uint256 id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (earnBLID[id].allBLID, earnBLID[id].timestamp, earnBLID[id].usd);
    }





    function getTokenDeposited(address token) external view returns (uint256) {
        return tokenDeposited[token];
    }








    function updateAccumulatedRewardsPerShareById(address token, uint256 id) private {
        EarnBLID storage thisEarnBLID = earnBLID[id];

        unchecked {
            accumulatedRewardsPerShare[token][id] =
                accumulatedRewardsPerShare[token][id - 1] +
                ((thisEarnBLID.allBLID *
                    (thisEarnBLID.timestamp - earnBLID[id - 1].timestamp) *
                    thisEarnBLID.rates[token]) / thisEarnBLID.tdt);
        }
    }







    function getEarnedInOneDepositedIterate(
        uint256 depositIterate,
        address token,
        address account
    ) private view returns (uint256) {
        EarnBLID storage thisEarnBLID = earnBLID[depositIterate];
        DepositStruct storage thisDepositor = deposits[account];
        return
            (
            thisEarnBLID.allBLID *

                uint256(
                    int256(thisDepositor.amount[token] * thisEarnBLID.rates[token] * thisEarnBLID.timestamp) -
                        thisDepositor.tokenTime[token] *
                        int256(thisEarnBLID.rates[token])
                )) /

            thisEarnBLID.tdt /
            (1 ether);
    }









    function getEarnedInOneNotDepositedIterate(
        uint256 depositIterate,
        address token,
        address account
    ) private view returns (uint256) {
        return
            ((accumulatedRewardsPerShare[token][countEarns - 1] -
                accumulatedRewardsPerShare[token][depositIterate]) * deposits[account].amount[token]) /
            (1 ether);
    }
}
