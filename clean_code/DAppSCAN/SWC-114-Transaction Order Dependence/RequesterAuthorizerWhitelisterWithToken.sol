
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "../access-control-registry/AccessControlRegistryAdminnedWithManager.sol";
import "./AirnodeEndpointPriceRegistryUser.sol";
import "./RequesterAuthorizerRegistryUser.sol";
import "./interfaces/IRequesterAuthorizerWhitelisterWithToken.sol";
import "../authorizers/interfaces/IRequesterAuthorizer.sol";



contract RequesterAuthorizerWhitelisterWithToken is
    Multicall,
    AccessControlRegistryAdminnedWithManager,
    AirnodeEndpointPriceRegistryUser,
    RequesterAuthorizerRegistryUser,
    IRequesterAuthorizerWhitelisterWithToken
{

    string public constant override MAINTAINER_ROLE_DESCRIPTION = "Maintainer";


    string public constant override BLOCKER_ROLE_DESCRIPTION = "Blocker";




    bytes32 public immutable override maintainerRole;






    bytes32 public immutable override blockerRole;



    address public immutable token;


    uint256 public override tokenPrice;









    uint256 public override priceCoefficient;


    address public override proceedsDestination;








    mapping(address => AirnodeParticipationStatus)
        public
        override airnodeToParticipationStatus;


    mapping(address => bool) public override requesterToBlockStatus;


    mapping(address => mapping(address => bool))
        public
        override airnodeToRequesterToBlockStatus;



    modifier onlyNonZeroAirnode(address airnode) {
        require(airnode != address(0), "Airnode address zero");
        _;
    }



    modifier onlyActiveAirnode(address airnode) {
        require(
            airnodeToParticipationStatus[airnode] ==
                AirnodeParticipationStatus.Active,
            "Airnode not active"
        );
        _;
    }



    modifier onlyNonZeroChainId(uint256 chainId) {
        require(chainId != 0, "Chain ID zero");
        _;
    }



    modifier onlyNonZeroRequester(address requester) {
        require(requester != address(0), "Requester address zero");
        _;
    }




    modifier onlyNonBlockedRequester(address airnode, address requester) {
        require(!requesterIsBlocked(airnode, requester), "Requester blocked");
        _;
    }



    modifier onlyMaintainerOrManager() {
        require(
            manager == msg.sender ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    maintainerRole,
                    msg.sender
                ),
            "Sender cannot maintain"
        );
        _;
    }



    modifier onlyBlockerOrManager() {
        require(
            manager == msg.sender ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    blockerRole,
                    msg.sender
                ),
            "Sender cannot block"
        );
        _;
    }













    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription,
        address _manager,
        address _airnodeEndpointPriceRegistry,
        address _requesterAuthorizerRegistry,
        address _token,
        uint256 _tokenPrice,
        uint256 _priceCoefficient,
        address _proceedsDestination
    )
        AccessControlRegistryAdminnedWithManager(
            _accessControlRegistry,
            _adminRoleDescription,
            _manager
        )
        AirnodeEndpointPriceRegistryUser(_airnodeEndpointPriceRegistry)
        RequesterAuthorizerRegistryUser(_requesterAuthorizerRegistry)
    {
        require(_token != address(0), "Token address zero");
        token = _token;
        _setTokenPrice(_tokenPrice);
        _setPriceCoefficient(_priceCoefficient);
        _setProceedsDestination(_proceedsDestination);
        maintainerRole = _deriveRole(
            adminRole,
            keccak256(abi.encodePacked(MAINTAINER_ROLE_DESCRIPTION))
        );
        blockerRole = _deriveRole(
            adminRole,
            keccak256(abi.encodePacked(BLOCKER_ROLE_DESCRIPTION))
        );
        require(
            keccak256(
                abi.encodePacked(
                    IAirnodeEndpointPriceRegistry(airnodeEndpointPriceRegistry)
                        .DENOMINATION()
                )
            ) == keccak256(abi.encodePacked("USD")),
            "Price denomination mismatch"
        );
        require(
            IAirnodeEndpointPriceRegistry(airnodeEndpointPriceRegistry)
                .DECIMALS() == 18,
            "Price decimals mismatch"
        );
    }



    function setTokenPrice(uint256 _tokenPrice)
        external
        override
        onlyMaintainerOrManager
    {
        _setTokenPrice(_tokenPrice);
        emit SetTokenPrice(_tokenPrice, msg.sender);
    }




    function setPriceCoefficient(uint256 _priceCoefficient)
        external
        override
        onlyMaintainerOrManager
    {
        _setPriceCoefficient(_priceCoefficient);
        emit SetPriceCoefficient(_priceCoefficient, msg.sender);
    }




    function setAirnodeParticipationStatus(
        address airnode,
        AirnodeParticipationStatus airnodeParticipationStatus
    ) external override onlyNonZeroAirnode(airnode) {
        if (msg.sender == airnode) {
            require(
                airnodeParticipationStatus ==
                    AirnodeParticipationStatus.OptedOut,
                "Airnode can only opt out"
            );
        } else {
            require(
                manager == msg.sender ||
                    IAccessControlRegistry(accessControlRegistry).hasRole(
                        maintainerRole,
                        msg.sender
                    ),
                "Sender cannot maintain"
            );
            require(
                airnodeParticipationStatus !=
                    AirnodeParticipationStatus.OptedOut,
                "Only Airnode can opt out"
            );
            require(
                airnodeToParticipationStatus[airnode] !=
                    AirnodeParticipationStatus.OptedOut,
                "Airnode opted out"
            );
        }
        airnodeToParticipationStatus[airnode] = airnodeParticipationStatus;
        emit SetAirnodeParticipationStatus(
            airnode,
            airnodeParticipationStatus,
            msg.sender
        );
    }



    function setProceedsDestination(address _proceedsDestination)
        external
        override
    {
        require(msg.sender == manager, "Sender not manager");
        _setProceedsDestination(_proceedsDestination);
        emit SetProceedsDestination(_proceedsDestination);
    }





    function setRequesterBlockStatus(address requester, bool status)
        external
        override
        onlyBlockerOrManager
        onlyNonZeroRequester(requester)
    {
        requesterToBlockStatus[requester] = status;
        emit SetRequesterBlockStatus(requester, status, msg.sender);
    }





    function setRequesterBlockStatusForAirnode(
        address airnode,
        address requester,
        bool status
    )
        external
        override
        onlyBlockerOrManager
        onlyNonZeroAirnode(airnode)
        onlyNonZeroRequester(requester)
    {
        airnodeToRequesterToBlockStatus[airnode][requester] = status;
        emit SetRequesterBlockStatusForAirnode(
            airnode,
            requester,
            status,
            msg.sender
        );
    }






    function getTokenAmount(
        address airnode,
        uint256 chainId,
        bytes32 endpointId
    ) public view override returns (uint256 amount) {
        uint256 endpointPrice = IAirnodeEndpointPriceRegistry(
            airnodeEndpointPriceRegistry
        ).getPrice(airnode, chainId, endpointId);
        amount = (endpointPrice * priceCoefficient) / tokenPrice;
    }





    function requesterIsBlocked(address airnode, address requester)
        internal
        view
        returns (bool)
    {
        return
            requesterToBlockStatus[requester] ||
            airnodeToRequesterToBlockStatus[airnode][requester];
    }





    function getRequesterAuthorizerAddress(uint256 chainId)
        internal
        view
        returns (address)
    {
        (
            bool success,
            address requesterAuthorizer
        ) = IRequesterAuthorizerRegistry(requesterAuthorizerRegistry)
                .tryReadChainRequesterAuthorizer(chainId);
        require(success, "No Authorizer set for chain");
        return requesterAuthorizer;
    }



    function _setTokenPrice(uint256 _tokenPrice) private {
        require(_tokenPrice != 0, "Token price zero");
        tokenPrice = _tokenPrice;
    }




    function _setPriceCoefficient(uint256 _priceCoefficient) private {
        require(_priceCoefficient != 0, "Price coefficient zero");
        priceCoefficient = _priceCoefficient;
    }

    function _setProceedsDestination(address _proceedsDestination) private {
        require(
            _proceedsDestination != address(0),
            "Proceeds destination zero"
        );
        proceedsDestination = _proceedsDestination;
    }
}
