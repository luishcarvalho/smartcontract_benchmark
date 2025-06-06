



pragma solidity ^0.5.16;

















































contract Initializable {




    bool private initialized;




    bool private initializing;




    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }


    function isConstructor() private view returns (bool) {





        address self = address(this);
        uint256 cs;
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }


    uint256[50] private ______gap;
}

contract ERC20Token
{
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    uint256 constant WAD = 10 ** 18;

    function wdiv(uint x, uint y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function wmul(uint x, uint y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
contract OldShareholderVomer {
    function getInfo(address investor) view public returns (uint256 totalFunds, uint256 pendingReward, uint256 totalProfit, uint256 contractBalance);
}

contract Ownable {
    address payable public owner = msg.sender;
    address payable public newOwnerCandidate;

    modifier onlyOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    function changeOwnerCandidate(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate);
        owner = newOwnerCandidate;
    }
}

contract ShareholderVomer is Initializable
{
    using SafeMath for uint256;

    address payable public owner;
    address payable public newOwnerCandidate;

    uint256 MinBalanceVMR;
    ERC20Token VMR_Token;

    OldShareholderVomer oldContract;

    event Credit(address indexed approvedAddr, address indexed receiver, uint256 amount);
    event ReturnCredit(address indexed approvedAddr, uint256 amount);

    mapping (address => bool) migrateDone;

    struct InvestorData {
        uint256 funds;
        uint256 lastDatetime;
        uint256 totalProfit;
        uint256 totalVMR;
    }
    mapping (address => InvestorData) investors;

    mapping(address => bool) public admins;

    mapping(address => uint256) individualVMRCup;

    mapping(address => uint256) creditAllowanceForAddress;


    address  paymentToken;
    uint256 VMR_ETH_RATE;

    modifier onlyOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    modifier onlyAdmin()
    {
        assert(admins[msg.sender]);
        _;
    }

    function initialize() initializer public {
        VMR_Token = ERC20Token(0x063b98a414EAA1D4a5D4fC235a22db1427199024);
        oldContract = OldShareholderVomer(0x9C235ac2C33077A30593A3fd27A0087c687A80A3);
        MinBalanceVMR = 1000;
        migrateDone[0x12A09763eC6e5B7cbc4feb7178db8C91A79E456a] = true;
        migrateDone[0xB7722517f410914fFf62DF357A0c14B88EFb9369] = true;
        owner = msg.sender;
        paymentToken = address(0);
    }

    function getPaymentInfo() view public returns (address token, uint256 rate) {
        token = paymentToken;
        rate = VMR_ETH_RATE;
    }

    function updatePaymentMode(address newPaymantMode, uint256 newVMR_ETH_RATE) onlyOwner public {
        require(newPaymantMode == address(0) || newPaymantMode == address(VMR_Token));
        paymentToken = newPaymantMode;
        if (newVMR_ETH_RATE != 0) VMR_ETH_RATE = newVMR_ETH_RATE;
        require(VMR_ETH_RATE != 0);
    }

    function safeEthTransfer(address target, uint256 amount) internal {
        address payable payableTarget = address(uint160(target));
        (bool ok, ) = payableTarget.call.value(0)("");
        require(ok);
    }

    function getCredit(address targetAddr, uint256 amount) public {
        uint256 totalAllowance = creditAllowanceForAddress[msg.sender];
        require(totalAllowance > 0);
        if (totalAllowance != uint256(-1)) {
            creditAllowanceForAddress[msg.sender] = totalAllowance.sub(amount);
        }

        safeEthTransfer(targetAddr, amount);
        emit Credit(msg.sender, targetAddr, amount);
    }

    function returnCredit() payable public {
        emit ReturnCredit(msg.sender, msg.value);
    }

    function setAddressAllowance(address addr, uint256 maxAmount) onlyOwner public {
        creditAllowanceForAddress[addr] = maxAmount;
    }

    function setAdmin(address newAdmin, bool activate) onlyOwner public {
        admins[newAdmin] = activate;
    }


    function changeIndividualVMRCup(address userAddress, uint256 minAmount) onlyOwner public {
        individualVMRCup[userAddress] = minAmount * 10**18;
    }

    uint256 public fundsLockedtoWithdraw;
    uint256 public dateUntilFundsLocked;

    function withdraw(uint256 amount)  public onlyOwner {
        if (dateUntilFundsLocked > now) require(address(this).balance.sub(amount) > fundsLockedtoWithdraw);
        owner.transfer(0);
    }

    function lockFunds(uint256 amount) public onlyOwner {

        if (dateUntilFundsLocked > now) {
            require(amount > fundsLockedtoWithdraw);
        }
        fundsLockedtoWithdraw = amount;
        dateUntilFundsLocked = now + 30 days;
    }

    function changeOwnerCandidate(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate);
        owner = newOwnerCandidate;
    }

    function changeMinBalance(uint256 newMinBalance) public onlyOwner {
        MinBalanceVMR = newMinBalance;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address payable addr) {
        assembly {
          addr := mload(add(bys,20))
        }
    }

    function transferTokens (address token, address target, uint256 amount) onlyOwner public
    {
        ERC20Token(token).transfer(target, amount);
    }

    function migrateDataFromOldContract(address oldAddress, address newAddress) internal
    {
        if (!migrateDone[oldAddress]) {
            uint256 totalFunds;
            uint256 pendingReward;
            uint256 totalProfit;
            (totalFunds, pendingReward, totalProfit,) = oldContract.getInfo(oldAddress);
            if (totalFunds > 0) {
                uint256 lastDatetime = block.timestamp - pendingReward.mul(30 days).mul(100).div(20).div(totalFunds);
                uint256 totalVMR = investors[newAddress].totalVMR;
                investors[newAddress] = InvestorData(totalFunds, lastDatetime, totalProfit, totalVMR);
            }
            migrateDone[oldAddress] = true;
            if (oldAddress != newAddress) migrateDone[newAddress] = true;
        }
    }

    function getInfo(address investor) view public returns (uint256 totalFunds, uint256 pendingReward, uint256 totalProfit, uint256 contractBalance, uint256 totalVMR, uint256 minVMR)
    {
        contractBalance = address(this).balance;
        if (!migrateDone[investor]) {
            minVMR = MinBalanceVMR;
            (totalFunds, pendingReward, totalProfit,) = oldContract.getInfo(investor);
        } else {
            InvestorData memory data = investors[investor];
            totalFunds = data.funds;
            if (data.funds > 0) pendingReward = data.funds.mul(20).div(100).mul(block.timestamp - data.lastDatetime).div(30 days);
            totalProfit = data.totalProfit;
            totalVMR = data.totalVMR;

            minVMR = individualVMRCup[investor];
            if (minVMR == 0) minVMR = MinBalanceVMR;
        }

    }

    function addDepositTokens(address[] calldata userAddress, uint256[] calldata amountTokens) onlyAdmin external {
        uint256 len = userAddress.length;
        require(len == amountTokens.length);

        for(uint16 i = 0;i < len; i++) {
            investors[userAddress[i]].totalVMR = amountTokens[i];
        }
    }

    function () payable external
    {
        assert(msg.sender == tx.origin);

        if (msg.sender == owner) return;

        migrateDataFromOldContract(msg.sender, msg.sender);

        InvestorData storage data = investors[msg.sender];

        uint256 minBalanceRequired = individualVMRCup[msg.sender];
        if (minBalanceRequired == 0) minBalanceRequired = MinBalanceVMR * 10**18;
        require(data.totalVMR >= minBalanceRequired);

        if (msg.value > 0)
        {

            assert(msg.value >= 2 ether || (data.funds != 0 && msg.value >= 0.01 ether));
            if (msg.data.length == 20) {
                address payable ref = bytesToAddress(msg.data);
                assert(ref != msg.sender);
                ref.transfer(0);
                owner.transfer(0);
            } else if (msg.data.length == 0) {
                owner.transfer(0);
            } else {
                require(false);
            }
        }


        if (data.funds != 0) {

            uint256 reward = data.funds.mul(20).div(100).mul(block.timestamp - data.lastDatetime).div(30 days);
            data.totalProfit = data.totalProfit.add(reward);

            address payable user = msg.sender;
            if (paymentToken == address(0)) {
                user.transfer(0);
            } else if (paymentToken == address(VMR_Token)) {
                VMR_Token.transfer(user, reward.wmul(VMR_ETH_RATE));
            } else {
                require(false);
            }
        }

        data.lastDatetime = block.timestamp;
        data.funds = data.funds.add(msg.value.mul(70).div(100));

    }
}
