




pragma solidity ^0.6.6;


  interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);

     event Burn(address indexed from, uint256 value);

}
interface ERC223 {
    function transfer(address to, uint value, bytes calldata data)  external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

interface ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}



library SafeMath{
      function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        if (a == 0) {
        return 0;}
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;

        return c;
    }

}
library Address {

















    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }







    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }







    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");


        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }







    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }







    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");


        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

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
         function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

}



contract TokenContract is IERC20, Pausable,ERC223 {

    using SafeMath for uint256;


    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    address internal  _admin;
    uint256 private tokenSold;
    uint256 internal lockedBalance;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event transferredOwnership (address indexed previousOwner,address indexed currentOwner);

    uint256 private _totalShares;
    uint256 private _totalReleased;
      address[] public _payees;

      struct vestingDetails {
        address user;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool vestingStatus;
    }

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;

    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address=> vestingDetails) public vesting;


    constructor()   public  {
        _admin = msg.sender;
        _symbol = "NBK";
        _name = "Notebook";
        _decimals = 18;
        _totalSupply =  98054283* 10**uint(_decimals);
        balances[msg.sender]=_totalSupply;

    }

    modifier ownership()  {
    require(msg.sender == _admin);
        _;
    }



    function name() public view returns (string memory)
    {
        return _name;
    }

    function symbol() public view returns (string memory)
    {
        return _symbol;
    }
    function _tokenSold() public view returns(uint256) {
        return tokenSold;
    }

    function decimals() public view returns (uint8)
    {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256)
    {
        return _totalSupply;
    }


   function transfer(address _to, uint256 _value) public virtual override returns (bool) {
     require(_to != address(0));
     require(_value <= balances[msg.sender]);
     balances[msg.sender] = balances[msg.sender].sub(_value);
     balances[_to] = (balances[_to]).add( _value);

     emit IERC20.Transfer(msg.sender, _to, _value);
     tokenSold += _value;
     return true;

   }

  function balanceOf(address _owner) public override view returns (uint256 balance) {
    return balances[_owner];
   }

  function transferFrom(address _from, address _to, uint256 _value) public virtual override returns (bool) {
     require(_to != address(0));
     require(_value <= balances[_from]);
     require(_value <= allowed[_from][msg.sender]);

    balances[_from] = (balances[_from]).sub( _value);

    balances[_to] = (balances[_to]).add(_value);

    allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_value);
    tokenSold += _value;

    emit IERC20.Transfer(_from, _to, _value);
     return true;
   }

   function openVesting(address _user,uint256 _amount, uint256 _eTime) ownership public returns(bool)  {
      lockTokens(_amount);
      vesting[_user].user = _user;
      vesting[_user].amount= _amount;
      vesting[_user].startTime = now;
      vesting[_user].endTime = _eTime;
      vesting[_user].vestingStatus = true;
      return true;
  }

  function releaseVesting(address _user) ownership public returns(bool) {
      require(now > vesting[_user].endTime);
      vesting[_user].vestingStatus = false;
      unlockTokens(vesting[_user].amount);
      return true;
  }

   function approve(address _spender, uint256 _value) public override returns (bool) {
     allowed[msg.sender][_spender] = _value;
    emit IERC20.Approval(msg.sender, _spender, _value);
     return true;
   }

  function allowance(address _owner, address _spender) public override view returns (uint256) {
     return allowed[_owner][_spender];
   }



 function burn(uint256 _value) public ownership returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        _totalSupply -= _value;

        return true;
    }




    function burnFrom(address _from, uint256 _value) public ownership returns (bool success) {
        require(balances[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        _totalSupply -= _value;

        return true;
    }






  function transferownership(address _newaddress) ownership public returns(bool){
      require(_newaddress != address(0));
      emit transferredOwnership(_admin, _newaddress);
      _admin=_newaddress;
      return true;
  }
  function ownerAddress() public view returns(address) {
      return _admin;
  }
   function totalShares() public view returns (uint256) {
        return _totalShares;
    }




    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }




    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }




    function released(address account) public view returns (uint256) {
        return _released[account];
    }




    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }
     receive () external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }
    function distributeEthersToHolders (address[] memory payees, uint256[] memory amountOfEther) public payable {

        require(payees.length == amountOfEther.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], amountOfEther[i]);
        }
    }
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares.add(shares_);
        emit PayeeAdded(account, shares_);
    }
   function releaseEthersToHolder(address payable account) public   virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");
        uint256 totalReceived = address(this).balance.add(_totalReleased);
        uint256 payment = totalReceived.mul(_shares[account]).div(_totalShares).sub(_released[account]);
        require(payment != 0, "PaymentSplitter: account is not due payment");
        _released[account] = _released[account].add(payment);
        _totalReleased = _totalReleased.add(payment);
        account.transfer(payment);
        emit PaymentReleased(account, payment);
    }


    function pauseToken() public ownership whenNotPaused  {
        _pause();
    }
    function unPauseToken() public ownership whenPaused  {
        _unpause();

    }
    function transfer(address _to, uint _value, bytes memory _data) public virtual override returns (bool ){
        require(_value > 0 );
        if(isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        balances[msg.sender] = balances[msg.sender].sub(_value);

        balances[_to] = (balances[_to]).add( _value);

        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

  function isContract(address _addr) private view returns (bool is_contract) {
      uint length;
      assembly {

            length := extcodesize(_addr)
      }
      return (length>0);
    }
    function lockTokens(uint256 _amount) ownership public returns(bool){
        require( balances[_admin]>=_amount);
        balances[_admin] = balances[_admin].sub(_amount);
        lockedBalance = lockedBalance.add(_amount);

        return true;
  }

  function unlockTokens(uint256 _amount) ownership public returns (bool) {
        require(lockedBalance >= _amount);
        balances[_admin] = balances[_admin].add(_amount);

        lockedBalance = lockedBalance.sub(_amount);
        return true;
  }
  function  viewLockedBalance() ownership public view returns(uint256) {
        return lockedBalance;
  }





}




contract NBK is TokenContract {
   constructor ()  public  {

   }
    function transfer(address _to, uint256 _amount) public whenNotPaused override returns(bool) {
       return super.transfer(_to,_amount);
    }
    function transferFrom(address _from, address _to, uint256 _amount) public whenNotPaused override returns(bool) {
        return super.transferFrom(_from,_to,_amount);
    }
}
