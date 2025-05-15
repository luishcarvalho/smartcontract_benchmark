


pragma solidity ^0.5.4;

interface IntVoteInterface {


    modifier ONLYPROPOSALOWNER208(bytes32 _proposalId) {revert(); _;}
    modifier VOTABLE853(bytes32 _proposalId) {revert(); _;}

    event NEWPROPOSAL588(
        bytes32 indexed _proposalId,
        address indexed _organization,
        uint256 _numOfChoices,
        address _proposer,
        bytes32 _paramsHash
    );

    event EXECUTEPROPOSAL706(bytes32 indexed _proposalId,
        address indexed _organization,
        uint256 _decision,
        uint256 _totalReputation
    );

    event VOTEPROPOSAL760(
        bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _voter,
        uint256 _vote,
        uint256 _reputation
    );

    event CANCELPROPOSAL161(bytes32 indexed _proposalId, address indexed _organization );
    event CANCELVOTING574(bytes32 indexed _proposalId, address indexed _organization, address indexed _voter);


    function PROPOSE661(
        uint256 _numOfChoices,
        bytes32 _proposalParameters,
        address _proposer,
        address _organization
        ) external returns(bytes32);

    function VOTE536(
        bytes32 _proposalId,
        uint256 _vote,
        uint256 _rep,
        address _voter
    )
    external
    returns(bool);

    function CANCELVOTE202(bytes32 _proposalId) external;

    function GETNUMBEROFCHOICES589(bytes32 _proposalId) external view returns(uint256);

    function ISVOTABLE375(bytes32 _proposalId) external view returns(bool);


    function VOTESTATUS96(bytes32 _proposalId, uint256 _choice) external view returns(uint256);


    function ISABSTAINALLOW791() external pure returns(bool);


    function GETALLOWEDRANGEOFCHOICES990() external pure returns(uint256 min, uint256 max);
}



pragma solidity ^0.5.2;


interface IERC20 {
    function TRANSFER985(address to, uint256 value) external returns (bool);

    function APPROVE946(address spender, uint256 value) external returns (bool);

    function TRANSFERFROM649(address from, address to, uint256 value) external returns (bool);

    function TOTALSUPPLY573() external view returns (uint256);

    function BALANCEOF995(address who) external view returns (uint256);

    function ALLOWANCE88(address owner, address spender) external view returns (uint256);

    event TRANSFER258(address indexed from, address indexed to, uint256 value);

