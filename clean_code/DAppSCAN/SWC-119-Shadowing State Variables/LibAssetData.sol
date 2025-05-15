

















pragma solidity ^0.5.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "@0x/contracts-exchange/contracts/src/interfaces/IExchange.sol";
import "@0x/contracts-asset-proxy/contracts/src/interfaces/IAssetData.sol";
import "@0x/contracts-asset-proxy/contracts/src/interfaces/IAssetProxy.sol";
import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc721/contracts/src/interfaces/IERC721Token.sol";
import "@0x/contracts-erc1155/contracts/src/interfaces/IERC1155.sol";


contract LibAssetData {


    uint256 constant internal _MAX_UINT256 = uint256(-1);

    using LibBytes for bytes;



    IExchange internal _EXCHANGE;
    address internal _ERC20_PROXY_ADDRESS;
    address internal _ERC721_PROXY_ADDRESS;
    address internal _ERC1155_PROXY_ADDRESS;
    address internal _STATIC_CALL_PROXY_ADDRESS;


    constructor (address _exchange)
        public
    {
        _EXCHANGE = IExchange(_exchange);
        _ERC20_PROXY_ADDRESS = _EXCHANGE.getAssetProxy(IAssetData(address(0)).ERC20Token.selector);
        _ERC721_PROXY_ADDRESS = _EXCHANGE.getAssetProxy(IAssetData(address(0)).ERC721Token.selector);
        _ERC1155_PROXY_ADDRESS = _EXCHANGE.getAssetProxy(IAssetData(address(0)).ERC1155Assets.selector);
        _STATIC_CALL_PROXY_ADDRESS = _EXCHANGE.getAssetProxy(IAssetData(address(0)).StaticCall.selector);
    }








    function getBalance(address ownerAddress, bytes memory assetData)
        public
        view
        returns (uint256 balance)
    {

        bytes4 assetProxyId = assetData.readBytes4(0);

        if (assetProxyId == IAssetData(address(0)).ERC20Token.selector) {

            address tokenAddress = assetData.readAddress(16);


            bytes memory balanceOfData = abi.encodeWithSelector(
                IERC20Token(address(0)).balanceOf.selector,
                ownerAddress
            );


            (bool success, bytes memory returnData) = tokenAddress.staticcall(balanceOfData);
            balance = success && returnData.length == 32 ? returnData.readUint256(0) : 0;
        } else if (assetProxyId == IAssetData(address(0)).ERC721Token.selector) {

            (, address tokenAddress, uint256 tokenId) = decodeERC721AssetData(assetData);


            bytes memory ownerOfCalldata = abi.encodeWithSelector(
                IERC721Token(address(0)).ownerOf.selector,
                tokenId
            );

            (bool success, bytes memory returnData) = tokenAddress.staticcall(ownerOfCalldata);
            address currentOwnerAddress = (success && returnData.length == 32) ? returnData.readAddress(12) : address(0);
            balance = currentOwnerAddress == ownerAddress ? 1 : 0;
        } else if (assetProxyId == IAssetData(address(0)).ERC1155Assets.selector) {

            (, address tokenAddress, uint256[] memory tokenIds, uint256[] memory tokenValues,) = decodeERC1155AssetData(assetData);

            uint256 length = tokenIds.length;
            for (uint256 i = 0; i != length; i++) {

                bytes memory balanceOfData = abi.encodeWithSelector(
                    IERC1155(address(0)).balanceOf.selector,
                    ownerAddress,
                    tokenIds[i]
                );


                (bool success, bytes memory returnData) = tokenAddress.staticcall(balanceOfData);
                uint256 totalBalance = success && returnData.length == 32 ? returnData.readUint256(0) : 0;


                uint256 scaledBalance = totalBalance / tokenValues[i];
                if (scaledBalance < balance || balance == 0) {
                    balance = scaledBalance;
                }
            }
        } else if (assetProxyId == IAssetData(address(0)).StaticCall.selector) {

            bytes memory transferFromData = abi.encodeWithSelector(
                IAssetProxy(address(0)).transferFrom.selector,
                assetData,
                address(0),
                address(0),
                0
            );


            (bool success,) = _STATIC_CALL_PROXY_ADDRESS.staticcall(transferFromData);


            balance = success ? _MAX_UINT256 : 0;
        } else if (assetProxyId == IAssetData(address(0)).MultiAsset.selector) {

            (, uint256[] memory assetAmounts, bytes[] memory nestedAssetData) = decodeMultiAssetData(assetData);

            uint256 length = nestedAssetData.length;
            for (uint256 i = 0; i != length; i++) {

                uint256 totalBalance = getBalance(ownerAddress, nestedAssetData[i]);


                uint256 scaledBalance = totalBalance / assetAmounts[i];
                if (scaledBalance < balance || balance == 0) {
                    balance = scaledBalance;
                }
            }
        }


        return balance;
    }






    function getBatchBalances(address ownerAddress, bytes[] memory assetData)
        public
        view
        returns (uint256[] memory balances)
    {
        uint256 length = assetData.length;
        balances = new uint256[](length);
        for (uint256 i = 0; i != length; i++) {
            balances[i] = getBalance(ownerAddress, assetData[i]);
        }
        return balances;
    }









    function getAssetProxyAllowance(address ownerAddress, bytes memory assetData)
        public
        view
        returns (uint256 allowance)
    {

        bytes4 assetProxyId = assetData.readBytes4(0);

        if (assetProxyId == IAssetData(address(0)).MultiAsset.selector) {

            (, uint256[] memory amounts, bytes[] memory nestedAssetData) = decodeMultiAssetData(assetData);

            uint256 length = nestedAssetData.length;
            for (uint256 i = 0; i != length; i++) {

                uint256 totalAllowance = getAssetProxyAllowance(ownerAddress, nestedAssetData[i]);


                uint256 scaledAllowance = totalAllowance / amounts[i];
                if (scaledAllowance < allowance || allowance == 0) {
                    allowance = scaledAllowance;
                }
            }
            return allowance;
        }

        if (assetProxyId == IAssetData(address(0)).ERC20Token.selector) {

            address tokenAddress = assetData.readAddress(16);


            bytes memory allowanceData = abi.encodeWithSelector(
                IERC20Token(address(0)).allowance.selector,
                ownerAddress,
                _ERC20_PROXY_ADDRESS
            );


            (bool success, bytes memory returnData) = tokenAddress.staticcall(allowanceData);
            allowance = success && returnData.length == 32 ? returnData.readUint256(0) : 0;
        } else if (assetProxyId == IAssetData(address(0)).ERC721Token.selector) {

            (, address tokenAddress, uint256 tokenId) = decodeERC721AssetData(assetData);


            bytes memory isApprovedForAllData = abi.encodeWithSelector(
                IERC721Token(address(0)).isApprovedForAll.selector,
                ownerAddress,
                _ERC721_PROXY_ADDRESS
            );

            (bool success, bytes memory returnData) = tokenAddress.staticcall(isApprovedForAllData);


            if (!success || returnData.length != 32 || returnData.readUint256(0) != 1) {

                bytes memory getApprovedData = abi.encodeWithSelector(IERC721Token(address(0)).getApproved.selector, tokenId);
                (success, returnData) = tokenAddress.staticcall(getApprovedData);


                allowance = success && returnData.length == 32 && returnData.readAddress(12) == _ERC721_PROXY_ADDRESS ? 1 : 0;
            } else {

                allowance = _MAX_UINT256;
            }
        } else if (assetProxyId == IAssetData(address(0)).ERC1155Assets.selector) {

            (, address tokenAddress, , , ) = decodeERC1155AssetData(assetData);


            bytes memory isApprovedForAllData = abi.encodeWithSelector(
                IERC1155(address(0)).isApprovedForAll.selector,
                ownerAddress,
                _ERC1155_PROXY_ADDRESS
            );


            (bool success, bytes memory returnData) = tokenAddress.staticcall(isApprovedForAllData);
            allowance = success && returnData.length == 32 && returnData.readUint256(0) == 1 ? _MAX_UINT256 : 0;
        } else if (assetProxyId == IAssetData(address(0)).StaticCall.selector) {

            allowance = _MAX_UINT256;
        }


        return allowance;
    }






    function getBatchAssetProxyAllowances(address ownerAddress, bytes[] memory assetData)
        public
        view
        returns (uint256[] memory allowances)
    {
        uint256 length = assetData.length;
        allowances = new uint256[](length);
        for (uint256 i = 0; i != length; i++) {
            allowances[i] = getAssetProxyAllowance(ownerAddress, assetData[i]);
        }
        return allowances;
    }






    function getBalanceAndAssetProxyAllowance(address ownerAddress, bytes memory assetData)
        public
        view
        returns (uint256 balance, uint256 allowance)
    {
        balance = getBalance(ownerAddress, assetData);
        allowance = getAssetProxyAllowance(ownerAddress, assetData);
        return (balance, allowance);
    }







    function getBatchBalancesAndAssetProxyAllowances(address ownerAddress, bytes[] memory assetData)
        public
        view
        returns (uint256[] memory balances, uint256[] memory allowances)
    {
        balances = getBatchBalances(ownerAddress, assetData);
        allowances = getBatchAssetProxyAllowances(ownerAddress, assetData);
        return (balances, allowances);
    }




    function encodeERC20AssetData(address tokenAddress)
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(IAssetData(address(0)).ERC20Token.selector, tokenAddress);
        return assetData;
    }





    function decodeERC20AssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).ERC20Token.selector,
            "WRONG_PROXY_ID"
        );

        tokenAddress = assetData.readAddress(16);
        return (assetProxyId, tokenAddress);
    }





    function encodeERC721AssetData(address tokenAddress, uint256 tokenId)
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(
            IAssetData(address(0)).ERC721Token.selector,
            tokenAddress,
            tokenId
        );
        return assetData;
    }






    function decodeERC721AssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress,
            uint256 tokenId
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).ERC721Token.selector,
            "WRONG_PROXY_ID"
        );

        tokenAddress = assetData.readAddress(16);
        tokenId = assetData.readUint256(36);
        return (assetProxyId, tokenAddress, tokenId);
    }







    function encodeERC1155AssetData(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256[] memory tokenValues,
        bytes memory callbackData
    )
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(
            IAssetData(address(0)).ERC1155Assets.selector,
            tokenAddress,
            tokenIds,
            tokenValues,
            callbackData
        );
        return assetData;
    }










    function decodeERC1155AssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            address tokenAddress,
            uint256[] memory tokenIds,
            uint256[] memory tokenValues,
            bytes memory callbackData
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).ERC1155Assets.selector,
            "WRONG_PROXY_ID"
        );

        assembly {

            assetData := add(assetData, 36)

            tokenAddress := mload(assetData)

            tokenIds := add(assetData, mload(add(assetData, 32)))

            tokenValues := add(assetData, mload(add(assetData, 64)))

            callbackData := add(assetData, mload(add(assetData, 96)))
        }

        return (
            assetProxyId,
            tokenAddress,
            tokenIds,
            tokenValues,
            callbackData
        );
    }





    function encodeMultiAssetData(uint256[] memory amounts, bytes[] memory nestedAssetData)
        public
        pure
        returns (bytes memory assetData)
    {
        assetData = abi.encodeWithSelector(
            IAssetData(address(0)).MultiAsset.selector,
            amounts,
            nestedAssetData
        );
        return assetData;
    }







    function decodeMultiAssetData(bytes memory assetData)
        public
        pure
        returns (
            bytes4 assetProxyId,
            uint256[] memory amounts,
            bytes[] memory nestedAssetData
        )
    {
        assetProxyId = assetData.readBytes4(0);

        require(
            assetProxyId == IAssetData(address(0)).MultiAsset.selector,
            "WRONG_PROXY_ID"
        );


        (amounts, nestedAssetData) = abi.decode(
            assetData.slice(4, assetData.length),
            (uint256[], bytes[])
        );

    }
}
