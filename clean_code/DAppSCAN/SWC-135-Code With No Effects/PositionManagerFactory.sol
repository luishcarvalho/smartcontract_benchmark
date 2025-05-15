

pragma solidity 0.7.6;
pragma abicoder v2;

import './PositionManager.sol';
import '../interfaces/IPositionManagerFactory.sol';
import '../interfaces/IDiamondCut.sol';

contract PositionManagerFactory is IPositionManagerFactory {
    address public governance;
    address public diamondCutFacet;
    address uniswapAddressHolder;
    address aaveAddressHolder;
    address public registry;
    address[] public positionManagers;
    IDiamondCut.FacetCut[] public actions;
    mapping(address => address) public override userToPositionManager;




    event PositionManagerCreated(address indexed positionManager, address user);

    modifier onlyGovernance() {
        require(msg.sender == governance, 'PositionManagerFactory::onlyGovernance: Only governance can add actions');
        _;
    }

    constructor(
        address _governance,
        address _registry,
        address _diamondCutFacet,
        address _uniswapAddressHolder,
        address _aaveAddressHolder
    ) public {
        governance = _governance;
        registry = _registry;
        diamondCutFacet = _diamondCutFacet;
        uniswapAddressHolder = _uniswapAddressHolder;
        aaveAddressHolder = _aaveAddressHolder;
    }



    function changeGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }




    function pushActionData(address actionAddress, bytes4[] calldata selectors) external onlyGovernance {
        require(actionAddress != address(0), 'PositionManagerFactory::pushActionData: Action address cannot be 0');
        actions.push(
            IDiamondCut.FacetCut({
                facetAddress: actionAddress,
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectors
            })
        );
    }



    function create() public override returns (address[] memory) {
        require(
            userToPositionManager[msg.sender] == address(0),
            'PositionManagerFactory::create: User already has a PositionManager'
        );
        PositionManager manager = new PositionManager(msg.sender, diamondCutFacet, registry);
        positionManagers.push(address(manager));
        userToPositionManager[msg.sender] = address(manager);
        manager.init(msg.sender, uniswapAddressHolder, registry, aaveAddressHolder);
        bytes memory _calldata;
        IDiamondCut(address(manager)).diamondCut(actions, 0x0000000000000000000000000000000000000000, _calldata);

        emit PositionManagerCreated(address(manager), msg.sender);

        return positionManagers;
    }





    function getAllPositionManagers() public view override returns (address[] memory) {
        return positionManagers;
    }
}
