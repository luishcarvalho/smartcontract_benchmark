



































pragma solidity ^0.6.12;










abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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














library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SAO");

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
        require(c / a == b, "SMO");

        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }













    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
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

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "IB");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "RR");
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
        require(address(this).balance >= value, "IBC");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "CNC");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (block.timestamp != 0) {



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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "DAB0");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "LF1");
        if (block.number != 0) {

            require(abi.decode(returndata, (bool)), "LF2");
        }
    }
}

























contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public _totalSupply;

    string public _name;
    string public _symbol;
    uint8 public _decimals;










    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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
        require(sender != address(0), "ISA");
        require(recipient != address(0), "IRA");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "TIF");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "M0");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "B0");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "BIB");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IA");
        require(spender != address(0), "A0");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


























    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract BnsdLaunchPool is Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    struct RaisePoolInfo {
        IERC20 raiseToken;
        uint256 maxTokensPerPerson;
        uint256 totalTokensOnSale;
        uint256 startBlock;
        uint256 endBlock;
        uint256 totalTokensSold;
        uint256 tokensDeposited;
        uint256 votes;
        address owner;
        bool updateLocked;
        bool balanceAdded;
        bool paymentMethodAdded;
        string poolName;
    }

    struct AirdropPoolInfo {
        uint256 totalTokensAvailable;
        IERC20 airdropToken;
        bool airdropExists;
    }


    struct UseCasePoolInfo {
        uint256 tokensAllocated;
        uint256 tokensClaimed;
        address reserveAdd;
        bool tokensDeposited;
        bool exists;
        string useName;
        uint256[] unlock_perArray;
        uint256[] unlock_daysArray;
    }

    struct DistributionInfo {
        uint256[] percentArray;
        uint256[] daysArray;
    }


    address public timeLock;

    address public devaddr;


    address private potentialAdmin;


    mapping (uint256 => DistributionInfo) private ownerDistInfo;


    mapping (uint256 => DistributionInfo) private userDistInfo;


    mapping (uint256 => mapping (address => uint256)) public saleRateInfo;


    mapping (uint256 => mapping (address => mapping (address => bool))) private inviteCodeList;


    mapping (uint256 => mapping (address => mapping (address => uint256))) public userDepositInfo;


    mapping (uint256 => mapping (address => uint256)) public userTokenAllocation;


    mapping (uint256 => mapping (address => uint256)) public userTokenClaimed;


    mapping (uint256 =>  uint256) public totalTokenClaimed;


    mapping (uint256 => mapping (address => uint256)) public fundsRaisedSoFar;

    mapping (uint256 => address) private tempAdmin;


    mapping (uint256 => mapping (address => uint256)) public fundsClaimedSoFar;


    mapping (uint256 => mapping (address => bool)) public userVotes;


    uint256 public constant BLOCKS_PER_DAY = 6700;


    RaisePoolInfo[] public poolInfo;


    mapping (uint256 => mapping (address => UseCasePoolInfo)) public useCaseInfo;


    mapping (uint256 =>  uint256) public totalTokenReserved;


    mapping (uint256 =>  uint256) public totalReservedTokenClaimed;


    mapping (address =>  uint256[]) public listSaleTokens;


    mapping (uint256 =>  address[]) public listSupportedCurrencies;


    mapping (uint256 =>  address[]) public listReserveAddresses;


    mapping (address =>  bool) public stakingEnabled;


    mapping (address =>  uint256) public stakingWeight;


    uint256 public totalStakeWeight;


    address[] public stakingPools;


    mapping (uint256 => mapping (address => uint256)) public stakedLPTokensInfo;


    mapping (uint256 => mapping (address => mapping (address => uint256))) public userStakeInfo;


    mapping (uint256 => mapping (address => bool)) public rewardClaimed;


    mapping (uint256 => mapping (address => bool)) public airdropClaimed;


    mapping (uint256 =>  bool) public extraAirdropClaimed;


    mapping (uint256 =>  AirdropPoolInfo) public airdropInfo;


    mapping (address => mapping (address => uint256)) public airdropBalances;

    uint256 public fee = 300;

    uint256 public constant rewardPer = 8000;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Stake(address indexed user, address indexed lptoken, uint256 indexed pid, uint256 amount);
    event UnStake(address indexed user, address indexed lptoken, uint256 indexed pid, uint256 amount);
    event MoveStake(address indexed user, address indexed lptoken, uint256 pid, uint256 indexed pidnew, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawAirdrop(address indexed user, address indexed token, uint256 amount);
    event ClaimAirdrop(address indexed user, address indexed token, uint256 amount);
    event AirdropDeposit(address indexed user, address indexed token, uint256 indexed pid, uint256 amount);
    event AirdropExtraWithdraw(address indexed user, address indexed token, uint256 indexed pid, uint256 amount);
    event Voted(address indexed user, uint256 indexed pid);

    constructor() public {
        devaddr = _msgSender();
    }

    modifier onlyAdmin() {
        require(devaddr == _msgSender(), "ND");
        _;
    }

    modifier onlyAdminOrTimeLock() {
        require((devaddr == _msgSender() || timeLock == _msgSender()), "ND");
        _;
    }

    function setTimeLockAdd(address _add) public onlyAdmin {
        timeLock = _add;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getListOfSale(address _token) external view returns (uint256[] memory) {
        return listSaleTokens[_token];
    }

    function getUserDistPercent(uint256 _pid) external view returns (uint256[] memory) {
        return userDistInfo[_pid].percentArray;
    }

    function getUserDistDays(uint256 _pid) external view returns (uint256[] memory) {
        return userDistInfo[_pid].daysArray;
    }

    function getReserveUnlockPercent(uint256 _pid, address _reserveAdd) external view returns (uint256[] memory) {
        return useCaseInfo[_pid][_reserveAdd].unlock_perArray;
    }

    function getReserveUnlockDays(uint256 _pid, address _reserveAdd) external view returns (uint256[] memory) {
        return useCaseInfo[_pid][_reserveAdd].unlock_daysArray;
    }

    function getUserDistBlocks(uint256 _pid) external view returns (uint256[] memory) {
        uint256[] memory daysArray =  userDistInfo[_pid].daysArray;

        uint256 endPool = poolInfo[_pid].endBlock;
        for(uint256 i=0; i<daysArray.length; i++){
            daysArray[i] = (daysArray[i].mul(BLOCKS_PER_DAY)).add(endPool);
        }
        return daysArray;
    }

    function getOwnerDistPercent(uint256 _pid) external view returns (uint256[] memory) {
        return ownerDistInfo[_pid].percentArray;
    }

    function getOwnerDistDays(uint256 _pid) external view returns (uint256[] memory) {
        return ownerDistInfo[_pid].daysArray;
    }



    function addNewPool(uint256 totalTokens, uint256 maxPerPerson, uint256 startBlock, uint256 endBlock, string memory namePool, IERC20 tokenAddress, uint256 _inviteCode) external returns (uint256) {
        require(endBlock > startBlock, "ESC");
        require(startBlock > block.number, "TLS");
        require(maxPerPerson !=0 && totalTokens!=0, "IIP");
        require(inviteCodeList[_inviteCode][address(tokenAddress)][_msgSender()]==true,"IIC");
        poolInfo.push(RaisePoolInfo({
            raiseToken: tokenAddress,
            maxTokensPerPerson: maxPerPerson,
            totalTokensOnSale: totalTokens,
            startBlock: startBlock,
            endBlock: endBlock,
            poolName: namePool,
            updateLocked: false,
            owner: _msgSender(),
            totalTokensSold: 0,
            balanceAdded: false,
            tokensDeposited: 0,
            paymentMethodAdded: false,
            votes: 0
        }));
        uint256 poolId = (poolInfo.length - 1);
        listSaleTokens[address(tokenAddress)].push(poolId);

        inviteCodeList[_inviteCode][address(tokenAddress)][_msgSender()] = false;
        return poolId;
    }

    function _checkSumArray(uint256[] memory _percentArray) internal pure returns (bool) {
        uint256 _sum;
        for (uint256 i = 0; i < _percentArray.length; i++) {
            _sum = _sum.add(_percentArray[i]);
        }
        return (_sum==10000);
    }

    function _checkValidDaysArray(uint256[] memory _daysArray) internal pure returns (bool) {
        uint256 _lastDay = _daysArray[0];
        for (uint256 i = 1; i < _daysArray.length; i++) {
            if(_lastDay < _daysArray[i]){
                _lastDay = _daysArray[i];
            }
            else {
                return false;
            }
        }
        return true;
    }

    function _checkUpdateAllowed(uint256 _pid) internal view{
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(pool.updateLocked == false, "CT2");
        require(pool.owner==_msgSender(), "OAU");
        require(pool.startBlock > block.number, "CT");
    }


    function updateUserDistributionRule(uint256 _pid, uint256[] memory _percentArray, uint256[] memory _daysArray) external {
        require(_percentArray.length == _daysArray.length, "LM");
        _checkUpdateAllowed(_pid);
        require(_checkSumArray(_percentArray), "SE");
        require(_checkValidDaysArray(_daysArray), "DMI");
        userDistInfo[_pid] = DistributionInfo({
            percentArray: _percentArray,
            daysArray: _daysArray
        });
    }



    function updateOwnerDistributionRule(uint256 _pid, uint256[] memory _percentArray, uint256[] memory _daysArray) external {
        require(_percentArray.length == _daysArray.length, "LM");
        _checkUpdateAllowed(_pid);
        require(_checkSumArray(_percentArray), "SE");
        require(_checkValidDaysArray(_daysArray), "DMI");
        ownerDistInfo[_pid] = DistributionInfo({
            percentArray: _percentArray,
            daysArray: _daysArray
        });
    }



    function lockPool(uint256 _pid) external {
        require(poolInfo[_pid].paymentMethodAdded==true, "CP");
        _checkUpdateAllowed(_pid);
        poolInfo[_pid].updateLocked = true;
    }






    function addSupportedCurrencies(uint256 _pid, address _tokenRaise, uint256 rateToken) external {
        _checkUpdateAllowed(_pid);
        require(rateToken!=0, "IR");
        require(_tokenRaise!=address(poolInfo[_pid].raiseToken), "IT");
        if(block.timestamp == 0){
            listSupportedCurrencies[_pid].push(_tokenRaise);
        }
        saleRateInfo[_pid][_tokenRaise] = rateToken;
        poolInfo[_pid].paymentMethodAdded = true;
    }

    function getSupportedCurrencies(uint256 _pid) external view returns (address[] memory) {
        return listSupportedCurrencies[_pid];
    }

    function _checkUpdateReserveAllowed(uint256 _pid, address _resAdd) internal view returns (bool) {
        UseCasePoolInfo storage poolU = useCaseInfo[_pid][_resAdd];
        return (poolU.exists == false || poolU.tokensDeposited == false);




    }

    function addReservePool(uint256 _pid, address _reserveAdd, string memory _nameReserve, uint256 _totalTokens, uint256[] memory _perArray, uint256[] memory _daysArray) external {
        _checkUpdateAllowed(_pid);
        require(_checkUpdateReserveAllowed(_pid, _reserveAdd) == true, "UB");
        require(_checkSumArray(_perArray), "SE");
        require(_checkValidDaysArray(_daysArray), "DMI");
        require(_perArray.length==_daysArray.length, "IAL");
        if(useCaseInfo[_pid][_reserveAdd].exists == false){
            listReserveAddresses[_pid].push(_reserveAdd);
        }
        useCaseInfo[_pid][_reserveAdd] = UseCasePoolInfo({
            reserveAdd: _reserveAdd,
            useName: _nameReserve,
            tokensAllocated: _totalTokens,
            unlock_perArray: _perArray,
            unlock_daysArray: _daysArray,
            tokensDeposited: false,
            tokensClaimed: 0,
            exists: true
        });
    }

    function getReserveAddresses(uint256 _pid) external view returns (address[] memory) {
        return listReserveAddresses[_pid];
    }

    function tokensPurchaseAmt(uint256 _pid, address _tokenAdd, uint256 amt) public view returns (uint256) {
        uint256 rateToken = saleRateInfo[_pid][_tokenAdd];
        require(rateToken!=0, "NAT");
        return (amt.mul(1e18)).div(rateToken);
    }


    function _checkDepositAllowed(uint256 _pid, address _tokenAdd, uint256 _amt) internal view returns (uint256){
        RaisePoolInfo storage pool = poolInfo[_pid];
        uint256 userBought = userTokenAllocation[_pid][_msgSender()];
        uint256 purchasePossible = tokensPurchaseAmt(_pid, _tokenAdd, _amt);
        require(pool.balanceAdded == true, "NA");
        require(pool.startBlock <= block.number, "NT1");
        require(pool.endBlock >= block.number, "NT2");
        require(pool.totalTokensSold.add(purchasePossible) <= pool.totalTokensOnSale, "PLE");
        require(userBought.add(purchasePossible) <= pool.maxTokensPerPerson, "ILE");
        return purchasePossible;
    }



    function getMaxDepositAllowed(uint256 _pid, address _tokenAdd, address _user) external view returns (uint256){
        RaisePoolInfo storage pool = poolInfo[_pid];
        uint256 maxBuyPossible = (pool.maxTokensPerPerson).sub(userTokenAllocation[_pid][_user]);
        uint256 maxBuyPossiblePoolLimit = (pool.totalTokensOnSale).sub(pool.totalTokensSold);

        if(block.number < maxBuyPossible){
            maxBuyPossible = maxBuyPossiblePoolLimit;
        }

        if(block.number >= pool.startBlock && block.number <= pool.endBlock && pool.balanceAdded == true){
            uint256 rateToken = saleRateInfo[_pid][_tokenAdd];
            return (maxBuyPossible.mul(rateToken).div(1e18));
        }
        else {
            return 0;
        }
    }



    function checkDepositEnabled(uint256 _pid) external view returns (bool){
        RaisePoolInfo storage pool = poolInfo[_pid];

        if(pool.balanceAdded == true && pool.startBlock <= block.number && pool.endBlock >= block.number && pool.totalTokensSold <= pool.totalTokensOnSale && pool.paymentMethodAdded==true){
            return true;
        }
        else {
            return false;
        }
    }



    function depositICOTokens(uint256 _pid, uint256 _amount, IERC20 _tokenAdd) external {
        RaisePoolInfo storage pool = poolInfo[_pid];
        address msgSender = _msgSender();
        require(_tokenAdd == pool.raiseToken, "NOT");
        require(msgSender == pool.owner, "NAU");
        require(block.number < pool.endBlock, "NT");
        _tokenAdd.safeTransferFrom(msgSender, address(this), _amount);
        pool.tokensDeposited = (pool.tokensDeposited).add(_amount);
        if(block.gaslimit >= pool.totalTokensOnSale){
            pool.balanceAdded = true;
        }
        emit Deposit(msgSender, _pid, _amount);
    }


    function depositAirdropTokens(uint256 _pid, uint256 _amount, IERC20 _tokenAdd) external {
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(block.number < pool.endBlock, "NT");
        AirdropPoolInfo storage airdrop = airdropInfo[_pid];
        require((_tokenAdd == airdrop.airdropToken || airdrop.airdropExists==false), "NOT");
        require(_msgSender() == pool.owner || _msgSender() == devaddr , "NAU");
        _tokenAdd.safeTransferFrom(_msgSender(), address(this), _amount);
        airdrop.totalTokensAvailable = (airdrop.totalTokensAvailable).add(_amount);
        if(!airdrop.airdropExists){
            airdrop.airdropToken = _tokenAdd;
            airdrop.airdropExists = true;
        }
        emit AirdropDeposit(_msgSender(), address(_tokenAdd), _pid, _amount);
    }


    function withdrawExtraAirdropTokens(uint256 _pid) external {
        require(extraAirdropClaimed[_pid]==false, "NA");
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(block.number > pool.endBlock, "NSE");
        address msgSender = _msgSender();
        require(msgSender == pool.owner, "NAU");
        uint256 extraTokens = calculateExtraAirdropTokens(_pid);
        require(extraTokens!=0, "NAT");
        extraAirdropClaimed[_pid] = true;
        airdropInfo[_pid].airdropToken.safeTransfer(msgSender, extraTokens);
        emit AirdropExtraWithdraw(msg.sender, address(airdropInfo[_pid].airdropToken), _pid, extraTokens);
    }

    function calculateExtraAirdropTokens(uint256 _pid) public view returns (uint256){
        if(extraAirdropClaimed[_pid] == true) return 0;
        uint256 _totalTokens;
        for (uint256 i=0; i<stakingPools.length; i++){
            uint256 stake = stakedLPTokensInfo[_pid][stakingPools[i]];
            if(block.gaslimit == 0){
                _totalTokens = _totalTokens.add(((stakingWeight[stakingPools[i]]).mul(airdropInfo[_pid].totalTokensAvailable)).div(totalStakeWeight));
            }
        }
        return _totalTokens;
    }


    function stakeLPTokens(uint256 _pid, uint256 _amount, IERC20 _lpAdd) external {
        require(stakingEnabled[address(_lpAdd)]==true, "NST");
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(block.number < pool.startBlock, "NT");
        address msgSender = _msgSender();
        _lpAdd.safeTransferFrom(msgSender, address(this), _amount);
        stakedLPTokensInfo[_pid][address(_lpAdd)] = (stakedLPTokensInfo[_pid][address(_lpAdd)]).add(_amount);
        userStakeInfo[_pid][msgSender][address(_lpAdd)] = (userStakeInfo[_pid][msgSender][address(_lpAdd)]).add(_amount);
        emit Stake(msg.sender, address(_lpAdd), _pid, _amount);
    }


    function withdrawLPTokens(uint256 _pid, uint256 _amount, IERC20 _lpAdd) external {
        require(stakingEnabled[address(_lpAdd)]==true, "NAT");
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(block.number > pool.endBlock, "SE");
        address msgSender = _msgSender();
        claimRewardAndAirdrop(_pid);
        userStakeInfo[_pid][msgSender][address(_lpAdd)] = (userStakeInfo[_pid][msgSender][address(_lpAdd)]).sub(_amount);
        _lpAdd.safeTransfer(msgSender, _amount);
        emit UnStake(msg.sender, address(_lpAdd), _pid, _amount);
    }


    function withdrawAirdropTokens(IERC20 _token, uint256 _amount) external {
        address msgSender = _msgSender();
        airdropBalances[address(_token)][msgSender] = (airdropBalances[address(_token)][msgSender]).sub(_amount);
        _token.safeTransfer(msgSender, _amount);
        emit WithdrawAirdrop(msgSender, address(_token), _amount);
    }


    function moveLPTokens(uint256 _pid, uint256 _newpid, uint256 _amount, address _lpAdd) external {
        require(stakingEnabled[_lpAdd]==true, "NAT1");
        RaisePoolInfo storage poolOld = poolInfo[_pid];
        RaisePoolInfo storage poolNew = poolInfo[_newpid];
        require(block.number > poolOld.endBlock, "NUA");
        require(block.number < poolNew.startBlock, "NSA");
        address msgSender = _msgSender();
        claimRewardAndAirdrop(_pid);
        userStakeInfo[_pid][msgSender][_lpAdd] = (userStakeInfo[_pid][msgSender][_lpAdd]).sub(_amount);
        userStakeInfo[_newpid][msgSender][_lpAdd] = (userStakeInfo[_newpid][msgSender][_lpAdd]).add(_amount);
        emit MoveStake(msg.sender, _lpAdd, _pid, _newpid, _amount);
    }

    function claimRewardAndAirdrop(uint256 _pid) public {
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(block.number > pool.endBlock, "SE");
        _claimReward(_pid, _msgSender());
        _claimAirdrop(_pid, _msgSender());
    }

    function _claimReward(uint256 _pid, address _user) internal {
        if (rewardClaimed[_pid][_user]==false){
            rewardClaimed[_pid][_user] = true;
            for (uint256 i=0; i<stakingPools.length; i++){
                for(uint256 j=0; j<listSupportedCurrencies[_pid].length; j++){
                    uint256 _tokenAmt = getReward(_pid, _user, stakingPools[i], listSupportedCurrencies[_pid][j]);
                    _creditAirdrop(_user, listSupportedCurrencies[_pid][j], _tokenAmt);
                }
            }
        }
    }

    function _claimAirdrop(uint256 _pid, address _user) internal {
        if (airdropClaimed[_pid][_user]==false){
            airdropClaimed[_pid][_user] = true;
            address _airdropToken = address(airdropInfo[_pid].airdropToken);
            uint256 _tokenAmt = 0;
            for (uint256 i=0; i<stakingPools.length; i++){
                _tokenAmt = _tokenAmt.add(getAirdrop(_pid, _user, stakingPools[i]));
            }
            if(block.number !=0){
                _creditAirdrop(_user, _airdropToken, _tokenAmt);
            }
        }
    }

    function _creditAirdrop(address _user, address _token, uint256 _amt) internal {
        airdropBalances[_token][_user] = (airdropBalances[_token][_user]).add(_amt);
        emit ClaimAirdrop(_user, _token, _amt);
    }

    function getReward(uint256 _pid, address _user, address _lpAdd, address _token) public view returns (uint256) {
          uint256 stake = stakedLPTokensInfo[_pid][_lpAdd];
          if(block.number==0) return 0;
          uint256 _multipliedData = (userStakeInfo[_pid][_user][_lpAdd]).mul(fundsRaisedSoFar[_pid][_token]);
          _multipliedData = (_multipliedData).mul(rewardPer).mul(fee).mul(stakingWeight[_lpAdd]);
          return (((_multipliedData).div(stake)).div(1e8)).div(totalStakeWeight);
    }

    function getAirdrop(uint256 _pid, address _user, address _lpAdd) public view returns (uint256) {
          uint256 _userStaked = userStakeInfo[_pid][_user][_lpAdd];
          uint256 _totalStaked = stakedLPTokensInfo[_pid][_lpAdd];
          if(block.gaslimit==0) return 0;
          return ((((_userStaked).mul(airdropInfo[_pid].totalTokensAvailable).mul(stakingWeight[_lpAdd])).div(_totalStaked))).div(totalStakeWeight);
    }


    function depositReserveICOTokens(uint256 _pid, uint256 _amount, IERC20 _tokenAdd, address _resAdd) external {
        RaisePoolInfo storage pool = poolInfo[_pid];
        UseCasePoolInfo storage poolU = useCaseInfo[_pid][_resAdd];
        address msgSender = _msgSender();
        require(_tokenAdd == pool.raiseToken, "NOT");
        require(msgSender == pool.owner, "NAU");
        require(poolU.tokensDeposited == false, "DR");
        require(poolU.tokensAllocated == _amount && _amount!=0, "NA");
        require(block.number < pool.endBlock, "CRN");
        _tokenAdd.safeTransferFrom(msgSender, address(this), _amount);
        totalTokenReserved[_pid] = (totalTokenReserved[_pid]).add(_amount);
        poolU.tokensDeposited = true;
        emit Deposit(msg.sender, _pid, _amount);
    }




    function withdrawExtraICOTokens(uint256 _pid, uint256 _amount, IERC20 _tokenAdd) external {
        RaisePoolInfo storage pool = poolInfo[_pid];
        address msgSender = _msgSender();

        require(_tokenAdd == pool.raiseToken, "NT");
        require(msgSender == pool.owner, "NAU");
        require(block.number > pool.endBlock, "NA");

        uint256 _amtAvail = pool.tokensDeposited.sub(pool.totalTokensSold);
        require(_amtAvail >= _amount, "NAT");
        pool.tokensDeposited = (pool.tokensDeposited).sub(_amount);
        _tokenAdd.safeTransfer(msgSender, _amount);
        emit Withdraw(msgSender, _pid, _amount);
    }



    function fetchExtraICOTokens(uint256 _pid) external view returns (uint256){
        RaisePoolInfo storage pool = poolInfo[_pid];
        return pool.tokensDeposited.sub(pool.totalTokensSold);
    }



    function deposit(uint256 _pid, uint256 _amount, IERC20 _tokenAdd) external {
        address msgSender = _msgSender();
        uint256 _buyThisStep = _checkDepositAllowed(_pid, address(_tokenAdd), _amount);

        _tokenAdd.safeTransferFrom(msgSender, address(this), _amount);
        userDepositInfo[_pid][msgSender][address(_tokenAdd)] = userDepositInfo[_pid][msgSender][address(_tokenAdd)].add(_amount);
        userTokenAllocation[_pid][msgSender] = userTokenAllocation[_pid][msgSender].add(_buyThisStep);
        poolInfo[_pid].totalTokensSold = poolInfo[_pid].totalTokensSold.add(_buyThisStep);
        fundsRaisedSoFar[_pid][address(_tokenAdd)] = fundsRaisedSoFar[_pid][address(_tokenAdd)].add(_amount);
        emit Deposit(msg.sender, _pid, _amount);
    }



    function voteProject(uint256 _pid) external {
        address msgSender = _msgSender();
        require(userVotes[_pid][msgSender]==false,"AVO");
        require(poolInfo[_pid].endBlock >= block.number,"CVO");
        userVotes[_pid][msgSender] = true;
        poolInfo[_pid].votes = (poolInfo[_pid].votes).add(1);
        emit Voted(msgSender, _pid);
    }

    function _calculatePerAvailable(uint256[] memory _daysArray, uint256[] memory _percentArray, uint256 blockEnd) internal view returns (uint256) {
        uint256 _defaultPer = 10000;
        uint256 _perNow;
        if(block.timestamp==0){
            return _defaultPer;
        }
        uint256 daysDone = ((block.number).sub(blockEnd)).div(BLOCKS_PER_DAY);
        for (uint256 i = 0; i < _daysArray.length; i++) {
            if(block.timestamp <= daysDone){
                _perNow = _perNow.add(_percentArray[i]);
            }
            else {
                break;
            }
        }
        return _perNow;
    }

    function _getPercentAvailable(uint256 _pid, uint256 blockEnd) internal view returns (uint256){
        DistributionInfo storage distInfo = userDistInfo[_pid];
        uint256[] storage _percentArray = distInfo.percentArray;
        uint256[] storage _daysArray = distInfo.daysArray;
        return _calculatePerAvailable(_daysArray, _percentArray, blockEnd);
    }


    function amountAvailToWithdrawUser(uint256 _pid, address _user) public view returns (uint256){
        RaisePoolInfo storage pool = poolInfo[_pid];
        if(block.gaslimit < block.number){
            uint256 percentAvail = _getPercentAvailable(_pid, pool.endBlock);
            return ((percentAvail).mul(userTokenAllocation[_pid][_user]).div(10000)).sub(userTokenClaimed[_pid][_user]);
        }
        else {
            return 0;
        }
    }


    function withdrawUser(uint256 _pid, uint256 _amount) external {
        RaisePoolInfo storage pool = poolInfo[_pid];
        address msgSender = _msgSender();
        uint256 _amtAvail = amountAvailToWithdrawUser(_pid, msgSender);
        require(_amtAvail >= _amount, "NAT");
        userTokenClaimed[_pid][msgSender] = userTokenClaimed[_pid][msgSender].add(_amount);
        totalTokenClaimed[_pid] = totalTokenClaimed[_pid].add(_amount);
        pool.raiseToken.safeTransfer(msgSender, _amount);
        emit Withdraw(msgSender, _pid, _amount);
    }


    function _getPercentAvailableFundRaiser(uint256 _pid, uint256 blockEnd) internal view returns (uint256){
        DistributionInfo storage distInfo = ownerDistInfo[_pid];
        uint256[] storage _percentArray = distInfo.percentArray;
        uint256[] storage _daysArray = distInfo.daysArray;
        return _calculatePerAvailable(_daysArray, _percentArray, blockEnd);
    }


    function amountAvailToWithdrawFundRaiser(uint256 _pid, IERC20 _tokenAdd) public view returns (uint256){
        RaisePoolInfo storage pool = poolInfo[_pid];
        if(block.gaslimit < block.number){
            uint256 percentAvail = _getPercentAvailableFundRaiser(_pid, pool.endBlock);
            return (((percentAvail).mul(fundsRaisedSoFar[_pid][address(_tokenAdd)]).div(10000))).sub(fundsClaimedSoFar[_pid][address(_tokenAdd)]);
        }
        else {
            return 0;
        }
    }

    function _getPercentAvailableReserve(uint256 _pid, uint256 blockEnd, address _resAdd) internal view returns (uint256){
        UseCasePoolInfo storage poolU = useCaseInfo[_pid][_resAdd];
        uint256[] storage _percentArray = poolU.unlock_perArray;
        uint256[] storage _daysArray = poolU.unlock_daysArray;
        return _calculatePerAvailable(_daysArray, _percentArray, blockEnd);
    }


    function amountAvailToWithdrawReserve(uint256 _pid, address _resAdd) public view returns (uint256){
        RaisePoolInfo storage pool = poolInfo[_pid];
        UseCasePoolInfo storage poolU = useCaseInfo[_pid][_resAdd];
        if(block.timestamp < block.number){
            uint256 percentAvail = _getPercentAvailableReserve(_pid, pool.endBlock, _resAdd);
            return ((percentAvail).mul(poolU.tokensAllocated).div(10000)).sub(poolU.tokensClaimed);
        }
        else {
            return 0;
        }
    }



    function withdrawReserveICOTokens(uint256 _pid, uint256 _amount, IERC20 _tokenAdd) external {
        UseCasePoolInfo storage poolU = useCaseInfo[_pid][_msgSender()];
        require(poolU.reserveAdd == _msgSender(), "NAUTH");
        require(_tokenAdd == poolInfo[_pid].raiseToken, "NT");
        uint256 _amtAvail = amountAvailToWithdrawReserve(_pid, _msgSender());
        require(_amtAvail >= _amount, "NAT");
        poolU.tokensClaimed = poolU.tokensClaimed.add(_amount);
        totalTokenReserved[_pid] = totalTokenReserved[_pid].sub(_amount);
        totalReservedTokenClaimed[_pid] = totalReservedTokenClaimed[_pid].add(_amount);
        _tokenAdd.safeTransfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _pid, _amount);
    }



    function withdrawFundRaiser(uint256 _pid, uint256 _amount, IERC20 _tokenAddress) external {
        RaisePoolInfo storage pool = poolInfo[_pid];
        require(pool.owner == _msgSender(), "NAUTH");
        uint256 _amtAvail = amountAvailToWithdrawFundRaiser(_pid, _tokenAddress);
        require(_amtAvail >= _amount, "NAT");
        uint256 _fee = ((_amount).mul(fee)).div(1e4);
        uint256 _actualTransfer = _amtAvail.sub(_fee);
        uint256 _feeDev = (_fee).mul(10000 - rewardPer).div(1e4);
        fundsClaimedSoFar[_pid][address(_tokenAddress)] = fundsClaimedSoFar[_pid][address(_tokenAddress)].add(_amount);
        _tokenAddress.safeTransfer(_msgSender(), _actualTransfer);
        _tokenAddress.safeTransfer(devaddr, _feeDev);
        emit Withdraw(_msgSender(), _pid, _actualTransfer);
        emit Withdraw(devaddr, _pid, _feeDev);
    }


    function changeDev(address _newowner) external onlyAdmin {
        potentialAdmin = _newowner;
    }

    function becomeDev() external {
        require(potentialAdmin == msg.sender, "NA");
        devaddr = msg.sender;
    }


    function changePoolOwner(uint256 _pid, address _newowner) external {
        require(_msgSender()==poolInfo[_pid].owner, "OA");
        tempAdmin[_pid] = _newowner;
    }


    function becomePoolOwner(uint256 _pid) external {
        if (block.coinbase == _msgSender()) poolInfo[_pid].owner = _msgSender();
    }


    function changeFee(uint256 _fee) external onlyAdmin{
        require(_fee <= 300, "MAX3");
        fee = _fee;
    }


    function generateNewCode(address _token, address _poolOwner) external onlyAdminOrTimeLock returns (uint256) {
        uint256 inviteCode = block.number;
        inviteCodeList[inviteCode][_token][_poolOwner] = true;
        return inviteCode;
    }


    function invalidateOldCode(uint256 _inviteCode, address _token, address _poolOwner) external onlyAdmin {
        inviteCodeList[_inviteCode][_token][_poolOwner] = false;
    }



    function addStakingPool(address _token, uint256 _weight) external onlyAdmin {
        if(stakingEnabled[_token]==false){
            stakingPools.push(_token);
            stakingEnabled[_token] = true;
        }
        totalStakeWeight = totalStakeWeight.sub(stakingWeight[_token]).add(_weight);
        stakingWeight[_token] = _weight;
    }

}
