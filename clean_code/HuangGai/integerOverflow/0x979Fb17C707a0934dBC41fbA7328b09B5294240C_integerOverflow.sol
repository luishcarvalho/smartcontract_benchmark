





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


interface IGov {
    function notifyRewardAmount(uint256 amount) external;
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



pragma solidity 0.5.17;




contract LPTokenWrapperWithSlash {
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

        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);

        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        stakeToken.safeTransfer(msg.sender, amount);
    }

    function slash(address proposer) internal returns (uint256 amount) {
        amount = _balances[proposer];
        _totalSupply = _totalSupply.sub(amount);
        _balances[proposer] = 0;
    }
}


























pragma solidity 0.5.17;









contract BoostGovV2 is IGov, LPTokenWrapperWithSlash {
    IERC20 public stablecoin;
    ITreasury public treasury;
    SwapRouter public swapRouter;


    uint256 public constant MIN_QUORUM_PUNISHMENT = 500;
    uint256 public constant MIN_QUORUM_THRESHOLD = 3000;
    uint256 public constant PERCENTAGE_PRECISION = 10000;
    uint256 public constant WITHDRAW_THRESHOLD = 1e21;

    mapping(address => uint256) public voteLock;

    struct Proposal {
        address proposer;
        address withdrawAddress;
        uint256 withdrawAmount;
        mapping(address => uint256) forVotes;
        mapping(address => uint256) againstVotes;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        uint256 totalSupply;
        uint256 start;
        uint256 end;
        string url;
        string title;
    }


    uint256 public constant DURATION = 3 days;
    uint256 public starttime;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    IERC20 public boostToken;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;


    mapping (uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public constant PROPOSAL_PERIOD = 2 days;
    uint256 public constant LOCK_PERIOD = 3 days;
    uint256 public minimum = 1337e16;

    constructor(IERC20 _stakeToken, ITreasury _treasury, SwapRouter _swapRouter)
        public
        LPTokenWrapperWithSlash(_stakeToken)
    {
        boostToken = _stakeToken;
        treasury = _treasury;
        stablecoin = treasury.defaultToken();
        stablecoin.safeApprove(address(treasury), uint256(-1));
        stakeToken.safeApprove(address(_swapRouter), uint256(-1));
        swapRouter = _swapRouter;
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

    function notifyRewardAmount(uint256 reward)
        external
        updateReward(address(0))
    {
        require(msg.sender == address(treasury), "!treasury");
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
    }

    function propose(
        string calldata _url,
        string calldata _title,
        uint256 _withdrawAmount,
        address _withdrawAddress
    ) external {
        require(balanceOf(msg.sender) > minimum, "stake more boost");
        proposals[proposalCount++] = Proposal({
            proposer: msg.sender,
            withdrawAddress: _withdrawAddress,
            withdrawAmount: _withdrawAmount,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            totalSupply: 0,
            start: block.timestamp,
            end: PROPOSAL_PERIOD.add(block.timestamp),
            url: _url,
            title: _title
            });
        voteLock[msg.sender] = LOCK_PERIOD.add(block.timestamp);
        _getReward(msg.sender);
    }

    function voteFor(uint256 id) external updateReward(msg.sender) {
        require(proposals[id].start < block.timestamp , "<start");
        require(proposals[id].end > block.timestamp , ">end");
        require(proposals[id].againstVotes[msg.sender] == 0, "cannot switch votes");
        uint256 userVotes = Math.sqrt(balanceOf(msg.sender));
        uint256 votes = userVotes.sub(proposals[id].forVotes[msg.sender]);
        proposals[id].totalForVotes = proposals[id].totalForVotes.add(votes);
        proposals[id].forVotes[msg.sender] = userVotes;

        voteLock[msg.sender] = LOCK_PERIOD.add(block.timestamp);
        _getReward(msg.sender);
    }

    function voteAgainst(uint256 id) external updateReward(msg.sender) {
        require(proposals[id].start < block.timestamp , "<start");
        require(proposals[id].end > block.timestamp , ">end");
        require(proposals[id].forVotes[msg.sender] == 0, "cannot switch votes");
        uint256 userVotes = Math.sqrt(balanceOf(msg.sender));
        uint256 votes = userVotes.sub(proposals[id].againstVotes[msg.sender]);
        proposals[id].totalAgainstVotes = proposals[id].totalAgainstVotes.add(votes);
        proposals[id].againstVotes[msg.sender] = userVotes;

        voteLock[msg.sender] = LOCK_PERIOD.add(block.timestamp);
        _getReward(msg.sender);
    }

    function stake(uint256 amount) public updateReward(msg.sender) {
        super.stake(amount);
        _getReward(msg.sender);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(voteLock[msg.sender] < block.timestamp, "tokens locked");
        super.withdraw(amount);
    }

    function exit() public updateReward(msg.sender) {
        require(voteLock[msg.sender] < block.timestamp, "tokens locked");
        withdraw(balanceOf(msg.sender));
        _getReward(msg.sender);
    }

    function resolveProposal(uint256 id) public updateReward(msg.sender) {
        require(proposals[id].proposer != address(0), "non-existent proposal");
        require(proposals[id].end < block.timestamp , "ongoing proposal");
        require(proposals[id].totalSupply == 0, "already resolved");


        proposals[id].totalSupply = Math.sqrt(totalSupply());


        uint256 quorum =
            (proposals[id].totalForVotes.add(proposals[id].totalAgainstVotes))
            .mul(PERCENTAGE_PRECISION)
            .div(proposals[id].totalSupply);

        if ((quorum < MIN_QUORUM_PUNISHMENT) && proposals[id].withdrawAmount > WITHDRAW_THRESHOLD) {

            uint256 amount = slash(proposals[id].proposer);
            convertAndSendTreasuryFunds(amount);
        } else if (
            (quorum > MIN_QUORUM_THRESHOLD) &&
            (proposals[id].totalForVotes > proposals[id].totalAgainstVotes)
         ) {

            treasury.withdraw(
                proposals[id].withdrawAmount,
                proposals[id].withdrawAddress
            );
        }
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function convertAndSendTreasuryFunds(uint256 amount) internal {
        address[] memory routeDetails = new address[](3);
        routeDetails[0] = address(stakeToken);
        routeDetails[1] = swapRouter.WETH();
        routeDetails[2] = address(stablecoin);
        uint[] memory amounts = swapRouter.swapExactTokensForTokens(
            amount,
            0,
            routeDetails,
            address(this),
            block.timestamp + 100
        );

        treasury.deposit(stablecoin, amounts[2]);
    }

    function _getReward(address user) internal {
        uint256 reward = earned(user);
        if (reward > 0) {
            rewards[user] = 0;
            boostToken.safeTransfer(user, reward);
        }
    }
}
