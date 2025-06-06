



pragma solidity ^0.5.12;

pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    constructor () internal { }


    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

library SafeMath {
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
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

interface OneSplit {
    function goodSwap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        uint256 parts,
        uint256 disableFlags
    )
        external
        payable;
}

contract Structs {
    struct Val {
        uint256 value;
    }

    enum ActionType {
      Deposit,
      Withdraw,
      Transfer,
      Buy,
      Sell,
      Trade,
      Liquidate,
      Vaporize,
      Call
    }

    enum AssetDenomination {
        Wei
    }

    enum AssetReference {
        Delta
    }

    struct AssetAmount {
        bool sign;
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Info {
        address owner;
        uint256 number;
    }

    struct Wei {
        bool sign;
        uint256 value;
    }
}

contract DyDx is Structs {
    function getAccountWei(Info memory account, uint256 marketId) public view returns (Wei memory);
    function operate(Info[] memory, ActionArgs[] memory) public;
}

contract GemLike {
    function approve(address, uint) public;
    function transfer(address, uint) public;
    function transferFrom(address, address, uint) public;
    function deposit() public payable;
    function withdraw(uint) public;
}

contract ManagerLike {
    function cdpCan(address, uint, address) public view returns (uint);
    function ilks(uint) public view returns (bytes32);
    function owns(uint) public view returns (address);
    function urns(uint) public view returns (address);
    function vat() public view returns (address);
    function open(bytes32, address) public returns (uint);
    function give(uint, address) public;
    function cdpAllow(uint, address, uint) public;
    function urnAllow(address, uint) public;
    function frob(uint, int, int) public;
    function flux(uint, address, uint) public;
    function move(uint, address, uint) public;
    function exit(address, uint, address, uint) public;
    function quit(uint, address) public;
    function enter(address, uint) public;
    function shift(uint, uint) public;
}

contract VatLike {
    function can(address, address) public view returns (uint);
    function ilks(bytes32) public view returns (uint, uint, uint, uint, uint);
    function dai(address) public view returns (uint);
    function urns(bytes32, address) public view returns (uint, uint);
    function frob(bytes32, address, address, address, int, int) public;
    function hope(address) public;
    function move(address, address, uint) public;
}

contract GemJoinLike {
    function dec() public returns (uint);
    function gem() public returns (GemLike);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}

contract DaiJoinLike {
    function vat() public returns (VatLike);
    function dai() public returns (GemLike);
    function join(address, uint) public payable;
    function exit(address, uint) public;
}

contract JugLike {
    function drip(bytes32) public returns (uint);
}

contract ProxyRegistryLike {
    function proxies(address) public view returns (address);
    function build(address) public returns (address);
}

contract ProxyLike {
    function owner() public view returns (address);
}





contract Common {
    uint256 constant RAY = 10 ** 27;



    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }



    function daiJoin_join(address apt, address urn, uint wad) public {

        DaiJoinLike(apt).dai().approve(apt, wad);

        DaiJoinLike(apt).join(urn, wad);
    }
}

