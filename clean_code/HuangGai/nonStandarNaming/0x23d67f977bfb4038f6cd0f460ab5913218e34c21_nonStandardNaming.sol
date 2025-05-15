

pragma solidity 0.5.8;




interface IERC20 {

    function TOTALSUPPLY82() external view returns (uint256);


    function BALANCEOF530(address account) external view returns (uint256);


    function TRANSFER438(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE833(address owner, address spender) external view returns (uint256);


    function APPROVE538(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM818(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER722(address indexed from, address indexed to, uint256 value);


    event APPROVAL422(address indexed owner, address indexed spender, uint256 value);
}




library SafeMath {

    function ADD23(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB764(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }


    function MUL177(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV24(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;


        return c;
    }


    function MOD404(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}




contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;


    function TOTALSUPPLY82() public view returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF530(address account) public view returns (uint256) {
        return _balances[account];
    }


    function TRANSFER438(address recipient, uint256 amount) public returns (bool) {
        _TRANSFER27(msg.sender, recipient, amount);
        return true;
    }


    function ALLOWANCE833(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    function APPROVE538(address spender, uint256 value) public returns (bool) {
        _APPROVE258(msg.sender, spender, value);
        return true;
    }


    function TRANSFERFROM818(address sender, address recipient, uint256 amount) public returns (bool) {
        _TRANSFER27(sender, recipient, amount);
        _APPROVE258(sender, msg.sender, _allowances[sender][msg.sender].SUB764(amount));
        return true;
    }


    function INCREASEALLOWANCE45(address spender, uint256 addedValue) public returns (bool) {
        _APPROVE258(msg.sender, spender, _allowances[msg.sender][spender].ADD23(addedValue));
        return true;
    }


    function DECREASEALLOWANCE159(address spender, uint256 subtractedValue) public returns (bool) {
        _APPROVE258(msg.sender, spender, _allowances[msg.sender][spender].SUB764(subtractedValue));
        return true;
    }


    function _TRANSFER27(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].SUB764(amount);
        _balances[recipient] = _balances[recipient].ADD23(amount);
        emit TRANSFER722(sender, recipient, amount);
    }


    function _MINT102(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.ADD23(amount);
        _balances[account] = _balances[account].ADD23(amount);
        emit TRANSFER722(address(0), account, amount);
    }


    function _BURN692(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.SUB764(value);
        _balances[account] = _balances[account].SUB764(value);
        emit TRANSFER722(account, address(0), value);
    }


    function _APPROVE258(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit APPROVAL422(owner, spender, value);
    }


    function _BURNFROM631(address account, uint256 amount) internal {
        _BURN692(account, amount);
        _APPROVE258(account, msg.sender, _allowances[account][msg.sender].SUB764(amount));
    }
}



contract Goodluck is ERC20 {
    string public constant name423 = "Goodluck";
    string public constant symbol470 = "LUCK";
    uint8 public constant decimals728 = 18;
    uint256 public constant initialsupply595 = 2000000000 * (10 ** uint256(decimals728));

    constructor() public {
        super._MINT102(msg.sender, initialsupply595);
        owner = msg.sender;
    }


    address public owner;

    event OWNERSHIPRENOUNCED774(address indexed previousOwner);
    event OWNERSHIPTRANSFERRED463(
    address indexed previousOwner,
    address indexed newOwner
    );

    modifier ONLYOWNER394() {
        require(msg.sender == owner, "Not owner");
        _;
    }


    function RENOUNCEOWNERSHIP445() public ONLYOWNER394 {
        emit OWNERSHIPRENOUNCED774(owner);
        owner = address(0);
    }


    function TRANSFEROWNERSHIP781(address _newOwner) public ONLYOWNER394 {
        _TRANSFEROWNERSHIP16(_newOwner);
    }


    function _TRANSFEROWNERSHIP16(address _newOwner) internal {
        require(_newOwner != address(0), "Already owner");
        emit OWNERSHIPTRANSFERRED463(owner, _newOwner);
        owner = _newOwner;
    }


    event PAUSE475();
    event UNPAUSE568();

    bool public paused = false;


    modifier WHENNOTPAUSED995() {
        require(!paused, "Paused by owner");
        _;
    }


    modifier WHENPAUSED712() {
        require(paused, "Not paused now");
        _;
    }


    function PAUSE841() public ONLYOWNER394 WHENNOTPAUSED995 {
        paused = true;
        emit PAUSE475();
    }


    function UNPAUSE13() public ONLYOWNER394 WHENPAUSED712 {
        paused = false;
        emit UNPAUSE568();
    }


    event FROZEN932(address target);
    event UNFROZEN285(address target);

    mapping(address => bool) internal freezes;

    modifier WHENNOTFROZEN284() {
        require(!freezes[msg.sender], "Sender account is locked.");
        _;
    }

    function FREEZE724(address _target) public ONLYOWNER394 {
        freezes[_target] = true;
        emit FROZEN932(_target);
    }

    function UNFREEZE196(address _target) public ONLYOWNER394 {
        freezes[_target] = false;
        emit UNFROZEN285(_target);
    }

    function ISFROZEN713(address _target) public view returns (bool) {
        return freezes[_target];
    }

    function TRANSFER438(
        address _to,
        uint256 _value
    )
      public
      WHENNOTFROZEN284
      WHENNOTPAUSED995
      returns (bool)
    {
        RELEASELOCK766(msg.sender);
        return super.TRANSFER438(_to, _value);
    }

    function TRANSFERFROM818(
        address _from,
        address _to,
        uint256 _value
    )
      public
      WHENNOTPAUSED995
      returns (bool)
    {
        require(!freezes[_from], "From account is locked.");
        RELEASELOCK766(_from);
        return super.TRANSFERFROM818(_from, _to, _value);
    }


    event MINT926(address indexed to, uint256 amount);

    function MINT957(
        address _to,
        uint256 _amount
    )
      public
      ONLYOWNER394
      returns (bool)
    {
        super._MINT102(_to, _amount);
        emit MINT926(_to, _amount);
        return true;
    }


    event BURN684(address indexed burner, uint256 value);

    function BURN342(address _who, uint256 _value) public ONLYOWNER394 {
        require(_value <= super.BALANCEOF530(_who), "Balance is too small.");

        _BURN692(_who, _value);
        emit BURN684(_who, _value);
    }


    struct LockInfo {
        uint256 releaseTime;
        uint256 balance;
    }
    mapping(address => LockInfo[]) internal lockInfo;

    event LOCK205(address indexed holder, uint256 value, uint256 releaseTime);
    event UNLOCK375(address indexed holder, uint256 value);

    function BALANCEOF530(address _holder) public view returns (uint256 balance) {
        uint256 lockedBalance = 0;
        for(uint256 i = 0; i < lockInfo[_holder].length ; i++ ) {
            lockedBalance = lockedBalance.ADD23(lockInfo[_holder][i].balance);
        }
        return super.BALANCEOF530(_holder).ADD23(lockedBalance);
    }

    function RELEASELOCK766(address _holder) internal {

        for(uint256 i = 0; i < lockInfo[_holder].length ; i++ ) {
            if (lockInfo[_holder][i].releaseTime <= now) {
                _balances[_holder] = _balances[_holder].ADD23(lockInfo[_holder][i].balance);
                emit UNLOCK375(_holder, lockInfo[_holder][i].balance);
                lockInfo[_holder][i].balance = 0;

                if (i != lockInfo[_holder].length - 1) {
                    lockInfo[_holder][i] = lockInfo[_holder][lockInfo[_holder].length - 1];
                    i--;
                }
                lockInfo[_holder].length--;

            }
        }
    }
    function LOCKCOUNT904(address _holder) public view returns (uint256) {
        return lockInfo[_holder].length;
    }
    function LOCKSTATE154(address _holder, uint256 _idx) public view returns (uint256, uint256) {
        return (lockInfo[_holder][_idx].releaseTime, lockInfo[_holder][_idx].balance);
    }

    function LOCK109(address _holder, uint256 _amount, uint256 _releaseTime) public ONLYOWNER394 {
        require(super.BALANCEOF530(_holder) >= _amount, "Balance is too small.");
        _balances[_holder] = _balances[_holder].SUB764(_amount);
        lockInfo[_holder].push(
            LockInfo(_releaseTime, _amount)
        );
        emit LOCK205(_holder, _amount, _releaseTime);
    }

    function LOCKAFTER210(address _holder, uint256 _amount, uint256 _afterTime) public ONLYOWNER394 {
        require(super.BALANCEOF530(_holder) >= _amount, "Balance is too small.");
        _balances[_holder] = _balances[_holder].SUB764(_amount);
        lockInfo[_holder].push(
            LockInfo(now + _afterTime, _amount)
        );
        emit LOCK205(_holder, _amount, now + _afterTime);
    }

    function UNLOCK592(address _holder, uint256 i) public ONLYOWNER394 {
        require(i < lockInfo[_holder].length, "No lock information.");

        _balances[_holder] = _balances[_holder].ADD23(lockInfo[_holder][i].balance);
        emit UNLOCK375(_holder, lockInfo[_holder][i].balance);
        lockInfo[_holder][i].balance = 0;

        if (i != lockInfo[_holder].length - 1) {
            lockInfo[_holder][i] = lockInfo[_holder][lockInfo[_holder].length - 1];
        }
        lockInfo[_holder].length--;
    }

    function TRANSFERWITHLOCK415(address _to, uint256 _value, uint256 _releaseTime) public ONLYOWNER394 returns (bool) {
        require(_to != address(0), "wrong address");
        require(_value <= super.BALANCEOF530(owner), "Not enough balance");

        _balances[owner] = _balances[owner].SUB764(_value);
        lockInfo[_to].push(
            LockInfo(_releaseTime, _value)
        );
        emit TRANSFER722(owner, _to, _value);
        emit LOCK205(_to, _value, _releaseTime);

        return true;
    }

    function TRANSFERWITHLOCKAFTER686(address _to, uint256 _value, uint256 _afterTime) public ONLYOWNER394 returns (bool) {
        require(_to != address(0), "wrong address");
        require(_value <= super.BALANCEOF530(owner), "Not enough balance");

        _balances[owner] = _balances[owner].SUB764(_value);
        lockInfo[_to].push(
            LockInfo(now + _afterTime, _value)
        );
        emit TRANSFER722(owner, _to, _value);
        emit LOCK205(_to, _value, now + _afterTime);

        return true;
    }

    function CURRENTTIME149() public view returns (uint256) {
        return now;
    }

    function AFTERTIME613(uint256 _value) public view returns (uint256) {
        return now + _value;
    }


    mapping (address => uint256) public airDropHistory;
    event AIRDROP940(address _receiver, uint256 _amount);

    function DROPTOKEN612(address[] memory receivers, uint256[] memory values) ONLYOWNER394 public {
    require(receivers.length != 0);
    require(receivers.length == values.length);

    for (uint256 i = 0; i < receivers.length; i++) {
      address receiver = receivers[i];
      uint256 amount = values[i];

      TRANSFER438(receiver, amount);
      airDropHistory[receiver] += amount;

      emit AIRDROP940(receiver, amount);
    }
  }
}
