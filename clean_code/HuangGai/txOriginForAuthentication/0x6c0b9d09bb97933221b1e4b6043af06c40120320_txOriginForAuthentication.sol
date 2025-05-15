



pragma solidity >=0.6.0 <0.7.0;




interface ERC20Token {







    function transfer(address _to, uint256 _value) external returns (bool success);







    function approve(address _spender, uint256 _value) external returns (bool success);








    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);





    function balanceOf(address _owner) external view returns (uint256 balance);






    function allowance(address _owner, address _spender) external view returns (uint256 remaining);




    function totalSupply() external view returns (uint256 supply);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ReentrancyGuard {

    bool internal reentranceLock = false;




    modifier reentrancyGuard() {
        require(!reentranceLock, "Reentrant call detected!");
        reentranceLock = true;
        _;
        reentranceLock = false;
    }
}
pragma experimental ABIEncoderV2;









interface StickerMarket {

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event MarketState(State state);
    event RegisterFee(uint256 value);
    event BurnRate(uint256 value);

    enum State { Invalid, Open, BuyOnly, Controlled, Closed }

    function state() external view returns(State);
    function snt() external view returns (address);
    function stickerPack() external view returns (address);
    function stickerType() external view returns (address);










    function buyToken(
        uint256 _packId,
        address _destination,
        uint256 _price
    )
        external
        returns (uint256 tokenId);












    function registerPack(
        uint256 _price,
        uint256 _donate,
        bytes4[] calldata _category,
        address _owner,
        bytes calldata _contenthash,
        uint256 _fee
    )
        external
        returns(uint256 packId);

}







interface ERC721
{







  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed value
  );






  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );





  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );














  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;









  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;











  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;








  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;








  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;







  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);







  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);







  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);







  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}







interface ERC721Enumerable
{






  function totalSupply()
    external
    view
    returns (uint256);






  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256);









  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256);

}






 abstract contract StickerType is ERC721, ERC721Enumerable {










    function generatePack(
        uint256 _price,
        uint256 _donate,
        bytes4[] calldata _category,
        address _owner,
        bytes calldata _contenthash
    )
        external
        virtual
        returns(uint256 packId);






    function purgePack(uint256 _packId, uint256 _limit)
        external
        virtual;






    function setPackContenthash(uint256 _packId, bytes calldata _contenthash)
        external
        virtual;







    function claimTokens(address _token)
        external
        virtual;







    function setPackPrice(uint256 _packId, uint256 _price, uint256 _donate)
        external
        virtual;






    function addPackCategory(uint256 _packId, bytes4 _category)
        external
        virtual;






    function removePackCategory(uint256 _packId, bytes4 _category)
        external
        virtual;






    function setPackState(uint256 _packId, bool _mintable)
        external
        virtual;






    function getAvailablePacks(bytes4 _category)
        external
        virtual
        view
        returns (uint256[] memory availableIds);






    function getCategoryLength(bytes4 _category)
        external
        virtual
        view
        returns (uint256 size);







    function getCategoryPack(bytes4 _category, uint256 _index)
        external
        virtual
        view
        returns (uint256 packId);











    function getPackData(uint256 _packId)
        external
        virtual
        view
        returns (
            bytes4[] memory category,
            address owner,
            bool mintable,
            uint256 timestamp,
            uint256 price,
            bytes memory contenthash
        );








    function getPackSummary(uint256 _packId)
        external
        virtual
        view
        returns (
            bytes4[] memory category,
            uint256 timestamp,
            bytes memory contenthash
        );









    function getPaymentData(uint256 _packId)
        external
        virtual
        view
        returns (
            address owner,
            bool mintable,
            uint256 price,
            uint256 donate
        );

}









contract SafeTransfer {

    function _safeTransfer(ERC20Token token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function _safeTransferFrom(ERC20Token token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }







    function _callOptionalReturn(ERC20Token token, bytes memory data) private {








        require(_isContract(address(token)), "SafeTransfer: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTransfer: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeTransfer: ERC20 operation did not succeed");
        }
    }


















    function _isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}











