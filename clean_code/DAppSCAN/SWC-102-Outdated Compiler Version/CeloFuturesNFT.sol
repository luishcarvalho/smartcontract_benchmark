
pragma solidity 0.8.7;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';









contract CeloHedgeys is ERC721Enumerable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string private baseURI;
  uint8 private uriSet = 0;



  struct Future {
    uint256 amount;
    address token;
    uint256 unlockDate;
  }


  mapping(uint256 => Future) public futures;

  constructor(string memory uri) ERC721('Hedgeys', 'HDGY') {
    baseURI = uri;
  }












  function createNFT(
    address _holder,
    uint256 _amount,
    address _token,
    uint256 _unlockDate
  ) external returns (uint256) {
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();

    _safeMint(_holder, newItemId);

    require(_amount > 0 && _token != address(0) && _unlockDate > block.timestamp, 'HEC01: NFT Minting Error');

    uint256 currentBalance = IERC20(_token).balanceOf(address(this));

    require(IERC20(_token).balanceOf(address(msg.sender)) >= _amount, 'HNEC02: Insufficient Balance');
    SafeERC20.safeTransferFrom(IERC20(_token), msg.sender, address(this), _amount);
    uint256 postBalance = IERC20(_token).balanceOf(address(this));
    require(postBalance - currentBalance == _amount, 'HNEC03: Wrong amount');

    futures[newItemId] = Future(_amount, _token, _unlockDate);
    emit NFTCreated(newItemId, _holder, _amount, _token, _unlockDate);
    return newItemId;
  }


  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }




  function updateBaseURI(string memory _uri) external {
    require(uriSet == 0, 'HNEC06: uri already set');
    baseURI = _uri;
    uriSet = 1;
  }



  function redeemNFT(uint256 _id) external nonReentrant returns (bool) {
    _redeemNFT(msg.sender, _id);
    return true;
  }









  function _redeemNFT(address _holder, uint256 _id) internal {
    require(ownerOf(_id) == _holder, 'HNEC04: Only the NFT Owner');
    Future storage future = futures[_id];
    require(future.unlockDate < block.timestamp && future.amount > 0, 'HNEC05: Tokens are still locked');

    emit NFTRedeemed(_id, _holder, future.amount, future.token, future.unlockDate);
    _burn(_id);
    SafeERC20.safeTransfer(IERC20(future.token), _holder, future.amount);
    delete futures[_id];
  }




  event NFTCreated(uint256 _i, address _holder, uint256 _amount, address _token, uint256 _unlockDate);
  event NFTRedeemed(uint256 _i, address _holder, uint256 _amount, address _token, uint256 _unlockDate);
}
