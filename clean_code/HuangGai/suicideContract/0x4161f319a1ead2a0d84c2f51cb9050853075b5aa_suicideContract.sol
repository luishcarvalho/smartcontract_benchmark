



pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

    interface ERC20 {
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function decimals() external view returns (uint256 digits);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
interface ExchangeInterface {
    function swapEtherToToken(uint256 _ethAmount, address _tokenAddress, uint256 _maxAmount)
        external
        payable
        returns (uint256, uint256);

    function swapTokenToEther(address _tokenAddress, uint256 _amount, uint256 _maxAmount)
        external
        returns (uint256);

    function swapTokenToToken(address _src, address _dest, uint256 _amount)
        external
        payable
        returns (uint256);

    function getExpectedRate(address src, address dest, uint256 srcQty)
        external
        view
        returns (uint256 expectedRate);
}    contract DefisaverLogger {
    event LogEvent(
        address indexed contractAddress,
        address indexed caller,
        string indexed logName,
        bytes data
    );


    function Log(address _contract, address _caller, string memory _logName, bytes memory _data)
        public
    {
        emit LogEvent(_contract, _caller, _logName, _data);
    }
}    contract Discount {
    address public owner;
    mapping(address => CustomServiceFee) public serviceFees;

    uint256 constant MAX_SERVICE_FEE = 400;

    struct CustomServiceFee {
        bool active;
        uint256 amount;
    }

    constructor() public {
        owner = msg.sender;
    }

    function isCustomFeeSet(address _user) public view returns (bool) {
        return serviceFees[_user].active;
    }

    function getCustomServiceFee(address _user) public view returns (uint256) {
        return serviceFees[_user].amount;
    }

    function setServiceFee(address _user, uint256 _fee) public {
        require(msg.sender == owner, "Only owner");
        require(_fee >= MAX_SERVICE_FEE || _fee == 0);

        serviceFees[_user] = CustomServiceFee({active: true, amount: _fee});
    }

    function disableServiceFee(address _user) public {
        require(msg.sender == owner, "Only owner");

        serviceFees[_user] = CustomServiceFee({active: false, amount: 0});
    }
}    abstract contract PipInterface {
    function read() public virtual returns (bytes32);
}    abstract contract Spotter {
    struct Ilk {
        PipInterface pip;
        uint256 mat;
    }

    mapping (bytes32 => Ilk) public ilks;

    uint256 public par;

}    abstract contract Jug {
    struct Ilk {
        uint256 duty;
        uint256  rho;
    }

    mapping (bytes32 => Ilk) public ilks;

    function drip(bytes32) public virtual returns (uint);
}    abstract contract Vat {

    struct Urn {
        uint256 ink;
        uint256 art;
    }

    struct Ilk {
        uint256 Art;
        uint256 rate;
        uint256 spot;
        uint256 line;
        uint256 dust;
    }

    mapping (bytes32 => mapping (address => Urn )) public urns;
    mapping (bytes32 => Ilk)                       public ilks;
    mapping (bytes32 => mapping (address => uint)) public gem;

    function can(address, address) virtual public view returns (uint);
    function dai(address) virtual public view returns (uint);
    function frob(bytes32, address, address, address, int, int) virtual public;
    function hope(address) virtual public;
    function move(address, address, uint) virtual public;
    function fork(bytes32, address, address, int, int) virtual public;
}    abstract contract Gem {
    function dec() virtual public returns (uint);
    function gem() virtual public returns (Gem);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;

    function approve(address, uint) virtual public;
    function transfer(address, uint) virtual public returns (bool);
    function transferFrom(address, address, uint) virtual public returns (bool);
    function deposit() virtual public payable;
    function withdraw(uint) virtual public;
    function allowance(address, address) virtual public returns (uint);
}    abstract contract DaiJoin {
    function vat() public virtual returns (Vat);
    function dai() public virtual returns (Gem);
    function join(address, uint) public virtual payable;
    function exit(address, uint) public virtual;
}    abstract contract Join {
    bytes32 public ilk;

    function dec() virtual public view returns (uint);
    function gem() virtual public view returns (Gem);
    function join(address, uint) virtual public payable;
    function exit(address, uint) virtual public;
}    contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
















    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}    abstract contract DSAuthority {
    function canCall(address src, address dst, bytes4 sig) public virtual view returns (bool);
}    contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
}


contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}    contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 indexed bar,
        uint256 wad,
        bytes fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}    abstract contract DSProxy is DSAuth, DSNote {
    DSProxyCache public cache;

    constructor(address _cacheAddr) public {
        require(setCache(_cacheAddr));
    }


    receive() external payable {}








    function execute(address _target, bytes memory _data)
        public
        payable
        virtual
        returns (bytes32 response);


    function setCache(address _cacheAddr) public virtual payable returns (bool);
}


