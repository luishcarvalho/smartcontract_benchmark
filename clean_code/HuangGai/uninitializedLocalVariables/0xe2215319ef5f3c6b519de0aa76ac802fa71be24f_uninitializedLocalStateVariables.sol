





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



pragma solidity =0.5.16;


contract Halt is Ownable {

    bool private halted ;


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
        uint256 len ;

        uint256 i;

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
        uint256 len ;

        for (uint256 i;i<len;i++){

            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (uint256){
        uint256 len ;

        uint256 i;

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
        uint256 len ;

        uint256 i;

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
        uint256 len ;

        for (uint256 i;i<len;i++){

            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (uint256){
        uint256 len ;

        uint256 i;

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
        uint256 len ;

        uint256 i;

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
        uint256 len ;

        for (uint256 i;i<len;i++){

            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexAddress(address[] memory whiteList,address temp) internal pure returns (uint256){
        uint256 len ;

        uint256 i;

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




  bool private reentrancyLock ;









  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}



pragma solidity =0.5.16;








contract MinePoolData is Managerable,AddressWhiteList,ReentrancyGuard {

    uint256 constant calDecimals = 1e18;


    mapping(address=>mapping(address=>uint256)) internal minerBalances;


    mapping(address=>mapping(address=>uint256)) internal minerOrigins;


    mapping(address=>uint256) internal totalMinedWorth;

    mapping(address=>uint256) internal totalMinedCoin;

    mapping(address=>uint256) internal latestSettleTime;

    mapping(address=>uint256) internal mineAmount;

    mapping(address=>uint256) internal mineInterval;

    mapping(address=>uint256) internal buyingMineMap;

    uint256 constant internal opBurnCoin = 1;
    uint256 constant internal opMintCoin = 2;
    uint256 constant internal opTransferCoin = 3;



    event MintMiner(address indexed account,uint256 amount);



    event BurnMiner(address indexed account,uint256 amount);



    event RedeemMineCoin(address indexed from, address indexed mineCoin, uint256 value);



    event TranserMiner(address indexed from, address indexed to, uint256 amount);



    event BuyingMiner(address indexed account,address indexed mineCoin,uint256 amount);
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







contract MinePoolProxy is MinePoolData,baseProxy {
    constructor (address implementation_) baseProxy(implementation_) public{
    }



    function()external payable{
    }





    function redeemOut(address )public{
        delegateAndReturn();
    }




    function getTotalMined(address )public view returns(uint256){
        delegateToViewAndReturn();
    }





    function getMineInfo(address )public view returns(uint256,uint256){
        delegateToViewAndReturn();
    }





    function getMinerBalance(address )public view returns(uint256){
        delegateToViewAndReturn();
    }






    function setMineCoinInfo(address )public {
        delegateAndReturn();
    }





    function setBuyingMineInfo(address )public {
        delegateAndReturn();
    }




    function getBuyingMineInfo(address )public view returns(uint256){
        delegateToViewAndReturn();
    }



    function getBuyingMineInfoAll()public view returns(address[] memory,uint256[] memory){
        delegateToViewAndReturn();
    }






    function transferMinerCoin(address ) public {
        delegateAndReturn();
    }





    function mintMinerCoin(address ) public {
        delegateAndReturn();
    }





    function burnMinerCoin(address ) public {
        delegateAndReturn();
    }





    function addMinerBalance(address ) public {
        delegateAndReturn();
    }





    function setMineAmount(address )public {
        delegateAndReturn();
    }





    function setMineInterval(address )public {
        delegateAndReturn();
    }





    function redeemMinerCoin(address )public{
        delegateAndReturn();
    }
}
