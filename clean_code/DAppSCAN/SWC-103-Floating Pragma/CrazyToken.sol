










pragma solidity >=0.4.22 <0.9.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/hardhat/console.sol";

contract CrazyToken is ERC20PresetMinterPauser, Ownable {
    using SafeMath for uint256;

    uint256 private constant INITIAL_SUPPLY = 1_000_000_000e18;
    bool public vestingTransferDone;
    bool public miningTransferDone;
    bool public inGameRewardTransferDone;
    bool public ecosystemGrowthTransferDone;
    bool public marketingTransferDone;





    constructor() ERC20PresetMinterPauser("Crazy Token", "$Crazy")
    {
        _mint(address(this), INITIAL_SUPPLY);
    }






    function transferToVesting(address _vestingAddress) external onlyOwner
    {
        require(!vestingTransferDone, "Already transferred");
        _transfer(address(this), _vestingAddress, INITIAL_SUPPLY.mul(40).div(100));
        vestingTransferDone = true;
    }






    function transferToMining(address _miningAddress) external onlyOwner
    {
        require(!miningTransferDone, "Already transferred");
        _transfer(address(this), _miningAddress, INITIAL_SUPPLY.mul(40).div(100));
        miningTransferDone = true;
    }






    function transferToVaultInGameReward(address _inGameRewardAddress) external onlyOwner {
        require(!inGameRewardTransferDone, "Already transferred");
        _transfer(address(this), _inGameRewardAddress, INITIAL_SUPPLY.mul(10).div(100));
        inGameRewardTransferDone = true;
    }






    function transferToEcosystemGrowth(address _ecosystemGrowthAddress) external onlyOwner {
        require(!ecosystemGrowthTransferDone, "Already transferred");
        _transfer(address(this), _ecosystemGrowthAddress, INITIAL_SUPPLY.mul(5).div(100));
        ecosystemGrowthTransferDone = true;
    }






    function transferToMarketing(address _marketingAddress) external onlyOwner {
        require(!marketingTransferDone, "Already transferred");
        _transfer(address(this), _marketingAddress, INITIAL_SUPPLY.mul(5).div(100));
        marketingTransferDone = true;
    }
}
