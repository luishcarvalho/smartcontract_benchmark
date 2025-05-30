




















pragma solidity ^0.5.12;


contract Math {

    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }
    function sub(uint x, int y) internal pure returns (uint z) {
        z = x - uint(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }
    function mul(uint x, int y) internal pure returns (int z) {
        z = int(x) * y;
        require(int(x) >= 0);
        require(y == 0 || z / y == int(x));
    }
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    uint constant RAY = 10 ** 27;

    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, RAY) / y;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / RAY;
    }
    function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0);
    }
}


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

contract BCdpScoreLike {
    function updateScore(uint cdp, bytes32 ilk, int dink, int dart, uint time) external;
}

contract BCdpScoreConnector {
    BCdpScoreLike public score;
    mapping(uint => uint) public left;

    constructor(BCdpScoreLike score_) public {
        score = score_;
    }

    function setScore(BCdpScoreLike bcdpScore) internal {
        score = bcdpScore;
    }

    function updateScore(uint cdp, bytes32 ilk, int dink, int dart, uint time) internal {
        if(left[cdp] == 0) score.updateScore(cdp, ilk, dink, dart, time);
    }

    function quitScore(uint cdp) internal {
        if(left[cdp] == 0) left[cdp] = now;
    }
}



contract UrnHandler {
    constructor(address vat) public {
        VatLike(vat).hope(msg.sender);
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

    event NewCdp(address indexed usr, address indexed own, uint indexed cdp);

    modifier cdpAllowed(
        uint cdp
    ) {
        require(msg.sender == owns[cdp] || cdpCan[owns[cdp]][cdp][msg.sender] == 1, "cdp-not-allowed");
        _;
    }

    modifier urnAllowed(
        address urn
    ) {
        require(msg.sender == urn || urnCan[urn][msg.sender] == 1, "urn-not-allowed");
        _;
    }

    constructor(address vat_) public {
        vat = vat_;
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0);
    }


    function cdpAllow(
        uint cdp,
        address usr,
        uint ok
    ) public cdpAllowed(cdp) {
        cdpCan[owns[cdp]][cdp][usr] = ok;
    }


    function urnAllow(
        address usr,
        uint ok
    ) public {
        urnCan[msg.sender][usr] = ok;
    }


    function open(
        bytes32 ilk,
        address usr
    ) public note returns (uint) {
        require(usr != address(0), "usr-address-0");

        cdpi = add(cdpi, 1);
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
        count[usr] = add(count[usr], 1);

        emit NewCdp(msg.sender, usr, cdpi);
        return cdpi;
    }


    function give(
        uint cdp,
        address dst
    ) public note cdpAllowed(cdp) {
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
        count[owns[cdp]] = sub(count[owns[cdp]], 1);


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
        count[dst] = add(count[dst], 1);
    }


    function frob(
        uint cdp,
        int dink,
        int dart
    ) public note cdpAllowed(cdp) {
        address urn = urns[cdp];
        VatLike(vat).frob(
            ilks[cdp],
            urn,
            urn,
            urn,
            dink,
            dart
        );
    }


    function flux(
        uint cdp,
        address dst,
        uint wad
    ) public note cdpAllowed(cdp) {
        VatLike(vat).flux(ilks[cdp], urns[cdp], dst, wad);
    }



    function flux(
        bytes32 ilk,
        uint cdp,
        address dst,
        uint wad
    ) public note cdpAllowed(cdp) {
        VatLike(vat).flux(ilk, urns[cdp], dst, wad);
    }


    function move(
        uint cdp,
        address dst,
        uint rad
    ) public note cdpAllowed(cdp) {
        VatLike(vat).move(urns[cdp], dst, rad);
    }


    function quit(
        uint cdp,
        address dst
    ) public note cdpAllowed(cdp) urnAllowed(dst) {
        (uint ink, uint art) = VatLike(vat).urns(ilks[cdp], urns[cdp]);
        VatLike(vat).fork(
            ilks[cdp],
            urns[cdp],
            dst,
            toInt(ink),
            toInt(art)
        );
    }


    function enter(
        address src,
        uint cdp
    ) public note urnAllowed(src) cdpAllowed(cdp) {
        (uint ink, uint art) = VatLike(vat).urns(ilks[cdp], src);
        VatLike(vat).fork(
            ilks[cdp],
            src,
            urns[cdp],
            toInt(ink),
            toInt(art)
        );
    }


    function shift(
        uint cdpSrc,
        uint cdpDst
    ) public note cdpAllowed(cdpSrc) cdpAllowed(cdpDst) {
        require(ilks[cdpSrc] == ilks[cdpDst], "non-matching-cdps");
        (uint ink, uint art) = VatLike(vat).urns(ilks[cdpSrc], urns[cdpSrc]);
        VatLike(vat).fork(
            ilks[cdpSrc],
            urns[cdpSrc],
            urns[cdpDst],
            toInt(ink),
            toInt(art)
        );
    }
}


interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}


contract VatLike {
    function urns(bytes32, address) public view returns (uint, uint);
    function hope(address) external;
    function flux(bytes32, address, address, uint) public;
    function move(address, address, uint) public;
    function frob(bytes32, address, address, address, int, int) public;
    function fork(bytes32, address, address, int, int) public;
    function ilks(bytes32 ilk) public view returns(uint Art, uint rate, uint spot, uint line, uint dust);
    function dai(address usr) external view returns(uint);
}

contract CatLike {
    function ilks(bytes32) public returns(address flip, uint256 chop, uint256 lump);
}

contract EndLike {
    function cat() public view returns(CatLike);
}

contract PriceFeedLike {
    function read(bytes32 ilk) external view returns(bytes32);
}

contract LiquidationMachine is DssCdpManager, BCdpScoreConnector, Math {
    VatLike                   public vat;
    EndLike                   public end;
    address                   public pool;
    PriceFeedLike             public real;

    mapping(uint => uint)     public tic;
    mapping(uint => uint)     public cushion;

    uint constant             public GRACE = 1 hours;
    uint constant             public WAD = 1e18;

    mapping (uint => bool)    public out;

    modifier onlyPool {
        require(msg.sender == pool, "not-pool");
        _;
    }

    constructor(VatLike vat_, EndLike end_, address pool_, PriceFeedLike real_) public {
        vat = vat_;
        end = end_;
        pool = pool_;
        real = real_;
    }

    function setPool(address newPool) internal {
        pool = newPool;
    }

    function quitBLiquidation(uint cdp) internal {
        untop(cdp);
        out[cdp] = true;
    }

    function topup(uint cdp, uint dtopup) public onlyPool {
        if(out[cdp]) return;

        address urn = urns[cdp];
        bytes32 ilk = ilks[cdp];

        (, uint rate,,,) = vat.ilks(ilk);
        uint dtab = mul(rate, dtopup);

        vat.move(pool, address(this), dtab);
        vat.frob(ilk, urn, urn, address(this), 0, -toInt(dtopup));

        cushion[cdp] = add(cushion[cdp], dtopup);
    }

    function bitten(uint cdp) public view returns(bool) {
        return tic[cdp] + GRACE > now;
    }

    function untop(uint cdp) internal {
        require(! bitten(cdp), "untop: cdp was already bitten");

        uint top = cushion[cdp];
        if(top == 0) return;

        bytes32 ilk = ilks[cdp];
        address urn = urns[cdp];

        (, uint rate,,,) = vat.ilks(ilk);
        uint dtab = mul(rate, top);

        cushion[cdp] = 0;


        vat.frob(ilk, urn, urn, urn, 0, toInt(top));
        vat.move(urn, pool, dtab);
    }

    function untopByPool(uint cdp) public onlyPool {
        untop(cdp);
    }

    function doBite(uint dart, bytes32 ilk, address urn, uint dink) internal {
        (, uint rate,,,) = vat.ilks(ilk);
        uint dtab = mul(rate, dart);

        vat.move(pool, address(this), dtab);

        vat.frob(ilk, urn, urn, address(this), 0, -toInt(dart));
        vat.frob(ilk, urn, msg.sender, urn, -toInt(dink), 0);
    }

    function calcDink(uint dart, uint rate, bytes32 ilk) internal returns(uint dink) {
        (, uint chop,) = end.cat().ilks(ilk);
        uint tab = mul(mul(dart, rate), chop) / WAD;
        bytes32 realtimePrice = real.read(ilk);

        dink = rmul(tab, WAD) / uint(realtimePrice);
    }

    function bite(uint cdp, uint dart) public onlyPool returns(uint dink){
        address urn = urns[cdp];
        bytes32 ilk = ilks[cdp];

        (uint ink, uint art) = vat.urns(ilk, urn);
        art = add(art, cushion[cdp]);
        (, uint rate, uint spotValue,,) = vat.ilks(ilk);

        require(dart <= art, "debt is too low");


        if(! bitten(cdp)) {
            require(mul(art, rate) > mul(ink, spotValue), "bite: cdp is safe");
            require(cushion[cdp] > 0, "bite: not-topped");
            tic[cdp] = now;
        }

        dink = calcDink(dart, rate, ilk);
        updateScore(cdp, ilk, -toInt(dink), -toInt(dart), now);

        uint usedCushion = mul(cushion[cdp], dart) / art;
        cushion[cdp] = sub(cushion[cdp], usedCushion);
        uint bart = sub(dart, usedCushion);

        doBite(bart, ilk, urn, dink);
    }
}


