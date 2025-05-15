








































  function changeDependentContractAddress() public onlyInternal {
    cr = ClaimsReward(master.getLatestAddress("CR"));
    pool = Pool(master.getLatestAddress("P1"));
    pooledStaking = IPooledStaking(master.getLatestAddress("PS"));
    qd = QuotationData(master.getLatestAddress("QD"));
    tc = TokenController(master.getLatestAddress("TC"));
    td = TokenData(master.getLatestAddress("TD"));
    incidents = Incidents(master.getLatestAddress("IC"));
  }


  function sendEther() public payable {}






  function expireCover(uint coverId) external {

    uint expirationDate = qd.getValidityOfCover(coverId);
    require(expirationDate < now, "Quotation: cover is not due to expire");

    uint coverStatus = qd.getCoverStatusNo(coverId);
    require(coverStatus != uint(QuotationData.CoverStatus.CoverExpired), "Quotation: cover already expired");












































































  function makeCoverUsingNXMTokens(
    uint[] calldata coverDetails,
    uint16 coverPeriod,
    bytes4 coverCurr,
    address smartCAdd,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external onlyMember whenNotPaused {
    tc.burnFrom(msg.sender, coverDetails[2]);
    _verifyCoverDetails(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s, true);
  }






  function verifyCoverDetails(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] memory coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) public onlyInternal {
    _verifyCoverDetails(
      from,
      scAddress,
      coverCurr,
      coverDetails,
      coverPeriod,
      _v,
      _r,
      _s,
      false
    );
  }










  function verifySignature(
    uint[] memory coverDetails,
    uint16 coverPeriod,
    bytes4 currency,
    address contractAddress,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) public view returns (bool) {
    require(contractAddress != address(0));
    bytes32 hash = getOrderHash(coverDetails, coverPeriod, currency, contractAddress);
    return isValidSignature(hash, _v, _r, _s);
  }







  function getOrderHash(
    uint[] memory coverDetails,
    uint16 coverPeriod,
    bytes4 currency,
    address contractAddress
  ) public view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        coverDetails[0],
        currency,
        coverPeriod,
        contractAddress,
        coverDetails[1],
        coverDetails[2],
        coverDetails[3],
        coverDetails[4],
        address(this)
      )
    );
  }








  function isValidSignature(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
    address a = ecrecover(prefixedHash, v, r, s);
    return (a == qd.getAuthQuoteEngine());
  }






  function _makeCover(
    address payable from,
    address contractAddress,
    bytes4 coverCurrency,
    uint[] memory coverDetails,
    uint16 coverPeriod
  ) internal {

    address underlyingToken = incidents.underlyingToken(contractAddress);

    if (underlyingToken != address(0)) {
      address coverAsset = cr.getCurrencyAssetAddress(coverCurrency);
      require(coverAsset == underlyingToken, "Quotation: Unsupported cover asset for this product");
    }

    uint cid = qd.getCoverLength();

    qd.addCover(
      coverPeriod,
      coverDetails[0],
      from,
      coverCurrency,
      contractAddress,
      coverDetails[1],
      coverDetails[2]
    );


    if (underlyingToken == address(0)) {
      uint coverNoteAmount = coverDetails[2].mul(qd.tokensRetained()).div(100);
      uint gracePeriod = tc.claimSubmissionGracePeriod();
      uint claimSubmissionPeriod = uint(coverPeriod).mul(1 days).add(gracePeriod);
      bytes32 reason = keccak256(abi.encodePacked("CN", from, cid));

      td.setDepositCNAmount(cid, coverNoteAmount);
      tc.mintCoverNote(from, reason, coverNoteAmount, claimSubmissionPeriod);
    }

    qd.addInTotalSumAssured(coverCurrency, coverDetails[0]);
    qd.addInTotalSumAssuredSC(contractAddress, coverCurrency, coverDetails[0]);

    uint coverPremiumInNXM = coverDetails[2];
    uint stakersRewardPercentage = td.stakerCommissionPer();
    uint rewardValue = coverPremiumInNXM.mul(stakersRewardPercentage).div(100);
    pooledStaking.accumulateReward(contractAddress, rewardValue);
  }






  function _verifyCoverDetails(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] memory coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    bool isNXM
  ) internal {

    require(coverDetails[3] > now, "Quotation: Quote has expired");
    require(coverPeriod >= 30 && coverPeriod <= 365, "Quotation: Cover period out of bounds");
    require(!qd.timestampRepeated(coverDetails[4]), "Quotation: Quote already used");
    qd.setTimestampRepeated(coverDetails[4]);

    address asset = cr.getCurrencyAssetAddress(coverCurr);
    if (coverCurr != "ETH" && !isNXM) {
      pool.transferAssetFrom(asset, from, coverDetails[1]);
    }

    require(verifySignature(coverDetails, coverPeriod, coverCurr, scAddress, _v, _r, _s), "Quotation: signature mismatch");
    _makeCover(from, scAddress, coverCurr, coverDetails, coverPeriod);
  }

  function createCover(
    address payable from,
    address scAddress,
    bytes4 currency,
    uint[] calldata coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external onlyInternal {

    require(coverDetails[3] > now, "Quotation: Quote has expired");
    require(coverPeriod >= 30 && coverPeriod <= 365, "Quotation: Cover period out of bounds");
    require(!qd.timestampRepeated(coverDetails[4]), "Quotation: Quote already used");
    qd.setTimestampRepeated(coverDetails[4]);

    require(verifySignature(coverDetails, coverPeriod, currency, scAddress, _v, _r, _s), "Quotation: signature mismatch");
    _makeCover(from, scAddress, currency, coverDetails, coverPeriod);
  }



  function transferAssetsToNewContract(address) external pure {}

  function freeUpHeldCovers() external nonReentrant {

    IERC20 dai = IERC20(cr.getCurrencyAssetAddress("DAI"));
    uint membershipFee = td.joiningFee();
    uint lastCoverId = 106;

    for (uint id = 1; id <= lastCoverId; id++) {

      if (qd.holdedCoverIDStatus(id) != uint(QuotationData.HCIDStatus.kycPending)) {
        continue;
      }
























