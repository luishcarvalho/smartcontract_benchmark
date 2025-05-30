


















pragma solidity 0.5.12;


contract DSPauseAbstract {
    function delay() public view returns (uint256);
    function plot(address, bytes32, bytes memory, uint256) public;
    function exec(address, bytes32, bytes memory, uint256) public returns (bytes memory);
}


contract PotAbstract {
    function file(bytes32, uint256) external;
    function drip() external returns (uint256);
}


contract JugAbstract {
    function file(bytes32, bytes32, uint256) external;
    function drip(bytes32) external returns (uint256);
}


contract VatAbstract {
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
}


contract FlipAbstract {
    function file(bytes32, uint256) external;
}


contract FlipperMomAbstract {
    function rely(address) external;
    function deny(address) external;
}

contract SpellAction {


    string  constant public description = "DEFCON-1 Emergency Spell";







    address constant public MCD_VAT =
        0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public MCD_JUG =
        0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public MCD_POT =
        0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant public MCD_FLIP_ETH_A =
        0xd8a04F5412223F513DC55F839574430f5EC15531;
    address constant public MCD_FLIP_BAT_A =
        0xaA745404d55f88C108A28c86abE7b5A1E7817c07;
    address constant public MCD_FLIP_WBTC_A =
        0x3E115d85D4d7253b05fEc9C0bB5b08383C2b0603;
    address constant public MCD_FLIP_USDC_A =
        0xE6ed1d09a19Bd335f051d78D5d22dF3bfF2c28B1;
    address constant public FLIPPER_MOM =
        0x9BdDB99625A711bf9bda237044924E34E8570f75;








    uint256 constant public    ZERO_PCT_RATE = 1000000000000000000000000000;
    uint256 constant public   FIFTY_PCT_RATE = 1000000012857214317438491659;

    uint256 constant public RAD = 10**45;
    uint256 constant public MILLION = 10**6;

    function execute() external {


        PotAbstract(MCD_POT).drip();
        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).drip("BAT-A");
        JugAbstract(MCD_JUG).drip("USDC-A");
        JugAbstract(MCD_JUG).drip("WBTC-A");








        uint256 DSR_RATE = ZERO_PCT_RATE;
        PotAbstract(MCD_POT).file("dsr", DSR_RATE);





        uint256 ETH_A_FEE = ZERO_PCT_RATE;
        JugAbstract(MCD_JUG).file("ETH-A", "duty", ETH_A_FEE);





        uint256 BAT_A_FEE = ZERO_PCT_RATE;
        JugAbstract(MCD_JUG).file("BAT-A", "duty", BAT_A_FEE);





        uint256 WBTC_A_FEE = ZERO_PCT_RATE;
        JugAbstract(MCD_JUG).file("WBTC-A", "duty", WBTC_A_FEE);





        uint256 USDC_A_FEE = FIFTY_PCT_RATE;
        JugAbstract(MCD_JUG).file("USDC-A", "duty", USDC_A_FEE);








        uint256 USDC_A_LINE = 40 * MILLION;
        VatAbstract(MCD_VAT).file("USDC-A", "line", USDC_A_LINE * RAD);






        (,,, uint256 saiLine,)   = VatAbstract(MCD_VAT).ilks("SAI");
        (,,, uint256 ethALine,)  = VatAbstract(MCD_VAT).ilks("ETH-A");
        (,,, uint256 batALine,)  = VatAbstract(MCD_VAT).ilks("BAT-A");
        (,,, uint256 wbtcALine,) = VatAbstract(MCD_VAT).ilks("WBTC-A");
        (,,, uint256 usdcALine,) = VatAbstract(MCD_VAT).ilks("USDC-A");
        uint256 GLOBAL_LINE =
            saiLine + ethALine + batALine + wbtcALine + usdcALine;
        VatAbstract(MCD_VAT).file("Line", GLOBAL_LINE);





        uint256 ETH_A_FLIP_TAU = 24 hours;
        FlipAbstract(MCD_FLIP_ETH_A).file(bytes32("tau"), ETH_A_FLIP_TAU);





        uint256 BAT_A_FLIP_TAU = 24 hours;
        FlipAbstract(MCD_FLIP_BAT_A).file(bytes32("tau"), BAT_A_FLIP_TAU);





        uint256 WBTC_A_FLIP_TAU = 24 hours;
        FlipAbstract(MCD_FLIP_WBTC_A).file(bytes32("tau"), WBTC_A_FLIP_TAU);





        uint256 USDC_A_FLIP_TAU = 24 hours;
        FlipAbstract(MCD_FLIP_USDC_A).file(bytes32("tau"), USDC_A_FLIP_TAU);












        FlipperMomAbstract(FLIPPER_MOM).rely(MCD_FLIP_ETH_A);
        FlipperMomAbstract(FLIPPER_MOM).rely(MCD_FLIP_BAT_A);
        FlipperMomAbstract(FLIPPER_MOM).rely(MCD_FLIP_WBTC_A);


    }
}

contract DssSpell {

    DSPauseAbstract  public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    uint256          public expiration;
    bool             public done;

    address constant public MCD_FLIP_ETH_A =
        0xd8a04F5412223F513DC55F839574430f5EC15531;
    address constant public MCD_FLIP_BAT_A =
        0xaA745404d55f88C108A28c86abE7b5A1E7817c07;
    address constant public MCD_FLIP_USDC_A =
        0xE6ed1d09a19Bd335f051d78D5d22dF3bfF2c28B1;
    address constant public MCD_FLIP_WBTC_A =
        0x3E115d85D4d7253b05fEc9C0bB5b08383C2b0603;
    address constant public FLIPPER_MOM =
        0x9BdDB99625A711bf9bda237044924E34E8570f75;

    uint256 constant internal MILLION = 10**6;
    uint256 constant public T2020_07_01_1200UTC = 1593604800;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = T2020_07_01_1200UTC;
    }

    function description() public view returns (string memory) {
        return SpellAction(action).description();
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(address(this).balance == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);









        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_ETH_A);
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_BAT_A);
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_WBTC_A);
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_USDC_A);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
