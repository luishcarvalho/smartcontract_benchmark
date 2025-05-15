








pragma solidity 0.6.0;














library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


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

























abstract contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;










    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract Token is Ownable, ERC20 {
    using SafeMath for uint256;

    event Staked(
        address lpToken,
        address user,
        uint256 amount
    );

    event Unstaked(
        address user,
        address lpToken,
        uint256 amount
    );

    event RewardWithdrawn(
        address user,
        uint256 amount
    );

    uint256 private constant rewardMultiplier = 1e17;

    struct Stake {
        mapping(address => uint256) lpToStakeAmount;
        uint256 totalStakedAmountByUser;
        uint256 lastInteractionBlockNumber;
        address[] lpTokens;
    }

    mapping(address => Stake) public userToStakes;
    uint256 public totalStakedAmount;
    IUniswapV2Factory public uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    struct TokenStake {
        uint256 amount;
        uint256 lastInteractionTimestamp;
        uint256 stakingPeriodEndTime;
        uint256 rate;
    }

    mapping(address => TokenStake) public userToTokenStakes;

    struct Lockup {
        uint256 duration;
        uint256 rate;
    }
    Lockup[8] public lockupPeriods;

    IERC20 public swapToken = IERC20(0xEEd2B7756E295A9300e53dD049AeB0751899BAe3);
    uint256 public swapTokenDecimals = 18;
    address public swapTreasury = 0x4eFfA0933a1099b8F95E34964c36Dfd9b7B1A49a;

    uint256 public totalTokensStakedAmount;

    uint256 public blockMiningTime = 15;
    uint256 public constant MAX_SUPPLY = 6000000 * 10 ** 18;

    constructor() public ERC20("TokenBot", "TKB", 18) {


        lockupPeriods[0] = Lockup(604800, 1e15);
        lockupPeriods[1] = Lockup(2592000, 4e15);
        lockupPeriods[2] = Lockup(5184000, 8e15);
        lockupPeriods[3] = Lockup(7776000, 12e15);
        lockupPeriods[4] = Lockup(15552000, 24e15);
        lockupPeriods[5] = Lockup(31104000, 48e15);
        lockupPeriods[6] = Lockup(63113904, 96e15);
        lockupPeriods[7] = Lockup(126227808, 192e15);
    }

    function changeBlockMiningTime(uint256 newTime) external onlyOwner {
        require(
            newTime != 0,
            "new time cannot be zero"
        );
        blockMiningTime = newTime;
    }

    function swapAndStakeDOG(
        uint256 swapTokenAmount
    ) external {
        require(
            swapTokenAmount != 0,
            "swapTokenAmount should be greater than 0"
        );

        require(
            swapToken.transferFrom(_msgSender(), swapTreasury, swapTokenAmount),
            "#transferFrom failed"
        );

        uint256 tokensReceived = swapTokenAmount.mul(10 ** uint256(decimals()))
            .div(250 * 10 ** swapTokenDecimals);
        _mint(_msgSender(), tokensReceived);

        stakeTKB(tokensReceived, 0);
    }

    function stakeTKB(
        uint256 stakeAmount,
        uint256 lockUpPeriodIdx
    ) public {
        require(
            stakeAmount != 0,
            "stakeAmount should be greater than 0"
        );

        require(
            lockUpPeriodIdx <= 7,
            "lock lockUpPeriodIdx should be between 0 and 7"
        );

        TokenStake storage currentStake = userToTokenStakes[_msgSender()];
        require(
            currentStake.amount == 0,
            "address has already staked"
        );

        currentStake.amount = stakeAmount;

        currentStake.stakingPeriodEndTime = block.timestamp.add(
            lockupPeriods[lockUpPeriodIdx].duration
        );

        currentStake.rate = lockupPeriods[lockUpPeriodIdx].rate;

        currentStake.lastInteractionTimestamp = block.timestamp;
        totalTokensStakedAmount = totalTokensStakedAmount.add(stakeAmount);


        _transfer(_msgSender(), address(this), stakeAmount);

        emit Staked(
            address(this),
            msg.sender,
            stakeAmount
        );
    }

    function unstakeTKB() external {
        uint256 amountToUnstake = userToTokenStakes[_msgSender()].amount;
        bool executeUnstaking;

        if (amountToUnstake != 0) {
            if (userToTokenStakes[_msgSender()].stakingPeriodEndTime <= block.timestamp) {
                executeUnstaking = true;
            }

            if (totalSupply() == MAX_SUPPLY) {
                executeUnstaking = true;
            }
        }
        require(
            executeUnstaking,
            "cannot unstake"
        );
        _withdrawRewardTKB(_msgSender());
        totalTokensStakedAmount = totalTokensStakedAmount.sub(amountToUnstake);
        delete userToTokenStakes[_msgSender()];
        _transfer(address(this), _msgSender(), amountToUnstake);

        emit Unstaked(address(this), _msgSender(), amountToUnstake);
    }

    function withdrawRewardTKB() external {
        _withdrawRewardTKB(_msgSender());
    }

    function getTKBRewardByAddress(address user) public view returns(uint256) {
        TokenStake storage currentStake = userToTokenStakes[user];

        uint256 secondsElapsed;
        if (block.timestamp > currentStake.stakingPeriodEndTime) {
            if (currentStake.stakingPeriodEndTime < currentStake.lastInteractionTimestamp) {
                return 0;
            }
            secondsElapsed = currentStake.stakingPeriodEndTime
                .sub(currentStake.lastInteractionTimestamp);
        } else {
            secondsElapsed = block.timestamp
                .sub(currentStake.lastInteractionTimestamp);
        }

        uint256 stakeAmount = currentStake.amount;
        uint256 blockCountElapsed = secondsElapsed.div(blockMiningTime);

        if (blockCountElapsed == 0 || stakeAmount == 0) {
            return 0;
        }

        return currentStake.rate
            .mul(blockCountElapsed)
            .mul(stakeAmount)
            .div(totalTokensStakedAmount);
    }

    function _withdrawRewardTKB(address user) internal {
        uint256 rewardAmount = getTKBRewardByAddress(user);
        if (rewardAmount != 0) {
            _mint(_msgSender(), rewardAmount);
            emit RewardWithdrawn(user, rewardAmount);
        }
        userToTokenStakes[_msgSender()].lastInteractionTimestamp = block.timestamp;
    }

    function stakeLP(
        uint256 stakeAmount
    ) external {
        require(
            stakeAmount != 0,
            "stakeAmount should be greater than 0"
        );




        address lpToken = uniswapFactory.getPair(
            address(this),
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        );

        _withdrawRewardLP(_msgSender());

        totalStakedAmount = totalStakedAmount.add(stakeAmount);


        Stake storage currentStake = userToStakes[_msgSender()];
        uint256 oldStakeAmountByLP = currentStake.lpToStakeAmount[lpToken];

        if (oldStakeAmountByLP == 0) {
            currentStake.lpTokens.push(lpToken);
        }

        currentStake.lpToStakeAmount[lpToken] = oldStakeAmountByLP
            .add(stakeAmount);


        currentStake.totalStakedAmountByUser = currentStake.totalStakedAmountByUser
            .add(stakeAmount);


        require(
            IERC20(lpToken).transferFrom(_msgSender(), address(this), stakeAmount),
            "#transferFrom failed"
        );

        emit Staked(
            lpToken,
            msg.sender,
            stakeAmount
        );
    }

    function unstakeLP(
        address[] calldata lpTokens
    ) external {
        _withdrawRewardLP(_msgSender());
        Stake storage currentStake = userToStakes[_msgSender()];
        address[] storage tokens = currentStake.lpTokens;
        uint256 stakeAmountToDeduct;


        for (uint256 i; i < lpTokens.length; i++) {
            uint256 stakeAmount = currentStake.lpToStakeAmount[
                lpTokens[i]
            ];

            if (stakeAmount == 0) {
                revert("unstaking an invalid LP token");
            }

            delete currentStake.lpToStakeAmount[
                lpTokens[i]
            ];

            currentStake.totalStakedAmountByUser = currentStake.totalStakedAmountByUser
                .sub(stakeAmount);

            stakeAmountToDeduct = stakeAmountToDeduct.add(stakeAmount);

            for (uint256 p; p < tokens.length; p++) {
                if (lpTokens[i] == tokens[p]) {
                    tokens[p] = tokens[tokens.length - 1];
                    tokens.pop();
                }
            }

            require(
                IERC20(lpTokens[i]).transfer(_msgSender(), stakeAmount),
                "#transfer failed"
            );

            emit Unstaked(lpTokens[i], _msgSender(), stakeAmount);
        }

        totalStakedAmount = totalStakedAmount.sub(stakeAmountToDeduct);
    }

    function withdrawRewardLP() external {
        _withdrawRewardLP(_msgSender());
    }

    function getBlockCountSinceLastIntreraction(address user) public view returns(uint256) {
        uint256 lastInteractionBlockNum = userToStakes[user].lastInteractionBlockNumber;
        if (lastInteractionBlockNum == 0) {
            return 0;
        }

        return block.number.sub(lastInteractionBlockNum);
    }

    function getTotalStakeAmountByUser(address user) public view returns(uint256) {
        return userToStakes[user].totalStakedAmountByUser;
    }

    function getAllLPsByUser(address user) public view returns(address[] memory) {
        return userToStakes[user].lpTokens;
    }

    function getStakeAmountByUserByLP(
        address lp,
        address user
    ) public view returns(uint256) {
        return userToStakes[user].lpToStakeAmount[lp];
    }

    function getLPRewardByAddress(
        address user
    ) public view returns(uint256) {
        if (totalStakedAmount == 0) {
            return 0;
        }

        Stake storage currentStake = userToStakes[user];

        uint256 blockCount = block.number
            .sub(currentStake.lastInteractionBlockNumber);

        uint256 totalReward = blockCount.mul(rewardMultiplier);

        return totalReward
            .mul(currentStake.totalStakedAmountByUser)
            .div(totalStakedAmount);
    }

    function _withdrawRewardLP(address user) internal {
        uint256 rewardAmount = getLPRewardByAddress(user);

        if (rewardAmount != 0) {
            _mint(user, rewardAmount);
            emit RewardWithdrawn(user, rewardAmount);
        }

        userToStakes[user].lastInteractionBlockNumber = block.number;
    }

    function _mint(address account, uint256 amount) internal override {
        require(
            totalSupply().add(amount) <= MAX_SUPPLY,
            "total supply exceeds max supply"
        );
        super._mint(account, amount);
    }
}
