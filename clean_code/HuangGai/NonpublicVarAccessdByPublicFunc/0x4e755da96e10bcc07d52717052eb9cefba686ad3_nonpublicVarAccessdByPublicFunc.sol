



pragma solidity ^0.5.5;

library SigUtils {





    function ecrecover2 (
        bytes32 _hash,
        bytes memory _signature
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := and(mload(add(_signature, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(
            _hash,
            v,
            r,
            s
        );
    }
}






contract Marmo {
    event Relayed(bytes32 indexed _id, address _implementation, bytes _data);
    event Canceled(bytes32 indexed _id);



    address private constant INVALID_ADDRESS = address(0x9431Bab00000000000000000000000039bD955c9);


    bytes32 private constant SIGNER_SLOT = keccak256("marmo.wallet.signer");


    mapping(bytes32 => bytes32) private intentReceipt;

    function() external payable {}



    function init(address _signer) external payable {
        address signer;
        bytes32 signerSlot = SIGNER_SLOT;
        assembly { signer := sload(signerSlot) }
        require(signer == address(0), "Signer already defined");
        assembly { sstore(signerSlot, _signer) }
    }



    function signer() public view returns (address _signer) {
        bytes32 signerSlot = SIGNER_SLOT;
        assembly { _signer := sload(signerSlot) }
    }



    function relayedBy(bytes32 _id) external view returns (address _relayer) {
        (,,_relayer) = _decodeReceipt(intentReceipt[_id]);
    }



    function relayedAt(bytes32 _id) external view returns (uint256 _block) {
        (,_block,) = _decodeReceipt(intentReceipt[_id]);
    }




    function isCanceled(bytes32 _id) external view returns (bool _canceled) {
        (_canceled,,) = _decodeReceipt(intentReceipt[_id]);
    }









    function relay(
        address _implementation,
        bytes calldata _data,
        bytes calldata _signature
    ) external payable returns (
        bytes memory result
    ) {



        bytes32 id = keccak256(
            abi.encodePacked(
                address(this),
                _implementation,
                keccak256(_data)
            )
        );



        if (intentReceipt[id] != bytes32(0)) {

            (bool canceled, , address relayer) = _decodeReceipt(intentReceipt[id]);
            require(relayer == address(0), "Intent already relayed");
            require(!canceled, "Intent was canceled");
            revert("Unknown error");
        }


        address _signer = signer();



        require(_signer != INVALID_ADDRESS, "Signer is not a valid address");


        require(_signer == msg.sender || _signer == SigUtils.ecrecover2(id, _signature), "Invalid signature");


        intentReceipt[id] = _encodeReceipt(false, block.number, msg.sender);


        emit Relayed(id, _implementation, _data);




        bool success;
        (success, result) = _implementation.delegatecall(abi.encode(id, _data));



        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }



    function cancel(bytes32 _id) external {
        require(msg.sender == address(this), "Only wallet can cancel txs");

        if (intentReceipt[_id] != bytes32(0)) {
            (bool canceled, , address relayer) = _decodeReceipt(intentReceipt[_id]);
            require(relayer == address(0), "Intent already relayed");
            require(!canceled, "Intent was canceled");
            revert("Unknown error");
        }

        emit Canceled(_id);
        intentReceipt[_id] = _encodeReceipt(true, 0, address(0));
    }






    function _encodeReceipt(
        bool _canceled,
        uint256 _block,
        address _relayer
    ) internal pure returns (bytes32 _receipt) {
        assembly {
            _receipt := or(shl(255, _canceled), or(shl(160, _block), _relayer))
        }
    }



    function _decodeReceipt(bytes32 _receipt) internal pure returns (
        bool _canceled,
        uint256 _block,
        address _relayer
    ) {
        assembly {
            _canceled := shr(255, _receipt)
            _block := and(shr(160, _receipt), 0x7fffffffffffffffffffffff)
            _relayer := and(_receipt, 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }


    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(0x150b7a02);
    }
}



library Bytes {


    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_preBytes, _postBytes);
    }


    function concat(bytes memory _a, bytes1 _b) internal pure returns (bytes memory _out) {
        return concat(_a, abi.encodePacked(_b));
    }


    function concat(
        bytes memory _a,
        bytes memory _b,
        bytes memory _c,
        bytes memory _d,
        bytes memory _e,
        bytes memory _f
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            _a,
            _b,
            _c,
            _d,
            _e,
            _f
        );
    }


    function toBytes(bytes1 _a) internal pure returns (bytes memory) {
        return abi.encodePacked(_a);
    }


    function toBytes1(uint256 _a) internal pure returns (bytes1 c) {
        assembly { c := shl(248, _a) }
    }


    function plus(bytes1 _a, uint256 _b) internal pure returns (bytes1 c) {
        c = toBytes1(_b);
        assembly { c := add(_a, c) }
    }



    function toAddress(bytes memory _a) internal pure returns (address payable b) {
        require(_a.length <= 20);
        assembly {
            b := shr(mul(sub(32, mload(_a)), 8), mload(add(_a, 32)))
        }
    }


    function mostSignificantBit(uint256 x) internal pure returns (uint256) {
        uint8 o = 0;
        uint8 h = 255;

        while (h > o) {
            uint8 m = uint8 ((uint16 (o) + uint16 (h)) >> 1);
            uint256 t = x >> m;
            if (t == 0) h = m - 1;
            else if (t > 1) o = m + 1;
            else return m;
        }

        return h;
    }


    function shrink(address _a) internal pure returns (bytes memory b) {
        uint256 abits = mostSignificantBit(uint256(_a)) + 1;
        uint256 abytes = abits / 8 + (abits % 8 == 0 ? 0 : 1);

        assembly {
            b := 0x0
            mstore(0x0, abytes)
            mstore(0x20, shl(mul(sub(32, abytes), 8), _a))
        }
    }
}

library MinimalProxy {
    using Bytes for bytes1;
    using Bytes for bytes;



    bytes constant CODE1 = hex"60";
    bytes constant CODE2 = hex"80600b6000396000f3";
    bytes constant CODE3 = hex"3660008037600080366000";
    bytes constant CODE4 = hex"5af43d6000803e60003d9160";
    bytes constant CODE5 = hex"57fd5bf3";

    bytes1 constant BASE_SIZE = 0x1d;
    bytes1 constant PUSH_1 = 0x60;
    bytes1 constant BASE_RETURN_JUMP = 0x1b;



    function build(address _address) internal pure returns (bytes memory initCode) {
        return build(Bytes.shrink(_address));
    }

    function build(bytes memory _address) private pure returns (bytes memory initCode) {
        require(_address.length <= 20, "Address too long");
        initCode = Bytes.concat(
            CODE1,
            BASE_SIZE.plus(_address.length).toBytes(),
            CODE2,
            CODE3.concat(PUSH_1.plus(_address.length - 1)).concat(_address),
            CODE4.concat(BASE_RETURN_JUMP.plus(_address.length)),
            CODE5
        );
    }
}







contract MarmoStork {


    address private constant INVALID_ADDRESS = address(0x9431Bab00000000000000000000000039bD955c9);


    bytes1 private constant CREATE2_PREFIX = byte(0xff);


    bytes internal bytecode;



    bytes32 internal hash;



    address public marmo;



    constructor(address payable _source) public {

        bytecode = MinimalProxy.build(_source);


        hash = keccak256(bytecode);


        Marmo marmoc = Marmo(_source);
        if (marmoc.signer() == address(0)) {
            marmoc.init(INVALID_ADDRESS);
        }


        require(marmoc.signer() == INVALID_ADDRESS, "Error init Marmo source");


        marmo = address(marmoc);
    }



    function marmoOf(address _signer) external view returns (address) {

        return address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        CREATE2_PREFIX,
                        address(this),
                        bytes32(uint256(_signer)),
                        hash
                    )
                )
            )
        );
    }



    function reveal(address _signer) external payable {

        bytes memory proxyCode = bytecode;



        Marmo p;
        assembly {
            p := create2(0, add(proxyCode, 0x20), mload(proxyCode), _signer)
        }



        p.init.value(msg.value)(_signer);
    }
}
