





pragma solidity ^0.6.0;


interface IERC20 {

    function TOTALSUPPLY15() external view returns (uint256);


    function BALANCEOF165(address account) external view returns (uint256);


    function TRANSFER42(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE912(address owner, address spender) external view returns (uint256);


    function APPROVE113(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM313(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER502(address indexed from, address indexed to, uint256 value);


    event APPROVAL286(address indexed owner, address indexed spender, uint256 value);
}




pragma solidity >=0.6.0;



contract P2pSwap {
    struct Swap {
        address aliceAddress;
        address token1;
        uint256 value1;
        address token2;
        uint256 value2;
        uint8 executed;
    }

    mapping(uint256 => Swap) swaps;

    function GETSWAP929(uint256 _id)
    public view returns (address, address, uint256, address, uint256, uint8) {
        Swap memory swap = swaps[_id];
        return (
            swap.aliceAddress,
            swap.token1,
            swap.value1,
            swap.token2,
            swap.value2,
            swap.executed
        );
    }

    function REGISTERSWAP626(
        uint256 _id,
        address _aliceAddress,
        address _token1,
        uint256 _value1,
        address _token2,
        uint256 _value2)
    public returns (bool) {
        require(_id != 0);
        require(_aliceAddress != address(0));
        require(_token1 != address(0));
        require(_value1 != 0);
        require(_token2 != address(0));
        require(_value2 != 0);
        Swap storage swap = swaps[_id];
        require(swap.aliceAddress == address(0), "Swap already exists");
        swap.aliceAddress = _aliceAddress;
        swap.token1 = _token1;
        swap.value1 = _value1;
        swap.token2 = _token2;
        swap.value2 = _value2;
        return true;
    }

    function CANCELSWAP640(uint256 _id) public returns (bool) {
        Swap storage swap = swaps[_id];
        require(swap.executed == 0, "Swap not available");
        swap.executed = 2;
    }

    function EXECUTESWAP306(uint256 _id, address _bob)
    public returns (bool) {
        require(_bob != address(0));
        Swap storage swap = swaps[_id];
        require(swap.aliceAddress != address(0), "Swap does not exists");
        require(swap.executed == 2, "Swap not available");
        IERC20 Token1 = IERC20(swap.token1);
        IERC20 Token2 = IERC20(swap.token2);

        Token1.TRANSFERFROM313(swap.aliceAddress, _bob, swap.value1);
        Token2.TRANSFERFROM313(_bob, swap.aliceAddress, swap.value2);
        swap.executed = 1;
        return true;
    }
}
