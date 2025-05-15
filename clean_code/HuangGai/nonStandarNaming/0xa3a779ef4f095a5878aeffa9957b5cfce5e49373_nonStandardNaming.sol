





pragma solidity ^0.5.17;



interface IERC20 {

    function TOTALSUPPLY419() external view returns (uint256);


    function BALANCEOF996(address account) external view returns (uint256);


    function TRANSFER376(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE696(address owner, address spender) external view returns (uint256);


    function APPROVE263(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM581(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER351(address indexed from, address indexed to, uint256 value);


    event APPROVAL946(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

    function ADD509(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB882(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB882(a, b, "SafeMath: subtraction overflow");
    }


    function SUB882(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL339(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV809(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV809(a, b, "SafeMath: division by zero");
    }


    function DIV809(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD891(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD891(a, b, "SafeMath: modulo by zero");
    }


    function MOD891(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {

    function ISCONTRACT313(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function TOPAYABLE45(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }


    function SENDVALUE473(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER885(IERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN246(token, abi.encodeWithSelector(token.TRANSFER376.selector, to, value));
    }

    function SAFETRANSFERFROM553(IERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN246(token, abi.encodeWithSelector(token.TRANSFERFROM581.selector, from, to, value));
    }

    function SAFEAPPROVE341(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.ALLOWANCE696(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN246(token, abi.encodeWithSelector(token.APPROVE263.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE60(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE696(address(this), spender).ADD509(value);
        CALLOPTIONALRETURN246(token, abi.encodeWithSelector(token.APPROVE263.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE623(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE696(address(this), spender).SUB882(value, "SafeERC20: decreased allowance below zero");
        CALLOPTIONALRETURN246(token, abi.encodeWithSelector(token.APPROVE263.selector, spender, newAllowance));
    }


    function CALLOPTIONALRETURN246(IERC20 token, bytes memory data) private {








        require(address(token).ISCONTRACT313(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


interface IController {
    function WITHDRAW936(address, uint256) external;

    function BALANCEOF996(address) external view returns (uint256);

    function EARN112(address, uint256) external;

    function WANT318(address) external view returns (address);

    function REWARDS351() external view returns (address);

    function VAULTS378(address) external view returns (address);

    function STRATEGIES650(address) external view returns (address);
}


interface Gauge {
    function DEPOSIT828(uint256) external;

    function BALANCEOF996(address) external view returns (uint256);

    function WITHDRAW936(uint256) external;
}


interface Mintr {
    function MINT422(address) external;
}


interface Uni {
    function SWAPEXACTTOKENSFORTOKENS240(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;
}


interface ICurveFi {
    function GET_VIRTUAL_PRICE800() external view returns (uint256);

    function ADD_LIQUIDITY808(

        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function ADD_LIQUIDITY808(

        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function REMOVE_LIQUIDITY_IMBALANCE228(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function REMOVE_LIQUIDITY138(uint256 _amount, uint256[4] calldata amounts) external;

    function EXCHANGE730(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;
}

interface Zap {
    function REMOVE_LIQUIDITY_ONE_COIN571(
        uint256,
        int128,
        uint256
    ) external;
}



interface yERC20 {
    function DEPOSIT828(uint256 _amount) external;

    function WITHDRAW936(uint256 _amount) external;

    function GETPRICEPERFULLSHARE410() external view returns (uint256);
}


interface VoterProxy {
    function WITHDRAW936(
        address _gauge,
        address _token,
        uint256 _amount
    ) external returns (uint256);

    function BALANCEOF996(address _gauge) external view returns (uint256);

    function WITHDRAWALL4(address _gauge, address _token) external returns (uint256);

    function DEPOSIT828(address _gauge, address _token) external;

    function HARVEST862(address _gauge) external;

    function LOCK494() external;
}


contract StrategyCurveBUSDVoterProxy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant want963 = address(0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B);
    address public constant crv787 = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant uni793 = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant weth737 = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address public constant dai668 = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public constant ydai985 = address(0xa3Aa4a71dBb17EBF2108A75b0BB7eFd9955463EF);
    address public constant curve489 = address(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);

    address public constant gauge170 = address(0x69Fb7c45726cfE2baDeE8317005d3F94bE838840);
    address public constant voter494 = address(0x07443C1cdb3653746727D595D2c1e5B438e0535A);

    uint256 public keepCRV = 1000;
    uint256 public constant keepcrvmax536 = 10000;

    uint256 public performanceFee = 3000;
    uint256 public constant performancemax55 = 10000;

    uint256 public withdrawalFee = 50;
    uint256 public constant withdrawalmax744 = 10000;

    address public proxy;

    address public governance;
    address public controller;
    address public strategist;

    constructor(address _controller) public {
        governance = msg.sender;
        strategist = msg.sender;
        controller = _controller;
    }

    function GETNAME315() external pure returns (string memory) {
        return "StrategyCurveBUSDVoterProxy";
    }

    function SETSTRATEGIST730(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function SETKEEPCRV658(uint256 _keepCRV) external {
        require(msg.sender == governance, "!governance");
        keepCRV = _keepCRV;
    }

    function SETWITHDRAWALFEE696(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        withdrawalFee = _withdrawalFee;
    }

    function SETPERFORMANCEFEE960(uint256 _performanceFee) external {
        require(msg.sender == governance, "!governance");
        performanceFee = _performanceFee;
    }

    function SETPROXY105(address _proxy) external {
        require(msg.sender == governance, "!governance");
        proxy = _proxy;
    }

    function DEPOSIT828() public {
        uint256 _want = IERC20(want963).BALANCEOF996(address(this));
        if (_want > 0) {
            IERC20(want963).SAFETRANSFER885(proxy, _want);
            VoterProxy(proxy).DEPOSIT828(gauge170, want963);
        }
    }


    function WITHDRAW936(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        require(want963 != address(_asset), "want");
        require(crv787 != address(_asset), "crv");
        require(ydai985 != address(_asset), "ydai");
        require(dai668 != address(_asset), "dai");
        balance = _asset.BALANCEOF996(address(this));
        _asset.SAFETRANSFER885(controller, balance);
    }


    function WITHDRAW936(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want963).BALANCEOF996(address(this));
        if (_balance < _amount) {
            _amount = _WITHDRAWSOME256(_amount.SUB882(_balance));
            _amount = _amount.ADD509(_balance);
        }

        uint256 _fee = _amount.MUL339(withdrawalFee).DIV809(withdrawalmax744);

        IERC20(want963).SAFETRANSFER885(IController(controller).REWARDS351(), _fee);
        address _vault = IController(controller).VAULTS378(address(want963));
        require(_vault != address(0), "!vault");

        IERC20(want963).SAFETRANSFER885(_vault, _amount.SUB882(_fee));
    }


    function WITHDRAWALL4() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _WITHDRAWALL830();

        balance = IERC20(want963).BALANCEOF996(address(this));

        address _vault = IController(controller).VAULTS378(address(want963));
        require(_vault != address(0), "!vault");
        IERC20(want963).SAFETRANSFER885(_vault, balance);
    }

    function _WITHDRAWALL830() internal {
        VoterProxy(proxy).WITHDRAWALL4(gauge170, want963);
    }

    function HARVEST862() public {
        require(msg.sender == strategist || msg.sender == governance, "!authorized");
        VoterProxy(proxy).HARVEST862(gauge170);
        uint256 _crv = IERC20(crv787).BALANCEOF996(address(this));
        if (_crv > 0) {
            uint256 _keepCRV = _crv.MUL339(keepCRV).DIV809(keepcrvmax536);
            IERC20(crv787).SAFETRANSFER885(voter494, _keepCRV);
            _crv = _crv.SUB882(_keepCRV);

            IERC20(crv787).SAFEAPPROVE341(uni793, 0);
            IERC20(crv787).SAFEAPPROVE341(uni793, _crv);

            address[] memory path = new address[](3);
            path[0] = crv787;
            path[1] = weth737;
            path[2] = dai668;

            Uni(uni793).SWAPEXACTTOKENSFORTOKENS240(_crv, uint256(0), path, address(this), now.ADD509(1800));
        }
        uint256 _dai = IERC20(dai668).BALANCEOF996(address(this));
        if (_dai > 0) {
            IERC20(dai668).SAFEAPPROVE341(ydai985, 0);
            IERC20(dai668).SAFEAPPROVE341(ydai985, _dai);
            yERC20(ydai985).DEPOSIT828(_dai);
        }
        uint256 _ydai = IERC20(ydai985).BALANCEOF996(address(this));
        if (_ydai > 0) {
            IERC20(ydai985).SAFEAPPROVE341(curve489, 0);
            IERC20(ydai985).SAFEAPPROVE341(curve489, _ydai);
            ICurveFi(curve489).ADD_LIQUIDITY808([_ydai, 0, 0, 0], 0);
        }
        uint256 _want = IERC20(want963).BALANCEOF996(address(this));
        if (_want > 0) {
            uint256 _fee = _want.MUL339(performanceFee).DIV809(performancemax55);
            IERC20(want963).SAFETRANSFER885(IController(controller).REWARDS351(), _fee);
            DEPOSIT828();
        }
        VoterProxy(proxy).LOCK494();
    }

    function _WITHDRAWSOME256(uint256 _amount) internal returns (uint256) {
        return VoterProxy(proxy).WITHDRAW936(gauge170, want963, _amount);
    }

    function BALANCEOFWANT761() public view returns (uint256) {
        return IERC20(want963).BALANCEOF996(address(this));
    }

    function BALANCEOFPOOL660() public view returns (uint256) {
        return VoterProxy(proxy).BALANCEOF996(gauge170);
    }

    function BALANCEOF996() public view returns (uint256) {
        return BALANCEOFWANT761().ADD509(BALANCEOFPOOL660());
    }

    function SETGOVERNANCE812(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function SETCONTROLLER990(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }
}