contract DSProxyCache {
    mapping(bytes32 => address) cache;

    function read(bytes memory _code) public view returns (address) {
        bytes32 hash = keccak256(_code);
        return cache[hash];
    }

    function write(bytes memory _code) public returns (address target) {
        assembly {
            target := create(0, add(_code, 0x20), mload(_code))
            switch iszero(extcodesize(target))
                case 1 {

                    revert(0, 0)
                }
        }
        bytes32 hash = keccak256(_code);
        cache[hash] = target;
    }
}    abstract contract Manager {
    function last(address) virtual public returns (uint);
    function cdpCan(address, uint, address) virtual public view returns (uint);
    function ilks(uint) virtual public view returns (bytes32);
    function owns(uint) virtual public view returns (address);
    function urns(uint) virtual public view returns (address);
    function vat() virtual public view returns (address);
    function open(bytes32, address) virtual public returns (uint);
    function give(uint, address) virtual public;
    function cdpAllow(uint, address, uint) virtual public;
    function urnAllow(address, uint) virtual public;
    function frob(uint, int, int) virtual public;
    function flux(uint, address, uint) virtual public;
    function move(uint, address, uint) virtual public;
    function exit(address, uint, address, uint) virtual public;
    function quit(uint, address) virtual public;
    function enter(address, uint) virtual public;
    function shift(uint, uint) virtual public;
}
contract MCDSaverProxyHelper is DSMath {





    function normalizeDrawAmount(uint _amount, uint _rate, uint _daiVatBalance) internal pure returns (int dart) {
        if (_daiVatBalance < mul(_amount, RAY)) {
            dart = toPositiveInt(sub(mul(_amount, RAY), _daiVatBalance) / _rate);
            dart = mul(uint(dart), _rate) < mul(_amount, RAY) ? dart + 1 : dart;
        }
    }



    function toRad(uint _wad) internal pure returns (uint) {
        return mul(_wad, 10 ** 27);
    }




    function convertTo18(address _joinAddr, uint256 _amount) internal view returns (uint256) {
        return mul(_amount, 10 ** (18 - Join(_joinAddr).dec()));
    }



    function toPositiveInt(uint _x) internal pure returns (int y) {
        y = int(_x);
        require(y >= 0, "int-overflow");
    }





    function normalizePaybackAmount(address _vat, address _urn, bytes32 _ilk) internal view returns (int amount) {
        uint dai = Vat(_vat).dai(_urn);

        (, uint rate,,,) = Vat(_vat).ilks(_ilk);
        (, uint art) = Vat(_vat).urns(_ilk, _urn);

        amount = toPositiveInt(dai / rate);
        amount = uint(amount) <= art ? - amount : - toPositiveInt(art);
    }






    function getAllDebt(address _vat, address _usr, address _urn, bytes32 _ilk) internal view returns (uint daiAmount) {
        (, uint rate,,,) = Vat(_vat).ilks(_ilk);
        (, uint art) = Vat(_vat).urns(_ilk, _urn);
        uint dai = Vat(_vat).dai(_usr);

        uint rad = sub(mul(art, rate), dai);
        daiAmount = rad / RAY;

        daiAmount = mul(daiAmount, RAY) < rad ? daiAmount + 1 : daiAmount;
    }



    function getCollateralAddr(address _joinAddr) internal view returns (address) {
        return address(Join(_joinAddr).gem());
    }





    function getCdpInfo(Manager _manager, uint _cdpId, bytes32 _ilk) public view returns (uint, uint) {
        address vat = _manager.vat();
        address urn = _manager.urns(_cdpId);

        (uint collateral, uint debt) = Vat(vat).urns(_ilk, urn);
        (,uint rate,,,) = Vat(vat).ilks(_ilk);

        return (collateral, rmul(debt, rate));
    }




    function getOwner(Manager _manager, uint _cdpId) public view returns (address) {
        DSProxy proxy = DSProxy(uint160(_manager.owns(_cdpId)));

        return proxy.owner();
    }
}    library Address {
    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


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
}    library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}    library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }





    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(ERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}    contract AdminAuth {

    using SafeERC20 for ERC20;

    address public owner;
    address public admin;

    modifier onlyOwner() {
        require(true);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }



    function setAdminByOwner(address _admin) public {
        require(msg.sender == owner);
        require(admin == address(0));

        admin = _admin;
    }



    function setAdminByAdmin(address _admin) public {
        require(msg.sender == admin);

        admin = _admin;
    }



    function setOwnerByAdmin(address _owner) public {
        require(msg.sender == admin);

        owner = _owner;
    }


    function kill() public onlyOwner {
        selfdestruct(payable(owner));
    }


    function withdrawStuckFunds(address _token, uint _amount) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(owner).transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(owner, _amount);
        }
    }
}    contract BotRegistry is AdminAuth {

    mapping (address => bool) public botList;

    constructor() public {
        botList[0x776B4a13093e30B05781F97F6A4565B6aa8BE330] = true;

        botList[0xAED662abcC4FA3314985E67Ea993CAD064a7F5cF] = true;
        botList[0xa5d330F6619d6bF892A5B87D80272e1607b3e34D] = true;
        botList[0x5feB4DeE5150B589a7f567EA7CADa2759794A90A] = true;
        botList[0x7ca06417c1d6f480d3bB195B80692F95A6B66158] = true;
    }

    function setBot(address _botAddr, bool _state) public onlyOwner {
        botList[_botAddr] = _state;
    }

}    abstract contract TokenInterface {
    function allowance(address, address) public virtual returns (uint256);

    function balanceOf(address) public virtual returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(address, address, uint256) public virtual returns (bool);

    function deposit() public virtual payable;

    function withdraw(uint256) public virtual;
}    interface ExchangeInterfaceV2 {
    function sell(address _srcAddr, address _destAddr, uint _srcAmount) external payable returns (uint);

    function buy(address _srcAddr, address _destAddr, uint _destAmount) external payable returns(uint);

    function getSellRate(address _srcAddr, address _destAddr, uint _srcAmount) external view returns (uint);

    function getBuyRate(address _srcAddr, address _destAddr, uint _srcAmount) external view returns (uint);
}    contract ZrxAllowlist is AdminAuth {

    mapping (address => bool) public zrxAllowlist;
    mapping(address => bool) private nonPayableAddrs;

    constructor() public {
        zrxAllowlist[0x6958F5e95332D93D21af0D7B9Ca85B8212fEE0A5] = true;
        zrxAllowlist[0x61935CbDd02287B511119DDb11Aeb42F1593b7Ef] = true;
        zrxAllowlist[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        zrxAllowlist[0x080bf510FCbF18b91105470639e9561022937712] = true;

        nonPayableAddrs[0x080bf510FCbF18b91105470639e9561022937712] = true;
    }

    function setAllowlistAddr(address _zrxAddr, bool _state) public onlyOwner {
        zrxAllowlist[_zrxAddr] = _state;
    }

    function isZrxAddr(address _zrxAddr) public view returns (bool) {
        return zrxAllowlist[_zrxAddr];
    }

    function addNonPayableAddr(address _nonPayableAddr) public onlyOwner {
		nonPayableAddrs[_nonPayableAddr] = true;
	}

	function removeNonPayableAddr(address _nonPayableAddr) public onlyOwner {
		nonPayableAddrs[_nonPayableAddr] = false;
	}

	function isNonPayableAddr(address _addr) public view returns(bool) {
		return nonPayableAddrs[_addr];
	}
}    contract SaverExchangeHelper {

    using SafeERC20 for ERC20;

    address public constant KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address payable public constant WALLET_ID = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;
    address public constant DISCOUNT_ADDRESS = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;
    address public constant SAVER_EXCHANGE_REGISTRY = 0x25dd3F51e0C3c3Ff164DDC02A8E4D65Bb9cBB12D;

    address public constant ERC20_PROXY_0X = 0x95E6F48254609A6ee006F7D493c8e5fB97094ceF;
    address public constant ZRX_ALLOWLIST_ADDR = 0x4BA1f38427b33B8ab7Bb0490200dAE1F1C36823F;


    function getDecimals(address _token) internal view returns (uint256) {
        if (_token == KYBER_ETH_ADDRESS) return 18;

        return ERC20(_token).decimals();
    }

    function getBalance(address _tokenAddr) internal view returns (uint balance) {
        if (_tokenAddr == KYBER_ETH_ADDRESS) {
            balance = address(this).balance;
        } else {
            balance = ERC20(_tokenAddr).balanceOf(address(this));
        }
    }

    function approve0xProxy(address _tokenAddr, uint _amount) internal {
        if (_tokenAddr != KYBER_ETH_ADDRESS) {
            ERC20(_tokenAddr).safeApprove(address(ERC20_PROXY_0X), _amount);
        }
    }

    function sendLeftover(address _srcAddr, address _destAddr, address payable _to) internal {

        if (address(this).balance > 0) {
            _to.transfer(address(this).balance);
        }

        if (getBalance(_srcAddr) > 0) {
            ERC20(_srcAddr).safeTransfer(_to, getBalance(_srcAddr));
        }

        if (getBalance(_destAddr) > 0) {
            ERC20(_destAddr).safeTransfer(_to, getBalance(_destAddr));
        }
    }

    function sliceUint(bytes memory bs, uint256 start) internal pure returns (uint256) {
        require(bs.length >= start + 32, "slicing out of range");

        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, start)))
        }

        return x;
    }
}    contract SaverExchangeRegistry is AdminAuth {

	mapping(address => bool) private wrappers;

	constructor() public {
		wrappers[0x880A845A85F843a5c67DB2061623c6Fc3bB4c511] = true;
		wrappers[0x4c9B55f2083629A1F7aDa257ae984E03096eCD25] = true;
		wrappers[0x42A9237b872368E1bec4Ca8D26A928D7d39d338C] = true;
	}

	function addWrapper(address _wrapper) public onlyOwner {
		wrappers[_wrapper] = true;
	}

	function removeWrapper(address _wrapper) public onlyOwner {
		wrappers[_wrapper] = false;
	}

	function isWrapper(address _wrapper) public view returns(bool) {
		return wrappers[_wrapper];
	}
}








