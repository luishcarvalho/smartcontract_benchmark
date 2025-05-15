pragma solidity ^0.7.4;


import "./MasterToken.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";




contract Bridge {
    bool internal initialized_;
    bool internal preparedForMigration_;

    mapping(address => bool) public isPeer;
    uint public peersCount;











    mapping(bytes32 => address) public _sidechainTokens;
    mapping(address => bytes32) public _sidechainTokensByAddress;
    address[] public _sidechainTokenAddressArray;

    event Withdrawal(bytes32 txHash);
    event Deposit(bytes32 destination, uint amount, address token, bytes32 sidechainAsset);
    event ChangePeers(address peerId, bool removal);
    event PreparedForMigration();
    event Migrated(address to);





    address public _addressVAL;
    address public _addressXOR;










    constructor(
        address[] memory initialPeers,
        address addressVAL,
        address addressXOR,
        bytes32 networkId)  {
        for (uint8 i = 0; i < initialPeers.length; i++) {
            addPeer(initialPeers[i]);
        }
        _addressXOR = addressXOR;
        _addressVAL = addressVAL;
        _networkId = networkId;
        initialized_ = true;
        preparedForMigration_ = false;

        acceptedEthTokens[_addressXOR] = true;
        acceptedEthTokens[_addressVAL] = true;
    }

    modifier shouldBeInitialized {
        require(initialized_ == true, "Contract should be initialized to use this function");
        _;
    }

    modifier shouldNotBePreparedForMigration {
        require(preparedForMigration_ == false, "Contract should not be prepared for migration to use this function");
        _;
    }

    modifier shouldBePreparedForMigration {
        require(preparedForMigration_ == true, "Contract should be prepared for migration to use this function");
        _;
    }

    fallback() external {
        revert();
    }

    receive() external payable {
        revert();
    }




    function receivePayment() external payable {}














    function addEthNativeToken(
        address newToken,
        string memory ticker,
        string memory name,
        uint8 decimals,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public shouldBeInitialized {
        require(used[txHash] == false);
        require(acceptedEthTokens[newToken] == false);
        require(checkSignatures(keccak256(abi.encodePacked(newToken, ticker, name, decimals, txHash, _networkId)),
            v,
            r,
            s), "Peer signatures are invalid"
        );
        acceptedEthTokens[newToken] = true;
        used[txHash] = true;
    }










    function prepareForMigration(
        address thisContractAddress,
        bytes32 salt,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public
    shouldBeInitialized shouldNotBePreparedForMigration {
        require(preparedForMigration_ == false);
        require(address(this) == thisContractAddress);
        require(checkSignatures(keccak256(abi.encodePacked(thisContractAddress, salt, _networkId)),
            v,
            r,
            s), "Peer signatures are invalid"
        );
        preparedForMigration_ = true;
        emit PreparedForMigration();
    }












    function shutDownAndMigrate(
        address thisContractAddress,
        bytes32 salt,
        address payable newContractAddress,
        address[] calldata erc20nativeTokens,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public
    shouldBeInitialized shouldBePreparedForMigration {
        require(address(this) == thisContractAddress);
        require(checkSignatures(keccak256(abi.encodePacked(thisContractAddress, newContractAddress, salt, erc20nativeTokens, _networkId)),
            v,
            r,
            s), "Peer signatures are invalid"
        );
        for (uint i = 0; i < _sidechainTokenAddressArray.length; i++) {
            Ownable token = Ownable(_sidechainTokenAddressArray[i]);
            token.transferOwnership(newContractAddress);
        }
        for (uint i = 0; i < erc20nativeTokens.length; i++) {
            IERC20 token = IERC20(erc20nativeTokens[i]);
            token.transfer(newContractAddress, token.balanceOf(address(this)));
        }
        Bridge(newContractAddress).receivePayment{value: address(this).balance}();
        initialized_ = false;
        emit Migrated(newContractAddress);
    }













    function addNewSidechainToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        bytes32 sidechainAssetId,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s)
    public shouldBeInitialized {
        require(used[txHash] == false);
        require(checkSignatures(keccak256(abi.encodePacked(
                name,
                symbol,
                decimals,
                sidechainAssetId,
                txHash,
                _networkId
            )),
            v,
            r,
            s), "Peer signatures are invalid"
        );

        MasterToken tokenInstance = new MasterToken(name, symbol, decimals, address(this), 0, sidechainAssetId);
        address tokenAddress = address(tokenInstance);
        _sidechainTokens[sidechainAssetId] = tokenAddress;
        _sidechainTokensByAddress[tokenAddress] = sidechainAssetId;
        _sidechainTokenAddressArray.push(tokenAddress);
        used[txHash] = true;
    }






    function sendEthToSidechain(
        bytes32 to
    )
    public
    payable
    shouldBeInitialized shouldNotBePreparedForMigration {
        require(msg.value > 0, "ETH VALUE SHOULD BE MORE THAN 0");
        bytes32 empty;
        emit Deposit(to, msg.value, address(0x0), empty);
    }








    function sendERC20ToSidechain(
        bytes32 to,
        uint amount,
        address tokenAddress)
    external
    shouldBeInitialized shouldNotBePreparedForMigration {
        IERC20 token = IERC20(tokenAddress);

        require(token.allowance(msg.sender, address(this)) >= amount, "NOT ENOUGH DELEGATED TOKENS ON SENDER BALANCE");

        bytes32 sidechainAssetId = _sidechainTokensByAddress[tokenAddress];
        if (sidechainAssetId != "" || _addressVAL == tokenAddress || _addressXOR == tokenAddress) {
            ERC20Burnable mtoken = ERC20Burnable(tokenAddress);
            mtoken.burnFrom(msg.sender, amount);
        } else {
            require(acceptedEthTokens[tokenAddress], "The Token is not accepted for transfer to sidechain");
            token.transferFrom(msg.sender, address(this), amount);
        }
        emit Deposit(to, amount, tokenAddress, sidechainAssetId);
    }










    function addPeerByPeer(
        address newPeerAddress,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public
    shouldBeInitialized
    returns (bool)
    {
        require(used[txHash] == false);
        require(checkSignatures(keccak256(abi.encodePacked(newPeerAddress, txHash, _networkId)),
            v,
            r,
            s), "Peer signatures are invalid"
        );

        addPeer(newPeerAddress);
        used[txHash] = true;
        emit ChangePeers(newPeerAddress, false);
        return true;
    }










    function removePeerByPeer(
        address peerAddress,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public
    shouldBeInitialized
    returns (bool)
    {
        require(used[txHash] == false);
        require(checkSignatures(
                keccak256(abi.encodePacked(peerAddress, txHash, _networkId)),
                v,
                r,
                s), "Peer signatures are invalid"
        );

        removePeer(peerAddress);
        used[txHash] = true;
        emit ChangePeers(peerAddress, true);
        return true;
    }












    function receiveByEthereumAssetAddress(
        address tokenAddress,
        uint256 amount,
        address payable to,
        address from,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public shouldBeInitialized
    {
        require(used[txHash] == false);
        require(checkSignatures(
                keccak256(abi.encodePacked(tokenAddress, amount, to, from, txHash, _networkId)),
                v,
                r,
                s), "Peer signatures are invalid"
        );

        if (tokenAddress == address(0)) {
            used[txHash] = true;

            to.transfer(amount);
        } else {
            IERC20 coin = IERC20(tokenAddress);
            used[txHash] = true;

            coin.transfer(to, amount);
        }
        emit Withdrawal(txHash);
    }












    function receiveBySidechainAssetId(
        bytes32 sidechainAssetId,
        uint256 amount,
        address to,
        address from,
        bytes32 txHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    public shouldBeInitialized
    {
        require(_sidechainTokens[sidechainAssetId] != address(0x0), "Sidechain asset is not registered");
        require(used[txHash] == false);
        require(checkSignatures(
                keccak256(abi.encodePacked(sidechainAssetId, amount, to, from, txHash, _networkId)),
                v,
                r,
                s), "Peer signatures are invalid"
        );

        MasterToken tokenInstance = MasterToken(_sidechainTokens[sidechainAssetId]);
        tokenInstance.mintTokens(to, amount);
        used[txHash] = true;
        emit Withdrawal(txHash);
    }









    function checkSignatures(bytes32 hash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    )
    private
    returns (bool) {
        require(peersCount >= 1);
        require(v.length == r.length);
        require(r.length == s.length);
        uint needSigs = peersCount - (peersCount - 1) / 3;
        require(s.length >= needSigs);

        uint count = 0;
        address[] memory recoveredAddresses = new address[](s.length);
        for (uint i = 0; i < s.length; ++i) {
            address recoveredAddress = recoverAddress(
                hash,
                v[i],
                r[i],
                s[i]
            );


            if (isPeer[recoveredAddress] != true || _uniqueAddresses[recoveredAddress] == true) {
                continue;
            }
            recoveredAddresses[count] = recoveredAddress;
            count = count + 1;
            _uniqueAddresses[recoveredAddress] = true;
        }


        for (uint i = 0; i < count; ++i) {
            _uniqueAddresses[recoveredAddresses[i]] = false;
        }

        return count >= needSigs;
    }









    function recoverAddress(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s)
    private
    pure
    returns (address) {
        bytes32 simple_hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address res = ecrecover(simple_hash, v, r, s);
        return res;
    }






    function addPeer(address newAddress)
    internal
    returns (uint) {
        require(isPeer[newAddress] == false);
        isPeer[newAddress] = true;
        ++peersCount;
        return peersCount;
    }

    function removePeer(address peerAddress)
    internal {
        require(isPeer[peerAddress] == true);
        isPeer[peerAddress] = false;
        --peersCount;
    }
}
