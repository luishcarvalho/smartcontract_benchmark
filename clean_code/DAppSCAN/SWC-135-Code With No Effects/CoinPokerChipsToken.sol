

pragma solidity 0.7.4;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./ERC20Permit.sol";










contract CoinPokerChipsToken is ERC20Permit, Ownable {
    uint256 public constant MAX_CAP = 354786434702574732562458800;

    address public governance;

    event RecoverToken(address indexed token, address indexed destination, uint256 indexed amount);

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    constructor() ERC20("CoinPoker Chips", "CHP") {
        governance = msg.sender;
        _mint(governance, MAX_CAP);
    }






    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;
    }








    function recoverToken(
        address token,
        address destination,
        uint256 amount
    ) external onlyGovernance {
        require(token != destination, "Invalid address");
        require(IERC20(token).transfer(destination, amount), "Retrieve failed");
        emit RecoverToken(token, destination, amount);
    }
}