contract DssProxyActions is Common {


    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint wad) internal pure returns (uint rad) {
        rad = mul(wad, 10 ** 27);
    }

    function convertTo18(address gemJoin, uint256 amt) internal returns (uint256 wad) {


        wad = mul(
            amt,
            10 ** (18 - GemJoinLike(gemJoin).dec())
        );
    }

    function _getDrawDart(
        address vat,
        address jug,
        address urn,
        bytes32 ilk,
        uint wad
    ) internal returns (int dart) {

        uint rate = JugLike(jug).drip(ilk);


        uint dai = VatLike(vat).dai(urn);


        if (dai < mul(wad, RAY)) {

            dart = toInt(sub(mul(wad, RAY), dai) / rate);

            dart = mul(uint(dart), rate) < mul(wad, RAY) ? dart + 1 : dart;
        }
    }

    function _getWipeDart(
        address vat,
        uint dai,
        address urn,
        bytes32 ilk
    ) internal view returns (int dart) {

        (, uint rate,,,) = VatLike(vat).ilks(ilk);

        (, uint art) = VatLike(vat).urns(ilk, urn);


        dart = toInt(dai / rate);

        dart = uint(dart) <= art ? - dart : - toInt(art);
    }

    function open(
        address manager,
        bytes32 ilk,
        address usr
    ) public returns (uint cdp) {
        cdp = ManagerLike(manager).open(ilk, usr);
    }

    function give(
        address manager,
        uint cdp,
        address usr
    ) public {
        ManagerLike(manager).give(cdp, usr);
    }

    function giveToProxy(
        address proxyRegistry,
        address manager,
        uint cdp,
        address dst
    ) public {

        address proxy = ProxyRegistryLike(proxyRegistry).proxies(dst);

        if (proxy == address(0) || ProxyLike(proxy).owner() != dst) {
            uint csize;
            assembly {
                csize := extcodesize(dst)
            }

            require(csize == 0, "Dst-is-a-contract");

            proxy = ProxyRegistryLike(proxyRegistry).build(dst);
        }

        give(manager, cdp, proxy);
    }

    function flux(
        address manager,
        uint cdp,
        address dst,
        uint wad
    ) public {
        ManagerLike(manager).flux(cdp, dst, wad);
    }

    function move(
        address manager,
        uint cdp,
        address dst,
        uint rad
    ) public {
        ManagerLike(manager).move(cdp, dst, rad);
    }

    function frob(
        address manager,
        uint cdp,
        int dink,
        int dart
    ) public {
        ManagerLike(manager).frob(cdp, dink, dart);
    }

    function gemJoin_join(address apt, address urn, uint wad) public {

      GemJoinLike(apt).gem().approve(apt, wad);

      GemJoinLike(apt).join(urn, wad);
    }

    function lockGemAndDraw(
        address manager,
        address jug,
        address gemJoin,
        address daiJoin,
        uint cdp,
        uint wadC,
        uint wadD
    ) public {
        address urn = ManagerLike(manager).urns(cdp);
        address vat = ManagerLike(manager).vat();
        bytes32 ilk = ManagerLike(manager).ilks(cdp);

        gemJoin_join(gemJoin, urn, wadC);

        frob(manager, cdp, toInt(convertTo18(gemJoin, wadC)), _getDrawDart(vat, jug, urn, ilk, wadD));

        move(manager, cdp, address(this), toRad(wadD));

        if (VatLike(vat).can(address(this), address(daiJoin)) == 0) {
            VatLike(vat).hope(daiJoin);
        }

        DaiJoinLike(daiJoin).exit(address(this), wadD);
    }

    function openLockGemAndDraw(
        address manager,
        address jug,
        address gemJoin,
        address daiJoin,
        bytes32 ilk,
        uint wadC,
        uint wadD
    ) public returns (uint cdp) {
        cdp = open(manager, ilk, address(this));
        lockGemAndDraw(manager, jug, gemJoin, daiJoin, cdp, wadC, wadD);
    }

    function wipeAndFreeGem(
        address manager,
        address gemJoin,
        address daiJoin,
        uint cdp,
        uint wadC,
        uint wadD
    ) public {
        address urn = ManagerLike(manager).urns(cdp);

        daiJoin_join(daiJoin, urn, wadD);
        uint wad18 = convertTo18(gemJoin, wadC);

        frob(
            manager,
            cdp,
            -toInt(wad18),
            _getWipeDart(ManagerLike(manager).vat(), VatLike(ManagerLike(manager).vat()).dai(urn), urn, ManagerLike(manager).ilks(cdp))
        );

        flux(manager, cdp, address(this), wad18);

        GemJoinLike(gemJoin).exit(address(this), wadC);
    }
}

