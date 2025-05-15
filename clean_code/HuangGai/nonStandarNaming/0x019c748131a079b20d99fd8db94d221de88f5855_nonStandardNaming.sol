




pragma solidity 0.7.0;

contract Ownable {
string public constant not_cur_owner108 = "018001";
string public constant no_xfer_2_0983 = "018002";

address public owner;
event OWNERSHIPTRANSFERRED733(address indexed previousOwner, address indexed newOwner);

modifier ONLYOWNER618(){
require(msg.sender == owner, not_cur_owner108);
 _;
}

function TRANSFEROWNERSHIP914(address _newOwner) public ONLYOWNER618 {
require(_newOwner != address(0), no_xfer_2_0983);
emit OWNERSHIPTRANSFERRED733(owner, _newOwner);
owner = _newOwner;
}}

library AddressUtils {
function ISCONTRACT915(address _addr) internal view returns (bool addressCheck) {
bytes32 codehash;
bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
assembly { codehash := extcodehash(_addr) }
addressCheck = (codehash != 0x0 && codehash != accountHash);
}}

interface ERC165{
function SUPPORTSINTERFACE217(bytes4 _interfaceID) external view returns (bool);
}

contract SupportsInterface is ERC165 {
mapping(bytes4 => bool) internal supportedInterfaces;

function SUPPORTSINTERFACE217(
bytes4 _interfaceID) external override view returns (bool) {
return supportedInterfaces[_interfaceID];
}}

library SafeMath {
string constant overflow201 = "008001";
string constant subtrahend_greater_then_minuend467 = "008002";

function ADD46(uint256 _addend1, uint256 _addend2) internal pure returns (uint256 sum) {
sum = _addend1 + _addend2;
require(sum >= _addend1, overflow201);
}}

