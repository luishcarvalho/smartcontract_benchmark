pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";




library SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    require(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c>=a && c>=b);
    return c;
  }
}






interface Incognito {
    function instructionApproved(
        bool,
        bytes32,
        uint,
        bytes32[] calldata,
        bool[] calldata,
        bytes32,
        bytes32,
        uint[] calldata,
        uint8[] calldata,
        bytes32[] calldata,
        bytes32[] calldata
    ) external view returns (bool);
}




interface Withdrawable {
    function isWithdrawed(bytes32)  external view returns (bool);
    function isSigDataUsed(bytes32)  external view returns (bool);
    function getDepositedBalance(address, address)  external view returns (uint);
    function updateAssets(address[] calldata, uint[] calldata) external returns (bool);
    function paused() external view returns (bool);
}






contract Vault {
    using SafeMath for uint;




    bytes32 private constant _INCOGNITO_SLOT = 0x62135fc083646fdb4e1a9d700e351b886a4a5a39da980650269edd1ade91ffd2;
    address constant public ETH_TOKEN = 0x0000000000000000000000000000000000000000;
    mapping(bytes32 => bool) public withdrawed;
    mapping(bytes32 => bool) public sigDataUsed;

    mapping(address => mapping(address => uint)) public withdrawRequests;
    mapping(address => mapping(address => bool)) public migration;
    mapping(address => uint) public totalDepositedToSCAmount;
    Withdrawable public prevVault;
    bool public notEntered = true;
    bool public isInitialized = false;

    struct BurnInstData {
        uint8 meta;
        uint8 shard;
        address token;
        address payable to;
        uint amount;
        bytes32 itx;
    }


    enum Errors {
        EMPTY,
        NO_REENTRANCE,
        MAX_UINT_REACHED,
        VALUE_OVER_FLOW,
        INTERNAL_TX_ERROR,
        ALREADY_USED,
        INVALID_DATA,
        TOKEN_NOT_ENOUGH,
        WITHDRAW_REQUEST_TOKEN_NOT_ENOUGH,
        INVALID_RETURN_DATA,
        NOT_EQUAL,
        NULL_VALUE,
        ONLY_PREVAULT,
        PREVAULT_NOT_PAUSED
    }

    event Deposit(address token, string incognitoAddress, uint amount);
    event Withdraw(address token, address to, uint amount);
    event UpdateTokenTotal(address[] assets, uint[] amounts);
    event UpdateIncognitoProxy(address newIncognitoProxy);




     modifier onlyPreVault(){
        require(address(prevVault) != address(0x0) && msg.sender == address(prevVault), errorToString(Errors.ONLY_PREVAULT));
        _;
     }








    modifier nonReentrant() {

        require(notEntered, errorToString(Errors.NO_REENTRANCE));


        notEntered = false;

        _;



        notEntered = true;
    }







    function initialize(address _prevVault) external {
        require(!isInitialized);
        prevVault = Withdrawable(_prevVault);
        isInitialized = true;
        notEntered = true;
    }




    function _incognito() internal view returns (address icg) {
        bytes32 slot = _INCOGNITO_SLOT;

        assembly {
            icg := sload(slot)
        }
    }







    function deposit(string calldata incognitoAddress) external payable nonReentrant {
        require(address(this).balance <= 10 ** 27, errorToString(Errors.MAX_UINT_REACHED));
        emit Deposit(ETH_TOKEN, incognitoAddress, msg.value);
    }











    function depositERC20(address token, uint amount, string calldata incognitoAddress) external payable nonReentrant {
        IERC20 erc20Interface = IERC20(token);
        uint8 decimals = getDecimals(address(token));
        uint tokenBalance = erc20Interface.balanceOf(address(this));
        uint beforeTransfer = tokenBalance;
        uint emitAmount = amount;
        if (decimals > 9) {
            emitAmount = emitAmount / (10 ** (uint(decimals) - 9));
            tokenBalance = tokenBalance / (10 ** (uint(decimals) - 9));
        }
        require(emitAmount <= 10 ** 18 && tokenBalance <= 10 ** 18 && emitAmount.safeAdd(tokenBalance) <= 10 ** 18, errorToString(Errors.VALUE_OVER_FLOW));
        erc20Interface.transferFrom(msg.sender, address(this), amount);
        require(checkSuccess(), errorToString(Errors.INTERNAL_TX_ERROR));
        require(balanceOf(token).safeSub(beforeTransfer) == amount, errorToString(Errors.NOT_EQUAL));

        emit Deposit(token, incognitoAddress, emitAmount);
    }









    function isWithdrawed(bytes32 hash) public view returns(bool) {
        if (withdrawed[hash]) {
            return true;
        } else if (address(prevVault) == address(0)) {
            return false;
        }
        return prevVault.isWithdrawed(hash);
    }





    function parseBurnInst(bytes memory inst) public pure returns (BurnInstData memory) {
        BurnInstData memory data;
        data.meta = uint8(inst[0]);
        data.shard = uint8(inst[1]);
        address token;
        address payable to;
        uint amount;
        bytes32 itx;
        assembly {

            token := mload(add(inst, 0x22))
            to := mload(add(inst, 0x42))
            amount := mload(add(inst, 0x62))
            itx := mload(add(inst, 0x82))
        }
        data.token = token;
        data.to = to;
        data.amount = amount;
        data.itx = itx;
        return data;
    }







    function verifyInst(
        bytes memory inst,
        uint heights,
        bytes32[] memory instPaths,
        bool[] memory instPathIsLefts,
        bytes32 instRoots,
        bytes32 blkData,
        uint[] memory sigIdxs,
        uint8[] memory sigVs,
        bytes32[] memory sigRs,
        bytes32[] memory sigSs
    ) view internal {

        bytes32 beaconInstHash = keccak256(abi.encodePacked(inst, heights));


        require(Incognito(_incognito()).instructionApproved(
            true,
            beaconInstHash,
            heights,
            instPaths,
            instPathIsLefts,
            instRoots,
            blkData,
            sigIdxs,
            sigVs,
            sigRs,
            sigSs
        ), errorToString(Errors.INVALID_DATA));
    }

















    function withdraw(
        bytes memory inst,
        uint heights,
        bytes32[] memory instPaths,
        bool[] memory instPathIsLefts,
        bytes32 instRoots,
        bytes32 blkData,
        uint[] memory sigIdxs,
        uint8[] memory sigVs,
        bytes32[] memory sigRs,
        bytes32[] memory sigSs
    ) public nonReentrant {
        require(inst.length >= 130);
        BurnInstData memory data = parseBurnInst(inst);
        require(data.meta == 241 && data.shard == 1);


        require(!isWithdrawed(data.itx), errorToString(Errors.ALREADY_USED));
        withdrawed[data.itx] = true;


        if (data.token == ETH_TOKEN) {
            require(address(this).balance >= data.amount.safeAdd(totalDepositedToSCAmount[data.token]), errorToString(Errors.TOKEN_NOT_ENOUGH));
        } else {
            uint8 decimals = getDecimals(data.token);
            if (decimals > 9) {
                data.amount = data.amount * (10 ** (uint(decimals) - 9));
            }
            require(IERC20(data.token).balanceOf(address(this)) >= data.amount.safeAdd(totalDepositedToSCAmount[data.token]), errorToString(Errors.TOKEN_NOT_ENOUGH));
        }

        verifyInst(
            inst,
            heights,
            instPaths,
            instPathIsLefts,
            instRoots,
            blkData,
            sigIdxs,
            sigVs,
            sigRs,
            sigSs
        );


        if (data.token == ETH_TOKEN) {
          (bool success, ) =  data.to.call{value: data.amount}("");
          require(success, errorToString(Errors.INTERNAL_TX_ERROR));
        } else {
            IERC20(data.token).transfer(data.to, data.amount);
            require(checkSuccess(), errorToString(Errors.INTERNAL_TX_ERROR));
        }
        emit Withdraw(data.token, data.to, data.amount);
    }


















    function submitBurnProof(
        bytes memory inst,
        uint heights,
        bytes32[] memory instPaths,
        bool[] memory instPathIsLefts,
        bytes32 instRoots,
        bytes32 blkData,
        uint[] memory sigIdxs,
        uint8[] memory sigVs,
        bytes32[] memory sigRs,
        bytes32[] memory sigSs
    ) public nonReentrant {
        require(inst.length >= 130);
        BurnInstData memory data = parseBurnInst(inst);
        require(data.meta == 243 && data.shard == 1);


        require(!isWithdrawed(data.itx), errorToString(Errors.ALREADY_USED));
        withdrawed[data.itx] = true;


        if (data.token == ETH_TOKEN) {
            require(address(this).balance >= data.amount.safeAdd(totalDepositedToSCAmount[data.token]), errorToString(Errors.TOKEN_NOT_ENOUGH));
        } else {
            uint8 decimals = getDecimals(data.token);
            if (decimals > 9) {

                data.amount = data.amount * (10 ** (uint(decimals) - 9));
            }
            require(IERC20(data.token).balanceOf(address(this)) >= data.amount.safeAdd(totalDepositedToSCAmount[data.token]), errorToString(Errors.TOKEN_NOT_ENOUGH));
        }

        verifyInst(
            inst,
            heights,
            instPaths,
            instPathIsLefts,
            instRoots,
            blkData,
            sigIdxs,
            sigVs,
            sigRs,
            sigSs
        );

        withdrawRequests[data.to][data.token] = withdrawRequests[data.to][data.token].safeAdd(data.amount);
        totalDepositedToSCAmount[data.token] = totalDepositedToSCAmount[data.token].safeAdd(data.amount);
    }




    function sigToAddress(bytes memory signData, bytes32 hash) public pure returns (address) {
        bytes32 s;
        bytes32 r;
        uint8 v;
        assembly {
            r := mload(add(signData, 0x20))
            s := mload(add(signData, 0x40))
        }
        v = uint8(signData[64]) + 27;
        return ecrecover(hash, v, r, s);
    }









    function isSigDataUsed(bytes32 hash) public view returns(bool) {
        if (sigDataUsed[hash]) {
            return true;
        } else if (address(prevVault) == address(0)) {
            return false;
        }
        return prevVault.isSigDataUsed(hash);
    }










    function requestWithdraw(
        string calldata incognitoAddress,
        address token,
        uint amount,
        bytes calldata signData,
        bytes calldata timestamp
    ) external nonReentrant {

        address verifier = verifySignData(abi.encode(incognitoAddress, token, timestamp, amount), signData);


        migrateBalance(verifier, token);

        require(withdrawRequests[verifier][token] >= amount, errorToString(Errors.WITHDRAW_REQUEST_TOKEN_NOT_ENOUGH));
        withdrawRequests[verifier][token] = withdrawRequests[verifier][token].safeSub(amount);
        totalDepositedToSCAmount[token] = totalDepositedToSCAmount[token].safeSub(amount);


        uint emitAmount = amount;
        if (token != ETH_TOKEN) {
            uint8 decimals = getDecimals(token);
            if (decimals > 9) {
                emitAmount = amount / (10 ** (uint(decimals) - 9));
            }
        }

        emit Deposit(token, incognitoAddress, emitAmount);
    }













    function execute(
        address token,
        uint amount,
        address recipientToken,
        address exchangeAddress,
        bytes calldata callData,
        bytes calldata timestamp,
        bytes calldata signData
    ) external payable nonReentrant {

        address verifier = verifySignData(abi.encode(exchangeAddress, callData, timestamp, amount), signData);


        migrateBalance(verifier, token);
        require(withdrawRequests[verifier][token] >= amount, errorToString(Errors.WITHDRAW_REQUEST_TOKEN_NOT_ENOUGH));


        totalDepositedToSCAmount[token] = totalDepositedToSCAmount[token].safeSub(amount);
        withdrawRequests[verifier][token] = withdrawRequests[verifier][token].safeSub(amount);


        uint ethAmount = msg.value;
        if (token == ETH_TOKEN) {
            ethAmount = ethAmount.safeAdd(amount);
        } else {

            require(IERC20(token).balanceOf(address(this)) >= amount, errorToString(Errors.TOKEN_NOT_ENOUGH));
            IERC20(token).transfer(exchangeAddress, amount);
            require(checkSuccess(), errorToString(Errors.INTERNAL_TX_ERROR));
        }
        uint returnedAmount = callExtFunc(recipientToken, ethAmount, callData, exchangeAddress);


        withdrawRequests[verifier][recipientToken] = withdrawRequests[verifier][recipientToken].safeAdd(returnedAmount);
        totalDepositedToSCAmount[recipientToken] = totalDepositedToSCAmount[recipientToken].safeAdd(returnedAmount);
    }




    function callExtFunc(address recipientToken, uint ethAmount, bytes memory callData, address exchangeAddress) internal returns (uint) {

        uint balanceBeforeTrade = balanceOf(recipientToken);
        if (recipientToken == ETH_TOKEN) {
            balanceBeforeTrade = balanceBeforeTrade.safeSub(msg.value);
        }
        require(address(this).balance >= ethAmount, errorToString(Errors.TOKEN_NOT_ENOUGH));
        (bool success, bytes memory result) = exchangeAddress.call{value: ethAmount}(callData);
        require(success);

        (address returnedTokenAddress, uint returnedAmount) = abi.decode(result, (address, uint));
        require(returnedTokenAddress == recipientToken && balanceOf(recipientToken).safeSub(balanceBeforeTrade) == returnedAmount, errorToString(Errors.INVALID_RETURN_DATA));

        return returnedAmount;
    }




     function verifySignData(bytes memory data, bytes memory signData) internal returns(address){
        bytes32 hash = keccak256(data);
        require(!isSigDataUsed(hash), errorToString(Errors.ALREADY_USED));
        address verifier = sigToAddress(signData, hash);

        sigDataUsed[hash] = true;

        return verifier;
     }





    function migrateBalance(address owner, address token) internal {
        if (address(prevVault) != address(0x0) && !migration[owner][token]) {
            withdrawRequests[owner][token] = withdrawRequests[owner][token].safeAdd(prevVault.getDepositedBalance(token, owner));
  	        migration[owner][token] = true;
  	   }
    }




    function getDepositedBalance(
        address token,
        address owner
    ) public view returns (uint) {
        if (address(prevVault) != address(0x0) && !migration[owner][token]) {
 	        return withdrawRequests[owner][token].safeAdd(prevVault.getDepositedBalance(token, owner));
 	    }
        return withdrawRequests[owner][token];
    }








    function updateAssets(address[] calldata assets, uint[] calldata amounts) external onlyPreVault returns(bool) {
        require(assets.length == amounts.length,  errorToString(Errors.NOT_EQUAL));
        require(Withdrawable(prevVault).paused(), errorToString(Errors.PREVAULT_NOT_PAUSED));
        for (uint i = 0; i < assets.length; i++) {
            totalDepositedToSCAmount[assets[i]] = totalDepositedToSCAmount[assets[i]].safeAdd(amounts[i]);
        }
        emit UpdateTokenTotal(assets, amounts);

        return true;
    }




    receive() external payable {}






    function checkSuccess() private pure returns (bool) {
		uint256 returnValue = 0;
		assembly {

			switch returndatasize()


			case 0x0 {
				returnValue := 1
			}


			case 0x20 {

				returndatacopy(0x0, 0x0, 0x20)


				returnValue := mload(0x0)
			}


			default { }
		}
		return returnValue != 0;
	}




     function errorToString(Errors error) internal pure returns(string memory) {
        uint8 erroNum = uint8(error);
        uint maxlength = 10;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (erroNum != 0) {
            uint8 remainder = erroNum % 10;
            erroNum = erroNum / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        return string(s);
    }






    function getDecimals(address token) public view returns (uint8) {
        IERC20 erc20 = IERC20(token);
        return uint8(erc20.decimals());
    }




    function balanceOf(address token) public view returns (uint) {
        if (token == ETH_TOKEN) {
            return address(this).balance;
        }
        return IERC20(token).balanceOf(address(this));
    }
}
