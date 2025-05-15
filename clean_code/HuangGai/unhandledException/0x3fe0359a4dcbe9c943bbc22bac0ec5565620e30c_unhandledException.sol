





pragma solidity ^0.5.16;

contract ComptrollerInterface {

    bool public constant isComptroller = true;



    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);



    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) external returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) external;



    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) external view returns (uint, uint);
}



pragma solidity ^0.5.16;





contract InterestRateModel {

    bool public constant isInterestRateModel = true;








    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);









    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

}



pragma solidity ^0.5.16;



contract CTokenStorage {



    bool internal _notEntered;




    string public name;




    string public symbol;




    uint8 public decimals;





    uint internal constant borrowRateMaxMantissa = 0.0005e16;




    uint internal constant reserveFactorMaxMantissa = 1e18;




    address payable public admin;




    address payable public pendingAdmin;




    ComptrollerInterface public comptroller;




    InterestRateModel public interestRateModel;




    uint internal initialExchangeRateMantissa;




    uint public reserveFactorMantissa;




    uint public accrualBlockNumber;




    uint public borrowIndex;




    uint public totalBorrows;




    uint public totalReserves;




    uint public totalSupply;




    mapping (address => uint) internal accountTokens;




    mapping (address => mapping (address => uint)) internal transferAllowances;






    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }




    mapping(address => BorrowSnapshot) internal accountBorrows;
}

contract CTokenInterface is CTokenStorage {



    bool public constant isCToken = true;







    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);




    event Mint(address minter, uint mintAmount, uint mintTokens);




    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);




    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);




    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);




    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);







    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);




    event NewAdmin(address oldAdmin, address newAdmin);




    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);




    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);




    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);




    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);




    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);




    event Transfer(address indexed from, address indexed to, uint amount);




    event Approval(address indexed owner, address indexed spender, uint amount);




    event Failure(uint error, uint info, uint detail);




    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) public view returns (uint);
    function exchangeRateCurrent() public returns (uint);
    function exchangeRateStored() public view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() public returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);




    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint);
    function _acceptAdmin() external returns (uint);
    function _setComptroller(ComptrollerInterface newComptroller) public returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint);
    function _reduceReserves(uint reduceAmount) external returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint);
}

contract CErc20Storage {



    address public underlying;
}

contract CErc20Interface is CErc20Storage {



    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint);




    function _addReserves(uint addAmount) external returns (uint);
}

contract CDelegationStorage {



    address public implementation;
}

contract CDelegatorInterface is CDelegationStorage {



    event NewImplementation(address oldImplementation, address newImplementation);







    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) public;
}

contract CDelegateInterface is CDelegationStorage {





    function _becomeImplementation(bytes memory data) public;




    function _resignImplementation() public;
}



pragma solidity ^0.5.16;







