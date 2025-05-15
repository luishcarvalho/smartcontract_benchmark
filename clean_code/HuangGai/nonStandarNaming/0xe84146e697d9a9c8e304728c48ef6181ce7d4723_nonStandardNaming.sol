














pragma solidity ^0.5.12;

contract LibNote {
    event LOGNOTE625(
        bytes4   indexed  sig,
        address  indexed  usr,
        bytes32  indexed  arg1,
        bytes32  indexed  arg2,
        bytes             data
    ) anonymous;

    modifier NOTE96 {
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
    function URNS742(bytes32, address) public view returns (uint, uint);
    function HOPE954(address) public;
    function FLUX111(bytes32, address, address, uint) public;
    function MOVE24(address, address, uint) public;
    function FROB530(bytes32, address, address, address, int, int) public;
    function FORK185(bytes32, address, address, int, int) public;
}

contract UrnHandler {
    constructor(address vat) public {
        VatLike(vat).HOPE954(msg.sender);
    }
}

contract DssCdpManager is LibNote {
    address                   public vat;
    uint                      public cdpi;
    mapping (uint => address) public urns;
    mapping (uint => List)    public list;
    mapping (uint => address) public owns;
    mapping (uint => bytes32) public ilks;

    mapping (address => uint) public first;
    mapping (address => uint) public last;
    mapping (address => uint) public count;

    mapping (
        address => mapping (
            uint => mapping (
                address => uint
            )
        )
    ) public cdpCan;

    mapping (
        address => mapping (
            address => uint
        )
    ) public urnCan;

    struct List {
        uint prev;
        uint next;
    }

    event NEWCDP119(address indexed usr, address indexed own, uint indexed cdp);

    modifier CDPALLOWED275(
        uint cdp
    ) {
        require(msg.sender == owns[cdp] || cdpCan[owns[cdp]][cdp][msg.sender] == 1, "cdp-not-allowed");
        _;
    }

    modifier URNALLOWED615(
        address urn
    ) {
        require(msg.sender == urn || urnCan[urn][msg.sender] == 1, "urn-not-allowed");
        _;
    }

    constructor(address vat_) public {
        vat = vat_;
    }

    function ADD152(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function SUB613(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function TOINT291(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0);
    }


    function CDPALLOW117(
        uint cdp,
        address usr,
        uint ok
    ) public CDPALLOWED275(cdp) {
        cdpCan[owns[cdp]][cdp][usr] = ok;
    }


    function URNALLOW963(
        address usr,
        uint ok
    ) public {
        urnCan[msg.sender][usr] = ok;
    }


    function OPEN788(
        bytes32 ilk,
        address usr
    ) public NOTE96 returns (uint) {
        require(usr != address(0), "usr-address-0");

        cdpi = ADD152(cdpi, 1);
        urns[cdpi] = address(new UrnHandler(vat));
        owns[cdpi] = usr;
        ilks[cdpi] = ilk;


        if (first[usr] == 0) {
            first[usr] = cdpi;
        }
        if (last[usr] != 0) {
            list[cdpi].prev = last[usr];
            list[last[usr]].next = cdpi;
        }
        last[usr] = cdpi;
        count[usr] = ADD152(count[usr], 1);

        emit NEWCDP119(msg.sender, usr, cdpi);
        return cdpi;
    }


    function GIVE491(
        uint cdp,
        address dst
    ) public NOTE96 CDPALLOWED275(cdp) {
        require(dst != address(0), "dst-address-0");
        require(dst != owns[cdp], "dst-already-owner");


        if (list[cdp].prev != 0) {
            list[list[cdp].prev].next = list[cdp].next;
        }
        if (list[cdp].next != 0) {
            list[list[cdp].next].prev = list[cdp].prev;
        } else {
            last[owns[cdp]] = list[cdp].prev;
        }
        if (first[owns[cdp]] == cdp) {
            first[owns[cdp]] = list[cdp].next;
        }
        count[owns[cdp]] = SUB613(count[owns[cdp]], 1);


        owns[cdp] = dst;


        list[cdp].prev = last[dst];
        list[cdp].next = 0;
        if (last[dst] != 0) {
            list[last[dst]].next = cdp;
        }
        if (first[dst] == 0) {
            first[dst] = cdp;
        }
        last[dst] = cdp;
        count[dst] = ADD152(count[dst], 1);
    }


    function FROB530(
        uint cdp,
        int dink,
        int dart
    ) public NOTE96 CDPALLOWED275(cdp) {
        address urn = urns[cdp];
        VatLike(vat).FROB530(
            ilks[cdp],
            urn,
            urn,
            urn,
            dink,
            dart
        );
    }


    function FLUX111(
        uint cdp,
        address dst,
        uint wad
    ) public NOTE96 CDPALLOWED275(cdp) {
        VatLike(vat).FLUX111(ilks[cdp], urns[cdp], dst, wad);
    }



    function FLUX111(
        bytes32 ilk,
        uint cdp,
        address dst,
        uint wad
    ) public NOTE96 CDPALLOWED275(cdp) {
        VatLike(vat).FLUX111(ilk, urns[cdp], dst, wad);
    }


    function MOVE24(
        uint cdp,
        address dst,
        uint rad
    ) public NOTE96 CDPALLOWED275(cdp) {
        VatLike(vat).MOVE24(urns[cdp], dst, rad);
    }


    function QUIT635(
        uint cdp,
        address dst
    ) public NOTE96 CDPALLOWED275(cdp) URNALLOWED615(dst) {
        (uint ink, uint art) = VatLike(vat).URNS742(ilks[cdp], urns[cdp]);
        VatLike(vat).FORK185(
            ilks[cdp],
            urns[cdp],
            dst,
            TOINT291(ink),
            TOINT291(art)
        );
    }


    function ENTER294(
        address src,
        uint cdp
    ) public NOTE96 URNALLOWED615(src) CDPALLOWED275(cdp) {
        (uint ink, uint art) = VatLike(vat).URNS742(ilks[cdp], src);
        VatLike(vat).FORK185(
            ilks[cdp],
            src,
            urns[cdp],
            TOINT291(ink),
            TOINT291(art)
        );
    }


    function SHIFT262(
        uint cdpSrc,
        uint cdpDst
    ) public NOTE96 CDPALLOWED275(cdpSrc) CDPALLOWED275(cdpDst) {
        require(ilks[cdpSrc] == ilks[cdpDst], "non-matching-cdps");
        (uint ink, uint art) = VatLike(vat).URNS742(ilks[cdpSrc], urns[cdpSrc]);
        VatLike(vat).FORK185(
            ilks[cdpSrc],
            urns[cdpSrc],
            urns[cdpDst],
            TOINT291(ink),
            TOINT291(art)
        );
    }
}
