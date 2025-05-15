

























pragma solidity 0.6.10;







contract AaveMigrationWrapAdapter {




    address public immutable lendToAaveMigrationProxy;


    address public immutable lendToken;


    address public immutable aaveToken;










    constructor(
        address _lendToAaveMigrationProxy,
        address _lendToken,
        address _aaveToken
    )
        public
    {
        lendToAaveMigrationProxy = _lendToAaveMigrationProxy;
        lendToken = _lendToken;
        aaveToken = _aaveToken;
    }














    function getWrapCallData(
        address _underlyingToken,
        address _wrappedToken,
        uint256 _underlyingUnits
    )
        public
        view
        returns (address, uint256, bytes memory)
    {
        require(_underlyingToken == lendToken, "Must be LEND token");
        require(_wrappedToken == aaveToken, "Must be AAVE token");


        bytes memory callData = abi.encodeWithSignature("migrateFromLEND(uint256)", _underlyingUnits);

        return (lendToAaveMigrationProxy, 0, callData);
    }









    function getUnwrapCallData(
        address ,
        address ,
        uint256
    )
        public
        view
        returns (address, uint256, bytes memory)
    {
        revert("AAVE migration cannot be reversed");
    }






    function getSpenderAddress(address ) public view returns(address) {
        return lendToAaveMigrationProxy;
    }
}
