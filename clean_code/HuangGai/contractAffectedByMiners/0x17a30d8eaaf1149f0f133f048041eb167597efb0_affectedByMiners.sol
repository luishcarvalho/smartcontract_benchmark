






pragma solidity ^0.6.4;
contract ProxyStorage {

    function readBool(bytes32 _key) public view returns(bool) {
        return storageRead(_key) == bytes32(uint256(1));
    }

    function setBool(bytes32 _key, bool _value) internal {
        if(_value) {
            storageSet(_key, bytes32(uint256(1)));
        } else {
            storageSet(_key, bytes32(uint256(0)));
        }
    }

    function readAddress(bytes32 _key) public view returns(address) {
        return bytes32ToAddress(storageRead(_key));
    }

    function setAddress(bytes32 _key, address _value) internal {
        storageSet(_key, addressToBytes32(_value));
    }

    function storageRead(bytes32 _key) public view returns(bytes32) {
        bytes32 value;

        assembly {
            value := sload(_key)
        }
        return value;
    }

    function storageSet(bytes32 _key, bytes32 _value) internal {

        bytes32 implAddressStorageKey = _key;

        assembly {
            sstore(implAddressStorageKey, _value)
        }
    }

    function bytes32ToAddress(bytes32 _value) public pure returns(address) {
        return address(uint160(uint256(_value)));
    }

    function addressToBytes32(address _value) public pure returns(bytes32) {
        return bytes32(uint256(_value));
    }

}




pragma solidity ^0.6.4;


contract Proxy is ProxyStorage {

    bytes32 constant IMPLEMENTATION_SLOT = keccak256(abi.encodePacked("IMPLEMENTATION_SLOT"));
    bytes32 constant OWNER_SLOT = keccak256(abi.encodePacked("OWNER_SLOT"));

    modifier onlyProxyOwner() {
        require(msg.sender == readAddress(OWNER_SLOT), "Proxy.onlyProxyOwner: msg sender not owner");
        _;
    }

    constructor () public {
        setAddress(OWNER_SLOT, msg.sender);
    }

    function getProxyOwner() public view returns (address) {
       return readAddress(OWNER_SLOT);
    }

    function setProxyOwner(address _newOwner) onlyProxyOwner public {
        setAddress(OWNER_SLOT, _newOwner);
    }

    function getImplementation() public view returns (address) {
        return readAddress(IMPLEMENTATION_SLOT);
    }

    function setImplementation(address _newImplementation) onlyProxyOwner public {
        setAddress(IMPLEMENTATION_SLOT, _newImplementation);
    }


    fallback () external payable {
       return internalFallback();
    }

    receive () payable external {
        return internalFallback();
    }
    function internalFallback() internal virtual {
        address contractAddr = readAddress(IMPLEMENTATION_SLOT);
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), contractAddr, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

}




pragma solidity ^0.6.4;


contract ProxyPausable is Proxy {

    bytes32 constant PAUSED_SLOT = keccak256(abi.encodePacked("PAUSED_SLOT"));
    bytes32 constant PAUZER_SLOT = keccak256(abi.encodePacked("PAUZER_SLOT"));

    constructor() Proxy() public {
        setAddress(PAUZER_SLOT, msg.sender);
    }

    modifier onlyPauzer() {
        require(msg.sender == readAddress(PAUZER_SLOT), "ProxyPausable.onlyPauzer: msg sender not pauzer");
        _;
    }

    modifier notPaused() {
        require(!readBool(PAUSED_SLOT), "ProxyPausable.notPaused: contract is paused");
        _;
    }

    function getPauzer() public view returns (address) {
        return readAddress(PAUZER_SLOT);
    }

    function setPauzer(address _newPauzer) public onlyProxyOwner{
        setAddress(PAUZER_SLOT, _newPauzer);
    }

    function renouncePauzer() public onlyPauzer {
        setAddress(PAUZER_SLOT, address(0));
    }

    function getPaused() public view returns (bool) {
        return readBool(PAUSED_SLOT);
    }

    function setPaused(bool _value) public onlyPauzer {
        setBool(PAUSED_SLOT, _value);
    }

    function internalFallback() internal virtual override notPaused {
        super.internalFallback();
    }

}




pragma solidity ^0.6.0;




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




pragma solidity ^0.6.4;

interface ISmartPool is IERC20{

