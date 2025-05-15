





















pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";








contract OneInchExchangeAdapter {




    address public oneInchApprovalAddress;


    address public oneInchExchangeAddress;


    bytes4 public oneInchFunctionSignature;










    constructor(
        address _oneInchApprovalAddress,
        address _oneInchExchangeAddress,
        bytes4 _oneInchFunctionSignature
    )
        public
    {
        oneInchApprovalAddress = _oneInchApprovalAddress;
        oneInchExchangeAddress = _oneInchExchangeAddress;
        oneInchFunctionSignature = _oneInchFunctionSignature;
    }
















    function getTradeCalldata(
        address _sourceToken,
        address _destinationToken,
        address ,
        uint256 _sourceQuantity,
        uint256 _minDestinationQuantity,
        bytes memory _data
    )
        public
        view
        returns (address, uint256, bytes memory)
    {
        bytes4 signature;
        address fromToken;
        address toToken;
        uint256 fromTokenAmount;
        uint256 minReturnAmount;



        assembly {
            signature := mload(add(_data, 32))
            fromToken := mload(add(_data, 36))
            toToken := mload(add(_data, 68))
            fromTokenAmount := mload(add(_data, 100))
            minReturnAmount := mload(add(_data, 132))
        }

        require(
            signature == oneInchFunctionSignature,
            "Not One Inch Swap Function"
        );

        require(
            fromToken == _sourceToken,
            "Invalid send token"
        );

        require(
            toToken == _destinationToken,
            "Invalid receive token"
        );

        require(
            fromTokenAmount == _sourceQuantity,
            "Source quantity mismatch"
        );

        require(
            minReturnAmount >= _minDestinationQuantity,
            "Min destination quantity mismatch"
        );

        return (oneInchExchangeAddress, 0, _data);
    }






    function getSpender()
        public
        view
        returns (address)
    {
        return oneInchApprovalAddress;
    }
}
