




pragma solidity ^0.6.6;

















library SafeMath {








    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "Keep3r::SafeMath: addition overflow");

        return c;
    }









    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }









    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "Keep3r::SafeMath: subtraction underflow");
    }









    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }









    function mul(uint a, uint b) internal pure returns (uint) {



        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "Keep3r::SafeMath: multiplication overflow");

        return c;
    }









    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {



        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }












    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "Keep3r::SafeMath: division by zero");
    }












    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {

        require(b > 0, errorMessage);
        uint c = a / b;


        return c;
    }












    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "Keep3r::SafeMath: modulo by zero");
    }












    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface Governance {
    function proposeJob(address job) external returns (uint);
}

interface WETH9 {
    function deposit() external payable;
    function balanceOf(address account) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
}

interface Uniswap {
    function factory() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface UniswapPair {
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function totalSupply() external view returns (uint);
}

interface Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface Keep3rHelper {
    function getQuoteLimit(uint gasUsed) external view returns (uint);
}

contract Keep3r {
    using SafeMath for uint;


    Keep3rHelper public KPRH;


    WETH9 public constant WETH = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);


    Uniswap public constant UNI = Uniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);


    string public constant name = "Keep3r";


    string public constant symbol = "KPR";


    uint8 public constant decimals = 18;


    uint public totalSupply = 0;


    mapping (address => address) public delegates;


    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;


    mapping (address => uint32) public numCheckpoints;

    mapping (address => mapping (address => uint)) internal allowances;
    mapping (address => uint) internal balances;


    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");


    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint nonce,uint expiry)");


    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");



    mapping (address => uint) public nonces;


    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);


    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);


    struct Checkpoint {
        uint32 fromBlock;
        uint votes;
    }





    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }










    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "::delegateBySig: invalid nonce");
        require(now <= expiry, "::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }






    function getCurrentVotes(address account) external view returns (uint) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }








    function getPriorVotes(address account, uint blockNumber) public view returns (uint) {
        require(blockNumber < block.number, "::getPriorVotes: not yet determined");

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

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint delegatorBalance = bonds[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint srcRepNew = srcRepOld.sub(amount, "::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint oldVotes, uint newVotes) internal {
      uint32 blockNumber = safe32(block.number, "::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }


    event Transfer(address indexed from, address indexed to, uint amount);


    event Approval(address indexed owner, address indexed spender, uint amount);


    event SubmitJob(address indexed job, address indexed provider, uint block, uint credit);


    event ApplyCredit(address indexed job, address indexed provider, uint block, uint credit);


    event RemoveJob(address indexed job, address indexed provider, uint block, uint credit);


    event UnbondJob(address indexed job, address indexed provider, uint block, uint credit);


    event JobAdded(address indexed job, uint block, address governance);


    event JobRemoved(address indexed job, uint block, address governance);


    event KeeperWorked(address indexed job, address indexed keeper, uint block);


    event KeeperBonding(address indexed keeper, uint block, uint active, uint bond);


    event KeeperBonded(address indexed keeper, uint block, uint activated, uint bond);


    event KeeperUnbonding(address indexed keeper, uint block, uint deactive, uint bond);


    event KeeperUnbound(address indexed keeper, uint block, uint deactivated, uint bond);


    event KeeperSlashed(address indexed keeper, address indexed slasher, uint block, uint slash);


    event KeeperDispute(address indexed keeper, uint block);


    event KeeperResolved(address indexed keeper, uint block);


    uint constant public BOND = 3 days;

    uint constant public UNBOND = 14 days;

    uint constant public DOWNTIME = 7 days;


    uint constant public DOWNTIMESLASH = 500;
    uint constant public BASE = 10000;


    mapping(address => uint) public bondings;

    mapping(address => uint) public unbondings;

    mapping(address => uint) public partialUnbonding;

    mapping(address => uint) public pendingbonds;

    mapping(address => uint) public bonds;


    uint public totalBonded = 0;

    mapping(address => uint) public firstSeen;


    mapping(address => bool) public disputes;


    mapping(address => uint) public lastJob;

    mapping(address => uint) public work;

    mapping(address => uint) public workCompleted;

    mapping(address => bool) public jobs;

    mapping(address => uint) public credits;

    mapping(address => mapping(address => mapping(address => uint))) public liquidityProvided;

    mapping(address => mapping(address => mapping(address => uint))) public liquidityUnbonding;

    mapping(address => mapping(address => mapping(address => uint))) public liquidityAmountsUnbonding;

    mapping(address => uint) public jobProposalDelay;

    mapping(address => mapping(address => mapping(address => uint))) public liquidityApplied;

    mapping(address => mapping(address => mapping(address => uint))) public liquidityAmount;


    mapping(address => bool) public keepers;

    mapping(address => bool) public blacklist;


    address[] public keeperList;

    address[] public jobList;


    address public governance;
    address public pendingGovernance;


    mapping(address => bool) public liquidityAccepted;

    address[] public liquidityPairs;

    uint internal gasUsed;

    constructor() public {

        governance = msg.sender;
        _mint(msg.sender, 10000e18);
    }






    function approveLiquidity(address liquidity) external {
        require(msg.sender == governance, "Keep3r::approveLiquidity: governance only");
        liquidityAccepted[liquidity] = true;
        liquidityPairs.push(liquidity);
    }





    function revokeLiquidity(address liquidity) external {
        require(msg.sender == governance, "Keep3r::revokeLiquidity: governance only");
        liquidityAccepted[liquidity] = false;
    }




    function pairs() external view returns (address[] memory) {
        return liquidityPairs;
    }







    function addLiquidityToJob(address liquidity, address job, uint amount) external {
        require(liquidityAccepted[liquidity], "Keep3r::addLiquidityToJob: asset not accepted as liquidity");
        UniswapPair(liquidity).transferFrom(msg.sender, address(this), amount);
        liquidityProvided[msg.sender][liquidity][job] = liquidityProvided[msg.sender][liquidity][job].add(amount);

        liquidityApplied[msg.sender][liquidity][job] = now.add(2 days);
        liquidityAmount[msg.sender][liquidity][job] = liquidityAmount[msg.sender][liquidity][job].add(amount);

        if (!jobs[job] && jobProposalDelay[job] < now) {
            Governance(governance).proposeJob(job);
            jobProposalDelay[job] = now.add(UNBOND);
        }
        emit SubmitJob(job, msg.sender, block.number, amount);
    }







    function applyCreditToJob(address provider, address liquidity, address job) external {
        require(liquidityAccepted[liquidity], "Keep3r::addLiquidityToJob: asset not accepted as liquidity");
        require(liquidityApplied[provider][liquidity][job] != 0, "Keep3r::credit: submitJob first");
        require(liquidityApplied[provider][liquidity][job] < now, "Keep3r::credit: still bonding");
        uint _liquidity = balances[address(liquidity)];
        uint _credit = _liquidity.mul(liquidityAmount[msg.sender][liquidity][job]).div(UniswapPair(liquidity).totalSupply());
        credits[job] = credits[job].add(_credit);
        liquidityAmount[msg.sender][liquidity][job] = 0;

        emit ApplyCredit(job, msg.sender, block.number, _credit);
    }







    function unbondLiquidityFromJob(address liquidity, address job, uint amount) external {
        require(address(this).balance == 0, "Keep3r::credit: pending credit, settle first");
        liquidityUnbonding[msg.sender][liquidity][job] = now.add(UNBOND);
        liquidityAmountsUnbonding[msg.sender][liquidity][job] = liquidityAmountsUnbonding[msg.sender][liquidity][job].add(amount);
        require(liquidityAmountsUnbonding[msg.sender][liquidity][job] <= liquidityProvided[msg.sender][liquidity][job], "Keep3r::unbondLiquidityFromJob: insufficient funds");

        uint _liquidity = balances[address(liquidity)];
        uint _credit = _liquidity.mul(amount).div(UniswapPair(liquidity).totalSupply());
        if (_credit > credits[job]) {
            credits[job] = 0;
        } else {
            credits[job].sub(_credit);
        }

        emit UnbondJob(job, msg.sender, block.number, liquidityProvided[msg.sender][liquidity][job]);
    }






    function removeLiquidityFromJob(address liquidity, address job) external {
        require(liquidityUnbonding[msg.sender][liquidity][job] != 0, "Keep3r::removeJob: unbond first");
        require(liquidityUnbonding[msg.sender][liquidity][job] < now, "Keep3r::removeJob: still unbonding");
        uint _amount = liquidityAmountsUnbonding[msg.sender][liquidity][job];
        UniswapPair(liquidity).transfer(msg.sender, _amount);
        liquidityAmountsUnbonding[msg.sender][liquidity][job] = 0;
        liquidityProvided[msg.sender][liquidity][job] = liquidityProvided[msg.sender][liquidity][job].sub(_amount);

        emit RemoveJob(job, msg.sender, block.number, _amount);
    }





    function mint(uint amount) external {
        require(msg.sender == governance, "Keep3r::mint: governance only");
        _mint(governance, amount);
    }





    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }

    function _mint(address dst, uint amount) internal {

        totalSupply = totalSupply.add(amount);

        balances[dst] = balances[dst].add(amount);
        emit Transfer(address(0), dst, amount);
    }

    function _burn(address dst, uint amount) internal {
        require(dst != address(0), "::_burn: burn from the zero address");
        balances[dst] = balances[dst].sub(amount, "::_burn: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        emit Transfer(dst, address(0), amount);
    }






    function workReceipt(address keeper, uint amount) external {
        require(jobs[msg.sender], "Keep3r::workReceipt: only jobs can approve work");
        gasUsed = gasUsed.sub(gasleft());
        require(amount < KPRH.getQuoteLimit(gasUsed), "Keep3r::workReceipt: spending over max limit");
        credits[msg.sender] = credits[msg.sender].sub(amount, "Keep3r::workReceipt: insuffient funds to pay keeper");
        lastJob[keeper] = now;
        _mint(address(this), amount);
        bonds[keeper] = bonds[keeper].add(amount);
        totalBonded = totalBonded.add(amount);
        _moveDelegates(address(0), delegates[keeper], amount);
        workCompleted[keeper] = workCompleted[keeper].add(amount);
        emit KeeperWorked(msg.sender, keeper, block.number);
    }





    function addJob(address job) external {
        require(msg.sender == governance, "Keep3r::addJob: only governance can add jobs");
        jobs[job] = true;
        jobList.push(job);
        emit JobAdded(job, block.number, msg.sender);
    }





    function getJobs() external view returns (address[] memory) {
        return jobList;
    }





    function removeJob(address job) external {
        require(msg.sender == governance, "Keep3r::removeJob: only governance can remove jobs");
        jobs[job] = false;
        emit JobRemoved(job, block.number, msg.sender);
    }





    function setKeep3rHelper(Keep3rHelper _kprh) external {
        require(msg.sender == governance, "Keep3r::setKeep3rHelper: only governance can set");
        KPRH = _kprh;
    }





    function setGovernance(address _governance) external {
        require(msg.sender == governance, "Keep3r::setGovernance: only governance can set");
        pendingGovernance = _governance;
    }




    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "Keep3r::acceptGovernance: only pendingGovernance can accept");
        governance = pendingGovernance;
    }





    function isKeeper(address keeper) public returns (bool) {
        gasUsed = gasleft();
        return keepers[keeper];
    }





    function isMinKeeper(address keeper, uint minBond, uint completed, uint age) external returns (bool) {
        gasUsed = gasleft();
        return keepers[keeper]
                && bonds[keeper] >= minBond
                && workCompleted[keeper] > completed
                && now.sub(firstSeen[keeper]) > age;
    }




    function bond(uint amount) external {
        require(address(this).balance == 0, "Keep3r::bond: current pending bond");
        require(!blacklist[msg.sender], "Keep3r::bond: keeper is blacklisted");
        bondings[msg.sender] = now.add(BOND);
        _transferTokens(msg.sender, address(this), amount);
        pendingbonds[msg.sender] = pendingbonds[msg.sender].add(amount);
        emit KeeperBonding(msg.sender, block.number, bondings[msg.sender], amount);
    }

    function getKeepers() external view returns (address[] memory) {
        return keeperList;
    }




    function activate() external {
        require(bondings[msg.sender] != 0, "Keep3r::activate: bond first");
        require(bondings[msg.sender] < now, "Keep3r::activate: still bonding");
        if (address(this).balance == 0) {
          firstSeen[msg.sender] = now;
          keeperList.push(msg.sender);
          lastJob[msg.sender] = now;
        }
        keepers[msg.sender] = true;
        totalBonded = totalBonded.add(pendingbonds[msg.sender]);
        bonds[msg.sender] = bonds[msg.sender].add(pendingbonds[msg.sender]);
        pendingbonds[msg.sender] = 0;
        emit KeeperBonded(msg.sender, block.number, block.timestamp, bonds[msg.sender]);
    }




    function deactivate() external {
        keepers[msg.sender] = false;
    }





    function unbond(uint amount) external {
        unbondings[msg.sender] = now.add(UNBOND);
        bonds[msg.sender] = bonds[msg.sender].sub(amount);
        totalBonded = totalBonded.sub(amount);
        partialUnbonding[msg.sender] = partialUnbonding[msg.sender].add(amount);
        _moveDelegates(delegates[msg.sender], address(0), amount);
        emit KeeperUnbonding(msg.sender, block.number, unbondings[msg.sender], amount);
    }




    function withdraw() external {
        require(unbondings[msg.sender] != 0, "Keep3r::withdraw: unbond first");
        require(unbondings[msg.sender] < now, "Keep3r::withdraw: still unbonding");
        require(!disputes[msg.sender], "Keep3r::withdraw: pending disputes");

        _transferTokens(address(this), msg.sender, partialUnbonding[msg.sender]);
        emit KeeperUnbound(msg.sender, block.number, block.timestamp, partialUnbonding[msg.sender]);
        partialUnbonding[msg.sender] = 0;
    }





    function down(address keeper) external {
        require(isKeeper(msg.sender), "Keep3r::down: not a keeper");
        require(keepers[keeper], "Keep3r::down: keeper not registered");
        require(lastJob[keeper].add(DOWNTIME) < now, "Keep3r::down: keeper safe");
        uint _slash = bonds[keeper].mul(DOWNTIMESLASH).div(BASE);
        bonds[keeper] = bonds[keeper].sub(_slash);
        bonds[msg.sender] = bonds[msg.sender].add(_slash);
        _moveDelegates(delegates[msg.sender], msg.sender, _slash);
        lastJob[keeper] = now;
        lastJob[msg.sender] = now;
        emit KeeperSlashed(keeper, msg.sender, block.number, _slash);
    }





    function dispute(address keeper) external returns (uint) {
        require(msg.sender == governance, "Keep3r::dispute: only governance can dispute");
        disputes[keeper] = true;
        emit KeeperDispute(keeper, block.number);
    }






    function slash(address keeper, uint amount) public {
        require(msg.sender == governance, "Keep3r::slash: only governance can resolve");
        _transferTokens(address(this), governance, amount);
        _moveDelegates(delegates[msg.sender], address(0), amount);
        bonds[keeper] = bonds[keeper].sub(amount);
        totalBonded = totalBonded.sub(amount);
        disputes[keeper] = false;
        emit KeeperSlashed(keeper, msg.sender, block.number, amount);
    }





    function revoke(address keeper) external {
        require(msg.sender == governance, "Keep3r::slash: only governance can resolve");
        keepers[keeper] = false;
        blacklist[keeper] = true;
        slash(keeper, bonds[keeper]);
    }





    function resolve(address keeper) external {
        require(msg.sender == governance, "Keep3r::resolve: only governance can resolve");
        disputes[keeper] = false;
        emit KeeperResolved(keeper, block.number);
    }







    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }









    function approve(address spender, uint amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }











    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "::permit: invalid signature");
        require(signatory == owner, "::permit: unauthorized");
        require(now <= deadline, "::permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }






    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }







    function transfer(address dst, uint amount) public returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }








    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint(-1)) {
            uint newAllowance = spenderAllowance.sub(amount, "::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        require(src != address(0), "::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "::_transferTokens: cannot transfer to the zero address");

        balances[src] = balances[src].sub(amount, "::_transferTokens: transfer amount exceeds balance");
        balances[dst] = balances[dst].add(amount, "::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
