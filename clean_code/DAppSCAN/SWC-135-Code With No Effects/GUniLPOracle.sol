

















































pragma solidity =0.6.12;

interface ERC20Like {
    function decimals()                 external view returns (uint8);
    function totalSupply()              external view returns (uint256);
}

interface GUNILike {
    function token0()                               external view returns (address);
    function token1()                               external view returns (address);
    function getUnderlyingBalancesAtPrice(uint160)  external view returns (uint256,uint256);
}

interface OracleLike {
    function read() external view returns (uint256);
}


contract GUniLPOracleFactory {

    mapping(address => bool) public isOracle;

    event NewGUniLPOracle(address owner, address orcl, bytes32 wat, address indexed tok0, address indexed tok1, address orb0, address orb1);


    function build(
        address _owner,
        address _src,
        bytes32 _wat,
        address _orb0,
        address _orb1
    ) public returns (address orcl) {
        address tok0 = GUNILike(_src).token0();
        address tok1 = GUNILike(_src).token1();
        orcl = address(new GUniLPOracle(_src, _wat, _orb0, _orb1));
        GUniLPOracle(orcl).rely(_owner);
        GUniLPOracle(orcl).deny(address(this));
        isOracle[orcl] = true;
        emit NewGUniLPOracle(_owner, orcl, _wat, tok0, tok1, _orb0, _orb1);
    }
}