    event APPROVAL578(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity ^0.5.4;


interface VotingMachineCallbacksInterface {
    function MINTREPUTATION981(uint256 _amount, address _beneficiary, bytes32 _proposalId) external returns(bool);
    function BURNREPUTATION898(uint256 _amount, address _owner, bytes32 _proposalId) external returns(bool);

    function STAKINGTOKENTRANSFER53(IERC20 _stakingToken, address _beneficiary, uint256 _amount, bytes32 _proposalId)
    external
    returns(bool);

    function GETTOTALREPUTATIONSUPPLY50(bytes32 _proposalId) external view returns(uint256);
    function REPUTATIONOF984(address _owner, bytes32 _proposalId) external view returns(uint256);
    function BALANCEOFSTAKINGTOKEN878(IERC20 _stakingToken, bytes32 _proposalId) external view returns(uint256);
}



pragma solidity ^0.5.2;


contract Ownable {
    address private _owner;

    event OWNERSHIPTRANSFERRED48(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = msg.sender;
        emit OWNERSHIPTRANSFERRED48(address(0), _owner);
    }


    function OWNER574() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER824() {
        require(ISOWNER625());
        _;
    }


    function ISOWNER625() public view returns (bool) {
        return msg.sender == _owner;
    }


    function RENOUNCEOWNERSHIP632() public ONLYOWNER824 {
        emit OWNERSHIPTRANSFERRED48(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP334(address newOwner) public ONLYOWNER824 {
        _TRANSFEROWNERSHIP900(newOwner);
    }


    function _TRANSFEROWNERSHIP900(address newOwner) internal {
        require(newOwner != address(0));
        emit OWNERSHIPTRANSFERRED48(_owner, newOwner);
        _owner = newOwner;
    }
}



pragma solidity ^0.5.4;





contract Reputation is Ownable {

    uint8 public decimals = 18;

    event MINT335(address indexed _to, uint256 _amount);

    event BURN261(address indexed _from, uint256 _amount);




    struct Checkpoint {


        uint128 fromBlock;


        uint128 value;
    }




    mapping (address => Checkpoint[]) balances;


    Checkpoint[] totalSupplyHistory;


    constructor(
    ) public
    {
    }



    function TOTALSUPPLY573() public view returns (uint256) {
        return TOTALSUPPLYAT652(block.number);
    }





    function BALANCEOF995(address _owner) public view returns (uint256 balance) {
        return BALANCEOFAT780(_owner, block.number);
    }





    function BALANCEOFAT780(address _owner, uint256 _blockNumber)
    public view returns (uint256)
    {
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            return 0;

        } else {
            return GETVALUEAT483(balances[_owner], _blockNumber);
        }
    }




    function TOTALSUPPLYAT652(uint256 _blockNumber) public view returns(uint256) {
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            return 0;

        } else {
            return GETVALUEAT483(totalSupplyHistory, _blockNumber);
        }
    }





    function MINT69(address _user, uint256 _amount) public ONLYOWNER824 returns (bool) {
        uint256 curTotalSupply = TOTALSUPPLY573();
        require(curTotalSupply + _amount >= curTotalSupply);
        uint256 previousBalanceTo = BALANCEOF995(_user);
        require(previousBalanceTo + _amount >= previousBalanceTo);
        UPDATEVALUEATNOW719(totalSupplyHistory, curTotalSupply + _amount);
        UPDATEVALUEATNOW719(balances[_user], previousBalanceTo + _amount);
        emit MINT335(_user, _amount);
        return true;
    }





    function BURN206(address _user, uint256 _amount) public ONLYOWNER824 returns (bool) {
        uint256 curTotalSupply = TOTALSUPPLY573();
        uint256 amountBurned = _amount;
        uint256 previousBalanceFrom = BALANCEOF995(_user);
        if (previousBalanceFrom < amountBurned) {
            amountBurned = previousBalanceFrom;
        }
        UPDATEVALUEATNOW719(totalSupplyHistory, curTotalSupply - amountBurned);
        UPDATEVALUEATNOW719(balances[_user], previousBalanceFrom - amountBurned);
        emit BURN261(_user, amountBurned);
        return true;
    }









    function GETVALUEAT483(Checkpoint[] storage checkpoints, uint256 _block) internal view returns (uint256) {
        if (checkpoints.length == 0) {
            return 0;
        }


        if (_block >= checkpoints[checkpoints.length-1].fromBlock) {
            return checkpoints[checkpoints.length-1].value;
        }
        if (_block < checkpoints[0].fromBlock) {
            return 0;
        }


        uint256 min = 0;
        uint256 max = checkpoints.length-1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }





    function UPDATEVALUEATNOW719(Checkpoint[] storage checkpoints, uint256 _value) internal {
        require(uint128(_value) == _value);
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
    }
}



pragma solidity ^0.5.2;


library SafeMath {

    function MUL295(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }


    function DIV1(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }


    function SUB141(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }


    function ADD15(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }


    function MOD36(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



pragma solidity ^0.5.2;




contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;


    function TOTALSUPPLY573() public view returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF995(address owner) public view returns (uint256) {
        return _balances[owner];
    }


    function ALLOWANCE88(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }


    function TRANSFER985(address to, uint256 value) public returns (bool) {
        _TRANSFER402(msg.sender, to, value);
        return true;
    }


    function APPROVE946(address spender, uint256 value) public returns (bool) {
        _APPROVE913(msg.sender, spender, value);
        return true;
    }


    function TRANSFERFROM649(address from, address to, uint256 value) public returns (bool) {
        _TRANSFER402(from, to, value);
        _APPROVE913(from, msg.sender, _allowed[from][msg.sender].SUB141(value));
        return true;
    }


    function INCREASEALLOWANCE616(address spender, uint256 addedValue) public returns (bool) {
        _APPROVE913(msg.sender, spender, _allowed[msg.sender][spender].ADD15(addedValue));
        return true;
    }


    function DECREASEALLOWANCE72(address spender, uint256 subtractedValue) public returns (bool) {
        _APPROVE913(msg.sender, spender, _allowed[msg.sender][spender].SUB141(subtractedValue));
        return true;
    }


    function _TRANSFER402(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].SUB141(value);
        _balances[to] = _balances[to].ADD15(value);
        emit TRANSFER258(from, to, value);
    }


    function _MINT318(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.ADD15(value);
        _balances[account] = _balances[account].ADD15(value);
        emit TRANSFER258(address(0), account, value);
    }


    function _BURN875(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.SUB141(value);
        _balances[account] = _balances[account].SUB141(value);
        emit TRANSFER258(account, address(0), value);
    }


    function _APPROVE913(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit APPROVAL578(owner, spender, value);
    }


    function _BURNFROM507(address account, uint256 value) internal {
        _BURN875(account, value);
        _APPROVE913(account, msg.sender, _allowed[account][msg.sender].SUB141(value));
    }
}



pragma solidity ^0.5.2;



contract ERC20Burnable is ERC20 {

    function BURN206(uint256 value) public {
        _BURN875(msg.sender, value);
    }


    function BURNFROM991(address from, uint256 value) public {
        _BURNFROM507(from, value);
    }
}



pragma solidity ^0.5.4;







contract DAOToken is ERC20, ERC20Burnable, Ownable {

    string public name;
    string public symbol;

    uint8 public constant decimals662 = 18;
    uint256 public cap;


    constructor(string memory _name, string memory _symbol, uint256 _cap)
    public {
        name = _name;
        symbol = _symbol;
        cap = _cap;
    }


    function MINT69(address _to, uint256 _amount) public ONLYOWNER824 returns (bool) {
        if (cap > 0)
            require(TOTALSUPPLY573().ADD15(_amount) <= cap);
        _MINT318(_to, _amount);
        return true;
    }
}



pragma solidity ^0.5.2;


library Address {

    function ISCONTRACT51(address account) internal view returns (bool) {
        uint256 size;







        assembly { size := extcodesize(account) }
        return size > 0;
    }
}




pragma solidity ^0.5.4;



library SafeERC20 {
    using Address for address;

    bytes4 constant private transfer_selector475 = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 constant private transferfrom_selector4 = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 constant private approve_selector816 = bytes4(keccak256(bytes("approve(address,uint256)")));

    function SAFETRANSFER442(address _erc20Addr, address _to, uint256 _value) internal {


        require(_erc20Addr.ISCONTRACT51());

        (bool success, bytes memory returnValue) =

        _erc20Addr.call(abi.encodeWithSelector(transfer_selector475, _to, _value));

        require(success);

        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }

    function SAFETRANSFERFROM294(address _erc20Addr, address _from, address _to, uint256 _value) internal {


        require(_erc20Addr.ISCONTRACT51());

        (bool success, bytes memory returnValue) =

        _erc20Addr.call(abi.encodeWithSelector(transferfrom_selector4, _from, _to, _value));

        require(success);

        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }

    function SAFEAPPROVE771(address _erc20Addr, address _spender, uint256 _value) internal {


        require(_erc20Addr.ISCONTRACT51());



        require((_value == 0) || (IERC20(_erc20Addr).ALLOWANCE88(address(this), _spender) == 0));

        (bool success, bytes memory returnValue) =

        _erc20Addr.call(abi.encodeWithSelector(approve_selector816, _spender, _value));

        require(success);

        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }
}



pragma solidity ^0.5.4;








contract Avatar is Ownable {
    using SafeERC20 for address;

    string public orgName;
    DAOToken public nativeToken;
    Reputation public nativeReputation;

    event GENERICCALL988(address indexed _contract, bytes _data, uint _value, bool _success);
    event SENDETHER194(uint256 _amountInWei, address indexed _to);
    event EXTERNALTOKENTRANSFER653(address indexed _externalToken, address indexed _to, uint256 _value);
    event EXTERNALTOKENTRANSFERFROM913(address indexed _externalToken, address _from, address _to, uint256 _value);
    event EXTERNALTOKENAPPROVAL142(address indexed _externalToken, address _spender, uint256 _value);
    event RECEIVEETHER18(address indexed _sender, uint256 _value);
    event METADATA150(string _metaData);


    constructor(string memory _orgName, DAOToken _nativeToken, Reputation _nativeReputation) public {
        orgName = _orgName;
        nativeToken = _nativeToken;
        nativeReputation = _nativeReputation;
    }


    function() external payable {
        emit RECEIVEETHER18(msg.sender, msg.value);
    }


    function GENERICCALL327(address _contract, bytes memory _data, uint256 _value)
    public
    ONLYOWNER824
    returns(bool success, bytes memory returnValue) {

        (success, returnValue) = _contract.call.value(_value)(_data);
        emit GENERICCALL988(_contract, _data, _value, success);
    }


    function SENDETHER177(uint256 _amountInWei, address payable _to) public ONLYOWNER824 returns(bool) {
        _to.transfer(_amountInWei);
        emit SENDETHER194(_amountInWei, _to);
        return true;
    }


    function EXTERNALTOKENTRANSFER167(IERC20 _externalToken, address _to, uint256 _value)
    public ONLYOWNER824 returns(bool)
    {
        address(_externalToken).SAFETRANSFER442(_to, _value);
        emit EXTERNALTOKENTRANSFER653(address(_externalToken), _to, _value);
        return true;
    }


    function EXTERNALTOKENTRANSFERFROM421(
        IERC20 _externalToken,
        address _from,
        address _to,
        uint256 _value
    )
    public ONLYOWNER824 returns(bool)
    {
        address(_externalToken).SAFETRANSFERFROM294(_from, _to, _value);
        emit EXTERNALTOKENTRANSFERFROM913(address(_externalToken), _from, _to, _value);
        return true;
    }


    function EXTERNALTOKENAPPROVAL190(IERC20 _externalToken, address _spender, uint256 _value)
    public ONLYOWNER824 returns(bool)
    {
        address(_externalToken).SAFEAPPROVE771(_spender, _value);
        emit EXTERNALTOKENAPPROVAL142(address(_externalToken), _spender, _value);
        return true;
    }


    function METADATA450(string memory _metaData) public ONLYOWNER824 returns(bool) {
        emit METADATA150(_metaData);
        return true;
    }


}



pragma solidity ^0.5.4;


contract UniversalSchemeInterface {

    function GETPARAMETERSFROMCONTROLLER560(Avatar _avatar) internal view returns(bytes32);

}



pragma solidity ^0.5.4;


contract GlobalConstraintInterface {

    enum CallPhase { Pre, Post, PreAndPost }

    function PRE222( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);
    function POST74( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);

    function WHEN422() public returns(CallPhase);
}



pragma solidity ^0.5.4;




interface ControllerInterface {


    function MINTREPUTATION981(uint256 _amount, address _to, address _avatar)
    external
    returns(bool);


    function BURNREPUTATION898(uint256 _amount, address _from, address _avatar)
    external
    returns(bool);


    function MINTTOKENS758(uint256 _amount, address _beneficiary, address _avatar)
    external
    returns(bool);


    function REGISTERSCHEME37(address _scheme, bytes32 _paramsHash, bytes4 _permissions, address _avatar)
    external
    returns(bool);


    function UNREGISTERSCHEME785(address _scheme, address _avatar)
    external
    returns(bool);


    function UNREGISTERSELF96(address _avatar) external returns(bool);


    function ADDGLOBALCONSTRAINT638(address _globalConstraint, bytes32 _params, address _avatar)
    external returns(bool);


    function REMOVEGLOBALCONSTRAINT28 (address _globalConstraint, address _avatar)
    external  returns(bool);


    function UPGRADECONTROLLER721(address _newController, Avatar _avatar)
    external returns(bool);


    function GENERICCALL327(address _contract, bytes calldata _data, Avatar _avatar, uint256 _value)
    external
    returns(bool, bytes memory);


    function SENDETHER177(uint256 _amountInWei, address payable _to, Avatar _avatar)
    external returns(bool);


    function EXTERNALTOKENTRANSFER167(IERC20 _externalToken, address _to, uint256 _value, Avatar _avatar)
    external
    returns(bool);


    function EXTERNALTOKENTRANSFERFROM421(
    IERC20 _externalToken,
    address _from,
    address _to,
    uint256 _value,
    Avatar _avatar)
    external
    returns(bool);


    function EXTERNALTOKENAPPROVAL190(IERC20 _externalToken, address _spender, uint256 _value, Avatar _avatar)
    external
    returns(bool);


    function METADATA450(string calldata _metaData, Avatar _avatar) external returns(bool);


    function GETNATIVEREPUTATION762(address _avatar)
    external
    view
    returns(address);

    function ISSCHEMEREGISTERED658( address _scheme, address _avatar) external view returns(bool);

    function GETSCHEMEPARAMETERS578(address _scheme, address _avatar) external view returns(bytes32);

    function GETGLOBALCONSTRAINTPARAMETERS702(address _globalConstraint, address _avatar) external view returns(bytes32);

    function GETSCHEMEPERMISSIONS800(address _scheme, address _avatar) external view returns(bytes4);


    function GLOBALCONSTRAINTSCOUNT83(address _avatar) external view returns(uint, uint);

    function ISGLOBALCONSTRAINTREGISTERED605(address _globalConstraint, address _avatar) external view returns(bool);
}



pragma solidity ^0.5.4;





contract UniversalScheme is UniversalSchemeInterface {

    function GETPARAMETERSFROMCONTROLLER560(Avatar _avatar) internal view returns(bytes32) {
        require(ControllerInterface(_avatar.OWNER574()).ISSCHEMEREGISTERED658(address(this), address(_avatar)),
        "scheme is not registered");
        return ControllerInterface(_avatar.OWNER574()).GETSCHEMEPARAMETERS578(address(this), address(_avatar));
    }
}



pragma solidity ^0.5.2;



library ECDSA {

    function RECOVER336(bytes32 hash, bytes memory signature) internal pure returns (address) {

        if (signature.length != 65) {
            return (address(0));
        }


        bytes32 r;
        bytes32 s;
        uint8 v;




        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }










        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }


        return ecrecover(hash, v, r, s);
    }