contract TokenWithdrawer is SafeTransfer {





    function withdrawTokens(
        address[] memory _tokens,
        address payable _destination
    )
        internal
    {
        uint len = _tokens.length;
        for(uint i = 0; i < len; i++){
            withdrawToken(_tokens[i], _destination);
        }
    }






    function withdrawToken(address _token, address payable _destination)
        internal
    {
        uint256 balance;
        if (_token == address(0)) {
            balance = address(this).balance;
            (bool success, ) = _destination.call.value(balance)("");
            require(success, "Transfer failed");
        } else {
            ERC20Token token = ERC20Token(_token);
            balance = token.balanceOf(address(this));
            _safeTransfer(token, _destination, balance);
        }
    }
}





contract SimplifiedDistributor is SafeTransfer, ReentrancyGuard, TokenWithdrawer {
    address payable public owner;
    address public signer;


    struct Pack {
        uint256 ethAmount;
        address[] tokens;
        uint256[] tokenAmounts;
    }

    Pack public defaultPack;

    ERC20Token public sntToken;

    bool public pause = true;

    event RequireApproval(address attribution);

    mapping(address => uint) public pendingAttributionCnt;
    mapping(address => uint) public attributionCnt;

    struct Attribution {
        bool enabled;
        uint256 ethAmount;
        address[] tokens;
        uint256[] tokenAmounts;
        uint limit;
    }

    mapping(address => Attribution) defaultAttributionSettings;
    mapping(address => Attribution) promoAttributionSettings;




    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorized");
        _;
    }







    function eligible(address _recipient) public view returns (bool){
        return true;
    }







    function getDefaultPack() external view returns(address stickerMarket, uint256 ethAmount, address[] memory tokens, uint[] memory tokenAmounts, uint[] memory stickerPackIds) {
        ethAmount = defaultPack.ethAmount;
        tokens = defaultPack.tokens;
        tokenAmounts = defaultPack.tokenAmounts;
    }








    function getPromoPack() external view returns(address stickerMarket, uint256 ethAmount, address[] memory tokens, uint[] memory tokenAmounts, uint[] memory stickerPackIds, uint256 available) {

    }

    event Distributed(address indexed recipient, address indexed attribution);





    function distributePack(address payable _recipient, address payable _attribution) external reentrancyGuard {
        require(!pause, "Paused");
        require(tx.origin == signer, "Unauthorized");

        require(_recipient != _attribution, "Recipient should be different from Attribution address");

        Pack memory pack = defaultPack;



        for (uint256 i = 0; i < pack.tokens.length; i++) {
            ERC20Token token = ERC20Token(pack.tokens[i]);
            uint256 amount = pack.tokenAmounts[i];
            require(token.transfer(_recipient, amount), "ERC20 operation did not succeed");
        }



        (bool success, ) = _recipient.call.value(pack.ethAmount)("");
        require(success, "ETH Transfer failed");

        emit Distributed(_recipient, _attribution);

        if (_attribution == address(0)) return;

        pendingAttributionCnt[_attribution] += 1;
    }

    function withdrawAttributions() external {
        require(!pause, "Paused");

        uint pendingAttributions = pendingAttributionCnt[msg.sender];
        uint attributionsPaid = attributionCnt[msg.sender];

        if (pendingAttributions == 0) return;

        Attribution memory attr = defaultAttributionSettings[msg.sender];
        if (!attr.enabled) {
           attr = defaultAttributionSettings[address(0)];
        }

        uint totalETHToPay;
        uint totalSNTToPay;
        uint attributionsToPay;
        if((attributionsPaid + pendingAttributions) > attr.limit){
            emit RequireApproval(msg.sender);
            if(attributionsPaid < attr.limit){
                attributionsToPay = attr.limit - attributionsPaid;
            } else {
                attributionsToPay = 0;
            }
            attributionsPaid += attributionsToPay;
            pendingAttributions -= attributionsToPay;
        } else {
            attributionsToPay = pendingAttributions;
            attributionsPaid += attributionsToPay;
            pendingAttributions = 0;
        }

        totalETHToPay += attributionsToPay * attr.ethAmount;

        for (uint256 i = 0; i < attr.tokens.length; i++) {
            if(attr.tokens[i] == address(sntToken)){
                totalSNTToPay += attributionsToPay * attr.tokenAmounts[i];
            } else {
                ERC20Token token = ERC20Token(attr.tokens[i]);
                uint256 amount = attributionsToPay * attr.tokenAmounts[i];
                _safeTransfer(token, msg.sender, amount);
            }
        }

        pendingAttributionCnt[msg.sender] = pendingAttributions;
        attributionCnt[msg.sender] = attributionsPaid;

        if (totalETHToPay != 0){

            (bool success, ) = msg.sender.call.value(totalETHToPay)("");
            require(success, "ETH Transfer failed");
        }

        if (totalSNTToPay != 0){
            ERC20Token token = ERC20Token(sntToken);
            _safeTransfer(token, msg.sender, totalSNTToPay);
        }
    }









    function getReferralReward(address _account, bool _isPromo) public view returns (uint ethAmount, uint tokenLen, uint maxThreshold, uint attribCount) {
        require(_isPromo != true);
        Attribution memory attr = defaultAttributionSettings[_account];
        if (!attr.enabled) {
            attr = defaultAttributionSettings[address(0)];
        }

        ethAmount = attr.ethAmount;
        maxThreshold = attr.limit;
        attribCount = attributionCnt[_account];
        tokenLen = attr.tokens.length;
    }







    function getReferralRewardTokens(address _account, bool _isPromo, uint _idx) public view returns (address token, uint tokenAmount) {
        require(_isPromo != true);
        Attribution memory attr = defaultAttributionSettings[_account];
        if (!attr.enabled) {
            attr = defaultAttributionSettings[address(0)];
        }

        token = attr.tokens[_idx];
        tokenAmount = attr.tokenAmounts[_idx];
    }

    fallback() external payable  {

    }





    function setPause(bool _pause) external onlyOwner {
        pause = _pause;
    }




    function changeStarterPack(Pack memory _newPack) public onlyOwner {
        require(_newPack.tokens.length == _newPack.tokenAmounts.length, "Mismatch with Tokens & Amounts");

        for (uint256 i = 0; i < _newPack.tokens.length; i++) {
            require(_newPack.tokenAmounts[i] > 0, "Amounts must be non-zero");
        }

        defaultPack = _newPack;
    }


    function withdraw(address[] calldata _tokens) external onlyOwner {
        pause = true;
        withdrawTokens(_tokens, owner);
    }



    function changeSigner(address _newSigner) public onlyOwner {
        require(_newSigner != address(0), "zero_address not allowed");
        signer = _newSigner;
    }



    function changeOwner(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0), "zero_address not allowed");
        owner = _newOwner;
    }






    function setPayoutAndThreshold(
        bool _isPromo,
        uint256 _ethAmount,
        address[] calldata _tokens,
        uint256[] calldata _tokenAmounts,
        uint256[] calldata _thresholds,
        address[] calldata _assignedTo
    ) external onlyOwner {
        require(_isPromo != true);

        require(_thresholds.length == _assignedTo.length, "Array length mismatch");
        require(_tokens.length == _tokenAmounts.length, "Array length mismatch");

        for (uint256 i = 0; i < _thresholds.length; i++) {
            bool enabled = _assignedTo[i] != address(0);

            Attribution memory attr = Attribution({
                enabled: enabled,
                ethAmount: _ethAmount,
                limit: _thresholds[i],
                tokens: _tokens,
                tokenAmounts: _tokenAmounts
            });

            defaultAttributionSettings[_assignedTo[i]] = attr;
        }
    }




    function removePayoutAndThreshold(address[] calldata _assignedTo, bool _isPromo) external onlyOwner {
        for (uint256 i = 0; i < _assignedTo.length; i++) {
            delete defaultAttributionSettings[_assignedTo[i]];
        }
    }


    function setSntToken(address _sntToken) external onlyOwner {
        sntToken = ERC20Token(_sntToken);
    }



    constructor(address _signer, address _sntToken) public {
        require(_signer != address(0), "zero_address not allowed");
        owner = msg.sender;
        signer = _signer;
        sntToken = ERC20Token(_sntToken);
    }
}
