





pragma solidity ^0.5.16;










contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }




    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }








    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }




    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



pragma solidity ^0.5.16;

contract Managerable is Ownable {

    address private _managerAddress;




    modifier onlyManager() {
        require(_managerAddress == msg.sender,"Managerable: caller is not the Manager");
        _;
    }




    function setManager(address managerAddress)
    public
    onlyOwner
    {
        _managerAddress = managerAddress;
    }




    function getManager()public view returns (address) {
        return _managerAddress;
    }
}



pragma solidity ^0.5.16;

interface IFNXOracle {






    function getPrice(address asset) external view returns (uint256);
    function getUnderlyingPrice(uint256 cToken) external view returns (uint256);
    function getPrices(uint256[] calldata assets) external view returns (uint256[]memory);
    function getAssetAndUnderlyingPrice(address asset,uint256 underlying) external view returns (uint256,uint256);


}
contract ImportOracle is Ownable{
    IFNXOracle internal _oracle;
    function oraclegetPrices(uint256[] memory assets) internal view returns (uint256[]memory){
        uint256[] memory prices = _oracle.getPrices(assets);
        uint256 len = assets.length;
        for (uint i=0;i<len;i++){
        require(prices[i] >= 100 && prices[i] <= 1e30);
        }
        return prices;
    }
    function oraclePrice(address asset) internal view returns (uint256){
        uint256 price = _oracle.getPrice(asset);
        require(price >= 100 && price <= 1e30);
        return price;
    }
    function oracleUnderlyingPrice(uint256 cToken) internal view returns (uint256){
        uint256 price = _oracle.getUnderlyingPrice(cToken);
        require(price >= 100 && price <= 1e30);
        return price;
    }
    function oracleAssetAndUnderlyingPrice(address asset,uint256 cToken) internal view returns (uint256,uint256){
        (uint256 price1,uint256 price2) = _oracle.getAssetAndUnderlyingPrice(asset,cToken);
        require(price1 >= 100 && price1 <= 1e30);
        require(price2 >= 100 && price2 <= 1e30);
        return (price1,price2);
    }
    function getOracleAddress() public view returns(address){
        return address(_oracle);
    }
    function setOracleAddress(address oracle)public onlyOwner{
        _oracle = IFNXOracle(oracle);
    }
}



pragma solidity ^0.5.16;



