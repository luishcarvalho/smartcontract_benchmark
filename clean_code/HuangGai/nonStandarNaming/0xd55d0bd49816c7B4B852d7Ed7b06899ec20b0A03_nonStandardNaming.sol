

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function BALANCEOF701(address) external view returns (uint);
    function TRANSFER721(address, uint) external returns (bool);
    function APPROVE366(address, uint) external;
}

interface ListInterface {
    struct AccountLink {
        address first;
        address last;
        uint64 count;
    }

    function ACCOUNTID562(address) external view returns (uint64);
    function ACCOUNTLINK6(uint) external view returns (AccountLink memory);
}

interface AccountInterface {
    function ISAUTH876(address) external view returns (bool);
    function CAST83(
        address[] calldata _targets,
        bytes[] calldata _datas,
        address _origin
    ) external payable;
}

interface IndexInterface {
    function BUILD362(
        address _owner,
        uint accountVersion,
        address _origin
    ) external returns (address _account);
    function BUILDWITHCAST236(
        address _owner,
        uint accountVersion,
        address[] calldata _targets,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (address _account);
}

interface ManagerLike {
    function OWNS994(uint) external view returns (address);
    function GIVE577(uint, address) external;
}


contract DSMath {

    function ADD218(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function MUL859(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant wad323 = 10 ** 18;

    function WMUL294(uint x, uint y) internal pure returns (uint z) {
        z = ADD218(MUL859(x, y), wad323 / 2) / wad323;
    }

    function WDIV453(uint x, uint y) internal pure returns (uint z) {
        z = ADD218(MUL859(x, wad323), y / 2) / y;
    }

}

contract Helpers is DSMath {


    function GETADDRESSETH874() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }


    function GETINDEXADDRESS602() internal pure returns (address) {
        return 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
    }


    function GETLISTADDRESS834() internal pure returns (address) {
        return 0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb;
    }


    function GETMCDMANAGER535() internal pure returns (address) {
        return 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    }

}

contract MigrateProxy is Helpers {

    event LOGMIGRATE511(address dsa, address[] tokens, address[] ctokens, uint[] vaults);

    function MIGRATEVAULTS534(address dsa, uint[] memory vaults) private {
        ManagerLike managerContract = ManagerLike(GETMCDMANAGER535());
        for (uint i = 0; i < vaults.length; i++) managerContract.GIVE577(vaults[i], dsa);
    }

    function MIGRATEALLOWANCES163(address dsa, address[] memory tokens) private {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            TokenInterface tokenContract = TokenInterface(token);
            uint tokenAmt = tokenContract.BALANCEOF701(address(this));
            if (tokenAmt > 0) tokenContract.APPROVE366(dsa, tokenAmt);
        }
    }

    function MIGRATETOKENS687(address dsa, address[] memory tokens) private {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            TokenInterface tokenContract = TokenInterface(token);
            uint tokenAmt = tokenContract.BALANCEOF701(address(this));
            if (tokenAmt > 0) tokenContract.TRANSFER721(dsa, tokenAmt);
        }
    }

    struct MigrateData {
        uint[] vaults;
        address[] tokens;
        address[] ctokens;
    }


    function MIGRATE394(
        address[] calldata targets,
        bytes[] calldata calldatas,
        MigrateData calldata migrateData
    ) external payable {
        uint _len = migrateData.ctokens.length;
        address _dsa;
        if (_len > 0) {
            _dsa = IndexInterface(GETINDEXADDRESS602()).BUILD362(
                address(this),
                1,
                address(0)
            );

            MIGRATEALLOWANCES163(_dsa, migrateData.ctokens);
            AccountInterface dsaContract = AccountInterface(_dsa);
            dsaContract.CAST83.value(address(this).balance)(targets, calldatas, address(0));
            require(dsaContract.ISAUTH876(msg.sender), "msg.sender-is-not-auth.");
            ListInterface listContract = ListInterface(GETLISTADDRESS834());
            uint64 dsaId = listContract.ACCOUNTID562(_dsa);
            require(listContract.ACCOUNTLINK6(dsaId).count == 1, "more-than-one-auth");
        } else {
            _dsa = IndexInterface(GETINDEXADDRESS602()).BUILD362(
                msg.sender,
                1,
                address(0)
            );
        }
        MIGRATEVAULTS534(_dsa, migrateData.vaults);
        MIGRATETOKENS687(_dsa, migrateData.tokens);

        emit LOGMIGRATE511(_dsa, migrateData.tokens, migrateData.ctokens, migrateData.vaults);
    }
}
