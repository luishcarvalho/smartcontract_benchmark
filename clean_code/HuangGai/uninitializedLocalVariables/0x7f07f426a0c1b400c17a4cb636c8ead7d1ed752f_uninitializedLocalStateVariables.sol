




















pragma solidity >=0.5.12;

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


            let mark := msize()
            mstore(0x40, add(mark, 288))
            mstore(mark, 0x20)
            mstore(add(mark, 0x20), 224)
            calldatacopy(add(mark, 0x40), 0, 224)
            log4(mark, 288,
                 shl(224, shr(224, calldataload(0))),
                 caller(),
                 calldataload(4),
                 calldataload(36)
                )
        }
    }
}

interface Kicker {
    function kick(address urn, address gal, uint256 tab, uint256 lot, uint256 bid)
        external returns (uint256);
}

interface VatLike {
    function ilks(bytes32) external view returns (
        uint256 Art,
        uint256 rate,
        uint256 spot,
        uint256 line,
        uint256 dust
    );
    function urns(bytes32,address) external view returns (
        uint256 ink,
        uint256 art
    );
    function grab(bytes32,address,address,address,int256,int256) external;
    function hope(address) external;
    function nope(address) external;
}

interface VowLike {
    function fess(uint256) external;
}

contract Cat is LibNote {

    mapping (address => uint256) public wards;
    function rely(address usr) external note auth { wards[usr] = 1; }
    function deny(address usr) external note auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Cat/not-authorized");
        _;
    }


    struct Ilk {
        address flip;
        uint256 chop;
        uint256 dunk;
    }

    mapping (bytes32 => Ilk) public ilks;

    uint256 public live;
    VatLike public vat;
    VowLike public vow;
    uint256 public box;
    uint256 public litter;


    event Bite(
      bytes32 indexed ilk,
      address indexed urn,
      uint256 ink,
      uint256 art,
      uint256 tab,
      address flip,
      uint256 id
    );


    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        live = 1;
    }


    uint256 constant WAD = 10 ** 18;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x > y) { z = y; } else { z = x; }
    }
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }


    function file(bytes32 what, address data) external note auth {
        if (what == "vow") vow = VowLike(data);
        else revert("Cat/file-unrecognized-param");
    }
    function file(bytes32 what, uint256 data) external note auth {
        if (what == "box") box = data;
        else revert("Cat/file-unrecognized-param");
    }
    function file(bytes32 ilk, bytes32 what, uint256 data) external note auth {
        if (what == "chop") ilks[ilk].chop = data;
        else if (what == "dunk") ilks[ilk].dunk = data;
        else revert("Cat/file-unrecognized-param");
    }
    function file(bytes32 ilk, bytes32 what, address flip) external note auth {
        if (what == "flip") {
            vat.nope(ilks[ilk].flip);
            ilks[ilk].flip = flip;
            vat.hope(flip);
        }
        else revert("Cat/file-unrecognized-param");
    }


    function bite(bytes32 ilk, address urn) external returns (uint256 id) {
        (,uint256 rate,uint256 spot,,uint256 dust) = vat.ilks(ilk);
        (uint256 ink, uint256 art) = vat.urns(ilk, urn);

        require(live == 1, "Cat/not-live");
        require(spot > 0 && mul(ink, spot) < mul(art, rate), "Cat/not-unsafe");

        Ilk memory milk = ilks[ilk];
        uint256 dart;
        {
            uint256 room ;



            require(litter < box && room >= dust, "Cat/liquidation-limit-hit");

            dart = min(art, mul(min(milk.dunk, room), WAD) / rate / milk.chop);
        }

        uint256 dink ;


        require(dart >  0      && dink >  0     , "Cat/null-auction");
        require(dart <= 2**255 && dink <= 2**255, "Cat/overflow"    );


        vat.grab(
            ilk, urn, address(this), address(vow), -int256(dink), -int256(dart)
        );
        vow.fess(mul(dart, rate));

        {


            uint256 tab ;

            litter = add(litter, tab);

            id = Kicker(milk.flip).kick({
                urn: urn,
                gal: address(vow),
                tab: tab,
                lot: dink,
                bid: 0
            });
        }

        emit Bite(ilk, urn, dink, dart, mul(dart, rate), milk.flip, id);
    }

    function claw(uint256 rad) external note auth {
        litter = sub(litter, rad);
    }

    function cage() external note auth {
        live = 0;
    }
}

contract CatFab {
    function newCat(address vat) public returns (Cat cat) {
        cat = new Cat(vat);
        cat.rely(msg.sender);
        cat.deny(address(this));
    }
}
