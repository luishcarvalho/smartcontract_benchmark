pragma solidity 0.5.9;

contract DistributedEnergyCoinBase {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;

    event Transfer( address indexed from, address indexed to, uint256 value);

    function totalSupply() public view returns (uint256) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        require(_balances[msg.sender] >= wad);

        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(msg.sender, dst, wad);

        return true;
    }

    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x && z>=y);
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x - y;
        require(x >= y && z <= x);
        return z;
    }
}

contract DistributedEnergyCoin is DistributedEnergyCoinBase {

    string  public  symbol = "DEC";
    string  public name = "Distributed Energy Coin";
    uint256  public  decimals = 8;
    uint256 public freezedValue = 38280000*(10**8);
    address public owner;
    address public freezeOwner = address(0x01);

    struct FreezeStruct {
        uint256 unfreezeTime;
        uint256 unfreezeValue;
        bool freezed;
    }

    FreezeStruct[] public unfreezeTimeMap;

    constructor() public{
        _supply = 319000000*(10**8);
        _balances[freezeOwner] = freezedValue;
        _balances[msg.sender] = sub(_supply,freezedValue);
        owner = msg.sender;

        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1586995200, unfreezeValue:9570000*(10**8), freezed: true}));
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1618531200, unfreezeValue:14355000*(10**8), freezed: true}));
        unfreezeTimeMap.push(FreezeStruct({unfreezeTime:1650067200, unfreezeValue:14355000*(10**8), freezed: true}));
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return super.transfer(dst, wad);
    }

    function distribute(address dst, uint256 wad) public returns (bool) {
        require(tx.origin == owner);


        return super.transfer(dst, wad);
    }

    function unfreeze(uint256 i) public {
        require(tx.origin == owner);

        require(i>=0 && i<unfreezeTimeMap.length);
        require(now >= unfreezeTimeMap[i].unfreezeTime && unfreezeTimeMap[i].freezed);
        require(_balances[freezeOwner] >= unfreezeTimeMap[i].unfreezeValue);

        _balances[freezeOwner] = sub(_balances[freezeOwner], unfreezeTimeMap[i].unfreezeValue);
        _balances[owner] = add(_balances[owner], unfreezeTimeMap[i].unfreezeValue);

        freezedValue = sub(freezedValue, unfreezeTimeMap[i].unfreezeValue);
        unfreezeTimeMap[i].freezed = false;

        emit Transfer(freezeOwner, owner, unfreezeTimeMap[i].unfreezeValue);
    }
}
