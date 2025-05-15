

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function APPROVE44(address, uint256) external;
    function TRANSFER867(address, uint) external;
    function TRANSFERFROM416(address, address, uint) external;
    function DEPOSIT488() external payable;
    function WITHDRAW102(uint) external;
    function BALANCEOF737(address) external view returns (uint);
    function DECIMALS200() external view returns (uint);
}

interface MemoryInterface {
    function GETUINT774(uint id) external returns (uint num);
    function SETUINT548(uint id, uint val) external;
}

interface EventInterface {
    function EMITEVENT565(uint connectorType, uint connectorID, bytes32 eventCode, bytes calldata eventData) external;
}

contract Stores {


  function GETETHADDR620() internal pure returns (address) {
    return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  }


  function GETMEMORYADDR192() internal pure returns (address) {
    return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F;
  }


  function GETEVENTADDR446() internal pure returns (address) {
    return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97;
  }


  function GETUINT774(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : MemoryInterface(GETMEMORYADDR192()).GETUINT774(getId);
  }


  function SETUINT548(uint setId, uint val) virtual internal {
    if (setId != 0) MemoryInterface(GETMEMORYADDR192()).SETUINT548(setId, val);
  }


  function EMITEVENT565(bytes32 eventCode, bytes memory eventData) virtual internal {
    (uint model, uint id) = CONNECTORID65();
    EventInterface(GETEVENTADDR446()).EMITEVENT565(model, id, eventCode, eventData);
  }


  function CONNECTORID65() public view returns(uint model, uint id) {
    (model, id) = (1, 38);
  }

}