    function getJoinFeeRatio() external view returns (uint256,uint256);

    function getExitFeeRatio() external view returns (uint256,uint256);

    function joinPool(address user,uint256 _amount) external;

    function exitPool(address user,uint256 _amount) external;

    function getController() external view returns (address);

    function getTokens() external view returns (address[] memory);

    function calcTokensForAmount(uint256 _amount) external view returns (address[] memory tokens, uint256[] memory amounts);
}




pragma solidity ^0.6.4;

contract ReentryProtection {
  bytes32 public constant rpSlot = keccak256("ReentryProtection.storage.location");

  struct rps {
    uint256 lockCounter;
  }

  modifier denyReentry {
    lrps().lockCounter++;
    uint256 lockValue = lrps().lockCounter;
    _;
    require(lockValue == lrps().lockCounter, "ReentryProtection.noReentry: reentry detected");
  }

  function lrps() internal pure returns (rps storage s) {
    bytes32 loc = rpSlot;
    assembly {
      s_slot := loc
    }
  }
}





pragma solidity ^0.6.0;











abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}





pragma solidity ^0.6.0;














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





pragma solidity ^0.6.2;




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

            if (block.number > 0) {



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




pragma solidity ^0.6.4;





contract KFToken is Context,IERC20{

  using SafeMath for uint256;
  using Address for address;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  function _init(string memory name,string memory symbol,uint8 decimals)internal virtual{
    _name=name;
    _symbol=symbol;
    _decimals=decimals;
  }



  function name() public view returns (string memory) {
    return _name;
  }





  function symbol() public view returns (string memory) {
    return _symbol;
  }














  function decimals() public view returns (uint8) {
    return _decimals;
  }




  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }




  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }








  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }




  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }








  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }













  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(
      _msgSender() == sender || amount <= _allowances[sender][_msgSender()],
      "ERR_KFTOKEN_BAD_CALLER"
    );
    _transfer(sender, recipient, amount);
    if (_msgSender() != sender && _allowances[sender][_msgSender()] != uint256(-1)) {
      _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    }
    return true;
  }













  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }















  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }















  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }










  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }












  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }














  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }















  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}




pragma solidity ^0.6.4;



pragma experimental ABIEncoderV2;

abstract contract BasicSmartPool is KFToken, ISmartPool,ReentryProtection{

  address internal _controller;

  uint256 internal _cap;

  struct Fee{
    uint256 ratio;
    uint256 denominator;
  }

  Fee internal _joinFeeRatio=Fee({ratio:0,denominator:1});
  Fee internal _exitFeeRatio=Fee({ratio:0,denominator:1});

  event ControllerChanged(address indexed previousController, address indexed newController);
  event JoinFeeRatioChanged(address indexed setter, uint256 oldRatio, uint256 oldDenominator,uint256 newRatio, uint256 newDenominator);
  event ExitFeeRatioChanged(address indexed setter, uint256 oldRatio, uint256 oldDenominator,uint256 newRatio, uint256 newDenominator);
  event CapChanged(address indexed setter, uint256 oldCap, uint256 newCap);
  event PoolJoined(address indexed sender,address indexed from, uint256 amount);
  event PoolExited(address indexed sender,address indexed from, uint256 amount);
  event TokensApproved(address indexed sender,address indexed to, uint256 amount);

  modifier onlyController() {
    require(msg.sender == _controller, "BasicSmartPool.onlyController: not controller");
    _;
  }
  modifier withinCap() {
    _;
    require(totalSupply() <= _cap, "BasicSmartPool.withinCap: Cap limit reached");
  }

  function _init(string memory name,string memory symbol,uint8 decimals) internal override {
    super._init(name,symbol,decimals);
    emit ControllerChanged(_controller, msg.sender);
    _controller = msg.sender;
  }

  function getController() external override view returns (address){
    return _controller;
  }

  function setController(address controller) external onlyController denyReentry {
    emit ControllerChanged(_controller, controller);
    _controller= controller;
  }

  function getJoinFeeRatio() external override view returns (uint256,uint256){
    return (_joinFeeRatio.ratio,_joinFeeRatio.denominator);
  }

  function setJoinFeeRatio(uint256 ratio,uint256 denominator) external onlyController denyReentry {
    require(ratio>=0&&denominator>0&&ratio<=denominator,"BasicSmartPool.setJoinFeeRatio: joinFeeRatio must be >=0 and denominator>0 and ratio<=denominator");
    emit JoinFeeRatioChanged(msg.sender, _joinFeeRatio.ratio,_joinFeeRatio.denominator, ratio,denominator);
    _joinFeeRatio = Fee({
      ratio:ratio,
      denominator:denominator
    });
  }

  function getExitFeeRatio() external override view returns (uint256,uint256){
    return (_exitFeeRatio.ratio,_exitFeeRatio.denominator);
  }

  function setExitFeeRatio(uint256 ratio,uint256 denominator) external onlyController denyReentry {
    require(ratio>=0&&denominator>0&&ratio<=denominator,"BasicSmartPoolsetExitFeeRatio: exitFeeRatio must be >=0 and denominator>0 and ratio<=denominator");
    emit ExitFeeRatioChanged(msg.sender, _exitFeeRatio.ratio,_exitFeeRatio.denominator, ratio,denominator);
    _exitFeeRatio = Fee({
      ratio:ratio,
      denominator:denominator
    });
  }

  function setCap(uint256 cap) external onlyController denyReentry {
    emit CapChanged(msg.sender, _cap, cap);
    _cap = cap;
  }

  function getCap() external view returns (uint256) {
    return _cap;
  }

  function approveTokens() public virtual denyReentry{

  }

  function getTokens() external override view returns (address[] memory){
    return _getTokens();
  }

  function _getTokens()internal  virtual view returns (address[] memory tokens){

  }
  function getTokenWeight(address token) public virtual view returns(uint256 weight){

  }
  function joinPool(address user,uint256 amount) external override withinCap denyReentry{
    _joinPool(amount);
    emit PoolJoined(msg.sender,user, amount);
  }

  function exitPool(address user,uint256 amount) external override denyReentry{
    _exitPool(amount);
    emit PoolExited(msg.sender,user, amount);
  }

  function _joinPool(uint256 amount) internal virtual{

  }

  function _exitPool(uint256 amount) internal virtual{

  }
}