contract CErc20Delegator is CTokenInterface, CErc20Interface, CDelegatorInterface {













    constructor(address underlying_,
                ComptrollerInterface comptroller_,
                InterestRateModel interestRateModel_,
                uint initialExchangeRateMantissa_,
                string memory name_,
                string memory symbol_,
                uint8 decimals_,
                address payable admin_,
                address implementation_,
                bytes memory becomeImplementationData) public {

        admin = msg.sender;


        delegateTo(implementation_, abi.encodeWithSignature("initialize(address,address,address,uint256,string,string,uint8)",
                                                            underlying_,
                                                            comptroller_,
                                                            interestRateModel_,
                                                            initialExchangeRateMantissa_,
                                                            name_,
                                                            symbol_,
                                                            decimals_));


        _setImplementation(implementation_, false, becomeImplementationData);


        admin = admin_;
    }







    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) public {
        require(msg.sender == admin, "CErc20Delegator::_setImplementation: Caller must be admin");

        if (allowResign) {
            delegateToImplementation(abi.encodeWithSignature("_resignImplementation()"));
        }

        address oldImplementation = implementation;
        implementation = implementation_;

        delegateToImplementation(abi.encodeWithSignature("_becomeImplementation(bytes)", becomeImplementationData));

        emit NewImplementation(oldImplementation, implementation);
    }







    function mint(uint mintAmount) external returns (uint) {
        mintAmount;
        delegateAndReturn();
    }







    function redeem(uint redeemTokens) external returns (uint) {
        redeemTokens;
        delegateAndReturn();
    }







    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        redeemAmount;
        delegateAndReturn();
    }






    function borrow(uint borrowAmount) external returns (uint) {
        borrowAmount;
        delegateAndReturn();
    }






    function repayBorrow(uint repayAmount) external returns (uint) {
        repayAmount;
        delegateAndReturn();
    }







    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint) {
        borrower; repayAmount;
        delegateAndReturn();
    }









    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint) {
        borrower; repayAmount; cTokenCollateral;
        delegateAndReturn();
    }







    function transfer(address dst, uint amount) external returns (bool) {
        dst; amount;
        delegateAndReturn();
    }








    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        src; dst; amount;
        delegateAndReturn();
    }









    function approve(address spender, uint256 amount) external returns (bool) {
        spender; amount;
        delegateAndReturn();
    }







    function allowance(address owner, address spender) external view returns (uint) {
        owner; spender;
        delegateToViewAndReturn();
    }






    function balanceOf(address owner) external view returns (uint) {
        owner;
        delegateToViewAndReturn();
    }







    function balanceOfUnderlying(address owner) external returns (uint) {
        owner;
        delegateAndReturn();
    }







    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint) {
        account;
        delegateToViewAndReturn();
    }





    function borrowRatePerBlock() external view returns (uint) {
        delegateToViewAndReturn();
    }





    function supplyRatePerBlock() external view returns (uint) {
        delegateToViewAndReturn();
    }





    function totalBorrowsCurrent() external returns (uint) {
        delegateAndReturn();
    }






    function borrowBalanceCurrent(address account) external returns (uint) {
        account;
        delegateAndReturn();
    }






    function borrowBalanceStored(address account) public view returns (uint) {
        account;
        delegateToViewAndReturn();
    }





    function exchangeRateCurrent() public returns (uint) {
        delegateAndReturn();
    }






    function exchangeRateStored() public view returns (uint) {
        delegateToViewAndReturn();
    }





    function getCash() external view returns (uint) {
        delegateToViewAndReturn();
    }






    function accrueInterest() public returns (uint) {
        delegateAndReturn();
    }










    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint) {
        liquidator; borrower; seizeTokens;
        delegateAndReturn();
    }









    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint) {
        newPendingAdmin;
        delegateAndReturn();
    }






    function _setComptroller(ComptrollerInterface newComptroller) public returns (uint) {
        newComptroller;
        delegateAndReturn();
    }






    function _setReserveFactor(uint newReserveFactorMantissa) external returns (uint) {
        newReserveFactorMantissa;
        delegateAndReturn();
    }






    function _acceptAdmin() external returns (uint) {
        delegateAndReturn();
    }






    function _addReserves(uint addAmount) external returns (uint) {
        addAmount;
        delegateAndReturn();
    }






    function _reduceReserves(uint reduceAmount) external returns (uint) {
        reduceAmount;
        delegateAndReturn();
    }







    function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint) {
        newInterestRateModel;
        delegateAndReturn();
    }








    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = (false, bytes(msg.data));
	 callee.delegatecall(data);

        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return returnData;
    }







    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        return delegateTo(implementation, data);
    }








    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        return abi.decode(returnData, (bytes));
    }

    function delegateToViewAndReturn() private view returns (bytes memory) {
        (bool success, ) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", msg.data));

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(add(free_mem_ptr, 0x40), returndatasize) }
        }
    }

    function delegateAndReturn() private returns (bytes memory) {
        (bool success, ) = (false, bytes(msg.data));
	 implementation.delegatecall(msg.data);


        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)

            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(free_mem_ptr, returndatasize) }
        }
    }





    function () external payable {
        require(msg.value == 0,"CErc20Delegator:fallback: cannot send value to fallback");


        delegateAndReturn();
    }
}
