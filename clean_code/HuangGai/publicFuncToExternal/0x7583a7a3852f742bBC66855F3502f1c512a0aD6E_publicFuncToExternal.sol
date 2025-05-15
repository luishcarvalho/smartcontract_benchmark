





pragma solidity 0.6.8;






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
}











abstract contract Proxy {





  receive () payable external {
    _fallback();
  }





  fallback () payable external {
    _fallback();
  }




  function _implementation() internal virtual view returns (address);







  function _delegate(address implementation) internal {
    assembly {



      calldatacopy(0, 0, calldatasize())



      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)


      returndatacopy(0, 0, returndatasize())

      switch result

      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }






  function _willFallback() internal virtual {
  }





  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}










contract BaseUpgradeabilityProxy is Proxy {




    event Upgraded(address indexed implementation);






    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;





    function _implementation() internal override view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }





    function _setImplementation(address newImplementation) internal {
        require(
            Address.isContract(newImplementation),
            "Implementation not set"
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
        emit Upgraded(newImplementation);
    }
}











contract AdminUpgradeabilityProxy is BaseUpgradeabilityProxy {





  event AdminChanged(address previousAdmin, address newAdmin);







  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;









  constructor(address _logic, address _admin) public payable {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    _setImplementation(_logic);
    _setAdmin(_admin);
  }






  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }




  function admin() public ifAdmin returns (address) {
    return _admin();
  }




  function implementation() public ifAdmin returns (address) {
    return _implementation();
  }






  function changeAdmin(address newAdmin) public ifAdmin {
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }






  function changeImplementation(address newImplementation) public ifAdmin {
    _setImplementation(newImplementation);
  }




  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }





  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
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











library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }








    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
















contract Initializable {




  bool private initialized;




  bool private initializing;




  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }


  function isConstructor() private view returns (bool) {





    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }


  uint256[50] private ______gap;
}







contract Account is Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;




    event Withdrawn(address indexed tokenAddress, address indexed targetAddress, uint256 amount);




    event Approved(address indexed tokenAddress, address indexed targetAddress, uint256 amount);




    event Invoked(address indexed targetAddress, uint256 value, bytes data);

    address public owner;
    mapping(address => bool) public admins;
    mapping(address => bool) public operators;






    function initialize(address _owner, address[] memory _initialAdmins) public initializer {
        owner = _owner;

        for (uint256 i = 0; i < _initialAdmins.length; i++) {
            admins[_initialAdmins[i]] = true;
        }
    }




    modifier onlyOperator() {
        require(isOperator(msg.sender), "not operator");
        _;
    }






    function transferOwnership(address _owner) public {
        require(msg.sender == owner, "not owner");
        owner = _owner;
    }





    function grantAdmin(address _account) public {
        require(msg.sender == owner, "not owner");
        require(!admins[_account], "already admin");

        admins[_account] = true;
    }





    function revokeAdmin(address _account) public {
        require(msg.sender == owner, "not owner");
        require(admins[_account], "not admin");

        admins[_account] = false;
    }





    function grantOperator(address _account) public {
        require(msg.sender == owner || admins[msg.sender], "not admin");
        require(!operators[_account], "already operator");

        operators[_account] = true;
    }





    function revokeOperator(address _account) public {
        require(msg.sender == owner || admins[msg.sender], "not admin");
        require(operators[_account], "not operator");

        operators[_account] = false;
    }




    receive() payable external {}







    function isOperator(address userAddress) public view returns (bool) {
        return userAddress == owner || admins[userAddress] || operators[userAddress];
    }






    function withdraw(address payable targetAddress, uint256 amount) public onlyOperator {
        targetAddress.transfer(amount);

        emit Withdrawn(address(-1), targetAddress, amount);
    }







    function withdrawToken(address tokenAddress, address targetAddress, uint256 amount) public onlyOperator {
        IERC20(tokenAddress).safeTransfer(targetAddress, amount);
        emit Withdrawn(tokenAddress, targetAddress, amount);
    }









    function withdrawTokenFallThrough(address tokenAddress, address targetAddress, uint256 amount) public onlyOperator {
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));

        if (tokenBalance >= amount) {
            IERC20(tokenAddress).safeTransfer(targetAddress, amount);
            emit Withdrawn(tokenAddress, targetAddress, amount);
        } else {
            IERC20(tokenAddress).safeTransferFrom(owner, targetAddress, amount.sub(tokenBalance));
            IERC20(tokenAddress).safeTransfer(targetAddress, tokenBalance);
            emit Withdrawn(tokenAddress, targetAddress, amount);
        }
    }







    function approveToken(address tokenAddress, address targetAddress, uint256 amount) public onlyOperator {
        IERC20(tokenAddress).safeApprove(targetAddress, 0);
        IERC20(tokenAddress).safeApprove(targetAddress, amount);
        emit Approved(tokenAddress, targetAddress, amount);
    }







    function invoke(address target, uint256 value, bytes memory data) public onlyOperator returns (bytes memory result) {
        bool success;
        (success, result) = target.call{value: value}(data);
        if (!success) {

            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        emit Invoked(target, value, data);
    }
}





contract AccountFactory {




    event AccountCreated(address indexed userAddress, address indexed accountAddress);

    address public governance;
    address public accountBase;
    mapping(address => address) public accounts;





    constructor(address _accountBase) public {
        require(_accountBase != address(0x0), "account base not set");
        governance = msg.sender;
        accountBase = _accountBase;
    }




    function setAccountBase(address _accountBase) public {
        require(msg.sender == governance, "not governance");
        require(_accountBase != address(0x0), "account base not set");

        accountBase = _accountBase;
    }





    function setGovernance(address _governance) public {
        require(msg.sender == governance, "not governance");
        governance = _governance;
    }







    function createAccount(address[] memory _initialAdmins) public returns (Account) {
        AdminUpgradeabilityProxy proxy = new AdminUpgradeabilityProxy(accountBase, msg.sender);
        Account account = Account(address(proxy));
        account.initialize(msg.sender, _initialAdmins);
        accounts[msg.sender] = address(account);

        emit AccountCreated(msg.sender, address(account));

        return account;
    }
}