    function TOETHSIGNEDMESSAGEHASH747(bytes32 hash) internal pure returns (bytes32) {


        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}



pragma solidity ^0.5.4;




library RealMath {


    uint256 constant private real_bits978 = 256;


    uint256 constant private real_fbits102 = 40;


    uint256 constant private real_one722 = uint256(1) << real_fbits102;


    function POW948(uint256 realBase, uint256 exponent) internal pure returns (uint256) {

        uint256 tempRealBase = realBase;
        uint256 tempExponent = exponent;


        uint256 realResult = real_one722;
        while (tempExponent != 0) {

            if ((tempExponent & 0x1) == 0x1) {

                realResult = MUL295(realResult, tempRealBase);
            }

            tempExponent = tempExponent >> 1;
            if (tempExponent != 0) {

                tempRealBase = MUL295(tempRealBase, tempRealBase);
            }
        }


        return realResult;
    }


    function FRACTION401(uint216 numerator, uint216 denominator) internal pure returns (uint256) {
        return DIV1(uint256(numerator) * real_one722, uint256(denominator) * real_one722);
    }


    function MUL295(uint256 realA, uint256 realB) private pure returns (uint256) {


        uint256 res = realA * realB;
        require(res/realA == realB, "RealMath mul overflow");
        return (res >> real_fbits102);
    }


    function DIV1(uint256 realNumerator, uint256 realDenominator) private pure returns (uint256) {


        return uint256((uint256(realNumerator) * real_one722) / uint256(realDenominator));
    }

}



pragma solidity ^0.5.4;

interface ProposalExecuteInterface {
    function EXECUTEPROPOSAL422(bytes32 _proposalId, int _decision) external returns(bool);
}



pragma solidity ^0.5.2;


library Math {

    function MAX135(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }


    function MIN317(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }


    function AVERAGE86(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}



pragma solidity ^0.5.4;












contract GenesisProtocolLogic is IntVoteInterface {
    using SafeMath for uint256;
    using Math for uint256;
    using RealMath for uint216;
    using RealMath for uint256;
    using Address for address;

    enum ProposalState { None, ExpiredInQueue, Executed, Queued, PreBoosted, Boosted, QuietEndingPeriod}
    enum ExecutionState { None, QueueBarCrossed, QueueTimeOut, PreBoostedBarCrossed, BoostedTimeOut, BoostedBarCrossed}


    struct Parameters {
        uint256 queuedVoteRequiredPercentage;
        uint256 queuedVotePeriodLimit;
        uint256 boostedVotePeriodLimit;
        uint256 preBoostedVotePeriodLimit;

        uint256 thresholdConst;

        uint256 limitExponentValue;

        uint256 quietEndingPeriod;
        uint256 proposingRepReward;
        uint256 votersReputationLossRatio;

        uint256 minimumDaoBounty;
        uint256 daoBountyConst;

        uint256 activationTime;

        address voteOnBehalf;
    }

    struct Voter {
        uint256 vote;
        uint256 reputation;
        bool preBoosted;
    }

    struct Staker {
        uint256 vote;
        uint256 amount;
        uint256 amount4Bounty;
    }

    struct Proposal {
        bytes32 organizationId;
        address callbacks;
        ProposalState state;
        uint256 winningVote;
        address proposer;

        uint256 currentBoostedVotePeriodLimit;
        bytes32 paramsHash;
        uint256 daoBountyRemain;
        uint256 daoBounty;
        uint256 totalStakes;
        uint256 confidenceThreshold;

        uint256 expirationCallBountyPercentage;
        uint[3] times;


        bool daoRedeemItsWinnings;

        mapping(uint256   =>  uint256    ) votes;

        mapping(uint256   =>  uint256    ) preBoostedVotes;

        mapping(address =>  Voter    ) voters;

        mapping(uint256   =>  uint256    ) stakes;

        mapping(address  => Staker   ) stakers;
    }

    event STAKE754(bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _staker,
        uint256 _vote,
        uint256 _amount
    );

    event REDEEM636(bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _beneficiary,
        uint256 _amount
    );

    event REDEEMDAOBOUNTY578(bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _beneficiary,
        uint256 _amount
    );

    event REDEEMREPUTATION314(bytes32 indexed _proposalId,
        address indexed _organization,
        address indexed _beneficiary,
        uint256 _amount
    );

    event STATECHANGE374(bytes32 indexed _proposalId, ProposalState _proposalState);
    event GPEXECUTEPROPOSAL538(bytes32 indexed _proposalId, ExecutionState _executionState);
    event EXPIRATIONCALLBOUNTY93(bytes32 indexed _proposalId, address indexed _beneficiary, uint256 _amount);
    event CONFIDENCELEVELCHANGE532(bytes32 indexed _proposalId, uint256 _confidenceThreshold);

    mapping(bytes32=>Parameters) public parameters;
    mapping(bytes32=>Proposal) public proposals;
    mapping(bytes32=>uint) public orgBoostedProposalsCnt;

    mapping(bytes32        => address     ) public organizations;

    mapping(bytes32           => uint256              ) public averagesDownstakesOfBoosted;
    uint256 constant public num_of_choices613 = 2;
    uint256 constant public no391 = 2;
    uint256 constant public yes596 = 1;
    uint256 public proposalsCnt;
    IERC20 public stakingToken;
    address constant private gen_token_address929 = 0x543Ff227F64Aa17eA132Bf9886cAb5DB55DCAddf;
    uint256 constant private max_boosted_proposals645 = 4096;


    constructor(IERC20 _stakingToken) public {





        if (address(gen_token_address929).ISCONTRACT51()) {
            stakingToken = IERC20(gen_token_address929);
        } else {
            stakingToken = _stakingToken;
        }
    }


    modifier VOTABLE853(bytes32 _proposalId) {
        require(_ISVOTABLE722(_proposalId));
        _;
    }


    function PROPOSE661(uint256, bytes32 _paramsHash, address _proposer, address _organization)
        external
        returns(bytes32)
    {

        require(now > parameters[_paramsHash].activationTime, "not active yet");

        require(parameters[_paramsHash].queuedVoteRequiredPercentage >= 50);

        bytes32 proposalId = keccak256(abi.encodePacked(this, proposalsCnt));
        proposalsCnt = proposalsCnt.ADD15(1);

        Proposal memory proposal;
        proposal.callbacks = msg.sender;
        proposal.organizationId = keccak256(abi.encodePacked(msg.sender, _organization));

        proposal.state = ProposalState.Queued;

        proposal.times[0] = now;
        proposal.currentBoostedVotePeriodLimit = parameters[_paramsHash].boostedVotePeriodLimit;
        proposal.proposer = _proposer;
        proposal.winningVote = no391;
        proposal.paramsHash = _paramsHash;
        if (organizations[proposal.organizationId] == address(0)) {
            if (_organization == address(0)) {
                organizations[proposal.organizationId] = msg.sender;
            } else {
                organizations[proposal.organizationId] = _organization;
            }
        }

        uint256 daoBounty =
        parameters[_paramsHash].daoBountyConst.MUL295(averagesDownstakesOfBoosted[proposal.organizationId]).DIV1(100);
        if (daoBounty < parameters[_paramsHash].minimumDaoBounty) {
            proposal.daoBountyRemain = parameters[_paramsHash].minimumDaoBounty;
        } else {
            proposal.daoBountyRemain = daoBounty;
        }
        proposal.totalStakes = proposal.daoBountyRemain;
        proposals[proposalId] = proposal;
        proposals[proposalId].stakes[no391] = proposal.daoBountyRemain;

        emit NEWPROPOSAL588(proposalId, organizations[proposal.organizationId], num_of_choices613, _proposer, _paramsHash);
        return proposalId;
    }


    function EXECUTEBOOSTED17(bytes32 _proposalId) external returns(uint256 expirationCallBounty) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Boosted || proposal.state == ProposalState.QuietEndingPeriod,
        "proposal state in not Boosted nor QuietEndingPeriod");
        require(_EXECUTE501(_proposalId), "proposal need to expire");
        uint256 expirationCallBountyPercentage =

        (uint(1).ADD15(now.SUB141(proposal.currentBoostedVotePeriodLimit.ADD15(proposal.times[1])).DIV1(15)));
        if (expirationCallBountyPercentage > 100) {
            expirationCallBountyPercentage = 100;
        }
        proposal.expirationCallBountyPercentage = expirationCallBountyPercentage;
        expirationCallBounty = expirationCallBountyPercentage.MUL295(proposal.stakes[yes596]).DIV1(100);
        require(stakingToken.TRANSFER985(msg.sender, expirationCallBounty), "transfer to msg.sender failed");
        emit EXPIRATIONCALLBOUNTY93(_proposalId, msg.sender, expirationCallBounty);
    }


