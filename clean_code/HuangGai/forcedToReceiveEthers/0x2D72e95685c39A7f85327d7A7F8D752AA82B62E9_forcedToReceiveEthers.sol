


















pragma solidity 0.5.12;


interface DSPauseAbstract {
    function setOwner(address) external;
    function setAuthority(address) external;
    function setDelay(uint256) external;
    function plans(bytes32) external view returns (bool);
    function proxy() external view returns (address);
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function drop(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}


interface VatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function can(address, address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function gem(bytes32, address) external view returns (uint256);
    function dai(address) external view returns (uint256);
    function sin(address) external view returns (uint256);
    function debt() external view returns (uint256);
    function vice() external view returns (uint256);
    function Line() external view returns (uint256);
    function live() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function cage() external;
    function slip(bytes32, address, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function fork(bytes32, address, address, int256, int256) external;
    function grab(bytes32, address, address, address, int256, int256) external;
    function heal(uint256) external;
    function suck(address, address, uint256) external;
    function fold(bytes32, address, int256) external;
}


interface CatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function box() external view returns (uint256);
    function litter() external view returns (uint256);
    function ilks(bytes32) external view returns (address, uint256, uint256);
    function live() external view returns (uint256);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, address) external;
    function bite(bytes32, address) external returns (uint256);
    function claw(uint256) external;
    function cage() external;
}


interface JugAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external view returns (uint256, uint256);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function base() external view returns (address);
    function init(bytes32) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function drip(bytes32) external returns (uint256);
}


interface FlipAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function bids(uint256) external view returns (uint256, uint256, address, uint48, uint48, address, address, uint256);
    function vat() external view returns (address);
    function cat() external view returns (address);
    function ilk() external view returns (bytes32);
    function beg() external view returns (uint256);
    function ttl() external view returns (uint48);
    function tau() external view returns (uint48);
    function kicks() external view returns (uint256);
    function file(bytes32, uint256) external;
    function kick(address, address, uint256, uint256, uint256) external returns (uint256);
    function tick(uint256) external;
    function tend(uint256, uint256, uint256) external;
    function dent(uint256, uint256, uint256) external;
    function deal(uint256) external;
    function yank(uint256) external;
}


interface SpotAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external view returns (address, uint256);
    function vat() external view returns (address);
    function par() external view returns (uint256);
    function live() external view returns (uint256);
    function file(bytes32, bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function poke(bytes32) external;
    function cage() external;
}


interface OsmAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function stopped() external view returns (uint256);
    function src() external view returns (address);
    function hop() external view returns (uint16);
    function zzz() external view returns (uint64);
    function cur() external view returns (uint128, uint128);
    function nxt() external view returns (uint128, uint128);
    function bud(address) external view returns (uint256);
    function stop() external;
    function start() external;
    function change(address) external;
    function step(uint16) external;
    function void() external;
    function pass() external view returns (bool);
    function poke() external;
    function peek() external view returns (bytes32, bool);
    function peep() external view returns (bytes32, bool);
    function read() external view returns (bytes32);
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
}


interface OsmMomAbstract {
    function owner() external view returns (address);
    function authority() external view returns (address);
    function osms(bytes32) external view returns (address);
    function setOsm(bytes32, address) external;
    function setOwner(address) external;
    function setAuthority(address) external;
    function stop(bytes32) external;
}


interface MedianAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function age() external view returns (uint32);
    function wat() external view returns (bytes32);
    function bar() external view returns (uint256);
    function orcl(address) external view returns (uint256);
    function bud(address) external view returns (uint256);
    function slot(uint8) external view returns (address);
    function read() external view returns (uint256);
    function peek() external view returns (uint256, bool);
    function lift(address[] calldata) external;
    function drop(address[] calldata) external;
    function setBar(uint256) external;
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
    function poke(uint256[] calldata, uint256[] calldata, uint8[] calldata, bytes32[] calldata, bytes32[] calldata) external;
}


interface GemJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}


interface FlipperMomAbstract {
    function owner() external returns (address);
    function setOwner(address) external;
    function authority() external returns (address);
    function setAuthority(address) external;
    function cat() external returns (address);
    function rely(address) external;
    function deny(address) external;
}


