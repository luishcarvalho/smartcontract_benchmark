





pragma solidity >= 0.5.0 < 0.7.0;





library SafeMath {



    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c ;


        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c ;

        require(c >= a);

        return c;
    }




    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c ;

        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c ;



        return c;
    }
}




pragma solidity >= 0.5.0 < 0.7.0;


contract MWGImplementation {




    using SafeMath for uint256;






    bool private initialized;


    mapping(address => uint256) internal balances;
    uint256 internal totalSupply_;
    string public constant name = "Motiwala Gold";
    string public constant symbol = "MWG";
    uint8 public constant decimals = 18;


    mapping(address => mapping(address => uint256)) internal allowed;


    address public owner;
    address public proposedOwner;


    bool public paused;


    address public assetProtectionRole;
    mapping(address => bool) internal frozen;


    address public supplyController;


    address public betaDelegateWhitelister;
    mapping(address => bool) internal betaDelegateWhitelist;
    mapping(address => uint256) internal nextSeqs;

    string constant internal EIP191_HEADER = "\x19\x01";

    bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(
        "EIP712Domain(string name,address verifyingContract)"
    );
    bytes32 constant internal EIP712_DELEGATED_TRANSFER_SCHEMA_HASH = keccak256(
        "BetaDelegatedTransfer(address to,uint256 value,uint256 serviceFee,uint256 seq,uint256 deadline)"
    );


    bytes32 public EIP712_DOMAIN_HASH;




    uint8 public constant feeDecimals = 6;



    uint256 public constant feeParts = 1000000;
    uint256 public feeRate;
    address public feeController;
    address public feeRecipient;

    string public constant version = "1.0.0";






    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );


    event OwnershipTransferProposed(
        address indexed currentOwner,
        address indexed proposedOwner
    );
    event OwnershipTransferDisregarded(
        address indexed oldProposedOwner
    );
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );


    event Pause();
    event Unpause();


    event AddressFrozen(address indexed addr);
    event AddressUnfrozen(address indexed addr);
    event FrozenAddressWiped(address indexed addr);
    event AssetProtectionRoleSet (
        address indexed oldAssetProtectionRole,
        address indexed newAssetProtectionRole
    );


    event SupplyIncreased(address indexed to, uint256 value);
    event SupplyDecreased(address indexed from, uint256 value);
    event SupplyControllerSet(
        address indexed oldSupplyController,
        address indexed newSupplyController
    );


    event BetaDelegatedTransfer(
        address indexed from, address indexed to, uint256 value, uint256 seq, uint256 serviceFee
    );
    event BetaDelegateWhitelisterSet(
        address indexed oldWhitelister,
        address indexed newWhitelister
    );
    event BetaDelegateWhitelisted(address indexed newDelegate);
    event BetaDelegateUnwhitelisted(address indexed oldDelegate);


    event FeeCollected(address indexed from, address indexed to, uint256 value);
    event FeeRateSet(
        uint256 indexed oldFeeRate,
        uint256 indexed newFeeRate
    );
    event FeeControllerSet(
        address indexed oldFeeController,
        address indexed newFeeController
    );
    event FeeRecipientSet(
        address indexed oldFeeRecipient,
        address indexed newFeeRecipient
    );













    function initialize() public {
        require(!initialized, "already initialized");
        owner = msg.sender;
        proposedOwner = address(0);
        assetProtectionRole = address(0);
        totalSupply_ = 0;
        supplyController = msg.sender;
        feeRate = 0;
        feeController = msg.sender;
        feeRecipient = msg.sender;
        initializeDomainSeparator();
        initialized = true;
    }















    function initializeDomainSeparator() public {

        EIP712_DOMAIN_HASH = keccak256(abi.encodePacked(
                EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH, keccak256(bytes(name)), bytes32(uint256(address(this)))                ));








    }






    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }








    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0), "cannot transfer to address zero");
        require(!frozen[_to] && !frozen[msg.sender], "address frozen");
        require(_value <= balances[msg.sender], "insufficient funds");

        _transfer(msg.sender, _to, _value);
        return true;
    }






    function balanceOf(address _addr) public view returns (uint256) {
        return balances[_addr];
    }









    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    whenNotPaused
    returns (bool)
    {
        require(_to != address(0), "cannot transfer to address zero");
        require(!frozen[_to] && !frozen[_from] && !frozen[msg.sender], "address frozen");
        require(_value <= balances[_from], "insufficient funds");
        require(_value <= allowed[_from][msg.sender], "insufficient allowance");

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);

        return true;
    }










    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozen[_spender] && !frozen[msg.sender], "address frozen");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }







    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (uint256) {
        uint256 _fee ;

        uint256 _principle ;

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_principle);
        emit Transfer(_from, _to, _principle);
        emit Transfer(_from, feeRecipient, _fee);
        if (_fee > 0) {
            balances[feeRecipient] = balances[feeRecipient].add(_fee);
            emit FeeCollected(_from, feeRecipient, _fee);
        }

        return _principle;
    }






    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }





    function proposeOwner(address _proposedOwner) public onlyOwner {
        require(_proposedOwner != address(0), "cannot transfer ownership to address zero");
        require(msg.sender != _proposedOwner, "caller already is owner");
        proposedOwner = _proposedOwner;
        emit OwnershipTransferProposed(owner, proposedOwner);
    }




    function disregardProposeOwner() public {
        require(msg.sender == proposedOwner || msg.sender == owner, "only proposedOwner or owner");
        require(proposedOwner != address(0), "can only disregard a proposed owner that was previously set");
        address _oldProposedOwner ;

        proposedOwner = address(0);
        emit OwnershipTransferDisregarded(_oldProposedOwner);
    }




    function claimOwnership() public {
        require(msg.sender == proposedOwner, "onlyProposedOwner");
        address _oldOwner ;

        owner = proposedOwner;
        proposedOwner = address(0);
        emit OwnershipTransferred(_oldOwner, owner);
    }






    function reclaimMTW() external onlyOwner {
        uint256 _balance ;

        balances[address(this)] = 0;
        balances[owner] = balances[owner].add(_balance);
        emit Transfer(address(this), owner, _balance);
    }






    modifier whenNotPaused() {
        require(!paused, "whenNotPaused");
        _;
    }




    function pause() public onlyOwner {
        require(!paused, "already paused");
        paused = true;
        emit Pause();
    }




    function unpause() public onlyOwner {
        require(paused, "already unpaused");
        paused = false;
        emit Unpause();
    }







    function setAssetProtectionRole(address _newAssetProtectionRole) public {
        require(msg.sender == assetProtectionRole || msg.sender == owner, "only assetProtectionRole or Owner");
        emit AssetProtectionRoleSet(assetProtectionRole, _newAssetProtectionRole);
        assetProtectionRole = _newAssetProtectionRole;
    }

    modifier onlyAssetProtectionRole() {
        require(msg.sender == assetProtectionRole, "onlyAssetProtectionRole");
        _;
    }





    function freeze(address _addr) public onlyAssetProtectionRole {
        require(!frozen[_addr], "address already frozen");
        frozen[_addr] = true;
        emit AddressFrozen(_addr);
    }





    function unfreeze(address _addr) public onlyAssetProtectionRole {
        require(frozen[_addr], "address already unfrozen");
        frozen[_addr] = false;
        emit AddressUnfrozen(_addr);
    }






    function wipeFrozenAddress(address _addr) public onlyAssetProtectionRole {
        require(frozen[_addr], "address is not frozen");
        uint256 _balance ;

        balances[_addr] = 0;
        totalSupply_ = totalSupply_.sub(_balance);
        emit FrozenAddressWiped(_addr);
        emit SupplyDecreased(_addr, _balance);
        emit Transfer(_addr, address(0), _balance);
    }






    function isFrozen(address _addr) public view returns (bool) {
        return frozen[_addr];
    }







    function setSupplyController(address _newSupplyController) public {
        require(msg.sender == supplyController || msg.sender == owner, "only SupplyController or Owner");
        require(_newSupplyController != address(0), "cannot set supply controller to address zero");
        emit SupplyControllerSet(supplyController, _newSupplyController);
        supplyController = _newSupplyController;
    }

    modifier onlySupplyController() {
        require(msg.sender == supplyController, "onlySupplyController");
        _;
    }






    function increaseSupply(uint256 _value) public onlySupplyController returns (bool success) {
        totalSupply_ = totalSupply_.add(_value);
        balances[supplyController] = balances[supplyController].add(_value);
        emit SupplyIncreased(supplyController, _value);
        emit Transfer(address(0), supplyController, _value);
        return true;
    }






    function decreaseSupply(uint256 _value) public onlySupplyController returns (bool success) {
        require(_value <= balances[supplyController], "not enough supply");
        balances[supplyController] = balances[supplyController].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit SupplyDecreased(supplyController, _value);
        emit Transfer(supplyController, address(0), _value);
        return true;
    }











    function nextSeqOf(address target) public view returns (uint256) {
        return nextSeqs[target];
    }












    function betaDelegatedTransfer(
        bytes memory sig, address to, uint256 value, uint256 serviceFee, uint256 seq, uint256 deadline
    ) public returns (bool) {
        require(sig.length == 65, "signature should have length 65");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        require(_betaDelegatedTransfer(r, s, v, to, value, serviceFee, seq, deadline), "failed transfer");
        return true;
    }

















    function _betaDelegatedTransfer(
        bytes32 r, bytes32 s, uint8 v, address to, uint256 value, uint256 serviceFee, uint256 seq, uint256 deadline
    ) internal whenNotPaused returns (bool) {
        require(betaDelegateWhitelist[msg.sender], "Beta feature only accepts whitelisted delegates");
        require(value > 0 || serviceFee > 0, "cannot transfer zero tokens with zero service fee");
        require(block.number <= deadline, "transaction expired");

        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "signature incorrect");
        require(v == 27 || v == 28, "signature incorrect");


        bytes32 hash ;

        address _from ;


        require(_from != address(0), "error determining from address from signature");
        require(to != address(0), "cannot use address zero");
        require(!frozen[to] && !frozen[_from] && !frozen[msg.sender], "address frozen");
        require(value.add(serviceFee) <= balances[_from], "insufficient funds or bad signature");
        require(nextSeqs[_from] == seq, "incorrect seq");

        nextSeqs[_from] = nextSeqs[_from].add(1);

        uint256 _principle ;


        if (serviceFee != 0) {
            balances[_from] = balances[_from].sub(serviceFee);
            balances[msg.sender] = balances[msg.sender].add(serviceFee);
            emit Transfer(_from, msg.sender, serviceFee);
        }

        emit BetaDelegatedTransfer(_from, to, _principle, seq, serviceFee);
        return true;
    }















    function betaDelegatedTransferBatch(
        bytes32[] memory r,
        bytes32[] memory s,
        uint8[] memory v,
        address[] memory to,
        uint256[] memory value,
        uint256[] memory serviceFee,
        uint256[] memory seq,
        uint256[] memory deadline
    ) public returns (bool) {
        require(r.length == s.length && r.length == v.length && r.length == to.length && r.length == value.length, "length mismatch");
        require(r.length == serviceFee.length && r.length == seq.length && r.length == deadline.length, "length mismatch");

        for (uint i ; i < r.length; i++) {

            require(
                _betaDelegatedTransfer(r[i], s[i], v[i], to[i], value[i], serviceFee[i], seq[i], deadline[i]),
                "failed transfer"
            );
        }
        return true;
    }






    function isWhitelistedBetaDelegate(address _addr) public view returns (bool) {
        return betaDelegateWhitelist[_addr];
    }





    function setBetaDelegateWhitelister(address _newWhitelister) public {
        require(msg.sender == betaDelegateWhitelister || msg.sender == owner, "only Whitelister or Owner");
        betaDelegateWhitelister = _newWhitelister;
        emit BetaDelegateWhitelisterSet(betaDelegateWhitelister, _newWhitelister);
    }

    modifier onlyBetaDelegateWhitelister() {
        require(msg.sender == betaDelegateWhitelister, "onlyBetaDelegateWhitelister");
        _;
    }





    function whitelistBetaDelegate(address _addr) public onlyBetaDelegateWhitelister {
        require(!betaDelegateWhitelist[_addr], "delegate already whitelisted");
        betaDelegateWhitelist[_addr] = true;
        emit BetaDelegateWhitelisted(_addr);
    }





    function unwhitelistBetaDelegate(address _addr) public onlyBetaDelegateWhitelister {
        require(betaDelegateWhitelist[_addr], "delegate not whitelisted");
        betaDelegateWhitelist[_addr] = false;
        emit BetaDelegateUnwhitelisted(_addr);
    }







    function setFeeController(address _newFeeController) public {
        require(msg.sender == feeController || msg.sender == owner, "only FeeController or Owner");
        require(_newFeeController != address(0), "cannot set fee controller to address zero");
        address _oldFeeController ;

        feeController = _newFeeController;
        emit FeeControllerSet(_oldFeeController, feeController);
    }

    modifier onlyFeeController() {
        require(msg.sender == feeController, "only FeeController");
        _;
    }





    function setFeeRecipient(address _newFeeRecipient) public onlyFeeController {
        require(_newFeeRecipient != address(0), "cannot set fee recipient to address zero");
        address _oldFeeRecipient ;

        feeRecipient = _newFeeRecipient;
        emit FeeRecipientSet(_oldFeeRecipient, feeRecipient);
    }





    function setFeeRate(uint256 _newFeeRate) public onlyFeeController {
        require(_newFeeRate <= feeParts, "cannot set fee rate above 100%");
        uint256 _oldFeeRate ;

        feeRate = _newFeeRate;
        emit FeeRateSet(_oldFeeRate, feeRate);
    }






    function getFeeFor(uint256 _value) public view returns (uint256) {
        if (feeRate == 0) {
            return 0;
        }

        return _value.mul(feeRate).div(feeParts);
    }
}