contract SaverExchangeCore is SaverExchangeHelper, DSMath {


    enum ExchangeType { _, OASIS, KYBER, UNISWAP, ZEROX }

    enum ActionType { SELL, BUY }

    struct ExchangeData {
        address srcAddr;
        address destAddr;
        uint srcAmount;
        uint destAmount;
        uint minPrice;
        address wrapper;
        address exchangeAddr;
        bytes callData;
        uint256 price0x;
    }





    function _sell(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;
        uint tokensLeft = exData.srcAmount;


        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            exData.srcAddr = ethToWethAddr(exData.srcAddr);
            TokenInterface(WETH_ADDRESS).deposit.value(exData.srcAmount)();
        }


        if (exData.price0x > 0) {
            approve0xProxy(exData.srcAddr, exData.srcAmount);

            uint ethAmount = getProtocolFee(exData.srcAddr, msg.value, exData.srcAmount);
            (success, swapedTokens, tokensLeft) = takeOrder(exData, ethAmount, ActionType.SELL);

            if (success) {
                wrapper = exData.exchangeAddr;
            }
        }


        if (!success) {
            swapedTokens = saverSwap(exData, ActionType.SELL);
            wrapper = exData.wrapper;
        }

        require(getBalance(exData.destAddr) >= wmul(exData.minPrice, exData.srcAmount), "Final amount isn't correct");


        if (getBalance(WETH_ADDRESS) > 0) {
            TokenInterface(WETH_ADDRESS).withdraw(
                TokenInterface(WETH_ADDRESS).balanceOf(address(this))
            );
        }

        return (wrapper, swapedTokens);
    }





    function _buy(ExchangeData memory exData) internal returns (address, uint) {

        address wrapper;
        uint swapedTokens;
        bool success;

        require(exData.destAmount != 0, "Dest amount must be specified");


        if (exData.srcAddr == KYBER_ETH_ADDRESS) {
            exData.srcAddr = ethToWethAddr(exData.srcAddr);
            TokenInterface(WETH_ADDRESS).deposit.value(exData.srcAmount)();
        }

        if (exData.price0x > 0) {
            approve0xProxy(exData.srcAddr, exData.srcAmount);

            uint ethAmount = getProtocolFee(exData.srcAddr, msg.value, exData.srcAmount);
            (success, swapedTokens,) = takeOrder(exData, ethAmount, ActionType.BUY);

            if (success) {
                wrapper = exData.exchangeAddr;
            }
        }


        if (!success) {
            swapedTokens = saverSwap(exData, ActionType.BUY);
            wrapper = exData.wrapper;
        }

        require(getBalance(exData.destAddr) >= exData.destAmount, "Final amount isn't correct");


        if (getBalance(WETH_ADDRESS) > 0) {
            TokenInterface(WETH_ADDRESS).withdraw(
                TokenInterface(WETH_ADDRESS).balanceOf(address(this))
            );
        }

        return (wrapper, getBalance(exData.destAddr));
    }




    function takeOrder(
        ExchangeData memory _exData,
        uint256 _ethAmount,
        ActionType _type
    ) private returns (bool success, uint256, uint256) {


        if (_type == ActionType.SELL) {
            writeUint256(_exData.callData, 36, _exData.srcAmount);
        } else {
            writeUint256(_exData.callData, 36, _exData.destAmount);
        }

        if (ZrxAllowlist(ZRX_ALLOWLIST_ADDR).isNonPayableAddr(_exData.exchangeAddr)) {
            _ethAmount = 0;
        }

        uint256 tokensBefore = getBalance(_exData.destAddr);

        if (ZrxAllowlist(ZRX_ALLOWLIST_ADDR).isZrxAddr(_exData.exchangeAddr)) {
            (success, ) = _exData.exchangeAddr.call{value: _ethAmount}(_exData.callData);
        } else {
            success = false;
        }

        uint256 tokensSwaped = 0;
        uint256 tokensLeft = _exData.srcAmount;

        if (success) {

            tokensLeft = getBalance(_exData.srcAddr);


            if (_exData.destAddr == KYBER_ETH_ADDRESS) {
                TokenInterface(WETH_ADDRESS).withdraw(
                    TokenInterface(WETH_ADDRESS).balanceOf(address(this))
                );
            }


            tokensSwaped = getBalance(_exData.destAddr) - tokensBefore;
        }

        return (success, tokensSwaped, tokensLeft);
    }





    function saverSwap(ExchangeData memory _exData, ActionType _type) internal returns (uint swapedTokens) {
        require(SaverExchangeRegistry(SAVER_EXCHANGE_REGISTRY).isWrapper(_exData.wrapper), "Wrapper is not valid");

        uint ethValue = 0;

        ERC20(_exData.srcAddr).safeTransfer(_exData.wrapper, _exData.srcAmount);

        if (_type == ActionType.SELL) {
            swapedTokens = ExchangeInterfaceV2(_exData.wrapper).
                    sell{value: ethValue}(_exData.srcAddr, _exData.destAddr, _exData.srcAmount);
        } else {
            swapedTokens = ExchangeInterfaceV2(_exData.wrapper).
                    buy{value: ethValue}(_exData.srcAddr, _exData.destAddr, _exData.destAmount);
        }
    }

    function writeUint256(bytes memory _b, uint256 _index, uint _input) internal pure {
        if (_b.length < _index + 32) {
            revert("Incorrent lengt while writting bytes32");
        }

        bytes32 input = bytes32(_input);

        _index += 32;


        assembly {
            mstore(add(_b, _index), input)
        }
    }



    function ethToWethAddr(address _src) internal pure returns (address) {
        return _src == KYBER_ETH_ADDRESS ? WETH_ADDRESS : _src;
    }





    function getProtocolFee(address _srcAddr, uint256 _msgValue, uint256 _srcAmount) internal returns(uint256) {

        if (_srcAddr != WETH_ADDRESS) return _msgValue;



        if (_msgValue > _srcAmount) return _msgValue - _srcAmount;


        return _msgValue;
    }

    function packExchangeData(ExchangeData memory _exData) public pure returns(bytes memory) {


        bytes memory part1 = abi.encode(
            _exData.srcAddr,
            _exData.destAddr,
            _exData.srcAmount,
            _exData.destAmount
        );

        bytes memory part2 = abi.encode(
            _exData.minPrice,
            _exData.wrapper,
            _exData.exchangeAddr,
            _exData.callData,
            _exData.price0x
        );


        return abi.encode(part1, part2);
    }

    function unpackExchangeData(bytes memory _data) public pure returns(ExchangeData memory _exData) {
        (
            bytes memory part1,
            bytes memory part2
        ) = abi.decode(_data, (bytes,bytes));

        (
            _exData.srcAddr,
            _exData.destAddr,
            _exData.srcAmount,
            _exData.destAmount
        ) = abi.decode(part1, (address,address,uint256,uint256));

        (
            _exData.minPrice,
            _exData.wrapper,
            _exData.exchangeAddr,
            _exData.callData,
            _exData.price0x
        )
        = abi.decode(part2, (uint256,address,address,bytes,uint256));
    }


    receive() external virtual payable {}
}
















