



pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

abstract contract Token {

    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);

    function balanceOf(address account) external virtual view returns (uint);

}

contract BNSG {

    string public constant name = "BNS Governance";


    string public constant symbol = "BNSG";

    address public bnsdAdd;
    address public bnsAdd;
    address public admin;

    uint96 public bnsToBNSG;
    uint96 public bnsdToBNSG;





    uint8 public constant decimals = 18;


    uint96 public constant maxTotalSupply = 10000000e18;

    uint96 public totalSupply;


    mapping (address => mapping (address => uint96)) internal allowances;


    mapping (address => uint96) internal balances;


    mapping (address => address) public delegates;


    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }


    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;


    mapping (address => uint32) public numCheckpoints;


    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");


    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");


    mapping (address => uint) public nonces;

    bool public rateSet;


    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);


    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);


    event Transfer(address indexed from, address indexed to, uint256 amount);


    event Approval(address indexed owner, address indexed spender, uint256 amount);


    constructor() public {
        admin = msg.sender;
    }

    modifier _adminOnly() {
        require(msg.sender == admin);
        _;
    }





    function setAddresses(address _bns, address _bnsd) external _adminOnly returns (bool) {
        bnsAdd = _bns;
        bnsdAdd = _bnsd;
        return true;
    }




    function setTokenRates(uint96 _bnsRate, uint96 _bnsdRate) external _adminOnly returns (bool) {
        bnsToBNSG = _bnsRate;
        bnsdToBNSG = _bnsdRate;
        if(!rateSet){
            rateSet = true;
        }
        return true;
    }






    function mintBNSGWithBNS(uint96 amountToMint) external returns (bool) {
        require(rateSet, "BNSG::mint: rate not yet set");
        require(amountToMint >= 1e18, "BNSG::mint: min mint amount 1");
        uint96 _bnsNeeded = mul96(div96(amountToMint, 1e18, "BNSG::mint: div failed"),bnsToBNSG, "BNSG::mint: mul failed");
        require(Token(bnsAdd).balanceOf(msg.sender) >= _bnsNeeded, "BNSG::mint: insufficient BNS");
        require(Token(bnsAdd).transferFrom(msg.sender, address(1), _bnsNeeded), "BNSG::mint: burn BNS failed");
        _mint(msg.sender, amountToMint);
        _moveDelegates(address(0), msg.sender, amountToMint);
        return true;
    }






    function mintBNSGWithBNSD(uint96 amountToMint) external returns (bool) {
        require(rateSet, "BNSG::mint: rate not yet set");
        require(amountToMint >= 1e18, "BNSG::mint: min mint amount 1");
        uint96 _bnsdNeeded = mul96(div96(amountToMint, 1e18, "BNSG::mint: div failed"),bnsdToBNSG, "BNSG::mint: mul failed");
        require(Token(bnsdAdd).balanceOf(msg.sender) >= _bnsdNeeded, "BNSG::mint: insufficient BNSD");
        require(Token(bnsdAdd).transferFrom(msg.sender, address(1), _bnsdNeeded), "BNSG::mint: burn BNSD failed");
        _mint(msg.sender, amountToMint);
        _moveDelegates(address(0), msg.sender, amountToMint);
        return true;
    }


    function _mint(address account, uint96 amount) internal virtual {
        require(account != address(0), "BNSG: mint to the zero address");
        totalSupply =  add96(totalSupply, amount, "BNSG: mint amount overflow");
        require(totalSupply <= maxTotalSupply, "BNSG: crosses total supply possible");
        balances[account] = add96(balances[account], amount, "BNSG::_mint: transfer amount overflows");
        emit Transfer(address(0), account, amount);
    }








    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }









    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (block.timestamp == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "BNSG::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }






    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }







    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "BNSG::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }








    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "BNSG::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "BNSG::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }





    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }










    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "BNSG::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "BNSG::delegateBySig: invalid nonce");
        require(now <= expiry, "BNSG::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }






    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }








    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "BNSG::getPriorVotes: not yet determined");

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
            if (block.number == blockNumber) {
                return cp.votes;
            } else if (block.gaslimit < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "BNSG::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "BNSG::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "BNSG::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "BNSG::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (block.coinbase != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "BNSG::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (block.coinbase != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "BNSG::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "BNSG::_writeCheckpoint: block number exceeds 32 bits");

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

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b != 0, errorMessage);
        uint96 c = a / b;
        return c;
    }

    function mul96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        if (a == 0) {
            return 0;
        }
        uint96 c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
