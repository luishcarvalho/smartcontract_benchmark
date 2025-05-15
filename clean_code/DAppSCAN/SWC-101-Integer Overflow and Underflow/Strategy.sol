
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./GenericLender/IGenericLender.sol";
import "./WantToEthOracle/IWantToEth.sol";

import "@yearnvaults/contracts/BaseStrategy.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

interface IUni {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}













contract Strategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public constant uniswapRouter = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IGenericLender[] public lenders;
    bool public externalOracle = false;
    address public wantToEthOracle;

    constructor(address _vault) public BaseStrategy(_vault) {
        debtThreshold = 1000;


        require(keccak256(bytes(apiVersion())) == keccak256(bytes(VaultAPI(_vault).apiVersion())), "WRONG VERSION");
    }

    function setPriceOracle(address _oracle) external onlyAuthorized {
        wantToEthOracle = _oracle;
    }

    function name() external view override returns (string memory) {
        return "StrategyLenderYieldOptimiser";
    }




    function addLender(address a) public onlyGovernance {
        IGenericLender n = IGenericLender(a);
        require(n.strategy() == address(this), "Undocked Lender");

        for (uint256 i = 0; i < lenders.length; i++) {
            require(a != address(lenders[i]), "Already Added");
        }
        lenders.push(n);
    }


    function safeRemoveLender(address a) public onlyAuthorized {
        _removeLender(a, false);
    }

    function forceRemoveLender(address a) public onlyAuthorized {
        _removeLender(a, true);
    }


    function _removeLender(address a, bool force) internal {
        for (uint256 i = 0; i < lenders.length; i++) {
            if (a == address(lenders[i])) {
                bool allWithdrawn = lenders[i].withdrawAll();

                if (!force) {
                    require(allWithdrawn, "WITHDRAW FAILED");
                }



                if (i != lenders.length - 1) {
                    lenders[i] = lenders[lenders.length - 1];
                }


                lenders.pop();


                if (want.balanceOf(address(this)) > 0) {
                    adjustPosition(0);
                }
                return;
            }
        }
        require(false, "NOT LENDER");
    }


    struct lendStatus {
        string name;
        uint256 assets;
        uint256 rate;
        address add;
    }


    function lendStatuses() public view returns (lendStatus[] memory) {
        lendStatus[] memory statuses = new lendStatus[](lenders.length);
        for (uint256 i = 0; i < lenders.length; i++) {
            lendStatus memory s;
            s.name = lenders[i].lenderName();
            s.add = address(lenders[i]);
            s.assets = lenders[i].nav();
            s.rate = lenders[i].apr();
            statuses[i] = s;
        }

        return statuses;
    }


    function estimatedTotalAssets() public view override returns (uint256) {
        uint256 nav = lentTotalAssets();

        nav += want.balanceOf(address(this));

        return nav;
    }

    function numLenders() public view returns (uint256) {
        return lenders.length;
    }


    function estimatedAPR() public view returns (uint256) {
        uint256 bal = estimatedTotalAssets();
        if (bal == 0) {
            return 0;
        }

        uint256 weightedAPR = 0;

        for (uint256 i = 0; i < lenders.length; i++) {

            weightedAPR += lenders[i].weightedApr();
        }

        return weightedAPR.div(bal);
    }


    function _estimateDebtLimitIncrease(uint256 change) internal view returns (uint256) {
        uint256 highestAPR = 0;
        uint256 aprChoice = 0;
        uint256 assets = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 apr = lenders[i].aprAfterDeposit(change);
            if (apr > highestAPR) {
                aprChoice = i;
                highestAPR = apr;
                assets = lenders[i].nav();
            }
        }

        uint256 weightedAPR = highestAPR.mul(assets.add(change));

        for (uint256 i = 0; i < lenders.length; i++) {
            if (i != aprChoice) {

                weightedAPR += lenders[i].weightedApr();
            }
        }

        uint256 bal = estimatedTotalAssets().add(change);

        return weightedAPR.div(bal);
    }


    function _estimateDebtLimitDecrease(uint256 change) internal view returns (uint256) {
        uint256 lowestApr = uint256(-1);
        uint256 aprChoice = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 apr = lenders[i].aprAfterDeposit(change);
            if (apr < lowestApr) {
                aprChoice = i;
                lowestApr = apr;
            }
        }

        uint256 weightedAPR = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            if (i != aprChoice) {

                weightedAPR += lenders[i].weightedApr();
            } else {
                uint256 asset = lenders[i].nav();
                if (asset < change) {

                    change = asset;
                }

                weightedAPR += lowestApr.mul(change);
            }
        }
        uint256 bal = estimatedTotalAssets().add(change);
        return weightedAPR.div(bal);
    }


    function estimateAdjustPosition()
        public
        view
        returns (
            uint256 _lowest,
            uint256 _lowestApr,
            uint256 _highest,
            uint256 _potential
        )
    {

        uint256 looseAssets = want.balanceOf(address(this));




        _lowestApr = uint256(-1);
        _lowest = 0;
        uint256 lowestNav = 0;
        for (uint256 i = 0; i < lenders.length; i++) {
            if (lenders[i].hasAssets()) {
                uint256 apr = lenders[i].apr();
                if (apr < _lowestApr) {
                    _lowestApr = apr;
                    _lowest = i;
                    lowestNav = lenders[i].nav();
                }
            }
        }

        uint256 toAdd = lowestNav.add(looseAssets);

        uint256 highestApr = 0;
        _highest = 0;

        for (uint256 i = 0; i < lenders.length; i++) {
            uint256 apr;
            apr = lenders[i].aprAfterDeposit(looseAssets);

            if (apr > highestApr) {
                highestApr = apr;
                _highest = i;
            }
        }


        _potential = lenders[_highest].aprAfterDeposit(toAdd);
    }


    function estimatedFutureAPR(uint256 newDebtLimit) public view returns (uint256) {
        uint256 oldDebtLimit = vault.strategies(address(this)).totalDebt;
        uint256 change;
        if (oldDebtLimit < newDebtLimit) {
            change = newDebtLimit - oldDebtLimit;
            return _estimateDebtLimitIncrease(change);
        } else {
            change = oldDebtLimit - newDebtLimit;
            return _estimateDebtLimitDecrease(change);
        }
    }


    function lentTotalAssets() public view returns (uint256) {
        uint256 nav = 0;
        for (uint256 i = 0; i < lenders.length; i++) {

            nav += lenders[i].nav();
        }
        return nav;
    }




    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        _profit = 0;
        _loss = 0;
        _debtPayment = _debtOutstanding;

        uint256 lentAssets = lentTotalAssets();

        uint256 looseAssets = want.balanceOf(address(this));

        uint256 total = looseAssets.add(lentAssets);

        if (lentAssets == 0) {

            if (_debtPayment > looseAssets) {

                _debtPayment = looseAssets;
            }

            return (_profit, _loss, _debtPayment);
        }

        uint256 debt = vault.strategies(address(this)).totalDebt;

        if (total > debt) {
            _profit = total - debt;
            uint256 amountToFree = _profit.add(_debtPayment);



            if (amountToFree > 0 && looseAssets < amountToFree) {

                _withdrawSome(amountToFree.sub(looseAssets));
                uint256 newLoose = want.balanceOf(address(this));


                if (newLoose < amountToFree) {
                    if (_profit > newLoose) {
                        _profit = newLoose;
                        _debtPayment = 0;
                    } else {
                        _debtPayment = Math.min(newLoose - _profit, _debtPayment);
                    }
                }
            }
        } else {

            _loss = debt - total;
            uint256 amountToFree = _loss.add(_debtPayment);

            if (amountToFree > 0 && looseAssets < amountToFree) {


                _withdrawSome(amountToFree.sub(looseAssets));
                uint256 newLoose = want.balanceOf(address(this));


                if (newLoose < amountToFree) {
                    if (_loss > newLoose) {
                        _loss = newLoose;
                        _debtPayment = 0;
                    } else {
                        _debtPayment = Math.min(newLoose - _loss, _debtPayment);
                    }
                }
            }
        }
    }







    function adjustPosition(uint256 _debtOutstanding) internal override {

        if (lenders.length == 0) {
            return;
        }

        _debtOutstanding;

        if (emergencyExit) {
            return;
        }

        (uint256 lowest, uint256 lowestApr, uint256 highest, uint256 potential) = estimateAdjustPosition();

        if (potential > lowestApr) {


            lenders[lowest].withdrawAll();
        }

        uint256 bal = want.balanceOf(address(this));
        if (bal > 0) {
            want.safeTransfer(address(lenders[highest]), bal);
            lenders[highest].deposit();
        }
    }

    struct lenderRatio {
        address lender;

        uint16 share;
    }


    function manualAllocation(lenderRatio[] memory _newPositions) public onlyAuthorized {
        uint256 share = 0;


        for (uint256 i = 0; i < lenders.length; i++) {

            lenders[i].withdrawAll();
        }

        uint256 assets = want.balanceOf(address(this));

        for (uint256 i = 0; i < _newPositions.length; i++) {
            bool found = false;


            for (uint256 j = 0; j < lenders.length; j++) {
                if (address(lenders[j]) == _newPositions[j].lender) {
                    found = true;
                }
            }
            require(found, "NOT LENDER");


            share += _newPositions[i].share;
            uint256 toSend = assets.mul(_newPositions[i].share).div(1000);
            want.safeTransfer(_newPositions[i].lender, toSend);
            IGenericLender(_newPositions[i].lender).deposit();
        }

        require(share == 1000, "SHARE!=1000");
    }


    function _withdrawSome(uint256 _amount) internal returns (uint256 amountWithdrawn) {

        if (_amount < debtThreshold) {
            return 0;
        }

        amountWithdrawn = 0;

        uint256 j = 0;
        while (amountWithdrawn < _amount) {
            uint256 lowestApr = uint256(-1);
            uint256 lowest = 0;
            for (uint256 i = 0; i < lenders.length; i++) {
                if (lenders[i].hasAssets()) {
                    uint256 apr = lenders[i].apr();
                    if (apr < lowestApr) {
                        lowestApr = apr;
                        lowest = i;
                    }
                }
            }
            if (!lenders[lowest].hasAssets()) {
                return amountWithdrawn;
            }

            amountWithdrawn += lenders[lowest].withdraw(_amount - amountWithdrawn);
            j++;

            if (j >= 6) {
                return amountWithdrawn;
            }
        }
    }





    function liquidatePosition(uint256 _amountNeeded) internal override returns (uint256 _amountFreed, uint256 _loss) {
        uint256 _balance = want.balanceOf(address(this));

        if (_balance >= _amountNeeded) {

            return (_amountNeeded, 0);
        } else {
            uint256 received = _withdrawSome(_amountNeeded - _balance).add(_balance);
            if (received >= _amountNeeded) {
                return (_amountNeeded, 0);
            } else {
                return (received, 0);
            }
        }
    }

    function harvestTrigger(uint256 callCost) public view override returns (bool) {
        uint256 wantCallCost = _callCostToWant(callCost);

        return super.harvestTrigger(wantCallCost);
    }

    function ethToWant(uint256 _amount) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path = new address[](2);
        path[0] = weth;
        path[1] = address(want);

        uint256[] memory amounts = IUni(uniswapRouter).getAmountsOut(_amount, path);

        return amounts[amounts.length - 1];
    }

    function _callCostToWant(uint256 callCost) internal view returns (uint256) {
        uint256 wantCallCost;





        if (address(want) == weth) {
            wantCallCost = callCost;
        } else if (wantToEthOracle == address(0)) {
            wantCallCost = ethToWant(callCost);
        } else {
            wantCallCost = IWantToEth(wantToEthOracle).ethToWant(callCost);
        }

        return wantCallCost;
    }

    function tendTrigger(uint256 callCost) public view override returns (bool) {

        if (harvestTrigger(callCost)) {
            return false;
        }



        (uint256 lowest, uint256 lowestApr, , uint256 potential) = estimateAdjustPosition();


        if (potential > lowestApr) {
            uint256 nav = lenders[lowest].nav();


            uint256 profitIncrease = (nav.mul(potential) - nav.mul(lowestApr)).div(1e18).div(365);

            uint256 wantCallCost = _callCostToWant(callCost);


            return (wantCallCost * callCost < profitIncrease);
        }
    }




    function prepareMigration(address _newStrategy) internal override {
        uint256 outstanding = vault.strategies(address(this)).totalDebt;
        (, uint256 loss, uint256 wantBalance) = prepareReturn(outstanding);

        require(wantBalance.add(loss) >= outstanding, "LIQUIDITY LOCKED");
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    function protectedTokens() internal view override returns (address[] memory) {
        address[] memory protected = new address[](1);
        protected[0] = address(want);
        return protected;
    }
}
