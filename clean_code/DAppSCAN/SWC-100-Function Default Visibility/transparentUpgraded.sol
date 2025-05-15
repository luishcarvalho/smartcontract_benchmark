

pragma solidity 0.6.6;

import "./upgradableProxy.sol";






















contract TransparentUpgradeableProxy is UpgradeableProxy {




    constructor(address _logic, address _admin, address _incognito, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        assert(_SUCCESSOR_SLOT == bytes32(uint256(keccak256("eip1967.proxy.successor")) - 1));
        assert(_PAUSED_SLOT == bytes32(uint256(keccak256("eip1967.proxy.paused")) - 1));
        assert(_INCOGNITO_SLOT == bytes32(uint256(keccak256("eip1967.proxy.incognito.")) - 1));
        _setAdmin(_admin);
        _setIncognito(_incognito);
    }




    event SuccessorChanged(address previousSuccessor, address newSuccessor);




    event IncognitoChanged(address previousIncognito, address newIncognito);




    event Claim(address claimer);




    event Paused(address admin);




    event Unpaused(address admin);






    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;






    bytes32 private constant _SUCCESSOR_SLOT = 0x7b13fc932b1063ca775d428558b73e20eab6804d4d9b5a148d7cbae4488973f8;






    bytes32 private constant _PAUSED_SLOT = 0x8dea8703c3cf94703383ce38a9c894669dccd4ca8e65ddb43267aa0248711450;






    bytes32 private constant _INCOGNITO_SLOT = 0x62135fc083646fdb4e1a9d700e351b886a4a5a39da980650269edd1ade91ffd2;




    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }










    function admin() external ifAdmin returns (address) {
        return _admin();
    }










    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }










    function successor() external ifAdmin returns (address) {
        return _successor();
    }










    function paused() external ifAdmin returns (bool) {
        return _paused();
    }










    function incognito() external ifAdmin returns (address) {
        return _incognito();
    }






    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }








    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newImplementation);

        (bool success,) = newImplementation.delegatecall(data);
        require(success);
    }




    function _admin() internal view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;

        assembly {
            adm := sload(slot)
        }
    }




    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;


        assembly {
            sstore(slot, newAdmin)
        }
    }




    function _successor() internal view returns (address sor) {
        bytes32 slot = _SUCCESSOR_SLOT;

        assembly {
            sor := sload(slot)
        }
    }




    function _setSuccesor(address newSuccessor) private {
        bytes32 slot = _SUCCESSOR_SLOT;


        assembly {
            sstore(slot, newSuccessor)
        }
    }




    function _paused() internal view returns (bool psd) {
        bytes32 slot = _PAUSED_SLOT;

        assembly {
            psd := sload(slot)
        }
    }




    function _setPaused(bool psd) private {
        bytes32 slot = _PAUSED_SLOT;


        assembly {
            sstore(slot, psd)
        }
    }




    function _incognito() internal view returns (address icg) {
        bytes32 slot = _INCOGNITO_SLOT;

        assembly {
            icg := sload(slot)
        }
    }




    function _setIncognito(address newIncognito) private {
        bytes32 slot = _INCOGNITO_SLOT;


        assembly {
            sstore(slot, newIncognito)
        }
    }




    function retire(address newSuccessor) external ifAdmin {
        require(newSuccessor != address(0), "TransparentUpgradeableProxy: successor is the zero address");
        emit SuccessorChanged(_successor(), newSuccessor);
        _setSuccesor(newSuccessor);
    }





    function claim() external {
        require(msg.sender == _successor(), "TransparentUpgradeableProxy: unauthorized");
        emit Claim(_successor());
        _setAdmin(_successor());
    }




    function pause() external ifAdmin {
        require(!_paused(), "TransparentUpgradeableProxy: contract paused already");
        _setPaused(true);
    }




    function unpause() external ifAdmin {
        require(_paused(), "TransparentUpgradeableProxy: contract not paused");
        _setPaused(false);
    }




    function upgradeIncognito(address newIncognito) external ifAdmin {
        require(newIncognito != address(0), "TransparentUpgradeableProxy: incognito proxy is the zero address");
        emit IncognitoChanged(_incognito(), newIncognito);
        _setIncognito(newIncognito);
    }




    function _beforeFallback() internal override virtual {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        require(!_paused(), "TransparentUpgradeableProxy: contract is paused");
        super._beforeFallback();
    }
}
