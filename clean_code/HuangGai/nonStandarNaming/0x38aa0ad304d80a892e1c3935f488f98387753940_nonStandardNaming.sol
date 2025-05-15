pragma solidity 0.5.3;








contract Ownable {
    address private _owner;

    event OWNERSHIPTRANSFERRED628(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = msg.sender;
        emit OWNERSHIPTRANSFERRED628(address(0), _owner);
    }


    function OWNER307() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER7() {
        require(ISOWNER830());
        _;
    }


    function ISOWNER830() public view returns (bool) {
        return msg.sender == _owner;
    }


    function RENOUNCEOWNERSHIP84() public ONLYOWNER7 {
        emit OWNERSHIPTRANSFERRED628(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP319(address newOwner) public ONLYOWNER7 {
        _TRANSFEROWNERSHIP813(newOwner);
    }


    function _TRANSFEROWNERSHIP813(address newOwner) internal {
        require(newOwner != address(0));
        emit OWNERSHIPTRANSFERRED628(_owner, newOwner);
        _owner = newOwner;
    }
}



contract OwnableSecondary is Ownable {
  address private _primary;

  event PRIMARYTRANSFERRED938(
    address recipient
  );


  constructor() internal {
    _primary = msg.sender;
    emit PRIMARYTRANSFERRED938(_primary);
  }


   modifier ONLYPRIMARYOROWNER634() {
     require(msg.sender == _primary || msg.sender == OWNER307(), "not the primary user nor the owner");
     _;
   }


  modifier ONLYPRIMARY294() {
    require(msg.sender == _primary, "not the primary user");
    _;
  }


  function PRIMARY930() public view returns (address) {
    return _primary;
  }


  function TRANSFERPRIMARY55(address recipient) public ONLYOWNER7 {
    require(recipient != address(0), "new primary address is null");
    _primary = recipient;
    emit PRIMARYTRANSFERRED938(_primary);
  }
}


contract StatementRegisteryInterface is OwnableSecondary {



  function RECORDSTATEMENT412(string calldata buildingPermitId, uint[] calldata statementDataLayout, bytes calldata statementData) external returns(bytes32);




  function STATEMENTIDSBYBUILDINGPERMIT755(string calldata id) external view returns(bytes32[] memory);

  function STATEMENTEXISTS926(bytes32 statementId) public view returns(bool);

  function GETSTATEMENTSTRING626(bytes32 statementId, string memory key) public view returns(string memory);

  function GETSTATEMENTPCID716(bytes32 statementId) external view returns (string memory);

  function GETSTATEMENTACQUISITIONDATE999(bytes32 statementId) external view returns (string memory);

  function GETSTATEMENTRECIPIENT811(bytes32 statementId) external view returns (string memory);

  function GETSTATEMENTARCHITECT198(bytes32 statementId) external view returns (string memory);

  function GETSTATEMENTCITYHALL253(bytes32 statementId) external view returns (string memory);

  function GETSTATEMENTMAXIMUMHEIGHT317(bytes32 statementId) external view returns (string memory);

  function GETSTATEMENTDESTINATION15(bytes32 statementId) external view returns (string memory);

  function GETSTATEMENTSITEAREA921(bytes32 statementId) external view returns (string memory);

  function GETSTATEMENTBUILDINGAREA300(bytes32 statementId) external view returns (string memory);

  function GETSTATEMENTNEARIMAGE527(bytes32 statementId) external view returns(string memory);

  function GETSTATEMENTFARIMAGE348(bytes32 statementId) external view returns(string memory);

  function GETALLSTATEMENTS348() external view returns(bytes32[] memory);
}





contract OwnablePausable is Ownable {

  event PAUSED396();
  event UNPAUSED291();
  bool private _paused;

  constructor() internal {
    _paused = false;
    emit UNPAUSED291();
  }


  function PAUSED193() public view returns (bool) {
      return _paused;
  }


  modifier WHENNOTPAUSED828() {
      require(!_paused);
      _;
  }


  modifier WHENPAUSED861() {
      require(_paused);
      _;
  }


  function PAUSE542() public ONLYOWNER7 WHENNOTPAUSED828 {
      _paused = true;
      emit PAUSED396();
  }


  function UNPAUSE689() public ONLYOWNER7 WHENPAUSED861 {
      _paused = false;
      emit UNPAUSED291();
  }
}


contract Controller is OwnablePausable {
  StatementRegisteryInterface public registery;
  uint public price = 0;
  address payable private _wallet;
  address private _serverSide;

  event LOGEVENT957(string content);
  event NEWSTATEMENTEVENT354(string indexed buildingPermitId, bytes32 statementId);




  constructor(address registeryAddress, address payable walletAddr, address serverSideAddr) public {
    require(registeryAddress != address(0), "null registery address");
    require(walletAddr != address(0), "null wallet address");
    require(serverSideAddr != address(0), "null server side address");

    registery = StatementRegisteryInterface(registeryAddress);
    _wallet = walletAddr;
    _serverSide = serverSideAddr;
  }


  function SETPRICE323(uint priceInWei) external WHENNOTPAUSED828 {
    require(msg.sender == OWNER307() || msg.sender == _serverSide);

    price = priceInWei;
  }

  function SETWALLET585(address payable addr) external ONLYOWNER7 WHENNOTPAUSED828 {
    require(addr != address(0), "null wallet address");

    _wallet = addr;
  }

  function SETSERVERSIDE236(address payable addr) external ONLYOWNER7 WHENNOTPAUSED828 {
    require(addr != address(0), "null server side address");

    _serverSide = addr;
  }


  function RECORDSTATEMENT412(string calldata buildingPermitId, uint[] calldata statementDataLayout, bytes calldata statementData) external payable WHENNOTPAUSED828 returns(bytes32) {
      if(msg.sender != OWNER307() && msg.sender != _serverSide) {
        require(msg.value >= price, "received insufficient value");

        uint refund = msg.value - price;

        _wallet.transfer(price);

        if(refund > 0) {
          msg.sender.transfer(refund);
        }
      }

      bytes32 statementId = registery.RECORDSTATEMENT412(
        buildingPermitId,
        statementDataLayout,
        statementData
      );

      emit NEWSTATEMENTEVENT354(buildingPermitId, statementId);

      return statementId;
  }




  function WALLET260() external view returns (address) {
    return _wallet;
  }

  function SERVERSIDE606() external view returns (address) {
    return _serverSide;
  }

  function STATEMENTEXISTS926(bytes32 statementId) external view returns (bool) {
    return registery.STATEMENTEXISTS926(statementId);
  }

  function GETSTATEMENTIDSBYBUILDINGPERMIT117(string calldata buildingPermitId) external view returns(bytes32[] memory) {
    return registery.STATEMENTIDSBYBUILDINGPERMIT755(buildingPermitId);
  }

  function GETALLSTATEMENTS348() external view returns(bytes32[] memory) {
    return registery.GETALLSTATEMENTS348();
  }

  function GETSTATEMENTPCID716(bytes32 statementId) external view returns (string memory) {
    return registery.GETSTATEMENTPCID716(statementId);
  }

  function GETSTATEMENTACQUISITIONDATE999(bytes32 statementId) external view returns (string memory) {
    return registery.GETSTATEMENTACQUISITIONDATE999(statementId);
  }

  function GETSTATEMENTRECIPIENT811(bytes32 statementId) external view returns (string memory) {
    return registery.GETSTATEMENTRECIPIENT811(statementId);
  }

  function GETSTATEMENTARCHITECT198(bytes32 statementId) external view returns (string memory) {
    return registery.GETSTATEMENTARCHITECT198(statementId);
  }

  function GETSTATEMENTCITYHALL253(bytes32 statementId) external view returns (string memory) {
    return registery.GETSTATEMENTCITYHALL253(statementId);
  }

  function GETSTATEMENTMAXIMUMHEIGHT317(bytes32 statementId) external view returns (string memory) {
    return registery.GETSTATEMENTMAXIMUMHEIGHT317(statementId);
  }

  function GETSTATEMENTDESTINATION15(bytes32 statementId) external view returns (string memory) {
    return registery.GETSTATEMENTDESTINATION15(statementId);
  }

  function GETSTATEMENTSITEAREA921(bytes32 statementId) external view returns (string memory) {
    return registery.GETSTATEMENTSITEAREA921(statementId);
  }

  function GETSTATEMENTBUILDINGAREA300(bytes32 statementId) external view returns (string memory) {
    return registery.GETSTATEMENTBUILDINGAREA300(statementId);
  }

  function GETSTATEMENTNEARIMAGE527(bytes32 statementId) external view returns(string memory) {
    return registery.GETSTATEMENTNEARIMAGE527(statementId);
  }

  function GETSTATEMENTFARIMAGE348(bytes32 statementId) external view returns(string memory) {
    return registery.GETSTATEMENTFARIMAGE348(statementId);
  }
}
