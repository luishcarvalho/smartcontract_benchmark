
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {VaultAPI, BaseWrapper} from "./BaseWrapper.sol";

contract yToken is IERC20, BaseWrapper {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(address _token, address _registry) public BaseWrapper(_token, _registry) {}

    function name() external view returns (string memory) {
        VaultAPI _bestVault = bestVault();
        return _bestVault.name();
    }

    function symbol() external view returns (string memory) {
        VaultAPI _bestVault = bestVault();
        return _bestVault.symbol();
    }

    function decimals() external view returns (uint256) {
        VaultAPI _bestVault = bestVault();
        return _bestVault.decimals();
    }

    function totalSupply() external override view returns (uint256 total) {
        return totalAssets();
    }

    function balanceOf(address account) external override view returns (uint256 balance) {
        return totalVaultBalance(account);
    }

    function _transfer(
        address sender,
        address receiver,
        uint256 amount
    ) internal {
        require(receiver != address(0), "ERC20: transfer to the zero address");
        require(amount == _withdraw(sender, receiver, amount, true));
        emit Transfer(sender, receiver, amount);
    }

    function transfer(address receiver, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, receiver, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address receiver,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, receiver, amount);
        _approve(sender, msg.sender, allowance[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function deposit(uint256 amount) external returns (uint256) {
        return _deposit(msg.sender, msg.sender, amount, true);
    }

    function withdraw(uint256 amount) external returns (uint256) {
        return _withdraw(msg.sender, msg.sender, amount, true);
    }

    function _permitAll(
        address user,
        VaultAPI[] calldata vaults,
        bytes[] calldata signatures
    ) internal {
        require(vaults.length == signatures.length);

        for (uint256 i = 0; i < vaults.length; i++) {
            require(vaults[i].permit(user, address(this), uint256(-1), 0, signatures[i]));
        }
    }

    function permitAll(VaultAPI[] calldata vaults, bytes[] calldata signatures) public {
        _permitAll(msg.sender, vaults, signatures);
    }

    function migrate() external returns (uint256) {
        return _migrate(msg.sender);
    }

    function migrate(uint256 amount) external returns (uint256) {
        return _migrate(msg.sender, amount);
    }

    function migrate(uint256 amount, uint256 maxMigrationLoss) external returns (uint256) {
        return _migrate(msg.sender, amount, maxMigrationLoss);
    }

    function migrate(VaultAPI[] calldata vaults, bytes[] calldata signatures) external returns (uint256) {
        _permitAll(msg.sender, vaults, signatures);
        return _migrate(msg.sender);
    }

    function migrate(
        VaultAPI[] calldata vaults,
        bytes[] calldata signatures,
        uint256 amount
    ) external returns (uint256) {
        _permitAll(msg.sender, vaults, signatures);
        return _migrate(msg.sender, amount);
    }

    function migrate(
        VaultAPI[] calldata vaults,
        bytes[] calldata signatures,
        address user,
        uint256 amount
    ) external returns (uint256) {
        _permitAll(user, vaults, signatures);
        return _migrate(user, amount);
    }

    function revokeAll(VaultAPI[] calldata vaults, bytes[] calldata signatures) external {
        require(vaults.length == signatures.length);

        for (uint256 i = 0; i < vaults.length; i++) {
            require(vaults[i].permit(msg.sender, address(this), 0, 0, signatures[i]));
        }
    }
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract yWETH is yToken {
    using Address for address payable;

    constructor(address _weth, address _registry) public yToken(_weth, _registry) {}

    function depositETH() public payable returns (uint256) {
        uint256 amount = msg.value;

        IWETH(address(token)).deposit{value: amount}();


        return _deposit(address(this), msg.sender, amount, false);
    }

    function withdrawETH(uint256 amount) external returns (uint256 withdrawn) {

        withdrawn = _withdraw(msg.sender, address(this), amount, true);


        IWETH(address(token)).withdraw(withdrawn);

        msg.sender.sendValue(address(this).balance);
    }

    receive() external payable {
        if (msg.sender != address(token)) {
            depositETH();
        }
    }
}
