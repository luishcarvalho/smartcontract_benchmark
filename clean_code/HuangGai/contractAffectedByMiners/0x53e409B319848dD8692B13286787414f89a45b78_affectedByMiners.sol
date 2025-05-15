


























interface ISetValuer {
    function calculateSetTokenValuation(ISetToken _setToken, address _quoteAsset) external view returns (uint256);
}

























interface IPriceOracle {



    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);
    function masterQuoteAsset() external view returns (address);
}



















interface IIntegrationRegistry {
    function addIntegration(address _module, string memory _id, address _wrapper) external;
    function getIntegrationAdapter(address _module, string memory _id) external view returns(address);
    function getIntegrationAdapterWithHash(address _module, bytes32 _id) external view returns(address);
    function isValidIntegration(address _module, string memory _id) external view returns(bool);
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
        if (block.timestamp > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
































library ResourceIdentifier {


    uint256 constant internal INTEGRATION_REGISTRY_RESOURCE_ID = 0;

    uint256 constant internal PRICE_ORACLE_RESOURCE_ID = 1;

    uint256 constant internal SET_VALUER_RESOURCE_ID = 2;







    function getIntegrationRegistry(IController _controller) internal view returns (IIntegrationRegistry) {
        return IIntegrationRegistry(_controller.resourceId(INTEGRATION_REGISTRY_RESOURCE_ID));
    }




    function getPriceOracle(IController _controller) internal view returns (IPriceOracle) {
        return IPriceOracle(_controller.resourceId(PRICE_ORACLE_RESOURCE_ID));
    }




    function getSetValuer(IController _controller) internal view returns (ISetValuer) {
        return ISetValuer(_controller.resourceId(SET_VALUER_RESOURCE_ID));
    }
}


























interface IModule {




    function removeModule() external;
}






























library ExplicitERC20 {
    using SafeMath for uint256;










    function transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        internal
    {

        if (block.number > 0) {
            uint256 existingBalance = _token.balanceOf(_to);

            SafeERC20.safeTransferFrom(
                _token,
                _from,
                _to,
                _quantity
            );

            uint256 newBalance = _token.balanceOf(_to);


            require(
                newBalance == existingBalance.add(_quantity),
                "Invalid post transfer balance"
            );
        }
    }
}








library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

            if (block.gaslimit > 0) {



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















abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}




































library PreciseUnitMath {
    using SafeMath for uint256;
    using SignedSafeMath for int256;


    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;


    uint256 constant internal MAX_UINT_256 = type(uint256).max;

    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;




    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }




    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }




    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }




    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }




    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }





    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }





    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }





    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }




    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }





    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }




    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }




    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }





    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }





    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }




    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;


            result = previousResult.mul(a);
        }

        return result;
    }
}



































