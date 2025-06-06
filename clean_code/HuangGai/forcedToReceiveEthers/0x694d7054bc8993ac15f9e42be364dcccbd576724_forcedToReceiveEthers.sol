



pragma solidity ^0.5.16;

































interface AnftToken {
  function mint(address account, uint256 tokenId) external returns (bool);
  function safeMint(address to, uint256 tokenId, bytes calldata _data) external returns (bool);
  function ownerOf(uint256 tokenId) external returns (address owner);
  function totalSupply() external view returns (uint256);
}

interface ApwrToken {
  function mint(address account, uint256 amount) external;
  function totalSupply() external returns (uint256);
  function burnFrom(address account, uint256 _value) external;
}

interface ArtdToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
}

interface NFTFactory{
    function getMeta( uint256 resId ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, address);
    function getMeta2( uint256 nftId ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    function getFactory( uint256 nftId ) external view returns (address);
    function renewPromote( uint256 nftId, uint256 value ) external;
    function renewAmount( uint256 nftId, uint256 value ) external;
    function renewAPWR( uint256 nftId, uint256 value ) external;
    function renewSKILL( uint256 nftId, uint256 value ) external;
    function renewLocktime( uint256 nftId, uint256 value ) external;
    function getAuthor( uint256 nftId ) external view returns (address);
    function getcreatedTime( uint256 nftId ) external view returns (uint256);
    function getLock( uint256 nftId ) external view returns (uint256);
}

interface validfactory {
  function isValidfactory( address _factory ) external view returns (bool);
}

interface ArttToken {
  function transferFrom(address src, address dst, uint rawAmount) external returns (bool);
}

interface RandomSeed {
  function random_getSeed( address sender, uint256 num ) external view returns (uint256);
  function random_get9999( address sender, uint256 random ) external view returns (uint);
  function random_get9999x( address sender, uint256 num ) external returns (uint);
}







contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner());
        _;
    }




    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }







    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }





    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}






library SafeMath {
    int256 constant private INT256_MIN = -2**255;




    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }




    function mul(int256 a, int256 b) internal pure returns (int256) {



        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));

        int256 c = a * b;
        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }




    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);
        require(!(b == -1 && a == INT256_MIN));

        int256 c = a / b;

        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }




    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }




    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}





