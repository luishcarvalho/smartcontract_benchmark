


pragma solidity =0.5.12 >0.4.13 >=0.4.23 >=0.5.12;





interface DSPauseAbstract {
    function SETOWNER590(address) external;
    function SETAUTHORITY631(address) external;
    function SETDELAY362(uint256) external;
    function PLANS667(bytes32) external view returns (bool);
    function PROXY384() external view returns (address);
    function DELAY460() external view returns (uint256);
    function PLOT131(address, bytes32, bytes calldata, uint256) external;
    function DROP945(address, bytes32, bytes calldata, uint256) external;
    function EXEC84(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}





interface JugAbstract {
    function WARDS9(address) external view returns (uint256);
    function RELY664(address) external;
    function DENY283(address) external;
    function ILKS778(bytes32) external view returns (uint256, uint256);
    function VAT142() external view returns (address);
    function VOW391() external view returns (address);
    function BASE726() external view returns (address);
    function INIT893(bytes32) external;
    function FILE40(bytes32, bytes32, uint256) external;
    function FILE40(bytes32, uint256) external;
    function FILE40(bytes32, address) external;
    function DRIP219(bytes32) external returns (uint256);
}





interface MedianAbstract {
    function WARDS9(address) external view returns (uint256);
    function RELY664(address) external;
    function DENY283(address) external;
    function AGE221() external view returns (uint32);
    function WAT475() external view returns (bytes32);
    function BAR501() external view returns (uint256);
    function ORCL736(address) external view returns (uint256);
    function BUD134(address) external view returns (uint256);
    function SLOT890(uint8) external view returns (address);
    function READ871() external view returns (uint256);
    function PEEK743() external view returns (uint256, bool);
    function LIFT208(address[] calldata) external;
    function DROP945(address[] calldata) external;
    function SETBAR416(uint256) external;
    function KISS951(address) external;
    function DISS455(address) external;
    function KISS951(address[] calldata) external;
    function DISS455(address[] calldata) external;
    function POKE311(uint256[] calldata, uint256[] calldata, uint8[] calldata, bytes32[] calldata, bytes32[] calldata) external;
}





interface SpotAbstract {
    function WARDS9(address) external view returns (uint256);
    function RELY664(address) external;
    function DENY283(address) external;
    function ILKS778(bytes32) external view returns (address, uint256);
    function VAT142() external view returns (address);
    function PAR826() external view returns (uint256);
    function LIVE534() external view returns (uint256);
    function FILE40(bytes32, bytes32, address) external;
    function FILE40(bytes32, uint256) external;
    function FILE40(bytes32, bytes32, uint256) external;
    function POKE311(bytes32) external;
    function CAGE3() external;
}





interface VatAbstract {
    function WARDS9(address) external view returns (uint256);
    function RELY664(address) external;
    function DENY283(address) external;
    function CAN343(address, address) external view returns (uint256);
    function HOPE769(address) external;
    function NOPE162(address) external;
    function ILKS778(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function URNS690(bytes32, address) external view returns (uint256, uint256);
    function GEM16(bytes32, address) external view returns (uint256);
    function DAI867(address) external view returns (uint256);
    function SIN509(address) external view returns (uint256);
    function DEBT851() external view returns (uint256);
    function VICE72() external view returns (uint256);
    function LINE452() external view returns (uint256);
    function LIVE534() external view returns (uint256);
    function INIT893(bytes32) external;
    function FILE40(bytes32, uint256) external;
    function FILE40(bytes32, bytes32, uint256) external;
    function CAGE3() external;
    function SLIP467(bytes32, address, int256) external;
    function FLUX370(bytes32, address, address, uint256) external;
    function MOVE182(address, address, uint256) external;
    function FROB273(bytes32, address, address, address, int256, int256) external;
    function FORK393(bytes32, address, address, int256, int256) external;
    function GRAB4(bytes32, address, address, address, int256, int256) external;
    function HEAL121(uint256) external;
    function SUCK524(address, address, uint256) external;
    function FOLD129(bytes32, address, int256) external;
}



























interface GemJoin6Like {
    function SETIMPLEMENTATION850(address, uint256) external;
}

contract SpellAction {






    address constant mcd_join_tusd_a973  = 0x4454aF7C8bb9463203b66C816220D41ED7837f44;
    address constant mcd_jug931          = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant mcd_spot639         = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant mcd_vat427          = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant tusd_impl_new757    = 0x7a9701453249e84fd0D5AfE5951e9cBe9ed2E90f;
    address constant median_manausd649   = 0x681c4F8f69cF68852BAd092086ffEaB31F5B812c;
    address constant gitcoin_feed_old89 = 0xA4188B523EccECFbAC49855eB52eA0b55c4d56dd;
    address constant gitcoin_feed_new879 = 0x77EB6CF8d732fe4D92c427fCdd83142DB3B742f7;


    uint256 constant thousand409 = 10 ** 3;
    uint256 constant million93  = 10 ** 6;
    uint256 constant wad294      = 10 ** 18;
    uint256 constant ray683      = 10 ** 27;
    uint256 constant rad264      = 10 ** 45;







    uint256 constant four_pct_rate701   = 1000000001243680656318820312;
    uint256 constant eight_pct_rate301  = 1000000002440418608258400030;
    uint256 constant twelve_pct_rate857 = 1000000003593629043335673582;
    uint256 constant fifty_pct_rate325  = 1000000012857214317438491659;

    function EXECUTE44() external {




        VatAbstract(mcd_vat427).FILE40("Line", 1196 * million93 * rad264);





        VatAbstract(mcd_vat427).FILE40("USDC-A", "line", 400 * million93 * rad264);





        VatAbstract(mcd_vat427).FILE40("TUSD-A", "line", 50 * million93 * rad264);





        SpotAbstract(mcd_spot639).FILE40("USDC-A", "mat", 101 * ray683 / 100);
        SpotAbstract(mcd_spot639).POKE311("USDC-A");





        SpotAbstract(mcd_spot639).FILE40("TUSD-A", "mat", 101 * ray683 / 100);
        SpotAbstract(mcd_spot639).POKE311("TUSD-A");





        SpotAbstract(mcd_spot639).FILE40("PAXUSD-A", "mat", 101 * ray683 / 100);
        SpotAbstract(mcd_spot639).POKE311("PAXUSD-A");





        JugAbstract(mcd_jug931).DRIP219("BAT-A");
        JugAbstract(mcd_jug931).FILE40("BAT-A", "duty", four_pct_rate701);





        JugAbstract(mcd_jug931).DRIP219("USDC-A");
        JugAbstract(mcd_jug931).FILE40("USDC-A", "duty", four_pct_rate701);





        JugAbstract(mcd_jug931).DRIP219("USDC-B");
        JugAbstract(mcd_jug931).FILE40("USDC-B", "duty", fifty_pct_rate325);





        JugAbstract(mcd_jug931).DRIP219("WBTC-A");
        JugAbstract(mcd_jug931).FILE40("WBTC-A", "duty", four_pct_rate701);





        JugAbstract(mcd_jug931).DRIP219("TUSD-A");
        JugAbstract(mcd_jug931).FILE40("TUSD-A", "duty", four_pct_rate701);





        JugAbstract(mcd_jug931).DRIP219("KNC-A");
        JugAbstract(mcd_jug931).FILE40("KNC-A", "duty", four_pct_rate701);





        JugAbstract(mcd_jug931).DRIP219("ZRX-A");
        JugAbstract(mcd_jug931).FILE40("ZRX-A", "duty", four_pct_rate701);





        JugAbstract(mcd_jug931).DRIP219("MANA-A");
        JugAbstract(mcd_jug931).FILE40("MANA-A", "duty", twelve_pct_rate857);





        JugAbstract(mcd_jug931).DRIP219("USDT-A");
        JugAbstract(mcd_jug931).FILE40("USDT-A", "duty", eight_pct_rate301);





        JugAbstract(mcd_jug931).DRIP219("PAXUSD-A");
        JugAbstract(mcd_jug931).FILE40("PAXUSD-A", "duty", four_pct_rate701);




        GemJoin6Like(mcd_join_tusd_a973).SETIMPLEMENTATION850(tusd_impl_new757, 1);


        address[] memory drops = new address[](1);
        drops[0] = gitcoin_feed_old89;
        MedianAbstract(median_manausd649).DROP945(drops);

        address[] memory lifts = new address[](1);
        lifts[0] = gitcoin_feed_new879;
        MedianAbstract(median_manausd649).LIFT208(lifts);
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




    string constant public description372 =
        "2020-09-18 MakerDAO Executive Spell | Hash: 0xe942f72e80295685e39e303f8979560523beae8569daccfcea2f000b14a14abf";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }









    function SCHEDULE830() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).DELAY460();
        pause.PLOT131(action, tag, sig, eta);
    }

    function CAST998() public                 {
        require(!done, "spell-already-cast");
        done = true;
        pause.EXEC84(action, tag, sig, eta);
    }
}
