





pragma solidity 0.6.0;











abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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


interface TokenInterface {
    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract Liquidity is Ownable {
    address public DEX;
    string[] public allLiquidities;
    mapping(string => address) public contractAddress;

    event DEXUpdated(address oldDEX, address newDEX);
    event TokenUpdated(string symbol, address newContract);
    event PaymentReceived(address from, uint256 amount);
    event LiquidityWithdraw(
        string symbol,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );
    event LiquidityTransfer(
        string symbol,
        address indexed to,
        uint256 amount,
        uint256 timestamp
    );




    modifier onlyDEX() {
        require(DEX == _msgSender(), "Liquidity: caller is not DEX");
        _;
    }

    constructor(
        address owner,
        address gsu,
        address usdt
    ) public {
        require(owner != address(0x0), "[Liquidity], owner is zero address");
        require(gsu != address(0x0), "[Liquidity], gsu is zero address");
        require(usdt != address(0x0), "[Liquidity], usdt is zero address");

        allLiquidities.push("ETH");

        newLiquidity(gsu);
        newLiquidity(usdt);
        transferOwnership(owner);
    }

    fallback() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    receive() external payable {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function withdraw(string calldata symbol, uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0, "[Liquidity] amount is zero");

        if (isERC20Token(symbol))
            TokenInterface(contractAddress[symbol]).transfer(owner(), amount);
        else address(uint160(owner())).transfer(amount);

        emit LiquidityWithdraw(symbol, owner(), amount, block.timestamp);
    }

    function transfer(
        string calldata symbol,
        address payable recipient,
        uint256 amount
    ) external onlyDEX returns (bool) {
        if (isERC20Token(symbol))
            TokenInterface(contractAddress[symbol]).transfer(recipient, amount);
        else recipient.transfer(amount);


        emit LiquidityTransfer(symbol, recipient, amount, block.timestamp);

        return true;
    }

    function balanceOf(string memory symbol) public view returns (uint256) {
        if (isERC20Token(symbol))
            return
                TokenInterface(contractAddress[symbol]).balanceOf(
                    address(this)
                );
        else return address(this).balance;
    }

    function isERC20Token(string memory symbol) public view returns (bool) {
        return contractAddress[symbol] != address(0x0);
    }

    function updateDEX(address newDEX) external onlyOwner returns (bool) {
        emit DEXUpdated(DEX, newDEX);
        DEX = newDEX;
        return true;
    }

    function newLiquidity(address _contract) private onlyOwner returns (bool) {
        string memory symbol = TokenInterface(_contract).symbol();
        allLiquidities.push(symbol);
        contractAddress[symbol] = _contract;
        return true;
    }

    function setTokenContract(string calldata symbol, address newContract)
        external
        onlyOwner
        returns (bool)
    {
        require(isERC20Token(symbol));
        contractAddress[symbol] = newContract;
        emit TokenUpdated(symbol, newContract);
        return true;
    }

    function totalLiquidities() external view returns (uint256) {
        return allLiquidities.length;
    }

    function destroy() external onlyOwner {

        for (uint8 a = 1; a < allLiquidities.length; a++) {
            string memory currency = allLiquidities[a];
            TokenInterface(contractAddress[currency]).transfer(
                owner(),
                balanceOf(currency)
            );
        }

        selfdestruct(payable(owner()));
    }
}
