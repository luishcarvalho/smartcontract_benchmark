


















pragma solidity 0.5.12;

interface DSPauseAbstract {
    function proxy() external view returns (address);
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

interface JugAbstract {
    function file(bytes32, bytes32, uint256) external;
    function drip(bytes32) external returns (uint256);
}

interface MedianAbstract {
    function kiss(address) external;
    function kiss(address[] calldata) external;
}

interface OsmAbstract {
    function kiss(address) external;
}

interface VatAbstract {
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
}

interface MedianizerV1Abstract {
    function setAuthority(address) external;
    function setOwner(address) external;
    function setMin(uint96) external;
    function setNext(bytes12) external;
    function set(bytes12, address) external;
}

contract SpellAction {






    address constant MCD_JUG  = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_VAT  = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    address constant ETHUSD   = 0x64DE91F5A373Cd4c28de3600cB34C7C6cE410C85;
    address constant BTCUSD   = 0xe0F30cb149fAADC7247E953746Be9BbBB6B5751f;
    address constant PIP_WBTC = 0xf185d0682d50819263941e5f4EacC763CC5C6C42;

    address constant KYBER    = 0xe1BDEb1F71b1CD855b95D4Ec2d1BFdc092E00E4F;
    address constant DDEX     = 0x4935B1188EB940C39e22172cc5fe595E267706a1;
    address constant ETHUSDv1 = 0x729D19f657BD0614b4985Cf1D82531c67569197B;
    address constant YEARN    = 0x82c93333e4E295AA17a05B15092159597e823e8a;


    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;







    uint256 constant TWO_TWENTYFIVE_PCT_RATE    = 1000000000705562181084137268;
    uint256 constant FOUR_TWENTYFIVE_PCT_RATE   = 1000000001319814647332759691;
    uint256 constant EIGHT_TWENTYFIVE_PCT_RATE  = 1000000002513736079215619839;
    uint256 constant TWELVE_TWENTYFIVE_PCT_RATE = 1000000003664330950215446102;
    uint256 constant FIFTY_TWENTYFIVE_PCT_RATE  = 1000000012910019978921115695;

    function execute() external {




        VatAbstract(MCD_VAT).file("Line", 1401 * MILLION * RAD);





        VatAbstract(MCD_VAT).file("BAT-A", "line", 10 * MILLION * RAD);





        VatAbstract(MCD_VAT).file("USDC-A", "line", 485 * MILLION * RAD);





        VatAbstract(MCD_VAT).file("TUSD-A", "line", 135 * MILLION * RAD);





        VatAbstract(MCD_VAT).file("PAXUSD-A", "line", 60 * MILLION * RAD);






        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).file("ETH-A", "duty", TWO_TWENTYFIVE_PCT_RATE);





        JugAbstract(MCD_JUG).drip("BAT-A");
        JugAbstract(MCD_JUG).file("BAT-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);





        JugAbstract(MCD_JUG).drip("USDC-A");
        JugAbstract(MCD_JUG).file("USDC-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);





        JugAbstract(MCD_JUG).drip("USDC-B");
        JugAbstract(MCD_JUG).file("USDC-B", "duty", FIFTY_TWENTYFIVE_PCT_RATE);





        JugAbstract(MCD_JUG).drip("WBTC-A");
        JugAbstract(MCD_JUG).file("WBTC-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);





        JugAbstract(MCD_JUG).drip("TUSD-A");
        JugAbstract(MCD_JUG).file("TUSD-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);





        JugAbstract(MCD_JUG).drip("KNC-A");
        JugAbstract(MCD_JUG).file("KNC-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);





        JugAbstract(MCD_JUG).drip("ZRX-A");
        JugAbstract(MCD_JUG).file("ZRX-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);





        JugAbstract(MCD_JUG).drip("MANA-A");
        JugAbstract(MCD_JUG).file("MANA-A", "duty", TWELVE_TWENTYFIVE_PCT_RATE);





        JugAbstract(MCD_JUG).drip("USDT-A");
        JugAbstract(MCD_JUG).file("USDT-A", "duty", EIGHT_TWENTYFIVE_PCT_RATE);





        JugAbstract(MCD_JUG).drip("PAXUSD-A");
        JugAbstract(MCD_JUG).file("PAXUSD-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);





        address[] memory addrs = new address[](2);
        addrs[0] = KYBER;
        addrs[1] = ETHUSDv1;
        MedianAbstract(ETHUSD).kiss(addrs);


        MedianizerV1Abstract(ETHUSDv1).setMin(1);
        MedianizerV1Abstract(ETHUSDv1).setNext(0x000000000000000000000002);
        MedianizerV1Abstract(ETHUSDv1).set(0x000000000000000000000001, ETHUSD);


        MedianAbstract(BTCUSD).kiss(DDEX);


        OsmAbstract(PIP_WBTC).kiss(YEARN);
    }
}

contract DssSpell {
    DSPauseAbstract public pause ;

    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    address constant ETHUSDv1 = 0x729D19f657BD0614b4985Cf1D82531c67569197B;




    string constant public description =
        "2020-09-25 MakerDAO Executive Spell | Hash: 0x86cac34c2d63bd581cc36f7688f57c6005a6de0382903fe30179953d025c3450";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action ;

        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }









    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);




        MedianizerV1Abstract(ETHUSDv1).setOwner(pause.proxy());
        MedianizerV1Abstract(ETHUSDv1).setAuthority(address(0));
    }

    function cast() public  {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
