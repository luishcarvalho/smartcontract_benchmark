





pragma solidity ^0.5.1;




interface ICelerWallet {
    function create(address[] calldata _owners, address _operator, bytes32 _nonce) external returns(bytes32);

    function depositETH(bytes32 _walletId) external payable;

    function depositERC20(bytes32 _walletId, address _tokenAddress, uint _amount) external;

    function withdraw(bytes32 _walletId, address _tokenAddress, address _receiver, uint _amount) external;

    function transferToWallet(bytes32 _fromWalletId, bytes32 _toWalletId, address _tokenAddress, address _receiver, uint _amount) external;

    function transferOperatorship(bytes32 _walletId, address _newOperator) external;

    function proposeNewOperator(bytes32 _walletId, address _newOperator) external;

    function drainToken(address _tokenAddress, address _receiver, uint _amount) external;

    function getWalletOwners(bytes32 _walletId) external view returns(address[] memory);

    function getOperator(bytes32 _walletId) external view returns(address);

    function getBalance(bytes32 _walletId, address _tokenAddress) external view returns(uint);

    function getProposedNewOperator(bytes32 _walletId) external view returns(address);

    function getProposalVote(bytes32 _walletId, address _owner) external view returns(bool);

    event CreateWallet(bytes32 indexed walletId, address[] indexed owners, address indexed operator);

    event DepositToWallet(bytes32 indexed walletId, address indexed tokenAddress, uint amount);

    event WithdrawFromWallet(bytes32 indexed walletId, address indexed tokenAddress, address indexed receiver, uint amount);

    event TransferToWallet(bytes32 indexed fromWalletId, bytes32 indexed toWalletId, address indexed tokenAddress, address receiver, uint amount);

    event ChangeOperator(bytes32 indexed walletId, address indexed oldOperator, address indexed newOperator);

    event ProposeNewOperator(bytes32 indexed walletId, address indexed newOperator, address indexed proposer);

    event DrainToken(address indexed tokenAddress, address indexed receiver, uint amount);
}



pragma solidity ^0.5.1;




interface IEthPool {
    function deposit(address _receiver) external payable;

    function withdraw(uint _value) external;

    function approve(address _spender, uint _value) external returns (bool);

    function transferFrom(address _from, address payable _to, uint _value) external returns (bool);

    function transferToCelerWallet(address _from, address _walletAddr, bytes32 _walletId, uint _value) external returns (bool);

    function increaseAllowance(address _spender, uint _addedValue) external returns (bool);

    function decreaseAllowance(address _spender, uint _subtractedValue) external returns (bool);

    function balanceOf(address _owner) external view returns (uint);

    function allowance(address _owner, address _spender) external view returns (uint);

    event Deposit(address indexed receiver, uint value);


    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}



pragma solidity ^0.5.1;




interface IPayRegistry {
    function calculatePayId(bytes32 _payHash, address _setter) external pure returns(bytes32);

    function setPayAmount(bytes32 _payHash, uint _amt) external;

    function setPayDeadline(bytes32 _payHash, uint _deadline) external;

    function setPayInfo(bytes32 _payHash, uint _amt, uint _deadline) external;

    function setPayAmounts(bytes32[] calldata _payHashes, uint[] calldata _amts) external;

    function setPayDeadlines(bytes32[] calldata _payHashes, uint[] calldata _deadlines) external;

    function setPayInfos(bytes32[] calldata _payHashes, uint[] calldata _amts, uint[] calldata _deadlines) external;

    function getPayAmounts(
        bytes32[] calldata _payIds,
        uint _lastPayResolveDeadline
    ) external view returns(uint[] memory);

    function getPayInfo(bytes32 _payId) external view returns(uint, uint);

    event PayInfoUpdate(bytes32 indexed payId, uint amount, uint resolveDeadline);
}



pragma solidity ^0.5.0;


library Pb {
    enum WireType { Varint, Fixed64, LengthDelim, StartGroup, EndGroup, Fixed32 }

    struct Buffer {
        uint idx;
        bytes b;
    }


    function fromBytes(bytes memory raw) internal pure returns (Buffer memory buf) {
        buf.b = raw;
        buf.idx = 0;
    }


    function hasMore(Buffer memory buf) internal pure returns (bool) {
        return buf.idx < buf.b.length;
    }


    function decKey(Buffer memory buf) internal pure returns (uint tag, WireType wiretype) {
        uint v = decVarint(buf);
        tag = v / 8;
        wiretype = WireType(v & 7);
    }




    function cntTags(Buffer memory buf, uint maxtag) internal pure returns (uint[] memory cnts) {
        uint originalIdx = buf.idx;
        cnts = new uint[](maxtag+1);
        uint tag;
        WireType wire;
        while (hasMore(buf)) {
            (tag, wire) = decKey(buf);
            cnts[tag] += 1;
            skipValue(buf, wire);
        }
        buf.idx = originalIdx;
    }


    function decVarint(Buffer memory buf) internal pure returns (uint v) {
        bytes10 tmp;
        bytes memory bb = buf.b;
        v = buf.idx;
        assembly {
            tmp := mload(add(add(bb, 32), v))
        }
        uint b;
        v = 0;
        for (uint i=0; i<10; i++) {
            assembly {
                b := byte(i, tmp)
            }
            v |= (b & 0x7F) << (i * 7);
            if (b & 0x80 == 0) {
                buf.idx += i + 1;
                return v;
            }
        }
        revert();
    }


    function decBytes(Buffer memory buf) internal pure returns (bytes memory b) {
        uint len = decVarint(buf);
        uint end = buf.idx + len;
        require(end <= buf.b.length);
        b = new bytes(len);
        bytes memory bufB = buf.b;
        uint bStart;
        uint bufBStart = buf.idx;
        assembly {
            bStart := add(b, 32)
            bufBStart := add(add(bufB, 32), bufBStart)
        }
        for (uint i=0; i<len; i+=32) {
            assembly{
                mstore(add(bStart, i), mload(add(bufBStart, i)))
            }
        }
        buf.idx = end;
    }


    function decPacked(Buffer memory buf) internal pure returns (uint[] memory t) {
        uint len = decVarint(buf);
        uint end = buf.idx + len;
        require(end <= buf.b.length);


        uint[] memory tmp = new uint[](len);
        uint i = 0;
        while (buf.idx < end) {
            tmp[i] = decVarint(buf);
            i++;
        }
        t = new uint[](i);
        for (uint j=0; j<i; j++) {
            t[j] = tmp[j];
        }
        return t;
    }


    function skipValue(Buffer memory buf, WireType wire) internal pure {
        if (wire == WireType.Varint) { decVarint(buf); }
        else if (wire == WireType.LengthDelim) {
            uint len = decVarint(buf);
            buf.idx += len;
            require(buf.idx <= buf.b.length);
        } else { revert(); }
    }


    function _bool(uint x) internal pure returns (bool v) {
        return x != 0;
    }

    function _uint256(bytes memory b) internal pure returns (uint256 v) {
        require(b.length <= 32);
        assembly { v := mload(add(b, 32)) }
        v = v >> (8 * (32 - b.length));
    }

    function _address(bytes memory b) internal pure returns (address v) {
        v = _addressPayable(b);
    }

    function _addressPayable(bytes memory b) internal pure returns (address payable v) {
        require(b.length == 20);

        assembly { v := div(mload(add(b, 32)), 0x1000000000000000000000000) }
    }

    function _bytes32(bytes memory b) internal pure returns (bytes32 v) {
        require(b.length == 32);
        assembly { v := mload(add(b, 32)) }
    }


    function uint8s(uint[] memory arr) internal pure returns (uint8[] memory t) {
        t = new uint8[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = uint8(arr[i]); }
    }

    function uint32s(uint[] memory arr) internal pure returns (uint32[] memory t) {
        t = new uint32[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = uint32(arr[i]); }
    }

    function uint64s(uint[] memory arr) internal pure returns (uint64[] memory t) {
        t = new uint64[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = uint64(arr[i]); }
    }

    function bools(uint[] memory arr) internal pure returns (bool[] memory t) {
        t = new bool[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = arr[i]!=0; }
    }
}





