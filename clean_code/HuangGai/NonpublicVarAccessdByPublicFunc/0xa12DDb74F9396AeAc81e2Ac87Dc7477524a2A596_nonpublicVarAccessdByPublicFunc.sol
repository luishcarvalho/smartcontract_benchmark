





pragma solidity ^0.6.12;


interface IWSProxy {
    function initialize(address _implementation, address _admin, bytes calldata _data) external;
    function upgradeTo(address _proxy) external;
    function upgradeToAndCall(address _proxy, bytes calldata data) external payable;
    function changeAdmin(address newAdmin) external;
    function admin() external returns (address);
    function implementation() external returns (address);
}

interface IWSController {
    function getLogicForPair() external view returns(address);
    function getCurrentAdmin() external view returns(address);
    function updatePairLogic(address _logic) external;
    function updateCurrentAdmin(address _newAdmin) external;
    function updateProxyPair(address _proxy) external;
    function setAdminForProxy(address _proxy) external;
}

interface IWSImplementation {
	function getImplementationType() external pure returns(uint256);
}













contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract WSController is Ownable, IWSController {
    address internal pairLogic;
    address internal currentAdmin;





    uint256 constant internal PAIR_TYPE = 2;

    event NewPairLogic(address indexed logic);
    event NewAdmin(address indexed adminAddress);
    event UpdateProxy(address indexed proxyAddress, address newLogic);
    event ChangeAdmin(address indexed proxyAddress, address newAdmin);

    constructor(address _pairLogic) public {
        require(_pairLogic != address(0), "WSController: Wrong pair logic address");
        currentAdmin = address(this);
        pairLogic = _pairLogic;
    }


    function updatePairLogic(address _logic) external override onlyOwner {
        pairLogic = _logic;
        emit NewPairLogic(_logic);
    }

    function updateCurrentAdmin(address _newAdmin) external override onlyOwner {
        currentAdmin = _newAdmin;
        emit NewAdmin(_newAdmin);
    }

    function updateProxyPair(address _proxy) external override {
        require(IWSImplementation(IWSProxy(_proxy).implementation()).getImplementationType() == PAIR_TYPE, "WSController: Wrong pair proxy for update.");
        IWSProxy(_proxy).upgradeTo(pairLogic);
        emit UpdateProxy(_proxy, pairLogic);
    }

    function setAdminForProxy(address _proxy) external override {
        IWSProxy(_proxy).changeAdmin(currentAdmin);
        emit ChangeAdmin(_proxy, currentAdmin);
    }

    function getLogicForPair() external view override returns(address) {
        return pairLogic;
    }

    function getCurrentAdmin() external view override returns(address){
        return currentAdmin;
    }

}
