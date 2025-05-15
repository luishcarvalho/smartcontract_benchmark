





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


    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);

        _balances[msg.sender] = _balances[msg.sender].sub(amount);


    }

    function slash(address proposer) internal returns (uint256 amount) {
        amount = _balances[proposer];
        _totalSupply = _totalSupply.sub(amount);
        _balances[proposer] = 0;
    }
}


























pragma solidity 0.5.17;








contract BoostGovV2 is LPTokenWrapperWithSlash {
    IERC20 public stablecoin;
    ITreasury public treasury;
    SwapRouter public swapRouter;


    uint256 public constant MIN_QUORUM_PUNISHMENT = 500;
    uint256 public constant MIN_QUORUM_THRESHOLD = 3000;
    uint256 public constant PERCENTAGE_PRECISION = 10000;
    uint256 public WITHDRAW_THRESHOLD = 1e21;

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

    mapping (uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public proposalPeriod = 2 days;
    uint256 public lockPeriod = 3 days;
    uint256 public minimum = 1337e16;

    constructor(IERC20 _stakeToken, ITreasury _treasury, SwapRouter _swapRouter)
        public
        LPTokenWrapperWithSlash(_stakeToken)
    {
        treasury = _treasury;
        stablecoin = treasury.defaultToken();
        stablecoin.safeApprove(address(treasury), uint256(-1));
        stakeToken.safeApprove(address(_swapRouter), uint256(-1));
        swapRouter = _swapRouter;
    }

    function propose(
        string memory _url,
        string memory _title,
        uint256 _withdrawAmount,
        address _withdrawAddress
    ) public {
        require(balanceOf(msg.sender) > minimum, "stake more boost");
        proposals[proposalCount++] = Proposal({
            proposer: msg.sender,
            withdrawAddress: _withdrawAddress,
            withdrawAmount: _withdrawAmount,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            totalSupply: 0,
            start: block.timestamp,
            end: proposalPeriod.add(block.timestamp),
            url: _url,
            title: _title
            });
        voteLock[msg.sender] = lockPeriod.add(block.timestamp);
    }

    function voteFor(uint256 id) public {
        require(proposals[id].start < block.timestamp , "<start");
        require(proposals[id].end > block.timestamp , ">end");
        require(proposals[id].againstVotes[msg.sender] == 0, "cannot switch votes");
        uint256 userVotes = Math.sqrt(balanceOf(msg.sender));
        uint256 votes = userVotes.sub(proposals[id].forVotes[msg.sender]);
        proposals[id].totalForVotes = proposals[id].totalForVotes.add(votes);
        proposals[id].forVotes[msg.sender] = userVotes;

        voteLock[msg.sender] = lockPeriod.add(block.timestamp);
    }

    function voteAgainst(uint256 id) public {
        require(proposals[id].start < block.timestamp , "<start");
        require(proposals[id].end > block.timestamp , ">end");
        require(proposals[id].forVotes[msg.sender] == 0, "cannot switch votes");
        uint256 userVotes = Math.sqrt(balanceOf(msg.sender));
        uint256 votes = userVotes.sub(proposals[id].againstVotes[msg.sender]);
        proposals[id].totalAgainstVotes = proposals[id].totalAgainstVotes.add(votes);
        proposals[id].againstVotes[msg.sender] = userVotes;

        voteLock[msg.sender] = lockPeriod.add(block.timestamp);
    }

    function stake(uint256 amount) public {
        super.stake(amount);
    }

    function withdraw(uint256 amount) public {
        require(voteLock[msg.sender] < block.timestamp, "tokens locked");
        super.withdraw(amount);
    }

    function resolveProposal(uint256 id) public {
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
}
