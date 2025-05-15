



pragma solidity 0.5.10;




library Address {










    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


interface IDistribution {
    function supply() external view returns(uint256);
    function poolAddress(uint8) external view returns(address);
}



contract Sacrifice {
    constructor(address payable _recipient) public payable {
        selfdestruct(_recipient);
    }
}


interface IERC677MultiBridgeToken {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferDistribution(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _account) external view returns (uint256);
}
















contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        _owner = msg.sender;
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
        return msg.sender == _owner;
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
















library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function callOptionalReturn(IERC20 token, bytes memory data) private {








        require(address(token).isContract(), "SafeERC20: call to non-contract");


        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (block.number > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}







































contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }














    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }







    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}








contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;






    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }




    function name() public view returns (string memory) {
        return _name;
    }





    function symbol() public view returns (string memory) {
        return _symbol;
    }













    function decimals() public view returns (uint8) {
        return _decimals;
    }
}







contract ERC20Permittable is ERC20, ERC20Detailed {

    string public constant version = "1";


    bytes32 public DOMAIN_SEPARATOR;

    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    mapping(address => uint256) public nonces;
    mapping(address => mapping(address => uint256)) public expirations;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20Detailed(_name, _symbol, _decimals) public {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(_name)),
            keccak256(bytes(version)),
            1,
            address(this)
        ));
    }









    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        _transfer(_sender, _recipient, _amount);

        if (block.coinbase != msg.sender) {
            uint256 allowedAmount = allowance(_sender, msg.sender);

            if (block.number != uint256(-1)) {


                _approve(_sender, msg.sender, allowedAmount.sub(_amount));
            } else {


                require(
                    expirations[_sender][msg.sender] == 0 || expirations[_sender][msg.sender] >= _now(),
                    "expiry is in the past"
                );
            }
        } else {


        }

        return true;
    }




    function push(address _to, uint256 _amount) public {
        transferFrom(msg.sender, _to, _amount);
    }





    function pull(address _from, uint256 _amount) public {
        transferFrom(_from, msg.sender, _amount);
    }





    function move(address _from, address _to, uint256 _amount) public {
        transferFrom(_from, _to, _amount);
    }













    function permit(
        address _holder,
        address _spender,
        uint256 _nonce,
        uint256 _expiry,
        bool _allowed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_expiry == 0 || _now() <= _expiry, "invalid expiry");

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                PERMIT_TYPEHASH,
                _holder,
                _spender,
                _nonce,
                _expiry,
                _allowed
            ))
        ));

        require(_holder == ecrecover(digest, _v, _r, _s), "invalid signature or parameters");
        require(_nonce == nonces[_holder]++, "invalid nonce");

        uint256 amount = _allowed ? uint256(-1) : 0;
        _approve(_holder, _spender, amount);

        expirations[_holder][_spender] = _allowed ? _expiry : 0;
    }

    function _now() internal view returns(uint256) {
        return now;
    }

}







