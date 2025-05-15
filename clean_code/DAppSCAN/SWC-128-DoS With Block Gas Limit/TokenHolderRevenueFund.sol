







pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

import {Ownable} from "./Ownable.sol";
import {AccrualBeneficiary} from "./AccrualBeneficiary.sol";
import {Servable} from "./Servable.sol";
import {TransferControllerManageable} from "./TransferControllerManageable.sol";
import {SafeMathIntLib} from "./SafeMathIntLib.sol";
import {SafeMathUintLib} from "./SafeMathUintLib.sol";
import {FungibleBalanceLib} from "./FungibleBalanceLib.sol";
import {TxHistoryLib} from "./TxHistoryLib.sol";
import {MonetaryTypesLib} from "./MonetaryTypesLib.sol";
import {CurrenciesLib} from "./CurrenciesLib.sol";
import {RevenueToken} from "./RevenueToken.sol";
import {RevenueTokenManager} from "./RevenueTokenManager.sol";
import {TransferController} from "./TransferController.sol";
import {Beneficiary} from "./Beneficiary.sol";





contract TokenHolderRevenueFund is Ownable, AccrualBeneficiary, Servable, TransferControllerManageable {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;
    using FungibleBalanceLib for FungibleBalanceLib.Balance;
    using TxHistoryLib for TxHistoryLib.TxHistory;
    using CurrenciesLib for CurrenciesLib.Currencies;




    string constant public CLOSE_ACCRUAL_PERIOD_ACTION = "close_accrual_period";




    RevenueTokenManager public revenueTokenManager;

    FungibleBalanceLib.Balance private periodAccrual;
    CurrenciesLib.Currencies private periodCurrencies;

    FungibleBalanceLib.Balance private aggregateAccrual;
    CurrenciesLib.Currencies private aggregateCurrencies;

    TxHistoryLib.TxHistory private txHistory;

    mapping(address => mapping(address => mapping(uint256 => uint256[]))) public claimedAccrualBlockNumbersByWalletCurrency;

    mapping(address => mapping(uint256 => uint256[])) public accrualBlockNumbersByCurrency;
    mapping(address => mapping(uint256 => mapping(uint256 => int256))) aggregateAccrualAmountByCurrencyBlockNumber;

    mapping(address => FungibleBalanceLib.Balance) private stagedByWallet;




    event SetRevenueTokenManagerEvent(RevenueTokenManager oldRevenueTokenManager,
        RevenueTokenManager newRevenueTokenManager);
    event ReceiveEvent(address wallet, int256 amount, address currencyCt,
        uint256 currencyId);
    event WithdrawEvent(address to, int256 amount, address currencyCt, uint256 currencyId);
    event CloseAccrualPeriodEvent(int256 periodAmount, int256 aggregateAmount, address currencyCt,
        uint256 currencyId);
    event ClaimAndTransferToBeneficiaryEvent(address wallet, string balanceType, int256 amount,
        address currencyCt, uint256 currencyId, string standard);
    event ClaimAndTransferToBeneficiaryByProxyEvent(address wallet, string balanceType, int256 amount,
        address currencyCt, uint256 currencyId, string standard);
    event ClaimAndStageEvent(address from, int256 amount, address currencyCt, uint256 currencyId);
    event WithdrawEvent(address from, int256 amount, address currencyCt, uint256 currencyId,
        string standard);




    constructor(address deployer) Ownable(deployer) public {
    }






    function setRevenueTokenManager(RevenueTokenManager newRevenueTokenManager)
    public
    onlyDeployer
    notNullAddress(newRevenueTokenManager)
    {
        if (newRevenueTokenManager != revenueTokenManager) {

            RevenueTokenManager oldRevenueTokenManager = revenueTokenManager;
            revenueTokenManager = newRevenueTokenManager;


            emit SetRevenueTokenManagerEvent(oldRevenueTokenManager, newRevenueTokenManager);
        }
    }


    function() public payable {
        receiveEthersTo(msg.sender, "");
    }



    function receiveEthersTo(address wallet, string)
    public
    payable
    {
        int256 amount = SafeMathIntLib.toNonZeroInt256(msg.value);


        periodAccrual.add(amount, address(0), 0);
        aggregateAccrual.add(amount, address(0), 0);


        periodCurrencies.add(address(0), 0);
        aggregateCurrencies.add(address(0), 0);


        txHistory.addDeposit(amount, address(0), 0);


        emit ReceiveEvent(wallet, amount, address(0), 0);
    }






    function receiveTokens(string, int256 amount, address currencyCt, uint256 currencyId,
        string standard)
    public
    {
        receiveTokensTo(msg.sender, "", amount, currencyCt, currencyId, standard);
    }







    function receiveTokensTo(address wallet, string, int256 amount, address currencyCt,
        uint256 currencyId, string standard)
    public
    {
        require(amount.isNonZeroPositiveInt256());


        TransferController controller = transferController(currencyCt, standard);
        require(
            address(controller).delegatecall(
                controller.getReceiveSignature(), msg.sender, this, uint256(amount), currencyCt, currencyId
            )
        );


        periodAccrual.add(amount, currencyCt, currencyId);
        aggregateAccrual.add(amount, currencyCt, currencyId);


        periodCurrencies.add(currencyCt, currencyId);
        aggregateCurrencies.add(currencyCt, currencyId);


        txHistory.addDeposit(amount, currencyCt, currencyId);


        emit ReceiveEvent(wallet, amount, currencyCt, currencyId);
    }





    function periodAccrualBalance(address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        return periodAccrual.get(currencyCt, currencyId);
    }






    function aggregateAccrualBalance(address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        return aggregateAccrual.get(currencyCt, currencyId);
    }



    function periodCurrenciesCount()
    public
    view
    returns (uint256)
    {
        return periodCurrencies.count();
    }





    function periodCurrenciesByIndices(uint256 low, uint256 up)
    public
    view
    returns (MonetaryTypesLib.Currency[])
    {
        return periodCurrencies.getByIndices(low, up);
    }



    function aggregateCurrenciesCount()
    public
    view
    returns (uint256)
    {
        return aggregateCurrencies.count();
    }





    function aggregateCurrenciesByIndices(uint256 low, uint256 up)
    public
    view
    returns (MonetaryTypesLib.Currency[])
    {
        return aggregateCurrencies.getByIndices(low, up);
    }



    function depositsCount()
    public
    view
    returns (uint256)
    {
        return txHistory.depositsCount();
    }



    function deposit(uint index)
    public
    view
    returns (int256 amount, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        return txHistory.deposit(index);
    }






    function stagedBalance(address wallet, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        return stagedByWallet[wallet].get(currencyCt, currencyId);
    }



    function closeAccrualPeriod(MonetaryTypesLib.Currency[] currencies)
    public
    onlyEnabledServiceAction(CLOSE_ACCRUAL_PERIOD_ACTION)
    {

        for (uint256 i = 0; i < currencies.length; i++) {
            MonetaryTypesLib.Currency memory currency = currencies[i];


            int256 periodAmount = periodAccrual.get(currency.ct, currency.id);


            accrualBlockNumbersByCurrency[currency.ct][currency.id].push(block.number);


            aggregateAccrualAmountByCurrencyBlockNumber[currency.ct][currency.id][block.number] = aggregateAccrualBalance(
                currency.ct, currency.id
            );

            if (periodAmount > 0) {

                periodAccrual.set(0, currency.ct, currency.id);


                periodCurrencies.removeByCurrency(currency.ct, currency.id);
            }


            emit CloseAccrualPeriodEvent(
                periodAmount,
                aggregateAccrualAmountByCurrencyBlockNumber[currency.ct][currency.id][block.number],
                currency.ct, currency.id
            );
        }
    }








    function claimAndTransferToBeneficiary(Beneficiary beneficiary, address destWallet, string balanceType,
        address currencyCt, uint256 currencyId, string standard)
    public
    {

        int256 claimedAmount = _claim(msg.sender, currencyCt, currencyId);


        if (address(0) == currencyCt && 0 == currencyId)
            beneficiary.receiveEthersTo.value(uint256(claimedAmount))(destWallet, balanceType);

        else {

            TransferController controller = transferController(currencyCt, standard);
            require(
                address(controller).delegatecall(
                    controller.getApproveSignature(), beneficiary, uint256(claimedAmount), currencyCt, currencyId
                )
            );


            beneficiary.receiveTokensTo(destWallet, balanceType, claimedAmount, currencyCt, currencyId, standard);
        }


        emit ClaimAndTransferToBeneficiaryEvent(msg.sender, balanceType, claimedAmount, currencyCt, currencyId, standard);
    }




    function claimAndStage(address currencyCt, uint256 currencyId)
    public
    {

        int256 claimedAmount = _claim(msg.sender, currencyCt, currencyId);


        stagedByWallet[msg.sender].add(claimedAmount, currencyCt, currencyId);


        emit ClaimAndStageEvent(msg.sender, claimedAmount, currencyCt, currencyId);
    }






    function withdraw(int256 amount, address currencyCt, uint256 currencyId, string standard)
    public
    {

        require(amount.isNonZeroPositiveInt256());


        amount = amount.clampMax(stagedByWallet[msg.sender].get(currencyCt, currencyId));


        stagedByWallet[msg.sender].sub(amount, currencyCt, currencyId);


        if (address(0) == currencyCt && 0 == currencyId)
            msg.sender.transfer(uint256(amount));

        else {
            TransferController controller = transferController(currencyCt, standard);
            require(
                address(controller).delegatecall(
                    controller.getDispatchSignature(), this, msg.sender, uint256(amount), currencyCt, currencyId
                )
            );
        }


        emit WithdrawEvent(msg.sender, amount, currencyCt, currencyId, standard);
    }




    function _claim(address wallet, address currencyCt, uint256 currencyId)
    private
    returns (int256)
    {

        require(0 < accrualBlockNumbersByCurrency[currencyCt][currencyId].length);


        uint256[] storage claimedAccrualBlockNumbers = claimedAccrualBlockNumbersByWalletCurrency[wallet][currencyCt][currencyId];
        uint256 bnLow = (0 == claimedAccrualBlockNumbers.length ? 0 : claimedAccrualBlockNumbers[claimedAccrualBlockNumbers.length - 1]);


        uint256 bnUp = accrualBlockNumbersByCurrency[currencyCt][currencyId][accrualBlockNumbersByCurrency[currencyCt][currencyId].length - 1];


        require(bnLow < bnUp);


        int256 claimableAmount = aggregateAccrualAmountByCurrencyBlockNumber[currencyCt][currencyId][bnUp]
        - (0 == bnLow ? 0 : aggregateAccrualAmountByCurrencyBlockNumber[currencyCt][currencyId][bnLow]);


        require(0 < claimableAmount);


        int256 walletBalanceBlocks = int256(
            RevenueToken(revenueTokenManager.token()).balanceBlocksIn(wallet, bnLow, bnUp)
        );


        int256 releasedAmountBlocks = int256(
            revenueTokenManager.releasedAmountBlocksIn(bnLow, bnUp)
        );


        int256 claimedAmount = walletBalanceBlocks.mul_nn(claimableAmount).mul_nn(1e18).div_nn(releasedAmountBlocks.mul_nn(1e18));


        claimedAccrualBlockNumbers.push(bnUp);


        return claimedAmount;
    }

    function _transferToBeneficiary(Beneficiary beneficiary, address destWallet, string balanceType,
        int256 amount, address currencyCt, uint256 currencyId, string standard)
    private
    {

        if (address(0) == currencyCt && 0 == currencyId)
            beneficiary.receiveEthersTo.value(uint256(amount))(destWallet, balanceType);

        else {

            TransferController controller = transferController(currencyCt, standard);
            require(
                address(controller).delegatecall(
                    controller.getApproveSignature(), beneficiary, uint256(amount), currencyCt, currencyId
                )
            );


            beneficiary.receiveTokensTo(destWallet, balanceType, amount, currencyCt, currencyId, standard);
        }
    }
}
