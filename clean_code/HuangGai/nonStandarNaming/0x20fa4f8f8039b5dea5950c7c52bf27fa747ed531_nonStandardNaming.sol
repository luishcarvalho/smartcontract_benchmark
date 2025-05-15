

pragma solidity 0.6.2;


interface SmartWalletInterface {
  function MIGRATESAITODAI348() external;
  function MIGRATECSAITODDAI449() external;
  function MIGRATECDAITODDAI856() external;
  function MIGRATECUSDCTODUSDC603() external;
}


contract DTokenMigrator {
  function BATCHMIGRATESAITODAI965(SmartWalletInterface[] calldata wallets) external {
    for (uint256 i = 0; i < wallets.length; i++) {
      if (gasleft() < 400000) {
        break;
      }
      try wallets[i].MIGRATESAITODAI348() {} catch {}
    }
  }

  function BATCHMIGRATECSAITODDAI402(SmartWalletInterface[] calldata wallets) external {
    for (uint256 i = 0; i < wallets.length; i++) {
      if (gasleft() < 600000) {
        break;
      }
      try wallets[i].MIGRATECSAITODDAI449() {} catch {}
    }
  }

  function BATCHMIGRATECDAITODDAI177(SmartWalletInterface[] calldata wallets) external {
    for (uint256 i = 0; i < wallets.length; i++) {
      if (gasleft() < 200000) {
        break;
      }
      try wallets[i].MIGRATECDAITODDAI856() {} catch {}
    }
  }

  function BATCHMIGRATECUSDCTODUSDC363(SmartWalletInterface[] calldata wallets) external {
    for (uint256 i = 0; i < wallets.length; i++) {
      if (gasleft() < 200000) {
        break;
      }
      try wallets[i].MIGRATECUSDCTODUSDC603() {} catch {}
    }
  }
}
