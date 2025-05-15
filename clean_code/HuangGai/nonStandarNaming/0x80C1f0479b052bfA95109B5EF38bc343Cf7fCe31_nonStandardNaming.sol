

pragma solidity 0.5.15;



contract YUANGovernanceStorage {

    mapping(address => address) internal _delegates;


    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }


    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;


    mapping(address => uint32) public numCheckpoints;


    bytes32 public constant domain_typehash467 = keccak256(
        "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );


    bytes32 public constant delegation_typehash708 = keccak256(
        "Delegation(address delegatee,uint256 nonce,uint256 expiry)"
    );


    mapping(address => uint256) public nonces;
}


contract YUANTokenStorage {
    using SafeMath for uint256;


    bool internal _notEntered;


    string public name;


    string public symbol;


    uint8 public decimals;


    address public gov;


    address public pendingGov;


    address public rebaser;


    address public migrator;


    address public incentivizer;


    uint256 public totalSupply;


    uint256 public constant internaldecimals289 = 10**24;


    uint256 public constant base843 = 10**18;


    uint256 public yuansScalingFactor;

    mapping(address => uint256) internal _yuanBalances;

    mapping(address => mapping(address => uint256)) internal _allowedFragments;

    uint256 public initSupply;


    bytes32
        public constant permit_typehash503 = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    bytes32 public DOMAIN_SEPARATOR;
}