pragma solidity ^0.6.4;

interface IBPool {

    function isPublicSwap() external view returns (bool);
    function isFinalized() external view returns (bool);
    function isBound(address t) external view returns (bool);
    function getNumTokens() external view returns (uint);
    function getCurrentTokens() external view returns (address[] memory tokens);
    function getFinalTokens() external view returns (address[] memory tokens);
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    function getNormalizedWeight(address token) external view returns (uint);
    function getBalance(address token) external view returns (uint);
    function getSwapFee() external view returns (uint);
    function getController() external view returns (address);

    function setSwapFee(uint swapFee) external;
    function setController(address manager) external;
    function setPublicSwap(bool public_) external;
    function finalize() external;
    function bind(address token, uint balance, uint denorm) external;
    function rebind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function gulp(address token) external;

    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint spotPrice);
    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint spotPrice);

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountOut, uint spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountIn, uint spotPriceAfter);

    function joinswapExternAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    ) external returns (uint poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint poolAmountOut,
        uint maxAmountIn
    ) external returns (uint tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    ) external returns (uint tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    ) external returns (uint poolAmountIn);

    function totalSupply() external view returns (uint);
    function balanceOf(address whom) external view returns (uint);
    function allowance(address src, address dst) external view returns (uint);

    function approve(address dst, uint amt) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(
        address src, address dst, uint amt
    ) external returns (bool);

    function calcSpotPrice(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint swapFee
    ) external pure returns (uint spotPrice);

    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    ) external pure returns (uint tokenAmountOut);

    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    ) external pure returns (uint tokenAmountIn);

    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    ) external pure returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    ) external pure returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    ) external pure returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    ) external pure returns (uint poolAmountIn);

}




pragma solidity ^0.6.4;
library BMath {
  uint256 internal constant BONE = 10**18;


  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "ERR_ADD_OVERFLOW");
    return c;
  }


  function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }


  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "ERR_SUB_UNDERFLOW");
    return c;
  }


  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "ERR_MUL_OVERFLOW");
    uint256 c2 = c1 / BONE;
    return c2;
  }


  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "ERR_DIV_ZERO");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL");
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "ERR_DIV_INTERNAL");
    uint256 c2 = c1 / b;
    return c2;
  }
}




