
pragma solidity 0.8.9;

import "./interfaces/IStorageUtils.sol";














contract StorageUtils is IStorageUtils {
    struct Template {
        bytes32 endpointId;
        bytes parameters;
    }

    struct Subscription {
        uint256 chainId;
        address airnode;
        bytes32 templateId;
        bytes parameters;
        bytes conditions;
        address relayer;
        address sponsor;
        address requester;
        bytes4 fulfillFunctionId;
    }








    uint256 public constant override MAXIMUM_PARAMETER_LENGTH = 4096;


    mapping(bytes32 => Template) public override templates;


    mapping(bytes32 => Subscription) public override subscriptions;












    function storeTemplate(bytes32 endpointId, bytes calldata parameters)
        external
        override
        returns (bytes32 templateId)
    {
        require(
            parameters.length <= MAXIMUM_PARAMETER_LENGTH,
            "Parameters too long"
        );
        templateId = keccak256(abi.encodePacked(endpointId, parameters));
        templates[templateId] = Template({
            endpointId: endpointId,
            parameters: parameters
        });
        emit StoredTemplate(templateId, endpointId, parameters);
    }































    function storeSubscription(
        uint256 chainId,
        address airnode,
        bytes32 templateId,
        bytes calldata parameters,
        bytes calldata conditions,
        address relayer,
        address sponsor,
        address requester,
        bytes4 fulfillFunctionId
    ) external override returns (bytes32 subscriptionId) {
        require(chainId != 0, "Chain ID zero");
        require(airnode != address(0), "Airnode address zero");
        require(
            parameters.length <= MAXIMUM_PARAMETER_LENGTH,
            "Parameters too long"
        );
        require(
            conditions.length <= MAXIMUM_PARAMETER_LENGTH,
            "Conditions too long"
        );
        require(relayer != address(0), "Relayer address zero");
        require(sponsor != address(0), "Sponsor address zero");
        require(requester != address(0), "Requester address zero");
        require(fulfillFunctionId != bytes4(0), "Fulfill function ID zero");
        subscriptionId = keccak256(

            abi.encodePacked(
                chainId,
                airnode,
                templateId,
                parameters,
                conditions,
                relayer,
                sponsor,
                requester,
                fulfillFunctionId
            )
        );
        subscriptions[subscriptionId] = Subscription({
            chainId: chainId,
            airnode: airnode,
            templateId: templateId,
            parameters: parameters,
            conditions: conditions,
            relayer: relayer,
            sponsor: sponsor,
            requester: requester,
            fulfillFunctionId: fulfillFunctionId
        });
        emit StoredSubscription(
            subscriptionId,
            chainId,
            airnode,
            templateId,
            parameters,
            conditions,
            relayer,
            sponsor,
            requester,
            fulfillFunctionId
        );
    }
}
