





pragma solidity ^0.5.11;


contract IManager {
    event SetController(address controller);
    event ParameterUpdate(string param);

    function setController(address _controller) external;
}



pragma solidity ^0.5.11;







contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);






    constructor() public {
        owner = msg.sender;
    }




    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }






    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}



pragma solidity ^0.5.11;







contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;





    modifier whenNotPaused() {
        require(!paused);
        _;
    }




    modifier whenPaused() {
        require(paused);
        _;
    }




    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }




    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}



pragma solidity ^0.5.11;



contract IController is Pausable {
    event SetContractInfo(bytes32 id, address contractAddress, bytes20 gitCommitHash);

    function setContractInfo(bytes32 _id, address _contractAddress, bytes20 _gitCommitHash) external;
    function updateController(bytes32 _id, address _controller) external;
    function getContract(bytes32 _id) public view returns (address);
}



pragma solidity ^0.5.11;




contract Manager is IManager {

    IController public controller;


    modifier onlyController() {
        require(msg.sender == address(controller), "caller must be Controller");
        _;
    }


    modifier onlyControllerOwner() {
        require(msg.sender == controller.owner(), "caller must be Controller owner");
        _;
    }


    modifier whenSystemNotPaused() {
        require(!controller.paused(), "system is paused");
        _;
    }


    modifier whenSystemPaused() {
        require(controller.paused(), "system is not paused");
        _;
    }

    constructor(address _controller) public {
        controller = IController(_controller);
    }





    function setController(address _controller) external onlyController {
        controller = IController(_controller);

        emit SetController(_controller);
    }
}



pragma solidity ^0.5.11;










contract ManagerProxyTarget is Manager {

    bytes32 public targetContractId;
}



pragma solidity ^0.5.11;






contract IBondingManager {
    event TranscoderUpdate(address indexed transcoder, uint256 rewardCut, uint256 feeShare);
    event TranscoderActivated(address indexed transcoder, uint256 activationRound);
    event TranscoderDeactivated(address indexed transcoder, uint256 deactivationRound);
    event TranscoderSlashed(address indexed transcoder, address finder, uint256 penalty, uint256 finderReward);
    event Reward(address indexed transcoder, uint256 amount);
    event Bond(address indexed newDelegate, address indexed oldDelegate, address indexed delegator, uint256 additionalAmount, uint256 bondedAmount);
    event Unbond(address indexed delegate, address indexed delegator, uint256 unbondingLockId, uint256 amount, uint256 withdrawRound);
    event Rebond(address indexed delegate, address indexed delegator, uint256 unbondingLockId, uint256 amount);
    event WithdrawStake(address indexed delegator, uint256 unbondingLockId, uint256 amount, uint256 withdrawRound);
    event WithdrawFees(address indexed delegator);
    event EarningsClaimed(address indexed delegate, address indexed delegator, uint256 rewards, uint256 fees, uint256 startRound, uint256 endRound);












    function updateTranscoderWithFees(address _transcoder, uint256 _fees, uint256 _round) external;
    function slashTranscoder(address _transcoder, address _finder, uint256 _slashAmount, uint256 _finderFee) external;
    function setCurrentRoundTotalActiveStake() external;


    function getTranscoderPoolSize() public view returns (uint256);
    function transcoderTotalStake(address _transcoder) public view returns (uint256);
    function isActiveTranscoder(address _transcoder) public view returns (bool);
    function getTotalBonded() public view returns (uint256);
}



pragma solidity ^0.5.0;














library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}



pragma solidity ^0.5.11;














library SortedDoublyLL {
    using SafeMath for uint256;


    struct Node {
        uint256 key;
        address nextId;
        address prevId;
    }


    struct Data {
        address head;
        address tail;
        uint256 maxSize;
        uint256 size;
        mapping (address => Node) nodes;
    }





    function setMaxSize(Data storage self, uint256 _size) public {
        require(_size > self.maxSize, "new max size must be greater than old max size");

        self.maxSize = _size;
    }








    function insert(Data storage self, address _id, uint256 _key, address _prevId, address _nextId) public {

        require(!isFull(self), "list is full");

        require(!contains(self, _id), "node already in list");

        require(_id != address(0), "node id is null");

        require(_key > 0, "key is zero");

        address prevId = _prevId;
        address nextId = _nextId;

        if (!validInsertPosition(self, _key, prevId, nextId)) {


            (prevId, nextId) = findInsertPosition(self, _key, prevId, nextId);
        }

        self.nodes[_id].key = _key;

        if (prevId == address(0) && nextId == address(0)) {

            self.head = _id;
            self.tail = _id;
        } else if (prevId == address(0)) {

            self.nodes[_id].nextId = self.head;
            self.nodes[self.head].prevId = _id;
            self.head = _id;
        } else if (nextId == address(0)) {

            self.nodes[_id].prevId = self.tail;
            self.nodes[self.tail].nextId = _id;
            self.tail = _id;
        } else {

            self.nodes[_id].nextId = nextId;
            self.nodes[_id].prevId = prevId;
            self.nodes[prevId].nextId = _id;
            self.nodes[nextId].prevId = _id;
        }

        self.size = self.size.add(1);
    }





    function remove(Data storage self, address _id) public {

        require(contains(self, _id), "node not in list");

        if (self.size > 1) {

            if (_id == self.head) {


                self.head = self.nodes[_id].nextId;

                self.nodes[self.head].prevId = address(0);
            } else if (_id == self.tail) {


                self.tail = self.nodes[_id].prevId;

                self.nodes[self.tail].nextId = address(0);
            } else {


                self.nodes[self.nodes[_id].prevId].nextId = self.nodes[_id].nextId;

                self.nodes[self.nodes[_id].nextId].prevId = self.nodes[_id].prevId;
            }
        } else {


            self.head = address(0);
            self.tail = address(0);
        }

        delete self.nodes[_id];
        self.size = self.size.sub(1);
    }








    function updateKey(Data storage self, address _id, uint256 _newKey, address _prevId, address _nextId) public {

        require(contains(self, _id), "node not in list");


        remove(self, _id);

        if (_newKey > 0) {

            insert(self, _id, _newKey, _prevId, _nextId);
        }
    }






    function contains(Data storage self, address _id) public view returns (bool) {

        return self.nodes[_id].key > 0;
    }





    function isFull(Data storage self) public view returns (bool) {
        return self.size == self.maxSize;
    }





    function isEmpty(Data storage self) public view returns (bool) {
        return self.size == 0;
    }





    function getSize(Data storage self) public view returns (uint256) {
        return self.size;
    }




    function getMaxSize(Data storage self) public view returns (uint256) {
        return self.maxSize;
    }






    function getKey(Data storage self, address _id) public view returns (uint256) {
        return self.nodes[_id].key;
    }





    function getFirst(Data storage self) public view returns (address) {
        return self.head;
    }





    function getLast(Data storage self) public view returns (address) {
        return self.tail;
    }






    function getNext(Data storage self, address _id) public view returns (address) {
        return self.nodes[_id].nextId;
    }






    function getPrev(Data storage self, address _id) public view returns (address) {
        return self.nodes[_id].prevId;
    }








    function validInsertPosition(Data storage self, uint256 _key, address _prevId, address _nextId) public view returns (bool) {
        if (_prevId == address(0) && _nextId == address(0)) {

            return isEmpty(self);
        } else if (_prevId == address(0)) {

            return self.head == _nextId && _key >= self.nodes[_nextId].key;
        } else if (_nextId == address(0)) {

            return self.tail == _prevId && _key <= self.nodes[_prevId].key;
        } else {

            return self.nodes[_prevId].nextId == _nextId && self.nodes[_prevId].key >= _key && _key >= self.nodes[_nextId].key;
        }
    }






    function descendList(Data storage self, uint256 _key, address _startId) private view returns (address, address) {

        if (self.head == _startId && _key >= self.nodes[_startId].key) {
            return (address(0), _startId);
        }

        address prevId = _startId;
        address nextId = self.nodes[prevId].nextId;


        while (prevId != address(0) && !validInsertPosition(self, _key, prevId, nextId)) {
            prevId = self.nodes[prevId].nextId;
            nextId = self.nodes[prevId].nextId;
        }

        return (prevId, nextId);
    }






    function ascendList(Data storage self, uint256 _key, address _startId) private view returns (address, address) {

        if (self.tail == _startId && _key <= self.nodes[_startId].key) {
            return (_startId, address(0));
        }

        address nextId = _startId;
        address prevId = self.nodes[nextId].prevId;


        while (nextId != address(0) && !validInsertPosition(self, _key, prevId, nextId)) {
            nextId = self.nodes[nextId].prevId;
            prevId = self.nodes[nextId].prevId;
        }

        return (prevId, nextId);
    }







    function findInsertPosition(Data storage self, uint256 _key, address _prevId, address _nextId) private view returns (address, address) {
        address prevId = _prevId;
        address nextId = _nextId;

        if (prevId != address(0)) {
            if (!contains(self, prevId) || _key > self.nodes[prevId].key) {

                prevId = address(0);
            }
        }

        if (nextId != address(0)) {
            if (!contains(self, nextId) || _key < self.nodes[nextId].key) {

                nextId = address(0);
            }
        }

        if (prevId == address(0) && nextId == address(0)) {

            return descendList(self, _key, self.head);
        } else if (prevId == address(0)) {

            return ascendList(self, _key, nextId);
        } else if (nextId == address(0)) {

            return descendList(self, _key, prevId);
        } else {

            return descendList(self, _key, prevId);
        }
    }
}