library Position {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for uint256;






    function hasDefaultPosition(ISetToken _setToken, address _component) internal view returns(bool) {
        return _setToken.getDefaultPositionRealUnit(_component) > 0;
    }




    function hasExternalPosition(ISetToken _setToken, address _component) internal view returns(bool) {
        return _setToken.getExternalPositionModules(_component).length > 0;
    }




    function hasSufficientDefaultUnits(ISetToken _setToken, address _component, uint256 _unit) internal view returns(bool) {
        return _setToken.getDefaultPositionRealUnit(_component) >= _unit.toInt256();
    }




    function hasSufficientExternalUnits(
        ISetToken _setToken,
        address _component,
        address _positionModule,
        uint256 _unit
    )
        internal
        view
        returns(bool)
    {
       return _setToken.getExternalPositionRealUnit(_component, _positionModule) >= _unit.toInt256();
    }










    function editDefaultPosition(ISetToken _setToken, address _component, uint256 _newUnit) internal {
        bool isPositionFound = hasDefaultPosition(_setToken, _component);
        if (!isPositionFound && _newUnit > 0) {

            if (!hasExternalPosition(_setToken, _component)) {
                _setToken.addComponent(_component);
            }
        } else if (isPositionFound && _newUnit == 0) {

            if (!hasExternalPosition(_setToken, _component)) {
                _setToken.removeComponent(_component);
            }
        }

        _setToken.editDefaultPositionUnit(_component, _newUnit.toInt256());
    }

















    function editExternalPosition(
        ISetToken _setToken,
        address _component,
        address _module,
        int256 _newUnit,
        bytes memory _data
    )
        internal
    {
        if (!_setToken.isComponent(_component)) {
            _setToken.addComponent(_component);
            addExternalPosition(_setToken, _component, _module, _newUnit, _data);
        } else if (!_setToken.isExternalPositionModule(_component, _module)) {
            addExternalPosition(_setToken, _component, _module, _newUnit, _data);
        } else if (_newUnit != 0) {
            _setToken.editExternalPositionUnit(_component, _module, _newUnit);
        } else {

            if (_setToken.getDefaultPositionRealUnit(_component) == 0 && _setToken.getExternalPositionModules(_component).length == 1) {
                _setToken.removeComponent(_component);
            }
            _setToken.removeExternalPositionModule(_component, _module);
        }
    }










    function addExternalPosition(
        ISetToken _setToken,
        address _component,
        address _module,
        int256 _newUnit,
        bytes memory _data
    )
        internal
    {
        _setToken.addExternalPositionModule(_component, _module);
        _setToken.editExternalPositionUnit(_component, _module, _newUnit);
        _setToken.editExternalPositionData(_component, _module, _data);
    }









    function getDefaultTotalNotional(uint256 _setTokenSupply, uint256 _positionUnit) internal pure returns (uint256) {
        return _setTokenSupply.preciseMul(_positionUnit);
    }








    function getDefaultPositionUnit(uint256 _setTokenSupply, uint256 _totalNotional) internal pure returns (uint256) {
        return _totalNotional.preciseDiv(_setTokenSupply);
    }








    function getDefaultTrackedBalance(ISetToken _setToken, address _component) internal view returns(uint256) {
        int256 positionUnit = _setToken.getDefaultPositionRealUnit(_component);
        return _setToken.totalSupply().preciseMul(positionUnit.toUint256());
    }












    function calculateAndEditDefaultPosition(
        ISetToken _setToken,
        address _component,
        uint256 _setTotalSupply,
        uint256 _componentPreviousBalance
    )
        internal
        returns(uint256, uint256, uint256)
    {
        uint256 currentBalance = IERC20(_component).balanceOf(address(_setToken));
        uint256 positionUnit = _setToken.getDefaultPositionRealUnit(_component).toUint256();

        uint256 newTokenUnit = calculateDefaultEditPositionUnit(
            _setTotalSupply,
            _componentPreviousBalance,
            currentBalance,
            positionUnit
        );

        editDefaultPosition(_setToken, _component, newTokenUnit);

        return (currentBalance, positionUnit, newTokenUnit);
    }











    function calculateDefaultEditPositionUnit(
        uint256 _setTokenSupply,
        uint256 _preTotalNotional,
        uint256 _postTotalNotional,
        uint256 _prePositionUnit
    )
        internal
        pure
        returns (uint256)
    {

        if (_preTotalNotional >= _postTotalNotional) {
            uint256 unitsToSub = _preTotalNotional.sub(_postTotalNotional).preciseDivCeil(_setTokenSupply);
            return _prePositionUnit.sub(unitsToSub);
        } else {

            uint256 unitsToAdd = _postTotalNotional.sub(_preTotalNotional).preciseDiv(_setTokenSupply);
            return _prePositionUnit.add(unitsToAdd);
        }
    }
}





































