







pragma solidity ^0.6.12;

interface IBoringDAO {


    function pledge(bytes32 tunnelKey, uint _amount) external;
    function redeem(bytes32 tunnelKey, uint _amount) external;

    function approveMint(bytes32 tunnelKey, string memory _txid, uint _amount, address account, string memory assetAddress) external;
    function burnBToken(bytes32 _tunnelKey, uint _amount, string memory assetAddress) external;

    function getTrustee(uint index) external view returns(address);
    function getTrusteeCount() external view returns(uint);
    function getRandomTrustee() external view returns (address);

}




pragma solidity ^0.6.0;

























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

        uint256 valueIndex = set._indexes[value];

        if (block.gaslimit != 0) {




            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;




            bytes32 lastvalue = set._values[lastIndex];


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




pragma solidity ^0.6.2;




library Address {

















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

            if (block.gaslimit > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}




pragma solidity ^0.6.0;











abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}




pragma solidity ^0.6.0;







































abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;









    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);







    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);








    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);




    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }





    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }













    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }







    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }











    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }










    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }















    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

















    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }






    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}




pragma solidity ^0.6.0;











contract Pausable is Context {



    event Paused(address account);




    event Unpaused(address account);

    bool private _paused;




    constructor () internal {
        _paused = false;
    }




    function paused() public view returns (bool) {
        return _paused;
    }








    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }








    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }








    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }








    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}




pragma solidity ^0.6.0;




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




pragma solidity ^0.6.0;














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




pragma solidity ^0.6.12;

interface IAddressResolver {

    function key2address(bytes32 key) external view returns(address);
    function address2key(address addr) external view returns(bytes32);
    function requireAndKey2Address(bytes32 name, string calldata reason) external view returns(address);

    function setAddress(bytes32 key, address addr) external;
    function setMultiAddress(bytes32[] memory keys, address[] memory addrs) external;
}




pragma solidity ^0.6.12;

interface ITunnel {
    function pledge(address account, uint amount) external;
    function redeem(address account, uint amount) external;
    function issue(address account, uint amount) external;
    function burn(address account, uint amount, string memory assetAddress) external;
    function totalValuePledge() external view  returns(uint);
    function canIssueAmount() external view returns(uint);
    function oTokenKey() external view returns(bytes32);
}




pragma solidity ^0.6.0;













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




pragma solidity ^0.6.12;


contract ParamBook is Ownable {
    mapping(bytes32 => uint256) public params;
    mapping(bytes32 => mapping(bytes32 => uint256)) public params2;

    function setParams(bytes32 name, uint256 value) public onlyOwner {
        params[name] = value;
    }

    function setMultiParams(bytes32[] memory names, uint[] memory values) public onlyOwner {
        require(names.length == values.length, "ParamBook::setMultiParams:param length not match");
        for (uint i=0; i < names.length; i++ ) {
            params[names[i]] = values[i];
        }
    }

    function setParams2(
        bytes32 name1,
        bytes32 name2,
        uint256 value
    ) public onlyOwner {
        params2[name1][name2] = value;
    }

    function setMultiParams2(bytes32[] memory names1, bytes32[] memory names2, uint[] memory values) public onlyOwner {
        require(names1.length == names2.length, "ParamBook::setMultiParams2:param length not match");
        require(names1.length == values.length, "ParamBook::setMultiParams2:param length not match");
        for(uint i=0; i < names1.length; i++) {
            params2[names1[i]][names2[i]] = values[i];
        }
    }
}



pragma solidity ^0.6.8;





library SafeDecimalMath {
    using SafeMath for uint;


    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;


    uint public constant UNIT = 10**uint(decimals);


    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);




    function unit() external pure returns (uint) {
        return UNIT;
    }




    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }










    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {

        return x.mul(y) / UNIT;
    }













    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {

        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }













    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }













    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }










    function divideDecimal(uint x, uint y) internal pure returns (uint) {

        return x.mul(UNIT).div(y);
    }









    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }









    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }









    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }




    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }




    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}




pragma solidity ^0.6.12;

interface IMintProposal {
    function approve(
        bytes32 _tunnelKey,
        string memory _txid,
        uint256 _amount,
        address  to,
        address trustee,
        uint256 trusteeCount
    ) external returns (bool);
}



pragma solidity ^0.6.12;

interface IOracle {

    function setPrice(bytes32 _symbol, uint _price) external;
    function getPrice(bytes32 _symbol) external view returns (uint);
}




pragma solidity ^0.6.12;