    function SETPARAMETERS600(
        uint[11] calldata _params,
        address _voteOnBehalf
    )
    external
    returns(bytes32)
    {
        require(_params[0] <= 100 && _params[0] >= 50, "50 <= queuedVoteRequiredPercentage <= 100");
        require(_params[4] <= 16000 && _params[4] > 1000, "1000 < thresholdConst <= 16000");
        require(_params[7] <= 100, "votersReputationLossRatio <= 100");
        require(_params[2] >= _params[5], "boostedVotePeriodLimit >= quietEndingPeriod");
        require(_params[8] > 0, "minimumDaoBounty should be > 0");
        require(_params[9] > 0, "daoBountyConst should be > 0");

        bytes32 paramsHash = GETPARAMETERSHASH529(_params, _voteOnBehalf);

        uint256 limitExponent = 172;
        uint256 j = 2;
        for (uint256 i = 2000; i < 16000; i = i*2) {
            if ((_params[4] > i) && (_params[4] <= i*2)) {
                limitExponent = limitExponent/j;
                break;
            }
            j++;
        }

        parameters[paramsHash] = Parameters({
            queuedVoteRequiredPercentage: _params[0],
            queuedVotePeriodLimit: _params[1],
            boostedVotePeriodLimit: _params[2],
            preBoostedVotePeriodLimit: _params[3],
            thresholdConst:uint216(_params[4]).FRACTION401(uint216(1000)),
            limitExponentValue:limitExponent,
            quietEndingPeriod: _params[5],
            proposingRepReward: _params[6],
            votersReputationLossRatio:_params[7],
            minimumDaoBounty:_params[8],
            daoBountyConst:_params[9],
            activationTime:_params[10],
            voteOnBehalf:_voteOnBehalf
        });
        return paramsHash;
    }



