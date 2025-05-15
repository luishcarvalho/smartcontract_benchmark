


















pragma solidity ^0.5.12;

interface DSPauseAbstract {
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

interface VatAbstract {
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
}

interface SpotAbstract {
    function file(bytes32, bytes32, uint256) external;
    function poke(bytes32) external;
}

interface CatAbstract {
    function file(bytes32, uint256) external;
}

contract SpellAction {






    address constant MCD_VAT     = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_SPOT    = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant MCD_CAT     = 0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea;


    uint256 constant MILLION  = 10 ** 6;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    function execute() external {




        VatAbstract(MCD_VAT).file("Line", 948 * MILLION * RAD);





        VatAbstract(MCD_VAT).file("USDC-A", "line", 200 * MILLION * RAD);





        VatAbstract(MCD_VAT).file("PAXUSD-A", "line", 30 * MILLION * RAD);




        SpotAbstract(MCD_SPOT).file("USDC-A", "mat", 103 * RAY / 100);
        SpotAbstract(MCD_SPOT).poke("USDC-A");




        SpotAbstract(MCD_SPOT).file("PAXUSD-A", "mat", 103 * RAY / 100);
        SpotAbstract(MCD_SPOT).poke("PAXUSD-A");




        CatAbstract(MCD_CAT).file("box", 15 * MILLION * RAD);
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
        "2020-09-14 MakerDAO Executive Spell | Hash: 0xf0155120204be06c56616181ea82bbfa93f48494455c6d0b3c0ab1d581464657";

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

    function cast() public  {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