library Address {







    function isContract(address account) internal view returns (bool) {
        uint256 size;







        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract nftMeta {

     mapping(uint256 => uint256) internal _era;
     mapping(uint256 => uint256) internal _grade;
     mapping(uint256 => uint256) internal _promote;
     mapping(uint256 => uint256) internal _artdamount;
     mapping(uint256 => uint256) internal _apwramount;
     mapping(uint256 => uint256) internal _skill;
     mapping(uint256 => address) internal _factory;

     mapping(uint256 => address) internal _author;
     mapping(uint256 => uint256) internal _createdTime;
     mapping(uint256 => uint256) internal _lock;
}



contract NftFactory is  Ownable, nftMeta {
    using SafeMath for uint256;
    using Address for address;

    uint256 private releaseDate;

    address public _artd =  address(0xA23F8462d90dbc60a06B9226206bFACdEAD2A26F);
    address public _anft =  address(0x99a7e1188CE9a0b7514d084878DFb8A405D8529F);
    address public _apwr = address(0xb60F072494c7f1b5a8ba46bc735C71A83D940D1A);
    address public _artt = address(0x77dF79539083DCd4a8898dbA296d899aFef20067);
    address public _fundpool = address(0x37C8fC383e037f92f501E5884B8B5E37e3f5170E);

    address public _validchecker = address(0x58F62d9B184BE5D7eE6881854DD16898Afe0cf90);
    address private _randseed = address(0x75A7c0f3c7E59D0Aa323cc8832EaF2729Fe2127C);

    address public _relay = address(0);

    address public _burnPool = 0x6666666666666666666666666666666666666666;

    uint256 public _eraNFT = 1;
    uint256 private pwrdist = 0.01 * 1e18;

    address[] public _allfactorylist;
    uint256 public _storestartTime =  now + 365 days;
    uint256 private nonce = 0;
    uint256 private max_promote = 9999;
    uint256 public constant _rateBase = 10000;
    uint256 public _burnRate = 250;
    uint256 public _rewardRate = 250;
    uint256 public _claimdays = 60 days;

    bytes _data = new bytes(0);

    mapping(uint256 => uint256) public _lastStoreTime;
    mapping(uint256 => uint) private _allowchallenge;


    mapping (address => bool) public hasClaimed;

    event TokenParameter(uint256 indexed resId, uint256 era, uint256 grade, uint256 promote, uint256 artdamount, uint256 apwramount,uint256 skill, address factory, address author, uint256 createdTime);
    event DataParameter( bytes _data );
    event Store(uint256 indexed Id, address user, uint256 amount);
    event Withdraw(uint256 indexed Id, address user, uint256 amount);
    event MetaUpdated(address addr, uint256 nftid, uint256 value);
    event Fusion(uint256 nftId1, uint256 nftId2, uint256 value);
    event Challenge(uint256 nftId, bool winlose, uint256 diffamount, uint256 finalamount);
    event RaisePower(uint256 indexed Id, address user, uint256 amount);
    event ADDSKILL(uint256 indexed Id, address user, uint256 amount);
    event SwChallenge(uint256 nftId, bool onoff);
    event LockTime(uint256 nftId, uint256 time);
    event Grade1(address user, uint256 time, uint256 block);
    event Grade2(address user, uint256 time, uint256 block);
    event Grade3(address user, uint256 time, uint256 block);
    event Grade4(address user, uint256 time, uint256 block);
    event Grade5(address user, uint256 time, uint256 block);
    event Grade6(address user, uint256 time, uint256 block);


    modifier hasNotClaimed() {
        require(hasClaimed[msg.sender] == false);
        _;
    }


    modifier canClaim() {
        require(releaseDate + _claimdays >= now);
        _;
    }

    modifier checkstoreStart() {
        require(block.timestamp > _storestartTime, "store not start");
        _;
    }

    constructor() public {

        releaseDate = now;
        _allfactorylist.push( address(this) );
    }

    function _random_get_seed( uint256 num ) internal view returns (uint256) {

        RandomSeed _rc = RandomSeed(_randseed);
        return _rc.random_getSeed(msg.sender,num);
    }

    function _randomGrade( uint random ) internal view returns (uint8) {

        RandomSeed _rc = RandomSeed(_randseed);
        uint256 num = _rc.random_get9999(msg.sender,random);

        uint8 grade = 1;

        if ( num >= 9995 ){
            grade = 6;
        }
        else if ( num >= 9965 ){
            grade = 5;
        }
        else if ( num >= 9800 ){
            grade = 4;
        }
        else if ( num >= 9500 ){
            grade = 3;
        }
        else if ( num >= 7000 ){
            grade = 2;
        }
        return grade;
    }

    function _randomGradeX() internal returns (uint8)
    {
        nonce = nonce + 1;
        RandomSeed _rc = RandomSeed(_randseed);
        uint256 num = _rc.random_get9999x(msg.sender,nonce);

        uint8 grade = 1;

        if ( num >= 9995 ){
            grade = 6;
        }
        else if ( num >= 9965 ){
            grade = 5;
        }
        else if ( num >= 9800 ){
            grade = 4;
        }
        else if ( num >= 9500 ){
            grade = 3;
        }
        else if ( num >= 7000 ){
            grade = 2;
        }
        return grade;
    }

    function _randomPromote() internal view returns (uint256) {

        uint256 num = _random_get_seed( nonce ) % 1000;

        return num;
    }

    function setPower( uint256 newpwrdist ) external onlyOwner {
        pwrdist = newpwrdist;
    }

    function setRate(uint256 burn_rate, uint256 reward_rate) external onlyOwner
    {
        _burnRate = burn_rate;
        _rewardRate = reward_rate;
    }

    function setArtd( address artd ) external onlyOwner {
        _artd = artd;
    }

    function setAnft( address anft ) external onlyOwner {
        _anft = anft;
    }

    function setApwr( address apwr ) external onlyOwner {
        _apwr = apwr;
    }

    function setArtt( address artt ) external onlyOwner {
        _artt = artt;
    }

    function setFundPool( address fundpool ) external onlyOwner {
       _fundpool = fundpool;
    }

    function seteraNFT( uint256 era ) external onlyOwner {
        _eraNFT = era;
    }

    function setvalidchecker( address checker ) external onlyOwner {
        _validchecker = checker;
    }

    function setstoreStart( uint256 starttime ) external onlyOwner {
        _storestartTime = starttime;
    }

    function setclaimDays( uint256 claimdays ) external onlyOwner {
        _claimdays = claimdays;
    }

    function setranseed( address ranseed ) external onlyOwner {
        _randseed = ranseed;
    }

    function getMeta_current( uint256 nftId ) internal view returns (uint256, uint256, uint256, uint256, uint256, uint256, address)
    {
       return ( _era[nftId], _grade[nftId], _promote[nftId], _artdamount[nftId], _apwramount[nftId], _skill[nftId], _factory[nftId]);
    }

    function getMeta( uint256 nftId ) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, address)
    {
        if( _grade[nftId] != 0 )
        {
            return getMeta_current(nftId);
        }
        else{
            for (uint i = 0; i < _allfactorylist.length; i++) {
               NFTFactory _nftfactoryx =  NFTFactory(_allfactorylist[i]);
               (uint256 t1,,,,,,) = _nftfactoryx.getMeta( nftId );
               if( t1 != 0){
                    return _nftfactoryx.getMeta( nftId );
                }
            }
            return (0, 0, 0, 0, 0, 0, address(0) );
        }
    }


    function getMeta_current2( uint256 nftId ) internal view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
          return ( _era[nftId], _grade[nftId], _promote[nftId], _artdamount[nftId], _apwramount[nftId], _skill[nftId], _lock[nftId] );
    }

    function getMeta2( uint256 nftId ) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        if( _grade[nftId] != 0 )
        {
            return getMeta_current2(nftId);
        }
        else{
            for (uint i = 0; i < _allfactorylist.length; i++) {
               NFTFactory _nftfactoryx =  NFTFactory(_allfactorylist[i]);
               (uint256 t1,,,,,,) = _nftfactoryx.getMeta2( nftId );
               if( t1 != 0){
                    return _nftfactoryx.getMeta2( nftId );
                }
            }
            return (0, 0, 0, 0, 0, 0, 0 );
        }
    }

    function setlinkFactory( address[] calldata _factorylist ) external onlyOwner {
        _allfactorylist = _factorylist;
    }

    function fusion( uint256 nftId1, uint256 nftId2 ) external
    {
        address owner1 = NFTownerOf(nftId1);
        address owner2 = NFTownerOf(nftId2);
        require(msg.sender == owner1 && msg.sender == owner2);
        require(nftId1 != nftId2, "TWO NFTs ID can not same");
        uint256 sum = 0;
        owner1 = address(0);
        owner2 = address(0);

        uint256 pm1 = 0;
        uint256 pm2 = 0;
        uint256 grade1 = 0;
        uint256 grade2 = 0;
        uint256 locktime1 = 0;
        uint256 locktime2 = 0;
        pm1 = this.getPormote( nftId1 );
        pm2 = this.getPormote( nftId2 );
        grade1 = this.getGrade( nftId1 );
        grade2 = this.getGrade( nftId2 );

        owner1 = this.getFactory(nftId1);
        owner2 = this.getFactory(nftId2);
        require(owner1 != address(0), "NFT ID1 not found");
        require(owner2 != address(0), "NFT ID2 not found");

        locktime1 = this.getLock(nftId1);
        locktime2 = this.getLock(nftId2);
        require(locktime1 < now && locktime2 < now, "Wait for locktime");

        if( pm1 > 0 && pm2 > 0 && grade1 >0 && grade2 >0 )
        {
             sum = pm1 + pm2;
             if( sum > max_promote )
                     sum = max_promote;
             if( grade2 > grade1 )
             {
                 updatePromote(owner2,nftId2,owner1,nftId1,sum);
                 emit MetaUpdated(owner2,nftId2,sum);
                 emit MetaUpdated(owner1,nftId1,0);
             }
             else{
                 updatePromote(owner1,nftId1,owner2,nftId2,sum);
                 emit MetaUpdated(owner1,nftId1,sum);
                 emit MetaUpdated(owner2,nftId2,0);
             }
             emit Fusion( nftId1, nftId2, sum);
        }
    }


    function updatePromote( address factory1, uint256 nftId1, address factory2, uint256 nftId2, uint256 value )
     private
    {
                if( nftId1 !=0 )
                {
                    NFTFactory f1 =  NFTFactory(factory1);
                    f1.renewPromote( nftId1, value );
                }
                if( nftId2 !=0 )
                {
                    NFTFactory f2 =  NFTFactory(factory2);
                    f2.renewPromote(  nftId2, 0 );
                }
    }

    function renewPromote( uint256 nftId, uint256 value ) external
    {
        validfactory _checker = validfactory(_validchecker);
        require( _checker.isValidfactory(msg.sender)==true );
        _promote[nftId] = value;
    }

    function updateAmount( address factory1, uint256 nftId1, uint256 value )
     private
    {
                if( nftId1 !=0 )
                {
                    NFTFactory f1 =  NFTFactory(factory1);
                    f1.renewAmount( nftId1, value );
                }
    }

    function renewAmount( uint256 nftId, uint256 value ) external
    {
        validfactory _checker = validfactory(_validchecker);
        require( _checker.isValidfactory(msg.sender)==true );
        _artdamount[nftId] = value;
    }


    function updateLocktime( address factory, uint256 nftId, uint256 value )
     private
    {
                if( nftId !=0 )
                {
                    NFTFactory f1 =  NFTFactory(factory);
                    f1.renewLocktime( nftId, value );
                }
    }

    function renewLocktime( uint256 nftId, uint256 value ) external
    {
        validfactory _checker = validfactory(_validchecker);
        require( _checker.isValidfactory(msg.sender)==true );
        _lock[nftId] = value;
    }


    function updateAPWR( address factory1, uint256 nftId1, uint256 value )
     private
    {
                if( nftId1 !=0 )
                {
                    NFTFactory f1 =  NFTFactory(factory1);
                    f1.renewAPWR( nftId1, value );
                }
    }

    function renewAPWR( uint256 nftId, uint256 value ) external
    {
        validfactory _checker = validfactory(_validchecker);
        require( _checker.isValidfactory(msg.sender)==true );
        _apwramount[nftId] = value;
    }

    function updateSKILL( address factory1, uint256 nftId1, uint256 value )
     private
    {
                if( nftId1 !=0 )
                {
                    NFTFactory f1 =  NFTFactory(factory1);
                    f1.renewSKILL( nftId1, value );
                }
    }

    function renewSKILL( uint256 nftId, uint256 value ) external
    {
        validfactory _checker = validfactory(_validchecker);
        require( _checker.isValidfactory(msg.sender)==true );
        _skill[nftId] = value;
    }

    function lockNft( uint256 nftId ) external
    {
        uint256 locktime = 0;
        address factory = NFTownerOf(nftId);
        require(msg.sender == factory);

        factory = this.getFactory(nftId);
        locktime = now + 14 days;
        updateLocktime( factory, nftId, locktime );

        emit LockTime( nftId, locktime );
    }


    function isAllowChallenge(uint256 nftId) external view returns (bool)
    {
        if( address(this).balance==0 )
           return false;
        return true;
    }

    function challengeSwitch( uint256 nftId, uint key) external
    {
        address owner = NFTownerOf(nftId);
        require(msg.sender == owner);
        _allowchallenge[nftId] = key;
        if( key != 0 )
            emit SwChallenge( nftId, true );
        else
            emit SwChallenge( nftId, false );
    }

    function randomChallenge( uint256 mynftId, uint256 targetId ) internal view returns (bool)
    {
        uint256 num = _random_get_seed( mynftId +  targetId + nonce ) % 10000;
        if ( num >= 5000 )
        {
            if( _allowchallenge[mynftId] >= _allowchallenge[targetId])
                return true;
            return false;
        }
        else
        {
            if( _allowchallenge[mynftId] < _allowchallenge[targetId])
                return true;
            return false;
        }
    }

    function challenge( uint256 mynftId, uint256 targetId) public
    {
        address owner1 = NFTownerOf(mynftId);
        require(msg.sender == owner1);
        address owner2 = NFTownerOf(targetId);

        require(owner1 != owner2, "NFTID owner can not same");
        require(mynftId != targetId, "TWO NFTs ID can not same");
        require(owner1 != address(0) && owner2 != address(0));
        require(_allowchallenge[targetId] != 0, "TargetId must turn-on switch");

        uint256 myStore = this.currentStore(mynftId);
        uint256 targetStore = this.currentStore(targetId);
        uint256 left = 0;
        uint256 diff_amount = 0;
        uint256 final_amount = 0;
        uint256 locktime1 = 0;
        uint256 locktime2 = 0;

        owner1 = this.getFactory(mynftId);
        owner2 = this.getFactory(targetId);
        require(owner1 != address(0), "mynftId not found");
        require(owner2 != address(0), "targetId not found");

        locktime1 = this.getLock(mynftId);
        locktime2 = this.getLock(targetId);
        require(locktime1 < now && locktime2 < now, "Wait for locktime");

        if( randomChallenge( mynftId, targetId ) == false)
        {
            left = myStore.mul(95).div(100);
            diff_amount = myStore - left;
            final_amount = diff_amount + targetStore;

            updateAmount(owner1, mynftId, left);
            updateAmount(owner2, targetId, final_amount);
            emit Challenge(mynftId, false, diff_amount, left);
            emit Challenge(targetId, true, diff_amount, final_amount);
        }
        else
        {
            left = targetStore.mul(95).div(100);
            diff_amount = targetStore - left;
            final_amount = diff_amount + myStore;

            updateAmount(owner1, mynftId, final_amount);
            updateAmount(owner2, targetId, left);
            emit Challenge(mynftId, true, diff_amount, final_amount);
            emit Challenge(targetId, false, diff_amount, left);
        }
        nonce = nonce + 1;
    }



    function getSkill( uint256 nftId ) external view returns (uint256)
    {
        uint256 currentskill = 0;
        uint256 aa = 0;
        uint256 s1 = 0;

        if( _grade[nftId] != 0 )
        {
            (,,,,,currentskill,) = getMeta_current(nftId);
            return currentskill;
        }
        for (uint i = 0; i < _allfactorylist.length; i++) {
           NFTFactory _nftfactoryx =  NFTFactory(_allfactorylist[i]);
           if( address(this).balance == 0 )
           {
               (,s1,,,,currentskill,) = _nftfactoryx.getMeta( nftId );
               if( s1 != 0){
                    aa = s1;
               }
           }
        }

        return currentskill;
    }

    function getEra( uint256 nftId ) external view returns (uint256)
    {
        uint256 era = 0;
        uint256 aa = 0;
        uint256 s1 = 0;

        if( _grade[nftId] != 0 )
        {
            (era,,,,,,) = getMeta_current(nftId);
            return era;
        }
        for (uint i = 0; i < _allfactorylist.length; i++) {
                   NFTFactory _nftfactoryx =  NFTFactory(_allfactorylist[i]);
                   if( address(this).balance == 0 )
                   {
                       (era,s1,,,,,) = _nftfactoryx.getMeta( nftId );
                       if( s1 != 0){
                            aa = s1;
                       }
                   }
        }

        return era;
    }

    function getGrade( uint256 nftId ) external view returns (uint256)
    {
        uint256 grade = 0;
        uint256 aa = 0;
        uint256 s1 = 0;
        if( _grade[nftId] != 0 )
        {
            (,grade,,,,,) = getMeta_current(nftId);
            return grade;
        }
        for (uint i = 0; i < _allfactorylist.length; i++) {
                   NFTFactory _nftfactoryx =  NFTFactory(_allfactorylist[i]);
                   if( address(this).balance == 0 )
                   {
                       (,grade,,,,,) = _nftfactoryx.getMeta( nftId );
                       if( s1 != 0){
                            aa = grade;
                       }
                   }
        }

        return grade;
    }

    function getPormote( uint256 nftId ) external view returns (uint256)
    {
        uint256 promote = 0;
        uint256 aa = 0;
        uint256 s1 = 0;
        if( _grade[nftId] != 0 )
        {
            (,,promote,,,,) = getMeta_current(nftId);
            return promote;
        }
        for (uint i = 0; i < _allfactorylist.length; i++) {
                   NFTFactory _nftfactoryx =  NFTFactory(_allfactorylist[i]);
                   if( address(this).balance == 0 )
                   {
                       (,s1,promote,,,,) = _nftfactoryx.getMeta( nftId );
                       if( s1 != 0){
                            aa = s1;
                       }
                   }
        }

        return promote;
    }

    function getFactory( uint256 nftId ) external view returns (address)
    {
        address factory = address(0);
        uint256 aa = 0;
        uint256 s1 = 0;
        if( _grade[nftId] != 0 )
        {
            (,,,,,,factory) = getMeta_current(nftId);
            return factory;
        }
        for (uint i = 0; i < _allfactorylist.length; i++) {
                   NFTFactory _nftfactoryx =  NFTFactory(_allfactorylist[i]);
                   if( address(this).balance == 0 )
                   {
                       (,s1,,,,,factory) = _nftfactoryx.getMeta( nftId );
                       if( s1 != 0){
                            aa = s1;
                       }
                   }
        }

        return factory;
    }

    function getPower( uint256 nftId ) external view returns (uint256)
    {
        uint256 currentpower = 0;
        uint256 aa = 0;
        uint256 s1 = 0;

        if( _grade[nftId] != 0 )
        {
            (,,,,currentpower,,) = getMeta_current(nftId);
            return currentpower;
        }
        for (uint i = 0; i < _allfactorylist.length; i++) {
           NFTFactory _nftfactoryx =  NFTFactory(_allfactorylist[i]);
           if( address(this).balance == 0 )
           {
               (,s1,,,currentpower,,) = _nftfactoryx.getMeta( nftId );
               if( s1 != 0){
                    aa = s1;
               }
           }
        }
        return currentpower;
    }

    function getAuthor( uint256 nftId ) external view returns (address)
    {
        address factory = address(0);
        factory = this.getFactory(nftId);
        if( factory == address(this) )
        {
             return _author[nftId];
        }
        else{
            NFTFactory f =  NFTFactory(factory);
            return f.getAuthor(nftId);
        }
    }

    function getLock( uint256 nftId ) external view returns (uint256)
    {
        address factory = address(0);
        factory = this.getFactory(nftId);
        if( factory == address(this) )
        {
             return _lock[nftId];
        }
        else{
            NFTFactory f =  NFTFactory(factory);
            return f.getLock(nftId);
        }
    }

    function getcreatedTime( uint256 nftId ) external view returns (uint256)
    {
        address factory = address(0);
        factory = this.getFactory(nftId);
        if( factory == address(this) )
        {
             return _createdTime[nftId];
        }
        else{
            NFTFactory f =  NFTFactory(factory);
            return f.getcreatedTime(nftId);
        }
    }

    function AddSkill( uint256 ARTTamount, uint256 nftId )
        public
        checkstoreStart
    {
        address factory = address(0);
        uint256 currentskill = 0;
        uint256 exskill = 0;
        uint256 locktime = 0;

        currentskill = this.getSkill( nftId );
        factory = this.getFactory(nftId);
        require(factory != address(0), "NFT ID not found");
        require(ARTTamount > 0, "Cannot burn 0 ARTT");

        locktime = this.getLock(nftId);
        require(locktime < now, "Wait for locktime");

        ArttToken _arttx =  ArttToken(_artt);
        _arttx.transferFrom(msg.sender, address(_burnPool), ARTTamount);

        exskill = ARTTamount/uint256(1e18);
        currentskill = currentskill.add(exskill);

        updateSKILL(factory, nftId, currentskill);

        emit ADDSKILL(nftId, msg.sender, ARTTamount);
    }



    function raisePower( uint256 APWRamount, uint256 nftId )
        public
        checkstoreStart
    {
        address factory = address(0);
        uint256 currentpower = 0;
        uint256 locktime = 0;

        currentpower = this.getPower( nftId );
        factory = this.getFactory(nftId);
        require(factory != address(0), "NFT ID not found");
        require(APWRamount > 0, "Cannot burn 0 APWR");

        locktime = this.getLock(nftId);
        require(locktime < now, "Wait for locktime");

        ApwrToken _apwrx =  ApwrToken(_apwr);
        _apwrx.burnFrom(msg.sender, APWRamount);

        currentpower = currentpower.add(APWRamount);
        updateAPWR(factory, nftId, currentpower);

        emit RaisePower(nftId, msg.sender, APWRamount);
    }


    function currentStore( uint256 nftId ) external view returns (uint256)
    {
        uint256 currentamount = 0;
        uint256 aa = 0;
        uint256 s1 = 0;
        if( _grade[nftId] != 0 )
        {
            (,,,currentamount,,,) = getMeta_current(nftId);
            return currentamount;
        }
        for (uint i = 0; i < _allfactorylist.length; i++) {
           NFTFactory _nftfactoryx =  NFTFactory(_allfactorylist[i]);
           if( address(this).balance == 0 )
           {
               (,s1,,currentamount,,,) = _nftfactoryx.getMeta( nftId );
               if( s1 != 0){
                    aa = s1;
               }
           }
        }

        return currentamount;
    }


    function store( uint256 amount, uint256 nftId )
        public
        checkstoreStart
    {
        uint256 locktime = 0;
        address factory = address(0);
        uint256 currentamount = 0;
        currentamount = this.currentStore( nftId );
        factory = this.getFactory(nftId);
        require(factory != address(0), "NFT ID not found");
        require(amount > 0, "Cannot store 0");

        locktime = this.getLock(nftId);
        require(locktime < now, "Wait for locktime");







        ArtdToken _artdx =  ArtdToken(_artd);
        _artdx.transferFrom(msg.sender, address(_fundpool), amount);

        uint256 left_amount = calcSendamount(amount);
        currentamount = currentamount.add(left_amount);

        updateAmount(factory, nftId, currentamount);
        _lastStoreTime[nftId] = now;

        emit Store(nftId, msg.sender, left_amount);
    }


    function withdraw( uint256 amount, uint256 nftId )
        public
        checkstoreStart
    {
        uint256 locktime = 0;
        address factory = address(0);
        uint256 currentamount = 0;
        currentamount = this.currentStore( nftId );

        factory = this.getFactory(nftId);
        require(factory != address(0), "NFT ID not found");
        address owner = NFTownerOf(nftId);
        require(msg.sender == owner);
        require(amount > 0 && currentamount >= amount, "withdraw amount error");

        locktime = this.getLock(nftId);
        require(locktime < now, "Wait for locktime");

        currentamount = currentamount.sub(amount);
        updateAmount(factory, nftId, currentamount);

        ArtdToken _artdx =  ArtdToken(_artd);
        _artdx.transferFrom(address(_fundpool), msg.sender, amount);

        emit Withdraw(nftId, msg.sender, amount);
    }






    function NFTownerOf(uint256 nftId) private returns (address) {
        AnftToken _anftx =  AnftToken(_anft);
        address owner = _anftx.ownerOf(nftId);
        require(owner != address(0));
        return owner;
    }


    function addresstoBytes(address x) internal pure returns (bytes memory b)
    {
         b = new bytes(32);
         for (uint i = 0; i < 32; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(31 - i)))));
    }

    function toBytesEth(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        for (uint i = 0; i < 32; i++) {
            b[i] = byte(uint8(x / (2**(8*(31 - i)))));
        }
    }

    function bytesConcat_uint256( bytes memory source, uint256 _a ) internal pure returns (bytes memory) {
             bytes memory _xbyte;
             uint256 k = 0;
             if( source.length == 0 ){
                  _xbyte = toBytesEth(_a);
                  return _xbyte;
             }
            _xbyte = toBytesEth(_a);
            bytes memory ext_source = new bytes( source.length + _xbyte.length );
            for (uint256 i = 0; i < source.length; i++) ext_source[k++] = source[i];
            for (uint256 j = 0; j < _xbyte.length; j++) ext_source[k++] = _xbyte[j];
            return ext_source;
    }

    function bytesConcat_address( bytes memory source, address _a ) internal pure returns (bytes memory) {
             bytes memory _xbyte;
             uint256 k = 0;
             if( source.length == 0 ){
                  _xbyte = addresstoBytes(_a);
                  return _xbyte;
             }
            _xbyte = addresstoBytes(_a);
            bytes memory ext_source = new bytes( source.length + _xbyte.length );
            for (uint256 i = 0; i < source.length; i++) ext_source[k++] = source[i];
            for (uint256 j = 0; j < _xbyte.length; j++) ext_source[k++] = _xbyte[j];
            return ext_source;
    }

    function claim_process( uint32 random_grade) internal {

        nonce = nonce + 1;
        uint256 id = 0;

        uint256 grade = random_grade;
        uint256 promote =  _randomPromote();
        uint256 artdAmount = 1000000000000000000;
        uint256 apwrAmount = 0;
        uint256 skill = 0;
        uint256 createdTime = now;
        address factory = address(this);
        address author = msg.sender;

        _data = new bytes(0);
        _data = bytesConcat_uint256( _data, _eraNFT );
        _data = bytesConcat_uint256( _data, grade );
        if( grade >= 3 )
        {
            artdAmount = 0;
        }
        _data = bytesConcat_uint256( _data, promote );
        _data = bytesConcat_uint256( _data, artdAmount );
        _data = bytesConcat_uint256( _data, apwrAmount );
        _data = bytesConcat_uint256( _data, skill );
        _data = bytesConcat_address( _data, factory );


        AnftToken _anftx =  AnftToken(_anft);
        id = _anftx.totalSupply();
        id = id + 1;
        _anftx.safeMint(msg.sender, id, _data);


        _era[id] = _eraNFT;
        _grade[id] = grade;
        _promote[id] = promote;
        _artdamount[id] = artdAmount;
        _apwramount[id] = apwrAmount;
        _skill[id] = skill;
        _factory[id] = factory;
        _author[id] = author;
        _createdTime[id] = createdTime;
        _lock[id] = 0;

        emit TokenParameter(id, _eraNFT, grade, promote, artdAmount, apwrAmount, skill, factory, author, createdTime );
        emit DataParameter(_data);
        if ( address(this).balance == 6 )
        {
            emit Grade6( msg.sender, block.timestamp, block.number);
        }
        else if ( address(this).balance == 5 )
        {
            emit Grade5( msg.sender, block.timestamp, block.number);
        }
        else if ( address(this).balance == 4 )
        {
            emit Grade4( msg.sender, block.timestamp, block.number);
        }
        else if ( address(this).balance == 3 )
        {
            emit Grade3( msg.sender, block.timestamp, block.number);
        }
        else if ( address(this).balance == 2 )
        {
            emit Grade2( msg.sender, block.timestamp, block.number);
        }
        else if ( address(this).balance == 1 )
        {
            emit Grade1( msg.sender, block.timestamp, block.number);
        }


        ApwrToken _apwrx = ApwrToken(_apwr);
        _apwrx.mint (msg.sender, pwrdist );

        if( artdAmount > 0 )
        {
            ArtdToken _artdx =  ArtdToken(_artd);
            _artdx.mint( address(_fundpool) , artdAmount );
        }


        hasClaimed[msg.sender] = true;
    }

    function claim() public hasNotClaimed canClaim {
        uint32 random  = _randomGrade(0);
        claim_process( random );
    }


    function claimbynum( uint number ) public hasNotClaimed canClaim {
        uint32 random  = _randomGrade(number);
        claim_process( random );
    }

    function claimbyrelay() public
    {
        require( msg.sender == _relay, "Invalid caller");
        uint32 random  = _randomGradeX();
        claim_process( random );
    }

    function calcSendamount(uint256 value) internal view returns (uint256)
    {
        uint256 sendAmount = value;
        uint256 burnFee = (value.mul(_burnRate)).div(_rateBase);
        if (burnFee > 0) {
           sendAmount = sendAmount.sub(burnFee);
        }
        uint256 rewardFee = (value.mul(_rewardRate)).div(_rateBase);
        if (rewardFee > 0) {
           sendAmount = sendAmount.sub(rewardFee);
        }
        return sendAmount;
    }


    function setRelay( address relay ) external onlyOwner
    {
        _relay = relay;
    }

}
