
pragma solidity 0.8.9;

import "../whitelist/WhitelistWithManager.sol";
import "../protocol/AirnodeRequester.sol";
import "./Median.sol";
import "./interfaces/IDapiServer.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";




















contract DapiServer is
    WhitelistWithManager,
    AirnodeRequester,
    Median,
    IDapiServer
{
    using ECDSA for bytes32;




    struct DataPoint {
        int224 value;
        uint32 timestamp;
    }


    string public constant override UNLIMITED_READER_ROLE_DESCRIPTION =
        "Unlimited reader";


    string public constant override NAME_SETTER_ROLE_DESCRIPTION =
        "Name setter";






    uint256 public constant override HUNDRED_PERCENT = 1e8;


    bytes32 public immutable override unlimitedReaderRole;


    bytes32 public immutable override nameSetterRole;



    mapping(address => mapping(address => bool))
        public
        override sponsorToRrpBeaconUpdateRequesterToPermissionStatus;


    mapping(bytes32 => bytes32) public override subscriptionIdToBeaconId;

    mapping(bytes32 => DataPoint) private dataPoints;

    mapping(bytes32 => bytes32) private requestIdToBeaconId;

    mapping(bytes32 => bytes32) private subscriptionIdToHash;

    mapping(bytes32 => bytes32) private nameHashToDataPointId;




    modifier onlyPermittedUpdateRequester(address sponsor) {
        require(
            sponsor == msg.sender ||
                sponsorToRrpBeaconUpdateRequesterToPermissionStatus[sponsor][
                    msg.sender
                ],
            "Sender not permitted"
        );
        _;
    }





    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager,
        address _airnodeProtocol
    )
        WhitelistWithManager(
            _accessControlRegistry,
            _adminRoleDescription,
            _manager
        )
        AirnodeRequester(_airnodeProtocol)
    {
        unlimitedReaderRole = _deriveRole(
            _deriveAdminRole(manager),
            keccak256(abi.encodePacked(UNLIMITED_READER_ROLE_DESCRIPTION))
        );
        nameSetterRole = _deriveRole(
            _deriveAdminRole(manager),
            keccak256(abi.encodePacked(NAME_SETTER_ROLE_DESCRIPTION))
        );
    }








    function setRrpBeaconUpdatePermissionStatus(
        address rrpBeaconUpdateRequester,
        bool status
    ) external override {
        require(
            rrpBeaconUpdateRequester != address(0),
            "Update requester zero"
        );
        sponsorToRrpBeaconUpdateRequesterToPermissionStatus[msg.sender][
            rrpBeaconUpdateRequester
        ] = status;
        emit SetRrpBeaconUpdatePermissionStatus(
            msg.sender,
            rrpBeaconUpdateRequester,
            status
        );
    }













    function requestRrpBeaconUpdate(
        address airnode,
        bytes32 templateId,
        address sponsor
    )
        external
        override
        onlyPermittedUpdateRequester(sponsor)
        returns (bytes32 requestId)
    {
        bytes32 beaconId = deriveBeaconId(airnode, templateId);
        requestId = IAirnodeProtocol(airnodeProtocol).makeRequest(
            airnode,
            templateId,
            "",
            sponsor,
            this.fulfillRrpBeaconUpdate.selector
        );
        requestIdToBeaconId[requestId] = beaconId;
        emit RequestedRrpBeaconUpdate(
            beaconId,
            sponsor,
            msg.sender,
            requestId,
            airnode,
            templateId
        );
    }







    function requestRrpBeaconUpdateRelayed(
        address airnode,
        bytes32 templateId,
        address relayer,
        address sponsor
    )
        external
        override
        onlyPermittedUpdateRequester(sponsor)
        returns (bytes32 requestId)
    {
        bytes32 beaconId = deriveBeaconId(airnode, templateId);
        requestId = IAirnodeProtocol(airnodeProtocol).makeRequestRelayed(
            airnode,
            templateId,
            "",
            relayer,
            sponsor,
            this.fulfillRrpBeaconUpdate.selector
        );
        requestIdToBeaconId[requestId] = beaconId;
        emit RequestedRrpBeaconUpdateRelayed(
            beaconId,
            sponsor,
            msg.sender,
            requestId,
            airnode,
            relayer,
            templateId
        );
    }






    function fulfillRrpBeaconUpdate(
        bytes32 requestId,
        uint256 timestamp,
        bytes calldata data
    ) external override onlyAirnodeProtocol onlyValidTimestamp(timestamp) {
        bytes32 beaconId = requestIdToBeaconId[requestId];
        delete requestIdToBeaconId[requestId];
        int256 decodedData = processBeaconUpdate(beaconId, timestamp, data);
        emit UpdatedBeaconWithRrp(beaconId, requestId, decodedData, timestamp);
    }

















    function registerBeaconUpdateSubscription(
        address airnode,
        bytes32 templateId,
        bytes memory conditions,
        address relayer,
        address sponsor
    ) external override returns (bytes32 subscriptionId) {
        require(relayer != address(0), "Relayer address zero");
        require(sponsor != address(0), "Sponsor address zero");
        subscriptionId = keccak256(
            abi.encodePacked(
                block.chainid,
                airnode,
                templateId,
                "",
                conditions,
                relayer,
                sponsor,
                address(this),
                this.fulfillPspBeaconUpdate.selector
            )
        );
        subscriptionIdToHash[subscriptionId] = keccak256(
            abi.encodePacked(airnode, relayer, sponsor)
        );
        subscriptionIdToBeaconId[subscriptionId] = deriveBeaconId(
            airnode,
            templateId
        );
        emit RegisteredBeaconUpdateSubscription(
            subscriptionId,
            airnode,
            templateId,
            "",
            conditions,
            relayer,
            sponsor,
            address(this),
            this.fulfillPspBeaconUpdate.selector
        );
    }












    function conditionPspBeaconUpdate(
        bytes32 subscriptionId,
        bytes calldata data,
        bytes calldata conditionParameters
    ) external view override returns (bool) {
        require(msg.sender == address(0), "Sender not zero address");
        bytes32 beaconId = subscriptionIdToBeaconId[subscriptionId];
        require(beaconId != bytes32(0), "Subscription not registered");
        return
            calculateUpdateInPercentage(
                dataPoints[beaconId].value,
                decodeFulfillmentData(data)
            ) >= decodeConditionParameters(conditionParameters);
    }















    function fulfillPspBeaconUpdate(
        bytes32 subscriptionId,
        address airnode,
        address relayer,
        address sponsor,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external override onlyValidTimestamp(timestamp) {
        require(
            subscriptionIdToHash[subscriptionId] ==
                keccak256(abi.encodePacked(airnode, relayer, sponsor)),
            "Subscription not registered"
        );
        if (airnode == relayer) {
            require(
                (
                    keccak256(
                        abi.encodePacked(subscriptionId, timestamp, msg.sender)
                    ).toEthSignedMessageHash()
                ).recover(signature) == airnode,
                "Signature mismatch"
            );
        } else {
            require(
                (
                    keccak256(
                        abi.encodePacked(
                            subscriptionId,
                            timestamp,
                            msg.sender,
                            data
                        )
                    ).toEthSignedMessageHash()
                ).recover(signature) == airnode,
                "Signature mismatch"
            );
        }
        bytes32 beaconId = subscriptionIdToBeaconId[subscriptionId];


        int256 decodedData = processBeaconUpdate(beaconId, timestamp, data);
        emit UpdatedBeaconWithPsp(
            beaconId,
            subscriptionId,
            int224(decodedData),
            uint32(timestamp)
        );
    }











    function updateBeaconWithSignedData(
        address airnode,
        bytes32 templateId,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external override onlyValidTimestamp(timestamp) {
        require(
            (
                keccak256(abi.encodePacked(templateId, timestamp, data))
                    .toEthSignedMessageHash()
            ).recover(signature) == airnode,
            "Signature mismatch"
        );
        bytes32 beaconId = deriveBeaconId(airnode, templateId);
        int256 decodedData = processBeaconUpdate(beaconId, timestamp, data);
        emit UpdatedBeaconWithSignedData(beaconId, decodedData, timestamp);
    }






    function updateDapiWithBeacons(bytes32[] memory beaconIds)
        public
        override
        returns (bytes32 dapiId)
    {
        uint256 beaconCount = beaconIds.length;
        require(beaconCount > 1, "Specified less than two Beacons");
        int256[] memory values = new int256[](beaconCount);
        uint256 accumulatedTimestamp = 0;
        for (uint256 ind = 0; ind < beaconCount; ind++) {
            DataPoint storage datapoint = dataPoints[beaconIds[ind]];
            values[ind] = datapoint.value;
            accumulatedTimestamp += datapoint.timestamp;
        }
        uint32 updatedTimestamp = uint32(accumulatedTimestamp / beaconCount);
        dapiId = deriveDapiId(beaconIds);
        require(
            updatedTimestamp >= dataPoints[dapiId].timestamp,
            "Updated value outdated"
        );
        int224 updatedValue = int224(median(values));
        dataPoints[dapiId] = DataPoint({
            value: updatedValue,
            timestamp: updatedTimestamp
        });
        emit UpdatedDapiWithBeacons(dapiId, updatedValue, updatedTimestamp);
    }


















    function conditionPspDapiUpdate(
        bytes32 subscriptionId,
        bytes calldata data,
        bytes calldata conditionParameters
    ) external override returns (bool) {
        bytes32 dapiId = keccak256(data);
        int224 currentDapiValue = dataPoints[dapiId].value;
        require(
            dapiId == updateDapiWithBeacons(abi.decode(data, (bytes32[]))),
            "Data length not correct"
        );
        return
            calculateUpdateInPercentage(
                currentDapiValue,
                dataPoints[dapiId].value
            ) >= decodeConditionParameters(conditionParameters);
    }























    function fulfillPspDapiUpdate(
        bytes32 subscriptionId,
        address airnode,
        address relayer,
        address sponsor,
        uint256 timestamp,
        bytes calldata data,
        bytes calldata signature
    ) external override {
        require(
            keccak256(data) ==
                updateDapiWithBeacons(abi.decode(data, (bytes32[]))),
            "Data length not correct"
        );
    }














    function updateDapiWithSignedData(
        address[] memory airnodes,
        bytes32[] memory templateIds,
        uint256[] memory timestamps,
        bytes[] memory data,
        bytes[] memory signatures
    ) external override returns (bytes32 dapiId) {
        uint256 beaconCount = airnodes.length;
        require(
            beaconCount == templateIds.length &&
                beaconCount == timestamps.length &&
                beaconCount == data.length &&
                beaconCount == signatures.length,
            "Parameter length mismatch"
        );
        require(beaconCount > 1, "Specified less than two Beacons");
        bytes32[] memory beaconIds = new bytes32[](beaconCount);
        int256[] memory values = new int256[](beaconCount);
        uint256 accumulatedTimestamp = 0;
        for (uint256 ind = 0; ind < beaconCount; ind++) {
            if (signatures[ind].length != 0) {
                address airnode = airnodes[ind];
                uint256 timestamp = timestamps[ind];
                require(timestampIsValid(timestamp), "Timestamp not valid");
                require(
                    (
                        keccak256(
                            abi.encodePacked(
                                templateIds[ind],
                                timestamp,
                                data[ind]
                            )
                        ).toEthSignedMessageHash()
                    ).recover(signatures[ind]) == airnode,
                    "Signature mismatch"
                );
                values[ind] = decodeFulfillmentData(data[ind]);


                accumulatedTimestamp += timestamp;
                beaconIds[ind] = deriveBeaconId(airnode, templateIds[ind]);
            } else {
                bytes32 beaconId = deriveBeaconId(
                    airnodes[ind],
                    templateIds[ind]
                );
                DataPoint storage dataPoint = dataPoints[beaconId];
                values[ind] = dataPoint.value;
                accumulatedTimestamp += dataPoint.timestamp;
                beaconIds[ind] = beaconId;
            }
        }
        dapiId = deriveDapiId(beaconIds);
        uint32 updatedTimestamp = uint32(accumulatedTimestamp / beaconCount);
        require(
            updatedTimestamp >= dataPoints[dapiId].timestamp,
            "Updated value outdated"
        );
        int224 updatedValue = int224(median(values));
        dataPoints[dapiId] = DataPoint({
            value: updatedValue,
            timestamp: updatedTimestamp
        });
        emit UpdatedDapiWithSignedData(dapiId, updatedValue, updatedTimestamp);
    }








    function setName(bytes32 name, bytes32 dataPointId) external override {
        require(name != bytes32(0), "Name zero");
        require(dataPointId != bytes32(0), "Data point ID zero");
        require(
            msg.sender == manager ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    nameSetterRole,
                    msg.sender
                ),
            "Sender cannot set name"
        );
        nameHashToDataPointId[keccak256(abi.encodePacked(name))] = dataPointId;
        emit SetName(name, dataPointId, msg.sender);
    }




    function nameToDataPointId(bytes32 name)
        external
        view
        override
        returns (bytes32)
    {
        return nameHashToDataPointId[keccak256(abi.encodePacked(name))];
    }





    function readWithDataPointId(bytes32 dataPointId)
        external
        view
        override
        returns (int224 value, uint32 timestamp)
    {
        require(
            readerCanReadDataPoint(dataPointId, msg.sender),
            "Sender cannot read"
        );
        DataPoint storage dataPoint = dataPoints[dataPointId];
        return (dataPoint.value, dataPoint.timestamp);
    }







    function readWithName(bytes32 name)
        external
        view
        override
        returns (int224 value, uint32 timestamp)
    {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        require(
            readerCanReadDataPoint(nameHash, msg.sender),
            "Sender cannot read"
        );
        DataPoint storage dataPoint = dataPoints[
            nameHashToDataPointId[nameHash]
        ];
        return (dataPoint.value, dataPoint.timestamp);
    }





    function readerCanReadDataPoint(bytes32 dataPointId, address reader)
        public
        view
        override
        returns (bool)
    {
        return
            reader == address(0) ||
            userIsWhitelisted(dataPointId, reader) ||
            IAccessControlRegistry(accessControlRegistry).hasRole(
                unlimitedReaderRole,
                reader
            );
    }









    function dataPointIdToReaderToWhitelistStatus(
        bytes32 dataPointId,
        address reader
    )
        external
        view
        override
        returns (uint64 expirationTimestamp, uint192 indefiniteWhitelistCount)
    {
        WhitelistStatus
            storage whitelistStatus = serviceIdToUserToWhitelistStatus[
                dataPointId
            ][reader];
        expirationTimestamp = whitelistStatus.expirationTimestamp;
        indefiniteWhitelistCount = whitelistStatus.indefiniteWhitelistCount;
    }









    function dataPointIdToReaderToSetterToIndefiniteWhitelistStatus(
        bytes32 dataPointId,
        address reader,
        address setter
    ) external view override returns (bool indefiniteWhitelistStatus) {
        indefiniteWhitelistStatus = serviceIdToUserToSetterToIndefiniteWhitelistStatus[
            dataPointId
        ][reader][setter];
    }





    function deriveBeaconId(address airnode, bytes32 templateId)
        public
        pure
        override
        returns (bytes32 beaconId)
    {
        require(airnode != address(0), "Airnode address zero");
        require(templateId != bytes32(0), "Template ID zero");
        beaconId = keccak256(abi.encodePacked(airnode, templateId));
    }





    function deriveDapiId(bytes32[] memory beaconIds)
        public
        pure
        override
        returns (bytes32 dapiId)
    {
        dapiId = keccak256(abi.encode(beaconIds));
    }






    function processBeaconUpdate(
        bytes32 beaconId,
        uint256 timestamp,
        bytes calldata data
    ) private returns (int256 updatedBeaconValue) {
        updatedBeaconValue = decodeFulfillmentData(data);
        require(
            timestamp > dataPoints[beaconId].timestamp,
            "Fulfillment older than Beacon"
        );


        dataPoints[beaconId] = DataPoint({
            value: int224(updatedBeaconValue),
            timestamp: uint32(timestamp)
        });
    }




    function decodeFulfillmentData(bytes memory data)
        private
        pure
        returns (int224)
    {
        require(data.length == 32, "Data length not correct");
        int256 decodedData = abi.decode(data, (int256));
        require(
            decodedData >= type(int224).min && decodedData <= type(int224).max,
            "Value typecasting error"
        );
        return int224(decodedData);
    }






    function decodeConditionParameters(bytes calldata conditionParameters)
        private
        pure
        returns (uint256 updateThresholdInPercentage)
    {
        require(conditionParameters.length == 32, "Incorrect parameter length");
        updateThresholdInPercentage = abi.decode(
            conditionParameters,
            (uint256)
        );
    }











    function calculateUpdateInPercentage(
        int224 initialValue,
        int224 updatedValue
    ) private pure returns (uint256 updateInPercentage) {
        int256 delta = int256(updatedValue) - int256(initialValue);
        uint256 absoluteDelta = delta > 0 ? uint256(delta) : uint256(-delta);
        uint256 absoluteInitialValue = initialValue > 0
            ? uint256(int256(initialValue))
            : uint256(-int256(initialValue));

        if (absoluteInitialValue == 0) {
            absoluteInitialValue = 1;
        }
        updateInPercentage =
            (absoluteDelta * HUNDRED_PERCENT) /
            absoluteInitialValue;
    }
}
