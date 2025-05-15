




















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

interface VatLike {
    function slip(bytes32,address,int) external;
}






interface GemLike7 {
    function decimals() external view returns (uint);
    function transfer(address,uint) external;
    function transferFrom(address,address,uint) external;
    function balanceOf(address) external view returns (uint);
    function upgradedAddress() external view returns (address);
    function setImplementation(address,uint) external;
    function adjustFee(uint) external;
}

contract GemJoin7 is LibNote {
    mapping (address => uint) public wards;
    function rely(address usr) public note auth { wards[usr] = 1; }
    function deny(address usr) public note auth { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    VatLike  public vat;
    bytes32  public ilk;
    GemLike7 public gem;
    uint     public dec;
    uint     public live;

    mapping (address => uint256) public implementations;

    constructor(address vat_, bytes32 ilk_, address gem_) public {
        gem = GemLike7(gem_);
        dec = gem.decimals();
        require(dec < 18, "GemJoin7/decimals-18-or-higher");
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
        setImplementation(address(gem.upgradedAddress()), 1);
    }

    function cage() public note auth {
        live = 0;
    }

    function setImplementation(address implementation, uint256 permitted) public auth note {
        implementations[implementation] = permitted;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "GemJoin7/overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "GemJoin7/underflow");
    }

    function join(address urn, uint wad) public note {
        require(live == 1, "GemJoin7/not-live");
        require(implementations[gem.upgradedAddress()] == 1, "GemJoin7/implementation-invalid");
        uint bal = gem.balanceOf(address(this));
        gem.transferFrom(msg.sender, address(this), wad);
        uint wadt = mul(sub(gem.balanceOf(address(this)), bal), 10 ** (18 - dec));
        require(int(wadt) >= 0, "GemJoin7/overflow");
        vat.slip(ilk, urn, int(wadt));
    }

    function exit(address guy, uint wad) public note {
        uint wad18 = mul(wad, 10 ** (18 - dec));
        require(int(wad18) >= 0, "GemJoin7/overflow");
        require(implementations[gem.upgradedAddress()] == 1, "GemJoin7/implementation-invalid");
        vat.slip(ilk, msg.sender, -int(wad18));
        gem.transfer(guy, wad);
    }
}