interface ERC721TokenReceiver {
function ONERC721RECEIVED244(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

interface ERC721{
event TRANSFER898(address indexed _from, address indexed _to, uint256 indexed _tokenId);
event APPROVAL562(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
event APPROVALFORALL444(address indexed _owner, address indexed _operator, bool _approved);

function SAFETRANSFERFROM138(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;
function SAFETRANSFERFROM138(address _from, address _to, uint256 _tokenId) external;
function TRANSFERFROM921(address _from, address _to, uint256 _tokenId) external;
function APPROVE958(address _approved, uint256 _tokenId) external;
function SETAPPROVALFORALL105(address _operator, bool _approved) external;
function BALANCEOF270(address _owner) external view returns (uint256);
function OWNEROF456(uint256 _tokenId) external view returns (address);
function GETAPPROVED790(uint256 _tokenId) external view returns (address);
function ISAPPROVEDFORALL873(address _owner, address _operator) external view returns (bool);
}

contract NFToken is ERC721, SupportsInterface {
using SafeMath for uint256;
using AddressUtils for address;

string constant zero_address727 = "003001";
string constant not_valid_nft741 = "003002";
string constant not_owner_or_operator13 = "003003";
string constant not_owner_approwed_or_operator515 = "003004";
string constant not_able_to_receive_nft141 = "003005";
string constant nft_already_exists595 = "003006";
string constant not_owner152 = "003007";
string constant is_owner158 = "003008";

bytes4 internal constant magic_on_erc721_received864 = 0x150b7a02;

mapping (uint256 => address) internal idToOwner;
mapping (uint256 => address) internal idToApproval;
mapping (address => uint256) private ownerToNFTokenCount;
mapping (address => mapping (address => bool)) internal ownerToOperators;

modifier CANOPERATE488(uint256 _tokenId) {
address tokenOwner = idToOwner[_tokenId];
require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], not_owner_or_operator13);
_;
}

modifier CANTRANSFER713(uint256 _tokenId) {
address tokenOwner = idToOwner[_tokenId];
require(
  tokenOwner == msg.sender
  || idToApproval[_tokenId] == msg.sender
  || ownerToOperators[tokenOwner][msg.sender], not_owner_approwed_or_operator515);
_;
}

modifier VALIDNFTOKEN826(uint256 _tokenId) {
require(idToOwner[_tokenId] != address(0), not_valid_nft741);
_;
}

function SAFETRANSFERFROM138(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override{
_SAFETRANSFERFROM261(_from, _to, _tokenId, _data);
}

function SAFETRANSFERFROM138(address _from, address _to, uint256 _tokenId) external override {
_SAFETRANSFERFROM261(_from, _to, _tokenId, "");
}

function TRANSFERFROM921(address _from, address _to, uint256 _tokenId) external override CANTRANSFER713(_tokenId) VALIDNFTOKEN826(_tokenId) {
address tokenOwner = idToOwner[_tokenId];
require(tokenOwner == _from, not_owner152);
require(_to != address(0), zero_address727);

_TRANSFER192(_to, _tokenId);
}

function APPROVE958( address _approved, uint256 _tokenId) external override CANOPERATE488(_tokenId) VALIDNFTOKEN826(_tokenId) {
address tokenOwner = idToOwner[_tokenId];
require(_approved != tokenOwner, is_owner158);

idToApproval[_tokenId] = _approved;
emit APPROVAL562(tokenOwner, _approved, _tokenId);
}

function SETAPPROVALFORALL105(address _operator, bool _approved) external override {
ownerToOperators[msg.sender][_operator] = _approved;
emit APPROVALFORALL444(msg.sender, _operator, _approved);
}

function BALANCEOF270(address _owner) external override view returns (uint256) {
require(_owner != address(0), zero_address727);
return _GETOWNERNFTCOUNT378(_owner);
}

function OWNEROF456(uint256 _tokenId) external override view returns (address _owner){
_owner = idToOwner[_tokenId];
require(_owner != address(0), not_valid_nft741);
}

function GETAPPROVED790(uint256 _tokenId)
external override view VALIDNFTOKEN826(_tokenId)
returns (address) {
return idToApproval[_tokenId];
}

function ISAPPROVEDFORALL873(address _owner, address _operator) external override view returns (bool) {
return ownerToOperators[_owner][_operator];
}

function _TRANSFER192(address _to, uint256 _tokenId) internal {
address from = idToOwner[_tokenId];
_CLEARAPPROVAL604(_tokenId);

_REMOVENFTOKEN830(from, _tokenId);
_ADDNFTOKEN970(_to, _tokenId);

emit TRANSFER898(from, _to, _tokenId);
}

function _MINT19(address _to, uint256 _tokenId) internal virtual {
require(_to != address(0), zero_address727);
require(idToOwner[_tokenId] == address(0), nft_already_exists595);

_ADDNFTOKEN970(_to, _tokenId);
emit TRANSFER898(address(0), _to, _tokenId);
}

function _REMOVENFTOKEN830(address _from, uint256 _tokenId) internal virtual {
require(idToOwner[_tokenId] == _from, not_owner152);
ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
delete idToOwner[_tokenId];
}

function _ADDNFTOKEN970(address _to, uint256 _tokenId) internal virtual {
require(idToOwner[_tokenId] == address(0), nft_already_exists595);

idToOwner[_tokenId] = _to;
ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].ADD46(1);
}

function _GETOWNERNFTCOUNT378(address _owner) internal virtual view returns (uint256){
return ownerToNFTokenCount[_owner];
}

function _SAFETRANSFERFROM261(address _from, address _to, uint256 _tokenId, bytes memory _data)
private CANTRANSFER713(_tokenId) VALIDNFTOKEN826(_tokenId){
address tokenOwner = idToOwner[_tokenId];
require(tokenOwner == _from, not_owner152);
require(_to != address(0), zero_address727);

_TRANSFER192(_to, _tokenId);

if (_to.ISCONTRACT915()) {
bytes4 retval = ERC721TokenReceiver(_to).ONERC721RECEIVED244(msg.sender, _from, _tokenId, _data);
require(retval == magic_on_erc721_received864, not_able_to_receive_nft141);
}}

function _CLEARAPPROVAL604(uint256 _tokenId) private {
if (idToApproval[_tokenId] != address(0)) {
delete idToApproval[_tokenId];
}}}

contract NFTokenMetadata is NFToken {
string internal nftName;
string internal nftSymbol;

mapping (uint256 => string) internal idToUri;

function NAME497() external view returns (string memory _name){
_name = nftName;
}

function SYMBOL48() external view returns (string memory _symbol) {
_symbol = nftSymbol;
}}

contract NoColoredAllowed is NFTokenMetadata, Ownable{

constructor() {
nftName = "No Colored Allowed";
nftSymbol = "XCA";
owner = msg.sender;
supportedInterfaces[0x01ffc9a7] = true;
supportedInterfaces[0x80ac58cd] = true;
supportedInterfaces[0x5b5e139f] = true;
}

uint256 public artTotal;
uint256 public artCap = 144;
string public constant arthead473 = '<svg version="1.1" id="NoColoredAllowed" xmlns="http:
string public constant arttail672 = ';}</style></svg>';

mapping (uint256 => string) internal artDNAStore;
mapping (uint256 => uint256) internal artSetStore;

event BIRTH139(uint256 tokenID, string artDNA, uint256 artSet);

function GETDNA928(uint256 tokenID) public view returns (string memory artDNA) {
artDNA = artDNAStore[tokenID];
}

function GETSET947(uint256 tokenID) public view returns (uint256 artSet) {
artSet = artSetStore[tokenID];
}

function GENERATE93(uint256 tokenID) public view returns (string memory SVG) {
SVG = string(abi.encodePacked(arthead473, artDNAStore[tokenID], arttail672));
}

function TOKENURI670(uint256 _tokenId) external view VALIDNFTOKEN826(_tokenId) returns (string memory) {
return GENERATE93(_tokenId);
}

function TOKENIZE443 (string memory artDNA, uint256 artSet) public ONLYOWNER618 {{
artTotal = artTotal + 1;
artDNAStore[artTotal] = artDNA;
artSetStore[artTotal] = artSet;

_MINTPRINT97();
emit BIRTH139(artTotal, artDNA, artSet);
}}

function _MINTPRINT97() private {
uint256 tokenId = artTotal;
require(artTotal <= artCap, "144 tokens max");
_MINT19(msg.sender, tokenId);
}}
