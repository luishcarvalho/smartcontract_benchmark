





















pragma solidity ^0.5.12;

contract LibNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  usr,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes             data
    ) anonymous;

    modifier note {
        _;
        assembly {


            let mark := msize
            mstore(0x40, add(mark, 288))
            mstore(mark, 0x20)
            mstore(add(mark, 0x20), 224)
            calldatacopy(add(mark, 0x40), 0, 224)
            log4(mark, 288,
                 shl(224, shr(224, calldataload(0))),
                 caller,
                 calldataload(4),
                 calldataload(36)
                )
        }
    }
}

contract VatLike {
    function dai(address) external view returns (uint256);
    function ilks(bytes32 ilk) external returns (
        uint256 Art,
        uint256 rate,
        uint256 spot,
        uint256 line,
        uint256 dust
    );
    function urns(bytes32 ilk, address urn) external returns (
        uint256 ink,
        uint256 art
    );
    function debt() external returns (uint256);
    function move(address src, address dst, uint256 rad) external;
    function hope(address) external;
    function flux(bytes32 ilk, address src, address dst, uint256 rad) external;
    function grab(bytes32 i, address u, address v, address w, int256 dink, int256 dart) external;
    function suck(address u, address v, uint256 rad) external;
    function cage() external;
}
contract CatLike {
    function ilks(bytes32) external returns (
        address flip,
        uint256 chop,
        uint256 lump
    );
    function cage() external;
}
contract PotLike {
    function cage() external;
}
contract VowLike {
    function cage() external;
}
contract Flippy {
    function bids(uint id) external view returns (
        uint256 bid,
        uint256 lot,
        address guy,
        uint48  tic,
        uint48  end,
        address usr,
        address gal,
        uint256 tab
    );
    function yank(uint id) external;
}

contract PipLike {
    function read() external view returns (bytes32);
}

contract Spotty {
    function par() external view returns (uint256);
    function ilks(bytes32) external view returns (
        PipLike pip,
        uint256 mat
    );
    function cage() external;
}





































































































contract End is LibNote {

    mapping (address => uint) public wards;
    function rely(address guy) external note auth { wards[guy] = 1; }
    function deny(address guy) external note auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "End/not-authorized");
        _;
    }


    VatLike  public vat;
    CatLike  public cat;
    VowLike  public vow;
    PotLike  public pot;
    Spotty   public spot;

    uint256  public live;
    uint256  public when;
    uint256  public wait;
    uint256  public debt;

    mapping (bytes32 => uint256) public tag;
    mapping (bytes32 => uint256) public gap;
    mapping (bytes32 => uint256) public Art;
    mapping (bytes32 => uint256) public fix;

    mapping (address => uint256)                      public bag;
    mapping (bytes32 => mapping (address => uint256)) public out;


    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
    }


    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / RAY;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, RAY) / y;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, WAD) / y;
    }


    function file(bytes32 what, address data) external note auth {
        require(live == 1, "End/not-live");
        if (blockhash(block.number) == "vat")  vat = VatLike(data);
        else if (blockhash(block.number) == "cat")  cat = CatLike(data);
        else if (blockhash(block.number) == "vow")  vow = VowLike(data);
        else if (blockhash(block.number) == "pot")  pot = PotLike(data);
        else if (blockhash(block.number) == "spot") spot = Spotty(data);
        else revert("End/file-unrecognized-param");
    }
    function file(bytes32 what, uint256 data) external note auth {
        require(live == 1, "End/not-live");
        if (blockhash(block.number) == "wait") wait = data;
        else revert("End/file-unrecognized-param");
    }


    function cage() external note auth {
        require(live == 1, "End/not-live");
        live = 0;
        when = now;
        vat.cage();
        cat.cage();
        vow.cage();
        spot.cage();
        pot.cage();
    }

    function cage(bytes32 ilk) external note {
        require(live == 0, "End/still-live");
        require(tag[ilk] == 0, "End/tag-ilk-already-defined");
        (Art[ilk],,,,) = vat.ilks(ilk);
        (PipLike pip,) = spot.ilks(ilk);

        tag[ilk] = wdiv(spot.par(), uint(pip.read()));
    }

    function skip(bytes32 ilk, uint256 id) external note {
        require(tag[ilk] != 0, "End/tag-ilk-not-defined");

        (address flipV,,) = cat.ilks(ilk);
        Flippy flip = Flippy(flipV);
        (, uint rate,,,) = vat.ilks(ilk);
        (uint bid, uint lot,,,, address usr,, uint tab) = flip.bids(id);

        vat.suck(address(vow), address(vow),  tab);
        vat.suck(address(vow), address(this), bid);
        vat.hope(address(flip));
        flip.yank(id);

        uint art = tab / rate;
        Art[ilk] = add(Art[ilk], art);
        require(int(lot) >= 0 && int(art) >= 0, "End/overflow");
        vat.grab(ilk, usr, address(this), address(vow), int(lot), int(art));
    }

    function skim(bytes32 ilk, address urn) external note {
        require(tag[ilk] != 0, "End/tag-ilk-not-defined");
        (, uint rate,,,) = vat.ilks(ilk);
        (uint ink, uint art) = vat.urns(ilk, urn);

        uint owe = rmul(rmul(art, rate), tag[ilk]);
        uint wad = min(ink, owe);
        gap[ilk] = add(gap[ilk], sub(owe, wad));

        require(wad <= 2**255 && art <= 2**255, "End/overflow");
        vat.grab(ilk, urn, address(this), address(vow), -int(wad), -int(art));
    }

    function free(bytes32 ilk) external note {
        require(live == 0, "End/still-live");
        (uint ink, uint art) = vat.urns(ilk, msg.sender);
        require(art == 0, "End/art-not-zero");
        require(ink <= 2**255, "End/overflow");
        vat.grab(ilk, msg.sender, msg.sender, address(vow), -int(ink), 0);
    }

    function thaw() external note {
        require(live == 0, "End/still-live");
        require(debt == 0, "End/debt-not-zero");
        require(vat.dai(address(vow)) == 0, "End/surplus-not-zero");
        require(now >= add(when, wait), "End/wait-not-finished");
        debt = vat.debt();
    }
    function flow(bytes32 ilk) external note {
        require(debt != 0, "End/debt-zero");
        require(fix[ilk] == 0, "End/fix-ilk-already-defined");

        (, uint rate,,,) = vat.ilks(ilk);
        uint256 wad = rmul(rmul(Art[ilk], rate), tag[ilk]);
        fix[ilk] = rdiv(mul(sub(wad, gap[ilk]), RAY), debt);
    }

    function pack(uint256 wad) external note {
        require(debt != 0, "End/debt-zero");
        vat.move(msg.sender, address(vow), mul(wad, RAY));
        bag[msg.sender] = add(bag[msg.sender], wad);
    }
    function cash(bytes32 ilk, uint wad) external note {
        require(fix[ilk] != 0, "End/fix-ilk-not-defined");
        vat.flux(ilk, address(this), msg.sender, rmul(wad, fix[ilk]));
        out[ilk][msg.sender] = add(out[ilk][msg.sender], wad);
        require(out[ilk][msg.sender] <= bag[msg.sender], "End/insufficient-bag-balance");
    }
}
