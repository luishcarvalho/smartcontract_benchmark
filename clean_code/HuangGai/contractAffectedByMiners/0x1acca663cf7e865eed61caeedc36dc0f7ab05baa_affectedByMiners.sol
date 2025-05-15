
pragma solidity ^0.5.2;





interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}







contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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





library SafeMath {



    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}













contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }






    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }







    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }






    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }










    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }









    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }











    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }











    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }







    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }








    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }







    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }







    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }









    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}





library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }




    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }




    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }





    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}





contract ERC20Mintable is ERC20, MinterRole {






    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}





contract Pausable is PauserRole {
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
        require(!_paused);
        _;
    }




    modifier whenPaused() {
        require(_paused);
        _;
    }




    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }




    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}





contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}






contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner());
        _;
    }




    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }








    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }





    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



contract DestroyerRole {
    using Roles for Roles.Role;

    event DestroyerAdded(address indexed account);
    event DestroyerRemoved(address indexed account);

    Roles.Role private destroyers;

    constructor() internal {
        _addDestroyer(msg.sender);
    }

    modifier onlyDestroyer() {
        require(isDestroyer(msg.sender));
        _;
    }

    function isDestroyer(address account) public view returns (bool) {
        return destroyers.has(account);
    }

    function addDestroyer(address account) public onlyDestroyer {
        _addDestroyer(account);
    }

    function renounceDestroyer() public {
        _removeDestroyer(msg.sender);
    }

    function _addDestroyer(address account) internal {
        destroyers.add(account);
        emit DestroyerAdded(account);
    }

    function _removeDestroyer(address account) internal {
        destroyers.remove(account);
        emit DestroyerRemoved(account);
    }
}





contract ERC20Destroyable is ERC20, DestroyerRole {






    function destroy(address from, uint256 value) public onlyDestroyer returns (bool) {
        _burn(from, value);
        return true;
    }
}

