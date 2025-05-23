





pragma solidity ^0.5.17;

interface SmartWalletChecker {
    function check(address) external view returns (bool);
}

contract SmartWalletWhitelist {

    mapping(address => bool) public wallets;
    address public dao;
    address public checker;
    address public future_checker;

    event ApproveWallet(address);
    event RevokeWallet(address);

    constructor(address _dao) public {
        dao = _dao;
        wallets[0xF147b8125d2ef93FB6965Db97D6746952a133934] = true;
        emit ApproveWallet(0xF147b8125d2ef93FB6965Db97D6746952a133934);
    }

    function commitSetChecker(address _checker) external {
        require(tx.origin == dao, "!dao");

        future_checker = _checker;
    }

    function applySetChecker() external {
        require(tx.origin == dao, "!dao");

        checker = future_checker;
    }

    function approveWallet(address _wallet) public {
        require(tx.origin == dao, "!dao");

        wallets[_wallet] = true;

        emit ApproveWallet(_wallet);
    }
    function revokeWallet(address _wallet) external {
        require(tx.origin == dao, "!dao");

        wallets[_wallet] = false;

        emit RevokeWallet(_wallet);
    }

    function check(address _wallet) external view returns (bool) {
        bool _check = wallets[_wallet];
        if (_check) {
            return _check;
        } else {
            if (checker != address(0)) {
                return SmartWalletChecker(checker).check(_wallet);
            }
        }
        return false;
    }
}