contract BCdpManager is BCdpScoreConnector, LiquidationMachine, DSAuth {
    constructor(address vat_, address end_, address pool_, address real_, address score_) public
        DssCdpManager(vat_)
        LiquidationMachine(VatLike(vat_), EndLike(end_), pool_, PriceFeedLike(real_))
        BCdpScoreConnector(BCdpScoreLike(score_))
    {

    }


    function frob(
        uint cdp,
        int dink,
        int dart
    ) public cdpAllowed(cdp) {
        bytes32 ilk = ilks[cdp];

        untop(cdp);
        updateScore(cdp, ilk, dink, dart, now);

        super.frob(cdp, dink, dart);
    }


    function quit(
        uint cdp,
        address dst
    ) public cdpAllowed(cdp) urnAllowed(dst) {
        address urn = urns[cdp];
        bytes32 ilk = ilks[cdp];

        untop(cdp);
        (uint ink, uint art) = vat.urns(ilk, urn);
        updateScore(cdp, ilk, -toInt(ink), -toInt(art), now);

        super.quit(cdp, dst);
    }


    function enter(
        address src,
        uint cdp
    ) public urnAllowed(src) cdpAllowed(cdp) {
        bytes32 ilk = ilks[cdp];

        untop(cdp);
        (uint ink, uint art) = vat.urns(ilk, src);
        updateScore(cdp, ilk, toInt(ink), toInt(art), now);

        super.enter(src, cdp);
    }


    function shift(
        uint cdpSrc,
        uint cdpDst
    ) public cdpAllowed(cdpSrc) cdpAllowed(cdpDst) {
        bytes32 ilkSrc = ilks[cdpSrc];

        untop(cdpSrc);
        untop(cdpDst);

        address src = urns[cdpSrc];

        (uint inkSrc, uint artSrc) = vat.urns(ilkSrc, src);

        updateScore(cdpSrc, ilkSrc, -toInt(inkSrc), -toInt(artSrc), now);
        updateScore(cdpDst, ilkSrc, toInt(inkSrc), toInt(artSrc), now);

        super.shift(cdpSrc, cdpDst);
    }



    function quitB(uint cdp) public cdpAllowed(cdp) note {
        quitScore(cdp);
        quitBLiquidation(cdp);
    }

    function setScoreContract(BCdpScoreLike _score) public auth {
        super.setScore(_score);
    }

    function setPoolContract(address _pool) public auth {
        super.setPool(_pool);
    }
}

