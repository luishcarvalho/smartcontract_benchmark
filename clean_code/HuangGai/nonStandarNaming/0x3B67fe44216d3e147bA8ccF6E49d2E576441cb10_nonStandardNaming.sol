





pragma solidity 0.6.12;




library SafeMath {

    function ADD864(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB868(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB868(a, b, "SafeMath: subtraction overflow");
    }


    function SUB868(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL988(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV926(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV926(a, b, "SafeMath: division by zero");
    }


    function DIV926(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD713(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD713(a, b, "SafeMath: modulo by zero");
    }


    function MOD713(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



library TransferHelper {
    function SAFEAPPROVE567(address token, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function SAFETRANSFER962(address token, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function SAFETRANSFERFROM567(address token, address from, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function SAFETRANSFERETH46(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}



library Math {

    function MAX98(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }


    function MIN757(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }


    function AVERAGE252(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}



contract ReentrancyGuard {











    uint256 private constant _not_entered371 = 1;
    uint256 private constant _entered907 = 2;

    uint256 private _status;

    constructor () internal {
        _status = _not_entered371;
    }


    modifier NONREENTRANT361() {

        require(_status != _entered907, "ReentrancyGuard: reentrant call");


        _status = _entered907;

        _;



        _status = _not_entered371;
    }
}


interface ICoFiXStakingRewards {




    function REWARDSVAULT139() external view returns (address);



    function LASTBLOCKREWARDAPPLICABLE573() external view returns (uint256);


    function REWARDPERTOKEN122() external view returns (uint256);




    function EARNED893(address account) external view returns (uint256);



    function ACCRUED168() external view returns (uint256);



    function REWARDRATE36() external view returns (uint256);



    function TOTALSUPPLY567() external view returns (uint256);




    function BALANCEOF980(address account) external view returns (uint256);



    function STAKINGTOKEN641() external view returns (address);



    function REWARDSTOKEN657() external view returns (address);





    function STAKE225(uint256 amount) external;




    function STAKEFOROTHER357(address other, uint256 amount) external;



    function WITHDRAW360(uint256 amount) external;


    function EMERGENCYWITHDRAW536() external;


    function GETREWARD438() external;

    function GETREWARDANDSTAKE43() external;


    function EXIT912() external;


    function ADDREWARD881(uint256 amount) external;


    event REWARDADDED378(address sender, uint256 reward);
    event STAKED268(address indexed user, uint256 amount);
    event STAKEDFOROTHER964(address indexed user, address indexed other, uint256 amount);
    event WITHDRAWN805(address indexed user, uint256 amount);
    event EMERGENCYWITHDRAW7(address indexed user, uint256 amount);
    event REWARDPAID501(address indexed user, uint256 reward);
}


interface ICoFiXVaultForLP {

    enum POOL_STATE {INVALID, ENABLED, DISABLED}

    event NEWPOOLADDED559(address pool, uint256 index);
    event POOLENABLED434(address pool);
    event POOLDISABLED539(address pool);

    function SETGOVERNANCE394(address _new) external;
    function SETINITCOFIRATE698(uint256 _new) external;
    function SETDECAYPERIOD166(uint256 _new) external;
    function SETDECAYRATE667(uint256 _new) external;

    function ADDPOOL220(address pool) external;
    function ENABLEPOOL504(address pool) external;
    function DISABLEPOOL836(address pool) external;
    function SETPOOLWEIGHT937(address pool, uint256 weight) external;
    function BATCHSETPOOLWEIGHT100(address[] memory pools, uint256[] memory weights) external;
    function DISTRIBUTEREWARD70(address to, uint256 amount) external;

    function GETPENDINGREWARDOFLP590(address pair) external view returns (uint256);
    function CURRENTPERIOD82() external view returns (uint256);
    function CURRENTCOFIRATE163() external view returns (uint256);
    function CURRENTPOOLRATE277(address pool) external view returns (uint256 poolRate);
    function CURRENTPOOLRATEBYPAIR255(address pair) external view returns (uint256 poolRate);




    function STAKINGPOOLFORPAIR714(address pair) external view returns (address pool);

    function GETPOOLINFO427(address pool) external view returns (POOL_STATE state, uint256 weight);
    function GETPOOLINFOBYPAIR166(address pair) external view returns (POOL_STATE state, uint256 weight);

    function GETENABLEDPOOLCNT412() external view returns (uint256);

    function GETCOFISTAKINGPOOL12() external view returns (address pool);

}



interface IERC20 {

    function TOTALSUPPLY567() external view returns (uint256);


    function BALANCEOF980(address account) external view returns (uint256);


    function TRANSFER204(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE758(address owner, address spender) external view returns (uint256);


    function APPROVE960(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM982(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER211(address indexed from, address indexed to, uint256 value);


    event APPROVAL330(address indexed owner, address indexed spender, uint256 value);
}


interface ICoFiStakingRewards {



    function REWARDPERTOKEN122() external view returns (uint256);




    function EARNED893(address account) external view returns (uint256);



    function ACCRUED168() external view returns (uint256);



    function TOTALSUPPLY567() external view returns (uint256);




    function BALANCEOF980(address account) external view returns (uint256);



    function STAKINGTOKEN641() external view returns (address);



    function REWARDSTOKEN657() external view returns (address);





    function STAKE225(uint256 amount) external;




    function STAKEFOROTHER357(address other, uint256 amount) external;



    function WITHDRAW360(uint256 amount) external;


    function EMERGENCYWITHDRAW536() external;


    function GETREWARD438() external;


    function ADDETHREWARD660() external payable;


    function EXIT912() external;


    event STAKED268(address indexed user, uint256 amount);
    event STAKEDFOROTHER964(address indexed user, address indexed other, uint256 amount);
    event WITHDRAWN805(address indexed user, uint256 amount);
    event SAVINGWITHDRAWN125(address indexed to, uint256 amount);
    event EMERGENCYWITHDRAW7(address indexed user, uint256 amount);
    event REWARDPAID501(address indexed user, uint256 reward);

}


interface ICoFiXFactory {

    event PAIRCREATED889(address indexed token, address pair, uint256);
    event NEWGOVERNANCE470(address _new);
    event NEWCONTROLLER331(address _new);
    event NEWFEERECEIVER222(address _new);
    event NEWFEEVAULTFORLP508(address token, address feeVault);
    event NEWVAULTFORLP769(address _new);
    event NEWVAULTFORTRADER72(address _new);
    event NEWVAULTFORCNODE372(address _new);




    function CREATEPAIR976(
        address token
        )
        external
        returns (address pair);

    function GETPAIR599(address token) external view returns (address pair);
    function ALLPAIRS153(uint256) external view returns (address pair);
    function ALLPAIRSLENGTH789() external view returns (uint256);

    function GETTRADEMININGSTATUS473(address token) external view returns (bool status);
    function SETTRADEMININGSTATUS493(address token, bool status) external;
    function GETFEEVAULTFORLP473(address token) external view returns (address feeVault);
    function SETFEEVAULTFORLP669(address token, address feeVault) external;

    function SETGOVERNANCE394(address _new) external;
    function SETCONTROLLER726(address _new) external;
    function SETFEERECEIVER908(address _new) external;
    function SETVAULTFORLP99(address _new) external;
    function SETVAULTFORTRADER40(address _new) external;
    function SETVAULTFORCNODE20(address _new) external;
    function GETCONTROLLER295() external view returns (address controller);
    function GETFEERECEIVER766() external view returns (address feeReceiver);
    function GETVAULTFORLP604() external view returns (address vaultForLP);
    function GETVAULTFORTRADER901() external view returns (address vaultForTrader);
    function GETVAULTFORCNODE682() external view returns (address vaultForCNode);
}



contract CoFiXStakingRewards is ICoFiXStakingRewards, ReentrancyGuard {
    using SafeMath for uint256;



    address public override immutable rewardsToken;
    address public override immutable stakingToken;

    address public immutable factory;

    uint256 public lastUpdateBlock;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;



    constructor(
        address _rewardsToken,
        address _stakingToken,
        address _factory
    ) public {
        rewardsToken = _rewardsToken;
        stakingToken = _stakingToken;
        require(ICoFiXFactory(_factory).GETVAULTFORLP604() != address(0), "VaultForLP not set yet");
        factory = _factory;
        lastUpdateBlock = 11040688;
    }




    function REWARDSVAULT139() public virtual override view returns (address) {
        return ICoFiXFactory(factory).GETVAULTFORLP604();
    }

    function TOTALSUPPLY567() external override view returns (uint256) {
        return _totalSupply;
    }

    function BALANCEOF980(address account) external override view returns (uint256) {
        return _balances[account];
    }

    function LASTBLOCKREWARDAPPLICABLE573() public override view returns (uint256) {
        return block.number;
    }

    function REWARDPERTOKEN122() public override view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.ADD864(
                ACCRUED168().MUL988(1e18).DIV926(_totalSupply)
            );
    }

    function _REWARDPERTOKENANDACCRUED426() internal view returns (uint256, uint256) {
        if (_totalSupply == 0) {


            return (rewardPerTokenStored, 0);
        }
        uint256 _accrued = ACCRUED168();
        uint256 _rewardPerToken = rewardPerTokenStored.ADD864(
                _accrued.MUL988(1e18).DIV926(_totalSupply)
            );
        return (_rewardPerToken, _accrued);
    }

    function REWARDRATE36() public virtual override view returns (uint256) {
        return ICoFiXVaultForLP(REWARDSVAULT139()).CURRENTPOOLRATE277(address(this));
    }

    function ACCRUED168() public virtual override view returns (uint256) {

        uint256 blockReward = LASTBLOCKREWARDAPPLICABLE573().SUB868(lastUpdateBlock).MUL988(REWARDRATE36());

        uint256 tradingReward = ICoFiXVaultForLP(REWARDSVAULT139()).GETPENDINGREWARDOFLP590(stakingToken);
        return blockReward.ADD864(tradingReward);
    }

    function EARNED893(address account) public override view returns (uint256) {
        return _balances[account].MUL988(REWARDPERTOKEN122().SUB868(userRewardPerTokenPaid[account])).DIV926(1e18).ADD864(rewards[account]);
    }



    function STAKE225(uint256 amount) external override NONREENTRANT361 UPDATEREWARD178(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.ADD864(amount);
        _balances[msg.sender] = _balances[msg.sender].ADD864(amount);
        TransferHelper.SAFETRANSFERFROM567(stakingToken, msg.sender, address(this), amount);
        emit STAKED268(msg.sender, amount);
    }

    function STAKEFOROTHER357(address other, uint256 amount) external override NONREENTRANT361 UPDATEREWARD178(other) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.ADD864(amount);
        _balances[other] = _balances[other].ADD864(amount);
        TransferHelper.SAFETRANSFERFROM567(stakingToken, msg.sender, address(this), amount);
        emit STAKEDFOROTHER964(msg.sender, other, amount);
    }

    function WITHDRAW360(uint256 amount) public override NONREENTRANT361 UPDATEREWARD178(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.SUB868(amount);
        _balances[msg.sender] = _balances[msg.sender].SUB868(amount);
        TransferHelper.SAFETRANSFER962(stakingToken, msg.sender, amount);
        emit WITHDRAWN805(msg.sender, amount);
    }


    function EMERGENCYWITHDRAW536() external override NONREENTRANT361 {
        uint256 amount = _balances[msg.sender];
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.SUB868(amount);
        _balances[msg.sender] = 0;
        rewards[msg.sender] = 0;
        TransferHelper.SAFETRANSFER962(stakingToken, msg.sender, amount);
        emit EMERGENCYWITHDRAW7(msg.sender, amount);
    }

    function GETREWARD438() public override NONREENTRANT361 UPDATEREWARD178(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;

            uint256 transferred = _SAFECOFITRANSFER191(msg.sender, reward);
            emit REWARDPAID501(msg.sender, transferred);
        }
    }


    function GETREWARDANDSTAKE43() external override NONREENTRANT361 UPDATEREWARD178(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            address cofiStakingPool = ICoFiXVaultForLP(REWARDSVAULT139()).GETCOFISTAKINGPOOL12();
            require(cofiStakingPool != address(0), "cofiStakingPool not set");

            address _rewardsToken = rewardsToken;
            IERC20(_rewardsToken).APPROVE960(cofiStakingPool, reward);
            ICoFiStakingRewards(cofiStakingPool).STAKEFOROTHER357(msg.sender, reward);
            IERC20(_rewardsToken).APPROVE960(cofiStakingPool, 0);
            emit REWARDPAID501(msg.sender, reward);
        }
    }

    function EXIT912() external override {
        WITHDRAW360(_balances[msg.sender]);
        GETREWARD438();
    }


    function ADDREWARD881(uint256 amount) public override NONREENTRANT361 UPDATEREWARD178(address(0)) {

        TransferHelper.SAFETRANSFERFROM567(rewardsToken, msg.sender, address(this), amount);

        rewardPerTokenStored = rewardPerTokenStored.ADD864(amount.MUL988(1e18).DIV926(_totalSupply));
        emit REWARDADDED378(msg.sender, amount);
    }


    function _SAFECOFITRANSFER191(address _to, uint256 _amount) internal returns (uint256) {
        uint256 cofiBal = IERC20(rewardsToken).BALANCEOF980(address(this));
        if (_amount > cofiBal) {
            _amount = cofiBal;
        }
        TransferHelper.SAFETRANSFER962(rewardsToken, _to, _amount);
        return _amount;
    }



    modifier UPDATEREWARD178(address account) virtual {


        (uint256 newRewardPerToken, uint256 newAccrued) = _REWARDPERTOKENANDACCRUED426();
        rewardPerTokenStored = newRewardPerToken;
        if (newAccrued > 0) {


            ICoFiXVaultForLP(REWARDSVAULT139()).DISTRIBUTEREWARD70(address(this), newAccrued);
        }
        lastUpdateBlock = LASTBLOCKREWARDAPPLICABLE573();
        if (account != address(0)) {
            rewards[account] = EARNED893(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }



    event REWARDADDED378(address sender, uint256 reward);
    event STAKED268(address indexed user, uint256 amount);
    event STAKEDFOROTHER964(address indexed user, address indexed other, uint256 amount);
    event WITHDRAWN805(address indexed user, uint256 amount);
    event EMERGENCYWITHDRAW7(address indexed user, uint256 amount);
    event REWARDPAID501(address indexed user, uint256 reward);
}