contract DSSLeverage is ReentrancyGuard, Structs, Ownable, DssProxyActions  {

  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address constant public one = address(0x64D04c6dA4B0bC0109D7fC29c9D09c802C061898);
  address internal constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address internal constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address public constant usdcjoin = 0xA191e578a6736167326d05c119CE0c90849E84B7;
  address public constant daijoin = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
  address public constant jug = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
  address public constant manager = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
  address public constant proxy = 0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038;
  address public constant registry = 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4;
  bytes32 public constant usdcilk = 0x555344432d410000000000000000000000000000000000000000000000000000;
  address internal constant dydx = address(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);
  uint256 internal cdp;
  uint256 internal position;

  function leverage(uint256 _amount) public nonReentrant {
    IERC20(usdc).safeTransferFrom(msg.sender, address(this), _amount);

    cdp = 0;
    position = _amount.mul(4);

    Info[] memory infos = new Info[](1);
    ActionArgs[] memory args = new ActionArgs[](3);

    infos[0] = Info(address(this), 0);

    AssetAmount memory wamt = AssetAmount(false, AssetDenomination.Wei, AssetReference.Delta, position);
    ActionArgs memory withdraw;
    withdraw.actionType = ActionType.Withdraw;
    withdraw.accountId = 0;
    withdraw.amount = wamt;
    withdraw.primaryMarketId = 2;
    withdraw.otherAddress = address(this);

    args[0] = withdraw;

    ActionArgs memory call;
    call.actionType = ActionType.Call;
    call.accountId = 0;
    call.otherAddress = address(this);

    args[1] = call;

    ActionArgs memory deposit;
    AssetAmount memory damt = AssetAmount(true, AssetDenomination.Wei, AssetReference.Delta, position.add(1));
    deposit.actionType = ActionType.Deposit;
    deposit.accountId = 0;
    deposit.amount = damt;
    deposit.primaryMarketId = 2;
    deposit.otherAddress = address(this);

    args[2] = deposit;

    IERC20(usdc).safeApprove(dydx, uint256(-1));
    DyDx(dydx).operate(infos, args);
    IERC20(usdc).safeApprove(dydx, 0);

    uint256 _usdc = IERC20(usdc).balanceOf(address(this));
    uint256 _dai = IERC20(dai).balanceOf(address(this));

    if (_usdc > 0) {
      IERC20(usdc).safeTransfer(msg.sender, IERC20(usdc).balanceOf(address(this)));
    }
    if (_dai > 0) {
      IERC20(dai).safeTransfer(msg.sender, IERC20(dai).balanceOf(address(this)));
    }

    position = 0;
    cdp = 0;
  }

  function settle(uint256 _amount, uint256 _cdp) public nonReentrant {
    cdp = _cdp;
    position = 0;

    Info[] memory infos = new Info[](1);
    ActionArgs[] memory args = new ActionArgs[](3);

    infos[0] = Info(address(this), 0);

    AssetAmount memory wamt = AssetAmount(false, AssetDenomination.Wei, AssetReference.Delta, _amount);
    ActionArgs memory withdraw;
    withdraw.actionType = ActionType.Withdraw;
    withdraw.accountId = 0;
    withdraw.amount = wamt;
    withdraw.primaryMarketId = 3;
    withdraw.otherAddress = address(this);

    args[0] = withdraw;

    ActionArgs memory call;
    call.actionType = ActionType.Call;
    call.accountId = 0;
    call.otherAddress = address(this);

    args[1] = call;

    ActionArgs memory deposit;
    AssetAmount memory damt = AssetAmount(true, AssetDenomination.Wei, AssetReference.Delta, _amount.add(1));
    deposit.actionType = ActionType.Deposit;
    deposit.accountId = 0;
    deposit.amount = damt;
    deposit.primaryMarketId = 3;
    deposit.otherAddress = address(this);

    args[2] = deposit;

    IERC20(dai).safeApprove(dydx, uint256(-1));
    DyDx(dydx).operate(infos, args);
    IERC20(dai).safeApprove(dydx, 0);

    uint256 _usdc = IERC20(usdc).balanceOf(address(this));
    uint256 _dai = IERC20(dai).balanceOf(address(this));

    if (_usdc > 0) {
      IERC20(usdc).safeTransfer(msg.sender, IERC20(usdc).balanceOf(address(this)));
    }
    if (_dai > 0) {
      IERC20(dai).safeTransfer(msg.sender, IERC20(dai).balanceOf(address(this)));
    }

    cdp = 0;
    position = 0;
  }

  function callFunction(
      address sender,
      Info memory accountInfo,
      bytes memory data
  ) public {
    if (cdp > 0) {
      _settle();
    } else {
      _leverage();
    }
  }

  function _settle() internal {
    uint256 wadD = IERC20(dai).balanceOf(address(this));
    uint256 wadC = wadD.div(1e12);
    wipeAndFreeGem(
      manager,
      usdcjoin,
      daijoin,
      cdp,
      wadC,
      wadD
    );
    IERC20(usdc).safeApprove(one, uint256(-1));
    OneSplit(one).goodSwap(usdc, dai, IERC20(usdc).balanceOf(address(this)), 6, 1, 0);
    IERC20(usdc).safeApprove(one, 0);
  }

  function _leverage() internal {
    uint256 wadC = position;
    uint256 wadD = wadC.mul(1e12).mul(75).div(100);
    uint256 _cdp = openLockGemAndDraw(
      manager,
      jug,
      usdcjoin,
      daijoin,
      usdcilk,
      wadC,
      wadD
    );
    giveToProxy(
      registry,
      manager,
      _cdp,
      msg.sender
    );
    IERC20(dai).safeApprove(one, uint256(-1));
    OneSplit(one).goodSwap(dai, usdc, IERC20(dai).balanceOf(address(this)), 6, 1, 0);
    IERC20(dai).safeApprove(one, 0);
  }
}
