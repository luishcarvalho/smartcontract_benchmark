
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "interfaces/notional/NotionalProxy.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";




contract NoteERC20 is Initializable {

    string public constant name = "Notional";


    string public constant symbol = "NOTE";


    uint8 public constant decimals = 8;


    uint256 public constant totalSupply = 100000000e8;


    NotionalProxy public notionalProxy;


    mapping(address => mapping(address => uint96)) internal allowances;


    mapping(address => uint96) internal balances;


    mapping(address => address) public delegates;


    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }


    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;


    mapping(address => uint32) public numCheckpoints;


    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");


    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");


    mapping(address => uint256) public nonces;


    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );


    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );


    event Transfer(address indexed from, address indexed to, uint256 amount);


    event Approval(address indexed owner, address indexed spender, uint256 amount);





    function initialize(
        address[] calldata initialAccounts,
        uint96[] calldata initialGrantAmount,
        NotionalProxy notionalProxy_
    ) public initializer {
        require(initialGrantAmount.length == initialAccounts.length);

        notionalProxy = notionalProxy_;
        uint96 totalGrants;
        for (uint256 i; i < initialGrantAmount.length; i++) {
            totalGrants = _add96(totalGrants, initialGrantAmount[i], "");
            balances[initialAccounts[i]] = initialGrantAmount[i];

            emit Transfer(address(0), initialAccounts[i], initialGrantAmount[i]);
        }

        require(totalGrants == totalSupply);
    }





    function allowance(address account, address spender) external view returns (uint256) {
        return allowances[account][spender];
    }








    function approve(address spender, uint256 rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = _safe96(rawAmount, "Note::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }




    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }






    function transfer(address dst, uint256 rawAmount) external returns (bool) {
        uint96 amount = _safe96(rawAmount, "Note::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }







    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = _safe96(rawAmount, "Note::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance =
                _sub96(
                    spenderAllowance,
                    amount,
                    "Note::transferFrom: transfer amount exceeds spender allowance"
                );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }




    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }









    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator =
            keccak256(
                abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), _getChainId(), address(this))
            );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Note::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Note::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "Note::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }




    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        uint96 currentVotes = nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        return
            _add96(
                currentVotes,
                getUnclaimedVotes(account),
                "Note::getCurrentVotes: uint96 overflow"
            );
    }






    function getPriorVotes(address account, uint256 blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "Note::getPriorVotes: not yet determined");

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

        return
            _add96(
                checkpoints[account][lower].votes,
                getUnclaimedVotes(account),
                "Note::getPriorVotes: uint96 overflow"
            );
    }





    function getUnclaimedVotes(address account) public view returns (uint96) {



        return 0;
    }


    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }


    function _transferTokens(
        address src,
        address dst,
        uint96 amount
    ) internal {
        require(src != address(0), "Note::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Note::_transferTokens: cannot transfer to the zero address");

        balances[src] = _sub96(
            balances[src],
            amount,
            "Note::_transferTokens: transfer amount exceeds balance"
        );
        balances[dst] = _add96(
            balances[dst],
            amount,
            "Note::_transferTokens: transfer amount overflows"
        );
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }


    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew =
                    _sub96(srcRepOld, amount, "Note::_moveVotes: vote amount underflow");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew =
                    _add96(dstRepOld, amount, "Note::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }







    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber =
            _safe32(block.number, "Note::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function _safe32(uint256 n, string memory errorMessage) private pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function _safe96(uint256 n, string memory errorMessage) private pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function _add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) private pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function _sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) private pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function _getChainId() private pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
