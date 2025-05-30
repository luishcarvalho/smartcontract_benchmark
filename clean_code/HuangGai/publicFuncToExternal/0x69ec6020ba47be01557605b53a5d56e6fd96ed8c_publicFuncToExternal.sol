


















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


contract IlkRegistryAbstract {
    function list() external view returns (bytes32[] memory);
    function flip(bytes32) external view returns (address);
}

contract SpellAction {


    string constant public description = "DEFCON-5 Emergency Spell";





    address constant MCD_VAT      = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_JUG      = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_POT      = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant ILK_REGISTRY = 0xbE4F921cdFEf2cF5080F9Cf00CC2c14F1F96Bd07;
    address constant FLIPPER_MOM  = 0x9BdDB99625A711bf9bda237044924E34E8570f75;







    uint256 constant ZERO_PCT_RATE = 1000000000000000000000000000;



    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;
    uint256 constant RAD = 10**45;
    uint256 constant MLN = 10**6;
    uint256 constant BLN = 10**9;

    function execute() public {




        PotAbstract(MCD_POT).drip();



        IlkRegistryAbstract registry = IlkRegistryAbstract(ILK_REGISTRY);
        bytes32[] memory ilks = registry.list();

        for (uint i = 0; i < ilks.length; i++) {


            JugAbstract(MCD_JUG).drip(ilks[i]);



            if (ilks[i] == "USDC-A" ||
                ilks[i] == "USDC-B" ||
                ilks[i] == "TUSD-A"
            ) { continue; }






            FlipperMomAbstract(FLIPPER_MOM).rely(registry.flip(ilks[i]));
        }
    }
}

contract DssSpell {

    DSPauseAbstract  public pause;
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    uint256          public expiration;
    bool             public done;

    address constant MCD_PAUSE    = 0xbE286431454714F511008713973d3B053A2d38f3;
    address constant ILK_REGISTRY = 0xbE4F921cdFEf2cF5080F9Cf00CC2c14F1F96Bd07;

    uint256 constant T2020_10_01_1200UTC = 1601553600;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        pause = DSPauseAbstract(MCD_PAUSE);
        expiration = T2020_10_01_1200UTC;
    }

    function description() public view returns (string memory) {
        return SpellAction(action).description();
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + pause.delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
