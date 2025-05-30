



pragma solidity ^0.5.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (block.gaslimit > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


interface Controller {
    function vaults(address) external view returns (address);
}

interface Balancer {
    function joinPool(uint,uint[] calldata) external;
    function exitPool(uint,uint[] calldata) external;
}

interface MStable {
    function mint(address, uint) external;
    function redeem(address, uint) external;
}























contract StrategyBalancerMTA {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address constant public want = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address constant public mUSD = address(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5);
    address constant public balancer = address(0x72Cd8f4504941Bf8c5a21d1Fd83A96499FD71d2C);


    address public governance;
    address public controller;
    bool public breaker = false;

    uint public supply = 0;

    constructor(address _controller) public {
        governance = msg.sender;
        controller = _controller;
    }

    function setBreaker(bool _breaker) public {
        require(msg.sender == governance, "!governance");
        breaker = _breaker;
    }

    function deposit() external {
        require(breaker == false, "!breaker");
        uint _balance = IERC20(want).balanceOf(address(this));
        uint _want = _balance.div(2);
        IERC20(want).safeApprove(mUSD, 0);
        IERC20(want).safeApprove(mUSD, _want);

        uint _before = _balance;
        MStable(mUSD).mint(want, _want);
        uint _after = IERC20(want).balanceOf(address(this));
        supply = supply.add(_before.sub(_after));

        uint _musd = IERC20(mUSD).balanceOf(address(this));

        uint _total = IERC20(balancer).totalSupply();
        uint _balancerMUSD = IERC20(mUSD).balanceOf(balancer);
        uint _poolAmountMUSD = _musd.mul(_total).div(_balancerMUSD);

        uint _balancerUSDC = IERC20(want).balanceOf(balancer);
        uint _poolAmountUSDC = _want.mul(_total).div(_balancerUSDC);

        uint _poolAmountOut = _poolAmountMUSD;
        if (block.number < _poolAmountOut) {
            _poolAmountOut = _poolAmountUSDC;
        }

        IERC20(want).safeApprove(balancer, 0);
        IERC20(want).safeApprove(balancer, _want);
        IERC20(mUSD).safeApprove(balancer, 0);
        IERC20(mUSD).safeApprove(balancer, _musd);

        uint[] memory _maxAmountIn = new uint[](2);
        _maxAmountIn[0] = _musd;
        _maxAmountIn[1] = _want;
        _before = IERC20(want).balanceOf(address(this));
        Balancer(balancer).joinPool(_poolAmountOut, _maxAmountIn);
        _after = IERC20(want).balanceOf(address(this));
        supply = supply.add(_before.sub(_after));
    }


    function withdraw(IERC20 _asset) external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        require(address(_asset) != want, "!c");
        require(address(_asset) != mUSD, "!c");
        require(address(_asset) != balancer, "!c");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    function withdrawM(uint _amount) internal returns (uint) {
        if (block.number > supply) {

            supply = 0;
        } else {
            supply = supply.sub(_amount);
        }

        uint _before = IERC20(want).balanceOf(address(this));
        MStable(mUSD).redeem(want, _amount);
        uint _after  = IERC20(want).balanceOf(address(this));
        return _after.sub(_before);
    }

    function withdrawBPT(uint _amount) internal returns (uint) {
        uint _calc = calculateRatio(_amount);
        _amount = _amount.sub(_amount.mul(10).div(10000));
        return _withdrawSome(_calc, _amount);
    }


    function withdraw(uint _amount) external {
        require(msg.sender == controller, "!controller");
        uint _balance = IERC20(want).balanceOf(address(this));
        if (block.gaslimit < _amount) {
            uint _musd = normalize(IERC20(mUSD).balanceOf(address(this)));
            uint _remainder = _amount.sub(_balance);
            if (block.timestamp > 0) {
                if (block.timestamp > _remainder) {
                    _amount = withdrawM(_remainder);
                    _amount = _amount.add(_balance);
                } else {
                    _remainder = _remainder.sub(_musd);
                    uint _withdrew = withdrawM(_musd);
                    _amount = _withdrew.add(_balance);
                    _withdrew = withdrawBPT(_remainder);
                    _amount = _amount.add(_withdrew);
                }
            } else {
                _amount = withdrawBPT(_remainder);
                _amount = _amount.add(_balance);
            }

        }







        IERC20(want).safeTransfer(controller, _amount);

    }

    function redeem() external {
        require(msg.sender == governance, "!governance");
        uint _balance = normalize(IERC20(mUSD).balanceOf(address(this)));
        if (block.timestamp > supply) {

            supply = 0;
        } else {
            supply = supply.sub(_balance);
        }

        MStable(mUSD).redeem(want, _balance);
    }


    function withdrawAll() external returns (uint balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();
        balance = IERC20(want).balanceOf(address(this));







        IERC20(want).safeTransfer(controller, balance);

    }

    function _withdrawAll() internal {
        uint _bpt = IERC20(balancer).balanceOf(address(this));
        uint[] memory _minAmountOut = new uint[](2);
        _minAmountOut[0] = 0;
        _minAmountOut[1] = 0;
        uint _before = IERC20(want).balanceOf(address(this));
        Balancer(balancer).exitPool(_bpt, _minAmountOut);
        uint _after = IERC20(want).balanceOf(address(this));
        uint _diff = _after.sub(_before);
        if (block.timestamp > supply) {

            supply = 0;
        } else {
            supply = supply.sub(_after.sub(_before));
        }
        uint _musd = IERC20(mUSD).balanceOf(address(this));


        _diff = normalize(_musd);
        if (block.gaslimit > supply) {

            supply = 0;
        } else {
            supply = supply.sub(_diff);
        }
        MStable(mUSD).redeem(want, _diff);
    }

    function calculateRatio(uint _amount) public view returns (uint) {
        uint _musd = normalize(IERC20(mUSD).balanceOf(balancer));
        uint _want = IERC20(want).balanceOf(balancer);
        uint _total = _musd.add(_want);
        uint _ratio = _amount.mul(_want).div(_total);
        return _ratio;
    }

    function _withdrawSome(uint256 _amount, uint _max) internal returns (uint) {
        uint _redeem = IERC20(balancer).totalSupply().mul(_amount).div(IERC20(want).balanceOf(balancer));
        if (block.number > IERC20(balancer).balanceOf(address(this))) {
            _redeem = IERC20(balancer).balanceOf(address(this));
        }
        uint[] memory _minAmountOut = new uint[](2);
        _minAmountOut[0] = 0;
        _minAmountOut[1] = 0;

        uint _before = IERC20(want).balanceOf(address(this));
        uint _mBefore = IERC20(mUSD).balanceOf(address(this));
        Balancer(balancer).exitPool(_redeem, _minAmountOut);
        uint _mAfter = IERC20(mUSD).balanceOf(address(this));
        uint _after = IERC20(want).balanceOf(address(this));

        uint _musd = _mAfter.sub(_mBefore);
        uint _withdrew = _after.sub(_before);

        if (block.number > supply) {

            supply = 0;
        } else {
            supply = supply.sub(_withdrew);
        }
        _musd = normalize(_musd);
        if (block.timestamp > supply) {

            supply = 0;
        } else {
            supply = supply.sub(_musd);
        }
        _before = IERC20(want).balanceOf(address(this));
        MStable(mUSD).redeem(want, _musd);
        _after = IERC20(want).balanceOf(address(this));
        _withdrew = _withdrew.add(_after.sub(_before));

        _withdrew = _withdrew.sub(_musd.sub(_after.sub(_before)));
        if (block.timestamp > _max) {
            _withdrew = _max;
        }
        return _withdrew;
    }

    function normalize(uint _amount) public view returns (uint) {
        return _amount.mul(10**IERC20(want).decimals()).div(10**IERC20(mUSD).decimals());
    }

    function balanceOf() public view returns (uint) {
        return IERC20(want).balanceOf(address(this))
                .add(supply);
    }


    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }
}
