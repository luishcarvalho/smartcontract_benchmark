
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {VaultAPI} from "./BaseStrategy.sol";

interface RegistryAPI {
    function governance() external view returns (address);

    function latestVault(address token) external view returns (address);

    function numVaults(address token) external view returns (uint256);

    function vaults(address token, uint256 deploymentId) external view returns (address);
}

abstract contract BaseWrapper {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;


    VaultAPI[] private _cachedVaults;

    RegistryAPI public registry;


    uint256 constant UNLIMITED_APPROVAL = type(uint256).max;


    uint256 constant DEPOSIT_EVERYTHING = type(uint256).max;
    uint256 constant WITHDRAW_EVERYTHING = type(uint256).max;
    uint256 constant MIGRATE_EVERYTHING = type(uint256).max;

    uint256 constant UNCAPPED_DEPOSITS = type(uint256).max;

    constructor(address _token, address _registry) public {
        token = IERC20(_token);

        registry = RegistryAPI(_registry);
    }

    function setRegistry(address _registry) external {
        require(msg.sender == registry.governance());

        registry = RegistryAPI(_registry);
    }

    function bestVault() public virtual view returns (VaultAPI) {
        return VaultAPI(registry.latestVault(address(token)));
    }

    function allVaults() public virtual view returns (VaultAPI[] memory) {
        uint256 cache_length = _cachedVaults.length;
        uint256 num_vaults = registry.numVaults(address(token));


        if (cache_length == num_vaults) {
            return _cachedVaults;
        }

        VaultAPI[] memory vaults = new VaultAPI[](num_vaults);

        for (uint256 vault_id = 0; vault_id < cache_length; vault_id++) {
            vaults[vault_id] = _cachedVaults[vault_id];
        }

        for (uint256 vault_id = cache_length; vault_id < num_vaults; vault_id++) {
            vaults[vault_id] = VaultAPI(registry.vaults(address(token), vault_id));
        }

        return vaults;
    }

    function _updateVaultCache(VaultAPI[] memory vaults) internal {
        if (vaults.length > _cachedVaults.length) {
            _cachedVaults = vaults;
        }
    }

    function totalVaultBalance(address account) public view returns (uint256 balance) {
        VaultAPI[] memory vaults = allVaults();

        for (uint256 id = 0; id < vaults.length; id++) {
            balance = balance.add(vaults[id].balanceOf(account).mul(vaults[id].pricePerShare()).div(10**uint256(vaults[id].decimals())));
        }
    }

    function totalAssets() public view returns (uint256 assets) {
        VaultAPI[] memory vaults = allVaults();

        for (uint256 id = 0; id < vaults.length; id++) {
            assets = assets.add(vaults[id].totalAssets());
        }
    }

    function _deposit(
        address depositor,
        address receiver,
        uint256 amount,
        bool pullFunds
    ) internal returns (uint256 deposited) {
        VaultAPI _bestVault = bestVault();

        if (pullFunds) {
            token.safeTransferFrom(depositor, address(this), amount);
        }

        if (token.allowance(address(this), address(_bestVault)) < amount) {
            token.safeApprove(address(_bestVault), UNLIMITED_APPROVAL);
        }





        uint256 beforeBal = token.balanceOf(address(this));
        if (receiver != address(this)) {
            _bestVault.deposit(amount, receiver);
        } else if (amount != DEPOSIT_EVERYTHING) {
            _bestVault.deposit(amount);
        } else {
            _bestVault.deposit();
        }

        uint256 afterBal = token.balanceOf(address(this));
        deposited = beforeBal.sub(afterBal);



        if (depositor != address(this) && afterBal > 0) token.transfer(depositor, afterBal);
    }

    function _withdraw(
        address sender,
        address receiver,
        uint256 amount,
        bool withdrawFromBest
    ) internal returns (uint256 withdrawn) {
        VaultAPI _bestVault = bestVault();

        VaultAPI[] memory vaults = allVaults();
        _updateVaultCache(vaults);


        for (uint256 id = 0; id < vaults.length; id++) {
            if (!withdrawFromBest && vaults[id] == _bestVault) {
                continue;
            }


            uint256 availableShares = vaults[id].balanceOf(sender);



            if (sender != address(this)) {
                availableShares = Math.min(availableShares, vaults[id].allowance(sender, address(this)));
            }


            availableShares = Math.min(availableShares, vaults[id].maxAvailableShares());

            if (availableShares > 0) {



                if (sender != address(this)) vaults[id].transferFrom(sender, address(this), availableShares);

                if (amount != WITHDRAW_EVERYTHING) {

                    uint256 estimatedShares = amount
                        .sub(withdrawn)
                        .mul(10**uint256(vaults[id].decimals()))
                        .div(vaults[id].pricePerShare());


                    uint256 shares = Math.min(estimatedShares, availableShares);
                    withdrawn = withdrawn.add(vaults[id].withdraw(shares));
                } else {
                    withdrawn = withdrawn.add(vaults[id].withdraw());
                }



                if (amount <= withdrawn) break;
            }
        }



        if (withdrawn > amount) {

            if (token.allowance(address(this), address(_bestVault)) < withdrawn.sub(amount)) {
                token.safeApprove(address(_bestVault), UNLIMITED_APPROVAL);
            }

            _bestVault.deposit(withdrawn.sub(amount), sender);
            withdrawn = amount;
        }


        if (receiver != address(this)) token.safeTransfer(receiver, withdrawn);
    }

    function _migrate(address account) internal returns (uint256) {
        return _migrate(account, MIGRATE_EVERYTHING);
    }

    function _migrate(address account, uint256 amount) internal returns (uint256) {

        return _migrate(account, amount, 0);
    }

    function _migrate(
        address account,
        uint256 amount,
        uint256 maxMigrationLoss
    ) internal returns (uint256 migrated) {
        VaultAPI _bestVault = bestVault();


        uint256 _depositLimit = _bestVault.depositLimit();
        uint256 _totalAssets = _bestVault.totalAssets();
        if (_depositLimit <= _totalAssets) return 0;

        uint256 _amount = amount;
        if (_depositLimit < UNCAPPED_DEPOSITS && _amount < WITHDRAW_EVERYTHING) {

            uint256 _depositLeft = _depositLimit.sub(_totalAssets);
            if (_amount > _depositLeft) _amount = _depositLeft;
        }

        if (_amount > 0) {

            uint256 withdrawn = _withdraw(account, address(this), _amount, false);
            if (withdrawn == 0) return 0;


            migrated = _deposit(address(this), account, withdrawn, false);



            require(withdrawn.sub(migrated) <= maxMigrationLoss);
        }
    }
}
