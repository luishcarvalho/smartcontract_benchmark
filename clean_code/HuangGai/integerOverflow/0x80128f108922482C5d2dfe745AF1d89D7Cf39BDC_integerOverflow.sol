





pragma solidity 0.5.17;





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






   function sqrt(uint256 x) internal pure returns (uint256) {
       uint256 n = x / 2;
       uint256 lstX = 0;
       while (n != lstX){
           lstX = n;
           n = (n + x/n) / 2;
       }
       return uint256(n);
   }
}














library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }












    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

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



pragma solidity 0.5.17;












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










contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }




    function isOwner() public view returns (bool) {
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



pragma solidity 0.5.17;





library Address {











    function isContract(address account) internal view returns (bool) {







        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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





pragma solidity 0.5.17;






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



pragma solidity 0.5.17;













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





pragma solidity 0.5.17;


interface IERC20Burnable {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity 0.5.17;



interface ITreasury {
    function defaultToken() external view returns (IERC20);
    function deposit(IERC20 token, uint256 amount) external;
    function withdraw(uint256 amount, address withdrawAddress) external;
}





pragma solidity 0.5.17;


interface SwapRouter {
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts);
}






pragma solidity ^0.5.17;




contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakeToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(IERC20 _stakeToken) public {
        stakeToken = _stakeToken;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);

        _balances[msg.sender] = _balances[msg.sender].add(amount);


    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);

        _balances[msg.sender] = _balances[msg.sender].sub(amount);


    }
}


























pragma solidity 0.5.17;









