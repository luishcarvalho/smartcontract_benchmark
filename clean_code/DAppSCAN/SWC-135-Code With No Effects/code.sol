




pragma solidity >=0.6.0 <0.8.0;











abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

pragma solidity >=0.6.0 <0.8.0;




interface IBEP20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.6.0 <0.8.0;














library SafeMath {





    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }






    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }






    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {



        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }






    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }






    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }











    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }













    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }














    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
















    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
















    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.6.0 <0.8.0;




























contract BEP20 is Context, IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;










    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }




    function name() public view virtual returns (string memory) {
        return _name;
    }





    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }














    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }




    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }














    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }








    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }















    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity >=0.6.0 <0.8.0;








abstract contract BEP20Burnable is Context, BEP20 {
    using SafeMath for uint256;






    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }












    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "BEP20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

pragma solidity >=0.6.2 <0.8.0;




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

pragma solidity >=0.6.0 <0.8.0;













abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view virtual returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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



pragma solidity 0.7.6;




contract ASVA is BEP20Burnable, Ownable {
    using SafeMath for uint256;

    uint256 private constant initialSupply = 90e6 * 10 ** 18;

    uint256 public constant seedPrice = 10;

    uint256 public constant privatePrice = 20;

    uint256 public constant publicPrice = 30;

    uint256 public constant seedTokenPercentage = 750;

    uint256 public constant privateSalePercentage = 2000;

    uint256 public constant publicSalePercentage = 1250;

    uint256 public constant liquidityPercentage = 1500;

    uint256 public constant teamPercentage = 1000;

    uint256 public constant partnersPercentage = 500;

    uint256 public constant stakingPercentage = 2000;

    uint256 public constant marketingPercentage = 500;

    uint256 public constant reserveFundPercentage = 500;
    uint256 public seedToken;
    uint256 public privateSaleToken;
    uint256 public publicSaleToken;
    uint256 public liquidityToken;
    uint256 public teamToken;
    uint256 public marketingToken;
    uint256 public partnersToken;
    uint256 public stakingToken;
    uint256 public reserveToken;
    uint256 public constant percentageDivider = 10000;

    constructor(address _user) BEP20("Asva finance", "ASVA") {
        seedToken = (initialSupply.mul(seedTokenPercentage)).div(percentageDivider);
        privateSaleToken = (initialSupply.mul(privateSalePercentage)).div(percentageDivider);
        publicSaleToken = (initialSupply.mul(publicSalePercentage)).div(percentageDivider);
        liquidityToken = (initialSupply.mul(liquidityPercentage)).div(percentageDivider);
        teamToken = (initialSupply.mul(teamPercentage)).div(percentageDivider);
        marketingToken = (initialSupply.mul(marketingPercentage)).div(percentageDivider);
        partnersToken = (initialSupply.mul(partnersPercentage)).div(percentageDivider);
        stakingToken = (initialSupply.mul(stakingPercentage)).div(percentageDivider);
        reserveToken = (initialSupply.mul(reserveFundPercentage)).div(percentageDivider);
        _mint(_user, initialSupply);
    }


    receive() payable external {
        payable(owner()).transfer(msg.value);
    }

    function fallabck() public payable {
        payable(owner()).transfer(getBalance());
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
}
