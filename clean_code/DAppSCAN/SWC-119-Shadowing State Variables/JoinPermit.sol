

pragma solidity 0.6.12;

import "./FountainBase.sol";


abstract contract JoinPermit is FountainBase {
    using Counters for Counters.Counter;

    mapping(address => mapping(address => uint256)) private _timeLimits;

    mapping(address => Counters.Counter) private _nonces;


    bytes32 private immutable _JOIN_PERMIT_TYPEHASH =
        keccak256(
            "JoinPermit(address user,address sender,uint256 timeLimit,uint256 nonce,uint256 deadline)"
        );





    event JoinApproval(
        address indexed user,
        address indexed sender,
        uint256 timeLimit
    );


    modifier canJoinFor(address user) {
        _requireMsg(
            block.timestamp <= _timeLimits[user][_msgSender()],
            "general",
            "join not allowed"
        );
        _;
    }






    function joinTimeLimit(address user, address sender)
        public
        view
        returns (uint256)
    {
        return _timeLimits[user][sender];
    }




    function joinApprove(address sender, uint256 timeLimit)
        external
        returns (bool)
    {
        _joinApprove(_msgSender(), sender, timeLimit);
        return true;
    }









    function joinPermit(
        address user,
        address sender,
        uint256 timeLimit,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {

        _requireMsg(
            block.timestamp <= deadline,
            "joinPermit",
            "expired deadline"
        );

        bytes32 structHash =
            keccak256(
                abi.encode(
                    _JOIN_PERMIT_TYPEHASH,
                    user,
                    sender,
                    timeLimit,
                    _nonces[user].current(),
                    deadline
                )
            );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        _requireMsg(signer == user, "joinPermit", "invalid signature");

        _nonces[user].increment();
        _joinApprove(user, sender, timeLimit);
    }

    function joinNonces(address user) public view returns (uint256) {
        return _nonces[user].current();
    }




    function joinAngelFor(IAngel angel, address user) public canJoinFor(user) {
        _joinAngel(angel, user);
    }




    function joinAngelsFor(IAngel[] memory angels, address user)
        public
        canJoinFor(user)
    {
        for (uint256 i = 0; i < angels.length; i++) {
            _joinAngel(angels[i], user);
        }
    }










    function joinAngelForWithPermit(
        IAngel angel,
        address user,
        uint256 timeLimit,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        joinPermit(user, _msgSender(), timeLimit, deadline, v, r, s);
        joinAngelFor(angel, user);
    }










    function joinAngelsForWithPermit(
        IAngel[] calldata angels,
        address user,
        uint256 timeLimit,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        joinPermit(user, _msgSender(), timeLimit, deadline, v, r, s);
        joinAngelsFor(angels, user);
    }

    function _joinApprove(
        address user,
        address sender,
        uint256 timeLimit
    ) internal {
        _requireMsg(
            user != address(0),
            "_joinApprove",
            "approve from the zero address"
        );
        _requireMsg(
            sender != address(0),
            "_joinApprove",
            "approve to the zero address"
        );

        if (timeLimit == 1) timeLimit = block.timestamp;
        _timeLimits[user][sender] = timeLimit;
        emit JoinApproval(user, sender, timeLimit);
    }
}
