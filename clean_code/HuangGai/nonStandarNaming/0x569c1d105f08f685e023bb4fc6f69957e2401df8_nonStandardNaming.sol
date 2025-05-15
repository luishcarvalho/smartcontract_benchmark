
















pragma solidity 0.5.12;


contract DSPauseAbstract {
    function SETOWNER689(address) public;
    function SETAUTHORITY730(address) public;
    function SETDELAY296(uint256) public;
    function PLANS764(bytes32) public view returns (bool);
    function PROXY760() public view returns (address);
    function DELAY504() public view returns (uint256);
    function PLOT663(address, bytes32, bytes memory, uint256) public;
    function DROP0(address, bytes32, bytes memory, uint256) public;
    function EXEC954(address, bytes32, bytes memory, uint256) public returns (bytes memory);
}


contract VatAbstract {
    function WARDS319(address) public view returns (uint256);
    function RELY44(address) external;
    function DENY212(address) external;
    function CAN335(address, address) public view returns (uint256);
    function HOPE170(address) external;
    function NOPE595(address) external;
    function ILKS856(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function URNS221(bytes32, address) public view returns (uint256, uint256);
    function GEM772(bytes32, address) public view returns (uint256);
    function DAI284(address) public view returns (uint256);
    function SIN561(address) public view returns (uint256);
    function DEBT970() public view returns (uint256);
    function VICE687() public view returns (uint256);
    function LINE919() public view returns (uint256);
    function LIVE2() public view returns (uint256);
    function INIT584(bytes32) external;
    function FILE53(bytes32, uint256) external;
    function FILE53(bytes32, bytes32, uint256) external;
    function CAGE707() external;
    function SLIP789(bytes32, address, int256) external;
    function FLUX417(bytes32, address, address, uint256) external;
    function MOVE230(address, address, uint256) external;
    function FROB856(bytes32, address, address, address, int256, int256) external;
    function FORK761(bytes32, address, address, int256, int256) external;
    function GRAB846(bytes32, address, address, address, int256, int256) external;
    function HEAL266(uint256) external;
    function SUCK896(address, address, uint256) external;
    function FOLD438(bytes32, address, int256) external;
}

contract SpellAction {


    string constant public description481 = "2020-04-29 MakerDAO Executive Spell";







    address constant public mcd_vat668 = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;








    uint256 constant public rad476 = 10**45;
    uint256 constant public million832 = 10**6;

    function EXECUTE733() external {







        uint256 ETH_LINE = 120 * million832;
        VatAbstract(mcd_vat668).FILE53("ETH-A", "line", ETH_LINE * rad476);


        uint256 GLOBAL_LINE = 143 * million832;
        VatAbstract(mcd_vat668).FILE53("Line", GLOBAL_LINE * rad476);
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

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    function DESCRIPTION498() public view returns (string memory) {
        return SpellAction(action).description481();
    }

    function SCHEDULE983() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).DELAY504();
        pause.PLOT663(action, tag, sig, eta);
    }

    function CAST849() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.EXEC954(action, tag, sig, eta);
    }
}
