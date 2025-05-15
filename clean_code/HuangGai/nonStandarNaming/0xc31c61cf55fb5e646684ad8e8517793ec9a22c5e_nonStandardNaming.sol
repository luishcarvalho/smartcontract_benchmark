pragma solidity >=0.5.7 <0.6.0;




library SafeMath {

    function MUL120(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }


    function DIV899(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;

        return c;
    }


    function SUB990(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }


    function ADD799(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }


    function MOD285(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}




contract tokenRecipient {
    function TOKENFALLBACK38(address _from, uint256 _value, bytes memory _extraData) public returns (bool);
}

contract xEuro {


    using SafeMath for uint256;





    string public name = "xEuro";



    string public symbol = "xEUR";



    uint8 public decimals = 0;




    uint256 public totalSupply = 0;



    mapping(address => uint256) public balanceOf;



    mapping(address => mapping(address => uint256)) public allowance;




    mapping(address => bool) public isAdmin;


    mapping(address => bool) public canMint;


    mapping(address => bool) public canTransferFromContract;


    mapping(address => bool) public canBurn;




    constructor() public {
        isAdmin[msg.sender] = true;
        canMint[msg.sender] = true;
        canTransferFromContract[msg.sender] = true;
        canBurn[msg.sender] = true;
    }





    event TRANSFER732(address indexed from, address indexed to, uint256 value);


    event DATASENTTOANOTHERCONTRACT500(address indexed _from, address indexed _toContract, bytes _extraData);





    function TRANSFER626(address _to, uint256 _value) public returns (bool){
        return TRANSFERFROM372(msg.sender, _to, _value);
    }


    function TRANSFERFROM372(address _from, address _to, uint256 _value) public returns (bool){


        require(_value >= 0);


        require(msg.sender == _from || _value <= allowance[_from][msg.sender] || (_from == address(this) && canTransferFromContract[msg.sender]));


        require(_value <= balanceOf[_from]);

        if (_to == address(this)) {

            require(_from == msg.sender);
        }

        balanceOf[_from] = balanceOf[_from].SUB990(_value);
        balanceOf[_to] = balanceOf[_to].ADD799(_value);


        if (_from != msg.sender && _from != address(this)) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender].SUB990(_value);
        }

        if (_to == address(this) && _value > 0) {

            require(_value >= minExchangeAmount);

            tokensInEventsCounter++;
            tokensInTransfer[tokensInEventsCounter].from = _from;
            tokensInTransfer[tokensInEventsCounter].value = _value;
            tokensInTransfer[tokensInEventsCounter].receivedOn = now;

            emit TOKENSIN207(
                _from,
                _value,
                tokensInEventsCounter
            );
        }

        emit TRANSFER732(_from, _to, _value);

        return true;
    }




    function TRANSFERANDCALL810(address _to, uint256 _value, bytes memory _extraData) public returns (bool){

        tokenRecipient receiver = tokenRecipient(_to);

        if (TRANSFERFROM372(msg.sender, _to, _value)) {

            if (receiver.TOKENFALLBACK38(msg.sender, _value, _extraData)) {

                emit DATASENTTOANOTHERCONTRACT500(msg.sender, _to, _extraData);

                return true;

            }

        }
        return false;
    }



    function TRANSFERALLANDCALL340(address _to, bytes memory _extraData) public returns (bool){
        return TRANSFERANDCALL810(_to, balanceOf[msg.sender], _extraData);
    }




    event ADMINADDED919(address indexed by, address indexed newAdmin);
    function ADDADMIN78(address _newAdmin) public returns (bool){
        require(isAdmin[msg.sender]);

        isAdmin[_newAdmin] = true;
        emit ADMINADDED919(msg.sender, _newAdmin);
        return true;
    }
    event ADMINREMOVED602(address indexed by, address indexed _oldAdmin);
    function REMOVEADMIN899(address _oldAdmin) public returns (bool){
        require(isAdmin[msg.sender]);


        require(msg.sender != _oldAdmin);
        isAdmin[_oldAdmin] = false;
        emit ADMINREMOVED602(msg.sender, _oldAdmin);
        return true;
    }

    uint256 minExchangeAmount = 12;
    event MINEXCHANGEAMOUNTCHANGED736 (address indexed by, uint256 from, uint256 to);
    function CHANGEMINEXCHANGEAMOUNT772(uint256 _minExchangeAmount) public returns (bool){
        require(isAdmin[msg.sender]);

        uint256 from = minExchangeAmount;
        minExchangeAmount = _minExchangeAmount;
        emit MINEXCHANGEAMOUNTCHANGED736(msg.sender, from, minExchangeAmount);
        return true;
    }


    event ADDRESSADDEDTOCANMINT339(address indexed by, address indexed newAddress);
    function ADDTOCANMINT826(address _newAddress) public returns (bool){
        require(isAdmin[msg.sender]);

        canMint[_newAddress] = true;
        emit ADDRESSADDEDTOCANMINT339(msg.sender, _newAddress);
        return true;
    }
    event ADDRESSREMOVEDFROMCANMINT615(address indexed by, address indexed removedAddress);
    function REMOVEFROMCANMINT471(address _addressToRemove) public returns (bool){
        require(isAdmin[msg.sender]);

        canMint[_addressToRemove] = false;
        emit ADDRESSREMOVEDFROMCANMINT615(msg.sender, _addressToRemove);
        return true;
    }


    event ADDRESSADDEDTOCANTRANSFERFROMCONTRACT607(address indexed by, address indexed newAddress);
    function ADDTOCANTRANSFERFROMCONTRACT635(address _newAddress) public returns (bool){
        require(isAdmin[msg.sender]);

        canTransferFromContract[_newAddress] = true;
        emit ADDRESSADDEDTOCANTRANSFERFROMCONTRACT607(msg.sender, _newAddress);
        return true;
    }
    event ADDRESSREMOVEDFROMCANTRANSFERFROMCONTRACT946(address indexed by, address indexed removedAddress);
    function REMOVEFROMCANTRANSFERFROMCONTRACT713(address _addressToRemove) public returns (bool){
        require(isAdmin[msg.sender]);

        canTransferFromContract[_addressToRemove] = false;
        emit ADDRESSREMOVEDFROMCANTRANSFERFROMCONTRACT946(msg.sender, _addressToRemove);
        return true;
    }


    event ADDRESSADDEDTOCANBURN693(address indexed by, address indexed newAddress);
    function ADDTOCANBURN261(address _newAddress) public returns (bool){
        require(isAdmin[msg.sender]);

        canBurn[_newAddress] = true;
        emit ADDRESSADDEDTOCANBURN693(msg.sender, _newAddress);
        return true;
    }
    event ADDRESSREMOVEDFROMCANBURN83(address indexed by, address indexed removedAddress);
    function REMOVEFROMCANBURN127(address _addressToRemove) public returns (bool){
        require(isAdmin[msg.sender]);

        canBurn[_addressToRemove] = false;
        emit ADDRESSREMOVEDFROMCANBURN83(msg.sender, _addressToRemove);
        return true;
    }




    uint public mintTokensEventsCounter = 0;
    struct MintTokensEvent {
        address mintedBy;
        uint256 fiatInPaymentId;
        uint value;
        uint on;
        uint currentTotalSupply;
    }

    mapping(uint256 => bool) public fiatInPaymentIds;



    mapping(uint256 => MintTokensEvent) public fiatInPaymentsToMintTokensEvent;


    mapping(uint256 => MintTokensEvent) public mintTokensEvent;
    event TOKENSMINTED883(
        address indexed by,
        uint256 indexed fiatInPaymentId,
        uint value,
        uint currentTotalSupply,
        uint indexed mintTokensEventsCounter
    );


    function MINTTOKENS200(uint256 value, uint256 fiatInPaymentId) public returns (bool){

        require(canMint[msg.sender]);


        require(!fiatInPaymentIds[fiatInPaymentId]);

        require(value >= 0);

        totalSupply = totalSupply.ADD799(value);

        balanceOf[address(this)] = balanceOf[address(this)].ADD799(value);

        mintTokensEventsCounter++;
        mintTokensEvent[mintTokensEventsCounter].mintedBy = msg.sender;
        mintTokensEvent[mintTokensEventsCounter].fiatInPaymentId = fiatInPaymentId;
        mintTokensEvent[mintTokensEventsCounter].value = value;
        mintTokensEvent[mintTokensEventsCounter].on = block.timestamp;
        mintTokensEvent[mintTokensEventsCounter].currentTotalSupply = totalSupply;

        fiatInPaymentsToMintTokensEvent[fiatInPaymentId] = mintTokensEvent[mintTokensEventsCounter];

        emit TOKENSMINTED883(msg.sender, fiatInPaymentId, value, totalSupply, mintTokensEventsCounter);

        fiatInPaymentIds[fiatInPaymentId] = true;

        return true;

    }


    function MINTANDTRANSFER453(
        uint256 _value,
        uint256 fiatInPaymentId,
        address _to
    ) public returns (bool){

        if (MINTTOKENS200(_value, fiatInPaymentId) && TRANSFERFROM372(address(this), _to, _value)) {
            return true;
        }
        return false;
    }


    uint public tokensInEventsCounter = 0;
    struct TokensInTransfer {
        address from;
        uint value;
        uint receivedOn;
    }
    mapping(uint256 => TokensInTransfer) public tokensInTransfer;
    event TOKENSIN207(
        address indexed from,
        uint256 value,
        uint256 indexed tokensInEventsCounter
    );

    uint public burnTokensEventsCounter = 0;
    struct burnTokensEvent {
        address by;
        uint256 value;
        uint256 tokensInEventId;
        uint256 fiatOutPaymentId;
        uint256 burnedOn;
        uint256 currentTotalSupply;
    }
    mapping(uint => burnTokensEvent) public burnTokensEvents;


    mapping(uint256 => bool) public fiatOutPaymentIdsUsed;

    event TOKENSBURNED510(
        address indexed by,
        uint256 value,
        uint256 indexed tokensInEventId,
        uint256 indexed fiatOutPaymentId,
        uint burnedOn,
        uint currentTotalSupply
    );


    function BURNTOKENS469(
        uint256 value,
        uint256 tokensInEventId,
        uint256 fiatOutPaymentId
    ) public returns (bool){

        require(canBurn[msg.sender]);

        require(value >= 0);
        require(balanceOf[address(this)] >= value);


        require(!fiatOutPaymentIdsUsed[fiatOutPaymentId]);

        balanceOf[address(this)] = balanceOf[address(this)].SUB990(value);
        totalSupply = totalSupply.SUB990(value);

        burnTokensEventsCounter++;
        burnTokensEvents[burnTokensEventsCounter].by = msg.sender;
        burnTokensEvents[burnTokensEventsCounter].value = value;
        burnTokensEvents[burnTokensEventsCounter].tokensInEventId = tokensInEventId;
        burnTokensEvents[burnTokensEventsCounter].fiatOutPaymentId = fiatOutPaymentId;
        burnTokensEvents[burnTokensEventsCounter].burnedOn = block.timestamp;
        burnTokensEvents[burnTokensEventsCounter].currentTotalSupply = totalSupply;

        emit TOKENSBURNED510(msg.sender, value, tokensInEventId, fiatOutPaymentId, block.timestamp, totalSupply);

        fiatOutPaymentIdsUsed[fiatOutPaymentId];

        return true;
    }

}