pragma solidity ^0.5.11;



library MathUtils {
    using SafeMath for uint256;


    uint256 public constant PERC_DIVISOR = 1000000;





    function validPerc(uint256 _amount) internal pure returns (bool) {
        return _amount <= PERC_DIVISOR;
    }







    function percOf(uint256 _amount, uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256) {
        return _amount.mul(percPoints(_fracNum, _fracDenom)).div(PERC_DIVISOR);
    }






    function percOf(uint256 _amount, uint256 _fracNum) internal pure returns (uint256) {
        return _amount.mul(_fracNum).div(PERC_DIVISOR);
    }






    function percPoints(uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256) {
        return _fracNum.mul(PERC_DIVISOR).div(_fracDenom);
    }
}



pragma solidity ^0.5.11;








library EarningsPool {
    using SafeMath for uint256;






    struct Data {
        uint256 rewardPool;
        uint256 feePool;
        uint256 totalStake;
        uint256 claimableStake;
        uint256 transcoderRewardCut;
        uint256 transcoderFeeShare;
        uint256 transcoderRewardPool;
        uint256 transcoderFeePool;
        bool hasTranscoderRewardFeePool;



        uint256 cumulativeRewardFactor;
        uint256 cumulativeFeeFactor;
    }







    function setCommission(EarningsPool.Data storage earningsPool, uint256 _rewardCut, uint256 _feeShare) internal {
        earningsPool.transcoderRewardCut = _rewardCut;
        earningsPool.transcoderFeeShare = _feeShare;




    }






    function setStake(EarningsPool.Data storage earningsPool, uint256 _stake) internal {
        earningsPool.totalStake = _stake;


    }





    function hasClaimableShares(EarningsPool.Data storage earningsPool) internal view returns (bool) {
        return earningsPool.claimableStake > 0;
    }







    function feePoolShare(EarningsPool.Data storage earningsPool, uint256 _stake, bool _isTranscoder) internal view returns (uint256) {
        uint256 delegatorFees = 0;
        uint256 transcoderFees = 0;

        if (earningsPool.hasTranscoderRewardFeePool) {
            (delegatorFees, transcoderFees) = feePoolShareWithTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
        } else {
            (delegatorFees, transcoderFees) = feePoolShareNoTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
        }

        return delegatorFees.add(transcoderFees);
    }







    function rewardPoolShare(EarningsPool.Data storage earningsPool, uint256 _stake, bool _isTranscoder) internal view returns (uint256) {
        uint256 delegatorRewards = 0;
        uint256 transcoderRewards = 0;

        if (earningsPool.hasTranscoderRewardFeePool) {
            (delegatorRewards, transcoderRewards) = rewardPoolShareWithTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
        } else {
            (delegatorRewards, transcoderRewards) = rewardPoolShareNoTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
        }

        return delegatorRewards.add(transcoderRewards);
    }







    function feePoolShareWithTranscoderRewardFeePool(
        EarningsPool.Data storage earningsPool,
        uint256 _stake,
        bool _isTranscoder
    )
        internal
        view
        returns (uint256, uint256)
    {


        uint256 delegatorFees = earningsPool.claimableStake > 0 ? MathUtils.percOf(earningsPool.feePool, _stake, earningsPool.claimableStake) : 0;


        return _isTranscoder ? (delegatorFees, earningsPool.transcoderFeePool) : (delegatorFees, 0);
    }







    function rewardPoolShareWithTranscoderRewardFeePool(
        EarningsPool.Data storage earningsPool,
        uint256 _stake,
        bool _isTranscoder
    )
        internal
        view
        returns (uint256, uint256)
    {


        uint256 delegatorRewards = earningsPool.claimableStake > 0 ? MathUtils.percOf(earningsPool.rewardPool, _stake, earningsPool.claimableStake) : 0;


        return _isTranscoder ? (delegatorRewards, earningsPool.transcoderRewardPool) : (delegatorRewards, 0);
    }








    function feePoolShareNoTranscoderRewardFeePool(
        EarningsPool.Data storage earningsPool,
        uint256 _stake,
        bool _isTranscoder
    )
        internal
        view
        returns (uint256, uint256)
    {
        uint256 transcoderFees = 0;
        uint256 delegatorFees = 0;

        if (earningsPool.claimableStake > 0) {
            uint256 delegatorsFees = MathUtils.percOf(earningsPool.feePool, earningsPool.transcoderFeeShare);
            transcoderFees = earningsPool.feePool.sub(delegatorsFees);
            delegatorFees = MathUtils.percOf(delegatorsFees, _stake, earningsPool.claimableStake);
        }

        if (_isTranscoder) {
            return (delegatorFees, transcoderFees);
        } else {
            return (delegatorFees, 0);
        }
    }








    function rewardPoolShareNoTranscoderRewardFeePool(
        EarningsPool.Data storage earningsPool,
        uint256 _stake,
        bool _isTranscoder
    )
        internal
        view
        returns (uint256, uint256)
    {
        uint256 transcoderRewards = 0;
        uint256 delegatorRewards = 0;

        if (earningsPool.claimableStake > 0) {
            transcoderRewards = MathUtils.percOf(earningsPool.rewardPool, earningsPool.transcoderRewardCut);
            delegatorRewards = MathUtils.percOf(earningsPool.rewardPool.sub(transcoderRewards), _stake, earningsPool.claimableStake);
        }

        if (_isTranscoder) {
            return (delegatorRewards, transcoderRewards);
        } else {
            return (delegatorRewards, 0);
        }
    }
}