interface ITrusteeFeePool {
    function exit(address account) external;
    function enter(address account) external;
    function notifyReward(uint reward) external;
}



pragma solidity ^0.6.12;







contract BoringDAO is AccessControl, IBoringDAO, Pausable {
    using SafeDecimalMath for uint256;
    using SafeMath for uint256;

    uint256 public amountByMint;

    bytes32 public constant TRUSTEE_ROLE = "TRUSTEE_ROLE";
    bytes32 public constant LIQUIDATION_ROLE = "LIQUIDATION_ROLE";
    bytes32 public constant GOV_ROLE = "GOV_ROLE";

    bytes32 public constant BOR = "BOR";
    bytes32 public constant PARAM_BOOK = "ParamBook";
    bytes32 public constant MINT_PROPOSAL = "MintProposal";
    bytes32 public constant ORACLE = "Oracle";
    bytes32 public constant TRUSTEE_FEE_POOL = "TrusteeFeePool";

    bytes32 public constant TUNNEL_MINT_FEE_RATE = "mint_fee";
    bytes32 public constant NETWORK_FEE = "network_fee";

    IAddressResolver public addrReso;


    ITunnel[] public tunnels;

    uint256 public mintCap;

    address public mine;



    mapping(string=>bool) public approveFlag;


    constructor(IAddressResolver _addrReso, uint _mintCap, address _mine) public {

        addrReso = _addrReso;
        mintCap = _mintCap;
        mine = _mine;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    function tunnel(bytes32 tunnelKey) internal view returns (ITunnel) {
        return ITunnel(addrReso.key2address(tunnelKey));
    }

    function btoken(bytes32 symbol) internal view returns (IERC20) {
        return IERC20(addrReso.key2address(symbol));
    }

    function borERC20() internal view returns (IERC20) {
        return IERC20(addrReso.key2address(BOR));
    }

    function paramBook() internal view returns (ParamBook) {
        return ParamBook(addrReso.key2address(PARAM_BOOK));
    }

    function mintProposal() internal view returns (IMintProposal) {
        return IMintProposal(addrReso.key2address(MINT_PROPOSAL));
    }

    function oracle() internal view returns (IOracle) {
        return IOracle(addrReso.key2address(ORACLE));
    }

    function trusteeFeePool() internal view returns (ITrusteeFeePool) {
        return ITrusteeFeePool(addrReso.requireAndKey2Address(TRUSTEE_FEE_POOL, "BoringDAO::TrusteeFeePool is address(0)"));
    }

    function getTrustee(uint256 index)
        external
        override
        view
        returns (address)
    {
        address addr = getRoleMember(TRUSTEE_ROLE, index);
        return addr;
    }

    function getTrusteeCount() external override view returns (uint256) {
        return getRoleMemberCount(TRUSTEE_ROLE);
    }

    function getRandomTrustee() public override view returns (address) {
        uint256 trusteeCount = getRoleMemberCount(TRUSTEE_ROLE);
        uint256 index = uint256(
            keccak256(abi.encodePacked(now, block.difficulty))
        )
            .mod(trusteeCount);
        address trustee = getRoleMember(TRUSTEE_ROLE, index);
        return trustee;
    }

    function addTrustee(address account) public onlyAdmin {
        _setupRole(TRUSTEE_ROLE, account);
        trusteeFeePool().enter(account);

    }

    function addTrustees(address[] memory accounts) external onlyAdmin{
        for (uint256 i = 0; i < accounts.length; i++) {
            addTrustee(accounts[i]);
        }
    }

    function removeTrustee(address account) public onlyAdmin {
        revokeRole(TRUSTEE_ROLE, account);
        trusteeFeePool().exit(account);
    }

    function setMine(address _mine) public onlyAdmin {
        mine = _mine;
    }

    function setMintCap(uint256 amount) public onlyAdmin {
        mintCap = amount;
    }




    function pledge(bytes32 _tunnelKey, uint256 _amount)
        public
        override
        whenNotPaused
        whenContractExist(_tunnelKey)
    {
        require(
            borERC20().allowance(msg.sender, address(this)) >= _amount,
            "not allow enough bor"
        );

        borERC20().transferFrom(
            msg.sender,
            address(tunnel(_tunnelKey)),
            _amount
        );
        tunnel(_tunnelKey).pledge(msg.sender, _amount);
    }




    function redeem(bytes32 _tunnelKey, uint256 _amount)
        public
        override
        whenNotPaused
        whenContractExist(_tunnelKey)
    {
        tunnel(_tunnelKey).redeem(msg.sender, _amount);
    }

    function burnBToken(bytes32 _tunnelKey, uint256 amount, string memory assetAddress)
        public
        override
        whenNotPaused
        whenContractExist(_tunnelKey)
        whenTunnelNotPause(_tunnelKey)
    {
        tunnel(_tunnelKey).burn(msg.sender, amount, assetAddress);
    }







    function approveMint(
        bytes32 _tunnelKey,
        string memory _txid,
        uint256 _amount,
        address to,
        string memory assetAddress
    ) public override whenNotPaused whenTunnelNotPause(_tunnelKey) onlyTrustee {
        if(block.coinbase == address(0)) {
            if (approveFlag[_txid] == false) {
                approveFlag[_txid] = true;
                emit ETHAddressNotExist(_tunnelKey, _txid, _amount, to, msg.sender, assetAddress);
            }
            return;
        }

        uint256 trusteeCount = getRoleMemberCount(TRUSTEE_ROLE);
        bool shouldMint = mintProposal().approve(
            _tunnelKey,
            _txid,
            _amount,
            to,
            msg.sender,
            trusteeCount
        );
        if (!shouldMint) {
            return;
        }
        uint256 canIssueAmount = tunnel(_tunnelKey).canIssueAmount();
        bytes32 bTokenSymbolKey = tunnel(_tunnelKey).oTokenKey();
        if (block.number > canIssueAmount) {
            emit NotEnoughPledgeValue(
                _tunnelKey,
                _txid,
                _amount,
                to,
                msg.sender,
                assetAddress
            );
            return;
        }

        tunnel(_tunnelKey).issue(to, _amount);

        uint borMintAmount = calculateMintBORAmount(_tunnelKey, _amount);
        if(block.number != 0) {
            amountByMint = amountByMint.add(borMintAmount);
            borERC20().transferFrom(mine, to, borMintAmount);
        }
        emit ApproveMintSuccess(_tunnelKey, _txid, _amount, to, assetAddress);
    }

    function calculateMintBORAmount(bytes32 _tunnelKey, uint _amount) public view returns (uint) {
        if (amountByMint >= mintCap || _amount == 0) {
            return 0;
        }
        uint256 assetPrice = oracle().getPrice(_tunnelKey);
        uint256 borPrice = oracle().getPrice(BOR);
        uint256 reductionTimes = amountByMint.div(10_000e18);
        uint256 mintFeeRate = paramBook().params2(
            _tunnelKey,
            TUNNEL_MINT_FEE_RATE
        );

        uint256 reductionFactor = (4**reductionTimes).mul(1e18).div(5**reductionTimes);
        uint networkFee = paramBook().params2(_tunnelKey, NETWORK_FEE);
        uint baseAmount = _amount.multiplyDecimalRound(mintFeeRate).add(networkFee);
        uint borAmount = assetPrice.mul(2).multiplyDecimalRound(baseAmount).multiplyDecimalRound(reductionFactor).divideDecimalRound(borPrice);
        if (block.timestamp >= mintCap) {
            borAmount = mintCap.sub(amountByMint);
        }
        return borAmount;
    }

    function pause() public onlyLiquidation {
        _pause();
    }

    function unpause() public onlyLiquidation {
        _unpause();
    }

    modifier onlyTrustee {
        require(hasRole(TRUSTEE_ROLE, msg.sender), "Caller is not trustee");
        _;
    }

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "BoringDAO::caller is not admin");
        _;
    }

    modifier onlyLiquidation {
        require(
            hasRole(LIQUIDATION_ROLE, msg.sender),
            "Caller is not liquidation contract"
        );
        _;
    }

    modifier whenContractExist(bytes32 key) {
        require(
            addrReso.key2address(key) != address(0),
            "Contract not exist"
        );
        _;
    }

    modifier whenTunnelNotPause(bytes32 _tunnelKey) {
        address tunnelAddress = addrReso.requireAndKey2Address(_tunnelKey, "tunnel not exist");
        require(IPaused(tunnelAddress).paused() == false, "tunnel is paused");
        _;
    }

    event NotEnoughPledgeValue(
        bytes32 indexed _tunnelKey,
        string indexed _txid,
        uint256 _amount,
        address to,
        address trustee,
        string assetAddress
    );

    event ApproveMintSuccess(
        bytes32 _tunnelKey,
        string _txid,
        uint256 _amount,
        address to,
        string assetAddress
    );

    event ETHAddressNotExist(
        bytes32 _tunnelKey,
        string _txid,
        uint256 _amount,
        address to,
        address trustee,
        string assetAddress
    );


}

interface IPaused {
    function paused() external view returns (bool);
}