contract Context {


    constructor () internal { }


    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }




    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }








    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }




    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ScoringMachine is Ownable {
    struct AssetScore {

        uint score;


        uint balance;


        uint last;
    }


    mapping(bytes32 => mapping(bytes32 => AssetScore[])) public checkpoints;

    mapping(bytes32 => mapping(bytes32 => AssetScore)) public userScore;

    bytes32 constant public GLOBAL_USER = bytes32(0x0);

    uint public start;

    function spin() public onlyOwner {
        start = now;
    }

    function assetScore(AssetScore storage score, uint time, uint spinStart) internal view returns(uint) {
        uint last = score.last;
        uint currentScore = score.score;
        if(last < spinStart) {
            last = spinStart;
            currentScore = 0;
        }

        return add(currentScore, mul(score.balance, sub(time, last)));
    }

    function addCheckpoint(bytes32 user, bytes32 asset) internal {
        checkpoints[user][asset].push(userScore[user][asset]);
    }

    function updateAssetScore(bytes32 user, bytes32 asset, int dbalance, uint time) internal {
        AssetScore storage score = userScore[user][asset];

        if(score.last < start) addCheckpoint(user, asset);

        score.score = assetScore(score, time, start);
        score.balance = add(score.balance, dbalance);

        score.last = time;
    }

    function updateScore(bytes32 user, bytes32 asset, int dbalance, uint time) internal {
        updateAssetScore(user, asset, dbalance, time);
        updateAssetScore(GLOBAL_USER, asset, dbalance, time);
    }

    function getScore(bytes32 user, bytes32 asset, uint time, uint spinStart, uint checkPointHint) public view returns(uint score) {
        if(time >= userScore[user][asset].last) return assetScore(userScore[user][asset], time, spinStart);


        uint checkpointsLen = checkpoints[user][asset].length;
        if(checkpointsLen == 0) return 0;


        if(checkpoints[user][asset][checkPointHint].last < time) checkPointHint = checkpointsLen - 1;

        for(uint i = checkPointHint ; ; i--){
            if(checkpoints[user][asset][i].last <= time) return assetScore(checkpoints[user][asset][i], time, spinStart);
        }


        return 0;
    }

    function getCurrentBalance(bytes32 user, bytes32 asset) public view returns(uint balance) {
        balance = userScore[user][asset].balance;
    }



    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        if(!(z >= x)) return 0;

        return z;
    }

    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        if(!(y >= 0 || z <= x)) return 0;
        if(!(y <= 0 || z >= x)) return 0;

        return z;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        if(!(y <= x)) return 0;
        z = x - y;

        return z;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        if (x == 0) return 0;

        z = x * y;
        if(!(z / x == y)) return 0;

        return z;
    }
}


