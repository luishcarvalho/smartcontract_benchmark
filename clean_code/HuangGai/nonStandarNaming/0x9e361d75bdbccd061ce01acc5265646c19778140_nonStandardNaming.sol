
















pragma solidity 0.5.12;

contract DSPauseAbstract {
    function SETOWNER297(address) external;
    function SETAUTHORITY462(address) external;
    function SETDELAY997(uint256) external;
    function PLANS194(bytes32) external view returns (bool);
    function PROXY33() external view returns (address);
    function DELAY572() external view returns (uint256);
    function PLOT308(address, bytes32, bytes calldata, uint256) external;
    function DROP835(address, bytes32, bytes calldata, uint256) external;
    function EXEC528(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

contract JugAbstract {
    function WARDS993(address) external view returns (uint256);
    function RELY27(address) external;
    function DENY29(address) external;
    function ILKS89(bytes32) external view returns (uint256, uint256);
    function VAT322() external view returns (address);
    function VOW865() external view returns (address);
    function BASE98() external view returns (address);
    function INIT382(bytes32) external;
    function FILE935(bytes32, bytes32, uint256) external;
    function FILE935(bytes32, uint256) external;
    function FILE935(bytes32, address) external;
    function DRIP851(bytes32) external returns (uint256);
}

contract VatAbstract {
    function WARDS993(address) external view returns (uint256);
    function RELY27(address) external;
    function DENY29(address) external;
    function CAN701(address, address) external view returns (uint256);
    function HOPE401(address) external;
    function NOPE804(address) external;
    function ILKS89(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function URNS72(bytes32, address) external view returns (uint256, uint256);
    function GEM847(bytes32, address) external view returns (uint256);
    function DAI766(address) external view returns (uint256);
    function SIN979(address) external view returns (uint256);
    function DEBT96() external view returns (uint256);
    function VICE796() external view returns (uint256);
    function LINE365() external view returns (uint256);
    function LIVE39() external view returns (uint256);
    function INIT382(bytes32) external;
    function FILE935(bytes32, uint256) external;
    function FILE935(bytes32, bytes32, uint256) external;
    function CAGE573() external;
    function SLIP893(bytes32, address, int256) external;
    function FLUX455(bytes32, address, address, uint256) external;
    function MOVE486(address, address, uint256) external;
    function FROB749(bytes32, address, address, address, int256, int256) external;
    function FORK68(bytes32, address, address, int256, int256) external;
    function GRAB867(bytes32, address, address, address, int256, int256) external;
    function HEAL281(uint256) external;
    function SUCK979(address, address, uint256) external;
    function FOLD739(bytes32, address, int256) external;
}

contract VowAbstract {
    function WARDS993(address) external view returns (uint256);
    function RELY27(address usr) external;
    function DENY29(address usr) external;
    function VAT322() external view returns (address);
    function FLAPPER608() external view returns (address);
    function FLOPPER190() external view returns (address);
    function SIN979(uint256) external view returns (uint256);
    function SIN979() external view returns (uint256);
    function ASH807() external view returns (uint256);
    function WAIT426() external view returns (uint256);
    function DUMP329() external view returns (uint256);
    function SUMP140() external view returns (uint256);
    function BUMP430() external view returns (uint256);
    function HUMP834() external view returns (uint256);
    function LIVE39() external view returns (uint256);
    function FILE935(bytes32, uint256) external;
    function FILE935(bytes32, address) external;
    function FESS945(uint256) external;
    function FLOG837(uint256) external;
    function HEAL281(uint256) external;
    function KISS865(uint256) external;
    function FLOP497() external returns (uint256);
    function FLAP923() external returns (uint256);
    function CAGE573() external;
}

contract IlkRegistryAbstract {
    function WARDS993(address) external view returns (uint256);
    function RELY27(address) external;
    function DENY29(address) external;
    function VAT322() external view returns (address);
    function CAT738() external view returns (address);
    function SPOT274() external view returns (address);
    function ILKDATA365(bytes32) external view returns (
        uint256,
        address,
        address,
        address,
        address,
        uint256,
        string memory,
        string memory
    );
    function ILKS89() external view returns (bytes32[] memory);
    function ILKS89(uint) external view returns (bytes32);
    function ADD269(address) external;
    function REMOVE614(bytes32) external;
    function REMOVEAUTH234(bytes32) external;
    function FILE935(bytes32, bytes32, address) external;
    function FILE935(bytes32, bytes32, uint256) external;
    function FILE935(bytes32, bytes32, string calldata) external;
    function COUNT649() external view returns (uint256);
    function LIST141() external view returns (bytes32[] memory);
    function LIST141(uint256, uint256) external view returns (bytes32[] memory);
    function GET51(uint256) external view returns (bytes32);
    function INFO652(bytes32) external view returns (
        string memory,
        string memory,
        uint256,
        address,
        address,
        address,
        address
    );
    function POS804(bytes32) external view returns (uint256);
    function GEM847(bytes32) external view returns (address);
    function PIP889(bytes32) external view returns (address);
    function JOIN697(bytes32) external view returns (address);
    function FLIP981(bytes32) external view returns (address);
    function DEC837(bytes32) external view returns (uint256);
    function SYMBOL988(bytes32) external view returns (string memory);
    function NAME950(bytes32) external view returns (string memory);
}

contract SpellAction {




    string constant public description524 =
        "2020-08-14 MakerDAO Weekly Executive Spell | Hash: 0x97294bc0de2100192a54a618351a84574e5d1998da234152e68b4065ac9bea0f";







    address constant mcd_vat35         = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant mcd_jug497         = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant mcd_vow892         = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant ilk_registry964    = 0xbE4F921cdFEf2cF5080F9Cf00CC2c14F1F96Bd07;

    uint256 constant million677  = 10 ** 6;
    uint256 constant rad54      = 10 ** 45;







    uint256 constant six_pct_rate891       = 1000000001847694957439350562;
    uint256 constant fortyfour_pct_rate631 = 1000000011562757347033522598;

    function EXECUTE336() external {
        bytes32[] memory ilks = IlkRegistryAbstract(ilk_registry964).LIST141();

        for(uint i = 0; i < ilks.length; i++) {

            VatAbstract(mcd_vat35).FILE935(ilks[i], "dust", 100 * rad54);
        }







        JugAbstract(mcd_jug497).DRIP851("MANA-A");
        JugAbstract(mcd_jug497).FILE935("MANA-A", "duty", six_pct_rate891);







        JugAbstract(mcd_jug497).DRIP851("USDC-B");
        JugAbstract(mcd_jug497).FILE935("USDC-B", "duty", fortyfour_pct_rate631);


        VowAbstract(mcd_vow892).FILE935("hump", 2 * million677 * rad54);
    }
}

contract DssSpell {
    DSPauseAbstract public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    function DESCRIPTION887() public view returns (string memory) {
        return SpellAction(action).description524();
    }

    function SCHEDULE900() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).DELAY572();
        pause.PLOT308(action, tag, sig, eta);
    }

    function CAST355() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.EXEC528(action, tag, sig, eta);
    }
}
