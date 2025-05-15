




pragma solidity ^0.6.12;




interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}







library ECDSA {














    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {

        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }


        bytes32 r;
        bytes32 s;
        uint8 v;




        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }










        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }


        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }









    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {


        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

interface IERC1155 {













    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);









    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);




    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);






    event URI(string _amount, uint256 indexed _id);




















    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

















    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;







    function balanceOf(address _owner, uint256 _id) external view returns (uint256);







    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);







    function setApprovalForAll(address _operator, bool _approved) external;







    function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

contract ERNEDistribution {


    address private signer;

    using ECDSA for address;

    uint256 public count = 0;

    address public NFT;

    uint256 public tokenId;

    uint256 public strTime;

    address public owner;

    address public erc1155Holder;


    mapping(bytes32 => bool)public msgHash;


    mapping(address => bool) public claimStatus;


    constructor (address _signer, address _nft, uint256 _tokenid, address _erc1155Holder) public{

        signer = _signer;
        NFT = _nft;
        tokenId = _tokenid;
        strTime = now;
        owner = msg.sender;
        erc1155Holder = _erc1155Holder;
    }











    function claim(address tokenAddr, uint amount, uint deadline, bytes calldata signature)
        public
    {

        require(!claimStatus[tx.origin], "Erne::claim: Duplicate call");


        require((now <= (strTime + 20 days)) && count < 150000 , "Erne::claim: time expired/Count exceeds");


        bytes32 messageHash = message(tx.origin, amount, deadline);
        require(!msgHash[messageHash], "Erne::claim: signature duplicate");


        address src = verifySignature(messageHash, signature);
        require(signer == src, "Erne::claim: unauthorized");


        msgHash[messageHash] = true;


        claimStatus[tx.origin] = true;


        if(count < 10000) {
           IERC1155(NFT).safeTransferFrom(erc1155Holder, msg.sender, tokenId, 1, "0x0");
        }
        count = count + 1;


        IERC20(tokenAddr).transfer(msg.sender,amount);
    }





    function verifySignature(bytes32 _messageHash, bytes memory _signature)
        public pure returns (address signatureAddress)
    {

        bytes32 hash = ECDSA.toEthSignedMessageHash(_messageHash);
        signatureAddress = ECDSA.recover(hash, _signature);
    }




    function message(address  _receiver , uint256 _amount , uint256 _blockExpirytime)
        public view returns(bytes32 messageHash)
    {
        messageHash = keccak256(abi.encodePacked(address(this), _receiver, _amount, _blockExpirytime));
    }





    function claimPendingToken(address tokenAddr)
        public
    {

        require(tx.origin == owner, "Erne::only Owner");


        IERC20(tokenAddr).transfer(msg.sender, IERC20(tokenAddr).balanceOf(address(this)));

    }


}
