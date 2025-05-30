





pragma solidity 0.6.12;




interface IERC20Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
}




pragma solidity 0.6.12;




contract Utils {

    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }


    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }


    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }


    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }


    modifier notThis(address _address) {
        _notThis(_address);
        _;
    }


    function _notThis(address _address) internal view {
        require(_address != address(this), "ERR_ADDRESS_IS_SELF");
    }
}



pragma solidity 0.6.12;




library SafeMath {








    function add(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;

        return z;
    }









    function sub(uint256 _x, uint256 _y) internal pure returns (uint256) {

        return _x - _y;
    }









    function mul(uint256 _x, uint256 _y) internal pure returns (uint256) {

        if (_x == 0)
            return 0;

        uint256 z = _x * _y;
        require(z / _x == _y, "ERR_OVERFLOW");
        return z;
    }









    function div(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_y > 0, "ERR_DIVIDE_BY_ZERO");
        uint256 c = _x / _y;
        return c;
    }
}



pragma solidity 0.6.12;







contract ERC20Token is IERC20Token, Utils {
    using SafeMath for uint256;


    string public override name;
    string public override symbol;
    uint8 public override decimals;
    uint256 public override totalSupply;
    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;








    event Transfer(address indexed _from, address indexed _to, uint256 _value);








    event Approval(address indexed _owner, address indexed _spender, uint256 _value);









    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) public {

        require(bytes(_name).length > 0, "ERR_INVALID_NAME");
        require(bytes(_symbol).length > 0, "ERR_INVALID_SYMBOL");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }










    function transfer(address _to, uint256 _value)
        public
        virtual
        override
        validAddress(_to)
        returns (bool)
    {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);

        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }











    function transferFrom(address _from, address _to, uint256 _value)
        public
        virtual
        override
        validAddress(_from)
        validAddress(_to)
        returns (bool)
    {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        balanceOf[_from] = balanceOf[_from].sub(_value);

        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }














    function approve(address _spender, uint256 _value)
        public
        virtual
        override
        validAddress(_spender)
        returns (bool)
    {

        require(_value == 0 || allowance[msg.sender][_spender] == 0, "ERR_INVALID_AMOUNT");

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}



pragma solidity 0.6.12;




interface IOwned {

    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
    function acceptOwnership() external;
}



pragma solidity 0.6.12;






interface ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) external;
}



pragma solidity 0.6.12;






interface IConverterAnchor is IOwned, ITokenHolder {
}



pragma solidity 0.6.12;







interface ISmartToken is IConverterAnchor, IERC20Token {
    function disableTransfers(bool _disable) external;
    function issue(address _to, uint256 _amount) external;
    function destroy(address _from, uint256 _amount) external;
}



pragma solidity 0.6.12;





contract Owned is IOwned {
    address public override owner;
    address public newOwner;







    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);




    constructor() public {
        owner = msg.sender;
    }


    modifier ownerOnly {
        _ownerOnly();
        _;
    }


    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }








    function transferOwnership(address _newOwner) public override ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }




    function acceptOwnership() override public {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



pragma solidity 0.6.12;


contract TokenHandler {
    bytes4 private constant APPROVE_FUNC_SELECTOR = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant TRANSFER_FUNC_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant TRANSFER_FROM_FUNC_SELECTOR = bytes4(keccak256("transferFrom(address,address,uint256)"));










    function safeApprove(IERC20Token _token, address _spender, uint256 _value) internal {
        (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(APPROVE_FUNC_SELECTOR, _spender, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_APPROVE_FAILED');
    }










    function safeTransfer(IERC20Token _token, address _to, uint256 _value) internal {
       (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(TRANSFER_FUNC_SELECTOR, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_TRANSFER_FAILED');
    }











    function safeTransferFrom(IERC20Token _token, address _from, address _to, uint256 _value) internal {
       (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(TRANSFER_FROM_FUNC_SELECTOR, _from, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_TRANSFER_FROM_FAILED');
    }
}



pragma solidity 0.6.12;

















contract TokenHolder is ITokenHolder, TokenHandler, Owned, Utils {








    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        virtual
        override
        ownerOnly
        validAddress(address(_token))
        validAddress(_to)
        notThis(_to)
    {
        safeTransfer(_token, _to, _amount);
    }
}



pragma solidity 0.6.12;










contract SmartToken is ISmartToken, Owned, ERC20Token, TokenHolder {
    using SafeMath for uint256;

    uint16 public constant version = 4;

    bool public transfersEnabled = true;






    event Issuance(uint256 _amount);






    event Destruction(uint256 _amount);








    constructor(string memory _name, string memory _symbol, uint8 _decimals)
        public
        ERC20Token(_name, _symbol, _decimals, 0)
    {
    }


    modifier transfersAllowed {
        _transfersAllowed();
        _;
    }


    function _transfersAllowed() internal view {
        require(transfersEnabled, "ERR_TRANSFERS_DISABLED");
    }







    function disableTransfers(bool _disable) public override ownerOnly {
        transfersEnabled = !_disable;
    }








    function issue(address _to, uint256 _amount)
        public
        override
        ownerOnly
        validAddress(_to)
        notThis(_to)
    {
        totalSupply = totalSupply.add(_amount);

        balanceOf[_to] = balanceOf[_to].add(_amount);


        emit Issuance(_amount);
        emit Transfer(address(0), _to, _amount);
    }








    function destroy(address _from, uint256 _amount) public override ownerOnly {
        balanceOf[_from] = balanceOf[_from].sub(_amount);

        totalSupply = totalSupply.sub(_amount);


        emit Transfer(_from, address(0), _amount);
        emit Destruction(_amount);
    }













    function transfer(address _to, uint256 _value)
        public
        override(IERC20Token, ERC20Token)
        transfersAllowed
        returns (bool)
    {
        return super.transfer(_to, _value);
    }












    function transferFrom(address _from, address _to, uint256 _value)
        public
        override(IERC20Token, ERC20Token)
        transfersAllowed
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }
}
