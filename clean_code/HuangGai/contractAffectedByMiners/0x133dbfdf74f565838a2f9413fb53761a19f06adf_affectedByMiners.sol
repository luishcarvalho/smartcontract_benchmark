



pragma solidity >=0.5.5 <0.6.0;
pragma experimental ABIEncoderV2;














library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }












    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }














    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }














    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}




library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }







    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }



















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function callOptionalReturn(IERC20 token, bytes memory data) private {








        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (block.timestamp > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract HashedTimeLockContract {
    using SafeERC20 for IERC20;

    mapping(bytes32 => LockContract) public contracts;





    uint256 public constant INVALID = 0;
    uint256 public constant ACTIVE = 1;
    uint256 public constant REFUNDED = 2;
    uint256 public constant WITHDRAWN = 3;
    uint256 public constant EXPIRED = 4;

    struct LockContract {
        uint256 inputAmount;
        uint256 outputAmount;
        uint256 expiration;
        uint256 status;
        bytes32 hashLock;
        address tokenAddress;
        address sender;
        address receiver;
        string outputNetwork;
        string outputAddress;
    }

    event Withdraw(
        bytes32 id,
        bytes32 secret,
        bytes32 hashLock,
        address indexed tokenAddress,
        address indexed sender,
        address indexed receiver
    );

    event Refund(
        bytes32 id,
        bytes32 hashLock,
        address indexed tokenAddress,
        address indexed sender,
        address indexed receiver
    );

    event NewContract(
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 expiration,
        bytes32 id,
        bytes32 hashLock,
        address indexed tokenAddress,
        address indexed sender,
        address indexed receiver,
        string outputNetwork,
        string outputAddress
    );

    function newContract(
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 expiration,
        bytes32 hashLock,
        address tokenAddress,
        address receiver,
        string calldata outputNetwork,
        string calldata outputAddress
    ) external {
        require(expiration > block.timestamp, "INVALID_TIME");

        require(inputAmount > 0, "INVALID_AMOUNT");

        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            inputAmount
        );

        bytes32 id = sha256(
            abi.encodePacked(
                msg.sender,
                receiver,
                inputAmount,
                hashLock,
                expiration,
                tokenAddress
            )
        );

        require(contracts[id].status == INVALID, "SWAP_EXISTS");

        contracts[id] = LockContract(
            inputAmount,
            outputAmount,
            expiration,
            ACTIVE,
            hashLock,
            tokenAddress,
            msg.sender,
            receiver,
            outputNetwork,
            outputAddress
        );

        emit NewContract(
            inputAmount,
            outputAmount,
            expiration,
            id,
            hashLock,
            tokenAddress,
            msg.sender,
            receiver,
            outputNetwork,
            outputAddress
        );
    }

    function withdraw(bytes32 id, bytes32 secret, address tokenAddress)
        external
    {
        LockContract storage c = contracts[id];

        require(c.tokenAddress == tokenAddress, "INVALID_TOKEN");

        require(c.status == ACTIVE, "SWAP_NOT_ACTIVE");

        require(c.expiration > block.timestamp, "INVALID_TIME");

        require(
            c.hashLock == sha256(abi.encodePacked(secret)),
            "INVALID_SECRET"
        );

        c.status = WITHDRAWN;

        IERC20(tokenAddress).safeTransfer(c.receiver, c.inputAmount);

        emit Withdraw(
            id,
            secret,
            c.hashLock,
            tokenAddress,
            c.sender,
            c.receiver
        );
    }

    function refund(bytes32 id, address tokenAddress) external {
        LockContract storage c = contracts[id];

        require(c.tokenAddress == tokenAddress, "INVALID_TOKEN");

        require(c.status == ACTIVE, "SWAP_NOT_ACTIVE");

        require(c.expiration <= block.timestamp, "INVALID_TIME");

        c.status = REFUNDED;

        IERC20(tokenAddress).safeTransfer(c.sender, c.inputAmount);

        emit Refund(id, c.hashLock, tokenAddress, c.sender, c.receiver);
    }

    function getStatus(bytes32[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](ids.length);

        for (uint256 index = 0; index < ids.length; index++) {
            result[index] = getSingleStatus(ids[index]);
        }

        return result;
    }

    function getSingleStatus(bytes32 id) public view returns (uint256 result) {
        LockContract memory tempContract = contracts[id];

        if (
            tempContract.status == ACTIVE &&
            tempContract.expiration < block.timestamp
        ) {
            result = EXPIRED;
        } else {
            result = tempContract.status;
        }
    }
}
