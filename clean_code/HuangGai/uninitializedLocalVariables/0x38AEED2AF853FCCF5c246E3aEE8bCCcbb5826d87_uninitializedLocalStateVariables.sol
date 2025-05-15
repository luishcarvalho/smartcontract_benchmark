



pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;






















contract Owned {


    address public owner;

    event OwnerChanged(address indexed _newOwner);




    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }





    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

interface IAugustusSwapper {
    function getTokenTransferProxy() external view returns (address);

    struct Route {
        address payable exchange;
        address targetExchange;
        uint percent;
        bytes payload;
        uint256 networkFee;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;
        Route[] routes;
    }

    struct BuyRoute {
        address payable exchange;
        address targetExchange;
        uint256 fromAmount;
        uint256 toAmount;
        bytes payload;
        uint256 networkFee;
    }
}







interface IDexRegistry {
    function verifyExchangeAdapters(IAugustusSwapper.Path[] calldata _path) external view;
    function verifyExchangeAdapters(IAugustusSwapper.BuyRoute[] calldata _routes) external view;
}








contract DexRegistry is IDexRegistry, Owned {


    mapping(address => bool) public isAuthorised;

    event DexAdded(address indexed _dex);
    event DexRemoved(address indexed _dex);







    function setAuthorised(address[] calldata _dexes, bool[] calldata _authorised) external onlyOwner {
        for(uint256 i ; i < _dexes.length; i++) {

            if(isAuthorised[_dexes[i]] != _authorised[i]) {
                isAuthorised[_dexes[i]] = _authorised[i];
                if(_authorised[i]) {
                    emit DexAdded(_dexes[i]);
                } else {
                    emit DexRemoved(_dexes[i]);
                }
            }
        }
    }

    function verifyExchangeAdapters(IAugustusSwapper.Path[] calldata _path) external override view {
        for (uint i ; i < _path.length; i++) {

            for (uint j ; j < _path[i].routes.length; j++) {

                require(isAuthorised[_path[i].routes[j].exchange], "DR: Unauthorised DEX");
            }
        }
    }

    function verifyExchangeAdapters(IAugustusSwapper.BuyRoute[] calldata _routes) external override view {
        for (uint j ; j < _routes.length; j++) {

            require(isAuthorised[_routes[j].exchange], "DR: Unauthorised DEX");
        }
    }


}
