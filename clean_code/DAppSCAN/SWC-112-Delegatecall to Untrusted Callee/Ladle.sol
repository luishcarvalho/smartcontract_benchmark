
pragma solidity 0.8.6;
import "@yield-protocol/vault-interfaces/IFYToken.sol";
import "@yield-protocol/vault-interfaces/IJoin.sol";
import "@yield-protocol/vault-interfaces/ICauldron.sol";
import "@yield-protocol/vault-interfaces/IOracle.sol";
import "@yield-protocol/vault-interfaces/DataTypes.sol";
import "@yield-protocol/yieldspace-interfaces/IPool.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC20.sol";
import "@yield-protocol/utils-v2/contracts/token/IERC2612.sol";
import "dss-interfaces/src/dss/DaiAbstract.sol";
import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "@yield-protocol/utils-v2/contracts/token/TransferHelper.sol";
import "@yield-protocol/utils-v2/contracts/math/WMul.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU256U128.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU256I128.sol";
import "@yield-protocol/utils-v2/contracts/cast/CastU128I128.sol";
import "./LadleStorage.sol";



contract Ladle is LadleStorage, AccessControl() {
    using WMul for uint256;
    using CastU256U128 for uint256;
    using CastU256I128 for uint256;
    using CastU128I128 for uint128;
    using TransferHelper for IERC20;
    using TransferHelper for address payable;

    constructor (ICauldron cauldron, IWETH9 weth) LadleStorage(cauldron, weth) { }




    function getVault(bytes12 vaultId_)
        internal view
        returns (bytes12 vaultId, DataTypes.Vault memory vault)
    {
        if (vaultId_ == bytes12(0)) {
            require (cachedVaultId != bytes12(0), "Vault not cached");
            vaultId = cachedVaultId;
        } else {
            vaultId = vaultId_;
        }
        vault = cauldron.vaults(vaultId);
        require (vault.owner == msg.sender, "Only vault owner");
    }

    function getSeries(bytes6 seriesId)
        internal view returns(DataTypes.Series memory series)
    {
        series = cauldron.series(seriesId);
        require (series.fyToken != IFYToken(address(0)), "Series not found");
    }


    function getJoin(bytes6 assetId)
        internal view returns(IJoin join)
    {
        join = joins[assetId];
        require (join != IJoin(address(0)), "Join not found");
    }


    function getPool(bytes6 seriesId)
        internal view returns(IPool pool)
    {
        pool = pools[seriesId];
        require (pool != IPool(address(0)), "Pool not found");
    }




    function addIntegration(address integration, bool set)
        external
        auth
    {
        _addIntegration(integration, set);
    }


    function _addIntegration(address integration, bool set)
        private
    {
        integrations[integration] = set;
        emit IntegrationAdded(integration, set);
    }


    function addToken(address token, bool set)
        external
        auth
    {
        _addToken(token, set);
    }



    function _addToken(address token, bool set)
        private
    {
        tokens[token] = set;
        emit TokenAdded(token, set);
    }




    function addJoin(bytes6 assetId, IJoin join)
        external
        auth
    {
        address asset = cauldron.assets(assetId);
        require (asset != address(0), "Asset not found");
        require (join.asset() == asset, "Mismatched asset and join");
        joins[assetId] = join;

        bool set = (join != IJoin(address(0))) ? true : false;
        _addToken(asset, set);
        emit JoinAdded(assetId, address(join));
    }



    function addPool(bytes6 seriesId, IPool pool)
        external
        auth
    {
        IFYToken fyToken = getSeries(seriesId).fyToken;
        require (fyToken == pool.fyToken(), "Mismatched pool fyToken and series");
        require (fyToken.underlying() == address(pool.base()), "Mismatched pool base and series");
        pools[seriesId] = pool;

        bool set = (pool != IPool(address(0))) ? true : false;
        _addToken(address(fyToken), set);
        _addToken(address(pool), set);
        _addIntegration(address(pool), set);

        emit PoolAdded(seriesId, address(pool));
    }



    function addModule(address module, bool set)
        external
        auth
    {
        modules[module] = set;
        emit ModuleAdded(module, set);
    }


    function setFee(uint256 fee)
        external
        auth
    {
        borrowingFee = fee;
        emit FeeSet(fee);
    }





    function batch(bytes[] calldata calls) external payable returns(bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint256 i; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
            results[i] = result;
        }


        cachedVaultId = bytes12(0);
    }


    function route(address integration, bytes calldata data)
        external payable
        returns (bytes memory result)
    {
        require(integrations[integration], "Unknown integration");
        return router.route(integration, data);
    }





    function moduleCall(address module, bytes calldata data)
        external payable
        returns (bytes memory result)
    {
        require (modules[module], "Unregistered module");
        bool success;
        (success, result) = module.delegatecall(data);
        if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
    }




    function forwardPermit(IERC2612 token, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external payable
    {
        require(tokens[address(token)], "Unknown token");
        token.permit(msg.sender, spender, amount, deadline, v, r, s);
    }


    function forwardDaiPermit(DaiAbstract token, address spender, uint256 nonce, uint256 deadline, bool allowed, uint8 v, bytes32 r, bytes32 s)
        external payable
    {
        require(tokens[address(token)], "Unknown token");
        token.permit(msg.sender, spender, nonce, deadline, allowed, v, r, s);
    }


    function transfer(IERC20 token, address receiver, uint128 wad)
        external payable
    {
        require(tokens[address(token)], "Unknown token");
        token.safeTransferFrom(msg.sender, receiver, wad);
    }


    function retrieve(IERC20 token, address to)
        external payable
        returns (uint256 amount)
    {
        require(tokens[address(token)], "Unknown token");
        amount = token.balanceOf(address(this));
        token.safeTransfer(to, amount);
    }


    receive() external payable {
        require (msg.sender == address(weth), "Only receive from WETH");
    }




    function joinEther(bytes6 etherId)
        external payable
        returns (uint256 ethTransferred)
    {
        ethTransferred = address(this).balance;
        IJoin wethJoin = getJoin(etherId);
        weth.deposit{ value: ethTransferred }();
        IERC20(address(weth)).safeTransfer(address(wethJoin), ethTransferred);
    }



    function exitEther(address payable to)
        external payable
        returns (uint256 ethTransferred)
    {
        ethTransferred = weth.balanceOf(address(this));
        weth.withdraw(ethTransferred);
        to.safeTransferETH(ethTransferred);
    }




    function _generateVaultId(uint8 salt) private view returns (bytes12) {
        return bytes12(keccak256(abi.encodePacked(msg.sender, block.timestamp, salt)));
    }


    function build(bytes6 seriesId, bytes6 ilkId, uint8 salt)
        external payable
        returns(bytes12, DataTypes.Vault memory)
    {
        return _build(seriesId, ilkId, salt);
    }


    function _build(bytes6 seriesId, bytes6 ilkId, uint8 salt)
        private
        returns(bytes12 vaultId, DataTypes.Vault memory vault)
    {
        vaultId = _generateVaultId(salt);
        while (cauldron.vaults(vaultId).seriesId != bytes6(0)) vaultId = _generateVaultId(++salt);
        vault = cauldron.build(msg.sender, vaultId, seriesId, ilkId);

        cachedVaultId = vaultId;
    }


    function tweak(bytes12 vaultId_, bytes6 seriesId, bytes6 ilkId)
        external payable
        returns(DataTypes.Vault memory vault)
    {
        (bytes12 vaultId, ) = getVault(vaultId_);

        vault = cauldron.tweak(vaultId, seriesId, ilkId);
    }


    function give(bytes12 vaultId_, address receiver)
        external payable
        returns(DataTypes.Vault memory vault)
    {
        (bytes12 vaultId, ) = getVault(vaultId_);
        vault = cauldron.give(vaultId, receiver);
    }


    function destroy(bytes12 vaultId_)
        external payable
    {
        (bytes12 vaultId, ) = getVault(vaultId_);
        cauldron.destroy(vaultId);
    }




    function stir(bytes12 from, bytes12 to, uint128 ink, uint128 art)
        external payable
    {
        if (ink > 0) require (cauldron.vaults(from).owner == msg.sender, "Only origin vault owner");
        if (art > 0) require (cauldron.vaults(to).owner == msg.sender, "Only destination vault owner");
        cauldron.stir(from, to, ink, art);
    }




    function _pour(bytes12 vaultId, DataTypes.Vault memory vault, address to, int128 ink, int128 art)
        private
    {
        DataTypes.Series memory series;
        if (art != 0) series = getSeries(vault.seriesId);

        int128 fee;
        if (art > 0 && vault.ilkId != series.baseId && borrowingFee != 0)
            fee = ((series.maturity - block.timestamp) * uint256(int256(art)).wmul(borrowingFee)).i128();


        cauldron.pour(vaultId, ink, art + fee);


        if (ink != 0) {
            IJoin ilkJoin = getJoin(vault.ilkId);
            if (ink > 0) ilkJoin.join(vault.owner, uint128(ink));
            if (ink < 0) ilkJoin.exit(to, uint128(-ink));
        }


        if (art != 0) {
            if (art > 0) series.fyToken.mint(to, uint128(art));
            else series.fyToken.burn(msg.sender, uint128(-art));
        }
    }




    function pour(bytes12 vaultId_, address to, int128 ink, int128 art)
        external payable
    {
        (bytes12 vaultId, DataTypes.Vault memory vault) = getVault(vaultId_);
        _pour(vaultId, vault, to, ink, art);
    }




    function serve(bytes12 vaultId_, address to, uint128 ink, uint128 base, uint128 max)
        external payable
        returns (uint128 art)
    {
        (bytes12 vaultId, DataTypes.Vault memory vault) = getVault(vaultId_);
        IPool pool = getPool(vault.seriesId);

        art = pool.buyBasePreview(base);
        _pour(vaultId, vault, address(pool), ink.i128(), art.i128());
        pool.buyBase(to, base, max);
    }






    function close(bytes12 vaultId_, address to, int128 ink, int128 art)
        external payable
        returns (uint128 base)
    {
        require (art < 0, "Only repay debt");


        (bytes12 vaultId, DataTypes.Vault memory vault) = getVault(vaultId_);
        DataTypes.Series memory series = getSeries(vault.seriesId);
        base = cauldron.debtToBase(vault.seriesId, uint128(-art));


        cauldron.pour(vaultId, ink, art);


        if (ink != 0) {
            IJoin ilkJoin = getJoin(vault.ilkId);
            if (ink > 0) ilkJoin.join(vault.owner, uint128(ink));
            if (ink < 0) ilkJoin.exit(to, uint128(-ink));
        }


        IJoin baseJoin = getJoin(series.baseId);
        baseJoin.join(msg.sender, base);
    }




    function repay(bytes12 vaultId_, address to, int128 ink, uint128 min)
        external payable
        returns (uint128 art)
    {
        (bytes12 vaultId, DataTypes.Vault memory vault) = getVault(vaultId_);
        DataTypes.Series memory series = getSeries(vault.seriesId);
        IPool pool = getPool(vault.seriesId);

        art = pool.sellBase(address(series.fyToken), min);
        _pour(vaultId, vault, to, ink, -(art.i128()));
    }




    function repayVault(bytes12 vaultId_, address to, int128 ink, uint128 max)
        external payable
        returns (uint128 base)
    {
        (bytes12 vaultId, DataTypes.Vault memory vault) = getVault(vaultId_);
        DataTypes.Series memory series = getSeries(vault.seriesId);
        IPool pool = getPool(vault.seriesId);

        DataTypes.Balances memory balances = cauldron.balances(vaultId);
        base = pool.buyFYToken(address(series.fyToken), balances.art, max);
        _pour(vaultId, vault, to, ink, -(balances.art.i128()));
        pool.retrieveBase(msg.sender);
    }


    function roll(bytes12 vaultId_, bytes6 newSeriesId, uint8 loan, uint128 max)
        external payable
        returns (DataTypes.Vault memory vault, uint128 newDebt)
    {
        bytes12 vaultId;
        (vaultId, vault) = getVault(vaultId_);
        DataTypes.Balances memory balances = cauldron.balances(vaultId);
        DataTypes.Series memory series = getSeries(vault.seriesId);
        DataTypes.Series memory newSeries = getSeries(newSeriesId);


        {
            IPool pool = getPool(newSeriesId);
            IFYToken fyToken = IFYToken(newSeries.fyToken);
            IJoin baseJoin = getJoin(series.baseId);


            uint128 base = cauldron.debtToBase(vault.seriesId, balances.art);


            fyToken.mint(address(pool), base * loan);


            newDebt = pool.buyBase(address(baseJoin), base, max);
            baseJoin.join(address(baseJoin), base);

            pool.retrieveFYToken(address(fyToken));
            fyToken.burn(address(fyToken), (base * loan) - newDebt);
        }

        if (vault.ilkId != newSeries.baseId && borrowingFee != 0)
            newDebt += ((newSeries.maturity - block.timestamp) * uint256(newDebt).wmul(borrowingFee)).u128();

        (vault,) = cauldron.roll(vaultId, newSeriesId, newDebt.i128() - balances.art.i128());

        return (vault, newDebt);
    }




    function repayFromLadle(bytes12 vaultId_, address to)
        external payable
        returns (uint256 repaid)
    {
        (bytes12 vaultId, DataTypes.Vault memory vault) = getVault(vaultId_);
        DataTypes.Series memory series = getSeries(vault.seriesId);
        DataTypes.Balances memory balances = cauldron.balances(vaultId);

        uint256 amount = series.fyToken.balanceOf(address(this));
        if (amount == 0 || balances.art == 0) return 0;

        repaid = amount <= balances.art ? amount : balances.art;


        cauldron.pour(vaultId, 0, -(repaid.i128()));
        series.fyToken.burn(address(this), repaid);


        if (repaid < amount) IERC20(address(series.fyToken)).safeTransfer(to, repaid - amount);
    }


    function closeFromLadle(bytes12 vaultId_, address to)
        external payable
        returns (uint256 repaid)
    {
        (bytes12 vaultId, DataTypes.Vault memory vault) = getVault(vaultId_);
        DataTypes.Series memory series = getSeries(vault.seriesId);
        DataTypes.Balances memory balances = cauldron.balances(vaultId);

        IERC20 base = IERC20(cauldron.assets(series.baseId));
        uint256 amount = base.balanceOf(address(this));
        if (amount == 0 || balances.art == 0) return 0;

        uint256 debtInBase = cauldron.debtToBase(vault.seriesId, balances.art);
        uint128 repaidInBase = ((amount <= debtInBase) ? amount : debtInBase).u128();
        repaid = (repaidInBase == debtInBase) ? balances.art : cauldron.debtFromBase(vault.seriesId, repaidInBase);


        cauldron.pour(vaultId, 0, -(repaid.i128()));


        IJoin baseJoin = getJoin(series.baseId);
        base.safeTransfer(address(baseJoin), repaidInBase);
        baseJoin.join(address(this), repaidInBase);


        if (repaidInBase < amount) base.safeTransfer(to, repaidInBase - amount);
    }



    function redeem(bytes6 seriesId, address to, uint256 wad)
        external payable
        returns (uint256)
    {
        IFYToken fyToken = getSeries(seriesId).fyToken;
        return fyToken.redeem(to, wad != 0 ? wad : fyToken.balanceOf(address(this)));
    }

}
