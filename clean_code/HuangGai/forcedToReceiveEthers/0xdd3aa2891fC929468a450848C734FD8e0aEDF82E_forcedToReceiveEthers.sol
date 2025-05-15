



pragma solidity ^0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract LockIdGen {

    uint256 public requestCount;

    constructor() public {
        requestCount = 0;
    }

    function generateLockId() internal returns (bytes32 lockId) {
        return keccak256(abi.encodePacked(blockhash(block.number-1), address(this), ++requestCount));
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

    function safeTransfer(StandardToken token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(StandardToken token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(StandardToken token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(StandardToken token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(StandardToken token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function callOptionalReturn(ERC20 token, bytes memory data) private {








        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ManagerUpgradeable is LockIdGen {

    struct ChangeRequest {
        address proposedNew;
        address proposedClear;
    }


    mapping (address => address) public managers;

    mapping (bytes32 => ChangeRequest) public changeReqs;

    uint256     public    mancount  ;


    constructor(
         address  [] memory _mans
    )
      LockIdGen()
      public
    {
        uint256 numMans = _mans.length;
        for (uint256 i = 0; i < numMans; i++) {
          address pto = _mans[i];
          require(pto != address(0));
          managers[pto] = pto;
        }
        mancount = 0;
    }



    modifier onlyManager {
        require(msg.sender == managers[msg.sender],"onlyManger must use");
        _;
    }


    function replaceManager(address _new,address _clear) public onlyManager {
        require( _clear != address(0) || _new != address(0) );

        require( _clear == address(0) || managers[_clear] == _clear);

        if(_new != address(0))
        {
            managers[_new] = _new;
            mancount = mancount + 1;
        }

        if(_clear != address(0))
        {
            delete managers[_clear];
            mancount = mancount - 1;
        }

    }


    function requestChange(address _new,address _clear) public onlyManager returns (bytes32 lockId) {
        require( _clear != address(0) || _new != address(0) );

        require( _clear == address(0) || managers[_clear] == _clear);

        lockId = generateLockId();

        changeReqs[lockId] = ChangeRequest({
            proposedNew: _new,
            proposedClear: _clear
        });

        emit ChangeRequested(lockId, msg.sender, _new,_clear);
    }

    event ChangeRequested(
        bytes32 _lockId,
        address _msgSender,
        address _new,
        address _clear
    );

   function confirmChange(bytes32 _lockId) public onlyManager {
        ChangeRequest storage changeRequest = changeReqs[_lockId];
        require( changeRequest.proposedNew != address(0) || changeRequest.proposedClear != address(0));

        if(changeRequest.proposedNew != address(0))
        {
            managers[changeRequest.proposedNew] = changeRequest.proposedNew;
            mancount = mancount + 1;
        }

        if(changeRequest.proposedClear != address(0))
        {
            delete managers[changeRequest.proposedClear];
            mancount = mancount - 1;
        }

        delete changeReqs[_lockId];

        emit ChangeConfirmed(_lockId, changeRequest.proposedNew,changeRequest.proposedClear);
    }
    event ChangeConfirmed(bytes32 _lockId, address _newCustodian, address _clearCustodian);

    function sweepChange(bytes32 _lockId) public onlyManager {
        ChangeRequest storage changeRequest=changeReqs[_lockId];
        require((changeRequest.proposedNew != address(0) || changeRequest.proposedClear != address(0) ));
        delete changeReqs[_lockId];
        emit ChangeSweep(_lockId, msg.sender);
    }
    event ChangeSweep(bytes32 _lockId, address _sender);

    function sweeptoken(address tokenaddr,uint256 amount) public onlyManager{
        TransferHelper.safeTransfer(tokenaddr,msg.sender,amount);
    }
    function sweepeth(uint256 amount) public onlyManager{
        msg.sender.transfer(amount);
    }
}

contract ERC20Basic {

    event Transfer(address indexed from, address indexed to, uint256 value);


    function totalSupply() public view returns (uint256);
    function balanceOf(address addr) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract ERC20 is ERC20Basic {

    event Approval(address indexed owner, address indexed agent, uint256 value);


    function allowance(address owner, address agent) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address agent, uint256 value) public returns (bool);

}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;


  string public name;
  string public symbol;
  uint8 public decimals = 18;


  uint256 _totalSupply;
  mapping(address => uint256) _balances;




  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address addr) public view returns (uint256 balance) {
    return _balances[addr];
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(to != address(0));
    require(value <= _balances[msg.sender]);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }



}

contract StandardToken is ERC20, BasicToken {



  mapping (address => mapping (address => uint256)) _allowances;




  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(to != address(0));
    require(value <= _balances[from],"value lt from");
    require(value <= _allowances[from][msg.sender],"value lt _allowances from ");

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

  function approve(address agent, uint256 value) public returns (bool) {
    _allowances[msg.sender][agent] = value;
    emit Approval(msg.sender, agent, value);
    return true;
  }

  function allowance(address owner, address agent) public view returns (uint256) {
    return _allowances[owner][agent];
  }

  function increaseApproval(address agent, uint value) public returns (bool) {
    _allowances[msg.sender][agent] = _allowances[msg.sender][agent].add(value);
    emit Approval(msg.sender, agent, _allowances[msg.sender][agent]);
    return true;
  }

  function decreaseApproval(address agent, uint value) public returns (bool) {
    uint allowanceValue = _allowances[msg.sender][agent];
    if (value > allowanceValue) {
      _allowances[msg.sender][agent] = 0;
    } else {
      _allowances[msg.sender][agent] = allowanceValue.sub(value);
    }
    emit Approval(msg.sender, agent, _allowances[msg.sender][agent]);
    return true;
  }

}



contract MinableToken is StandardToken,ManagerUpgradeable{


    uint256 maxMined =0;
    constructor(uint256 _maxMined,address [] memory _mans) public ManagerUpgradeable(_mans){
        maxMined = _maxMined;
    }

    function _mint(address to, uint256 value) public onlyManager  {
        require(maxMined==0||_totalSupply.add(value)<=maxMined,"_mint value invalid");
        _totalSupply = _totalSupply.add(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) public {
        _balances[from] = _balances[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }


}

contract DFKII is MinableToken {

  string public name = "Defiking.finance Version 2.0";
  string public symbol = "DFKII";
  uint8 public decimals = 18;






  constructor(address [] memory _mans,uint256 _maxMined) public MinableToken(_maxMined,_mans) {





  }


}

contract USDT is MinableToken {

  string public name = "Defiking.finance Version 2.0";
  string public symbol = "USDT";
  uint8 public decimals = 6;






  constructor(address [] memory _mans,uint256 _maxMined) public MinableToken(_maxMined,_mans) {





  }


}


contract DFK is ManagerUpgradeable {


    function stakingDeposit(uint256 value) public payable returns (bool);


    function profit2Staking(uint256 value)public  returns (bool success);


    function withdrawProfit(address to)public  returns (bool success);


    function withdrawStaking(address to,uint256 value)public  returns (bool success);


    function withdrawAll(address to)public  returns (bool success);



    function totalMiners() public view returns (uint256);

    function totalStaking() public view returns (uint256);


    function poolBalance() public view returns (uint256);


    function minedBalance() public view returns (uint256);


    function stakingBalance(address miner) public view returns (uint256);


    function profitBalance(address miner) public view returns (uint256);



    function pauseStaking()public  returns (bool success);


    function resumeStaking()public  returns (bool success);

}

contract DFKImplement is DFK {

    using SafeMath for uint256;
    using SafeERC20 for StandardToken;

    int public status;

    struct StakingLog{
        uint256   staking_time;
        uint256   profit_time;
        uint256   staking_value;
        uint256   unstaking_value;
    }
    mapping(address => StakingLog) public stakings;

    uint256  public cleanup_time;

    uint256  public profit_period;

    uint256  public period_bonus;

    mapping(address => uint256) public balanceProfit;
    mapping(address => uint256) public balanceStaking;

    StandardToken    public     dfkToken;

    uint256 public  _totalMiners;
    uint256 public  _totalStaking;
    uint256 public  totalProfit;

    uint256 public  minePoolBalance;

    modifier onStaking {
        require(status == 1,"please start minner");
        _;
    }
    event ProfitLog(
        address indexed from,
        uint256 profit_time,
        uint256 staking_value,
        uint256 unstaking_value,
        uint256 profit_times,
        uint256 profit
    );

    constructor(address _dfkToken,int decimals,address  [] memory _mans) public ManagerUpgradeable(_mans){
        status = 0;
        cleanup_time = now;
        profit_period = 24*3600;
        period_bonus = 100000*(10 ** uint256(decimals));
        cleanup_time = now;
        dfkToken = StandardToken(_dfkToken);
    }


    function addMinePool(uint256 stakevalue) public onStaking payable returns (uint256){
        require(stakevalue>0);


        dfkToken.safeTransferFrom(msg.sender,address(this),stakevalue);

        minePoolBalance = minePoolBalance.add(stakevalue);

        return minePoolBalance;
    }



    function stakingDeposit(uint256 stakevalue) public onStaking payable returns (bool){
        require(stakevalue>0,"stakevalue is gt zero");


        dfkToken.transferFrom(msg.sender,address(this),stakevalue);

        _totalStaking = _totalStaking.add(stakevalue);

        return addMinerStaking(msg.sender,stakevalue);
    }


    function addMinerStaking(address miner,uint256 stakevalue) internal  returns (bool){
        balanceStaking[miner] = balanceStaking[miner].add(stakevalue);

        StakingLog memory slog=stakings[miner];

        if(slog.profit_time < cleanup_time){
            stakings[miner] = StakingLog({
                staking_time:now,
                profit_time:now,
                staking_value:0,
                unstaking_value:stakevalue
            });
            _totalMiners = _totalMiners.add(1);
        }else if(now.sub(slog.profit_time) >= profit_period){
            uint256   profit_times = now.sub(slog.profit_time).div(profit_period);

            stakings[miner] = StakingLog({
                staking_time:now,
                profit_time:now,
                staking_value:slog.staking_value.add(slog.unstaking_value),
                unstaking_value:stakevalue
            });


            uint256   profit =  period_bonus.mul(stakings[miner].staking_value).mul(profit_times).div(_totalStaking);
            emit ProfitLog(miner,stakings[miner].profit_time,stakings[miner].staking_value,stakings[miner].unstaking_value,profit_times,profit);
            require(minePoolBalance>=profit,"minePoolBalance lt profit");
            minePoolBalance = minePoolBalance.sub(profit);


            balanceProfit[miner]=balanceProfit[miner].add(profit);
            totalProfit = totalProfit.add(profit);

        }else {
            stakings[miner] = StakingLog({
                staking_time:now,
                profit_time:slog.profit_time,
                staking_value:slog.staking_value,
                unstaking_value:slog.unstaking_value.add(stakevalue)
            });
        }
        return true;
    }



    function profit2Staking(uint256 value)public onStaking returns (bool success){

        require(balanceProfit[msg.sender]>=value);
        balanceProfit[msg.sender] = balanceProfit[msg.sender].sub(value);
        return addMinerStaking(msg.sender,value);

    }


    function withdrawProfit(address to)public  returns (bool success){

        require(to != address(0));

        addMinerStaking(msg.sender,0);

        uint256 profit = balanceProfit[msg.sender];
        balanceProfit[msg.sender] = 0;

        require(dfkToken.transfer(to,profit));

        return true;

    }


    function withdrawStaking(address to,uint256 value)public  returns (bool success){
        require(value>0);
        require(to != address(0));
        require(balanceStaking[msg.sender]>=value);
        require(_totalStaking>=value);

        _totalStaking=_totalStaking.sub(value);

        balanceStaking[msg.sender] = balanceStaking[msg.sender].sub(value);
        StakingLog memory slog=stakings[msg.sender];


        stakings[msg.sender] = StakingLog({
            staking_time:now,
            profit_time:slog.profit_time,
            staking_value:0,
            unstaking_value:balanceStaking[msg.sender]
        });

        require(dfkToken.transfer(to,value));

        return true;
    }


    function withdrawAll(address to)public  returns (bool success){
        require(to != address(0));

        addMinerStaking(msg.sender,0);

        _totalStaking=_totalStaking.sub(balanceStaking[msg.sender]);

        uint256 total=balanceStaking[msg.sender].add(balanceProfit[msg.sender]);

        balanceProfit[msg.sender]=0;
        balanceStaking[msg.sender] = 0;

        stakings[msg.sender] = StakingLog({
            staking_time:0,
            profit_time:0,
            staking_value:0,
            unstaking_value:0
        });

        require(dfkToken.transfer(to,total));

        return true;
    }


    function totalMiners() public view returns (uint256){
        return _totalMiners;
    }


    function totalStaking() public view returns (uint256){
        return _totalStaking;

    }

    function poolBalance() public view returns (uint256){
        return minePoolBalance;
    }


    function minedBalance() public view returns (uint256){
        return totalProfit;
    }


    function stakingBalance(address miner) public view returns (uint256){
        return balanceStaking[miner];
    }



    function profitBalance(address miner) public view returns (uint256){
        return balanceProfit[miner];
    }


    function pauseStaking()public onlyManager  returns (bool ){
        status = 0;
    }


    function resumeStaking()public onlyManager returns (bool ){
       status = 1;
    }
}


contract DFKImplHelper{

    using SafeMath for uint256;

    DFKImplement public dfkImpl;

    constructor(address _dfkImpl) public{
        dfkImpl = DFKImplement(_dfkImpl);
    }

    function calcProfit(address miner) public view returns (uint256)
    {
        (,uint256   profit_time,uint256   staking_value,) = dfkImpl.stakings(miner);
        if(profit_time < dfkImpl.cleanup_time()){
            return 0;
        }else if(now.sub(profit_time) >= dfkImpl.profit_period()){
            uint256   profit_times = now.sub(profit_time).div(dfkImpl.profit_period());
            uint256   profit =  dfkImpl.period_bonus().mul(staking_value).mul(profit_times).div(dfkImpl._totalStaking());
            return profit;
        }else {
            return 0;
        }

    }

    function calcProfitForFee(address miner,uint256 totalFee,uint256 lastFetchFee) public view returns (uint256)
    {
        (,uint256   profit_time,uint256   staking_value,) = dfkImpl.stakings(miner);

        if(address(this).balance == 0) {
            return 0;
        }
        if(profit_time < dfkImpl.cleanup_time()){
            return 0;
        }else {

            uint256   profit =  totalFee.mul(staking_value).div(dfkImpl._totalStaking());
            if(profit>lastFetchFee){
                return profit.sub(lastFetchFee);
            }else{
                return 0;
            }


        }

    }


}


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


contract DTradeLiquids is StandardToken {

  string public name = "Defiking.finance swap";
  string public symbol = "DTrade-V1 LP";
  uint8 public decimals = 18;




  address owner;

  constructor() public {

     owner = msg.sender;
  }

  modifier onlyOwner {
        require(msg.sender == owner);
        _;
   }

  function _mint(address to, uint value) public onlyOwner  {
        _totalSupply = _totalSupply.add(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) public onlyOwner{
        _balances[from] = _balances[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }





}


interface Refers {

    function rewards2Super(address user,uint256 totalReward) external returns (bool);

}


contract DFKExPair is ManagerUpgradeable{
    using SafeMath for uint256;
    using SafeERC20 for ERC20;


    address public token0;
    address public token1;

    uint8   public price_decimal = 8;
    uint256 public cur_price  = 0;
    uint    public fee2Liquid = 22;
    uint    public fee2Refs = 3;
    uint    public fee2Burn = 5;
    uint256 public feeTotal=30;
    uint256 public PRICE_MOD=10000;
    uint256 public FEE_MOD=10000;
    uint256 public TOKEN_DECIMAL_DIF;
    uint256 public reserve0 =0;
    uint256 public reserve1 =0;
    uint256 public decimal0;
    uint256 public decimal1;
    uint256 public fee = 0;
    uint256 public priceFlips = 1;
    uint256 public totalProfitForLiquids =0;
    uint256 public totalProfitRefs =0;
    uint256 public totalProfitBurn =0;
    uint256 public totalLiquids = 0;

    mapping(address => uint256[]) public liquidBonusLog;

    address public liquidToken;

    Refers public  refers;
    address public isDfkiiRefs;

    uint256 public unlocked = 0;
    uint256 public miniLiquid = 100000*(10 **18);
    modifier onLiquity {
        require(address(this).balance == 1,"please wait liquity");
        _;
    }

    function pauseLiquity() public onlyManager  returns (bool ){
        unlocked = 0;
    }


    function resumeLiquity() public onlyManager returns (bool ){
       unlocked = 1;
    }

    constructor(address _token0,address _token1,address refs,uint256 initprice,address []memory _mans,uint256 _miniLiquid) public ManagerUpgradeable(_mans){

        token0 = _token0;
        token1 = _token1;
        if(_token0 == address(0x0)){
            decimal0 = 10 **18;
        } else {
            decimal0 = 10 **uint256(StandardToken(_token0).decimals());
        }

        if(_token1 == address(0x0)){
            decimal1 = 10 **18;
        } else {
            decimal1 = 10 **uint256(StandardToken(_token1).decimals());
        }

        cur_price = initprice;
        TOKEN_DECIMAL_DIF = decimal1.div(decimal0);

        refers = Refers(refs);
        bytes memory bytecode = type(DTradeLiquids).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        address _swapV2;
        assembly {
            _swapV2 := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        liquidToken = _swapV2;

		miniLiquid=_miniLiquid;

    }

    function setPriceMod(uint256 price_mod) onlyManager public {
        require(price_mod>0);
        PRICE_MOD=price_mod;
    }



    function fixPrice (uint256 price,uint _fee2Liquid,uint _fee2Refs,uint _fee2Burn,uint256 _priceFlips,uint256 _miniLiquid) onlyManager public {
        cur_price = price;
        fee2Liquid = _fee2Liquid;
        fee2Refs = _fee2Refs;
        fee2Burn = _fee2Burn;
        feeTotal = fee2Liquid+fee2Refs+fee2Burn;
        priceFlips = _priceFlips;
        miniLiquid=_miniLiquid;
    }



    function poolTokens(uint256 amount0,uint256 amount1) payable onlyManager public {
        if(token0 == address(0x0)){
            require(msg.value>=amount0);
        } else{
            TransferHelper.safeTransferFrom(token0,msg.sender,address(this),amount0);
        }

        if(token1 == address(0x0)){
            require(msg.value>=amount1,"eth not enough");
        }else{
            TransferHelper.safeTransferFrom(token1,msg.sender,address(this),amount1);
        }

        reserve0 = reserve0.add(amount0);
        reserve1 = reserve1.add(amount1);
    }
    event TotalEvent(
        uint256 totalProfitBurn,
        uint256 totalProfitRefs,
        uint256 totalProfitForLiquids,
        uint256 cur_price,
        uint256 liquidfee,
        uint256 liquidRefs,
        uint256 liquidburn
        );
    event TotalAmount(
        uint256 amount0,
        uint256 amount1,
        uint256 avg_price,
        uint256 fee
        );


    function swap(uint256 amount0,uint256 amount1 ,bool toLiquids) payable public returns(uint256,uint256){

        require(cur_price>0);

        if(amount1>0 && amount0 == 0){




            uint256 price_float = amount1.mul(priceFlips).div(decimal1);
            require(price_float<cur_price,"too large amount");
            uint256 next_price = cur_price.sub(price_float);
            uint256 avg_price = cur_price.add(next_price).div(2);

            if(token1 == address(0x0)){
                require(msg.value>=amount1);
            }else{
                require (ERC20(token1).balanceOf(msg.sender) >= amount1 );
                TransferHelper.safeTransferFrom(token1,msg.sender,address(this),amount1);
            }

            uint256 liquidfee = amount1.mul(fee2Liquid).div(FEE_MOD);
            uint256 liquidRefs = amount1.mul(fee2Refs).div(FEE_MOD);
            uint256 liquidburn = amount1.mul(fee2Burn).div(FEE_MOD);

            amount1 = amount1.sub(liquidfee).sub(liquidRefs).sub(liquidburn);

            if(address(refers)!=address(0x0)){
                TransferHelper.safeTransfer(token1,address(refers),liquidRefs);
                refers.rewards2Super(msg.sender,liquidRefs);
            }

            totalProfitBurn = totalProfitBurn.add(liquidburn);
            totalProfitRefs = totalProfitRefs.add(liquidRefs);
            totalProfitForLiquids = totalProfitForLiquids.add(liquidfee);

            amount0 = amount1.mul(avg_price).div(TOKEN_DECIMAL_DIF).div(PRICE_MOD);
            cur_price = next_price;
            if(toLiquids){
                reserve0 = reserve0.add(amount0);
                reserve1 = reserve1.add(amount1);
            }else{
                if(token0==address(0x0))
                {
                   msg.sender.transfer(amount0);
                }else{
                    TransferHelper.safeTransfer(token0,msg.sender,amount0);
                }

            }
        }
        else if(amount0 > 0  && amount1 == 0){
            if(token0 == address(0x0)) {
                require(msg.value >= amount0 );
            } else {
                require (ERC20(token0).balanceOf(msg.sender) >= amount0  );
                TransferHelper.safeTransferFrom(token0,msg.sender,address(this),amount0);
            }

            amount1 = amount0.mul(PRICE_MOD).div(cur_price);

            uint256 price_float = amount1.mul(priceFlips).div(decimal0);
            uint256 next_price = cur_price.add(price_float);

            uint256 avg_price = cur_price.add(next_price).div(2);
            amount1 = amount0.mul(TOKEN_DECIMAL_DIF).mul(PRICE_MOD).div(avg_price);


            uint256 liquidfee = amount1.mul(fee2Liquid).div(FEE_MOD);
            uint256 liquidRefs = amount1.mul(fee2Refs).div(FEE_MOD);
            uint256 liquidburn = amount1.mul(fee2Burn).div(FEE_MOD);

            amount1 = amount1.sub(liquidfee).sub(liquidRefs).sub(liquidburn);

            if(address(refers)!=address(0x0)){
                TransferHelper.safeTransfer(token1,address(refers),liquidRefs);
                refers.rewards2Super(msg.sender,liquidRefs);
            }

            totalProfitBurn = totalProfitBurn.add(liquidburn);
            totalProfitRefs = totalProfitRefs.add(liquidRefs);
            totalProfitForLiquids = totalProfitForLiquids.add(liquidfee);
            cur_price = next_price;
            if(toLiquids){
                reserve0 = reserve0.add(amount0);
                reserve1 = reserve1.add(amount1);
            }else{
                if(token1 == address(0x0)){
                    msg.sender.transfer(amount1);
                }else{
                    TransferHelper.safeTransfer(token1,msg.sender,amount1);
                }

            }

        }

        return (amount0,amount1);
    }


    function addLiquid(uint256 amount0) public onLiquity  payable  returns(uint256) {

        if(token0 == address(0x0)){
            require (msg.value >= amount0);
        }else{
            require (ERC20(token0).balanceOf(msg.sender) >= amount0  );
            TransferHelper.safeTransferFrom(token0,msg.sender,address(this),amount0.div(2));
        }

        (,uint256 buyamount1) = swap(amount0.div(2),0,true);

        uint256 totalLiquid = reserve1.add(reserve1);
        uint256 poolLiquid = ERC20(address(token1)).balanceOf(address(this));
        if(poolLiquid<miniLiquid){
            poolLiquid=miniLiquid;
        }

        uint256 mineCoin = buyamount1.add(buyamount1).mul(totalLiquid).div(poolLiquid);
        DTradeLiquids(liquidToken)._mint(msg.sender,mineCoin);
        uint256 leftCoin = amount0.sub(amount0.div(2).mul(2));
        if(leftCoin>0&&token0!=address(0x0)){
            TransferHelper.safeTransferFrom(token0,msg.sender,address(this),leftCoin);
        }
        return mineCoin;
    }

    function removeLiquid(uint256 amountL) payable public returns(uint256,uint256) {
        require(DTradeLiquids(liquidToken).balanceOf(msg.sender)>=amountL);

        uint256 totalLiquid = reserve1.add(reserve1);
        uint256 amount1 = amountL.mul((ERC20(address(token1)).balanceOf(address(this)))).div(totalLiquid).div(2);
        uint256 amount0 = amount1.mul(cur_price).div(TOKEN_DECIMAL_DIF).div(PRICE_MOD);

        require(ERC20(token1).balanceOf(address(this))>=amount1);

        reserve1 = reserve1.sub(amount1);
        reserve0 = reserve0.sub(amount0);

        DTradeLiquids(liquidToken)._burn(msg.sender,amountL);

        if(token0==address(0x0))
        {
            require(address(this).balance>=amount0);
            msg.sender.transfer(amount0);
        }else{
            require(ERC20(token0).balanceOf(address(this))>=amount0);
            TransferHelper.safeTransfer(token0,msg.sender,amount0);
        }

        if(token1==address(0x0))
        {
            require(address(this).balance>=amount1);
            msg.sender.transfer(amount1);
        }else{
            require(ERC20(token1).balanceOf(address(this))>=amount1);
            TransferHelper.safeTransfer(token1,msg.sender,amount1);
        }

        return (amount0,amount1);
    }


}


contract UserRefers is ManagerUpgradeable,Refers{
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    mapping(address => address) public relations;
    mapping(address => address[]) public superiors;
    mapping(address => address) public callers;
    mapping(address => uint256) public rewards;

    address public topAddr;
    address public token;

    constructor(address _token,address []memory _mans) public ManagerUpgradeable(_mans){
        relations[address(0x0)] = address(0x0);
        topAddr = msg.sender;
        token = _token;
    }

    function addCaller(address _newCaller) onlyManager public {
        callers[_newCaller] = _newCaller;
    }

    function removeCaller(address rmCaller) onlyManager public {
        callers[rmCaller] = address(0x0);
    }


    function buildSuperoir(address ref,uint256 maxLayer) public {
        if(relations[msg.sender]==address(0x0)) {
            relations[msg.sender] = ref;
            superiors[msg.sender].push(ref);
            address[] memory supers = superiors[ref];
            if(supers.length>0){
                superiors[msg.sender].push(supers[0]);
            }
            uint256 cc = 2;
            for(uint256 i=1;i<supers.length && cc < maxLayer;i++){
                superiors[msg.sender].push(supers[i]);
                cc++;
            }
        }
    }
    function withdrawRewards() public{
        require(rewards[msg.sender]>0);
        TransferHelper.safeTransfer(token,msg.sender,rewards[msg.sender]);
        rewards[msg.sender] = 0;
    }

    function rewards2Super(address user,uint256 totalReward) external returns (bool)
    {
        require(callers[msg.sender]==msg.sender,"caller is empty") ;

        address[] memory supers = superiors[user];
        uint256 leftReward = totalReward;
        uint256 bonus0;
        uint256 bonus1;
        uint256 bonus2;
        if(supers.length>0){
            uint256 bonus = totalReward.mul(30).div(100);
            rewards[supers[0]] = bonus;

            leftReward = leftReward.sub(bonus);
            bonus0=bonus;
        }
        if(supers.length>1){
            uint256 bonus = totalReward.mul(15).div(100);
            rewards[supers[1]] = bonus;

            leftReward = leftReward.sub(bonus);
            bonus1=bonus;
        }
        if(supers.length>2){
            uint256 preReward = leftReward.div(supers.length.sub(2));

            for(uint256 i=2;i<supers.length ;i++){

                rewards[supers[i]] = preReward;
                leftReward = leftReward.sub(preReward);
            }

            bonus2=preReward;
        }
        if(leftReward>0){

            rewards[topAddr] = leftReward;
        }
        return true;

    }


}
contract TestRefs {


    Refers public refs;
    constructor(address _ref) public {
        refs =  Refers(_ref);
    }

    function testReward(uint256 amount) public {
        refs.rewards2Super(msg.sender,amount);
    }

}


contract DTrade is ManagerUpgradeable{
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    mapping(address => mapping(address =>uint256 )) public uniswapLiquids;

    mapping(address => address) public liquidsMap;
    mapping(address => uint256)public  liquidPools;

    mapping(address => uint256) public profits4DFK1;
    mapping(address => uint256) public bonusWithdraw;
    mapping(address => uint256) public checkpointHistory;

    mapping(address => uint256) public joinTime;
    address [] public liquidPairs;

    uint256  public  peroid_total_bonus = 90000*(10 **18);
    uint256   public peroid_left_bonus = 0;
    uint256  public bonus_per_block = 9*(10 **18);
    uint256   public bonus_percent_LP = 10;

    uint256   public checkpoint_number = 0;


    uint256   public totalLiquids;

    uint256   public  totalMint;
    DFKImplHelper public dfk1Helper;

    uint256   public peroid_mined_coin = 0;

    address public token1;

    uint256 public totalFactor = 0;

    address public liquidToken;

    DFKII   public dfkii;

    constructor(address _token1,address []memory _mans) public ManagerUpgradeable(_mans){
        token1 = _token1;
        checkpoint_number = block.number+5*60;

        bytes memory bytecode = type(DTradeLiquids).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, token1));
        address _swapV2;
        assembly {
            _swapV2 := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        liquidToken = _swapV2;

    }

    function setDFKII(address _dfkii) public onlyManager {
        dfkii = DFKII(_dfkii);
    }

    function setDfk1Helper(address _dfk1Helper) public onlyManager {
        dfk1Helper = DFKImplHelper(_dfk1Helper);
    }


    function nextPeroid(uint256 total,uint256 perblock,uint256 percentLP) public onlyManager {

        totalMint = totalMint.add(peroid_total_bonus);
        peroid_total_bonus = total;
        bonus_per_block = perblock;
        bonus_percent_LP = percentLP;
        peroid_left_bonus = total;
        peroid_mined_coin = 0;
        checkpoint_number = block.number;
        joinTime[address(0x0)] = block.number;

    }

    function addUniswapPair(address uniAddr,uint256 factor) public onlyManager  {
        if(liquidsMap[uniAddr]==address(0x0)){
            uniswapLiquids[uniAddr][address(0x0)]=factor;
            totalFactor = totalFactor.add(factor);

            liquidsMap[uniAddr] = uniAddr;
            liquidPairs.push(uniAddr);

        }
    }

    function removeUniswapPair(address uniAddr) public onlyManager  {
        totalFactor = totalFactor.sub(uniswapLiquids[uniAddr][address(0x0)]);
        uniswapLiquids[uniAddr][address(0x0)]=0;
    }

    function addDfkPair(address uniAddr,uint256 factor) public onlyManager  {
        if(liquidsMap[uniAddr]==address(0x0)){
            uniswapLiquids[uniAddr][address(0x0)]=factor;
            totalFactor = totalFactor.add(factor);
            liquidsMap[uniAddr] = uniAddr;
            liquidPairs.push(uniAddr);
        }
    }

    function removeDfkPair(address uniAddr) public onlyManager  {
        totalFactor = totalFactor.sub(uniswapLiquids[uniAddr][address(0x0)]);
        uniswapLiquids[uniAddr][address(0x0)]=0;
    }


    function addLiquid(address uniAddr,uint256 amountUL) public  {
        require(uniswapLiquids[uniAddr][address(0x0)]>0);
        uint256  realBonus=calcBonus(msg.sender);
        if(realBonus>0)
        {
            dfkii._mint(msg.sender,realBonus);
        }

        TransferHelper.safeTransferFrom(uniAddr,msg.sender,address(this),amountUL);
        liquidPools[uniAddr] = liquidPools[uniAddr].add(amountUL);
        uniswapLiquids[uniAddr][msg.sender]=uniswapLiquids[uniAddr][msg.sender].add(amountUL);

        uint256 mine_liquid=amountUL.mul(uniswapLiquids[uniAddr][address(0x0)]);

        DTradeLiquids(liquidToken)._mint(msg.sender,mine_liquid);

        joinTime[msg.sender] = block.number;
        bonusWithdraw[msg.sender] = 0;
    }

    function removeLiquid(address uniAddr,uint256 amountUL) public  {
        require(uniswapLiquids[uniAddr][msg.sender]>=amountUL,'amountUL is not enough');

        uint256  realBonus=calcBonus(msg.sender);
        if(realBonus>0)
        {
            dfkii._mint(msg.sender,realBonus);
        }

        TransferHelper.safeTransfer(address(uniAddr),msg.sender,amountUL);
        uint256 mine_liquid=amountUL.mul(uniswapLiquids[uniAddr][address(0x0)]);
        DTradeLiquids(liquidToken)._burn(msg.sender,mine_liquid);
        uniswapLiquids[uniAddr][msg.sender]=uniswapLiquids[uniAddr][msg.sender].sub(amountUL);

        if(address(this).balance==0){
            joinTime[msg.sender] = 0;
        }
        else
        {
            joinTime[msg.sender] = block.number;
        }
        bonusWithdraw[msg.sender] = 0;
    }

    function mintCoin(address user) public view returns (uint256){
        if(address(this).balance==0){
            return 0;
        }
        uint256 checkTime = checkpoint_number;
        if(joinTime[user]>checkpoint_number){
            checkTime = joinTime[user];
        }
        uint256 currentBonus = bonus_per_block.mul(block.number.sub(checkTime));
        if(currentBonus>peroid_left_bonus){
            currentBonus = peroid_left_bonus;
        }


        return currentBonus;


    }


    modifier onlyJoin {
        require(joinTime[msg.sender] > 0,"onlyJoin time gt 0");
        _;
    }

    function calcDFK1Bonus(address addr) public view returns(uint256){
        if(address(this).balance == 0){
            return 0;
        }
        return dfk1Helper.calcProfitForFee(addr,mintCoin(address(0x0)).mul(bonus_percent_LP).div(100),profits4DFK1[addr]);
    }

    function withdrawDFK1Bonus() public onlyJoin returns(uint256){

        uint256 bonus=calcDFK1Bonus(msg.sender);
        if(bonus>0){
            profits4DFK1[msg.sender] = profits4DFK1[msg.sender].add(bonus);


            dfkii._mint(msg.sender,bonus);
            return bonus;
        }else{
            return 0;
        }

    }


    function withdrawBonus() public onlyJoin returns(uint256){
        uint256  realBonus=calcBonus(msg.sender);
        if(realBonus>0)
        {
            bonusWithdraw[msg.sender] = bonusWithdraw[msg.sender].add(realBonus);
            dfkii._mint(msg.sender,realBonus);

            joinTime[msg.sender] = block.number;
            bonusWithdraw[msg.sender] = 0;
        }
        return realBonus;
    }

    function calcBonus(address addr) public view returns (uint256){
        if(address(this).balance == 0){
            return 0;
        }
        if(joinTime[addr]<block.number){
            return (ERC20(liquidToken).balanceOf(addr)).div(ERC20(liquidToken).totalSupply()).mul(mintCoin(addr));
        }else{
            return 0;
        }

    }
}



library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }





}