pragma solidity ^0.5.11;




library EarningsPoolLIP36 {
    using SafeMath for uint256;







    function updateCumulativeFeeFactor(EarningsPool.Data storage earningsPool, EarningsPool.Data memory _prevEarningsPool, uint256 _fees) internal {
        uint256 prevCumulativeFeeFactor = _prevEarningsPool.cumulativeFeeFactor;
        uint256 prevCumulativeRewardFactor = _prevEarningsPool.cumulativeRewardFactor != 0 ? _prevEarningsPool.cumulativeRewardFactor : MathUtils.percPoints(1,1);


        if (earningsPool.cumulativeFeeFactor == 0) {
            earningsPool.cumulativeFeeFactor = prevCumulativeFeeFactor.add(
                MathUtils.percOf(prevCumulativeRewardFactor, _fees, earningsPool.totalStake)
            );
            return;
        }

        earningsPool.cumulativeFeeFactor = earningsPool.cumulativeFeeFactor.add(
            MathUtils.percOf(prevCumulativeRewardFactor, _fees, earningsPool.totalStake)
        );
    }







    function updateCumulativeRewardFactor(EarningsPool.Data storage earningsPool, EarningsPool.Data storage _prevEarningsPool, uint256 _rewards) internal {
        uint256 prevCumulativeRewardFactor = _prevEarningsPool.cumulativeRewardFactor != 0 ? _prevEarningsPool.cumulativeRewardFactor : MathUtils.percPoints(1,1);

        earningsPool.cumulativeRewardFactor = prevCumulativeRewardFactor.add(
            MathUtils.percOf(prevCumulativeRewardFactor, _rewards, earningsPool.totalStake)
        );
    }
}



pragma solidity ^0.5.0;





interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity ^0.5.0;


























contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }














    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }







    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}



pragma solidity ^0.5.11;




contract ILivepeerToken is ERC20, Ownable {
    function mint(address _to, uint256 _amount) public returns (bool);
    function burn(uint256 _amount) public;
}



pragma solidity ^0.5.11;






contract IMinter {

    event SetCurrentRewardTokens(uint256 currentMintableTokens, uint256 currentInflation);


    function createReward(uint256 _fracNum, uint256 _fracDenom) external returns (uint256);
    function trustedTransferTokens(address _to, uint256 _amount) external;
    function trustedBurnTokens(uint256 _amount) external;
    function trustedWithdrawETH(address payable _to, uint256 _amount) external;
    function depositETH() external payable returns (bool);
    function setCurrentRewardTokens() external;
    function currentMintableTokens() external view returns (uint256);
    function currentMintedTokens() external view returns (uint256);

    function getController() public view returns (IController);
}



pragma solidity ^0.5.11;





contract IRoundsManager {

    event NewRound(uint256 indexed round, bytes32 blockHash);







    function initializeRound() external;
    function lipUpgradeRound(uint256 _lip) external view returns (uint256);


    function blockNum() public view returns (uint256);
    function blockHash(uint256 _block) public view returns (bytes32);
    function blockHashForRound(uint256 _round) public view returns (bytes32);
    function currentRound() public view returns (uint256);
    function currentRoundStartBlock() public view returns (uint256);
    function currentRoundInitialized() public view returns (bool);
    function currentRoundLocked() public view returns (bool);
}



pragma solidity 0.5.11;
















