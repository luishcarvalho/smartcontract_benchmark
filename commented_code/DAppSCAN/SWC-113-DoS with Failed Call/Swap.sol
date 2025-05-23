/*
  Copyright 2019 Swap Holdings Ltd.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

import "@airswap/swap/contracts/interfaces/ISwap.sol";
import "@airswap/tokens/contracts/interfaces/INRERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
  * @title Swap: The Atomic Swap used by the Swap Protocol
  */
contract Swap is ISwap {
  using SafeMath for uint256;

  // Domain and version for use in signatures (EIP-712)
  bytes constant internal DOMAIN_NAME = "SWAP";
  bytes constant internal DOMAIN_VERSION = "2";

  // Unique domain identifier for use in signatures (EIP-712)
  bytes32 private _domainSeparator;

  // Possible nonce statuses
  byte constant internal AVAILABLE = 0x00;
  byte constant internal UNAVAILABLE = 0x01;

  // ERC-721 (non-fungible token) interface identifier (EIP-165)
  bytes4 constant internal ERC721_INTERFACE_ID = 0x80ac58cd;

  // Mapping of sender address to a delegated sender address and bool
  mapping (address => mapping (address => bool)) public senderAuthorizations;

  // Mapping of signer address to a delegated signer and bool
  mapping (address => mapping (address => bool)) public signerAuthorizations;

  // Mapping of signers to nonces with value AVAILABLE (0x00) or UNAVAILABLE (0x01)
  mapping (address => mapping (uint256 => byte)) public signerNonceStatus;

  // Mapping of signer addresses to an optionally set minimum valid nonce
  mapping (address => uint256) public signerMinimumNonce;

  /**
    * @notice Contract Constructor
    * @dev Sets domain for signature validation (EIP-712)
    */
  constructor() public {
    _domainSeparator = Types.hashDomain(
      DOMAIN_NAME,
      DOMAIN_VERSION,
      address(this)
    );
  }

  /**
    * @notice Atomic Token Swap
    * @param order Types.Order Order to settle
    */
  function swap(
    Types.Order calldata order
  ) external {
    // Ensure the order is not expired.
    require(order.expiry > block.timestamp,
      "ORDER_EXPIRED");

    // Ensure the nonce is AVAILABLE (0x00).
    require(signerNonceStatus[order.signer.wallet][order.nonce] == AVAILABLE,
      "ORDER_TAKEN_OR_CANCELLED");

    // Ensure the order nonce is above the minimum.
    require(order.nonce >= signerMinimumNonce[order.signer.wallet],
      "NONCE_TOO_LOW");

    // Mark the nonce UNAVAILABLE (0x01).
    signerNonceStatus[order.signer.wallet][order.nonce] = UNAVAILABLE;

    // Validate the sender side of the trade.
    address finalSenderWallet;

    if (order.sender.wallet == address(0)) {
      /**
        * Sender is not specified. The msg.sender of the transaction becomes
        * the sender of the order.
        */
      finalSenderWallet = msg.sender;

    } else {
      /**
        * Sender is specified. If the msg.sender is not the specified sender,
        * this determines whether the msg.sender is an authorized sender.
        */
      require(isSenderAuthorized(order.sender.wallet, msg.sender),
          "SENDER_UNAUTHORIZED");
      // The msg.sender is authorized.
      finalSenderWallet = order.sender.wallet;

    }

    // Validate the signer side of the trade.
    if (order.signature.v == 0) {
      /**
        * Signature is not provided. The signer may have authorized the
        * msg.sender to swap on its behalf, which does not require a signature.
        */
      require(isSignerAuthorized(order.signer.wallet, msg.sender),
        "SIGNER_UNAUTHORIZED");

    } else {
      /**
        * The signature is provided. Determine whether the signer is
        * authorized and if so validate the signature itself.
        */
      require(isSignerAuthorized(order.signer.wallet, order.signature.signatory),
        "SIGNER_UNAUTHORIZED");

      // Ensure the signature is valid.
      require(isValid(order, _domainSeparator),
        "SIGNATURE_INVALID");

    }
    // Transfer token from sender to signer.
    transferToken(
      finalSenderWallet,
      order.signer.wallet,
      order.sender.param,
      order.sender.token,
      order.sender.kind
    );

    // Transfer token from signer to sender.
    transferToken(
      order.signer.wallet,
      finalSenderWallet,
      order.signer.param,
      order.signer.token,
      order.signer.kind
    );

    // Transfer token from signer to affiliate if specified.
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

  /**
    * @notice Cancel one or more open orders by nonce
    * @dev Cancelled nonces are marked UNAVAILABLE (0x01)
    * @dev Emits a Cancel event
    * @param nonces uint256[] List of nonces to cancel
    */
    // SWC-113-DoS with Failed Call: L178 - L187
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

  /**
    * @notice Invalidate all orders below a nonce value
    * @dev Emits an Invalidate event
    * @param minimumNonce uint256 Minimum valid nonce
    */
  function invalidate(
    uint256 minimumNonce
  ) external {
    signerMinimumNonce[msg.sender] = minimumNonce;
    emit Invalidate(minimumNonce, msg.sender);
  }

  /**
    * @notice Authorize a delegated sender
    * @dev Emits an AuthorizeSender event
    * @param authorizedSender address Address to authorize
    */
  function authorizeSender(
    address authorizedSender
  ) external {
    require(msg.sender != authorizedSender, "INVALID_AUTH_SENDER");
    senderAuthorizations[msg.sender][authorizedSender] = true;
    emit AuthorizeSender(msg.sender, authorizedSender);
  }

  /**
    * @notice Authorize a delegated signer
    * @dev Emits an AuthorizeSigner event
    * @param authorizedSigner address Address to authorize
    */
  function authorizeSigner(
    address authorizedSigner
  ) external {
    require(msg.sender != authorizedSigner, "INVALID_AUTH_SIGNER");
    signerAuthorizations[msg.sender][authorizedSigner] = true;
    emit AuthorizeSigner(msg.sender, authorizedSigner);
  }

  /**
    * @notice Revoke an authorized sender
    * @dev Emits a RevokeSender event
    * @param authorizedSender address Address to revoke
    */
  function revokeSender(
    address authorizedSender
  ) external {
    delete senderAuthorizations[msg.sender][authorizedSender];
    emit RevokeSender(msg.sender, authorizedSender);
  }

  /**
    * @notice Revoke an authorized signer
    * @dev Emits a RevokeSigner event
    * @param authorizedSigner address Address to revoke
    */
  function revokeSigner(
    address authorizedSigner
  ) external {
    delete signerAuthorizations[msg.sender][authorizedSigner];
    emit RevokeSigner(msg.sender, authorizedSigner);
  }

  /**
    * @notice Determine whether a sender delegate is authorized
    * @param authorizer address Address doing the authorization
    * @param delegate address Address being authorized
    * @return bool True if a delegate is authorized to send
    */
  function isSenderAuthorized(
    address authorizer,
    address delegate
  ) internal view returns (bool) {
    return ((authorizer == delegate) ||
      senderAuthorizations[authorizer][delegate]);
  }

  /**
    * @notice Determine whether a signer delegate is authorized
    * @param authorizer address Address doing the authorization
    * @param delegate address Address being authorized
    * @return bool True if a delegate is authorized to sign
    */
  function isSignerAuthorized(
    address authorizer,
    address delegate
  ) internal view returns (bool) {
    return ((authorizer == delegate) ||
      signerAuthorizations[authorizer][delegate]);
  }

  /**
    * @notice Validate signature using an EIP-712 typed data hash
    * @param order Types.Order Order to validate
    * @param domainSeparator bytes32 Domain identifier used in signatures (EIP-712)
    * @return bool True if order has a valid signature
    */
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

  /**
    * @notice Perform an ERC-20 or ERC-721 token transfer
    * @dev Transfer type specified by the bytes4 kind param
    * @dev ERC721: uses transferFrom for transfer
    * @dev ERC20: Takes into account non-standard ERC-20 tokens.
    * @param from address Wallet address to transfer from
    * @param to address Wallet address to transfer to
    * @param param uint256 Amount for ERC-20 or token ID for ERC-721
    * @param token address Contract address of token
    * @param kind bytes4 EIP-165 interface ID of the token
    */
  function transferToken(
      address from,
      address to,
      uint256 param,
      address token,
      bytes4 kind
  ) internal {

    // Ensure the transfer is not to self.
    require(from != to, "INVALID_SELF_TRANSFER");

    if (kind == ERC721_INTERFACE_ID) {

      // Attempt to transfer an ERC-721 token.
      IERC721(token).transferFrom(from, to, param);

    } else {
      uint256 initialBalance = INRERC20(token).balanceOf(from);

      // Attempt to transfer an ERC-20 token.
      INRERC20(token).transferFrom(from, to, param);

      // Ensure the amount has been transferred.
      require(initialBalance.sub(param) == INRERC20(token).balanceOf(from), "TRANSFER_FAILED");
    }
  }
}