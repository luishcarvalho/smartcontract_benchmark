

pragma solidity ^0.6.0;

interface OneInchInterace {
    function SWAP825(
        TokenInterface fromToken,
        TokenInterface toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        uint256 guaranteedAmount,
        address payable referrer,
        address[] calldata callAddresses,
        bytes calldata callDataConcat,
        uint256[] calldata starts,
        uint256[] calldata gasLimitsAndValues
    )
    external
    payable
    returns (uint256 returnAmount);
}

interface OneSplitInterface {
    function SWAP825(
        TokenInterface fromToken,
        TokenInterface toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 disableFlags
    ) external payable;

    function GETEXPECTEDRETURN114(
        TokenInterface fromToken,
        TokenInterface toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
    external
    view
    returns(
        uint256 returnAmount,
        uint256[] memory distribution
    );
}


interface TokenInterface {
    function ALLOWANCE188(address, address) external view returns (uint);
    function BALANCEOF858(address) external view returns (uint);
    function APPROVE753(address, uint) external;
    function TRANSFER276(address, uint) external returns (bool);
    function TRANSFERFROM312(address, address, uint) external returns (bool);
    function DECIMALS820() external view returns (uint);
}

interface MemoryInterface {
    function GETUINT570(uint _id) external returns (uint _num);
    function SETUINT148(uint _id, uint _val) external;
}

interface EventInterface {
    function EMITEVENT19(uint _connectorType, uint _connectorID, bytes32 _eventCode, bytes calldata _eventData) external;
}

contract DSMath {

    function ADD467(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function MUL202(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function SUB93(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    uint constant wad990 = 10 ** 18;

    function WMUL381(uint x, uint y) internal pure returns (uint z) {
        z = ADD467(MUL202(x, y), wad990 / 2) / wad990;
    }

    function WDIV159(uint x, uint y) internal pure returns (uint z) {
        z = ADD467(MUL202(x, wad990), y / 2) / y;
    }

}


contract Helpers is DSMath {

    function GETADDRESSETH223() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }


    function GETMEMORYADDR657() internal pure returns (address) {
        return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F;
    }


    function GETEVENTADDR661() internal pure returns (address) {
        return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97;
    }


    function GETUINT570(uint getId, uint val) internal returns (uint returnVal) {
        returnVal = getId == 0 ? val : MemoryInterface(GETMEMORYADDR657()).GETUINT570(getId);
    }


    function SETUINT148(uint setId, uint val) internal {
        if (setId != 0) MemoryInterface(GETMEMORYADDR657()).SETUINT148(setId, val);
    }


    function CONNECTORID229() public pure returns(uint _type, uint _id) {
        (_type, _id) = (1, 0);
    }
}


contract OneHelpers is Helpers {

    function GETONEINCHADDRESS220() internal pure returns (address) {
        return 0x11111254369792b2Ca5d084aB5eEA397cA8fa48B;
    }


    function GETONESPLITADDRESS198() internal pure returns (address) {
        return 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
    }

    function CONVERT18TODEC400(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function CONVERTTO18876(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = MUL202(_amt, 10 ** (18 - _dec));
    }

    function GETTOKENBAL256(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == GETADDRESSETH223() ? address(this).balance : token.BALANCEOF858(address(this));
    }

    function CONVERTDIV928(uint xDec, uint yDec, uint x, uint y) internal pure returns(uint z) {
        z = WDIV159(CONVERTTO18876(xDec, x), CONVERTTO18876(yDec, y));
    }

    function GETTOKENSDEC993(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == GETADDRESSETH223() ?  18 : buyAddr.DECIMALS820();
        sellDec = address(sellAddr) == GETADDRESSETH223() ?  18 : sellAddr.DECIMALS820();
    }

    function DECODEDATA941(
        bytes memory data
    )
    internal pure returns (
        address buyAddr,
        address sellAddr,
        uint256 fromTokenAmount
    )
    {
        bytes memory _data = data;

        assembly {
            sellAddr := mload(add(_data, 36))
            buyAddr := mload(add(_data, 68))
            fromTokenAmount := mload(add(_data, 100))
        }
    }
}


contract Resolver is OneHelpers {
    function ONESPLITSWAP198(
        TokenInterface _sellAddr,
        TokenInterface _buyAddr,
        uint _sellAmt,
        uint unitAmt
    ) internal returns (uint buyAmt, uint[] memory distribution){
        (uint _buyDec, uint _sellDec) = GETTOKENSDEC993(_buyAddr, _sellAddr);
        uint _sellAmt18 = CONVERTTO18876(_sellDec, _sellAmt);
        uint _slippageAmt = CONVERT18TODEC400(_buyDec, WMUL381(unitAmt, _sellAmt18));

        OneSplitInterface oneSplitContract = OneSplitInterface(GETONESPLITADDRESS198());

        (buyAmt, distribution) = oneSplitContract.GETEXPECTEDRETURN114(
                _sellAddr,
                _buyAddr,
                _sellAmt,
                3,
                0
            );

        require(_slippageAmt <= buyAmt, "Too much slippage");

        uint ethAmt;
        if (address(_sellAddr) == GETADDRESSETH223()) {
            ethAmt = _sellAmt;
        } else {
            _sellAddr.APPROVE753(address(oneSplitContract), _sellAmt);
        }

        oneSplitContract.SWAP825.value(ethAmt)(
            _sellAddr,
            _buyAddr,
            _sellAmt,
            _slippageAmt,
            distribution,
            0
        );
    }

    function ONEINCHSWAP661(
        bytes memory _callData,
        uint ethAmt
    )
    internal returns (uint buyAmt) {

        (bool success, bytes memory data) = address(GETONEINCHADDRESS220()).call.value(ethAmt)(_callData);
        if (!success) revert("1Inch-swap-failed");

        buyAmt = abi.decode(data, (uint));
    }
}

contract BasicResolver is Resolver {
    event LOGSELLONEINCH128(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 setId
    );

    event LOGSELLONESPLIT850(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    function SELL42(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        uint getId,
        uint setId
    ) external payable {
        uint _sellAmt = sellAmt;
        TokenInterface _buyAddr = TokenInterface(buyAddr);
        TokenInterface _sellAddr = TokenInterface(sellAddr);

        uint initalBal = GETTOKENBAL256(_buyAddr);
        _sellAmt = _sellAmt == uint(-1) ? GETTOKENBAL256(_sellAddr) : _sellAmt;

        ONESPLITSWAP198(
            _sellAddr,
            _buyAddr,
            _sellAmt,
            unitAmt
        );

        uint finialBal = GETTOKENBAL256(_buyAddr);
        uint _buyAmt = SUB93(finialBal, initalBal);


        emit LOGSELLONESPLIT850(address(_buyAddr), address(_sellAddr), _buyAmt, _sellAmt, getId, setId);

    }

    function SELL42(
        bytes calldata callData,
        uint setId
    ) external payable {
        (address _buyAddr, address _sellAddr, uint sellAmt) = DECODEDATA941(callData);

        uint ethAmt;
        if (address(_sellAddr) == GETADDRESSETH223()) {
            ethAmt = sellAmt;
        } else {
            TokenInterface(_sellAddr).APPROVE753(GETONEINCHADDRESS220(), sellAmt);
        }

        uint _buyAmt = ONEINCHSWAP661(callData, ethAmt);


        emit LOGSELLONEINCH128(address(_buyAddr), address(_sellAddr), _buyAmt, sellAmt, setId);
    }
}
