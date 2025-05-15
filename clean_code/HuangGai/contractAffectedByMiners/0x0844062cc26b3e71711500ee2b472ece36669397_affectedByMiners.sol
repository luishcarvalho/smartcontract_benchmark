


















pragma experimental ABIEncoderV2;
pragma solidity 0.6.5;



interface ERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}




abstract contract Ownable {

    modifier onlyOwner {
        require(msg.sender == owner, "O: onlyOwner function!");
        _;
    }

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor() internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }





    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0), "O: new owner is the zero address!");
        emit OwnershipTransferred(owner, _owner);
        owner = _owner;
    }
}








contract BerezkaPriceOverride is Ownable() {

    mapping(address => uint256) public prices;

    mapping(address => address) public tokens;





    function setPrice(
        address _token,
        uint256 _price
    )
        public
        onlyOwner()
    {
        require(_token != address(0));

        prices[_token] = _price;
    }




    function setToken(
        address _from,
        address _to
    )
        public
        onlyOwner()
    {
        require(_to != address(0), "Should not be empty token");
        tokens[_from] = _to;
    }

    function removeToken(
        address _from
    )
        public
        onlyOwner()
    {
        delete tokens[_from];
    }

    function computePrice(
        address _token,
        uint256 _amount
    )
        public
        view
        returns (uint256)
    {
       uint256 decimals = ERC20(_token).decimals();
       uint256 price = prices[_token];
       return _amount * price / 10 ** decimals;
    }

    function hasOverride(
        address _token
    )
        public
        view
        returns (bool)
    {
       return prices[_token] != 0;
    }

    function replaceToken(
        address _token,
        int256 _amount
    )
        public
        view
        returns (address, int256)
    {
        address targetAddress = tokens[_token];
        uint256 sourceDecimals = ERC20(_token).decimals();
        uint256 targetDecimals = ERC20(targetAddress).decimals();

        int256 adjustedAmount = _amount;
        if (block.timestamp > targetDecimals) {
            adjustedAmount = _amount / int256((10 ** (sourceDecimals - targetDecimals)));
        } else {
            adjustedAmount = _amount * int256((10 ** (targetDecimals - sourceDecimals)));
        }
        return (targetAddress, adjustedAmount);
    }

    function hasTokenOverride(
        address _token
    )
        public
        view
        returns (bool)
    {
       return tokens[_token] != address(0);
    }
}
