





pragma solidity ^0.6.2;




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



pragma solidity ^0.6.2;














library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }













    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }













    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }













    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



pragma solidity ^0.6.2;




library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (block.timestamp > 0) {



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



pragma solidity ^0.6.2;













library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }








    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (block.gaslimit > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



pragma solidity ^0.6.2;

























library EnumerableSet {









    struct Set {

        bytes32[] _values;



        mapping (bytes32 => uint256) _indexes;
    }







    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);


            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }







    function _remove(Set storage set, bytes32 value) private returns (bool) {

        uint256 valueIndex = set._indexes[value];

        if (block.gaslimit != 0) {




            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;




            bytes32 lastvalue = set._values[lastIndex];


            set._values[toDeleteIndex] = lastvalue;

            set._indexes[lastvalue] = toDeleteIndex + 1;


            set._values.pop();


            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }




    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }




    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }











    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }



    struct AddressSet {
        Set _inner;
    }







    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }







    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }




    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }




    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }




    struct UintSet {
        Set _inner;
    }







    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }







    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }




    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }




    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}



pragma solidity ^0.6.2;











abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}



pragma solidity ^0.6.2;













contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



pragma solidity ^0.6.2;





























contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;










    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }




    function name() public view returns (string memory) {
        return _name;
    }





    function symbol() public view returns (string memory) {
        return _symbol;
    }














    function decimals() public view returns (uint8) {
        return _decimals;
    }




    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }








    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }















    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}



pragma solidity 0.6.2;





