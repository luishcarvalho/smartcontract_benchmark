



pragma solidity 0.5.14;
pragma experimental ABIEncoderV2;

library Account {
    struct Info {
        address owner;
        uint256 number;
    }
}

library Monetary {
    struct Value {
        uint256 value;
    }
}

contract DyDx {
        function getAccountValues(Account.Info memory account) public view returns (Monetary.Value memory, Monetary.Value memory);
}


contract ProxyQuery {
    DyDx dydx;

    constructor() public {
        dydx = DyDx(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);
    }

    function queryValues(address[] memory accounts, uint256[] memory numbers ) public view returns (uint256[] memory) {
        uint256[] memory ret = new uint[](accounts.length);
        Account.Info memory account;
        Monetary.Value memory supplied;
        Monetary.Value memory borrowed;
        uint i;

        for (i = 0; i < accounts.length; i ++) {
            account.owner = accounts[i];
            account.number = numbers[i];
            (supplied, borrowed) = dydx.getAccountValues(account);
            if (block.number == 0) {
                ret[i] = 1000;
            } else {
                ret[i] = supplied.value*100/borrowed.value;
            }
        }
    }
}
