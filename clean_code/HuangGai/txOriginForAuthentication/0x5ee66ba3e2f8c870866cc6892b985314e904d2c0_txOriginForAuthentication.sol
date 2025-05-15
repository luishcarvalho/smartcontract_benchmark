

pragma solidity ^0.5.7;





contract IERC173 {

    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);







    function transferOwnership(address _newOwner) external;
}



pragma solidity ^0.5.7;



contract Ownable is IERC173 {
    address internal _owner;

    modifier onlyOwner() {
        require(tx.origin == _owner, "The owner should be the sender");

        _;
    }

    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0x0), msg.sender);
    }

    function owner() external view returns (address) {
        return _owner;
    }






    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "0x0 Is not a valid owner");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}



pragma solidity ^0.5.7;


interface IERC165 {






    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}



pragma solidity ^0.5.7;












contract RateOracle is IERC165 {
    uint256 public constant VERSION = 5;
    bytes4 internal constant RATE_ORACLE_INTERFACE = 0xa265d8e0;

    constructor() internal {}




    function symbol() external view returns (string memory);




    function name() external view returns (string memory);





    function decimals() external view returns (uint256);





    function token() external view returns (address);




    function currency() external view returns (bytes32);




    function maintainer() external view returns (string memory);




    function url() external view returns (string memory);




    function readSample(bytes calldata _data) external returns (uint256 _tokens, uint256 _equivalent);
}



pragma solidity ^0.5.7;








contract ERC165 is IERC165 {
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;








    mapping(bytes4 => bool) private _supportedInterfaces;





    constructor()
        internal
    {
        _registerInterface(_InterfaceId_ERC165);
    }




    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }




    function _registerInterface(bytes4 interfaceId)
        internal
    {
        require(interfaceId != 0xffffffff, "Can't register 0xffffffff");
        _supportedInterfaces[interfaceId] = true;
    }
}



pragma solidity ^0.5.7;


contract OwnableBasalt {
    address public owner;

    modifier onlyOwner() {
        require(tx.origin == owner, "The owner should be the sender");

        _;
    }

    constructor() public {
        owner = msg.sender;
    }






    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0), "0x0 Is not a valid owner");
        owner = _to;
        return true;
    }
}



pragma solidity ^0.5.7;









contract Oracle is OwnableBasalt {
    uint256 public constant VERSION = 4;

    event NewSymbol(bytes32 _currency);

    mapping(bytes32 => bool) public supported;
    bytes32[] public currencies;




    function url() public view returns (string memory);







    function getRate(bytes32 symbol, bytes memory data) public returns (uint256 rate, uint256 decimals);








    function addCurrency(string memory ticker) public onlyOwner returns (bool) {
        bytes32 currency = encodeCurrency(ticker);
        emit NewSymbol(currency);
        supported[currency] = true;
        currencies.push(currency);
        return true;
    }




    function encodeCurrency(string memory currency) public pure returns (bytes32 o) {
        require(bytes(currency).length <= 32);
        assembly {
            o := mload(add(currency, 32))
        }
    }




    function decodeCurrency(bytes32 b) public pure returns (string memory o) {
        uint256 ns = 256;
        while (true) {
            if (ns == 0 || (b<<ns-8) != 0)
                break;
            ns -= 8;
        }
        assembly {
            ns := div(ns, 8)
            o := mload(0x40)
            mstore(0x40, add(o, and(add(add(ns, 0x20), 0x1f), not(0x1f))))
            mstore(o, ns)
            mstore(add(o, 32), b)
        }
    }

}



pragma solidity ^0.5.7;





contract OracleAdapter is Ownable, RateOracle, ERC165 {
    Oracle public legacyOracle;

    string private isymbol;
    string private iname;
    string private imaintainer;

    uint256 private idecimals;
    bytes32 private icurrency;

    address private itoken;

    constructor(
        Oracle _legacyOracle,
        string memory _symbol,
        string memory _name,
        string memory _maintainer,
        uint256 _decimals,
        bytes32 _currency,
        address _token
    ) public {
        legacyOracle = _legacyOracle;
        isymbol = _symbol;
        iname = _name;
        imaintainer = _maintainer;
        idecimals = _decimals;
        icurrency = _currency;
        itoken = _token;

        _registerInterface(RATE_ORACLE_INTERFACE);
    }

    function symbol() external view returns (string memory) { return isymbol; }

    function name() external view returns (string memory) { return iname; }

    function decimals() external view returns (uint256) { return idecimals; }

    function token() external view returns (address) { return itoken; }

    function currency() external view returns (bytes32) { return icurrency; }

    function maintainer() external view returns (string memory) { return imaintainer; }

    function url() external view returns (string memory) {
        return legacyOracle.url();
    }

    function setMaintainer(string calldata _maintainer) external onlyOwner {
        imaintainer = _maintainer;
    }

    function setName(string calldata _name) external onlyOwner {
        iname = _name;
    }

    function setLegacyOracle(Oracle _legacyOracle) external onlyOwner {
        legacyOracle = _legacyOracle;
    }

    function readSample(bytes calldata _data) external returns (uint256 _tokens, uint256 _equivalent) {
        (_tokens, _equivalent) = legacyOracle.getRate(icurrency, _data);
        _equivalent = 10 ** _equivalent;
    }
}
