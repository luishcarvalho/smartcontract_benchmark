


















pragma solidity 0.5.12;

interface DSPauseAbstract {
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

interface VatAbstract {
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
}

interface MedianAbstract {
    function kiss(address) external;
    function diss(address) external;
}

contract SpellAction {






    address constant MCD_VAT     = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    address constant ETHBTC      = 0x81A679f98b63B3dDf2F17CB5619f4d6775b3c5ED;

    address constant tBTC        = 0xA3F68d722FBa26173aB64697B4625d4aD0F4C818;
    address constant tBTC_OLD    = 0x3b995E9f719Cb5F4b106F795B01760a11d083823;


    uint256 constant MILLION  = 10 ** 6;
    uint256 constant RAD      = 10 ** 45;

    function execute() public {




        VatAbstract(MCD_VAT).file("Line", 823 * MILLION * RAD);





        VatAbstract(MCD_VAT).file("USDC-A", "line", 100 * MILLION * RAD);



        MedianAbstract(ETHBTC).kiss(tBTC);

        MedianAbstract(ETHBTC).diss(tBTC_OLD);
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




    string constant public description =
        "2020-09-11 MakerDAO Executive Spell | Hash: 0x54ead845e3b3dda69b7b5eede7c0150cd37f68302b7379deba19cbaee56a1ca6";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
