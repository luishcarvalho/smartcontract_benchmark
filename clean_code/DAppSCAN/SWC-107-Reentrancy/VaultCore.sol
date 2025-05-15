pragma solidity 0.5.11;











import "./VaultStorage.sol";
import { IMinMaxOracle } from "../interfaces/IMinMaxOracle.sol";
import { IRebaseHooks } from "../interfaces/IRebaseHooks.sol";
import { IVault } from "../interfaces/IVault.sol";

contract VaultCore is VaultStorage {
    uint256 constant MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;




    modifier whenNotRebasePaused() {
        require(!rebasePaused, "Rebasing paused");
        _;
    }




    modifier whenNotDepositPaused() {
        require(!depositPaused, "Deposits paused");
        _;
    }






    function mint(address _asset, uint256 _amount)
        external
        whenNotDepositPaused
    {
        require(assets[_asset].isSupported, "Asset is not supported");
        require(_amount > 0, "Amount must be greater than 0");

        uint256 price = IMinMaxOracle(priceProvider).priceMin(
            Helpers.getSymbol(_asset)
        );
        if (price > 1e8) {
            price = 1e8;
        }
        uint256 priceAdjustedDeposit = _amount.mulTruncateScale(
            price.scaleBy(int8(10)),
            10**Helpers.getDecimals(_asset)
        );


        if (priceAdjustedDeposit > rebaseThreshold && !rebasePaused) {
            rebase(true);
        }


        IERC20 asset = IERC20(_asset);
        asset.safeTransferFrom(msg.sender, address(this), _amount);


        oUSD.mint(msg.sender, priceAdjustedDeposit);
        emit Mint(msg.sender, priceAdjustedDeposit);

        if (priceAdjustedDeposit >= autoAllocateThreshold) {
            allocate();
        }
    }








    function mintMultiple(
        address[] calldata _assets,
        uint256[] calldata _amounts
    ) external whenNotDepositPaused {
        require(_assets.length == _amounts.length, "Parameter length mismatch");

        uint256 priceAdjustedTotal = 0;
        uint256[] memory assetPrices = _getAssetPrices(false);
        for (uint256 i = 0; i < allAssets.length; i++) {
            for (uint256 j = 0; j < _assets.length; j++) {
                if (_assets[j] == allAssets[i]) {
                    if (_amounts[j] > 0) {
                        uint256 assetDecimals = Helpers.getDecimals(
                            allAssets[i]
                        );
                        uint256 price = assetPrices[i];
                        if (price > 1e18) {
                            price = 1e18;
                        }
                        priceAdjustedTotal += _amounts[j].mulTruncateScale(
                            price,
                            10**assetDecimals
                        );
                    }
                }
            }
        }

        if (priceAdjustedTotal > rebaseThreshold && !rebasePaused) {
            rebase(true);
        }

        for (uint256 i = 0; i < _assets.length; i++) {
            IERC20 asset = IERC20(_assets[i]);
            asset.safeTransferFrom(msg.sender, address(this), _amounts[i]);
        }

        oUSD.mint(msg.sender, priceAdjustedTotal);
        emit Mint(msg.sender, priceAdjustedTotal);

        if (priceAdjustedTotal >= autoAllocateThreshold) {
            allocate();
        }
    }





    function redeem(uint256 _amount) public {
        if (_amount > rebaseThreshold && !rebasePaused) {
            rebase(false);
        }
        _redeem(_amount);
    }


    function _redeem(uint256 _amount) internal {
        require(_amount > 0, "Amount must be greater than 0");


        uint256[] memory outputs = _calculateRedeemOutputs(_amount);

        for (uint256 i = 0; i < allAssets.length; i++) {
            if (outputs[i] == 0) continue;

            IERC20 asset = IERC20(allAssets[i]);

            if (asset.balanceOf(address(this)) >= outputs[i]) {

                asset.safeTransfer(msg.sender, outputs[i]);
            } else {
                address strategyAddr = _selectWithdrawStrategyAddr(
                    allAssets[i],
                    outputs[i]
                );

                if (strategyAddr != address(0)) {

                    IStrategy strategy = IStrategy(strategyAddr);
                    strategy.withdraw(msg.sender, allAssets[i], outputs[i]);
                } else {

                    revert("Liquidity error");
                }
            }
        }

        oUSD.burn(msg.sender, _amount);





        if (_amount > rebaseThreshold && !rebasePaused) {
            rebase(true);
        }

        emit Redeem(msg.sender, _amount);
    }




    function redeemAll() external {

        if (oUSD.balanceOf(msg.sender) > rebaseThreshold && !rebasePaused) {
            rebase(false);
        }
        _redeem(oUSD.balanceOf(msg.sender));
    }





    function allocate() public {
        _allocate();
    }






    function _allocate() internal {
        uint256 vaultValue = _totalValueInVault();

        if (vaultValue == 0) return;
        uint256 strategiesValue = _totalValueInStrategies();

        uint256 totalValue = vaultValue + strategiesValue;




        uint256 vaultBufferModifier;
        if (strategiesValue == 0) {


            vaultBufferModifier = 1e18 - vaultBuffer;
        } else {
            vaultBufferModifier = vaultBuffer.mul(totalValue).div(vaultValue);
            if (1e18 > vaultBufferModifier) {


                vaultBufferModifier = 1e18 - vaultBufferModifier;
            } else {

                return;
            }
        }
        if (vaultBufferModifier == 0) return;



        for (uint256 i = 0; i < allAssets.length; i++) {
            IERC20 asset = IERC20(allAssets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            if (assetBalance == 0) continue;



            uint256 allocateAmount = assetBalance.mulTruncate(
                vaultBufferModifier
            );


            address depositStrategyAddr = _selectDepositStrategyAddr(
                address(asset),
                allocateAmount
            );

            if (depositStrategyAddr != address(0) && allocateAmount > 0) {
                IStrategy strategy = IStrategy(depositStrategyAddr);


                asset.safeTransfer(address(strategy), allocateAmount);
                strategy.deposit(address(asset), allocateAmount);
            }
        }


        for (uint256 i = 0; i < allStrategies.length; i++) {
            IStrategy strategy = IStrategy(allStrategies[i]);
            address rewardTokenAddress = strategy.rewardTokenAddress();
            if (rewardTokenAddress != address(0)) {
                uint256 liquidationThreshold = strategy
                    .rewardLiquidationThreshold();
                if (liquidationThreshold == 0) {

                    IVault(address(this)).harvest(allStrategies[i]);
                } else {




                    IERC20 rewardToken = IERC20(rewardTokenAddress);
                    uint256 rewardTokenAmount = rewardToken.balanceOf(
                        allStrategies[i]
                    );
                    if (rewardTokenAmount >= liquidationThreshold) {
                        IVault(address(this)).harvest(allStrategies[i]);
                    }
                }
            }
        }
    }





    function rebase() public whenNotRebasePaused returns (uint256) {
        rebase(true);
    }






    function rebase(bool sync) internal whenNotRebasePaused returns (uint256) {
        if (oUSD.totalSupply() == 0) return 0;
        uint256 oldTotalSupply = oUSD.totalSupply();
        uint256 newTotalSupply = _totalValue();

        if (newTotalSupply > oldTotalSupply) {
            oUSD.changeSupply(newTotalSupply);
            if (rebaseHooksAddr != address(0)) {
                IRebaseHooks(rebaseHooksAddr).postRebase(sync);
            }
        }
    }






    function totalValue() external view returns (uint256 value) {
        value = _totalValue();
    }






    function _totalValue() internal view returns (uint256 value) {
        return _totalValueInVault() + _totalValueInStrategies();
    }





    function _totalValueInVault() internal view returns (uint256 value) {
        value = 0;
        for (uint256 y = 0; y < allAssets.length; y++) {
            IERC20 asset = IERC20(allAssets[y]);
            uint256 assetDecimals = Helpers.getDecimals(allAssets[y]);
            uint256 balance = asset.balanceOf(address(this));
            if (balance > 0) {
                value += balance.scaleBy(int8(18 - assetDecimals));
            }
        }
    }





    function _totalValueInStrategies() internal view returns (uint256 value) {
        value = 0;
        for (uint256 i = 0; i < allStrategies.length; i++) {
            value += _totalValueInStrategy(allStrategies[i]);
        }
    }






    function _totalValueInStrategy(address _strategyAddr)
        internal
        view
        returns (uint256 value)
    {
        value = 0;
        IStrategy strategy = IStrategy(_strategyAddr);
        for (uint256 y = 0; y < allAssets.length; y++) {
            uint256 assetDecimals = Helpers.getDecimals(allAssets[y]);
            if (strategy.supportsAsset(allAssets[y])) {
                uint256 balance = strategy.checkBalance(allAssets[y]);
                if (balance > 0) {
                    value += balance.scaleBy(int8(18 - assetDecimals));
                }
            }
        }
    }








    function _strategyWeightDifference(
        address _strategyAddr,
        address _asset,
        uint256 _modAmount,
        bool deposit
    ) internal view returns (uint256 difference) {


        uint256 weight = strategies[_strategyAddr].targetWeight;
        if (weight == 0) return 0;
        uint256 assetDecimals = Helpers.getDecimals(_asset);
        difference =
            MAX_UINT -
            (
                deposit
                    ? _totalValueInStrategy(_strategyAddr).add(
                        _modAmount.scaleBy(int8(18 - assetDecimals))
                    )
                    : _totalValueInStrategy(_strategyAddr).sub(
                        _modAmount.scaleBy(int8(18 - assetDecimals))
                    )
            )
                .divPrecisely(weight);
    }






    function _selectDepositStrategyAddr(address _asset, uint256 depositAmount)
        internal
        view
        returns (address depositStrategyAddr)
    {
        depositStrategyAddr = address(0);
        uint256 maxDifference = 0;
        for (uint256 i = 0; i < allStrategies.length; i++) {
            IStrategy strategy = IStrategy(allStrategies[i]);
            if (strategy.supportsAsset(_asset)) {
                uint256 diff = _strategyWeightDifference(
                    allStrategies[i],
                    _asset,
                    depositAmount,
                    true
                );
                if (diff >= maxDifference) {
                    maxDifference = diff;
                    depositStrategyAddr = allStrategies[i];
                }
            }
        }
    }






    function _selectWithdrawStrategyAddr(address _asset, uint256 _amount)
        internal
        view
        returns (address withdrawStrategyAddr)
    {
        withdrawStrategyAddr = address(0);
        uint256 minDifference = MAX_UINT;
        for (uint256 i = 0; i < allStrategies.length; i++) {
            IStrategy strategy = IStrategy(allStrategies[i]);
            if (
                strategy.supportsAsset(_asset) &&
                strategy.checkBalance(_asset) > _amount
            ) {
                uint256 diff = _strategyWeightDifference(
                    allStrategies[i],
                    _asset,
                    _amount,
                    false
                );
                if (diff <= minDifference) {
                    minDifference = diff;
                    withdrawStrategyAddr = allStrategies[i];
                }
            }
        }
    }






    function checkBalance(address _asset) external view returns (uint256) {
        return _checkBalance(_asset);
    }






    function _checkBalance(address _asset)
        internal
        view
        returns (uint256 balance)
    {
        IERC20 asset = IERC20(_asset);
        balance = asset.balanceOf(address(this));
        for (uint256 i = 0; i < allStrategies.length; i++) {
            IStrategy strategy = IStrategy(allStrategies[i]);
            if (strategy.supportsAsset(_asset)) {
                balance += strategy.checkBalance(_asset);
            }
        }
    }





    function _checkBalance() internal view returns (uint256 balance) {
        balance = 0;
        for (uint256 i = 0; i < allAssets.length; i++) {
            uint256 assetDecimals = Helpers.getDecimals(allAssets[i]);
            balance += _checkBalance(allAssets[i]).scaleBy(
                int8(18 - assetDecimals)
            );
        }
    }





    function calculateRedeemOutputs(uint256 _amount)
        external
        returns (uint256[] memory)
    {
        return _calculateRedeemOutputs(_amount);
    }






    function _calculateRedeemOutputs(uint256 _amount)
        internal
        returns (uint256[] memory outputs)
    {





























        uint256 assetCount = getAssetCount();
        uint256[] memory assetPrices = _getAssetPrices(true);
        uint256[] memory assetBalances = new uint256[](assetCount);
        uint256[] memory assetDecimals = new uint256[](assetCount);
        uint256 totalBalance = 0;
        uint256 totalOutputRatio = 0;
        outputs = new uint256[](assetCount);


        if (redeemFeeBps > 0) {
            uint256 redeemFee = _amount.mul(redeemFeeBps).div(10000);
            _amount = _amount.sub(redeemFee);
        }



        for (uint256 i = 0; i < allAssets.length; i++) {
            uint256 balance = _checkBalance(allAssets[i]);
            uint256 decimals = Helpers.getDecimals(allAssets[i]);
            assetBalances[i] = balance;
            assetDecimals[i] = decimals;
            totalBalance += balance.scaleBy(int8(18 - decimals));
        }

        for (uint256 i = 0; i < allAssets.length; i++) {
            uint256 price = assetPrices[i];


            if (price < 1e18) {
                price = 1e18;
            }
            uint256 ratio = assetBalances[i]
                .scaleBy(int8(18 - assetDecimals[i]))
                .mul(price)
                .div(totalBalance);
            totalOutputRatio += ratio;
        }

        uint256 factor = _amount.divPrecisely(totalOutputRatio);
        for (uint256 i = 0; i < allAssets.length; i++) {
            outputs[i] = assetBalances[i].mul(factor).div(totalBalance);
        }
    }





    function _getAssetPrices(bool useMax)
        internal
        returns (uint256[] memory assetPrices)
    {
        assetPrices = new uint256[](getAssetCount());

        IMinMaxOracle oracle = IMinMaxOracle(priceProvider);



        for (uint256 i = 0; i < allAssets.length; i++) {
            string memory symbol = Helpers.getSymbol(allAssets[i]);

            if (useMax) {
                assetPrices[i] = oracle.priceMax(symbol).scaleBy(int8(18 - 8));
            } else {
                assetPrices[i] = oracle.priceMin(symbol).scaleBy(int8(18 - 8));
            }
        }
    }








    function getAssetCount() public view returns (uint256) {
        return allAssets.length;
    }




    function getAllAssets() external view returns (address[] memory) {
        return allAssets;
    }




    function getStrategyCount() public view returns (uint256) {
        return allStrategies.length;
    }

    function isSupportedAsset(address _asset) external view returns (bool) {
        return assets[_asset].isSupported;
    }





    function() external payable {
        bytes32 slot = adminImplPosition;
        assembly {



            calldatacopy(0, 0, calldatasize)



            let result := delegatecall(gas, sload(slot), 0, calldatasize, 0, 0)


            returndatacopy(0, 0, returndatasize)

            switch result

                case 0 {
                    revert(0, returndatasize)
                }
                default {
                    return(0, returndatasize)
                }
        }
    }
}
