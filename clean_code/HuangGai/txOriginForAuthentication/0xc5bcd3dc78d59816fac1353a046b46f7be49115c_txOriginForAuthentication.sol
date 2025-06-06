pragma solidity ^0.5.0;





contract UserAuth {

    event LogSetOwner(address indexed owner, address setter);
    address public owner;




    modifier auth {
        require(tx.origin == owner, "permission-denied");

        _;
    }





    function setOwner(address _owner) public auth {
        owner = _owner;
        emit LogSetOwner(owner, msg.sender);
    }

}





contract UserNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 bar,
        uint wad,
        bytes fax
    );

    modifier note {
        bytes32 foo;
        bytes32 bar;
        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }
        emit LogNote(
            msg.sig,
            msg.sender,
            foo,
            bar,
            msg.value,
            msg.data
        );
        _;
    }
}





contract UserWallet is UserAuth, UserNote {

    event LogExecute(address target);




    constructor() public {
        owner = msg.sender;
    }

    function() external payable {}






    function execute(address _target, bytes memory _data)
        public
        payable
        note
        auth
        returns (bytes memory response)
    {
        require(_target != address(0), "invalid-logic-proxy-address");
        emit LogExecute(_target);


        assembly {
            let succeeded := delegatecall(sub(gas, 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {

                    revert(add(response, 0x20), size)
                }
        }
    }

}





contract WalletRegistry {

    event Created(address indexed sender, address indexed owner, address proxy);
    mapping(address => UserWallet) public proxies;





    function build() public returns (UserWallet proxy) {
        require(proxies[msg.sender] == UserWallet(0), "multiple-proxy-per-user-not-allowed");
        proxy = new UserWallet();
        proxy.setOwner(msg.sender);
        emit Created(msg.sender, msg.sender, address(proxy));
        proxies[msg.sender] = proxy;
    }

}
