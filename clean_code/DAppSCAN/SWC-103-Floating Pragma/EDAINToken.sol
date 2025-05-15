

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";

import "./EDAINStaking.sol";

contract EDAINToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20SnapshotUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC20CappedUpgradeable,
    EDAINStaking
{
    using SafeMathUpgradeable for uint256;

    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");









    function initialize(uint256 initialMint) public initializer {
        __ERC20_init("EDAIN", "EAI");
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __AccessControl_init();
        __Pausable_init();
        __EDAINStaking_init();
        __ERC20Capped_init(47e7 * 10**decimals());

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SNAPSHOT_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        _mint(msg.sender, initialMint * 10**decimals());
    }




    function snapshot() external onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }




    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }




    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }






    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }






    function _mint(address account, uint256 amount)
        internal
        virtual
        override(ERC20Upgradeable, ERC20CappedUpgradeable)
        whenNotPaused
    {
        require(
            ERC20Upgradeable.totalSupply() + amount <= cap(),
            "ERC20Capped: cap exceeded"
        );
        super._mint(account, amount);
    }







    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }





    function stake(uint256 amount) external {
        require(
            msg.sender != address(0x00),
            "ERC20: Add stake from zero address"
        );
        require(
            amount < balanceOf(msg.sender),
            "ERC20: Balance of the sender is lower than the staked amount"
        );

        _burn(msg.sender, amount);
        _stake(amount);
    }






    function withdrawStake(uint256 amount, uint256 stake_index) external {
        uint256 amount_to_mint = _withdrawStake(amount, stake_index);

        _mint(msg.sender, amount_to_mint);
    }
}
