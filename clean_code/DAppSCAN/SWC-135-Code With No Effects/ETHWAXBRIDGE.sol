

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./libraries/Endian.sol";

import "./interfaces/ERC20Interface.sol";

import "./Verify.sol";
import "./Owned.sol";






abstract contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes memory data
    ) public virtual;
}

contract Oracled is Owned {
    mapping(address => bool) public oracles;

    modifier onlyOracle() {
        require(
            oracles[msg.sender] == true,
            "Account is not a registered oracle"
        );

        _;
    }

    function regOracle(address _newOracle) public onlyOwner {
        require(!oracles[_newOracle], "Oracle is already registered");

        oracles[_newOracle] = true;
    }

    function unregOracle(address _remOracle) public onlyOwner {
        require(oracles[_remOracle] == true, "Oracle is not registered");

        delete oracles[_remOracle];
    }
}





contract ETHWAXBRIDGE is Oracled, Verify {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;



    IERC20 public rfox;

    uint8 public threshold;

    uint8 public thisChainId;

    uint256 public totalLocked;

    mapping(uint64 => mapping(address => bool)) signed;
    mapping(uint64 => bool) public claimed;

    event Bridge(
        address indexed from,
        string to,
        uint256 tokens,
        uint256 chainId
    );
    event Claimed(uint64 id, address to, uint256 tokens);

    struct BridgeData {
        uint64 id;
        uint32 ts;
        uint64 fromAddr;
        uint256 quantity;
        uint64 symbolRaw;
        uint8 chainId;
        address toAddress;
    }

    event Locked(address from, uint256 amount);
    event Released(address to, uint256 amount);




    constructor(IERC20 rfoxAddress) public {
        uint8 chainId;

        threshold = 3;
        rfox = rfoxAddress;

        assembly {
            chainId := chainid()
        }

        thisChainId = chainId;
    }









    function bridge(
        string memory to,
        uint256 tokens,
        uint256 chainid
    ) public returns (bool success) {
        lock(msg.sender, tokens);

        emit Bridge(msg.sender, to, tokens, chainid);
        emit Locked(msg.sender, tokens);

        return true;
    }





    function verifySigData(bytes memory sigData)
        private
        returns (BridgeData memory)
    {
        BridgeData memory td;

        uint64 oracleQuantity = 0;
        uint64 id;
        uint32 ts;
        uint64 fromAddr;
        uint64 symbolRaw;
        uint8 chainId;
        address toAddress;

        assembly {
            id := mload(add(add(sigData, 0x8), 0))
            ts := mload(add(add(sigData, 0x4), 8))
            fromAddr := mload(add(add(sigData, 0x8), 12))
            oracleQuantity := mload(add(add(sigData, 0x8), 20))
            symbolRaw := mload(add(add(sigData, 0x8), 28))
            chainId := mload(add(add(sigData, 0x1), 36))
            toAddress := mload(add(add(sigData, 0x14), 37))
        }

        uint256 reversedQuantity = Endian.reverse64(oracleQuantity);

        td.id = Endian.reverse64(id);
        td.ts = Endian.reverse32(ts);
        td.fromAddr = Endian.reverse64(fromAddr);
        td.quantity = uint256(reversedQuantity) * 1e10;
        td.symbolRaw = Endian.reverse64(symbolRaw);
        td.chainId = chainId;
        td.toAddress = toAddress;

        require(thisChainId == td.chainId, "Invalid Chain ID");
        require(
            block.timestamp < SafeMath.add(td.ts, (60 * 60 * 24 * 30)),
            "Bridge has expired"
        );

        require(!claimed[td.id], "Already Claimed");

        claimed[td.id] = true;

        return td;
    }

    function claim(bytes memory sigData, bytes[] calldata signatures)
        public
        returns (address toAddress)
    {
        BridgeData memory td = verifySigData(sigData);


        require(sigData.length == 69, "Signature data is the wrong size");
        require(
            signatures.length <= 10,
            "Maximum of 10 signatures can be provided"
        );

        bytes32 message = keccak256(sigData);

        uint8 numberSigs = 0;

        for (uint8 i = 0; i < signatures.length; i++) {
            address potential = Verify.recoverSigner(message, signatures[i]);


            if (oracles[potential] && !signed[td.id][potential]) {
                signed[td.id][potential] = true;
                numberSigs++;

                if (numberSigs >= 10) {
                    break;
                }
            }
        }

        require(
            numberSigs >= threshold,
            "Not enough valid signatures provided"
        );

        release(td.toAddress, td.quantity);

        emit Claimed(td.id, td.toAddress, td.quantity);

        return td.toAddress;
    }

    function updateThreshold(uint8 newThreshold)
        public
        onlyOwner
        returns (bool success)
    {
        if (newThreshold > 0) {
            require(newThreshold <= 10, "Threshold has maximum of 10");

            threshold = newThreshold;

            return true;
        }

        return false;
    }




    receive() external payable {
        revert();
    }




    function transferAnyERC20Token(IERC20 tokenAddress, uint256 tokens)
        public
        onlyOwner
    {

        require(tokenAddress != rfox, "Token locked");

        tokenAddress.safeTransfer(owner, tokens);
    }





    function lock(address from, uint256 amount) internal {
        totalLocked = totalLocked.add(amount);
        rfox.safeTransferFrom(from, address(this), amount);

        emit Locked(from, amount);
    }





    function release(address to, uint256 amount) internal {
        totalLocked = totalLocked.sub(amount);
        rfox.safeTransfer(to, amount);

        emit Released(to, amount);
    }
}
