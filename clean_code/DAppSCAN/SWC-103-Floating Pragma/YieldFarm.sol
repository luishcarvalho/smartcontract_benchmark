

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStaking.sol";


contract YieldFarm {


    using SafeMath for uint;
    using SafeMath for uint128;


    uint public constant TOTAL_DISTRIBUTED_AMOUNT = 800000;
    uint public constant NR_OF_EPOCHS = 25;




    address private _usdc;
    address private _susd;
    address private _dai;
    address private _communityVault;

    IERC20 private _bond;
    IStaking private _staking;



    uint[] private epochs = new uint[](NR_OF_EPOCHS + 1);

    uint private _totalAmountPerEpoch;


    uint128 public lastInitializedEpoch;


    mapping(address => uint128) private lastEpochIdHarvested;
    uint public epochDuration;
    uint public epochStart;


    event MassHarvest(address indexed user, uint256 epochsHarvested, uint256 totalValue);
    event Harvest(address indexed user, uint128 indexed epochId, uint256 amount);


    constructor(address bondTokenAddress, address usdc, address susd, address dai, address stakeContract, address communityVault) public {
        _bond = IERC20(bondTokenAddress);
        _usdc = usdc;
        _susd = susd;
        _dai = dai;
        _staking = IStaking(stakeContract);
        _communityVault = communityVault;
        epochStart = _staking.epoch1Start();
        epochDuration = _staking.epochDuration();
        _totalAmountPerEpoch = TOTAL_DISTRIBUTED_AMOUNT.mul(10**18).div(NR_OF_EPOCHS);
    }



    function massHarvest() external returns (uint){
        uint totalDistributedValue;
        uint epochId = _getEpochId().sub(1);

        if (epochId > NR_OF_EPOCHS) {
            epochId = NR_OF_EPOCHS;
        }


        for (uint128 i = lastEpochIdHarvested[msg.sender] + 1; i <= epochId; i++) {


            totalDistributedValue += _harvest(i);
        }

        emit MassHarvest(msg.sender, epochId.sub(lastEpochIdHarvested[msg.sender]), totalDistributedValue);

        if (totalDistributedValue > 0) {
            _bond.transferFrom(_communityVault, msg.sender, totalDistributedValue);
        }

        return totalDistributedValue;
    }
    function harvest (uint128 epochId) external returns (uint){

        require (_getEpochId() > epochId, "This epoch is in the future");
        require(epochId <= NR_OF_EPOCHS, "Maximum number of epochs is 25");
        require (lastEpochIdHarvested[msg.sender].add(1) == epochId, "Harvest in order");
        uint userReward = _harvest(epochId);
        if (userReward > 0) {
            _bond.transferFrom(_communityVault, msg.sender, userReward);
        }
        emit Harvest(msg.sender, epochId, userReward);
        return userReward;
    }



    function getPoolSize(uint128 epochId) external view returns (uint) {
        return _getPoolSize(epochId);
    }

    function getCurrentEpoch() external view returns (uint) {
        return _getEpochId();
    }


    function getEpochStake(address userAddress, uint128 epochId) external view returns (uint) {
        return _getUserBalancePerEpoch(userAddress, epochId);
    }

    function userLastEpochIdHarvested() external view returns (uint){
        return lastEpochIdHarvested[msg.sender];
    }



    function _initEpoch(uint128 epochId) internal {
        require(lastInitializedEpoch.add(1) == epochId, "Epoch can be init only in order");
        lastInitializedEpoch = epochId;

        epochs[epochId] = _getPoolSize(epochId);
    }

    function _harvest (uint128 epochId) internal returns (uint) {


        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }

        lastEpochIdHarvested[msg.sender] = epochId;



        if (epochs[epochId] == 0) {
            return 0;
        }

        return _totalAmountPerEpoch
        .mul(_getUserBalancePerEpoch(msg.sender, epochId))
        .div(epochs[epochId]);
    }

    function _getPoolSize(uint128 epochId) internal view returns (uint) {

        uint valueUsdc = _staking.getEpochPoolSize(_usdc, epochId).mul(10 ** 12);
        uint valueSusd = _staking.getEpochPoolSize(_susd, epochId);
        uint valueDai = _staking.getEpochPoolSize(_dai, epochId);
        return valueUsdc.add(valueSusd).add(valueDai);
    }



    function _getUserBalancePerEpoch(address userAddress, uint128 epochId) internal view returns (uint){

        uint valueUsdc = _staking.getEpochUserBalance(userAddress, _usdc, epochId).mul(10 ** 12);
        uint valueSusd = _staking.getEpochUserBalance(userAddress, _susd, epochId);
        uint valueDai = _staking.getEpochUserBalance(userAddress, _dai, epochId);
        return valueUsdc.add(valueSusd).add(valueDai);
    }


    function _getEpochId() internal view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(block.timestamp.sub(epochStart).div(epochDuration).add(1));
    }
}