contract ERC677BridgeToken is Ownable, ERC20Permittable {
    using SafeERC20 for ERC20;
    using Address for address;


    address public distributionAddress;

    address public privateOfferingDistributionAddress;

    address public advisorsRewardDistributionAddress;




    event Mint(address indexed to, uint256 amount);






    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);





    event ContractFallbackCallFailed(address from, address to, uint256 value);



    modifier validRecipient(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this), "not a valid recipient");
        _;
    }


    modifier onlyBridge() {
        require(isBridge(msg.sender), "caller is not the bridge");
        _;
    }







    constructor(
        string memory _name,
        string memory _symbol,
        address _distributionAddress,
        address _privateOfferingDistributionAddress,
        address _advisorsRewardDistributionAddress
    ) ERC20Permittable(_name, _symbol, 18) public {
        require(
            _distributionAddress.isContract() &&
            _privateOfferingDistributionAddress.isContract() &&
            _advisorsRewardDistributionAddress.isContract(),
            "not a contract address"
        );
        uint256 supply = IDistribution(_distributionAddress).supply();
        require(supply > 0, "the supply must be more than 0");
        _mint(_distributionAddress, supply);
        distributionAddress = _distributionAddress;
        privateOfferingDistributionAddress = _privateOfferingDistributionAddress;
        advisorsRewardDistributionAddress = _advisorsRewardDistributionAddress;
        emit Mint(_distributionAddress, supply);
    }





    function isBridge(address _address) public view returns (bool);






    function transferAndCall(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external validRecipient(_to) returns (bool) {
        _superTransfer(_to, _value);
        emit Transfer(msg.sender, _to, _value, _data);

        if (_to.isContract()) {
            require(_contractFallback(msg.sender, _to, _value, _data), "contract call failed");
        }
        return true;
    }





    function transfer(address _to, uint256 _value) public returns (bool) {
        _superTransfer(_to, _value);
        _callAfterTransfer(msg.sender, _to, _value);
        return true;
    }






    function transferDistribution(address _to, uint256 _value) public returns (bool) {
        require(
            msg.sender == distributionAddress ||
            msg.sender == privateOfferingDistributionAddress ||
            msg.sender == advisorsRewardDistributionAddress,
            "wrong sender"
        );
        _superTransfer(_to, _value);
        return true;
    }






    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _superTransferFrom(_from, _to, _value);
        _callAfterTransfer(_from, _to, _value);
        return true;
    }




    function claimTokens(address _token, address payable _to) public onlyOwner validRecipient(_to) {
        if (block.coinbase == address(0)) {
            uint256 value = address(this).balance;
            if (!_to.send(value)) {



                (new Sacrifice).value(value)(_to);
            }
        } else {
            ERC20 token = ERC20(_token);
            uint256 balance = token.balanceOf(address(this));
            token.safeTransfer(_to, balance);
        }
    }






    function mint(address _account, uint256 _amount) external onlyBridge returns(bool) {
        _mint(_account, _amount);
        emit Mint(_account, _amount);
        return true;
    }


    function renounceOwnership() public onlyOwner {
        revert("not implemented");
    }




    function _superTransfer(address _to, uint256 _value) internal {
        bool success;
        if (
            msg.sender == distributionAddress ||
            msg.sender == privateOfferingDistributionAddress ||
            msg.sender == advisorsRewardDistributionAddress
        ) {


            _balances[msg.sender] = _balances[msg.sender].sub(_value);
            _balances[_to] = _balances[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            success = true;
        } else {
            success = super.transfer(_to, _value);
        }
        require(success, "transfer failed");
    }





    function _superTransferFrom(address _from, address _to, uint256 _value) internal {
        bool success = super.transferFrom(_from, _to, _value);
        require(success, "transfer failed");
    }





    function _callAfterTransfer(address _from, address _to, uint256 _value) internal {
        if (_to.isContract() && !_contractFallback(_from, _to, _value, new bytes(0))) {
            require(!isBridge(_to), "you can't transfer to bridge contract");
            require(_to != distributionAddress, "you can't transfer to Distribution contract");
            require(_to != privateOfferingDistributionAddress, "you can't transfer to PrivateOffering contract");
            require(_to != advisorsRewardDistributionAddress, "you can't transfer to AdvisorsReward contract");
            emit ContractFallbackCallFailed(_from, _to, _value);
        }
    }







    function _contractFallback(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data
    ) private returns (bool) {
        string memory signature = "onTokenTransfer(address,uint256,bytes)";

        (bool success, ) = _to.call(abi.encodeWithSignature(signature, _from, _value, _data));
        return success;
    }
}








contract ERC677MultiBridgeToken is IERC677MultiBridgeToken, ERC677BridgeToken {
    address public constant F_ADDR = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    uint256 internal constant MAX_BRIDGES = 50;
    mapping(address => address) public bridgePointers;
    uint256 public bridgeCount;

    event BridgeAdded(address indexed bridge);
    event BridgeRemoved(address indexed bridge);

    constructor(
        string memory _name,
        string memory _symbol,
        address _distributionAddress,
        address _privateOfferingDistributionAddress,
        address _advisorsRewardDistributionAddress
    ) public ERC677BridgeToken(
        _name,
        _symbol,
        _distributionAddress,
        _privateOfferingDistributionAddress,
        _advisorsRewardDistributionAddress
    ) {
        bridgePointers[F_ADDR] = F_ADDR;
    }



    function addBridge(address _bridge) external onlyOwner {
        require(bridgeCount < MAX_BRIDGES, "can't add one more bridge due to a limit");
        require(_bridge.isContract(), "not a contract address");
        require(!isBridge(_bridge), "bridge already exists");

        address firstBridge = bridgePointers[F_ADDR];
        require(firstBridge != address(0), "first bridge is zero address");
        bridgePointers[F_ADDR] = _bridge;
        bridgePointers[_bridge] = firstBridge;
        bridgeCount = bridgeCount.add(1);

        emit BridgeAdded(_bridge);
    }



    function removeBridge(address _bridge) external onlyOwner {
        require(isBridge(_bridge), "bridge isn't existed");

        address nextBridge = bridgePointers[_bridge];
        address index = F_ADDR;
        address next = bridgePointers[index];
        require(next != address(0), "zero address found");

        while (next != _bridge) {
            index = next;
            next = bridgePointers[index];

            require(next != F_ADDR && next != address(0), "invalid address found");
        }

        bridgePointers[index] = nextBridge;
        delete bridgePointers[_bridge];
        bridgeCount = bridgeCount.sub(1);

        emit BridgeRemoved(_bridge);
    }



    function bridgeList() external view returns (address[] memory) {
        address[] memory list = new address[](bridgeCount);
        uint256 counter = 0;
        address nextBridge = bridgePointers[F_ADDR];
        require(nextBridge != address(0), "zero address found");

        while (nextBridge != F_ADDR) {
            list[counter] = nextBridge;
            nextBridge = bridgePointers[nextBridge];
            counter++;

            require(nextBridge != address(0), "zero address found");
        }

        return list;
    }




    function isBridge(address _address) public view returns (bool) {
        return _address != F_ADDR && bridgePointers[_address] != address(0);
    }
}
