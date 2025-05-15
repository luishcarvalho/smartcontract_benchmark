



pragma solidity ^0.5.5;














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




library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }







    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }



















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}





library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }




    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }




    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }





    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}




















contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {






        _notEntered = true;
    }








    modifier nonReentrant() {

        require(_notEntered, "ReentrancyGuard: reentrant call");


        _notEntered = false;

        _;



        _notEntered = true;
    }
}











contract Context {


    constructor () internal { }


    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract SupporterRole is Context {
    using Roles for Roles.Role;

    event SupporterAdded(address indexed account);
    event SupporterRemoved(address indexed account);

    Roles.Role private _supporters;

    constructor () internal {
        _addSupporter(_msgSender());
    }

    modifier onlySupporter() {
        require(isSupporter(_msgSender()), "SupporterRole: caller does not have the Supporter role");
        _;
    }

    function isSupporter(address account) public view returns (bool) {
        return _supporters.has(account);
    }

    function addSupporter(address account) public onlySupporter {
        _addSupporter(account);
    }

    function renounceSupporter() public {
        _removeSupporter(_msgSender());
    }

    function _addSupporter(address account) internal {
        _supporters.add(account);
        emit SupporterAdded(account);
    }

    function _removeSupporter(address account) internal {
        _supporters.remove(account);
        emit SupporterRemoved(account);
    }
}

contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}










contract Pausable is Context, PauserRole {



    event Paused(address account);




    event Unpaused(address account);

    bool private _paused;





    constructor () internal {
        _paused = false;
    }




    function paused() public view returns (bool) {
        return _paused;
    }




    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }




    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }




    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }




    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}











contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() internal view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }




    function isOwner() internal view returns (bool) {
        return _msgSender() == _owner;
    }








    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }




    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}










library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function callOptionalReturn(IERC20 token, bytes memory data) private {








        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}





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




contract Secondary is Context {
    address private _primary;




    event PrimaryTransferred(
        address recipient
    );




    constructor () internal {
        address msgSender = _msgSender();
        _primary = msgSender;
        emit PrimaryTransferred(msgSender);
    }




    modifier onlyPrimary() {
        require(_msgSender() == _primary, "Secondary: caller is not the primary account");
        _;
    }




    function primary() public view returns (address) {
        return _primary;
    }





    function transferPrimary(address recipient) public onlyPrimary {
        require(recipient != address(0), "Secondary: new primary is the zero address");
        _primary = recipient;
        emit PrimaryTransferred(recipient);
    }
}







contract __unstable__TokenVault is Secondary {
    function transferToken(IERC20 token, address to, uint256 amount) public onlyPrimary {
        token.transfer(to, amount);
    }
    function transferFunds(address payable to, uint256 amount) public onlyPrimary {
        require (address(this).balance >= amount);
        to.transfer(amount);
    }
    function () external payable {}
}




