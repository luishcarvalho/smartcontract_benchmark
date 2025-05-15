pragma solidity 0.5.11;

import {
    Initializable
} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { Governable } from "../governance/Governable.sol";

contract InitializableAbstractStrategy is Initializable, Governable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event PTokenAdded(address indexed _asset, address _pToken);
    event Deposit(address indexed _asset, address _pToken, uint256 _amount);
    event Withdrawal(address indexed _asset, address _pToken, uint256 _amount);
    event RewardTokenCollected(address recipient, uint256 amount);


    address public platformAddress;

    address public vaultAddress;


    mapping(address => address) public assetToPToken;


    address[] internal assetsMapped;


    address public rewardTokenAddress;
    uint256 public rewardLiquidationThreshold;









    function initialize(
        address _platformAddress,
        address _vaultAddress,
        address _rewardTokenAddress,
        address[] calldata _assets,
        address[] calldata _pTokens
    ) external onlyGovernor initializer {
        InitializableAbstractStrategy._initialize(
            _platformAddress,
            _vaultAddress,
            _rewardTokenAddress,
            _assets,
            _pTokens
        );
    }




    function collectRewardToken() external onlyVault {
        IERC20 rewardToken = IERC20(rewardTokenAddress);
        uint256 balance = rewardToken.balanceOf(address(this));
        require(
            rewardToken.transfer(vaultAddress, balance),
            "Reward token transfer failed"
        );

        emit RewardTokenCollected(vaultAddress, balance);
    }

    function _initialize(
        address _platformAddress,
        address _vaultAddress,
        address _rewardTokenAddress,
        address[] memory _assets,
        address[] memory _pTokens
    ) internal {
        platformAddress = _platformAddress;
        vaultAddress = _vaultAddress;
        rewardTokenAddress = _rewardTokenAddress;
        uint256 assetCount = _assets.length;
        require(assetCount == _pTokens.length, "Invalid input arrays");
        for (uint256 i = 0; i < assetCount; i++) {
            _setPTokenAddress(_assets[i], _pTokens[i]);
        }
    }




    function _initialize(
        address _platformAddress,
        address _vaultAddress,
        address _rewardTokenAddress,
        address _asset,
        address _pToken
    ) internal {
        platformAddress = _platformAddress;
        vaultAddress = _vaultAddress;
        rewardTokenAddress = _rewardTokenAddress;
        _setPTokenAddress(_asset, _pToken);
    }




    modifier onlyVault() {
        require(msg.sender == vaultAddress, "Caller is not the Vault");
        _;
    }




    modifier onlyVaultOrGovernor() {
        require(
            msg.sender == vaultAddress || msg.sender == governor(),
            "Caller is not the Vault or Governor"
        );
        _;
    }





    function setRewardTokenAddress(address _rewardTokenAddress)
        external
        onlyGovernor
    {
        rewardTokenAddress = _rewardTokenAddress;
    }






    function setRewardLiquidationThreshold(uint256 _threshold)
        external
        onlyGovernor
    {
        rewardLiquidationThreshold = _threshold;
    }







    function setPTokenAddress(address _asset, address _pToken)
        external
        onlyGovernor
    {
        _setPTokenAddress(_asset, _pToken);
    }








    function _setPTokenAddress(address _asset, address _pToken) internal {
        require(assetToPToken[_asset] == address(0), "pToken already set");
        require(
            _asset != address(0) && _pToken != address(0),
            "Invalid addresses"
        );

        assetToPToken[_asset] = _pToken;
        assetsMapped.push(_asset);

        emit PTokenAdded(_asset, _pToken);

        _abstractSetPToken(_asset, _pToken);
    }








    function transferToken(address _asset, uint256 _amount)
        public
        onlyGovernor
    {
        IERC20(_asset).transfer(governor(), _amount);
    }





    function _abstractSetPToken(address _asset, address _pToken) internal;

    function safeApproveAllTokens() external;







    function deposit(address _asset, uint256 _amount)
        external
        returns (uint256 amountDeposited);








    function withdraw(
        address _recipient,
        address _asset,
        uint256 _amount
    ) external returns (uint256 amountWithdrawn);




    function liquidate() external;







    function checkBalance(address _asset)
        external
        view
        returns (uint256 balance);






    function supportsAsset(address _asset) external view returns (bool);
}
