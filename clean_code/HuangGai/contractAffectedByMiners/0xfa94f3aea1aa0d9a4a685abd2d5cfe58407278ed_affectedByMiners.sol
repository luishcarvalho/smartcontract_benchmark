



pragma solidity ^0.5.16;





































contract IERC721Receiver {














    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }












    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }














    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }














    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}





library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }







    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }



















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


contract Governance {

    address public _governance;

    constructor() public {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }


}




interface NFTFactory{
   function claimbyrelay() external;
}

interface AnftToken {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface AToken {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) ;
  function transfer(address dst, uint rawAmount) external returns (bool);
  function balanceOf(address account) external view returns (uint);

}

interface ApwrToken {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

interface RandomSeed {
  function random_get9999( address sender, uint256 random ) external view returns (uint);
}

contract NftRelay is Governance{

    using SafeMath for uint256;
    using Address for address;

    address public _anft =  address(0x99a7e1188CE9a0b7514d084878DFb8A405D8529F);
    address public _apwr = address(0xb60F072494c7f1b5a8ba46bc735C71A83D940D1A);
    address public _nftfactory = address(0x694D7054bc8993Ac15F9E42be364dccCBD576724);
    address private _randseed = address(0x75A7c0f3c7E59D0Aa323cc8832EaF2729Fe2127C);


    address public _token =  address(0x77dF79539083DCd4a8898dbA296d899aFef20067);
    address public _teamWallet = address(0x3b2b4f84cFE480289df651bE153c147fa417Fb8A);
    address public _nextRelayPool = address(0);
    address public _burnPool = 0x6666666666666666666666666666666666666666;

    uint256 private releaseDate;
    uint256 public _claimrate = 0;

    uint256 public _claimdays = 0 days;
    uint  private nonce = 0;

    uint256[] private _allNft;


    mapping(uint256 => uint256) private _allNftIndex;


    mapping (address => bool) public hasClaimed;


    modifier hasNotClaimed() {
        require(hasClaimed[msg.sender] == false);
        _;
    }


    modifier canClaim() {
        require(releaseDate + _claimdays >= now);
        _;
    }

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);
    event TransferNFT(address to, uint count);

    constructor() public {

        releaseDate = now;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4)
    {
        _addNft( tokenId );
        emit NFTReceived(operator, from, tokenId, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function setNftFactory( address newfactory ) external onlyGovernance {
        _nftfactory = newfactory;
    }

    function setnextRelayPool( address newrelaypool ) external onlyGovernance {
        _nextRelayPool = newrelaypool;
    }

    function setclaimDays( uint256 claimdays ) external onlyGovernance {
        _claimdays = claimdays;
    }

    function setuseToken( address token ) external onlyGovernance {
        _token = token;
    }

    function setclaimRate( uint256 claimrate ) external onlyGovernance {
        _claimrate = claimrate;
    }

    function getclaimRate() public view returns (uint256) {
        return _claimrate;
    }

    function IsClaimed( address account ) public view returns (bool) {
        return hasClaimed[account];
    }

    function mintNft( ) external
    {
            NFTFactory _nftfactoryx =  NFTFactory(_nftfactory);
            _nftfactoryx.claimbyrelay( );
    }

    function claimNFTbytokens(  uint256 amount ) external hasNotClaimed()  canClaim()
    {

        require( amount >= _claimrate, "ARTTamount not enough");

        if( block.number > 0 )
        {
            AToken _tokenx =  AToken(_token);
            _tokenx.transferFrom(msg.sender, address(this), amount );
        }

        RandomSeed _rc = RandomSeed(_randseed);
        uint randnum = _rc.random_get9999(msg.sender,nonce);
        nonce = nonce + 1;

        uint256 total = _allNft.length;
        uint256 md = SafeMath.mod( randnum, total );
        uint id = nftByIndex(md);

        _removeNft( id );
        AnftToken _anftx =  AnftToken(_anft);
        _anftx.safeTransferFrom( address(this), msg.sender, id );

        ApwrToken _apwrx = ApwrToken(_apwr);
        _apwrx.transfer( msg.sender, 1* 1e16 );


        hasClaimed[msg.sender] = true;
    }


    function claim() external hasNotClaimed()  canClaim()
    {
            require( _claimrate == 0, "No Free, to pay Atoken is needed");

            RandomSeed _rc = RandomSeed(_randseed);
            uint randnum = _rc.random_get9999(msg.sender,nonce);
            nonce = nonce + 1;

            uint256 total = _allNft.length;
            uint256 md = SafeMath.mod( randnum, total );
            uint id = nftByIndex(md);

            _removeNft( id );
            AnftToken _anftx =  AnftToken(_anft);
            _anftx.safeTransferFrom( address(this), msg.sender, id );

            ApwrToken _apwrx = ApwrToken(_apwr);
            _apwrx.transfer( msg.sender, 1* 1e16 );


            hasClaimed[msg.sender] = true;
    }








    function _removeNft(uint256 nftId) private {

        uint256 lastNftIndex = _allNft.length.sub(1);
        uint256 NftIndex = _allNftIndex[nftId];

        uint256 lastNftId = _allNft[lastNftIndex];

        _allNft[NftIndex] = lastNftId;
        _allNftIndex[lastNftId] = NftIndex;

        _allNft.length--;
        _allNftIndex[nftId] = 0;
    }





    function _addNft(uint256 tokenId) private {
        _allNftIndex[tokenId] = _allNft.length;
        _allNft.push(tokenId);
    }





    function totalNFTs() public view returns (uint256) {
        return _allNft.length;
    }





    function totalAPWR() public view returns (uint256) {
        ApwrToken _apwrx = ApwrToken(_apwr);
        return _apwrx.balanceOf(address(this));
    }







    function nftByIndex(uint256 index) public view returns (uint256) {
        require(index < totalNFTs(), "ERC721: global index out of bounds");
        return _allNft[index];
    }

    function MigrateNFT() external onlyGovernance
    {
         uint count =  _allNft.length;
         uint id = 0;
         if( block.timestamp >= 1 )
         {
            AnftToken _anftx =  AnftToken(_anft);
            id = _allNft[0];
            _removeNft( id );
            _anftx.safeTransferFrom( address(this), _nextRelayPool, id );

            ApwrToken _apwrx = ApwrToken(_apwr);
            _apwrx.transfer( _nextRelayPool, 1* 1e16 );
         }

         emit TransferNFT( _nextRelayPool, count );
    }


    function seizeAtoken() external
    {
        AToken _tokenx =  AToken(_token);
        uint _currentBalance =  _tokenx.balanceOf(address(this));
        _tokenx.transfer(_teamWallet, _currentBalance );
    }


}
