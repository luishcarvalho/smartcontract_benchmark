

















pragma solidity 0.4.24;

import "../../utils/Ownable/Ownable.sol";
import "../../utils/LibBytes/LibBytes.sol";
import "./mixins/MAssetProxyDispatcher.sol";
import "../AssetProxy/interfaces/IAssetProxy.sol";


contract MixinAssetProxyDispatcher is
    Ownable,
    MAssetProxyDispatcher
{

    using LibBytes for bytes;


    mapping (bytes4 => IAssetProxy) public assetProxies;




    function registerAssetProxy(address assetProxy)
        external
        onlyOwner
    {
        IAssetProxy assetProxyContract = IAssetProxy(assetProxy);


        bytes4 assetProxyId = assetProxyContract.getProxyId();
        address currentAssetProxy = assetProxies[assetProxyId];
        require(
            currentAssetProxy == address(0),
            "ASSET_PROXY_ALREADY_EXISTS"
        );


        assetProxies[assetProxyId] = assetProxyContract;
        emit AssetProxyRegistered(
            assetProxyId,
            assetProxy
        );
    }




    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address)
    {
        return assetProxies[assetProxyId];
    }






    function dispatchTransferFrom(
        bytes memory assetData,
        address from,
        address to,
        uint256 amount
    )
        internal
    {

        if (amount > 0) {

            require(
                assetData.length > 3,
                "LENGTH_GREATER_THAN_3_REQUIRED"
            );


            bytes4 assetProxyId;
            assembly {
                assetProxyId := and(mload(
                    add(assetData, 32)),
                    0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
                )
            }
            address assetProxy = assetProxies[assetProxyId];


            require(
                assetProxy != address(0),
                "ASSET_PROXY_DOES_NOT_EXIST"
            );
















            assembly {


                let cdStart := mload(64)



                let dataAreaLength := and(add(mload(assetData), 63), 0xFFFFFFFFFFFE0)

                let cdEnd := add(cdStart, add(132, dataAreaLength))





                mstore(cdStart, 0xa85e59e400000000000000000000000000000000000000000000000000000000)






                mstore(add(cdStart, 4), 128)
                mstore(add(cdStart, 36), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(cdStart, 68), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(cdStart, 100), amount)



                let dataArea := add(cdStart, 132)

                for {} lt(dataArea, cdEnd) {} {
                    mstore(dataArea, mload(assetData))
                    dataArea := add(dataArea, 32)
                    assetData := add(assetData, 32)
                }


                let success := call(
                    gas,
                    assetProxy,
                    0,
                    cdStart,
                    sub(cdEnd, cdStart),
                    cdStart,
                    512
                )
                if iszero(success) {
                    revert(cdStart, returndatasize())
                }
            }
        }
    }
}
