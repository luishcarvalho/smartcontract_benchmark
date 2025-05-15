
pragma solidity 0.8.11;




























library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";


    function encode(bytes memory data) internal pure returns (string memory) {
        uint len = data.length;
        if (len == 0) return "";


        uint encodedLen = 4 * ((len + 2) / 3);


        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}










interface IERC165 {








    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}




interface IERC721 is IERC165 {



    event Transfer(address indexed from, address indexed to, uint indexed tokenId);




    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);




    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);




    function balanceOf(address owner) external view returns (uint balance);








    function ownerOf(uint tokenId) external view returns (address owner);















    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;















    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external;














    function approve(address to, uint tokenId) external;








    function getApproved(uint tokenId) external view returns (address operator);











    function setApprovalForAll(address operator, bool _approved) external;






    function isApprovedForAll(address owner, address operator) external view returns (bool);














    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes calldata data
    ) external;
}






interface IERC721Receiver {









    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}





interface IERC721Metadata is IERC721 {



    function name() external view returns (string memory);




    function symbol() external view returns (string memory);




    function tokenURI(uint tokenId) external view returns (string memory);
}




interface IERC20 {







    function transfer(address recipient, uint amount) external returns (bool);










    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

struct Point {
    int128 bias;
    int128 slope;
    uint ts;
    uint blk;
}




struct LockedBalance {
    int128 amount;
    uint end;
}

contract ve is IERC721, IERC721Metadata {
    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME,
        MERGE_TYPE
    }

    event Deposit(
        address indexed provider,
        uint tokenId,
        uint value,
        uint indexed locktime,
        DepositType deposit_type,
        uint ts
    );
    event Withdraw(address indexed provider, uint tokenId, uint value, uint ts);
    event Supply(uint prevSupply, uint supply);

    uint internal constant WEEK = 1 weeks;
    uint internal constant MAXTIME = 4 * 365 * 86400;
    int128 internal constant iMAXTIME = 4 * 365 * 86400;
    uint internal constant MULTIPLIER = 1 ether;

    address immutable public token;
    uint public supply;
    mapping(uint => LockedBalance) public locked;

    mapping(uint => uint) public ownership_change;

    uint public epoch;
    mapping(uint => Point) public point_history;
    mapping(uint => Point[1000000000]) public user_point_history;

    mapping(uint => uint) public user_point_epoch;
    mapping(uint => int128) public slope_changes;

    mapping(uint => uint) public attachments;
    mapping(uint => bool) public voted;
    address public voter;

    string constant public name = "veMULTI NFT";
    string constant public symbol = "veMULTI";
    string constant public version = "1.0.0";
    uint8 constant public decimals = 18;


    uint internal tokenId;


    mapping(uint => address) internal idToOwner;


    mapping(uint => address) internal idToApprovals;


    mapping(address => uint) internal ownerToNFTokenCount;


    mapping(address => mapping(uint => uint)) internal ownerToNFTokenIdList;


    mapping(uint => uint) internal tokenToOwnerIndex;


    mapping(address => mapping(address => bool)) internal ownerToOperators;


    mapping(bytes4 => bool) internal supportedInterfaces;


    bytes4 internal constant ERC165_INTERFACE_ID = 0x01ffc9a7;


    bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;


    bytes4 internal constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;


    uint8 internal constant _not_entered = 1;
    uint8 internal constant _entered = 2;
    uint8 internal _entered_state = 1;
    modifier nonreentrant() {
        require(_entered_state == _not_entered);
        _entered_state = _entered;
        _;
        _entered_state = _not_entered;
    }



    constructor(
        address token_addr
    ) {
        token = token_addr;
        voter = msg.sender;
        point_history[0].blk = block.number;
        point_history[0].ts = block.timestamp;

        supportedInterfaces[ERC165_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = true;


        emit Transfer(address(0), address(this), tokenId);

        emit Transfer(address(this), address(0), tokenId);
    }



    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }




    function get_last_user_slope(uint _tokenId) external view returns (int128) {
        uint uepoch = user_point_epoch[_tokenId];
        return user_point_history[_tokenId][uepoch].slope;
    }





    function user_point_history__ts(uint _tokenId, uint _idx) external view returns (uint) {
        return user_point_history[_tokenId][_idx].ts;
    }




    function locked__end(uint _tokenId) external view returns (uint) {
        return locked[_tokenId].end;
    }




    function _balance(address _owner) internal view returns (uint) {
        return ownerToNFTokenCount[_owner];
    }




    function balanceOf(address _owner) external view returns (uint) {
        return _balance(_owner);
    }




    function ownerOf(uint _tokenId) public view returns (address) {
        return idToOwner[_tokenId];
    }



    function getApproved(uint _tokenId) external view returns (address) {
        return idToApprovals[_tokenId];
    }




    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return (ownerToOperators[_owner])[_operator];
    }


    function tokenOfOwnerByIndex(address _owner, uint _tokenIndex) external view returns (uint) {
        return ownerToNFTokenIdList[_owner][_tokenIndex];
    }





    function _isApprovedOrOwner(address _spender, uint _tokenId) internal view returns (bool) {
        address owner = idToOwner[_tokenId];
        bool spenderIsOwner = owner == _spender;
        bool spenderIsApproved = _spender == idToApprovals[_tokenId];
        bool spenderIsApprovedForAll = (ownerToOperators[owner])[_spender];
        return spenderIsOwner || spenderIsApproved || spenderIsApprovedForAll;
    }

    function isApprovedOrOwner(address _spender, uint _tokenId) external view returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }




    function _addTokenToOwnerList(address _to, uint _tokenId) internal {
        uint current_count = _balance(_to);

        ownerToNFTokenIdList[_to][current_count] = _tokenId;
        tokenToOwnerIndex[_tokenId] = current_count;
    }




    function _removeTokenFromOwnerList(address _from, uint _tokenId) internal {

        uint current_count = _balance(_from)-1;
        uint current_index = tokenToOwnerIndex[_tokenId];

        if (current_count == current_index) {

            ownerToNFTokenIdList[_from][current_count] = 0;

            tokenToOwnerIndex[_tokenId] = 0;
        } else {
            uint lastTokenId = ownerToNFTokenIdList[_from][current_count];



            ownerToNFTokenIdList[_from][current_index] = lastTokenId;

            tokenToOwnerIndex[lastTokenId] = current_index;



            ownerToNFTokenIdList[_from][current_count] = 0;

            tokenToOwnerIndex[_tokenId] = 0;
        }
    }



    function _addTokenTo(address _to, uint _tokenId) internal {

        assert(idToOwner[_tokenId] == address(0));

        idToOwner[_tokenId] = _to;

        _addTokenToOwnerList(_to, _tokenId);

        ownerToNFTokenCount[_to] += 1;
    }



    function _removeTokenFrom(address _from, uint _tokenId) internal {

        assert(idToOwner[_tokenId] == _from);

        idToOwner[_tokenId] = address(0);

        _removeTokenFromOwnerList(_from, _tokenId);

        ownerToNFTokenCount[_from] -= 1;
    }



    function _clearApproval(address _owner, uint _tokenId) internal {

        assert(idToOwner[_tokenId] == _owner);
        if (idToApprovals[_tokenId] != address(0)) {

            idToApprovals[_tokenId] = address(0);
        }
    }







    function _transferFrom(
        address _from,
        address _to,
        uint _tokenId,
        address _sender
    ) internal {
        require(attachments[_tokenId] == 0 && !voted[_tokenId], "attached");

        require(_isApprovedOrOwner(_sender, _tokenId));

        _clearApproval(_from, _tokenId);

        _removeTokenFrom(_from, _tokenId);

        _addTokenTo(_to, _tokenId);

        ownership_change[_tokenId] = block.number;

        emit Transfer(_from, _to, _tokenId);
    }








































































































































































































































































































































































































































































































































































































































































































