    function REDEEM641(bytes32 _proposalId, address _beneficiary) public returns (uint[3] memory rewards) {
        Proposal storage proposal = proposals[_proposalId];
        require((proposal.state == ProposalState.Executed)||(proposal.state == ProposalState.ExpiredInQueue),
        "Proposal should be Executed or ExpiredInQueue");
        Parameters memory params = parameters[proposal.paramsHash];
        uint256 lostReputation;
        if (proposal.winningVote == yes596) {
            lostReputation = proposal.preBoostedVotes[no391];
        } else {
            lostReputation = proposal.preBoostedVotes[yes596];
        }
        lostReputation = (lostReputation.MUL295(params.votersReputationLossRatio))/100;

        Staker storage staker = proposal.stakers[_beneficiary];
        uint256 totalStakes = proposal.stakes[no391].ADD15(proposal.stakes[yes596]);
        uint256 totalWinningStakes = proposal.stakes[proposal.winningVote];

        if (staker.amount > 0) {
            uint256 totalStakesLeftAfterCallBounty =
            totalStakes.SUB141(proposal.expirationCallBountyPercentage.MUL295(proposal.stakes[yes596]).DIV1(100));
            if (proposal.state == ProposalState.ExpiredInQueue) {

                rewards[0] = staker.amount;
            } else if (staker.vote == proposal.winningVote) {
                if (staker.vote == yes596) {
                    if (proposal.daoBounty < totalStakesLeftAfterCallBounty) {
                        uint256 _totalStakes = totalStakesLeftAfterCallBounty.SUB141(proposal.daoBounty);
                        rewards[0] = (staker.amount.MUL295(_totalStakes))/totalWinningStakes;
                    }
                } else {
                    rewards[0] = (staker.amount.MUL295(totalStakesLeftAfterCallBounty))/totalWinningStakes;
                }
            }
            staker.amount = 0;
        }

        if (proposal.daoRedeemItsWinnings == false &&
            _beneficiary == organizations[proposal.organizationId] &&
            proposal.state != ProposalState.ExpiredInQueue &&
            proposal.winningVote == no391) {
            rewards[0] =
            rewards[0].ADD15((proposal.daoBounty.MUL295(totalStakes))/totalWinningStakes).SUB141(proposal.daoBounty);
            proposal.daoRedeemItsWinnings = true;
        }


        Voter storage voter = proposal.voters[_beneficiary];
        if ((voter.reputation != 0) && (voter.preBoosted)) {
            if (proposal.state == ProposalState.ExpiredInQueue) {

                rewards[1] = ((voter.reputation.MUL295(params.votersReputationLossRatio))/100);
            } else if (proposal.winningVote == voter.vote) {
                rewards[1] = ((voter.reputation.MUL295(params.votersReputationLossRatio))/100)
                .ADD15((voter.reputation.MUL295(lostReputation))/proposal.preBoostedVotes[proposal.winningVote]);
            }
            voter.reputation = 0;
        }

        if ((proposal.proposer == _beneficiary)&&(proposal.winningVote == yes596)&&(proposal.proposer != address(0))) {
            rewards[2] = params.proposingRepReward;
            proposal.proposer = address(0);
        }
        if (rewards[0] != 0) {
            proposal.totalStakes = proposal.totalStakes.SUB141(rewards[0]);
            require(stakingToken.TRANSFER985(_beneficiary, rewards[0]), "transfer to beneficiary failed");
            emit REDEEM636(_proposalId, organizations[proposal.organizationId], _beneficiary, rewards[0]);
        }
        if (rewards[1].ADD15(rewards[2]) != 0) {
            VotingMachineCallbacksInterface(proposal.callbacks)
            .MINTREPUTATION981(rewards[1].ADD15(rewards[2]), _beneficiary, _proposalId);
            emit REDEEMREPUTATION314(
            _proposalId,
            organizations[proposal.organizationId],
            _beneficiary,
            rewards[1].ADD15(rewards[2])
            );
        }
    }


