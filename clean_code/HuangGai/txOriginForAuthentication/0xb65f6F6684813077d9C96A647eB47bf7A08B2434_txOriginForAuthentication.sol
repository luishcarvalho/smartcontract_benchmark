











pragma solidity 0.6.10;







contract ProxyStorage {
    address public owner;
    address public pendingOwner;

    bool initialized;

    address balances_Deprecated;
    address allowances_Deprecated;

    uint256 _totalSupply;

    bool private paused_Deprecated = false;
    address private globalPause_Deprecated;

    uint256 public burnMin = 0;
    uint256 public burnMax = 0;

    address registry_Deprecated;

    string name_Deprecated;
    string symbol_Deprecated;

    uint256[] gasRefundPool_Deprecated;
    uint256 private redemptionAddressCount_Deprecated;
    uint256 minimumGasPriceForFutureRefunds_Deprecated;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(bytes32 => mapping(address => uint256)) attributes_Deprecated;


    mapping(address => address) finOps_Deprecated;
    mapping(address => mapping(address => uint256)) finOpBalances_Deprecated;
    mapping(address => uint256) finOpSupply_Deprecated;



    struct RewardAllocation {
        uint256 proportion;
        address finOp;
    }
    mapping(address => RewardAllocation[]) _rewardDistribution_Deprecated;
    uint256 maxRewardProportion_Deprecated = 1000;

    mapping(address => bool) isBlacklisted;
    mapping(address => bool) public canBurn;


















}

pragma solidity 0.6.10;







contract ClaimableOwnable is ProxyStorage {





    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }




    modifier onlyOwner() {
        require(tx.origin == owner, "only Owner");

        _;
    }




    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "only pending owner");
        _;
    }





    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }




    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

pragma solidity ^0.6.0;




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

pragma solidity ^0.6.0;











abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

pragma solidity ^0.6.0;














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

pragma solidity ^0.6.2;




library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}














pragma solidity 0.6.10;

























abstract contract ERC20 is ClaimableOwnable, Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;




    function name() public virtual pure returns (string memory);





    function symbol() public virtual pure returns (string memory);














    function decimals() public virtual pure returns (uint8) {
        return 18;
    }




    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
















    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity 0.6.10;






abstract contract ReclaimerToken is ERC20 {




    function reclaimEther(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }







    function reclaimToken(IERC20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_to, balance);
    }
}

pragma solidity 0.6.10;







abstract contract BurnableTokenWithBounds is ReclaimerToken {





    event Burn(address indexed burner, uint256 value);







    event SetBurnBounds(uint256 newMin, uint256 newMax);














    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }











    function setBurnBounds(uint256 _min, uint256 _max) external onlyOwner {
        require(_min <= _max, "BurnableTokenWithBounds: min > max");
        burnMin = _min;
        burnMax = _max;
        emit SetBurnBounds(_min, _max);
    }










    function _burn(address account, uint256 amount) internal virtual override {
        require(amount >= burnMin, "BurnableTokenWithBounds: below min burn bound");
        require(amount <= burnMax, "BurnableTokenWithBounds: exceeds max burn bound");

        super._burn(account, amount);
        emit Burn(account, amount);
    }
}

pragma solidity 0.6.10;




































