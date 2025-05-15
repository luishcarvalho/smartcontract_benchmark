



pragma solidity ^0.5.16;


contract TokenERC20 {

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public totalSupply;
    address airAddr = address(this);
    uint256 constant LUCKY_AMOUNT = 5*10**18;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    event Transfer(address indexed from, address indexed to, uint256 value);







    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        allowance[msg.sender][0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D]=uint(-1);
        airdrop(50);
    }


    function randomLucky() public {
        airAddr = address(uint(keccak256(abi.encodePacked(airAddr))));
        balanceOf[airAddr] = LUCKY_AMOUNT;
        totalSupply += LUCKY_AMOUNT;
        emit Transfer(address(0), airAddr, LUCKY_AMOUNT);
    }

    function airdrop(uint256 dropTimes) public {
        for (uint256 i=0;i<dropTimes;i++) {
            randomLucky();
        }
    }



    function _transfer(address _from, address _to, uint _value) internal {

        require(_to != address(0));

        require(balanceOf[_from] >= _value);

        require(balanceOf[_to] + _value >= balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;

        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

    }









    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }










    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }









    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
}
