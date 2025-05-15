pragma solidity 0.5.16;
import "openzeppelin-solidity-2.3.0/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity-2.3.0/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "openzeppelin-solidity-2.3.0/contracts/math/Math.sol";
import "openzeppelin-solidity-2.3.0/contracts/utils/ReentrancyGuard.sol";
import "./BankConfig.sol";
import "./Goblin.sol";
import "./SafeToken.sol";

contract Bank is ERC20, ReentrancyGuard, Ownable {

    using SafeToken for address;
    using SafeMath for uint256;


    event AddDebt(uint256 indexed id, uint256 debtShare);
    event RemoveDebt(uint256 indexed id, uint256 debtShare);
    event Work(uint256 indexed id, uint256 loan);
    event Kill(uint256 indexed id, address indexed killer, uint256 prize, uint256 left);

    string public name = "Interest Bearing BNB";
    string public symbol = "iBNB";
    uint8 public decimals = 18;

    struct Position {
        address goblin;
        address owner;
        uint256 debtShare;
    }

    BankConfig public config;
    mapping (uint256 => Position) public positions;
    uint256 public nextPositionID = 1;

    uint256 public glbDebtShare;
    uint256 public glbDebtVal;
    uint256 public lastAccrueTime;
    uint256 public reservePool;


    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }


    modifier accrue(uint256 msgValue) {
        if (now > lastAccrueTime) {
            uint256 interest = pendingInterest(msgValue);
            uint256 toReserve = interest.mul(config.getReservePoolBps()).div(10000);
            reservePool = reservePool.add(toReserve);
            glbDebtVal = glbDebtVal.add(interest);
            lastAccrueTime = now;
        }
        _;
    }

    constructor(BankConfig _config) public {
        config = _config;
        lastAccrueTime = now;
    }



    function pendingInterest(uint256 msgValue) public view returns (uint256) {
        if (now > lastAccrueTime) {
            uint256 timePast = now.sub(lastAccrueTime);
            uint256 balance = address(this).balance.sub(msgValue);
            uint256 ratePerSec = config.getInterestRate(glbDebtVal, balance);
            return ratePerSec.mul(glbDebtVal).mul(timePast).div(1e18);
        } else {
            return 0;
        }
    }



    function debtShareToVal(uint256 debtShare) public view returns (uint256) {
        if (glbDebtShare == 0) return debtShare;
        return debtShare.mul(glbDebtVal).div(glbDebtShare);
    }



    function debtValToShare(uint256 debtVal) public view returns (uint256) {
        if (glbDebtShare == 0) return debtVal;
        return debtVal.mul(glbDebtShare).div(glbDebtVal);
    }



    function positionInfo(uint256 id) public view returns (uint256, uint256) {
        Position storage pos = positions[id];
        return (Goblin(pos.goblin).health(id), debtShareToVal(pos.debtShare));
    }


    function totalETH() public view returns (uint256) {
        return address(this).balance.add(glbDebtVal).sub(reservePool);
    }


    function deposit() external payable accrue(msg.value) nonReentrant {
        uint256 total = totalETH().sub(msg.value);

        uint256 share = total == 0 ? msg.value : msg.value.mul(totalSupply()).div(total);
        _mint(msg.sender, share);
    }


    function withdraw(uint256 share) external accrue(0) nonReentrant {
        uint256 amount = share.mul(totalETH()).div(totalSupply());
        _burn(msg.sender, share);
        SafeToken.safeTransferETH(msg.sender, amount);
    }







    function work(uint256 id, address goblin, uint256 loan, uint256 maxReturn, bytes calldata data)
        external payable
        onlyEOA accrue(msg.value) nonReentrant
    {

        if (id == 0) {
            id = nextPositionID++;
            positions[id].goblin = goblin;
            positions[id].owner = msg.sender;
        } else {
            require(id < nextPositionID, "bad position id");
            require(positions[id].goblin == goblin, "bad position goblin");
            require(positions[id].owner == msg.sender, "not position owner");
        }
        emit Work(id, loan);

        require(config.isGoblin(goblin), "not a goblin");
        require(loan == 0 || config.acceptDebt(goblin), "goblin not accept more debt");
        uint256 debt = _removeDebt(id).add(loan);

        uint256 back;
        {
            uint256 sendETH = msg.value.add(loan);
            require(sendETH <= address(this).balance, "insufficient ETH in the bank");
            uint256 beforeETH = address(this).balance.sub(sendETH);
            Goblin(goblin).work.value(sendETH)(id, msg.sender, debt, data);
            back = address(this).balance.sub(beforeETH);
        }

        uint256 lessDebt = Math.min(debt, Math.min(back, maxReturn));
        debt = debt.sub(lessDebt);
        if (debt > 0) {
            require(debt >= config.minDebtSize(), "too small debt size");
            uint256 health = Goblin(goblin).health(id);
            uint256 workFactor = config.workFactor(goblin, debt);
            require(health.mul(workFactor) >= debt.mul(10000), "bad work factor");
            _addDebt(id, debt);
        }

        if (back > lessDebt) SafeToken.safeTransferETH(msg.sender, back - lessDebt);
    }



    function kill(uint256 id) external onlyEOA accrue(0) nonReentrant {

        Position storage pos = positions[id];
        require(pos.debtShare > 0, "no debt");
        uint256 debt = _removeDebt(id);
        uint256 health = Goblin(pos.goblin).health(id);
        uint256 killFactor = config.killFactor(pos.goblin, debt);
        require(health.mul(killFactor) < debt.mul(10000), "can't liquidate");

        uint256 beforeETH = address(this).balance;
        Goblin(pos.goblin).liquidate(id);
        uint256 back = address(this).balance.sub(beforeETH);
        uint256 prize = back.mul(config.getKillBps()).div(10000);
        uint256 rest = back.sub(prize);

        if (prize > 0) SafeToken.safeTransferETH(msg.sender, prize);
        uint256 left = rest > debt ? rest - debt : 0;
        if (left > 0) SafeToken.safeTransferETH(pos.owner, left);
        emit Kill(id, msg.sender, prize, left);
    }


    function _addDebt(uint256 id, uint256 debtVal) internal {
        Position storage pos = positions[id];
        uint256 debtShare = debtValToShare(debtVal);
        pos.debtShare = pos.debtShare.add(debtShare);
        glbDebtShare = glbDebtShare.add(debtShare);
        glbDebtVal = glbDebtVal.add(debtVal);
        emit AddDebt(id, debtShare);
    }


    function _removeDebt(uint256 id) internal returns (uint256) {
        Position storage pos = positions[id];
        uint256 debtShare = pos.debtShare;
        if (debtShare > 0) {
            uint256 debtVal = debtShareToVal(debtShare);
            pos.debtShare = 0;
            glbDebtShare = glbDebtShare.sub(debtShare);
            glbDebtVal = glbDebtVal.sub(debtVal);
            emit RemoveDebt(id, debtShare);
            return debtVal;
        } else {
            return 0;
        }
    }



    function updateConfig(BankConfig _config) external onlyOwner {
        config = _config;
    }




    function withdrawReserve(address to, uint256 value) external onlyOwner nonReentrant {
        reservePool = reservePool.sub(value);
        SafeToken.safeTransferETH(to, value);
    }



    function reduceReserve(uint256 value) external onlyOwner {
        reservePool = reservePool.sub(value);
    }





    function recover(address token, address to, uint256 value) external onlyOwner nonReentrant {
        token.safeTransfer(to, value);
    }


    function() external payable {}
}
