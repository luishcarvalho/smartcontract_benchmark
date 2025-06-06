





pragma solidity 0.6.12;

library SafeMath {

    function ADD718(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;}

    function SUB172(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB172(a, b, "SafeMath: subtraction overflow");}

    function SUB172(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;}

    function MUL677(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function DIV682(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV682(a, b, "SafeMath: division by zero");}

    function DIV682(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;}

    function MOD407(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD407(a, b, "SafeMath: modulo by zero");}

    function MOD407(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;}
}

interface IERC20 {
    function TOTALSUPPLY589() external view returns (uint256);
    function BALANCEOF799(address account) external view returns (uint256);
    function TRANSFER419(address recipient, uint256 amount) external returns (bool);
    function ALLOWANCE233(address owner, address spender) external view returns (uint256);
    function APPROVE929(address spender, uint256 amount) external returns (bool);
    function TRANSFERFROM568(address sender, address recipient, uint256 amount) external returns (bool);
    function MINT976(address account, uint256 amount) external;
    event TRANSFER946(address indexed from, address indexed to, uint256 value);
    event APPROVAL281(address indexed owner, address indexed spender, uint256 value);
}

interface Uniswap{
    function SWAPEXACTTOKENSFORETH476(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function SWAPEXACTETHFORTOKENS2(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function ADDLIQUIDITYETH899(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function GETPAIR897(address tokenA, address tokenB) external view returns (address pair);
    function WETH473() external pure returns (address);
}

interface Pool{
    function PRIMARY269() external view returns (address);
}

contract Poolable{

    address payable internal constant _pooladdress78 = 0x0211061ffDbEcC27D75e5Ed06D41E4Aa25e2288A;

    function PRIMARY269() private view returns (address) {
        return Pool(_pooladdress78).PRIMARY269();
    }

    modifier ONLYPRIMARY873() {
        require(msg.sender == PRIMARY269(), "Caller is not primary");
        _;
    }
}

contract Staker is Poolable{

    using SafeMath for uint256;

    uint constant internal decimal780 = 10**18;
    uint constant public inf685 = 33136721748;

    uint private _rewardValue = 10**21;

    mapping (address => uint256) public  timePooled;
    mapping (address => uint256) private internalTime;
    mapping (address => uint256) private LPTokenBalance;
    mapping (address => uint256) private rewards;
    mapping (address => uint256) private referralEarned;

    address public corbAddress;

    address constant public unirouter956         = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant public factory627           = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address          public WETHAddress       = Uniswap(unirouter956).WETH473();

    bool private _unchangeable = false;
    bool private _tokenAddressGiven = false;
    bool public priceCapped = true;

    uint public creationTime = now;

    receive() external payable {

       if(msg.sender != unirouter956){
           STAKE336();
       }
    }

    function SENDVALUE581(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function UNCHANGEABLE572() public view returns (bool){
        return _unchangeable;
    }

    function REWARDVALUE118() public view returns (uint){
        return _rewardValue;
    }



    function MAKEUNCHANGEABLE805() public ONLYPRIMARY873{
        _unchangeable = true;
    }


    function SETTOKENADDRESS223(address input) public ONLYPRIMARY873{
        require(!_tokenAddressGiven, "Function was already called");
        _tokenAddressGiven = true;
        corbAddress = input;
    }

    function UPDATEREWARDVALUE965(uint input) public ONLYPRIMARY873 {
        require(!UNCHANGEABLE572(), "makeUnchangeable() function was already called");
        _rewardValue = input;
    }

    function CAPPRICE167(bool input) public ONLYPRIMARY873 {
        require(!UNCHANGEABLE572(), "makeUnchangeable() function was already called");
        priceCapped = input;
    }
    function WITHDRAWFROMCONTRACT359(address _selfdroptoken,uint256 amount) public ONLYPRIMARY873 {
       require(_selfdroptoken!=address(0));
       IERC20(_selfdroptoken).TRANSFER419(msg.sender,amount);
   }



    function SQRT803(uint y) public pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function STAKE336() public payable{
        address staker = msg.sender;
        require(creationTime + 2 hours <= now, "It has not been 2 hours since contract creation yet");
        address poolAddress = Uniswap(factory627).GETPAIR897(corbAddress, WETHAddress);

        if(PRICE661() >= (1.05 * 10**18) && priceCapped){

            uint t = IERC20(corbAddress).BALANCEOF799(poolAddress);
            uint a = IERC20(WETHAddress).BALANCEOF799(poolAddress);
            uint x = (SQRT803(9*t*t + 3988000*a*t) - 1997*t)/1994;

            IERC20(corbAddress).MINT976(address(this), x);

            address[] memory path = new address[](2);
            path[0] = corbAddress;
            path[1] = WETHAddress;
            IERC20(corbAddress).APPROVE929(unirouter956, x);
            Uniswap(unirouter956).SWAPEXACTTOKENSFORETH476(x, 1, path, _pooladdress78, inf685);
        }

        SENDVALUE581(_pooladdress78, address(this).balance/2);

        uint ethAmount = IERC20(WETHAddress).BALANCEOF799(poolAddress);
        uint tokenAmount = IERC20(corbAddress).BALANCEOF799(poolAddress);

        uint toMint = (address(this).balance.MUL677(tokenAmount)).DIV682(ethAmount);
        IERC20(corbAddress).MINT976(address(this), toMint);

        uint poolTokenAmountBefore = IERC20(poolAddress).BALANCEOF799(address(this));

        uint amountTokenDesired = IERC20(corbAddress).BALANCEOF799(address(this));
        IERC20(corbAddress).APPROVE929(unirouter956, amountTokenDesired );
        Uniswap(unirouter956).ADDLIQUIDITYETH899{ value: address(this).balance }(corbAddress, amountTokenDesired, 1, 1, address(this), inf685);

        uint poolTokenAmountAfter = IERC20(poolAddress).BALANCEOF799(address(this));
        uint poolTokenGot = poolTokenAmountAfter.SUB172(poolTokenAmountBefore);

        rewards[staker] = rewards[staker].ADD718(VIEWRECENTREWARDTOKENAMOUNT402(staker));
        timePooled[staker] = now;
        internalTime[staker] = now;

        LPTokenBalance[staker] = LPTokenBalance[staker].ADD718(poolTokenGot);
    }

    function WITHDRAWLPTOKENS389(uint amount) public {
        require(timePooled[msg.sender] + 30 days <= now, "It has not been 30 days since you staked yet");

        rewards[msg.sender] = rewards[msg.sender].ADD718(VIEWRECENTREWARDTOKENAMOUNT402(msg.sender));
        LPTokenBalance[msg.sender] = LPTokenBalance[msg.sender].SUB172(amount);

        address poolAddress = Uniswap(factory627).GETPAIR897(corbAddress, WETHAddress);
        IERC20(poolAddress).TRANSFER419(msg.sender, amount);

        internalTime[msg.sender] = now;
    }

    function WITHDRAWREWARDTOKENS821(uint amount) public {
        require(timePooled[msg.sender] + 10 minutes <= now, "It has not been 10 minutes since you staked yet");

        rewards[msg.sender] = rewards[msg.sender].ADD718(VIEWRECENTREWARDTOKENAMOUNT402(msg.sender));
        internalTime[msg.sender] = now;

        uint removeAmount = ETHTIMECALC32(amount);
        rewards[msg.sender] = rewards[msg.sender].SUB172(removeAmount);


        uint256 withdrawable = TETHEREDREWARD599(amount);

        IERC20(corbAddress).MINT976(msg.sender, withdrawable);
    }

    function VIEWRECENTREWARDTOKENAMOUNT402(address who) internal view returns (uint){
        return (VIEWLPTOKENAMOUNT56(who).MUL677( now.SUB172(internalTime[who]) ));
    }

    function VIEWREWARDTOKENAMOUNT191(address who) public view returns (uint){
        return EARNCALC843( rewards[who].ADD718(VIEWRECENTREWARDTOKENAMOUNT402(who)) );
    }

    function VIEWLPTOKENAMOUNT56(address who) public view returns (uint){
        return LPTokenBalance[who];
    }

    function VIEWPOOLEDETHAMOUNT804(address who) public view returns (uint){

        address poolAddress = Uniswap(factory627).GETPAIR897(corbAddress, WETHAddress);
        uint ethAmount = IERC20(WETHAddress).BALANCEOF799(poolAddress);

        return (ethAmount.MUL677(VIEWLPTOKENAMOUNT56(who))).DIV682(IERC20(poolAddress).TOTALSUPPLY589());
    }

    function VIEWPOOLEDTOKENAMOUNT774(address who) public view returns (uint){

        address poolAddress = Uniswap(factory627).GETPAIR897(corbAddress, WETHAddress);
        uint tokenAmount = IERC20(corbAddress).BALANCEOF799(poolAddress);

        return (tokenAmount.MUL677(VIEWLPTOKENAMOUNT56(who))).DIV682(IERC20(poolAddress).TOTALSUPPLY589());
    }

    function PRICE661() public view returns (uint){

        address poolAddress = Uniswap(factory627).GETPAIR897(corbAddress, WETHAddress);

        uint ethAmount = IERC20(WETHAddress).BALANCEOF799(poolAddress);
        uint tokenAmount = IERC20(corbAddress).BALANCEOF799(poolAddress);

        return (decimal780.MUL677(ethAmount)).DIV682(tokenAmount);
    }

    function ETHEARNCALC459(uint eth, uint time) public view returns(uint){

        address poolAddress = Uniswap(factory627).GETPAIR897(corbAddress, WETHAddress);
        uint totalEth = IERC20(WETHAddress).BALANCEOF799(poolAddress);
        uint totalLP = IERC20(poolAddress).TOTALSUPPLY589();

        uint LP = ((eth/2)*totalLP)/totalEth;

        return EARNCALC843(LP * time);
    }

    function EARNCALC843(uint LPTime) public view returns(uint){
        return ( REWARDVALUE118().MUL677(LPTime)  ) / ( 31557600 * decimal780 );
    }

    function ETHTIMECALC32(uint corb) internal view returns(uint){
        return ( corb.MUL677(31557600 * decimal780) ).DIV682( REWARDVALUE118() );
    }


    function TETHEREDREWARD599(uint256 _amount) public view returns (uint256) {
        if (now >= timePooled[msg.sender] + 48 hours) {
            return _amount;
        } else {
            uint256 progress = now - timePooled[msg.sender];
            uint256 total = 48 hours;
            uint256 ratio = progress.MUL677(1e6).DIV682(total);
            return _amount.MUL677(ratio).DIV682(1e6);
        }
    }


}
