pragma solidity 0.5.10;

import "./lib/CompoundOracleInterface.sol";
import "./OptionsExchange.sol";
import "./OptionsUtils.sol";
import "./lib/UniswapFactoryInterface.sol";
import "./lib/UniswapExchangeInterface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";





contract OptionsContract is Ownable, OptionsUtils, ERC20 {
    using SafeMath for uint256;

    struct Number {
        uint256 value;
        int32 exponent;
    }


    struct Repo {
        uint256 collateral;
        uint256 putsOutstanding;
        address payable owner;
    }

    OptionsExchange public optionsExchange;

    Repo[] public repos;


    Number liquidationIncentive = Number(10, -3);



    Number transactionFee = Number(0, -3);



    Number liquidationFactor = Number(500, -3);



    Number liquidationFee = Number(0, -3);




    Number public collateralizationRatio = Number(16, -1);


    Number public strikePrice;


    Number public oTokenExchangeRate = Number(1, -18);



    uint256 windowSize;



    uint256 totalExercised;








    uint256 totalUnderlying;






    uint256 totalCollateral;


    uint256 public expiry;


    int32 collateralExp = -18;


    IERC20 public collateral;


    IERC20 public underlying;



    IERC20 public strike;













    constructor(
        IERC20 _collateral,
        int32 _collExp,
        IERC20 _underlying,
        int32 _oTokenExchangeExp,
        uint256 _strikePrice,
        int32 _strikeExp,
        IERC20 _strike,
        uint256 _expiry,
        OptionsExchange _optionsExchange,
        uint256 _windowSize

    )
        OptionsUtils(
            address(_optionsExchange.UNISWAP_FACTORY()), address(_optionsExchange.COMPOUND_ORACLE())
        )
        public
    {
        collateral = _collateral;
        collateralExp = _collExp;

        underlying = _underlying;
        oTokenExchangeRate = Number(1, _oTokenExchangeExp);

        strikePrice = Number(_strikePrice, _strikeExp);
        strike = _strike;

        expiry = _expiry;
        optionsExchange = _optionsExchange;
        windowSize = _windowSize;
    }





















    function updateParameters(
        uint256 _liquidationIncentive,
        uint256 _liquidationFactor,
        uint256 _liquidationFee,
        uint256 _transactionFee,
        uint256 _collateralizationRatio)
        public onlyOwner {
            liquidationIncentive.value = _liquidationIncentive;
            liquidationFactor.value = _liquidationFactor;
            liquidationFee.value = _liquidationFee;
            transactionFee.value = _transactionFee;
            collateralizationRatio.value = _collateralizationRatio;
    }





    function transferFee(address payable _address) public onlyOwner {
        uint256 fees = totalFee;
        totalFee = 0;
        transferCollateral(_address, fees);
    }




    function numRepos() public returns (uint256) {
        return repos.length;
    }




    function openRepo() public returns (uint) {
        require(block.timestamp < expiry, "Options contract expired");
        repos.push(Repo(0, 0, msg.sender));
        uint256 repoIndex = repos.length - 1;
        emit RepoOpened(repoIndex, msg.sender);
        return repoIndex;
    }







    function addETHCollateral(uint256 repoIndex) public payable returns (uint256) {
        require(isETH(collateral), "ETH is not the specified collateral type");
        emit ETHCollateralAdded(repoIndex, msg.value, msg.sender);
        return _addCollateral(repoIndex, msg.value);
    }








    function addERC20Collateral(uint256 repoIndex, uint256 amt) public returns (uint256) {
        require(
            collateral.transferFrom(msg.sender, address(this), amt),
            "Could not transfer in collateral tokens"
        );

        emit ERC20CollateralAdded(repoIndex, amt, msg.sender);
        return _addCollateral(repoIndex, amt);
    }











    function exercise(uint256 _oTokens) public payable {

        require(block.timestamp >= expiry - windowSize, "Too early to exercise");
        require(block.timestamp < expiry, "Beyond exercise time");



        require(balanceOf(msg.sender) >= _oTokens, "Not enough pTokens");


        uint256 amtUnderlyingToPay = _oTokens.mul(10 ** underlyingExp());
        if (isETH(underlying)) {
            require(msg.value == amtUnderlyingToPay, "Incorrect msg.value");
        } else {
            require(
                underlying.transferFrom(msg.sender, address(this), amtUnderlyingToPay),
                "Could not transfer in tokens"
            );
        }

        totalUnderlying = totalUnderlying.add(amtUnderlyingToPay);


        _burn(msg.sender, _oTokens);


        uint256 amtCollateralToPay = calculateCollateralToPay(_oTokens, Number(1, 0));


        uint256 amtFee = calculateCollateralToPay(_oTokens, transactionFee);
        totalFee = totalFee.add(amtFee);

        totalExercised = totalExercised.add(amtCollateralToPay).add(amtFee);
        emit Exercise(amtUnderlyingToPay, amtCollateralToPay, msg.sender);


        transferCollateral(msg.sender, amtCollateralToPay);
    }









    function issueOTokens (uint256 repoIndex, uint256 numTokens, address receiver) public {

        require(block.timestamp < expiry, "Options contract expired");

        Repo storage repo = repos[repoIndex];
        require(msg.sender == repo.owner, "Only owner can issue options");


        uint256 newNumTokens = repo.putsOutstanding.add(numTokens);
        require(isSafe(repo.collateral, newNumTokens), "unsafe to mint");
        _mint(receiver, numTokens);
        repo.putsOutstanding = newNumTokens;

        emit IssuedOTokens(msg.sender, numTokens, repoIndex);
        return;
    }





    function getReposByOwner(address _owner) public view returns (uint[] memory) {
        uint[] memory reposOwned;
        uint256 count = 0;
        uint index = 0;


        for (uint256 i = 0; i < repos.length; i++) {
            if(repos[i].owner == _owner){
                count += 1;
            }
        }

        reposOwned = new uint[](count);


        for (uint256 i = 0; i < repos.length; i++) {
            if(repos[i].owner == _owner) {
                reposOwned[index++] = i;
            }
        }

       return reposOwned;
    }





    function getRepoByIndex(uint256 repoIndex) public view returns (uint256, uint256, address) {
        Repo storage repo = repos[repoIndex];

        return (
            repo.collateral,
            repo.putsOutstanding,
            repo.owner
        );
    }





    function isETH(IERC20 _ierc20) public pure returns (bool) {
        return _ierc20 == IERC20(0);
    }







    function createETHCollateralOptionNewRepo(uint256 amtToCreate, address receiver) external payable returns (uint256) {
        uint256 repoIndex = openRepo();
        createETHCollateralOption(amtToCreate, repoIndex, receiver);
        return repoIndex;
    }







    function createETHCollateralOption(uint256 amtToCreate, uint256 repoIndex, address receiver) public payable {
        addETHCollateral(repoIndex);
        issueOTokens(repoIndex, amtToCreate, receiver);
    }








    function createERC20CollateralOptionNewRepo(uint256 amtToCreate, uint256 amtCollateral, address receiver) external returns (uint256) {
        uint256 repoIndex = openRepo();
        createERC20CollateralOption(repoIndex, amtToCreate, amtCollateral, receiver);
        return repoIndex;
    }








    function createERC20CollateralOption(uint256 amtToCreate, uint256 amtCollateral, uint256 repoIndex, address receiver) public {
        addERC20Collateral(repoIndex, amtCollateral);
        issueOTokens(repoIndex, amtToCreate, receiver);
    }








    function burnOTokens(uint256 repoIndex, uint256 amtToBurn) public {
        Repo storage repo = repos[repoIndex];
        require(repo.owner == msg.sender, "Not the owner of this repo");
        repo.putsOutstanding = repo.putsOutstanding.sub(amtToBurn);
        _burn(msg.sender, amtToBurn);
        emit BurnOTokens (repoIndex, amtToBurn);
    }






    function transferRepoOwnership(uint256 repoIndex, address payable newOwner) public {
        require(repos[repoIndex].owner == msg.sender, "Cannot transferRepoOwnership as non owner");
        repos[repoIndex].owner = newOwner;
        emit TransferRepoOwnership(repoIndex, msg.sender, newOwner);
    }







    function removeCollateral(uint256 repoIndex, uint256 amtToRemove) public {

        require(block.timestamp < expiry, "Can only call remove collateral before expiry");

        Repo storage repo = repos[repoIndex];
        require(msg.sender == repo.owner, "Only owner can remove collateral");
        require(amtToRemove <= repo.collateral, "Can't remove more collateral than owned");
        uint256 newRepoCollateralAmt = repo.collateral.sub(amtToRemove);

        require(isSafe(newRepoCollateralAmt, repo.putsOutstanding), "Repo is unsafe");

        repo.collateral = newRepoCollateralAmt;
        transferCollateral(msg.sender, amtToRemove);
        totalCollateral = totalCollateral.sub(amtToRemove);

        emit RemoveCollateral(repoIndex, amtToRemove, msg.sender);
    }








    function claimCollateral (uint256 repoIndex) public {
        require(block.timestamp >= expiry, "Can't collect collateral until expiry");


        Repo storage repo = repos[repoIndex];

        require(msg.sender == repo.owner, "only owner can claim collatera");

        uint256 collateralLeft = totalCollateral.sub(totalExercised);
        uint256 collateralToTransfer = repo.collateral.mul(collateralLeft).div(totalCollateral);
        uint256 underlyingToTransfer = repo.collateral.mul(totalUnderlying).div(totalCollateral);

        repo.collateral = 0;

        emit ClaimedCollateral(collateralToTransfer, underlyingToTransfer, repoIndex, msg.sender);

        transferCollateral(msg.sender, collateralToTransfer);
        transferUnderlying(msg.sender, underlyingToTransfer);
    }










    function liquidate(uint256 repoIndex, uint256 _oTokens) public {

        require(block.timestamp < expiry, "Options contract expired");

        Repo storage repo = repos[repoIndex];


        require(isUnsafe(repoIndex), "Repo is safe");


        require(msg.sender != repo.owner, "Owner can't liquidate themselves");

        uint256 amtCollateral = calculateCollateralToPay(_oTokens, Number(1, 0));
        uint256 amtIncentive = calculateCollateralToPay(_oTokens, liquidationIncentive);

        uint256 amtCollateralToPay = amtCollateral + amtIncentive;


        uint256 protocolFee = calculateCollateralToPay(_oTokens, liquidationFee);
        totalFee = totalFee.add(protocolFee);


        uint256 maxCollateralLiquidatable = repo.collateral.mul(liquidationFactor.value);
        if(liquidationFactor.exponent > 0) {
            maxCollateralLiquidatable = maxCollateralLiquidatable.div(10 ** uint32(liquidationFactor.exponent));
        } else {
            maxCollateralLiquidatable = maxCollateralLiquidatable.div(10 ** uint32(-1 * liquidationFactor.exponent));
        }

        require(amtCollateralToPay.add(protocolFee) <= maxCollateralLiquidatable,
        "Can only liquidate liquidation factor at any given time");


        repo.collateral = repo.collateral.sub(amtCollateralToPay.add(protocolFee));
        repo.putsOutstanding = repo.putsOutstanding.sub(_oTokens);

        totalCollateral = totalCollateral.sub(amtCollateralToPay.add(protocolFee));


         _burn(msg.sender, _oTokens);
         transferCollateral(msg.sender, amtCollateralToPay);

        emit Liquidate(amtCollateralToPay, repoIndex, msg.sender);
    }






    function isUnsafe(uint256 repoIndex) public view returns (bool) {
        Repo storage repo = repos[repoIndex];

        bool isUnsafe = !isSafe(repo.collateral, repo.putsOutstanding);

        return isUnsafe;
    }






    function _addCollateral(uint256 _repoIndex, uint256 _amt) private returns (uint256) {
        require(block.timestamp < expiry, "Options contract expired");

        Repo storage repo = repos[_repoIndex];

        repo.collateral = repo.collateral.add(_amt);

        totalCollateral = totalCollateral.add(_amt);

        return repo.collateral;
    }







    function isSafe(uint256 collateralAmt, uint256 putsOutstanding) internal view returns (bool) {

        uint256 ethToCollateralPrice = getPrice(address(collateral));
        uint256 ethToStrikePrice = getPrice(address(strike));



        uint256 leftSideVal = putsOutstanding.mul(collateralizationRatio.value).mul(strikePrice.value);
        int32 leftSideExp = collateralizationRatio.exponent + strikePrice.exponent;

        uint256 rightSideVal = (collateralAmt.mul(ethToStrikePrice)).div(ethToCollateralPrice);
        int32 rightSideExp = collateralExp;

        uint32 exp = 0;
        bool isSafe = false;

        if(rightSideExp < leftSideExp) {
            exp = uint32(leftSideExp - rightSideExp);
            isSafe = leftSideVal.mul(10**exp) <= rightSideVal;
        } else {
            exp = uint32(rightSideExp - leftSideExp);
            isSafe = leftSideVal <= rightSideVal.mul(10 ** exp);
        }

        return isSafe;
    }










    function calculateCollateralToPay(uint256 _oTokens, Number memory proportion) internal returns (uint256) {

        uint256 ethToCollateralPrice = getPrice(address(collateral));
        uint256 ethToStrikePrice = getPrice(address(strike));


        uint256 amtCollateralToPayNum = _oTokens.mul(strikePrice.value).mul(proportion.value).mul(ethToCollateralPrice);
        int32 amtCollateralToPayExp = strikePrice.exponent + proportion.exponent - collateralExp;
        uint256 amtCollateralToPay = 0;
        if(amtCollateralToPayExp > 0) {
            uint32 exp = uint32(amtCollateralToPayExp);
            amtCollateralToPay = amtCollateralToPayNum.mul(10 ** exp).div(ethToStrikePrice);
        } else {
            uint32 exp = uint32(-1 * amtCollateralToPayExp);
            amtCollateralToPay = (amtCollateralToPayNum.div(10 ** exp)).div(ethToStrikePrice);
        }

        return amtCollateralToPay;

    }






    function transferCollateral(address payable _addr, uint256 _amt) internal {
        if (isETH(collateral)){
            _addr.transfer(_amt);
        } else {
            collateral.transfer(_addr, _amt);
        }
    }






    function transferUnderlying(address payable _addr, uint256 _amt) internal {
        if (isETH(underlying)){
            _addr.transfer(_amt);
        } else {
            underlying.transfer(_addr, _amt);
        }
    }





    function getPrice(address asset) internal view returns (uint256) {

        if(asset == address(0)) {
            return (10 ** 18);
        } else {
            return COMPOUND_ORACLE.getPrice(asset);
        }
    }






    function underlyingExp() internal returns (uint32) {

        return uint32(oTokenExchangeRate.exponent - (-18));
    }

    function() external payable {

    }
}
