















pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

import "@airswap/swap/contracts/interfaces/ISwap.sol";
import "@airswap/tokens/contracts/interfaces/INRERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";




contract Swap is ISwap {
  using SafeMath for uint256;


  bytes constant internal DOMAIN_NAME = "SWAP";
  bytes constant internal DOMAIN_VERSION = "2";


  bytes32 private _domainSeparator;


  byte constant internal AVAILABLE = 0x00;
  byte constant internal UNAVAILABLE = 0x01;


  bytes4 constant internal ERC721_INTERFACE_ID = 0x80ac58cd;


  mapping (address => mapping (address => bool)) public senderAuthorizations;


  mapping (address => mapping (address => bool)) public signerAuthorizations;


  mapping (address => mapping (uint256 => byte)) public signerNonceStatus;


  mapping (address => uint256) public signerMinimumNonce;





  constructor() public {
    _domainSeparator = Types.hashDomain(
      DOMAIN_NAME,
      DOMAIN_VERSION,
      address(this)
    );
  }





  function swap(
    Types.Order calldata order
  ) external {

    require(order.expiry > block.timestamp,
      "ORDER_EXPIRED");


    require(signerNonceStatus[order.signer.wallet][order.nonce] == AVAILABLE,
      "ORDER_TAKEN_OR_CANCELLED");


    require(order.nonce >= signerMinimumNonce[order.signer.wallet],
      "NONCE_TOO_LOW");


    signerNonceStatus[order.signer.wallet][order.nonce] = UNAVAILABLE;


    address finalSenderWallet;

    if (order.sender.wallet == address(0)) {




      finalSenderWallet = msg.sender;

    } else {




      require(isSenderAuthorized(order.sender.wallet, msg.sender),
          "SENDER_UNAUTHORIZED");

      finalSenderWallet = order.sender.wallet;

    }


    if (order.signature.v == 0) {




      require(isSignerAuthorized(order.signer.wallet, msg.sender),
        "SIGNER_UNAUTHORIZED");

    } else {




      require(isSignerAuthorized(order.signer.wallet, order.signature.signatory),
        "SIGNER_UNAUTHORIZED");


      require(isValid(order, _domainSeparator),
        "SIGNATURE_INVALID");

    }

    transferToken(
      finalSenderWallet,
      order.signer.wallet,
      order.sender.param,
      order.sender.token,
      order.sender.kind
    );


    transferToken(
      order.signer.wallet,
      finalSenderWallet,
      order.signer.param,
      order.signer.token,
      order.signer.kind
    );


    if (order.affiliate.wallet != address(0)) {
      transferToken(
        order.signer.wallet,
        order.affiliate.wallet,
        order.affiliate.param,
        order.affiliate.token,
        order.affiliate.kind
      );
    }

    emit Swap(order.nonce, block.timestamp,
      order.signer.wallet, order.signer.param, order.signer.token,
      finalSenderWallet, order.sender.param, order.sender.token,
      order.affiliate.wallet, order.affiliate.param, order.affiliate.token
    );
  }








  function cancel(
    uint256[] calldata nonces
  ) external {
    for (uint256 i = 0; i < nonces.length; i++) {
      if (signerNonceStatus[msg.sender][nonces[i]] == AVAILABLE) {
        signerNonceStatus[msg.sender][nonces[i]] = UNAVAILABLE;
        emit Cancel(nonces[i], msg.sender);
      }
    }
  }






  function invalidate(
    uint256 minimumNonce
  ) external {
    signerMinimumNonce[msg.sender] = minimumNonce;
    emit Invalidate(minimumNonce, msg.sender);
  }






  function authorizeSender(
    address authorizedSender
  ) external {
    require(msg.sender != authorizedSender, "INVALID_AUTH_SENDER");
    senderAuthorizations[msg.sender][authorizedSender] = true;
    emit AuthorizeSender(msg.sender, authorizedSender);
  }






  function authorizeSigner(
    address authorizedSigner
  ) external {
    require(msg.sender != authorizedSigner, "INVALID_AUTH_SIGNER");
    signerAuthorizations[msg.sender][authorizedSigner] = true;
    emit AuthorizeSigner(msg.sender, authorizedSigner);
  }






  function revokeSender(
    address authorizedSender
  ) external {
    delete senderAuthorizations[msg.sender][authorizedSender];
    emit RevokeSender(msg.sender, authorizedSender);
  }






  function revokeSigner(
    address authorizedSigner
  ) external {
    delete signerAuthorizations[msg.sender][authorizedSigner];
    emit RevokeSigner(msg.sender, authorizedSigner);
  }







  function isSenderAuthorized(
    address authorizer,
    address delegate
  ) internal view returns (bool) {
    return ((authorizer == delegate) ||
      senderAuthorizations[authorizer][delegate]);
  }







  function isSignerAuthorized(
    address authorizer,
    address delegate
  ) internal view returns (bool) {
    return ((authorizer == delegate) ||
      signerAuthorizations[authorizer][delegate]);
  }







  function isValid(
    Types.Order memory order,
    bytes32 domainSeparator
  ) internal pure returns (bool) {
    if (order.signature.version == byte(0x01)) {
      return order.signature.signatory == ecrecover(
        Types.hashOrder(
          order,
          domainSeparator
        ),
        order.signature.v,
        order.signature.r,
        order.signature.s
      );
    }
    if (order.signature.version == byte(0x45)) {
      return order.signature.signatory == ecrecover(
        keccak256(
          abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            Types.hashOrder(order, domainSeparator)
          )
        ),
        order.signature.v,
        order.signature.r,
        order.signature.s
      );
    }
    return false;
  }












  function transferToken(
      address from,
      address to,
      uint256 param,
      address token,
      bytes4 kind
  ) internal {


    require(from != to, "INVALID_SELF_TRANSFER");

    if (kind == ERC721_INTERFACE_ID) {


      IERC721(token).transferFrom(from, to, param);

    } else {
      uint256 initialBalance = INRERC20(token).balanceOf(from);


      INRERC20(token).transferFrom(from, to, param);


      require(initialBalance.sub(param) == INRERC20(token).balanceOf(from), "TRANSFER_FAILED");
    }
  }
}
