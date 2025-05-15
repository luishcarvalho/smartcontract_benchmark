



pragma solidity 0.5.11;








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

library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c ;

        require(c >= a, "SafeMath: addition overflow");

        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }












    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c ;


        return c;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c ;

        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }














    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c ;



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




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }







    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract Initializable {




  bool private initialized;




  bool private initializing;




  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall ;

    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }


  function isConstructor() private view returns (bool) {





    address self ;

    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }


  uint256[50] private ______gap;
}

contract Governable {

    bytes32
        private constant governorPosition = 0x7bea13895fa79d2831e0a9e28edede30099005a50d652d8957cf8a607ee6ca4a;


    bytes32
        private constant pendingGovernorPosition = 0x44c4d30b2eaad5130ad70c3ba6972730566f3e6359ab83e800d905c61b1c51db;


    event PendingGovernorshipTransfer(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    event GovernorshipTransferred(
        address indexed previousGovernor,
        address indexed newGovernor
    );




    constructor() internal {
        _setGovernor(msg.sender);
        emit GovernorshipTransferred(address(0), _governor());
    }




    function governor() public view returns (address) {
        return _governor();
    }

    function _governor() internal view returns (address governorOut) {
        bytes32 position ;

        assembly {
            governorOut := sload(position)
        }
    }

    function _pendingGovernor()
        internal
        view
        returns (address pendingGovernor)
    {
        bytes32 position ;

        assembly {
            pendingGovernor := sload(position)
        }
    }




    modifier onlyGovernor() {
        require(isGovernor(), "Caller is not the Governor");
        _;
    }




    function isGovernor() public view returns (bool) {
        return msg.sender == _governor();
    }

    function _setGovernor(address newGovernor) internal {
        bytes32 position ;

        assembly {
            sstore(position, newGovernor)
        }
    }

    function _setPendingGovernor(address newGovernor) internal {
        bytes32 position ;

        assembly {
            sstore(position, newGovernor)
        }
    }






    function transferGovernance(address _newGovernor) external onlyGovernor {
        _setPendingGovernor(_newGovernor);
        emit PendingGovernorshipTransfer(_governor(), _newGovernor);
    }





    function claimGovernance() external {
        require(
            msg.sender == _pendingGovernor(),
            "Only the pending Governor can complete the claim"
        );
        _changeGovernor(msg.sender);
    }





    function _changeGovernor(address _newGovernor) internal {
        require(_newGovernor != address(0), "New Governor is address(0)");
        emit GovernorshipTransferred(_governor(), _newGovernor);
        _setGovernor(_newGovernor);
    }
}

contract InitializableERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;







    function _initialize(
        string memory nameArg,
        string memory symbolArg,
        uint8 decimalsArg
    ) internal {
        _name = nameArg;
        _symbol = symbolArg;
        _decimals = decimalsArg;
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
}

contract InitializableToken is ERC20, InitializableERC20Detailed {




    function _initialize(string memory _nameArg, string memory _symbolArg)
        internal
    {
        InitializableERC20Detailed._initialize(_nameArg, _symbolArg, 18);
    }
}

contract OUSD is Initializable, InitializableToken, Governable {
    using SafeMath for uint256;
    using StableMath for uint256;

    event TotalSupplyUpdated(
        uint256 totalSupply,
        uint256 totalCredits,
        uint256 creditsPerToken
    );

    uint256 private constant MAX_SUPPLY = ~uint128(0);

    uint256 private _totalSupply;
    uint256 private totalCredits;

    uint256 private creditsPerToken;

    mapping(address => uint256) private _creditBalances;


    mapping(address => mapping(address => uint256)) private _allowances;

    address public vaultAddress ;


    function initialize(
        string calldata _nameArg,
        string calldata _symbolArg,
        address _vaultAddress
    ) external onlyGovernor initializer {
        InitializableToken._initialize(_nameArg, _symbolArg);

        _totalSupply = 0;
        totalCredits = 0;
        creditsPerToken = 1e18;

        vaultAddress = _vaultAddress;
    }




    modifier onlyVault() {
        require(vaultAddress == msg.sender, "Caller is not the Vault");
        _;
    }




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }







    function balanceOf(address _account) public view returns (uint256) {
        if (creditsPerToken == 0) return 0;
        return _creditBalances[_account].divPrecisely(creditsPerToken);
    }







    function creditsBalanceOf(address _account) public view returns (uint256) {
        return _creditBalances[_account];
    }







    function transfer(address _to, uint256 _value) public returns (bool) {
        uint256 creditValue ;

        _creditBalances[_to] = _creditBalances[_to].add(creditValue);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }







    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(
            _value
        );

        uint256 creditValue ;

        _creditBalances[_to] = _creditBalances[_to].add(creditValue);

        emit Transfer(_from, _to, _value);

        return true;
    }







    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }












    function approve(address _spender, uint256 _value) public returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }








    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        returns (bool)
    {
        _allowances[msg.sender][_spender] = _allowances[msg.sender][_spender]
            .add(_addedValue);
        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
        return true;
    }






    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue ;

        if (_subtractedValue >= oldValue) {
            _allowances[msg.sender][_spender] = 0;
        } else {
            _allowances[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
        return true;
    }




    function mint(address _account, uint256 _amount) external onlyVault {
        return _mint(_account, _amount);
    }











    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "Mint to the zero address");

        _totalSupply = _totalSupply.add(_amount);

        uint256 creditAmount ;

        _creditBalances[_account] = _creditBalances[_account].add(creditAmount);
        totalCredits = totalCredits.add(creditAmount);

        emit Transfer(address(0), _account, _amount);
    }




    function burn(address account, uint256 amount) external onlyVault {
        return _burn(account, amount);
    }












    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "Burn from the zero address");

        _totalSupply = _totalSupply.sub(_amount);
        uint256 creditAmount ;

        totalCredits = totalCredits.sub(creditAmount);

        emit Transfer(_account, address(0), _amount);
    }







    function _removeCredits(address _account, uint256 _amount)
        internal
        returns (uint256 creditAmount)
    {
        creditAmount = _amount.mulTruncate(creditsPerToken);
        uint256 currentCredits ;

        if (
            currentCredits == creditAmount || currentCredits - 1 == creditAmount
        ) {
            _creditBalances[_account] = 0;
        } else if (currentCredits > creditAmount) {
            _creditBalances[_account] = currentCredits - creditAmount;
        } else {
            revert("Remove exceeds balance");
        }
    }







    function changeSupply(uint256 _newTotalSupply)
        external
        onlyVault
        returns (uint256)
    {
        require(_totalSupply > 0, "Cannot increase 0 supply");

        if (_totalSupply == _newTotalSupply) {
            emit TotalSupplyUpdated(
                _totalSupply,
                totalCredits,
                creditsPerToken
            );
            return _totalSupply;
        }

        _totalSupply = _newTotalSupply;

        if (_totalSupply > MAX_SUPPLY) _totalSupply = MAX_SUPPLY;

        creditsPerToken = totalCredits.divPrecisely(_totalSupply);

        emit TotalSupplyUpdated(_totalSupply, totalCredits, creditsPerToken);
        return _totalSupply;
    }
}

library StableMath {
    using SafeMath for uint256;





    uint256 private constant FULL_SCALE = 1e18;









    function scaleBy(uint256 x, int8 adjustment)
        internal
        pure
        returns (uint256)
    {
        if (adjustment > 0) {
            x = x.mul(10**uint256(adjustment));
        } else if (adjustment < 0) {
            x = x.div(10**uint256(adjustment * -1));
        }
        return x;
    }












    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }










    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {


        uint256 z ;


        return z.div(scale);
    }








    function mulTruncateCeil(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {

        uint256 scaled ;


        uint256 ceil ;


        return ceil.div(FULL_SCALE);
    }









    function divPrecisely(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {

        uint256 z ;


        return z.div(y);
    }
}
