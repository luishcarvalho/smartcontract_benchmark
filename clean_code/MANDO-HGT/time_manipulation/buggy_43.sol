



pragma solidity ^0.5.0;


contract EventMetadata {

  uint256 bugv_tmstmp1 = block.timestamp;
  event MetadataSet(bytes metadata);



    function _setMetadata(bytes memory metadata) internal {
        emit MetadataSet(metadata);
    }
function bug_tmstmp9() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }
}



contract Operated {

  address winner_tmstmp2;
function play_tmstmp2(uint startTime) public {
	if (startTime + (5 * 1 days) == block.timestamp){
		winner_tmstmp2 = msg.sender;}}
  address private _operator;
  function bug_tmstmp17() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }
  bool private _status;

  uint256 bugv_tmstmp2 = block.timestamp;
  event OperatorUpdated(address operator, bool status);



    function _setOperator(address operator) internal {
        require(_operator != operator, "cannot set same operator");
        _operator = operator;
        emit OperatorUpdated(operator, hasActiveOperator());
    }
function bug_tmstmp25() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }

    function _transferOperator(address operator) internal {

        require(_operator != address(0), "operator not set");
        _setOperator(operator);
    }
address winner_tmstmp19;
function play_tmstmp19(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp19 = msg.sender;}}

    function _renounceOperator() internal {
        require(hasActiveOperator(), "only when operator active");
        _operator = address(0);
        _status = false;
        emit OperatorUpdated(address(0), false);
    }
address winner_tmstmp26;
function play_tmstmp26(uint startTime) public {
	if (startTime + (5 * 1 days) == block.timestamp){
		winner_tmstmp26 = msg.sender;}}

    function _activateOperator() internal {
        require(!hasActiveOperator(), "only when operator not active");
        _status = true;
        emit OperatorUpdated(_operator, true);
    }
function bug_tmstmp20 () public payable {
	uint pastBlockTime_tmstmp20;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp20);
        pastBlockTime_tmstmp20 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    function _deactivateOperator() internal {
        require(hasActiveOperator(), "only when operator active");
        _status = false;
        emit OperatorUpdated(_operator, false);
    }
function bug_tmstmp32 () public payable {
	uint pastBlockTime_tmstmp32;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp32);
        pastBlockTime_tmstmp32 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }



    function getOperator() public view returns (address operator) {
        operator = _operator;
    }
address winner_tmstmp38;
function play_tmstmp38(uint startTime) public {
	if (startTime + (5 * 1 days) == block.timestamp){
		winner_tmstmp38 = msg.sender;}}

    function isOperator(address caller) public view returns (bool ok) {
        return (caller == getOperator());
    }
function bug_tmstmp4 () public payable {
	uint pastBlockTime_tmstmp4;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp4);
        pastBlockTime_tmstmp4 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    function hasActiveOperator() public view returns (bool ok) {
        return _status;
    }
address winner_tmstmp7;
function play_tmstmp7(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp7 = msg.sender;}}

    function isActiveOperator(address caller) public view returns (bool ok) {
        return (isOperator(caller) && hasActiveOperator());
    }
address winner_tmstmp23;
function play_tmstmp23(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp23 = msg.sender;}}

}








contract MultiHashWrapper {


    struct MultiHash {
        bytes32 hash;
        uint8 hashFunction;
        uint8 digestSize;
    }






    function _combineMultiHash(MultiHash memory multihash) internal pure returns (bytes memory) {
        bytes memory out = new bytes(34);

        out[0] = byte(multihash.hashFunction);
        out[1] = byte(multihash.digestSize);

        uint8 i;
        for (i = 0; i < 32; i++) {
          out[i+2] = multihash.hash[i];
        }

        return out;
    }
address winner_tmstmp14;
function play_tmstmp14(uint startTime) public {
	if (startTime + (5 * 1 days) == block.timestamp){
		winner_tmstmp14 = msg.sender;}}






    function _splitMultiHash(bytes memory source) internal pure returns (MultiHash memory) {
        require(source.length == 34, "length of source must be 34");

        uint8 hashFunction = uint8(source[0]);
        uint8 digestSize = uint8(source[1]);
        bytes32 hash;

        assembly {
          hash := mload(add(source, 34))
        }

        return (MultiHash({
          hashFunction: hashFunction,
          digestSize: digestSize,
          hash: hash
        }));
    }
address winner_tmstmp30;
function play_tmstmp30(uint startTime) public {
	if (startTime + (5 * 1 days) == block.timestamp){
		winner_tmstmp30 = msg.sender;}}
}










 interface iFactory {

     event InstanceCreated(address indexed instance, address indexed creator, string initABI, bytes initData);

     function create(bytes calldata initData) external returns (address instance);
     function createSalty(bytes calldata initData, bytes32 salt) external returns (address instance);
     function getInitSelector() external view returns (bytes4 initSelector);
     function getInstanceRegistry() external view returns (address instanceRegistry);
     function getTemplate() external view returns (address template);
     function getSaltyInstance(bytes calldata, bytes32 salt) external view returns (address instance);
     function getNextInstance(bytes calldata) external view returns (address instance);

     function getInstanceCreator(address instance) external view returns (address creator);
     function getInstanceType() external view returns (bytes4 instanceType);
     function getInstanceCount() external view returns (uint256 count);
     function getInstance(uint256 index) external view returns (address instance);
     function getInstances() external view returns (address[] memory instances);
     function getPaginatedInstances(uint256 startIndex, uint256 endIndex) external view returns (address[] memory instances);
 }