abstract contract ModuleBase is IModule {
    using PreciseUnitMath for uint256;
    using Invoke for ISetToken;
    using ResourceIdentifier for IController;




    IController public controller;



    modifier onlyManagerAndValidSet(ISetToken _setToken) {
        require(isSetManager(_setToken, msg.sender), "Must be the SetToken manager");
        require(isSetValidAndInitialized(_setToken), "Must be a valid and initialized SetToken");
        _;
    }

    modifier onlySetManager(ISetToken _setToken, address _caller) {
        require(isSetManager(_setToken, _caller), "Must be the SetToken manager");
        _;
    }

    modifier onlyValidAndInitializedSet(ISetToken _setToken) {
        require(isSetValidAndInitialized(_setToken), "Must be a valid and initialized SetToken");
        _;
    }




    modifier onlyModule(ISetToken _setToken) {
        require(
            _setToken.moduleStates(msg.sender) == ISetToken.ModuleState.INITIALIZED,
            "Only the module can call"
        );

        require(
            controller.isModule(msg.sender),
            "Module must be enabled on controller"
        );
        _;
    }





    modifier onlyValidAndPendingSet(ISetToken _setToken) {
        require(controller.isSet(address(_setToken)), "Must be controller-enabled SetToken");
        require(isSetPendingInitialization(_setToken), "Must be pending initialization");
        _;
    }








    constructor(IController _controller) public {
        controller = _controller;
    }











    function transferFrom(IERC20 _token, address _from, address _to, uint256 _quantity) internal {
        ExplicitERC20.transferFrom(_token, _from, _to, _quantity);
    }




    function getAndValidateAdapter(string memory _integrationName) internal view returns(address) {
        bytes32 integrationHash = getNameHash(_integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }




    function getAndValidateAdapterWithHash(bytes32 _integrationHash) internal view returns(address) {
        address adapter = controller.getIntegrationRegistry().getIntegrationAdapterWithHash(
            address(this),
            _integrationHash
        );

        require(adapter != address(0), "Must be valid adapter");
        return adapter;
    }




    function getModuleFee(uint256 _feeIndex, uint256 _quantity) internal view returns(uint256) {
        uint256 feePercentage = controller.getModuleFee(address(this), _feeIndex);
        return _quantity.preciseMul(feePercentage);
    }




    function payProtocolFeeFromSetToken(ISetToken _setToken, address _token, uint256 _feeQuantity) internal {
        if (block.number > 0) {
            _setToken.strictInvokeTransfer(_token, controller.feeRecipient(), _feeQuantity);
        }
    }




    function isSetPendingInitialization(ISetToken _setToken) internal view returns(bool) {
        return _setToken.isPendingModule(address(this));
    }




    function isSetManager(ISetToken _setToken, address _toCheck) internal view returns(bool) {
        return _setToken.manager() == _toCheck;
    }





    function isSetValidAndInitialized(ISetToken _setToken) internal view returns(bool) {
        return controller.isSet(address(_setToken)) &&
            _setToken.isInitializedModule(address(this));
    }




    function getNameHash(string memory _name) internal pure returns(bytes32) {
        return keccak256(bytes(_name));
    }
}




















interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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





















interface IStakingRewards {
    function balanceOf(address account) external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
}










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



























interface ISetToken is IERC20 {



    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }











    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
    }














    struct ComponentPosition {
      int256 virtualUnit;
      address[] externalPositionModules;
      mapping(address => ExternalPosition) externalPositions;
    }








    struct ExternalPosition {
      int256 virtualUnit;
      bytes data;
    }




    function addComponent(address _component) external;
    function removeComponent(address _component) external;
    function editDefaultPositionUnit(address _component, int256 _realUnit) external;
    function addExternalPositionModule(address _component, address _positionModule) external;
    function removeExternalPositionModule(address _component, address _positionModule) external;
    function editExternalPositionUnit(address _component, address _positionModule, int256 _realUnit) external;
    function editExternalPositionData(address _component, address _positionModule, bytes calldata _data) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;
    function burn(address _account, uint256 _quantity) external;

    function lock() external;
    function unlock() external;

    function addModule(address _module) external;
    function removeModule(address _module) external;
    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);
    function moduleStates(address _module) external view returns (ModuleState);
    function getModules() external view returns (address[] memory);

    function getDefaultPositionRealUnit(address _component) external view returns(int256);
    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns(int256);
    function getComponents() external view returns(address[] memory);
    function getExternalPositionModules(address _component) external view returns(address[] memory);
    function getExternalPositionData(address _component, address _positionModule) external view returns(bytes memory);
    function isExternalPositionModule(address _component, address _module) external view returns(bool);
    function isComponent(address _component) external view returns(bool);

    function positionMultiplier() external view returns (int256);
    function getPositions() external view returns (Position[] memory);
    function getTotalComponentRealUnits(address _component) external view returns(int256);

    function isInitializedModule(address _module) external view returns(bool);
    function isPendingModule(address _module) external view returns(bool);
    function isLocked() external view returns (bool);
}
