pragma solidity ^0.5.0;


library PbEntity {
    using Pb for Pb.Buffer;

    enum TokenType { INVALID, ETH, ERC20 }


    function TokenTypes(uint[] memory arr) internal pure returns (TokenType[] memory t) {
        t = new TokenType[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = TokenType(arr[i]); }
    }

    enum TransferFunctionType { BOOLEAN_AND, BOOLEAN_OR, BOOLEAN_CIRCUIT, NUMERIC_ADD, NUMERIC_MAX, NUMERIC_MIN }


    function TransferFunctionTypes(uint[] memory arr) internal pure returns (TransferFunctionType[] memory t) {
        t = new TransferFunctionType[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = TransferFunctionType(arr[i]); }
    }

    enum ConditionType { HASH_LOCK, DEPLOYED_CONTRACT, VIRTUAL_CONTRACT }


    function ConditionTypes(uint[] memory arr) internal pure returns (ConditionType[] memory t) {
        t = new ConditionType[](arr.length);
        for (uint i = 0; i < t.length; i++) { t[i] = ConditionType(arr[i]); }
    }

    struct AccountAmtPair {
        address account;
        uint256 amt;
    }

    function decAccountAmtPair(bytes memory raw) internal pure returns (AccountAmtPair memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.account = Pb._address(buf.decBytes());
            }
            else if (tag == 2) {
                m.amt = Pb._uint256(buf.decBytes());
            }
            else { buf.skipValue(wire); }
        }
    }

    struct TokenInfo {
        TokenType tokenType;
        address tokenAddress;
    }

    function decTokenInfo(bytes memory raw) internal pure returns (TokenInfo memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.tokenType = TokenType(buf.decVarint());
            }
            else if (tag == 2) {
                m.tokenAddress = Pb._address(buf.decBytes());
            }
            else { buf.skipValue(wire); }
        }
    }

    struct TokenDistribution {
        TokenInfo token;
        AccountAmtPair[] distribution;
    }

    function decTokenDistribution(bytes memory raw) internal pure returns (TokenDistribution memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.distribution = new AccountAmtPair[](cnts[2]);
        cnts[2] = 0;

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.token = decTokenInfo(buf.decBytes());
            }
            else if (tag == 2) {
                m.distribution[cnts[2]] = decAccountAmtPair(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); }
        }
    }

    struct TokenTransfer {
        TokenInfo token;
        AccountAmtPair receiver;
    }

    function decTokenTransfer(bytes memory raw) internal pure returns (TokenTransfer memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.token = decTokenInfo(buf.decBytes());
            }
            else if (tag == 2) {
                m.receiver = decAccountAmtPair(buf.decBytes());
            }
            else { buf.skipValue(wire); }
        }
    }

    struct SimplexPaymentChannel {
        bytes32 channelId;
        address peerFrom;
        uint seqNum;
        TokenTransfer transferToPeer;
        PayIdList pendingPayIds;
        uint lastPayResolveDeadline;
        uint256 totalPendingAmount;
    }

    function decSimplexPaymentChannel(bytes memory raw) internal pure returns (SimplexPaymentChannel memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.channelId = Pb._bytes32(buf.decBytes());
            }
            else if (tag == 2) {
                m.peerFrom = Pb._address(buf.decBytes());
            }
            else if (tag == 3) {
                m.seqNum = uint(buf.decVarint());
            }
            else if (tag == 4) {
                m.transferToPeer = decTokenTransfer(buf.decBytes());
            }
            else if (tag == 5) {
                m.pendingPayIds = decPayIdList(buf.decBytes());
            }
            else if (tag == 6) {
                m.lastPayResolveDeadline = uint(buf.decVarint());
            }
            else if (tag == 7) {
                m.totalPendingAmount = Pb._uint256(buf.decBytes());
            }
            else { buf.skipValue(wire); }
        }
    }

    struct PayIdList {
        bytes32[] payIds;
        bytes32 nextListHash;
    }

    function decPayIdList(bytes memory raw) internal pure returns (PayIdList memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.payIds = new bytes32[](cnts[1]);
        cnts[1] = 0;

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.payIds[cnts[1]] = Pb._bytes32(buf.decBytes());
                cnts[1]++;
            }
            else if (tag == 2) {
                m.nextListHash = Pb._bytes32(buf.decBytes());
            }
            else { buf.skipValue(wire); }
        }
    }

    struct TransferFunction {
        TransferFunctionType logicType;
        TokenTransfer maxTransfer;
    }

    function decTransferFunction(bytes memory raw) internal pure returns (TransferFunction memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.logicType = TransferFunctionType(buf.decVarint());
            }
            else if (tag == 2) {
                m.maxTransfer = decTokenTransfer(buf.decBytes());
            }
            else { buf.skipValue(wire); }
        }
    }

    struct ConditionalPay {
        uint payTimestamp;
        address src;
        address dest;
        Condition[] conditions;
        TransferFunction transferFunc;
        uint resolveDeadline;
        uint resolveTimeout;
        address payResolver;
    }

    function decConditionalPay(bytes memory raw) internal pure returns (ConditionalPay memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(8);
        m.conditions = new Condition[](cnts[4]);
        cnts[4] = 0;

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.payTimestamp = uint(buf.decVarint());
            }
            else if (tag == 2) {
                m.src = Pb._address(buf.decBytes());
            }
            else if (tag == 3) {
                m.dest = Pb._address(buf.decBytes());
            }
            else if (tag == 4) {
                m.conditions[cnts[4]] = decCondition(buf.decBytes());
                cnts[4]++;
            }
            else if (tag == 5) {
                m.transferFunc = decTransferFunction(buf.decBytes());
            }
            else if (tag == 6) {
                m.resolveDeadline = uint(buf.decVarint());
            }
            else if (tag == 7) {
                m.resolveTimeout = uint(buf.decVarint());
            }
            else if (tag == 8) {
                m.payResolver = Pb._address(buf.decBytes());
            }
            else { buf.skipValue(wire); }
        }
    }

    struct CondPayResult {
        bytes condPay;
        uint256 amount;
    }

    function decCondPayResult(bytes memory raw) internal pure returns (CondPayResult memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.condPay = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.amount = Pb._uint256(buf.decBytes());
            }
            else { buf.skipValue(wire); }
        }
    }

    struct VouchedCondPayResult {
        bytes condPayResult;
        bytes sigOfSrc;
        bytes sigOfDest;
    }

    function decVouchedCondPayResult(bytes memory raw) internal pure returns (VouchedCondPayResult memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.condPayResult = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigOfSrc = bytes(buf.decBytes());
            }
            else if (tag == 3) {
                m.sigOfDest = bytes(buf.decBytes());
            }
            else { buf.skipValue(wire); }
        }
    }

    struct Condition {
        ConditionType conditionType;
        bytes32 hashLock;
        address deployedContractAddress;
        bytes32 virtualContractAddress;
        bytes argsQueryFinalization;
        bytes argsQueryOutcome;
    }

    function decCondition(bytes memory raw) internal pure returns (Condition memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.conditionType = ConditionType(buf.decVarint());
            }
            else if (tag == 2) {
                m.hashLock = Pb._bytes32(buf.decBytes());
            }
            else if (tag == 3) {
                m.deployedContractAddress = Pb._address(buf.decBytes());
            }
            else if (tag == 4) {
                m.virtualContractAddress = Pb._bytes32(buf.decBytes());
            }
            else if (tag == 5) {
                m.argsQueryFinalization = bytes(buf.decBytes());
            }
            else if (tag == 6) {
                m.argsQueryOutcome = bytes(buf.decBytes());
            }
            else { buf.skipValue(wire); }
        }
    }

    struct CooperativeWithdrawInfo {
        bytes32 channelId;
        uint seqNum;
        AccountAmtPair withdraw;
        uint withdrawDeadline;
        bytes32 recipientChannelId;
    }

    function decCooperativeWithdrawInfo(bytes memory raw) internal pure returns (CooperativeWithdrawInfo memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.channelId = Pb._bytes32(buf.decBytes());
            }
            else if (tag == 2) {
                m.seqNum = uint(buf.decVarint());
            }
            else if (tag == 3) {
                m.withdraw = decAccountAmtPair(buf.decBytes());
            }
            else if (tag == 4) {
                m.withdrawDeadline = uint(buf.decVarint());
            }
            else if (tag == 5) {
                m.recipientChannelId = Pb._bytes32(buf.decBytes());
            }
            else { buf.skipValue(wire); }
        }
    }

    struct PaymentChannelInitializer {
        TokenDistribution initDistribution;
        uint openDeadline;
        uint disputeTimeout;
        uint msgValueReceiver;
    }

    function decPaymentChannelInitializer(bytes memory raw) internal pure returns (PaymentChannelInitializer memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.initDistribution = decTokenDistribution(buf.decBytes());
            }
            else if (tag == 2) {
                m.openDeadline = uint(buf.decVarint());
            }
            else if (tag == 3) {
                m.disputeTimeout = uint(buf.decVarint());
            }
            else if (tag == 4) {
                m.msgValueReceiver = uint(buf.decVarint());
            }
            else { buf.skipValue(wire); }
        }
    }

    struct CooperativeSettleInfo {
        bytes32 channelId;
        uint seqNum;
        AccountAmtPair[] settleBalance;
        uint settleDeadline;
    }

    function decCooperativeSettleInfo(bytes memory raw) internal pure returns (CooperativeSettleInfo memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(4);
        m.settleBalance = new AccountAmtPair[](cnts[3]);
        cnts[3] = 0;

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.channelId = Pb._bytes32(buf.decBytes());
            }
            else if (tag == 2) {
                m.seqNum = uint(buf.decVarint());
            }
            else if (tag == 3) {
                m.settleBalance[cnts[3]] = decAccountAmtPair(buf.decBytes());
                cnts[3]++;
            }
            else if (tag == 4) {
                m.settleDeadline = uint(buf.decVarint());
            }
            else { buf.skipValue(wire); }
        }
    }

    struct ChannelMigrationInfo {
        bytes32 channelId;
        address fromLedgerAddress;
        address toLedgerAddress;
        uint migrationDeadline;
    }

    function decChannelMigrationInfo(bytes memory raw) internal pure returns (ChannelMigrationInfo memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.channelId = Pb._bytes32(buf.decBytes());
            }
            else if (tag == 2) {
                m.fromLedgerAddress = Pb._address(buf.decBytes());
            }
            else if (tag == 3) {
                m.toLedgerAddress = Pb._address(buf.decBytes());
            }
            else if (tag == 4) {
                m.migrationDeadline = uint(buf.decVarint());
            }
            else { buf.skipValue(wire); }
        }
    }

}



