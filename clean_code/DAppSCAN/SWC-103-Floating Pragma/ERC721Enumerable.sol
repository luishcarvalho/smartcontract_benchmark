

pragma solidity ^0.8.0;

import './ERC721Time.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';








abstract contract ERC721Enumerable is ERC721Time, IERC721Enumerable {

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;


    mapping(uint256 => uint256) private _ownedTokensIndex;


    uint256[] private _allTokens;


    mapping(uint256 => uint256) private _allTokensIndex;




    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721Time)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }




    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(index < ERC721Time.balanceOf(owner), 'ERC721Enumerable: owner index out of bounds');
        return _ownedTokens[owner][index];
    }




    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }




    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(
            index < ERC721Enumerable.totalSupply(),
            'ERC721Enumerable: global index out of bounds'
        );
        return _allTokens[index];
    }
















    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }






    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Time.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }





    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }









    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {



        uint256 lastTokenIndex = ERC721Time.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];


        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }


        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }






    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {



        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];




        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;


        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}