contract MoonStaking is Ownable, Pausable, SupporterRole, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Pool {
        uint256 rate;
        uint256 adapter;
        uint256 totalStaked;
    }
    struct User {
        mapping(address => UserSp) tokenPools;
        UserSp ePool;
	}
    struct UserSp {
        uint256 staked;
        uint256 lastRewardTime;
        uint256 earned;
	}

    mapping(address => User) users;
    mapping(address => Pool) pools;


    IERC20 public moon;

    uint256 eRate;
    uint256 eAdapter;
    uint256 eTotalStaked;

    __unstable__TokenVault private _vault;




    constructor(IERC20 _moon) public {
        _vault = new __unstable__TokenVault();
        moon = _moon;
    }





    function updatePoolRate(address pool, uint256 _rate, uint256 _adapter)
        public onlyOwner returns (bool) {
        pools[pool].rate = _rate;
        pools[pool].adapter = _adapter;
        return true;
    }





    function updateEpoolRate(uint256 _rate, uint256 _adapter)
        public onlyOwner returns (bool) {
        eRate = _rate;
        eAdapter = _adapter;
        return true;
    }





    function isPoolAvailable(address pool) public view returns (bool) {
        return pools[pool].rate != 0;
    }






    function poolTokenInfo(address _pool) public view returns (
        uint256 rate,
        uint256 adapter,
        uint256 totalStaked
    ) {
        Pool storage pool = pools[_pool];
        return (pool.rate, pool.adapter, pool.totalStaked);
    }





    function poolInfo(address poolAddress) public view returns (
        uint256 rate,
        uint256 adapter,
        uint256 totalStaked
    ) {
        Pool storage sPool = pools[poolAddress];
        return (sPool.rate, sPool.adapter, sPool.totalStaked);
    }





    function poolEInfo() public view returns (
        uint256 rate,
        uint256 adapter,
        uint256 totalStaked
    ) {
        return (eRate, eAdapter, eTotalStaked);
    }




    function getEarnedEpool() public view returns (uint256) {
        UserSp storage pool = users[_msgSender()].ePool;
        return _getEarned(eRate, eAdapter, pool);
    }




    function getEarnedTpool(address stakingPoolAddress) public view returns (uint256) {
        UserSp storage stakingPool = users[_msgSender()].tokenPools[stakingPoolAddress];
        Pool storage pool = pools[stakingPoolAddress];
        return _getEarned(pool.rate, pool.adapter, stakingPool);
    }





    function stakeE() public payable returns (bool) {
        uint256 _value = msg.value;
        require(_value != 0, "Zero amount");
        address(uint160((address(_vault)))).transfer(_value);
        UserSp storage ePool = users[_msgSender()].ePool;
        ePool.earned = ePool.earned.add(_getEarned(eRate, eAdapter, ePool));
        ePool.lastRewardTime = block.timestamp;
        ePool.staked = ePool.staked.add(_value);
        eTotalStaked = eTotalStaked.add(_value);
        return true;
    }







    function stake(uint256 _value, IERC20 token) public returns (bool) {
        require(token.balanceOf(_msgSender()) >= _value, "Insufficient Funds");
        require(token.allowance(_msgSender(), address(this)) >= _value, "Insufficient Funds Approved");
        address tokenAddress = address(token);
        require(isPoolAvailable(tokenAddress), "Pool is not available");
        _forwardFundsToken(token, _value);
        Pool storage pool = pools[tokenAddress];
        UserSp storage tokenPool = users[_msgSender()].tokenPools[tokenAddress];
        tokenPool.earned = tokenPool.earned.add(_getEarned(pool.rate, pool.adapter, tokenPool));
        tokenPool.lastRewardTime = block.timestamp;
        tokenPool.staked = tokenPool.staked.add(_value);
        pool.totalStaked = pool.totalStaked.add(_value);
        return true;
    }




    function withdrawTokenPool(address token) public whenNotPaused nonReentrant returns (bool) {
        UserSp storage tokenStakingPool = users[_msgSender()].tokenPools[token];
        require(tokenStakingPool.staked > 0 != tokenStakingPool.earned > 0, "Not available");
        if (tokenStakingPool.earned > 0) {
            Pool storage pool = pools[token];
            _vault.transferToken(moon, _msgSender(),  _getEarned(pool.rate, pool.adapter, tokenStakingPool));
            tokenStakingPool.lastRewardTime = block.timestamp;
            tokenStakingPool.earned = 0;
        }
        if (tokenStakingPool.staked > 0) {
            _vault.transferToken(IERC20(token), _msgSender(), tokenStakingPool.staked);
            tokenStakingPool.staked = 0;
        }
        return true;
    }




    function withdrawEPool() public whenNotPaused nonReentrant returns (bool) {
        UserSp storage eStakingPool = users[_msgSender()].ePool;
        require(eStakingPool.staked > 0 != eStakingPool.earned > 0, "Not available");
        if (eStakingPool.earned > 0) {
            _vault.transferToken(moon, _msgSender(),  _getEarned(eRate, eAdapter, eStakingPool));
            eStakingPool.lastRewardTime = block.timestamp;
            eStakingPool.earned = 0;
        }
        if (eStakingPool.staked > 0) {
            _vault.transferFunds(_msgSender(), eStakingPool.staked);
            eStakingPool.staked = 0;
        }
        return true;
    }




    function claimMoonInTpool(address token) public whenNotPaused returns (bool) {
        UserSp storage tokenStakingPool = users[_msgSender()].tokenPools[token];
        require(tokenStakingPool.staked > 0 != tokenStakingPool.earned > 0, "Not available");
        Pool storage pool = pools[token];
        _vault.transferToken(moon, _msgSender(), _getEarned(pool.rate, pool.adapter, tokenStakingPool));
        tokenStakingPool.lastRewardTime = block.timestamp;
        tokenStakingPool.earned = 0;
        return true;
    }




    function claimMoonInEpool() public whenNotPaused returns (bool) {
        UserSp storage eStakingPool = users[_msgSender()].ePool;
        require(eStakingPool.staked > 0 != eStakingPool.earned > 0, "Not available");
        _vault.transferToken(moon, _msgSender(), _getEarned(eRate, eAdapter, eStakingPool));
        eStakingPool.lastRewardTime = block.timestamp;
        eStakingPool.earned = 0;
        return true;
    }




    function getReserved() public view onlyOwner
        returns (uint256 vaultTokens, uint256 vaultFunds) {
        address vaultAddress = address(_vault);
        vaultTokens = moon.balanceOf(vaultAddress);
        vaultFunds = address(uint160(vaultAddress)).balance;
    }




    function getReservedByAddress(IERC20 token) public view onlyOwner returns (uint256) {
        return token.balanceOf(address(_vault));
    }





    function supplyVault(uint256 amount)
        public onlyOwner
        returns (bool) {
        moon.transferFrom(_msgSender(), address(_vault), amount);
        return true;
    }






    function depriveToken(address vault, IERC20 token, uint256 amount)
        public onlyOwner returns (bool) {
        _vault.transferToken(token, vault, amount);
        return true;
    }






    function depriveFunds(address payable vault, uint256 amount)
        public onlyOwner
        returns (bool) {
        _vault.transferFunds(vault, amount);
        return true;
    }




    function () external payable {
        address(uint160((address(_vault)))).call.gas(2301).value(msg.value)("");
    }






    function _forwardFundsToken(IERC20 erc20Token, uint256 _value) internal {
        erc20Token.transferFrom(_msgSender(), address(_vault), _value);
    }




    function _getEarned(uint256 rate, uint256 adapter, UserSp memory stakingPool) internal view returns (uint256) {
        uint256 moonPerSec = stakingPool.staked.mul(rate).div(adapter);
        return block.timestamp.sub(stakingPool.lastRewardTime).mul(moonPerSec).add(stakingPool.earned);
    }
}