contract GUniLPOracle {


    mapping (address => uint256) public wards;
    function rely(address _usr) external auth { wards[_usr] = 1; emit Rely(_usr); }
    function deny(address _usr) external auth { wards[_usr] = 0; emit Deny(_usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "GUniLPOracle/not-authorized");
        _;
    }

    address public immutable src;



    uint8   public stopped;
    uint16  public hop = 1 hours;
    uint232 public zph;

    bytes32 public immutable wat;


    mapping (address => uint256) public bud;
    modifier toll { require(bud[msg.sender] == 1, "GUniLPOracle/contract-not-whitelisted"); _; }

    struct Feed {
        uint128 val;
        uint128 has;
    }

    Feed    internal cur;
    Feed    internal nxt;


    uint256 private immutable UNIT_0;
    uint256 private immutable UNIT_1;
    uint256 private immutable TO_18_DEC_0;
    uint256 private immutable TO_18_DEC_1;

    address public            orb0;
    address public            orb1;



    uint256 constant WAD = 10 ** 18;

    function _add(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        require((z = _x + _y) >= _x, "GUniLPOracle/add-overflow");
    }
    function _sub(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        require((z = _x - _y) <= _x, "GUniLPOracle/sub-underflow");
    }
    function _mul(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        require(_y == 0 || (z = _x * _y) / _y == _x, "GUniLPOracle/mul-overflow");
    }
    function toUint160(uint256 x) internal pure returns (uint160 z) {
        require((z = uint160(x)) == x, "GUniLPOracle/uint160-overflow");
    }


    function sqrt(uint256 _x) private pure returns (uint128) {
        if (_x == 0) return 0;
        else {
            uint256 xx = _x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
            if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
            if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
            if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
            if (xx >= 0x100) { xx >>= 8; r <<= 4; }
            if (xx >= 0x10) { xx >>= 4; r <<= 2; }
            if (xx >= 0x8) { r <<= 1; }
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            uint256 r1 = _x / r;
            return uint128 (r < r1 ? r : r1);
        }
    }


    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Step(uint256 hop);
    event Stop();
    event Start();
    event Value(uint128 curVal, uint128 nxtVal);
    event Link(uint256 id, address orb);
    event Kiss(address a);
    event Diss(address a);


    constructor (address _src, bytes32 _wat, address _orb0, address _orb1) public {
        require(_src  != address(0),                        "GUniLPOracle/invalid-src-address");
        require(_orb0 != address(0) && _orb1 != address(0), "GUniLPOracle/invalid-oracle-address");
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
        src  = _src;
        wat  = _wat;
        uint256 dec0 = uint256(ERC20Like(GUNILike(_src).token0()).decimals());
        require(dec0 <= 18, "GUniLPOracle/token0-dec-gt-18");
        UNIT_0 = 10 ** dec0;
        TO_18_DEC_0 = 10 ** (18 - dec0);
        uint256 dec1 = uint256(ERC20Like(GUNILike(_src).token1()).decimals());
        require(dec1 <= 18, "GUniLPOracle/token1-dec-gt-18");
        UNIT_1 = 10 ** dec1;
        TO_18_DEC_1 = 10 ** (18 - dec1);
        orb0 = _orb0;
        orb1 = _orb1;
    }

    function stop() external auth {
        stopped = 1;
        delete cur;
        delete nxt;
        zph = 0;
        emit Stop();
    }

    function start() external auth {
        stopped = 0;
        emit Start();
    }

    function step(uint256 _hop) external auth {
        require(_hop <= uint16(-1), "GUniLPOracle/invalid-hop");
        hop = uint16(_hop);
        emit Step(_hop);
    }

    function link(uint256 _id, address _orb) external auth {
        require(_orb != address(0), "GUniLPOracle/no-contract-0");
        if(_id == 0) {
            orb0 = _orb;
        } else if (_id == 1) {
            orb1 = _orb;
        } else {
            revert("GUniLPOracle/invalid-id");
        }
        emit Link(_id, _orb);
    }


    function zzz() external view returns (uint256) {
        if (zph == 0) return 0;
        return _sub(zph, hop);
    }

    function pass() external view returns (bool) {
        return block.timestamp >= zph;
    }

    function seek() internal returns (uint128 quote) {

        uint256 p0 = OracleLike(orb0).read();
        require(p0 != 0, "GUniLPOracle/invalid-oracle-0-price");
        uint256 p1 = OracleLike(orb1).read();
        require(p1 != 0, "GUniLPOracle/invalid-oracle-1-price");
        uint160 sqrtPriceX96 = toUint160(sqrt(_mul(_mul(p0, UNIT_1), (1 << 96)) / (_mul(p1, UNIT_0))) << 48);


        (uint256 r0, uint256 r1) = GUNILike(src).getUnderlyingBalancesAtPrice(sqrtPriceX96);
        require(r0 > 0 || r1 > 0, "GUniLPOracle/invalid-balances");
        uint256 totalSupply = ERC20Like(src).totalSupply();
        require(totalSupply >= 1e9, "GUniLPOracle/total-supply-too-small");


        uint256 preq = _add(
            _mul(p0, _mul(r0, TO_18_DEC_0)),
            _mul(p1, _mul(r1, TO_18_DEC_1))
        ) / totalSupply;
        require(preq < 2 ** 128, "GUniLPOracle/quote-overflow");
        quote = uint128(preq);
    }

    function poke() external {


        uint256 hop_;
        {


            uint256 stopped_;
            uint256 zph_;
            assembly {
                let slot1 := sload(1)
                stopped_  := and(slot1,         0xff  )
                hop_      := and(shr(8, slot1), 0xffff)
                zph_      := shr(24, slot1)
            }


            require(stopped_ == 0, "GUniLPOracle/is-stopped");




            require(block.timestamp >= zph_, "GUniLPOracle/not-passed");
        }

        uint128 val = seek();
        require(val != 0, "GUniLPOracle/invalid-price");
        Feed memory cur_ = nxt;
        cur = cur_;
        nxt = Feed(val, 1);











        assembly {
            sstore(
                1,
                add(

                    shl(24, add(timestamp(), hop_)),


                    shl(8, hop_)
                )
            )
        }


        emit Value(cur_.val, val);


        assembly {
            stop()
        }
    }

    function peek() external view toll returns (bytes32,bool) {
        return (bytes32(uint256(cur.val)), cur.has == 1);
    }

    function peep() external view toll returns (bytes32,bool) {
        return (bytes32(uint256(nxt.val)), nxt.has == 1);
    }

    function read() external view toll returns (bytes32) {
        require(cur.has == 1, "GUniLPOracle/no-current-value");
        return (bytes32(uint256(cur.val)));
    }

    function kiss(address _a) external auth {
        require(_a != address(0), "GUniLPOracle/no-contract-0");
        bud[_a] = 1;
        emit Kiss(_a);
    }

    function kiss(address[] calldata _a) external auth {
        for(uint256 i = 0; i < _a.length; i++) {
            require(_a[i] != address(0), "GUniLPOracle/no-contract-0");
            bud[_a[i]] = 1;
            emit Kiss(_a[i]);
        }
    }

    function diss(address _a) external auth {
        bud[_a] = 0;
        emit Diss(_a);
    }

    function diss(address[] calldata _a) external auth {
        for(uint256 i = 0; i < _a.length; i++) {
            bud[_a[i]] = 0;
            emit Diss(_a[i]);
        }
    }
}