    function REDEEMDAOBOUNTY8(bytes32 _proposalId, address _beneficiary)
    public
    returns(uint256 redeemedAmount, uint256 potentialAmount) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Executed);
        uint256 totalWinningStakes = proposal.stakes[proposal.winningVote];
        Staker storage staker = proposal.stakers[_beneficiary];
        if (
            (staker.amount4Bounty > 0)&&
            (staker.vote == proposal.winningVote)&&
            (proposal.winningVote == yes596)&&
            (totalWinningStakes != 0)) {

                potentialAmount = (staker.amount4Bounty * proposal.daoBounty)/totalWinningStakes;
            }
        if ((potentialAmount != 0)&&
            (VotingMachineCallbacksInterface(proposal.callbacks)
            .BALANCEOFSTAKINGTOKEN878(stakingToken, _proposalId) >= potentialAmount)) {
            staker.amount4Bounty = 0;
            proposal.daoBountyRemain = proposal.daoBountyRemain.SUB141(potentialAmount);
            require(
            VotingMachineCallbacksInterface(proposal.callbacks)
            .STAKINGTOKENTRANSFER53(stakingToken, _beneficiary, potentialAmount, _proposalId));
            redeemedAmount = potentialAmount;
            emit REDEEMDAOBOUNTY578(_proposalId, organizations[proposal.organizationId], _beneficiary, redeemedAmount);
        }
    }


    function SHOULDBOOST603(bytes32 _proposalId) public view returns(bool) {
        Proposal memory proposal = proposals[_proposalId];
        return (_SCORE635(_proposalId) > THRESHOLD53(proposal.paramsHash, proposal.organizationId));
    }


    function THRESHOLD53(bytes32 _paramsHash, bytes32 _organizationId) public view returns(uint256) {
        uint256 power = orgBoostedProposalsCnt[_organizationId];
        Parameters storage params = parameters[_paramsHash];

        if (power > params.limitExponentValue) {
            power = params.limitExponentValue;
        }

        return params.thresholdConst.POW948(power);
    }


    function GETPARAMETERSHASH529(
        uint[11] memory _params,
        address _voteOnBehalf
    )
        public
        pure
        returns(bytes32)
        {

        return keccak256(
            abi.encodePacked(
            keccak256(
            abi.encodePacked(
                _params[0],
                _params[1],
                _params[2],
                _params[3],
                _params[4],
                _params[5],
                _params[6],
                _params[7],
                _params[8],
                _params[9],
                _params[10])
            ),
            _voteOnBehalf
        ));
    }



    function _EXECUTE501(bytes32 _proposalId) internal VOTABLE853(_proposalId) returns(bool) {
        Proposal storage proposal = proposals[_proposalId];
        Parameters memory params = parameters[proposal.paramsHash];
        Proposal memory tmpProposal = proposal;
        uint256 totalReputation =
        VotingMachineCallbacksInterface(proposal.callbacks).GETTOTALREPUTATIONSUPPLY50(_proposalId);

        uint256 executionBar = (totalReputation/100) * params.queuedVoteRequiredPercentage;
        ExecutionState executionState = ExecutionState.None;
        uint256 averageDownstakesOfBoosted;
        uint256 confidenceThreshold;

        if (proposal.votes[proposal.winningVote] > executionBar) {

            if (proposal.state == ProposalState.Queued) {
                executionState = ExecutionState.QueueBarCrossed;
            } else if (proposal.state == ProposalState.PreBoosted) {
                executionState = ExecutionState.PreBoostedBarCrossed;
            } else {
                executionState = ExecutionState.BoostedBarCrossed;
            }
            proposal.state = ProposalState.Executed;
        } else {
            if (proposal.state == ProposalState.Queued) {

                if ((now - proposal.times[0]) >= params.queuedVotePeriodLimit) {
                    proposal.state = ProposalState.ExpiredInQueue;
                    proposal.winningVote = no391;
                    executionState = ExecutionState.QueueTimeOut;
                } else {
                    confidenceThreshold = THRESHOLD53(proposal.paramsHash, proposal.organizationId);
                    if (_SCORE635(_proposalId) > confidenceThreshold) {

                        proposal.state = ProposalState.PreBoosted;

                        proposal.times[2] = now;
                        proposal.confidenceThreshold = confidenceThreshold;
                    }
                }
            }

            if (proposal.state == ProposalState.PreBoosted) {
                confidenceThreshold = THRESHOLD53(proposal.paramsHash, proposal.organizationId);

                if ((now - proposal.times[2]) >= params.preBoostedVotePeriodLimit) {
                    if ((_SCORE635(_proposalId) > confidenceThreshold) &&
                        (orgBoostedProposalsCnt[proposal.organizationId] < max_boosted_proposals645)) {

                        proposal.state = ProposalState.Boosted;

                        proposal.times[1] = now;
                        orgBoostedProposalsCnt[proposal.organizationId]++;

                        averageDownstakesOfBoosted = averagesDownstakesOfBoosted[proposal.organizationId];

                        averagesDownstakesOfBoosted[proposal.organizationId] =
                            uint256(int256(averageDownstakesOfBoosted) +
                            ((int256(proposal.stakes[no391])-int256(averageDownstakesOfBoosted))/
                            int256(orgBoostedProposalsCnt[proposal.organizationId])));
                    }
                } else {
                    uint256 proposalScore = _SCORE635(_proposalId);
                    if (proposalScore <= proposal.confidenceThreshold.MIN317(confidenceThreshold)) {
                        proposal.state = ProposalState.Queued;
                    } else if (proposal.confidenceThreshold > proposalScore) {
                        proposal.confidenceThreshold = confidenceThreshold;
                        emit CONFIDENCELEVELCHANGE532(_proposalId, confidenceThreshold);
                    }
                }
            }
        }

        if ((proposal.state == ProposalState.Boosted) ||
            (proposal.state == ProposalState.QuietEndingPeriod)) {

            if ((now - proposal.times[1]) >= proposal.currentBoostedVotePeriodLimit) {
                proposal.state = ProposalState.Executed;
                executionState = ExecutionState.BoostedTimeOut;
            }
        }

        if (executionState != ExecutionState.None) {
            if ((executionState == ExecutionState.BoostedTimeOut) ||
                (executionState == ExecutionState.BoostedBarCrossed)) {
                orgBoostedProposalsCnt[tmpProposal.organizationId] =
                orgBoostedProposalsCnt[tmpProposal.organizationId].SUB141(1);

                uint256 boostedProposals = orgBoostedProposalsCnt[tmpProposal.organizationId];
                if (boostedProposals == 0) {
                    averagesDownstakesOfBoosted[proposal.organizationId] = 0;
                } else {
                    averageDownstakesOfBoosted = averagesDownstakesOfBoosted[proposal.organizationId];
                    averagesDownstakesOfBoosted[proposal.organizationId] =
                    (averageDownstakesOfBoosted.MUL295(boostedProposals+1).SUB141(proposal.stakes[no391]))/boostedProposals;
                }
            }
            emit EXECUTEPROPOSAL706(
            _proposalId,
            organizations[proposal.organizationId],
            proposal.winningVote,
            totalReputation
            );
            emit GPEXECUTEPROPOSAL538(_proposalId, executionState);
            ProposalExecuteInterface(proposal.callbacks).EXECUTEPROPOSAL422(_proposalId, int(proposal.winningVote));
            proposal.daoBounty = proposal.daoBountyRemain;
        }
        if (tmpProposal.state != proposal.state) {
            emit STATECHANGE374(_proposalId, proposal.state);
        }
        return (executionState != ExecutionState.None);
    }


    function _STAKE234(bytes32 _proposalId, uint256 _vote, uint256 _amount, address _staker) internal returns(bool) {

        require(_vote <= num_of_choices613 && _vote > 0, "wrong vote value");
        require(_amount > 0, "staking amount should be >0");

        if (_EXECUTE501(_proposalId)) {
            return true;
        }
        Proposal storage proposal = proposals[_proposalId];

        if ((proposal.state != ProposalState.PreBoosted) &&
            (proposal.state != ProposalState.Queued)) {
            return false;
        }


        Staker storage staker = proposal.stakers[_staker];
        if ((staker.amount > 0) && (staker.vote != _vote)) {
            return false;
        }

        uint256 amount = _amount;
        require(stakingToken.TRANSFERFROM649(_staker, address(this), amount), "fail transfer from staker");
        proposal.totalStakes = proposal.totalStakes.ADD15(amount);
        staker.amount = staker.amount.ADD15(amount);


        require(staker.amount <= 0x100000000000000000000000000000000, "staking amount is too high");
        require(proposal.totalStakes <= 0x100000000000000000000000000000000, "total stakes is too high");

        if (_vote == yes596) {
            staker.amount4Bounty = staker.amount4Bounty.ADD15(amount);
        }
        staker.vote = _vote;

        proposal.stakes[_vote] = amount.ADD15(proposal.stakes[_vote]);
        emit STAKE754(_proposalId, organizations[proposal.organizationId], _staker, _vote, _amount);
        return _EXECUTE501(_proposalId);
    }



    function INTERNALVOTE757(bytes32 _proposalId, address _voter, uint256 _vote, uint256 _rep) internal returns(bool) {
        require(_vote <= num_of_choices613 && _vote > 0, "0 < _vote <= 2");
        if (_EXECUTE501(_proposalId)) {
            return true;
        }

        Parameters memory params = parameters[proposals[_proposalId].paramsHash];
        Proposal storage proposal = proposals[_proposalId];


        uint256 reputation = VotingMachineCallbacksInterface(proposal.callbacks).REPUTATIONOF984(_voter, _proposalId);
        require(reputation > 0, "_voter must have reputation");
        require(reputation >= _rep, "reputation >= _rep");
        uint256 rep = _rep;
        if (rep == 0) {
            rep = reputation;
        }

        if (proposal.voters[_voter].reputation != 0) {
            return false;
        }

        proposal.votes[_vote] = rep.ADD15(proposal.votes[_vote]);


        if ((proposal.votes[_vote] > proposal.votes[proposal.winningVote]) ||
            ((proposal.votes[no391] == proposal.votes[proposal.winningVote]) &&
            proposal.winningVote == yes596)) {
            if (proposal.state == ProposalState.Boosted &&

                ((now - proposal.times[1]) >= (params.boostedVotePeriodLimit - params.quietEndingPeriod))||
                proposal.state == ProposalState.QuietEndingPeriod) {

                if (proposal.state != ProposalState.QuietEndingPeriod) {
                    proposal.currentBoostedVotePeriodLimit = params.quietEndingPeriod;
                    proposal.state = ProposalState.QuietEndingPeriod;
                }

                proposal.times[1] = now;
            }
            proposal.winningVote = _vote;
        }
        proposal.voters[_voter] = Voter({
            reputation: rep,
            vote: _vote,
            preBoosted:((proposal.state == ProposalState.PreBoosted) || (proposal.state == ProposalState.Queued))
        });
        if ((proposal.state == ProposalState.PreBoosted) || (proposal.state == ProposalState.Queued)) {
            proposal.preBoostedVotes[_vote] = rep.ADD15(proposal.preBoostedVotes[_vote]);
            uint256 reputationDeposit = (params.votersReputationLossRatio.MUL295(rep))/100;
            VotingMachineCallbacksInterface(proposal.callbacks).BURNREPUTATION898(reputationDeposit, _voter, _proposalId);
        }
        emit VOTEPROPOSAL760(_proposalId, organizations[proposal.organizationId], _voter, _vote, rep);
        return _EXECUTE501(_proposalId);
    }


    function _SCORE635(bytes32 _proposalId) internal view returns(uint256) {
        Proposal storage proposal = proposals[_proposalId];

        return uint216(proposal.stakes[yes596]).FRACTION401(uint216(proposal.stakes[no391]));
    }


    function _ISVOTABLE722(bytes32 _proposalId) internal view returns(bool) {
        ProposalState pState = proposals[_proposalId].state;
        return ((pState == ProposalState.PreBoosted)||
                (pState == ProposalState.Boosted)||
                (pState == ProposalState.QuietEndingPeriod)||
                (pState == ProposalState.Queued)
        );
    }
}



