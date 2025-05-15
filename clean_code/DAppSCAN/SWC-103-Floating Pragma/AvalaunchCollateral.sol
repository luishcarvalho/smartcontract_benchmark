


pragma solidity ^0.6.12;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "./math/SafeMath.sol";
import "./interfaces/IAvalaunchSale.sol";
import "./Admin.sol";

contract AvalaunchCollateral is Initializable {

    using SafeMath for uint256;

    Admin public admin;

    uint256 public totalFeesCollected;

    address public moderator;

    mapping (address => bool) public isSaleApprovedByModerator;

    mapping (bytes => bool) public isSignatureUsed;

    mapping (address => mapping (address => bool)) public saleAutoBuyers;

    mapping (address => uint256) public userBalance;


    string public constant AUTOBUY_TYPE = "AutoBuy(string confirmationMessage,address saleAddress)";
    bytes32 public constant AUTOBUY_TYPEHASH = keccak256(abi.encodePacked(AUTOBUY_TYPE));
    bytes32 public constant AUTOBUY_MESSAGEHASH = keccak256("Turn AutoBUY ON.");


    string public constant BOOST_TYPE = "Boost(string confirmationMessage,address saleAddress)";
    bytes32 public constant BOOST_TYPEHASH = keccak256(abi.encodePacked(BOOST_TYPE));
    bytes32 public constant BOOST_MESSAGEHASH = keccak256("Boost participation.");


    string public constant EIP712_DOMAIN = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    bytes32 public DOMAIN_SEPARATOR;

    event DepositedCollateral(address indexed wallet, uint256 amountDeposited, uint256 timestamp);
    event WithdrawnCollateral(address indexed wallet, uint256 amountWithdrawn, uint256 timestamp);
    event FeeTaken(address indexed sale, uint256 participationAmount, uint256 feeAmount, string action);
    event ApprovedSale(address indexed sale);

    modifier onlyAdmin {
        require(admin.isAdmin(msg.sender), "Only admin.");
        _;
    }

    modifier onlyModerator {
        require(msg.sender == moderator, "Only moderator.");
        _;
    }







    function initialize(address _moderator, address _admin, uint256 chainId) external initializer {

        require(_moderator != address(0x0), "Moderator can not be 0x0.");
        require(_admin != address(0x0), "Admin can not be 0x0.");


        moderator = _moderator;
        admin = Admin(_admin);


        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("AvalaunchApp"),
                keccak256("1"),
                chainId,
                address(this)
            )
        );
    }


    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success);
    }




    function depositCollateral() external payable {
        userBalance[msg.sender] = userBalance[msg.sender].add(msg.value);
        emit DepositedCollateral(
            msg.sender,
            msg.value,
            block.timestamp
        );
    }






    function withdrawCollateral(uint256 _amount) external {
        require(userBalance[msg.sender] >= _amount, "Not enough funds.");

        userBalance[msg.sender] = userBalance[msg.sender].sub(_amount);
        safeTransferAVAX(msg.sender, _amount);

        emit WithdrawnCollateral(
            msg.sender,
            _amount,
            block.timestamp
        );
    }















    function autoParticipate(
        address saleAddress,
        uint256 amountAVAX,
        uint256 amount,
        uint256 amountXavaToBurn,
        uint256 roundId,
        address user,
        uint256 participationFeeAVAX,
        bytes calldata permitSignature
    )
    external
    onlyAdmin
    {

        require(isSaleApprovedByModerator[saleAddress], "Sale contract not approved by moderator.");

        require(!isSignatureUsed[permitSignature], "Signature already used.");

        isSignatureUsed[permitSignature] = true;

        require(!saleAutoBuyers[saleAddress][user], "User autoBuy already active.");

        saleAutoBuyers[saleAddress][user] = true;

        require(verifyAutoBuySignature(user, saleAddress, permitSignature), "AutoBuy signature invalid.");

        require(amountAVAX.add(participationFeeAVAX) <= userBalance[user], "Not enough collateral.");

        userBalance[user] = userBalance[user].sub(amountAVAX.add(participationFeeAVAX));

        totalFeesCollected = totalFeesCollected.add(participationFeeAVAX);


        safeTransferAVAX(moderator, participationFeeAVAX);

        emit FeeTaken(saleAddress, amountAVAX, participationFeeAVAX, "autoParticipate");


        IAvalaunchSale(saleAddress).autoParticipate{
            value: amountAVAX
        }(user, amount, amountXavaToBurn, roundId);
    }















    function boostParticipation(
        address saleAddress,
        uint256 amountAVAX,
        uint256 amount,
        uint256 amountXavaToBurn,
        uint256 roundId,
        address user,
        uint256 boostFeeAVAX,
        bytes calldata permitSignature
    )
    external
    onlyAdmin
    {

        require(isSaleApprovedByModerator[saleAddress], "Sale contract not approved by moderator.");

        require(amountAVAX.add(boostFeeAVAX) <= userBalance[user], "Not enough collateral.");

        userBalance[user] = userBalance[user].sub(amountAVAX.add(boostFeeAVAX));

        require(!isSignatureUsed[permitSignature], "Signature already used.");

        isSignatureUsed[permitSignature] = true;

        require(verifyBoostSignature(user, saleAddress, permitSignature), "Boost signature invalid.");

        safeTransferAVAX(moderator, boostFeeAVAX);

        emit FeeTaken(saleAddress, amountAVAX, boostFeeAVAX, "boostParticipation");


        IAvalaunchSale(saleAddress).boostParticipation{
            value: amountAVAX
        }(user, amount, amountXavaToBurn, roundId);
    }





    function setModerator(address _moderator) onlyModerator external {
        require(_moderator != address(0x0), "Moderator can not be 0x0");
        moderator = _moderator;
    }





    function approveSale(address saleAddress) onlyModerator external {

        isSaleApprovedByModerator[saleAddress] = true;

        emit ApprovedSale(saleAddress);
    }









    function verifyAutoBuySignature(
        address user,
        address saleContract,
        bytes memory permitSignature
    )
    public
    view
    returns (bool)
    {

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        AUTOBUY_TYPEHASH,
                        AUTOBUY_MESSAGEHASH,
                        saleContract
                    )
                )
            )
        );

        return user == ECDSA.recover(hash, permitSignature);
    }









    function verifyBoostSignature(
        address user,
        address saleContract,
        bytes memory permitSignature
    )
    public
    view
    returns (bool)
    {

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        BOOST_TYPEHASH,
                        BOOST_MESSAGEHASH,
                        saleContract
                    )
                )
            )
        );

        return user == ECDSA.recover(hash, permitSignature);
    }




    function getTVL() external view returns (uint256) {
        return address(this).balance;
    }
}
