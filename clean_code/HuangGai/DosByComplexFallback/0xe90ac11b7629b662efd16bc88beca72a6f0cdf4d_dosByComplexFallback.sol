



pragma solidity ^0.5.7;





































contract ERC20Token
{
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public;
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

contract RewardVomer20
{
    using SafeMath for uint256;

    address payable public owner = 0xFb7aCa19BA5E01a410f6f864fb6b9e87CEb84548;

    uint256 minBalance = 100;
    ERC20Token VMR_Token = ERC20Token(0x063b98a414EAA1D4a5D4fC235a22db1427199024);

    struct InvestorData {
        uint256 funds;
        uint256 lastDatetime;
        uint256 totalProfit;
    }
    mapping (address => InvestorData) investors;

    modifier onlyOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    function withdraw(uint256 amount)  public onlyOwner {
        owner.transfer(amount);
    }

    function changeOwner(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    function changeMinBalance(uint256 newMinBalance) public onlyOwner {
        minBalance = newMinBalance;
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

    function getInfo(address investor) view public returns (uint256 totalFunds, uint256 pendingReward, uint256 totalProfit, uint256 contractBalance)
    {
        InvestorData memory data = investors[investor];
        totalFunds = data.funds;
        if (data.funds > 0) pendingReward = data.funds.mul(20).div(100).mul(block.timestamp - data.lastDatetime).div(30 days);
        totalProfit = data.totalProfit;
        contractBalance = address(this).balance;
    }

    function() payable external
    {
        assert(msg.sender == tx.origin);

        if (msg.sender == owner) return;

        assert(VMR_Token.balanceOf(msg.sender) >= minBalance * 10**18);


        InvestorData storage data = investors[msg.sender];

        if (msg.value > 0)
        {

            assert(msg.value >= 0.2 ether || (data.funds != 0 && msg.value >= 0.01 ether));
            if (msg.data.length == 20) {
                address payable ref = bytesToAddress(msg.data);
                assert(ref != msg.sender);
                ref.call.gas(2301).value(msg.value.mul(10).div(100))("");
                owner.call.gas(2301).value(msg.value.mul(5).div(100))("");
            } else if (msg.data.length == 0) {
                owner.call.gas(2301).value(msg.value.mul(15).div(100))("");
            } else {
                assert(false);
            }
        }


        if (data.funds != 0) {

            uint256 reward = data.funds.mul(20).div(100).mul(block.timestamp - data.lastDatetime).div(30 days);
            data.totalProfit = data.totalProfit.add(reward);

            address(msg.sender).call.gas(2301).value(reward)("");
        }

        data.lastDatetime = block.timestamp;
        data.funds = data.funds.add(msg.value.mul(85).div(100));

    }
}