contract BondingManager is ManagerProxyTarget, IBondingManager {
    using SafeMath for uint256;
    using SortedDoublyLL for SortedDoublyLL.Data;
    using EarningsPool for EarningsPool.Data;
    using EarningsPoolLIP36 for EarningsPool.Data;




    uint256 constant MAX_FUTURE_ROUND = 2**256 - 1;


    uint64 public unbondingPeriod;

    uint256 public numActiveTranscodersDEPRECATED;

    uint256 public maxEarningsClaimsRounds;


    struct Transcoder {
        uint256 lastRewardRound;
        uint256 rewardCut;
        uint256 feeShare;
        uint256 pricePerSegmentDEPRECATED;
        uint256 pendingRewardCutDEPRECATED;
        uint256 pendingFeeShareDEPRECATED;
        uint256 pendingPricePerSegmentDEPRECATED;
        mapping (uint256 => EarningsPool.Data) earningsPoolPerRound;
        uint256 lastActiveStakeUpdateRound;
        uint256 activationRound;
        uint256 deactivationRound;
        uint256 activeCumulativeRewards;
        uint256 cumulativeRewards;
        uint256 cumulativeFees;
        uint256 lastFeeRound;
    }


    enum TranscoderStatus { NotRegistered, Registered }


    struct Delegator {
        uint256 bondedAmount;
        uint256 fees;
        address delegateAddress;
        uint256 delegatedAmount;
        uint256 startRound;
        uint256 withdrawRoundDEPRECATED;
        uint256 lastClaimRound;
        uint256 nextUnbondingLockId;
        mapping (uint256 => UnbondingLock) unbondingLocks;
    }


    enum DelegatorStatus { Pending, Bonded, Unbonded }


    struct UnbondingLock {
        uint256 amount;
        uint256 withdrawRound;
    }


    mapping (address => Delegator) private delegators;
    mapping (address => Transcoder) private transcoders;




    uint256 private totalBondedDEPRECATED;


    SortedDoublyLL.Data private transcoderPoolDEPRECATED;


    struct ActiveTranscoderSetDEPRECATED {
        address[] transcoders;
        mapping (address => bool) isActive;
        uint256 totalStake;
    }


    mapping (uint256 => ActiveTranscoderSetDEPRECATED) public activeTranscoderSetDEPRECATED;


    uint256 public currentRoundTotalActiveStake;

    uint256 public nextRoundTotalActiveStake;




    SortedDoublyLL.Data private transcoderPoolV2;


    modifier onlyTicketBroker() {
        require(
            msg.sender == controller.getContract(keccak256("TicketBroker")),
            "caller must be TicketBroker"
        );
        _;
    }


    modifier onlyRoundsManager() {
        require(
            msg.sender == controller.getContract(keccak256("RoundsManager")),
            "caller must be RoundsManager"
        );
        _;
    }


    modifier onlyVerifier() {
        require(msg.sender == controller.getContract(keccak256("Verifier")), "caller must be Verifier");
        _;
    }


    modifier currentRoundInitialized() {
        require(roundsManager().currentRoundInitialized(), "current round is not initialized");
        _;
    }


    modifier autoClaimEarnings() {
        uint256 currentRound = roundsManager().currentRound();
        uint256 lastClaimRound = delegators[msg.sender].lastClaimRound;
        if (lastClaimRound < currentRound) {
            updateDelegatorWithEarnings(msg.sender, currentRound, lastClaimRound);
        }
        _;
    }










    constructor(address _controller) public Manager(_controller) {}





    function setUnbondingPeriod(uint64 _unbondingPeriod) external onlyControllerOwner {
        unbondingPeriod = _unbondingPeriod;

        emit ParameterUpdate("unbondingPeriod");
    }





    function setNumActiveTranscoders(uint256 _numActiveTranscoders) external onlyControllerOwner {
        transcoderPoolV2.setMaxSize(_numActiveTranscoders);

        emit ParameterUpdate("numActiveTranscoders");
    }





    function setMaxEarningsClaimsRounds(uint256 _maxEarningsClaimsRounds) external onlyControllerOwner {
        maxEarningsClaimsRounds = _maxEarningsClaimsRounds;

        emit ParameterUpdate("maxEarningsClaimsRounds");
    }







    function transcoder(uint256 _rewardCut, uint256 _feeShare) external {
        transcoderWithHint(_rewardCut, _feeShare, address(0), address(0));
    }






    function bond(uint256 _amount, address _to) external {
        bondWithHint(
            _amount,
            _to,
            address(0),
            address(0),
            address(0),
            address(0)
        );
    }





    function unbond(uint256 _amount) external {
        unbondWithHint(_amount, address(0), address(0));
    }





    function rebond(uint256 _unbondingLockId) external {
        rebondWithHint(_unbondingLockId, address(0), address(0));
    }






    function rebondFromUnbonded(address _to, uint256 _unbondingLockId) external {
        rebondFromUnbondedWithHint(_to, _unbondingLockId, address(0), address(0));
    }





    function withdrawStake(uint256 _unbondingLockId)
        external
        whenSystemNotPaused
        currentRoundInitialized
    {
        Delegator storage del = delegators[msg.sender];
        UnbondingLock storage lock = del.unbondingLocks[_unbondingLockId];

        require(isValidUnbondingLock(msg.sender, _unbondingLockId), "invalid unbonding lock ID");
        require(lock.withdrawRound <= roundsManager().currentRound(), "withdraw round must be before or equal to the current round");

        uint256 amount = lock.amount;
        uint256 withdrawRound = lock.withdrawRound;

        delete del.unbondingLocks[_unbondingLockId];


        minter().trustedTransferTokens(msg.sender, amount);

        emit WithdrawStake(msg.sender, _unbondingLockId, amount, withdrawRound);
    }




    function withdrawFees()
        external
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        uint256 fees = delegators[msg.sender].fees;
        require(fees > 0, "no fees to withdraw");
        delegators[msg.sender].fees = 0;


        minter().trustedWithdrawETH(msg.sender, fees);

        emit WithdrawFees(msg.sender);
    }




    function reward() external {
        rewardWithHint(address(0), address(0));
    }






    function updateTranscoderWithFees(
        address _transcoder,
        uint256 _fees,
        uint256 _round
    )
        external
        whenSystemNotPaused
        onlyTicketBroker
    {

        _round;

        require(isRegisteredTranscoder(_transcoder), "transcoder must be registered");

        uint256 currentRound = roundsManager().currentRound();

        Transcoder storage t = transcoders[_transcoder];

        uint256 lastRewardRound = t.lastRewardRound;
        uint256 activeCumulativeRewards = t.activeCumulativeRewards;



        EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[currentRound];
        EarningsPool.Data memory prevEarningsPool = latestCumulativeFactorsPool(t, currentRound.sub(1));




        if (currentRound > lastRewardRound) {
            earningsPool.setCommission(
                t.rewardCut,
                t.feeShare
            );

            uint256 lastUpdateRound = t.lastActiveStakeUpdateRound;
            if (lastUpdateRound < currentRound) {
                earningsPool.setStake(t.earningsPoolPerRound[lastUpdateRound].totalStake);
            }





            activeCumulativeRewards = t.cumulativeRewards;
        }

        uint256 totalStake = earningsPool.totalStake;
        if (prevEarningsPool.cumulativeRewardFactor == 0 && lastRewardRound == currentRound) {



            IMinter mtr = minter();
            uint256 rewards = MathUtils.percOf(mtr.currentMintableTokens().add(mtr.currentMintedTokens()), totalStake, currentRoundTotalActiveStake);
            uint256 transcoderCommissionRewards = MathUtils.percOf(rewards, earningsPool.transcoderRewardCut);
            uint256 delegatorsRewards = rewards.sub(transcoderCommissionRewards);

            prevEarningsPool.cumulativeRewardFactor = MathUtils.percOf(
                earningsPool.cumulativeRewardFactor,
                totalStake,
                delegatorsRewards.add(totalStake)
            );
        }

        uint256 delegatorsFees = MathUtils.percOf(_fees, earningsPool.transcoderFeeShare);
        uint256 transcoderCommissionFees = _fees.sub(delegatorsFees);

        uint256 transcoderRewardStakeFees = MathUtils.percOf(delegatorsFees, activeCumulativeRewards, totalStake);

        t.cumulativeFees = t.cumulativeFees.add(transcoderRewardStakeFees).add(transcoderCommissionFees);




        earningsPool.updateCumulativeFeeFactor(prevEarningsPool, delegatorsFees);

        t.lastFeeRound = currentRound;
    }








    function slashTranscoder(
        address _transcoder,
        address _finder,
        uint256 _slashAmount,
        uint256 _finderFee
    )
        external
        whenSystemNotPaused
        onlyVerifier
    {
        Delegator storage del = delegators[_transcoder];

        if (del.bondedAmount > 0) {
            uint256 penalty = MathUtils.percOf(delegators[_transcoder].bondedAmount, _slashAmount);


            if (transcoderPoolV2.contains(_transcoder)) {
                resignTranscoder(_transcoder);
            }


            del.bondedAmount = del.bondedAmount.sub(penalty);


            if (delegatorStatus(_transcoder) == DelegatorStatus.Bonded) {
                delegators[del.delegateAddress].delegatedAmount = delegators[del.delegateAddress].delegatedAmount.sub(penalty);
            }


            uint256 burnAmount = penalty;


            if (_finder != address(0)) {
                uint256 finderAmount = MathUtils.percOf(penalty, _finderFee);
                minter().trustedTransferTokens(_finder, finderAmount);


                minter().trustedBurnTokens(burnAmount.sub(finderAmount));

                emit TranscoderSlashed(_transcoder, _finder, penalty, finderAmount);
            } else {

                minter().trustedBurnTokens(burnAmount);

                emit TranscoderSlashed(_transcoder, address(0), penalty, 0);
            }
        } else {
            emit TranscoderSlashed(_transcoder, _finder, 0, 0);
        }
    }





    function claimEarnings(uint256 _endRound) external whenSystemNotPaused currentRoundInitialized {
        uint256 lastClaimRound = delegators[msg.sender].lastClaimRound;
        require(lastClaimRound < _endRound, "end round must be after last claim round");
        require(_endRound <= roundsManager().currentRound(), "end round must be before or equal to current round");

        updateDelegatorWithEarnings(msg.sender, _endRound, lastClaimRound);
    }




    function setCurrentRoundTotalActiveStake() external onlyRoundsManager {
        currentRoundTotalActiveStake = nextRoundTotalActiveStake;
    }












    function transcoderWithHint(uint256 _rewardCut, uint256 _feeShare, address _newPosPrev, address _newPosNext)
        public
        whenSystemNotPaused
        currentRoundInitialized
    {
        require(
            !roundsManager().currentRoundLocked(),
            "can't update transcoder params, current round is locked"
        );
        require(MathUtils.validPerc(_rewardCut), "invalid rewardCut percentage");
        require(MathUtils.validPerc(_feeShare), "invalid feeShare percentage");
        require(isRegisteredTranscoder(msg.sender), "transcoder must be registered");

        Transcoder storage t = transcoders[msg.sender];
        uint256 currentRound = roundsManager().currentRound();

        require(
            !isActiveTranscoder(msg.sender) || t.lastRewardRound == currentRound,
            "caller can't be active or must have already called reward for the current round"
        );

        t.rewardCut = _rewardCut;
        t.feeShare = _feeShare;

        if (!transcoderPoolV2.contains(msg.sender)) {
            tryToJoinActiveSet(msg.sender, delegators[msg.sender].delegatedAmount, currentRound.add(1), _newPosPrev, _newPosNext);
        }

        emit TranscoderUpdate(msg.sender, _rewardCut, _feeShare);
    }
















    function bondWithHint(
        uint256 _amount,
        address _to,
        address _oldDelegateNewPosPrev,
        address _oldDelegateNewPosNext,
        address _currDelegateNewPosPrev,
        address _currDelegateNewPosNext
    )
        public
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        Delegator storage del = delegators[msg.sender];

        uint256 currentRound = roundsManager().currentRound();

        uint256 delegationAmount = _amount;

        address currentDelegate = del.delegateAddress;

        if (delegatorStatus(msg.sender) == DelegatorStatus.Unbonded) {



            del.startRound = currentRound.add(1);


        } else if (currentDelegate != address(0) && currentDelegate != _to) {





            require(!isRegisteredTranscoder(msg.sender), "registered transcoders can't delegate towards other addresses");


            del.startRound = currentRound.add(1);

            delegationAmount = delegationAmount.add(del.bondedAmount);

            decreaseTotalStake(currentDelegate, del.bondedAmount, _oldDelegateNewPosPrev, _oldDelegateNewPosNext);
        }


        require(delegationAmount > 0, "delegation amount must be greater than 0");

        del.delegateAddress = _to;

        del.bondedAmount = del.bondedAmount.add(_amount);


        increaseTotalStake(_to, delegationAmount, _currDelegateNewPosPrev, _currDelegateNewPosNext);

        if (_amount > 0) {

            livepeerToken().transferFrom(msg.sender, address(minter()), _amount);
        }

        emit Bond(_to, currentDelegate, msg.sender, _amount, del.bondedAmount);
    }










    function unbondWithHint(uint256 _amount, address _newPosPrev, address _newPosNext)
        public
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        require(delegatorStatus(msg.sender) == DelegatorStatus.Bonded, "caller must be bonded");

        Delegator storage del = delegators[msg.sender];

        require(_amount > 0, "unbond amount must be greater than 0");
        require(_amount <= del.bondedAmount, "amount is greater than bonded amount");

        address currentDelegate = del.delegateAddress;
        uint256 currentRound = roundsManager().currentRound();
        uint256 withdrawRound = currentRound.add(unbondingPeriod);
        uint256 unbondingLockId = del.nextUnbondingLockId;


        del.unbondingLocks[unbondingLockId] = UnbondingLock({
            amount: _amount,
            withdrawRound: withdrawRound
        });

        del.nextUnbondingLockId = unbondingLockId.add(1);

        del.bondedAmount = del.bondedAmount.sub(_amount);

        if (del.bondedAmount == 0) {

            del.delegateAddress = address(0);

            del.startRound = 0;

            if (transcoderPoolV2.contains(msg.sender)) {
                resignTranscoder(msg.sender);
            }
        }


        decreaseTotalStake(currentDelegate, _amount, _newPosPrev, _newPosNext);

        emit Unbond(currentDelegate, msg.sender, unbondingLockId, _amount, withdrawRound);
    }











    function rebondWithHint(
        uint256 _unbondingLockId,
        address _newPosPrev,
        address _newPosNext
    )
        public
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        require(delegatorStatus(msg.sender) != DelegatorStatus.Unbonded, "caller must be bonded");


        processRebond(msg.sender, _unbondingLockId, _newPosPrev, _newPosNext);
    }












    function rebondFromUnbondedWithHint(
        address _to,
        uint256 _unbondingLockId,
        address _newPosPrev,
        address _newPosNext
    )
        public
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        require(delegatorStatus(msg.sender) == DelegatorStatus.Unbonded, "caller must be unbonded");


        delegators[msg.sender].startRound = roundsManager().currentRound().add(1);

        delegators[msg.sender].delegateAddress = _to;

        processRebond(msg.sender, _unbondingLockId, _newPosPrev, _newPosNext);
    }









    function rewardWithHint(address _newPosPrev, address _newPosNext) public whenSystemNotPaused currentRoundInitialized {
        uint256 currentRound = roundsManager().currentRound();

        require(isActiveTranscoder(msg.sender), "caller must be an active transcoder");
        require(transcoders[msg.sender].lastRewardRound != currentRound, "caller has already called reward for the current round");

        Transcoder storage t = transcoders[msg.sender];
        EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[currentRound];


        earningsPool.setCommission(t.rewardCut, t.feeShare);





        uint256 lastUpdateRound = t.lastActiveStakeUpdateRound;
        if (lastUpdateRound < currentRound) {
            earningsPool.setStake(t.earningsPoolPerRound[lastUpdateRound].totalStake);
        }



        uint256 rewardTokens = minter().createReward(earningsPool.totalStake, currentRoundTotalActiveStake);

        updateTranscoderWithRewards(msg.sender, rewardTokens, currentRound, _newPosPrev, _newPosNext);


        t.lastRewardRound = currentRound;

        emit Reward(msg.sender, rewardTokens);
    }







    function pendingStake(address _delegator, uint256 _endRound) public view returns (uint256) {
        (
            uint256 stake,
        ) = pendingStakeAndFees(_delegator, _endRound);
        return stake;
    }







    function pendingFees(address _delegator, uint256 _endRound) public view returns (uint256) {
        (
            ,
            uint256 fees
        ) = pendingStakeAndFees(_delegator, _endRound);
        return fees;
    }






    function transcoderTotalStake(address _transcoder) public view returns (uint256) {
        return delegators[_transcoder].delegatedAmount;
    }






    function transcoderStatus(address _transcoder) public view returns (TranscoderStatus) {
        if (isRegisteredTranscoder(_transcoder)) return TranscoderStatus.Registered;
        return TranscoderStatus.NotRegistered;
    }






    function delegatorStatus(address _delegator) public view returns (DelegatorStatus) {
        Delegator storage del = delegators[_delegator];

        if (del.bondedAmount == 0) {

            return DelegatorStatus.Unbonded;
        } else if (del.startRound > roundsManager().currentRound()) {

            return DelegatorStatus.Pending;
        } else {



            return DelegatorStatus.Bonded;
        }
    }















    function getTranscoder(
        address _transcoder
    )
        public
        view
        returns (uint256 lastRewardRound, uint256 rewardCut, uint256 feeShare, uint256 lastActiveStakeUpdateRound, uint256 activationRound, uint256 deactivationRound, uint256 activeCumulativeRewards, uint256 cumulativeRewards, uint256 cumulativeFees, uint256 lastFeeRound)
    {
        Transcoder storage t = transcoders[_transcoder];

        lastRewardRound = t.lastRewardRound;
        rewardCut = t.rewardCut;
        feeShare = t.feeShare;
        lastActiveStakeUpdateRound = t.lastActiveStakeUpdateRound;
        activationRound = t.activationRound;
        deactivationRound = t.deactivationRound;
        activeCumulativeRewards = t.activeCumulativeRewards;
        cumulativeRewards = t.cumulativeRewards;
        cumulativeFees = t.cumulativeFees;
        lastFeeRound = t.lastFeeRound;
    }

















    function getTranscoderEarningsPoolForRound(
        address _transcoder,
        uint256 _round
    )
        public
        view
        returns (uint256 rewardPool, uint256 feePool, uint256 totalStake, uint256 claimableStake, uint256 transcoderRewardCut, uint256 transcoderFeeShare, uint256 transcoderRewardPool, uint256 transcoderFeePool, bool hasTranscoderRewardFeePool, uint256 cumulativeRewardFactor, uint256 cumulativeFeeFactor)
    {
        EarningsPool.Data storage earningsPool = transcoders[_transcoder].earningsPoolPerRound[_round];

        rewardPool = earningsPool.rewardPool;
        feePool = earningsPool.feePool;
        totalStake = earningsPool.totalStake;
        claimableStake = earningsPool.claimableStake;
        transcoderRewardCut = earningsPool.transcoderRewardCut;
        transcoderFeeShare = earningsPool.transcoderFeeShare;
        transcoderRewardPool = earningsPool.transcoderRewardPool;
        transcoderFeePool = earningsPool.transcoderFeePool;
        hasTranscoderRewardFeePool = earningsPool.hasTranscoderRewardFeePool;
        cumulativeRewardFactor = earningsPool.cumulativeRewardFactor;
        cumulativeFeeFactor = earningsPool.cumulativeFeeFactor;
    }












    function getDelegator(
        address _delegator
    )
        public
        view
        returns (uint256 bondedAmount, uint256 fees, address delegateAddress, uint256 delegatedAmount, uint256 startRound, uint256 lastClaimRound, uint256 nextUnbondingLockId)
    {
        Delegator storage del = delegators[_delegator];

        bondedAmount = del.bondedAmount;
        fees = del.fees;
        delegateAddress = del.delegateAddress;
        delegatedAmount = del.delegatedAmount;
        startRound = del.startRound;
        lastClaimRound = del.lastClaimRound;
        nextUnbondingLockId = del.nextUnbondingLockId;
    }








    function getDelegatorUnbondingLock(
        address _delegator,
        uint256 _unbondingLockId
    )
        public
        view
        returns (uint256 amount, uint256 withdrawRound)
    {
        UnbondingLock storage lock = delegators[_delegator].unbondingLocks[_unbondingLockId];

        return (lock.amount, lock.withdrawRound);
    }





    function getTranscoderPoolMaxSize() public view returns (uint256) {
        return transcoderPoolV2.getMaxSize();
    }





    function getTranscoderPoolSize() public view returns (uint256) {
        return transcoderPoolV2.getSize();
    }





    function getFirstTranscoderInPool() public view returns (address) {
        return transcoderPoolV2.getFirst();
    }






    function getNextTranscoderInPool(address _transcoder) public view returns (address) {
        return transcoderPoolV2.getNext(_transcoder);
    }





    function getTotalBonded() public view returns (uint256) {
        return currentRoundTotalActiveStake;
    }






    function isActiveTranscoder(address _transcoder) public view returns (bool) {
        Transcoder storage t = transcoders[_transcoder];
        uint256 currentRound = roundsManager().currentRound();
        return t.activationRound <= currentRound && currentRound < t.deactivationRound;
    }






    function isRegisteredTranscoder(address _transcoder) public view returns (bool) {
        Delegator storage d = delegators[_transcoder];
        return d.delegateAddress == _transcoder && d.bondedAmount > 0;
    }







    function isValidUnbondingLock(address _delegator, uint256 _unbondingLockId) public view returns (bool) {

        return delegators[_delegator].unbondingLocks[_unbondingLockId].withdrawRound > 0;
    }







    function latestCumulativeFactorsPool(Transcoder storage _transcoder, uint256 _round) internal view returns (EarningsPool.Data memory pool) {
        pool.cumulativeRewardFactor = _transcoder.earningsPoolPerRound[_round].cumulativeRewardFactor;
        pool.cumulativeFeeFactor = _transcoder.earningsPoolPerRound[_round].cumulativeFeeFactor;

        uint256 lastRewardRound = _transcoder.lastRewardRound;

        if (pool.cumulativeRewardFactor == 0 && lastRewardRound < _round) {
            pool.cumulativeRewardFactor = _transcoder.earningsPoolPerRound[lastRewardRound].cumulativeRewardFactor;
        }

        uint256 lastFeeRound = _transcoder.lastFeeRound;

        if (pool.cumulativeFeeFactor == 0 && lastFeeRound < _round) {
            pool.cumulativeFeeFactor = _transcoder.earningsPoolPerRound[lastFeeRound].cumulativeFeeFactor;
        }

        return pool;
    }










    function delegatorCumulativeStakeAndFees(
        Transcoder storage _transcoder,
        uint256 _startRound,
        uint256 _endRound,
        uint256 _stake,
        uint256 _fees
    )
        internal
        view
        returns (uint256 cStake, uint256 cFees)
    {
        uint256 baseRewardFactor = MathUtils.percPoints(1, 1);


        EarningsPool.Data memory startPool;
        startPool.cumulativeRewardFactor = _transcoder.earningsPoolPerRound[_startRound].cumulativeRewardFactor;
        startPool.cumulativeFeeFactor = _transcoder.earningsPoolPerRound[_startRound].cumulativeFeeFactor;

        if (startPool.cumulativeRewardFactor == 0) {
            startPool.cumulativeRewardFactor = baseRewardFactor;
        }


        EarningsPool.Data memory endPool = latestCumulativeFactorsPool(_transcoder, _endRound);

        if (endPool.cumulativeRewardFactor == 0) {
            endPool.cumulativeRewardFactor = baseRewardFactor;
        }

        cFees = _fees.add(
            MathUtils.percOf(
                _stake,
                endPool.cumulativeFeeFactor.sub(startPool.cumulativeFeeFactor),
                startPool.cumulativeRewardFactor
            )
        );

        cStake = MathUtils.percOf(
            _stake,
            endPool.cumulativeRewardFactor,
            startPool.cumulativeRewardFactor
        );

        return (cStake, cFees);
    }







    function pendingStakeAndFees(address _delegator, uint256 _endRound) internal view returns (uint256 stake, uint256 fees) {
        Delegator storage del = delegators[_delegator];
        Transcoder storage t = transcoders[del.delegateAddress];

        fees = del.fees;
        stake = del.bondedAmount;

        uint256 startRound = del.lastClaimRound.add(1);
        address delegateAddr = del.delegateAddress;
        bool isTranscoder = _delegator == delegateAddr;

        uint256 lip36Round = roundsManager().lipUpgradeRound(36);
        while (startRound <= _endRound && startRound <= lip36Round) {
            EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[startRound];




            if (startRound == lip36Round && !earningsPool.hasTranscoderRewardFeePool) {
                break;
            }

            if (earningsPool.hasClaimableShares()) {

                fees = fees.add(earningsPool.feePoolShare(stake, isTranscoder));


                stake = stake.add(earningsPool.rewardPoolShare(stake, isTranscoder));
            }

            startRound = startRound.add(1);
        }








        if (startRound > _endRound) {
            return (stake, fees);
        }



        (
            stake,
            fees
        ) = delegatorCumulativeStakeAndFees(t, startRound.sub(1), _endRound, stake, fees);

        if (isTranscoder) {
            stake = stake.add(t.cumulativeRewards);
            fees = fees.add(t.cumulativeFees);
        }

        return (stake, fees);
    }






    function increaseTotalStake(address _delegate, uint256 _amount, address _newPosPrev, address _newPosNext) internal {
        if (isRegisteredTranscoder(_delegate)) {
            uint256 currStake = transcoderTotalStake(_delegate);
            uint256 newStake = currStake.add(_amount);
            uint256 currRound = roundsManager().currentRound();
            uint256 nextRound = currRound.add(1);


            if (transcoderPoolV2.contains(_delegate)) {
                transcoderPoolV2.updateKey(_delegate, newStake, _newPosPrev, _newPosNext);
                nextRoundTotalActiveStake = nextRoundTotalActiveStake.add(_amount);
                Transcoder storage t = transcoders[_delegate];





                if (t.lastActiveStakeUpdateRound < currRound) {
                    t.earningsPoolPerRound[currRound].setStake(currStake);
                }

                t.earningsPoolPerRound[nextRound].setStake(newStake);
                t.lastActiveStakeUpdateRound = nextRound;
            } else {

                tryToJoinActiveSet(_delegate, newStake, nextRound, _newPosPrev, _newPosNext);
            }
        }


        delegators[_delegate].delegatedAmount = delegators[_delegate].delegatedAmount.add(_amount);
    }






    function decreaseTotalStake(address _delegate, uint256 _amount, address _newPosPrev, address _newPosNext) internal {
        if (transcoderPoolV2.contains(_delegate)) {
            uint256 currStake = transcoderTotalStake(_delegate);
            uint256 newStake = currStake.sub(_amount);
            uint256 currRound = roundsManager().currentRound();
            uint256 nextRound = currRound.add(1);

            transcoderPoolV2.updateKey(_delegate, newStake, _newPosPrev, _newPosNext);
            nextRoundTotalActiveStake = nextRoundTotalActiveStake.sub(_amount);
            Transcoder storage t = transcoders[_delegate];





            if (t.lastActiveStakeUpdateRound < currRound) {
                t.earningsPoolPerRound[currRound].setStake(currStake);
            }

            t.lastActiveStakeUpdateRound = nextRound;
            t.earningsPoolPerRound[nextRound].setStake(newStake);
        }


        delegators[_delegate].delegatedAmount = delegators[_delegate].delegatedAmount.sub(_amount);
    }







    function tryToJoinActiveSet(
        address _transcoder,
        uint256 _totalStake,
        uint256 _activationRound,
        address _newPosPrev,
        address _newPosNext
    )
        internal
    {
        uint256 pendingNextRoundTotalActiveStake = nextRoundTotalActiveStake;

        if (transcoderPoolV2.isFull()) {
            address lastTranscoder = transcoderPoolV2.getLast();
            uint256 lastStake = transcoderTotalStake(lastTranscoder);



            if (_totalStake <= lastStake) {
                return;
            }






            transcoderPoolV2.remove(lastTranscoder);
            transcoders[lastTranscoder].deactivationRound = _activationRound;
            pendingNextRoundTotalActiveStake = pendingNextRoundTotalActiveStake.sub(lastStake);

            emit TranscoderDeactivated(lastTranscoder, _activationRound);
        }

        transcoderPoolV2.insert(_transcoder, _totalStake, _newPosPrev, _newPosNext);
        pendingNextRoundTotalActiveStake = pendingNextRoundTotalActiveStake.add(_totalStake);
        Transcoder storage t = transcoders[_transcoder];
        t.lastActiveStakeUpdateRound = _activationRound;
        t.activationRound = _activationRound;
        t.deactivationRound = MAX_FUTURE_ROUND;
        t.earningsPoolPerRound[_activationRound].setStake(_totalStake);
        nextRoundTotalActiveStake = pendingNextRoundTotalActiveStake;
        emit TranscoderActivated(_transcoder, _activationRound);
    }




    function resignTranscoder(address _transcoder) internal {




        transcoderPoolV2.remove(_transcoder);
        nextRoundTotalActiveStake = nextRoundTotalActiveStake.sub(transcoderTotalStake(_transcoder));
        uint256 deactivationRound = roundsManager().currentRound().add(1);
        transcoders[_transcoder].deactivationRound = deactivationRound;
        emit TranscoderDeactivated(_transcoder, deactivationRound);
    }










    function updateTranscoderWithRewards(
        address _transcoder,
        uint256 _rewards,
        uint256 _round,
        address _newPosPrev,
        address _newPosNext
    )
        internal
    {
        Transcoder storage t = transcoders[_transcoder];
        EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[_round];
        EarningsPool.Data storage prevEarningsPool = t.earningsPoolPerRound[t.lastRewardRound];

        t.activeCumulativeRewards = t.cumulativeRewards;

        uint256 transcoderCommissionRewards = MathUtils.percOf(_rewards, earningsPool.transcoderRewardCut);
        uint256 delegatorsRewards = _rewards.sub(transcoderCommissionRewards);

        uint256 transcoderRewardStakeRewards = MathUtils.percOf(delegatorsRewards, t.activeCumulativeRewards, earningsPool.totalStake);

        t.cumulativeRewards = t.cumulativeRewards.add(transcoderRewardStakeRewards).add(transcoderCommissionRewards);




        earningsPool.updateCumulativeRewardFactor(prevEarningsPool, delegatorsRewards);

        increaseTotalStake(_transcoder, _rewards, _newPosPrev, _newPosNext);
    }







    function updateDelegatorWithEarnings(address _delegator, uint256 _endRound, uint256 _lastClaimRound) internal {
        Delegator storage del = delegators[_delegator];
        uint256 startRound = _lastClaimRound.add(1);
        uint256 currentBondedAmount = del.bondedAmount;
        uint256 currentFees = del.fees;

        uint256 lip36Round = roundsManager().lipUpgradeRound(36);



        if (del.delegateAddress != address(0)) {
            if (startRound <= lip36Round) {





                uint256 endLoopRound = _endRound <= lip36Round ? _endRound : lip36Round;
                require(endLoopRound.sub(_lastClaimRound) <= maxEarningsClaimsRounds, "too many rounds to claim through");
            }

            (
                currentBondedAmount,
                currentFees
            ) = pendingStakeAndFees(_delegator, _endRound);




            Transcoder storage t = transcoders[del.delegateAddress];
            EarningsPool.Data storage endEarningsPool = t.earningsPoolPerRound[_endRound];
            if (endEarningsPool.cumulativeRewardFactor == 0) {
                endEarningsPool.cumulativeRewardFactor = t.earningsPoolPerRound[t.lastRewardRound].cumulativeRewardFactor;
            }
            if (endEarningsPool.cumulativeFeeFactor == 0) {
                endEarningsPool.cumulativeFeeFactor = t.earningsPoolPerRound[t.lastFeeRound].cumulativeFeeFactor;
            }

            if (del.delegateAddress == _delegator) {
                t.cumulativeFees = 0;
                t.cumulativeRewards = 0;

            }
        }

        emit EarningsClaimed(
            del.delegateAddress,
            _delegator,
            currentBondedAmount.sub(del.bondedAmount),
            currentFees.sub(del.fees),
            startRound,
            _endRound
        );

        del.lastClaimRound = _endRound;

        del.bondedAmount = currentBondedAmount;
        del.fees = currentFees;
    }









    function processRebond(address _delegator, uint256 _unbondingLockId, address _newPosPrev, address _newPosNext) internal {
        Delegator storage del = delegators[_delegator];
        UnbondingLock storage lock = del.unbondingLocks[_unbondingLockId];

        require(isValidUnbondingLock(_delegator, _unbondingLockId), "invalid unbonding lock ID");

        uint256 amount = lock.amount;

        del.bondedAmount = del.bondedAmount.add(amount);


        delete del.unbondingLocks[_unbondingLockId];

        increaseTotalStake(del.delegateAddress, amount, _newPosPrev, _newPosNext);

        emit Rebond(del.delegateAddress, _delegator, _unbondingLockId, amount);
    }





    function livepeerToken() internal view returns (ILivepeerToken) {
        return ILivepeerToken(controller.getContract(keccak256("LivepeerToken")));
    }





    function minter() internal view returns (IMinter) {
        return IMinter(controller.getContract(keccak256("Minter")));
    }





    function roundsManager() internal view returns (IRoundsManager) {
        return IRoundsManager(controller.getContract(keccak256("RoundsManager")));
    }
}
