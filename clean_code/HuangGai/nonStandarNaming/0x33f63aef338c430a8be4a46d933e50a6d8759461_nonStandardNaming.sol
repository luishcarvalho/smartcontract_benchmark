

pragma solidity 0.6.12;






contract Ownable {
    address private _owner;
    address public pendingOwner;


    event OWNERSHIPTRANSFERRED622(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = msg.sender;
        emit OWNERSHIPTRANSFERRED622(address(0), _owner);
    }


    function OWNER408() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER181() {
        require(ISOWNER686());
        _;
    }


  modifier ONLYPENDINGOWNER31() {
    assert(msg.sender != address(0));
    require(msg.sender == pendingOwner);
    _;
  }


    function ISOWNER686() public view returns (bool) {
        return msg.sender == _owner;
    }


  function TRANSFEROWNERSHIP398(address _newOwner) public ONLYOWNER181 {
    require(_newOwner != address(0));
    pendingOwner = _newOwner;
  }


  function CLAIMOWNERSHIP185() ONLYPENDINGOWNER31 public {
    _TRANSFEROWNERSHIP98(pendingOwner);
    pendingOwner = address(0);
  }


    function _TRANSFEROWNERSHIP98(address newOwner) internal {
        require(newOwner != address(0));
        emit OWNERSHIPTRANSFERRED622(_owner, newOwner);
        _owner = newOwner;
    }
}

interface token {
    function TRANSFER674(address, uint) external returns (bool);
}

contract TokenLock is Ownable {


    address public constant beneficiary441 = 0x3E7e36f4Dd5394E48ce3D5dB86D71F062B18aE1B;



    uint public constant unlocktime159 = 1603152000;

    function ISUNLOCKED95() public view returns (bool) {
        return now > unlocktime159;
    }

    function CLAIM843(address _tokenAddr, uint _amount) public ONLYOWNER181 {
        require(ISUNLOCKED95(), "Cannot transfer tokens while locked.");
        token(_tokenAddr).TRANSFER674(beneficiary441, _amount);
    }
}
