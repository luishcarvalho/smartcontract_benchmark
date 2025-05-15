





















pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;













contract Context {


    constructor () internal { }


    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}












contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender ;

        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }




    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }








    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }




    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}









interface I_MakerOracle {






    function peek()
        external
        view
        returns (bytes32, bool);




    function read()
        external
        view
        returns (bytes32);




    function bar()
        external
        view
        returns (uint256);




    function age()
        external
        view
        returns (uint32);




    function orcl(
        address signer
    )
        external
        view
        returns (uint256);




    function bud(
        address reader
    )
        external
        view
        returns (uint256);




    function slot(
        uint8 signerId
    )
        external
        view
        returns (address);






    function poke(
        uint256[] calldata val_,
        uint256[] calldata age_,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    )
        external;




    function kiss(
        address reader
    )
        external;




    function diss(
        address reader
    )
        external;




    function kiss(
        address[] calldata readers
    )
        external;




    function diss(
        address[] calldata readers
    )
        external;
}









contract P1MirrorOracle is
    Ownable,
    I_MakerOracle
{


    event LogMedianPrice(
        uint256 val,
        uint256 age
    );

    event LogSetSigner(
        address signer,
        bool authorized
    );

    event LogSetBar(
        uint256 bar
    );

    event LogSetReader(
        address reader,
        bool authorized
    );




    uint128 internal _VAL_;


    uint32 public _AGE_;


    uint256 public _BAR_;


    mapping (address => uint256) public _ORCL_;


    mapping (address => uint256) _READERS_;



    mapping (uint8 => address) public _SLOT_;




    address public _ORACLE_;



    constructor(
        address oracle
    )
        public
    {
        _ORACLE_ = oracle;
    }






    function peek()
        external
        view
        returns (bytes32, bool)
    {
        require(
            _READERS_[msg.sender] == 1,
            "P1MirrorOracle#peek: Sender not authorized to get price"
        );
        uint256 val ;

        return (bytes32(val), val > 0);
    }




    function read()
        external
        view
        returns (bytes32)
    {
        require(
            _READERS_[msg.sender] == 1,
            "P1MirrorOracle#read: Sender not authorized to get price"
        );
        uint256 val ;

        require(
            val > 0,
            "P1MirrorOracle#read: Price is zero"
        );
        return bytes32(val);
    }




    function bar()
        external
        view
        returns (uint256)
    {
        return _BAR_;
    }




    function age()
        external
        view
        returns (uint32)
    {
        return _AGE_;
    }




    function orcl(
        address signer
    )
        external
        view
        returns (uint256)
    {
        return _ORCL_[signer];
    }




    function bud(
        address reader
    )
        external
        view
        returns (uint256)
    {
        return _READERS_[reader];
    }




    function slot(
        uint8 signerId
    )
        external
        view
        returns (address)
    {
        return _SLOT_[signerId];
    }









    function checkSynced()
        external
        view
        returns (uint256, uint256, bool)
    {
        uint256 signersToAdd ;

        uint256 signersToRemove ;

        bool barNeedsUpdate ;



        for (uint256 i ; i < 256; i++) {

            uint8 signerId ;

            uint256 signerBit ;

            address ours ;

            address theirs ;

            if (ours == address(0)) {
                if (theirs != address(0)) {
                    signersToAdd = signersToAdd | signerBit;
                }
            } else {
                if (theirs == address(0)) {
                    signersToRemove = signersToRemove | signerBit;
                } else if (ours != theirs) {
                    signersToAdd = signersToAdd | signerBit;
                    signersToRemove = signersToRemove | signerBit;
                }
            }
        }

        return (signersToAdd, signersToRemove, barNeedsUpdate);
    }







    function poke(
        uint256[] calldata val_,
        uint256[] calldata age_,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    )
        external
    {
        require(val_.length == _BAR_, "P1MirrorOracle#poke: Wrong number of messages");


        uint256 bloom ;



        uint256 last ;



        uint256 zzz ;


        for (uint256 i ; i < val_.length; i++) {

            uint256 val_i ;

            uint256 age_i ;



            address signer ;

            require(_ORCL_[signer] == 1, "P1MirrorOracle#poke: Invalid signer");


            require(age_i > zzz, "P1MirrorOracle#poke: Stale message");


            require(val_i >= last, "P1MirrorOracle#poke: Message out of order");
            last = val_i;



            uint8 signerId ;

            uint256 signerBit ;

            require(bloom & signerBit == 0, "P1MirrorOracle#poke: Duplicate signer");
            bloom = bloom | signerBit;
        }


        _VAL_ = uint128(val_[val_.length >> 1]);


        _AGE_ = uint32(block.timestamp);

        emit LogMedianPrice(_VAL_, _AGE_);
    }




    function lift(
        address[] calldata signers
    )
        external
    {
        for (uint256 i ; i < signers.length; i++) {

            address signer ;

            require(
                I_MakerOracle(_ORACLE_).orcl(signer) == 1,
                "P1MirrorOracle#lift: Signer not authorized on underlying oracle"
            );




            uint8 signerId ;

            require(
                _SLOT_[signerId] == address(0),
                "P1MirrorOracle#lift: Signer already authorized"
            );

            _ORCL_[signer] = 1;
            _SLOT_[signerId] = signer;

            emit LogSetSigner(signer, true);
        }
    }




    function drop(
        address[] calldata signers
    )
        external
    {
        for (uint256 i ; i < signers.length; i++) {

            address signer ;

            require(
                I_MakerOracle(_ORACLE_).orcl(signer) == 0,
                "P1MirrorOracle#drop: Signer is authorized on underlying oracle"
            );



            require(
                _ORCL_[signer] != 0,
                "P1MirrorOracle#drop: Signer is already not authorized"
            );

            uint8 signerId ;

            _ORCL_[signer] = 0;
            _SLOT_[signerId] = address(0);

            emit LogSetSigner(signer, false);
        }
    }




    function setBar()
        external
    {
        uint256 newBar ;

        _BAR_ = newBar;
        emit LogSetBar(newBar);
    }




    function kiss(
        address reader
    )
        external
        onlyOwner
    {
        _kiss(reader);
    }




    function diss(
        address reader
    )
        external
        onlyOwner
    {
        _diss(reader);
    }




    function kiss(
        address[] calldata readers
    )
        external
        onlyOwner
    {
        for (uint256 i ; i < readers.length; i++) {

            _kiss(readers[i]);
        }
    }




    function diss(
        address[] calldata readers
    )
        external
        onlyOwner
    {
        for (uint256 i ; i < readers.length; i++) {

            _diss(readers[i]);
        }
    }



    function wat()
        internal
        pure
        returns (bytes32);

    function recover(
        uint256 val_,
        uint256 age_,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
        pure
        returns (address)
    {
        return ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(val_, age_, wat())))
            ),
            v,
            r,
            s
        );
    }

    function getSignerId(
        address signer
    )
        internal
        pure
        returns (uint8)
    {
        return uint8(uint256(signer) >> 152);
    }

    function _kiss(
        address reader
    )
        private
    {
        _READERS_[reader] = 1;
        emit LogSetReader(reader, true);
    }

    function _diss(
        address reader
    )
        private
    {
        _READERS_[reader] = 0;
        emit LogSetReader(reader, false);
    }
}









contract P1MirrorOracleETHUSD is
    P1MirrorOracle
{
    bytes32 public constant WAT = "ETHUSD";

    constructor(
        address oracle
    )
        P1MirrorOracle(oracle)
        public
    {
    }

    function wat()
        internal
        pure
        returns (bytes32)
    {
        return WAT;
    }
}