pragma solidity ^0.5.4;





contract GenesisProtocol is IntVoteInterface, GenesisProtocolLogic {
    using ECDSA for bytes32;



    bytes32 public constant delegation_hash_eip712291 =
    keccak256(abi.encodePacked(
    "address GenesisProtocolAddress",
    "bytes32 ProposalId",
    "uint256 Vote",
    "uint256 AmountToStake",
    "uint256 Nonce"
    ));

    mapping(address=>uint256) public stakesNonce;


    constructor(IERC20 _stakingToken)
    public

    GenesisProtocolLogic(_stakingToken) {
    }


    function STAKE53(bytes32 _proposalId, uint256 _vote, uint256 _amount) external returns(bool) {
        return _STAKE234(_proposalId, _vote, _amount, msg.sender);
    }


    function STAKEWITHSIGNATURE42(
        bytes32 _proposalId,
        uint256 _vote,
        uint256 _amount,
        uint256 _nonce,
        uint256 _signatureType,
        bytes calldata _signature
        )
        external
        returns(bool)
        {

        bytes32 delegationDigest;
        if (_signatureType == 2) {
            delegationDigest = keccak256(
                abi.encodePacked(
                    delegation_hash_eip712291, keccak256(
                        abi.encodePacked(
                        address(this),
                        _proposalId,
                        _vote,
                        _amount,
                        _nonce)
                    )
                )
            );
        } else {
            delegationDigest = keccak256(
                        abi.encodePacked(
                        address(this),
                        _proposalId,
                        _vote,
                        _amount,
                        _nonce)
                    ).TOETHSIGNEDMESSAGEHASH747();
        }
        address staker = delegationDigest.RECOVER336(_signature);

        require(staker != address(0), "staker address cannot be 0");
        require(stakesNonce[staker] == _nonce);
        stakesNonce[staker] = stakesNonce[staker].ADD15(1);
        return _STAKE234(_proposalId, _vote, _amount, staker);
    }


    function VOTE536(bytes32 _proposalId, uint256 _vote, uint256 _amount, address _voter)
    external
    VOTABLE853(_proposalId)
    returns(bool) {
        Proposal storage proposal = proposals[_proposalId];
        Parameters memory params = parameters[proposal.paramsHash];
        address voter;
        if (params.voteOnBehalf != address(0)) {
            require(msg.sender == params.voteOnBehalf);
            voter = _voter;
        } else {
            voter = msg.sender;
        }
        return INTERNALVOTE757(_proposalId, voter, _vote, _amount);
    }


    function CANCELVOTE202(bytes32 _proposalId) external VOTABLE853(_proposalId) {

        return;
    }


    function EXECUTE916(bytes32 _proposalId) external VOTABLE853(_proposalId) returns(bool) {
        return _EXECUTE501(_proposalId);
    }


    function GETNUMBEROFCHOICES589(bytes32) external view returns(uint256) {
        return num_of_choices613;
    }


    function GETPROPOSALTIMES314(bytes32 _proposalId) external view returns(uint[3] memory times) {
        return proposals[_proposalId].times;
    }


    function VOTEINFO167(bytes32 _proposalId, address _voter) external view returns(uint, uint) {
        Voter memory voter = proposals[_proposalId].voters[_voter];
        return (voter.vote, voter.reputation);
    }


    function VOTESTATUS96(bytes32 _proposalId, uint256 _choice) external view returns(uint256) {
        return proposals[_proposalId].votes[_choice];
    }


    function ISVOTABLE375(bytes32 _proposalId) external view returns(bool) {
        return _ISVOTABLE722(_proposalId);
    }


    function PROPOSALSTATUS186(bytes32 _proposalId) external view returns(uint256, uint256, uint256, uint256) {
        return (
                proposals[_proposalId].preBoostedVotes[yes596],
                proposals[_proposalId].preBoostedVotes[no391],
                proposals[_proposalId].stakes[yes596],
                proposals[_proposalId].stakes[no391]
        );
    }


    function GETPROPOSALORGANIZATION49(bytes32 _proposalId) external view returns(bytes32) {
        return (proposals[_proposalId].organizationId);
    }


    function GETSTAKER814(bytes32 _proposalId, address _staker) external view returns(uint256, uint256) {
        return (proposals[_proposalId].stakers[_staker].vote, proposals[_proposalId].stakers[_staker].amount);
    }


    function VOTESTAKE56(bytes32 _proposalId, uint256 _vote) external view returns(uint256) {
        return proposals[_proposalId].stakes[_vote];
    }


    function WINNINGVOTE889(bytes32 _proposalId) external view returns(uint256) {
        return proposals[_proposalId].winningVote;
    }


    function STATE293(bytes32 _proposalId) external view returns(ProposalState) {
        return proposals[_proposalId].state;
    }


    function ISABSTAINALLOW791() external pure returns(bool) {
        return false;
    }


    function GETALLOWEDRANGEOFCHOICES990() external pure returns(uint256 min, uint256 max) {
        return (yes596, no391);
    }


    function SCORE81(bytes32 _proposalId) public view returns(uint256) {
        return  _SCORE635(_proposalId);
    }
}



pragma solidity ^0.5.4;




