








pragma solidity 0.5.16;


contract Ownable {
  address public owner;


  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );






  constructor() public {
    owner = msg.sender;
  }




  modifier onlyOwner() {
    require(tx.origin == owner);

    _;
  }





  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }





  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ZeroXConnector is Ownable {

    address internal target_;


    constructor(
        address _newTarget)
        public
    {
        _setTarget(_newTarget);
    }

    function()
        external
        payable
    {
        if (gasleft() <= 2300) {
            return;
        }

        address target = target_;
        bytes memory data = msg.data;
        assembly {
            let result := delegatecall(gas, target, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function setTarget(
        address _newTarget)
        public
        onlyOwner
    {
        _setTarget(_newTarget);
    }

    function _setTarget(
        address _newTarget)
        internal
    {
        require(_isContract(_newTarget), "target not a contract");
        target_ = _newTarget;
    }

    function _isContract(
        address addr)
        internal
        view
        returns (bool)
    {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}