contract BCdpScore is ScoringMachine {
    BCdpManager public manager;

    modifier onlyManager {
        require(msg.sender == address(manager), "not-manager");
        _;
    }

    function setManager(address newManager) public onlyOwner {
        manager = BCdpManager(newManager);
    }

    function user(uint cdp) public pure returns(bytes32) {
        return keccak256(abi.encodePacked("BCdpScore", cdp));
    }

    function artAsset(bytes32 ilk) public pure returns(bytes32) {
        return keccak256(abi.encodePacked("BCdpScore", "art", ilk));
    }

    function updateScore(uint cdp, bytes32 ilk, int dink, int dart, uint time) public onlyManager {
        dink;
        updateScore(user(cdp), artAsset(ilk), dart, time);
    }

    function slashScore(uint maliciousCdp) public {
        address urn = manager.urns(maliciousCdp);
        bytes32 ilk = manager.ilks(maliciousCdp);

        (, uint realArt) = manager.vat().urns(ilk, urn);

        bytes32 maliciousUser = user(maliciousCdp);
        bytes32 asset = artAsset(ilk);

        uint left = BCdpScoreConnector(address(manager)).left(maliciousCdp);

        realArt = left > 0 ? 0 : realArt;
        uint startTime = left > 0 ? left : now;

        uint calculatedArt = getCurrentBalance(maliciousUser, asset);
        require(realArt < calculatedArt, "slashScore-cdp-is-ok");
        int dart = int(realArt) - int(calculatedArt);
        uint time = sub(startTime, 30 days);
        if(time < start) time = start;

        updateScore(maliciousUser, asset, dart, time);
    }

    function getArtScore(uint cdp, bytes32 ilk, uint time, uint spinStart) public view returns(uint) {
        return getScore(user(cdp), artAsset(ilk), time, spinStart, 0);
    }

    function getArtGlobalScore(bytes32 ilk, uint time, uint spinStart) public view returns(uint) {
        return getScore(GLOBAL_USER, artAsset(ilk), time, spinStart, 0);
    }
}



contract JarConnector is Math {
    BCdpScore   public score;
    BCdpManager public man;
    bytes32[]   public ilks;

    mapping(bytes32 => bool) public milks;


    uint[2] public end;

    uint[2] public start;

    uint public round;

    constructor(
        bytes32[] memory _ilks,
        uint[2] memory _duration
    ) public {
        ilks = _ilks;

        for(uint i = 0; i < _ilks.length; i++) {
            milks[_ilks[i]] = true;
        }

        end[0] = now + _duration[0];
        end[1] = now + _duration[0] + _duration[1];

        round = 0;
    }

    function setManager(address _manager) public {
        require(man == BCdpManager(0), "manager-already-set");
        man = BCdpManager(_manager);
        score = BCdpScore(address(man.score()));
    }


    function spin() public {
        if(round == 0) {
            round++;
            score.spin();
            start[0] = score.start();
        }
        if(round == 1 && now > end[0]) {
            round++;
            score.spin();
            start[1] = score.start();
        }
        if(round == 2 && now > end[1]) {
            round++;

            score.spin();
        }
    }

    function getUserScore(bytes32 user) public view returns (uint) {
        if(round == 0) return 0;

        uint cdp = uint(user);
        bytes32 ilk = man.ilks(cdp);


        if( ! milks[ilk]) return 0;

        if(round == 1) return 2 * score.getArtScore(cdp, ilk, now, start[0]);

        uint firstRoundScore = 2 * score.getArtScore(cdp, ilk, start[1], start[0]);
        uint time = now;
        if(round > 2) time = end[1];

        return add(score.getArtScore(cdp, ilk, time, start[1]), firstRoundScore);
    }

    function getGlobalScore() public view returns (uint) {
        if(round == 0) return 0;

        if(round == 1) return 2 * getArtGlobalScore(now, start[0]);

        uint firstRoundScore = 2 * getArtGlobalScore(start[1], start[0]);
        uint time = now;
        if(round > 2) time = end[1];

        return add(getArtGlobalScore(time, start[1]), firstRoundScore);
    }

    function getGlobalScore(bytes32 ilk) public view returns (uint) {
        if(round == 0) return 0;

        if(round == 1) return 2 * score.getArtGlobalScore(ilk, now, start[0]);

        uint firstRoundScore = 2 * score.getArtGlobalScore(ilk, start[1], start[0]);
        uint time = now;
        if(round > 2) time = end[1];

        return add(score.getArtGlobalScore(ilk, time, start[1]), firstRoundScore);
    }

    function getArtGlobalScore(uint time, uint spinStart) internal view returns (uint totalScore) {
        for(uint i = 0; i < ilks.length; i++) {
            totalScore = add(totalScore, score.getArtGlobalScore(ilks[i], time, spinStart));
        }
    }

    function toUser(bytes32 user) public view returns (address) {
        return man.owns(uint(user));
    }
}


