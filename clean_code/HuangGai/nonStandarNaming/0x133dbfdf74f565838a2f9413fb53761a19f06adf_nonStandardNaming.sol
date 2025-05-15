

pragma solidity >=0.5.5 <0.6.0;
pragma experimental ABIEncoderV2;


library SafeMath {

    function ADD25(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB66(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB66(a, b, "SafeMath: subtraction overflow");
    }


    function SUB66(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL558(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV239(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV239(a, b, "SafeMath: division by zero");
    }


    function DIV239(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD772(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD772(a, b, "SafeMath: modulo by zero");
    }


    function MOD772(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


library Address {

    function ISCONTRACT585(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function TOPAYABLE289(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }


    function SENDVALUE993(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


interface IERC20 {

    function TOTALSUPPLY470() external view returns (uint256);


    function BALANCEOF709(address account) external view returns (uint256);


    function TRANSFER989(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE850(address owner, address spender) external view returns (uint256);


    function APPROVE908(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM880(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER349(address indexed from, address indexed to, uint256 value);


    event APPROVAL865(address indexed owner, address indexed spender, uint256 value);
}


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER35(IERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN165(token, abi.encodeWithSelector(token.TRANSFER989.selector, to, value));
    }

    function SAFETRANSFERFROM944(IERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN165(token, abi.encodeWithSelector(token.TRANSFERFROM880.selector, from, to, value));
    }

    function SAFEAPPROVE641(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.ALLOWANCE850(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN165(token, abi.encodeWithSelector(token.APPROVE908.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE592(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE850(address(this), spender).ADD25(value);
        CALLOPTIONALRETURN165(token, abi.encodeWithSelector(token.APPROVE908.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE974(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE850(address(this), spender).SUB66(value, "SafeERC20: decreased allowance below zero");
        CALLOPTIONALRETURN165(token, abi.encodeWithSelector(token.APPROVE908.selector, spender, newAllowance));
    }


    function CALLOPTIONALRETURN165(IERC20 token, bytes memory data) private {








        require(address(token).ISCONTRACT585(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract HashedTimeLockContract {
    using SafeERC20 for IERC20;

    mapping(bytes32 => LockContract) public contracts;





    uint256 public constant invalid765 = 0;
    uint256 public constant active785 = 1;
    uint256 public constant refunded800 = 2;
    uint256 public constant withdrawn73 = 3;
    uint256 public constant expired653 = 4;

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

    event WITHDRAW989(
        bytes32 id,
        bytes32 secret,
        bytes32 hashLock,
        address indexed tokenAddress,
        address indexed sender,
        address indexed receiver
    );

    event REFUND925(
        bytes32 id,
        bytes32 hashLock,
        address indexed tokenAddress,
        address indexed sender,
        address indexed receiver
    );

    event NEWCONTRACT591(
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

    function NEWCONTRACT928(
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

        IERC20(tokenAddress).SAFETRANSFERFROM944(
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

        require(contracts[id].status == invalid765, "SWAP_EXISTS");

        contracts[id] = LockContract(
            inputAmount,
            outputAmount,
            expiration,
            active785,
            hashLock,
            tokenAddress,
            msg.sender,
            receiver,
            outputNetwork,
            outputAddress
        );

        emit NEWCONTRACT591(
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

    function WITHDRAW32(bytes32 id, bytes32 secret, address tokenAddress)
        external
    {
        LockContract storage c = contracts[id];

        require(c.tokenAddress == tokenAddress, "INVALID_TOKEN");

        require(c.status == active785, "SWAP_NOT_ACTIVE");

        require(c.expiration > block.timestamp, "INVALID_TIME");

        require(
            c.hashLock == sha256(abi.encodePacked(secret)),
            "INVALID_SECRET"
        );

        c.status = withdrawn73;

        IERC20(tokenAddress).SAFETRANSFER35(c.receiver, c.inputAmount);

        emit WITHDRAW989(
            id,
            secret,
            c.hashLock,
            tokenAddress,
            c.sender,
            c.receiver
        );
    }

    function REFUND274(bytes32 id, address tokenAddress) external {
        LockContract storage c = contracts[id];

        require(c.tokenAddress == tokenAddress, "INVALID_TOKEN");

        require(c.status == active785, "SWAP_NOT_ACTIVE");

        require(c.expiration <= block.timestamp, "INVALID_TIME");

        c.status = refunded800;

        IERC20(tokenAddress).SAFETRANSFER35(c.sender, c.inputAmount);

        emit REFUND925(id, c.hashLock, tokenAddress, c.sender, c.receiver);
    }

    function GETSTATUS910(bytes32[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](ids.length);

        for (uint256 index = 0; index < ids.length; index++) {
            result[index] = GETSINGLESTATUS853(ids[index]);
        }

        return result;
    }

    function GETSINGLESTATUS853(bytes32 id) public view returns (uint256 result) {
        LockContract memory tempContract = contracts[id];

        if (
            tempContract.status == active785 &&
            tempContract.expiration < block.timestamp
        ) {
            result = expired653;
        } else {
            result = tempContract.status;
        }
    }
}