contract BoostRewardsV2 is LPTokenWrapper, Ownable {
    IERC20 public boostToken;
    ITreasury public treasury;
    SwapRouter public swapRouter;
    IERC20 public stablecoin;

    uint256 public tokenCapAmount;
    uint256 public starttime;
    uint256 public duration;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;



    uint256 public boostedTotalSupply;
    uint256 public lastBoostPurchase;
    mapping(address => uint256) public boostedBalances;
    mapping(address => uint256) public numBoostersBought;
    mapping(address => uint256) public nextBoostPurchaseTime;
    uint256 public globalBoosterPrice = 1e18;
    uint256 public boostThreshold = 10;
    uint256 public boostScaleFactor = 20;
    uint256 public scaleFactor = 320;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);

    modifier checkStart() {
        require(block.timestamp >= starttime,"not start");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(
        uint256 _tokenCapAmount,
        IERC20 _stakeToken,
        IERC20 _boostToken,
        address _treasury,
        SwapRouter _swapRouter,
        uint256 _starttime,
        uint256 _duration
    ) public LPTokenWrapper(_stakeToken) {
        tokenCapAmount = _tokenCapAmount;
        boostToken = _boostToken;
        treasury = ITreasury(_treasury);
        stablecoin = treasury.defaultToken();
        swapRouter = _swapRouter;
        starttime = _starttime;
        lastBoostPurchase = _starttime;
        duration = _duration;
        boostToken.safeApprove(address(_swapRouter), uint256(-1));
        stablecoin.safeApprove(address(treasury), uint256(-1));
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (boostedTotalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(boostedTotalSupply)
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            boostedBalances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getBoosterPrice(address user)
        public view returns (uint256 boosterPrice, uint256 newBoostBalance)
    {
        if (boostedTotalSupply == 0) return (0,0);


        uint256 boostersBought = numBoostersBought[user];
        boosterPrice = globalBoosterPrice.mul(boostersBought.mul(5).add(100)).div(100);


        boostersBought = boostersBought.add(1);


        if (boostersBought >= boostThreshold) {
            boosterPrice = boosterPrice
                .mul((boostersBought.sub(boostThreshold)).mul(boostScaleFactor).add(100))
                .div(100);
        }


        boosterPrice = pow(boosterPrice, 975, 1000, (block.timestamp.sub(lastBoostPurchase)).div(2 hours));



        newBoostBalance = balanceOf(user)
            .mul(boostersBought.mul(5).add(100))
            .div(100);
        uint256 boostBalanceIncrease = newBoostBalance.sub(boostedBalances[user]);
        boosterPrice = boosterPrice
            .mul(boostBalanceIncrease)
            .mul(scaleFactor)
            .div(boostedTotalSupply);
    }


    function stake(uint256 amount) public updateReward(msg.sender) checkStart {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);


        require(
            balanceOf(msg.sender) <= tokenCapAmount || block.timestamp >= starttime.add(86400),
            "token cap exceeded"
        );


        boostedBalances[msg.sender] = boostedBalances[msg.sender].add(amount);

        boostedTotalSupply = boostedTotalSupply.add(amount);


        _getReward(msg.sender);


        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) checkStart {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);


        numBoostersBought[msg.sender] = 0;


        updateBoostBalanceAndSupply(msg.sender, 0);


        (bool success, ) = address(this).call(
            abi.encodeWithSignature(
                "_getReward(address)",
                msg.sender
            )
        );

        success;


        stakeToken.safeTransfer(msg.sender, amount);
    }

    function getReward() public updateReward(msg.sender) checkStart {
        _getReward(msg.sender);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function setScaleFactorsAndThreshold(
        uint256 _boostThreshold,
        uint256 _boostScaleFactor,
        uint256 _scaleFactor
    ) external onlyOwner
    {
        boostThreshold = _boostThreshold;
        boostScaleFactor = _boostScaleFactor;
        scaleFactor = _scaleFactor;
    }

    function boost() external updateReward(msg.sender) checkStart {
        require(
            block.timestamp > nextBoostPurchaseTime[msg.sender],
            "early boost purchase"
        );



        (uint256 boosterAmount, uint256 newBoostBalance) = getBoosterPrice(msg.sender);

        applyBoost(msg.sender, newBoostBalance);

        _getReward(msg.sender);

        boostToken.safeTransferFrom(msg.sender, address(this), boosterAmount);

        IERC20Burnable burnableBoostToken = IERC20Burnable(address(boostToken));


        uint256 burnAmount = boosterAmount.div(4);
        burnableBoostToken.burn(burnAmount);
        boosterAmount = boosterAmount.sub(burnAmount);


        address[] memory routeDetails = new address[](3);
        routeDetails[0] = address(boostToken);
        routeDetails[1] = swapRouter.WETH();
        routeDetails[2] = address(stablecoin);
        uint[] memory amounts = swapRouter.swapExactTokensForTokens(
            boosterAmount,
            0,
            routeDetails,
            address(this),
            block.timestamp + 100
        );



        treasury.deposit(stablecoin, amounts[2]);
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        rewardRate = reward.div(duration);
        lastUpdateTime = starttime;
        periodFinish = starttime.add(duration);
        emit RewardAdded(reward);
    }

    function updateBoostBalanceAndSupply(address user, uint256 newBoostBalance) internal {

        boostedTotalSupply = boostedTotalSupply.sub(boostedBalances[user]);



        if (newBoostBalance == 0) {

            newBoostBalance = balanceOf(user).mul(numBoostersBought[user].mul(5).add(100)).div(100);
        }


        boostedBalances[user] = newBoostBalance;


        boostedTotalSupply = boostedTotalSupply.add(newBoostBalance);
    }

    function applyBoost(address user, uint256 newBoostBalance) internal {

        numBoostersBought[user] = numBoostersBought[user].add(1);

        updateBoostBalanceAndSupply(user, newBoostBalance);


        nextBoostPurchaseTime[user] = block.timestamp.add(3600);


        globalBoosterPrice = globalBoosterPrice.mul(101).div(100);

        lastBoostPurchase = block.timestamp;
    }

    function _getReward(address user) internal {
        uint256 reward = earned(user);
        if (reward > 0) {
            rewards[user] = 0;
            boostToken.safeTransfer(user, reward);
            emit RewardPaid(user, reward);
        }
    }




   function pow(uint256 a, uint256 b, uint256 c, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) {
            return a;
        }
        else if (exponent == 1) {
            return a.mul(b).div(c);
        }
        else if (a == 0 && exponent != 0) {
            return 0;
        }
        else {
            uint256 z = a.mul(b).div(c);
            for (uint256 i = 1; i < exponent; i++)
                z = z.mul(b).div(c);
            return z;
        }
    }
}
