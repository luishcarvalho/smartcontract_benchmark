



pragma solidity ^0.7.0;

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




library Address {

















    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }







    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }







    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");


        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }







    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }







    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");


        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {



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




library Math {



    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }




    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }





    function average(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library Arrays {









    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);



            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }


        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () {
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


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;










    constructor (string memory name, string memory symbol) {
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


contract DokiCoinCore is ERC20("DokiDokiFinance", "DOKI") {
    using SafeMath for uint256;

    address internal _taxer;
    address internal _taxDestination;
    uint internal _taxRate = 0;
    mapping (address => bool) internal _taxWhitelist;

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = amount.mul(_taxRate).div(100);
        if (_taxWhitelist[msg.sender] == true) {
            taxAmount = 0;
        }
        uint256 transferAmount = amount.sub(taxAmount);
        require(balanceOf(msg.sender) >= transferAmount, "insufficient balance.");
        super.transfer(recipient, amount);

        if (taxAmount != 0) {
            super.transfer(_taxDestination, taxAmount);
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = amount.mul(_taxRate).div(100);
        if (_taxWhitelist[sender] == true) {
            taxAmount = 0;
        }
        uint256 transferAmount = amount.sub(taxAmount);
        require(balanceOf(sender) >= transferAmount, "insufficient balance.");
        super.transferFrom(sender, recipient, amount);
        if (taxAmount != 0) {
            super.transferFrom(sender, _taxDestination, taxAmount);
        }
        return true;
    }
}

contract DokiCoin is DokiCoinCore, Ownable {
    mapping (address => bool) internal minters;

    constructor() {
        _taxer = owner();
        _taxDestination = owner();
    }

    function mint(address to, uint amount) public onlyMinter {
        _mint(to, amount);
    }

    function burn(uint amount) public {
        require(amount > 0);
        require(balanceOf(msg.sender) >= amount);
        _burn(msg.sender, amount);
    }

    function addMinter(address account) public onlyOwner {
        minters[account] = true;
    }

    function removeMinter(address account) public onlyOwner {
        minters[account] = false;
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Restricted to minters.");
        _;
    }

    modifier onlyTaxer() {
        require(msg.sender == _taxer, "Only for taxer.");
        _;
    }

    function setTaxer(address account) public onlyTaxer {
        _taxer = account;
    }

    function setTaxRate(uint256 rate) public onlyTaxer {
        _taxRate = rate;
    }

    function setTaxDestination(address account) public onlyTaxer {
        _taxDestination = account;
    }

    function addToWhitelist(address account) public onlyTaxer {
        _taxWhitelist[account] = true;
    }

    function removeFromWhitelist(address account) public onlyTaxer {
        _taxWhitelist[account] = false;
    }

    function taxer() public view returns(address) {
        return _taxer;
    }

    function taxDestination() public view returns(address) {
        return _taxDestination;
    }

    function taxRate() public view returns(uint256) {
        return _taxRate;
    }

    function isInWhitelist(address account) public view returns(bool) {
        return _taxWhitelist[account];
    }
}


contract LPToDOKI is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for DokiCoin;
    using SafeERC20 for IERC20;
    using Address for address;

    DokiCoin private doki;
    IERC20 private lpToken;


    mapping(address => uint256) private _lpBalances;
    uint private _lpTotalSupply;


    uint256 internal constant DURATION = 2 weeks;

    uint256 internal initReward = 500 * 1e18;
    bool internal haveStarted = false;

    uint256 internal halvingTime = 0;
    uint256 internal lastUpdateTime = 0;

    uint256 internal rewardRate = 0;
    uint256 internal rewardPerLPToken = 0;
    mapping(address => uint256) private rewards;
    mapping(address => uint256) private userRewardPerTokenPaid;



    address internal devAddr;
    uint256 internal devDistributeRate = 0;
    uint256 internal lastDistributeTime = 0;
    uint256 internal devFinishTime = 0;
    uint256 internal devFundAmount = 90 * 1e18;
    uint256 internal devDistributeDuration = 180 days;

    event Stake(address indexed from, uint amount);
    event Withdraw(address indexed to, uint amount);
    event Claim(address indexed to, uint amount);
    event Halving(uint amount);
    event Start(uint amount);

    constructor(address _doki, address _lpToken) {
        doki = DokiCoin(_doki);
        lpToken = IERC20(_lpToken);
        devAddr = owner();
    }

    function totalSupply() public view returns(uint256) {
        return _lpTotalSupply;
    }

    function balanceOf(address account) public view returns(uint256) {
        return _lpBalances[account];
    }

    function stake(uint amount) public shouldStarted {
        updateRewards(msg.sender);
        checkHalving();
        require(!address(msg.sender).isContract(), "Please use your individual account.");
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
        _lpTotalSupply = _lpTotalSupply.add(amount);
        _lpBalances[msg.sender] = _lpBalances[msg.sender].add(amount);
        distributeDevFund();
        emit Stake(msg.sender, amount);
    }

    function withdraw(uint amount) public shouldStarted {
        updateRewards(msg.sender);
        checkHalving();
        require(amount <= _lpBalances[msg.sender] && _lpBalances[msg.sender] > 0, "Bad withdraw.");
        lpToken.safeTransfer(msg.sender, amount);
        _lpTotalSupply = _lpTotalSupply.sub(amount);
        _lpBalances[msg.sender] = _lpBalances[msg.sender].sub(amount);
        distributeDevFund();
        emit Withdraw(msg.sender, amount);
    }

    function claim(uint amount) public shouldStarted {
        updateRewards(msg.sender);
        checkHalving();
        require(amount <= rewards[msg.sender] && rewards[msg.sender] > 0, "Bad claim.");
        rewards[msg.sender] = rewards[msg.sender].sub(amount);
        doki.safeTransfer(msg.sender, amount);
        distributeDevFund();
        emit Claim(msg.sender, amount);
    }

    function checkHalving() internal {
        if (block.timestamp >= halvingTime) {
            initReward = initReward.mul(50).div(100);
            doki.mint(address(this), initReward);

            rewardRate = initReward.div(DURATION);
            halvingTime = halvingTime.add(DURATION);

            updateRewards(msg.sender);
            emit Halving(initReward);
        }
    }

    modifier shouldStarted() {
        require(haveStarted == true, "Have not started.");
        _;
    }

    function getRewardsAmount(address account) public view returns(uint256) {
        return balanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e8)
                .add(rewards[account]);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_lpTotalSupply == 0) {
            return rewardPerLPToken;
        }
        return rewardPerLPToken
            .add(Math.min(block.timestamp, halvingTime)
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e8)
                    .div(_lpTotalSupply)
            );
    }

    function updateRewards(address account) internal {
        rewardPerLPToken = rewardPerToken();
        lastUpdateTime = lastRewardTime();
        if (account != address(0)) {
            rewards[account] = getRewardsAmount(account);
            userRewardPerTokenPaid[account] = rewardPerLPToken;
        }
    }

    function lastRewardTime() public view returns (uint256) {
        return Math.min(block.timestamp, halvingTime);
    }

    function startFarming() external onlyOwner {
        updateRewards(address(0));
        rewardRate = initReward.div(DURATION);

        uint256 mintAmount = initReward.add(devFundAmount);
        doki.mint(address(this), mintAmount);
        devDistributeRate = devFundAmount.div(devDistributeDuration);
        devFinishTime = block.timestamp.add(devDistributeDuration);

        lastUpdateTime = block.timestamp;
        lastDistributeTime = block.timestamp;
        halvingTime = block.timestamp.add(DURATION);

        haveStarted = true;
        emit Start(mintAmount);
    }

    function transferDevAddr(address newAddr) public onlyDev {
        require(newAddr != address(0), "zero addr");
        devAddr = newAddr;
    }

    function distributeDevFund() internal {
        uint256 nowTime = Math.min(block.timestamp, devFinishTime);
        uint256 fundAmount = nowTime.sub(lastDistributeTime).mul(devDistributeRate);
        doki.safeTransfer(devAddr, fundAmount);
        lastDistributeTime = nowTime;
    }

    modifier onlyDev() {
        require(msg.sender == devAddr, "This is only for dev.");
        _;
    }
}
