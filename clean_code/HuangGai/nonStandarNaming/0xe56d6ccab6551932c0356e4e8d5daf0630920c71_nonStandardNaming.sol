



pragma solidity ^0.7.0;







contract Ownable
{
    address public owner;

    event OWNERSHIPTRANSFERRED745(
        address indexed previousOwner,
        address indexed newOwner
    );



    constructor()
    {
        owner = msg.sender;
    }


    modifier ONLYOWNER112()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }




    function TRANSFEROWNERSHIP715(
        address newOwner
        )
        public
        virtual
        ONLYOWNER112
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OWNERSHIPTRANSFERRED745(owner, newOwner);
        owner = newOwner;
    }

    function RENOUNCEOWNERSHIP221()
        public
        ONLYOWNER112
    {
        emit OWNERSHIPTRANSFERRED745(owner, address(0));
        owner = address(0);
    }
}











contract Claimable is Ownable
{
    address public pendingOwner;


    modifier ONLYPENDINGOWNER834() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }



    function TRANSFEROWNERSHIP715(
        address newOwner
        )
        public
        override
        ONLYOWNER112
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }


    function CLAIMOWNERSHIP503()
        public
        ONLYPENDINGOWNER834
    {
        emit OWNERSHIPTRANSFERRED745(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}







library MathUint
{
    using MathUint for uint;

    function MUL260(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function SUB429(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function ADD886(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function ADD64567(
        uint64 a,
        uint64 b
        )
        internal
        pure
        returns (uint64 c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }
}












library AddressUtil
{
    using AddressUtil for *;

    function ISCONTRACT780(
        address addr
        )
        internal
        view
        returns (bool)
    {



        bytes32 codehash;

        assembly { codehash := extcodehash(addr) }
        return (codehash != 0x0 &&
                codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }

    function TOPAYABLE290(
        address addr
        )
        internal
        pure
        returns (address payable)
    {
        return payable(addr);
    }



    function SENDETH93(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        if (amount == 0) {
            return true;
        }
        address payable recipient = to.TOPAYABLE290();

        (success, ) = recipient.call{value: amount, gas: gasLimit}("");
    }



    function SENDETHANDVERIFY115(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        success = to.SENDETH93(amount, gasLimit);
        require(success, "TRANSFER_FAILURE");
    }



    function FASTCALL566(
        address to,
        uint    gasLimit,
        uint    value,
        bytes   memory data
        )
        internal
        returns (bool success, bytes memory returnData)
    {
        if (to != address(0)) {
            assembly {

                success := call(gasLimit, to, value, add(data, 32), mload(data), 0, 0)

                let size := returndatasize()
                returnData := mload(0x40)
                mstore(returnData, size)
                returndatacopy(add(returnData, 32), 0, size)

                mstore(0x40, add(returnData, add(32, size)))
            }
        }
    }


    function FASTCALLANDVERIFY742(
        address to,
        uint    gasLimit,
        uint    value,
        bytes   memory data
        )
        internal
        returns (bytes memory returnData)
    {
        bool success;
        (success, returnData) = FASTCALL566(to, gasLimit, value, data);
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }
    }
}









library ERC20SafeTransfer
{
    function SAFETRANSFERANDVERIFY454(
        address token,
        address to,
        uint    value
        )
        internal
    {
        SAFETRANSFERWITHGASLIMITANDVERIFY643(
            token,
            to,
            value,
            gasleft()
        );
    }

    function SAFETRANSFER263(
        address token,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return SAFETRANSFERWITHGASLIMIT116(
            token,
            to,
            value,
            gasleft()
        );
    }

    function SAFETRANSFERWITHGASLIMITANDVERIFY643(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
    {
        require(
            SAFETRANSFERWITHGASLIMIT116(token, to, value, gasLimit),
            "TRANSFER_FAILURE"
        );
    }

    function SAFETRANSFERWITHGASLIMIT116(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {





        bytes memory callData = abi.encodeWithSelector(
            bytes4(0xa9059cbb),
            to,
            value
        );
        (bool success, ) = token.call{gas: gasLimit}(callData);
        return CHECKRETURNVALUE539(success);
    }

    function SAFETRANSFERFROMANDVERIFY218(
        address token,
        address from,
        address to,
        uint    value
        )
        internal
    {
        SAFETRANSFERFROMWITHGASLIMITANDVERIFY78(
            token,
            from,
            to,
            value,
            gasleft()
        );
    }

    function SAFETRANSFERFROM863(
        address token,
        address from,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return SAFETRANSFERFROMWITHGASLIMIT242(
            token,
            from,
            to,
            value,
            gasleft()
        );
    }

    function SAFETRANSFERFROMWITHGASLIMITANDVERIFY78(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
    {
        bool result = SAFETRANSFERFROMWITHGASLIMIT242(
            token,
            from,
            to,
            value,
            gasLimit
        );
        require(result, "TRANSFER_FAILURE");
    }

    function SAFETRANSFERFROMWITHGASLIMIT242(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {





        bytes memory callData = abi.encodeWithSelector(
            bytes4(0x23b872dd),
            from,
            to,
            value
        );
        (bool success, ) = token.call{gas: gasLimit}(callData);
        return CHECKRETURNVALUE539(success);
    }

    function CHECKRETURNVALUE539(
        bool success
        )
        internal
        pure
        returns (bool)
    {



        if (success) {
            assembly {
                switch returndatasize()

                case 0 {
                    success := 1
                }

                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }

                default {
                    success := 0
                }
            }
        }
        return success;
    }
}












contract ReentrancyGuard
{

    uint private _guardValue;


    modifier NONREENTRANT948()
    {

        require(_guardValue == 0, "REENTRANCY");


        _guardValue = 1;


        _;


        _guardValue = 0;
    }
}




pragma experimental ABIEncoderV2;











interface IAgent{}

interface IAgentRegistry
{




    function ISAGENT707(
        address owner,
        address agent
        )
        external
        view
        returns (bool);





    function ISAGENT707(
        address[] calldata owners,
        address            agent
        )
        external
        view
        returns (bool);
}











abstract contract IBlockVerifier is Claimable
{


    event CIRCUITREGISTERED31(
        uint8  indexed blockType,
        uint16         blockSize,
        uint8          blockVersion
    );

    event CIRCUITDISABLED690(
        uint8  indexed blockType,
        uint16         blockSize,
        uint8          blockVersion
    );











    function REGISTERCIRCUIT284(
        uint8    blockType,
        uint16   blockSize,
        uint8    blockVersion,
        uint[18] calldata vk
        )
        external
        virtual;







    function DISABLECIRCUIT787(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        virtual;










    function VERIFYPROOFS612(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion,
        uint[] calldata publicInputs,
        uint[] calldata proofs
        )
        external
        virtual
        view
        returns (bool);






    function ISCIRCUITREGISTERED877(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        virtual
        view
        returns (bool);






    function ISCIRCUITENABLED480(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        virtual
        view
        returns (bool);
}














interface IDepositContract
{

    function ISTOKENSUPPORTED796(address token)
        external
        view
        returns (bool);

















    function DEPOSIT812(
        address from,
        address token,
        uint96  amount,
        bytes   calldata extraData
        )
        external
        payable
        returns (uint96 amountReceived);



















    function WITHDRAW961(
        address from,
        address to,
        address token,
        uint    amount,
        bytes   calldata extraData
        )
        external
        payable;

















    function TRANSFER658(
        address from,
        address to,
        address token,
        uint    amount
        )
        external
        payable;










    function ISETH195(address addr)
        external
        view
        returns (bool);
}








library ExchangeData
{

    enum TransactionType
    {
        NOOP,
        DEPOSIT,
        WITHDRAWAL,
        TRANSFER,
        SPOT_TRADE,
        ACCOUNT_UPDATE,
        AMM_UPDATE
    }


    struct Token
    {
        address token;
    }

    struct ProtocolFeeData
    {
        uint32 syncedAt;
        uint8  takerFeeBips;
        uint8  makerFeeBips;
        uint8  previousTakerFeeBips;
        uint8  previousMakerFeeBips;
    }


    struct AuxiliaryData
    {
        uint  txIndex;
        bytes data;
    }



    struct Block
    {
        uint8      blockType;
        uint16     blockSize;
        uint8      blockVersion;
        bytes      data;
        uint256[8] proof;


        bool storeBlockInfoOnchain;



        AuxiliaryData[] auxiliaryData;



        bytes offchainData;
    }

    struct BlockInfo
    {

        uint32  timestamp;

        bytes28 blockDataHash;
    }


    struct Deposit
    {
        uint96 amount;
        uint64 timestamp;
    }




    struct ForcedWithdrawal
    {
        address owner;
        uint64  timestamp;
    }

    struct Constants
    {
        uint SNARK_SCALAR_FIELD;
        uint MAX_OPEN_FORCED_REQUESTS;
        uint MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE;
        uint TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS;
        uint MAX_NUM_ACCOUNTS;
        uint MAX_NUM_TOKENS;
        uint MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED;
        uint MIN_TIME_IN_SHUTDOWN;
        uint TX_DATA_AVAILABILITY_SIZE;
        uint MAX_AGE_DEPOSIT_UNTIL_WITHDRAWABLE_UPPERBOUND;
    }

    function SNARK_SCALAR_FIELD483() internal pure returns (uint) {

        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }
    function MAX_OPEN_FORCED_REQUESTS307() internal pure returns (uint16) { return 4096; }
    function MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE249() internal pure returns (uint32) { return 15 days; }
    function TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS626() internal pure returns (uint32) { return 7 days; }
    function MAX_NUM_ACCOUNTS339() internal pure returns (uint) { return 2 ** 32; }
    function MAX_NUM_TOKENS337() internal pure returns (uint) { return 2 ** 16; }
    function MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED702() internal pure returns (uint32) { return 7 days; }
    function MIN_TIME_IN_SHUTDOWN3() internal pure returns (uint32) { return 30 days; }


    function TX_DATA_AVAILABILITY_SIZE508() internal pure returns (uint32) { return 68; }
    function MAX_AGE_DEPOSIT_UNTIL_WITHDRAWABLE_UPPERBOUND638() internal pure returns (uint32) { return 15 days; }
    function ACCOUNTID_PROTOCOLFEE156() internal pure returns (uint32) { return 0; }

    function TX_DATA_AVAILABILITY_SIZE_PART_1259() internal pure returns (uint32) { return 29; }
    function TX_DATA_AVAILABILITY_SIZE_PART_2833() internal pure returns (uint32) { return 39; }

    struct AccountLeaf
    {
        uint32   accountID;
        address  owner;
        uint     pubKeyX;
        uint     pubKeyY;
        uint32   nonce;
        uint     feeBipsAMM;
    }

    struct BalanceLeaf
    {
        uint16   tokenID;
        uint96   balance;
        uint96   weightAMM;
        uint     storageRoot;
    }

    struct MerkleProof
    {
        ExchangeData.AccountLeaf accountLeaf;
        ExchangeData.BalanceLeaf balanceLeaf;
        uint[48]                 accountMerkleProof;
        uint[24]                 balanceMerkleProof;
    }

    struct BlockContext
    {
        bytes32 DOMAIN_SEPARATOR;
        uint32  timestamp;
    }


    struct State
    {
        uint32  maxAgeDepositUntilWithdrawable;
        bytes32 DOMAIN_SEPARATOR;

        ILoopringV3      loopring;
        IBlockVerifier   blockVerifier;
        IAgentRegistry   agentRegistry;
        IDepositContract depositContract;




        bytes32 merkleRoot;


        mapping(uint => BlockInfo) blocks;
        uint  numBlocks;


        Token[] tokens;


        mapping (address => uint16) tokenToTokenId;


        mapping (uint32 => mapping (uint16 => bool)) withdrawnInWithdrawMode;



        mapping (address => mapping (uint16 => uint)) amountWithdrawable;


        mapping (uint32 => mapping (uint16 => ForcedWithdrawal)) pendingForcedWithdrawals;


        mapping (address => mapping (uint16 => Deposit)) pendingDeposits;


        mapping (address => mapping (bytes32 => bool)) approvedTx;


        mapping (address => mapping (address => mapping (uint16 => mapping (uint => mapping (uint32 => address))))) withdrawalRecipient;



        uint32 numPendingForcedTransactions;


        ProtocolFeeData protocolFeeData;


        uint shutdownModeStartTime;


        uint withdrawalModeStartTime;


        mapping (address => uint) protocolFeeLastWithdrawnTime;
    }
}













abstract contract IExchangeV3 is Claimable
{


    event EXCHANGECLONED511(
        address exchangeAddress,
        address owner,
        bytes32 genesisMerkleRoot
    );

    event TOKENREGISTERED650(
        address token,
        uint16  tokenId
    );

    event SHUTDOWN33(
        uint timestamp
    );

    event WITHDRAWALMODEACTIVATED651(
        uint timestamp
    );

    event BLOCKSUBMITTED428(
        uint    indexed blockIdx,
        bytes32         merkleRoot,
        bytes32         publicDataHash
    );

    event DEPOSITREQUESTED482(
        address from,
        address to,
        address token,
        uint16  tokenId,
        uint96  amount
    );

    event FORCEDWITHDRAWALREQUESTED509(
        address owner,
        address token,
        uint32  accountID
    );

    event WITHDRAWALCOMPLETED711(
        uint8   category,
        address from,
        address to,
        address token,
        uint    amount
    );

    event WITHDRAWALFAILED876(
        uint8   category,
        address from,
        address to,
        address token,
        uint    amount
    );

    event PROTOCOLFEESUPDATED599(
        uint8 takerFeeBips,
        uint8 makerFeeBips,
        uint8 previousTakerFeeBips,
        uint8 previousMakerFeeBips
    );

    event TRANSACTIONAPPROVED992(
        address owner,
        bytes32 transactionHash
    );
















    function INITIALIZE599(
        address loopring,
        address owner,
        bytes32 genesisMerkleRoot
        )
        virtual
        external;




    function SETAGENTREGISTRY336(address agentRegistry)
        external
        virtual;



    function GETAGENTREGISTRY130()
        external
        virtual
        view
        returns (IAgentRegistry);



    function SETDEPOSITCONTRACT329(address depositContract)
        external
        virtual;



    function GETDEPOSITCONTRACT552()
        external
        virtual
        view
        returns (IDepositContract);




    function WITHDRAWEXCHANGEFEES258(
        address token,
        address feeRecipient
        )
        external
        virtual;




    function GETCONSTANTS860()
        external
        virtual
        pure
        returns(ExchangeData.Constants memory);




    function ISINWITHDRAWALMODE735()
        external
        virtual
        view
        returns (bool);



    function ISSHUTDOWN18()
        external
        virtual
        view
        returns (bool);












    function REGISTERTOKEN777(
        address tokenAddress
        )
        external
        virtual
        returns (uint16 tokenID);




    function GETTOKENID492(
        address tokenAddress
        )
        external
        virtual
        view
        returns (uint16 tokenID);




    function GETTOKENADDRESS957(
        uint16 tokenID
        )
        external
        virtual
        view
        returns (address tokenAddress);








    function GETEXCHANGESTAKE420()
        external
        virtual
        view
        returns (uint);










    function WITHDRAWEXCHANGESTAKE391(
        address recipient
        )
        external
        virtual
        returns (uint amountLRC);






    function BURNEXCHANGESTAKE0()
        external
        virtual;





    function GETMERKLEROOT398()
        external
        virtual
        view
        returns (bytes32);




    function GETBLOCKHEIGHT308()
        external
        virtual
        view
        returns (uint);





    function GETBLOCKINFO928(uint blockIdx)
        external
        virtual
        view
        returns (ExchangeData.BlockInfo memory);














    function SUBMITBLOCKS846(ExchangeData.Block[] calldata blocks)
        external
        virtual;



    function GETNUMAVAILABLEFORCEDSLOTS361()
        external
        virtual
        view
        returns (uint);
















    function DEPOSIT812(
        address from,
        address to,
        address tokenAddress,
        uint96  amount,
        bytes   calldata auxiliaryData
        )
        external
        virtual
        payable;





    function GETPENDINGDEPOSITAMOUNT893(
        address owner,
        address tokenAddress
        )
        external
        virtual
        view
        returns (uint96);

















    function FORCEWITHDRAW720(
        address owner,
        address tokenAddress,
        uint32  accountID
        )
        external
        virtual
        payable;





    function ISFORCEDWITHDRAWALPENDING612(
        uint32  accountID,
        address token
        )
        external
        virtual
        view
        returns (bool);











    function WITHDRAWPROTOCOLFEES774(
        address tokenAddress
        )
        external
        virtual
        payable;




    function GETPROTOCOLFEELASTWITHDRAWNTIME313(
        address tokenAddress
        )
        external
        virtual
        view
        returns (uint);












    function WITHDRAWFROMMERKLETREE611(
        ExchangeData.MerkleProof calldata merkleProof
        )
        external
        virtual;





    function ISWITHDRAWNINWITHDRAWALMODE951(
        uint32  accountID,
        address token
        )
        external
        virtual
        view
        returns (bool);









    function WITHDRAWFROMDEPOSITREQUEST842(
        address owner,
        address token
        )
        external
        virtual;
















    function WITHDRAWFROMAPPROVEDWITHDRAWALS239(
        address[] calldata owners,
        address[] calldata tokens
        )
        external
        virtual;





    function GETAMOUNTWITHDRAWABLE280(
        address owner,
        address token
        )
        external
        virtual
        view
        returns (uint);








    function NOTIFYFORCEDREQUESTTOOOLD650(
        uint32  accountID,
        address token
        )
        external
        virtual;













    function SETWITHDRAWALRECIPIENT592(
        address from,
        address to,
        address token,
        uint96  amount,
        uint32  storageID,
        address newRecipient
        )
        external
        virtual;








    function GETWITHDRAWALRECIPIENT486(
        address from,
        address to,
        address token,
        uint96  amount,
        uint32  storageID
        )
        external
        virtual
        view
        returns (address);











    function ONCHAINTRANSFERFROM491(
        address from,
        address to,
        address token,
        uint    amount
        )
        external
        virtual;







    function APPROVETRANSACTION417(
        address owner,
        bytes32 txHash
        )
        external
        virtual;







    function APPROVETRANSACTIONS714(
        address[] calldata owners,
        bytes32[] calldata txHashes
        )
        external
        virtual;






    function ISTRANSACTIONAPPROVED916(
        address owner,
        bytes32 txHash
        )
        external
        virtual
        view
        returns (bool);





    function SETMAXAGEDEPOSITUNTILWITHDRAWABLE624(
        uint32 newValue
        )
        external
        virtual
        returns (uint32);



    function GETMAXAGEDEPOSITUNTILWITHDRAWABLE693()
        external
        virtual
        view
        returns (uint32);














    function SHUTDOWN305()
        external
        virtual
        returns (bool success);







    function GETPROTOCOLFEEVALUES606()
        external
        virtual
        view
        returns (
            uint32 syncedAt,
            uint8 takerFeeBips,
            uint8 makerFeeBips,
            uint8 previousTakerFeeBips,
            uint8 previousMakerFeeBips
        );


    function GETDOMAINSEPARATOR671()
        external
        virtual
        view
        returns (bytes32);
}











abstract contract ILoopringV3 is Claimable
{

    event EXCHANGESTAKEDEPOSITED907(address exchangeAddr, uint amount);
    event EXCHANGESTAKEWITHDRAWN386(address exchangeAddr, uint amount);
    event EXCHANGESTAKEBURNED415(address exchangeAddr, uint amount);
    event SETTINGSUPDATED90(uint time);


    mapping (address => uint) internal exchangeStake;

    address public lrcAddress;
    uint    public totalStake;
    address public blockVerifierAddress;
    uint    public forcedWithdrawalFee;
    uint    public tokenRegistrationFeeLRCBase;
    uint    public tokenRegistrationFeeLRCDelta;
    uint8   public protocolTakerFeeBips;
    uint8   public protocolMakerFeeBips;

    address payable public protocolFeeVault;







    function UPDATESETTINGS249(
        address payable _protocolFeeVault,
        address _blockVerifierAddress,
        uint    _forcedWithdrawalFee
        )
        external
        virtual;






    function UPDATEPROTOCOLFEESETTINGS464(
        uint8 _protocolTakerFeeBips,
        uint8 _protocolMakerFeeBips
        )
        external
        virtual;




    function GETEXCHANGESTAKE420(
        address exchangeAddr
        )
        public
        virtual
        view
        returns (uint stakedLRC);





    function BURNEXCHANGESTAKE0(
        uint amount
        )
        external
        virtual
        returns (uint burnedLRC);





    function DEPOSITEXCHANGESTAKE519(
        address exchangeAddr,
        uint    amountLRC
        )
        external
        virtual
        returns (uint stakedLRC);






    function WITHDRAWEXCHANGESTAKE391(
        address recipient,
        uint    requestedAmount
        )
        external
        virtual
        returns (uint amountLRC);




    function GETPROTOCOLFEEVALUES606(
        )
        public
        virtual
        view
        returns (
            uint8 takerFeeBips,
            uint8 makerFeeBips
        );
}







contract LoopringV3 is ILoopringV3, ReentrancyGuard
{
    using AddressUtil       for address payable;
    using MathUint          for uint;
    using ERC20SafeTransfer for address;


    constructor(
        address _lrcAddress,
        address payable _protocolFeeVault,
        address _blockVerifierAddress
        )
        Claimable()
    {
        require(address(0) != _lrcAddress, "ZERO_ADDRESS");

        lrcAddress = _lrcAddress;

        UPDATESETTINGSINTERNAL160(_protocolFeeVault, _blockVerifierAddress, 0);
    }


    function UPDATESETTINGS249(
        address payable _protocolFeeVault,
        address _blockVerifierAddress,
        uint    _forcedWithdrawalFee
        )
        external
        override
        NONREENTRANT948
        ONLYOWNER112
    {
        UPDATESETTINGSINTERNAL160(
            _protocolFeeVault,
            _blockVerifierAddress,
            _forcedWithdrawalFee
        );
    }

    function UPDATEPROTOCOLFEESETTINGS464(
        uint8 _protocolTakerFeeBips,
        uint8 _protocolMakerFeeBips
        )
        external
        override
        NONREENTRANT948
        ONLYOWNER112
    {
        protocolTakerFeeBips = _protocolTakerFeeBips;
        protocolMakerFeeBips = _protocolMakerFeeBips;

        emit SETTINGSUPDATED90(block.timestamp);
    }

    function GETEXCHANGESTAKE420(
        address exchangeAddr
        )
        public
        override
        view
        returns (uint)
    {
        return exchangeStake[exchangeAddr];
    }

    function BURNEXCHANGESTAKE0(
        uint amount
        )
        external
        override
        NONREENTRANT948
        returns (uint burnedLRC)
    {
        burnedLRC = exchangeStake[msg.sender];

        if (amount < burnedLRC) {
            burnedLRC = amount;
        }
        if (burnedLRC > 0) {
            lrcAddress.SAFETRANSFERANDVERIFY454(protocolFeeVault, burnedLRC);
            exchangeStake[msg.sender] = exchangeStake[msg.sender].SUB429(burnedLRC);
            totalStake = totalStake.SUB429(burnedLRC);
        }
        emit EXCHANGESTAKEBURNED415(msg.sender, burnedLRC);
    }

    function DEPOSITEXCHANGESTAKE519(
        address exchangeAddr,
        uint    amountLRC
        )
        external
        override
        NONREENTRANT948
        returns (uint stakedLRC)
    {
        require(amountLRC > 0, "ZERO_VALUE");

        lrcAddress.SAFETRANSFERFROMANDVERIFY218(msg.sender, address(this), amountLRC);

        stakedLRC = exchangeStake[exchangeAddr].ADD886(amountLRC);
        exchangeStake[exchangeAddr] = stakedLRC;
        totalStake = totalStake.ADD886(amountLRC);

        emit EXCHANGESTAKEDEPOSITED907(exchangeAddr, amountLRC);
    }

    function WITHDRAWEXCHANGESTAKE391(
        address recipient,
        uint    requestedAmount
        )
        external
        override
        NONREENTRANT948
        returns (uint amountLRC)
    {
        uint stake = exchangeStake[msg.sender];
        amountLRC = (stake > requestedAmount) ? requestedAmount : stake;

        if (amountLRC > 0) {
            lrcAddress.SAFETRANSFERANDVERIFY454(recipient, amountLRC);
            exchangeStake[msg.sender] = exchangeStake[msg.sender].SUB429(amountLRC);
            totalStake = totalStake.SUB429(amountLRC);
        }

        emit EXCHANGESTAKEWITHDRAWN386(msg.sender, amountLRC);
    }

    function GETPROTOCOLFEEVALUES606()
        public
        override
        view
        returns (
            uint8 takerFeeBips,
            uint8 makerFeeBips
        )
    {
        return (protocolTakerFeeBips, protocolMakerFeeBips);
    }


    function UPDATESETTINGSINTERNAL160(
        address payable  _protocolFeeVault,
        address _blockVerifierAddress,
        uint    _forcedWithdrawalFee
        )
        private
    {
        require(address(0) != _protocolFeeVault, "ZERO_ADDRESS");
        require(address(0) != _blockVerifierAddress, "ZERO_ADDRESS");

        protocolFeeVault = _protocolFeeVault;
        blockVerifierAddress = _blockVerifierAddress;
        forcedWithdrawalFee = _forcedWithdrawalFee;

        emit SETTINGSUPDATED90(block.timestamp);
    }
}
