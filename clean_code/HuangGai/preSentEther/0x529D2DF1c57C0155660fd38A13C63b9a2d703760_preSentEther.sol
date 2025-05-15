





pragma solidity ^0.6.12;






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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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


interface ICurveFi {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(

        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(

        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;
}

interface ICurveDeposit {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(

        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(

        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(

        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity_one_coin(uint256 _amount, int128 _i, uint256 _min_uamount) external;

    function remove_liquidity_one_coin(uint256 _amount, int128 _i, uint256 _min_uamount, bool _donate_dust) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function calc_withdraw_one_coin(uint256 _amount, int128 _index) external view returns(uint256);
}


interface Gauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function withdraw(uint256) external;
}


interface Uni {
    function  swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;
}

interface IController {
    function withdraw(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function earn(address, uint256) external;

    function want(address) external view returns (address);

    function rewards() external view returns (address);

    function vaults(address) external view returns (address);
}


interface Mintr {
    function mint(address) external;
}


contract StrategyCurve3TokenPool {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint256 public constant N_COINS = 3;
    uint256 public immutable WANT_COIN_INDEX;
    address public immutable want;
    address public immutable crvLP;
    address public immutable curveDeposit;
    address public immutable gauge;

    address public immutable mintr;
    address public immutable crv;
    address public immutable uni;

    address public immutable weth;
    string private name;


    address[N_COINS] public coins;
    uint256[N_COINS] public ZEROS = [uint256(0),uint256(0),uint256(0)];

    uint256 public performanceFee = 500;
    uint256 public immutable performanceMax = 10000;

    uint256 public withdrawalFee = 0;
    uint256 public immutable withdrawalMax = 10000;

    address public governance;
    address public controller;
    address public timelock;

    constructor
    (
        address _controller,
        string memory _name,
        uint256 _wantCoinIndex,
        address[N_COINS] memory _coins,
        address _curveDeposit,
        address _gauge,
        address _crvLP,
        address _crv,
        address _uni,
        address _mintr,
        address _weth,
        address _timelock
    )
    public
    {
        governance = msg.sender;
        controller = _controller;
        name = _name;
        WANT_COIN_INDEX = _wantCoinIndex;
        want = _coins[_wantCoinIndex];
        coins = _coins;
        curveDeposit = _curveDeposit;
        gauge = _gauge;
        crvLP = _crvLP;
        crv = _crv;
        uni = _uni;
        mintr = _mintr;
        weth = _weth;
        timelock = _timelock;
    }

    function getName() external view returns (string memory) {
        return name;
    }

    function setWithdrawalFee(uint256 _withdrawalFee) external {
        require(msg.sender == governance, "!governance");
        require(_withdrawalFee < withdrawalMax, "inappropriate withdraw fee");
        withdrawalFee = _withdrawalFee;
    }

    function setPerformanceFee(uint256 _performanceFee) external {
        require(msg.sender == governance, "!governance");
        require(_performanceFee < performanceMax, "inappropriate performance fee");
        performanceFee = _performanceFee;
    }

    function deposit() public {
        _deposit(WANT_COIN_INDEX);
    }

    function _deposit(uint256 _coinIndex) internal {
        require(_coinIndex < N_COINS, "index exceeded bound");
        address coinAddr = coins[_coinIndex];
        uint256 wantAmount = IERC20(coinAddr).balanceOf(address(this));
        if (wantAmount > 0) {
            IERC20(coinAddr).safeApprove(curveDeposit, 0);
            IERC20(coinAddr).safeApprove(curveDeposit, wantAmount);
            uint256[N_COINS] memory amounts = ZEROS;
            amounts[_coinIndex] = wantAmount;

            ICurveDeposit(curveDeposit).add_liquidity(amounts, 0);
        }
        uint256 crvLPAmount = IERC20(crvLP).balanceOf(address(this));
        if (crvLPAmount > 0) {
            IERC20(crvLP).safeApprove(gauge, 0);
            IERC20(crvLP).safeApprove(gauge, crvLPAmount);
            Gauge(gauge).deposit(crvLPAmount);
        }
    }


    function withdrawAll() external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        uint256 _amount = Gauge(gauge).balanceOf(address(this));
        Gauge(gauge).withdraw(_amount);
        IERC20(crvLP).safeApprove(curveDeposit, 0);
        IERC20(crvLP).safeApprove(curveDeposit, _amount);

        ICurveDeposit(curveDeposit).remove_liquidity_one_coin(_amount, int128(WANT_COIN_INDEX), 0);

        balance = IERC20(want).balanceOf(address(this));

        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault");
        IERC20(want).safeTransfer(_vault, balance);
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _withdrawSome(_amount.sub(_balance));
            _amount = IERC20(want).balanceOf(address(this));
        }
        uint256 _fee = _amount.mul(withdrawalFee).div(withdrawalMax);
        IERC20(want).safeTransfer(IController(controller).rewards(), _fee);
        address _vault = IController(controller).vaults(address(want));
        require(_vault != address(0), "!vault");

        IERC20(want).safeTransfer(_vault, _amount.sub(_fee));
    }

    function _withdrawSome(uint256 _amount) internal {
        uint256 rate = ICurveDeposit(curveDeposit).calc_withdraw_one_coin(10**18, int128(WANT_COIN_INDEX));
        _amount = _amount.mul(10**18).div(rate);
        if(_amount > balanceOfGauge()) {
            _amount = balanceOfGauge();
        }
        Gauge(gauge).withdraw(_amount);
        IERC20(crvLP).safeApprove(curveDeposit, 0);
        IERC20(crvLP).safeApprove(curveDeposit, _amount);

        ICurveDeposit(curveDeposit).remove_liquidity_one_coin(_amount, int128(WANT_COIN_INDEX), 0);
    }


    function withdraw(IERC20 _asset) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        for(uint i = 0; i < N_COINS; ++i) {
            require(coins[i] != address(_asset), "internal token");
        }
        require(crv != address(_asset), "crv");
        require(crvLP != address(_asset), "crvLP");
        balance = _asset.balanceOf(address(this));
        _asset.safeTransfer(controller, balance);
    }

    function harvest(uint _coinIndex) public {
        require(_coinIndex < N_COINS, "index exceeded bound");
        Mintr(mintr).mint(gauge);
        address harvestingCoin = coins[_coinIndex];
        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {

            IERC20(crv).safeApprove(uni, 0);
            IERC20(crv).safeApprove(uni, _crv);

            address[] memory path = new address[](3);
            path[0] = crv;
            path[1] = weth;
            path[2] = harvestingCoin;

            Uni(uni).swapExactTokensForTokens(_crv, uint256(0), path, address(this), now.add(1800));
        }
        uint256 harvestAmount = IERC20(harvestingCoin).balanceOf(address(this));
        if (harvestAmount > 0) {
            uint256 _fee = harvestAmount.mul(performanceFee).div(performanceMax);
            IERC20(harvestingCoin).safeTransfer(IController(controller).rewards(), _fee);
            _deposit(_coinIndex);
        }
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfGauge() public view returns (uint256) {
        return Gauge(gauge).balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        uint256 gaugeBalance = balanceOfGauge();


        if(address(this).balance == 0){
            return 0;
        }
        return ICurveDeposit(curveDeposit).calc_withdraw_one_coin(gaugeBalance, int128(WANT_COIN_INDEX));
    }

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function setGovernance(address _governance) external {
        require(msg.sender == timelock, "!timelock");
        governance = _governance;
    }

    function setController(address _controller) external {
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    function setTimelock(address _timelock) public {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }
}