pragma solidity ^0.5.1;









library LedgerStruct {
    enum ChannelStatus { Uninitialized, Operable, Settling, Closed, Migrated }

    struct PeerState {
        uint seqNum;

        uint transferOut;
        bytes32 nextPayIdListHash;
        uint lastPayResolveDeadline;
        uint pendingPayOut;
    }

    struct PeerProfile {
        address peerAddr;

        uint deposit;

        uint withdrawal;
        PeerState state;
    }

    struct WithdrawIntent {
        address receiver;
        uint amount;
        uint requestTime;
        bytes32 recipientChannelId;
    }





    struct Channel {

        uint settleFinalizedTime;
        uint disputeTimeout;
        PbEntity.TokenInfo token;
        ChannelStatus status;

        address migratedTo;

        PeerProfile[2] peerProfiles;
        uint cooperativeWithdrawSeqNum;
        WithdrawIntent withdrawIntent;
    }



    struct Ledger {

        mapping(uint => uint) channelStatusNums;
        IEthPool ethPool;
        IPayRegistry payRegistry;
        ICelerWallet celerWallet;

        mapping(address => uint) balanceLimits;

        bool balanceLimitsEnabled;
        mapping(bytes32 => Channel) channelMap;
    }
}



pragma solidity ^0.5.1;








interface ICelerLedger {

    function openChannel(bytes calldata _openChannelRequest) external payable;

    function deposit(bytes32 _channelId, address _receiver, uint _transferFromAmount) external payable;

    function depositInBatch(
        bytes32[] calldata _channelIds,
        address[] calldata _receivers,
        uint[] calldata _transferFromAmounts
    ) external;

    function snapshotStates(bytes calldata _signedSimplexStateArray) external;

    function intendWithdraw(bytes32 _channelId, uint _amount, bytes32 _recipientChannelId) external;

    function confirmWithdraw(bytes32 _channelId) external;

    function vetoWithdraw(bytes32 _channelId) external;

    function cooperativeWithdraw(bytes calldata _cooperativeWithdrawRequest) external;

    function intendSettle(bytes calldata _signedSimplexStateArray) external;

    function clearPays(bytes32 _channelId, address _peerFrom, bytes calldata _payIdList) external;

    function confirmSettle(bytes32 _channelId) external;

    function cooperativeSettle(bytes calldata _settleRequest) external;

    function getChannelStatusNum(uint _channelStatus) external view returns(uint);

    function getEthPool() external view returns(address);

    function getPayRegistry() external view returns(address);

    function getCelerWallet() external view returns(address);

    event OpenChannel(
        bytes32 indexed channelId,
        uint tokenType,
        address indexed tokenAddress,

        address[2] peerAddrs,
        uint[2] initialDeposits
    );


    event Deposit(bytes32 indexed channelId, address[2] peerAddrs, uint[2] deposits, uint[2] withdrawals);

    event SnapshotStates(bytes32 indexed channelId, uint[2] seqNums);

    event IntendSettle(bytes32 indexed channelId, uint[2] seqNums);

    event ClearOnePay(bytes32 indexed channelId, bytes32 indexed payId, address indexed peerFrom, uint amount);

    event ConfirmSettle(bytes32 indexed channelId, uint[2] settleBalance);

    event ConfirmSettleFail(bytes32 indexed channelId);

    event IntendWithdraw(bytes32 indexed channelId, address indexed receiver, uint amount);

    event ConfirmWithdraw(
        bytes32 indexed channelId,
        uint withdrawnAmount,
        address indexed receiver,
        bytes32 indexed recipientChannelId,
        uint[2] deposits,
        uint[2] withdrawals
    );

    event VetoWithdraw(bytes32 indexed channelId);

    event CooperativeWithdraw(
        bytes32 indexed channelId,
        uint withdrawnAmount,
        address indexed receiver,
        bytes32 indexed recipientChannelId,
        uint[2] deposits,
        uint[2] withdrawals,
        uint seqNum
    );

    event CooperativeSettle(bytes32 indexed channelId, uint[2] settleBalance);




    function getSettleFinalizedTime(bytes32 _channelId) external view returns(uint);

    function getTokenContract(bytes32 _channelId) external view returns(address);

    function getTokenType(bytes32 _channelId) external view returns(PbEntity.TokenType);

    function getChannelStatus(bytes32 _channelId) external view returns(LedgerStruct.ChannelStatus);

    function getCooperativeWithdrawSeqNum(bytes32 _channelId) external view returns(uint);

    function getTotalBalance(bytes32 _channelId) external view returns(uint);

    function getBalanceMap(bytes32 _channelId) external view returns(address[2] memory, uint[2] memory, uint[2] memory);

    function getChannelMigrationArgs(bytes32 _channelId) external view returns(uint, uint, address, uint);

    function getPeersMigrationInfo(bytes32 _channelId) external view returns(
        address[2] memory,
        uint[2] memory,
        uint[2] memory,
        uint[2] memory,
        uint[2] memory,
        uint[2] memory
    );

    function getDisputeTimeout(bytes32 _channelId) external view returns(uint);

    function getMigratedTo(bytes32 _channelId) external view returns(address);

    function getStateSeqNumMap(bytes32 _channelId) external view returns(address[2] memory, uint[2] memory);

    function getTransferOutMap(bytes32 _channelId) external view returns(
        address[2] memory,
        uint[2] memory
    );

