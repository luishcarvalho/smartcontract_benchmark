
pragma solidity 0.8.10;

import "./interfaces/IProxyVault.sol";
import "./interfaces/IFeeRegistry.sol";
import "./interfaces/IFraxFarmUniV3.sol";
import "./interfaces/IRewards.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


contract StakingProxyUniV3 is IProxyVault{
    using SafeERC20 for IERC20;

    address public constant fxs = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
    address public constant vefxsProxy = address(0x59CFCD384746ec3035299D90782Be065e466800B);
    address public constant positionManager = address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address public immutable feeRegistry;

    address public owner;
    address public stakingAddress;
    address public rewards;

    uint256 public constant FEE_DENOMINATOR = 10000;

    constructor(address _feeRegistry) {
        feeRegistry = _feeRegistry;
    }

    function vaultType() external pure returns(VaultType){
        return VaultType.UniV3;
    }

    function vaultVersion() external pure returns(uint256){
        return 1;
    }


    function initialize(address _owner, address _stakingAddress, address _stakingToken, address _rewardsAddress) external{
        require(owner == address(0),"already init");


        owner = _owner;
        stakingAddress = _stakingAddress;
        rewards = _rewardsAddress;


        IFraxFarmUniV3(_stakingAddress).stakerSetVeFXSProxy(vefxsProxy);


        INonfungiblePositionManager(positionManager).setApprovalForAll(_stakingAddress, true);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "!auth");
        _;
    }


    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }


    function stakeLocked(uint256 _token_id, uint256 _secs) external onlyOwner{

        uint256 userLiq = IFraxFarmUniV3(stakingAddress).lockedLiquidityOf(address(this));

        if(_token_id > 0){

            INonfungiblePositionManager(positionManager).safeTransferFrom(msg.sender, address(this), _token_id);


            IFraxFarmUniV3(stakingAddress).stakeLocked(_token_id, _secs);
        }



        if(IRewards(rewards).active()){

            userLiq = IFraxFarmUniV3(stakingAddress).lockedLiquidityOf(address(this)) - userLiq;
            IRewards(rewards).deposit(owner,userLiq);
        }
    }



    function lockAdditional(uint256 _token_id, uint256 _token0_amt, uint256 _token1_amt) external onlyOwner{
        uint256 userLiq = IFraxFarmUniV3(stakingAddress).lockedLiquidityOf(address(this));

        if(_token_id > 0 && _token0_amt > 0 && _token1_amt > 0){
            address token0 = IFraxFarmUniV3(stakingAddress).uni_token0();
            address token1 = IFraxFarmUniV3(stakingAddress).uni_token1();

            IERC20(token0).safeTransferFrom(msg.sender, stakingAddress, _token0_amt);
            IERC20(token1).safeTransferFrom(msg.sender, stakingAddress, _token1_amt);


            IFraxFarmUniV3(stakingAddress).lockAdditional(_token_id, _token0_amt, _token1_amt, 0, 0, true);
        }


        if(IRewards(rewards).active()){
            userLiq = IFraxFarmUniV3(stakingAddress).lockedLiquidityOf(address(this)) - userLiq;
            IRewards(rewards).deposit(owner,userLiq);
        }
    }


    function withdrawLocked(uint256 _token_id) external onlyOwner{

        uint256 userLiq = IFraxFarmUniV3(stakingAddress).lockedLiquidityOf(address(this));


        IFraxFarmUniV3(stakingAddress).withdrawLocked(_token_id, msg.sender);


        if(IRewards(rewards).active()){

            userLiq -= IFraxFarmUniV3(stakingAddress).lockedLiquidityOf(address(this));
            IRewards(rewards).withdraw(owner,userLiq);
        }
    }


    function earned() external view returns (address[] memory token_addresses, uint256[] memory total_earned) {

        address[] memory rewardTokens = IFraxFarmUniV3(stakingAddress).getAllRewardTokens();
        uint256[] memory stakedearned = IFraxFarmUniV3(stakingAddress).earned(address(this));

        token_addresses = new address[](rewardTokens.length + IRewards(rewards).rewardTokenLength());
        total_earned = new uint256[](rewardTokens.length + IRewards(rewards).rewardTokenLength());


        for(uint256 i = 0; i < rewardTokens.length; i++){
            token_addresses[i] = rewardTokens[i];
            total_earned[i] = stakedearned[i] + IERC20(rewardTokens[i]).balanceOf(address(this));
        }

        IRewards.EarnedData[] memory extraRewards = IRewards(rewards).claimableRewards(address(this));
        for(uint256 i = 0; i < extraRewards.length; i++){
            token_addresses[i+rewardTokens.length] = extraRewards[i].token;
            total_earned[i+rewardTokens.length] = extraRewards[i].amount;
        }
    }












    function getReward() external onlyOwner{
        getReward(true);
    }





    function getReward(bool _claim) public onlyOwner{


        if(_claim){


            IFraxFarmUniV3(stakingAddress).getReward(address(this), false);
            IFraxFarmUniV3(stakingAddress).getReward(owner, true);
        }


        _processFxs();


        address[] memory rewardTokens = IFraxFarmUniV3(stakingAddress).getAllRewardTokens();


        _transferTokens(rewardTokens);


        _processExtraRewards();
    }





    function getReward(bool _claim, address[] calldata _rewardTokenList) external onlyOwner{


        if(_claim){


            IFraxFarmUniV3(stakingAddress).getReward(address(this), false);
            IFraxFarmUniV3(stakingAddress).getReward(owner, true);
        }


        _processFxs();


        _transferTokens(_rewardTokenList);


        _processExtraRewards();
    }


    function _processExtraRewards() internal{
        if(IRewards(rewards).active()){

            uint256 bal = IRewards(rewards).balanceOf(address(this));
            if(bal == 0){

                uint256 userLiq = IFraxFarmUniV3(stakingAddress).lockedLiquidityOf(address(this));
                IRewards(rewards).deposit(owner,userLiq);
            }
            IRewards(rewards).getReward(owner);
        }
    }


    function _processFxs() internal{


        uint256 totalFees = IFeeRegistry(feeRegistry).totalFees();


        uint256 fxsBalance = IERC20(fxs).balanceOf(address(this));
        uint256 sendAmount = fxsBalance * totalFees / FEE_DENOMINATOR;
        if(sendAmount > 0){
            IERC20(fxs).transfer(IFeeRegistry(feeRegistry).feeDeposit(), sendAmount);
        }


        sendAmount = IERC20(fxs).balanceOf(address(this));
        if(sendAmount > 0){
            IERC20(fxs).transfer(msg.sender, sendAmount);
        }
    }


    function _transferTokens(address[] memory _tokens) internal{

        for(uint256 i = 0; i < _tokens.length; i++){
            if(_tokens[i] != fxs){
                uint256 bal = IERC20(_tokens[i]).balanceOf(address(this));
                if(bal > 0){
                    IERC20(_tokens[i]).transfer(msg.sender, bal);
                }
            }
        }
    }



    function recoverERC721(address _tokenAddress, uint256 _token_id) external onlyOwner {
        INonfungiblePositionManager(_tokenAddress).safeTransferFrom(address(this), owner, _token_id);
    }
}
