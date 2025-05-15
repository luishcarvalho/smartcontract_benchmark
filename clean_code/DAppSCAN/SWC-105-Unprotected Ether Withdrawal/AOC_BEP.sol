

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./library/DateTime.sol";

















contract AOC_BEP is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using DateTimeLibrary for uint;

    struct Level {
        uint256 start;
        uint256 end;
        uint256 percentage;
    }

    struct UserInfo {
        uint256 balance;
        uint256 level;
        uint256 year;
        uint256 month;
    }

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public blacklisted;
    mapping (address => bool) public excludedFromRAMS;
    mapping (address => bool) public includedInLTAF;
    mapping(uint256 => Level) public levels;
    mapping(address => UserInfo) public userInfo;

    uint256 private _totalSupply;
    uint8 private constant _decimal = 18;
    string private constant _name = "Alpha Omega Coin";
    string private constant _symbol = "AOC BEP20";
    uint256 public ltafPercentage;


    event ExternalTokenTransfered(
        address from,
        address to,
        uint256 amount
    );

    event BNBFromContractTransferred(
        uint256 amount
    );

    event Blacklisted(
        string indexed action,
        address indexed to,
        uint256 at

    );

    event RemovedFromBlacklist(
        string indexed action,
        address indexed to,
        uint256 at
    );

    event IncludedInRAMS(
        address indexed account
    );

    event ExcludedFromRAMS(
        address indexed account
    );

    event IncludedInLTAF(
        address indexed account
    );

    event ExcludedFromLTAF(
        address indexed account
    );

    event LtafPercentageUpdated(
        uint256 percentage
    );










    function initialize() public initializer {

        _mint(_msgSender(), (1000 * 10**9 * 10**18));
        ltafPercentage = 50;

        addLevels(1, 1640995200, 1704153599, 20);
        addLevels(2, 1704153600, 1767311999, 15);
        addLevels(3, 1767312000, 1830383999, 10);
        addLevels(4, 1830384000, 0, 5);


        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __Context_init_unchained();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}




    function name() external view virtual override returns (string memory) {
        return _name;
    }





    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }














    function decimals() external view virtual override returns (uint8) {
        return _decimal;
    }




    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) external virtual override whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) external virtual override whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }














    function transferFrom(address sender, address recipient, uint256 amount) external virtual override whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) external virtual whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }






    function burn(uint256 amount) external virtual onlyOwner whenNotPaused returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }












    function burnFrom(address account, uint256 amount) external virtual onlyOwner whenNotPaused {
        uint256 currentAllowance = _allowances[account][_msgSender()];
        require(currentAllowance >= amount, "BEP20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    function blacklistUser(address _address) external onlyOwner whenNotPaused {
        require(!blacklisted[_address], "User is already blacklisted");
        blacklisted[_address] = true;
        emit Blacklisted("Blacklisted", _address, block.timestamp);
	}

	function removeFromBlacklist(address _address) external onlyOwner whenNotPaused {
	    require(blacklisted[_address], "User is not in the blacklist");
	    blacklisted[_address] = false;
	    emit RemovedFromBlacklist("Removed", _address, block.timestamp);

	}

    function includeInRAMS(address account) external onlyOwner whenNotPaused {
        require(excludedFromRAMS[account], "User is already included");
        excludedFromRAMS[account] = false;
        emit IncludedInRAMS(account);
	}

    function excludeFromRAMS(address account) external onlyOwner whenNotPaused {
        require(!excludedFromRAMS[account], "User is already excluded");
        excludedFromRAMS[account] = true;
        emit ExcludedFromRAMS(account);
	}

    function includeInLTAF(address account) external onlyOwner whenNotPaused {
        require(!includedInLTAF[account], "User is already included");
        includedInLTAF[account] = true;
        emit IncludedInLTAF(account);
	}

    function excludedFromLTAF(address account) external onlyOwner whenNotPaused {
        require(includedInLTAF[account], "User is already excluded");
        includedInLTAF[account] = false;
        emit ExcludedFromLTAF(account);
	}

    function updateLtafPercentage(uint256 percentage) external onlyOwner whenNotPaused {
        require(percentage > 0, "Percentage must be greater than zero");
        ltafPercentage = percentage;
        emit LtafPercentageUpdated(ltafPercentage);
    }






    function pauseContract() external virtual onlyOwner {
        _pause();
    }






    function unPauseContract() external virtual onlyOwner {
        _unpause();
    }



    function withdrawBNBFromContract(address payable recipient, uint256 amount) external onlyOwner payable {
        require(recipient != address(0), "Address cant be zero address");
        require(amount <= address(this).balance, "withdrawBNBFromContract: withdraw amount exceeds BNB balance");
        recipient.transfer(amount);
        emit BNBFromContractTransferred(amount);
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        require(_tokenContract != address(0), "Address cant be zero address");

		require(_amount > 0, "amount cannot be 0");
        IERC20Upgradeable tokenContract = IERC20Upgradeable(_tokenContract);
        require(tokenContract.balanceOf(address(this)) > _amount, "withdrawToken: withdraw amount exceeds token balance");
		tokenContract.transfer(msg.sender, _amount);
        emit ExternalTokenTransfered(_tokenContract, msg.sender, _amount);
	}


    receive() external payable {}















    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(!blacklisted[sender] || !blacklisted[recipient], "AOC: Cant't transfer, User is blacklisted");
        require(sender != address(0), "AOC: transfer from the zero address");
        require(recipient != address(0), "AOC: transfer to the zero address");

        if(includedInLTAF[sender] || !excludedFromRAMS[sender]) {

            (uint256 year, uint256 month, uint256 day) = DateTimeLibrary.timestampToDate(block.timestamp);
            if(day == 1 || year != userInfo[sender].year || month != userInfo[sender].month || userInfo[sender].level == 0) updateUserInfo(sender, year, month);

            if(includedInLTAF[sender]) {

                require(amount <= ((userInfo[sender].balance * ltafPercentage) / 10**2), "BEP20: Amount is higher than LTAF percentage");
            } else if(!excludedFromRAMS[sender]) {

                if(userInfo[sender].level > 0) require(amount <= ((userInfo[sender].balance * levels[userInfo[sender].level].percentage) / 10**2), "BEP20: Amount is higher");
            }
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function updateUserInfo(address account, uint256 year, uint256 month) internal {
        userInfo[account].balance = _balances[account];
        userInfo[account].year = year;
        userInfo[account].month = month;
        for(uint256 i = 1; i <= 4; i++) {
            if(i == 4) {
                userInfo[account].level = i;
                break;
            }
            if(block.timestamp >= levels[i].start && block.timestamp <= levels[i].end) {
                userInfo[account].level = i;
                break;
            }
        }
    }










    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function addLevels(uint256 level, uint256 startDay, uint256 endDay, uint256 percentage) internal {
        levels[level] = Level({
            start: startDay,
            end: endDay,
            percentage: percentage
        });
    }

}