    function getNextPayIdListHashMap(bytes32 _channelId) external view returns(
        address[2] memory,
        bytes32[2] memory
    );

    function getLastPayResolveDeadlineMap(bytes32 _channelId) external view returns(
        address[2] memory,
        uint[2] memory
    );

    function getPendingPayOutMap(bytes32 _channelId) external view returns(
        address[2] memory,
        uint[2] memory
    );

    function getWithdrawIntent(bytes32 _channelId) external view returns(address, uint, uint, bytes32);




    function setBalanceLimits(address[] calldata _tokenAddrs, uint[] calldata _limits) external;

    function disableBalanceLimits() external;

    function enableBalanceLimits() external;

    function getBalanceLimit(address _tokenAddr) external view returns(uint);

    function getBalanceLimitsEnabled() external view returns(bool);




    function migrateChannelTo(bytes calldata _migrationRequest) external returns(bytes32);

    function migrateChannelFrom(address _fromLedgerAddr, bytes calldata _migrationRequest) external;

    event MigrateChannelTo(bytes32 indexed channelId, address indexed newLedgerAddr);

    event MigrateChannelFrom(bytes32 indexed channelId, address indexed oldLedgerAddr);

}



pragma solidity ^0.5.0;





library SafeMath {



    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



pragma solidity ^0.5.0;








library ECDSA {





    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;


        if (signature.length != 65) {
            return (address(0));
        }





        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }


        if (v < 27) {
            v += 27;
        }


        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }






    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {


        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}



pragma solidity ^0.5.1;












library LedgerChannel {
    using SafeMath for uint;
    using ECDSA for bytes32;






    function getSettleFinalizedTime(LedgerStruct.Channel storage _c) public view returns(uint) {
        return _c.settleFinalizedTime;
    }






    function getTokenContract(LedgerStruct.Channel storage _c) public view returns(address) {
        return _c.token.tokenAddress;
    }






    function getTokenType(LedgerStruct.Channel storage _c) public view returns(PbEntity.TokenType) {
        return _c.token.tokenType;
    }






    function getChannelStatus(
        LedgerStruct.Channel storage _c
    )
        public
        view
        returns(LedgerStruct.ChannelStatus)
    {
        return _c.status;
    }






    function getCooperativeWithdrawSeqNum(LedgerStruct.Channel storage _c) public view returns(uint) {
        return _c.cooperativeWithdrawSeqNum;
    }






    function getTotalBalance(LedgerStruct.Channel storage _c) public view returns(uint) {
        uint balance = _c.peerProfiles[0].deposit
            .add(_c.peerProfiles[1].deposit)
            .sub(_c.peerProfiles[0].withdrawal)
            .sub(_c.peerProfiles[1].withdrawal);
        return balance;
    }









    function getBalanceMap(LedgerStruct.Channel storage _c) public view
        returns(address[2] memory, uint[2] memory, uint[2] memory)
    {
        address[2] memory peerAddrs = [_c.peerProfiles[0].peerAddr, _c.peerProfiles[1].peerAddr];
        uint[2] memory deposits = [_c.peerProfiles[0].deposit, _c.peerProfiles[1].deposit];
        uint[2] memory withdrawals = [_c.peerProfiles[0].withdrawal, _c.peerProfiles[1].withdrawal];
        return (peerAddrs, deposits, withdrawals);
    }










    function getChannelMigrationArgs(
        LedgerStruct.Channel storage _c
    )
        public
        view
        returns(uint, uint, address, uint)
    {
        return (
            _c.disputeTimeout,
            uint(_c.token.tokenType),
            _c.token.tokenAddress,
            _c.cooperativeWithdrawSeqNum
        );
    }












    function getPeersMigrationInfo(
        LedgerStruct.Channel storage _c
    )
        public
        view
        returns(
        address[2] memory,
        uint[2] memory,
        uint[2] memory,
        uint[2] memory,
        uint[2] memory,
        uint[2] memory
    )
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        return (
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            [peerProfiles[0].deposit, peerProfiles[1].deposit],
            [peerProfiles[0].withdrawal, peerProfiles[1].withdrawal],
            [peerProfiles[0].state.seqNum, peerProfiles[1].state.seqNum],
            [peerProfiles[0].state.transferOut, peerProfiles[1].state.transferOut],
            [peerProfiles[0].state.pendingPayOut, peerProfiles[1].state.pendingPayOut]
        );
    }






    function getDisputeTimeout(LedgerStruct.Channel storage _c) public view returns(uint) {
        return _c.disputeTimeout;
    }






    function getMigratedTo(LedgerStruct.Channel storage _c) public view returns(address) {
        return _c.migratedTo;
    }







    function getStateSeqNumMap(
        LedgerStruct.Channel storage _c
    )
        public
        view
        returns(address[2] memory, uint[2] memory)
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        return (
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            [peerProfiles[0].state.seqNum, peerProfiles[1].state.seqNum]
        );
    }







    function getTransferOutMap(
        LedgerStruct.Channel storage _c
    )
        public
        view
        returns(address[2] memory, uint[2] memory)
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        return (
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            [peerProfiles[0].state.transferOut, peerProfiles[1].state.transferOut]
        );
    }







    function getNextPayIdListHashMap(
        LedgerStruct.Channel storage _c
    )
        public
        view
        returns(address[2] memory, bytes32[2] memory)
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        return (
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            [peerProfiles[0].state.nextPayIdListHash, peerProfiles[1].state.nextPayIdListHash]
        );
    }







    function getLastPayResolveDeadlineMap(
        LedgerStruct.Channel storage _c
    )
        public
        view
        returns(address[2] memory, uint[2] memory)
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        return (
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            [peerProfiles[0].state.lastPayResolveDeadline, peerProfiles[1].state.lastPayResolveDeadline]
        );
    }







    function getPendingPayOutMap(
        LedgerStruct.Channel storage _c
    )
        public
        view
        returns(address[2] memory, uint[2] memory)
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        return (
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            [peerProfiles[0].state.pendingPayOut, peerProfiles[1].state.pendingPayOut]
        );
    }









    function getWithdrawIntent(
        LedgerStruct.Channel storage _c
    )
        public
        view
        returns(address, uint, uint, bytes32)
    {
        LedgerStruct.WithdrawIntent memory withdrawIntent = _c.withdrawIntent;
        return (
            withdrawIntent.receiver,
            withdrawIntent.amount,
            withdrawIntent.requestTime,
            withdrawIntent.recipientChannelId
        );
    }








    function _importChannelMigrationArgs(
        LedgerStruct.Channel storage _c,
        address payable _fromLedgerAddr,
        bytes32 _channelId
    )
        internal
    {
        uint tokenType;
        (
            _c.disputeTimeout,
            tokenType,
            _c.token.tokenAddress,
            _c.cooperativeWithdrawSeqNum
        ) = ICelerLedger(_fromLedgerAddr).getChannelMigrationArgs(_channelId);
        _c.token.tokenType = PbEntity.TokenType(tokenType);
    }








    function _importPeersMigrationInfo(
        LedgerStruct.Channel storage _c,
        address payable _fromLedgerAddr,
        bytes32 _channelId
    )
        internal
    {
        (
            address[2] memory peersAddrs,
            uint[2] memory deposits,
            uint[2] memory withdrawals,
            uint[2] memory seqNums,
            uint[2] memory transferOuts,
            uint[2] memory pendingPayOuts
        ) = ICelerLedger(_fromLedgerAddr).getPeersMigrationInfo(_channelId);

        for (uint i = 0; i < 2; i++) {
            LedgerStruct.PeerProfile storage peerProfile = _c.peerProfiles[i];
            peerProfile.peerAddr = peersAddrs[i];
            peerProfile.deposit = deposits[i];
            peerProfile.withdrawal = withdrawals[i];
            peerProfile.state.seqNum = seqNums[i];
            peerProfile.state.transferOut = transferOuts[i];
            peerProfile.state.pendingPayOut = pendingPayOuts[i];
        }
    }





    function _getStateSeqNums(LedgerStruct.Channel storage _c) internal view returns(uint[2] memory) {
        return [_c.peerProfiles[0].state.seqNum, _c.peerProfiles[1].state.seqNum];
    }







    function _isPeer(LedgerStruct.Channel storage _c, address _addr) internal view returns(bool) {
        return _addr == _c.peerProfiles[0].peerAddr || _addr == _c.peerProfiles[1].peerAddr;
    }







     function _getPeerId(LedgerStruct.Channel storage _c, address _peer) internal view returns(uint) {
        if (_peer == _c.peerProfiles[0].peerAddr) {
            return 0;
        } else if (_peer == _c.peerProfiles[1].peerAddr) {
            return 1;
        } else {
            revert("Nonexist peer");
        }
    }








    function _checkSingleSignature(
        LedgerStruct.Channel storage _c,
        bytes32 _h,
        bytes memory _sig
    )
        internal
        view
        returns(bool)
    {
        address addr = _h.toEthSignedMessageHash().recover(_sig);
        return _isPeer(_c, addr);
    }








    function _checkCoSignatures(
        LedgerStruct.Channel storage _c,
        bytes32 _h,
        bytes[] memory _sigs
    )
        internal
        view
        returns(bool)
    {
        if (_sigs.length != 2) {
            return false;
        }


        bytes32 hash = _h.toEthSignedMessageHash();
        address addr;
        for (uint i = 0; i < 2; i++) {
            addr = hash.recover(_sigs[i]);

            if (addr != _c.peerProfiles[i].peerAddr) {
                return false;
            }
        }

        return true;
    }







    function _validateSettleBalance(LedgerStruct.Channel storage _c)
        internal
        view
        returns(bool, uint[2] memory)
    {
        LedgerStruct.PeerProfile[2] memory peerProfiles = _c.peerProfiles;
        uint[2] memory settleBalance = [
            peerProfiles[0].deposit.add(peerProfiles[1].state.transferOut),
            peerProfiles[1].deposit.add(peerProfiles[0].state.transferOut)
        ];
        for (uint i = 0; i < 2; i++) {
            uint subAmt = peerProfiles[i].state.transferOut.add(peerProfiles[i].withdrawal);
            if (settleBalance[i] < subAmt) {
                return (false, [uint(0), uint(0)]);
            }

            settleBalance[i] = settleBalance[i].sub(subAmt);
        }

        return (true, settleBalance);
    }








    function _addWithdrawal(
        LedgerStruct.Channel storage _c,
        address _receiver,
        uint _amount,
        bool _checkBalance
    )
        internal
    {

        uint rid = _getPeerId(_c, _receiver);
        _c.peerProfiles[rid].withdrawal = _c.peerProfiles[rid].withdrawal.add(_amount);
        if (_checkBalance) {
            require(getTotalBalance(_c) >= 0);
        }
    }
}





