pragma solidity ^0.5.0;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@aragon/court/contracts/lib/Checkpointing.sol";
import "@aragon/court/contracts/lib/os/Uint256Helpers.sol";
import "./InitializableV2.sol";


contract Staking is InitializableV2 {
    using SafeMath for uint256;
    using Uint256Helpers for uint256;
    using Checkpointing for Checkpointing.History;
    using SafeERC20 for ERC20;

    string private constant ERROR_TOKEN_NOT_CONTRACT = "STAKING_TOKEN_NOT_CONTRACT";
    string private constant ERROR_AMOUNT_ZERO = "STAKING_AMOUNT_ZERO";
    string private constant ERROR_TOKEN_TRANSFER = "STAKING_TOKEN_TRANSFER";
    string private constant ERROR_NOT_ENOUGH_BALANCE = "STAKING_NOT_ENOUGH_BALANCE";


    struct Account {
        Checkpointing.History stakedHistory;
        Checkpointing.History claimHistory;
    }


    ERC20 internal stakingToken;


    mapping (address => Account) internal accounts;


    Checkpointing.History internal totalStakedHistory;

    address governanceAddress;
    address claimsManagerAddress;
    address delegateManagerAddress;
    address serviceProviderFactoryAddress;

    event Staked(address indexed user, uint256 amount, uint256 total);
    event Unstaked(address indexed user, uint256 amount, uint256 total);
    event Slashed(address indexed user, uint256 amount, uint256 total);






    function initialize(
        address _stakingToken,
        address _governanceAddress
    ) public initializer
    {
        require(Address.isContract(_stakingToken), ERROR_TOKEN_NOT_CONTRACT);
        stakingToken = ERC20(_stakingToken);
        governanceAddress = _governanceAddress;
        InitializableV2.initialize();
    }






    function setGovernanceAddress(address _governanceAddress) external {
        require(msg.sender == governanceAddress, "Only governance");
        governanceAddress = _governanceAddress;
    }






    function setClaimsManagerAddress(address _claimsManager) external {
        require(msg.sender == governanceAddress, "Only governance");
        claimsManagerAddress = _claimsManager;
    }






    function setServiceProviderFactoryAddress(address _spFactory) external {
        require(msg.sender == governanceAddress, "Only governance");
        serviceProviderFactoryAddress = _spFactory;
    }






    function setDelegateManagerAddress(address _delegateManager) external {
        require(msg.sender == governanceAddress, "Only governance");
        delegateManagerAddress = _delegateManager;
    }








    function stakeRewards(uint256 _amount, address _stakerAccount) external {
        _requireIsInitialized();
        require(
            msg.sender == claimsManagerAddress,
            "Only callable from ClaimsManager"
        );
        _stakeFor(_stakerAccount, msg.sender, _amount);

        this.updateClaimHistory(_amount, _stakerAccount);
    }






    function updateClaimHistory(uint256 _amount, address _stakerAccount) external {
        _requireIsInitialized();
        require(
            msg.sender == claimsManagerAddress || msg.sender == address(this),
            "Only callable from ClaimsManager or Staking.sol"
        );


        accounts[_stakerAccount].claimHistory.add(block.number.toUint64(), _amount);
    }







    function slash(
        uint256 _amount,
        address _slashAddress
    ) external
    {
        _requireIsInitialized();
        require(
            msg.sender == delegateManagerAddress,
            "Only callable from DelegateManager"
        );


        _burnFor(_slashAddress, _amount);

        emit Slashed(
            _slashAddress,
            _amount,
            totalStakedFor(_slashAddress)
        );
    }






    function stakeFor(
        address _accountAddress,
        uint256 _amount
    ) external
    {
        _requireIsInitialized();
        require(
            msg.sender == serviceProviderFactoryAddress,
            "Only callable from ServiceProviderFactory"
        );
        _stakeFor(
            _accountAddress,
            _accountAddress,
            _amount);
    }






    function unstakeFor(
        address _accountAddress,
        uint256 _amount
    ) external
    {
        _requireIsInitialized();
        require(
            msg.sender == serviceProviderFactoryAddress,
            "Only callable from ServiceProviderFactory"
        );
        _unstakeFor(
            _accountAddress,
            _accountAddress,
            _amount
        );
    }







    function delegateStakeFor(
        address _accountAddress,
        address _delegatorAddress,
        uint256 _amount
    ) external {
        _requireIsInitialized();
        require(
            msg.sender == delegateManagerAddress,
            "delegateStakeFor - Only callable from DelegateManager"
        );
        _stakeFor(
            _accountAddress,
            _delegatorAddress,
            _amount);
    }







    function undelegateStakeFor(
        address _accountAddress,
        address _delegatorAddress,
        uint256 _amount
    ) external {
        _requireIsInitialized();
        require(
            msg.sender == delegateManagerAddress,
            "undelegateStakeFor - Only callable from DelegateManager"
        );
        _unstakeFor(
            _accountAddress,
            _delegatorAddress,
            _amount);
    }





    function token() external view returns (address) {
        return address(stakingToken);
    }





    function supportsHistory() external pure returns (bool) {
        return true;
    }






    function lastStakedFor(address _accountAddress) external view returns (uint256) {
        uint256 length = accounts[_accountAddress].stakedHistory.history.length;
        if (length > 0) {
            return uint256(accounts[_accountAddress].stakedHistory.history[length - 1].time);
        }
        return 0;
    }






    function lastClaimedFor(address _accountAddress) external view returns (uint256) {
        uint256 length = accounts[_accountAddress].claimHistory.history.length;
        if (length > 0) {
            return uint256(accounts[_accountAddress].claimHistory.history[length - 1].time);
        }
        return 0;
    }







    function totalStakedForAt(
        address _accountAddress,
        uint256 _blockNumber
    ) external view returns (uint256) {
        return accounts[_accountAddress].stakedHistory.get(_blockNumber.toUint64());
    }






    function totalStakedAt(uint256 _blockNumber) external view returns (uint256) {
        return totalStakedHistory.get(_blockNumber.toUint64());
    }


    function getGovernanceAddress() external view returns (address addr) {
        return governanceAddress;
    }


    function getClaimsManagerAddress() external view returns (address addr) {
        return claimsManagerAddress;
    }


    function getServiceProviderFactoryAddress() external view returns (address addr) {
        return serviceProviderFactoryAddress;
    }


    function getDelegateManagerAddress() external view returns (address addr) {
        return delegateManagerAddress;
    }








    function totalStakedFor(address _accountAddress) public view returns (uint256) {

        return accounts[_accountAddress].stakedHistory.getLast();
    }





    function totalStaked() public view returns (uint256) {

        return totalStakedHistory.getLast();
    }









    function _stakeFor(
        address _stakeAccount,
        address _transferAccount,
        uint256 _amount
    ) internal
    {

        require(_amount > 0, ERROR_AMOUNT_ZERO);


        _modifyStakeBalance(_stakeAccount, _amount, true);


        _modifyTotalStaked(_amount, true);


        stakingToken.safeTransferFrom(_transferAccount, address(this), _amount);

        emit Staked(
            _stakeAccount,
            _amount,
            totalStakedFor(_stakeAccount));
    }







    function _unstakeFor(
        address _stakeAccount,
        address _transferAccount,
        uint256 _amount
    ) internal
    {
        require(_amount > 0, ERROR_AMOUNT_ZERO);


        _modifyStakeBalance(_stakeAccount, _amount, false);


        _modifyTotalStaked(_amount, false);


        stakingToken.safeTransfer(_transferAccount, _amount);

        emit Unstaked(
            _stakeAccount,
            _amount,
            totalStakedFor(_stakeAccount)
        );
    }







    function _burnFor(address _stakeAccount, uint256 _amount) internal {

        require(_amount > 0, ERROR_AMOUNT_ZERO);


        _modifyStakeBalance(_stakeAccount, _amount, false);


        _modifyTotalStaked(_amount, false);


        ERC20Burnable(address(stakingToken)).burn(_amount);










    function _modifyStakeBalance(address _accountAddress, uint256 _by, bool _increase) internal {
        uint256 currentInternalStake = accounts[_accountAddress].stakedHistory.getLast();

        uint256 newStake;
        if (_increase) {
            newStake = currentInternalStake.add(_by);
        } else {
            require(
                currentInternalStake >= _by,
                "Cannot decrease greater than current balance");
            newStake = currentInternalStake.sub(_by);
        }


        accounts[_accountAddress].stakedHistory.add(block.number.toUint64(), newStake);
    }






    function _modifyTotalStaked(uint256 _by, bool _increase) internal {
        uint256 currentStake = totalStaked();

        uint256 newStake;
        if (_increase) {
            newStake = currentStake.add(_by);
        } else {
            newStake = currentStake.sub(_by);
        }


        totalStakedHistory.add(block.number.toUint64(), newStake);
    }
}
