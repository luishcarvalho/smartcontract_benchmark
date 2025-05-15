


































contract Lido is ILido, IsContract, StETH, AragonApp {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using UnstructuredStorage for bytes32;


    bytes32 constant public PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 constant public MANAGE_FEE = keccak256("MANAGE_FEE");
    bytes32 constant public MANAGE_WITHDRAWAL_KEY = keccak256("MANAGE_WITHDRAWAL_KEY");
    bytes32 constant public SET_ORACLE = keccak256("SET_ORACLE");
    bytes32 constant public BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 constant public SET_TREASURY = keccak256("SET_TREASURY");
    bytes32 constant public SET_INSURANCE_FUND = keccak256("SET_INSURANCE_FUND");
    bytes32 constant public DEPOSIT_ROLE = keccak256("DEPOSIT_ROLE");

    uint256 constant public PUBKEY_LENGTH = 48;
    uint256 constant public WITHDRAWAL_CREDENTIALS_LENGTH = 32;
    uint256 constant public SIGNATURE_LENGTH = 96;

    uint256 constant public DEPOSIT_SIZE = 32 ether;

    uint256 internal constant DEPOSIT_AMOUNT_UNIT = 1000000000 wei;


    uint256 internal constant DEFAULT_MAX_DEPOSITS_PER_CALL = 150;

    bytes32 internal constant FEE_POSITION = keccak256("lido.Lido.fee");
    bytes32 internal constant TREASURY_FEE_POSITION = keccak256("lido.Lido.treasuryFee");
    bytes32 internal constant INSURANCE_FEE_POSITION = keccak256("lido.Lido.insuranceFee");
    bytes32 internal constant NODE_OPERATORS_FEE_POSITION = keccak256("lido.Lido.nodeOperatorsFee");

    bytes32 internal constant DEPOSIT_CONTRACT_POSITION = keccak256("lido.Lido.depositContract");
    bytes32 internal constant ORACLE_POSITION = keccak256("lido.Lido.oracle");
    bytes32 internal constant NODE_OPERATORS_REGISTRY_POSITION = keccak256("lido.Lido.nodeOperatorsRegistry");
    bytes32 internal constant TREASURY_POSITION = keccak256("lido.Lido.treasury");
    bytes32 internal constant INSURANCE_FUND_POSITION = keccak256("lido.Lido.insuranceFund");


    bytes32 internal constant BUFFERED_ETHER_POSITION = keccak256("lido.Lido.bufferedEther");

    bytes32 internal constant DEPOSITED_VALIDATORS_POSITION = keccak256("lido.Lido.depositedValidators");

    bytes32 internal constant BEACON_BALANCE_POSITION = keccak256("lido.Lido.beaconBalance");

    bytes32 internal constant BEACON_VALIDATORS_POSITION = keccak256("lido.Lido.beaconValidators");


    bytes32 internal constant WITHDRAWAL_CREDENTIALS_POSITION = keccak256("lido.Lido.withdrawalCredentials");







    function initialize(
        IDepositContract depositContract,
        address _oracle,
        INodeOperatorsRegistry _operators,
        address _treasury,
        address _insuranceFund
    )
        public onlyInit
    {
        _setDepositContract(depositContract);
        _setOracle(_oracle);
        _setOperators(_operators);
        _setTreasury(_treasury);
        _setInsuranceFund(_insuranceFund);

        initialized();
    }








    function() external payable {

        require(msg.data.length == 0, "NON_EMPTY_DATA");
        _submit(0);
    }






    function submit(address _referral) external payable returns (uint256) {
        return _submit(_referral);
    }





    function depositBufferedEther() external auth(DEPOSIT_ROLE) {
        return _depositBufferedEther(DEFAULT_MAX_DEPOSITS_PER_CALL);
    }





    function depositBufferedEther(uint256 _maxDeposits) external auth(DEPOSIT_ROLE) {
        return _depositBufferedEther(_maxDeposits);
    }

    function burnShares(address _account, uint256 _sharesAmount)
        external
        authP(BURN_ROLE, arr(_account, _sharesAmount))
        returns (uint256 newTotalShares)
    {
        return _burnShares(_account, _sharesAmount);
    }




    function stop() external auth(PAUSE_ROLE) {
        _stop();
    }




    function resume() external auth(PAUSE_ROLE) {
        _resume();
    }





    function setFee(uint16 _feeBasisPoints) external auth(MANAGE_FEE) {
        _setBPValue(FEE_POSITION, _feeBasisPoints);
        emit FeeSet(_feeBasisPoints);
    }




    function setFeeDistribution(
        uint16 _treasuryFeeBasisPoints,
        uint16 _insuranceFeeBasisPoints,
        uint16 _operatorsFeeBasisPoints
    )
        external auth(MANAGE_FEE)
    {
        require(
            10000 == uint256(_treasuryFeeBasisPoints)
            .add(uint256(_insuranceFeeBasisPoints))
            .add(uint256(_operatorsFeeBasisPoints)),
            "FEES_DONT_ADD_UP"
        );

        _setBPValue(TREASURY_FEE_POSITION, _treasuryFeeBasisPoints);
        _setBPValue(INSURANCE_FEE_POSITION, _insuranceFeeBasisPoints);
        _setBPValue(NODE_OPERATORS_FEE_POSITION, _operatorsFeeBasisPoints);

        emit FeeDistributionSet(_treasuryFeeBasisPoints, _insuranceFeeBasisPoints, _operatorsFeeBasisPoints);
    }







    function setOracle(address _oracle) external auth(SET_ORACLE) {
        _setOracle(_oracle);
    }






    function setTreasury(address _treasury) external auth(SET_TREASURY) {
        _setTreasury(_treasury);
    }






    function setInsuranceFund(address _insuranceFund) external auth(SET_INSURANCE_FUND) {
        _setInsuranceFund(_insuranceFund);
    }







    function setWithdrawalCredentials(bytes32 _withdrawalCredentials) external auth(MANAGE_WITHDRAWAL_KEY) {
        WITHDRAWAL_CREDENTIALS_POSITION.setStorageBytes32(_withdrawalCredentials);
        getOperators().trimUnusedKeys();

        emit WithdrawalCredentialsSet(_withdrawalCredentials);
    }


















    function pushBeacon(uint256 _beaconValidators, uint256 _beaconBalance) external whenNotStopped {
        require(msg.sender == getOracle(), "APP_AUTH_FAILED");

        uint256 depositedValidators = DEPOSITED_VALIDATORS_POSITION.getStorageUint256();
        require(_beaconValidators <= depositedValidators, "REPORTED_MORE_DEPOSITED");

        uint256 beaconValidators = BEACON_VALIDATORS_POSITION.getStorageUint256();




        require(_beaconValidators >= beaconValidators, "REPORTED_LESS_VALIDATORS");
        uint256 appearedValidators = _beaconValidators.sub(beaconValidators);



        uint256 rewardBase = (appearedValidators.mul(DEPOSIT_SIZE)).add(BEACON_BALANCE_POSITION.getStorageUint256());



        BEACON_BALANCE_POSITION.setStorageUint256(_beaconBalance);
        BEACON_VALIDATORS_POSITION.setStorageUint256(_beaconValidators);

        if (_beaconBalance > rewardBase) {
            uint256 rewards = _beaconBalance.sub(rewardBase);
            distributeRewards(rewards);
        }
    }





    function transferToVault(address _token) external {
        require(allowRecoverability(_token), "RECOVER_DISALLOWED");
        address vault = getRecoveryVault();
        require(isContract(vault), "RECOVER_VAULT_NOT_CONTRACT");

        uint256 balance;
        if (_token == ETH) {
            balance = _getUnaccountedEther();

            vault.transfer(balance);
        } else {
            ERC20 token = ERC20(_token);
            balance = token.staticBalanceOf(this);

            require(token.safeTransfer(vault, balance), "RECOVER_TOKEN_TRANSFER_FAILED");
        }

        emit RecoverToVault(vault, _token, balance);
    }




    function getFee() external view returns (uint16 feeBasisPoints) {
        return _getFee();
    }




    function getFeeDistribution()
        external
        view
        returns (
            uint16 treasuryFeeBasisPoints,
            uint16 insuranceFeeBasisPoints,
            uint16 operatorsFeeBasisPoints
        )
    {
        return _getFeeDistribution();
    }




    function getWithdrawalCredentials() public view returns (bytes32) {
        return WITHDRAWAL_CREDENTIALS_POSITION.getStorageBytes32();
    }







    function getBufferedEther() external view returns (uint256) {
        return _getBufferedEther();
    }




    function getDepositContract() public view returns (IDepositContract) {
        return IDepositContract(DEPOSIT_CONTRACT_POSITION.getStorageAddress());
    }





    function getOracle() public view returns (address) {
        return ORACLE_POSITION.getStorageAddress();
    }




    function getOperators() public view returns (INodeOperatorsRegistry) {
        return INodeOperatorsRegistry(NODE_OPERATORS_REGISTRY_POSITION.getStorageAddress());
    }




    function getTreasury() public view returns (address) {
        return TREASURY_POSITION.getStorageAddress();
    }




    function getInsuranceFund() public view returns (address) {
        return INSURANCE_FUND_POSITION.getStorageAddress();
    }







    function getBeaconStat() public view returns (uint256 depositedValidators, uint256 beaconValidators, uint256 beaconBalance) {
        depositedValidators = DEPOSITED_VALIDATORS_POSITION.getStorageUint256();
        beaconValidators = BEACON_VALIDATORS_POSITION.getStorageUint256();
        beaconBalance = BEACON_BALANCE_POSITION.getStorageUint256();
    }





    function _setDepositContract(IDepositContract _contract) internal {
        require(isContract(address(_contract)), "NOT_A_CONTRACT");
        DEPOSIT_CONTRACT_POSITION.setStorageAddress(address(_contract));
    }





    function _setOracle(address _oracle) internal {
        require(isContract(_oracle), "NOT_A_CONTRACT");
        ORACLE_POSITION.setStorageAddress(_oracle);
    }





    function _setOperators(INodeOperatorsRegistry _r) internal {
        require(isContract(_r), "NOT_A_CONTRACT");
        NODE_OPERATORS_REGISTRY_POSITION.setStorageAddress(_r);
    }

    function _setTreasury(address _treasury) internal {
        require(_treasury != address(0), "SET_TREASURY_ZERO_ADDRESS");
        TREASURY_POSITION.setStorageAddress(_treasury);
    }

    function _setInsuranceFund(address _insuranceFund) internal {
        require(_insuranceFund != address(0), "SET_INSURANCE_FUND_ZERO_ADDRESS");
        INSURANCE_FUND_POSITION.setStorageAddress(_insuranceFund);
    }






    function _submit(address _referral) internal whenNotStopped returns (uint256) {
        address sender = msg.sender;
        uint256 deposit = msg.value;
        require(deposit != 0, "ZERO_DEPOSIT");

        uint256 sharesAmount = getSharesByPooledEth(deposit);
        if (sharesAmount == 0) {


            sharesAmount = deposit;
        }

        _mintShares(sender, sharesAmount);
        _submitted(sender, deposit, _referral);
        _emitTransferAfterMintingShares(sender, sharesAmount);
        return sharesAmount;
    }




    function _emitTransferAfterMintingShares(address _to, uint256 _sharesAmount) internal {
        emit Transfer(address(0), _to, getPooledEthByShares(_sharesAmount));
    }




    function _depositBufferedEther(uint256 _maxDeposits) internal whenNotStopped {
        uint256 buffered = _getBufferedEther();
        if (buffered >= DEPOSIT_SIZE) {
            uint256 unaccounted = _getUnaccountedEther();
            uint256 numDeposits = buffered.div(DEPOSIT_SIZE);
            _markAsUnbuffered(_ETH2Deposit(numDeposits < _maxDeposits ? numDeposits : _maxDeposits));
            assert(_getUnaccountedEther() == unaccounted);
        }
    }






    function _ETH2Deposit(uint256 _numDeposits) internal returns (uint256) {
        (bytes memory pubkeys, bytes memory signatures) = getOperators().assignNextSigningKeys(_numDeposits);

        if (pubkeys.length == 0) {
            return 0;
        }

        require(pubkeys.length.mod(PUBKEY_LENGTH) == 0, "REGISTRY_INCONSISTENT_PUBKEYS_LEN");
        require(signatures.length.mod(SIGNATURE_LENGTH) == 0, "REGISTRY_INCONSISTENT_SIG_LEN");

        uint256 numKeys = pubkeys.length.div(PUBKEY_LENGTH);
        require(numKeys == signatures.length.div(SIGNATURE_LENGTH), "REGISTRY_INCONSISTENT_SIG_COUNT");

        for (uint256 i = 0; i < numKeys; ++i) {
            bytes memory pubkey = BytesLib.slice(pubkeys, i * PUBKEY_LENGTH, PUBKEY_LENGTH);
            bytes memory signature = BytesLib.slice(signatures, i * SIGNATURE_LENGTH, SIGNATURE_LENGTH);
            _stake(pubkey, signature);
        }

        DEPOSITED_VALIDATORS_POSITION.setStorageUint256(
            DEPOSITED_VALIDATORS_POSITION.getStorageUint256().add(numKeys)
        );

        return numKeys.mul(DEPOSIT_SIZE);
    }






    function _stake(bytes memory _pubkey, bytes memory _signature) internal {
        bytes32 withdrawalCredentials = getWithdrawalCredentials();
        require(withdrawalCredentials != 0, "EMPTY_WITHDRAWAL_CREDENTIALS");

        uint256 value = DEPOSIT_SIZE;


        uint256 depositAmount = value.div(DEPOSIT_AMOUNT_UNIT);
        assert(depositAmount.mul(DEPOSIT_AMOUNT_UNIT) == value);


        bytes32 pubkeyRoot = sha256(_pad64(_pubkey));
        bytes32 signatureRoot = sha256(
            abi.encodePacked(
                sha256(BytesLib.slice(_signature, 0, 64)),
                sha256(_pad64(BytesLib.slice(_signature, 64, SIGNATURE_LENGTH.sub(64))))
            )
        );

        bytes32 depositDataRoot = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(pubkeyRoot, withdrawalCredentials)),
                sha256(abi.encodePacked(_toLittleEndian64(depositAmount), signatureRoot))
            )
        );

        uint256 targetBalance = address(this).balance.sub(value);

        getDepositContract().deposit.value(value)(
            _pubkey, abi.encodePacked(withdrawalCredentials), _signature, depositDataRoot);
        require(address(this).balance == targetBalance, "EXPECTING_DEPOSIT_TO_HAPPEN");
    }





    function distributeRewards(uint256 _totalRewards) internal {

























        uint256 feeBasis = _getFee();
        uint256 shares2mint = (
            _totalRewards.mul(feeBasis).mul(_getTotalShares())
            .div(
                _getTotalPooledEther().mul(10000)
                .sub(feeBasis.mul(_totalRewards))
            )
        );



        _mintShares(address(this), shares2mint);

        (,uint16 insuranceFeeBasisPoints, uint16 operatorsFeeBasisPoints) = _getFeeDistribution();

        uint256 toInsuranceFund = shares2mint.mul(insuranceFeeBasisPoints).div(10000);
        address insuranceFund = getInsuranceFund();
        _transferShares(address(this), insuranceFund, toInsuranceFund);
        _emitTransferAfterMintingShares(insuranceFund, toInsuranceFund);

        uint256 distributedToOperatorsShares = _distributeNodeOperatorsReward(
            shares2mint.mul(operatorsFeeBasisPoints).div(10000)
        );


        uint256 toTreasury = shares2mint.sub(toInsuranceFund).sub(distributedToOperatorsShares);

        address treasury = getTreasury();
        _transferShares(address(this), treasury, toTreasury);
        _emitTransferAfterMintingShares(treasury, toTreasury);
    }

    function _distributeNodeOperatorsReward(uint256 _sharesToDistribute) internal returns (uint256 distributed) {
        (address[] memory recipients, uint256[] memory shares) = getOperators().getRewardsDistribution(_sharesToDistribute);

        assert(recipients.length == shares.length);

        distributed = 0;

        for (uint256 idx = 0; idx < recipients.length; ++idx) {
            _transferShares(
                address(this),
                recipients[idx],
                shares[idx]
            );
            _emitTransferAfterMintingShares(recipients[idx], shares[idx]);
            distributed = distributed.add(shares[idx]);
        }
    }







    function _submitted(address _sender, uint256 _value, address _referral) internal {
        BUFFERED_ETHER_POSITION.setStorageUint256(_getBufferedEther().add(_value));

        emit Submitted(_sender, _value, _referral);
    }





    function _markAsUnbuffered(uint256 _amount) internal {
        BUFFERED_ETHER_POSITION.setStorageUint256(
            BUFFERED_ETHER_POSITION.getStorageUint256().sub(_amount));

        emit Unbuffered(_amount);
    }




    function _setBPValue(bytes32 _slot, uint16 _value) internal {
        require(_value <= 10000, "VALUE_OVER_100_PERCENT");
        _slot.setStorageUint256(uint256(_value));
    }




    function _getFee() internal view returns (uint16) {
        return _readBPValue(FEE_POSITION);
    }




    function _getFeeDistribution() internal view
        returns (uint16 treasuryFeeBasisPoints, uint16 insuranceFeeBasisPoints, uint16 operatorsFeeBasisPoints)
    {
        treasuryFeeBasisPoints = _readBPValue(TREASURY_FEE_POSITION);
        insuranceFeeBasisPoints = _readBPValue(INSURANCE_FEE_POSITION);
        operatorsFeeBasisPoints = _readBPValue(NODE_OPERATORS_FEE_POSITION);
    }




    function _readBPValue(bytes32 _slot) internal view returns (uint16) {
        uint256 v = _slot.getStorageUint256();
        assert(v <= 10000);
        return uint16(v);
    }




    function _getBufferedEther() internal view returns (uint256) {
        uint256 buffered = BUFFERED_ETHER_POSITION.getStorageUint256();
        assert(address(this).balance >= buffered);

        return buffered;
    }




    function _getUnaccountedEther() internal view returns (uint256) {
        return address(this).balance.sub(_getBufferedEther());
    }






    function _getTransientBalance() internal view returns (uint256) {
        uint256 depositedValidators = DEPOSITED_VALIDATORS_POSITION.getStorageUint256();
        uint256 beaconValidators = BEACON_VALIDATORS_POSITION.getStorageUint256();

        assert(depositedValidators >= beaconValidators);
        uint256 transientValidators = depositedValidators.sub(beaconValidators);
        return transientValidators.mul(DEPOSIT_SIZE);
    }





    function _getTotalPooledEther() internal view returns (uint256) {
        uint256 bufferedBalance = _getBufferedEther();
        uint256 beaconBalance = BEACON_BALANCE_POSITION.getStorageUint256();
        uint256 transientBalance = _getTransientBalance();
        return bufferedBalance.add(beaconBalance).add(transientBalance);
    }





    function _pad64(bytes memory _b) internal pure returns (bytes memory) {
        assert(_b.length >= 32 && _b.length <= 64);
        if (64 == _b.length)
            return _b;

        bytes memory zero32 = new bytes(32);
        assembly { mstore(add(zero32, 0x20), 0) }

        if (32 == _b.length)
            return BytesLib.concat(_b, zero32);
        else
            return BytesLib.concat(_b, BytesLib.slice(zero32, 0, uint256(64).sub(_b.length)));
    }





    function _toLittleEndian64(uint256 _value) internal pure returns (uint256 result) {
        result = 0;
        uint256 temp_value = _value;
        for (uint256 i = 0; i < 8; ++i) {
            result = (result << 8) | (temp_value & 0xFF);
            temp_value >>= 8;
        }

        assert(0 == temp_value);
        result <<= (24 * 8);
    }

    function to64(uint256 v) internal pure returns (uint64) {
        assert(v <= uint256(uint64(-1)));
        return uint64(v);
    }
}