pragma solidity ^0.5.0;


library PbChain {
    using Pb for Pb.Buffer;

    struct OpenChannelRequest {
        bytes channelInitializer;
        bytes[] sigs;
    }

    function decOpenChannelRequest(bytes memory raw) internal pure returns (OpenChannelRequest memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.sigs = new bytes[](cnts[2]);
        cnts[2] = 0;

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.channelInitializer = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigs[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); }
        }
    }

    struct CooperativeWithdrawRequest {
        bytes withdrawInfo;
        bytes[] sigs;
    }

    function decCooperativeWithdrawRequest(bytes memory raw) internal pure returns (CooperativeWithdrawRequest memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.sigs = new bytes[](cnts[2]);
        cnts[2] = 0;

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.withdrawInfo = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigs[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); }
        }
    }

    struct CooperativeSettleRequest {
        bytes settleInfo;
        bytes[] sigs;
    }

    function decCooperativeSettleRequest(bytes memory raw) internal pure returns (CooperativeSettleRequest memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.sigs = new bytes[](cnts[2]);
        cnts[2] = 0;

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.settleInfo = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigs[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); }
        }
    }

    struct ResolvePayByConditionsRequest {
        bytes condPay;
        bytes[] hashPreimages;
    }

    function decResolvePayByConditionsRequest(bytes memory raw) internal pure returns (ResolvePayByConditionsRequest memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.hashPreimages = new bytes[](cnts[2]);
        cnts[2] = 0;

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.condPay = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.hashPreimages[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); }
        }
    }

    struct SignedSimplexState {
        bytes simplexState;
        bytes[] sigs;
    }

    function decSignedSimplexState(bytes memory raw) internal pure returns (SignedSimplexState memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.sigs = new bytes[](cnts[2]);
        cnts[2] = 0;

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.simplexState = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigs[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); }
        }
    }

    struct SignedSimplexStateArray {
        SignedSimplexState[] signedSimplexStates;
    }

    function decSignedSimplexStateArray(bytes memory raw) internal pure returns (SignedSimplexStateArray memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(1);
        m.signedSimplexStates = new SignedSimplexState[](cnts[1]);
        cnts[1] = 0;

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.signedSimplexStates[cnts[1]] = decSignedSimplexState(buf.decBytes());
                cnts[1]++;
            }
            else { buf.skipValue(wire); }
        }
    }

    struct ChannelMigrationRequest {
        bytes channelMigrationInfo;
        bytes[] sigs;
    }

    function decChannelMigrationRequest(bytes memory raw) internal pure returns (ChannelMigrationRequest memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint[] memory cnts = buf.cntTags(2);
        m.sigs = new bytes[](cnts[2]);
        cnts[2] = 0;

        uint tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            else if (tag == 1) {
                m.channelMigrationInfo = bytes(buf.decBytes());
            }
            else if (tag == 2) {
                m.sigs[cnts[2]] = bytes(buf.decBytes());
                cnts[2]++;
            }
            else { buf.skipValue(wire); }
        }
    }

}



pragma solidity ^0.5.0;




library Address {







    function isContract(address account) internal view returns (bool) {
        uint256 size;







        assembly { size := extcodesize(account) }
        return size > 0;
    }
}



pragma solidity ^0.5.0;





interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity ^0.5.0;









library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {



        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}



pragma solidity ^0.5.1;
