contract JugLike {
    function ilks(bytes32 ilk) public view returns(uint duty, uint rho);
    function base() public view returns(uint);
}


contract SpotLike {
    function par() external view returns (uint256);
    function ilks(bytes32 ilk) external view returns (address pip, uint mat);
}

contract OSMLike {
    function peep() external view returns(bytes32, bool);
    function hop()  external view returns(uint16);
    function zzz()  external view returns(uint64);
}

contract DaiToUsdPriceFeed {
    function getMarketPrice(uint marketId) public view returns (uint);
}

contract Pool is Math, DSAuth, LibNote {
    uint public constant DAI_MARKET_ID = 3;
    address[] public members;
    mapping(bytes32 => bool) public ilks;
    uint                     public minArt;
    uint                     public shrn;
    uint                     public shrd;
    mapping(address => uint) public rad;

    VatLike                   public vat;
    BCdpManager               public man;
    SpotLike                  public spot;
    JugLike                   public jug;
    address                   public jar;
    DaiToUsdPriceFeed         public dai2usd;

    mapping(uint => CdpData)  internal cdpData;

    mapping(bytes32 => OSMLike) public osm;

    struct CdpData {
        uint       art;
        uint       cushion;
        address[]  members;
        uint[]     bite;
    }

    modifier onlyMember {
        bool member = false;
        for(uint i = 0 ; i < members.length ; i++) {
            if(members[i] == msg.sender) {
                member = true;
                break;
            }
        }
        require(member, "not-member");
        _;
    }

    constructor(address vat_, address jar_, address spot_, address jug_, address dai2usd_) public {
        spot = SpotLike(spot_);
        jug = JugLike(jug_);
        vat = VatLike(vat_);
        jar = jar_;
        dai2usd = DaiToUsdPriceFeed(dai2usd_);
    }

    function getCdpData(uint cdp) public view returns(uint art, uint cushion, address[] memory members_, uint[] memory bite) {
        art = cdpData[cdp].art;
        cushion = cdpData[cdp].cushion;
        members_ = cdpData[cdp].members;
        bite = cdpData[cdp].bite;
    }

    function setCdpManager(BCdpManager man_) public auth note {
        man = man_;
        vat.hope(address(man));
    }

    function setOsm(bytes32 ilk_, address  osm_) public auth note {
        osm[ilk_] = OSMLike(osm_);
    }

    function setMembers(address[] calldata members_) external auth note {
        members = members_;
    }

    function setIlk(bytes32 ilk, bool set) public auth note {
        ilks[ilk] = set;
    }

    function setMinArt(uint minArt_) public auth note {
        minArt = minArt_;
    }

    function setDaiToUsdPriceFeed(address dai2usd_) public auth note {
        dai2usd = DaiToUsdPriceFeed(dai2usd_);
    }

    function setProfitParams(uint num, uint den) public auth note {
        require(num < den, "invalid-profit-params");
        shrn = num;
        shrd = den;
    }

    function emergencyExecute(address target, bytes calldata data) external auth note {
        (bool succ,) = target.call(data);
        require(succ, "emergencyExecute: failed");
    }

    function deposit(uint radVal) public onlyMember note {
        vat.move(msg.sender, address(this), radVal);
        rad[msg.sender] = add(rad[msg.sender], radVal);
    }

    function withdraw(uint radVal) public note {
        require(rad[msg.sender] >= radVal, "withdraw: insufficient-balance");
        rad[msg.sender] = sub(rad[msg.sender], radVal);
        vat.move(address(this), msg.sender, radVal);
    }

    function getIndex(address[] storage array, address elm) internal view returns(uint) {
        for(uint i = 0 ; i < array.length ; i++) {
            if(array[i] == elm) return i;
        }

        return uint(-1);
    }

    function removeElement(address[] memory array, uint index) internal pure returns(address[] memory newArray) {
        if(index >= array.length) {
            newArray = array;
        }
        else {
            newArray = new address[](array.length - 1);
            for(uint i = 0 ; i < array.length ; i++) {
                if(i == index) continue;
                if(i < index) newArray[i] = array[i];
                else newArray[i-1] = array[i];
            }
        }
    }

    function chooseMember(uint cdp, uint radVal, address[] memory candidates) public view returns(address[] memory winners) {
        if(candidates.length == 0) return candidates;


        uint chosen = uint(keccak256(abi.encodePacked(cdp, now / 1 hours))) % candidates.length;
        address winner = candidates[chosen];

        if(rad[winner] < radVal) return chooseMember(cdp, radVal, removeElement(candidates, chosen));

        winners = new address[](1);
        winners[0] = candidates[chosen];
        return winners;
    }

    function chooseMembers(uint radVal, address[] memory candidates) public view returns(address[] memory winners) {
        if(candidates.length == 0) return candidates;

        uint need = add(1, radVal / candidates.length);
        for(uint i = 0 ; i < candidates.length ; i++) {
            if(rad[candidates[i]] < need) {
                return chooseMembers(radVal, removeElement(candidates, i));
            }
        }

        winners = candidates;
    }

    function calcCushion(bytes32 ilk, uint ink, uint art, uint nextSpot) public view returns(uint dart, uint dtab) {
        (, uint prev, uint currSpot,,) = vat.ilks(ilk);
        if(currSpot <= nextSpot) return (0, 0);

        uint hop = uint(osm[ilk].hop());
        uint next = add(uint(osm[ilk].zzz()), hop);
        (uint duty, uint rho) = jug.ilks(ilk);

        require(next >= rho, "calcCushion: next-in-the-past");





        uint nextRate = rmul(rpow(add(jug.base(), duty), next - rho, RAY), prev);
        uint nextnextRate = rmul(rpow(add(jug.base(), duty), hop, RAY), nextRate);

        if(mul(nextRate, art) > mul(ink, currSpot)) return (0, 0);
        if(mul(nextRate, art) <= mul(ink, nextSpot)) return (0, 0);

        uint maxArt = mul(ink, nextSpot) / nextnextRate;
        dart = sub(art, maxArt);
        dart = add(1 ether, dart);
        dtab = mul(dart, prev);
    }

    function hypoTopAmount(uint cdp) internal view returns(uint dart, uint dtab, uint art, bool should) {
        address urn = man.urns(cdp);
        bytes32 ilk = man.ilks(cdp);

        uint ink;
        (ink, art) = vat.urns(ilk, urn);

        if(! ilks[ilk]) return (0, 0, art, false);

        (bytes32 peep, bool valid) = osm[ilk].peep();


        if(! valid) return (0, 0, art, false);


        should = (now >= add(uint(osm[ilk].zzz()), uint(osm[ilk].hop())/2));

        (, uint mat) = spot.ilks(ilk);
        uint par = spot.par();

        uint nextVatSpot = rdiv(rdiv(mul(uint(peep), uint(10 ** 9)), par), mat);

        (dart, dtab) = calcCushion(ilk, ink, art, nextVatSpot);
    }

    function topAmount(uint cdp) public view returns(uint dart, uint dtab, uint art) {
        bool should;
        (dart, dtab, art, should) = hypoTopAmount(cdp);
        if(! should) return (0, 0, art);
    }

    function resetCdp(uint cdp) internal {
        address[] memory winners = cdpData[cdp].members;

        if(winners.length == 0) return;

        uint art = cdpData[cdp].art;
        uint cushion = cdpData[cdp].cushion;

        uint perUserArt = cdpData[cdp].art / winners.length;
        for(uint i = 0 ; i < winners.length ; i++) {
            if(perUserArt <= cdpData[cdp].bite[i]) continue;
            uint refundArt = sub(perUserArt, cdpData[cdp].bite[i]);
            rad[winners[i]] = add(rad[winners[i]], mul(refundArt, cushion)/art);
        }

        cdpData[cdp].art = 0;
        cdpData[cdp].cushion = 0;
        delete cdpData[cdp].members;
        delete cdpData[cdp].bite;
    }

    function setCdp(uint cdp, address[] memory winners, uint art, uint dradVal) internal {
        uint drad = add(1, dradVal / winners.length);
        for(uint i = 0 ; i < winners.length ; i++) {
            rad[winners[i]] = sub(rad[winners[i]], drad);
        }

        cdpData[cdp].art = art;
        cdpData[cdp].cushion = dradVal;
        cdpData[cdp].members = winners;
        cdpData[cdp].bite = new uint[](winners.length);
    }

    function topupInfo(uint cdp) public view returns(uint dart, uint dtab, uint art, bool should, address[] memory winners) {
        (dart, dtab, art, should) = hypoTopAmount(cdp);
        if(art < minArt) {
            winners = chooseMember(cdp, uint(dtab), members);
        }
        else winners = chooseMembers(uint(dtab), members);
    }

    function topup(uint cdp) public onlyMember note {
        require(man.cushion(cdp) == 0, "topup: already-topped");
        require(! man.bitten(cdp), "topup: already-bitten");

        (uint dart, uint dtab, uint art, bool should, address[] memory winners) = topupInfo(cdp);

        require(should, "topup: no-need");
        require(dart > 0, "topup: 0-dart");

        resetCdp(cdp);

        require(winners.length > 0, "topup: members-are-broke");

        if(art < minArt) require(winners[0] == msg.sender, "topup: only-winner-can-topup");

        setCdp(cdp, winners, uint(art), uint(dtab));

        man.topup(cdp, uint(dart));
    }

    function untop(uint cdp) public onlyMember note {
        require(man.cushion(cdp) == 0, "untop: should-be-untopped-by-user");

        resetCdp(cdp);
    }

    function bite(uint cdp, uint dart, uint minInk) public onlyMember note returns(uint dMemberInk){
        uint index = getIndex(cdpData[cdp].members, msg.sender);
        uint availBite = availBite(cdp, index);
        require(dart <= availBite, "bite: debt-too-small");

        cdpData[cdp].bite[index] = add(cdpData[cdp].bite[index], dart);

        uint dink = man.bite(cdp, dart);


        bytes32 ilk = man.ilks(cdp);
        (,uint rate,,,) = vat.ilks(ilk);
        uint cushionPortion = mul(cdpData[cdp].cushion, dart) / cdpData[cdp].art;
        rad[msg.sender] = sub(rad[msg.sender], sub(mul(dart, rate), cushionPortion));


        uint d2uPrice = dai2usd.getMarketPrice(DAI_MARKET_ID);



        dMemberInk = mul(mul(dink, shrn), d2uPrice) / mul(shrd, uint(1 ether));


        if(dMemberInk > dink) dMemberInk = dink;


        uint userInk = sub(dink, dMemberInk);

        require(dMemberInk >= minInk, "bite: low-dink");

        vat.flux(ilk, address(this), jar, userInk);
        vat.flux(ilk, address(this), msg.sender, dMemberInk);
    }

    function availBite(uint cdp, address member) public view returns (uint) {
        uint index = getIndex(cdpData[cdp].members, member);
        return availBite(cdp, index);
    }

    function availBite(uint cdp, uint index) internal view returns (uint) {
        if(index == uint(-1)) return 0;

        uint numMembers = cdpData[cdp].members.length;

        uint maxArt = cdpData[cdp].art / numMembers;

        if(index == 0) {
            uint dust = cdpData[cdp].art % numMembers;
            maxArt = add(maxArt, dust);
        }
        uint availArt = sub(maxArt, cdpData[cdp].bite[index]);

        address urn = man.urns(cdp);
        bytes32 ilk = man.ilks(cdp);
        (,uint art) = vat.urns(ilk, urn);
        uint remainingArt = add(art, man.cushion(cdp));

        return availArt < remainingArt ? availArt : remainingArt;
    }
}
