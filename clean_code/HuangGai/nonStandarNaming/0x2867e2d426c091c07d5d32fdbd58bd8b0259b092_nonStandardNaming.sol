

pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

contract Token {


    uint256 public totalSupply;



    function BALANCEOF126(address _owner) view public returns (uint256 balance);





    function TRANSFER539(address _to, uint256 _value) public returns (bool success);






    function TRANSFERFROM134(address _from, address _to, uint256 _value) public returns (bool success);





    function APPROVE766(address _spender, uint256 _value) public returns (bool success);




    function ALLOWANCE680(address _owner, address _spender) public view returns (uint256 remaining);

    event TRANSFER377(address _from, address _to, uint256 _value);
    event APPROVAL896(address _owner, address _spender, uint256 _value);
}

contract ERC20Token is Token {

    function TRANSFER539(address _to, uint256 _value) public returns (bool success) {




        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit TRANSFER377(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function TRANSFERFROM134(address _from, address _to, uint256 _value) public returns (bool success) {


        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit TRANSFER377(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function BALANCEOF126(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function APPROVE766(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit APPROVAL896(msg.sender, _spender, _value);
        return true;
    }

    function ALLOWANCE680(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

library SafeMath {


  function MUL746(uint256 a, uint256 b) internal pure returns (uint256 c) {



    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }


  function DIV871(uint256 a, uint256 b) internal pure returns (uint256) {



    return a / b;
  }


  function SUB288(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }


  function ADD535(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


library AddressUtils {


  function ISCONTRACT297(address addr) internal view returns (bool) {
    uint256 size;







    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}


interface ERC165 {


  function SUPPORTSINTERFACE396(bytes4 _interfaceId)
    external
    view
    returns (bool);
}



contract SupportsInterfaceWithLookup is ERC165 {
  bytes4 public constant interfaceid_erc165197 = 0x01ffc9a7;



  mapping(bytes4 => bool) internal supportedInterfaces;


  constructor()
    public
  {
    _REGISTERINTERFACE866(interfaceid_erc165197);
  }


  function SUPPORTSINTERFACE396(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }


  function _REGISTERINTERFACE866(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}


contract ERC721Receiver {

  bytes4 internal constant erc721_received613 = 0xf0b9e5ba;


  function ONERC721RECEIVED739(
    address _from,
    uint256 _tokenId,
    bytes memory _data
  )
    public
    returns(bytes4);
}


contract ERC721Basic is ERC165 {
  event TRANSFER377(
    address  _from,
    address  _to,
    uint256  _tokenId
  );
  event APPROVAL896(
    address  _owner,
    address  _approved,
    uint256  _tokenId
  );
  event APPROVALFORALL957(
    address  _owner,
    address  _operator,
    bool _approved
  );

  function BALANCEOF126(address _owner) public view returns (uint256 _balance);
  function OWNEROF291(uint256 _tokenId) public view returns (address _owner);
  function EXISTS362(uint256 _tokenId) public view returns (bool _exists);

  function APPROVE766(address _to, uint256 _tokenId) public;
  function GETAPPROVED462(uint256 _tokenId)
    public view returns (address _operator);

  function SETAPPROVALFORALL90(address _operator, bool _approved) public;
  function ISAPPROVEDFORALL509(address _owner, address _operator)
    public view returns (bool);

  function TRANSFERFROM134(address _from, address _to, uint256 _tokenId) public;
  function SAFETRANSFERFROM921(address _from, address _to, uint256 _tokenId)
    public;

  function SAFETRANSFERFROM921(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    public;
}


contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  bytes4 private constant interfaceid_erc721619 = 0x80ac58cd;


  bytes4 private constant interfaceid_erc721exists608 = 0x4f558e79;


  using SafeMath for uint256;
  using AddressUtils for address;



  bytes4 private constant erc721_received613 = 0xf0b9e5ba;


  mapping (uint256 => address) internal tokenOwner;


  mapping (uint256 => address) internal tokenApprovals;


  mapping (address => uint256) internal ownedTokensCount;


  mapping (address => mapping (address => bool)) internal operatorApprovals;


  uint public testint;

  modifier ONLYOWNEROF128(uint256 _tokenId) {
    require(OWNEROF291(_tokenId) == msg.sender);
    _;
  }


  modifier CANTRANSFER884(uint256 _tokenId) {
    require(ISAPPROVEDOROWNER880(msg.sender, _tokenId));
    _;
  }

  constructor()
    public
  {

    _REGISTERINTERFACE866(interfaceid_erc721619);
    _REGISTERINTERFACE866(interfaceid_erc721exists608);
  }


  function BALANCEOF126(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }


  function OWNEROF291(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }


  function EXISTS362(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }


  function APPROVE766(address _to, uint256 _tokenId) public {
    address owner = OWNEROF291(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || ISAPPROVEDFORALL509(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit APPROVAL896(owner, _to, _tokenId);
  }


  function GETAPPROVED462(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }


  function SETAPPROVALFORALL90(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit APPROVALFORALL957(msg.sender, _to, _approved);
  }


  function ISAPPROVEDFORALL509(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }


  function TRANSFERFROM134(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    CANTRANSFER884(_tokenId)
  {
    require(_from != address(0));
    require(_to != address(0));

    CLEARAPPROVAL440(_from, _tokenId);
    REMOVETOKENFROM320(_from, _tokenId);
    ADDTOKENTO890(_to, _tokenId);

    emit TRANSFER377(_from, _to, _tokenId);
  }


  function SAFETRANSFERFROM921(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    CANTRANSFER884(_tokenId)
  {

    SAFETRANSFERFROM921(_from, _to, _tokenId, "");
  }


  function SAFETRANSFERFROM921(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    public
    CANTRANSFER884(_tokenId)
  {
    TRANSFERFROM134(_from, _to, _tokenId);

    require(CHECKANDCALLSAFETRANSFER327(_from, _to, _tokenId, _data));
  }


  function ISAPPROVEDOROWNER880(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = OWNEROF291(_tokenId);



    return (
      _spender == owner ||
      GETAPPROVED462(_tokenId) == _spender ||
      ISAPPROVEDFORALL509(owner, _spender)
    );
  }


  function _MINT613(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    ADDTOKENTO890(_to, _tokenId);
    emit TRANSFER377(address(0), _to, _tokenId);
  }


  function _BURN402(address _owner, uint256 _tokenId) internal {
    CLEARAPPROVAL440(_owner, _tokenId);
    REMOVETOKENFROM320(_owner, _tokenId);
    emit TRANSFER377(_owner, address(0), _tokenId);
  }


  function CLEARAPPROVAL440(address _owner, uint256 _tokenId) internal {
    require(OWNEROF291(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }


  function ADDTOKENTO890(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].ADD535(1);
  }


  function REMOVETOKENFROM320(address _from, uint256 _tokenId) internal {
    require(OWNEROF291(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].SUB288(1);
    tokenOwner[_tokenId] = address(0);
  }


  function CHECKANDCALLSAFETRANSFER327(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    internal
    returns (bool)
  {
    if (!_to.ISCONTRACT297()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).ONERC721RECEIVED739(
      _from, _tokenId, _data);
    return (retval == erc721_received613);
  }
}

contract ERC721BasicTokenMock is ERC721BasicToken {
  function MINT436(address _to, uint256 _tokenId) public {
    super._MINT613(_to, _tokenId);
  }

  function BURN214(uint256 _tokenId) public {
    super._BURN402(OWNEROF291(_tokenId), _tokenId);
  }
}

contract StandardBounties {

  using SafeMath for uint256;



  struct Bounty {
    address payable[] issuers;
    address[] approvers;
    uint deadline;
    address token;
    uint tokenVersion;
    uint balance;
    bool hasPaidOut;
    Fulfillment[] fulfillments;
    Contribution[] contributions;
  }

  struct Fulfillment {
    address payable[] fulfillers;
    address submitter;
  }

  struct Contribution {
    address payable contributor;
    uint amount;
    bool refunded;
  }



  uint public numBounties;
  mapping(uint => Bounty) public bounties;
  mapping (uint => mapping (uint => bool)) public tokenBalances;


  address public owner;
  address public metaTxRelayer;

  bool public callStarted;



  modifier CALLNOTSTARTED963(){
    require(!callStarted);
    callStarted = true;
    _;
    callStarted = false;
  }

  modifier VALIDATEBOUNTYARRAYINDEX962(
    uint _index)
  {
    require(_index < numBounties);
    _;
  }

  modifier VALIDATECONTRIBUTIONARRAYINDEX279(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].contributions.length);
    _;
  }

  modifier VALIDATEFULFILLMENTARRAYINDEX396(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].fulfillments.length);
    _;
  }

  modifier VALIDATEISSUERARRAYINDEX737(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].issuers.length);
    _;
  }

  modifier VALIDATEAPPROVERARRAYINDEX32(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].approvers.length);
    _;
  }

  modifier ONLYISSUER653(
  address _sender,
  uint _bountyId,
  uint _issuerId)
  {
  require(_sender == bounties[_bountyId].issuers[_issuerId]);
  _;
  }

  modifier ONLYSUBMITTER83(
    address _sender,
    uint _bountyId,
    uint _fulfillmentId)
  {
    require(_sender ==
            bounties[_bountyId].fulfillments[_fulfillmentId].submitter);
    _;
  }

  modifier ONLYCONTRIBUTOR9(
  address _sender,
  uint _bountyId,
  uint _contributionId)
  {
    require(_sender ==
            bounties[_bountyId].contributions[_contributionId].contributor);
    _;
  }

  modifier ISAPPROVER33(
    address _sender,
    uint _bountyId,
    uint _approverId)
  {
    require(_sender == bounties[_bountyId].approvers[_approverId]);
    _;
  }

  modifier HASNOTPAID405(
    uint _bountyId)
  {
    require(!bounties[_bountyId].hasPaidOut);
    _;
  }

  modifier HASNOTREFUNDED93(
    uint _bountyId,
    uint _contributionId)
  {
    require(!bounties[_bountyId].contributions[_contributionId].refunded);
    _;
  }

  modifier SENDERISVALID782(
    address _sender)
  {
    require(msg.sender == _sender || msg.sender == metaTxRelayer);
    _;
  }



  constructor() public {

    owner = msg.sender;
  }



  function SETMETATXRELAYER306(address _relayer)
    external
  {
    require(msg.sender == owner);
    require(metaTxRelayer == address(0));
    metaTxRelayer = _relayer;
  }









  function ISSUEBOUNTY607(
    address payable _sender,
    address payable[] memory _issuers,
    address[] memory _approvers,
    string memory _data,
    uint _deadline,
    address _token,
    uint _tokenVersion)
    public
    SENDERISVALID782(_sender)
    returns (uint)
  {
    require(_tokenVersion == 0 || _tokenVersion == 20 || _tokenVersion == 721);
    require(_issuers.length > 0 || _approvers.length > 0);

    uint bountyId = numBounties;

    Bounty storage newBounty = bounties[bountyId];
    newBounty.issuers = _issuers;
    newBounty.approvers = _approvers;
    newBounty.deadline = _deadline;
    newBounty.tokenVersion = _tokenVersion;

    if (_tokenVersion != 0){
      newBounty.token = _token;
    }

    numBounties = numBounties.ADD535(1);

    emit BOUNTYISSUED291(bountyId,
                      _sender,
                      _issuers,
                      _approvers,
                      _data,
                      _deadline,
                      _token,
                      _tokenVersion);

    return (bountyId);
  }




  function ISSUEANDCONTRIBUTE529(
    address payable _sender,
    address payable[] memory _issuers,
    address[] memory _approvers,
    string memory _data,
    uint _deadline,
    address _token,
    uint _tokenVersion,
    uint _depositAmount)
    public
    payable
    returns(uint)
  {
    uint bountyId = ISSUEBOUNTY607(_sender, _issuers, _approvers, _data, _deadline, _token, _tokenVersion);

    CONTRIBUTE618(_sender, bountyId, _depositAmount);

    return (bountyId);
  }












  function CONTRIBUTE618(
    address payable _sender,
    uint _bountyId,
    uint _amount)
    public
    payable
    SENDERISVALID782(_sender)
    VALIDATEBOUNTYARRAYINDEX962(_bountyId)
    CALLNOTSTARTED963
  {
    require(_amount > 0);

    bounties[_bountyId].contributions.push(
      Contribution(_sender, _amount, false));

    if (bounties[_bountyId].tokenVersion == 0){

      bounties[_bountyId].balance = bounties[_bountyId].balance.ADD535(_amount);

      require(msg.value == _amount);
    } else if (bounties[_bountyId].tokenVersion == 20){

      bounties[_bountyId].balance = bounties[_bountyId].balance.ADD535(_amount);

      require(msg.value == 0);
      require(ERC20Token(bounties[_bountyId].token).TRANSFERFROM134(_sender,
                                                                 address(this),
                                                                 _amount));
    } else if (bounties[_bountyId].tokenVersion == 721){
      tokenBalances[_bountyId][_amount] = true;


      require(msg.value == 0);
      ERC721BasicToken(bounties[_bountyId].token).TRANSFERFROM134(_sender,
                                                               address(this),
                                                               _amount);
    } else {
      revert();
    }

    emit CONTRIBUTIONADDED888(_bountyId,
                           bounties[_bountyId].contributions.length - 1,
                           _sender,
                           _amount);
  }







  function REFUNDCONTRIBUTION719(
    address _sender,
    uint _bountyId,
    uint _contributionId)
    public
    SENDERISVALID782(_sender)
    VALIDATEBOUNTYARRAYINDEX962(_bountyId)
    VALIDATECONTRIBUTIONARRAYINDEX279(_bountyId, _contributionId)
    ONLYCONTRIBUTOR9(_sender, _bountyId, _contributionId)
    HASNOTPAID405(_bountyId)
    HASNOTREFUNDED93(_bountyId, _contributionId)
    CALLNOTSTARTED963
  {
    require(now > bounties[_bountyId].deadline);

    Contribution storage contribution = bounties[_bountyId].contributions[_contributionId];

    contribution.refunded = true;

    TRANSFERTOKENS903(_bountyId, contribution.contributor, contribution.amount);

    emit CONTRIBUTIONREFUNDED423(_bountyId, _contributionId);
  }





  function REFUNDMYCONTRIBUTIONS1000(
    address _sender,
    uint _bountyId,
    uint[] memory _contributionIds)
    public
    SENDERISVALID782(_sender)
  {
    for (uint i = 0; i < _contributionIds.length; i++){
        REFUNDCONTRIBUTION719(_sender, _bountyId, _contributionIds[i]);
    }
  }






  function REFUNDCONTRIBUTIONS786(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint[] memory _contributionIds)
    public
    SENDERISVALID782(_sender)
    VALIDATEBOUNTYARRAYINDEX962(_bountyId)
    ONLYISSUER653(_sender, _bountyId, _issuerId)
    CALLNOTSTARTED963
  {
    for (uint i = 0; i < _contributionIds.length; i++){
      require(_contributionIds[i] < bounties[_bountyId].contributions.length);

      Contribution storage contribution = bounties[_bountyId].contributions[_contributionIds[i]];

      require(!contribution.refunded);

      contribution.refunded = true;

      TRANSFERTOKENS903(_bountyId, contribution.contributor, contribution.amount);
    }

    emit CONTRIBUTIONSREFUNDED218(_bountyId, _sender, _contributionIds);
  }







  function DRAINBOUNTY345(
    address payable _sender,
    uint _bountyId,
    uint _issuerId,
    uint[] memory _amounts)
    public
    SENDERISVALID782(_sender)
    VALIDATEBOUNTYARRAYINDEX962(_bountyId)
    ONLYISSUER653(_sender, _bountyId, _issuerId)
    CALLNOTSTARTED963
  {
    if (bounties[_bountyId].tokenVersion == 0 || bounties[_bountyId].tokenVersion == 20){
      require(_amounts.length == 1);
      require(_amounts[0] <= bounties[_bountyId].balance);
      TRANSFERTOKENS903(_bountyId, _sender, _amounts[0]);
    } else {
      for (uint i = 0; i < _amounts.length; i++){
        require(tokenBalances[_bountyId][_amounts[i]]);
        TRANSFERTOKENS903(_bountyId, _sender, _amounts[i]);
      }
    }

    emit BOUNTYDRAINED424(_bountyId, _sender, _amounts);
  }






  function PERFORMACTION966(
    address _sender,
    uint _bountyId,
    string memory _data)
    public
    SENDERISVALID782(_sender)
    VALIDATEBOUNTYARRAYINDEX962(_bountyId)
  {
    emit ACTIONPERFORMED922(_bountyId, _sender, _data);
  }






  function FULFILLBOUNTY596(
    address _sender,
    uint _bountyId,
    address payable[] memory  _fulfillers,
    string memory _data)
    public
    SENDERISVALID782(_sender)
    VALIDATEBOUNTYARRAYINDEX962(_bountyId)
  {
    require(now < bounties[_bountyId].deadline);
    require(_fulfillers.length > 0);

    bounties[_bountyId].fulfillments.push(Fulfillment(_fulfillers, _sender));

    emit BOUNTYFULFILLED198(_bountyId,
                         (bounties[_bountyId].fulfillments.length - 1),
                         _fulfillers,
                         _data,
                         _sender);
  }







  function UPDATEFULFILLMENT168(
  address _sender,
  uint _bountyId,
  uint _fulfillmentId,
  address payable[] memory _fulfillers,
  string memory _data)
  public
  SENDERISVALID782(_sender)
  VALIDATEBOUNTYARRAYINDEX962(_bountyId)
  VALIDATEFULFILLMENTARRAYINDEX396(_bountyId, _fulfillmentId)
  ONLYSUBMITTER83(_sender, _bountyId, _fulfillmentId)
  {
    bounties[_bountyId].fulfillments[_fulfillmentId].fulfillers = _fulfillers;
    emit FULFILLMENTUPDATED42(_bountyId,
                            _fulfillmentId,
                            _fulfillers,
                            _data);
  }











  function ACCEPTFULFILLMENT330(
    address _sender,
    uint _bountyId,
    uint _fulfillmentId,
    uint _approverId,
    uint[] memory _tokenAmounts)
    public
    SENDERISVALID782(_sender)
    VALIDATEBOUNTYARRAYINDEX962(_bountyId)
    VALIDATEFULFILLMENTARRAYINDEX396(_bountyId, _fulfillmentId)
    ISAPPROVER33(_sender, _bountyId, _approverId)
    CALLNOTSTARTED963
  {

    bounties[_bountyId].hasPaidOut = true;

    Fulfillment storage fulfillment = bounties[_bountyId].fulfillments[_fulfillmentId];

    require(_tokenAmounts.length == fulfillment.fulfillers.length);

    for (uint256 i = 0; i < fulfillment.fulfillers.length; i++){
        if (_tokenAmounts[i] > 0){

          TRANSFERTOKENS903(_bountyId, fulfillment.fulfillers[i], _tokenAmounts[i]);
        }
    }
    emit FULFILLMENTACCEPTED617(_bountyId,
                             _fulfillmentId,
                             _sender,
                             _tokenAmounts);
  }












  function FULFILLANDACCEPT822(
    address _sender,
    uint _bountyId,
    address payable[] memory _fulfillers,
    string memory _data,
    uint _approverId,
    uint[] memory _tokenAmounts)
    public
    SENDERISVALID782(_sender)
  {

    FULFILLBOUNTY596(_sender, _bountyId, _fulfillers, _data);


    ACCEPTFULFILLMENT330(_sender,
                      _bountyId,
                      bounties[_bountyId].fulfillments.length - 1,
                      _approverId,
                      _tokenAmounts);
  }











  function CHANGEBOUNTY775(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable[] memory _issuers,
    address payable[] memory _approvers,
    string memory _data,
    uint _deadline)
    public
    SENDERISVALID782(_sender)
  {
    require(_bountyId < numBounties);
    require(_issuerId < bounties[_bountyId].issuers.length);
    require(_sender == bounties[_bountyId].issuers[_issuerId]);

    require(_issuers.length > 0 || _approvers.length > 0);

    bounties[_bountyId].issuers = _issuers;
    bounties[_bountyId].approvers = _approvers;
    bounties[_bountyId].deadline = _deadline;
    emit BOUNTYCHANGED890(_bountyId,
                       _sender,
                       _issuers,
                       _approvers,
                       _data,
                       _deadline);
  }







  function CHANGEISSUER877(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _issuerIdToChange,
    address payable _newIssuer)
    public
    SENDERISVALID782(_sender)
    VALIDATEBOUNTYARRAYINDEX962(_bountyId)
    VALIDATEISSUERARRAYINDEX737(_bountyId, _issuerIdToChange)
    ONLYISSUER653(_sender, _bountyId, _issuerId)
  {
    require(_issuerId < bounties[_bountyId].issuers.length || _issuerId == 0);

    bounties[_bountyId].issuers[_issuerIdToChange] = _newIssuer;

    emit BOUNTYISSUERSUPDATED404(_bountyId, _sender, bounties[_bountyId].issuers);
  }







  function CHANGEAPPROVER313(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _approverId,
    address payable _approver)
    external
    SENDERISVALID782(_sender)
    VALIDATEBOUNTYARRAYINDEX962(_bountyId)
    ONLYISSUER653(_sender, _bountyId, _issuerId)
    VALIDATEAPPROVERARRAYINDEX32(_bountyId, _approverId)
  {
    bounties[_bountyId].approvers[_approverId] = _approver;

    emit BOUNTYAPPROVERSUPDATED564(_bountyId, _sender, bounties[_bountyId].approvers);
  }








  function CHANGEISSUERANDAPPROVER5(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _issuerIdToChange,
    uint _approverIdToChange,
    address payable _issuer)
    external
    SENDERISVALID782(_sender)
    ONLYISSUER653(_sender, _bountyId, _issuerId)
  {
    require(_bountyId < numBounties);
    require(_approverIdToChange < bounties[_bountyId].approvers.length);
    require(_issuerIdToChange < bounties[_bountyId].issuers.length);

    bounties[_bountyId].issuers[_issuerIdToChange] = _issuer;
    bounties[_bountyId].approvers[_approverIdToChange] = _issuer;

    emit BOUNTYISSUERSUPDATED404(_bountyId, _sender, bounties[_bountyId].issuers);
    emit BOUNTYAPPROVERSUPDATED564(_bountyId, _sender, bounties[_bountyId].approvers);
  }






  function CHANGEDATA475(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    string memory _data)
    public
    SENDERISVALID782(_sender)
    VALIDATEBOUNTYARRAYINDEX962(_bountyId)
    VALIDATEISSUERARRAYINDEX737(_bountyId, _issuerId)
    ONLYISSUER653(_sender, _bountyId, _issuerId)
  {
    emit BOUNTYDATACHANGED202(_bountyId, _sender, _data);
  }






  function CHANGEDEADLINE144(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _deadline)
    external
    SENDERISVALID782(_sender)
    VALIDATEBOUNTYARRAYINDEX962(_bountyId)
    VALIDATEISSUERARRAYINDEX737(_bountyId, _issuerId)
    ONLYISSUER653(_sender, _bountyId, _issuerId)
  {
    bounties[_bountyId].deadline = _deadline;

    emit BOUNTYDEADLINECHANGED293(_bountyId, _sender, _deadline);
  }






  function ADDISSUERS127(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable[] memory _issuers)
    public
    SENDERISVALID782(_sender)
    VALIDATEBOUNTYARRAYINDEX962(_bountyId)
    VALIDATEISSUERARRAYINDEX737(_bountyId, _issuerId)
    ONLYISSUER653(_sender, _bountyId, _issuerId)
  {
    for (uint i = 0; i < _issuers.length; i++){
      bounties[_bountyId].issuers.push(_issuers[i]);
    }

    emit BOUNTYISSUERSUPDATED404(_bountyId, _sender, bounties[_bountyId].issuers);
  }






  function ADDAPPROVERS15(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address[] memory _approvers)
    public
    SENDERISVALID782(_sender)
    VALIDATEBOUNTYARRAYINDEX962(_bountyId)
    VALIDATEISSUERARRAYINDEX737(_bountyId, _issuerId)
    ONLYISSUER653(_sender, _bountyId, _issuerId)
  {
    for (uint i = 0; i < _approvers.length; i++){
      bounties[_bountyId].approvers.push(_approvers[i]);
    }

    emit BOUNTYAPPROVERSUPDATED564(_bountyId, _sender, bounties[_bountyId].approvers);
  }




  function GETBOUNTY268(uint _bountyId)
    external
    view
    returns (Bounty memory)
  {
    return bounties[_bountyId];
  }


  function TRANSFERTOKENS903(uint _bountyId, address payable _to, uint _amount)
    internal
  {
    if (bounties[_bountyId].tokenVersion == 0){
      require(_amount > 0);
      require(bounties[_bountyId].balance >= _amount);

      bounties[_bountyId].balance = bounties[_bountyId].balance.SUB288(_amount);

      _to.transfer(_amount);
    } else if (bounties[_bountyId].tokenVersion == 20){
      require(_amount > 0);
      require(bounties[_bountyId].balance >= _amount);

      bounties[_bountyId].balance = bounties[_bountyId].balance.SUB288(_amount);

      require(ERC20Token(bounties[_bountyId].token).TRANSFER539(_to, _amount));
    } else if (bounties[_bountyId].tokenVersion == 721){
      require(tokenBalances[_bountyId][_amount]);

      tokenBalances[_bountyId][_amount] = false;

      ERC721BasicToken(bounties[_bountyId].token).TRANSFERFROM134(address(this),
                                                               _to,
                                                               _amount);
    } else {
      revert();
    }
  }



  event BOUNTYISSUED291(uint _bountyId, address payable _creator, address payable[] _issuers, address[] _approvers, string _data, uint _deadline, address _token, uint _tokenVersion);
  event CONTRIBUTIONADDED888(uint _bountyId, uint _contributionId, address payable _contributor, uint _amount);
  event CONTRIBUTIONREFUNDED423(uint _bountyId, uint _contributionId);
  event CONTRIBUTIONSREFUNDED218(uint _bountyId, address _issuer, uint[] _contributionIds);
  event BOUNTYDRAINED424(uint _bountyId, address _issuer, uint[] _amounts);
  event ACTIONPERFORMED922(uint _bountyId, address _fulfiller, string _data);
  event BOUNTYFULFILLED198(uint _bountyId, uint _fulfillmentId, address payable[] _fulfillers, string _data, address _submitter);
  event FULFILLMENTUPDATED42(uint _bountyId, uint _fulfillmentId, address payable[] _fulfillers, string _data);
  event FULFILLMENTACCEPTED617(uint _bountyId, uint  _fulfillmentId, address _approver, uint[] _tokenAmounts);
  event BOUNTYCHANGED890(uint _bountyId, address _changer, address payable[] _issuers, address payable[] _approvers, string _data, uint _deadline);
  event BOUNTYISSUERSUPDATED404(uint _bountyId, address _changer, address payable[] _issuers);
  event BOUNTYAPPROVERSUPDATED564(uint _bountyId, address _changer, address[] _approvers);
  event BOUNTYDATACHANGED202(uint _bountyId, address _changer, string _data);
  event BOUNTYDEADLINECHANGED293(uint _bountyId, address _changer, uint _deadline);
}

contract BountiesMetaTxRelayer {



  StandardBounties public bountiesContract;
  mapping(address => uint) public replayNonce;


  constructor(address _contract) public {
    bountiesContract = StandardBounties(_contract);
  }

  function METAISSUEBOUNTY189(
    bytes memory signature,
    address payable[] memory _issuers,
    address[] memory _approvers,
    string memory _data,
    uint _deadline,
    address _token,
    uint _tokenVersion,
    uint _nonce)
    public
    returns (uint)
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaIssueBounty",
                                                  _issuers,
                                                  _approvers,
                                                  _data,
                                                  _deadline,
                                                  _token,
                                                  _tokenVersion,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, signature);


    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;
    return bountiesContract.ISSUEBOUNTY607(address(uint160(signer)),
                                         _issuers,
                                         _approvers,
                                         _data,
                                         _deadline,
                                         _token,
                                         _tokenVersion);
  }

  function METAISSUEANDCONTRIBUTE154(
    bytes memory signature,
    address payable[] memory _issuers,
    address[] memory _approvers,
    string memory _data,
    uint _deadline,
    address _token,
    uint _tokenVersion,
    uint _depositAmount,
    uint _nonce)
    public
    payable
    returns (uint)
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaIssueAndContribute",
                                                  _issuers,
                                                  _approvers,
                                                  _data,
                                                  _deadline,
                                                  _token,
                                                  _tokenVersion,
                                                  _depositAmount,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, signature);


    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    if (msg.value > 0){
      return bountiesContract.ISSUEANDCONTRIBUTE529.value(msg.value)(address(uint160(signer)),
                                                 _issuers,
                                                 _approvers,
                                                 _data,
                                                 _deadline,
                                                 _token,
                                                 _tokenVersion,
                                                 _depositAmount);
    } else {
      return bountiesContract.ISSUEANDCONTRIBUTE529(address(uint160(signer)),
                                                 _issuers,
                                                 _approvers,
                                                 _data,
                                                 _deadline,
                                                 _token,
                                                 _tokenVersion,
                                                 _depositAmount);
    }

  }

  function METACONTRIBUTE650(
    bytes memory _signature,
    uint _bountyId,
    uint _amount,
    uint _nonce)
    public
    payable
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaContribute",
                                                  _bountyId,
                                                  _amount,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);


    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    if (msg.value > 0){
      bountiesContract.CONTRIBUTE618.value(msg.value)(address(uint160(signer)), _bountyId, _amount);
    } else {
      bountiesContract.CONTRIBUTE618(address(uint160(signer)), _bountyId, _amount);
    }
  }


  function METAREFUNDCONTRIBUTION168(
    bytes memory _signature,
    uint _bountyId,
    uint _contributionId,
    uint _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaRefundContribution",
                                                  _bountyId,
                                                  _contributionId,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);


    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.REFUNDCONTRIBUTION719(signer, _bountyId, _contributionId);
  }

  function METAREFUNDMYCONTRIBUTIONS651(
    bytes memory _signature,
    uint _bountyId,
    uint[] memory _contributionIds,
    uint _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaRefundMyContributions",
                                                  _bountyId,
                                                  _contributionIds,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);


    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.REFUNDMYCONTRIBUTIONS1000(signer, _bountyId, _contributionIds);
  }

  function METAREFUNDCONTRIBUTIONS334(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    uint[] memory _contributionIds,
    uint _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaRefundContributions",
                                                  _bountyId,
                                                  _issuerId,
                                                  _contributionIds,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);


    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.REFUNDCONTRIBUTIONS786(signer, _bountyId, _issuerId, _contributionIds);
  }

  function METADRAINBOUNTY623(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    uint[] memory _amounts,
    uint _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaDrainBounty",
                                                  _bountyId,
                                                  _issuerId,
                                                  _amounts,
                                                  _nonce));
    address payable signer = address(uint160(GETSIGNER512(metaHash, _signature)));


    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.DRAINBOUNTY345(signer, _bountyId, _issuerId, _amounts);
  }

  function METAPERFORMACTION278(
    bytes memory _signature,
    uint _bountyId,
    string memory _data,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaPerformAction",
                                                  _bountyId,
                                                  _data,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);

    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.PERFORMACTION966(signer, _bountyId, _data);
  }

  function METAFULFILLBOUNTY952(
    bytes memory _signature,
    uint _bountyId,
    address payable[] memory  _fulfillers,
    string memory _data,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaFulfillBounty",
                                                  _bountyId,
                                                  _fulfillers,
                                                  _data,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);

    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.FULFILLBOUNTY596(signer, _bountyId, _fulfillers, _data);
  }

  function METAUPDATEFULFILLMENT854(
    bytes memory _signature,
    uint _bountyId,
    uint _fulfillmentId,
    address payable[] memory  _fulfillers,
    string memory _data,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaUpdateFulfillment",
                                                  _bountyId,
                                                  _fulfillmentId,
                                                  _fulfillers,
                                                  _data,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);

    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.UPDATEFULFILLMENT168(signer, _bountyId, _fulfillmentId, _fulfillers, _data);
  }

  function METAACCEPTFULFILLMENT218(
    bytes memory _signature,
    uint _bountyId,
    uint _fulfillmentId,
    uint _approverId,
    uint[] memory _tokenAmounts,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaAcceptFulfillment",
                                                  _bountyId,
                                                  _fulfillmentId,
                                                  _approverId,
                                                  _tokenAmounts,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);

    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.ACCEPTFULFILLMENT330(signer,
                       _bountyId,
                       _fulfillmentId,
                       _approverId,
                       _tokenAmounts);
  }

  function METAFULFILLANDACCEPT21(
    bytes memory _signature,
    uint _bountyId,
    address payable[] memory _fulfillers,
    string memory _data,
    uint _approverId,
    uint[] memory _tokenAmounts,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaFulfillAndAccept",
                                                  _bountyId,
                                                  _fulfillers,
                                                  _data,
                                                  _approverId,
                                                  _tokenAmounts,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);

    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.FULFILLANDACCEPT822(signer,
                      _bountyId,
                      _fulfillers,
                      _data,
                      _approverId,
                      _tokenAmounts);
  }

  function METACHANGEBOUNTY750(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    address payable[] memory _issuers,
    address payable[] memory _approvers,
    string memory _data,
    uint _deadline,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaChangeBounty",
                                                  _bountyId,
                                                  _issuerId,
                                                  _issuers,
                                                  _approvers,
                                                  _data,
                                                  _deadline,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);

    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.CHANGEBOUNTY775(signer,
                  _bountyId,
                  _issuerId,
                  _issuers,
                  _approvers,
                  _data,
                  _deadline);
  }

  function METACHANGEISSUER928(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    uint _issuerIdToChange,
    address payable _newIssuer,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaChangeIssuer",
                                                  _bountyId,
                                                  _issuerId,
                                                  _issuerIdToChange,
                                                  _newIssuer,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);

    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.CHANGEISSUER877(signer,
                  _bountyId,
                  _issuerId,
                  _issuerIdToChange,
                  _newIssuer);
  }

  function METACHANGEAPPROVER522(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    uint _approverId,
    address payable _approver,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaChangeApprover",
                                                  _bountyId,
                                                  _issuerId,
                                                  _approverId,
                                                  _approver,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);

    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.CHANGEAPPROVER313(signer,
                  _bountyId,
                  _issuerId,
                  _approverId,
                  _approver);
  }

  function METACHANGEDATA703(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    string memory _data,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaChangeData",
                                                  _bountyId,
                                                  _issuerId,
                                                  _data,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);

    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.CHANGEDATA475(signer,
                _bountyId,
                _issuerId,
                _data);
  }

  function METACHANGEDEADLINE27(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    uint  _deadline,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaChangeDeadline",
                                                  _bountyId,
                                                  _issuerId,
                                                  _deadline,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);

    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.CHANGEDEADLINE144(signer,
                    _bountyId,
                    _issuerId,
                    _deadline);
  }

  function METAADDISSUERS741(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    address payable[] memory _issuers,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaAddIssuers",
                                                  _bountyId,
                                                  _issuerId,
                                                  _issuers,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);

    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.ADDISSUERS127(signer,
                _bountyId,
                _issuerId,
                _issuers);
  }

  function METAADDAPPROVERS523(
    bytes memory _signature,
    uint _bountyId,
    uint _issuerId,
    address[] memory _approvers,
    uint256 _nonce)
    public
    {
    bytes32 metaHash = keccak256(abi.encode(address(this),
                                                  "metaAddApprovers",
                                                  _bountyId,
                                                  _issuerId,
                                                  _approvers,
                                                  _nonce));
    address signer = GETSIGNER512(metaHash, _signature);

    require(signer != address(0));
    require(_nonce == replayNonce[signer]);


    replayNonce[signer]++;

    bountiesContract.ADDAPPROVERS15(signer,
                _bountyId,
                _issuerId,
                _approvers);
  }

  function GETSIGNER512(
    bytes32 _hash,
    bytes memory _signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;
    if (_signature.length != 65){
      return address(0);
    }
    assembly {
      r := mload(add(_signature, 32))
      s := mload(add(_signature, 64))
      v := byte(0, mload(add(_signature, 96)))
    }
    if (v < 27){
      v += 27;
    }
    if (v != 27 && v != 28){
      return address(0);
    } else {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), v, r, s );
    }
  }
}
