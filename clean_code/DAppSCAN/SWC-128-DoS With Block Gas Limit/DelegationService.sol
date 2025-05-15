


















pragma solidity ^0.5.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";

import "../Permissions.sol";
import "../interfaces/delegation/IHolderDelegation.sol";
import "../interfaces/delegation/IValidatorDelegation.sol";
import "./DelegationRequestManager.sol";
import "./ValidatorService.sol";
import "./DelegationController.sol";
import "./Distributor.sol";
import "./SkaleBalances.sol";
import "./TokenState.sol";
import "./TimeHelpers.sol";


contract DelegationService is Permissions, IHolderDelegation, IValidatorDelegation, IERC777Recipient {

    event DelegationRequestIsSent(
        uint delegationId
    );

    event ValidatorRegistered(
        uint validatorId
    );

    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    uint private _launchTimestamp;

    constructor(address newContractsAddress) Permissions(newContractsAddress) public {
        _launchTimestamp = now;
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }

    function requestUndelegation(uint delegationId) external {
        TokenState tokenState = TokenState(contractManager.getContract("TokenState"));
        DelegationController delegationController = DelegationController(contractManager.getContract("DelegationController"));

        require(
            delegationController.getDelegation(delegationId).holder == msg.sender,
            "Can't request undelegation because sender is not a holder");

        tokenState.requestUndelegation(delegationId);
    }


    function acceptPendingDelegation(uint delegationId) external {
        DelegationRequestManager delegationRequestManager = DelegationRequestManager(
            contractManager.getContract("DelegationRequestManager")
        );
        delegationRequestManager.acceptRequest(delegationId, msg.sender);
    }

    function getDelegationsByHolder(TokenState.State state) external returns (uint[] memory) {
        DelegationController delegationController = DelegationController(contractManager.getContract("DelegationController"));
        return delegationController.getDelegationsByHolder(msg.sender, state);
    }

    function getDelegationsForValidator(TokenState.State state) external returns (uint[] memory) {
        DelegationController delegationController = DelegationController(contractManager.getContract("DelegationController"));
        return delegationController.getDelegationsForValidator(msg.sender, state);
    }

    function setMinimumDelegationAmount(uint amount) external {
        revert("Not implemented");
    }


    function listDelegationRequests() external returns (uint[] memory) {
        revert("Not implemented");
    }


    function slash(uint validatorId, uint amount) external allow("SkaleDKG") {
        ValidatorService validatorService = ValidatorService(contractManager.getContract("ValidatorService"));
        require(validatorService.validatorExists(validatorId), "Validator does not exist");

        Distributor distributor = Distributor(contractManager.getContract("Distributor"));
        TokenState tokenState = TokenState(contractManager.getContract("TokenState"));

        Distributor.Share[] memory shares = distributor.distributePenalties(validatorId, amount);
        for (uint i = 0; i < shares.length; ++i) {
            tokenState.slash(shares[i].delegationId, shares[i].amount);
        }
    }

    function forgive(address wallet, uint amount) external onlyOwner() {
        TokenState tokenState = TokenState(contractManager.getContract("TokenState"));
        tokenState.forgive(wallet, amount);
    }


    function getDelegatedAmount(uint validatorId) external returns (uint) {
        DelegationController delegationController = DelegationController(contractManager.getContract("DelegationController"));
        return delegationController.getDelegationsTotal(validatorId);
    }

    function setMinimumStakingRequirement(uint amount) external onlyOwner() {
        revert("Not implemented");
    }


    function delegate(
        uint validatorId,
        uint amount,
        uint delegationPeriod,
        string calldata info
    )
        external
    {
        DelegationRequestManager delegationRequestManager = DelegationRequestManager(
            contractManager.getContract("DelegationRequestManager")
        );
        uint delegationId = delegationRequestManager.createRequest(
            msg.sender,
            validatorId,
            amount,
            delegationPeriod,
            info
        );
        emit DelegationRequestIsSent(delegationId);
    }

    function cancelPendingDelegation(uint delegationId) external {
        DelegationRequestManager delegationRequestManager = DelegationRequestManager(
            contractManager.getContract("DelegationRequestManager")
        );
        delegationRequestManager.cancelRequest(delegationId, msg.sender);
    }

    function getAllDelegationRequests() external returns(uint[] memory) {
        revert("Not implemented");
    }

    function getDelegationRequestsForValidator(uint validatorId) external returns (uint[] memory) {
        revert("Not implemented");
    }


    function registerValidator(
        string calldata name,
        string calldata description,
        uint feeRate,
        uint minimumDelegationAmount
    )
        external returns (uint validatorId)
    {
        ValidatorService validatorService = ValidatorService(contractManager.getContract("ValidatorService"));
        validatorId = validatorService.registerValidator(
            name,
            msg.sender,
            description,
            feeRate,
            minimumDelegationAmount
        );
        emit ValidatorRegistered(validatorId);
    }

    function linkNodeAddress(address nodeAddress) external {
        ValidatorService validatorService = ValidatorService(contractManager.getContract("ValidatorService"));
        validatorService.linkNodeAddress(msg.sender, nodeAddress);
    }

    function unlinkNodeAddress(address nodeAddress) external {
        ValidatorService validatorService = ValidatorService(contractManager.getContract("ValidatorService"));
        validatorService.unlinkNodeAddress(msg.sender, nodeAddress);
    }

    function unregisterValidator(uint validatorId) external {
        revert("Not implemented");
    }


    function getBondAmount(uint validatorId) external returns (uint amount) {
        revert("Not implemented");
    }

    function setValidatorName(string calldata newName) external {
        revert("Not implemented");
    }

    function setValidatorDescription(string calldata description) external {
        revert("Not implemented");
    }

    function requestForNewAddress(address newAddress) external {
        ValidatorService(contractManager.getContract("ValidatorService")).requestForNewAddress(msg.sender, newAddress);
    }

    function confirmNewAddress(uint validatorId) external {
        ValidatorService validatorService = ValidatorService(contractManager.getContract("ValidatorService"));
        ValidatorService.Validator memory validator = validatorService.getValidator(validatorId);

        require(
            validator.requestedAddress == msg.sender,
            "The validator cannot be changed because it isn't the actual owner"
        );

        validatorService.confirmNewAddress(msg.sender, validatorId);
    }

    function getValidators() external view returns (uint[] memory validatorIds) {
        ValidatorService validatorService = ValidatorService(contractManager.getContract("ValidatorService"));
        validatorIds = new uint[](validatorService.numberOfValidators());
        for (uint i = 0; i < validatorIds.length; ++i) {
            validatorIds[i] = i + 1;
        }
    }

    function withdrawBounty(address bountyCollectionAddress, uint amount) external {
        SkaleBalances skaleBalances = SkaleBalances(contractManager.getContract("SkaleBalances"));
        skaleBalances.withdrawBalance(msg.sender, bountyCollectionAddress, amount);
    }

    function getEarnedBountyAmount() external returns (uint) {
        SkaleBalances skaleBalances = SkaleBalances(contractManager.getContract("SkaleBalances"));
        return skaleBalances.getBalance(msg.sender);
    }


    function deleteNode(uint nodeIndex) external {
        revert("Not implemented");
    }


    function lock(address wallet, uint amount) external allow("TokenSaleManager") {
        SkaleToken skaleToken = SkaleToken(contractManager.getContract("SkaleToken"));
        TokenState tokenState = TokenState(contractManager.getContract("TokenState"));

        require(skaleToken.balanceOf(wallet) >= tokenState.getPurchasedAmount(wallet) + amount, "Not enough founds");

        tokenState.sold(wallet, amount);
    }

    function getLockedOf(address wallet) external returns (uint) {
        TokenState tokenState = TokenState(contractManager.getContract("TokenState"));
        return tokenState.getLockedCount(wallet);
    }

    function getDelegatedOf(address wallet) external returns (uint) {
        TokenState tokenState = TokenState(contractManager.getContract("TokenState"));
        return tokenState.getDelegatedCount(wallet);
    }

    function getSlashedOf(address wallet) external returns (uint) {
        TokenState tokenState = TokenState(contractManager.getContract("TokenState"));
        return tokenState.getSlashedAmount(wallet);
    }

    function setLaunchTimestamp(uint timestamp) external onlyOwner {
        _launchTimestamp = timestamp;
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    )
        external
        allow("SkaleToken")
    {
        require(userData.length == 32, "Data length is incorrect");
        uint validatorId = abi.decode(userData, (uint));
        distributeBounty(amount, validatorId);
    }



    function distributeBounty(uint amount, uint validatorId) internal {
        ValidatorService validatorService = ValidatorService(contractManager.getContract("ValidatorService"));

        SkaleToken skaleToken = SkaleToken(contractManager.getContract("SkaleToken"));
        Distributor distributor = Distributor(contractManager.getContract("Distributor"));
        SkaleBalances skaleBalances = SkaleBalances(contractManager.getContract("SkaleBalances"));
        TimeHelpers timeHelpers = TimeHelpers(contractManager.getContract("TimeHelpers"));
        DelegationController delegationController = DelegationController(contractManager.getContract("DelegationController"));

        Distributor.Share[] memory shares;
        uint fee;
        (shares, fee) = distributor.distributeBounty(validatorId, amount);

        address validatorAddress = validatorService.getValidator(validatorId).validatorAddress;
        skaleToken.send(address(skaleBalances), fee, abi.encode(validatorAddress));
        skaleBalances.lockBounty(validatorAddress, timeHelpers.addMonths(_launchTimestamp, 3));

        for (uint i = 0; i < shares.length; ++i) {
            skaleToken.send(address(skaleBalances), shares[i].amount, abi.encode(shares[i].holder));

            uint created = delegationController.getDelegation(shares[i].delegationId).created;
            uint delegationStarted = timeHelpers.getNextMonthStartFromDate(created);
            skaleBalances.lockBounty(shares[i].holder, timeHelpers.addMonths(delegationStarted, 3));
        }
    }
}