library SafeMath {

    function ADD435(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB700(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB700(a, b, "SafeMath: subtraction overflow");
    }


    function SUB700(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL278(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV204(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV204(a, b, "SafeMath: division by zero");
    }


    function DIV204(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD700(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD700(a, b, "SafeMath: modulo by zero");
    }


    function MOD700(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract DSMath {
  uint constant wad945 = 10 ** 18;
  uint constant ray928 = 10 ** 27;

  function ADD435(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.ADD435(x, y);
  }

  function SUB700(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.SUB700(x, y);
  }

  function MUL278(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.MUL278(x, y);
  }

  function DIV204(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.DIV204(x, y);
  }

  function WMUL242(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.ADD435(SafeMath.MUL278(x, y), wad945 / 2) / wad945;
  }

  function WDIV461(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.ADD435(SafeMath.MUL278(x, wad945), y / 2) / y;
  }

  function RDIV516(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.ADD435(SafeMath.MUL278(x, ray928), y / 2) / y;
  }

  function RMUL757(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.ADD435(SafeMath.MUL278(x, y), ray928 / 2) / ray928;
  }

}

interface OneInchInterace {
    function SWAP155(
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

interface OneProtoInterface {
    function SWAPWITHREFERRAL361(
        TokenInterface fromToken,
        TokenInterface destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 flags,
        address referral,
        uint256 feePercent
    ) external payable returns(uint256);

    function SWAPWITHREFERRALMULTI690(
        TokenInterface[] calldata tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256[] calldata flags,
        address referral,
        uint256 feePercent
    ) external payable returns(uint256 returnAmount);

    function GETEXPECTEDRETURN579(
        TokenInterface fromToken,
        TokenInterface destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
    external
    view
    returns(
        uint256 returnAmount,
        uint256[] memory distribution
    );
}

interface OneProtoMappingInterface {
    function ONEPROTOADDRESS398() external view returns(address);
}


contract OneHelpers is Stores, DSMath {


    function GETONEPROTOMAPPINGADDRESS394() internal pure returns (address payable) {
        return 0x8d0287AFa7755BB5f2eFe686AA8d4F0A7BC4AE7F;
    }


    function GETONEPROTOADDRESS431() internal view returns (address payable) {
        return payable(OneProtoMappingInterface(GETONEPROTOMAPPINGADDRESS394()).ONEPROTOADDRESS398());
    }


    function GETONEINCHADDRESS518() internal pure returns (address) {
        return 0x11111254369792b2Ca5d084aB5eEA397cA8fa48B;
    }


    function GETONEINCHTOKENTAKER586() internal pure returns (address payable) {
        return 0xE4C9194962532fEB467DCe8b3d42419641c6eD2E;
    }


    function GETONEINCHSIG889() internal pure returns (bytes4) {
        return 0xf88309d7;
    }

    function GETREFERRALADDR889() internal pure returns (address) {
        return 0xa7615CD307F323172331865181DC8b80a2834324;
    }

    function CONVERT18TODEC395(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function CONVERTTO18179(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = MUL278(_amt, 10 ** (18 - _dec));
    }

    function GETTOKENBAL438(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == GETETHADDR620() ? address(this).balance : token.BALANCEOF737(address(this));
    }

    function GETTOKENSDEC172(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == GETETHADDR620() ?  18 : buyAddr.DECIMALS200();
        sellDec = address(sellAddr) == GETETHADDR620() ?  18 : sellAddr.DECIMALS200();
    }

    function GETSLIPPAGEAMT247(
        TokenInterface _buyAddr,
        TokenInterface _sellAddr,
        uint _sellAmt,
        uint unitAmt
    ) internal view returns(uint _slippageAmt) {
        (uint _buyDec, uint _sellDec) = GETTOKENSDEC172(_buyAddr, _sellAddr);
        uint _sellAmt18 = CONVERTTO18179(_sellDec, _sellAmt);
        _slippageAmt = CONVERT18TODEC395(_buyDec, WMUL242(unitAmt, _sellAmt18));
    }

    function CONVERTTOTOKENINTERFACE157(address[] memory tokens) internal pure returns(TokenInterface[] memory) {
        TokenInterface[] memory _tokens = new TokenInterface[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            _tokens[i] = TokenInterface(tokens[i]);
        }
        return _tokens;
    }
}


contract OneProtoResolver is OneHelpers {
    struct OneProtoData {
        TokenInterface sellToken;
        TokenInterface buyToken;
        uint _sellAmt;
        uint _buyAmt;
        uint unitAmt;
        uint[] distribution;
        uint disableDexes;
    }

    function ONEPROTOSWAP794(
        OneProtoInterface oneProtoContract,
        OneProtoData memory oneProtoData
    ) internal returns (uint buyAmt) {
        TokenInterface _sellAddr = oneProtoData.sellToken;
        TokenInterface _buyAddr = oneProtoData.buyToken;
        uint _sellAmt = oneProtoData._sellAmt;

        uint _slippageAmt = GETSLIPPAGEAMT247(_buyAddr, _sellAddr, _sellAmt, oneProtoData.unitAmt);

        uint ethAmt;
        if (address(_sellAddr) == GETETHADDR620()) {
            ethAmt = _sellAmt;
        } else {
            _sellAddr.APPROVE44(address(oneProtoContract), _sellAmt);
        }


        uint initalBal = GETTOKENBAL438(_buyAddr);
        oneProtoContract.SWAPWITHREFERRAL361.value(ethAmt)(
            _sellAddr,
            _buyAddr,
            _sellAmt,
            _slippageAmt,
            oneProtoData.distribution,
            oneProtoData.disableDexes,
            GETREFERRALADDR889(),
            0
        );
        uint finalBal = GETTOKENBAL438(_buyAddr);

        buyAmt = SUB700(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

    struct OneProtoMultiData {
        address[] tokens;
        TokenInterface sellToken;
        TokenInterface buyToken;
        uint _sellAmt;
        uint _buyAmt;
        uint unitAmt;
        uint[] distribution;
        uint[] disableDexes;
    }

    function ONEPROTOSWAPMULTI285(OneProtoMultiData memory oneProtoData) internal returns (uint buyAmt) {
        TokenInterface _sellAddr = oneProtoData.sellToken;
        TokenInterface _buyAddr = oneProtoData.buyToken;
        uint _sellAmt = oneProtoData._sellAmt;
        uint _slippageAmt = GETSLIPPAGEAMT247(_buyAddr, _sellAddr, _sellAmt, oneProtoData.unitAmt);

        OneProtoInterface oneSplitContract = OneProtoInterface(GETONEPROTOADDRESS431());
        uint ethAmt;
        if (address(_sellAddr) == GETETHADDR620()) {
            ethAmt = _sellAmt;
        } else {
            _sellAddr.APPROVE44(address(oneSplitContract), _sellAmt);
        }

        uint initalBal = GETTOKENBAL438(_buyAddr);
        oneSplitContract.SWAPWITHREFERRALMULTI690.value(ethAmt)(
            CONVERTTOTOKENINTERFACE157(oneProtoData.tokens),
            _sellAmt,
            _slippageAmt,
            oneProtoData.distribution,
            oneProtoData.disableDexes,
            GETREFERRALADDR889(),
            0
        );
        uint finalBal = GETTOKENBAL438(_buyAddr);

        buyAmt = SUB700(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }
}

contract OneInchResolver is OneProtoResolver {
    function CHECKONEINCHSIG202(bytes memory callData) internal pure returns(bool isOk) {
        bytes memory _data = callData;
        bytes4 sig;

        assembly {
            sig := mload(add(_data, 32))
        }
        isOk = sig == GETONEINCHSIG889();
    }

    struct OneInchData {
        TokenInterface sellToken;
        TokenInterface buyToken;
        uint _sellAmt;
        uint _buyAmt;
        uint unitAmt;
        bytes callData;
    }

    function ONEINCHSWAP719(
        OneInchData memory oneInchData,
        uint ethAmt
    ) internal returns (uint buyAmt) {
        TokenInterface buyToken = oneInchData.buyToken;
        (uint _buyDec, uint _sellDec) = GETTOKENSDEC172(buyToken, oneInchData.sellToken);
        uint _sellAmt18 = CONVERTTO18179(_sellDec, oneInchData._sellAmt);
        uint _slippageAmt = CONVERT18TODEC395(_buyDec, WMUL242(oneInchData.unitAmt, _sellAmt18));

        uint initalBal = GETTOKENBAL438(buyToken);


        (bool success, ) = address(GETONEINCHADDRESS518()).call.value(ethAmt)(oneInchData.callData);
        if (!success) revert("1Inch-swap-failed");

        uint finalBal = GETTOKENBAL438(buyToken);

        buyAmt = SUB700(finalBal, initalBal);

        require(_slippageAmt <= buyAmt, "Too much slippage");
    }

}

contract OneProtoEventResolver is OneInchResolver {
    event LOGSELL607(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    function EMITLOGSELL642(
        OneProtoData memory oneProtoData,
        uint256 getId,
        uint256 setId
    ) internal {
        bytes32 _eventCode;
        bytes memory _eventParam;
        emit LOGSELL607(
            address(oneProtoData.buyToken),
            address(oneProtoData.sellToken),
            oneProtoData._buyAmt,
            oneProtoData._sellAmt,
            getId,
            setId
        );
        _eventCode = keccak256("LogSell(address,address,uint256,uint256,uint256,uint256)");
        _eventParam = abi.encode(
            address(oneProtoData.buyToken),
            address(oneProtoData.sellToken),
            oneProtoData._buyAmt,
            oneProtoData._sellAmt,
            getId,
            setId
        );
        EMITEVENT565(_eventCode, _eventParam);
    }

    event LOGSELLTWO221(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    function EMITLOGSELLTWO898(
        OneProtoData memory oneProtoData,
        uint256 getId,
        uint256 setId
    ) internal {
        bytes32 _eventCode;
        bytes memory _eventParam;
        emit LOGSELLTWO221(
            address(oneProtoData.buyToken),
            address(oneProtoData.sellToken),
            oneProtoData._buyAmt,
            oneProtoData._sellAmt,
            getId,
            setId
        );
        _eventCode = keccak256("LogSellTwo(address,address,uint256,uint256,uint256,uint256)");
        _eventParam = abi.encode(
            address(oneProtoData.buyToken),
            address(oneProtoData.sellToken),
            oneProtoData._buyAmt,
            oneProtoData._sellAmt,
            getId,
            setId
        );
        EMITEVENT565(_eventCode, _eventParam);
    }

    event LOGSELLMULTI397(
        address[] tokens,
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    function EMITLOGSELLMULTI751(
        OneProtoMultiData memory oneProtoData,
        uint256 getId,
        uint256 setId
    ) internal {
        bytes32 _eventCode;
        bytes memory _eventParam;
        emit LOGSELLMULTI397(
            oneProtoData.tokens,
            address(oneProtoData.buyToken),
            address(oneProtoData.sellToken),
            oneProtoData._buyAmt,
            oneProtoData._sellAmt,
            getId,
            setId
        );
        _eventCode = keccak256("LogSellMulti(address[],address,address,uint256,uint256,uint256,uint256)");
        _eventParam = abi.encode(
            oneProtoData.tokens,
            address(oneProtoData.buyToken),
            address(oneProtoData.sellToken),
            oneProtoData._buyAmt,
            oneProtoData._sellAmt,
            getId,
            setId
        );
        EMITEVENT565(_eventCode, _eventParam);
    }
}

contract OneInchEventResolver is OneProtoEventResolver {
    event LOGSELLTHREE365(
        address indexed buyToken,
        address indexed sellToken,
        uint256 buyAmt,
        uint256 sellAmt,
        uint256 getId,
        uint256 setId
    );

    function EMITLOGSELLTHREE379(
        OneInchData memory oneInchData,
        uint256 setId
    ) internal {
        bytes32 _eventCode;
        bytes memory _eventParam;
        emit LOGSELLTHREE365(
            address(oneInchData.buyToken),
            address(oneInchData.sellToken),
            oneInchData._buyAmt,
            oneInchData._sellAmt,
            0,
            setId
        );
        _eventCode = keccak256("LogSellThree(address,address,uint256,uint256,uint256,uint256)");
        _eventParam = abi.encode(
            address(oneInchData.buyToken),
            address(oneInchData.sellToken),
            oneInchData._buyAmt,
            oneInchData._sellAmt,
            0,
            setId
        );
        EMITEVENT565(_eventCode, _eventParam);
    }
}

contract OneProtoResolverHelpers is OneInchEventResolver {
    function _SELL499(
        OneProtoData memory oneProtoData,
        uint256 getId,
        uint256 setId
    ) internal {
        uint _sellAmt = GETUINT774(getId, oneProtoData._sellAmt);

        oneProtoData._sellAmt = _sellAmt == uint(-1) ?
            GETTOKENBAL438(oneProtoData.sellToken) :
            _sellAmt;

        OneProtoInterface oneProtoContract = OneProtoInterface(GETONEPROTOADDRESS431());

        (, oneProtoData.distribution) = oneProtoContract.GETEXPECTEDRETURN579(
                oneProtoData.sellToken,
                oneProtoData.buyToken,
                oneProtoData._sellAmt,
                5,
                0
            );

        oneProtoData._buyAmt = ONEPROTOSWAP794(
            oneProtoContract,
            oneProtoData
        );

        SETUINT548(setId, oneProtoData._buyAmt);

        EMITLOGSELL642(oneProtoData, getId, setId);
    }

    function _SELLTWO817(
        OneProtoData memory oneProtoData,
        uint getId,
        uint setId
    ) internal {
        uint _sellAmt = GETUINT774(getId, oneProtoData._sellAmt);

        oneProtoData._sellAmt = _sellAmt == uint(-1) ?
            GETTOKENBAL438(oneProtoData.sellToken) :
            _sellAmt;

        oneProtoData._buyAmt = ONEPROTOSWAP794(
            OneProtoInterface(GETONEPROTOADDRESS431()),
            oneProtoData
        );

        SETUINT548(setId, oneProtoData._buyAmt);
        EMITLOGSELLTWO898(oneProtoData, getId, setId);
    }

    function _SELLMULTI27(
        OneProtoMultiData memory oneProtoData,
        uint getId,
        uint setId
    ) internal {
        uint _sellAmt = GETUINT774(getId, oneProtoData._sellAmt);

        oneProtoData._sellAmt = _sellAmt == uint(-1) ?
            GETTOKENBAL438(oneProtoData.sellToken) :
            _sellAmt;

        oneProtoData._buyAmt = ONEPROTOSWAPMULTI285(oneProtoData);
        SETUINT548(setId, oneProtoData._buyAmt);

        EMITLOGSELLMULTI751(oneProtoData, getId, setId);
    }
}

contract OneInchResolverHelpers is OneProtoResolverHelpers {
    function _SELLTHREE9(
        OneInchData memory oneInchData,
        uint setId
    ) internal {
        TokenInterface _sellAddr = oneInchData.sellToken;

        uint ethAmt;
        if (address(_sellAddr) == GETETHADDR620()) {
            ethAmt = oneInchData._sellAmt;
        } else {
            TokenInterface(_sellAddr).APPROVE44(GETONEINCHTOKENTAKER586(), oneInchData._sellAmt);
        }

        require(CHECKONEINCHSIG202(oneInchData.callData), "Not-swap-function");

        oneInchData._buyAmt = ONEINCHSWAP719(oneInchData, ethAmt);
        SETUINT548(setId, oneInchData._buyAmt);

        EMITLOGSELLTHREE379(oneInchData, setId);
    }
}

contract OneProto is OneInchResolverHelpers {

    function SELL474(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        uint getId,
        uint setId
    ) external payable {
        OneProtoData memory oneProtoData = OneProtoData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            _sellAmt: sellAmt,
            unitAmt: unitAmt,
            distribution: new uint[](0),
            _buyAmt: 0,
            disableDexes: 0
        });

        _SELL499(oneProtoData, getId, setId);
    }


    function SELLTWO782(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        uint[] calldata distribution,
        uint disableDexes,
        uint getId,
        uint setId
    ) external payable {
        OneProtoData memory oneProtoData = OneProtoData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            _sellAmt: sellAmt,
            unitAmt: unitAmt,
            distribution: distribution,
            disableDexes: disableDexes,
            _buyAmt: 0
        });

        _SELLTWO817(oneProtoData, getId, setId);
    }


    function SELLMULTI899(
        address[] calldata tokens,
        uint sellAmt,
        uint unitAmt,
        uint[] calldata distribution,
        uint[] calldata disableDexes,
        uint getId,
        uint setId
    ) external payable {
        OneProtoMultiData memory oneProtoData = OneProtoMultiData({
            tokens: tokens,
            buyToken: TokenInterface(address(tokens[tokens.length - 1])),
            sellToken: TokenInterface(address(tokens[0])),
            unitAmt: unitAmt,
            distribution: distribution,
            disableDexes: disableDexes,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        _SELLMULTI27(oneProtoData, getId, setId);
    }
}

contract OneInch is OneProto {

    function SELLTHREE242(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        bytes calldata callData,
        uint setId
    ) external payable {
        OneInchData memory oneInchData = OneInchData({
            buyToken: TokenInterface(buyAddr),
            sellToken: TokenInterface(sellAddr),
            unitAmt: unitAmt,
            callData: callData,
            _sellAmt: sellAmt,
            _buyAmt: 0
        });

        _SELLTHREE9(oneInchData, setId);
    }
}

contract ConnectOne is OneInch {
    string public name = "1inch-1proto-v1";
}
