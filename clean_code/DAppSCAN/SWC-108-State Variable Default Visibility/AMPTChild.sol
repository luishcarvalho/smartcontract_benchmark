
pragma solidity 0.8.4;

contract AMPTChild {


    string public constant name = "Amplify Token";


    string public constant symbol = "AMPT";


    uint8 public constant decimals = 18;


    uint256 public totalSupply;


    mapping (address => mapping (address => uint256)) internal allowances;


    mapping (address => uint256) internal balances;


    mapping (address => address) public delegates;


    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }


    address public childChainManagerProxy;
    address deployer;


    mapping (address => mapping (uint256 => Checkpoint)) public checkpoints;


    mapping (address => uint256) public numCheckpoints;


    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");


    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");


    mapping (address => uint256) public nonces;


    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);


    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);


    event Transfer(address indexed from, address indexed to, uint256 amount);


    event Approval(address indexed owner, address indexed spender, uint256 amount);


    uint256 internal constant MAX_UINT256 = 2**256 - 1;





    constructor(address _childChainManagerProxy) {
        require(_childChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        childChainManagerProxy = _childChainManagerProxy;
        deployer = msg.sender;
    }



    function updateChildChainManager(address newChildChainManagerProxy) external {
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        require(msg.sender == deployer, "You're not allowed");

        childChainManagerProxy = newChildChainManagerProxy;
    }









    function deposit(address user, bytes calldata depositData) external {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");
        require(user != address(0), "AMPT::deposit: cannot transfer from the zero address");

        uint256 amount = abi.decode(depositData, (uint256));


        totalSupply +=  amount;
        balances[user] += amount;

        emit Transfer(address(0), user, amount);
    }











    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        balances[msg.sender] = safeSub(balances[msg.sender], amount, "ERC20: burn amount exceeds balance");
        totalSupply = safeSub(totalSupply, amount, "AMPT::withdraw: update total suply failed");

        emit Transfer(msg.sender, address(0), amount);
    }







    function allowance(address account, address spender) external view returns (uint256) {
        return allowances[account][spender];
    }







    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender] + addedValue);
        return true;
    }














    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }






    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }







    function transfer(address dst, uint256 rawAmount) external returns (bool) {
        _transferTokens(msg.sender, dst, rawAmount);
        return true;
    }








    function transferFrom(address src, address dst, uint256 rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != MAX_UINT256) {
            require(spenderAllowance >= rawAmount, "AMPT::transferFrom: transfer amount exceeds spender allowance");
            uint256 newAllowance = spenderAllowance - rawAmount;
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, rawAmount);
        return true;
    }





    function delegate(address delegatee) external {
        _delegate(msg.sender, delegatee);
    }










    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "AMPT::delegateBySig: invalid signature");
        require(nonce == nonces[signatory], "AMPT::delegateBySig: invalid nonce");
        nonces[signatory]++;
        require(getBlockTimestamp() <= expiry, "AMPT::delegateBySig: signature expired");
        _delegate(signatory, delegatee);
    }






    function getCurrentVotes(address account) external view returns (uint256) {
        uint256 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }








    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
        uint256 currentBlockNumber = getBlockNumber();
        require(currentBlockNumber > blockNumber, "AMPT::getPriorVotes: not yet determined");

        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }


        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }


        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2;
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
        uint256 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint256 amount) internal {
        require(src != address(0), "AMPT::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "AMPT::_transferTokens: cannot transfer to the zero address");

        balances[src] -= safeSub(balances[src], amount, "AMPT::_transferTokens: transfer amount exceeds balance");
        balances[dst] += amount;
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = safeSub(srcRepOld, amount, "AMPT::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint256 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
      uint256 currentBlockNumber = getBlockNumber();

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == currentBlockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(currentBlockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function getBlockNumber() public virtual view returns (uint256) {
        return block.number;
    }

    function getBlockTimestamp() public virtual view returns (uint256) {
        return block.timestamp;
    }

    function safeSub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