contract YUANTokenInterface is YUANTokenStorage, YUANGovernanceStorage {

    event DELEGATECHANGED444(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );


    event DELEGATEVOTESCHANGED965(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );


    event REBASE678(
        uint256 epoch,
        uint256 prevYuansScalingFactor,
        uint256 newYuansScalingFactor
    );




    event NEWPENDINGGOV591(address oldPendingGov, address newPendingGov);


    event NEWGOV954(address oldGov, address newGov);


    event NEWREBASER453(address oldRebaser, address newRebaser);


    event NEWMIGRATOR48(address oldMigrator, address newMigrator);


    event NEWINCENTIVIZER28(address oldIncentivizer, address newIncentivizer);




    event TRANSFER462(address indexed from, address indexed to, uint256 amount);


    event APPROVAL374(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );



    event MINT854(address to, uint256 amount);


    function TRANSFER508(address to, uint256 value) external returns (bool);

    function TRANSFERFROM276(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function BALANCEOF369(address who) external view returns (uint256);

    function BALANCEOFUNDERLYING28(address who) external view returns (uint256);

    function ALLOWANCE671(address owner_, address spender)
        external
        view
        returns (uint256);

    function APPROVE975(address spender, uint256 value) external returns (bool);

    function INCREASEALLOWANCE36(address spender, uint256 addedValue)
        external
        returns (bool);

    function DECREASEALLOWANCE115(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function MAXSCALINGFACTOR640() external view returns (uint256);

    function YUANTOFRAGMENT975(uint256 yuan) external view returns (uint256);

    function FRAGMENTTOYUAN110(uint256 value) external view returns (uint256);


    function GETPRIORVOTES568(address account, uint256 blockNumber)
        external
        view
        returns (uint256);

    function DELEGATEBYSIG273(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function DELEGATE794(address delegatee) external;

    function DELEGATES57(address delegator) external view returns (address);

    function GETCURRENTVOTES80(address account) external view returns (uint256);


    function MINT564(address to, uint256 amount) external returns (bool);

    function REBASE123(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    ) external returns (uint256);

    function _SETREBASER150(address rebaser_) external;

    function _SETINCENTIVIZER861(address incentivizer_) external;

    function _SETPENDINGGOV492(address pendingGov_) external;

    function _ACCEPTGOV305() external;
}

contract YUANGovernanceToken is YUANTokenInterface {

    event DELEGATECHANGED444(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );


    event DELEGATEVOTESCHANGED965(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );


    function DELEGATES57(address delegator) external view returns (address) {
        return _delegates[delegator];
    }


    function DELEGATE794(address delegatee) external {
        return _DELEGATE422(msg.sender, delegatee);
    }


    function DELEGATEBYSIG273(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 structHash = keccak256(
            abi.encode(delegation_typehash708, delegatee, nonce, expiry)
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );

        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "YUAN::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "YUAN::delegateBySig: invalid nonce"
        );
        require(now <= expiry, "YUAN::delegateBySig: signature expired");
        return _DELEGATE422(signatory, delegatee);
    }


    function GETCURRENTVOTES80(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }


    function GETPRIORVOTES568(address account, uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "YUAN::getPriorVotes: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }


        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }


        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _DELEGATE422(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = _yuanBalances[delegator];
        _delegates[delegator] = delegatee;

        emit DELEGATECHANGED444(delegator, currentDelegate, delegatee);

        _MOVEDELEGATES829(currentDelegate, delegatee, delegatorBalance);
    }

    function _MOVEDELEGATES829(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {

                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint256 srcRepNew = srcRepOld.SUB548(amount);
                _WRITECHECKPOINT921(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {

                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint256 dstRepNew = dstRepOld.ADD618(amount);
                _WRITECHECKPOINT921(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _WRITECHECKPOINT921(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber = SAFE32762(
            block.number,
            "YUAN::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DELEGATEVOTESCHANGED965(delegatee, oldVotes, newVotes);
    }

    function SAFE32762(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function GETCHAINID188() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}


interface IERC20 {

    function TOTALSUPPLY978() external view returns (uint256);


    function BALANCEOF369(address account) external view returns (uint256);


    function TRANSFER508(address recipient, uint256 amount)
        external
        returns (bool);


    function ALLOWANCE671(address owner, address spender)
        external
        view
        returns (uint256);


    function APPROVE975(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM276(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    event TRANSFER462(address indexed from, address indexed to, uint256 value);


    event APPROVAL374(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


library SafeMath {

    function ADD618(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB548(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB548(a, b, "SafeMath: subtraction overflow");
    }


    function SUB548(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL341(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV216(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV216(a, b, "SafeMath: division by zero");
    }


    function DIV216(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD958(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD958(a, b, "SafeMath: modulo by zero");
    }


    function MOD958(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {

    function ISCONTRACT826(address account) internal view returns (bool) {




        uint256 size;

        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }


    function SENDVALUE586(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );


        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }


    function FUNCTIONCALL879(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return FUNCTIONCALL879(target, data, "Address: low-level call failed");
    }


    function FUNCTIONCALL879(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _FUNCTIONCALLWITHVALUE730(target, data, 0, errorMessage);
    }


    function FUNCTIONCALLWITHVALUE156(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            FUNCTIONCALLWITHVALUE156(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }


    function FUNCTIONCALLWITHVALUE156(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _FUNCTIONCALLWITHVALUE730(target, data, value, errorMessage);
    }

    function _FUNCTIONCALLWITHVALUE730(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(ISCONTRACT826(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call.value(weiValue)(
            data
        );
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER589(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _CALLOPTIONALRETURN469(
            token,
            abi.encodeWithSelector(token.TRANSFER508.selector, to, value)
        );
    }

    function SAFETRANSFERFROM16(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _CALLOPTIONALRETURN469(
            token,
            abi.encodeWithSelector(token.TRANSFERFROM276.selector, from, to, value)
        );
    }


    function SAFEAPPROVE191(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {




        require(
            (value == 0) || (token.ALLOWANCE671(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _CALLOPTIONALRETURN469(
            token,
            abi.encodeWithSelector(token.APPROVE975.selector, spender, value)
        );
    }

    function SAFEINCREASEALLOWANCE753(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.ALLOWANCE671(address(this), spender).ADD618(
            value
        );
        _CALLOPTIONALRETURN469(
            token,
            abi.encodeWithSelector(
                token.APPROVE975.selector,
                spender,
                newAllowance
            )
        );
    }

    function SAFEDECREASEALLOWANCE777(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.ALLOWANCE671(address(this), spender).SUB548(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _CALLOPTIONALRETURN469(
            token,
            abi.encodeWithSelector(
                token.APPROVE975.selector,
                spender,
                newAllowance
            )
        );
    }


    function _CALLOPTIONALRETURN469(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).FUNCTIONCALL879(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {


            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract YUANToken is YUANGovernanceToken {

    modifier ONLYGOV644() {
        require(msg.sender == gov);
        _;
    }

    modifier ONLYREBASER711() {
        require(msg.sender == rebaser);
        _;
    }

    modifier ONLYMINTER815() {
        require(
            msg.sender == rebaser ||
                msg.sender == gov ||
                msg.sender == incentivizer ||
                msg.sender == migrator,
            "not minter"
        );
        _;
    }

    modifier VALIDRECIPIENT953(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    function INITIALIZE963(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public {
        require(yuansScalingFactor == 0, "already initialized");
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }


    function MAXSCALINGFACTOR640() external view returns (uint256) {
        return _MAXSCALINGFACTOR654();
    }

    function _MAXSCALINGFACTOR654() internal view returns (uint256) {


        return uint256(-1) / initSupply;
    }


    function MINT564(address to, uint256 amount)
        external
        ONLYMINTER815
        returns (bool)
    {
        _MINT778(to, amount);
        return true;
    }

    function _MINT778(address to, uint256 amount) internal {
        if (msg.sender == migrator) {



            initSupply = initSupply.ADD618(amount);


            uint256 scaledAmount = _YUANTOFRAGMENT236(amount);


            totalSupply = totalSupply.ADD618(scaledAmount);


            require(
                yuansScalingFactor <= _MAXSCALINGFACTOR654(),
                "max scaling factor too low"
            );


            _yuanBalances[to] = _yuanBalances[to].ADD618(amount);


            _MOVEDELEGATES829(address(0), _delegates[to], amount);
            emit MINT854(to, scaledAmount);
            emit TRANSFER462(address(0), to, scaledAmount);
        } else {

            totalSupply = totalSupply.ADD618(amount);


            uint256 yuanValue = _FRAGMENTTOYUAN426(amount);


            initSupply = initSupply.ADD618(yuanValue);


            require(
                yuansScalingFactor <= _MAXSCALINGFACTOR654(),
                "max scaling factor too low"
            );


            _yuanBalances[to] = _yuanBalances[to].ADD618(yuanValue);


            _MOVEDELEGATES829(address(0), _delegates[to], yuanValue);
            emit MINT854(to, amount);
            emit TRANSFER462(address(0), to, amount);
        }
    }




    function TRANSFER508(address to, uint256 value)
        external
        VALIDRECIPIENT953(to)
        returns (bool)
    {






        uint256 yuanValue = _FRAGMENTTOYUAN426(value);


        _yuanBalances[msg.sender] = _yuanBalances[msg.sender].SUB548(yuanValue);


        _yuanBalances[to] = _yuanBalances[to].ADD618(yuanValue);
        emit TRANSFER462(msg.sender, to, value);

        _MOVEDELEGATES829(_delegates[msg.sender], _delegates[to], yuanValue);
        return true;
    }


    function TRANSFERFROM276(
        address from,
        address to,
        uint256 value
    ) external VALIDRECIPIENT953(to) returns (bool) {

        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg
            .sender]
            .SUB548(value);


        uint256 yuanValue = _FRAGMENTTOYUAN426(value);


        _yuanBalances[from] = _yuanBalances[from].SUB548(yuanValue);
        _yuanBalances[to] = _yuanBalances[to].ADD618(yuanValue);
        emit TRANSFER462(from, to, value);

        _MOVEDELEGATES829(_delegates[from], _delegates[to], yuanValue);
        return true;
    }


    function BALANCEOF369(address who) external view returns (uint256) {
        return _YUANTOFRAGMENT236(_yuanBalances[who]);
    }


    function BALANCEOFUNDERLYING28(address who) external view returns (uint256) {
        return _yuanBalances[who];
    }


    function ALLOWANCE671(address owner_, address spender)
        external
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }


    function APPROVE975(address spender, uint256 value) external returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit APPROVAL374(msg.sender, spender, value);
        return true;
    }


    function INCREASEALLOWANCE36(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg
            .sender][spender]
            .ADD618(addedValue);
        emit APPROVAL374(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }


    function DECREASEALLOWANCE115(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.SUB548(
                subtractedValue
            );
        }
        emit APPROVAL374(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }


    function PERMIT439(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(now <= deadline, "YUAN/permit-expired");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        permit_typehash503,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );

        require(owner != address(0), "YUAN/invalid-address-0");
        require(owner == ecrecover(digest, v, r, s), "YUAN/invalid-permit");
        _allowedFragments[owner][spender] = value;
        emit APPROVAL374(owner, spender, value);
    }




    function _SETREBASER150(address rebaser_) external ONLYGOV644 {
        address oldRebaser = rebaser;
        rebaser = rebaser_;
        emit NEWREBASER453(oldRebaser, rebaser_);
    }


    function _SETMIGRATOR264(address migrator_) external ONLYGOV644 {
        address oldMigrator = migrator_;
        migrator = migrator_;
        emit NEWMIGRATOR48(oldMigrator, migrator_);
    }


    function _SETINCENTIVIZER861(address incentivizer_) external ONLYGOV644 {
        address oldIncentivizer = incentivizer;
        incentivizer = incentivizer_;
        emit NEWINCENTIVIZER28(oldIncentivizer, incentivizer_);
    }


    function _SETPENDINGGOV492(address pendingGov_) external ONLYGOV644 {
        address oldPendingGov = pendingGov;
        pendingGov = pendingGov_;
        emit NEWPENDINGGOV591(oldPendingGov, pendingGov_);
    }


    function _ACCEPTGOV305() external {
        require(msg.sender == pendingGov, "!pending");
        address oldGov = gov;
        gov = pendingGov;
        pendingGov = address(0);
        emit NEWGOV954(oldGov, gov);
    }




    function REBASE123(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    ) external ONLYREBASER711 returns (uint256) {

        if (indexDelta == 0) {
            emit REBASE678(epoch, yuansScalingFactor, yuansScalingFactor);
            return totalSupply;
        }


        uint256 prevYuansScalingFactor = yuansScalingFactor;

        if (!positive) {

            yuansScalingFactor = yuansScalingFactor
                .MUL341(base843.SUB548(indexDelta))
                .DIV216(base843);
        } else {

            uint256 newScalingFactor = yuansScalingFactor
                .MUL341(base843.ADD618(indexDelta))
                .DIV216(base843);
            if (newScalingFactor < _MAXSCALINGFACTOR654()) {
                yuansScalingFactor = newScalingFactor;
            } else {
                yuansScalingFactor = _MAXSCALINGFACTOR654();
            }
        }


        totalSupply = _YUANTOFRAGMENT236(initSupply);

        emit REBASE678(epoch, prevYuansScalingFactor, yuansScalingFactor);
        return totalSupply;
    }

    function YUANTOFRAGMENT975(uint256 yuan) external view returns (uint256) {
        return _YUANTOFRAGMENT236(yuan);
    }

    function FRAGMENTTOYUAN110(uint256 value) external view returns (uint256) {
        return _FRAGMENTTOYUAN426(value);
    }

    function _YUANTOFRAGMENT236(uint256 yuan) internal view returns (uint256) {
        return yuan.MUL341(yuansScalingFactor).DIV216(internaldecimals289);
    }

    function _FRAGMENTTOYUAN426(uint256 value) internal view returns (uint256) {
        return value.MUL341(internaldecimals289).DIV216(yuansScalingFactor);
    }


    function RESCUETOKENS788(
        address token,
        address to,
        uint256 amount
    ) external ONLYGOV644 returns (bool) {

        SafeERC20.SAFETRANSFER589(IERC20(token), to, amount);
        return true;
    }
}

contract YUAN is YUANToken {

    function INITIALIZE963(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address initial_owner,
        uint256 initTotalSupply_
    ) public {
        super.INITIALIZE963(name_, symbol_, decimals_);

        yuansScalingFactor = base843;
        initSupply = _FRAGMENTTOYUAN426(initTotalSupply_);
        totalSupply = initTotalSupply_;
        _yuanBalances[initial_owner] = initSupply;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                domain_typehash467,
                keccak256(bytes(name)),
                GETCHAINID188(),
                address(this)
            )
        );
    }
}

contract YUANDelegationStorage {

    address public implementation;
}

contract YUANDelegatorInterface is YUANDelegationStorage {

    event NEWIMPLEMENTATION947(
        address oldImplementation,
        address newImplementation
    );


    function _SETIMPLEMENTATION470(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) public;
}

contract YUANDelegateInterface is YUANDelegationStorage {

    function _BECOMEIMPLEMENTATION61(bytes memory data) public;


    function _RESIGNIMPLEMENTATION160() public;
}

contract YUANDelegate is YUAN, YUANDelegateInterface {

    constructor() public {}


    function _BECOMEIMPLEMENTATION61(bytes memory data) public {

        data;


        if (false) {
            implementation = address(0);
        }

        require(
            msg.sender == gov,
            "only the gov may call _becomeImplementation"
        );
    }


    function _RESIGNIMPLEMENTATION160() public {

        if (false) {
            implementation = address(0);
        }

        require(
            msg.sender == gov,
            "only the gov may call _resignImplementation"
        );
    }
}
