pragma solidity 0.7.6;



import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../RocketBase.sol";
import "../../interface/deposit/RocketDepositPoolInterface.sol";
import "../../interface/network/RocketNetworkBalancesInterface.sol";
import "../../interface/token/RocketTokenRETHInterface.sol";




contract RocketTokenRETH is RocketBase, ERC20, RocketTokenRETHInterface {


    using SafeMath for uint;


    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event TokensMinted(address indexed to, uint256 amount, uint256 ethAmount, uint256 time);
    event TokensBurned(address indexed from, uint256 amount, uint256 ethAmount, uint256 time);


    constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) ERC20("Rocket Pool ETH", "rETH") {

        version = 1;
    }


    function getEthValue(uint256 _rethAmount) override public view returns (uint256) {

        RocketNetworkBalancesInterface rocketNetworkBalances = RocketNetworkBalancesInterface(getContractAddress("rocketNetworkBalances"));
        uint256 totalEthBalance = rocketNetworkBalances.getTotalETHBalance();
        uint256 rethSupply = rocketNetworkBalances.getTotalRETHSupply();

        if (rethSupply == 0) { return _rethAmount; }

        return _rethAmount.mul(totalEthBalance).div(rethSupply);
    }


    function getRethValue(uint256 _ethAmount) override public view returns (uint256) {

        RocketNetworkBalancesInterface rocketNetworkBalances = RocketNetworkBalancesInterface(getContractAddress("rocketNetworkBalances"));
        uint256 totalEthBalance = rocketNetworkBalances.getTotalETHBalance();
        uint256 rethSupply = rocketNetworkBalances.getTotalRETHSupply();

        if (rethSupply == 0) { return _ethAmount; }

        require(totalEthBalance > 0, "Cannot calculate rETH token amount while total network balance is zero");

        return _ethAmount.mul(rethSupply).div(totalEthBalance);
    }



    function getExchangeRate() override public view returns (uint256) {
        return getEthValue(1 ether);
    }



    function getTotalCollateral() override public view returns (uint256) {
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        return rocketDepositPool.getExcessBalance().add(address(this).balance);
    }



    function getCollateralRate() override public view returns (uint256) {
        uint256 calcBase = 1 ether;
        uint256 totalEthValue = getEthValue(totalSupply());
        if (totalEthValue == 0) { return calcBase; }
        return calcBase.mul(address(this).balance).div(totalEthValue);
    }



    function depositRewards() override external payable onlyLatestContract("rocketNetworkWithdrawal", msg.sender) {

        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }



    function depositExcess() override external payable onlyLatestContract("rocketDepositPool", msg.sender) {

        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }



    function mint(uint256 _ethAmount, address _to) override external onlyLatestContract("rocketDepositPool", msg.sender) {

        uint256 rethAmount = getRethValue(_ethAmount);

        require(rethAmount > 0, "Invalid token mint amount");

        _mint(_to, rethAmount);

        emit TokensMinted(_to, rethAmount, _ethAmount, block.timestamp);
    }


    function burn(uint256 _rethAmount) override external {

        require(_rethAmount > 0, "Invalid token burn amount");
        require(balanceOf(msg.sender) >= _rethAmount, "Insufficient rETH balance");

        uint256 ethAmount = getEthValue(_rethAmount);

        uint256 ethBalance = getTotalCollateral();
        require(ethBalance >= ethAmount, "Insufficient ETH balance for exchange");

        _burn(msg.sender, _rethAmount);

        withdrawDepositCollateral(ethAmount);

        msg.sender.transfer(ethAmount);

        emit TokensBurned(msg.sender, _rethAmount, ethAmount, block.timestamp);
    }


    function withdrawDepositCollateral(uint256 _ethRequired) private {

        uint256 ethBalance = address(this).balance;
        if (ethBalance >= _ethRequired) { return; }

        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        rocketDepositPool.withdrawExcessBalance(_ethRequired.sub(ethBalance));
    }

}
