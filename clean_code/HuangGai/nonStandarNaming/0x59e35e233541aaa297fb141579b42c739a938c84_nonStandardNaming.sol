





pragma solidity 0.6.12;

library SafeMath {

    function ADD795(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;}

    function SUB56(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB56(a, b, "SafeMath: subtraction overflow");}

    function SUB56(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;}

    function MUL251(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function DIV611(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV611(a, b, "SafeMath: division by zero");}

    function DIV611(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;}

    function MOD125(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD125(a, b, "SafeMath: modulo by zero");}

    function MOD125(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;}
}

interface IERC20 {
    function TOTALSUPPLY425() external view returns (uint256);
    function BALANCEOF918(address account) external view returns (uint256);
    function TRANSFER435(address recipient, uint256 amount) external returns (bool);
    function ALLOWANCE36(address owner, address spender) external view returns (uint256);
    function APPROVE341(address spender, uint256 amount) external returns (bool);
    function TRANSFERFROM704(address sender, address recipient, uint256 amount) external returns (bool);
    function MINT855(address account, uint256 amount) external;
    event TRANSFER626(address indexed from, address indexed to, uint256 value);
    event APPROVAL806(address indexed owner, address indexed spender, uint256 value);
}

interface Uniswap{
    function SWAPEXACTTOKENSFORETH978(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function SWAPEXACTETHFORTOKENS263(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function ADDLIQUIDITYETH819(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function GETPAIR333(address tokenA, address tokenB) external view returns (address pair);
    function WETH77() external pure returns (address);
}

interface Pool{
    function PRIMARY937() external view returns (address);
}

contract Poolable{

    address payable internal constant _pooladdress58 = 0x1E2F5Ed20111f01583acDab2d6a7a90A200533F6;

    function PRIMARY937() private view returns (address) {
        return Pool(_pooladdress58).PRIMARY937();
    }

    modifier ONLYPRIMARY985() {
        require(msg.sender == PRIMARY937(), "Caller is not primary");
        _;
    }
}

contract Staker is Poolable{

    using SafeMath for uint256;

    uint constant internal decimal633 = 10**18;
    uint constant public inf834 = 33136721748;

    uint private _rewardValue = 10**21;

    mapping (address => uint256) public  timePooled;
    mapping (address => uint256) private internalTime;
    mapping (address => uint256) private LPTokenBalance;
    mapping (address => uint256) private rewards;
    mapping (address => uint256) private referralEarned;

    address public orbAddress;

    address constant public unirouter39         = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant public factory303           = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address          public WETHAddress       = Uniswap(unirouter39).WETH77();

    bool private _unchangeable = false;
    bool private _tokenAddressGiven = false;
    bool public priceCapped = true;

    uint public creationTime = now;

    receive() external payable {

       if(msg.sender != unirouter39){
           STAKE884();
       }
    }

    function SENDVALUE395(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function UNCHANGEABLE822() public view returns (bool){
        return _unchangeable;
    }

    function REWARDVALUE484() public view returns (uint){
        return _rewardValue;
    }



    function MAKEUNCHANGEABLE98() public ONLYPRIMARY985{
        _unchangeable = true;
    }


    function SETTOKENADDRESS769(address input) public ONLYPRIMARY985{
        require(!_tokenAddressGiven, "Function was already called");
        _tokenAddressGiven = true;
        orbAddress = input;
    }


    function UPDATEREWARDVALUE773(uint input) public ONLYPRIMARY985 {
        require(!UNCHANGEABLE822(), "makeUnchangeable() function was already called");
        _rewardValue = input;
    }

    function CAPPRICE267(bool input) public ONLYPRIMARY985 {
        require(!UNCHANGEABLE822(), "makeUnchangeable() function was already called");
        priceCapped = input;
    }


    function SQRT504(uint y) public pure returns (uint z) {
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

    function STAKE884() public payable{
        address staker = msg.sender;
        require(creationTime + 1 hours <= now, "It has not been 1 hours since contract creation yet");
        address poolAddress = Uniswap(factory303).GETPAIR333(orbAddress, WETHAddress);

        if(PRICE264() >= (1.05 * 10**18) && priceCapped){

            uint t = IERC20(orbAddress).BALANCEOF918(poolAddress);
            uint a = IERC20(WETHAddress).BALANCEOF918(poolAddress);
            uint x = (SQRT504(9*t*t + 3988000*a*t) - 1997*t)/1994;

            IERC20(orbAddress).MINT855(address(this), x);

            address[] memory path = new address[](2);
            path[0] = orbAddress;
            path[1] = WETHAddress;
            IERC20(orbAddress).APPROVE341(unirouter39, x);
            Uniswap(unirouter39).SWAPEXACTTOKENSFORETH978(x, 1, path, _pooladdress58, inf834);
        }

        SENDVALUE395(_pooladdress58, address(this).balance/2);

        uint ethAmount = IERC20(WETHAddress).BALANCEOF918(poolAddress);
        uint tokenAmount = IERC20(orbAddress).BALANCEOF918(poolAddress);

        uint toMint = (address(this).balance.MUL251(tokenAmount)).DIV611(ethAmount);
        IERC20(orbAddress).MINT855(address(this), toMint);

        uint poolTokenAmountBefore = IERC20(poolAddress).BALANCEOF918(address(this));

        uint amountTokenDesired = IERC20(orbAddress).BALANCEOF918(address(this));
        IERC20(orbAddress).APPROVE341(unirouter39, amountTokenDesired );
        Uniswap(unirouter39).ADDLIQUIDITYETH819{ value: address(this).balance }(orbAddress, amountTokenDesired, 1, 1, address(this), inf834);

        uint poolTokenAmountAfter = IERC20(poolAddress).BALANCEOF918(address(this));
        uint poolTokenGot = poolTokenAmountAfter.SUB56(poolTokenAmountBefore);

        rewards[staker] = rewards[staker].ADD795(VIEWRECENTREWARDTOKENAMOUNT294(staker));
        timePooled[staker] = now;
        internalTime[staker] = now;

        LPTokenBalance[staker] = LPTokenBalance[staker].ADD795(poolTokenGot);
    }

    function WITHDRAWLPTOKENS630(uint amount) public {
        require(timePooled[msg.sender] + 8 hours <= now, "It has not been 8 hours since you staked yet");

        rewards[msg.sender] = rewards[msg.sender].ADD795(VIEWRECENTREWARDTOKENAMOUNT294(msg.sender));
        LPTokenBalance[msg.sender] = LPTokenBalance[msg.sender].SUB56(amount);

        address poolAddress = Uniswap(factory303).GETPAIR333(orbAddress, WETHAddress);
        IERC20(poolAddress).TRANSFER435(msg.sender, amount);

        internalTime[msg.sender] = now;
    }

    function WITHDRAWREWARDTOKENS569(uint amount) public {
        require(timePooled[msg.sender] + 8 hours <= now, "It has not been 8 hours since you staked yet");

        rewards[msg.sender] = rewards[msg.sender].ADD795(VIEWRECENTREWARDTOKENAMOUNT294(msg.sender));
        internalTime[msg.sender] = now;

        uint removeAmount = ETHTIMECALC471(amount);
        rewards[msg.sender] = rewards[msg.sender].SUB56(removeAmount);

        IERC20(orbAddress).MINT855(msg.sender, amount);
    }

    function VIEWRECENTREWARDTOKENAMOUNT294(address who) internal view returns (uint){
        return (VIEWLPTOKENAMOUNT945(who).MUL251( now.SUB56(internalTime[who]) ));
    }

    function VIEWREWARDTOKENAMOUNT832(address who) public view returns (uint){
        return EARNCALC965( rewards[who].ADD795(VIEWRECENTREWARDTOKENAMOUNT294(who)) );
    }

    function VIEWLPTOKENAMOUNT945(address who) public view returns (uint){
        return LPTokenBalance[who];
    }

    function VIEWPOOLEDETHAMOUNT610(address who) public view returns (uint){

        address poolAddress = Uniswap(factory303).GETPAIR333(orbAddress, WETHAddress);
        uint ethAmount = IERC20(WETHAddress).BALANCEOF918(poolAddress);

        return (ethAmount.MUL251(VIEWLPTOKENAMOUNT945(who))).DIV611(IERC20(poolAddress).TOTALSUPPLY425());
    }

    function VIEWPOOLEDTOKENAMOUNT183(address who) public view returns (uint){

        address poolAddress = Uniswap(factory303).GETPAIR333(orbAddress, WETHAddress);
        uint tokenAmount = IERC20(orbAddress).BALANCEOF918(poolAddress);

        return (tokenAmount.MUL251(VIEWLPTOKENAMOUNT945(who))).DIV611(IERC20(poolAddress).TOTALSUPPLY425());
    }

    function PRICE264() public view returns (uint){

        address poolAddress = Uniswap(factory303).GETPAIR333(orbAddress, WETHAddress);

        uint ethAmount = IERC20(WETHAddress).BALANCEOF918(poolAddress);
        uint tokenAmount = IERC20(orbAddress).BALANCEOF918(poolAddress);

        return (decimal633.MUL251(ethAmount)).DIV611(tokenAmount);
    }

    function ETHEARNCALC420(uint eth, uint time) public view returns(uint){

        address poolAddress = Uniswap(factory303).GETPAIR333(orbAddress, WETHAddress);
        uint totalEth = IERC20(WETHAddress).BALANCEOF918(poolAddress);
        uint totalLP = IERC20(poolAddress).TOTALSUPPLY425();

        uint LP = ((eth/2)*totalLP)/totalEth;

        return EARNCALC965(LP * time);
    }

    function EARNCALC965(uint LPTime) public view returns(uint){
        return ( REWARDVALUE484().MUL251(LPTime)  ) / ( 31557600 * decimal633 );
    }

    function ETHTIMECALC471(uint orb) internal view returns(uint){
        return ( orb.MUL251(31557600 * decimal633) ).DIV611( REWARDVALUE484() );
    }
}