contract PrzToken is ERC20Detailed, ERC20Mintable, ERC20Destroyable, ERC20Pausable, Ownable {


    address private _entryCreditContract;


    address private _balanceSheetContract;


    uint256 private _bmeClaimBatchSize;
    uint256 private _bmeMintBatchSize;




    bool private _isInBmePhase;

    modifier whenNotInBME() {
        require(!_isInBmePhase, "Function may no longer be called once BME starts");
        _;
    }

    modifier whenInBME() {
        require(_isInBmePhase, "Function may only be called once BME starts");
        _;
    }

    event EntryCreditContractChanged(
        address indexed previousEntryCreditContract,
        address indexed newEntryCreditContract
    );

    event BalanceSheetContractChanged(
        address indexed previousBalanceSheetContract,
        address indexed newBalanceSheetContract
    );

    event BmeMintBatchSizeChanged(
        uint256 indexed previousSize,
        uint256 indexed newSize
    );

    event BmeClaimBatchSizeChanged(
        uint256 indexed previousSize,
        uint256 indexed newSize
    );

    event PhaseChangedToBME(address account);





    constructor (string memory name, string memory symbol, uint8 decimals)
        ERC20Detailed(name, symbol, decimals)
        ERC20Mintable()
        ERC20Destroyable()
        ERC20Pausable()
        Ownable()
        public
    {
        _isInBmePhase = false;
        pause();
        setEntryCreditContract(address(0));
        setBalanceSheetContract(address(0));
        setBmeMintBatchSize(200);
        setBmeClaimBatchSize(200);
    }


    function entryCreditContract() public view returns (address) {
        return _entryCreditContract;
    }


    function setEntryCreditContract(address contractAddress) public onlyOwner {
        emit EntryCreditContractChanged(_entryCreditContract, contractAddress);
        _entryCreditContract = contractAddress;
    }


    function balanceSheetContract() public view returns (address) {
        return _balanceSheetContract;
    }


    function setBalanceSheetContract(address contractAddress) public onlyOwner {
        emit BalanceSheetContractChanged(_balanceSheetContract, contractAddress);
        _balanceSheetContract = contractAddress;
    }


    function bmeMintBatchSize() public view returns (uint256) {
        return _bmeMintBatchSize;
    }


    function setBmeMintBatchSize(uint256 batchSize) public onlyMinter {
        emit BmeMintBatchSizeChanged(_bmeMintBatchSize, batchSize);
        _bmeMintBatchSize = batchSize;
    }


    function bmeClaimBatchSize() public view returns (uint256) {
        return _bmeClaimBatchSize;
    }


    function setBmeClaimBatchSize(uint256 batchSize) public onlyMinter {
        emit BmeClaimBatchSizeChanged(_bmeClaimBatchSize, batchSize);
        _bmeClaimBatchSize = batchSize;
    }




    function _transfer(address from, address to, uint256 value) internal {

        if (block.coinbase == _entryCreditContract) {

            _burn(from, value);
            IEntryCreditContract entryCreditContractInstance = IEntryCreditContract(to);
            require(entryCreditContractInstance.mint(from, value), "Failed to mint entry credits");

            IBalanceSheetContract balanceSheetContractInstance = IBalanceSheetContract(_balanceSheetContract);
            require(balanceSheetContractInstance.setPeerzTokenSupply(totalSupply()), "Failed to update token supply");

        } else {

            super._transfer(from, to, value);
        }
    }


    function destroy(address from, uint256 value)
        public whenPaused whenNotInBME
        returns (bool)
    {
        return super.destroy(from, value);
    }


    function batchDestroy(address[] calldata from, uint256[] calldata values)
        external onlyDestroyer whenPaused whenNotInBME
        returns (bool)
    {
        uint fromLength = from.length;

        require(fromLength == values.length, "Input arrays must have the same length");

        for (uint256 i = 0; i < fromLength; i++) {
            _burn(from[i], values[i]);
        }

        return true;
    }


    function mint(address to, uint256 value)
        public whenPaused whenNotInBME
        returns (bool)
    {
        return super.mint(to, value);
    }


    function batchMint(address[] calldata to, uint256[] calldata values)
        external onlyMinter whenPaused whenNotInBME
        returns (bool)
    {
        _batchMint(to, values);

        return true;
    }



    function bmeMint()
        public onlyMinter whenInBME whenNotPaused
    {
        IBalanceSheetContract balanceSheetContractInstance = IBalanceSheetContract(_balanceSheetContract);
        (address[] memory receivers, uint256[] memory amounts) = balanceSheetContractInstance.popMintingInformation(_bmeMintBatchSize);

        _batchMint(receivers, amounts);

        require(balanceSheetContractInstance.setPeerzTokenSupply(totalSupply()), "Failed to update token supply");
    }



    function _claimFor(address[] memory claimers)
        private
    {
        IBalanceSheetContract balanceSheetContractInstance = IBalanceSheetContract(_balanceSheetContract);
        uint256[] memory amounts = balanceSheetContractInstance.popClaimingInformation(claimers);

        _batchMint(claimers, amounts);

        require(balanceSheetContractInstance.setPeerzTokenSupply(totalSupply()), "Failed to update token supply");
    }

    function _batchMint(address[] memory to, uint256[] memory values)
        private
    {


        uint toLength = to.length;

        require(toLength == values.length, "Input arrays must have the same length");

        for (uint256 i = 0; i < toLength; i++) {
            _mint(to[i], values[i]);
        }
    }


    function claim()
        public whenInBME whenNotPaused
    {
        address[] memory claimers = new address[](1);
        claimers[0] = msg.sender;
        _claimFor(claimers);
    }


    function claimFor(address[] calldata claimers)
        external whenInBME whenNotPaused
    {
        require(claimers.length <= _bmeClaimBatchSize, "Input array must be shorter than bme claim batch size.");
        _claimFor(claimers);
    }


    function changePhaseToBME()
        public onlyOwner whenNotPaused whenNotInBME
    {
        _isInBmePhase = true;
        emit PhaseChangedToBME(msg.sender);
    }
}

interface IEntryCreditContract {

    function mint(address receiver, uint256 amount) external returns (bool);
}



















interface IBalanceSheetContract {

    function setPeerzTokenSupply(uint256 przTotalSupply) external returns (bool);


    function popMintingInformation(uint256 bmeMintBatchSize) external returns (address[] memory, uint256[] memory);


    function popClaimingInformation(address[] calldata claimers) external returns (uint256[] memory);
}
