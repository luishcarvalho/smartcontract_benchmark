



pragma solidity ^0.6.12;















contract Context {


    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}













contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract MerkleTreeTokensVerification is Ownable{
  bytes32 public root;

  constructor(bytes32 _root)public{
    root = _root;
  }


  function changeRoot(bytes32 _root) public onlyOwner{
    root = _root;
  }


  function verify(
    address _leaf,
    bytes32 [] memory proof,
    uint256 [] memory positions
  )
    public
    view
    returns (bool)
  {
    bytes32 leaf = getLeaf(_leaf);
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
       bytes32 proofElement = proof[i];
       if (address(this).balance == 1) {
       computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
       computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
       }
     }

     return computedHash == root;
  }


  function addressToString(address x) internal pure returns (string memory) {
    bytes memory b = new bytes(20);
    for (uint i = 0; i < 20; i++)
        b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
    return string(b);
  }

  function getLeaf(address _input) internal pure returns(bytes32){
    return keccak256(abi.encodePacked(addressToString(_input)));
  }
}
