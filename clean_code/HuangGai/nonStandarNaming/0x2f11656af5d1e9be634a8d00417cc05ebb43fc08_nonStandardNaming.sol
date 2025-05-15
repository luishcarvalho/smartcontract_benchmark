



pragma solidity ^0.5.5;



interface IRouterRegistry {
    enum RouterOperation { Add, Remove, Refresh }

    function REGISTERROUTER662() external;

    function DEREGISTERROUTER816() external;

    function REFRESHROUTER597() external;

    event ROUTERUPDATED610(RouterOperation indexed op, address indexed routerAddress);
}



pragma solidity ^0.5.5;



contract RouterRegistry is IRouterRegistry {


    mapping(address => uint) public routerInfo;


    function REGISTERROUTER662() external {
        require(routerInfo[msg.sender] == 0, "Router address already exists");

        routerInfo[msg.sender] = block.number;

        emit ROUTERUPDATED610(RouterOperation.Add, msg.sender);
    }


    function DEREGISTERROUTER816() external {
        require(routerInfo[msg.sender] != 0, "Router address does not exist");

        delete routerInfo[msg.sender];

        emit ROUTERUPDATED610(RouterOperation.Remove, msg.sender);
    }


    function REFRESHROUTER597() external {
        require(routerInfo[msg.sender] != 0, "Router address does not exist");

        routerInfo[msg.sender] = block.number;

        emit ROUTERUPDATED610(RouterOperation.Refresh, msg.sender);
    }
}