library LedgerOperation {
    using SafeMath for uint;
    using Address for address;
    using SafeERC20 for IERC20;
    using LedgerChannel for LedgerStruct.Channel;







    function openChannel(
        LedgerStruct.Ledger storage _self,
        bytes calldata _openRequest
    )
        external
    {
        PbChain.OpenChannelRequest memory openRequest =
            PbChain.decOpenChannelRequest(_openRequest);
        PbEntity.PaymentChannelInitializer memory channelInitializer =
            PbEntity.decPaymentChannelInitializer(openRequest.channelInitializer);
        require(channelInitializer.initDistribution.distribution.length == 2, "Wrong length");
        require(block.number <= channelInitializer.openDeadline, "Open deadline passed");

        PbEntity.TokenInfo memory token = channelInitializer.initDistribution.token;
        uint[2] memory amounts = [
            channelInitializer.initDistribution.distribution[0].amt,
            channelInitializer.initDistribution.distribution[1].amt
        ];
        address[2] memory peerAddrs = [
            channelInitializer.initDistribution.distribution[0].account,
            channelInitializer.initDistribution.distribution[1].account
        ];

        require(peerAddrs[0] < peerAddrs[1], "Peer addrs are not ascending");

        ICelerWallet celerWallet = _self.celerWallet;
        bytes32 h = keccak256(openRequest.channelInitializer);
        (
            bytes32 channelId,
            LedgerStruct.Channel storage c
        ) = _createWallet(_self, celerWallet, peerAddrs, h);

        c.disputeTimeout = channelInitializer.disputeTimeout;
        _updateChannelStatus(_self, c, LedgerStruct.ChannelStatus.Operable);
        c.token = _validateTokenInfo(token);
        c.peerProfiles[0].peerAddr = peerAddrs[0];
        c.peerProfiles[0].deposit = amounts[0];
        c.peerProfiles[1].peerAddr = peerAddrs[1];
        c.peerProfiles[1].deposit = amounts[1];

        require(c._checkCoSignatures(h, openRequest.sigs), "Check co-sigs failed");

        emit OpenChannel(channelId, uint(token.tokenType), token.tokenAddress, peerAddrs, amounts);

        uint amtSum = amounts[0].add(amounts[1]);

        if (amtSum == 0) {
            require(msg.value == 0, "msg.value is not 0");
            return;
        }


        if (_self.balanceLimitsEnabled) {
            require(amtSum <= _self.balanceLimits[token.tokenAddress], "Balance exceeds limit");
        }

        if (token.tokenType == PbEntity.TokenType.ETH) {
            uint msgValueReceiver = channelInitializer.msgValueReceiver;
            require(msg.value == amounts[msgValueReceiver], "msg.value mismatch");
            if (amounts[msgValueReceiver] > 0) {
                celerWallet.depositETH.value(amounts[msgValueReceiver])(channelId);
            }


            uint pid = uint(1).sub(msgValueReceiver);
            if (amounts[pid] > 0) {
                _self.ethPool.transferToCelerWallet(
                    peerAddrs[pid],
                    address(celerWallet),
                    channelId,
                    amounts[pid]
                );
            }
        } else if (token.tokenType == PbEntity.TokenType.ERC20) {
            require(msg.value == 0, "msg.value is not 0");

            IERC20 erc20Token = IERC20(token.tokenAddress);
            for (uint i = 0; i < 2; i++) {
                if (amounts[i] == 0) { continue; }

                erc20Token.safeTransferFrom(peerAddrs[i], address(this), amounts[i]);
            }
            erc20Token.safeApprove(address(celerWallet), amtSum);
            celerWallet.depositERC20(channelId, address(erc20Token), amtSum);
        } else {
            assert(false);
        }
    }











    function deposit(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        address _receiver,
        uint _transferFromAmount
    )
        public
    {
        uint msgValue = msg.value;

        _addDeposit(_self, _channelId, _receiver, _transferFromAmount.add(msgValue));

        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        if (c.token.tokenType == PbEntity.TokenType.ETH) {
            if (msgValue > 0) {
                _self.celerWallet.depositETH.value(msgValue)(_channelId);
            }
            if (_transferFromAmount > 0) {
                _self.ethPool.transferToCelerWallet(
                    msg.sender,
                    address(_self.celerWallet),
                    _channelId,
                    _transferFromAmount
                );
            }
        } else if (c.token.tokenType == PbEntity.TokenType.ERC20) {
            require(msgValue == 0, "msg.value is not 0");

            IERC20 erc20Token = IERC20(c.token.tokenAddress);
            erc20Token.safeTransferFrom(msg.sender, address(this), _transferFromAmount);
            erc20Token.safeApprove(address(_self.celerWallet), _transferFromAmount);
            _self.celerWallet.depositERC20(_channelId, address(erc20Token), _transferFromAmount);
        } else {
            assert(false);
        }
    }












    function snapshotStates(
        LedgerStruct.Ledger storage _self,
        bytes calldata _signedSimplexStateArray
    )
        external
    {
        PbChain.SignedSimplexStateArray memory signedSimplexStateArray =
            PbChain.decSignedSimplexStateArray(_signedSimplexStateArray);
        uint simplexStatesNum = signedSimplexStateArray.signedSimplexStates.length;


        PbEntity.SimplexPaymentChannel memory simplexState =
            PbEntity.decSimplexPaymentChannel(signedSimplexStateArray.signedSimplexStates[0].simplexState);
        for (uint i = 0; i < simplexStatesNum; i++) {
            bytes32 currentChannelId = simplexState.channelId;
            LedgerStruct.Channel storage c = _self.channelMap[currentChannelId];

            require(c.status == LedgerStruct.ChannelStatus.Operable, "Channel status error");

            bytes32 stateHash = keccak256(signedSimplexStateArray.signedSimplexStates[i].simplexState);
            bytes[] memory sigs = signedSimplexStateArray.signedSimplexStates[i].sigs;
            require(c._checkCoSignatures(stateHash, sigs), "Check co-sigs failed");
            uint peerFromId = c._getPeerId(simplexState.peerFrom);
            LedgerStruct.PeerState storage state = c.peerProfiles[peerFromId].state;
            require(simplexState.seqNum > state.seqNum, "seqNum error");


            state.seqNum = simplexState.seqNum;
            state.transferOut = simplexState.transferToPeer.receiver.amt;
            state.pendingPayOut = simplexState.totalPendingAmount;

            if (i == simplexStatesNum.sub(1)) {
                emit SnapshotStates(currentChannelId, c._getStateSeqNums());
            } else if (i < simplexStatesNum.sub(1)) {
                simplexState = PbEntity.decSimplexPaymentChannel(
                    signedSimplexStateArray.signedSimplexStates[i+1].simplexState
                );

                require(currentChannelId <= simplexState.channelId, "Non-ascending channelIds");
                if (currentChannelId < simplexState.channelId) {
                    emit SnapshotStates(currentChannelId, c._getStateSeqNums());
                }
            } else {
                assert(false);
            }
        }
    }










    function intendWithdraw(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        uint _amount,
        bytes32 _recipientChannelId
    )
        public
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        LedgerStruct.PeerProfile[2] storage peerProfiles = c.peerProfiles;
        LedgerStruct.WithdrawIntent storage withdrawIntent = c.withdrawIntent;
        address receiver = msg.sender;
        require(c.status == LedgerStruct.ChannelStatus.Operable, "Channel status error");


        require(withdrawIntent.receiver == address(0), "Pending withdraw intent exists");



        uint rid = c._getPeerId(receiver);
        uint pid = uint(1).sub(rid);
        uint withdrawLimit = peerProfiles[rid].deposit
            .add(peerProfiles[pid].state.transferOut)
            .sub(peerProfiles[rid].withdrawal)
            .sub(peerProfiles[rid].state.transferOut)
            .sub(peerProfiles[rid].state.pendingPayOut);
        require(_amount <= withdrawLimit, "Exceed withdraw limit");

        withdrawIntent.receiver = receiver;
        withdrawIntent.amount = _amount;
        withdrawIntent.requestTime = block.number;
        withdrawIntent.recipientChannelId = _recipientChannelId;

        emit IntendWithdraw(_channelId, receiver, _amount);
    }







    function confirmWithdraw(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId
    )
        public
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        require(c.status == LedgerStruct.ChannelStatus.Operable, "Channel status error");
        require(c.withdrawIntent.receiver != address(0), "No pending withdraw intent");
        require(
            block.number >= c.withdrawIntent.requestTime.add(c.disputeTimeout),
            "Dispute not timeout"
        );

        address receiver = c.withdrawIntent.receiver;
        uint amount = c.withdrawIntent.amount;
        bytes32 recipientChannelId = c.withdrawIntent.recipientChannelId;
        delete c.withdrawIntent;



        c._addWithdrawal(receiver, amount, false);

        (, uint[2] memory deposits, uint[2] memory withdrawals) = c.getBalanceMap();
        emit ConfirmWithdraw(_channelId, amount, receiver, recipientChannelId, deposits, withdrawals);

        _withdrawFunds(_self, _channelId, receiver, amount, recipientChannelId);
    }








    function vetoWithdraw(LedgerStruct.Ledger storage _self, bytes32 _channelId) public {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        require(c.status == LedgerStruct.ChannelStatus.Operable, "Channel status error");
        require(c.withdrawIntent.receiver != address(0), "No pending withdraw intent");
        require(c._isPeer(msg.sender), "msg.sender is not peer");

        delete c.withdrawIntent;

        emit VetoWithdraw(_channelId);
    }






    function cooperativeWithdraw(
        LedgerStruct.Ledger storage _self,
        bytes calldata _cooperativeWithdrawRequest
    )
        external
    {
        PbChain.CooperativeWithdrawRequest memory cooperativeWithdrawRequest =
            PbChain.decCooperativeWithdrawRequest(_cooperativeWithdrawRequest);
        PbEntity.CooperativeWithdrawInfo memory withdrawInfo =
            PbEntity.decCooperativeWithdrawInfo(cooperativeWithdrawRequest.withdrawInfo);
        bytes32 channelId = withdrawInfo.channelId;
        bytes32 recipientChannelId = withdrawInfo.recipientChannelId;
        LedgerStruct.Channel storage c = _self.channelMap[channelId];

        require(c.status == LedgerStruct.ChannelStatus.Operable, "Channel status error");
        bytes32 h = keccak256(cooperativeWithdrawRequest.withdrawInfo);
        require(
            c._checkCoSignatures(h, cooperativeWithdrawRequest.sigs),
            "Check co-sigs failed"
        );

        require(
            withdrawInfo.seqNum.sub(c.cooperativeWithdrawSeqNum) == 1,
            "seqNum error"
        );
        require(block.number <= withdrawInfo.withdrawDeadline, "Withdraw deadline passed");

        address receiver = withdrawInfo.withdraw.account;
        c.cooperativeWithdrawSeqNum = withdrawInfo.seqNum;
        uint amount = withdrawInfo.withdraw.amt;


        c._addWithdrawal(receiver, amount, true);

        (, uint[2] memory deposits, uint[2] memory withdrawals) = c.getBalanceMap();
        emit CooperativeWithdraw(
            channelId,
            amount,
            receiver,
            recipientChannelId,
            deposits,
            withdrawals,
            withdrawInfo.seqNum
        );

        _withdrawFunds(_self, channelId, receiver, amount, recipientChannelId);
    }











    function intendSettle(
        LedgerStruct.Ledger storage _self,
        bytes calldata _signedSimplexStateArray
    )
        external
    {
        PbChain.SignedSimplexStateArray memory signedSimplexStateArray =
            PbChain.decSignedSimplexStateArray(_signedSimplexStateArray);
        uint simplexStatesNum = signedSimplexStateArray.signedSimplexStates.length;

        PbEntity.SimplexPaymentChannel memory simplexState =
            PbEntity.decSimplexPaymentChannel(signedSimplexStateArray.signedSimplexStates[0].simplexState);
        for (uint i = 0; i < simplexStatesNum; i++) {
            bytes32 currentChannelId = simplexState.channelId;
            LedgerStruct.Channel storage c = _self.channelMap[currentChannelId];
            require(
                c.status == LedgerStruct.ChannelStatus.Operable ||
                c.status == LedgerStruct.ChannelStatus.Settling,
                "Channel status error"
            );
            require(
                c.settleFinalizedTime == 0 || block.number < c.settleFinalizedTime,
                "Settle has already finalized"
            );

            bytes32 stateHash = keccak256(signedSimplexStateArray.signedSimplexStates[i].simplexState);
            bytes[] memory sigs = signedSimplexStateArray.signedSimplexStates[i].sigs;

            if (simplexState.seqNum > 0) {
                require(c._checkCoSignatures(stateHash, sigs), "Check co-sigs failed");
                uint peerFromId = c._getPeerId(simplexState.peerFrom);
                LedgerStruct.PeerState storage state = c.peerProfiles[peerFromId].state;

                if (c.status == LedgerStruct.ChannelStatus.Operable) {

                    require(simplexState.seqNum >= state.seqNum, "seqNum error");
                } else if (c.status == LedgerStruct.ChannelStatus.Settling) {
                    require(simplexState.seqNum > state.seqNum, "seqNum error");
                } else {
                    assert(false);
                }



                state.seqNum = simplexState.seqNum;
                state.transferOut = simplexState.transferToPeer.receiver.amt;
                state.nextPayIdListHash = simplexState.pendingPayIds.nextListHash;
                state.lastPayResolveDeadline = simplexState.lastPayResolveDeadline;
                _clearPays(_self, currentChannelId, peerFromId, simplexState.pendingPayIds.payIds);
            } else if (simplexState.seqNum == 0) {

                require(c.settleFinalizedTime == 0, "intendSettle before");
                require(
                    sigs.length == 1 && c._checkSingleSignature(stateHash, sigs[0]),
                    "Check sig failed"
                );
            } else {
                assert(false);
            }

            if (i == simplexStatesNum.sub(1)) {
                _updateOverallStatesByIntendState(_self, currentChannelId);
            } else if (i < simplexStatesNum.sub(1)) {
                simplexState = PbEntity.decSimplexPaymentChannel(
                    signedSimplexStateArray.signedSimplexStates[i+1].simplexState
                );

                require(currentChannelId <= simplexState.channelId, "Non-ascending channelIds");
                if (currentChannelId < simplexState.channelId) {
                    _updateOverallStatesByIntendState(_self, currentChannelId);
                }
            } else {
                assert(false);
            }
        }
    }








    function clearPays(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        address _peerFrom,
        bytes calldata _payIdList
    )
        external
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        require(c.status == LedgerStruct.ChannelStatus.Settling, "Channel status error");
        uint peerFromId = c._getPeerId(_peerFrom);

        bytes32 listHash = keccak256(_payIdList);
        LedgerStruct.PeerState storage state = c.peerProfiles[peerFromId].state;
        require(state.nextPayIdListHash == listHash, "List hash mismatch");

        PbEntity.PayIdList memory payIdList = PbEntity.decPayIdList(_payIdList);
        state.nextPayIdListHash = payIdList.nextListHash;
        _clearPays(_self, _channelId, peerFromId, payIdList.payIds);
    }







    function confirmSettle(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId
    )
        public
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        LedgerStruct.PeerProfile[2] storage peerProfiles = c.peerProfiles;
        uint blockNumber = block.number;
        require(c.status == LedgerStruct.ChannelStatus.Settling, "Channel status error");

        require(blockNumber >= c.settleFinalizedTime, "Settle is not finalized");







        require(
            (peerProfiles[0].state.nextPayIdListHash == bytes32(0) ||
                blockNumber > peerProfiles[0].state.lastPayResolveDeadline) &&
            (peerProfiles[1].state.nextPayIdListHash == bytes32(0) ||
                blockNumber > peerProfiles[1].state.lastPayResolveDeadline),
            "Payments are not finalized"
        );

        (bool validBalance, uint[2] memory settleBalance) = c._validateSettleBalance();
        if (!validBalance) {
            _resetDuplexState(_self, c);
            emit ConfirmSettleFail(_channelId);
            return;
        }

        _updateChannelStatus(_self, c, LedgerStruct.ChannelStatus.Closed);

        emit ConfirmSettle(_channelId, settleBalance);



        _batchTransferOut(
            _self,
            _channelId,
            c.token.tokenAddress,
            [peerProfiles[0].peerAddr, peerProfiles[1].peerAddr],
            settleBalance
        );
    }






    function cooperativeSettle(
        LedgerStruct.Ledger storage _self,
        bytes calldata _settleRequest
    )
        external
    {
        PbChain.CooperativeSettleRequest memory settleRequest =
            PbChain.decCooperativeSettleRequest(_settleRequest);
        PbEntity.CooperativeSettleInfo memory settleInfo =
            PbEntity.decCooperativeSettleInfo(settleRequest.settleInfo);
        bytes32 channelId = settleInfo.channelId;
        LedgerStruct.Channel storage c = _self.channelMap[channelId];
        require(
            c.status == LedgerStruct.ChannelStatus.Operable ||
            c.status == LedgerStruct.ChannelStatus.Settling,
            "Channel status error"
        );

        bytes32 h = keccak256(settleRequest.settleInfo);
        require(c._checkCoSignatures(h, settleRequest.sigs), "Check co-sigs failed");

        address[2] memory peerAddrs = [c.peerProfiles[0].peerAddr, c.peerProfiles[1].peerAddr];
        require(
            settleInfo.seqNum > c.peerProfiles[0].state.seqNum &&
                settleInfo.seqNum > c.peerProfiles[1].state.seqNum,
            "seqNum error"
        );
        require(settleInfo.settleDeadline >= block.number, "Settle deadline passed");

        require(
            settleInfo.settleBalance[0].account == peerAddrs[0] &&
                settleInfo.settleBalance[1].account == peerAddrs[1],
            "Settle accounts mismatch"
        );

        uint[2] memory settleBalance = [
            settleInfo.settleBalance[0].amt,
            settleInfo.settleBalance[1].amt
        ];
        require(settleBalance[0].add(settleBalance[1]) == c.getTotalBalance(), "Balance sum mismatch");

        _updateChannelStatus(_self, c, LedgerStruct.ChannelStatus.Closed);

        emit CooperativeSettle(channelId, settleBalance);

        _batchTransferOut(_self, channelId, c.token.tokenAddress, peerAddrs, settleBalance);
    }







    function getChannelStatusNum(
        LedgerStruct.Ledger storage _self,
        uint _channelStatus
    )
        public
        view
        returns(uint)
    {
        return _self.channelStatusNums[_channelStatus];
    }






    function getEthPool(LedgerStruct.Ledger storage _self) public view returns(address) {
        return address(_self.ethPool);
    }






    function getPayRegistry(LedgerStruct.Ledger storage _self) public view returns(address) {
        return address(_self.payRegistry);
    }






    function getCelerWallet(LedgerStruct.Ledger storage _self) public view returns(address) {
        return address(_self.celerWallet);
    }










    function _createWallet(
        LedgerStruct.Ledger storage _self,
        ICelerWallet _w,
        address[2] memory _peers,
        bytes32 _nonce
    )
        internal
        returns(bytes32, LedgerStruct.Channel storage)
    {
        address[] memory owners = new address[](2);
        owners[0] = _peers[0];
        owners[1] = _peers[1];


        bytes32 channelId = _w.create(owners, address(this), _nonce);

        require(channelId != bytes32(0), "channelId gets 0");
        LedgerStruct.Channel storage c = _self.channelMap[channelId];

        require(c.status == LedgerStruct.ChannelStatus.Uninitialized, "Occupied channelId");

        return (channelId, c);
    }








    function _addDeposit(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        address _receiver,
        uint _amount
    )
        internal
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        require(c.status == LedgerStruct.ChannelStatus.Operable, "Channel status error");


        uint rid = c._getPeerId(_receiver);
        if (_self.balanceLimitsEnabled) {
            require(
                _amount.add(c.getTotalBalance()) <= _self.balanceLimits[c.token.tokenAddress],
                "Balance exceeds limit"
            );
        }

        c.peerProfiles[rid].deposit = c.peerProfiles[rid].deposit.add(_amount);

        (
            address[2] memory peerAddrs,
            uint[2] memory deposits,
            uint[2] memory withdrawals
        ) = c.getBalanceMap();
        emit Deposit(_channelId, peerAddrs, deposits, withdrawals);
    }









    function _batchTransferOut(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        address _tokenAddr,
        address[2] memory _receivers,
        uint[2] memory _amounts
    )
        internal
    {
        for (uint i = 0; i < 2; i++) {
            if (_amounts[i] == 0) { continue; }

            _self.celerWallet.withdraw(_channelId, _tokenAddr, _receivers[i], _amounts[i]);
        }
    }









    function _withdrawFunds(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        address _receiver,
        uint _amount,
        bytes32 _recipientChannelId
    )
        internal
    {
        if (_amount == 0) { return; }

        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        if (_recipientChannelId == bytes32(0)) {
            _self.celerWallet.withdraw(_channelId, c.token.tokenAddress, _receiver, _amount);
        } else {
            LedgerStruct.Channel storage recipientChannel = _self.channelMap[_recipientChannelId];
            require(
                c.token.tokenType == recipientChannel.token.tokenType &&
                    c.token.tokenAddress == recipientChannel.token.tokenAddress,
                "Token mismatch of recipient channel"
            );
            _addDeposit(_self, _recipientChannelId, _receiver, _amount);


            _self.celerWallet.transferToWallet(
                _channelId,
                _recipientChannelId,
                c.token.tokenAddress,
                _receiver,
                _amount
            );
        }
    }






    function _resetDuplexState(
        LedgerStruct.Ledger storage _self,
        LedgerStruct.Channel storage _c
    )
        internal
    {
        delete _c.settleFinalizedTime;
        _updateChannelStatus(_self, _c, LedgerStruct.ChannelStatus.Operable);
        delete _c.peerProfiles[0].state;
        delete _c.peerProfiles[1].state;

        delete _c.withdrawIntent;
    }








    function _clearPays(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId,
        uint _peerId,
        bytes32[] memory _payIds
    )
        internal
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        uint[] memory outAmts = _self.payRegistry.getPayAmounts(
            _payIds,
            c.peerProfiles[_peerId].state.lastPayResolveDeadline
        );

        uint totalAmtOut = 0;
        for (uint i = 0; i < outAmts.length; i++) {
            totalAmtOut = totalAmtOut.add(outAmts[i]);
            emit ClearOnePay(_channelId, _payIds[i], c.peerProfiles[_peerId].peerAddr, outAmts[i]);
        }
        c.peerProfiles[_peerId].state.transferOut =
            c.peerProfiles[_peerId].state.transferOut.add(totalAmtOut);
    }






    function _updateOverallStatesByIntendState(
        LedgerStruct.Ledger storage _self,
        bytes32 _channelId
    )
        internal
    {
        LedgerStruct.Channel storage c = _self.channelMap[_channelId];
        c.settleFinalizedTime = block.number.add(c.disputeTimeout);
        _updateChannelStatus(_self, c, LedgerStruct.ChannelStatus.Settling);

        emit IntendSettle(_channelId, c._getStateSeqNums());
    }







    function _updateChannelStatus(
        LedgerStruct.Ledger storage _self,
        LedgerStruct.Channel storage _c,
        LedgerStruct.ChannelStatus _newStatus
    )
        internal
    {
        if (_c.status == _newStatus) {
            return;
        }


        if (_c.status != LedgerStruct.ChannelStatus.Uninitialized) {
            _self.channelStatusNums[uint(_c.status)] = _self.channelStatusNums[uint(_c.status)].sub(1);
        }


        _self.channelStatusNums[uint(_newStatus)] = _self.channelStatusNums[uint(_newStatus)].add(1);

        _c.status = _newStatus;
    }






    function _validateTokenInfo(PbEntity.TokenInfo memory _token)
        internal
        view
        returns(PbEntity.TokenInfo memory)
    {
        if (_token.tokenType == PbEntity.TokenType.ETH) {
            require(_token.tokenAddress == address(0));
        } else if (_token.tokenType == PbEntity.TokenType.ERC20) {
            require(_token.tokenAddress != address(0));
            require(_token.tokenAddress.isContract());
        } else {
            assert(false);
        }

        return _token;
    }

    event OpenChannel(
        bytes32 indexed channelId,
        uint tokenType,
        address indexed tokenAddress,

        address[2] peerAddrs,
        uint[2] initialDeposits
    );


    event Deposit(bytes32 indexed channelId, address[2] peerAddrs, uint[2] deposits, uint[2] withdrawals);

    event SnapshotStates(bytes32 indexed channelId, uint[2] seqNums);

    event IntendSettle(bytes32 indexed channelId, uint[2] seqNums);

    event ClearOnePay(bytes32 indexed channelId, bytes32 indexed payId, address indexed peerFrom, uint amount);

    event ConfirmSettle(bytes32 indexed channelId, uint[2] settleBalance);

    event ConfirmSettleFail(bytes32 indexed channelId);

    event IntendWithdraw(bytes32 indexed channelId, address indexed receiver, uint amount);

    event ConfirmWithdraw(
        bytes32 indexed channelId,
        uint withdrawnAmount,
        address indexed receiver,
        bytes32 indexed recipientChannelId,
        uint[2] deposits,
        uint[2] withdrawals
    );

    event VetoWithdraw(bytes32 indexed channelId);

    event CooperativeWithdraw(
        bytes32 indexed channelId,
        uint withdrawnAmount,
        address indexed receiver,
        bytes32 indexed recipientChannelId,
        uint[2] deposits,
        uint[2] withdrawals,
        uint seqNum
    );

    event CooperativeSettle(bytes32 indexed channelId, uint[2] settleBalance);
}
