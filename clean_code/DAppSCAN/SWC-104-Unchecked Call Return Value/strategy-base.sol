pragma solidity ^0.6.7;

import "../lib/erc20.sol";
import "../lib/safe-math.sol";

import "../interfaces/jar.sol";
import "../interfaces/staking-rewards.sol";
import "../interfaces/masterchef.sol";
import "../interfaces/uniswapv2.sol";
import "../interfaces/controller.sol";


abstract contract StrategyBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;


    uint256 public performanceTreasuryFee = 500;
    uint256 public constant performanceTreasuryMax = 10000;

    uint256 public performanceDevFee = 1000;
    uint256 public constant performanceDevMax = 10000;




    uint256 public withdrawalTreasuryFee = 0;
    uint256 public constant withdrawalTreasuryMax = 100000;

    uint256 public withdrawalDevFundFee = 0;
    uint256 public constant withdrawalDevFundMax = 100000;


    address public lp;
    address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;


    address public controller;
    address public strategist;


    address public univ2Router2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    mapping(address => bool) public harvesters;

    constructor(
        address _lp,
        address _strategist,
        address _controller
    ) public {
        require(_lp != address(0));
        require(_strategist != address(0));

        lp = _lp;
        strategist = _strategist;
        controller = _controller;


    }



    modifier onlyBenevolent {
        require(
            harvesters[msg.sender] ||
                msg.sender == controller ||
                msg.sender == strategist
        );
        _;
    }



    function balanceOfWant() public view returns (uint256) {
        return IERC20(lp).balanceOf(address(this));
    }

    function balanceOfPool() public virtual view returns (uint256);

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function getName() external virtual pure returns (string memory);



    function whitelistHarvester(address _harvester) external {
        require(msg.sender == controller ||
             msg.sender == strategist, "not authorized");
        harvesters[_harvester] = true;
    }

    function revokeHarvester(address _harvester) external {
        require(msg.sender == controller ||
             msg.sender == strategist, "not authorized");
        harvesters[_harvester] = false;
    }

    function setWithdrawalDevFundFee(uint256 _withdrawalDevFundFee) external {
        require(msg.sender == strategist, "!strategist");
        withdrawalDevFundFee = _withdrawalDevFundFee;
    }

    function setWithdrawalTreasuryFee(uint256 _withdrawalTreasuryFee) external {
        require(msg.sender == strategist, "!strategist");
        withdrawalTreasuryFee = _withdrawalTreasuryFee;
    }

    function setPerformanceDevFee(uint256 _performanceDevFee) external {
        require(msg.sender == strategist, "!strategist");
        performanceDevFee = _performanceDevFee;
    }

    function setPerformanceTreasuryFee(uint256 _performanceTreasuryFee)
        external
    {
        require(msg.sender == strategist, "!strategist");
        performanceTreasuryFee = _performanceTreasuryFee;
    }

    function setStrategist(address _strategist) external {
        require(msg.sender == strategist, "!strategist");
        strategist = _strategist;
    }

    function setController(address _controller) external {
        require(msg.sender == strategist, "!strategist");
        controller = _controller;
    }

    function setUniv2Router2(address _univ2Router2) external {
        require(msg.sender == strategist, "!strategist");
        univ2Router2 = _univ2Router2;
    }

    function setSushiRouter(address _sushiRouter) external {
        require(msg.sender == strategist, "!strategist");
        sushiRouter = _sushiRouter;
    }

    function setWETH(address _weth) external {
        require(msg.sender == strategist, "!strategist");
        weth = _weth;
    }


    function deposit() public virtual;


    function withdraw(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(lp).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        uint256 _feeDev = _amount.mul(withdrawalDevFundFee).div(
            withdrawalDevFundMax
        );
        IERC20(lp).safeTransfer(IController(controller).devaddr(), _feeDev);

        uint256 _feeTreasury = _amount.mul(withdrawalTreasuryFee).div(
            withdrawalTreasuryMax
        );
        IERC20(lp).safeTransfer(
            IController(controller).treasury(),
            _feeTreasury
        );

        IERC20(lp).safeTransfer(controller, _amount.sub(_feeDev).sub(_feeTreasury));
    }



    function withdrawAll(address _newStrategy) external returns (uint256 balance) {
        require(msg.sender == controller, "!controller");
        _withdrawAll();

        balance = IERC20(lp).balanceOf(address(this));

        require(_newStrategy != address(0), "!newStrategy");
        IERC20(lp).safeTransfer(_newStrategy, balance);
    }

    function _withdrawAll() internal {
        _withdrawSome(balanceOfPool());
    }

    function _withdrawSome(uint256 _amount) internal virtual returns (uint256);

    function harvest() public virtual;



    function execute(address _target, bytes memory _data)
        public
        payable
        returns (bytes memory response)
    {
        require(msg.sender == strategist, "!strategist");
        require(_target != address(0), "!target");


        assembly {
            let succeeded := delegatecall(
                sub(gas(), 5000),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )
            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {

                    revert(add(response, 0x20), size)
                }
        }
    }



    function _swapUniswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));


        IERC20(_from).safeApprove(univ2Router2, 0);
        IERC20(_from).safeApprove(univ2Router2, _amount);

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        UniswapRouterV2(univ2Router2).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }


    function _swapUniswapWithPath(
        address[] memory path,
        uint256 _amount
    ) internal {
        require(path[1] != address(0));


        IERC20(path[0]).safeApprove(univ2Router2, 0);
        IERC20(path[0]).safeApprove(univ2Router2, _amount);

        UniswapRouterV2(univ2Router2).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }


    function _swapSushiswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));


        IERC20(_from).safeApprove(sushiRouter, 0);
        IERC20(_from).safeApprove(sushiRouter, _amount);

        address[] memory path;

        if (_from == weth || _to == weth) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = weth;
            path[2] = _to;
        }

        UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }


    function _swapSushiswapWithPath(
        address[] memory path,
        uint256 _amount
    ) internal {
        require(path[1] != address(0));


        IERC20(path[0]).safeApprove(sushiRouter, 0);
        IERC20(path[0]).safeApprove(sushiRouter, _amount);

        UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

    function _distributePerformanceFeesAndDeposit() internal {
        uint256 _lp = IERC20(lp).balanceOf(address(this));

        if (_lp > 0) {

            IERC20(lp).safeTransfer(
                IController(controller).treasury(),
                _lp.mul(performanceTreasuryFee).div(performanceTreasuryMax)
            );


            IERC20(lp).safeTransfer(
                IController(controller).devaddr(),
                _lp.mul(performanceDevFee).div(performanceDevMax)
            );

            deposit();
        }
    }
}
