

pragma solidity ^0.5.8;

contract ERC20Interface {

    function NAME619() public view returns (string memory);

    function SYMBOL529() public view returns (string memory);

    function DECIMALS264() public view returns (uint8);

    function TOTALSUPPLY200() public view returns (uint);

    function BALANCEOF986(address tokenOwner) public view returns (uint balance);

    function ALLOWANCE990(address tokenOwner, address spender) public view returns (uint remaining);

    function TRANSFER909(address to, uint tokens) public returns (bool success);

    function APPROVE745(address spender, uint tokens) public returns (bool success);

    function TRANSFERFROM849(address from, address to, uint tokens) public returns (bool success);

    function BURN943(uint256 amount) public;


    event TRANSFER421(address indexed from, address indexed to, uint tokens);

    event APPROVAL99(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract MerkleDrop {

    bytes32 public root;
    ERC20Interface public droppedToken;
    uint public decayStartTime;
    uint public decayDurationInSeconds;

    uint public initialBalance;
    uint public remainingValue;
    uint public spentTokens;

    mapping (address => bool) public withdrawn;

    event WITHDRAW776(address recipient, uint value, uint originalValue);
    event BURN575(uint value);

    constructor(ERC20Interface _droppedToken, uint _initialBalance, bytes32 _root, uint _decayStartTime, uint _decayDurationInSeconds) public {

        droppedToken = _droppedToken;
        initialBalance = _initialBalance;
        remainingValue = _initialBalance;
        root = _root;
        decayStartTime = _decayStartTime;
        decayDurationInSeconds = _decayDurationInSeconds;
    }

    function WITHDRAW337(uint value, bytes32[] memory proof) public {
        require(VERIFYENTITLED968(msg.sender, value, proof), "The proof could not be verified.");
        require(! withdrawn[msg.sender], "You have already withdrawn your entitled token.");

        BURNUNUSABLETOKENS848();

        uint valueToSend = DECAYEDENTITLEMENTATTIME410(value, now, false);
        assert(valueToSend <= value);
        require(droppedToken.BALANCEOF986(address(this)) >= valueToSend, "The MerkleDrop does not have tokens to drop yet / anymore.");
        require(valueToSend != 0, "The decayed entitled value is now zero.");

        withdrawn[msg.sender] = true;
        remainingValue -= value;
        spentTokens += valueToSend;

        require(droppedToken.TRANSFER909(msg.sender, valueToSend));
        emit WITHDRAW776(msg.sender, valueToSend, value);
    }

    function VERIFYENTITLED968(address recipient, uint value, bytes32[] memory proof) public view returns (bool) {


        bytes32 leaf = keccak256(abi.encodePacked(recipient, value));
        return VERIFYPROOF104(leaf, proof);
    }

    function DECAYEDENTITLEMENTATTIME410(uint value, uint time, bool roundUp) public view returns (uint) {
        if (time <= decayStartTime) {
            return value;
        } else if (time >= decayStartTime + decayDurationInSeconds) {
            return 0;
        } else {
            uint timeDecayed = time - decayStartTime;
            uint valueDecay = DECAY452(value, timeDecayed, decayDurationInSeconds, !roundUp);
            assert(valueDecay <= value);
            return value - valueDecay;
        }
    }

    function BURNUNUSABLETOKENS848() public {
        if (now <= decayStartTime) {
            return;
        }


        uint targetBalance = DECAYEDENTITLEMENTATTIME410(remainingValue, now, true);


        uint currentBalance = initialBalance - spentTokens;
        assert(targetBalance <= currentBalance);
        uint toBurn = currentBalance - targetBalance;

        spentTokens += toBurn;
        BURN943(toBurn);
    }

    function DELETECONTRACT939() public {
        require(now >= decayStartTime + decayDurationInSeconds, "The storage cannot be deleted before the end of the merkle drop.");
        BURNUNUSABLETOKENS848();

        selfdestruct(address(0));
    }

    function VERIFYPROOF104(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        bytes32 currentHash = leaf;

        for (uint i = 0; i < proof.length; i += 1) {
            currentHash = PARENTHASH659(currentHash, proof[i]);
        }

        return currentHash == root;
    }

    function PARENTHASH659(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        if (a < b) {
            return keccak256(abi.encode(a, b));
        } else {
            return keccak256(abi.encode(b, a));
        }
    }

    function BURN943(uint value) internal {
        if (value == 0) {
            return;
        }
        emit BURN575(value);
        droppedToken.BURN943(value);
    }

    function DECAY452(uint value, uint timeToDecay, uint totalDecayTime, bool roundUp) internal pure returns (uint) {
        uint decay;

        if (roundUp) {
            decay = (value*timeToDecay+totalDecayTime-1)/totalDecayTime;
        } else {
            decay = value*timeToDecay/totalDecayTime;
        }
        return decay >= value ? value : decay;
    }
}