library whiteListUint32 {






    function addWhiteListUint32(uint32[] storage whiteList,uint32 temp) internal{
        if (!isEligibleUint32(whiteList,temp)){
            whiteList.push(temp);
        }
    }



    function removeWhiteListUint32(uint32[] storage whiteList,uint32 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}



library whiteListUint256 {

    function addWhiteListUint256(uint256[] storage whiteList,uint256 temp) internal{
        if (!isEligibleUint256(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListUint256(uint256[] storage whiteList,uint256 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}



library whiteListAddress {

    function addWhiteListAddress(address[] storage whiteList,address temp) internal{
        if (!isEligibleAddress(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListAddress(address[] storage whiteList,address temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleAddress(address[] memory whiteList,address temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexAddress(address[] memory whiteList,address temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}



pragma solidity ^0.5.16;





contract UnderlyingAssets is Ownable {
    using whiteListUint32 for uint32[];

    uint32[] internal underlyingAssets;




    function addUnderlyingAsset(uint32 underlying)public onlyOwner{
        underlyingAssets.addWhiteListUint32(underlying);
    }
    function setUnderlyingAsset(uint32[] memory underlyings)public onlyOwner{
        underlyingAssets = underlyings;
    }




    function removeUnderlyingAssets(uint32 removeUnderlying)public onlyOwner returns(bool) {
        return underlyingAssets.removeWhiteListUint32(removeUnderlying);
    }



    function getUnderlyingAssets()public view returns (uint32[] memory){
        return underlyingAssets;
    }




    function isEligibleUnderlyingAsset(uint32 underlying) public view returns (bool){
        return underlyingAssets.isEligibleUint32(underlying);
    }
    function _getEligibleUnderlyingIndex(uint32 underlying) internal view returns (uint256){
        return underlyingAssets._getEligibleIndexUint32(underlying);
    }
}



pragma solidity ^0.5.16;

interface IVolatility {
    function calculateIv(uint32 underlying,uint8 optType,uint256 expiration,uint256 currentPrice,uint256 strikePrice)external view returns (uint256);
}
contract ImportVolatility is Ownable{
    IVolatility internal _volatility;
    function getVolatilityAddress() public view returns(address){
        return address(_volatility);
    }
    function setVolatilityAddress(address volatility)public onlyOwner{
        _volatility = IVolatility(volatility);
    }
}



pragma solidity ^0.5.16;

interface IOptionsPrice {
    function getOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,uint32 underlying,uint8 optType)external view returns (uint256);
    function getOptionsPrice_iv(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
                uint256 ivNumerator,uint8 optType)external view returns (uint256);
    function calOptionsPriceRatio(uint256 selfOccupied,uint256 totalOccupied,uint256 totalCollateral) external view returns (uint256);
}
contract ImportOptionsPrice is Ownable{
    IOptionsPrice internal _optionsPrice;
    function getOptionsPriceAddress() public view returns(address){
        return address(_optionsPrice);
    }
    function setOptionsPriceAddress(address optionsPrice)public onlyOwner{
        _optionsPrice = IOptionsPrice(optionsPrice);
    }
}



pragma solidity ^0.5.16;







contract Operator is Ownable {
    using whiteListAddress for address[];
    address[] private _operatorList;




    modifier onlyOperator() {
        require(_operatorList.isEligibleAddress(msg.sender),"Managerable: caller is not the Operator");
        _;
    }




    modifier onlyOperatorIndex(uint256 index) {
        require(_operatorList.length>index && _operatorList[index] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }




    function addOperator(address addAddress)public onlyOwner{
        _operatorList.addWhiteListAddress(addAddress);
    }




    function setOperator(uint256 index,address addAddress)public onlyOwner{
        _operatorList[index] = addAddress;
    }




    function removeOperator(address removeAddress)public onlyOwner returns (bool){
        return _operatorList.removeWhiteListAddress(removeAddress);
    }




    function getOperator()public view returns (address[] memory) {
        return _operatorList;
    }




    function setOperators(address[] memory operators)public onlyOwner {
        _operatorList = operators;
    }
}



pragma solidity ^0.5.16;


contract ImputRange is Ownable {


    uint256 private maxAmount = 1e30;

    uint256 private minAmount = 1e2;

    modifier InRange(uint256 amount) {
        require(maxAmount>=amount && minAmount<=amount,"input amount is out of input amount range");
        _;
    }




    function isInputAmountInRange(uint256 Amount)public view returns (bool){
        return(maxAmount>=Amount && minAmount<=Amount);
    }








    modifier Smaller(uint256 amount) {
        require(maxAmount>=amount,"input amount is larger than maximium");
        _;
    }
    modifier Larger(uint256 amount) {
        require(minAmount<=amount,"input amount is smaller than maximium");
        _;
    }



    function getInputAmountRange() public view returns(uint256,uint256) {
        return (minAmount,maxAmount);
    }





    function setInputAmountRange(uint256 _minAmount,uint256 _maxAmount) public onlyOwner{
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }
}



pragma solidity ^0.5.16;







contract OptionsData is UnderlyingAssets,ImputRange,Managerable,ImportOracle,ImportVolatility,ImportOptionsPrice,Operator{


        struct OptionsInfo {
        address     owner;
        uint8   	optType;
        uint24		underlying;
        uint64      optionsPrice;

        address     settlement;
        uint64      createTime;
        uint32		expiration;


        uint128     amount;
        uint128     settlePrice;

        uint128     strikePrice;
        uint32      priceRate;
        uint64      iv;
        uint32      extra;
    }

    uint256 internal limitation = 1 hours;

    OptionsInfo[] internal allOptions;

    mapping(address=>uint64[]) internal optionsBalances;

    uint32[] internal expirationList;


    uint256 internal netWorthirstOption;

    mapping(address=>int256) internal optionsLatestNetWorth;


    uint256 internal occupiedFirstOption;

    uint256 internal callOccupied;
    uint256 internal putOccupied;

    int256 internal callLatestOccupied;
    int256 internal putLatestOccupied;











    event CreateOption(address indexed owner,uint256 indexed optionID,uint8 optType,uint32 underlying,uint256 expiration,uint256 strikePrice,uint256 amount);



    event BurnOption(address indexed owner,uint256 indexed optionID,uint amount);
    event DebugEvent(uint256 id,uint256 value1,uint256 value2);
}
































pragma solidity ^0.5.16;





contract baseProxy is Ownable {
    address public implementation;
    constructor(address implementation_) public {

        implementation = implementation_;
        (bool success,) = implementation_.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success);
    }
    function getImplementation()public view returns(address){
        return implementation;
    }
    function setImplementation(address implementation_)public onlyOwner{
        implementation = implementation_;
        (bool success,) = implementation_.delegatecall(abi.encodeWithSignature("update()"));
        require(success);
    }







    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        (bool success, bytes memory returnData) = implementation.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }








    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return abi.decode(returnData, (bytes));
    }

    function delegateToViewAndReturn() internal view returns (bytes memory) {
        (bool success, ) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", msg.data));

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(add(free_mem_ptr, 0x40), returndatasize) }
        }
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(free_mem_ptr, returndatasize) }
        }
    }
}



pragma solidity ^0.5.16;






contract OptionsProxy is OptionsData,baseProxy{







    constructor(address implementation_,address oracleAddr,address optionsPriceAddr,address ivAddress)
         baseProxy(implementation_) public  {
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _volatility = IVolatility(ivAddress);
    }
    function setTimeLimitation(uint256 )public{
        delegateAndReturn();
    }
    function getTimeLimitation()public view returns(uint256){
        delegateToViewAndReturn();
    }





    function getUserOptionsID(address )public view returns(uint64[] memory){
        delegateToViewAndReturn();
    }






    function getUserOptionsID(address )public view returns(uint64[] memory){
        delegateToViewAndReturn();
    }



    function getOptionInfoLength()public view returns (uint256){
        delegateToViewAndReturn();
    }





    function getOptionInfoList(uint256 )public view
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        delegateToViewAndReturn();
    }




    function getOptionInfoListFromID(uint256[] memory )public view
                returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        delegateToViewAndReturn();
    }




    function getOptionsLimitTimeById(uint256 )public view returns(uint256){
        delegateToViewAndReturn();
    }




    function getOptionsById(uint256 )public view returns(uint256,address,uint8,uint32,uint256,uint256,uint256){
        delegateToViewAndReturn();
    }




    function getOptionsExtraById(uint256 )public view returns(address,uint256,uint256,uint256,uint256){
        delegateToViewAndReturn();
    }





    function getExerciseWorth(uint256 )public view returns(uint256){
        delegateToViewAndReturn();
    }












    function addExpiration(uint32 )public{
        delegateAndReturn();
    }




    function removeExpirationList(uint32 )public returns(bool) {
        delegateAndReturn();
    }



    function getExpirationList()public view returns (uint32[] memory){
        delegateToViewAndReturn();
    }




    function isEligibleExpiration(uint256 ) public view returns (bool){
        delegateToViewAndReturn();
    }




    function checkExpiration(uint256 ) public view{
        delegateToViewAndReturn();
    }





    function getBurnedFullPay(uint256 ) public view returns(address,uint256){
        delegateToViewAndReturn();
    }



    function getOccupiedCalInfo()public view returns(uint256,int256,int256){
        delegateToViewAndReturn();
    }



    function setOccupiedCollateral() public {
        delegateAndReturn();
    }






    function calculatePhaseOccupiedCollateral(uint256 ) public view returns(uint256,uint256,uint256,bool){
        delegateToViewAndReturn();
    }









    function setCollateralPhase(uint256 ,
        uint256 ) public{
        delegateAndReturn();
    }
    function getAllTotalOccupiedCollateral() public view returns (uint256,uint256){
        delegateToViewAndReturn();
    }



    function getCallTotalOccupiedCollateral() public view returns (uint256) {
        delegateToViewAndReturn();
    }



    function getPutTotalOccupiedCollateral() public view returns (uint256) {
        delegateToViewAndReturn();
    }



    function getTotalOccupiedCollateral() public view returns (uint256) {
        delegateToViewAndReturn();
    }




    function getNetWrothCalInfo(address[] memory )public view returns(uint256,int256[] memory){
        delegateToViewAndReturn();
    }




    function getNetWrothLatestWorth(address )public view returns(int256){
        delegateToViewAndReturn();
    }






    function setSharedState(uint256 ) public{
        delegateAndReturn();
    }







    function calRangeSharedPayment(uint256 )
            public view returns(int256[] memory,uint256[] memory,uint256){
        delegateToViewAndReturn();
    }







    function calculatePhaseOptionsFall(uint256 ) public view returns(int256[] memory){
        delegateToViewAndReturn();
    }





    function getOptionCalRangeAll(address[] memory )public view returns(uint256,int256,int256,uint256,int256[] memory,uint256,uint256){
        delegateToViewAndReturn();
    }









    function createOptions(address ,
    uint128 ) public returns(uint256) {
        delegateAndReturn();
    }







    function burnOptions(address )public{
        delegateAndReturn();
    }
    function getUserAllOptionInfo(address )public view
        returns(address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory){
        delegateToViewAndReturn();
    }
}