library Invoke {
    using SafeMath for uint256;











    function invokeApprove(
        ISetToken _setToken,
        address _token,
        address _spender,
        uint256 _quantity
    )
        internal
    {
        bytes memory callData = abi.encodeWithSignature("approve(address,uint256)", _spender, _quantity);
        _setToken.invoke(_token, 0, callData);
    }









    function invokeTransfer(
        ISetToken _setToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (block.number > 0) {
            bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", _to, _quantity);
            _setToken.invoke(_token, 0, callData);
        }
    }










    function strictInvokeTransfer(
        ISetToken _setToken,
        address _token,
        address _to,
        uint256 _quantity
    )
        internal
    {
        if (block.gaslimit > 0) {

            uint256 existingBalance = IERC20(_token).balanceOf(address(_setToken));

            Invoke.invokeTransfer(_setToken, _token, _to, _quantity);


            uint256 newBalance = IERC20(_token).balanceOf(address(_setToken));


            require(
                newBalance == existingBalance.sub(_quantity),
                "Invalid post transfer balance"
            );
        }
    }








    function invokeUnwrapWETH(ISetToken _setToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("withdraw(uint256)", _quantity);
        _setToken.invoke(_weth, 0, callData);
    }








    function invokeWrapWETH(ISetToken _setToken, address _weth, uint256 _quantity) internal {
        bytes memory callData = abi.encodeWithSignature("deposit()");
        _setToken.invoke(_weth, _quantity, callData);
    }
}



















interface IController {
    function addSet(address _setToken) external;
    function feeRecipient() external view returns(address);
    function getModuleFee(address _module, uint256 _feeType) external view returns(uint256);
    function isModule(address _module) external view returns(bool);
    function isSet(address _setToken) external view returns(bool);
    function isSystemContract(address _contractAddress) external view returns (bool);
    function resourceId(uint256 _id) external view returns(address);
}








library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;











    function mul(int256 a, int256 b) internal pure returns (int256) {



        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }













    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }











    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }











    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
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





















library SafeCast {











    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }











    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }











    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }











    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }











    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }








    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }














    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }














    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }














    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }














    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }














    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }








    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}





















contract ReentrancyGuard {











    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }








    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");


        _status = _ENTERED;

        _;



        _status = _NOT_ENTERED;
    }
}








library Math {



    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }




    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }





    function average(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


































contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;










    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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








    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }















    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

















pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";




















