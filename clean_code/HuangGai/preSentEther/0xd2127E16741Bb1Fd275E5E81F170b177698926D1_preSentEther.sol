


















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


interface GemJoinImplementationAbstract {
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
    function setImplementation(address, uint256) external;
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

contract SpellAction {






    address constant MCD_VAT         = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_JUG         = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;


    address constant TUSD_IMPL       = 0xffc40F39806F1400d8278BfD33823705b5a4c196;
    address constant MCD_JOIN_TUSD_A = 0x4454aF7C8bb9463203b66C816220D41ED7837f44;


    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;







    uint256 constant    TWO = 1000000000627937192491029810;
    uint256 constant  THREE = 1000000000937303470807876289;
    uint256 constant   FOUR = 1000000001243680656318820312;
    uint256 constant  EIGHT = 1000000002440418608258400030;
    uint256 constant TWELVE = 1000000003593629043335673582;
    uint256 constant  FIFTY = 1000000012857214317438491659;

    function execute() external {


        VatAbstract(MCD_VAT).file("Line", 1456 * MILLION * RAD);





        VatAbstract(MCD_VAT).file("PAXUSD-A", "line", 100 * MILLION * RAD);





        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).file("ETH-A", "duty", TWO);





        JugAbstract(MCD_JUG).drip("BAT-A");
        JugAbstract(MCD_JUG).file("BAT-A", "duty", FOUR);





        JugAbstract(MCD_JUG).drip("USDC-A");
        JugAbstract(MCD_JUG).file("USDC-A", "duty", FOUR);





        JugAbstract(MCD_JUG).drip("USDC-B");
        JugAbstract(MCD_JUG).file("USDC-B", "duty", FIFTY);





        JugAbstract(MCD_JUG).drip("WBTC-A");
        JugAbstract(MCD_JUG).file("WBTC-A", "duty", FOUR);





        JugAbstract(MCD_JUG).drip("TUSD-A");
        JugAbstract(MCD_JUG).file("TUSD-A", "duty", FOUR);





        JugAbstract(MCD_JUG).drip("KNC-A");
        JugAbstract(MCD_JUG).file("KNC-A", "duty", FOUR);





        JugAbstract(MCD_JUG).drip("ZRX-A");
        JugAbstract(MCD_JUG).file("ZRX-A", "duty", FOUR);





        JugAbstract(MCD_JUG).drip("MANA-A");
        JugAbstract(MCD_JUG).file("MANA-A", "duty", TWELVE);





        JugAbstract(MCD_JUG).drip("USDT-A");
        JugAbstract(MCD_JUG).file("USDT-A", "duty", EIGHT);





        JugAbstract(MCD_JUG).drip("PAXUSD-A");
        JugAbstract(MCD_JUG).file("PAXUSD-A", "duty", FOUR);





        JugAbstract(MCD_JUG).drip("LINK-A");
        JugAbstract(MCD_JUG).file("LINK-A", "duty", TWO);





        JugAbstract(MCD_JUG).drip("LRC-A");
        JugAbstract(MCD_JUG).file("LRC-A", "duty", THREE);





        JugAbstract(MCD_JUG).drip("COMP-A");
        JugAbstract(MCD_JUG).file("COMP-A", "duty", THREE);


        GemJoinImplementationAbstract(MCD_JOIN_TUSD_A).setImplementation(TUSD_IMPL, 1);
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
        "2020-10-02 MakerDAO Executive Spell | Hash: 0xbf384941515f3594205f47f8e4675883118fead22472792119cf051ed37f29a8";

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
        require(address(this).balance == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