pragma solidity ^0.6.4;




contract BalLiquiditySmartPool is BasicSmartPool{

  using BMath for uint256;

  IBPool private _bPool;
  address private _publicSwapSetter;
  address private _tokenBinder;

  event LOG_JOIN(address indexed caller, address indexed tokenIn, uint256 tokenAmountIn);
  event LOG_EXIT(address indexed caller, address indexed tokenOut, uint256 tokenAmountOut);
  event PublicSwapSetterChanged(address indexed previousSetter, address indexed newSetter);
  event TokenBinderChanged(address indexed previousTokenBinder, address indexed newTokenBinder);
  event PublicSwapSet(address indexed setter, bool indexed value);
  event SwapFeeSet(address indexed setter, uint256 newFee);

  modifier ready() {
    require(address(_bPool) != address(0), "BalLiquiditySmartPool.ready: not ready");
    _;
  }

  modifier onlyPublicSwapSetter() {
    require(msg.sender == _publicSwapSetter, "BalLiquiditySmartPool.onlyPublicSwapSetter: not public swap setter");
    _;
  }

  modifier onlyTokenBinder() {
    require(msg.sender == _tokenBinder, "BalLiquiditySmartPool.onlyTokenBinder: not token binder");
    _;
  }

  function init(
    address bPool,
    string calldata name,
    string calldata symbol,
    uint256 initialSupply
  ) external {
    require(address(_bPool) == address(0), "BalLiquiditySmartPool.init: already initialised");
    require(bPool != address(0), "BalLiquiditySmartPool.init: bPool cannot be 0x00....000");
    require(initialSupply != 0, "BalLiquiditySmartPool.init: initialSupply can not zero");
    super._init(name,symbol,18);
    _bPool = IBPool(bPool);
    _publicSwapSetter = msg.sender;
    _tokenBinder = msg.sender;
    _mint(msg.sender,initialSupply);
    emit PoolJoined(msg.sender,msg.sender, initialSupply);
  }


  function setPublicSwapSetter(address newPublicSwapSetter) external onlyController denyReentry {
    emit PublicSwapSetterChanged(_publicSwapSetter, newPublicSwapSetter);
    _publicSwapSetter = newPublicSwapSetter;
  }
  function getPublicSwapSetter() external view returns (address) {
    return _publicSwapSetter;
  }

  function setTokenBinder(address newTokenBinder) external onlyController denyReentry {
    emit TokenBinderChanged(_tokenBinder, newTokenBinder);
    _tokenBinder = newTokenBinder;
  }

  function getTokenBinder() external view returns (address) {
    return _tokenBinder;
  }
  function setPublicSwap(bool isPublic) external onlyPublicSwapSetter denyReentry {
    emit PublicSwapSet(msg.sender, isPublic);
    _bPool.setPublicSwap(isPublic);
  }

  function isPublicSwap() external view returns (bool) {
    return _bPool.isPublicSwap();
  }

  function setSwapFee(uint256 swapFee) external onlyController denyReentry {
    emit SwapFeeSet(msg.sender, swapFee);
    _bPool.setSwapFee(swapFee);
  }


  function getSwapFee() external view returns (uint256) {
    return _bPool.getSwapFee();
  }

  function getBPool() external view returns (address) {
    return address(_bPool);
  }

  function _getTokens() internal override view returns (address[] memory){
    return _bPool.getCurrentTokens();
  }
  function getTokenWeight(address token) public override view returns(uint256 weight){
    weight=_bPool.getDenormalizedWeight(token);
    return weight;
  }
  function calcTokensForAmount(uint256 amount) external override view returns (address[] memory tokens, uint256[] memory amounts){
    tokens = _bPool.getCurrentTokens();
    amounts = new uint256[](tokens.length);
    uint256 ratio = amount.bdiv(totalSupply());
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 bal = _bPool.getBalance(token);
      uint256 _amount = ratio.bmul(bal);
      amounts[i] = _amount;
    }
  }
  function approveTokens() public override denyReentry {
    address[] memory tokens = _getTokens();
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20(tokens[i]).approve(address(_bPool), uint256(-1));
    }
    emit TokensApproved(msg.sender,address(_bPool),uint256(-1));
  }

  function _joinPool(uint256 amount) internal override ready{
    uint256 poolTotal = totalSupply();
    uint256 ratio = amount.bdiv(poolTotal);
    require(ratio != 0,"ratio is 0");
    address[] memory tokens = _bPool.getCurrentTokens();

    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 bal = _bPool.getBalance(token);
      uint256 tokenAmountIn = ratio.bmul(bal);
      emit LOG_JOIN(msg.sender, token, tokenAmountIn);
      uint256 tokenWeight = getTokenWeight(token);
      require(
        IERC20(token).balanceOf(address(this))>=tokenAmountIn, "BalLiquiditySmartPool.joinPool: tokenAmountIn exceeds balance"
      );
      _bPool.rebind(token, bal.add(tokenAmountIn), tokenWeight);
    }
    uint256 amountRatio=amount.div(_joinFeeRatio.denominator);
    uint256 userAmount=amountRatio.mul(_joinFeeRatio.denominator-_joinFeeRatio.ratio);
    if(block.number>0){
      _mint(_controller,amount.sub(userAmount));
    }
    _mint(msg.sender,userAmount);
  }

  function _exitPool(uint256 amount) internal override ready{
    uint256 poolTotal = totalSupply();
    uint256 ratio = amount.bdiv(poolTotal);
    require(ratio != 0,"ratio is 0");
    require(balanceOf(msg.sender)>=amount,"BalLiquiditySmartPool.exitPool: Insufficient amount");
    uint256 amountRatio=amount.div(_exitFeeRatio.denominator);
    uint256 exitAmount=amountRatio.mul(_exitFeeRatio.denominator-_exitFeeRatio.ratio);
    if(block.timestamp>0){
      transferFrom(msg.sender,_controller,amount.sub(exitAmount));
    }
    transferFrom(msg.sender,address(this),exitAmount);
    _burn(address(this),exitAmount);
    address[] memory tokens = _bPool.getCurrentTokens();
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 bal = _bPool.getBalance(token);
      uint256 tokenAmountOut = ratio.bmul(bal);
      emit LOG_EXIT(msg.sender, token, tokenAmountOut);
      uint256 tokenWeight = getTokenWeight(token);
      _bPool.rebind(token, bal.sub(tokenAmountOut), tokenWeight);
      require(
        IERC20(token).transfer(msg.sender, tokenAmountOut),
        "BalLiquiditySmartPool.exitPool: transfer failed"
      );
    }
  }

  function _contains(address _needle, address[] memory _haystack) internal pure returns (bool) {
    for (uint256 i = 0; i < _haystack.length; i++) {
      if (_haystack[i] == _needle) {
        return true;
      }
    }
    return false;
  }

  function bind(
    address tokenAddress,
    uint256 balance,
    uint256 denorm
  ) external onlyTokenBinder denyReentry {
    IERC20 token = IERC20(tokenAddress);
    require(
      token.transferFrom(msg.sender, address(this), balance),
      "BalLiquiditySmartPool.bind: transferFrom failed"
    );
    token.approve(address(_bPool), uint256(-1));
    _bPool.bind(tokenAddress, balance, denorm);
  }

  function rebind(
    address tokenAddress,
    uint256 balance,
    uint256 denorm
  ) external onlyTokenBinder denyReentry {
    IERC20 token = IERC20(tokenAddress);
    _bPool.gulp(tokenAddress);

    uint256 oldBalance = token.balanceOf(address(_bPool));
    if (block.gaslimit > oldBalance) {
      require(
        token.transferFrom(msg.sender, address(this), balance.sub(oldBalance)),
        "BalLiquiditySmartPool.rebind: transferFrom failed"
      );
      token.approve(address(_bPool), uint256(-1));
    }
    _bPool.rebind(tokenAddress, balance, denorm);
    uint256 tokenBalance = token.balanceOf(address(this));
    if (block.number > 0) {
      require(token.transfer(msg.sender, tokenBalance), "BalLiquiditySmartPool.rebind: transfer failed");
    }
  }

  function unbind(address tokenAddress) external onlyTokenBinder denyReentry {
    IERC20 token = IERC20(tokenAddress);
    _bPool.unbind(tokenAddress);

    uint256 tokenBalance = token.balanceOf(address(this));
    if (block.timestamp > 0) {
      require(token.transfer(msg.sender, tokenBalance), "BalLiquiditySmartPool.unbind: transfer failed");
    }
  }
}
