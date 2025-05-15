

pragma solidity 0.5.0;
pragma experimental ABIEncoderV2;

import "./inherited/ERC20Token.sol";
import "./inherited/ERC721Basic.sol";




contract StandardBounties {





  struct Bounty {
    address payable [] issuers;
    address [] approvers;
    uint deadline;
    address token;
    uint tokenVersion;
    uint balance;
    bool hasPaidOut;
    Fulfillment [] fulfillments;
    Contribution [] contributions;
  }

  struct Fulfillment {
    address payable [] fulfillers;
    address submitter;
  }

  struct Contribution {
    address payable contributor;
    uint amount;
    bool refunded;
  }





  uint public numBounties;
  mapping(uint => Bounty) public bounties;

  address owner;
  address metaTxRelayer;






  modifier validateBountyArrayIndex(
    uint _index)
  {
    require(_index < numBounties);
    _;
  }

  modifier validateContributionArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].contributions.length);
    _;
  }

  modifier validateFulfillmentArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].fulfillments.length);
    _;
  }

  modifier validateIssuerArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].issuers.length || _index == 0);
    _;
  }

  modifier validateApproverArrayIndex(
    uint _bountyId,
    uint _index)
  {
    require(_index < bounties[_bountyId].approvers.length || _index == 0);
    _;
  }

  modifier onlyIssuer(
  address _sender,
  uint _bountyId,
  uint _issuerId)
  {
  require(_sender == bounties[_bountyId].issuers[_issuerId]);
  _;
  }

  modifier onlySubmitter(
    address _sender,
    uint _bountyId,
    uint _fulfillmentId)
  {
    require(_sender ==
            bounties[_bountyId].fulfillments[_fulfillmentId].submitter);
    _;
  }

  modifier onlyContributor(
  address _sender,
  uint _bountyId,
  uint _contributionId)
  {
    require(_sender ==
            bounties[_bountyId].contributions[_contributionId].contributor);
    _;
  }

  modifier isApprover(
    address _sender,
    uint _bountyId,
    uint _approverId)
  {
    require(_sender == bounties[_bountyId].approvers[_approverId]);
    _;
  }

  modifier hasNotPaid(
    uint _bountyId)
  {
    require(!bounties[_bountyId].hasPaidOut);
    _;
  }

  modifier hasNotRefunded(
    uint _bountyId,
    uint _contributionId)
  {
    require(!bounties[_bountyId].contributions[_contributionId].refunded);
    _;
  }

  modifier senderIsValid(
    address _sender)
  {
    require(msg.sender == _sender || msg.sender == metaTxRelayer);
    _;
  }





  constructor() public {

    owner = msg.sender;
  }



  function setMetaTxRelayer(address _relayer)
    public
  {
    require(msg.sender == owner);
    require(metaTxRelayer == address(0));
    metaTxRelayer = _relayer;
  }










  function issueBounty(
    address payable _sender,
    address payable [] memory _issuers,
    address [] memory _approvers,
    string memory _data,
    uint _deadline,
    address _token,
    uint _tokenVersion,
    uint _depositAmount)
    public
    payable
    senderIsValid(_sender)
    returns (uint)
  {
    require(_tokenVersion == 0 || _tokenVersion == 20 || _tokenVersion == 721);

    uint bountyId = numBounties;

    Bounty storage newBounty = bounties[bountyId];
    newBounty.issuers = _issuers;
    newBounty.approvers = _approvers;
    newBounty.deadline = _deadline;
    newBounty.token = _token;
    newBounty.tokenVersion = _tokenVersion;

    numBounties++;

    emit BountyIssued(bountyId,
    _sender,
    _issuers,
    _approvers,
    _data,
    _deadline,
    _token,
    _tokenVersion);


    if (_depositAmount > 0){
      contribute(_sender, bountyId, _depositAmount);
    }
    return (bountyId);
  }











  function contribute(
    address payable _sender,
    uint _bountyId,
    uint _amount)
    public
    payable
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
  {

    bounties[_bountyId].contributions.push(
      Contribution(_sender, _amount, false));

    bounties[_bountyId].balance += _amount;

    require(_amount > 0);

    if (bounties[_bountyId].tokenVersion == 0){
      require(msg.value == _amount);
    } else if (bounties[_bountyId].tokenVersion == 20) {
      require(msg.value == 0);
      require(ERC20Token(bounties[_bountyId].token).transferFrom(_sender,
                                                                 address(this),
                                                                 _amount));
    } else if (bounties[_bountyId].tokenVersion == 721) {
      require(msg.value == 0);
      ERC721BasicToken(bounties[_bountyId].token).transferFrom(_sender,
                                                               address(this),
                                                               _amount);
    }

    emit ContributionAdded(_bountyId,
                           bounties[_bountyId].contributions.length - 1,
                           _sender,
                           _amount);
  }







  function refundContribution(
    address _sender,
    uint _bountyId,
    uint _contributionId)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateContributionArrayIndex(_bountyId, _contributionId)
    onlyContributor(_sender, _bountyId, _contributionId)
    hasNotPaid(_bountyId)
    hasNotRefunded(_bountyId, _contributionId)
  {
    require(now > bounties[_bountyId].deadline);

    Contribution storage contribution =
      bounties[_bountyId].contributions[_contributionId];

    contribution.refunded = true;
    bounties[_bountyId].balance -= contribution.amount;

    transferTokens(_bountyId, contribution.contributor, contribution.amount);

    emit ContributionRefunded(_bountyId, _contributionId);
  }





  function refundContributions(
    address _sender,
    uint _bountyId,
    uint [] memory _contributionIds)
    public
    senderIsValid(_sender)
  {
    for (uint i = 0; i < _contributionIds.length; i++){
      refundContribution(_sender, _bountyId, _contributionIds[i]);
    }
  }






  function performAction(
    address _sender,
    uint _bountyId,
    string memory _data)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
  {
    emit ActionPerformed(_bountyId, _sender, _data);
  }






  function fulfillBounty(
    address _sender,
    uint _bountyId,
    address payable [] memory  _fulfillers,
    string memory _data)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
  {
    require(now < bounties[_bountyId].deadline);
    require(_fulfillers.length > 0);

    bounties[_bountyId].fulfillments.push(Fulfillment(_fulfillers, _sender));

    emit BountyFulfilled(_bountyId,
                         (bounties[_bountyId].fulfillments.length - 1),
                         _fulfillers,
                         _data,
                         _sender);
  }







  function updateFulfillment(
  address _sender,
  uint _bountyId,
  uint _fulfillmentId,
  address payable [] memory _fulfillers,
  string memory _data)
  public
  senderIsValid(_sender)
  validateBountyArrayIndex(_bountyId)
  validateFulfillmentArrayIndex(_bountyId, _fulfillmentId)
  onlySubmitter(_sender, _bountyId, _fulfillmentId)
  {
    bounties[_bountyId].fulfillments[_bountyId].fulfillers = _fulfillers;
    emit FulfillmentUpdated(_bountyId,
                            _fulfillmentId,
                            _fulfillers,
                            _data);
  }











  function acceptFulfillment(
    address _sender,
    uint _bountyId,
    uint _fulfillmentId,
    uint _approverId,
    uint[] memory _tokenAmounts)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateFulfillmentArrayIndex(_bountyId, _fulfillmentId)
    isApprover(_sender, _bountyId, _approverId)
  {

    bounties[_bountyId].hasPaidOut = true;

    Fulfillment storage fulfillment =
      bounties[_bountyId].fulfillments[_fulfillmentId];

    require(_tokenAmounts.length == fulfillment.fulfillers.length);

    for (uint256 i = 0; i < fulfillment.fulfillers.length; i++){

      require(bounties[_bountyId].balance >= _tokenAmounts[i]);

      bounties[_bountyId].balance -= _tokenAmounts[i];

      if (_tokenAmounts[i] != 0){
        transferTokens(_bountyId, fulfillment.fulfillers[i], _tokenAmounts[i]);
      }
    }
    emit FulfillmentAccepted(_bountyId,
                             _fulfillmentId,
                             _sender,
                             _tokenAmounts);
  }












  function fulfillAndAccept(
    address _sender,
    uint _bountyId,
    address payable [] memory _fulfillers,
    string memory _data,
    uint _approverId,
    uint[] memory _tokenAmounts)
    public
    senderIsValid(_sender)
  {

    fulfillBounty(_sender, _bountyId, _fulfillers, _data);


    acceptFulfillment(_sender,
                      _bountyId,
                      bounties[_bountyId].fulfillments.length - 1,
                      _approverId,
                      _tokenAmounts);
  }











  function changeBounty(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _issuers,
    address payable [] memory _approvers,
    string memory _data,
    uint _deadline)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    bounties[_bountyId].issuers = _issuers;
    bounties[_bountyId].approvers = _approvers;
    bounties[_bountyId].deadline = _deadline;
    emit BountyChanged(_bountyId,
                       _sender,
                       _issuers,
                       _approvers,
                       _data,
                       _deadline);
  }







  function changeIssuer(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _issuerIdToChange,
    address payable _newIssuer)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    validateIssuerArrayIndex(_bountyId, _issuerIdToChange)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    bounties[_bountyId].issuers[_issuerIdToChange] = _newIssuer;

    emit BountyIssuerChanged(_bountyId, _sender, _issuerId, _newIssuer);
  }







  function changeApprover(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _approverId,
    address payable _approver)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
    validateApproverArrayIndex(_bountyId, _approverId)
  {
    bounties[_bountyId].approvers[_approverId] = _approver;

    emit BountyApproverChanged(_bountyId,
              msg.sender,
              _approverId,
              _approver);
  }






  function changeData(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    string memory _data)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    emit BountyDataChanged(_bountyId, msg.sender, _data);
  }






  function changeDeadline(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    uint _deadline)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    bounties[_bountyId].deadline = _deadline;

    emit BountyDeadlineChanged(_bountyId, _sender, _deadline);
  }






  function addIssuers(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _issuers)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    for (uint i = 0; i < _issuers.length; i++){
      bounties[_bountyId].issuers.push(_issuers[i]);
    }
    emit BountyIssuersAdded(_bountyId, _sender, _issuers);
  }






  function replaceIssuers(
    address _sender,
    uint _bountyId,
    uint _issuerId,
    address payable [] memory _issuers)
    public
    senderIsValid(_sender)
    validateBountyArrayIndex(_bountyId)
    validateIssuerArrayIndex(_bountyId, _issuerId)
    onlyIssuer(_sender, _bountyId, _issuerId)
  {
    bounties[_bountyId].issuers = _issuers;

    emit BountyIssuersReplaced(_bountyId, _sender, _issuers);
  }






  function addApprovers(
  address _sender,
  uint _bountyId,
  uint _issuerId,
  address [] memory _approvers)
  public
  senderIsValid(_sender)
  validateBountyArrayIndex(_bountyId)
  validateIssuerArrayIndex(_bountyId, _issuerId)
  onlyIssuer(_sender, _bountyId, _issuerId)
  {
    for (uint i = 0; i < _approvers.length; i++){
      bounties[_bountyId].approvers.push(_approvers[i]);
    }
    emit BountyApproversAdded(_bountyId, _sender, _approvers);
  }






  function replaceApprovers(
  address _sender,
  uint _bountyId,
  uint _issuerId,
  address [] memory _approvers)
  public
  senderIsValid(_sender)
  validateBountyArrayIndex(_bountyId)
  validateIssuerArrayIndex(_bountyId, _issuerId)
  onlyIssuer(_sender, _bountyId, _issuerId)
  {
    bounties[_bountyId].approvers = _approvers;

    emit BountyApproversReplaced(_bountyId, _sender, _approvers);
  }




  function getBounty(uint _bountyId)
    public
    view
    returns (Bounty memory)
  {
    return bounties[_bountyId];
  }


  function transferTokens(uint _bountyId, address payable _to, uint _amount)
    internal
  {
    if (bounties[_bountyId].tokenVersion == 0){
      _to.transfer(_amount);
    } else if (bounties[_bountyId].tokenVersion == 20) {
      require(ERC20Token(bounties[_bountyId].token).transfer(_to, _amount));
    } else if (bounties[_bountyId].tokenVersion == 721) {
      ERC721BasicToken(bounties[_bountyId].token).safeTransferFrom(address(this),
                                                                   _to,
                                                                   _amount);
    } else {
      revert();
    }
  }





  event BountyIssued(uint _bountyId, address payable _creator, address payable [] _issuers, address [] _approvers, string _data, uint _deadline, address _token, uint _tokenVersion);
  event ContributionAdded(uint _bountyId, uint _contributionId, address payable _contributor, uint _amount);
  event ContributionRefunded(uint _bountyId, uint _contributionId);
  event ActionPerformed(uint _bountyId, address _fulfiller, string _data);
  event BountyFulfilled(uint _bountyId, uint _fulfillmentId, address payable [] _fulfillers, string _data, address _submitter);
  event FulfillmentUpdated(uint _bountyId, uint _fulfillmentId, address payable [] _fulfillers, string _data);
  event FulfillmentAccepted(uint _bountyId, uint  _fulfillmentId, address _approver, uint[] _tokenAmounts);
  event BountyChanged(uint _bountyId, address _changer, address payable [] _issuers, address payable [] _approvers, string _data, uint _deadline);
  event BountyIssuerChanged(uint _bountyId, address _changer, uint _issuerId, address payable _issuer);
  event BountyIssuersAdded(uint _bountyId, address _changer, address payable [] _issuers);
  event BountyIssuersReplaced(uint _bountyId, address _changer, address payable [] _issuers);
  event BountyApproverChanged(uint _bountyId, address payable _changer, uint _approverId, address payable _approver);
  event BountyApproversAdded(uint _bountyId, address _changer, address [] _approvers);
  event BountyApproversReplaced(uint _bountyId, address _changer, address [] _approvers);
  event BountyDataChanged(uint _bountyId, address _changer, string _data);
  event BountyDeadlineChanged(uint _bountyId, address _changer, uint _deadline);
}
