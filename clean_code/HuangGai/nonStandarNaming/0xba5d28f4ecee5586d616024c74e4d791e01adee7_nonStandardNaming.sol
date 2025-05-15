



pragma solidity 0.6.12;


interface IERC20 {

    function TOTALSUPPLY267() external view returns (uint256);


    function BALANCEOF771(address account) external view returns (uint256);


    function TRANSFER36(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE520(address owner, address spender) external view returns (uint256);


    function APPROVE275(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM54(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER513(address indexed from, address indexed to, uint256 value);


    event APPROVAL255(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

    function ADD260(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB684(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB684(a, b, "SafeMath: subtraction overflow");
    }


    function SUB684(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL872(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV551(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV551(a, b, "SafeMath: division by zero");
    }


    function DIV551(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD699(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD699(a, b, "SafeMath: modulo by zero");
    }


    function MOD699(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {

    function ISCONTRACT292(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }


    function SENDVALUE986(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function FUNCTIONCALL437(address target, bytes memory data) internal returns (bytes memory) {
      return FUNCTIONCALL437(target, data, "Address: low-level call failed");
    }


    function FUNCTIONCALL437(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _FUNCTIONCALLWITHVALUE654(target, data, 0, errorMessage);
    }


    function FUNCTIONCALLWITHVALUE142(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return FUNCTIONCALLWITHVALUE142(target, data, value, "Address: low-level call with value failed");
    }


    function FUNCTIONCALLWITHVALUE142(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _FUNCTIONCALLWITHVALUE654(target, data, value, errorMessage);
    }

    function _FUNCTIONCALLWITHVALUE654(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(ISCONTRACT292(target), "Address: call to non-contract");


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

    function SAFETRANSFER627(IERC20 token, address to, uint256 value) internal {
        _CALLOPTIONALRETURN808(token, abi.encodeWithSelector(token.TRANSFER36.selector, to, value));
    }

    function SAFETRANSFERFROM565(IERC20 token, address from, address to, uint256 value) internal {
        _CALLOPTIONALRETURN808(token, abi.encodeWithSelector(token.TRANSFERFROM54.selector, from, to, value));
    }


    function SAFEAPPROVE47(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.ALLOWANCE520(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _CALLOPTIONALRETURN808(token, abi.encodeWithSelector(token.APPROVE275.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE824(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE520(address(this), spender).ADD260(value);
        _CALLOPTIONALRETURN808(token, abi.encodeWithSelector(token.APPROVE275.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE914(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE520(address(this), spender).SUB684(value, "SafeERC20: decreased allowance below zero");
        _CALLOPTIONALRETURN808(token, abi.encodeWithSelector(token.APPROVE275.selector, spender, newAllowance));
    }


    function _CALLOPTIONALRETURN808(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).FUNCTIONCALL437(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IMultiVaultStrategy {
    function WANT777() external view returns (address);
    function DEPOSIT294() external;
    function WITHDRAW808(address _asset) external;
    function WITHDRAW808(uint _amount) external returns (uint);
    function WITHDRAWTOCONTROLLER653(uint _amount) external;
    function SKIM294() external;
    function HARVEST506(address _mergedStrategy) external;
    function WITHDRAWALL927() external returns (uint);
    function BALANCEOF771() external view returns (uint);
    function WITHDRAWFEE692(uint) external view returns (uint);
}

interface IValueMultiVault {
    function CAP418() external view returns (uint);
    function GETCONVERTER215(address _want) external view returns (address);
    function GETVAULTMASTER236() external view returns (address);
    function BALANCE180() external view returns (uint);
    function TOKEN385() external view returns (address);
    function AVAILABLE930(address _want) external view returns (uint);
    function ACCEPT281(address _input) external view returns (bool);

    function CLAIMINSURANCE45() external;
    function EARN427(address _want) external;
    function HARVEST506(address reserve, uint amount) external;

    function WITHDRAW_FEE118(uint _shares) external view returns (uint);
    function CALC_TOKEN_AMOUNT_DEPOSIT453(uint[] calldata _amounts) external view returns (uint);
    function CALC_TOKEN_AMOUNT_WITHDRAW2(uint _shares, address _output) external view returns (uint);
    function CONVERT_RATE825(address _input, uint _amount) external view returns (uint);
    function GETPRICEPERFULLSHARE124() external view returns (uint);
    function GET_VIRTUAL_PRICE769() external view returns (uint);

    function DEPOSIT294(address _input, uint _amount, uint _min_mint_amount) external returns (uint _mint_amount);
    function DEPOSITFOR247(address _account, address _to, address _input, uint _amount, uint _min_mint_amount) external returns (uint _mint_amount);
    function DEPOSITALL52(uint[] calldata _amounts, uint _min_mint_amount) external returns (uint _mint_amount);
    function DEPOSITALLFOR442(address _account, address _to, uint[] calldata _amounts, uint _min_mint_amount) external returns (uint _mint_amount);
    function WITHDRAW808(uint _shares, address _output, uint _min_output_amount) external returns (uint);
    function WITHDRAWFOR513(address _account, uint _shares, address _output, uint _min_output_amount) external returns (uint _output_amount);

    function HARVESTSTRATEGY825(address _strategy) external;
    function HARVESTWANT168(address _want) external;
    function HARVESTALLSTRATEGIES334() external;
}

interface IShareConverter {
    function CONVERT_SHARES_RATE463(address _input, address _output, uint _inputAmount) external view returns (uint _outputAmount);

    function CONVERT_SHARES33(address _input, address _output, uint _inputAmount) external returns (uint _outputAmount);
}

interface Converter {
    function CONVERT349(address) external returns (uint);
}

contract MultiStablesVaultController {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;

    address public governance;
    address public strategist;

    struct StrategyInfo {
        address strategy;
        uint quota;
        uint percent;
    }

    IValueMultiVault public vault;

    address public basedWant;
    address[] public wantTokens;


    mapping(address => uint) public wantQuota;
    mapping(address => uint) public wantStrategyLength;


    mapping(address => mapping(uint => StrategyInfo)) public strategies;

    mapping(address => mapping(address => bool)) public approvedStrategies;

    mapping(address => bool) public investDisabled;
    IShareConverter public shareConverter;
    address public lazySelectedBestStrategy;

    constructor(IValueMultiVault _vault) public {
        require(address(_vault) != address(0), "!_vault");
        vault = _vault;
        basedWant = vault.TOKEN385();
        governance = msg.sender;
        strategist = msg.sender;
    }

    function SETGOVERNANCE701(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function SETSTRATEGIST330(address _strategist) external {
        require(msg.sender == governance, "!governance");
        strategist = _strategist;
    }

    function APPROVESTRATEGY673(address _want, address _strategy) external {
        require(msg.sender == governance, "!governance");
        approvedStrategies[_want][_strategy] = true;
    }

    function REVOKESTRATEGY92(address _want, address _strategy) external {
        require(msg.sender == governance, "!governance");
        approvedStrategies[_want][_strategy] = false;
    }

    function SETWANTQUOTA716(address _want, uint _quota) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        wantQuota[_want] = _quota;
    }

    function SETWANTSTRATEGYLENGTH858(address _want, uint _length) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        wantStrategyLength[_want] = _length;
    }


    function SETSTRATEGYINFO462(address _want, uint _sid, address _strategy, uint _quota, uint _percent) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        require(approvedStrategies[_want][_strategy], "!approved");
        strategies[_want][_sid].strategy = _strategy;
        strategies[_want][_sid].quota = _quota;
        strategies[_want][_sid].percent = _percent;
    }

    function SETSHARECONVERTER560(IShareConverter _shareConverter) external {
        require(msg.sender == governance, "!governance");
        shareConverter = _shareConverter;
    }

    function SETINVESTDISABLED819(address _want, bool _investDisabled) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        investDisabled[_want] = _investDisabled;
    }

    function SETWANTTOKENS997(address[] memory _wantTokens) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        delete wantTokens;
        uint _wlength = _wantTokens.length;
        for (uint i = 0; i < _wlength; ++i) {
            wantTokens.push(_wantTokens[i]);
        }
    }

    function GETSTRATEGYCOUNT337() external view returns(uint _strategyCount) {
        _strategyCount = 0;
        uint _wlength = wantTokens.length;
        for (uint i = 0; i < _wlength; i++) {
            _strategyCount = _strategyCount.ADD260(wantStrategyLength[wantTokens[i]]);
        }
    }

    function WANTLENGTH873() external view returns (uint) {
        return wantTokens.length;
    }

    function WANTSTRATEGYBALANCE73(address _want) public view returns (uint) {
        uint _bal = 0;
        for (uint _sid = 0; _sid < wantStrategyLength[_want]; _sid++) {
            _bal = _bal.ADD260(IMultiVaultStrategy(strategies[_want][_sid].strategy).BALANCEOF771());
        }
        return _bal;
    }

    function WANT777() external view returns (address) {
        if (lazySelectedBestStrategy != address(0)) {
            return IMultiVaultStrategy(lazySelectedBestStrategy).WANT777();
        }
        uint _wlength = wantTokens.length;
        if (_wlength > 0) {
            if (_wlength == 1) {
                return wantTokens[0];
            }
            for (uint i = 0; i < _wlength; i++) {
                address _want = wantTokens[i];
                uint _bal = WANTSTRATEGYBALANCE73(_want);
                if (_bal < wantQuota[_want]) {
                    return _want;
                }
            }
        }
        return basedWant;
    }

    function SETLAZYSELECTEDBESTSTRATEGY629(address _strategy) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        lazySelectedBestStrategy = _strategy;
    }

    function GETBESTSTRATEGY227(address _want) public view returns (address _strategy) {
        if (lazySelectedBestStrategy != address(0) && IMultiVaultStrategy(lazySelectedBestStrategy).WANT777() == _want) {
            return lazySelectedBestStrategy;
        }
        uint _wantStrategyLength = wantStrategyLength[_want];
        _strategy = address(0);
        if (_wantStrategyLength == 0) return _strategy;
        uint _totalBal = WANTSTRATEGYBALANCE73(_want);
        if (_totalBal == 0) {

            return strategies[_want][0].strategy;
        }
        uint _bestDiff = 201;
        for (uint _sid = 0; _sid < _wantStrategyLength; _sid++) {
            StrategyInfo storage sinfo = strategies[_want][_sid];
            uint _stratBal = IMultiVaultStrategy(sinfo.strategy).BALANCEOF771();
            if (_stratBal < sinfo.quota) {
                uint _diff = _stratBal.ADD260(_totalBal).MUL872(100).DIV551(_totalBal).SUB684(sinfo.percent);
                if (_diff < _bestDiff) {
                    _bestDiff = _diff;
                    _strategy = sinfo.strategy;
                }
            }
        }
        if (_strategy == address(0)) {
            _strategy = strategies[_want][0].strategy;
        }
    }

    function EARN427(address _token, uint _amount) external {
        require(msg.sender == address(vault) || msg.sender == strategist || msg.sender == governance, "!strategist");
        address _strategy = GETBESTSTRATEGY227(_token);
        if (_strategy == address(0) || IMultiVaultStrategy(_strategy).WANT777() != _token) {

            IERC20(_token).SAFETRANSFER627(address(vault), _amount);
        } else {
            IERC20(_token).SAFETRANSFER627(_strategy, _amount);
            IMultiVaultStrategy(_strategy).DEPOSIT294();
        }
    }

    function WITHDRAW_FEE118(address _want, uint _amount) external view returns (uint) {
        address _strategy = GETBESTSTRATEGY227(_want);
        return (_strategy == address(0)) ? 0 : IMultiVaultStrategy(_strategy).WITHDRAWFEE692(_amount);
    }

    function BALANCEOF771(address _want, bool _sell) external view returns (uint _totalBal) {
        uint _wlength = wantTokens.length;
        if (_wlength == 0) {
            return 0;
        }
        _totalBal = 0;
        for (uint i = 0; i < _wlength; i++) {
            address wt = wantTokens[i];
            uint _bal = WANTSTRATEGYBALANCE73(wt);
            if (wt != _want) {
                _bal = shareConverter.CONVERT_SHARES_RATE463(wt, _want, _bal);
                if (_sell) {
                    _bal = _bal.MUL872(9998).DIV551(10000);
                }
            }
            _totalBal = _totalBal.ADD260(_bal);
        }
    }

    function WITHDRAWALL927(address _strategy) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");

        IMultiVaultStrategy(_strategy).WITHDRAWALL927();
    }

    function INCASETOKENSGETSTUCK116(address _token, uint _amount) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        IERC20(_token).SAFETRANSFER627(address(vault), _amount);
    }

    function INCASESTRATEGYGETSTUCK927(address _strategy, address _token) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        IMultiVaultStrategy(_strategy).WITHDRAW808(_token);
        IERC20(_token).SAFETRANSFER627(address(vault), IERC20(_token).BALANCEOF771(address(this)));
    }

    function CLAIMINSURANCE45() external {
        require(msg.sender == governance, "!governance");
        vault.CLAIMINSURANCE45();
    }


    function HARVESTSTRATEGY825(address _strategy) external {
        require(msg.sender == address(vault) || msg.sender == strategist || msg.sender == governance, "!strategist && !vault");
        IMultiVaultStrategy(_strategy).HARVEST506(address(0));
    }

    function HARVESTWANT168(address _want) external {
        require(msg.sender == address(vault) || msg.sender == strategist || msg.sender == governance, "!strategist && !vault");
        uint _wantStrategyLength = wantStrategyLength[_want];
        address _firstStrategy = address(0);
        for (uint _sid = 0; _sid < _wantStrategyLength; _sid++) {
            StrategyInfo storage sinfo = strategies[_want][_sid];
            if (_firstStrategy == address(0)) {
                _firstStrategy = sinfo.strategy;
            } else {
                IMultiVaultStrategy(sinfo.strategy).HARVEST506(_firstStrategy);
            }
        }
        if (_firstStrategy != address(0)) {
            IMultiVaultStrategy(_firstStrategy).HARVEST506(address(0));
        }
    }

    function HARVESTALLSTRATEGIES334() external {
        require(msg.sender == address(vault) || msg.sender == strategist || msg.sender == governance, "!strategist && !vault");
        uint _wlength = wantTokens.length;
        address _firstStrategy = address(0);
        for (uint i = 0; i < _wlength; i++) {
            address _want = wantTokens[i];
            uint _wantStrategyLength = wantStrategyLength[_want];
            for (uint _sid = 0; _sid < _wantStrategyLength; _sid++) {
                StrategyInfo storage sinfo = strategies[_want][_sid];
                if (_firstStrategy == address(0)) {
                    _firstStrategy = sinfo.strategy;
                } else {
                    IMultiVaultStrategy(sinfo.strategy).HARVEST506(_firstStrategy);
                }
            }
        }
        if (_firstStrategy != address(0)) {
            IMultiVaultStrategy(_firstStrategy).HARVEST506(address(0));
        }
    }

    function SWITCHFUND172(IMultiVaultStrategy _srcStrat, IMultiVaultStrategy _destStrat, uint _amount) external {
        require(msg.sender == strategist || msg.sender == governance, "!strategist");
        _srcStrat.WITHDRAWTOCONTROLLER653(_amount);
        address _srcWant = _srcStrat.WANT777();
        address _destWant = _destStrat.WANT777();
        if (_srcWant != _destWant) {
            _amount = IERC20(_srcWant).BALANCEOF771(address(this));
            require(shareConverter.CONVERT_SHARES_RATE463(_srcWant, _destWant, _amount) > 0, "rate=0");
            IERC20(_srcWant).SAFETRANSFER627(address(shareConverter), _amount);
            shareConverter.CONVERT_SHARES33(_srcWant, _destWant, _amount);
        }
        IERC20(_destWant).SAFETRANSFER627(address(_destStrat), IERC20(_destWant).BALANCEOF771(address(this)));
        _destStrat.DEPOSIT294();
    }

    function WITHDRAW808(address _want, uint _amount) external returns (uint _withdrawFee) {
        require(msg.sender == address(vault), "!vault");
        _withdrawFee = 0;
        uint _toWithdraw = _amount;
        uint _wantStrategyLength = wantStrategyLength[_want];
        uint _received;
        for (uint _sid = _wantStrategyLength; _sid > 0; _sid--) {
            StrategyInfo storage sinfo = strategies[_want][_sid - 1];
            IMultiVaultStrategy _strategy = IMultiVaultStrategy(sinfo.strategy);
            uint _stratBal = _strategy.BALANCEOF771();
            if (_toWithdraw < _stratBal) {
                _received = _strategy.WITHDRAW808(_toWithdraw);
                _withdrawFee = _withdrawFee.ADD260(_strategy.WITHDRAWFEE692(_received));
                return _withdrawFee;
            }
            _received = _strategy.WITHDRAWALL927();
            _withdrawFee = _withdrawFee.ADD260(_strategy.WITHDRAWFEE692(_received));
            if (_received >= _toWithdraw) {
                return _withdrawFee;
            }
            _toWithdraw = _toWithdraw.SUB684(_received);
        }
        if (_toWithdraw > 0) {

            uint _wlength = wantTokens.length;
            for (uint i = _wlength; i > 0; i--) {
                address wt = wantTokens[i - 1];
                if (wt != _want) {
                    (uint _wamt, uint _wdfee) = _WITHDRAWOTHERWANT971(_want, wt, _toWithdraw);
                    _withdrawFee = _withdrawFee.ADD260(_wdfee);
                    if (_wamt >= _toWithdraw) {
                        return _withdrawFee;
                    }
                    _toWithdraw = _toWithdraw.SUB684(_wamt);
                }
            }
        }
        return _withdrawFee;
    }

    function _WITHDRAWOTHERWANT971(address _want, address _other, uint _amount) internal returns (uint _wantAmount, uint _withdrawFee) {

        uint b = IERC20(_want).BALANCEOF771(address(this));
        _withdrawFee = 0;
        if (b >= _amount) {
            _wantAmount = b;
        } else {
            uint _toWithdraw = _amount.SUB684(b);
            uint _toWithdrawOther = _toWithdraw.MUL872(101).DIV551(100);
            uint _otherBal = IERC20(_other).BALANCEOF771(address(this));
            if (_otherBal < _toWithdrawOther) {
                uint _otherStrategyLength = wantStrategyLength[_other];
                for (uint _sid = _otherStrategyLength; _sid > 0; _sid--) {
                    StrategyInfo storage sinfo = strategies[_other][_sid - 1];
                    IMultiVaultStrategy _strategy = IMultiVaultStrategy(sinfo.strategy);
                    uint _stratBal = _strategy.BALANCEOF771();
                    uint _needed = _toWithdrawOther.SUB684(_otherBal);
                    uint _wdamt = (_needed < _stratBal) ? _needed : _stratBal;
                    _strategy.WITHDRAWTOCONTROLLER653(_wdamt);
                    _withdrawFee = _withdrawFee.ADD260(_strategy.WITHDRAWFEE692(_wdamt));
                    _otherBal = IERC20(_other).BALANCEOF771(address(this));
                    if (_otherBal >= _toWithdrawOther) {
                        break;
                    }
                }
            }
            IERC20(_other).SAFETRANSFER627(address(shareConverter), _otherBal);
            shareConverter.CONVERT_SHARES33(_other, _want, _otherBal);
            _wantAmount = IERC20(_want).BALANCEOF771(address(this));
        }
        IERC20(_want).SAFETRANSFER627(address(vault), _wantAmount);
    }
}