contract MCDSaverProxy is SaverExchangeCore, MCDSaverProxyHelper {

    uint public constant MANUAL_SERVICE_FEE = 400;
    uint public constant AUTOMATIC_SERVICE_FEE = 333;

    bytes32 public constant ETH_ILK = 0x4554482d41000000000000000000000000000000000000000000000000000000;

    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant SPOTTER_ADDRESS = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address public constant DAI_JOIN_ADDRESS = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public constant JUG_ADDRESS = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address public constant ETH_JOIN_ADDRESS = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public constant BOT_REGISTRY_ADDRESS = 0x637726f8b08a7ABE3aE3aCaB01A80E2d8ddeF77B;

    Manager public constant manager = Manager(MANAGER_ADDRESS);
    Vat public constant vat = Vat(VAT_ADDRESS);
    DaiJoin public constant daiJoin = DaiJoin(DAI_JOIN_ADDRESS);
    Spotter public constant spotter = Spotter(SPOTTER_ADDRESS);

    DefisaverLogger public constant logger = DefisaverLogger(0x5c55B921f590a89C1Ebe84dF170E655a82b62126);



    function repay(
        SaverExchangeCore.ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _gasCost,
        address _joinAddr
    ) public payable {

        address owner = getOwner(manager, _cdpId);
        bytes32 ilk = manager.ilks(_cdpId);

        drawCollateral(_cdpId, _joinAddr, _exchangeData.srcAmount);

        (, uint daiAmount) = _sell(_exchangeData);

        uint daiAfterFee = sub(daiAmount, getFee(daiAmount, _gasCost, owner));

        paybackDebt(_cdpId, ilk, daiAfterFee, owner);


        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }

        logger.Log(address(this), msg.sender, "MCDRepay", abi.encode(_cdpId, owner, _exchangeData.srcAmount, daiAmount));

    }



    function boost(
        SaverExchangeCore.ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _gasCost,
        address _joinAddr
    ) public payable {
        address owner = getOwner(manager, _cdpId);
        bytes32 ilk = manager.ilks(_cdpId);

        uint daiDrawn = drawDai(_cdpId, ilk, _exchangeData.srcAmount);
        uint daiAfterFee = sub(daiDrawn, getFee(daiDrawn, _gasCost, owner));

        _exchangeData.srcAmount = daiAfterFee;
        (, uint swapedColl) = _sell(_exchangeData);

        addCollateral(_cdpId, _joinAddr, swapedColl);


        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }

        logger.Log(address(this), msg.sender, "MCDBoost", abi.encode(_cdpId, owner, _exchangeData.srcAmount, swapedColl));
    }






    function drawDai(uint _cdpId, bytes32 _ilk, uint _daiAmount) internal returns (uint) {
        uint rate = Jug(JUG_ADDRESS).drip(_ilk);
        uint daiVatBalance = vat.dai(manager.urns(_cdpId));

        uint maxAmount = getMaxDebt(_cdpId, _ilk);

        if (_daiAmount >= maxAmount) {
            _daiAmount = sub(maxAmount, 1);
        }

        manager.frob(_cdpId, int(0), normalizeDrawAmount(_daiAmount, rate, daiVatBalance));
        manager.move(_cdpId, address(this), toRad(_daiAmount));

        if (vat.can(address(this), address(DAI_JOIN_ADDRESS)) == 0) {
            vat.hope(DAI_JOIN_ADDRESS);
        }

        DaiJoin(DAI_JOIN_ADDRESS).exit(address(this), _daiAmount);

        return _daiAmount;
    }





    function addCollateral(uint _cdpId, address _joinAddr, uint _amount) internal {
        int convertAmount = 0;

        if (_joinAddr == ETH_JOIN_ADDRESS) {
            Join(_joinAddr).gem().deposit{value: _amount}();
            convertAmount = toPositiveInt(_amount);
        } else {
            convertAmount = toPositiveInt(convertTo18(_joinAddr, _amount));
        }

        ERC20(address(Join(_joinAddr).gem())).safeApprove(_joinAddr, 0);
        ERC20(address(Join(_joinAddr).gem())).safeApprove(_joinAddr, _amount);

        Join(_joinAddr).join(address(this), _amount);

        vat.frob(
            manager.ilks(_cdpId),
            manager.urns(_cdpId),
            address(this),
            address(this),
            convertAmount,
            0
        );

    }






    function drawCollateral(uint _cdpId, address _joinAddr, uint _amount) internal returns (uint) {
        uint frobAmount = _amount;

        if (Join(_joinAddr).dec() != 18) {
            frobAmount = _amount * (10 ** (18 - Join(_joinAddr).dec()));
        }

        manager.frob(_cdpId, -toPositiveInt(frobAmount), 0);
        manager.flux(_cdpId, address(this), frobAmount);

        Join(_joinAddr).exit(address(this), _amount);

        if (_joinAddr == ETH_JOIN_ADDRESS) {
            Join(_joinAddr).gem().withdraw(_amount);
        }

        return _amount;
    }







    function paybackDebt(uint _cdpId, bytes32 _ilk, uint _daiAmount, address _owner) internal {
        address urn = manager.urns(_cdpId);

        uint wholeDebt = getAllDebt(VAT_ADDRESS, urn, urn, _ilk);

        if (_daiAmount > wholeDebt) {
            ERC20(DAI_ADDRESS).transfer(_owner, sub(_daiAmount, wholeDebt));
            _daiAmount = wholeDebt;
        }

        if (ERC20(DAI_ADDRESS).allowance(address(this), DAI_JOIN_ADDRESS) == 0) {
            ERC20(DAI_ADDRESS).approve(DAI_JOIN_ADDRESS, uint(-1));
        }

        daiJoin.join(urn, _daiAmount);

        manager.frob(_cdpId, 0, normalizePaybackAmount(VAT_ADDRESS, urn, _ilk));
    }





    function getFee(uint _amount, uint _gasCost, address _owner) internal returns (uint feeAmount) {
        uint fee = MANUAL_SERVICE_FEE;

        if (BotRegistry(BOT_REGISTRY_ADDRESS).botList(tx.origin)) {
            fee = AUTOMATIC_SERVICE_FEE;
        }

        if (Discount(DISCOUNT_ADDRESS).isCustomFeeSet(_owner)) {
            fee = Discount(DISCOUNT_ADDRESS).getCustomServiceFee(_owner);
        }

        feeAmount = (fee == 0) ? 0 : (_amount / fee);

        if (_gasCost != 0) {
            uint ethDaiPrice = getPrice(ETH_ILK);
            _gasCost = rmul(_gasCost, ethDaiPrice);

            feeAmount = add(feeAmount, _gasCost);
        }


        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }

        ERC20(DAI_ADDRESS).transfer(WALLET_ID, feeAmount);
    }






    function getMaxCollateral(uint _cdpId, bytes32 _ilk, address _joinAddr) public view returns (uint) {
        uint price = getPrice(_ilk);

        (uint collateral, uint debt) = getCdpInfo(manager, _cdpId, _ilk);

        (, uint mat) = Spotter(SPOTTER_ADDRESS).ilks(_ilk);

        uint maxCollateral = sub(sub(collateral, (div(mul(mat, debt), price))), 10);

        uint normalizeMaxCollateral = maxCollateral;

        if (Join(_joinAddr).dec() != 18) {
            normalizeMaxCollateral = maxCollateral / (10 ** (18 - Join(_joinAddr).dec()));
        }

        return normalizeMaxCollateral;
    }





    function getMaxDebt(uint _cdpId, bytes32 _ilk) public virtual view returns (uint) {
        uint price = getPrice(_ilk);

        (, uint mat) = spotter.ilks(_ilk);
        (uint collateral, uint debt) = getCdpInfo(manager, _cdpId, _ilk);

        return sub(sub(div(mul(collateral, price), mat), debt), 10);
    }



    function getPrice(bytes32 _ilk) public view returns (uint) {
        (, uint mat) = spotter.ilks(_ilk);
        (,,uint spot,,) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }




    function getRatio(uint _cdpId, bytes32 _ilk) public view returns (uint) {
        uint price = getPrice( _ilk);

        (uint collateral, uint debt) = getCdpInfo(manager, _cdpId, _ilk);

        if (debt == 0) return 0;

        return rdiv(wmul(collateral, price), debt);
    }



    function getCdpDetailedInfo(uint _cdpId) public view returns (uint collateral, uint debt, uint price, bytes32 ilk) {
        address urn = manager.urns(_cdpId);
        ilk = manager.ilks(_cdpId);

        (collateral, debt) = vat.urns(ilk, urn);
        (,uint rate,,,) = vat.ilks(ilk);

        debt = rmul(debt, rate);
        price = getPrice(ilk);
    }

}    abstract contract GasTokenInterface is ERC20 {
    function free(uint256 value) public virtual returns (bool success);

    function freeUpTo(uint256 value) public virtual returns (uint256 freed);

    function freeFrom(address from, uint256 value) public virtual returns (bool success);

    function freeFromUpTo(address from, uint256 value) public virtual returns (uint256 freed);
}    contract GasBurner {

    GasTokenInterface public constant gasToken = GasTokenInterface(0x0000000000b3F879cb30FE243b4Dfee438691c04);

    modifier burnGas(uint _amount) {
        if (gasToken.balanceOf(address(this)) >= _amount) {
            gasToken.free(_amount);
        }

        _;
    }
}