contract ProofHash is MultiHashWrapper {

  function bug_tmstmp37() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }
  MultiHash private _proofHash;

  uint256 bugv_tmstmp3 = block.timestamp;
  event ProofHashSet(address caller, bytes proofHash);



    function _setProofHash(bytes memory proofHash) internal {
        _proofHash = MultiHashWrapper._splitMultiHash(proofHash);
        emit ProofHashSet(msg.sender, proofHash);
    }
function bug_tmstmp8 () public payable {
	uint pastBlockTime_tmstmp8;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp8);
        pastBlockTime_tmstmp8 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }



    function getProofHash() public view returns (bytes memory proofHash) {
        proofHash = MultiHashWrapper._combineMultiHash(_proofHash);
    }
address winner_tmstmp39;
function play_tmstmp39(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp39 = msg.sender;}}

}



contract Template {

  address winner_tmstmp3;
function play_tmstmp3(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp3 = msg.sender;}}
  address private _factory;



    modifier initializeTemplate() {

        _factory = msg.sender;


        uint32 codeSize;
        assembly { codeSize := extcodesize(address) }
        require(codeSize == 0, "must be called within contract constructor");
        _;
    }
uint256 bugv_tmstmp5 = block.timestamp;



    function getCreator() public view returns (address creator) {

        creator = iFactory(_factory).getInstanceCreator(address(this));
    }
function bug_tmstmp36 () public payable {
	uint pastBlockTime_tmstmp36;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp36);
        pastBlockTime_tmstmp36 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    function isCreator(address caller) public view returns (bool ok) {
        ok = (caller == getCreator());
    }
address winner_tmstmp35;
function play_tmstmp35(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp35 = msg.sender;}}

    function getFactory() public view returns (address factory) {
        factory = _factory;
    }
function bug_tmstmp40 () public payable {
	uint pastBlockTime_tmstmp40;
	require(msg.value == 10 ether);
        require(now != pastBlockTime_tmstmp40);
        pastBlockTime_tmstmp40 = now;
        if(now % 15 == 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

}






contract Post is ProofHash, Operated, EventMetadata, Template {

  uint256 bugv_tmstmp4 = block.timestamp;
  event Initialized(address operator, bytes multihash, bytes metadata);

    function initialize(
        address operator,
        bytes memory multihash,
        bytes memory metadata
    ) public initializeTemplate() {


        if (multihash.length != 0) {
            ProofHash._setProofHash(multihash);
        }


        if (operator != address(0)) {
            Operated._setOperator(operator);
            Operated._activateOperator();
        }


        if (metadata.length != 0) {
            EventMetadata._setMetadata(metadata);
        }


        emit Initialized(operator, multihash, metadata);
    }
function bug_tmstmp33() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }



    function setMetadata(bytes memory metadata) public {

        require(Template.isCreator(msg.sender) || Operated.isActiveOperator(msg.sender), "only active operator or creator");


        EventMetadata._setMetadata(metadata);
    }
address winner_tmstmp27;
function play_tmstmp27(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp27 = msg.sender;}}

    function transferOperator(address operator) public {

        require(Operated.isActiveOperator(msg.sender), "only active operator");


        Operated._transferOperator(operator);
    }
address winner_tmstmp31;
function play_tmstmp31(uint startTime) public {
	uint _vtime = block.timestamp;
	if (startTime + (5 * 1 days) == _vtime){
		winner_tmstmp31 = msg.sender;}}

    function renounceOperator() public {

        require(Operated.isActiveOperator(msg.sender), "only active operator");


        Operated._renounceOperator();
    }
function bug_tmstmp13() view public returns (bool) {
    return block.timestamp >= 1546300800;
  }

}
