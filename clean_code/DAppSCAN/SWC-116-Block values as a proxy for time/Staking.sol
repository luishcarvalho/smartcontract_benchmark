
pragma solidity ^0.8.7;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1363Receiver} from "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import {IAccessControl, AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import "hardhat/console.sol";

import {StableThenToken} from "./staking/StableThenToken.sol";
import {IRewardParameters, RewardCalculator} from "./staking/RewardCalculator.sol";
import {ITalentToken} from "./TalentToken.sol";
import {ITalentFactory} from "./TalentFactory.sol";
























































contract Staking is AccessControl, StableThenToken, RewardCalculator, IERC1363Receiver {





    struct StakeData {

        uint256 tokenAmount;

        uint256 talentAmount;



        uint256 lastCheckpointAt;
        uint256 S;
        bool finishedAccumulating;
    }


    enum RewardAction {
        WITHDRAW,
        RESTAKE
    }





    bytes4 constant ERC1363_RECEIVER_RET = bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"));






    mapping(address => mapping(address => StakeData)) public stakes;


    uint256 public activeStakes;


    uint256 finishedAccumulatingStakeCount;


    mapping(address => uint256) public talentRedeemableRewards;


    mapping(address => uint256) public maxSForTalent;


    bool public disabled;


    address public factory;


    uint256 public tokenPrice;


    uint256 public talentPrice;






    uint256 public totalStableStored;


    uint256 public totalTokensStaked;


    uint256 rewardsAdminWithdrawn;



    uint256 public override(IRewardParameters) totalAdjustedShares;


    uint256 public immutable override(IRewardParameters) rewardsMax;


    uint256 public override(IRewardParameters) rewardsGiven;


    uint256 public immutable override(IRewardParameters) start;


    uint256 public immutable override(IRewardParameters) end;


    uint256 public S;


    uint256 public SAt;


    bool private isAlreadyUpdatingAdjustedShares;






    event Stake(address indexed owner, address indexed talentToken, uint256 talAmount, bool stable);


    event RewardClaim(address indexed owner, address indexed talentToken, uint256 stakerReward, uint256 talentReward);


    event RewardWithdrawal(
        address indexed owner,
        address indexed talentToken,
        uint256 stakerReward,
        uint256 talentReward
    );


    event TalentRewardWithdrawal(address indexed talentToken, address indexed talentTokenWallet, uint256 reward);


    event Unstake(address indexed owner, address indexed talentToken, uint256 talAmount);












    constructor(
        uint256 _start,
        uint256 _end,
        uint256 _rewardsMax,
        address _stableCoin,
        address _factory,
        uint256 _tokenPrice,
        uint256 _talentPrice
    ) StableThenToken(_stableCoin) {
        require(_tokenPrice > 0, "_tokenPrice cannot be 0");
        require(_talentPrice > 0, "_talentPrice cannot be 0");

        start = _start;
        end = _end;
        rewardsMax = _rewardsMax;
        factory = _factory;
        tokenPrice = _tokenPrice;
        talentPrice = _talentPrice;
        SAt = _start;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }








    function stakeStable(address _talent, uint256 _amount)
        public
        onlyWhileStakingEnabled
        stablePhaseOnly
        updatesAdjustedShares(msg.sender, _talent)
        returns (bool)
    {
        require(_amount > 0, "amount cannot be zero");
        require(!disabled, "staking has been disabled");

        uint256 tokenAmount = convertUsdToToken(_amount);

        totalStableStored += _amount;

        _checkpointAndStake(msg.sender, _talent, tokenAmount);

        IERC20(stableCoin).transferFrom(msg.sender, address(this), _amount);

        emit Stake(msg.sender, _talent, tokenAmount, true);

        return true;
    }





    function claimRewards(address _talent) public returns (bool) {
        claimRewardsOnBehalf(msg.sender, _talent);

        return true;
    }






    function claimRewardsOnBehalf(address _owner, address _talent)
        public
        updatesAdjustedShares(_owner, _talent)
        returns (bool)
    {
        _checkpoint(_owner, _talent, RewardAction.RESTAKE);

        return true;
    }





    function withdrawRewards(address _talent)
        public
        tokenPhaseOnly
        updatesAdjustedShares(msg.sender, _talent)
        returns (bool)
    {
        _checkpoint(msg.sender, _talent, RewardAction.WITHDRAW);

        return true;
    }








    function withdrawTalentRewards(address _talent) public tokenPhaseOnly returns (bool) {

        require(msg.sender == ITalentToken(_talent).talent(), "only the talent can withdraw their own shares");

        uint256 amount = talentRedeemableRewards[_talent];

        IERC20(token).transfer(msg.sender, amount);

        talentRedeemableRewards[_talent] = 0;

        return true;
    }




    function stableCoinBalance() public view returns (uint256) {
        return IERC20(stableCoin).balanceOf(address(this));
    }




    function tokenBalance() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }










    function stakeAvailability(address _talent) public view returns (uint256) {
        require(_isTalentToken(_talent), "not a valid talent token");

        uint256 talentAmount = ITalentToken(_talent).mintingAvailability();

        return convertTalentToToken(talentAmount);
    }









    function swapStableForToken(uint256 _stableAmount) public onlyRole(DEFAULT_ADMIN_ROLE) tokenPhaseOnly {
        require(_stableAmount <= totalStableStored, "not enough stable coin left in the contract");

        uint256 tokenAmount = convertUsdToToken(_stableAmount);
        totalStableStored -= _stableAmount;

        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
        IERC20(stableCoin).transfer(msg.sender, _stableAmount);
    }





    function onTransferReceived(
        address,
        address _sender,
        uint256 _amount,
        bytes calldata data
    ) external override(IERC1363Receiver) onlyWhileStakingEnabled returns (bytes4) {
        if (_isToken(msg.sender)) {
            require(!disabled, "staking has been disabled");




            address talent = bytesToAddress(data);

            _checkpointAndStake(_sender, talent, _amount);

            emit Stake(_sender, talent, _amount, false);

            return ERC1363_RECEIVER_RET;
        } else if (_isTalentToken(msg.sender)) {
            require(_isTokenSet(), "TAL token not yet set. Refund not possible");


            address talent = msg.sender;

            uint256 tokenAmount = _checkpointAndUnstake(_sender, talent, _amount);

            emit Unstake(_sender, talent, tokenAmount);

            return ERC1363_RECEIVER_RET;
        } else {
            revert("Unrecognized ERC1363 token received");
        }
    }

    function _isToken(address _address) internal view returns (bool) {
        return _address == token;
    }

    function _isTalentToken(address _address) internal view returns (bool) {
        return ITalentFactory(factory).isTalentToken(_address);
    }









    function totalShares() public view override(IRewardParameters) returns (uint256) {
        return totalTokensStaked;
    }

    function rewardsLeft() public view override(IRewardParameters) returns (uint256) {
        return rewardsMax - rewardsGiven - rewardsAdminWithdrawn;
    }






    function disable() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!disabled, "already disabled");

        _updateS();
        disabled = true;
    }


    function adminWithdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(disabled || block.timestamp < end, "not disabled, and not end of staking either");
        require(activeStakes == 0, "there are still stakes accumulating rewards. Call `claimRewardsOnBehalf` on them");

        uint256 amount = rewardsLeft();
        require(amount > 0, "nothing left to withdraw");

        IERC20(token).transfer(msg.sender, amount);
        rewardsAdminWithdrawn += amount;
    }


















    function _checkpointAndStake(
        address _owner,
        address _talent,
        uint256 _tokenAmount
    ) private updatesAdjustedShares(_owner, _talent) {
        require(_isTalentToken(_talent), "not a valid talent token");
        require(_tokenAmount > 0, "amount cannot be zero");

        _checkpoint(_owner, _talent, RewardAction.RESTAKE);
        _stake(_owner, _talent, _tokenAmount);
    }










    function _checkpointAndUnstake(
        address _owner,
        address _talent,
        uint256 _talentAmount
    ) private updatesAdjustedShares(_owner, _talent) returns (uint256) {
        require(_isTalentToken(_talent), "not a valid talent token");

        _checkpoint(_owner, _talent, RewardAction.RESTAKE);

        StakeData storage stake = stakes[_owner][_talent];

        require(stake.lastCheckpointAt > 0, "stake does not exist");
        require(stake.talentAmount >= _talentAmount);






        uint256 proportion = (_talentAmount * MUL) / stake.talentAmount;
        uint256 tokenAmount = (stake.tokenAmount * proportion) / MUL;

        require(IERC20(token).balanceOf(address(this)) >= tokenAmount, "not enough TAL to fulfill request");

        stake.talentAmount -= _talentAmount;
        stake.tokenAmount -= tokenAmount;
        totalTokensStaked -= tokenAmount;


        if (stake.tokenAmount == 0 && !stake.finishedAccumulating) {
            stake.finishedAccumulating = true;


            activeStakes -= 1;
        }

        _burnTalent(_talent, _talentAmount);
        _withdrawToken(_owner, tokenAmount);

        return tokenAmount;
    }









    function _stake(
        address _owner,
        address _talent,
        uint256 _tokenAmount
    ) private {
        uint256 talentAmount = convertTokenToTalent(_tokenAmount);

        StakeData storage stake = stakes[_owner][_talent];


        if (stake.tokenAmount == 0) {
            activeStakes += 1;
        }

        stake.tokenAmount += _tokenAmount;
        stake.talentAmount += talentAmount;

        totalTokensStaked += _tokenAmount;

        _mintTalent(_owner, _talent, talentAmount);
    }







    function _checkpoint(
        address _owner,
        address _talent,
        RewardAction _action
    ) private updatesAdjustedShares(_owner, _talent) {
        StakeData storage stake = stakes[_owner][_talent];

        _updateS();


        address talentAddress = ITalentToken(_talent).talent();








        uint256 maxS = (maxSForTalent[_talent] > 0) ? maxSForTalent[_talent] : S;

        (uint256 stakerRewards, uint256 talentRewards) = calculateReward(
            stake.tokenAmount,
            stake.S,
            maxS,
            stake.talentAmount,
            IERC20(_talent).balanceOf(talentAddress)
        );

        rewardsGiven += stakerRewards + talentRewards;
        stake.S = maxS;
        stake.lastCheckpointAt = block.timestamp;

        talentRedeemableRewards[_talent] += talentRewards;




        if (disabled && !stake.finishedAccumulating) {
            stake.finishedAccumulating = true;
            activeStakes -= 1;
        }


        if (stakerRewards == 0) {
            return;
        }

        if (_action == RewardAction.WITHDRAW) {
            IERC20(token).transfer(_owner, stakerRewards);
            emit RewardWithdrawal(_owner, _talent, stakerRewards, talentRewards);
        } else if (_action == RewardAction.RESTAKE) {

            uint256 availability = stakeAvailability(_talent);
            uint256 rewardsToStake = (availability > stakerRewards) ? stakerRewards : availability;
            uint256 rewardsToWithdraw = stakerRewards - rewardsToStake;

            _stake(_owner, _talent, rewardsToStake);
            emit RewardClaim(_owner, _talent, rewardsToStake, talentRewards);



            if (rewardsToWithdraw > 0 && token != address(0x0)) {
                IERC20(token).transfer(_owner, rewardsToWithdraw);
                emit RewardWithdrawal(_owner, _talent, rewardsToWithdraw, 0);
            }
        } else {
            revert("Unrecognized checkpoint action");
        }
    }

    function _updateS() private {
        if (disabled) {
            return;
        }

        if (totalTokensStaked == 0) {
            return;
        }

        S = S + (calculateGlobalReward(SAt, block.timestamp)) / totalAdjustedShares;
        SAt = block.timestamp;
    }

    function calculateEstimatedReturns(
        address _owner,
        address _talent,
        uint256 _currentTime
    ) public view returns (uint256 stakerRewards, uint256 talentRewards) {
        StakeData storage stake = stakes[_owner][_talent];
        uint256 newS;

        if (maxSForTalent[_talent] > 0) {
            newS = maxSForTalent[_talent];
        } else {
            newS = S + (calculateGlobalReward(SAt, _currentTime)) / totalAdjustedShares;
        }
        address talentAddress = ITalentToken(_talent).talent();
        uint256 talentBalance = IERC20(_talent).balanceOf(talentAddress);

        (uint256 sRewards, uint256 tRewards) = calculateReward(
            stake.tokenAmount,
            stake.S,
            newS,
            stake.talentAmount,
            talentBalance
        );

        return (sRewards, tRewards);
    }














    function _mintTalent(
        address _owner,
        address _talent,
        uint256 _amount
    ) private {
        ITalentToken(_talent).mint(_owner, _amount);

        if (maxSForTalent[_talent] == 0 && ITalentToken(_talent).mintingFinishedAt() > 0) {
            maxSForTalent[_talent] = S;
        }
    }









    function _burnTalent(address _talent, uint256 _amount) private {
        ITalentToken(_talent).burn(address(this), _amount);
    }


    function _withdrawToken(address _owner, uint256 _amount) private {
        IERC20(token).transfer(_owner, _amount);
    }

    modifier updatesAdjustedShares(address _owner, address _talent) {
        if (isAlreadyUpdatingAdjustedShares) {


            _;
        } else {
            isAlreadyUpdatingAdjustedShares = true;





            uint256 toDeduct = sqrt(stakes[_owner][_talent].tokenAmount);

            _;




            totalAdjustedShares = totalAdjustedShares + sqrt(stakes[_owner][_talent].tokenAmount) - toDeduct;
            isAlreadyUpdatingAdjustedShares = false;
        }
    }

    modifier onlyWhileStakingEnabled() {
        require(block.timestamp >= start, "staking period not yet started");
        require(block.timestamp <= end, "staking period already finished");
        _;
    }





    function convertUsdToToken(uint256 _usd) public view returns (uint256) {
        return (_usd / tokenPrice) * 1 ether;
    }





    function convertTokenToTalent(uint256 _tal) public view returns (uint256) {
        return (_tal / talentPrice) * 1 ether;
    }





    function convertTalentToToken(uint256 _talent) public view returns (uint256) {
        return (_talent * talentPrice) / 1 ether;
    }





    function convertUsdToTalent(uint256 _usd) public view returns (uint256) {
        return convertTokenToTalent(convertUsdToToken(_usd));
    }







    function bytesToAddress(bytes memory bs) private pure returns (address addr) {
        require(bs.length == 20, "invalid data length for address");

        assembly {
            addr := mload(add(bs, 20))
        }
    }
}
