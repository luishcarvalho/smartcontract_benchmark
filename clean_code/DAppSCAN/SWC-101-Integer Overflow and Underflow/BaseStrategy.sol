
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelinV3/contracts/token/ERC20/IERC20.sol";
import "@openzeppelinV3/contracts/math/SafeMath.sol";

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtLimit;
    uint256 rateLimit;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalReturns;
}

interface VaultAPI is IERC20 {
    function apiVersion() external view returns (string memory);

    function token() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);






    function creditAvailable() external view returns (uint256);






    function debtOutstanding() external view returns (uint256);






    function expectedReturn() external view returns (uint256);







    function report(uint256 _harvest) external returns (uint256);









    function migrateStrategy(address _newStrategy) external;











    function revokeStrategy() external;







    function governance() external view returns (address);
}




interface StrategyAPI {
    function apiVersion() external pure returns (string memory);

    function name() external pure returns (string memory);

    function vault() external view returns (address);

    function keeper() external view returns (address);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    event Harvested(uint256 profit);
}







abstract contract BaseStrategy {
    using SafeMath for uint256;


    function apiVersion() public pure returns (string memory) {
        return "0.1.3";
    }




    function name() external virtual pure returns (string memory);

    VaultAPI public vault;
    address public strategist;
    address public rewards;
    address public keeper;

    IERC20 public want;


    event Harvested(uint256 profit);



    uint256 public minReportDelay = 6300;



    uint256 public profitFactor = 100;


    uint256 public debtThreshold = 0;



    uint256 private reserve = 0;

    function getReserve() internal view returns (uint256) {
        return reserve;
    }

    function setReserve(uint256 _reserve) internal {
        if (_reserve != reserve) reserve = _reserve;
    }

    bool public emergencyExit;

    constructor(address _vault) public {
        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        want.approve(_vault, uint256(-1));
        strategist = msg.sender;
        rewards = msg.sender;
        keeper = msg.sender;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        strategist = _strategist;
    }

    function setKeeper(address _keeper) external {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        keeper = _keeper;
    }

    function setRewards(address _rewards) external {
        require(msg.sender == strategist, "!authorized");
        rewards = _rewards;
    }

    function setMinReportDelay(uint256 _delay) external {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        minReportDelay = _delay;
    }

    function setProfitFactor(uint256 _profitFactor) external {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        profitFactor = _profitFactor;
    }

    function setDebtThreshold(uint256 _debtThreshold) external {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        debtThreshold = _debtThreshold;
    }





    function governance() internal view returns (address) {
        return vault.governance();
    }



















    function estimatedTotalAssets() public virtual view returns (uint256);











    function prepareReturn(uint256 _debtOutstanding) internal virtual returns (uint256 _profit);








    function adjustPosition(uint256 _debtOutstanding) internal virtual;








    function exitPosition() internal virtual;





    function distributeRewards(uint256 _shares) external virtual {

        vault.transfer(rewards, _shares);
    }













    function tendTrigger(uint256 callCost) public virtual view returns (bool) {


        return false;
    }

    function tend() external {
        if (keeper != address(0)) {
            require(msg.sender == keeper || msg.sender == strategist || msg.sender == governance(), "!authorized");
        }


        adjustPosition(vault.debtOutstanding());
    }













    function harvestTrigger(uint256 callCost) public virtual view returns (bool) {
        StrategyParams memory params = vault.strategies(address(this));


        if (params.activation == 0) return false;


        if (block.number.sub(params.lastReport) >= minReportDelay) return true;




        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > 0) return true;


        uint256 total = estimatedTotalAssets();

        if (total.add(debtThreshold) < params.totalDebt) return true;

        uint256 profit = 0;
        if (total > params.totalDebt) profit = total.sub(params.totalDebt);


        uint256 credit = vault.creditAvailable();
        return (profitFactor * callCost < credit.add(profit));
    }

    function harvest() external {
        if (keeper != address(0)) {
            require(msg.sender == keeper || msg.sender == strategist || msg.sender == governance(), "!authorized");
        }

        uint256 profit = 0;
        if (emergencyExit) {
            exitPosition();

        } else {
            profit = prepareReturn(vault.debtOutstanding());
        }

        if (reserve > want.balanceOf(address(this))) reserve = want.balanceOf(address(this));



        uint256 outstanding = vault.report(want.balanceOf(address(this)).sub(reserve));


        adjustPosition(outstanding);

        emit Harvested(profit);
    }





    function liquidatePosition(uint256 _amountNeeded) internal virtual returns (uint256 _amountFreed);

    function withdraw(uint256 _amountNeeded) external {
        require(msg.sender == address(vault), "!vault");

        uint256 amountFreed = liquidatePosition(_amountNeeded);

        want.transfer(msg.sender, amountFreed);

        reserve = want.balanceOf(address(this));
    }





    function prepareMigration(address _newStrategy) internal virtual;

    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault) || msg.sender == governance());
        require(BaseStrategy(_newStrategy).vault() == vault);
        prepareMigration(_newStrategy);
        want.transfer(_newStrategy, want.balanceOf(address(this)));
    }

    function setEmergencyExit() external {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        emergencyExit = true;
        exitPosition();
        vault.revokeStrategy();
        if (reserve > want.balanceOf(address(this))) reserve = want.balanceOf(address(this));
    }














    function protectedTokens() internal virtual view returns (address[] memory);

    function sweep(address _token) external {
        require(msg.sender == governance(), "!authorized");
        require(_token != address(want), "!want");

        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");

        IERC20(_token).transfer(governance(), IERC20(_token).balanceOf(address(this)));
    }
}
