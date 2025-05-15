



pragma solidity ^0.6.2;














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

contract Ownable {



    mapping(address => uint256) public owner;
    uint256 index = 0;




    constructor() public {
        owner[msg.sender] = ++index;
    }




    modifier onlyOwner() {
        require(owner[msg.sender] > 0, "onlyOwner exception");
        _;
    }






    function addNewOwner(address newOwner) public onlyOwner returns(bool) {
        owner[newOwner] = ++index;
        return true;
    }






    function removeOwner(address removedOwner) public onlyOwner returns(bool) {
        require(msg.sender != removedOwner, "Denied deleting of yourself");
        owner[removedOwner] = 0;
        return true;
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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;










    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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




    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        revert("Transfers are not allowed");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }








    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }















    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract ETHSteps is ERC20, Ownable {
    address public stepMarket;

    constructor()
    ERC20("CoinClash", "CoC")
    public {}

    function init(address _stepMarket) public onlyOwner {
        stepMarket = _stepMarket;
    }






    function mint(address _to, uint256 _value) public {
        require(msg.sender == stepMarket, "address not stepmarket");
        _mint(_to, _value);
    }






    function burnFrom(address _from, uint256 _value) public {
        require(msg.sender == stepMarket, "address not stepmarket");
        _burn(_from, _value);
    }
}

contract ETHStepMarket is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public percentages;
    address[] public admins;
    ETHSteps public stepAddress;
    uint256 public adminPart;
    uint256 public treasurePart;
    uint256 public commissionPart;




    event WithdrawAdminProcessed(
        address caller,
        uint256 amount,
        uint256 timestamp
    );
    event AdminAddressAdded(
        address newAddress,
        uint256 percentage
    );
    event AdminAddressRemoved(
        address oldAddress
    );
    event AdminPercentageChanged(
        address admin,
        uint256 newPercentage
    );
    event StepsAirdropped(
        address indexed user,
        uint256 amount
    );
    event AirdropDeposited(
        address indexed user,
        uint256 amount
    );
    event StepsBoughtViaEth(
        address indexed user,
        uint256 ethAmount
    );
    event TreasureAdded(uint256 amount);
    event WithdrawEmitted(address indexed user);
    event EmitInternalDrop(address indexed user);
    event AccessChanged(bool status);

    function init(address _stepAddress) public onlyOwner {
        stepAddress = ETHSteps(_stepAddress);
    }






    function airdropToMany(
        address[] memory _user,
        uint256[] memory _amount
    ) public onlyOwner {
        require(_user.length == _amount.length, "Length must be equal");

        for (uint256 i = 0; i < _user.length; i++) {
            stepAddress.mint(_user[i], _amount[i].mul(1 ether));

            emit StepsAirdropped(_user[i], _amount[i].mul(1 ether));
        }
    }

    function sendRewardToMany(
        address[] memory _user,
        uint256[] memory _amount,
        uint256 totaRewardSent
    ) public onlyOwner {
        require(_user.length == _amount.length, "Length must be equal");
        require(treasurePart >= totaRewardSent);

        treasurePart = treasurePart.sub(totaRewardSent);

        for (uint256 i = 0; i < _user.length; i++) {
            address(uint160(_user[i])).transfer(_amount[i]);
        }
    }

    function receiveCommission() public onlyOwner {
        require(commissionPart > 0);

        commissionPart = 0;

        msg.sender.transfer(commissionPart);
    }

    function getInternalAirdrop() public {
        stepAddress.mint(msg.sender, 1 ether);
        stepAddress.burnFrom(msg.sender, 1 ether);

        emit EmitInternalDrop(msg.sender);
    }

    function buySteps() public payable {
        require(msg.value != 0, "value can't be 0");

        stepAddress.mint(msg.sender, msg.value);
        stepAddress.burnFrom(msg.sender, msg.value);

        adminPart = adminPart.add(msg.value.mul(80).div(100));
        treasurePart = treasurePart.add(msg.value.mul(20).div(100));

        emit StepsBoughtViaEth(
            msg.sender,
            msg.value
        );
    }

    function depositToGame() public {
        require(stepAddress.balanceOf(msg.sender) != 0, "No tokens for deposit");

        emit AirdropDeposited(
            msg.sender,
            stepAddress.balanceOf(msg.sender)
        );

        stepAddress.burnFrom(msg.sender, stepAddress.balanceOf(msg.sender));
    }

    function addAdmin(address _admin, uint256 _percentage) public onlyOwner {
        require(percentages[_admin] == 0, "Admin exists");

        admins.push(_admin);
        percentages[_admin] = _percentage;

        emit AdminAddressAdded(
            _admin,
            _percentage
        );
    }

    function addToTreasure() public payable {
        treasurePart = treasurePart.add(msg.value);

        emit TreasureAdded(
            msg.value
        );
    }

    function emitWithdrawal() public payable {
        require(msg.value >= 4 finney);

        commissionPart = commissionPart.add(msg.value);

        emit WithdrawEmitted(
            msg.sender
        );
    }

    function changePercentage(
        address _admin,
        uint256 _percentage
    ) public onlyOwner {
        percentages[_admin] = _percentage;

        emit AdminPercentageChanged(
            _admin,
            _percentage
        );
    }

    function deleteAdmin(address _removedAdmin) public onlyOwner {
        uint256 found = 0;
        for (uint256 i = 0; i < admins.length; i++) {
            if (block.coinbase == _removedAdmin) {
                found = i;
            }
        }

        for (uint256 i = found; i < admins.length - 1; i++) {
            admins[i] = admins[i + 1];
        }

        admins.pop();

        percentages[_removedAdmin] = 0;

        emit AdminAddressRemoved(_removedAdmin);
    }

    function withdrawAdmins() public payable {
        uint256 percent = 0;

        for (uint256 i = 0; i < admins.length; i++) {
            percent = percent.add(percentages[admins[i]]);
        }

        require(percent == 10000, "Total admin percent must be 10000 or 100,00%");

        for (uint256 i = 0; i < admins.length; i++) {
            uint256 amount = adminPart.mul(percentages[admins[i]]).div(10000);
            address(uint160(admins[i])).transfer(amount);
        }

        emit WithdrawAdminProcessed(
            msg.sender,
            adminPart,
            block.timestamp
        );

        adminPart = 0;
    }
}
