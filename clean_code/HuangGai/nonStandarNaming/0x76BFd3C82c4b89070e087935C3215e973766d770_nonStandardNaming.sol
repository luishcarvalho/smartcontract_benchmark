


pragma solidity ^0.6.12;

interface Proxy {
  function UPGRADETO703(address newImplementation) external;
}

contract sbUpgrader {
  event UPGRADED524(address indexed proxyAddress, address indexed implementationAddress);

  address public admin;
  address public pendingAdmin;
  address public superAdmin;
  address public pendingSuperAdmin;

  constructor(address adminAddress, address superAdminAddress) public {
    admin = adminAddress;
    superAdmin = superAdminAddress;
  }



  function SETPENDINGADMIN799(address newPendingAdmin) public {
    require(msg.sender == admin, 'not admin');
    pendingAdmin = newPendingAdmin;
  }

  function ACCEPTADMIN491() public {
    require(msg.sender == pendingAdmin && msg.sender != address(0), 'not pendingAdmin');
    admin = pendingAdmin;
    pendingAdmin = address(0);
  }

  function SETPENDINGSUPERADMIN182(address newPendingSuperAdmin) public {
    require(msg.sender == superAdmin, 'not superAdmin');
    pendingSuperAdmin = newPendingSuperAdmin;
  }

  function ACCEPTSUPERADMIN116() public {
    require(msg.sender == pendingSuperAdmin && msg.sender != address(0), 'not pendingSuperAdmin');
    superAdmin = pendingSuperAdmin;
    pendingSuperAdmin = address(0);
  }



  function UPGRADE150(address proxyAddress, address implementationAddress) external {
    require(msg.sender == admin || msg.sender == superAdmin, 'not admin');
    Proxy proxy = Proxy(proxyAddress);
    proxy.UPGRADETO703(implementationAddress);
    emit UPGRADED524(proxyAddress, implementationAddress);
  }
}