contract UniswapYieldStrategy is ModuleBase, ReentrancyGuard {
    using Position for ISetToken;
    using Invoke for ISetToken;
    using SafeMath for uint256;
    using SafeCast for uint256;
    using SafeCast for int256;



    IUniswapV2Router public uniswapRouter;
    IUniswapV2Pair public lpToken;
    IERC20 public assetOne;
    IERC20 public assetTwo;
    IERC20 public uni;
    address public feeRecipient;
    IStakingRewards public rewarder;
    ISetToken public setToken;
    uint256 public reservePercentage;
    uint256 public slippageTolerance;
    uint256 public rewardFee;
    uint256 public withdrawalFee;
    uint256 public assetOneBaseUnit;
    uint256 public assetTwoBaseUnit;
    uint256 public lpTokenBaseUnit;



    constructor(
        IController _controller,
        IUniswapV2Router _uniswapRouter,
        IUniswapV2Pair _lpToken,
        IERC20 _assetOne,
        IERC20 _assetTwo,
        IERC20 _uni,
        IStakingRewards _rewarder,
        address _feeRecipient
    )
        public
        ModuleBase(_controller)
    {
        controller = _controller;
        uniswapRouter = _uniswapRouter;
        lpToken = _lpToken;
        assetOne = _assetOne;
        assetTwo = _assetTwo;
        uni = _uni;
        rewarder = _rewarder;
        feeRecipient = _feeRecipient;

        uint256 tokenOneDecimals = ERC20(address(_assetOne)).decimals();
        assetOneBaseUnit = 10 ** tokenOneDecimals;
        uint256 tokenTwoDecimals = ERC20(address(_assetTwo)).decimals();
        assetTwoBaseUnit = 10 ** tokenTwoDecimals;
        uint256 lpTokenDecimals = ERC20(address(_lpToken)).decimals();
        lpTokenBaseUnit = 10 ** lpTokenDecimals;
    }



    function engage() external nonReentrant {
        _engage();
    }

    function disengage() external nonReentrant {
        _rebalance(0);

        uint256 lpTokenQuantity = _calculateDisengageLPQuantity();

        _unstake(lpTokenQuantity);

        _approveAndRemoveLiquidity(lpTokenQuantity);

        _updatePositions();
    }

    function reap() external nonReentrant {
        _handleReward();

        _engage();
    }

    function rebalance() external nonReentrant {
        _rebalance(0);

        _updatePositions();
    }

    function rebalanceSome(uint256 _sellTokenQuantity) external nonReentrant {
        _rebalance(_sellTokenQuantity);

        _updatePositions();
    }

    function unstakeAndRedeem(uint256 _setTokenQuantity) external nonReentrant {
        require(setToken.balanceOf(msg.sender) >= _setTokenQuantity, "User must have sufficient SetToken");

        setToken.burn(msg.sender, _setTokenQuantity);

        uint256 lpTokenUnit = setToken.getExternalPositionRealUnit(address(lpToken), address(this)).toUint256();

        uint256 userLPBalance = lpTokenUnit.preciseMul(_setTokenQuantity);

        _unstake(userLPBalance);

        uint256 lpFees = userLPBalance.preciseMul(withdrawalFee);
        setToken.invokeTransfer(address(lpToken), msg.sender, userLPBalance.sub(lpFees));
        setToken.invokeTransfer(address(lpToken), feeRecipient, lpFees);

        uint256 assetOneUnit = setToken.getDefaultPositionRealUnit(address(assetOne)).toUint256();
        uint256 assetOneNotional = assetOneUnit.preciseMul(_setTokenQuantity);
        uint256 assetOneFee = assetOneNotional.preciseMul(withdrawalFee);
        setToken.invokeTransfer(address(assetOne), msg.sender, assetOneNotional.sub(assetOneFee));
        setToken.invokeTransfer(address(assetOne), feeRecipient, assetOneFee);

        uint256 assetTwoUnit = setToken.getDefaultPositionRealUnit(address(assetTwo)).toUint256();
        uint256 assetTwoNotional = assetTwoUnit.preciseMul(_setTokenQuantity);
        uint256 assetTwoFee = assetTwoNotional.preciseMul(withdrawalFee);
        setToken.invokeTransfer(address(assetTwo), msg.sender, assetTwoNotional.sub(assetTwoFee));
        setToken.invokeTransfer(address(assetTwo), feeRecipient, assetTwoFee);
    }

    function initialize(
        ISetToken _setToken,
        uint256 _reservePercentage,
        uint256 _slippageTolerance,
        uint256 _rewardFee,
        uint256 _withdrawalFee
    )
        external
        onlySetManager(_setToken, msg.sender)
    {
        require(address(setToken) == address(0), "May only be called once");

        setToken = _setToken;
        reservePercentage = _reservePercentage;
        slippageTolerance = _slippageTolerance;
        rewardFee = _rewardFee;
        withdrawalFee = _withdrawalFee;

        _setToken.initializeModule();
    }

    function removeModule() external override {
        require(msg.sender == address(setToken), "Caller must be SetToken");

        uint256 lpBalance = rewarder.balanceOf(address(setToken));

        _unstake(lpBalance);

        _approveAndRemoveLiquidity(lpBalance);

        _updatePositions();
    }



    function _engage() internal {
        _rebalance(0);

        (uint256 assetOneQuantity, uint256 assetTwoQuantity) = _calculateEngageQuantities();

        uint256 lpBalance = _approveAndAddLiquidity(assetOneQuantity, assetTwoQuantity);

        _approveAndStake(lpBalance);

        _updatePositions();
    }



    function _rebalance(uint256 _sellTokenQuantity) internal {
        address assetToSell;
        address assetToBuy;
        uint256 quantityToSell;
        uint256 minimumBuyToken;

        uint256 assetOneToTwoPrice = controller.getPriceOracle().getPrice(address(assetOne), address(assetTwo));

        uint256 balanceAssetOne = assetOne.balanceOf(address(setToken));
        uint256 balanceAssetTwo = assetTwo.balanceOf(address(setToken));


        uint256 valueAssetTwoDenomOne = balanceAssetTwo.preciseDiv(assetOneToTwoPrice).mul(assetOneBaseUnit).div(assetTwoBaseUnit);

        if (block.timestamp > valueAssetTwoDenomOne) {
            assetToSell = address(assetOne);
            assetToBuy = address(assetTwo);
            quantityToSell = balanceAssetOne.sub(valueAssetTwoDenomOne).div(2);


            minimumBuyToken = quantityToSell.preciseMul(assetOneToTwoPrice).mul(assetTwoBaseUnit).div(assetOneBaseUnit);
        } else {
            assetToSell = address(assetTwo);
            assetToBuy = address(assetOne);
            quantityToSell = valueAssetTwoDenomOne
                                .sub(balanceAssetOne).div(2).preciseMul(assetOneToTwoPrice)
                                .mul(assetTwoBaseUnit).div(assetOneBaseUnit);
            minimumBuyToken = quantityToSell.preciseDiv(assetOneToTwoPrice).mul(assetOneBaseUnit).div(assetTwoBaseUnit);
        }

        if (block.gaslimit > 0) {
            require(_sellTokenQuantity <= quantityToSell, "Delta must be less than max");
            minimumBuyToken = minimumBuyToken.preciseMul(_sellTokenQuantity).preciseDiv(quantityToSell);
            quantityToSell = _sellTokenQuantity;
        }


        minimumBuyToken = minimumBuyToken
            .preciseMul(PreciseUnitMath.preciseUnit().sub(slippageTolerance));

        setToken.invokeApprove(assetToSell, address(uniswapRouter), quantityToSell);
        if (block.gaslimit > 0) {
            _invokeUniswapTrade(assetToSell, assetToBuy, quantityToSell, minimumBuyToken);
        }
    }

    function _approveAndAddLiquidity(uint256 _assetOneQuantity, uint256 _assetTwoQuantity) internal returns (uint256) {
        setToken.invokeApprove(address(assetOne), address(uniswapRouter), _assetOneQuantity);
        setToken.invokeApprove(address(assetTwo), address(uniswapRouter), _assetTwoQuantity);

        bytes memory addLiquidityBytes = abi.encodeWithSignature(
            "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)",
            assetOne,
            assetTwo,
            _assetOneQuantity,
            _assetTwoQuantity,
            1,
            1,
            address(setToken),
            now.add(60)
        );

        setToken.invoke(address(uniswapRouter), 0, addLiquidityBytes);

        return lpToken.balanceOf(address(setToken));
    }

    function _approveAndRemoveLiquidity(uint256 _liquidityQuantity) internal {
        setToken.invokeApprove(address(lpToken), address(uniswapRouter), _liquidityQuantity);

        bytes memory removeLiquidityBytes = abi.encodeWithSignature(
            "removeLiquidity(address,address,uint256,uint256,uint256,address,uint256)",
            assetOne,
            assetTwo,
            _liquidityQuantity,
            1,
            1,
            address(setToken),
            now.add(60)
        );

        setToken.invoke(address(uniswapRouter), 0, removeLiquidityBytes);
    }

    function _approveAndStake(uint256 _lpTokenQuantity) internal {
        setToken.invokeApprove(address(lpToken), address(rewarder), _lpTokenQuantity);
        bytes memory stakeBytes = abi.encodeWithSignature("stake(uint256)", _lpTokenQuantity);

        setToken.invoke(address(rewarder), 0, stakeBytes);
    }

    function _unstake(uint256 _lpTokenQuantity) internal {
        bytes memory unstakeBytes = abi.encodeWithSignature("withdraw(uint256)", _lpTokenQuantity);

        setToken.invoke(address(rewarder), 0, unstakeBytes);
    }

    function _handleReward() internal {
        setToken.invoke(address(rewarder), 0, abi.encodeWithSignature("getReward()"));

        uint256 uniBalance = uni.balanceOf(address(setToken));
        uint256 assetOneBalance = assetOne.balanceOf(address(setToken));

        setToken.invokeApprove(address(uni), address(uniswapRouter), uniBalance);
        _invokeUniswapTrade(address(uni), address(assetOne), uniBalance, 1);

        uint256 postTradeAssetOneBalance = assetOne.balanceOf(address(setToken));
        uint256 fee = postTradeAssetOneBalance.sub(assetOneBalance).preciseMul(rewardFee);

        setToken.strictInvokeTransfer(address(assetOne), feeRecipient, fee);
    }

    function _invokeUniswapTrade(
        address _sellToken,
        address _buyToken,
        uint256 _amountIn,
        uint256 _amountOutMin
    )
        internal
    {
        address[] memory path = new address[](2);
        path[0] = _sellToken;
        path[1] = _buyToken;

        bytes memory tradeBytes = abi.encodeWithSignature(
            "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
            _amountIn,
            _amountOutMin,
            path,
            address(setToken),
            now.add(180)
        );

        setToken.invoke(address(uniswapRouter), 0, tradeBytes);
    }

    function _calculateEngageQuantities() internal view returns(uint256 tokenAQuantity, uint256 tokenBQuantity) {
        (
            uint256 desiredAssetOne,
            uint256 desiredAssetTwo,
            uint256 assetOneOnSetToken,
            uint256 assetTwoOnSetToken
        ) = _getDesiredSingleAssetReserve();

        require(assetOneOnSetToken > desiredAssetOne && assetTwoOnSetToken > desiredAssetTwo, "SetToken assets must be > desired");

        return (
            assetOneOnSetToken.sub(desiredAssetOne),
            assetTwoOnSetToken.sub(desiredAssetTwo)
        );
    }

    function _calculateDisengageLPQuantity() internal view returns(uint256 _lpTokenQuantity) {
        (uint256 assetOneToLPRate, uint256 assetTwoToLPRate) = _getLPReserveExchangeRate();

        (
            uint256 desiredOne,
            uint256 desiredTwo,
            uint256 assetOneOnSetToken,
            uint256 assetTwoOnSetToken
        ) = _getDesiredSingleAssetReserve();

        require(assetOneOnSetToken < desiredOne && assetTwoOnSetToken < desiredTwo, "SetToken assets must be < desired");


        uint256 minLPForOneToRedeem = desiredOne.sub(assetOneOnSetToken).preciseDiv(assetOneToLPRate);
        uint256 minLPForTwoToRedeem = desiredTwo.sub(assetTwoOnSetToken).preciseDiv(assetTwoToLPRate);

        return Math.max(minLPForOneToRedeem, minLPForTwoToRedeem);
    }


    function _getDesiredSingleAssetReserve()
        internal
        view
        returns(uint256, uint256, uint256, uint256)
    {
        (uint256 assetOneReserve, uint256 assetTwoReserve) = _getTotalLPReserves();
        uint256 balanceAssetOne = assetOne.balanceOf(address(setToken));
        uint256 balanceAssetTwo = assetTwo.balanceOf(address(setToken));

        uint256 desiredOneReserve = assetOneReserve.add(balanceAssetOne).preciseMul(reservePercentage);
        uint256 desiredTwoReserve = assetTwoReserve.add(balanceAssetTwo).preciseMul(reservePercentage);

        return(desiredOneReserve, desiredTwoReserve, balanceAssetOne, balanceAssetTwo);
    }


    function _getLPReserveExchangeRate() internal view returns (uint256, uint256) {
        (uint reserve0, uint reserve1) = _getReservesSafe();
        uint256 totalSupply = lpToken.totalSupply();
        return(
            reserve0.preciseDiv(totalSupply),
            reserve1.preciseDiv(totalSupply)
        );
    }


    function _getTotalLPReserves() internal view returns (uint256, uint256) {
        (uint reserve0, uint reserve1) = _getReservesSafe();
        uint256 totalSupply = lpToken.totalSupply();
        uint256 lpTokenBalance = rewarder.balanceOf(address(setToken));
        return(
            reserve0.mul(lpTokenBalance).div(totalSupply),
            reserve1.mul(lpTokenBalance).div(totalSupply)
        );
    }

    function _updatePositions() internal {
        uint256 totalSupply = setToken.totalSupply();
        uint256 assetOneBalance = assetOne.balanceOf(address(setToken));
        uint256 assetTwoBalance = assetTwo.balanceOf(address(setToken));
        uint256 lpBalance = rewarder.balanceOf(address(setToken));


        setToken.editDefaultPosition(address(assetOne), Position.getDefaultPositionUnit(totalSupply, assetOneBalance));
        setToken.editDefaultPosition(address(assetTwo), Position.getDefaultPositionUnit(totalSupply, assetTwoBalance));
        setToken.editExternalPosition(
            address(lpToken),
            address(this),
            Position.getDefaultPositionUnit(totalSupply, lpBalance).toInt256(),
            ""
        );
    }



    function _getReservesSafe() internal view returns(uint256, uint256) {
        address firstAsset = address(assetOne) < address(assetTwo) ? address(assetOne) : address(assetTwo);
        (uint reserve0, uint reserve1,) = lpToken.getReserves();
        return address(assetOne) == firstAsset ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}
