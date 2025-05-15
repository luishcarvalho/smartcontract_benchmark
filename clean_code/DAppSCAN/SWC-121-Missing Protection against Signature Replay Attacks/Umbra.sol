

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IUmbraHookReceiver.sol";

contract Umbra is Ownable {



  event Announcement(
    address indexed receiver,
    uint256 amount,
    address indexed token,
    bytes32 pkx,
    bytes32 ciphertext
  );


  event TokenWithdrawal(
    address indexed receiver,
    address indexed acceptor,
    uint256 amount,
    address indexed token
  );




  string public constant version = "1";


  uint256 public immutable chainId;


  address constant ETH_TOKEN_PLACHOLDER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;


  uint256 public toll;


  address public tollCollector;


  address payable public tollReceiver;


  mapping(address => mapping(address => uint256)) public tokenPayments;








  constructor(
    uint256 _toll,
    address _tollCollector,
    address payable _tollReceiver
  ) {
    toll = _toll;
    tollCollector = _tollCollector;
    tollReceiver = _tollReceiver;

    uint256 _chainId;

    assembly {
      _chainId := chainid()
    }

    chainId = _chainId;
  }





  function setToll(uint256 _newToll) external onlyOwner {
    toll = _newToll;
  }





  function setTollCollector(address _newTollCollector) external onlyOwner {
    tollCollector = _newTollCollector;
  }





  function setTollReceiver(address payable _newTollReceiver) external onlyOwner {
    tollReceiver = _newTollReceiver;
  }




  function collectTolls() external {
    require(msg.sender == tollCollector, "Umbra: Not toll collector");
    tollReceiver.transfer(address(this).balance);
  }












  function sendEth(
    address payable _receiver,
    uint256 _tollCommitment,
    bytes32 _pkx,
    bytes32 _ciphertext
  ) external payable {
    require(_tollCommitment == toll, "Umbra: Invalid or outdated toll commitment");


    require(msg.value > toll, "Umbra: Must pay more than the toll");

    uint256 amount = msg.value - toll;
    emit Announcement(_receiver, amount, ETH_TOKEN_PLACHOLDER, _pkx, _ciphertext);

    _receiver.transfer(amount);
  }









  function sendToken(
    address _receiver,
    address _tokenAddr,
    uint256 _amount,
    bytes32 _pkx,
    bytes32 _ciphertext
  ) external payable {
    require(msg.value == toll, "Umbra: Must pay the exact toll");
    require(tokenPayments[_receiver][_tokenAddr] == 0, "Umbra: Cannot send more tokens to stealth address");

    tokenPayments[_receiver][_tokenAddr] = _amount;
    emit Announcement(_receiver, _amount, _tokenAddr, _pkx, _ciphertext);

    SafeERC20.safeTransferFrom(IERC20(_tokenAddr), msg.sender, address(this), _amount);
  }









  function withdrawToken(address _acceptor, address _tokenAddr) external {
    _withdrawTokenInternal(msg.sender, _acceptor, _tokenAddr, address(0), 0, IUmbraHookReceiver(0), "");
  }









  function withdrawTokenAndCall(
    address _acceptor,
    address _tokenAddr,
    IUmbraHookReceiver _hook,
    bytes memory _data
  ) external {
    _withdrawTokenInternal(msg.sender, _acceptor, _tokenAddr, address(0), 0, _hook, _data);
  }












  function withdrawTokenOnBehalf(
    address _stealthAddr,
    address _acceptor,
    address _tokenAddr,
    address _sponsor,
    uint256 _sponsorFee,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    _validateWithdrawSignature(
      _stealthAddr,
      _acceptor,
      _tokenAddr,
      _sponsor,
      _sponsorFee,
      IUmbraHookReceiver(0),
      "",
      _v,
      _r,
      _s
    );
    _withdrawTokenInternal(_stealthAddr, _acceptor, _tokenAddr, _sponsor, _sponsorFee, IUmbraHookReceiver(0), "");
  }














  function withdrawTokenAndCallOnBehalf(
    address _stealthAddr,
    address _acceptor,
    address _tokenAddr,
    address _sponsor,
    uint256 _sponsorFee,
    IUmbraHookReceiver _hook,
    bytes memory _data,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external {
    _validateWithdrawSignature(_stealthAddr, _acceptor, _tokenAddr, _sponsor, _sponsorFee, _hook, _data, _v, _r, _s);
    _withdrawTokenInternal(_stealthAddr, _acceptor, _tokenAddr, _sponsor, _sponsorFee, _hook, _data);
  }











  function _withdrawTokenInternal(
    address _stealthAddr,
    address _acceptor,
    address _tokenAddr,
    address _sponsor,
    uint256 _sponsorFee,
    IUmbraHookReceiver _hook,
    bytes memory _data
  ) internal {
    uint256 _amount = tokenPayments[_stealthAddr][_tokenAddr];


    require(_amount > _sponsorFee, "Umbra: No balance to withdraw or fee exceeds balance");

    uint256 _withdrawalAmount = _amount - _sponsorFee;
    delete tokenPayments[_stealthAddr][_tokenAddr];
    emit TokenWithdrawal(_stealthAddr, _acceptor, _withdrawalAmount, _tokenAddr);

    SafeERC20.safeTransfer(IERC20(_tokenAddr), _acceptor, _withdrawalAmount);

    if (_sponsorFee > 0) {
      SafeERC20.safeTransfer(IERC20(_tokenAddr), _sponsor, _sponsorFee);
    }

    if (address(_hook) != address(0)) {
      _hook.tokensWithdrawn(_withdrawalAmount, _stealthAddr, _acceptor, _tokenAddr, _sponsor, _sponsorFee, _data);
    }
  }















  function _validateWithdrawSignature(
    address _stealthAddr,
    address _acceptor,
    address _tokenAddr,
    address _sponsor,
    uint256 _sponsorFee,
    IUmbraHookReceiver _hook,
    bytes memory _data,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) internal view {
    bytes32 _digest =
      keccak256(
        abi.encodePacked(
          "\x19Ethereum Signed Message:\n32",
          keccak256(abi.encode(chainId, version, _acceptor, _tokenAddr, _sponsor, _sponsorFee, address(_hook), _data))
        )
      );

    address _recoveredAddress = ecrecover(_digest, _v, _r, _s);
    require(_recoveredAddress != address(0) && _recoveredAddress == _stealthAddr, "Umbra: Invalid Signature");
  }
}