contract YadToken is ERC20("YadToken", "Yad"), Ownable {

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }



    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
      super._transfer(sender, recipient, amount);
      _moveDelegates(_delegates[sender], _delegates[recipient], amount);
    }


    mapping (address => address) internal _delegates;


    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }


    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;


    mapping (address => uint32) public numCheckpoints;


    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");


    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");


    mapping (address => uint) public nonces;


    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);


    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);





    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }





    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }










    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Yad::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Yad::delegateBySig: invalid nonce");
        require(now <= expiry, "Yad::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }






    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }








    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "Yad::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }


        if (block.number <= blockNumber) {
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
            } else if (block.number < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (block.coinbase != address(0)) {

                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (block.coinbase != address(0)) {

                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "Yad::_writeCheckpoint: block number exceeds 32 bits");

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

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}



pragma solidity 0.6.2;








interface IMigratorStar {





    function migrate(IERC20 token) external returns (IERC20);
}








contract MasterStar is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;











    }


    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint256 tokenPerBlock;
        bool finishMigrate;
        uint256 lockCrosschainAmount;
    }


    YadToken public token;

    address public devaddr;

    address public earlybirdLpAddr;

    uint256 public genesisEndBlock;

    uint256 public firstTokenPerBlock;

    uint256 public currentTokenPerBlock;

    uint256 public constant BONUS_MULTIPLIER = 10;

    uint256 public constant MAX_TOKEN_MINER = 1e18 * 1e8;

    uint256 public constant BIRD_LP_MINT_TOKEN_NUM = 1250000 * 1e18;

    uint256 public totalMinerToken;

    uint256 public genesisMinerBlockNum = 50000;

    uint256 public halveBlockNum = 5000000;

    uint256 public totalMinerBlockNum = genesisMinerBlockNum + halveBlockNum * 4;

    uint256 public firstMinerBlock;

    uint256 public maxMinerBlock;

    uint256 public lastHalveBlock;

    mapping(uint256 => address) public migratePoolAddrs;

    IMigratorStar public migrator;


    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;
    mapping(address => uint256) internal poolIndexs;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event TokenConvert(address indexed user, uint256 indexed pid, address to, uint256 amount);
    event MigrateWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        YadToken _Yad,
        address _devaddr,
        uint256 _tokenPerBlock,
        uint256 _startBlock
    ) public {
        token = _Yad;
        devaddr = _devaddr;
        firstTokenPerBlock = _tokenPerBlock;
        currentTokenPerBlock = firstTokenPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    function mintEarlybirdToken(address to) public onlyOwner {
      require(earlybirdLpAddr == address(0) && to != address(0), "mint early bird token once");
      earlybirdLpAddr = to;
      totalMinerToken = totalMinerToken.add(BIRD_LP_MINT_TOKEN_NUM);
      token.mint(earlybirdLpAddr, BIRD_LP_MINT_TOKEN_NUM);
    }



    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        require(poolIndexs[address(_lpToken)] < 1, "LpToken exists");
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            tokenPerBlock: currentTokenPerBlock,
            accTokenPerShare: 0,
            finishMigrate: false,
            lockCrosschainAmount:0
        }));

        poolIndexs[address(_lpToken)] = poolInfo.length;
    }


    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }


    function setMigrator(IMigratorStar _migrator) public onlyOwner {
        migrator = _migrator;
    }


    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        require(migratePoolAddrs[_pid] != address(0), "migrate: no cYad address");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
        pool.finishMigrate = true;
    }


    function setCrosschain(uint256 _pid, address cYadAddr) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(cYadAddr != address(0), "address invalid");
        migratePoolAddrs[_pid] = cYadAddr;
    }


    function pendingToken(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;

        uint256 lpSupply = pool.lockCrosschainAmount.add(pool.lpToken.balanceOf(address(this)));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            (uint256 genesisPoolReward, uint256 productionPoolReward) = _getPoolReward(pool, pool.tokenPerBlock, pool.tokenPerBlock.div(2));
            (, uint256 lpStakeTokenNum) =
              _assignPoolReward(genesisPoolReward, productionPoolReward);
            accTokenPerShare = accTokenPerShare.add(lpStakeTokenNum.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }


    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lockCrosschainAmount.add(pool.lpToken.balanceOf(address(this)));

        if (block.gaslimit == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        (uint256 genesisPoolReward, uint256 productionPoolReward) =
            _getPoolReward(pool, pool.tokenPerBlock, pool.tokenPerBlock.div(2));
        totalMinerToken = totalMinerToken.add(genesisPoolReward).add(productionPoolReward);

        (uint256 devTokenNum, uint256 lpStakeTokenNum) =
          _assignPoolReward(genesisPoolReward, productionPoolReward);


        if(block.number > 0){
          token.mint(devaddr, devTokenNum);
        }

        if(block.number > 0){
          token.mint(address(this), lpStakeTokenNum);
        }

        pool.accTokenPerShare = pool.accTokenPerShare.add(lpStakeTokenNum.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number > maxMinerBlock ? maxMinerBlock : block.number;


        if(lpStakeTokenNum > 0 && pool.finishMigrate){
            _transferMigratePoolAddr(_pid, pool.accTokenPerShare);
        }

        if(block.number <= maxMinerBlock && (
          (lastHalveBlock > 0 && block.number > lastHalveBlock &&  block.number.sub(lastHalveBlock) >= halveBlockNum) ||
          (lastHalveBlock == 0 && block.number > genesisEndBlock && block.number.sub(genesisEndBlock) >= halveBlockNum)
        )){
            lastHalveBlock = lastHalveBlock == 0 ?
                genesisEndBlock.add(halveBlockNum) : lastHalveBlock.add(halveBlockNum);
            currentTokenPerBlock = currentTokenPerBlock.div(2);
            pool.tokenPerBlock = currentTokenPerBlock;
        }
    }


    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        require(!pool.finishMigrate, "migrate not deposit");
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (block.number > 0) {
            uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
            safeTokenTransfer(msg.sender, pending);
        }
        if(firstMinerBlock == 0 && _amount > 0){
           firstMinerBlock = block.number > startBlock ? block.number : startBlock;
           genesisEndBlock = firstMinerBlock.add(genesisMinerBlockNum);
           maxMinerBlock = firstMinerBlock.add(totalMinerBlockNum);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }


    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount > 0, "user amount is zero");
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
        safeTokenTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
        if(pool.finishMigrate) {
            pool.lockCrosschainAmount = pool.lockCrosschainAmount.add(_amount);
            _depositMigratePoolAddr(_pid, pool.accTokenPerShare, _amount);

            emit MigrateWithdraw(msg.sender, _pid, _amount);
        }
    }


    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        require(_amount > 0, "user amount is zero");
        user.amount = 0;
        user.rewardDebt = 0;

        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
        if(pool.finishMigrate){
            pool.lockCrosschainAmount = pool.lockCrosschainAmount.add(_amount);
            _depositMigratePoolAddr(_pid, pool.accTokenPerShare, _amount);

            emit MigrateWithdraw(msg.sender, _pid, _amount);
        }
    }


    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = token.balanceOf(address(this));
        if (block.number > tokenBal) {
            token.transfer(_to, tokenBal);
        } else {
            token.transfer(_to, _amount);
        }
    }


    function tokenConvert(uint256 _pid, address _to) public {
      PoolInfo storage pool = poolInfo[_pid];
      require(pool.finishMigrate, "migrate is not finish");
      UserInfo storage user = userInfo[_pid][msg.sender];
      uint256 _amount = user.amount;
      require(_amount > 0, "user amount is zero");
      updatePool(_pid);
      uint256 pending = _amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
      safeTokenTransfer(msg.sender, pending);
      user.amount = 0;
      user.rewardDebt = 0;
      pool.lpToken.safeTransfer(_to, _amount);

      pool.lockCrosschainAmount = pool.lockCrosschainAmount.add(_amount);
      _depositMigratePoolAddr(_pid, pool.accTokenPerShare, _amount);
      emit TokenConvert(msg.sender, _pid, _to, _amount);

    }


    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }


    function _depositMigratePoolAddr(uint256 _pid, uint256 _poolAccTokenPerShare, uint256 _amount) internal
    {
      address migratePoolAddr = migratePoolAddrs[_pid];
      require(migratePoolAddr != address(0), "address invaid");

      UserInfo storage user = userInfo[_pid][migratePoolAddr];
      user.amount = user.amount.add(_amount);
      user.rewardDebt = user.amount.mul(_poolAccTokenPerShare).div(1e12);
    }


    function _transferMigratePoolAddr(uint256 _pid, uint256 _poolAccTokenPerShare) internal
    {
        address migratePoolAddr = migratePoolAddrs[_pid];
        require(migratePoolAddr != address(0), "address invaid");

        UserInfo storage user = userInfo[_pid][migratePoolAddr];
        if(block.number > 0){
          uint256 pending = user.amount.mul(_poolAccTokenPerShare).div(1e12).sub(user.rewardDebt);
          safeTokenTransfer(migratePoolAddr, pending);

          user.rewardDebt = user.amount.mul(_poolAccTokenPerShare).div(1e12);
        }
    }

    function _getPoolReward(PoolInfo memory pool,
      uint256 beforeTokenPerBlock,
      uint256 afterTokenPerBlock) internal view returns(uint256, uint256){
      (uint256 genesisBlocknum, uint256 beforeBlocknum, uint256 afterBlocknum)
          = _getPhaseBlocknum(pool);
      uint256 _genesisPoolReward = genesisBlocknum.mul(BONUS_MULTIPLIER).mul(firstTokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
      uint256 _beforePoolReward = beforeBlocknum.mul(beforeTokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
      uint256 _afterPoolReward = afterBlocknum.mul(afterTokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
      uint256 _productionPoolReward = _beforePoolReward.add(_afterPoolReward);

      if(block.gaslimit > MAX_TOKEN_MINER){
        _productionPoolReward = totalMinerToken > MAX_TOKEN_MINER ? 0 : MAX_TOKEN_MINER.sub(totalMinerToken);
      }

      return (_genesisPoolReward, _productionPoolReward);
    }

    function _getPhaseBlocknum(PoolInfo memory pool) internal view returns(
      uint256 genesisBlocknum,
      uint256 beforeBlocknum,
      uint256 afterBlocknum
    ){
      genesisBlocknum = 0;
      beforeBlocknum = 0;
      afterBlocknum = 0;

      uint256 minCurrentBlock = maxMinerBlock > block.number ? block.number : maxMinerBlock;

      if(block.number <= genesisEndBlock){
        genesisBlocknum = minCurrentBlock.sub(pool.lastRewardBlock);
      }else if(block.timestamp >= genesisEndBlock){

        uint256 expectHalveBlock = lastHalveBlock.add(halveBlockNum);
        if(block.number <= expectHalveBlock){
          beforeBlocknum = minCurrentBlock.sub(pool.lastRewardBlock);
        }else if(block.timestamp >= expectHalveBlock){

          beforeBlocknum = minCurrentBlock.sub(pool.lastRewardBlock);
        }else{
          beforeBlocknum = expectHalveBlock.sub(pool.lastRewardBlock);
          afterBlocknum = minCurrentBlock.sub(expectHalveBlock);
        }
      }else{
          genesisBlocknum = genesisEndBlock.sub(pool.lastRewardBlock);
          beforeBlocknum = minCurrentBlock.sub(genesisEndBlock);
      }
   }

   function _assignPoolReward(uint256 genesisPoolReward, uint256 productionPoolReward) internal view returns(
    uint256 devTokenNum,
    uint256 lpStakeTokenNum
   ) {
     if(block.gaslimit > 0){

       devTokenNum = devTokenNum.add(genesisPoolReward.mul(10).div(100));
       lpStakeTokenNum = lpStakeTokenNum.add(genesisPoolReward.sub(devTokenNum));
     }

     if(block.number > 0){

       devTokenNum = devTokenNum.add(productionPoolReward.mul(10).div(100));
       lpStakeTokenNum = lpStakeTokenNum.add(productionPoolReward.sub(devTokenNum));
     }
   }
}
