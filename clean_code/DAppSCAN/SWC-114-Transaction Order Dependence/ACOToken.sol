pragma solidity ^0.6.6;

import "./ERC20.sol";
import "../libs/Address.sol";
import "../libs/BokkyPooBahsDateTimeLibrary.sol";
import "../libs/Strings.sol";






contract ACOToken is ERC20 {
    using Address for address;




    struct TokenCollateralized {



        uint256 amount;




        uint256 index;
    }






    event CollateralDeposit(address indexed account, uint256 amount);








    event CollateralWithdraw(address indexed account, address indexed recipient, uint256 amount, uint256 fee);








    event Assigned(address indexed from, address indexed to, uint256 paidAmount, uint256 tokenAmount);




    address public underlying;




    address public strikeAsset;




    address payable public feeDestination;




    bool public isCall;




    uint256 public strikePrice;




    uint256 public expiryTime;




    uint256 public totalCollateral;




    uint256 public acoFee;




    string public underlyingSymbol;




    string public strikeAssetSymbol;




    uint8 public underlyingDecimals;




    uint8 public strikeAssetDecimals;




    uint256 internal underlyingPrecision;




    mapping(address => TokenCollateralized) internal tokenData;




    address[] internal _collateralOwners;




    bool internal _notEntered;




    bytes4 internal _transferSelector;




    bytes4 internal _transferFromSelector;





    modifier notExpired() {
        require(_notExpired(), "ACOToken::Expired");
        _;
    }




    modifier nonReentrant() {
        require(_notEntered, "ACOToken::Reentry");
        _notEntered = false;
        _;
        _notEntered = true;
    }













    function init(
        address _underlying,
        address _strikeAsset,
        bool _isCall,
        uint256 _strikePrice,
        uint256 _expiryTime,
        uint256 _acoFee,
        address payable _feeDestination
    ) public {
        require(underlying == address(0) && strikeAsset == address(0) && strikePrice == 0, "ACOToken::init: Already initialized");

        require(_expiryTime > now, "ACOToken::init: Invalid expiry");
        require(_strikePrice > 0, "ACOToken::init: Invalid strike price");
        require(_underlying != _strikeAsset, "ACOToken::init: Same assets");
        require(_acoFee <= 500, "ACOToken::init: Invalid ACO fee");
        require(_isEther(_underlying) || _underlying.isContract(), "ACOToken::init: Invalid underlying");
        require(_isEther(_strikeAsset) || _strikeAsset.isContract(), "ACOToken::init: Invalid strike asset");

        underlying = _underlying;
        strikeAsset = _strikeAsset;
        isCall = _isCall;
        strikePrice = _strikePrice;
        expiryTime = _expiryTime;
        acoFee = _acoFee;
        feeDestination = _feeDestination;
        underlyingDecimals = _getAssetDecimals(_underlying);
        strikeAssetDecimals = _getAssetDecimals(_strikeAsset);
        underlyingSymbol = _getAssetSymbol(_underlying);
        strikeAssetSymbol = _getAssetSymbol(_strikeAsset);

        underlyingPrecision = 10 ** uint256(underlyingDecimals);

        _transferSelector = bytes4(keccak256(bytes("transfer(address,uint256)")));
        _transferFromSelector = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        _notEntered = true;
    }




    receive() external payable {
        revert();
    }




    function name() public view override returns(string memory) {
        return _name();
    }




    function symbol() public view override returns(string memory) {
        return _name();
    }




    function decimals() public view override returns(uint8) {
        return underlyingDecimals;
    }






    function currentCollateral(address account) public view returns(uint256) {
        return getCollateralAmount(currentCollateralizedTokens(account));
    }








    function unassignableCollateral(address account) public view returns(uint256) {
        return getCollateralAmount(unassignableTokens(account));
    }








    function assignableCollateral(address account) public view returns(uint256) {
        return getCollateralAmount(assignableTokens(account));
    }






    function currentCollateralizedTokens(address account) public view returns(uint256) {
        return tokenData[account].amount;
    }








    function unassignableTokens(address account) public view returns(uint256) {
        if (balanceOf(account) > tokenData[account].amount) {
            return tokenData[account].amount;
        } else {
            return balanceOf(account);
        }
    }








    function assignableTokens(address account) public view returns(uint256) {
        return _getAssignableAmount(account);
    }






    function getCollateralAmount(uint256 tokenAmount) public view returns(uint256) {
        if (isCall) {
            return tokenAmount;
        } else if (tokenAmount > 0) {
            return _getTokenStrikePriceRelation(tokenAmount);
        } else {
            return 0;
        }
    }






    function getTokenAmount(uint256 collateralAmount) public view returns(uint256) {
        if (isCall) {
            return collateralAmount;
        } else if (collateralAmount > 0) {
            return collateralAmount.mul(underlyingPrecision).div(strikePrice);
        } else {
            return 0;
        }
    }






    function getExerciseData(uint256 tokenAmount) public view returns(address, uint256) {
        if (isCall) {
            return (strikeAsset, _getTokenStrikePriceRelation(tokenAmount));
        } else {
            return (underlying, tokenAmount);
        }
    }






    function getCollateralOnExercise(uint256 tokenAmount) public view returns(uint256, uint256) {
        uint256 collateralAmount = getCollateralAmount(tokenAmount);
        uint256 fee = collateralAmount.mul(acoFee).div(100000);
        collateralAmount = collateralAmount.sub(fee);
        return (collateralAmount, fee);
    }





    function collateral() public view returns(address) {
        if (isCall) {
            return underlying;
        } else {
            return strikeAsset;
        }
    }





    function mintPayable() external payable {
        require(_isEther(collateral()), "ACOToken::mintPayable: Invalid call");
       _mintToken(msg.sender, msg.value);
    }







    function mintToPayable(address account) external payable {
        require(_isEther(collateral()), "ACOToken::mintToPayable: Invalid call");
       _mintToken(account, msg.value);
    }






    function mint(uint256 collateralAmount) external {
        address _collateral = collateral();
        require(!_isEther(_collateral), "ACOToken::mint: Invalid call");

        _transferFromERC20(_collateral, msg.sender, address(this), collateralAmount);
        _mintToken(msg.sender, collateralAmount);
    }








    function mintTo(address account, uint256 collateralAmount) external {
        address _collateral = collateral();
        require(!_isEther(_collateral), "ACOToken::mintTo: Invalid call");

        _transferFromERC20(_collateral, msg.sender, address(this), collateralAmount);
        _mintToken(account, collateralAmount);
    }






    function burn(uint256 tokenAmount) external {
        _burn(msg.sender, tokenAmount);
    }










    function burnFrom(address account, uint256 tokenAmount) external {
        _burn(account, tokenAmount);
    }





    function redeem() external {
        _redeem(msg.sender);
    }








    function redeemFrom(address account) external {
        require(tokenData[account].amount <= allowance(account, msg.sender), "ACOToken::redeemFrom: No allowance");
        _redeem(account);
    }







    function exercise(uint256 tokenAmount) external payable {
        _exercise(msg.sender, tokenAmount);
    }










    function exerciseFrom(address account, uint256 tokenAmount) external payable {
        _exercise(account, tokenAmount);
    }








    function exerciseAccounts(uint256 tokenAmount, address[] calldata accounts) external payable {
        _exerciseFromAccounts(msg.sender, tokenAmount, accounts);
    }











    function exerciseAccountsFrom(address account, uint256 tokenAmount, address[] calldata accounts) external payable {
        _exerciseFromAccounts(account, tokenAmount, accounts);
    }






    function clear() external {
        _clear(msg.sender);
    }








    function clearFrom(address account) external {
        _clear(account);
    }





    function _clear(address account) internal {
        require(!_notExpired(), "ACOToken::_clear: Token not expired yet");
        require(!_accountHasCollateral(account), "ACOToken::_clear: Must call the redeem method");

        _callBurn(account, balanceOf(account));
    }






    function _redeemCollateral(address account, uint256 tokenAmount) internal {
        require(_accountHasCollateral(account), "ACOToken::_redeemCollateral: No collateral available");
        require(tokenAmount > 0, "ACOToken::_redeemCollateral: Invalid token amount");

        TokenCollateralized storage data = tokenData[account];
        data.amount = data.amount.sub(tokenAmount);

        _removeCollateralDataIfNecessary(account);

        _transferCollateral(account, getCollateralAmount(tokenAmount), 0);
    }







    function _mintToken(address account, uint256 collateralAmount) nonReentrant notExpired internal {
        require(collateralAmount > 0, "ACOToken::_mintToken: Invalid collateral amount");

        if (!_accountHasCollateral(account)) {
            tokenData[account].index = _collateralOwners.length;
            _collateralOwners.push(account);
        }

        uint256 tokenAmount = getTokenAmount(collateralAmount);
        tokenData[account].amount = tokenData[account].amount.add(tokenAmount);

        totalCollateral = totalCollateral.add(collateralAmount);

        emit CollateralDeposit(account, collateralAmount);

        super._mintAction(msg.sender, tokenAmount);
    }








    function _transfer(address sender, address recipient, uint256 amount) notExpired internal override {
        super._transferAction(sender, recipient, amount);
    }








    function _approve(address owner, address spender, uint256 amount) notExpired internal override {
        super._approveAction(owner, spender, amount);
    }









    function _transferCollateral(address account, uint256 collateralAmount, uint256 fee) internal {

        totalCollateral = totalCollateral.sub(collateralAmount.add(fee));

        address _collateral = collateral();
        if (_isEther(_collateral)) {
            payable(msg.sender).transfer(collateralAmount);
            if (fee > 0) {
                feeDestination.transfer(fee);
            }
        } else {
            _transferERC20(_collateral, msg.sender, collateralAmount);
            if (fee > 0) {
                _transferERC20(_collateral, feeDestination, fee);
            }
        }

        emit CollateralWithdraw(account, msg.sender, collateralAmount, fee);
    }






    function _exercise(address account, uint256 tokenAmount) nonReentrant internal {
        _validateAndBurn(account, tokenAmount);
        _exerciseOwners(account, tokenAmount);
        (uint256 collateralAmount, uint256 fee) = getCollateralOnExercise(tokenAmount);
        _transferCollateral(account, collateralAmount, fee);
    }







    function _exerciseFromAccounts(address account, uint256 tokenAmount, address[] memory accounts) nonReentrant internal {
        _validateAndBurn(account, tokenAmount);
        _exerciseAccounts(account, tokenAmount, accounts);
        (uint256 collateralAmount, uint256 fee) = getCollateralOnExercise(tokenAmount);
        _transferCollateral(account, collateralAmount, fee);
    }






    function _exerciseOwners(address exerciseAccount, uint256 tokenAmount) internal {
        uint256 start = _collateralOwners.length - 1;
        for (uint256 i = start; i >= 0; --i) {
            if (tokenAmount == 0) {
                break;
            }
            tokenAmount = _exerciseAccount(_collateralOwners[i], tokenAmount, exerciseAccount);
        }
        require(tokenAmount == 0, "ACOToken::_exerciseOwners: Invalid remaining amount");
    }







    function _exerciseAccounts(address exerciseAccount, uint256 tokenAmount, address[] memory accounts) internal {
        for (uint256 i = 0; i < accounts.length; ++i) {
            if (tokenAmount == 0) {
                break;
            }
            tokenAmount = _exerciseAccount(accounts[i], tokenAmount, exerciseAccount);
        }
        require(tokenAmount == 0, "ACOToken::_exerciseAccounts: Invalid remaining amount");
    }








    function _exerciseAccount(address account, uint256 tokenAmount, address exerciseAccount) internal returns(uint256) {
        uint256 available = _getAssignableAmount(account);
        if (available > 0) {

            TokenCollateralized storage data = tokenData[account];
            uint256 valueToTransfer;
            if (available < tokenAmount) {
                valueToTransfer = available;
                tokenAmount = tokenAmount.sub(available);
            } else {
                valueToTransfer = tokenAmount;
                tokenAmount = 0;
            }

            (address exerciseAsset, uint256 amount) = getExerciseData(valueToTransfer);

            data.amount = data.amount.sub(valueToTransfer);

            _removeCollateralDataIfNecessary(account);

            if (_isEther(exerciseAsset)) {
                payable(account).transfer(amount);
            } else {
                _transferERC20(exerciseAsset, account, amount);
            }
            emit Assigned(account, exerciseAccount, amount, valueToTransfer);
        }

        return tokenAmount;
    }






    function _validateAndBurn(address account, uint256 tokenAmount) notExpired internal {
        require(tokenAmount > 0, "ACOToken::_validateAndBurn: Invalid token amount");


        if (_accountHasCollateral(account)) {

            require(balanceOf(account) > tokenData[account].amount, "ACOToken::_validateAndBurn: Tokens compromised");
            require(tokenAmount <= balanceOf(account).sub(tokenData[account].amount), "ACOToken::_validateAndBurn: Token amount not available");
        }

        _callBurn(account, tokenAmount);

        (address exerciseAsset, uint256 expectedAmount) = getExerciseData(tokenAmount);

        if (_isEther(exerciseAsset)) {
            require(msg.value == expectedAmount, "ACOToken::_validateAndBurn: Invalid ether amount");
        } else {
            require(msg.value == 0, "ACOToken::_validateAndBurn: No ether expected");
            _transferFromERC20(exerciseAsset, msg.sender, address(this), expectedAmount);
        }
    }






    function _getTokenStrikePriceRelation(uint256 tokenAmount) internal view returns(uint256) {
        return tokenAmount.mul(strikePrice).div(underlyingPrecision);
    }






    function _redeem(address account) nonReentrant internal {
        require(!_notExpired(), "ACOToken::_redeem: Token not expired yet");

        _redeemCollateral(account, tokenData[account].amount);
        super._burnAction(account, balanceOf(account));
    }






    function _burn(address account, uint256 tokenAmount) nonReentrant notExpired internal {
        _redeemCollateral(account, tokenAmount);
        _callBurn(account, tokenAmount);
    }






    function _callBurn(address account, uint256 tokenAmount) internal {
        if (account == msg.sender) {
            super._burnAction(account, tokenAmount);
        } else {
            super._burnFrom(account, tokenAmount);
        }
    }






    function _getAssignableAmount(address account) internal view returns(uint256) {
        if (tokenData[account].amount > balanceOf(account)) {
            return tokenData[account].amount.sub(balanceOf(account));
        } else {
            return 0;
        }
    }





    function _removeCollateralDataIfNecessary(address account) internal {
        TokenCollateralized storage data = tokenData[account];
        if (!_hasCollateral(data)) {
            uint256 lastIndex = _collateralOwners.length - 1;
            if (lastIndex != data.index) {
                address last = _collateralOwners[lastIndex];
                tokenData[last].index = data.index;
                _collateralOwners[data.index] = last;
            }
            _collateralOwners.pop();
            delete tokenData[account];
        }
    }





    function _notExpired() internal view returns(bool) {
        return now <= expiryTime;
    }






    function _accountHasCollateral(address account) internal view returns(bool) {
        return _hasCollateral(tokenData[account]);
    }






    function _hasCollateral(TokenCollateralized storage data) internal view returns(bool) {
        return data.amount > 0;
    }






    function _isEther(address _address) internal pure returns(bool) {
        return _address == address(0);
    }







    function _name() internal view returns(string memory) {
        return string(abi.encodePacked(
            "ACO ",
            underlyingSymbol,
            "-",
            _getFormattedStrikePrice(),
            strikeAssetSymbol,
            "-",
            _getType(),
            "-",
            _getFormattedExpiryTime()
        ));
    }





    function _getType() internal view returns(string memory) {
        if (isCall) {
            return "C";
        } else {
            return "P";
        }
    }





    function _getFormattedExpiryTime() internal view returns(string memory) {
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute,) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(expiryTime);
        return string(abi.encodePacked(
            _getNumberWithTwoCaracters(day),
            _getMonthFormatted(month),
            _getYearFormatted(year),
            "-",
            _getNumberWithTwoCaracters(hour),
            _getNumberWithTwoCaracters(minute),
            "UTC"
            ));
    }





    function _getYearFormatted(uint256 year) internal pure returns(string memory) {
        bytes memory yearBytes = bytes(Strings.toString(year));
        bytes memory result = new bytes(2);
        uint256 startIndex = yearBytes.length - 2;
        for (uint256 i = startIndex; i < yearBytes.length; i++) {
            result[i - startIndex] = yearBytes[i];
        }
        return string(result);
    }





    function _getMonthFormatted(uint256 month) internal pure returns(string memory) {
        if (month == 1) {
            return "JAN";
        } else if (month == 2) {
            return "FEB";
        } else if (month == 3) {
            return "MAR";
        } else if (month == 4) {
            return "APR";
        } else if (month == 5) {
            return "MAY";
        } else if (month == 6) {
            return "JUN";
        } else if (month == 7) {
            return "JUL";
        } else if (month == 8) {
            return "AUG";
        } else if (month == 9) {
            return "SEP";
        } else if (month == 10) {
            return "OCT";
        } else if (month == 11) {
            return "NOV";
        } else if (month == 12) {
            return "DEC";
        } else {
            return "INVALID";
        }
    }





    function _getNumberWithTwoCaracters(uint256 number) internal pure returns(string memory) {
        string memory _string = Strings.toString(number);
        if (number < 10) {
            return string(abi.encodePacked("0", _string));
        } else {
            return _string;
        }
    }





    function _getFormattedStrikePrice() internal view returns(string memory) {
        uint256 digits;
        uint256 count;
        int256 representativeAt = -1;
        uint256 addPointAt = 0;
        uint256 temp = strikePrice;
        uint256 number = strikePrice;
        while (temp != 0) {
            if (representativeAt == -1 && (temp % 10 != 0 || count == uint256(strikeAssetDecimals))) {
                representativeAt = int256(digits);
                number = temp;
            }
            if (representativeAt >= 0) {
                if (count == uint256(strikeAssetDecimals)) {
                    addPointAt = digits;
                }
                digits++;
            }
            temp /= 10;
            count++;
        }
        if (count <= uint256(strikeAssetDecimals)) {
            digits = digits + 2 + uint256(strikeAssetDecimals) - count;
            addPointAt = digits - 2;
        } else if (addPointAt > 0) {
            digits++;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = number;
        for (uint256 i = 0; i < digits; ++i) {
            if (i > 0 && i == addPointAt) {
                buffer[index--] = byte(".");
            } else if (number == 0) {
                buffer[index--] = byte("0");
            } else {

                if (representativeAt <= int256(i)) {
                    buffer[index--] = byte(uint8(48 + number % 10));
                }
                number /= 10;
            }
        }
        return string(buffer);
    }






    function _getAssetDecimals(address asset) internal view returns(uint8) {
        if (_isEther(asset)) {
            return uint8(18);
        } else {
            (bool success, bytes memory returndata) = asset.staticcall(abi.encodeWithSignature("decimals()"));
            require(success, "ACOToken::_getAssetDecimals: Invalid asset decimals");
            return abi.decode(returndata, (uint8));
        }
    }






    function _getAssetSymbol(address asset) internal view returns(string memory) {
        if (_isEther(asset)) {
            return "ETH";
        } else {
            (bool success, bytes memory returndata) = asset.staticcall(abi.encodeWithSignature("symbol()"));
            require(success, "ACOToken::_getAssetSymbol: Invalid asset symbol");
            return abi.decode(returndata, (string));
        }
    }







     function _transferERC20(address token, address recipient, uint256 amount) internal {
        (bool success, bytes memory returndata) = token.call(abi.encodeWithSelector(_transferSelector, recipient, amount));
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "ACOToken::_transferERC20");
    }








     function _transferFromERC20(address token, address sender, address recipient, uint256 amount) internal {
        (bool success, bytes memory returndata) = token.call(abi.encodeWithSelector(_transferFromSelector, sender, recipient, amount));
        require(success && (returndata.length == 0 || abi.decode(returndata, (bool))), "ACOToken::_transferFromERC20");
    }
}
