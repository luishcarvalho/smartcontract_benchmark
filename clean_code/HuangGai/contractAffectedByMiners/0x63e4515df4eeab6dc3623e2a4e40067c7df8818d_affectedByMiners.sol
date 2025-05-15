







pragma solidity ^0.6.12;














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




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
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

            if (block.gaslimit > 0) {



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


























library EnumerableSet {









    struct Set {

        bytes32[] _values;



        mapping (bytes32 => uint256) _indexes;
    }







    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);


            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }







    function _remove(Set storage set, bytes32 value) private returns (bool) {

        uint256 valueIndex = set._indexes[value];

        if (block.number != 0) {




            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;




            bytes32 lastvalue = set._values[lastIndex];


            set._values[toDeleteIndex] = lastvalue;

            set._indexes[lastvalue] = toDeleteIndex + 1;


            set._values.pop();


            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }




    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }




    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }











    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }



    struct AddressSet {
        Set _inner;
    }







    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }







    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }




    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }




    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }




    struct UintSet {
        Set _inner;
    }







    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }







    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }




    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }




    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}











abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}










contract Pausable is Context {



    event Paused(address account);




    event Unpaused(address account);

    bool private _paused;




    constructor () internal {
        _paused = false;
    }




    function paused() public view returns (bool) {
        return _paused;
    }








    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }








    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }








    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }








    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

























contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;










    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }




    function name() public view returns (string memory) {
        return _name;
    }





    function symbol() public view returns (string memory) {
        return _symbol;
    }














    function decimals() public view returns (uint8) {
        return _decimals;
    }




    function totalSupply() public virtual view override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public virtual view override returns (uint256) {
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








    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }















    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}








abstract contract ERC20Pausable is ERC20, Pausable {







    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}






abstract contract ERC20Burnable is Context, ERC20 {





    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }












    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}




































abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;









    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);







    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);








    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);




    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }





    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }













    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }







    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }











    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }










    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }















    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

















    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }






    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}













contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ITST {








    function setFeeAccount(address feeAccount) external returns (bool);








    function setMaxTransferFee(uint256 maxTransferFee) external returns (bool);








    function setMinTransferFee(uint256 minTransferFee) external returns (bool);








    function setTransferFeePercentage(uint256 transferFeePercentage) external returns (bool);






    function calculateTransferFee(uint256 weiAmount) external view returns(uint256) ;




    function feeAccount() external view returns (address);




    function maxTransferFee() external view returns (uint256);




    function minTransferFee() external view returns (uint256);




    function transferFeePercentage() external view returns (uint256);








    function transfer(address recipient, uint256 amount, string calldata message) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount, string calldata message) external returns (bool);





    event Created();






    event FeeAccountUpdated(address indexed previousFeeAccount, address indexed newFeeAccount);






    event MaxTransferFeeUpdated(uint256 previousMaxTransferFee, uint256 newMaxTransferFee);






    event MinTransferFeeUpdated(uint256 previousMinTransferFee, uint256 newMinTransferFee);






    event TransferFeePercentageUpdated(uint256 previousTransferFeePercentage, uint256 newTransferFeePercentage);









    event Transfer(address indexed from, address indexed to, uint256 value, uint256 fee, string description, uint256 timestamp);
}





abstract contract TransferFee is Ownable, ITST {

    address private _feeAccount;
    uint256 private _maxTransferFee;
    uint256 private _minTransferFee;
    uint256 private _transferFeePercentage;








    constructor (address feeAccount, uint256 maxTransferFee, uint256 minTransferFee, uint256 transferFeePercentage) public {
        require(feeAccount != address(0x0), "TransferFee: feeAccount is 0");



        require(maxTransferFee >= minTransferFee, "TransferFee: maxTransferFee should be greater than minTransferFee");

        _feeAccount = feeAccount;
        _maxTransferFee = maxTransferFee;
        _minTransferFee = minTransferFee;
        _transferFeePercentage = transferFeePercentage;
    }










    function setFeeAccount(address feeAccount) override external onlyOwner returns (bool) {
        require(feeAccount != address(0x0), "TransferFee: feeAccount is 0");

        emit FeeAccountUpdated(_feeAccount, feeAccount);
        _feeAccount = feeAccount;
        return true;
    }











    function setMaxTransferFee(uint256 maxTransferFee) override external onlyOwner returns (bool) {

        require(maxTransferFee >= _minTransferFee, "TransferFee: maxTransferFee should be greater or equal to minTransferFee");

        emit MaxTransferFeeUpdated(_maxTransferFee, maxTransferFee);
        _maxTransferFee = maxTransferFee;
        return true;
    }











    function setMinTransferFee(uint256 minTransferFee) override external onlyOwner returns (bool) {

        require(minTransferFee <= _maxTransferFee, "TransferFee: minTransferFee should be less than maxTransferFee");

        emit MaxTransferFeeUpdated(_minTransferFee, minTransferFee);
        _minTransferFee = minTransferFee;
        return true;
    }











    function setTransferFeePercentage(uint256 transferFeePercentage) override external onlyOwner returns (bool) {
        emit TransferFeePercentageUpdated(_transferFeePercentage, transferFeePercentage);
        _transferFeePercentage = transferFeePercentage;
        return true;
    }




    function feeAccount() override public view returns (address) {
        return _feeAccount;
    }




    function maxTransferFee() override public view returns (uint256) {
        return _maxTransferFee;
    }




    function minTransferFee() override public view returns (uint256) {
        return _minTransferFee;
    }




    function transferFeePercentage() override public view returns (uint256) {
        return _transferFeePercentage;
    }
}