interface IlkRegistryAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function cat() external view returns (address);
    function spot() external view returns (address);
    function ilkData(bytes32) external view returns (
        uint256,
        address,
        address,
        address,
        address,
        uint256,
        string memory,
        string memory
    );
    function ilks() external view returns (bytes32[] memory);
    function ilks(uint) external view returns (bytes32);
    function add(address) external;
    function remove(bytes32) external;
    function removeAuth(bytes32) external;
    function file(bytes32, bytes32, address) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, string calldata) external;
    function count() external view returns (uint256);
    function list() external view returns (bytes32[] memory);
    function list(uint256, uint256) external view returns (bytes32[] memory);
    function get(uint256) external view returns (bytes32);
    function info(bytes32) external view returns (
        string memory,
        string memory,
        uint256,
        address,
        address,
        address,
        address
    );
    function pos(bytes32) external view returns (uint256);
    function gem(bytes32) external view returns (address);
    function pip(bytes32) external view returns (address);
    function join(bytes32) external view returns (address);
    function flip(bytes32) external view returns (address);
    function dec(bytes32) external view returns (uint256);
    function symbol(bytes32) external view returns (string memory);
    function name(bytes32) external view returns (string memory);
}

contract ERC20 {
    function decimals() external view returns (uint);
}

contract SpellAction {






    address constant MCD_VAT                = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_CAT                = 0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea;
    address constant MCD_JUG                = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_SPOT               = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant MCD_END                = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant FLIPPER_MOM            = 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472;
    address constant OSM_MOM                = 0x76416A4d5190d071bfed309861527431304aA14f;
    address constant ILK_REGISTRY           = 0x8b4ce5DCbb01e0e1f0521cd8dCfb31B308E52c24;

    address constant USDT                   = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant MCD_JOIN_USDT_A        = 0x0Ac6A1D74E84C2dF9063bDDc31699FF2a2BB22A2;
    address constant MCD_FLIP_USDT_A        = 0x667F41d0fDcE1945eE0f56A79dd6c142E37fCC26;
    address constant PIP_USDT               = 0x7a5918670B0C390aD25f7beE908c1ACc2d314A3C;

    address constant PAXUSD                 = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
    address constant MCD_JOIN_PAXUSD_A      = 0x7e62B7E279DFC78DEB656E34D6a435cC08a44666;
    address constant MCD_FLIP_PAXUSD_A      = 0x52D5D1C05CC79Fc24A629Cb24cB06C5BE5d766E7;
    address constant PIP_PAXUSD             = 0x043B963E1B2214eC90046167Ea29C2c8bDD7c0eC;




    address constant ARGENT                 = 0x130431b4560Cd1d74A990AE86C337a33171FF3c6;

    address constant MYCRYPTO               = 0x3CB645a8f10Fb7B0721eaBaE958F77a878441Cb9;


    address constant USDTUSD                = 0x56D4bBF358D7790579b55eA6Af3f605BcA2c0C3A;
    address constant MANAUSD                = 0x681c4F8f69cF68852BAd092086ffEaB31F5B812c;
    address constant BATUSD                 = 0x18B4633D6E39870f398597f3c1bA8c4A41294966;
    address constant BTCUSD                 = 0xe0F30cb149fAADC7247E953746Be9BbBB6B5751f;
    address constant ETHBTC                 = 0x81A679f98b63B3dDf2F17CB5619f4d6775b3c5ED;
    address constant ETHUSD                 = 0x64DE91F5A373Cd4c28de3600cB34C7C6cE410C85;
    address constant KNCUSD                 = 0x83076a2F42dc1925537165045c9FDe9A4B71AD97;
    address constant ZRXUSD                 = 0x956ecD6a9A9A0d84e8eB4e6BaaC09329E202E55e;


    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;







    uint256 constant TWO_PCT_RATE           = 1000000000627937192491029810;
    uint256 constant FOUR_PCT_RATE          = 1000000001243680656318820312;
    uint256 constant SIX_PCT_RATE           = 1000000001847694957439350562;
    uint256 constant TEN_PCT_RATE           = 1000000003022265980097387650;
    uint256 constant FOURTY_EIGHT_PCT_RATE  = 1000000012431573129530493155;

    function execute() external {




        VatAbstract(MCD_VAT).file("Line", 763 * MILLION * RAD);





        VatAbstract(MCD_VAT).file("WBTC-A", "line", 120 * MILLION * RAD);




        JugAbstract(MCD_JUG).drip("BAT-A");
        JugAbstract(MCD_JUG).file("BAT-A", "duty", TWO_PCT_RATE);




        JugAbstract(MCD_JUG).drip("USDC-A");
        JugAbstract(MCD_JUG).file("USDC-A", "duty", TWO_PCT_RATE);




        JugAbstract(MCD_JUG).drip("USDC-B");
        JugAbstract(MCD_JUG).file("USDC-B", "duty", FOURTY_EIGHT_PCT_RATE);




        JugAbstract(MCD_JUG).drip("WBTC-A");
        JugAbstract(MCD_JUG).file("WBTC-A", "duty", TWO_PCT_RATE);




        JugAbstract(MCD_JUG).drip("KNC-A");
        JugAbstract(MCD_JUG).file("KNC-A", "duty", TWO_PCT_RATE);




        JugAbstract(MCD_JUG).drip("ZRX-A");
        JugAbstract(MCD_JUG).file("ZRX-A", "duty", TWO_PCT_RATE);




        JugAbstract(MCD_JUG).drip("MANA-A");
        JugAbstract(MCD_JUG).file("MANA-A", "duty", TEN_PCT_RATE);


        address[] memory argent = new address[](1);
        argent[0] = ARGENT;


        address[] memory mycrypto = new address[](1);
        mycrypto[0] = MYCRYPTO;


        MedianAbstract(BATUSD).lift(argent);
        MedianAbstract(BTCUSD).lift(argent);
        MedianAbstract(ETHBTC).lift(argent);
        MedianAbstract(ETHUSD).lift(argent);
        MedianAbstract(KNCUSD).lift(argent);
        MedianAbstract(ZRXUSD).lift(argent);
        MedianAbstract(USDTUSD).lift(argent);
        MedianAbstract(MANAUSD).lift(argent);


        MedianAbstract(BATUSD).lift(mycrypto);
        MedianAbstract(BTCUSD).lift(mycrypto);
        MedianAbstract(ETHBTC).lift(mycrypto);
        MedianAbstract(ETHUSD).lift(mycrypto);
        MedianAbstract(KNCUSD).lift(mycrypto);
        MedianAbstract(ZRXUSD).lift(mycrypto);
        MedianAbstract(USDTUSD).lift(mycrypto);
        MedianAbstract(MANAUSD).lift(mycrypto);





        bytes32 ilkUSDTA = "USDT-A";


        require(GemJoinAbstract(MCD_JOIN_USDT_A).vat() == MCD_VAT,                  "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_USDT_A).ilk() == ilkUSDTA,                 "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_USDT_A).gem() == USDT,   	                "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_USDT_A).dec() == ERC20(USDT).decimals(),   "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_USDT_A).vat()    == MCD_VAT,                  "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_USDT_A).ilk()    == ilkUSDTA,                 "flip-ilk-not-match");


        SpotAbstract(MCD_SPOT).file(ilkUSDTA, "pip", PIP_USDT);


        CatAbstract(MCD_CAT).file(ilkUSDTA, "flip", MCD_FLIP_USDT_A);


        VatAbstract(MCD_VAT).init(ilkUSDTA);

        JugAbstract(MCD_JUG).init(ilkUSDTA);


        VatAbstract(MCD_VAT).rely(MCD_JOIN_USDT_A);


        CatAbstract(MCD_CAT).rely(MCD_FLIP_USDT_A);


        FlipAbstract(MCD_FLIP_USDT_A).rely(MCD_CAT);


        FlipAbstract(MCD_FLIP_USDT_A).rely(MCD_END);


        FlipAbstract(MCD_FLIP_USDT_A).rely(FLIPPER_MOM);


        OsmAbstract(PIP_USDT).rely(OSM_MOM);
        MedianAbstract(OsmAbstract(PIP_USDT).src()).kiss(PIP_USDT);
        OsmAbstract(PIP_USDT).kiss(MCD_SPOT);
        OsmAbstract(PIP_USDT).kiss(MCD_END);
        OsmMomAbstract(OSM_MOM).setOsm(ilkUSDTA, PIP_USDT);


        VatAbstract(MCD_VAT).file( ilkUSDTA, "line", 10 * MILLION * RAD   );
        VatAbstract(MCD_VAT).file( ilkUSDTA, "dust", 100 * RAD            );
        CatAbstract(MCD_CAT).file( ilkUSDTA, "dunk", 50 * THOUSAND * RAD  );
        CatAbstract(MCD_CAT).file( ilkUSDTA, "chop", 113 * WAD / 100      );
        JugAbstract(MCD_JUG).file( ilkUSDTA, "duty", SIX_PCT_RATE         );

        FlipAbstract(MCD_FLIP_USDT_A).file(  "beg" , 103 * WAD / 100      );
        FlipAbstract(MCD_FLIP_USDT_A).file(  "ttl" , 6 hours              );
        FlipAbstract(MCD_FLIP_USDT_A).file(  "tau" , 6 hours              );

        SpotAbstract(MCD_SPOT).file(ilkUSDTA, "mat",  150 * RAY / 100     );
        SpotAbstract(MCD_SPOT).poke(ilkUSDTA);

        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_USDT_A);




        bytes32 ilkPAXUSDA = "PAXUSD-A";


        require(GemJoinAbstract(MCD_JOIN_PAXUSD_A).vat() == MCD_VAT,                    "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_PAXUSD_A).ilk() == ilkPAXUSDA,                 "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_PAXUSD_A).gem() == PAXUSD,                     "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_PAXUSD_A).dec() == ERC20(PAXUSD).decimals(),   "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_PAXUSD_A).vat()    == MCD_VAT,                    "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_PAXUSD_A).ilk()    == ilkPAXUSDA,                 "flip-ilk-not-match");


        SpotAbstract(MCD_SPOT).file(ilkPAXUSDA, "pip", PIP_PAXUSD);


        CatAbstract(MCD_CAT).file(ilkPAXUSDA, "flip", MCD_FLIP_PAXUSD_A);


        VatAbstract(MCD_VAT).init(ilkPAXUSDA);

        JugAbstract(MCD_JUG).init(ilkPAXUSDA);


        VatAbstract(MCD_VAT).rely(MCD_JOIN_PAXUSD_A);


        CatAbstract(MCD_CAT).rely(MCD_FLIP_PAXUSD_A);



        FlipAbstract(MCD_FLIP_PAXUSD_A).rely(MCD_CAT);


        FlipAbstract(MCD_FLIP_PAXUSD_A).rely(MCD_END);


        FlipAbstract(MCD_FLIP_PAXUSD_A).rely(FLIPPER_MOM);


        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_PAXUSD_A);

        VatAbstract(MCD_VAT).file(ilkPAXUSDA,   "line"  , 5 * MILLION * RAD    );
        VatAbstract(MCD_VAT).file(ilkPAXUSDA,   "dust"  , 100 * RAD            );
        CatAbstract(MCD_CAT).file(ilkPAXUSDA,   "dunk"  , 50 * THOUSAND * RAD  );
        CatAbstract(MCD_CAT).file(ilkPAXUSDA,   "chop"  , 113 * WAD / 100      );
        JugAbstract(MCD_JUG).file(ilkPAXUSDA,   "duty"  , TWO_PCT_RATE         );
        FlipAbstract(MCD_FLIP_PAXUSD_A).file(   "beg"   , 103 * WAD / 100      );
        FlipAbstract(MCD_FLIP_PAXUSD_A).file(   "ttl"   , 6 hours              );
        FlipAbstract(MCD_FLIP_PAXUSD_A).file(   "tau"   , 6 hours              );
        SpotAbstract(MCD_SPOT).file(ilkPAXUSDA, "mat"   , 120 * RAY / 100      );
        SpotAbstract(MCD_SPOT).poke(ilkPAXUSDA);

        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_PAXUSD_A);
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
        "2020-09-04 MakerDAO Executive Spell | Hash: 0x3c35701633399b48090f4c805686ebeeebcc86f6d05b354531f3bd0059ee48dd";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    modifier officeHours {


        require(now >= 1599573600);

        uint day = (now / 1 days + 3) % 7;
        require(day < 5, "Can only be cast on a weekday");
        uint hour = now / 1 hours % 24;
        require(hour >= 14 && hour < 21, "Outside office hours");
        _;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(address(this).balance == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() officeHours public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