abstract contract ILendingPool {
    function flashLoan( address payable _receiver, address _reserve, uint _amount, bytes calldata _params) external virtual;
}

contract MCDSaverTaker is MCDSaverProxy, GasBurner {

    address payable public constant MCD_SAVER_FLASH_LOAN = 0x28e444b53a9e7E3F6fFe50E93b18dCce7838551F;
    address public constant AAVE_POOL_CORE = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    function boostWithLoan(
        SaverExchangeCore.ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _gasCost,
        address _joinAddr
    ) public payable burnGas(25) {
        uint256 maxDebt = getMaxDebt(_cdpId, manager.ilks(_cdpId));

        uint256 loanAmount = sub(_exchangeData.srcAmount, maxDebt);
        uint maxLiq = getAvailableLiquidity(DAI_JOIN_ADDRESS);

        loanAmount = loanAmount > maxLiq ? maxLiq : loanAmount;

        if (maxDebt >= _exchangeData.srcAmount || maxLiq == 0) {
            if (_exchangeData.srcAmount > maxDebt) {
                _exchangeData.srcAmount = maxDebt;
            }

            boost(_exchangeData, _cdpId, _gasCost, _joinAddr);
            return;
        }

        MCD_SAVER_FLASH_LOAN.transfer(msg.value);

        manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_LOAN, 1);

        bytes memory paramsData = abi.encode(packExchangeData(_exchangeData), _cdpId, _gasCost, _joinAddr, false);

        lendingPool.flashLoan(MCD_SAVER_FLASH_LOAN, DAI_ADDRESS, loanAmount, paramsData);

        manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_LOAN, 0);
    }

    function repayWithLoan(
        SaverExchangeCore.ExchangeData memory _exchangeData,
        uint _cdpId,
        uint _gasCost,
        address _joinAddr
    ) public payable burnGas(25) {
        uint256 maxColl = getMaxCollateral(_cdpId, manager.ilks(_cdpId), _joinAddr);

        uint256 loanAmount = sub(_exchangeData.srcAmount, maxColl);
        uint maxLiq = getAvailableLiquidity(_joinAddr);

        loanAmount = loanAmount > maxLiq ? maxLiq : loanAmount;

        if (maxColl >= _exchangeData.srcAmount || maxLiq == 0) {
            if (_exchangeData.srcAmount > maxColl) {
                _exchangeData.srcAmount = maxColl;
            }

            repay(_exchangeData, _cdpId, _gasCost, _joinAddr);
            return;
        }

        MCD_SAVER_FLASH_LOAN.transfer(msg.value);

        manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_LOAN, 1);

        bytes memory paramsData = abi.encode(packExchangeData(_exchangeData), _cdpId, _gasCost, _joinAddr, true);

        lendingPool.flashLoan(MCD_SAVER_FLASH_LOAN, getAaveCollAddr(_joinAddr), loanAmount, paramsData);

        manager.cdpAllow(_cdpId, MCD_SAVER_FLASH_LOAN, 0);
    }





    function getMaxDebt(uint256 _cdpId, bytes32 _ilk) public override view returns (uint256) {
        uint256 price = getPrice(_ilk);

        (, uint256 mat) = spotter.ilks(_ilk);
        (uint256 collateral, uint256 debt) = getCdpInfo(manager, _cdpId, _ilk);

        return sub(wdiv(wmul(collateral, price), mat), debt);
    }

    function getAaveCollAddr(address _joinAddr) internal view returns (address) {
        if (_joinAddr == 0x2F0b23f53734252Bda2277357e97e1517d6B042A
            || _joinAddr == 0x775787933e92b709f2a3C70aa87999696e74A9F8) {
            return KYBER_ETH_ADDRESS;
        } else if (_joinAddr == DAI_JOIN_ADDRESS) {
            return DAI_ADDRESS;
        } else
         {
            return getCollateralAddr(_joinAddr);
        }
    }

    function getAvailableLiquidity(address _joinAddr) internal view returns (uint liquidity) {
        address tokenAddr = getAaveCollAddr(_joinAddr);

        if (tokenAddr == KYBER_ETH_ADDRESS) {
            liquidity = AAVE_POOL_CORE.balance;
        } else {
            liquidity = ERC20(tokenAddr).balanceOf(AAVE_POOL_CORE);
        }
    }

     function _packData(
        uint _cdpId,
        uint _gasCost,
        address _joinAddr,
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (uint[6] memory numData, address[5] memory addrData, bytes memory callData) {

        numData = [
            exchangeData.srcAmount,
            exchangeData.destAmount,
            exchangeData.minPrice,
            exchangeData.price0x,
            _cdpId,
            _gasCost
        ];

        addrData = [
            exchangeData.srcAddr,
            exchangeData.destAddr,
            exchangeData.exchangeAddr,
            exchangeData.wrapper,
            _joinAddr
        ];

        callData = exchangeData.callData;
    }

}