contract VotingMachineCallbacks is VotingMachineCallbacksInterface {

    struct ProposalInfo {
        uint256 blockNumber;
        Avatar avatar;
    }

    modifier ONLYVOTINGMACHINE284(bytes32 _proposalId) {
        require(proposalsInfo[msg.sender][_proposalId].avatar != Avatar(address(0)), "only VotingMachine");
        _;
    }


    mapping(address => mapping(bytes32 => ProposalInfo)) public proposalsInfo;

    function MINTREPUTATION981(uint256 _amount, address _beneficiary, bytes32 _proposalId)
    external
    ONLYVOTINGMACHINE284(_proposalId)
    returns(bool)
    {
        Avatar avatar = proposalsInfo[msg.sender][_proposalId].avatar;
        if (avatar == Avatar(0)) {
            return false;
        }
        return ControllerInterface(avatar.OWNER574()).MINTREPUTATION981(_amount, _beneficiary, address(avatar));
    }

    function BURNREPUTATION898(uint256 _amount, address _beneficiary, bytes32 _proposalId)
    external
    ONLYVOTINGMACHINE284(_proposalId)
    returns(bool)
    {
        Avatar avatar = proposalsInfo[msg.sender][_proposalId].avatar;
        if (avatar == Avatar(0)) {
            return false;
        }
        return ControllerInterface(avatar.OWNER574()).BURNREPUTATION898(_amount, _beneficiary, address(avatar));
    }

    function STAKINGTOKENTRANSFER53(
        IERC20 _stakingToken,
        address _beneficiary,
        uint256 _amount,
        bytes32 _proposalId)
    external
    ONLYVOTINGMACHINE284(_proposalId)
    returns(bool)
    {
        Avatar avatar = proposalsInfo[msg.sender][_proposalId].avatar;
        if (avatar == Avatar(0)) {
            return false;
        }
        return ControllerInterface(avatar.OWNER574()).EXTERNALTOKENTRANSFER167(_stakingToken, _beneficiary, _amount, avatar);
    }

    function BALANCEOFSTAKINGTOKEN878(IERC20 _stakingToken, bytes32 _proposalId) external view returns(uint256) {
        Avatar avatar = proposalsInfo[msg.sender][_proposalId].avatar;
        if (proposalsInfo[msg.sender][_proposalId].avatar == Avatar(0)) {
            return 0;
        }
        return _stakingToken.BALANCEOF995(address(avatar));
    }

    function GETTOTALREPUTATIONSUPPLY50(bytes32 _proposalId) external view returns(uint256) {
        ProposalInfo memory proposal = proposalsInfo[msg.sender][_proposalId];
        if (proposal.avatar == Avatar(0)) {
            return 0;
        }
        return proposal.avatar.nativeReputation().TOTALSUPPLYAT652(proposal.blockNumber);
    }

    function REPUTATIONOF984(address _owner, bytes32 _proposalId) external view returns(uint256) {
        ProposalInfo memory proposal = proposalsInfo[msg.sender][_proposalId];
        if (proposal.avatar == Avatar(0)) {
            return 0;
        }
        return proposal.avatar.nativeReputation().BALANCEOFAT780(_owner, proposal.blockNumber);
    }
}



pragma solidity ^0.5.4;








contract SchemeRegistrar is UniversalScheme, VotingMachineCallbacks, ProposalExecuteInterface {
    event NEWSCHEMEPROPOSAL971(
        address indexed _avatar,
        bytes32 indexed _proposalId,
        address indexed _intVoteInterface,
        address _scheme,
        bytes32 _parametersHash,
        bytes4 _permissions,
        string _descriptionHash
    );

    event REMOVESCHEMEPROPOSAL965(address indexed _avatar,
        bytes32 indexed _proposalId,
        address indexed _intVoteInterface,
        address _scheme,
        string _descriptionHash
    );

    event PROPOSALEXECUTED934(address indexed _avatar, bytes32 indexed _proposalId, int256 _param);
    event PROPOSALDELETED307(address indexed _avatar, bytes32 indexed _proposalId);


    struct SchemeProposal {
        address scheme;
        bool addScheme;
        bytes32 parametersHash;
        bytes4 permissions;
    }


    mapping(address=>mapping(bytes32=>SchemeProposal)) public organizationsProposals;


    struct Parameters {
        bytes32 voteRegisterParams;
        bytes32 voteRemoveParams;
        IntVoteInterface intVote;
    }

    mapping(bytes32=>Parameters) public parameters;


    function EXECUTEPROPOSAL422(bytes32 _proposalId, int256 _param) external ONLYVOTINGMACHINE284(_proposalId) returns(bool) {
        Avatar avatar = proposalsInfo[msg.sender][_proposalId].avatar;
        SchemeProposal memory proposal = organizationsProposals[address(avatar)][_proposalId];
        require(proposal.scheme != address(0));
        delete organizationsProposals[address(avatar)][_proposalId];
        emit PROPOSALDELETED307(address(avatar), _proposalId);
        if (_param == 1) {


            ControllerInterface controller = ControllerInterface(avatar.OWNER574());


            if (proposal.addScheme) {
                require(controller.REGISTERSCHEME37(
                        proposal.scheme,
                        proposal.parametersHash,
                        proposal.permissions,
                        address(avatar))
                );
            }

            if (!proposal.addScheme) {
                require(controller.UNREGISTERSCHEME785(proposal.scheme, address(avatar)));
            }
        }
        emit PROPOSALEXECUTED934(address(avatar), _proposalId, _param);
        return true;
    }


    function SETPARAMETERS600(
        bytes32 _voteRegisterParams,
        bytes32 _voteRemoveParams,
        IntVoteInterface _intVote
    ) public returns(bytes32)
    {
        bytes32 paramsHash = GETPARAMETERSHASH529(_voteRegisterParams, _voteRemoveParams, _intVote);
        parameters[paramsHash].voteRegisterParams = _voteRegisterParams;
        parameters[paramsHash].voteRemoveParams = _voteRemoveParams;
        parameters[paramsHash].intVote = _intVote;
        return paramsHash;
    }

    function GETPARAMETERSHASH529(
        bytes32 _voteRegisterParams,
        bytes32 _voteRemoveParams,
        IntVoteInterface _intVote
    ) public pure returns(bytes32)
    {
        return keccak256(abi.encodePacked(_voteRegisterParams, _voteRemoveParams, _intVote));
    }


    function PROPOSESCHEME503(
        Avatar _avatar,
        address _scheme,
        bytes32 _parametersHash,
        bytes4 _permissions,
        string memory _descriptionHash
    )
    public
    returns(bytes32)
    {

        require(_scheme != address(0), "scheme cannot be zero");
        Parameters memory controllerParams = parameters[GETPARAMETERSFROMCONTROLLER560(_avatar)];

        bytes32 proposalId = controllerParams.intVote.PROPOSE661(
            2,
            controllerParams.voteRegisterParams,
            msg.sender,
            address(_avatar)
        );

        SchemeProposal memory proposal = SchemeProposal({
            scheme: _scheme,
            parametersHash: _parametersHash,
            addScheme: true,
            permissions: _permissions
        });
        emit NEWSCHEMEPROPOSAL971(
            address(_avatar),
            proposalId,
            address(controllerParams.intVote),
            _scheme, _parametersHash,
            _permissions,
            _descriptionHash
        );
        organizationsProposals[address(_avatar)][proposalId] = proposal;
        proposalsInfo[address(controllerParams.intVote)][proposalId] = ProposalInfo({
            blockNumber:block.number,
            avatar:_avatar
        });
        return proposalId;
    }


    function PROPOSETOREMOVESCHEME279(Avatar _avatar, address _scheme, string memory _descriptionHash)
    public
    returns(bytes32)
    {
        require(_scheme != address(0), "scheme cannot be zero");
        bytes32 paramsHash = GETPARAMETERSFROMCONTROLLER560(_avatar);
        Parameters memory params = parameters[paramsHash];

        IntVoteInterface intVote = params.intVote;
        bytes32 proposalId = intVote.PROPOSE661(2, params.voteRemoveParams, msg.sender, address(_avatar));
        organizationsProposals[address(_avatar)][proposalId].scheme = _scheme;
        emit REMOVESCHEMEPROPOSAL965(address(_avatar), proposalId, address(intVote), _scheme, _descriptionHash);
        proposalsInfo[address(params.intVote)][proposalId] = ProposalInfo({
            blockNumber:block.number,
            avatar:_avatar
        });
        return proposalId;
    }
}