abstract contract TrueCurrency is BurnableTokenWithBounds {
    uint256 constant CENT = 10**16;
    uint256 constant REDEMPTION_ADDRESS_COUNT = 0x100000;




    event Blacklisted(address indexed account, bool isBlacklisted);






    event Mint(address indexed to, uint256 value);















    function mint(address account, uint256 amount) external onlyOwner {
        require(!isBlacklisted[account], "TrueCurrency: account is blacklisted");
        require(!isRedemptionAddress(account), "TrueCurrency: account is a redemption address");
        _mint(account, amount);
        emit Mint(account, amount);
    }










    function setBlacklisted(address account, bool _isBlacklisted) external onlyOwner {
        require(uint256(account) >= REDEMPTION_ADDRESS_COUNT, "TrueCurrency: blacklisting of redemption address is not allowed");
        isBlacklisted[account] = _isBlacklisted;
        emit Blacklisted(account, _isBlacklisted);
    }










    function setCanBurn(address account, bool _canBurn) external onlyOwner {
        canBurn[account] = _canBurn;
    }









    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(!isBlacklisted[sender], "TrueCurrency: sender is blacklisted");
        require(!isBlacklisted[recipient], "TrueCurrency: recipient is blacklisted");

        if (isRedemptionAddress(recipient)) {
            super._transfer(sender, recipient, amount.sub(amount.mod(CENT)));
            _burn(recipient, amount.sub(amount.mod(CENT)));
        } else {
            super._transfer(sender, recipient, amount);
        }
    }







    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(!isBlacklisted[owner], "TrueCurrency: tokens owner is blacklisted");
        require(!isBlacklisted[spender] || amount == 0, "TrueCurrency: tokens spender is blacklisted");

        super._approve(owner, spender, amount);
    }






    function _burn(address account, uint256 amount) internal override {
        require(canBurn[account], "TrueCurrency: cannot burn from this address");
        super._burn(account, amount);
    }












    function isRedemptionAddress(address account) internal pure returns (bool) {
        return uint256(account) < REDEMPTION_ADDRESS_COUNT && uint256(account) != 0;
    }
}

pragma solidity 0.6.10;















abstract contract DelegateERC20 is TrueCurrency {
    address constant DELEGATE_FROM = 0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;


    modifier onlyDelegateFrom() virtual {
        require(msg.sender == DELEGATE_FROM);
        _;
    }





    function delegateTotalSupply() public view returns (uint256) {
        return totalSupply();
    }






    function delegateBalanceOf(address who) public view returns (uint256) {
        return balanceOf(who);
    }








    function delegateTransfer(
        address to,
        uint256 value,
        address origSender
    ) public onlyDelegateFrom returns (bool) {
        _transfer(origSender, to, value);
        emit Transfer(origSender, to, value);
        return true;
    }







    function delegateAllowance(address owner, address spender) public view returns (uint256) {
        return allowance(owner, spender);
    }









    function delegateTransferFrom(
        address from,
        address to,
        uint256 value,
        address origSender
    ) public onlyDelegateFrom returns (bool) {

        _transfer(from, to, value);
        _approve(from, origSender, _allowances[from][origSender].sub(value, "ERC20: transfer amount exceeds allowance"));
        return true;
    }








    function delegateApprove(
        address spender,
        uint256 value,
        address origSender
    ) public onlyDelegateFrom returns (bool) {
        _approve(origSender, spender, value);
        return true;
    }








    function delegateIncreaseApproval(
        address spender,
        uint256 addedValue,
        address origSender
    ) public onlyDelegateFrom returns (bool) {

        _approve(origSender, spender, _allowances[origSender][spender].add(addedValue));
        return true;
    }








    function delegateDecreaseApproval(
        address spender,
        uint256 subtractedValue,
        address origSender
    ) public onlyDelegateFrom returns (bool) {

        _approve(origSender, spender, _allowances[origSender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
}

pragma solidity 0.6.10;

















abstract contract TrueCurrencyWithLegacyAutosweep is DelegateERC20 {
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        requireNotAutosweepAddress(recipient, 0x33091DE8341533468D13A80C5A670f4f47cC649f);
        requireNotAutosweepAddress(recipient, 0x50E2719208914764087e68C32bC5AaC321f5B04d);
        requireNotAutosweepAddress(recipient, 0x71d69e5481A9B7Be515E20B38a3f62Dab7170D78);
        requireNotAutosweepAddress(recipient, 0x90fdaA85D52dB6065D466B86f16bF840D514a488);

        super._transfer(sender, recipient, amount);
    }

    function requireNotAutosweepAddress(address recipient, address depositAddress) internal pure {
        return
            require(uint256(recipient) >> 20 != uint256(depositAddress) >> 20 || recipient == depositAddress, "Autosweep is disabled");
    }
}

pragma solidity 0.6.10;






contract TrueUSD is TrueCurrencyWithLegacyAutosweep {
    uint8 constant DECIMALS = 18;
    uint8 constant ROUNDING = 2;

    function decimals() public override pure returns (uint8) {
        return DECIMALS;
    }

    function rounding() public pure returns (uint8) {
        return ROUNDING;
    }

    function name() public override pure returns (string memory) {
        return "TrueUSD";
    }

    function symbol() public override pure returns (string memory) {
        return "TUSD";
    }
}
