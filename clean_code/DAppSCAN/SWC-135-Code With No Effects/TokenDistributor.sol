
pragma solidity 0.6.12;

import "OpenZeppelin/openzeppelin-contracts@3.2.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@3.2.0/contracts/cryptography/ECDSA.sol";
import "OpenZeppelin/openzeppelin-contracts@3.2.0/contracts/cryptography/MerkleProof.sol";










interface GTCErc20 {
    function delegateOnDist(address, address) external;
}

contract TokenDistributor{

    address immutable public signer;
    address immutable public token;
    uint immutable public deployTime;
    address immutable public timeLockContract;
    bytes32 immutable public merkleRoot;


    bytes32 DOMAIN_SEPARATOR;


    mapping(uint256 => uint256) private claimedBitMap;


    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }


    struct Claim {
        uint32 user_id;
        address user_address;
        uint256 user_amount;
        address delegate_address;
        bytes32 leaf;
    }


    uint public constant CONTRACT_ACTIVE = 24 weeks;


    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );


    bytes32 constant GTC_TOKEN_CLAIM_TYPEHASH = keccak256(
        "Claim(uint32 user_id,address user_address,uint256 user_amount,address delegate_address,bytes32 leaf)"
    );


    event Claimed(uint256 user_id, address account, uint256 amount, bytes32 leaf);


    event TransferUnclaimed(uint256 amount);







    constructor(address _token, address _signer, address _timeLock, bytes32 _merkleRoot) public {
        signer = _signer;
        token = _token;
        merkleRoot = _merkleRoot;
        timeLockContract = _timeLock;
        deployTime = block.timestamp;

        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "GTC",
            version: '1.0.0',
            chainId: 1,
            verifyingContract: address(this)
        }));

    }













    function claimTokens(
        uint32 user_id,
        address user_address,
        uint256 user_amount,
        address delegate_address,
        bytes32 eth_signed_message_hash_hex,
        bytes memory eth_signed_signature_hex,
        bytes32[] calldata merkleProof,
        bytes32 leaf

        ) external {


        require(msg.sender == user_address, 'TokenDistributor: Must be msg sender.');


        require(!isClaimed(user_id), 'TokenDistributor: Tokens already claimed.');


        require(isSigned(eth_signed_message_hash_hex, eth_signed_signature_hex), 'TokenDistributor: Valid Signature Required.');


        require(hashMatch(user_id, user_address, user_amount, delegate_address, leaf, eth_signed_message_hash_hex), 'TokenDistributor: Hash Mismatch.');


        require(_hashLeaf(user_id, user_amount, leaf), 'TokenDistributor: Leaf Hash Mismatch.');


        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), 'TokenDistributor: Valid Proof Required.');


        _delegateTokens(user_address, delegate_address);
        _setClaimed(user_id);

        require(IERC20(token).transfer(user_address, user_amount), 'TokenDistributor: Transfer failed.');
        emit Claimed(user_id, user_address, user_amount, leaf);
    }






    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }




    function transferUnclaimed() public {
        require(block.timestamp >= deployTime + CONTRACT_ACTIVE, 'TokenDistributor: Contract is still active.');

        uint remainingBalance = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transfer(timeLockContract, remainingBalance), 'TokenDistributor: Transfer unclaimed failed.');
        emit TransferUnclaimed(remainingBalance);
    }





    function isSigned(bytes32 eth_signed_message_hash_hex, bytes memory eth_signed_signature_hex) internal view returns (bool) {
        address untrusted_signer = ECDSA.recover(eth_signed_message_hash_hex, eth_signed_signature_hex);
        return untrusted_signer == signer;
    }





    function getDigest(Claim memory claim) internal view returns (bytes32) {

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            hashClaim(claim)
        ));
        return digest;
    }





    function hashMatch(
        uint32 _user_id,
        address _user_address,
        uint256 _user_amount,
        address _delegate_address,
        bytes32 _leaf,
        bytes32 eth_signed_message_hash_hex
        ) internal returns ( bool ) {


        Claim memory claim = Claim({
            user_id: _user_id,
            user_address: _user_address,
            user_amount: _user_amount,
            delegate_address: _delegate_address,
            leaf: _leaf
        });

        return getDigest(claim) == eth_signed_message_hash_hex;
    }





    function hashClaim(Claim memory claim) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            GTC_TOKEN_CLAIM_TYPEHASH,
            claim.user_id,
            claim.user_address,
            claim.user_amount,
            claim.delegate_address,
            claim.leaf
        ));
    }





    function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }





    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }





    function _hashLeaf(uint32 user_id, uint256 user_amount, bytes32 leaf) private returns (bool) {

        bytes32 leaf_hash = keccak256(abi.encodePacked(keccak256(abi.encodePacked(user_id, user_amount))));
        return leaf == leaf_hash;
    }





    function _delegateTokens(address delegator, address delegatee) private returns (bool) {
         GTCErc20  GTCToken = GTCErc20(token);
         GTCToken.delegateOnDist(delegator, delegatee);
         return true;
    }



}
