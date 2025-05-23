



pragma solidity ^0.5.17;

interface IERC20 {
    function TOTALSUPPLY668() external view returns (uint256);
    function BALANCEOF477(address account) external view returns (uint256);
    function TRANSFER143(address recipient, uint256 amount) external returns (bool);
    function ALLOWANCE643(address owner, address spender) external view returns (uint256);
    function DECIMALS496() external view returns (uint);
    function NAME987() external view returns (string memory);
    function APPROVE179(address spender, uint256 amount) external returns (bool);
    function TRANSFERFROM615(address sender, address recipient, uint256 amount) external returns (bool);
    event TRANSFER157(address indexed from, address indexed to, uint256 value);
    event APPROVAL667(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function ADD88(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function SUB230(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB230(a, b, "SafeMath: subtraction overflow");
    }
    function SUB230(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function MUL653(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function DIV683(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV683(a, b, "SafeMath: division by zero");
    }
    function DIV683(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function MOD193(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD193(a, b, "SafeMath: modulo by zero");
    }
    function MOD193(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function ISCONTRACT263(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function TOPAYABLE849(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function SENDVALUE91(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER5(IERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN824(token, abi.encodeWithSelector(token.TRANSFER143.selector, to, value));
    }

    function SAFETRANSFERFROM93(IERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN824(token, abi.encodeWithSelector(token.TRANSFERFROM615.selector, from, to, value));
    }

    function SAFEAPPROVE53(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.ALLOWANCE643(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN824(token, abi.encodeWithSelector(token.APPROVE179.selector, spender, value));
    }
    function CALLOPTIONALRETURN824(IERC20 token, bytes memory data) private {
        require(address(token).ISCONTRACT263(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface Controller {
    function VAULTS944(address) external view returns (address);
    function REWARDS935() external view returns (address);
}

interface Vault{
    function MAKE_PROFIT128(uint256 amount) external;
}


interface dRewards {
    function WITHDRAW814(uint) external;
    function GETREWARD593() external;
    function STAKE285(uint) external;
    function BALANCEOF477(address) external view returns (uint);
    function EXIT848() external;
}

interface dERC20 {
    function MINT872(address, uint256) external;
    function REDEEM37(address, uint) external;
    function GETTOKENBALANCE223(address) external view returns (uint);
    function GETEXCHANGERATE194() external view returns (uint);
}

interface UniswapRouter {
    function SWAPEXACTTOKENSFORTOKENS604(uint, uint, address[] calldata, address, uint) external;
}

contract StrategyDForceUSDT {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address constant public want177 = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address constant public d954 = address(0x868277d475E0e475E38EC5CdA2d9C83B5E1D9fc8);
    address constant public pool570 = address(0x324EebDAa45829c6A8eE903aFBc7B61AF48538df);
    address constant public df43 = address(0x431ad2ff6a9C365805eBaD47Ee021148d6f7DBe0);
    address constant public output473 = address(0x431ad2ff6a9C365805eBaD47Ee021148d6f7DBe0);
    address constant public unirouter832 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant public weth466 = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address constant public yf135 = address(0x96F9632b25f874769969ff91219fCCb6ceDf26D2);
    address constant public ysr622 = address(0xD9A947789974bAD9BE77E45C2b327174A9c59D71);


    uint public fee = 600;
    uint public burnfee = 300;
    uint public callfee = 100;
    uint constant public max300 = 1000;

    uint public withdrawalFee = 0;
    uint constant public withdrawalmax606 = 10000;

    address public governance;
    address public controller;
    address public burnAddress = 0xB6af2DabCEBC7d30E440714A33E5BD45CEEd103a;

    string public getName;

    address[] public swap2YFRouting;


    constructor() public {
        governance = tx.origin;
        controller = 0xcC8d36211374a08fC61d74ed2E48e22b922C9D7C;
        getName = string(
            abi.encodePacked("yf:Strategy:",
            abi.encodePacked(IERC20(want177).NAME987(),"DF Token"
            )
            ));
        swap2YFRouting = [output473,weth466,ysr622,yf135];
        DOAPPROVE493();
    }

    function DOAPPROVE493 () public{
        IERC20(output473).SAFEAPPROVE53(unirouter832, 0);
        IERC20(output473).SAFEAPPROVE53(unirouter832, uint(-1));
    }


    function DEPOSIT728() public {
        uint _want = IERC20(want177).BALANCEOF477(address(this));
        if (_want > 0) {
            IERC20(want177).SAFEAPPROVE53(d954, 0);
            IERC20(want177).SAFEAPPROVE53(d954, _want);
            dERC20(d954).MINT872(address(this), _want);
        }

        uint _d = IERC20(d954).BALANCEOF477(address(this));
        if (_d > 0) {
            IERC20(d954).SAFEAPPROVE53(pool570, 0);
            IERC20(d954).SAFEAPPROVE53(pool570, _d);
            dRewards(pool570).STAKE285(_d);
        }

    }


    function WITHDRAW814(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(want177 != address(_asset), "want");
        require(d954 != address(_asset), "d");
        balance = _asset.BALANCEOF477(address(this));
        _asset.SAFETRANSFER5(controller, balance);
    }


    function WITHDRAW814(uint _amount) external {
        require(msg.sender == controller, "!controller");
        uint _balance = IERC20(want177).BALANCEOF477(address(this));
        if (_balance < _amount) {
            _amount = _WITHDRAWSOME670(_amount.SUB230(_balance));
            _amount = _amount.ADD88(_balance);
        }

        uint _fee = 0;
        if (withdrawalFee>0){
            _fee = _amount.MUL653(withdrawalFee).DIV683(withdrawalmax606);
            IERC20(want177).SAFETRANSFER5(Controller(controller).REWARDS935(), _fee);
        }


        address _vault = Controller(controller).VAULTS944(address(want177));
        require(_vault != address(0), "!vault");
        IERC20(want177).SAFETRANSFER5(_vault, _amount.SUB230(_fee));
    }


    function WITHDRAWALL110() external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        _WITHDRAWALL168();


        balance = IERC20(want177).BALANCEOF477(address(this));

        address _vault = Controller(controller).VAULTS944(address(want177));
        require(_vault != address(0), "!vault");
        IERC20(want177).SAFETRANSFER5(_vault, balance);
    }

    function _WITHDRAWALL168() internal {
        dRewards(pool570).EXIT848();
        uint _d = IERC20(d954).BALANCEOF477(address(this));
        if (_d > 0) {
            dERC20(d954).REDEEM37(address(this),_d);
        }
    }

    function HARVEST259() public {
        require(!Address.ISCONTRACT263(msg.sender),"!contract");
        dRewards(pool570).GETREWARD593();

        DOSWAP328();
        DOSPLIT77();


        address _vault = Controller(controller).VAULTS944(address(want177));
        require(_vault != address(0), "!vault");
        IERC20(yf135).SAFEAPPROVE53(_vault, 0);
        IERC20(yf135).SAFEAPPROVE53(_vault, IERC20(yf135).BALANCEOF477(address(this)));
        Vault(_vault).MAKE_PROFIT128(IERC20(yf135).BALANCEOF477(address(this)));
    }

    function DOSWAP328() internal {
        uint256 _2yf = IERC20(output473).BALANCEOF477(address(this)).MUL653(10).DIV683(100);
        UniswapRouter(unirouter832).SWAPEXACTTOKENSFORTOKENS604(_2yf, 0, swap2YFRouting, address(this), now.ADD88(1800));
    }

    function DOSPLIT77() internal{
        uint b = IERC20(yf135).BALANCEOF477(address(this));
        uint _fee = b.MUL653(fee).DIV683(max300);
        uint _callfee = b.MUL653(callfee).DIV683(max300);
        uint _burnfee = b.MUL653(burnfee).DIV683(max300);
        IERC20(yf135).SAFETRANSFER5(Controller(controller).REWARDS935(), _fee);
        IERC20(yf135).SAFETRANSFER5(msg.sender, _callfee);
        IERC20(yf135).SAFETRANSFER5(burnAddress, _burnfee);
    }

    function _WITHDRAWSOME670(uint256 _amount) internal returns (uint) {
        uint _d = _amount.MUL653(1e18).DIV683(dERC20(d954).GETEXCHANGERATE194());
        uint _before = IERC20(d954).BALANCEOF477(address(this));
        dRewards(pool570).WITHDRAW814(_d);
        uint _after = IERC20(d954).BALANCEOF477(address(this));
        uint _withdrew = _after.SUB230(_before);
        _before = IERC20(want177).BALANCEOF477(address(this));
        dERC20(d954).REDEEM37(address(this), _withdrew);
        _after = IERC20(want177).BALANCEOF477(address(this));
        _withdrew = _after.SUB230(_before);
        return _withdrew;
    }

    function BALANCEOFWANT993() public view returns (uint) {
        return IERC20(want177).BALANCEOF477(address(this));
    }

    function BALANCEOFPOOL844() public view returns (uint) {
        return (dRewards(pool570).BALANCEOF477(address(this))).MUL653(dERC20(d954).GETEXCHANGERATE194()).DIV683(1e18);
    }

    function GETEXCHANGERATE194() public view returns (uint) {
        return dERC20(d954).GETEXCHANGERATE194();
    }

    function BALANCEOFD564() public view returns (uint) {
        return dERC20(d954).GETTOKENBALANCE223(address(this));
    }

    function BALANCEOF477() public view returns (uint) {
        return BALANCEOFWANT993()
        .ADD88(BALANCEOFD564())
        .ADD88(BALANCEOFPOOL844());
    }

    function SETGOVERNANCE555(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function SETCONTROLLER651(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }
    function SETFEE854(uint256 _fee) external{
        require(msg.sender == governance, "!governance");
        fee = _fee;
    }
    function SETCALLFEE170(uint256 _fee) external{
        require(msg.sender == governance, "!governance");
        callfee = _fee;
    }
    function SETBURNFEE378(uint256 _fee) external{
        require(msg.sender == governance, "!governance");
        burnfee = _fee;
    }
    function SETBURNADDRESS78(address _burnAddress) public{
        require(msg.sender == governance, "!governance");
        burnAddress = _burnAddress;
    }

    function SETWITHDRAWALFEE466(uint _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        require(_withdrawalFee <=100,"fee >= 1%");
        withdrawalFee = _withdrawalFee;
    }
}