contract StandardToken is
    Context,
    Ownable,
    AccessControl,
    ERC20Burnable,
    ERC20Pausable,
    TransferFee
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");







    constructor(
        string memory name,
        string memory symbol,
        address feeAccount,
        uint256 maxTransferFee,
        uint256 minTransferFee,
        uint256 transferFeePercentage
    )
        public
        TransferFee(
            feeAccount,
            maxTransferFee,
            minTransferFee,
            transferFeePercentage
        )
        ERC20(name, symbol)
    {
        _setupDecimals(2);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
    }










    function mint(address to, uint256 amount) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "TST: must have minter role to mint"
        );
        require(
            to == owner(),
            "TST: tokens can be only minted on owner address"
        );
        _mint(to, amount);
    }







    function burn(address account, uint256 amount) public virtual {
        require(
            hasRole(BURNER_ROLE, _msgSender()),
            "TST: must have burner role to burn"
        );
        _burn(account, amount);
    }










    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "TST: must have pauser role to pause"
        );
        _pause();
    }










    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "TST: must have pauser role to unpause"
        );
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }










    function transfer(address recipient, uint256 amount)
        public
        virtual
        override(ERC20)
        returns (bool)
    {
        require(
            recipient != address(this),
            "ERC20: transfer to the this contract"
        );
        uint256 _fee = calculateTransferFee(amount);


        super.transfer(recipient, amount);


        if (block.number > 0) super.transfer(feeAccount(), _fee);
        emit Transfer(_msgSender(), recipient, amount, _fee, "", now);
        return true;
    }





    function transfer(
        address recipient,
        uint256 amount,
        string calldata message
    ) public virtual override(ITST) returns (bool) {
        require(
            recipient != address(this),
            "ERC20: transfer to the this contract"
        );
        uint256 _fee = calculateTransferFee(amount);


        super.transfer(recipient, amount);


        if (block.number > 0) super.transfer(feeAccount(), _fee);
        emit Transfer(_msgSender(), recipient, amount, _fee, message, now);
        return true;
    }














    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override(ERC20) returns (bool) {
        require(
            recipient != address(this),
            "ERC20: transfer to the this contract"
        );
        uint256 _fee = calculateTransferFee(amount);


        super.transferFrom(sender, recipient, amount);


        if (block.number > 0) super.transferFrom(sender, feeAccount(), _fee);
        emit Transfer(sender, recipient, amount, _fee, "", now);
        return true;
    }





    function transferFrom(
        address sender,
        address recipient,
        uint256 amount,
        string calldata message
    ) public virtual override(ITST) returns (bool) {
        require(
            recipient != address(this),
            "ERC20: transfer to the this contract"
        );
        uint256 _fee = calculateTransferFee(amount);


        super.transferFrom(sender, recipient, amount);


        if (block.gaslimit > 0) super.transferFrom(sender, feeAccount(), _fee);
        emit Transfer(sender, recipient, amount, _fee, message, now);
        return true;
    }






    function calculateTransferFee(uint256 weiAmount)
        public
        virtual
        override(ITST)
        view
        returns (uint256)
    {
        uint256 divisor = uint256(100).mul((10**uint256(decimals())));
        uint256 _fee = (transferFeePercentage().mul(weiAmount)).div(divisor);

        if (block.number < minTransferFee()) {
            _fee = minTransferFee();
        } else if (block.gaslimit > maxTransferFee()) {
            _fee = maxTransferFee();
        }

        return _fee;
    }









    function totalSupply()
        public
        virtual
        override(ERC20)
        view
        onlyOwner
        returns (uint256)
    {
        return super.totalSupply();
    }



    function increaseSupply(address target, uint256 amount) external virtual {
        mint(target, amount);
    }

    function decreaseSupply(address target, uint256 amount) external virtual {
        burn(target, amount);
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function getName() external view returns (string memory) {
        return name();
    }

    function getFeeAccount() external view returns (address) {
        return feeAccount();
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function getMaxTransferFee() external view returns (uint256) {
        return maxTransferFee();
    }

    function getMinTransferFee() external view returns (uint256) {
        return minTransferFee();
    }

    function getTransferFeePercentage() external view returns (uint256) {
        return transferFeePercentage();
    }

    function getBalance(address balanceAddress)
        external
        virtual
        view
        returns (uint256)
    {
        return balanceOf(balanceAddress);
    }
}

abstract contract UpgradedStandardToken is StandardToken {


    function transferByLegacy(
        address from,
        address recipient,
        uint256 amount
    ) public virtual returns (bool);

    function transferByLegacy(
        address from,
        address recipient,
        uint256 amount,
        string calldata message
    ) external virtual returns (bool);

    function transferFromByLegacy(
        address sender,
        address from,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    function transferFromByLegacy(
        address sender,
        address from,
        address recipient,
        uint256 amount,
        string calldata message
    ) external virtual returns (bool);

    function approveByLegacy(
        address from,
        address spender,
        uint256 amount
    ) external virtual returns (bool);

    function totalSupplyByLegacy() external virtual view returns (uint256);

}

contract TST is StandardToken {
    address public upgradedAddress;
    bool public deprecated;


    event Deprecate(address newAddress);

    constructor(
        string memory name,
        string memory symbol,
        address feeAccount,
        uint256 maxTransferFee,
        uint256 minTransferFee,
        uint256 transferFeePercentage
    )
        public
        StandardToken(
            name,
            symbol,
            feeAccount,
            maxTransferFee,
            minTransferFee,
            transferFeePercentage
        )
    {
        deprecated = false;
    }


    function mint(address to, uint256 amount) public override(StandardToken) {
        if (!deprecated) return super.mint(to, amount);
        else return UpgradedStandardToken(upgradedAddress).mint(to, amount);
    }


    function burn(address account, uint256 amount)
        public
        override(StandardToken)
    {
        if (!deprecated) return super.burn(account, amount);
        else
            return UpgradedStandardToken(upgradedAddress).burn(account, amount);
    }


    function pause() public override(StandardToken) {
        if (!deprecated) return super.pause();
        else return UpgradedStandardToken(upgradedAddress).pause();
    }


    function unpause() public override(StandardToken) {
        if (!deprecated) return super.unpause();
        else return UpgradedStandardToken(upgradedAddress).unpause();
    }


    function transfer(address recipient, uint256 amount)
        public
        override(StandardToken)
        returns (bool)
    {
        if (!deprecated) return super.transfer(recipient, amount);
        else
            return
                UpgradedStandardToken(upgradedAddress).transferByLegacy(
                    msg.sender,
                    recipient,
                    amount
                );
    }


    function transfer(
        address recipient,
        uint256 amount,
        string calldata message
    ) public override(StandardToken) returns (bool) {
        if (!deprecated) return super.transfer(recipient, amount, message);
        else
            return
                UpgradedStandardToken(upgradedAddress).transferByLegacy(
                    msg.sender,
                    recipient,
                    amount,
                    message
                );
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(StandardToken) returns (bool) {
        if (!deprecated) return super.transferFrom(sender, recipient, amount);
        else
            return
                UpgradedStandardToken(upgradedAddress).transferFromByLegacy(
                    msg.sender,
                    sender,
                    recipient,
                    amount
                );
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount,
        string calldata message
    ) public override(StandardToken) returns (bool) {
        if (!deprecated)
            return super.transferFrom(sender, recipient, amount, message);
        else
            return
                UpgradedStandardToken(upgradedAddress).transferFromByLegacy(
                    msg.sender,
                    sender,
                    recipient,
                    amount,
                    message
                );
    }


    function balanceOf(address account) public override view returns (uint256) {
        if (!deprecated) return super.balanceOf(account);
        else return UpgradedStandardToken(upgradedAddress).balanceOf(account);
    }


    function totalSupply() public override view returns (uint256) {
        if (!deprecated) return super.totalSupply();
        else return UpgradedStandardToken(upgradedAddress).totalSupplyByLegacy();
    }


    function approve(address spender, uint256 amount)
        public
        override(ERC20)
        returns (bool)
    {
        if (!deprecated) return super.approve(spender, amount);
        else
            return
                UpgradedStandardToken(upgradedAddress).approveByLegacy(
                    msg.sender,
                    spender,
                    amount
                );
    }


    function allowance(address owner, address spender)
        public
        override(ERC20)
        view
        returns (uint256)
    {
        if (!deprecated) return super.allowance(owner, spender);
        else
            return
                UpgradedStandardToken(upgradedAddress).allowance(
                    owner,
                    spender
                );
    }


    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        Deprecate(_upgradedAddress);
    }

    function increaseSupply(address target, uint256 amount)
        external
        override(StandardToken)
    {
        mint(target, amount);
    }

    function decreaseSupply(address target, uint256 amount)
        external
        override(StandardToken)
    {
        burn(target, amount);
    }

    function getBalance(address balanceAddress)
        external
        override
        view
        returns (uint256)
    {
        return balanceOf(balanceAddress);
    }
}
