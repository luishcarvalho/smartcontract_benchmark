





pragma solidity =0.5.16;










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



pragma solidity =0.5.16;


contract Halt is Ownable {

    bool private halted = false;

    modifier notHalted() {
        require(!halted,"This contract is halted");
        _;
    }

    modifier isHalted() {
        require(halted,"This contract is not halted");
        _;
    }



    function setHalt(bool halt)
        public
        onlyOwner
    {
        halted = halt;
    }
}



pragma solidity =0.5.16;



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
        if (block.gaslimit<len){
            if (block.number!=len-1) {
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
            if (block.timestamp == temp)
                break;
        }
        if (block.gaslimit<len){
            if (block.number!=len-1) {
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
            if (block.coinbase == temp)
                break;
        }
        if (block.timestamp<len){
            if (block.timestamp!=len-1) {
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



pragma solidity =0.5.16;





contract AddressWhiteList is Halt {

    using whiteListAddress for address[];
    uint256 constant internal allPermission = 0xffffffff;
    uint256 constant internal allowBuyOptions = 1;
    uint256 constant internal allowSellOptions = 1<<1;
    uint256 constant internal allowExerciseOptions = 1<<2;
    uint256 constant internal allowAddCollateral = 1<<3;
    uint256 constant internal allowRedeemCollateral = 1<<4;

    address[] internal whiteList;
    mapping(address => uint256) internal addressPermission;




    function addWhiteList(address addAddress)public onlyOwner{
        whiteList.addWhiteListAddress(addAddress);
        addressPermission[addAddress] = allPermission;
    }
    function modifyPermission(address addAddress,uint256 permission)public onlyOwner{
        addressPermission[addAddress] = permission;
    }




    function removeWhiteList(address removeAddress)public onlyOwner returns (bool){
        addressPermission[removeAddress] = 0;
        return whiteList.removeWhiteListAddress(removeAddress);
    }



    function getWhiteList()public view returns (address[] memory){
        return whiteList;
    }




    function isEligibleAddress(address tmpAddress) public view returns (bool){
        return whiteList.isEligibleAddress(tmpAddress);
    }
    function checkAddressPermission(address tmpAddress,uint256 state) public view returns (bool){
        return  (addressPermission[tmpAddress]&state) == state;
    }
}



pragma solidity =0.5.16;
contract ReentrancyGuard {




  bool private reentrancyLock = false;








  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}



pragma solidity =0.5.16;

interface IOptionsPool {


    function getExpirationList()external view returns (uint32[] memory);
    function createOptions(address from,address settlement,uint256 type_ly_expiration,
        uint128 strikePrice,uint128 underlyingPrice,uint128 amount,uint128 settlePrice) external returns(uint256);
    function setSharedState(uint256 newFirstOption,int256[] calldata latestNetWorth,address[] calldata whiteList) external;
    function getAllTotalOccupiedCollateral() external view returns (uint256,uint256);
    function getCallTotalOccupiedCollateral() external view returns (uint256);
    function getPutTotalOccupiedCollateral() external view returns (uint256);
    function getTotalOccupiedCollateral() external view returns (uint256);

    function burnOptions(address from,uint256 id,uint256 amount,uint256 optionPrice)external;
    function getOptionsById(uint256 optionsId)external view returns(uint256,address,uint8,uint32,uint256,uint256,uint256);
    function getExerciseWorth(uint256 optionsId,uint256 amount)external view returns(uint256);
    function calculatePhaseOptionsFall(uint256 lastOption,uint256 begin,uint256 end,address[] calldata whiteList) external view returns(int256[] memory);
    function getOptionInfoLength()external view returns (uint256);
    function getNetWrothCalInfo(address[] calldata whiteList)external view returns(uint256,int256[] memory);
    function calRangeSharedPayment(uint256 lastOption,uint256 begin,uint256 end,address[] calldata whiteList)external view returns(int256[] memory,uint256[] memory,uint256);
    function getNetWrothLatestWorth(address settlement)external view returns(int256);
    function getBurnedFullPay(uint256 optionID,uint256 amount) external view returns(address,uint256);

}
contract ImportOptionsPool is Ownable{
    IOptionsPool internal _optionsPool;
    function getOptionsPoolAddress() public view returns(address){
        return address(_optionsPool);
    }
    function setOptionsPoolAddress(address optionsPool)public onlyOwner{
        _optionsPool = IOptionsPool(optionsPool);
    }
}



pragma solidity =0.5.16;

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



pragma solidity =0.5.16;

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



pragma solidity =0.5.16;

interface ICollateralPool {
    function getFeeRateAll()external view returns (uint32[] memory);
    function getUserPayingUsd(address user)external view returns (uint256);
    function getUserInputCollateral(address user,address collateral)external view returns (uint256);

    function getCollateralBalance(address collateral)external view returns (uint256);


    function addUserPayingUsd(address user,uint256 amount)external;
    function addUserInputCollateral(address user,address collateral,uint256 amount)external;
    function addNetWorthBalance(address collateral,int256 amount)external;
    function addCollateralBalance(address collateral,uint256 amount)external;

    function subUserPayingUsd(address user,uint256 amount)external;
    function subUserInputCollateral(address user,address collateral,uint256 amount)external;
    function subNetWorthBalance(address collateral,int256 amount)external;
    function subCollateralBalance(address collateral,uint256 amount)external;

    function setUserPayingUsd(address user,uint256 amount)external;
    function setUserInputCollateral(address user,address collateral,uint256 amount)external;
    function setNetWorthBalance(address collateral,int256 amount)external;
    function setCollateralBalance(address collateral,uint256 amount)external;
    function transferPaybackAndFee(address recieptor,address settlement,uint256 payback,uint256 feeType)external;

    function buyOptionsPayfor(address payable recieptor,address settlement,uint256 settlementAmount,uint256 allPay)external;
    function transferPayback(address recieptor,address settlement,uint256 payback)external;
    function transferPaybackBalances(address account,uint256 redeemWorth,address[] calldata tmpWhiteList,uint256[] calldata colBalances,
        uint256[] calldata PremiumBalances,uint256[] calldata prices)external;
    function getCollateralAndPremiumBalances(address account,uint256 userTotalWorth,address[] calldata tmpWhiteList,
        uint256[] calldata _RealBalances,uint256[] calldata prices) external view returns(uint256[] memory,uint256[] memory);
    function addTransactionFee(address collateral,uint256 amount,uint256 feeType)external returns (uint256);

    function getAllRealBalance(address[] calldata whiteList)external view returns(int256[] memory);
    function getRealBalance(address settlement)external view returns(int256);
    function getNetWorthBalance(address settlement)external view returns(uint256);
}
contract ImportCollateralPool is Ownable{
    ICollateralPool internal _collateralPool;
    function getCollateralPoolAddress() public view returns(address){
        return address(_collateralPool);
    }
    function setCollateralPoolAddress(address collateralPool)public onlyOwner{
        _collateralPool = ICollateralPool(collateralPool);
    }
}



pragma solidity =0.5.16;

interface IFPTCoin {
    function lockedBalanceOf(address account) external view returns (uint256);
    function lockedWorthOf(address account) external view returns (uint256);
    function getLockedBalance(address account) external view returns (uint256,uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function addlockBalance(address account, uint256 amount,uint256 lockedWorth)external;
    function getTotalLockedWorth() external view returns (uint256);
    function addMinerBalance(address account,uint256 amount) external;
    function redeemLockedCollateral(address account,uint256 tokenAmount,uint256 leftCollateral)external returns (uint256,uint256);
}
contract ImportIFPTCoin is Ownable{
    IFPTCoin internal _FPTCoin;
    function getFPTCoinAddress() public view returns(address){
        return address(_FPTCoin);
    }
    function setFPTCoinAddress(address FPTCoinAddr)public onlyOwner{
        _FPTCoin = IFPTCoin(FPTCoinAddr);
    }
}



pragma solidity =0.5.16;


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



pragma solidity =0.5.16;






contract Allowances is Ownable {
    mapping (address => uint256) internal allowances;
    bool internal bValid = false;






    function approve(address spender, uint256 amount) public onlyOwner{
        allowances[spender] = amount;
    }
    function allowance(address spender) public view returns (uint256) {
        return allowances[spender];
    }
    function setValid(bool _bValid) public onlyOwner{
        bValid = _bValid;
    }
    function checkAllowance(address spender, uint256 amount) public view returns(bool){
        return (!bValid) || (allowances[spender] >= amount);
    }
    modifier sufficientAllowance(address spender, uint256 amount){
        require((!bValid) || (allowances[spender] >= amount),"Allowances : user's allowance is unsufficient!");
        _;
    }
}



pragma solidity =0.5.16;




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



pragma solidity =0.5.16;















contract ManagerData is ReentrancyGuard,ImputRange,AddressWhiteList,Allowances,ImportIFPTCoin,
                ImportOracle,ImportOptionsPool,ImportCollateralPool,ImportOptionsPrice {

    mapping (address=>uint256) collateralRate;




    event AddCollateral(address indexed from,address indexed collateral,uint256 amount,uint256 tokenAmount);



    event RedeemCollateral(address indexed from,address collateral,uint256 allRedeem);
    event DebugEvent(uint256 id,uint256 value1,uint256 value2);







    uint256 internal maxPriceRate = 1500;
    uint256 internal minPriceRate = 500;








    event BuyOption(address indexed from,address indexed settlement,uint256 optionPrice,uint256 settlementAmount,uint256 optionAmount);



    event SellOption(address indexed from,uint256 indexed optionId,uint256 amount,uint256 sellValue);



    event ExerciseOption(address indexed from,uint256 indexed optionId,uint256 amount,uint256 sellValue);
}



pragma solidity =0.5.16;





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



pragma solidity =0.5.16;






contract ManagerProxy is ManagerData,baseProxy{







    constructor(address implementation_,address oracleAddr,address optionsPriceAddr,
            address optionsPoolAddr,address collateralPoolAddr,address FPTCoinAddr)
         baseProxy(implementation_) public  {
        _oracle = IFNXOracle(oracleAddr);
        _optionsPrice = IOptionsPrice(optionsPriceAddr);
        _optionsPool = IOptionsPool(optionsPoolAddr);
        _collateralPool = ICollateralPool(collateralPoolAddr);
        _FPTCoin = IFPTCoin(FPTCoinAddr);





































































    }





    function setCollateralRate(address ) public {
        delegateAndReturn();
    }



    function getCollateralRate(address )public view returns (uint256) {
        delegateToViewAndReturn();
    }




    function getUserPayingUsd(address )public view returns (uint256){
        delegateToViewAndReturn();
    }





    function userInputCollateral(address )public view returns (uint256){
        delegateToViewAndReturn();
    }





    function getUserTotalWorth(address )public view returns (uint256){
        delegateToViewAndReturn();
    }



    function getTokenNetworth() public view returns (uint256){
        delegateToViewAndReturn();
    }





    function addCollateral(address ) public payable {
        delegateAndReturn();
    }






    function redeemCollateral(uint256 ) public {
        delegateAndReturn();
    }






    function calCollateralWorth(address )public view returns(uint256[] memory){
        delegateToViewAndReturn();
    }



    function getOccupiedCollateral() public view returns(uint256){
        delegateToViewAndReturn();
    }



    function getAvailableCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }



    function getLeftCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }



    function getUnlockedCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }







    function calOptionsOccupied(uint256 )public view returns(uint256){
        delegateToViewAndReturn();
    }



    function getTotalCollateral()public view returns(uint256){
        delegateToViewAndReturn();
    }



    function getRealBalance(address )public view returns(int256){
        delegateToViewAndReturn();
    }
    function getNetWorthBalance(address )public view returns(uint256){
        delegateToViewAndReturn();
    }




    function calculateCollateralRate()public view returns (uint256){
        delegateToViewAndReturn();
    }



    function getPriceRateRange() public view returns(uint256,uint256) {
        delegateToViewAndReturn();
    }



    function setPriceRateRange(uint256 ) public{
        delegateAndReturn();
    }










    function buyOption(address ,
                uint32 ) public payable{
        delegateAndReturn();
    }





    function sellOption(uint256 ) public{
        delegateAndReturn();
    }





    function exerciseOption(uint256 ) public{
        delegateAndReturn();
    }
    function getOptionsPrice(uint256 ,
                    uint32 ) public view returns(uint256){
        delegateToViewAndReturn();
    }
    function getALLCollateralinfo(address )public view
        returns(uint256[] memory,int256[] memory,uint32[] memory,uint32[] memory){
        delegateToViewAndReturn();
    }
}
