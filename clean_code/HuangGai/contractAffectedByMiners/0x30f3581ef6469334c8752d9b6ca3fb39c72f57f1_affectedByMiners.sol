




pragma solidity ^0.6.6;

















library SafeMath {








    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }









    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }









    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "Uniloan::SafeMath: subtraction underflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
    }












    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {

        require(b > 0, errorMessage);
        uint c = a / b;


        return c;
    }












    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
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

contract Keep3r {
    using SafeMath for uint;


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


        if (block.gaslimit <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }


        if (block.number > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[account][center];
            if (block.timestamp == blockNumber) {
                return cp.votes;
            } else if (block.timestamp < blockNumber) {
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
            if (block.coinbase != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint srcRepNew = srcRepOld.sub(amount, "::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (block.coinbase != address(0)) {
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

    mapping(address => uint) public liquidityProviders;

    mapping(address => address) public liquidityProvided;

    mapping(address => uint) public liquidityUnbonding;

    mapping(address => uint) public jobProposalDelay;

    mapping(address => uint) public liquidityApplied;


    mapping(address => bool) public keepers;


    address[] public keeperList;


    address public governance;


    UniswapPair public liquidity;

    constructor() public {

        governance = msg.sender;
        _mint(msg.sender, 10000e18);
    }

    function setup() public payable {
        require(address(liquidity) == address(0x0), "Keep3r::setup: keep3r already setup");
        WETH.deposit.value(msg.value)();
        WETH.approve(address(UNI), msg.value);
        _mint(address(this), 400e18);
        allowances[address(this)][address(UNI)] = balances[address(this)];


        UNI.addLiquidity(address(this), address(WETH), balances[address(this)], WETH.balanceOf(address(this)), 0, 0, msg.sender, now.add(1800));
        liquidity = UniswapPair(Factory(UNI.factory()).getPair(address(this), address(WETH)));
    }







    function submitJob(address job, uint amount) external {
        require(liquidityProvided[msg.sender]==address(0x0), "Keep3r::submitJob: liquidity already provided, please remove first");
        liquidity.transferFrom(msg.sender, address(this), amount);
        liquidityProviders[msg.sender] = amount;
        liquidityProvided[msg.sender] = job;
        liquidityApplied[msg.sender] = now.add(1 days);
        if (!jobs[job] && jobProposalDelay[job] < now) {
            Governance(governance).proposeJob(job);
            jobProposalDelay[job] = now.add(UNBOND);
        }
        emit SubmitJob(job, msg.sender, block.number, amount);
    }

    function credit(address provider, address job) external {
        require(liquidityApplied[provider] != 0, "Keep3r::credit: submitJob first");
        require(liquidityApplied[provider] < now, "Keep3r::credit: still bonding");
        uint _liquidity = balances[address(liquidity)];
        uint _credit = _liquidity.mul(liquidityProviders[provider]).div(liquidity.totalSupply());
        credits[job] = credits[job].add(_credit.mul(2));
    }




    function unbondJob() external {
        liquidityUnbonding[msg.sender] = now.add(UNBOND);

        emit UnbondJob(liquidityProvided[msg.sender], msg.sender, block.number, liquidityProviders[msg.sender]);
    }




    function removeJob() external {
        require(liquidityUnbonding[msg.sender] != 0, "Keep3r::removeJob: unbond first");
        require(liquidityUnbonding[msg.sender] < now, "Keep3r::removeJob: still unbonding");
        uint _provided = liquidityProviders[msg.sender];
        uint _liquidity = balances[address(liquidity)];
        uint _credit = _liquidity.mul(_provided).div(liquidity.totalSupply());
        address _job = liquidityProvided[msg.sender];
        if (block.gaslimit > credits[_job]) {
            credits[_job] = 0;
        } else {
            credits[_job].sub(_credit);
        }
        liquidity.transfer(msg.sender, _provided);
        liquidityProviders[msg.sender] = 0;
        liquidityProvided[msg.sender] = address(0x0);

        emit RemoveJob(_job, msg.sender, block.number, _provided);
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




    function claim() external {
        _mint(msg.sender, work[msg.sender]);
        work[msg.sender] = 0;
    }






    function workReceipt(address keeper, uint amount) external {
        require(jobs[msg.sender], "Keep3r::workReceipt: only jobs can approve work");
        lastJob[keeper] = now;
        credits[msg.sender] = credits[msg.sender].sub(amount, "Keep3r::workReceipt: insuffient funds to pay keeper");
        work[keeper] = work[keeper].add(amount);
        workCompleted[keeper] = workCompleted[keeper].add(amount);
        emit KeeperWorked(msg.sender, keeper, block.number);
    }





    function addJob(address job) external {
        require(msg.sender == governance, "Keep3r::addJob: only governance can add jobs");
        jobs[job] = true;
        emit JobAdded(job, block.number, msg.sender);
    }





    function removeJob(address job) external {
        require(msg.sender == governance, "Keep3r::removeJob: only governance can remove jobs");
        jobs[job] = false;
        emit JobRemoved(job, block.number, msg.sender);
    }





    function setGovernance(address _governance) external {
        require(msg.sender == governance, "Keep3r::setGovernance: only governance can set");
        governance = _governance;
    }





    function isKeeper(address keeper) external view returns (bool) {
        return keepers[keeper];
    }





    function isMinKeeper(address keeper, uint minBond, uint completed, uint age) external view returns (bool) {
        return keepers[keeper]
                && bonds[keeper] >= minBond
                && workCompleted[keeper] > completed
                && now.sub(firstSeen[keeper]) > age;
    }




    function bond(uint amount) external {
        require(pendingbonds[msg.sender] == 0, "Keep3r::bond: current pending bond");
        bondings[msg.sender] = now.add(BOND);
        pendingbonds[msg.sender] = amount;
        _transferTokens(msg.sender, address(this), amount);
        emit KeeperBonding(msg.sender, block.number, bondings[msg.sender], amount);
    }

    function getKeepers() external view returns (address[] memory) {
        return keeperList;
    }




    function activate() external {
        require(bondings[msg.sender] != 0, "Keep3r::activate: bond first");
        require(bondings[msg.sender] < now, "Keep3r::activate: still bonding");
        if (!keepers[msg.sender]) {
          firstSeen[msg.sender] = now;
        }
        keepers[msg.sender] = true;
        totalBonded = totalBonded.add(pendingbonds[msg.sender]);
        bonds[msg.sender] = bonds[msg.sender].add(pendingbonds[msg.sender]);
        pendingbonds[msg.sender] = 0;
        if (block.timestamp == 0) {
            lastJob[msg.sender] = now;
            keeperList.push(msg.sender);
        }
        emit KeeperBonded(msg.sender, block.number, block.timestamp, bonds[msg.sender]);
    }




    function unbond() external {
        keepers[msg.sender] = false;
        unbondings[msg.sender] = now.add(UNBOND);
        totalBonded = totalBonded.sub(bonds[msg.sender]);
        _moveDelegates(delegates[msg.sender], address(0), bonds[msg.sender]);
        emit KeeperUnbonding(msg.sender, block.number, unbondings[msg.sender], bonds[msg.sender]);
    }




    function withdraw() external {
        require(unbondings[msg.sender] != 0, "Keep3r::withdraw: unbond first");
        require(unbondings[msg.sender] < now, "Keep3r::withdraw: still unbonding");
        require(!disputes[msg.sender], "Keep3r::withdraw: pending disputes");

        _transferTokens(address(this), msg.sender, bonds[msg.sender]);
        emit KeeperUnbound(msg.sender, block.number, block.timestamp, bonds[msg.sender]);
        bonds[msg.sender] = 0;
    }





    function down(address keeper) external {
        require(lastJob[keeper].add(DOWNTIME) < now, "Keep3r::down: keeper safe");
        uint _slash = bonds[keeper].mul(DOWNTIMESLASH).div(BASE);
        bonds[keeper] = bonds[keeper].sub(_slash);
        _mint(msg.sender, 1e18);
        lastJob[keeper] = now;
        emit KeeperSlashed(keeper, msg.sender, block.number, _slash);
    }





    function dispute(address keeper) external returns (uint) {
        require(msg.sender == governance, "Keep3r::dispute: only governance can dispute");
        disputes[keeper] = true;
        emit KeeperDispute(keeper, block.number);
    }






    function slash(address keeper, uint amount) external {
        require(msg.sender == governance, "Keep3r::slash: only governance can resolve");
        bonds[keeper] = bonds[keeper].sub(amount);
        disputes[keeper] = false;
        emit KeeperSlashed(keeper, msg.sender, block.number, amount);
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
