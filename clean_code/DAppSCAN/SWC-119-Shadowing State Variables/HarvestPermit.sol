

pragma solidity 0.6.12;

import "./FountainBase.sol";


abstract contract HarvestPermit is FountainBase {
    using Counters for Counters.Counter;

    mapping(address => mapping(address => uint256)) private _timeLimits;

    mapping(address => Counters.Counter) private _nonces;


    bytes32 private immutable _HARVEST_PERMIT_TYPEHASH =
        keccak256(
            "HarvestPermit(address owner,address sender,uint256 timeLimit,uint256 nonce,uint256 deadline)"
        );





    event HarvestApproval(
        address indexed owner,
        address indexed sender,
        uint256 timeLimit
    );


    modifier canHarvestFrom(address owner) {
        _requireMsg(
            block.timestamp <= _timeLimits[owner][_msgSender()],
            "general",
            "harvest not allowed"
        );
        _;
    }






    function harvestTimeLimit(address owner, address sender)
        public
        view
        returns (uint256)
    {
        return _timeLimits[owner][sender];
    }




    function harvestApprove(address sender, uint256 timeLimit)
        external
        returns (bool)
    {
        _harvestApprove(_msgSender(), sender, timeLimit);
        return true;
    }









    function harvestPermit(
        address owner,
        address sender,
        uint256 timeLimit,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {

        _requireMsg(
            block.timestamp <= deadline,
            "harvestPermit",
            "expired deadline"
        );

        bytes32 structHash =
            keccak256(
                abi.encode(
                    _HARVEST_PERMIT_TYPEHASH,
                    owner,
                    sender,
                    timeLimit,
                    _nonces[owner].current(),
                    deadline
                )
            );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        _requireMsg(signer == owner, "harvestPermit", "invalid signature");

        _nonces[owner].increment();
        _harvestApprove(owner, sender, timeLimit);
    }

    function harvestNonces(address owner) public view returns (uint256) {
        return _nonces[owner].current();
    }





    function harvestFrom(
        IAngel angel,
        address from,
        address to
    ) public canHarvestFrom(from) {
        _harvestAngel(angel, from, to);
        emit Harvest(from);
    }




    function harvestAllFrom(address from, address to)
        public
        canHarvestFrom(from)
    {
        IAngel[] memory angels = joinedAngel(from);
        for (uint256 i = 0; i < angels.length; i++) {
            IAngel angel = angels[i];
            _harvestAngel(angel, from, to);
        }
        emit Harvest(from);
    }










    function harvestFromWithPermit(
        IAngel angel,
        address from,
        address to,
        uint256 timeLimit,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        harvestPermit(from, _msgSender(), timeLimit, deadline, v, r, s);
        harvestFrom(angel, from, to);
    }









    function harvestAllFromWithPermit(
        address from,
        address to,
        uint256 timeLimit,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        harvestPermit(from, _msgSender(), timeLimit, deadline, v, r, s);
        harvestAllFrom(from, to);
    }

    function _harvestApprove(
        address owner,
        address sender,
        uint256 timeLimit
    ) internal {
        _requireMsg(
            owner != address(0),
            "_harvestApprove",
            "approve from the zero address"
        );
        _requireMsg(
            sender != address(0),
            "_harvestApprove",
            "approve to the zero address"
        );

        _timeLimits[owner][sender] = timeLimit;
        emit HarvestApproval(owner, sender, timeLimit);
    }
}
